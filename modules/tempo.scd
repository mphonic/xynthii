(~module.isNil).if({
	(Document.current.dir ++ "/base/module.scd").loadPaths;
});

~tempoclocker = (
	parent: ~module,
	synthDef: SynthDef(\tempoclocker, {|
		tempo = 110,
		subdivision = 4,
		on = 0.5,
		out = 30|
		var time, sig;
		time = tempo.max(0.25) * 60.reciprocal * subdivision;
		sig = Trig.kr(
			Impulse.kr(time),
			time.reciprocal * on
		);
		Out.kr(
			out,
			sig * 2 - 1
		);
	}),
	outputConfig: Dictionary[\out -> \k],
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
			["Tempo", \tempo, ControlSpec(1.0, 360, 2)],
			["Sub", \subdivision, ControlSpec(1, 8, \lin, 1.0)],
			["On", \on, \unipolar]
		],
		ne = 3,
		width = style.calculateViewWidth(pl, gl, ne, ks * ne),
		height = style.calculateViewHeight(pt, lh, ks + th),
		view = View(parent, width@height),
		f = view.addFlowLayout(pl@pt, gl@gt),
		i;

		self.views = Dictionary.new;

		StaticText(view).string_(self.name).fixedWidth_(ks);
	/*	i = Button(view, 8@8)
		.background_(Color.black);*/
		f.nextLine;
		style.knobRow(view, knobConf, self, ks, true);
		self.views[\view] = view;

		view;
	}
);