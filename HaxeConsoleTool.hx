import haxe.io.Eof;
import haxe.Json;
import sys.FileSystem;
import sys.io.File;

using StringTools;

typedef ConsoleOptimization = {
	var gFlag:Bool;
	var o2Flag:Bool;
}

typedef ConsoleLinkOptions = {
	var ip:String;
	var linkToConsole:Bool;
	var openEmuIfTransferFailed:Bool;
}

typedef ConsoleSettings = {
	var target:String;
	var deleteTempFiles:Bool;
	var compileAsPlugin:Bool;
	var defines:Array<String>;
	var libraries:Array<String>;
	var linkOptions:ConsoleLinkOptions;
	var optimizations:ConsoleOptimization;
}

typedef ConsoleMetadata = {
	var title:String;
	var description:String;
	var author:String;
}

typedef HaxeConsoleProject = {
	var settings:ConsoleSettings;
	var metadata:ConsoleMetadata;
}

class HaxeConsoleTool {
	static var cwd = "";
	
	static var HXML_TEMP = "-cp source
-main Main
-lib hxcpp
-D loop_unroll_max_cost=0
-D no_ssl
-D no_pch
{1}
-D HAXE_OUTPUT_PART=HAXE_CONSOLE
-D HXCPP_SINGLE_THREADED_APP
-D HXCPP_STACK_TRACE
-D HXCPP_STACK_LINE
-D static_link
-D message.reporting=pretty
{2}
-cpp export";

	static function readConfig():HaxeConsoleProject {
		if (FileSystem.exists("consoleSettings.json")) {
			return Json.parse(File.getContent("consoleSettings.json"));
		}
		throw 'Please generate it by calling "haxelib run haxeconsole -g" to generate a Config File.';
	}

	inline static function execute(cmd:String):Bool {
		trace('$ $cmd');
		return Sys.command(cmd) == 0;
	}

	static function toDKPPath(pathString:String):String {
		var env = Sys.getEnv("DEVKITPRO");
		if (env != null) return pathString.replace("[DKP_PATH]", env);
		return pathString.replace("[DKP_PATH]", Sys.systemName() == "Windows" ? "C:/devkitpro" : "/opt/devkitpro");
	}

	static function askForInput(warning:String):Bool {
		try {
			trace('/!\\ $warning /!\\\n\t[Y] = YES\t\t[N] = NO');
			Sys.print("> \x1b[36;1m");
			var out = Sys.stdin().readLine().toLowerCase().charAt(0) == "y";
			Sys.print("\x1b[37;1m");
			return out;
		} catch(_:Eof) {
			trace("\n\x1b[37;1mNo, don't input an EOF. :(");
			return askForInput(warning);
		}
	}

	static function makeDirs(directory:String) {
		var dirs = directory.split("/");
		var path = "";
		for (dir in dirs) {
			path += '$dir/';
			try { FileSystem.createDirectory(path); } catch(_) {}
		}
	}

	static function recursiveCopyFiles(fromDir:String, toDir:String) {
		if (!FileSystem.exists(fromDir)) return;
		makeDirs('$toDir/');
		for (list in FileSystem.readDirectory(fromDir)) {
			var path = '$fromDir/$list';
			if (FileSystem.isDirectory(path)) recursiveCopyFiles(path, '$toDir/$list');
			else File.saveBytes('$toDir/$list', File.getBytes(path));
		}
	}

	static function recursiveRMTree(dir:String) {
		for (list in FileSystem.readDirectory(dir)) {
			var path = '$dir/$list';
			if (FileSystem.isDirectory(path)) recursiveRMTree(path);
			else FileSystem.deleteFile(path);
		}
		FileSystem.deleteDirectory(dir);
	}

	inline static function deleteFileIfExist(file:String) {
		if (FileSystem.exists(file)) FileSystem.deleteFile(file);
	}

	static function getTargetExt(p:HaxeConsoleProject):String {
		if (p.settings.target == "wiiu") return p.settings.compileAsPlugin ? "wps" : "rpx";
		return p.settings.compileAsPlugin ? "cia" : "3dsx";
	}

	static function fileHandler(p:HaxeConsoleProject = null) {
		if (p == null) p = readConfig();
		var ext = getTargetExt(p);
		if (!FileSystem.exists('buildFiles/output.$ext')) {
			trace("Application needs to be built first");
			return;
		}

		var ip = p.settings.linkOptions.ip;
		function validateIP():Bool {
			var dots = ip.split(".");
			if (dots.length != 4) return false;
			for (number in dots) {
				try {
					var num = Std.parseInt(number);
					if (num == null || !(0 <= num && num <= 255)) return false;
				} catch(_) { return false; }
			}
			return !ip.contains("-");
		}

		if (validateIP() && p.settings.linkOptions.linkToConsole) {
			var devkitpro = toDKPPath("[DKP_PATH]");
			if (p.settings.target == "3ds") {
				var tool = Sys.systemName() == "Windows" ? '$devkitpro/tools/bin/3dslink.exe' : '$devkitpro/tools/bin/3dslink';
				if (!execute('$tool -a $ip buildFiles/output.3dsx') && p.settings.linkOptions.openEmuIfTransferFailed) {
					trace("Transfer failed, try running emulator manually.");
			 }
			} else {
				var tool = Sys.systemName() == "Windows" ? '$devkitpro/tools/bin/wiiload.exe' : '$devkitpro/tools/bin/wiiload';
				Sys.putEnv("WIILOAD", 'tcp:$ip');
				execute('$tool buildFiles/output.$ext');
			}
		} else {
			trace("Skipping auto-launch. Set a valid IP in consoleSettings.json to use 3dslink/wiiload.");
		}
	}

	static function main() {
		haxe.Log.trace = (v, ?infos) -> Sys.println(v);
		Sys.print('\x1b[33;1m
██    ██   ██████   ██    ██  ████████   ██████   ███████    ██████
██    ██  ██    ██  ██    ██  ██    ██  ██    ██  ██   ███  ██    ██
██    ██  ██    ██   ██  ██   ██              ██  ██    ██  ██
████████  ████████    ████    ██████      █████   ██    ██   ██████
██    ██  ██    ██   ██  ██   ██              ██  ██    ██        ██
██    ██  ██    ██  ██    ██  ██    ██  ██    ██  ██   ███  ██    ██
██    ██  ██    ██  ██    ██  ████████   ██████   ███████    ██████\x1b[37;1m
======================== Unified Console Tool ========================
');

		var args = Sys.args();
		if (args.length == 1) {
			trace("
\tArgs (haxelib run haxeconsole [arg]):
\t\t[-g]: Generates a New JSON for Console format.
\t\t[-c]: Compiles to a compatible working application.
\t\t[-e]: Calls addr2line for Error Lookup.
\t\t[-s]: Wrapper for Sending the built application.
			");
			return;
		}

		{
			var path = args[args.length - 1];
			Sys.setCwd(path);
			args.remove(path);
		}

		cwd = Sys.getCwd().replace("\\", "/");
		cwd = cwd.substr(0, cwd.length - 1);
		switch args.shift() {
			case "-g":
				if (FileSystem.exists('consoleSettings.json') && !askForInput("consoleSettings.json EXISTS! Overwrite?")) return;
				var out:HaxeConsoleProject = {
					settings: {
						target: "3ds",
						deleteTempFiles: false,
						compileAsPlugin: false,
						defines: [],
						libraries: ["hxcpp"],
						linkOptions: { ip: "192.168.1.100", linkToConsole: false, openEmuIfTransferFailed: false },
						optimizations: { gFlag: false, o2Flag: true }
					},
					metadata: { title: "HaxeConsole", description: "Made with Haxe!", author: "Author" }
				};
				File.saveContent('consoleSettings.json', Json.stringify(out, null, "\t"));
				trace("Generated Console Settings Config!");

			case "-c":
				function sanityCheck(info:String, func:()->Bool, ngText:String = "") {
					var out = Sys.stdout();
					Sys.print('\x1b[35;1m> $info...\x1b[37;1m');
					if (func()) { out.writeString("\x1b[32;1m OK. \x1b[37;1m \n"); } 
					else { out.writeString('\x1b[31;1m NG. $ngText \x1b[37;1m \n'); Sys.exit(1); }
				}

				sanityCheck("Checking for Config", () -> FileSystem.exists("consoleSettings.json"), 'Run "-g" first.');
				
				var project:HaxeConsoleProject = null;
				sanityCheck("Loading the Project", () -> {
					try { project = readConfig(); return true; } catch(_) { return false; }
				}, 'JSON is not Formatted Correctly!');

				var isWiiU = project.settings.target == "wiiu";
				var goodHaxeLibs:Array<String> = [];
				var flagsKey = isWiiU ? "[HAXEWIIU_FLAGS]" : "[HAXE3DS_FLAGS]";
				var attributes:Map<String, Array<String>> = [ flagsKey => [] ];

				if (isWiiU) {
					attributes[flagsKey] = ['-lHAXEWIIU', '-lwut', '-lcoreinit', '-lfs', '-lgx2', '-lhxcpp', '-Iexport/include', '-L"[DKP_PATH]/wut/lib"', '-I"[DKP_PATH]/wut/include"', '-I"[DKP_PATH]/wut/include/wut"'];
				} else {
					attributes[flagsKey] = ['-lHAXE3DS', '-lcitro2d', '-lcitro3d', '-lctru', '-lcwav', '-lncsnd', '-lhxcpp', '-Iexport/include', '-L"[DKP_PATH]/portlibs/3ds/lib"', '-I"[DKP_PATH]/portlibs/3ds/include"', '-lz'];
				}

				{
					final mapper:Map<String, Bool> = ["-O2" => project.settings.optimizations.o2Flag, "-g" => project.settings.optimizations.gFlag];
					for (string => enabled in mapper.keyValueIterator()) if (enabled) attributes[flagsKey].push(string);
				}

				for (i => lib in project.settings.libraries) project.settings.libraries[i] = lib.toLowerCase();
				if (!project.settings.libraries.contains("hxcpp")) project.settings.libraries.insert(0, "hxcpp");

				sanityCheck('Parsing all ${project.settings.libraries.length} libraries', () -> {
					for (lib in project.settings.libraries) {
						var path = '.haxelib/$lib';
						if (!FileSystem.exists(path)) { trace('SKIPPING LIBRARY "$lib"'); continue; }
						path += '/${File.getContent('$path/.current').trim()}';
						if (FileSystem.exists('$path/assets')) recursiveCopyFiles('$path/assets', "export");
						goodHaxeLibs.push(lib);
					}
					return true;
				}, "What??");

				for (directories in ["export", "assets/romfs", "buildFiles"]) makeDirs(directories);
				if (FileSystem.exists("assets")) recursiveCopyFiles("assets", "export");

				var targetDefine = isWiiU ? (project.settings.compileAsPlugin ? "-D IS_WUPS_PLUGIN" : "-D IS_WUT_RPX") : (project.settings.compileAsPlugin ? "-D IS_CIA" : "-D IS_3DSX");
				var platformDefine = isWiiU ? "-D wiiu\n-D cafe\n-D HAXEWIIU" : "-D nx\n-D haxe3ds";
				
				HXML_TEMP = HXML_TEMP.replace("{1}", platformDefine + "\n" + [for (lib in goodHaxeLibs) '-lib $lib\n-D ${lib.toUpperCase()}'].join("\n"));
				HXML_TEMP = HXML_TEMP.replace("{2}", targetDefine);
				for (define in project.settings.defines) {
					HXML_TEMP += '$define\n';
					attributes[flagsKey].push(define);
			 }
				File.saveContent("build.hxml", HXML_TEMP);

				sanityCheck("Updating toolchain for compiler use", () -> {
					try {
						var toolchainPath = '.haxelib/hxcpp/${File.getContent(".haxelib/hxcpp/.current").trim()}/toolchain';
						var xmlName = isWiiU ? "wiiu-toolchain.xml" : "haxe3ds-setup.xml";
						var xmlContent = File.getContent('$toolchainPath/$xmlName');
						for (key => flags in attributes.keyValueIterator()) {
							var values = "";
							for (flag in flags) values += '<flag value=\'${flag.replace("\\", "/").trim()}\'/>\n';
							xmlContent = xmlContent.replace(key, values);
						}
						File.saveContent('$toolchainPath/linux-toolchain.xml', toDKPPath(xmlContent));
						return true;
					} catch(error) { trace(error); return false; }
				}, "Something went wrong!");

				trace("Initial Setup Complete! Compiling Library");
				sanityCheck("Compiling using the custom HXML file", () -> execute("haxe build.hxml"), "Failed to compile!");
				
				Sys.setCwd('export');
				var makeTarget = isWiiU ? (project.settings.compileAsPlugin ? "wps" : "rpx") : (project.settings.compileAsPlugin ? "cia" : "3dsx");
				sanityCheck("Finally Compiling to Working Application", () -> execute('make clean && make $makeTarget'), "Failed to compile!");

				recursiveCopyFiles("output", "../buildFiles");
				Sys.setCwd("..");

				if (project.settings.deleteTempFiles) {
					recursiveRMTree("export");
					deleteFileIfExist("build.hxml");
				} else {
					recursiveRMTree("export/output");
				}
				trace("Successfully Compiled!");
				fileHandler(project);

			case "-s": fileHandler();
			case "-e":
				var devkitpro = toDKPPath("[DKP_PATH]");
				var project = readConfig();
				var isWiiU = project.settings.target == "wiiu";
				var addr2line = isWiiU 
					? (Sys.systemName() == "Windows" ? '$devkitpro/devkitPPC/bin/powerpc-eabi-addr2line.exe' : '$devkitpro/devkitPPC/bin/powerpc-eabi-addr2line')
					: (Sys.systemName() == "Windows" ? '$devkitpro/devkitARM/bin/arm-none-eabi-addr2line.exe' : '$devkitpro/devkitARM/bin/arm-none-eabi-addr2line');
				execute('$addr2line -i -p -s -f -C -r -a -e buildFiles/output.elf ${args.join(" ")}');
		}
	}
}
