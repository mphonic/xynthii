( // ONLY RUN THIS IF XYNTHII ISN'T ALREADY RUNNING
(Document.current.dir ++ "/xynthii.scd").loadPaths;
~makeXynthii.value({|d| ~xynthii = d });
)
// Wait til you see "Ready to go."
~xynthii.makeGui();

// Run this if you want to use MIDI learn or write custom MIDI
MIDIIn.connectAll;