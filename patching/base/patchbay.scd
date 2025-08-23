~patchbay = (
	dumpSettings: {|self, cb|
		var o = self.io[\outputs],
		patches = List.new,
		ocount = 0,
		ocond = Condition.new(o.size < 1),
		otest = {
			ocount = ocount + 1;
			(ocount >= o.size).if({
				ocond.test = true;
				ocond.signal;
			});
		},
		params = [\mul, \add, \modmul, \modadd];
		o.keys.do({|key|
			var p = o[key][\patches];
			(p.notNil).if({
				var pcount = 0;
				(p.keys.size > 0).if({
					p.keys.do({|i|
						var count = 0,
						v = p[i],
						cond = Condition.new(false),
						ps = Dictionary[
							\outputKey -> key,
							\inputKey -> self.getInputKeyFromPatch(v, i),
							\modKey -> self.getModKeyFromPatch(v, i)
						];
						params.do({|param|
							self.getNodeFromPatch(v).get(param, {|i|
								ps[param] = i;
								count = count + 1;
								(count >= params.size).if({
									cond.test = true;
									cond.signal;
								});
							});
						});
						{
							cond.wait;
							patches.add(ps);
							pcount = pcount + 1;
							(pcount >= p.keys.size).if({
								otest.value;
							});
						}.fork;
					});
				}, {
					otest.value;
				});
			}, {
				otest.value;
			});
		});
		{
			ocond.wait;
			self.views !? {|v|
				v[\ccs] !? {|c|
					patches.add(Dictionary[\viewCcs -> c]);
				};
			};
			cb.value(patches);
		}.fork;
	},
	saveSettings: {|self, path, cb|
		self.dumpSettings({|v|
			v.writeTextArchive(path);
			cb.value(v);
		});
	},
	setFromSettings: {|self, patches, cb|
		{
			self.unpatchAll();
			s.sync;
			patches.do({|p|
				(p.includesKey(\viewCcs)).if({
					self.viewCcs = p[\viewCcs];
				}, {
					self.patch(p[\outputKey], p[\inputKey], p[\mul], p[\add], p[\modKey], p[\modmul], p[\modadd]);
				});
			});
			// remove viewCcs
			patches = patches.select({|p| p.includesKey(\viewCcs).not });
			s.sync;
			cb.value(patches);
		}.fork;
	},
	loadSettings: {|self, path, cb|
		var settings = Object.readTextArchive(path);
		self.setFromSettings(settings, cb);
	},
	unpatchAll: {|self|
		var o = self.io[\outputs];
		o.keys.do({|key|
			var p = o[key][\patches];
			(p.notNil).if({
				p.keys.do({|i|
					self.unpatch(key, self.getPatchInputId(p[i], i));
				});
			});
		});
	}
);