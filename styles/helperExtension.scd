var helperExtension;

(~style.isNil).if({
	(Document.current.dir ++ "/styles/module.scd").loadPaths;
});

helperExtension = (
	viewWithTopLabel: {|self, parent, bounds, label, thing, text, module, param|
		var v = View(parent, bounds),
		l = VLayout().margins_(0).spacing_(0),
		t = StaticText()
		.string_(label)
		.align_(\center);

		l.add(t, align: \top);
		l.add(thing, align: \top);
		self.addListenCapability(thing, module, param);
		text !? {|t| l.add(t, align: \top) };
		v.layout_(l);
		v;
	},
	addListenCapability: {|self, thing, module, param|
		thing.mouseDownAction_({|view, x, y, mod|
			(mod == 131072).if({ // shift
				// listen for midi
				self.listenForMidi(thing, module, param);
			}, {
				([262144, 655360].includes(mod)).if({ // ctrl or shift-alt
					// delete current midi controls
					self.removeMidi(thing, module, param);
				});
			});
		});
	},
	listenForMidi: {|self, view, module, param|
		var key = (module.name ++ param).asSymbol,
		listenKey = (key ++ "listen").asSymbol,
		cc,
		cond = Condition(false);
		MIDIdef.cc(listenKey, {|val, num, chan, src|
			cc = num;
			cond.test = true;
			cond.signal;
		});
		Routine({
			4.wait;
			cond.test = true;
			cond.signal;
		}).play(AppClock);
		Routine({
			cond.wait;
			(cc.notNil).if({
				var d = module.views[\ccs] ? Dictionary.new;
				d[param] = cc;
				module.views[\ccs] = d;
				MIDIdef.cc(key, {|val, num, chan, src|
					{
						view.valueAction_(val.linlin(0, 127, 0, 1.0));
					}.defer;
				}, cc);
			});
			MIDIdef(listenKey).free;
		}).play(AppClock);
	},
	removeMidi: {|self, view, module, param|
		var key = module.name ++ param,
		d = module.views[\ccs] ? Dictionary.new;
		d.removeAt(param);
		module.views[\ccs] = d;
		MIDIdef(key.asSymbol).free;
	},
	calculateViewWidth: {|self, p, g, ne, ew|
		p * 2 + (g * ne - 1) + ew;
	},
	calculateViewHeight: {|self, p, lh, eh|
		p * 2 + eh + lh
	},
	knobRow: {|self, view, knobConf, module, ks, addText = false|
		var th = self.textFieldHeight ? 22;
		ks = ks ? self.knobSize;
		knobConf.do({|e|
			var spec = (e[2] ? \unipolar).asSpec,
			k = Knob(),
			t,
			tact,
			param = e[1];

			(addText).if({
				("freq".matchRegexp(param.asString).and(
					param.asString != "freqscale"
				)).if({
					// allow note names
					tact = {|v|
						var val = v.value;
						("([a-g]|[A-G])(b|#)?[0-9]".matchRegexp(val)).if({
							val = val.notemidi.midicps;
						});
						k.valueAction_(module.views[param][1].unmap(val.asFloat));
					};
				}, {
					tact = {|v|
						k.valueAction_(module.views[param][1].unmap(v.value.asFloat))
					};
				});
				t = TextField()
				.action_(tact);
				k.action_({|v|
					var val = module.views[param][1].map(v.value);
					module.setParams(param, val);
					t.value_(val.round(0.001));
				});
			}, {
				k.action_({|v|
					module.setParams(param, module.views[param][1].map(v.value));
				});
			});
			self.viewWithTopLabel(
				view,
				ks@(addText.asInteger * th + ks),
				e[0],
				k,
				t,
				module,
				param
			);
			module.views[param] = [k, spec, t];
			module[\controls][param].get({|v|
				{
					k.value_(module.views[param][1].unmap(v));
					t !? {|e| e.value_(v.round(0.001)) };
				}.defer
			});
		});
	}
);

~style = ~style ++ helperExtension;