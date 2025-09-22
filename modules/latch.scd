(~module.isNil).if({
	(Document.current.dir ++ "/base/module.scd").loadPaths;
});
~latch = (
	parent: ~module,
	synthDef: SynthDef(\latch, {|
		carIn = 34,
		modIn = 36
		out = 0,
		kOut = 55|
		var car = In.ar(carIn, 1),
		mod = In.ar(modIn, 1),
		sig = Latch.ar(car, mod);

		Out.ar(out, sig);
		Out.kr(kOut, A2K.kr(sig));
	}),
	outputConfig: Dictionary[\out -> [\a, 1], \kOut -> \k],
	inputConfig: Dictionary[\carIn -> [\a, 1], \modIn -> [\a, 1]],
	addPatchOnBypass: true,
	playBypass: {|self|
		SynthDef(\bypassLatch ++ self.node.nodeID.asString, {
			var in = In.ar(self[\inputs][\carIn], 1);
			Out.ar(self[\outputs][\out], in);
		}).play(self.node, addAction: 'addAfter');
	},
	makeGui: {|self, parent, styles|
		nil
	}
);