( // ONLY RUN THIS IF XYNTHII ISN'T ALREADY RUNNING
(Document.current.dir ++ "/xynthii.scd").loadPaths;
~makeXynthii.value({|d| ~xynthii = d });
MIDIIn.connectAll;
)
// Wait til you see "Ready to go."
~xynthii.makeGui();
// Optionally load this setting
~xynthii.loadSettings(Document.current.dir ++ "/presets/leady");

( // Keyboard control
var notes = List.new,
noteOn,
keytrack = 1, // keytrack for filt -- 0 = none, 1 = full
velocitySensitivity = 0, // 0 = none, 1 = full
bendRange = 2.0, // semitones
bend = 0,
legato = true,
silent = false,
i = ~xynthii,
turnKeysOn,
turnKeysOff,
turnRecordOn,
turnRecordOff,
target = \p,
recordVelocity = true,
advanceOnKeyUp = true,
w;

noteOn = {|num, val, doTrig = false|
	(silent.not).if({
		var m = (num + bend).midicps,
		d = num - 64 * keytrack;

		i.osc1.setParams(\freq, m);
		val !? { i.vca1.setParams(\amp, val.linlin(0, 127, -96 * velocitySensitivity, 0).dbamp); };
		i.filt.setParams(\ffreqmul, d.midiratio);
		(doTrig).if({ i.trigger(1) });
	});
};

turnKeysOn = {
	MIDIdef.noteOn(\xynthiikeyson, {|val, num, chan, src|
		(silent.not).if({
			var doTrig = ((legato.not).or(notes.size == 0));

			notes.add(num);
			noteOn.value(num, val, doTrig);
		});
	});
	MIDIdef.noteOff(\xynthiikeysoff, {|val, num, chan, src|
		(silent.not).if({
			notes.removeAt(notes.indexOf(num));
			(notes.size > 0).if({
				(legato.not).if({ i.trigger(0) });
				noteOn.value(notes[notes.size - 1])
			}, {
				i.trigger(0);
			});
		});
	});
	MIDIdef.bend(\xynthiibend, {|val, chan, src|
		var b = val.linlin(0, 16256, bendRange.neg, bendRange),
		n = notes[notes.size - 1],
		d = n !? {|v| v };
		bend = b;

		(d.notNil).if({
			noteOn.value(d)
		});
	});
};

turnKeysOff = {
	MIDIdef(\xynthiikeyson).free;
	MIDIdef(\xynthiikeysoff).free;
	MIDIdef(\xynthiibend).free;
};
turnRecordOn = {
	var q = i.seq,
	writeNote = {|val, num|
		var step = q.currentStep,
		pknobs = q.views[target],
		vknobs = q.views[\v],
		pval = (num - 64).midiratio.explin(
			0.02480314143737,
			38.054627679533,
			0,
			1.0),
		vval = val !? { val / 127 };
		{
			pknobs[step][0].valueAction_(pval);
			(recordVelocity.and(target != \v).and(vval.notNil)).if({ vknobs[step][0].valueAction_(vval); });
		}.defer;
		q.trigger(1);
	};
	silent = true;
	i.trigger(0);
	notes = List.new;
	MIDIdef.noteOn(\seqwrite, {|val, num, chan, src|
		notes.add(num);
		writeNote.value(val, num);
	});

	MIDIdef.noteOff(\seqwriteoff, {|val, num, chan, src|
		notes.removeAt(notes.indexOf(num));
		(notes.size > 0).if({
			writeNote.value(nil, notes[notes.size - 1]);
		}, {
			i.trigger(0);
			{
				(advanceOnKeyUp).if({
					q.advanceSeq();
				});
			}.defer;
		});
	});
};

turnRecordOff = {
	silent = false;
	MIDIdef(\seqwrite).free;
	MIDIdef(\seqwriteoff).free;
};

w = Window("MIDI Control", Rect(100, 500, 400, 100));
w.view.layout_(
	VLayout(
		HLayout(
			VLayout(
				StaticText().string_("Keytrack"),
				Knob().value_(1).action_({|v| keytrack = v.value })
			),
			VLayout(
				StaticText().string_("Vel Sens"),
				Knob().value_(0).action_({|v| velocitySensitivity = v.value })
			),
			Button().states_([["Legato: On"], ["Legato: Off"]])
			.action_({|v| legato = v.value.asBoolean.not }),
			HLayout(
				StaticText().string_("Bend Range"),
				TextField().value_("2")
				.action_({|v| bendRange = v.value.asFloat })
			),
		),
		HLayout(
			Button().states_([["Record"], ["Stop"]])
			.action_({|v|
				(v.value == 1).if({
					turnRecordOn.value;
				}, {
					turnRecordOff.value;
				})
			}),
			Button().states_([["Advance: On"], ["Advance: Off"]])
			.action_({|v| advanceOnKeyUp = v.value.asBoolean.not }),
			Button().states_([["Vel: On"], ["Vel: Off"]])
			.action_({|v| recordVelocity = v.value.asBoolean.not }),
			Button().states_([["Note 2 Pitch"], ["Note 2 Vel"]])
			.action_({|v|
				(v.value == 1).if({
					target = \v;
				}, {
					target = \p;
				});
			});
		)
	)
);

turnKeysOn.value();
w.onClose_({
	turnKeysOff.value;
	turnRecordOff.value;
});
w.view.palette_(QPalette.dark);
CmdPeriod.doOnce({
	w.close();
	turnKeysOff.value;
	turnRecordOff.value;
});
w.front;
)

MIDIdef.freeAll
// MIDIIn.doNoteOnAction(1, 1, 56, 64);
// MIDIIn.doNoteOffAction(1, 1, 56, 64);