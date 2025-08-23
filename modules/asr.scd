(~syncableEnvelope.isNil).if({
	(Document.current.dir ++ "/base/syncableenvelope.scd").loadPaths;
});
~asr = (
	parent: ~syncableEnvelope,
	synthDef: SynthDef(\asr, {|
		att = 1.0,
		dec = 1.0,
		curve = -4,
		gate = 0,
		gatemod = 1,
		kOut = 30,
		out = 30|
		var env = EnvGen.ar(
			Env.asr(att, 1, dec, curve: curve),
			(gatemod - 1).max(0) + gate
		);
		Out.kr(kOut, A2K.kr(env));
		Out.ar(
			out,
			env
		);
	}),
	outputConfig: Dictionary[\out -> \a, \kOut -> \k],
	customDumpSettings: {|self, dict, cb|
		dict[\syncedWith] = (self.syncedWith ? List.new).collect({|e| e.name }).asSet.asList;
		dict[\syncedFrom] = (self.syncedFrom ? Event.new).name;
		cb.value(dict);
	},
	makeGui: {|self, parent, styles, canSync = false, syncSource|
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
			["Att", \att, ControlSpec(0.0, 30.0, 4)],
			["Dec", \dec, ControlSpec(0.0, 30.0, 4)]
		],
		ne = 2,
		width = style.calculateViewWidth(pl, gl, ne, ks * ne + 45),
		height = style.calculateViewHeight(pt, lh, ks + th),
		view = View(parent, width@height),
		f = view.addFlowLayout(pl@pt, gl@gt),
		g = Button(bounds: bw@bh)
		.states_([["Gate"], ["Rel"]])
		.action_({|v|
			self.setParams(\gate, v.value);
		}),
		sb;

		self.views = Dictionary.new;

		StaticText(view).string_(self.name).fixedWidth_(ks);
		f.nextLine;
		(canSync).if({
			sb = Button(bounds: bw@bh)
			.states_([["^"], ["-"]])
			.action_({|v|
				(v.value == 0).if({
					self.unsync();
				}, {
					self.sync(syncSource);
				});
			})
			.value_(self.syncedFrom.notNil.asInteger);
		});
		View(view, 40@(height - lh)).layout_(VLayout(
			[g, stretch: 1],
			[sb, stretch: 1]
		).margins_(0).spacing_(0));
		self.views[\gate] = g;
		self.views[\sync] = sb;
		style.knobRow(view, knobConf, self, ks, true);
		self.controls[\gate].get({|v|
			{ self.views[\gate].value_(v) }.defer;
		});
		self.views[\view] = view;
		view;
	}
);