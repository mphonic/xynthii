(~module.isNil).if({
	(Document.current.dir ++ "/base/module.scd").loadPaths;
});
~noise = (
	parent: ~module,
	synthDef: SynthDef(\noise, {|
		color = 0.5,
		amp = 1.0,
		out = 30|
		var sig;
		color = color.clip * 2;
		sig = Mix(
			[
				BrownNoise.ar((color < 1) * (1 - color)),
				PinkNoise.ar((color <= 1) * color + (
					(color > 1) * (2 - color)
				)),
				WhiteNoise.ar((color > 1) * (color - 1))
			]
		);
		Out.ar(
			out,
			sig * amp
		);
	}),
	outputConfig: Dictionary[\out -> \a],
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
			["Color", \color, \unipolar],
			["Amp", \amp, \amp]
		],
		ne = 2,
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