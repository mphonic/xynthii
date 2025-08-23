(~module.isNil).if({
	(Document.current.dir ++ "/base/module.scd").loadPaths;
});

~syncableEnvelope = (
	parent: ~module,
	sync: {|self, source|
		var sourceBus,
		summers = source.modsummers ? Dictionary.new;
		(summers[\gate].notNil).if({
			sourceBus = source.modbusses[\gate][\out];
		}, {
			sourceBus = source.controls[\gate];
		});
		(source.syncedWith.notNil).if({
			source.syncedWith.add(self);
		}, {
			source.syncedWith = List[self];
		});
		self.syncedFrom = source;
		(self.modsummers.notNil).if({
			var node = self.modsummers[\gate];
			(node.notNil).if({|n|
				node.map(\param, source.controls[\gate]);
			}, {
				self.node.map(\gate, sourceBus);
			});
		}, {
			self.node.map(\gate, sourceBus);
		});
		self.updateGuiSync(true);
	},
	unsync: {|self, defIndex|
		(self.syncedFrom.notNil).if({
			var source = self.syncedFrom,
			bus = self.controls[\gate];

			(self.modsummers.notNil).if({
				var node = self.modsummers[\gate];
				(node.notNil).if({|n|
					node.map(\param, bus);
				}, {
					self.node.map(\gate, bus);
				});
			}, {
				self.node.map(\gate, bus);
			});
			self.syncedFrom = nil;
			source.syncedWith !? {|sw|
				var n = sw.select({|v| v.name != self.name });
				source.syncedWith = n.asList;
			};
			self.updateGuiSync(false);
		});
	},
	updateGuiSync: {|self, isSynced|
		self.views !? {|v|
			self.views[\sync] !? {|view|
				{ view.value_(isSynced) }.defer
			};
		}
	},
	handleSync: {|self|
		self.syncedWith !? {|sw|
			sw.do({|e|
				e !? { e.sync(self) }
			});
		};
		self.syncedFrom !? {|sf|
			self.sync(sf);
		};
	},
	setSyncFromSettings: {|self, settings, modules|
		var sf = settings[\syncedFrom],
		sw = settings[\syncedWith];
		modules = (modules.isArray).if({ modules }, { [modules] });
		(sf.notNil).if({
			var m = modules.select({|e| e.name == sf }).pop();
			(m.notNil).if({ self.sync(m) }, { self.unsync() });
		}, {
			self.unsync();
			(sw.notNil).if({
				var m = modules.select({|e| sw.includes(e.name) });
				(m.size > 0).if({ self.syncedWith = m }, { self.syncedWith = nil });
			}, {
				self.syncedWith = nil;
			});
		});
	}
);