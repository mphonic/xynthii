(// ONLY RUN THIS IF XYNTHII ISN'T ALREADY RUNNING
(Document.current.dir ++ "/xynthii.scd").loadPaths;
~makeXynthii.value({|d| ~xynthii = d });
)
// Wait til you see "Ready to go."
~xynthii.loadSettings(Document.current.dir ++ "/presets/trackme");
~xynthii.makeGui();

( // Run this to track different properties of the sound from your main input
// run ~tracker.free below to stop tracking
var x = ~xynthii,
o1 = x.osc1[\controls],
o2 = x.osc2[\controls],
o3 = x.osc3[\controls],
v1 = x.vca1[\controls],
v2 = x.vca2[\controls],
f = x.filt[\controls],
r = x.ring[\controls],
d = x.del[\controls],
v = x.verb[\controls];

~tracker = SynthDef(\spectrack, {
	var sig, chain, centroid, flatness, pcile, amplitude, pitch, hasPitch;
	sig = SoundIn.ar(0);
	chain = FFT(LocalBuf(2048), sig, wintype: 1);
	centroid = SpecCentroid.kr(chain).lag(0.025);
	flatness = SpecFlatness.kr(chain).lag(0.025);
	pcile = SpecPcile.kr(chain, 0.5).lag(0.025);
	#pitch, hasPitch = Tartini.kr(sig);

	amplitude = Amplitude.kr(sig, 0.02, 0.1) * 2.5;
	amplitude = amplitude.clip;
	// amplitude = amplitude > 0.01 * amplitude;
	pitch = (pitch.lag(0.025).cpsmidi - 60)
	.midiratio
	.max(0.03125)
	.explin(0.03125, 48, 0, 2.0);

	hasPitch = hasPitch.lag(0.1);

	centroid = (centroid.cpsmidi - 60).midiratio;

	Out.kr(o1[\freqmod], pitch);
	Out.kr(o2[\freqmod], pitch);
	Out.kr(o3[\freqmod], pitch);
	Out.kr(v1[\amp], amplitude * hasPitch * (1 - flatness));
	Out.kr(v2[\amp], amplitude * (1 - hasPitch) * flatness);
	Out.kr(f[\ffreq], pcile);
	Out.kr(f[\ffreqmul], centroid);
	Out.kr(o1[\fmLevel], flatness * 0.25);
	Out.kr(o2[\fmLevel], flatness * 0.25);
	Out.kr(o3[\fmLevel], flatness * 0.25);
	Out.kr(r[\level], flatness);

	amplitude = amplitude.lag(1);
	Out.kr(d[\mix], amplitude * 0.5);
	Out.kr(v[\mix], amplitude * 0.5);
}).play(x.groups.main, addAction: 'addToHead');
)
~tracker.free

( // Run this to replace the output with a concatenated version of input & xynthii
// Run ~concat.free below to go back to normal output.
~concat = SynthDef(\concat, {|len = 0.025, reverse = 0|
	var in = SoundIn.ar(0),
	xin = In.ar(0, 2),
	c = Concat2.ar(
		Select.ar(reverse, [xin, in]),
		Select.ar(reverse, [in, xin]),
		2,
		2,
		LFNoise2.kr(0.25).range(0, len),
		len,
		threshold: 0.0001
	);
	ReplaceOut.ar(0, c);
}).play(~xynthii.groups.main, addAction: 'addToTail');
)
~concat.set(\len, 0.1); // etc.
~concat.set(\reverse, 1);
~concat.free