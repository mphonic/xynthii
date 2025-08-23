(~module.isNil).if({
	(Document.current.dir ++ "/base/module.scd").loadPaths;
});
~mono2Stereo = (
	parent: ~module,
	synthDef: SynthDef(\output12, {|in = 32, out = 0, tone = 0.0, amp = 1.0, pan = 0.0, panmod = 1|
		var sig = In.ar(in, 1);
		sig = BLowShelf.ar(sig, 650, 1.0, tone.neg);
		sig = BHiShelf.ar(sig, 650, 1.0, tone);
		Out.ar(
			out,
			Limiter.ar(
				Pan2.ar(
					LeakDC.ar(sig),
					pan + (panmod - 1),
					amp
				),
				-0.3.dbamp
			)
		);
	}),
	defaults: Dictionary[\out -> 0],
	inputConfig: Dictionary[\in -> \a],
	makeGui: {|self, parent, styles|
		var style = styles ? Event.new,
		ks = style.knobSize ? 50,
		pl = style.paddingLeft ? 20,
		pt = style.paddingTop ? 20,
		gl = style.gapLeft ? 4,
		gt = style.gapRight ? 4,
		lh = style.lineHeight ? 11,
		th = style.textFieldHeight ? 22,
		knobConf = [
			["Tone", \tone, ControlSpec(-12, 12.0)],
			["Amp", \amp, \amp],
			["Pan", \pan, \pan]
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
		view;
	}
);