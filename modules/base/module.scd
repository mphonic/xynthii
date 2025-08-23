~module = (
	name: 'module',
	synthDef: {},
	outputConfig: Dictionary[\out -> \a],
	defaults: Dictionary.new,
	hasInit: false,
	releaseable: false,
	rateMap: Dictionary[\a -> 'audio', \k -> 'control'],
	create: {|self, name, skipDef = true|
		(self.hasInit).if({
			self;
		}, {
			var o = self.deepCopy;
			o.name = name;
			o.outputConfig = o.outputConfig ? Dictionary[\out -> \a];
			// set up io busses
			o.createIoBusses();
			// set up control and mod busses
			o.createControlBusses();
			// generate defaults from SynthDef
			o.generateDefaults();
			(skipDef.not).if({
				{
					self.sendSynthDefs();
					s.sync;
					o.hasInit = true;
				}.fork;
			}, {
				o.hasInit = true;
			});
			o
		});
	},
	sendSynthDefs: {|self|
		var defs = self.synthDef;
		(defs.isArray.not).if({ defs = [defs] });
		defs.do({|e|
			e.send(s);
		});
	},
	getSynthDef: {|self|
		(self.synthDef.isArray).if({
			self.synthDef[self.selectedSynthDef ? 0]
		}, {
			self.synthDef
		});
	},
	createIoBusses: {|self|
		var rates = self.rateMap,
		i = self.inputConfig ? Dictionary.new,
		o = self.outputConfig ? Dictionary.new,
		io = [Dictionary.new, Dictionary.new];
		[i, o].do({|dict, c|
			dict.keys.do({|key|
				var conf = dict[key];
				io[c][key] = self.getBusFromConfig(conf, 'audio');
			});
		});
		self.inputs = io[0];
		self.outputs = io[1];
	},
	createControlBusses: {|self|
		var c = self.controlConfig ? Dictionary.new,
		m = Dictionary.new, // modbusses
		a = self.getSynthDef().func.argNames,
		o = self.outputs.keys,
		i = self.inputs.keys,
		io = o ++ i;
		a.do({|key|
			((io.includes(key).not)
				.and("^(t_|i_|e_|b_)".matchRegexp(key.asString).not)
			).if({
				var conf = c[key] ? \k;
				c[key] = self.getBusFromConfig(conf);
				m[key] = Dictionary[
					\in -> self.getBusFromConfig(conf),
					\out -> self.getBusFromConfig(conf)
				];
			});
		});
		self.controls = c;
		self.modbusses = m;
	},
	getBusFromConfig: {|self, conf, defaultRate = 'control'|
		var rate, channels, rates = self.rateMap;
		(conf.isArray.not).if({
			channels = 1;
			rate = rates[conf] ? defaultRate;
		}, {
			rate = rates[conf[0]] ? defaultRate;
			channels = conf[1] ? 1;
		});
		(rate == 'audio').if({
			Bus.audio(numChannels: channels);
		}, {
			Bus.control(numChannels: channels);
		});
	},
	generateDefaults: {|self|
		var f = self.getSynthDef().func,
		a = f.argNames,
		d = f.defaultArgs,
		defaults = Dictionary.new;
		a.do({|e, c|
			defaults[e] = d[c];
		});
		self.defaults = defaults;
	},
	generateSynthArgs: {|self, args|
		var a = Dictionary.newFrom(args),
		i = self.inputs,
		o = self.outputs,
		d = self.defaults;
		// set i/o bus args
		[i, o].do({|dict|
			dict.keys.do({|key|
				a[key] = a[key] ? dict[key];
			});
		});
		// set defaults if not present
		d.keys.do({|key|
			a[key] = a[key] ? d[key];
		});
		a;
	},
	go: {|self, args, target, action = 'addToHead'|
		(self.hasInit).if({
			var c = self.controls,
			a = self.generateSynthArgs(args ? []),
			n = Synth(self.getSynthDef().name, a.asPairs, target ? s, action).register;
			// set control busses and map to node
			c.keys.do({|key|
				(a[key].notNil).if({
					c[key].set(a[key]);
				});
				n.map(key, c[key]);
			});
			self.node = n;
			n;
		}, {
			"Error: Module has not been initialized. Run [module].create".postln;
			nil;
		});
	},
	switchSynthDef: {|self, defIndex, cb, synthargs|
		self.selectedSynthDef = defIndex;
		self.replace(cb, Dictionary.newFrom(synthargs ? Array.newClear(1)));
	},
	replace: {|self, cb, synthargs|
		(self.hasInit).if({
			var c = self.controls,
			args = synthargs ? Dictionary.new,
			cond = Condition.new(false),
			count = 0;
			c.keys.do({|key|
				c[key].get({|v|
					args[key] = v;
					count = count + 1;
					(count >= c.size).if({
						cond.test = true;
						cond.signal;
					});
				});
			});
			{
				var a, n,
				m = self.modsummers ? Dictionary.new,
				b = self.modbusses,
				modded = List.new;
				cond.wait;
				a = self.generateSynthArgs(args);
				n = Synth.replace(self.node, self.getSynthDef().name, a.asPairs, true).register;
				s.sync;
				m.keys.do({|key|
					modded.add(key);
					n.map(key, b[key][\out]);
				});
				c.keys
				.select({|key| modded.includes(key).not })
				.do({|key|
					n.map(key, c[key]);
				});
				self.node = n;
				cb.value(self.node);
			}.fork;
		}, {
			"Error: Module has not been initialized. Run [module].create".postln;
		});
	},
	setParams: {|...args|
		var self = args.removeAt(0),
		a = Dictionary.newFrom(args);
		a.keys.do({|key|
			var c = self.controls[key];
			(c.notNil).if({
				var chan = c.numChannels;
				(chan < 2).if({
					c.set(a[key]);
				},
				{
					c.setn(a[key]);
				});
			}, {
				self.node.set(key, a[key]);
			});
			(self.keepGuiUpdated).if({
				{ self.updateView(key, a[key]) }.defer;
			});
		});
	},
	toggleBypass: {|self|
		var vs = self.views,
		v = vs !? {|x| x[\view] },
		bp = self.node.isRunning;
		{
			v !? {|x|
				x.children.do({|c| c.enabled_(bp.not); });
			};
		}.defer;
		(bp).if({
			self.node.run(false);
		}, {
			self.node.run(true);
		});
		(bp.and(self.addPatchOnBypass)).if({
			var inchans = self[\inputs][\in].numChannels,
			outchans = self[\outputs][\out].numChannels;
			{
				self.bypassNode = self.playBypass;
				s.sync;
				(self.bypassNode.isNil).if({
					self.bypassNode = Synth.after(self.node,
						"bypass" ++ (inchans ? 1).asString
						++ (outchans ? 1).asString,
						[
							\in, self[\inputs][\in],
							\out, self[\outputs][\out]
						]
					);
				})
			}.fork;
		}, {
			self.bypassNode.free;
		});
	},
	lastClick: 0,
	addBypassAction: {|self, addPatch = false|
		var v = self.views[\view];
		v.children.do({|e| e.enabled_(self.node.isRunning) });
		self.addPatchOnBypass = addPatch;
		v.mouseUpAction_({
			var t = SystemClock.seconds,
			diff = t - self.lastClick;
			(diff < 0.3).if({
				var b = self.toggleBypass();

			});
			self.lastClick = t;
		});
	},
	end: {|self, kill = false|
		(self.releaseable.asBoolean && kill.not).if(
			{ self.node.release; },
			{ self.node.free }
		);
		// TO-DO: What if we want to wait for the release to end?
		self.unpatchAll();
		[self.inputs, self.outputs, self.controls].do({|dict|
			dict.values.do({|bus| bus.free; });
		});
		self.modbusses.values.do({|dict|
			dict.values.do({|d| d.free });
		});
		self.hasInit = false;
	},
	keepGuiUpdated: true,
	updateView: {|self, key, value|
		var views = self.views ? Dictionary.new,
		gui = views[key];
		(gui.notNil).if({
			var view, spec, text, sv;
			(gui.isArray).if({
				# view, spec, text = gui;
			}, {
				view = gui;
			});
			{
				(spec.notNil).if({
					sv = spec.unmap(value);
				}, {
					sv = value;
				});
				view.value_(sv);
				text !? {|t| t.value_(value.round(0.001)) };
			}.defer;
		});
	},
	updateGui: {|self|
		var keys = self[\controls].keys
		.select({|key| self.views[key].notNil });

		keys.do({|key|
			self[\controls][key].get({|v|
				{
					self.updateView(key, v);
				}.defer;
			});
		});
	},
	syncGui: {|self|
		(self.guiTask.notNil).if({
			(self.guiTask.isPlaying.not).if({ self.guiTask.play });
		}, {
			(self.views.notNil).if({
				var keys = self[\controls].keys
				.select({|key| self.views[key].notNil });

				self.guiTask = Task({
					loop {
						keys.do({|key|
							self[\controls][key].get({|v|
								{
									self.updateView(key, v);
								}.defer;
							});
						});
						0.09.wait;
					}
				});
				self.guiTask.play;
			});
		});
	},
	stopSyncGui: {|self|
		self.guiTask !? {|v| v.stop };
	},
	dumpControls: {|self|
		self.controls.keys.asArray;
	},
	dumpSettings: {|self, cb|
		var count = 0,
		c = self.controls,
		o = Dictionary.new,
		cond = Condition.new(false);
		o[\selectedSynthDef] = self.selectedSynthDef;
		o[\viewCcs] = self.views !? {|v| v[\ccs] };
		c.keys.do({|key|
			var chan = c[key].numChannels;
			(chan < 2).if({
				c[key].get({|v|
					o[key] = v;
					count = count + 1;
					(count >= c.size).if({
						cond.test = true;
						cond.signal;
					});
				});
			}, {
				c[key].getn(chan, {|v|
					o[key] = v;
					count = count + 1;
					(count >= c.size).if({
						cond.test = true;
						cond.signal;
					});
				});
			});
		});
		{
			cond.wait;
			o[\bypassed] = self.node.isRunning.not;
			(self.customDumpSettings(o, cb).isNil).if({
				cb.value(o);
			});
		}.fork;
	},
	saveSettings: {|self, path, cb|
		self.dumpSettings({|v|
			v.writeTextArchive(path);
			cb.value(v);
		});
	},
	setFromSettings: {|self, dict, cb|
		var c = self.controls,
		bp = self.node.isRunning.not;

		{
			dict.keys.do({|key|
				var b = c[key];
				(b.notNil).if({
					(b.numChannels < 2).if({
						b.set(dict[key]);
					}, {
						b.setn(dict[key]);
					});
				});
			});
			s.sync;
			(dict[\selectedSynthDef] != self.selectedSynthDef).if({
				self.switchSynthDef(dict[\selectedSynthDef]);
			});
		}.fork;
		(dict[\bypassed].asBoolean != bp).if({ self.toggleBypass() });
		self.viewCcs = dict[\viewCcs];
		(self.customSetFromSettings(dict, cb).isNil).if({
			cb.value(dict);
		});
	},
	loadSettings: {|self, path, cb|
		var settings = Object.readTextArchive(path);
		self.setFromSettings(settings, cb);
	}
);