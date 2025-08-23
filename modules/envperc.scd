(~module.isNil).if({
	(Document.current.dir ++ "/base/module.scd").loadPaths;
});
~envPerc = (
	parent: ~module,
	synthDef: SynthDef(\envPerc, {|
		att = 0.0,
		dec = 1.0,
		curve = -4.0,
		t_gate = 0,
		kOut = 30,
		out = 30|
		var env = EnvGen.ar(Env.perc(att, dec, curve: curve), t_gate);
		Out.kr(kOut, A2K.kr(env));
		Out.ar(
			out,
			env
		);
	}),
	outputConfig: Dictionary[\out -> \a, \kOut -> \k],
	makeGui: {|self, parent, styles, hideAtt = false, showAttSwitch = false|
		var style = styles ? Event.new,
		ks = style.knobSize ? 50,
		pl = style.paddingLeft ? 20,
		pt = style.paddingTop ? 20,
		gl = style.gapLeft ? 4,
		gt = style.gapRight ? 4,
		lh = style.lineHeight ? 11,
		bw = style.toggleButtonWidth ? 50,
		bh = style.toggleButtonHeight ? 25,
		knobConf = [
			["Att", \att, ControlSpec(0.0, 10.0, 4)],
			["Dec", \dec, ControlSpec(0.0, 10.0, 4)]
		],
		ne = (hideAtt).if({
			1 + (showAttSwitch).if({ 1 }, { 0 })
		}, {
			2
		}),
		width = style.calculateViewWidth(pl, gl, ne, ks * ne),
		height = style.calculateViewHeight(pt, lh, ks),
		view = View(parent, width@height),
		f = view.addFlowLayout(pl@pt, gl@gt);

		self.views = Dictionary.new;

		(hideAtt).if({ knobConf.removeAt(0) });

		StaticText(view).string_(self.name).fixedWidth_(ks);
		f.nextLine;
		(showAttSwitch && hideAtt).if({
			var a = Button(bounds: bw@bh)
			.states_([["S"], ["L"]])
			.action_({|v|
				self.setParams(\att, (v.value == 0).if({ 0.01 }, { 0.1 }));
			});
			style.viewWithTopLabel(view, ks@ks, "Att", a);
			self[\controls][\att].get({|v| {
				(v < 0.1).if({ a.value_(0) }, { a.value_(1) });
			}.defer;
			});
			self.views[\att] = [a, ControlSpec(0.0, 10.0, 4)];
		});

		style.knobRow(view, knobConf, self);
		self.views[\view] = view;
		view;
	}
);