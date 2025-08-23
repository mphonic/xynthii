(~syncableEnvelope.isNil).if({
	(Document.current.dir ++ "/base/syncableenvelope.scd").loadPaths;
});
~envelope = (
	parent: ~syncableEnvelope,
	synthDef: (2..16).collect({|c|
		SynthDef(\env ++ c, {|
			dur = 1,
			out = 0,
			kOut = 33,
			gate = 0,
			gatemod = 1|
			var env, envctl;
			env = Env(
				Array.fill(c, 1),
				Array.fill(c - 1, 1 / c),
				Array.fill(c - 1, -4),
				c - 2,
				nil
			);
			envctl = EnvGen.ar(
				\e_env.kr(env.asArray),
				(gatemod - 1).max(0) + gate,
				timeScale: dur
			);
			Out.kr(kOut, A2K.kr(envctl) * 2 - 1);
			Out.ar(out, envctl)
		}).send(s);
	}),
	outputConfig: Dictionary[\out -> \a, \kOut -> \k],
	setEnv: {|self, env|
		var cur = self.env;
		(env.curves.size < env.times.size).if({
			env.curves = Array.fill(env.times.size, {|c|
				env.curves[c.min(env.curves.size - 1)];
			});
		});
		env.times = env.times.normalizeSum;
		(env.levels.size == cur.levels.size).if({
			self.node.set(\e_env, env);
		}, {
			{
				self.switchSynthDef(env.levels.size - 2,
					{ self.handleSync },
					[\e_env, env]
				);
				s.sync;
				self.node.set(\e_env, env);
			}.fork;
		});

		self.env = env;
		self.looping = env.loopNode.notNil;
		(self.views.notNil).if({
			{
				self.views[\env].setEnv(env);
				self.views[\env].curves_(env.curves);
				self.views[\loop].value_(self.looping.asInteger);
				self.views[\adsr].value_(self.adsr.asInteger);
			}.defer;
		});
	},
	customSetFromSettings: {|self, dict, cb|
		self.adsr = dict[\adsr];
		self.setEnv(dict[\env]);
		self.setParams(\dur, dict[\dur]);
		cb.value(dict);
	},
	customDumpSettings: {|self, dict, cb|
		dict[\env] = self.env;
		dict[\adsr] = self.adsr;
		dict[\syncedWith] = (self.syncedWith ? List.new).collect({|e| e.name }).asSet.asList;
		dict[\syncedFrom] = (self.syncedFrom ? Event.new).name;
		cb.value(dict);
	},
	env: Env([0, 1.0], [1], [-4], nil, nil),
	adsr: true,
	looping: false,
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
		ew = 295,
		width = pl * 2 + (gl * 2) + ew + 40,
		height = 175,
		view = View(parent, width@height),
		f = view.addFlowLayout(pl@pt, gl@gt),
		bv,
		bf,
		ev,
		gb,
		ab,
		lb,
		sb,
		ds,
		dsSpec = ControlSpec(0.02, 60.0, 4),
		dt;

		StaticText(view).string_(self.name).fixedWidth_(ks);
		f.nextLine;
		bv = View(view, 40@(height - 28));
		bf = bv.addFlowLayout(0@0, 0@0);
		gb = Button(bv, 40@20)
		.states_([["Gate"], ["Rel"]])
		.action_({|v|
			self.setParams(\gate, v.value);
		});
		bf.nextLine;
		ab = Button(bv, 40@20)
		.states_([["Free"], ["Adsr"]])
		.action_({|v|
			var adsr = (v.value.asBoolean).and(ev.value[0].size > 4);
			self.setAdsrModeFromView(adsr);
			(adsr != v.value.asBoolean).if({ v.value_(0) });
		})
		.value_((self.adsr).if({ 1 }, { 0 }));
		bf.nextLine;
		lb = Button(bv, 40@20)
		.states_([["Once"], ["Loop"]])
		.action_({|v|
			self.looping = v.value.asBoolean;
			self.generateEnvelopeFromView();
		})
		.value_(self.env.loopNode.notNil.asInteger);
		bf.nextLine;
		ds = Knob(bv, 40@40)
		.action_({|v|
			dt.value_(dsSpec.map(v.value).round(0.001));
			self.setParams(\dur, dsSpec.map(v.value));
		});

		dt = TextField(bv, 40@20)
		.value_(1)
		.action_({|v| ds.valueAction_(dsSpec.unmap(v.value.asFloat)) });

		(canSync).if({
			bf.nextLine;
			sb = Button(bv, 40@20)
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

		self.controls[\gate].get({|v|
			{ gb.value_(v) }.defer;
		});

		self.controls[\dur].get({|v|
			{
				ds.value_(dsSpec.unmap(v));
				dt.value_(v.round(0.001));
			}.defer;
		});

		ev = self.makeEnvView(view, ew@(height - 28));
		self.views = Dictionary[
			\env -> ev,
			\gate -> gb,
			\adsr -> ab,
			\loop -> lb,
			\dur -> [ds, dsSpec, dt],
			\sync -> sb
		];

		self.views[\view] = view;
		view;
	},
	makeEnvView: {|self, parent, bounds|
		var ev,
		generateEnvelope,
		setAdsrMode,
		mouseDown = false,
		lastY = nil,
		lastClick = 0,
		curveIndex;

		ev = EnvelopeView(parent, bounds)
		.drawLines_(true)
		.selectionColor_(Color.red)
		.drawRects_(true)
		.resize_(5)
		.keepHorizontalOrder_(true)
		.elasticSelection_(true)
		.action_({|v|
			var val = v.value;
			((self.adsr).and([2, 3].includes(v.index))).if({
				var ind = (v.index == 2).if({ 3 }, { 2 }),
				ls = val[1];
				ls[ind] = ls[v.index];
				v.value_([val[0], ls]);
			});
		})
		.thumbSize_(10);

		ev.mouseDownAction_({|v, x, y, mod|
			mouseDown = true;
			lastY = y;
		});
		ev.mouseUpAction_({|v, x, y, mod|
			var sec = AppClock.seconds;
			// dbl click
			((sec - lastClick) < 0.3).if({
				var sel = v.selection;
				(sel.size > 0).if({
					var ls, ds, nds, ci = -1, curves;

					#ds, ls = v.value;
					nds = Array.newClear(ds.size - sel.size);
					ls = ls.select({|v, c| sel.includes(c).not });
					curves = self.env.curves.select({|v, c| sel.includes(c + 1).not });
					ds.do({|e, c|
						(sel.includes(c).not).if({
							ci = ci + 1;
							nds[ci] = e;
						});
					});
					// sel.do({|e| b.deselectIndex(e) });
					v.value_([nds, ls]);
					v.curves_(curves);
					self.env.curves = curves;
					self.generateEnvelopeFromView();
				}, {
					var width = v.bounds.width,
					height = v.bounds.height,
					xpos = x / width,
					ypos = height - y / height,
					xs = v.value[0],
					ys = v.value[1],
					index = (xs < xpos).indexOf(false),
					nxs,
					nys,
					ncs,
					curves = self.env.curves;

					nxs = xs.insert(index, xpos);
					nys = ys.insert(index, ypos);
					ncs = curves.insert(index - 1, curves[index - 1]);
					v.value_([nxs, nys]);
					v.curves_(ncs);
					self.env.curves = ncs;
					self.adsr = false;
					self.views[\adsr].value_(0);
					self.generateEnvelopeFromView();
				});
				self.adsr = false;
				self.views[\adsr].value_(0);
			}, {
				((v.selection.size > 0)
					.or(mouseDown.and(curveIndex.notNil))).if({
					self.generateEnvelopeFromView();
				});
			});
			lastClick = sec;
			mouseDown = false;
			curveIndex = nil;
		});
		ev.mouseMoveAction_({|v, x, y, mod|
			(mouseDown.and(v.selection.size < 1)).if({
				var diff = y - lastY,
				xs = v.value[0],
				xvals = xs.normalizeSum,
				ys = v.value[1],
				width = v.bounds.width,
				pos = x / width,
				curve,
				curves = self.env.curves,
				mult;

				xvals = xvals / xvals[xvals.size - 1];

				(curveIndex.isNil).if({
					curveIndex = (xvals < pos).indexOf(false) - 1;
				});
				curve = curves[curveIndex];
				mult = (ys[curveIndex] < ys[curveIndex + 1]).if({ 1 }, { -1 });

				curve = diff * mult * 0.05 + curve;
				curves[curveIndex] = curve;
				v.curves_(curves);
				self.env.curves = curves;
				lastY = y;
			}, {
				curveIndex = nil;
			});
		});

		ev.setEnv(self.env);
		ev.curves_(self.env.curves);

		ev;
	},
	setAdsrModeFromView: {|self, bool|
		(bool.not).if({
			self.adsr = false;
		}, {
			var ev = self.views[\env],
			val = ev.value,
			ds = val[0],
			ls = val[1],
			cs = self.env.curves;
			self.adsr = true;
			(ds.size > 5).if({
				ds = ds.select({|v, c| (c < 3).or(c >= (ds.size - 2)) });
				ls = ls.select({|v, c| (c < 3).or(c >= (ls.size - 2)) });
				cs = cs.select({|v, c| (c < 2).or(c >= (cs.size - 2)) });
				ls[3] = ls[2];
				ev.value_([ds, ls]);
				ev.curves_(cs);
				self.env.curves = cs;
				self.generateEnvelopeFromView();
			}, {
				(ds.size == 5).if({
					ls[3] = ls[2];
					ev.value_([ds, ls]);
					self.generateEnvelopeFromView();
				});
			});
		});
	},
	generateEnvelopeFromView: {|self|
		var ds, ls, val = self.views[\env].value, env;

		ds = val[0];
		ds = ds.collect({|e, c| (c == 0).if({ nil }, { e - ds[c - 1] }) });
		ds.removeAt(0);
		ls = val[1];
		env = Env(ls, ds, self.env.curves, releaseNode: ls.size - 2, loopNode: (self.looping).if({ 0 }, { nil }));
		self.setEnv(env);
	}
);
