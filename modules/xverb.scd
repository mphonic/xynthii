(~module.isNil).if({
	(Document.current.dir ++ "/base/module.scd").loadPaths;
});

~xverb = (
	parent: ~module,
	synthDef: [
		SynthDef(\scverb_44, {|
			outL=0,
			outR=1,
			inL=22,
			inR=23,
			mix=0.2,
			time=5,
			lpf=8200|
			var apj, sig, mods, delays, dts, fbs, fb, filts;
			sig=[In.ar(inL, 1), In.ar(inR, 1)];
			dts=[0.056077097505669, 0.062743764172336, 0.072947845804989, 0.080657596371882, 0.08859410430839, 0.093582766439909, 0.04859410430839, 0.043832199546485];
			fb=exp(log(0.001) * 0.089 * time.reciprocal);
			mods=LFNoise2.kr([3.1, 3.5, 1.110, 3.973, 2.341, 1.897, 0.891, 3.221],
				[0.0010, 0.0011, 0.0017, 0.0006, 0.0010, 0.0011, 0.0017, 0.0006]
			);
			fbs=LocalIn.ar(8);
			apj=0.25 * Mix.ar(fbs);
			delays=DelayC.ar(sig - fbs + apj, 0.1, dts + mods);
			filts=LPF.ar(delays * fb, lpf);
			LocalOut.ar(DelayC.ar(filts, ControlDur.ir, ControlDur.ir));
			sig = (1 - mix) * sig;
			mix = mix * 0.35;
			Out.ar(
				outL,
				sig[0] + (mix *
					Mix.ar([filts[0], filts[2], filts[4], filts[6]]))
			);
			Out.ar(
				outR,
				sig[1] + (mix *
					Mix.ar([filts[1], filts[3], filts[5], filts[7]]))
			);
		}),
		SynthDef(\scverb_48, {|
			outL=0,
			outR=0,
			inL=22,
			inR=23,
			mix=0.2,
			time=5,
			lpf=8200|
			var apj, sig, mods, delays, dts, fbs, fb, filts;
			sig=[In.ar(inL, 1), In.ar(inR, 1)];
			dts=[0.056104166666667, 0.062729166666667, 0.073145833333333, 0.080770833333333, 0.088604166666667, 0.093604166666667, 0.048604166666667, 0.043729166666667];
			fb=exp(log(0.001) * 0.089 * time.reciprocal);
			mods=LFNoise2.kr([3.1, 3.5, 1.110, 3.973, 2.341, 1.897, 0.891, 3.221],
				[0.0010, 0.0011, 0.0017, 0.0006, 0.0010, 0.0011, 0.0017, 0.0006]
			);
			fbs=LocalIn.ar(8);
			apj=0.25 * Mix.ar(fbs);
			delays=DelayC.ar(sig - fbs + apj, 0.1, dts + mods);
			filts=LPF.ar(delays * fb, lpf);
			LocalOut.ar(DelayC.ar(filts, ControlDur.ir, ControlDur.ir));
			sig = (1 - mix) * sig;
			mix = mix * 0.35;
			Out.ar(
				outL,
				sig[0] + (mix *
					Mix.ar([filts[0], filts[2], filts[4], filts[6]]))
			);
			Out.ar(
				outR,
				sig[1] + (mix *
					Mix.ar([filts[1], filts[3], filts[5], filts[7]]))
			);
		})
	],
	addPatchOnBypass: true,
	playBypass: {|self|
		SynthDef(\bypassXverb ++ self.node.nodeID.asString, {
			var inL = In.ar(self[\inputs][\inL], 1),
			inR = In.ar(self[\inputs][\inR], 1);
			Out.ar(self[\outputs][\outL], inL);
			Out.ar(self[\outputs][\outR], inR);
		}).play(self.node, addAction: 'addAfter');
	},
	outputConfig: Dictionary[\outL -> \a, \outR -> \a],
	inputConfig: Dictionary[\inL -> \a, \inR -> \a],
	makeGui: {|self, parent, styles, canSync = false, syncSource|
		var style = styles ? Event.new,
		ks = style.knobSize ? 50,
		pl = style.paddingLeft ? 20,
		pt = style.paddingTop ? 20,
		gl = style.gapLeft ? 4,
		gt = style.gapRight ? 4,
		lh = style.lineHeight ? 11,
		th = style.textFieldHeight ? 22,
		knobConf = [
			["Time", \time, ControlSpec(0.1, 30, 4)],
			["Cut", \lpf, \freq],
			["Mix", \mix, \unipolar]
		],
		ne = 3,
		width = style.calculateViewWidth(pl, gl, ne, ks * ne),
		height = style.calculateViewHeight(pt, lh, ks + th),
		view = View(parent, width@height),
		f = view.addFlowLayout(pl@pt, gl@gt);

		self.views = Dictionary.new;

		StaticText(view).string_(self.name).fixedWidth_(ks);
		f.nextLine;
		style.knobRow(view, knobConf, self, ks, true);
		self.views[\view] = view;
		self.addBypassAction(true);
		view;
	}
);