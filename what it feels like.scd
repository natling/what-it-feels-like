(
~buffers = [
	"keyboard 1.aif",
	"keyboard 2.aif",
	"keyboard 3.aif",
	"keyboard 4.aif",
	"keyboard 5.aif",
	"keyboard 6.aif",
	"keyboard 7.aif",
	"keyboard 8.aif",
	"mouse 1.aif",
	"mouse 2.aif",
	"mouse 3.aif",
	"mouse 4.aif",
	"mouse 5.aif",
	"mouse 6.aif",
	"mouse 7.aif",
	"null.aif",
]
.collect{arg i; thisProcess.nowExecutingPath.dirname +/+ "sounds" +/+ i}
.collect{arg i; Buffer.read(s, i)};
)

(
SynthDef(\playBuf,
	{
		| out = 0, bufnum = 0, rate = 1, startPos = 0, loop = 0, spread = 0, center = 0, amp = 1 |

		var player;

		player = PlayBuf.ar(
			numChannels: 1,
			bufnum: bufnum,
			rate: rate,
			startPos: startPos,
			loop: loop,
			doneAction: 2,
		);

		player = Splay.ar(inArray: player, spread: spread, level: amp, center: center);
		Out.ar(out, player);
	};
).add;
)

(
var keyboard, mouse, null, nullInstances, nullInstancesN, player;
var segmentLevelsLow, segmentLevelsHigh, segmentDurs;

keyboard = ~buffers[0..7];
mouse    = ~buffers[8..14];
null     = ~buffers[15];

nullInstancesN = 10;

nullInstances = nullInstancesN.collect{
	arg i;

	Synth(\playBuf,
		[
			bufnum: null,
			startPos: i.linlin(0, nullInstancesN, 0.0, 1.0),
			loop: 1,
			spread: 1,
			center: i.linlin(0, nullInstancesN - 1, -1.0, 1.0),
			amp: 1,
		];
	);
};

segmentLevelsLow  = [1.0, 0.01, 0.01];
segmentLevelsHigh = [5.0, 0.01, 0.01];

segmentDurs = [30, 2] * 60;

player = Pbind(
	\instrument, \playBuf,
	\bufnum, Pif(
		condition: Pfunc({0.5.coin}),
		iftrue:  Prand(keyboard, inf),
		iffalse: Prand(mouse, inf),
	),
	\delta, Pwhite(
		lo: Pseg(
			levels: Pseq(segmentLevelsLow),
			durs: Pseq(segmentDurs),
			curves: 'exp',
		),
		hi: Pseg(
			levels: Pseq(segmentLevelsHigh),
			durs: Pseq(segmentDurs),
			curves: 'exp',
		),
	),
	\spread, 0,
	\center, Pwhite(-1.0, 1.0),
	\amp, 1,
);

TempoClock.tempo = 1;

Task({
	s.prepareForRecord;
	s.record;
	5.wait;
	player.play;
	segmentDurs.sum.wait;
	5.wait;
	nullInstances.do{arg i; i.free};
	3.wait;
	s.stopRecording;
}).play;
)