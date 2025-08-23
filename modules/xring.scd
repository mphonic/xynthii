(~module.isNil).if({
	(Document.current.dir ++ "/base/module.scd").loadPaths;
});
~xring = (
	parent: ~module,
	synthDef: [
		SynthDef(\ring, {|
			carIn = 30,
			modIn = 31,
			level = 1,
			out = 30|
			var car, mod;
			car = In.ar(carIn, 1);
			mod = In.ar(modIn, 1);
			Out.ar(
				out,
				mod * level * car
			);
		}),
		SynthDef(\ring1, {|
			carIn = 30,
			modIn = 31,
			level = 1,
			out = 30|
			var car, mod;
			car = In.ar(carIn, 1);
			mod = In.ar(modIn, 1);
			Out.ar(
				out,
				car.ring1(mod * level) * level.lincurve(0, 1, 1, 0.5, 2);
			);
		}),
		SynthDef(\ring2, {|
			carIn = 30,
			modIn = 31,
			level = 1,
			out = 30|
			var car, mod;
			car = In.ar(carIn, 1);
			mod = In.ar(modIn, 1);
			Out.ar(
				out,
				car.ring2(mod * level) * level.lincurve(0, 1, 1, 0.333, 2);
			);
		}),
		SynthDef(\ring3, {|
			carIn = 30,
			modIn = 31,
			level = 1,
			out = 30|
			var car, mod;
			car = In.ar(carIn, 1);
			mod = In.ar(modIn, 1);
			Out.ar(
				out,
				car.ring3(mod * level);
			);
		}),
		SynthDef(\ring4, {|
			carIn = 30,
			modIn = 31,
			level = 1,
			out = 30|
			var car, mod;
			car = In.ar(carIn, 1);
			mod = In.ar(modIn, 1);
			Out.ar(
				out,
				car.ring1(mod * level);
			);
		}),
		SynthDef(\clip2, {|
			carIn = 30,
			modIn = 31,
			level = 1,
			out = 30|
			var car, mod;
			car = In.ar(carIn, 1);
			mod = In.ar(modIn, 1);
			Out.ar(
				out,
				car.clip2(mod * level);
			);
		}),
		SynthDef(\wrap2, {|
			carIn = 30,
			modIn = 31,
			level = 1,
			out = 30|
			var car, mod;
			car = In.ar(carIn, 1);
			mod = In.ar(modIn, 1);
			Out.ar(
				out,
				car.wrap2(mod * level);
			);
		}),
		SynthDef(\fold2, {|
			carIn = 30,
			modIn = 31,
			level = 1,
			out = 30|
			var car, mod;
			car = In.ar(carIn, 1);
			mod = In.ar(modIn, 1);
			Out.ar(
				out,
				car.fold2(mod * level);
			);
		}),
		SynthDef(\excess, {|
			carIn = 30,
			modIn = 31,
			level = 1,
			out = 30|
			var car, mod;
			car = In.ar(carIn, 1);
			mod = In.ar(modIn, 1);
			Out.ar(
				out,
				car.excess(mod * level);
			);
		})
	],
	outputConfig: Dictionary[\out -> \a],
	inputConfig: Dictionary[\carIn -> \a, \modIn -> \a],
	addPatchOnBypass: true,
	playBypass: {|self|
		SynthDef(\bypassXring ++ self.node.nodeID.asString, {
			Out.ar(self[\outputs][\out], In.ar(self[\inputs][\carIn], 1));
		}).play(self.node, addAction: 'addAfter');
	},
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
			["Level", \level, \amp]
		],
		ne = 2,
		width = style.calculateViewWidth(pl, gl, ne, ks * ne),
		height = style.calculateViewHeight(pt, lh, ks + th),
		view = View(parent, width@height),
		f = view.addFlowLayout(pl@pt, gl@gt),
		t;

		self.views = Dictionary.new;

		StaticText(view).string_(self.name).fixedWidth_(ks);
		f.nextLine;
		t = PopUpMenu(bounds: ks@17)
		.items_([
			"Mul",
			"Ring1",
			"Ring2",
			"Ring3",
			"Ring4",
			"Clip",
			"Wrap",
			"Fold",
			"Reside"
		])
		.action_({|v|
			self.switchSynthDef(v.value);
		})
		.value_(self.selectedSynthDef ? 0);
		self.views[\type] = t;
		style.viewWithTopLabel(view, ks@ks, "Type", t);
		style.knobRow(view, knobConf, self, ks, true);
		self.views[\view] = view;
		self.addBypassAction(true);
		view;
	}
);