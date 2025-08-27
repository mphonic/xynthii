( // ONLY RUN THIS IF XYNTHII ISN'T ALREADY RUNNING
(Document.current.dir ++ "/xynthii.scd").loadPaths;
~makeXynthii.value({|d| ~xynthii = d });
)
// Wait til you see "Ready to go."
~xynthii.makeGui();

// Open a window to allow you to randomly nudge paramter settings
(
var changeSelectView = {|view, dev = 0|
	var size = (view.class == Button).if({ view.states.size }, { view.items.size }),
	val = view.value,
	step = (dev.coin).if({ [-1, 1].choose }, { 0 }),
	new = (val + step).fold(0, size - 1);
	(new != val).if({
		view.valueAction_(new);
	});
},
nudgeView = {|view, dev = 0|
	var val = view.value,
	new = (val + rrand(dev.neg, dev)).fold(0.0, 1.0);
	view.valueAction_(new);
},
allModules = ~xynthii.sortedModules
.collect({|e| e.name })
.collect({|e|
	var m = ~xynthii.keys.select({|k|
		var y = false;
		(~xynthii[k].class == Event).if({
			y = ~xynthii[k][\name] == e;
		});
		y;
	}).pop();
	m ? false;
}) ++ [\modPod],
nudge = {|dev = 0.1, exclude, excludeButtons = false|
	var m = allModules,
	c,
	e = exclude ? Array.new;
	m = m.select({|v| e.includes(v).not });
	m.do({|e|
		var views = ~xynthii[e].views;
		(e == \modPod).if({
			var mods = views[\modulations],
			v = mods.collect({|e| e.children }).flat();
			{
				v.do({|e, c|
					(e.class == Knob).if({
						{ nudgeView.value(e, dev) }.defer;
					}, {
						{ changeSelectView.value(e, dev); }.defer;
					});
					s.sync;
				});
			}.fork;
		}, {
			(views.notNil).if({
				views.keys.do({|k|
					v = views[k];
					(v.isArray.and(v.size > 3)).if({ // sequencer or modpod
						v.do({|e|
							var view = e[0];
							nudgeView.value(view, dev);
						});
					}, {
						var view = (v.isArray).if({ v[0] }, { v });
						switch(view.class)
						{ Button } {
							((k != \play).and(excludeButtons.not)).if({ // leave play alone
								changeSelectView.value(view, dev);
							});
						}
						{ PopUpMenu } {
							changeSelectView.value(view, dev);
						}
						{ Knob } {
							nudgeView.value(view, dev);
						}
					});
				});
			});
		});
	});
},
dev = 0.05,
exclude = nil,
// if you want to exclude certain modules, you can add them to
// an exclude array, instead of using exclude = nil; i.e.,
// exclude = [\modPod, \seq],
excludeButtons = true, // set to false if you want buttons nudged, too
w = Window("Xynthii Nudge Params", Rect(10, 500, 300, 60));
w.layout_(HLayout(
	[Button()
	.states_([["Nudge"]])
	.action_({|v| nudge.(dev, exclude, excludeButtons) }),
		stretch: 4],
	VLayout(
		StaticText().string_("Amount"),
		Knob()
		.action_({|v| dev = v.value.linexp(0, 1.0, 0.01, 1.0) })
		.value_(0.05.explin(0.01, 1.0, 0.0, 1))
	)
));
CmdPeriod.doOnce({ w.close });
w.view.palette_(QPalette.dark);
w.front;
)