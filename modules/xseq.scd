(~module.isNil).if({
	(Document.current.dir ++ "/base/module.scd").loadPaths;
});

~xSeq = (
	parent: ~module,
	synthDef: SynthDef(\xSeq, {|
		pitch = 0,
		velocity = 0,
		tempo = 4,
		step = 0,
		t_trig = 0,
		pOut = 12,
		vOut = 13,
		pkOut = 32,
		vkOut = 33,
		tkOut = 34|
		var p = pitch,
		v = velocity;
		SendReply.ar(K2A.ar(t_trig), '/dfamseq', [step, pitch, velocity]);
		Out.ar(pOut, K2A.ar(p));
		Out.ar(vOut, K2A.ar(v));
		Out.kr(pkOut, p);
		Out.kr(vkOut, v);
		Out.kr(tkOut, tempo);
	}),
	outputConfig: Dictionary[
		\pOut -> \a,
		\vOut -> \a,
		\pkOut -> \k,
		\vkOut -> \k,
		\tkOut -> \k
	],
	steps: 16,
	lastStep: 16,
	pitches: Array.fill(16, 0),
	velocities: Array.fill(16, 0),
	onRatio: 0.5,
	setNumSteps: {|self, steps|
		(steps != self.steps).if({
			self.steps = steps;
			self.lastStep = steps;
			self.pitches = Array.fill(steps, {|c| self.pitches.clipAt(c) });
			self.velocities = Array.fill(steps, {|c| self.velocities.clipAt(c) });
		});
	},
	currentStep: 0,
	previousStep: 0,
	isSeqPlaying: 0,
	tempo: 0.25,
	runningTempo: 0.25,
	velocityToTrigMin: -1.0,
	startTasks: {|self|
		(self.seqTask.isNil).if({ self.createSeqTask() });
		self.seqTask.start;
	},
	pauseTasks: {|self|
		(self.seqTask.isNil).if({ self.createSeqTask() });
		self.seqTask.pause;
	},
	createSeqTask: {|self|
		var cond = Condition(false);
		self.seqTask = Task({
			var start = 0, end = 0, diff;
			loop {
				var count = 0,
				cur = self.currentStep,
				prev = self.previousStep;

				self.trigger();
				(self.views.notNil).if({
					self.updateActiveStepView(prev, cur);
				});

				start = SystemClock.seconds;
				s.sync;
				self[\outputs][\tkOut].get({|v|
					self.runningTempo = (v.notNil.and(v > 0)).if({
						v.reciprocal;
					}, {
						0.25;
					});
					cond.test = true;
					cond.signal;
				});
				cond.wait;
				end = SystemClock.seconds;
				diff = end - start;
				(self.runningTempo < diff).if({
					["seq late", end - start].postln;
				});
				(self.runningTempo - diff * self.onRatio).max(0).wait;
				self.trigFunc(0);
				(self.runningTempo - diff * (1 - self.onRatio)).max(0).wait;
				cond.test = false;
				cond.signal;
				self.previousStep = self.currentStep;
				self.currentStep = self.currentStep + 1 % self.lastStep;
			}
		}, SystemClock)
	},
	trigger: {|self|
		var step = self.currentStep,
		v = self.velocities[step];

		self[\controls][\pitch].set(self.pitches[step]);
		self[\controls][\velocity].set(v);
		self.node.set(\t_trig, 1);
		((v >= self.velocityToTrigMin)
			.or(self.seqTask.isPlaying.not)).if({
			self.trigFunc(1);
		});
	},
	setTrigFunc: {|self, trigFunc|
		self.trigFunc = trigFunc;
	},
	stopOnSettingsChange: false,
	resetOnSettingsChange: false,
	stopAndResetOnSettingsChange: {|self, b|
		self.stopOnSettingsChange = b;
		self.resetOnSettingsChange = b;
	},
	customDumpSettings: {|self, dict, cb|
		dict[\play] = self.isSeqPlaying;
		dict[\p] = self.pitches;
		dict[\v] = self.velocities;
		dict[\steps] = self.steps;
		dict[\lastStep] = self.lastStep;
		dict[\on] = self.onRatio;
		cb.value(dict);
	},
	customSetFromSettings: {|self, dict, cb|
		self.isSeqPlaying = dict[\play];
		self.tempo = dict[\tempo].reciprocal;
		self.pitches = dict[\p];
		self.velocities = dict[\v];
		self.onRatio = dict[\on];
		self.setNumSteps(dict[\steps]);
		self.lastStep = dict[\lastStep] ? dict[\steps];
		(self.stopOnSettingsChange).if(
			{ self.stopSeq(); },
			(self.isSeqPlaying > 0).if({
				self.startSeq(self.resetOnSettingsChange ? false);
			}, {
				self.stopSeq();
			});
		);
		(self.resetOnSettingsChange).if({ self.resetSeq(); });
		self.setParams(
			\pitch, self.pitches[self.currentStep ? 0],
			\velocity, self.velocities[self.currentStep ? 0]
		);
		cb.value(dict);
	},
	startSeq: {|self, andReset = false|
		self.currentStep = (andReset).if({
			self.resetSeq();
			0
		}, { self.currentStep });
		(self.seqTask.isPlaying.not).if({ self.startTasks(); });
		self.setParams(\play, 1);
	},
	stopSeq: {|self|
		self.pauseTasks();
		self.setParams(\play, 0);
		self.trigFunc(0);
	},
	resetSeq: {|self|
		var gui = self.views,
		prev = self.currentStep ? 0;
		self.currentStep = 0;
		self.previousStep = 0;
		(gui.notNil
			.and(self.keepGuiUpdated
				.and(prev > 0))).if({
			self.updateActiveStepView(prev, 0);
		});
		self.seqTask.reset;
	},
	advanceSeq: {|self|
		var gui = self.views;
		self.previousStep = self.currentStep;
		self.currentStep = self.currentStep + 1 % self.steps;
		(gui.notNil
			.and(self.keepGuiUpdated)).if({
			var prev = self.previousStep,
			cur = self.currentStep;
			self.updateActiveStepView(prev, cur);
		});
	},
	updateActiveStepView: {|self, prev, cur|
		var gui = self.views;
		{
			gui[\v][prev][0].background_(self.offColor);
			gui[\p][prev][0].background_(self.offColor);
			gui[\v][cur][0].background_(self.onColor);
			gui[\p][cur][0].background_(self.onColor);
		}.defer;
	},
	onColor: Color(0.75,0.7,0.7),
	offColor: Color(0.42745098039216, 0.42745098039216, 0.42745098039216),
	makeGui: {|self, parent, styles|
		var style = styles ? Event.new,
		ks = style.knobSize ? 50,
		sks = style.smallKnobSize ? 25,
		pl = style.paddingLeft ? 20,
		pt = style.paddingTop ? 20,
		gl = style.gapLeft ? 4,
		gt = style.gapRight ? 4,
		lh = style.lineHeight ? 11,
		bw = style.toggleButtonWidth ? 50,
		bh = style.toggleButtonHeight ? 25,
		tSpec = ControlSpec(0.5, 20, \exp),
		r,
		tb,
		p,
		kwidth = self.steps * (sks * 1.525) + (self.steps * gl) + (pl * 2),
		width = ks * 3.25 + (bw * 2.25) + (pl * 2) + (6 * gl) + kwidth,
		view = View(parent, 950@parent.bounds.height),
		f = view.addFlowLayout(pl@pt, gl@gt),
		tview,
		td,
		kview,
		kd,
		spec = \pan.asSpec,
		offColor = self.offColor,
		onColor = self.onColor;

		self.views = Dictionary.new;
	/*	StaticText(view).string_(self.name).fixedWidth_(ks);
		f.nextLine;*/
		style.knobRow(view, [
			["Tempo", \tempo, tSpec],
			["On", \on, \unipolar],
			["Steps", \lastStep, ControlSpec(1, self.steps, \lin, 1.0)]
		], self, ks, true);
		self.views[\on][0].action_({|v|
			self.onRatio = v.value;
			self.views[\on][2].value_(v.value);
		})
		.valueAction_(self.onRatio);
		self.views[\lastStep][0].action_({|v|
			var val = self.views[\lastStep][1].map(v.value);
			self.lastStep = val;
			self.views[\lastStep][2].value_(val);
		})
		.valueAction_(self.views[\lastStep][1].unmap(self.lastStep ? self.steps));
		tview = View(view, (bw + (pl * 2))@view.bounds.height);
		td = tview.addFlowLayout(pl@pt, 0@0);
		tb = Button(tview, bw@bh)
		.states_([["Trigger"]])
		.action_({
			self.trigger();
			{
				(self.onRatio * self.runningTempo).wait;
				self.trigFunc(0);
			}.fork;
		});
		p = Button(tview, bw@bh)
		.states_([["Play"], ["Stop"]])
		.action_({|v|
			(v.value == 0).if({ self.stopSeq() }, { self.startSeq() });
		})
		.value_(self.isSeqPlaying);
		r = Button(tview, bw@bh)
		.states_([["Reset"]])
		.action_({|v|
			self.views[\ind].do({|e| e.background_(offColor) });
			self.resetSeq();
		});
		Button(tview, bw@bh)
		.states_([["Adv"]])
		.action_({|v|
			self.advanceSeq();
		});

		self.views[\reset] = r;
		self.views[\play] = p;

		kview = View(view, kwidth@view.bounds.height);
		kd = kview.addFlowLayout(pl@pt, 0@0);

		self.views[\p] = Array.newClear(self.steps);
		self.views[\v] = Array.newClear(self.steps);

		[self.views[\p], self.views[\v]].do({|a, i|
			var params = [\pitch, \velocity],
			properties = Dictionary[\pitch -> \pitches, \velocity -> \velocities],
			param = params[i],
			prop = properties[param],
			labels = ["Pitch", "Vel"];
			StaticText(kview, 40@(lh + 4)).string_(labels[i]);
			kd.nextLine;
			self.steps.do({|c|
				a[c] = [
					Knob(kview)
					.action_({|v|
						var val = spec.map(v.value);
						(c == self.currentStep).if({
							self.setParams(param, val);
						});
						self[prop][c] = val;
					})
					.value_(spec.unmap(self[prop][c]))
					.fixedSize_(sks@sks)
					.background_((c == self.currentStep).if(
						{ onColor },
						{ offColor }
					)),
					spec];
			});
			kd.nextLine;
		});

		self.views[\view] = view;
		view;
	},
	updateView: {|self, key, value|
		var views = self.views ? Dictionary.new,
		gui = views[key];
		(gui.notNil).if({
			([\pitch, \velocity].includes(key.asSymbol).not).if({
				var view = (gui.isArray).if({ gui[0] }, { gui }),
				spec = (gui.isArray).if({ gui[1] }, { nil });
				(spec.notNil).if({
					view.value_(spec.unmap(value));
				}, {
					view.value_(value);
				});
			}, {
				var spec = \pan.asSpec;
				gui[self.currentStep][0].value_(spec.unmap(e));
			});
		});
	}
);
