(
~makeXynthii = {|cb, outputBus = 0|
	var dfam;
	s.waitForBoot({
		dfam = Environment.make({
			var docDir = Document.current.dir,
			base = [
				"modules/base/module",
				"modules/base/controlextension",
				"modules/base/syncableenvelope",
				"patching/base/patchbay",
				"styles/defaults",
				"styles/helperExtension"
			],
			modules = [
				"modules/xosc",
				"modules/noise",
				"modules/asr",
				"modules/input",
				"modules/xfilt",
				"modules/xring",
				"modules/xdelay",
				"modules/xverb",
				"modules/envelope",
				"modules/vca",
				"modules/mono2stereo",
				"modules/tempo",
				"modules/multilfo",
				"modules/xseq",
				"modules/xy"
			],
			patching = [
				"patching/synthdefs",
				"patching/audiopatchbay",
				"patching/audiopatchpinmatrixgui",
				"patching/controlpatchbay",
				"patching/controlpatchmenu"
			],
			groups = [
				\outputs,
				\effects,
				\mixers,
				\oscs,
				\envs
			],
			outputs,
			effects,
			mixers,
			oscs,
			envs,
			trigEnv;

			~sortedModules = List.new;
			// s.freeAll;

			"Creating modules...".postln;
			[base, modules, patching].do({|e|
				e.do({|v|
					(docDir ++ "/" ++ v ++ ".scd").loadPaths;
				});
			});

			~sendPatchDefs.value;

			[
				~xosc,
				~noise,
				~asr,
				~input,
				~xfilt,
				~xring,
				~xdelay,
				~xverb,
				~envelope,
				~vca,
				~mono2Stereo,
				~tempoclocker,
				~multilfo,
				~xSeq,
				~xy
			].do({|e, c|
				(e.isNil).if({ c.postln; }); // debug
				e.sendSynthDefs();
			});

			~osc1 = ~xosc.create('O1');
			~osc2 = ~xosc.create('O2');
			~osc3 = ~xosc.create('O3');
			~noise = ~noise.create('N');
			~in1 = ~input.create('IN1');
			~in2 = ~input.create('IN2');

			~osc2.selectedSynthDef = 1;
			~osc3.selectedSynthDef = 1;

			~trap = ~asr.create('E1');
			~env2 = ~envelope.create('E2');
			~env3 = ~envelope.create('E3');
			~clocker = ~tempoclocker.create('CL');
			~lfo1 = ~multilfo.create('LF1');
			~lfo2 = ~multilfo.create('LF2');
			~lfo3 = ~multilfo.create('LF3');
			~lfo4 = ~multilfo.create('LF4');
			~joy = ~xy.create('XY');
			~seq = ~xSeq.create('SEQ');

			~filt = ~xfilt.create('F');
			~ring = ~xring.create('RNG');
			~del = ~xdelay.create('DEL');
			~verb = ~xverb.create('REV');

			~vca1 = ~vca.create('V1');
			~vca2 = ~vca.create('V2');

			~out1 = ~mono2Stereo.create('OU1');
			~out2 = ~mono2Stereo.create('OU2');

			s.sync;
			"Modules created".postln;

			~groups = (
				main: Group.new
			);

			groups.do({|e|
				~groups[e] = Group.new(~groups.main);
			});

			s.sync;

			outputs = (
				modules: [~out2, ~out1, ~verb, ~del],
				defaults: [[\out, outputBus], [\out, outputBus]],
				g: ~groups.outputs
			);
			effects = (
				modules: [~filt, ~ring],
				g: ~groups.effects
			);
			mixers = (
				modules: [~vca2, ~vca1],
				g: ~groups.mixers
			);
			oscs = (
				modules: [~osc1, ~osc2, ~osc3, ~noise, ~in1, ~in2],
				g: ~groups.oscs
			);
			envs = (
				modules: [~env3, ~env2, ~trap, ~lfo1, ~lfo2, ~lfo3, ~lfo4, ~seq, ~clocker, ~joy],
				g: ~groups.envs
			);
			"Starting synths...".postln;
			[outputs, effects, mixers, oscs, envs].do({|e|
				(e.notNil).if({
					e.modules.do({|m, c|
						var a = e.defaults ? Array.new;
						m.go(a[c], e.g);
					});
					~sortedModules = ~sortedModules ++ e.modules;
				});
			});

			s.sync;
			"Synths started".postln;
			// default settings
			trigEnv = ~trap; // we do this for trigFunc closure
			// trigger func for "outside" use
			~trigger = {|self, v| trigEnv.setParams(\gate, v); };
			~seq.setTrigFunc({|self, msg|
				trigEnv.setParams(\gate, msg);
			});

			~env2.setEnv(Env([0, 1.0, 0.5, 0.5, 0.0], [0.01, 0.3, 0.5, 1.0].normalizeSum, [-4, -4, -4, -4], 3));
			~env3.setEnv(Env([0, 1.0, 0.5, 0.5, 0.0], [0.01, 0.3, 0.5, 1.0].normalizeSum, [-4, -4, -4, -4], 3));
			~in2.setParams(\source, 1);
			[~lfo1, ~lfo2, ~lfo3, ~lfo4].do({|e|
				e[\controls][\gate] = ~trap[\controls][\gate];
			});
			// add patch from clk to trapezoid
			~clk2trap = Synth.before(~trap.node, \kpatch1, [
				\in, ~clocker[\outputs][\out],
				\out, ~trap[\controls][\gate],
				\mul, 0
			]).register;
			~clk2trap.run(false);

			~patcher = ~audioPatchbay.create(~sortedModules);
			~modPod = ~controlPatchbay.create(~sortedModules, envs.modules);
			s.sync;

			~makeGui = {|self, bounds, keepUpdated, knobMode = \vert|
				var w = Window("xynthii", bounds ? Rect(10, Window.screenBounds.height - 830, 1448, 755)),
				pl = self.style.paddingLeft ? 20,
				pt = self.style.paddingTop ? 20,
				gl = self.style.gapLeft ? 4,
				gt = self.style.gapTop ? 4,
				f = w.addFlowLayout(pl@pt, gl@gt),
				mc = View(w, w.bounds), // main container
				mf = mc.addFlowLayout(0@0, 0@0),

				cv = View(mc, 1070@(w.bounds.height - 270)), // controls container
				cf = cv.addFlowLayout(0@0, gl@gt),

				dv = View(cv, cv.bounds.width@28), // l / s buttons
				df = dv.addFlowLayout(0@0, gl@gt),

				pv = View(mc, 350@(cv.bounds.height)), // patch container
				pf = pv.addFlowLayout(0@0, 0@0),

				sv = View(mc, mc.bounds.width@150), // lower container
				sf = sv.addFlowLayout(0@0, 0@0),

				mpv = View(mc, mc.bounds.width@150), // modpod container
				mpf = mpv.addFlowLayout(0@0, 0@0),

				ov = View(cv, 285@(cv.bounds.height)), // osc container
				of = ov.addFlowLayout(0@0, 0@0),

				fv = View(cv, 371@(cv.bounds.height)), // filt container
				ff = fv.addFlowLayout(0@0, 0@0),

				ouv = View(cv, 410@(cv.bounds.height)), // outputs container
				ouf = ouv.addFlowLayout(0@0, 0@0);

				knobMode = knobMode ? self.knobMode ? \vert;
				keepUpdated = keepUpdated ? self.keepGuiUpdated ? true;
				Knob.defaultMode_(knobMode);

				// Donate please
				Button(dv, 75@20)
				.states_([["Donate"]])
				.action_({
					"open https://github.com/mphonic/SC-DFAM/blob/master/README.md#donate".unixCmd();
"explorer https://github.com/mphonic/SC-DFAM/blob/master/README.md#donate".unixCmd();
				});

				// load / save
				Button(dv, 20@20)
				.states_([["L"]])
				.action_({
					FileDialog({|p|
						self.loadSettings(p[0]);
					}, nil, 1, 0, path: "presets");
				});
				Button(dv, 20@20)
				.states_([["S"]])
				.action_({
					FileDialog({|p|
						self.saveSettings(p[0]);
					}, nil, 1, 1, path: "presets");
				});
				Button(dv, 20@20)
				.states_([["R"], ["O", Color.white, Color.red]])
				.action_({|v|
					(v.value == 1).if({
						s.record(
							Document.current.dir ++
							"/recordings/xynthii_" ++
							Date.getDate().stamp ++
							".aiff"
						);
					}, {
						s.stopRecording;
					});
				});
				self.presetNameView = StaticText(dv, ((self.presetName ? "default").size * 5 + 35)@20)
				.string_("Patch: " ++ (self.presetName ? "default"))
				.align_(\right);
				StaticText(dv, 500@20).string_("  <xynthii>");

				self.osc1.makeGui(ov, self.style);
				of.nextLine;
				self.osc2.makeGui(ov, self.style, true, self.osc1);
				of.nextLine;
				self.osc3.makeGui(ov, self.style, true, self.osc1);
				of.nextLine;
				self.noise.makeGui(ov, self.style);
				self.in1.makeGui(ov, self.style);
				self.in2.makeGui(ov, self.style);

				self.filt.makeGui(fv, self.style);
				self.ring.makeGui(fv, self.style);
				ff.nextLine;

				self.trap.makeGui(fv, self.style);
				View(fv, 20@107).layout_(VLayout(
					Button()
					.states_([["<"], ["x"]])
					.action_({|v|
						(v.value == 0).if({
							self.clk2trap.set(\mul, 0, \add, 0);
							self.clk2trap.run(false);
						}, {
							self.clk2trap.run(true);
							self.clk2trap.set(\mul, 0.5, \add, 0.5);
						});
					})
					.value_(self.clk2trap.isRunning)
				).margins_(0).spacing_(0));
				self.clocker.makeGui(fv, self.style);
				ff.nextLine;
				self.env2.makeGui(fv, self.style, true, self.trap);

				self.del.makeGui(ouv, self.style);
				self.verb.makeGui(ouv, self.style);
				ouf.nextLine;
				self.out1.makeGui(ouv, self.style);
				self.out2.makeGui(ouv, self.style);
				ouf.nextLine;
				View(ouv, 33@107).layout_(VLayout(
					[nil, stretch: 1],
					Button()
					.states_([[">"]])
					.action_({|v|
						{
							self.env2.dumpSettings({|val|
								self.env3.setFromSettings(val);
							});
						}.defer;
					}).fixedWidth_(20),
					Button()
					.states_([["<"]])
					.action_({|v|
						{
							self.env3.dumpSettings({|val|
								self.env2.setFromSettings(val);
							});
						}.defer;
					}).fixedWidth_(20)
				).margins_(0));
				self.env3.makeGui(ouv, self.style, true, self.trap);

				self.patcher.makeGui(pv, nil, ["OU1", "OU2"],
					[
						"O1 fm", "O2 fm", "O3 fm",
						"V1 env", "V1", "V2 env", "V2",
						"RNG car", "RNG mod", "F", "F fm",
						"DEL", "REV l", "REV r", "OU1", "OU2"
					],
					[
						"SEQ p", "SEQ v",
						"O1", "O2", "O3", "N",
						"IN1", "IN2",
						"F", "V1", "V2",
						"E1", "E2", "E3", "RNG",
						"DEL", "REV l", "REV r"
					]
				);

				self.joy.makeGui(sv, self.style);
				self.lfo1.makeGui(sv, self.style);
				self.lfo2.makeGui(sv, self.style);
				self.lfo3.makeGui(sv, self.style);
				self.lfo4.makeGui(sv, self.style);

				self.modPod.makeGui(mpv, 11, [
					"E1 gate",
					"E2 gate",
					"E3 gate",
					"O1 freqscale",
					"O1 freqmod",
					"O2 freqmod",
					"O3 freqmod",
					"F ffreqmul",
					"IN1 source",
					"IN2 source",
					"OU1 pan",
					"OU2 pan",
					"LF1 gate",
					"LF2 gate",
					"LF3 gate",
					"SEQ pitch",
					"SEQ velocity",
					"SEQ step",
					"XY x",
					"XY y"
				], ["SEQ tk"],
				self.style
				);

				self.seq2OscGui(sv, self.style);
				self.seq2OscGui(sv, self.style, true);

				self.seq.makeGui(sv, self.style);

				self.guiWindow = w;

				w.onClose_({
					self.clearAllViewCcs();
				});

				CmdPeriod.doOnce {
					w.close;
					MIDIdef.freeAll;
				};
				w.view.palette_(QPalette.dark);
				self.sortedModules.do({|e|
					e.keepGuiUpdated = keepUpdated;
				});
				self.keepGuiUpdated = keepUpdated;
				self.updateViewCcs();
				w.front;
			};

			~seq2OscGui = {|self, view, style, vel = false|
				var t = ["pk", "vk"][vel.asInteger],
				n = ["P2Osc", "V2Osc"][vel.asInteger],
				out = "SEQ " ++ t,
				isOn = [
					self.modPod.getPatchById(
						out,
						out ++ "2O1 freqmod"
					).notNil,
					self.modPod.getPatchById(
						out,
						out ++ "2O2 freqmod"
					).notNil,
					self.modPod.getPatchById(
						out,
						out ++ "2O3 freqmod"
					).notNil
				],
				allOn = isOn.indexOf(false).isNil,
				butts = Array.fill(3, {|c|
					var o = (c + 1).asString;
					Button()
					.states_([
						["O" ++ o ++ " off"],
						["O" ++ o ++ " on"]
					])
					.action_({|v|
						(v.value == 0).if({
							self.modPod.unpatch(out, out ++ "2O" ++ o ++ " freqmod");
						}, {
							(self.modPod.getPatchById(
								out, out ++ "2O" ++ o ++ " freqmod").isNil).if({
								self.modPod.patch(out, "O" ++ o ++ " freqmod", 1);
							});
						})
					})
					.value_(isOn[c].and(allOn.not).asInteger)
				});

				View(view, 40@100).layout_(VLayout(
					[nil, stretch: 1],
					[StaticText().string_(n), align: \top],
					[butts[0], align: \bottom],
					[butts[1], align: \bottom],
					[butts[2], align: \bottom],
					[
						Button()
						.states_([["All off"], ["All on"]])
						.action_({|v|
							(v.value == 0).if({
								3.do({|e, c|
									var o = e + 1;
									self.modPod.unpatch(out,
										out ++ "2O" ++ o ++ " freqmod");
									butts[c]
									.value_(0)
									.enabled_(true);
								});
							}, {
								3.do({|e, c|
									var o = e + 1,
									id = out ++ "2O" ++ o ++ " freqmod",
									in = "O" ++ o ++ " freqmod";
									(self.modPod.getPatchById(
										out,
										id).isNil).if({
										self.modPod.patch(out, in, 1);
									});
									butts[c].enabled_(false);
								});
							});
						})
						.value_(allOn.asInteger)
						, align: \bottom]
				).margins_(0).spacing_(0));
				(allOn).if({
					butts.do({|e| e.enabled_(false) });
				});
			};

			~updateViewCcs = {|self|
				self.sortedModules.do({|e|
					// clear any existing
					e.views !? {|vs|
						vs.keys.do({|key|
							MIDIdef((e.name ++ key).asSymbol).free;
						});
					};
					(e.viewCcs.notNil).if({
						var ccs = e.viewCcs;
						ccs.keys.do({|key|
							var k = e.views[key];
							(k.isArray).if({ k = k[0] });
							MIDIdef.cc((e.name ++ key).asSymbol, {|val, num|
								{
									k.valueAction_(val.linlin(0, 127, 0, 1.0));
								}.defer;
							}, ccs[key]);
						});
					});
				});
			};

			~clearAllViewCcs = {|self|
				self.sortedModules.do({|e|
					e.views !? {|vs|
						vs.keys.do({|key|
							MIDIdef((e.name ++ key).asSymbol).free;
						});
					};
				});
			};

			~dumpSettings = {|self, cb|
				var set = Dictionary.new,
				modules = self.sortedModules,
				mc = Condition.new(false),
				pc = Condition.new(false),
				ms = 0,
				ps = 0,
				size = modules.size;
				// set[\midi] = MIDIdef.all;
				modules.do({|m, c|
					m.dumpSettings({|v|
						set[m.name] = v;
						ms = ms + 1;
						(ms >= size).if({
							mc.test = true;
							mc.signal;
						});
					});
				});
				self.patcher.dumpSettings({|v|
					set[\patcher] = v;
					ps = ps + 1;
					(ps >= 2).if({
						pc.test = true;
						pc.signal;
					});
				});
				self.modPod.dumpSettings({|v|
					set[\modPod] = v;
					ps = ps + 1;
					(ps >= 2).if({
						pc.test = true;
						pc.signal;
					});
				});
				{
					mc.wait;
					pc.wait;
					set[\clk2trap] = self.clk2trap.isRunning;
					cb.value(set);
				}.fork;
			};

			~setFromSettings = {|self, settings, name = "default"|
				self.patcher.setFromSettings(
					settings[\patcher] ? Dictionary.new
				);
				(settings[\clk2trap].asBoolean).if({
					self.clk2trap.run(true);
					self.clk2trap.set(\mul, 0.5, \add, 0.5);
				}, {
					self.clk2trap.run(false);
				});
				self.presetName = name;
				settings.keys.do({|key|
					var module = self.sortedModules.select({|m|
						m.name == key
					});
					(module.size > 0).if({
						module[0].setFromSettings(settings[key]);
					});
				});
				// orchestrate syncs mods and gui
				{
					s.sync;
					self.osc1.setSyncFromSettings(
						settings[self.osc1.name] ? Dictionary.new,
						[self.osc2, self.osc3]
					);
					s.sync;
					self.osc2.setSyncFromSettings(
						settings[self.osc2.name] ? Dictionary.new,
						self.osc1
					);
					s.sync;
					self.osc3.setSyncFromSettings(
						settings[self.osc3.name] ? Dictionary.new,
						self.osc1
					);
					s.sync;
					self.trap.setSyncFromSettings(
						settings[self.trap.name] ? Dictionary.new,
						[self.env2, self.env3]
					);
					s.sync;
					self.env2.setSyncFromSettings(
						settings[self.env2.name] ? Dictionary.new,
						self.trap
					);
					s.sync;
					self.env3.setSyncFromSettings(
						settings[self.env3.name] ? Dictionary.new,
						self.trap
					);
					s.sync;
					self.modPod.setFromSettings(
						settings[\modPod] ? Dictionary.new
					);
					s.sync;
					// only the BEST reverb :)
					(s.sampleRate % 48000 == 0).if({
						self.verb.switchSynthDef(1);
					}, {
						self.verb.switchSynthDef(0);
					});
					(self.guiWindow.notNil).if({
						s.sync;
						{
							var b = self.guiWindow.bounds;
							self.guiWindow.close;
							self.makeGui(b);
							self.presetNameView.string_("Patch: " ++ name);
						}.defer;
					});
				}.fork;
			};

			~saveSettings = {|self, path, cb|
				self.dumpSettings({|v|
					v.writeTextArchive(path);
					{
						self.presetNameView.string_("Patch: " ++ path.split($/).pop());
					}.defer;
					("Settings saved to " ++ path).postln;
					cb.value(v);
				});
			};

			~loadSettings = {|self, path, cb|
				var settings = Object.readTextArchive(path);
				(settings.notNil).if({
					self.setFromSettings(settings, path.split($/).pop());
					cb.value(settings);
				}, {
					"Settings not found".postln;
				});
			};

			"Loading settings...".postln;
		});

		dfam.know = true;
		dfam.loadSettings(Document.current.dir ++ "/presets/default", {
			"Settings loaded.".postln;
			"Ready to go.".postln;
		});
		cb.value(dfam);
	});
}
)