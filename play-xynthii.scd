( // ONLY RUN THIS IF XYNTHII ISN'T ALREADY RUNNING
(Document.current.dir ++ "/xynthii.scd").loadPaths;
~makeXynthii.value({|d| ~xynthii = d });
)
// Wait til you see "Ready to go."
~xynthii.makeGui();

// Is the text on your interface getting cutoff? You can change the font and size if you want:
Font.default = Font("Arial", 10);

// Run this if you want to use MIDI learn or write custom MIDI
MIDIIn.connectAll;