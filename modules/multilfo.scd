(~module.isNil).if({
	(Document.current.dir ++ "/base/module.scd").loadPaths;
});
~multilfo = (
	parent: ~module,
	synthDef: [
		SynthDef(\lftri, {|gate, freq = 4, out = 0|
			Out.kr(out, LFTri.kr(freq));
		}),
		SynthDef(\lfpulse, {|gate, freq = 4, out = 0|
			Out.kr(out, LFPulse.kr(freq) * 2 - 1);
		}),
		SynthDef(\lfsaw, {|gate, freq = 4, out = 0|
			Out.kr(out, LFSaw.kr(freq));
		}),
		SynthDef(\lfsh, {|gate, freq = 4, out = 0|
			Out.kr(out, LFDNoise0.kr(freq).lag(0.02));
		}),
		SynthDef(\lfnoise, {|gate, freq = 4, out = 0|
			Out.kr(out, LFDNoise3.kr(freq));
		}),
		SynthDef(\smoothwalk, {|gate, freq = 4, out = 0|
			Out.kr(out, LFBrownNoise2.kr(freq, 0.5, 2))
		}),
		SynthDef(\lfdust, {|gate, freq = 4, out = 0|
			var trig = Dust2.kr(freq);
			Out.kr(out, Latch.kr(trig, trig.abs).lag(0.02) * 2 - 1);
		}),
		SynthDef(\lfdustwalk, {|gate, freq = 4, out = 0|
			var trig = Dust.kr(freq);
			Out.kr(out, TBrownRand.kr(-1.0, 1.0, 0.5, 2, trig));
		}),
		SynthDef(\trigff, {|gate, out = 0|
			Out.kr(out, ToggleFF.kr(gate) * 2 - 1);
		}),
		SynthDef(\trigrand, {|gate, out = 0|
			Out.kr(out, TRand.kr(-1.0, 1.0, gate));
		}),
		SynthDef(\trigbrownrand, {|gate, out = 0|
			Out.kr(out, TBrownRand.kr(-1.0, 1.0, 0.5, 2, gate));
		}),
		SynthDef(\trigramp, {|gate, freq = 4, out = 0|
			Out.kr(out, Phasor.kr(gate, freq * ControlDur.ir, -1.0, 1.0, -1.0));
		}),
		SynthDef(\trigsin, {|gate, freq = 4, out = 0|
			Out.kr(out, SinOsc.kr(
				0,
				Phasor.kr(gate, freq * 2pi * ControlDur.ir, 0, 2pi, 0))
			);
		})
	],
	outputConfig: Dictionary[\out -> \k],
	makeGui: {|self, parent, styles|
		var style = styles ? Event.new,
		ks = style.knobSize ? 50,
		pl = style.paddingLeft ? 20,
		pt = style.paddingTop ? 20,
		gl = style.gapLeft ? 4,
		gt = style.gapRight ? 4,
		lh = style.lineHeight ? 11,
		th = style.textFieldHeight ? 22,
		ne = 1,
		width = style.calculateViewWidth(pl, gl, ne, ks * ne),
		height = style.calculateViewHeight(pt, lh, ks + th),
		view = View(parent, width@parent.bounds.height),
		f = view.addFlowLayout(pl@pt, gl@gt),
		knobConf = [["Freq", \freq, \lofreq]],
		m;

		self.views = Dictionary.new;

		StaticText(view).string_(self.name).fixedWidth_(ks);
		f.nextLine;
		m = PopUpMenu(view, ks@20)
		.items_([
			"Tri",
			"Pul",
			"Saw",
			"SH",
			"LF Noise",
			"LF Walk",
			"Dust",
			"Stagger",
			"Trig FF",
			"Trig Rand",
			"Trig Stag",
			"Trig Ramp",
			"Trig Sin"
		])
		.action_({|v|
			self.switchSynthDef(v.value);
			[8, 9, 10].includes(v.value).if({
				self[\views][\freq][0].enabled_(false);
			}, {
				self[\views][\freq][0].enabled_(true);
			});
		})
		.value_(self.selectedSynthDef ? 0);
		self.views[\synth] = [m];

		style.knobRow(view, knobConf, self, ks, true);
		self.views[\view] = view;
		view;
	}
);