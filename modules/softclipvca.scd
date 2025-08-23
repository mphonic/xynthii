(~module.isNil).if({
	(Document.current.dir ++ "/base/module.scd").loadPaths;
});
~softclipVca = (
	parent: ~module,
	synthDef: SynthDef(\vca, {|in = 32,
		amp = 1.0,
		envIn = 30,
		out = 0|
		var signalInput = In.ar(in, 1),
		am = In.ar(envIn, 1);
		Out.ar(out, (signalInput * am * amp).softclip);
	}),
	inputConfig: Dictionary[\in -> \a, \envIn -> \a],
	makeGui: {|self, parent, styles|
		var style = styles ? Event.new,
		ks = style.knobSize ? 50,
		pl = style.paddingLeft ? 20,
		pt = style.paddingTop ? 20,
		gl = style.gapLeft ? 4,
		gt = style.gapRight ? 4,
		lh = style.lineHeight ? 11,
		ne = 1,
		width = style.calculateViewWidth(pl, gl, ne, ks * ne),
		height = style.calculateViewHeight(pt, lh, ks),
		view = View(parent, width@height),
		f = view.addFlowLayout(pl@pt, gl@gt),
		spec = \amp.asSpec,
		k = Knob()
		.action_({|v|
			self.setParams(\amp, spec.map(v.value));
		});

		self.views = Dictionary.new;
		self.views[\amp] = [k, spec];

		StaticText(view).string_(self.name).fixedWidth_(ks);
		style.viewWithTopLabel(view, ks@ks, "Amp", k);
		self[\controls][\amp].get({|v| { k.value_(spec.unmap(v)) }.defer });
		self.views[\view] = view;
		view;
	}
);