var extension;

(~module.isNil).if({
	(Document.current.dir ++ "/base/module.scd").loadPaths;
});

extension = (
	addMod: {|
		self,
		id,
		param,
		sourceBus,
		mul = 1.0,
		add = 0.0,
		patchBaseDef = \kpatch,
		sumBaseDef = \kmodsum|
		var c = self.controls[param];
		(c.notNil).if({
			var m = self.modbusses[param],
			d = self.modulators ? Dictionary.new,
			p = d[param] ? Dictionary.new,
			sc = sourceBus.numChannels,
			patchDef = patchBaseDef ++ sc.asString,
			patchNode;
			(p.size < 1).if({
				{
					var sumDef = sumBaseDef ++ sc.asString,
					summers = self.modsummers ? Dictionary.new,
					n;
					n = Synth.before(self.node, sumDef, [
						\in, m[\in],
						\out, m[\out]
					]);
					summers[param] = n;
					self.modsummers = summers;
					s.sync;
					n.map(\param, c);
					self.node.map(param, m[\out]);
					self.handleSync(param);
				}.fork;
			});
			(p[id].notNil).if({
				patchNode = Synth.replace(p[id], patchDef, [
					\in, sourceBus,
					\out, m[\in],
					\mul, mul,
					\add, add
				]); // patch to mod in
			}, {
				patchNode = Synth(patchDef, [
					\in, sourceBus,
					\out, m[\in],
					\mul, mul,
					\add, add], target: self.node.group);
			});
			p[id] = patchNode;
			d[param] = p;
			self.modulators = d;
			self.handleSync(param);
			patchNode;
		}, {
			("Warning: Param does not exist on " ++ self.name).postln;
			nil;
		});
	},
	removeMod: {|self, param, id|
		var m = self.modulators ? Dictionary.new,
		d = m[param];
		(d.notNil && d.size > 0).if({
			var p = d[id];
			(p.notNil).if({
				(d.size == 1).if({
					self.node.map(param, self.controls[param]);
					self.modsummers[param].free;
					self.modsummers.removeAt(param);
				});
				p.free;
				d.removeAt(id);
				self.modulators[param] = d;
				self.handleSync(param);
				self.modulators;
			}, {
				("Warning: No modulators with id " ++ id ++ " on param " ++ param).postln;
				nil;
			});
		}, {
			("Warning: No modulators for " ++ param ++ " on " ++ self.name).postln;
			nil;
		});
	},
	setMod: {|self, param, id, mul = 1.0, add = 0.0|
		var m = self.modulators ? Dictionary.new,
		p = m[param] ? Dictionary.new,
		n = p[id];
		(n.notNil).if({
			n.set(\mul, mul, \add, add);
		}, {
			("Warning: No modulators with id " ++ id ++ " on param " ++ param).postln;
			nil;
		});
	}
);
~module = ~module ++ extension;