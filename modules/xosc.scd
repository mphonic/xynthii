(~module.isNil).if({
	(Document.current.dir ++ "/base/module.scd").loadPaths;
});

~xosc = (
	parent: ~module,
	synthDef: [
		SynthDef(\xsine, {|freq = 100,
			freqmod = 1,
			freqscale = 0,
			fmIn = 30
			fmLevel = 0.0,
			pmLevel = 0,
			pw = 0.0,
			amp = 0.1,
			out = 0|
			var sig,
			phas,
			phasc,
			fm = (In.ar(fmIn, 1)),
			pm = fm * (pmLevel * 8);
			fm = fm * fmLevel;
			freq = freq.max(0.01);
			freq = Select.ar(fm < 0, [
				fm.linexp(0.0, 1.0, freq, 20000.0),
				fm.linexp(-1.0, 0.0, 20.0.min(freq), freq)
			]).lag(0.01);
			freq = freq * (freqmod - 1 * 64).midiratio * freqscale.midiratio;
			pw = pw.lag(0.1);
			phas = Phasor.ar(
				0,
				freq.max(0.01).min(20000) * SampleDur.ir
			);
			phasc = phas.lincurve(0, 1, 0, 1, pw.max(0.1).linlin(0, 1, 0, 12));
			/*sig = SinOsc.ar(
				0,
				if(pw,
					phas.lincurve(0, 1, 0, 1, 12),
					// phas,
					phas
				) * 2pi,
				mul: amp.lag(0.02)
			);*/
			phas = (pw <= 0.1) * if(pw / 0.1, phasc, phas)
			+ ((pw > 0.1) * phasc);
			sig = SinOscOS.ar(
				0,
				phas * 2 + pm,
				oversample: 4,
				mul: amp.lag(0.02)
			);
			Out.ar(out, LeakDC.ar(sig.checkBadValues));
		}),
		SynthDef(\xtri, {|freq = 100,
			freqmod = 1,
			freqscale = 0,
			fmIn = 30
			fmLevel = 0.0,
			pmLevel = 0,
			pw = 0.0,
			amp = 0.1,
			out = 0|
			var sig,
			fm = (In.ar(fmIn, 1)),
			pm = fm * (pmLevel * 8);
			fm = fm * fmLevel;
			freq = freq.max(0.01);
			freq = Select.ar(fm < 0, [
				fm.linexp(0.0, 1.0, freq, 20000.0),
				fm.linexp(-1.0, 0.0, 20.0.min(freq), freq)
			]).lag(0.01);
			freq = freq * (freqmod - 1 * 64).midiratio * freqscale.midiratio;
			/*sig = VarSaw.ar(
				freq.max(0.01).min(20000),
				width: pw,
				mul: amp.lag(0.02)
			);*/
			sig = VarSawOS.ar(
				freq.max(0.01).min(20000),
				pm,
				width: pw.lag(0.02),
				oversample: 4,
				mul: amp.lag(0.02)
			);
			Out.ar(out, sig.checkBadValues);
		}),
		SynthDef(\xpulse, {|freq = 100,
			freqmod = 1,
			freqscale = 0,
			fmIn = 30
			fmLevel = 0.0,
			pmLevel = 0,
			pw = 0.5,
			amp = 0.1,
			out = 0|
			var sig,
			fm = (In.ar(fmIn, 1)),
			pm = fm * (pmLevel * 8);
			fm = fm * fmLevel;
			freq = freq.max(0.01);
			freq = Select.ar(fm < 0, [
				fm.linexp(0.0, 1.0, freq, 20000.0),
				fm.linexp(-1.0, 0.0, 20.0.min(freq), freq)
			]).lag(0.01);
			freq = freq * (freqmod - 1 * 64).midiratio * freqscale.midiratio;
	/*		sig = Pulse.ar(
				freq.max(0.01).min(20000),
				pw.max(0.001).min(0.999),
				amp.lag(0.02)
			);*/
			sig = SquareOS.ar(
				freq.max(0.01).min(20000),
				pm,
				width: pw.max(0.002).min(0.998).lag(0.02),
				oversample: 4,
				mul: (amp * 0.5).lag(0.02)
			);
			Out.ar(out, sig.checkBadValues);
		})
	],
	inputConfig: Dictionary[\fmIn -> \a],
	outputConfig: Dictionary[\out -> \a],
	sync: {|self, source|
		var sourceBus,
		summers = source.modsummers ? Dictionary.new;
		(summers[\freq].notNil).if({
			sourceBus = source.modbusses[\freq][\out];
		}, {
			sourceBus = source.controls[\freq];
		});
		(source.syncedWith.notNil).if({
			source.syncedWith.add(self);
		}, {
			source.syncedWith = List[self];
		});
		self.syncedFrom = source;
		{ s.sync; self.node.map(\freq, sourceBus); }.fork;
		self.modsummers !? {|m|
			var node = m[\freq];
			node !? {|n|
				var mb = self.modbusses[\freqscale];
				node.set(
					\out, mb[\out]
				);
				node.map(\param, self.controls[\freqscale]);
				node.moveBefore(self.node);
			};
		};
		self.updateGuiSync(true);
	},
	unsync: {|self, defIndex|
		(self.syncedFrom.notNil).if({
			var source = self.syncedFrom;

			self.node.map(\freq, self.controls[\freq]);
			self.modsummers !? {|m|
				var node = m[\freqscale];
				node !? {|n|
					var mb = self.modbusses[\freq];
					node.set(
						\out, mb[\out]
					);
					node.map(\param, self.controls[\freq]);
					node.moveBefore(self.node);
				};
			};
			self.syncedFrom = nil;
			self.setParams(\freqscale, 0);
			source.syncedWith !? {|sw|
				var n = sw.select({|v| v.name != self.name });
				source.syncedWith = n;
			};
			self.updateGuiSync(false);
		});
	},
	updateGuiSync: {|self, isSynced|
		self.views !? {|v|
			var params = [\freq, \freqscale],
			dparam = params[isSynced.asInteger];
			{
				var parent = v[dparam][0].parent;
				parent !? {|p|
					(p.bounds.width == 0).if({
						var sparam = params[(isSynced.asInteger - 1).abs],
						sview = v[sparam][0].parent,
						dview = v[dparam][0].parent,
						bounds = sview.bounds;
						dview.bounds = bounds;
						sview.bounds = Rect(0, 0, 0, 0);
						v[\sync] !? {|sy| sy.value_(isSynced.asInteger) };
						v[\range] !? {|r| r.enabled_(isSynced.not) };
						/*(isSynced.not).if({
							v[\freq][0].valueAction_(v[\freq][0].value);
						});*/
					});
				}
			}.defer;
		}
	},
	usePm: false,
	setFmOrPm: {|self, fm = true|
		self.usePm = fm.not;
		self.setParams([\fmLevel, \pmLevel].at(fm.asInteger), 0);
		self.updateGuiFm();
	},
	updateGuiFm: {|self|
		self.views !? {|v|
			var params = [\fmLevel, \pmLevel],
			dparam = params[self.usePm.asInteger];
			{
				var parent = v[dparam][0].parent;
				parent !? {|p|
					(p.bounds.width == 0).if({
						var sparam = params[(self.usePm.asInteger - 1).abs],
						sview = v[sparam][0].parent,
						dview = v[dparam][0].parent,
						bounds = sview.bounds;
						dview.bounds = bounds;
						sview.bounds = Rect(0, 0, 0, 0);
					});
				}
			}.defer;
		}
	},
	handleSync: {|self, param|
		self.syncedWith !? {|sw|
			sw.do({|e|
				e.sync(self);
			});
		};
		self.syncedFrom !? {|sf|
			self.sync(sf);
		};
	},
	customDumpSettings: {|self, o, cb|
		o[\syncedWith] = (self.syncedWith ? List.new).collect({|e| e.name }).asSet.asList;
		o[\syncedFrom] = (self.syncedFrom ? Event.new).name;
		o[\freqSpec] = self.freqSpec;
		o[\usePm] = self.usePm;
		cb.value(o);
	},
	customSetFromSettings: {|self, dict, cb|
		self.freqSpec = dict[\freqSpec] ? \freq;
		self.usePm = dict[\usePm] ? false;
		self.setFmOrPm(self.usePm.not);
		cb.value(dict);
	},
	setSyncFromSettings: {|self, settings, modules|
		var sf = settings[\syncedFrom],
		sw = settings[\syncedWith];
		modules = (modules.isArray).if({ modules }, { [modules] });
		(sf.notNil).if({
			var m = modules.select({|e| e.name == sf }).pop();
			(m.notNil).if({ self.sync(m) }, { self.unsync() });
		}, {
			self.unsync();
			(sw.notNil).if({
				var m = modules.select({|e| sw.includes(e.name) });
				(m.size > 0).if({ self.syncedWith = m }, { self.syncedWith = nil });
			}, {
				self.syncedWith = nil;
			});
		});
	},
	freqSpec: \freq,
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
			["Freq", \freq, self.freqSpec],
			["Pw", \pw, \unipolar],
			["Fm", \fmLevel, \pan],
			["Amp", \amp, \amp],
			["Freq", \freqscale, ControlSpec(-64.0, 64.0)],
			["Pm", \pmLevel, \amp]
		],
		ne = 5,
		width = style.calculateViewWidth(pl, gl, ne, ks * ne),
		height = style.calculateViewHeight(pt, lh, ks + th),
		bs = [["~"], ["|\\"], ["_|"]],
		o = Button(bounds: bw@bh)
		.states_(bs)
		.action_({|v|
			self.switchSynthDef(v.value,
				{ self.handleSync }
			);
		})
		.value_(self.selectedSynthDef ? 0),
		fs,
		view = View(parent, width@height),
		f = view.addFlowLayout(pl@pt, gl@gt),
		sb;

		self.views = Dictionary.new;

		view.decorator_(f);

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
					fs.enabled_(false);
				});
			})
			.value_((self.syncedFrom.notNil).if({ 1 }, { 0 }));
			fs = Button(bounds: bw@bh)
			.states_([["F"], ["L"]])
			.action_({|v|
				var val = v.value,
				spec = (val == 0).if({ \freq }, { \lofreq });
				(spec != self.freqSpec).if({
					var view = self.views[\freq],
					k = view[0];
					self.freqSpec = spec;
					view[1] = spec.asSpec;
					view[0].valueAction_(view[0].value);
				});
			})
			.value_((self.freqSpec != \freq).asInteger)
			.enabled_(self.syncedFrom.isNil);
		});
		View(view, 25@(height - th - lh)).layout_(VLayout(
			o,
			sb,
			fs
		).margins_(0).spacing_(0));
		self.views[\type] = o;
		self.views[\sync] = sb;
		self.views[\range] = fs;
		style.knobRow(view, knobConf, self, ks, true);
		self.views[\pmLevel][2].mouseUpAction_({|v, x, y, mod|
			(mod == 524288).if({
				self.setFmOrPm(self.usePm);
			});
		});
		self.views[\fmLevel][2].mouseUpAction_({|v, x, y, mod|
			(mod == 524288).if({
				self.setFmOrPm(self.usePm);
			});
		});
		self.views[\freqscale][0].parent.bounds = Rect(0, 0, 0, 0);
		self.views[\pmLevel][0].parent.bounds = Rect(0, 0, 0, 0);
		self.updateGuiSync(self.syncedFrom.notNil);
		self.updateGuiFm();
		self.views[\view] = view;
		self.addBypassAction();
		view;
	}
);