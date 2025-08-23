/* If you are using OSX and your installed extensions are not working properly, they may be quarantined. If you run the code below, it should unquarantine all of your extensions. After the code runs, quit and restart SC. */

(
var unquarantine = {|ext|
	(ext ++ "/*").pathMatch
	.select({|p|
		"^[.]".matchRegexp(p).not;
	})
	.do({|p|
		("(.scx)$".matchRegexp(p)).if({
			("xattr -rd com.apple.quarantine " ++ p).unixCmd;
		}, {
			(File.type(p) == \directory).if({
				unquarantine.value(p);
			});
		});
	});
};

unquarantine.(Platform.userExtensionDir);
)