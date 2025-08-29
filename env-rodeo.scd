( // ONLY RUN THIS IF XYNTHII ISN'T ALREADY RUNNING
(Document.current.dir ++ "/xynthii.scd").loadPaths;
~makeXynthii.value({|d| ~xynthii = d });
)
// Wait til you see "Ready to go."
~xynthii.loadSettings(Document.current.dir ++ "/presets/soopersawrn");
~xynthii.makeGui();

// Random walks fill the envelopes and determine rate of gates
(
var nodes = 7,
minDur = 0.25,
maxDur = 1.0,
dev = 0.1,
s1,
s2,
s3;
s1 = {
	Array.fill(nodes, { Pbrown(0.0, 1.0, dev, inf).asStream });
}.dup;
s2 = {
	Array.fill(nodes - 1, { Pbrown(0.02, 1.0, dev, inf).asStream });
}.dup;
s3 = [
	Array.fill(nodes, { Pbrown(minDur, maxDur, 0.05, inf).asStream }),
	Array.fill(nodes - 1, { Pbrown(-4.0, 4.0, dev, inf).asStream })
];
Tdef(\squiggle).clear;
Tdef(\squiggle, {
	inf.do {|c|
		var s1Val = s1.collect({|e| Array.fill(nodes, {|i| e[i].next }) }),
		s2Val = s1.collect({|e| Array.fill(nodes - 1, {|i| e[i].next }).normalizeSum }),
		s3Val = s3[0].wrapAt(c).next,
		curves = s3[1].collect({|e| e.next }),
		env1 = Env(([0] ++ s1Val[0].select({|e, c| (c > 0).and(c < (nodes - 1)) }) ++ [0]).normalize, s2Val[0], curves, releaseNode: nodes - 2),
		env2 = Env(s1Val[1], s2Val[1], curves, releaseNode: nodes - 2),
		dur = s3Val,
		len = dur - (s2Val[0][s2Val[0].size - 1].max(s2Val[1][s2Val[1].size - 1]) * dur);
		~xynthii.env2.setEnv(env1);
		~xynthii.env2.setParams(\dur, len);
		~xynthii.env3.setEnv(env2);
		~xynthii.env3.setParams(\dur, len);
		~xynthii.trigger(1);
		(len).max(0.1).wait;
		(0.05.coin).if({ rrand(0.5, 2.0).wait });
		~xynthii.trigger(0);
		(dur - len).max(0.01).wait;
	}
}).play;
)
Tdef(\squiggle).stop; ~xynthii.trigger(0);
