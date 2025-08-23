(
var defs = List.new;
(1..4).do({|n|
	var c = n.asString;
	defs.add(
		SynthDef(\kmodsum ++ c, {|param, in, out|
			Out.kr(out, param.ring1(In.kr(in, n)));
		})
	);

	defs.add(
		SynthDef(\kpatch ++ c, {|in, out, modin, mul = 1.0, add = 0.0, modmul = 0, modadd = 0, hasmod = 0|
			Out.kr(
				out,
				In.kr(in, n).ring1(
					In.kr(modin, n) * modmul + modadd * hasmod
				) * mul + add
			);
		});
	);
	defs.add(
		SynthDef(\patch ++ c, {|in, out, mul = 1.0, add = 0.0|
			Out.ar(out, In.ar(in, n) * mul + add);
		});
	);

	defs.add(
		SynthDef(\patchFb ++ c, {|in, out, mul = 1.0, add = 0.0|
		Out.ar(out, InFeedback.ar(in, n) * mul + add);
	});
	);
	(1..n).do({|e, x|
		var i = e.asString;
		defs.add(
			SynthDef(\bypass ++ i ++ c, {|in, out|
				Out.ar(out, In.ar(in, e).dup((n - x).min(1)).pop());
			});
		);

		defs.add(
			SynthDef(\kbypass ++ i ++ c, {|in, out|
				Out.kr(out, In.kr(in, e).dup((n - x).min(1)).pop());
			});
		);

		defs.add(
			SynthDef(\bypassFb ++ i ++ c, {|in, out|
				Out.ar(out, InFeedback.ar(in, e).dup((n - x).min(1)).pop());
			});
		);
	});
});

~sendPatchDefs = {
	defs.do({|e| e.send(s); });
};
~patchDefs = defs;
)