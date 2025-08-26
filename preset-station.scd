( // ONLY RUN THIS IF XYNTHII ISN'T ALREADY RUNNING
(Document.current.dir ++ "/xynthii.scd").loadPaths;
~makeXynthii.value({|d| ~xynthii = d });
)
// Wait til you see "Ready to go."
~xynthii.makeGui();

/* This will allow you to load a number of presets into memory and immediate switch between them. Could be useful for a performance, for instance. */
(
var num = 18,
w = Window("Xynthii Preset Station"),
layout = w.addFlowLayout(),
presets = List.newClear(num),
presetViews = List.newClear(num),
current,
x = ~xynthii;

num.do({|c|
	var lp = Button()
	.states_([["Load Preset..."]])
	.action_({|v|
		FileDialog({|p|
			presets[c] = Object.readTextArchive(p[0]);
			v.states_([[p[0].split($/).pop()]]);
			sp.enabled_(true);
		}, nil, 1, 0, path: "presets");
	}),
	sp = Button()
	.states_([[">"]])
	.action_({|v|
		(current != c).if({
			x.setFromSettings(presets[c], lp.states[0][0]);
			presetViews.do({|e|
				var l = e[1];
				l.states_([[">"]]);
			});
			v.states_([["O", nil, Color.green]]);
			current = c;
		});
	})
	.enabled_(false)
	.fixedWidth_(20),
	el = View(w, 180@40).layout_(HLayout([lp, stretch: 4], sp));
	presetViews[c] = [lp, sp];
});

CmdPeriod.doOnce({ w.close });
w.view.palette_(QPalette.dark);
w.front;
)