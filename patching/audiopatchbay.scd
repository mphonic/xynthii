(~patchbay.isNil).if({
	(Document.current.dir ++ "/base/patchbay.scd").loadPaths;
});
~audioPatchbay = (
	parent: ~patchbay,
	create: {|self, sortedModules|
		var o = self.deepCopy;
		o.modules = sortedModules;
		o.io = Dictionary[
			\inputs -> Dictionary.new,
			\outputs -> Dictionary.new
		];
		o.modules.do({|e|
			var toReplace = ["in", "out"],
			confKey = [\inputConfig, \outputConfig];
			[\inputs, \outputs].do({|io, c|
				o.generateIoSet(e, io, confKey[c], toReplace[c]);
			});
		});
		o;
	},
	generateIoSet: {|self, module, destinationKey, confKey, replaceString|
		(module[destinationKey].notNil).if({
			var confIndex = module[confKey] ? Dictionary.new;
			module[destinationKey].keys.do({|key|
				var conf = confIndex[key],
				rate;
				(conf.isArray).if({
					rate = conf[0];
				}, {
					rate = conf;
				});
				(rate != \k).if({
					var paramName = key.asString.toLower().replace(replaceString, ""),
					spacer = "",
					bus = module[destinationKey][key],
					name;
					(paramName.size > 0).if({ spacer = " " });
					name = module.name ++ spacer ++ paramName;
					self.io[destinationKey][name] = Dictionary[
						\moduleName -> module.name,
						\bus -> bus,
						\module -> module
					];
				});
			});
		});
	},
	patch: {|self, outputKey, inputKey, mul = 1.0, add = 0.0, modkey, modmul, modadd, baseDefName = \patch|
		var outputSource = self.io[\outputs][outputKey],
		inputSource = self.io[\inputs][inputKey],
		channels = outputSource[\bus].numChannels,
		fb = "",
		p = outputSource[\patches] ? Dictionary.new;
		(self.requiresFeedback(inputSource[\module], outputSource[\module])).if({
			fb = "Fb";
		});
		p[inputKey] = Synth.before(
			inputSource[\module].node,
			baseDefName ++ fb ++ channels.asString, [
				\in, outputSource[\bus],
				\out, inputSource[\bus],
				\mul, mul,
				\add, add
		]);
		outputSource[\patches] = p;
	},
	unpatch: {|self, outputKey, inputKey|
		var p = self.io[\outputs][outputKey][\patches];
		(p.notNil).if({
			var i = p[inputKey];
			i.free;
			p[inputKey] = nil;
		});
	},
	setPatch: {|self, outputKey, inputKey, mul, add = 0|
		var p = self.io[\outputs][outputKey][\patches];
		(p.notNil).if({
			var i = p[inputKey];
			i.set(\mul, mul, \add, add);
		});
	},
	requiresFeedback: {|self, inputModule, outputModule|
		self.modules.indexOf(inputModule) >= self.modules.indexOf(outputModule);
	},
	getInputKeyFromPatch: {|self, patch, key|
		key;
	},
	getNodeFromPatch: {|self, patch|
		patch;
	},
	getPatchInputId: {|self, patch, key|
		key;
	}
);