(~module.isNil).if({
	(Document.current.dir ++ "/base/module.scd").loadPaths;
});

~xdelay = (
	parent: ~module,
	synthDef: SynthDef(\xdelay, {|
		out=0,
		in=22,
		mix=0.2,
		delay = 0.125,
		time=5,
		i_max_del=8,
		lpf=1200|
		var sig, mod, del, fbs, fb, hpf = 120;
		sig=In.ar(in, 1);
		fb=exp(log(0.001) * delay.max(SampleDur.ir) * time.reciprocal);
		mod=LFPar.kr(0.667, mul: 0.00027);
		fbs=LocalIn.ar(1).softclip;
		del=DelayC.ar(Limiter.ar(Mix([fbs * fb, sig]), 0.99, 0.01) , i_max_del, delay.lag(0.1) + mod);
		del=LPF.ar(HPF.ar(del, hpf), lpf);
		LocalOut.ar(del);
		Out.ar(out, 1 - mix * sig + (mix * del));
	}),
	outputConfig: Dictionary[\out -> \a],
	inputConfig: Dictionary[\in -> \a],
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
			["Del", \delay, ControlSpec(0.01, 8.0, 2)],
			["Sus", \time, ControlSpec(0.0001, 30, 4)],
			["Cut", \lpf, \freq],
			["Mix", \mix, \unipolar]
		],
		ne = 4,
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