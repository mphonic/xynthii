var extension, sortModules;
(~audioPatchbay.isNil).if({
	(Document.current.dir ++ "/base/audiopatchbay.scd").loadPaths;
});

sortModules = {|modules, dict|
	dict.keys.asSortedList({|a, b|
		var nameA = dict[a][\moduleName],
		nameB = dict[b][\moduleName],
		amod = modules.select({|v| v.name == nameA }).pop(),
		bmod = modules.select({|v| v.name == nameB }).pop(),
		ia = modules.indexOf(amod),
		ib = modules.indexOf(bmod);
		(ia == ib).if({
			a < b;
		}, {
			ia < ib;
		});
	});
};
extension = (
	makeGui: {|self, parent, ignoreInputs, ignoreOutputs, inputOrder, outputOrder, bs, tw, th, fs|
		var g,
		r = 0,
		c = 0,
		numCols,
		o = self.io[\outputs],
		i = self.io[\inputs],
		outputs,
		inputs,
		buttonSize = bs ? 20,
		textWindowWidth = tw ? 35,
		textWindowHeight = th ? 87,
		fontSize = fs ? 10,
		viewHeight,
		viewWidth,
		view,
		rm = self.modules.reverse;
		// sort by module order
		inputs = (inputOrder.notNil).if({
			inputOrder.select({|e| i.keys.includes(e.asString) });
			// sortModules.value(rm, i);
		}, {
			sortModules.value(rm, i);
		});
		// ["inputs", inputs].postln;
		outputs = (outputOrder.notNil).if({
			outputOrder.select({|e| o.keys.includes(e.asString) });
			// sortModules.value(rm, o);
		}, {
			sortModules.value(rm, o);
		});

		self.views = Dictionary.new;

		(ignoreInputs.notNil).if({
			ignoreInputs = ignoreInputs.collect({|v| v.asSymbol });
			inputs = inputs
			.collect({|v| v.asSymbol })
			.select({|v| ignoreInputs.includes(v).not })
			.collect({|v| v.asString });
		});
		(ignoreOutputs.notNil).if({
			ignoreOutputs = ignoreOutputs.collect({|v| v.asSymbol });
			outputs = outputs
			.collect({|v| v.asSymbol })
			.select({|v| ignoreOutputs.includes(v).not })
			.collect({|v| v.asString });
		});

		g = GridLayout().margins_(0).spacing_(0);
		numCols = inputs.size;
		g.add(nil, r, c);
		c = c + 1;
		inputs.do({|key, i|
			var k = key.asString,
			a = Array.fill(k.size, {|c| k[c] }),
			string = a.join("\n");
			g.add(
				StaticText()
				.string_(string ++ " ")
				.fixedSize_(buttonSize@textWindowHeight)
				.align_(\bottom),
				r,
				c + i
			);
		});
		r = 1;
		outputs.do({|key, i|
			var h = HLayout().margins_(0).spacing_(0),
			p = o[key][\patches] ? Dictionary.new;

			self.views[key] = Dictionary.new;
			g.add(StaticText()
				.string_(key ++ " ")
				.fixedSize_(textWindowWidth@buttonSize)
				.align_(\right),
				r + i,
				0
			);
			c = 1;
			inputs.do({|ikey, x|
				var isOn = p[ikey].notNil,
				kon = [
					Color.clear,
					Color.black,
					Color.gray,
					Color.black
				],
				koff = [
					Color.clear,
					Color.clear,
					Color.clear,
					Color.clear
				],
				b = Button()
				.states_([["", nil, Color.gray], ["", nil, Color(0.75, 0.7, 0.7)]])
				.action_({|b|
					(b.value == 0).if({
						self.unpatch(key, ikey);
						k.visible_(false);
					}, {
						self.patch(key, ikey);
						k.value_(1)
						.visible_(true);
					});
				})
				.fixedSize_(buttonSize@buttonSize)
				.value_(isOn.asInteger),

				k = Knob(b, Rect(
					b.bounds.left + 2,
					b.bounds.top + 2,
					b.bounds.width * 0.8,
					b.bounds.height * 0.8
				))
				.action_({|v| self.setPatch(key, ikey, \amp.asSpec.map(v.value)) })
				.enabled_(false)
				.color_(koff)
				.value_(1);

				b.mouseDownAction_({|v, x, y, mod|
					(mod == 524288).if({
						k.color_(kon)
						.enabled_(true);
					});
				});

				b.mouseUpAction_({|v, x, y, mod|
					k.color_((k.value < 1).if({ kon }, { koff }))
					.enabled_(false);
				});

				(isOn).if({
					p[ikey].get(\mul, {|v|
						{
							var vis = (v < 1);
							k.value_(\amp.asSpec.unmap(v))
							.color_((vis).if({ kon }, { koff }));
						}.defer;
					});
				});

				self.views[key][ikey] = b;
				g.add(b,
					r + i,
					c + x
				);
			});
		});
		viewHeight = o.size * buttonSize + textWindowHeight;
		viewWidth = i.size * buttonSize + textWindowWidth;
		view = View(parent, bounds: viewWidth@viewHeight).layout_(g);
		self.views[\view] = view;
		view;
	},
	updateGui: {|self|
		var o = self.io[\outputs],
		v = self.views;
		o.keys.do({|key|
			var p = o[key][\patches];
			(v[key].notNil).if({
				v[key].keys.do({|k| v[key][k].value_(0) });
				p.keys.do({|ikey|
					(v[key][ikey].notNil).if({
						v[key][ikey].value_(1);
					});
				});
			});
		});
	}
);

~audioPatchbay = ~audioPatchbay ++ extension;