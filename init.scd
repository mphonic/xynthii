/* NOTE: If you use Linux or have experience installing extensions in Supercollider, install them the normal way (instructions in the README). This is an experimental script to help beginners install extensions without any stress.*/

/*
Run the code below. To do so, put your cursor anywhere between the main parentheses. Do not select any text -- just have the cursor within the parentheses somewhere. On Mac, hit cmd-Return. On Windows, hit ctrl-Enter. The code should run. If you do not see any errors, you should be good to go. You won't have to run this code again.
Quit and reopen Supercollider. If you want to double-check installation, open test-install.scd and run the code there. If all looks good, open play-xynthii.scd and execute the code there. You should now have a functioning xynthii.
*/

(
var arc = Platform.architecture,
ext = Platform.userExtensionDir,
dir = Document.current.dir ++ "/extensions";

Platform.case(
	\linux, { "Please follow instructions in README to install extensions.".postln; },
	\windows, {
		var paths,
		skipMatch = ("_64".matchRegexp(arc.asString)).if({ 32 }, { 64 });

		dir = dir ++ "/windows/";
		paths = (dir ++ "*").pathMatch
		.collect({|item|
			item.select({|e, c| c < (item.size - 1) });
		})
		.select({|item|
			var pathSplit = item.split(Platform.pathSeparator),
			folder = pathSplit[pathSplit.size - 1];
			("(^[.]|.*(" ++ skipMatch ++ "))")
			.matchRegexp(folder)
			.not;
		})
		.collect({|path|
			var name = path.split(Platform.pathSeparator).pop,
			dest;
			("sc3-plugins".matchRegexp(name)).if({
				name = "SC3plugins";
				path = path ++ "\\" ++ name;
			});
			dest = ext ++ "\\" ++ name;
			("xcopy \"" ++ path ++ "\" \"" ++ dest ++ "\" /s /i").unixCmd;
			dest;
		})
		.collect({|path|
			(File.exists(path).not).if({
				("**********ERROR: Did not successfully copy " ++ path).postln;
				"Follow instructions in README for installing extensions".postln;
				false;
			}, {
				true;
			});
		})
		.select({|b| b.not });
		(paths.size > 0).if({
			"*Sorry, the installation of extensions was unsuccessful. Please follow the instructions in the README to manually install extensions. Don't worry, it's not hard*".postln;
		}, {
			"Installation successful. Quit then restart Supercollider. Open play-xynthii.scd and execute the code to start using xynthii.".postln;
		});
	},
	\osx, {
		var paths,
		skipMatch = ("(AArch|_arm)".matchRegexp(arc.asString)).if({ "_intel" }, { "_arm" });

		dir = dir ++ "/mac/";
		paths = (dir ++ "*").pathMatch
		.collect({|item|
			item.select({|e, c| c < (item.size - 1) });
		})
		.select({|item|
			var pathSplit = item.split(Platform.pathSeparator),
			folder = pathSplit[pathSplit.size - 1];
			("(^[.]|.*(" ++ skipMatch ++ "))")
			.matchRegexp(folder)
			.not;
		})
		.collect({|path|
			var name = path.split(Platform.pathSeparator).pop,
			dest;
			("Oversampling".matchRegexp(name)).if({
				name = "OversamplingOscillators";
				path = path ++ "/" ++ name;
			}, {
				("PortedPlugins".matchRegexp(name)).if({
					name = "PortedPlugins";
					path = path ++ "/" ++ name;
				});
			});
			dest = ext ++ "/" ++ name;
			("cp -r '" ++ path ++ "' '" ++ ext ++ "/'").unixCmd;
			dest;
		});
		{
			"Copying files...".postln;
			1.wait;
			paths = paths
			.collect({|path|
				(File.exists(path).not).if({
					("**********ERROR: Did not successfully copy " ++ path).postln;
					"Follow instructions in README for installing extensions".postln;
					false;
				}, {
					true;
				});
			})
			.select({|b| b.not });
			(paths.size > 0).if({
				"*Sorry, the installation of extensions was unsuccessful. Please follow the instructions in the README to manually install extensions. Don't worry, it's not hard*".postln;
			}, {
				"Plugins were installed successfully. You will need to unquarantine some by opening Applications -> Utilities -> Terminal and running these two lines:".postln;
				("xattr -rd com.apple.quarantine " ++ ext.replace(" ", "\\ ") ++ "/PortedPlugins/*.scx").postln;
				("xattr -rd com.apple.quarantine " ++ ext.replace(" ", "\\ ") ++ "/OversamplingOscillators/scx_files/*.scx").postln;
				"Then quit and restart Supercollider. Open play-xynthii.scd and execute the code to start using xynthii.".postln;
			});
		}.fork;
	}
);
)
