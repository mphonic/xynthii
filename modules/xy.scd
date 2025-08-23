(~module.isNil).if({
	(Document.current.dir ++ "/base/module.scd").loadPaths;
});
~xy = (
	parent: ~module,
	synthDef: SynthDef(\xyk, {|x = 0, y = 0, outX = 32, outY = 33|
		Out.kr(outX, x.lag(0.1));
		Out.kr(outY, y.lag(0.1));
	}),
	outputConfig: Dictionary[\outX -> \k, \outY -> \k],
	makeGui: {|self, parent, styles|
		var style = styles ? Event.new,
		ks = style.smallKnobSize ? 25,
		pl = style.paddingLeft ? 20,
		pt = style.paddingTop ? 20,
		gl = style.gapLeft ? 4,
		gt = style.gapRight ? 4,
		lh = style.lineHeight ? 11,
		height = parent.bounds.height - (pt * 2) - (gt * 2),
		width = height,
		view = View(parent, width@height),
		f = view.addFlowLayout(pl@pt, gl@gt),
		spec = \pan.asSpec,
		xy;

	/*	StaticText(view, 50@lh).string_(self.name).fixedSize_(ks@lh);
		f.nextLine;*/

		xy = Slider2D(view, 100@100)
		.action_({|v|
			self[\controls][\x].set(spec.map(v.x));
			self[\controls][\y].set(spec.map(v.y));
		})
		.x_(0.5)
		.y_(0.5);

		self.views = Dictionary.new;
		self.views[\x] = xy;
		self.views[\y] = xy;

		self[\controls][\x].get({|v| { xy.x_(spec.unmap(v)) }.defer });
		self[\controls][\y].get({|v| { xy.y_(spec.unmap(v)) }.defer });
		self.views[\view] = view;
		view;
	}
);