var extension, sortModules;

(~controlPatchbay.isNil).if({
	(Document.current.dir ++ "/base/controlpatchbay.scd").loadPaths;
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
	modView: {|self, parent, inputs, outputs, selected, ignoreInputs, ignoreOutputs|
		var mw = 90,
		mh = 25,
		ks = 25,
		g = 4,
		v = View(parent, (mw + ks + g)@(mh * 3)),
		f = FlowLayout(v.bounds, 0@0, g@0),
		iItems = inputs.asArray,
		oItems = outputs.asArray,
		pin,
		pmm,
		pou,
		sl,
		ml,
		id,
		input,
		output,
		modmod,
		lastClick = 0,
		spec = \pan.asSpec;

		v.decorator_(f);

		self.podIndex = (self.podIndex ? 0) + 1;

		(ignoreInputs.notNil).if({
			iItems = iItems.select({|v| ignoreInputs.includes(v).not });
		});
		(ignoreOutputs.notNil).if({
			oItems = oItems.select({|v| ignoreOutputs.includes(v).not });
		});

		v.mouseUpAction_({
			var t = SystemClock.seconds,
			diff = t - lastClick;
			((diff < 0.25).and(id.notNil)).if({
				var bypassed = self.toggleBypass(output.asString, id);
				(bypassed).if({
					v.children.do({|e| e.enabled_(false); });
				}, {
					v.children.do({|e| e.enabled_(true); });
				});
			});
			lastClick = t;
		});

		(selected.notNil).if({
			var in = iItems.indexOf(selected[0].asSymbol),
			out = oItems.indexOf(selected[1].asSymbol);
			id = selected[2];
			(
				in.notNil
				&&
				out.notNil
				&&
				id.notNil
			).if({
				input = selected[0];
				output = selected[1];
				id = selected[2];
				modmod = selected[5];
			}, {
				selected = nil;
			});
		});

		pin = PopUpMenu(v, mw@mh)
		.items_([" "] ++ iItems)
		.action_({|v|
			var i = v.items[v.value];
			(v.value == 0).if({
				(id.notNil).if({
					self.unpatch(output.asString, id);
					id = nil;
				});
				input = nil;
			}, {
				input = i;
				(output.notNil).if({
					(id.notNil).if({
						self.unpatch(output.asString, id);
					});
					id = self.patch(output.asString, input.asString, spec.map(sl.value));
					(modmod.notNil).if({
						self.addModMod(output.asString, modmod.asString, id, spec.map(ml.value));
					});
				});
			});
		})
		.value_((input.isNil).if({ 0 }, { iItems.indexOf(input) + 1 }));
		sl = Knob(v, ks@ks)
		.action_({|v|
			(id.notNil).if({
				self.setPatch(output.asString, id, spec.map(v.value));
			});
		})
		.value_((selected.isNil).if({ 0.5 }, { spec.unmap(selected[3]) ? 0.5 }));
		self.style.addListenCapability(sl, self, "mul" ++ self.podIndex.asString);
		self.views[("mul" ++ self.podIndex.asString).asSymbol] = sl;
		f.nextLine;
		pmm = PopUpMenu(v, mw@mh)
		.items_([" "] ++ oItems)
		.action_({|v|
			var i = v.items[v.value];
			(v.value == 0).if({
				(id.notNil).if({
					self.removeModMod(output.asString, id);
				});
				modmod = nil;
				ml.enabled_(false);
			}, {
				modmod = i;
				(id.notNil).if({
					self.addModMod(output.asString, modmod.asString, id, spec.map(ml.value));
				});
				ml.enabled_(true);
			});
		})
		.value_((modmod.isNil).if({ 0 }, {
			var ind = oItems.indexOf(modmod);
			(ind.notNil).if({ ind + 1 }, { 0 })
		}));
		ml = Knob(v, ks@ks)
		.action_({|v|
			(id.notNil).if({
				self.setModMod(output.asString, id, spec.map(v.value));
			});
		})
		.value_((selected.isNil).if({ 0.5 }, { spec.unmap(selected[6] ? 0) }))
		.enabled_(modmod.notNil.and(modmod != \nil));
		self.style.addListenCapability(ml, self, "modmul" ++ self.podIndex.asString);
		self.views[("modmul" ++ self.podIndex.asString).asSymbol] = ml;
		f.nextLine;
		pou = PopUpMenu(v, mw@mh)
		.items_([" "] ++ oItems)
		.action_({|v|
			var i = v.items[v.value];
			(v.value == 0).if({
				(id.notNil).if({
					self.unpatch(output.asString, id);
					id = nil;
				});
				output = nil;
			}, {
				(input.notNil).if({
					(id.notNil).if({
						self.unpatch(output.asString, id);
					});
					output = i;
					id = self.patch(output.asString, input.asString, spec.map(sl.value));
					(modmod.notNil).if({
						self.addModMod(output.asString, modmod.asString, id, spec.map(ml.value));
					});
				}, {
					output = i;
				});
			});
		})
		.value_((output.isNil).if({ 0 }, { oItems.indexOf(output) + 1 }));
		v;
	},
	makeGui: {|self, parent, mods = 1, excludeInputs, excludeOutputs, style|
		var o = sortModules.value(self.modulators, self.io[\outputs])
		.collect({|v| v.asSymbol }),
		i = sortModules.value(self.modules, self.io[\inputs])
		.collect({|v| v.asSymbol }),
		view = View(parent, parent.bounds),
		f = FlowLayout(view.bounds, 0@0, 12@0),
		patches = self.getAllPatches();

		view.decorator_(f);
		self.style = style;
		self.podIndex = 0;

		self.views = Dictionary.new;

		StaticText(view).string_("Mod Pod").fixedWidth_(60);
		f.nextLine;

		// ignore t_ and i_ rate inputs
		i = i.select({|v| " (t_|i_|e_|b_)".matchRegexp(v.asString).not });
		(excludeInputs.notNil).if({
			excludeInputs = excludeInputs.collect({|v| v.asSymbol });
			i = i.select({|v| excludeInputs.includes(v).not });
			patches = patches.select({|v|
				excludeInputs.includes(v[\inputKey].asSymbol).not
			});
		});
		(excludeOutputs.notNil).if({
			excludeOutputs = excludeOutputs.collect({|v| v.asSymbol });
			o = o.select({|v| excludeOutputs.includes(v).not });
			patches = patches.select({|v|
				excludeOutputs.includes(v[\outputKey].asSymbol).not
			});
		});
		self.views[\modulations] = List.new;

		(patches.size > 0).if({
			self.addExistingPatches(patches, view, i, o, mods);
		}, {
			self.addNewModViews(mods, view, i, o);
		});
		self.views[\view] = view;
		view;
	},
	addExistingPatches: {|self, patches, view, i, o, total|
		var count = 0,
		cond = Condition(false);

		patches.do({|p|
			var ok = p[\outputKey],
			id = p[\id];
			self.getPatchInfo(ok, id, {|v|
				(v.notNil).if({
					p[\mul] = v[\mul];
					p[\add] = v[\add];
					p[\modmul] = v[\modmul];
					p[\modadd] = v[\modadd];
					p[\modKey] = v[\modKey];
				});
				count = count + 1;
				(count >= patches.size).if({
					cond.test = true;
					cond.signal;
				});
			});
		});
		{
			cond.wait;
			{
				patches.do({|p|
					self.views[\modulations].add(
						self.modView(view, i, o, [
							p[\inputKey].asSymbol,
							p[\outputKey].asSymbol,
							p[\id],
							p[\mul],
							p[\add],
							p[\modKey].asSymbol,
							p[\modmul],
							p[\modadd]
						])
					);
				});
				self.addNewModViews((total - patches.size).max(0), view, i, o);
				(self.viewCcs.notNil).if({
					var ccs = self.viewCcs;
					ccs.keys.do({|key|
						var k = self.views[key.asSymbol];
						(k.isArray).if({ k = k[0] });
						MIDIdef.cc((self.name ++ key).asSymbol, {|val, num|
							{
								k.valueAction_(val.linlin(0, 127, 0, 1.0));
							}.defer;
						}, ccs[key]);
					});
				});
			}.defer;
		}.fork;
	},
	addNewModViews: {|self, num, view, i, o|
		num.do({
			self.views[\modulations].add(self.modView(view, i, o));
		});
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

~controlPatchbay = ~controlPatchbay ++ extension;