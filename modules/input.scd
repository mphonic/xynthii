(~module.isNil).if({
	(Document.current.dir ++ "/base/module.scd").loadPaths;
});
~input = (
	parent: ~module,
	synthDef: SynthDef(\input, {|
		source = 0,
		amp = 1.0,
		out = 30,
		envOut = 34|
		var sig;
		sig = SoundIn.ar(source, amp);
		Out.kr(envOut,
			Amplitude.kr(sig) * 2 - 1
		);
		Out.ar(
			out,
			sig
		);
	}),
	outputConfig: Dictionary[\out -> \a, \envOut -> \k],
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
			["Amp", \amp, \amp]
		],
		ne = 1,
		width = style.calculateViewWidth(pl, gl, ne, ks * ne),
		height = style.calculateViewHeight(pt, lh, ks + th),
		view = View(parent, width@height),
		f = view.addFlowLayout(pl@pt, gl@gt);

		self.views = Dictionary.new;

		StaticText(view).string_(self.name).fixedWidth_(ks);
		f.nextLine;
		style.knobRow(view, knobConf, self, ks, true);
		self.views[\view] = view;
		self.addBypassAction();
		view;
	}
);