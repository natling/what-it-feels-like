(
Buffer.freeAll(s);

z = (
	buffers: ['keyboard', 'mouse', 'null'].collect{
		arg category;
		category -> PathName(thisProcess.nowExecutingPath.dirname +/+ category).files.collect{
			arg file;
			Buffer.read(s, file.fullPath);
		};
	}.asDict(class: Event),

	null: (
		layers: 10,
	),

	segments: (
		levels: (
			low:  [ 1.0, 0.01, 0.01 ],
			high: [ 5.0, 0.01, 0.01 ],
		),

		durations: [ 30, 2 ] * 60,
	),
);

SynthDef(\playBuf,
	{
		| out = 0, bufnum = 0, rate = 1, startPos = 0, loop = 0, spread = 0, center = 0, amp = 1 |

		var signal = PlayBuf.ar(
			numChannels: 1,
			bufnum: bufnum,
			rate: rate,
			startPos: startPos,
			loop: loop,
			doneAction: 2,
		);

		signal = Splay.ar(inArray: signal, spread: spread, level: amp, center: center);
		Out.ar(out, signal);
	};
).add;
)

(
z.null.player = Task{
	z.null.instances = z.null.layers.collect{
		arg i;

		Synth(\playBuf,
			[
				bufnum: z.buffers.null.unbubble,
				startPos: i.linlin(0, z.null.layers, 0.0, 1.0),
				loop: 1,
				spread: 1,
				center: i.linlin(0, z.null.layers - 1, -1.0, 1.0),
				amp: 1,
			],
		);
	};
};

z.segments.player = Pbind(
	\instrument, \playBuf,
	\bufnum, Pif(
		condition: Pfunc{0.5.coin},
		iftrue:  Prand(z.buffers.keyboard, inf),
		iffalse: Prand(z.buffers.mouse,    inf),
	),
	\delta, Pwhite(
		lo: Pseg(
			levels: Pseq(z.segments.levels.low),
			durs:   Pseq(z.segments.durations),
			curves: 'exp',
		),
		hi: Pseg(
			levels: Pseq(z.segments.levels.high),
			durs:   Pseq(z.segments.durations),
			curves: 'exp',
		),
	),
	\spread, 0,
	\center, Pwhite(-1.0, 1.0),
	\amp, 1,
);

z.player = Task{
	z.null.player.play;
	5.wait;
	z.segments.player.play;
	z.segments.durations.sum.wait;
	5.wait;
	z.null.instances.do(_.free);
};

z.recorder = Task{
	s.prepareForRecord;
	2.wait;
	s.record;
	3.wait;
	z.player.play;
	5.wait;
	z.segments.durations.sum.wait;
	5.wait;
	3.wait;
	s.stopRecording;
};

TempoClock.tempo = 1;
z.player.play;
)