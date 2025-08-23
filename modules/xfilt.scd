(~module.isNil).if({
	(Document.current.dir ++ "/base/module.scd").loadPaths;
});
~xfilt = (
	parent: ~module,
	synthDef: [
		/*SynthDef(\moogLadder, {|in = 30,
			ffreq = 440,
			ffreqmul = 1,
			res = 0.0,
			fmIn = 30
			fmLevel = 0.0,
			amp = 1,
			out = 0|
			var signalInput, fm, filt;
			signalInput = In.ar(in, 1);
			fm = (In.ar(fmIn, 1) * fmLevel).range(-64, 64).midiratio;
			ffreq = ffreq.lag(0.02) * fm;
			filt = BMoog.ar(
				signalInput,
				ffreq.max(20).min(20000),
				res,
				mul: amp * 0.334
			);
			Out.ar(out, filt);
		}),
		SynthDef(\blowpass, {|in = 30,
			ffreq = 440,
			ffreqmul = 1,
			res = 0.0,
			fmIn = 30
			fmLevel = 0.0,
			amp = 1,
			out = 0|
			var signalInput, fm, filt;
			signalInput = In.ar(in, 1);
			fm = (In.ar(fmIn, 1) * fmLevel).range(-64, 64).midiratio;
			ffreq = ffreq.lag(0.02) * fm;
			filt = BLowPass.ar(
				signalInput,
				ffreq.ring1(fm).max(20).min(20000),
				res.linlin(0.0, 1.0, 1.0, 0.01),
				mul: amp
			);
			Out.ar(out, filt);
		}),*/
		SynthDef(\vaLadder24, {|in = 30,
			ffreq = 440,
			ffreqmul = 1,
			res = 0.0,
			fmIn = 30
			fmLevel = 0.0,
			amp = 1,
			out = 0|
			var signalInput, fm, filt;
			signalInput = In.ar(in, 1) * 0.25;
			fm = (In.ar(fmIn, 1) * fmLevel).range(-72, 72).midiratio;
			ffreq = ffreq.lag(0.02) * fm;
			filt = VALadder.ar(
				signalInput,
				(ffreq * ffreqmul).max(20).min(20000),
				res,
				type: 0
			);
			Out.ar(out, filt * amp);
		}),
		SynthDef(\vaLadder12, {|in = 30,
			ffreq = 440,
			ffreqmul = 1,
			res = 0.0,
			fmIn = 30
			fmLevel = 0.0,
			amp = 1,
			out = 0|
			var signalInput, fm, filt;
			signalInput = In.ar(in, 1) * 0.25;
			fm = (In.ar(fmIn, 1) * fmLevel).range(-72, 72).midiratio;
			ffreq = ffreq.lag(0.02) * fm;
			filt = VALadder.ar(
				signalInput,
				(ffreq * ffreqmul).max(20).min(20000),
				res,
				type: 1
			);
			Out.ar(out, filt * amp);
		})
	],
	inputConfig: Dictionary[\in -> \a, \fmIn -> \a],
	lo24: {|self|
		self.updateSynth(0);
	},
	lo12: {|self|
		self.updateSynth(1);
	},
	updateSynth: {|self, index|
		var gui = self.views;
		self.switchSynthDef(index);
		(gui.notNil.and(self.keepGuiUpdated)).if({
			{ gui[\mode].value_(index); }.defer;
		});
	},
	addPatchOnBypass: true,
	makeGui: {|self, parent, styles|
		var style = styles ? Event.new,
		ks = style.knobSize ? 50,
		pl = style.paddingLeft ? 20,
		pt = style.paddingTop ? 20,
		gl = style.gapLeft ? 4,
		gt = style.gapRight ? 4,
		lh = style.lineHeight ? 11,
		bw = style.toggleButtonWidth ? 50,
		bh = style.toggleButtonHeight ? 25,
		th = style.textFieldHeight ? 22,
		knobConf = [
			["Cutoff", \ffreq, \freq],
			["Res", \res],
			["Fm", \fmLevel, \pan]
		],
		width = style.calculateViewWidth(pl, gl, 4, ks * 4),
		height = style.calculateViewHeight(pt, lh, ks + th),
		l = Button(bounds: bw@bh)
		.states_([["24"], ["12"]])
		.action_({|v|
			self.switchSynthDef(v.value);
		})
		.value_(self.selectedSynthDef ? 0),
		view = View(parent, width@height),
		f = view.addFlowLayout(pl@pt, gl@gt);

		self.views = Dictionary.new;
		self.views[\mode] = l;
		StaticText(view).string_(self.name).fixedWidth_(ks);
		f.nextLine;
		style.viewWithTopLabel(view, ks@ks, "Type", l);
		style.knobRow(view, knobConf, self, ks, true);
		self.views[\view] = view;
		self.addBypassAction(true);
		view;
	}
);