import haxe.io.Eof;
import haxe.Json;
import sys.FileSystem;
import sys.io.File;

using StringTools;

typedef H3DSP_Optimization = { var gFlag:Bool; var o2Flag:Bool; }
typedef H3DSP_LinkOptions = { var ip:String; var linkToConsole:Bool; var openEmuIfTransferFailed:Bool; }

typedef H3DSP_Settings = {
	var deleteTempFiles:Bool;
	var compileAsCIA:Bool;
	var compileAsWUP:Bool;
	var compileAsPlugin:Bool;
	var defines:Array<String>;
	var libraries:Array<String>;
	var linkOptions:H3DSP_LinkOptions;
	var optimizations:H3DSP_Optimization;
}

typedef H3DSP_Metadata = { var title:String; var description:String; var author:String; }
typedef Haxe3DSProject = { var settings:H3DSP_Settings; var metadata:H3DSP_Metadata; }

class Haxe3DS_Tool {
	static var cwd = "";
	static var HXML_TEMP = "-cp source\n-main Main\n\n# libs\n-lib hxcpp\n\n# defines\n-D loop_unroll_max_cost=0\n-D no_ssl\n-D no_pch\n{1}\n-D HAXE_OUTPUT_PART=HAXE_CONSOLE\n-D HXCPP_SINGLE_THREADED_APP\n-D HXCPP_STACK_TRACE\n-D HXCPP_STACK_LINE\n-D static_link\n-D message.reporting=pretty\n{2}\n\n# output directory\n-cpp export";

	static function readConfig():Haxe3DSProject {
		if (FileSystem.exists("3dsSettings.json")) return Json.parse(File.getContent("3dsSettings.json"));
		throw 'Please generate it by calling "haxelib run haxe3ds -g" to generate a Config File.';
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
			Sys.print("> ");
			var out = Sys.stdin().readLine().toLowerCase().charAt(0) == "y";
			Sys.print("\n");
			return out;
		} catch(_:Eof) {
			trace("\nNo, don't input an EOF. :(");
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

	static function getTargetExt(project:Haxe3DSProject, isWiiU:Bool):String {
		if (isWiiU) {
			if (project.settings.compileAsWUP) return "wup";
			return project.settings.compileAsPlugin ? "wps" : "rpx";
		}
		return project.settings.compileAsCIA ? "cia" : "3dsx";
	}

	static function fileHandler(p:Haxe3DSProject = null, isWiiU:Bool = false) {
		if (p == null) p = readConfig();
		var ext = getTargetExt(p, isWiiU);
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
			if (!isWiiU) {
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
			trace("Skipping auto-launch. Set a valid IP in 3dsSettings.json to use 3dslink/wiiload.");
		}
	}

	static function buildWUP(project:Haxe3DSProject, titleId:String = "0005000010100100"):Bool {
		var wupDir = "wup_build";
		makeDirs('$wupDir/code');
		makeDirs('$wupDir/meta');
		makeDirs('$wupDir/content');
		
		var rpxPaths = ["output/output.rpx", "output.rpx", "../buildFiles/output.rpx"];
		var foundRpx = false;
		
		for (path in rpxPaths) {
			if (FileSystem.exists(path)) {
				trace("SUCCESS: Found .rpx at: " + path);
				File.saveBytes('$wupDir/code/Deltarune.rpx', File.getBytes(path));
				foundRpx = true;
				break;
			}
		}
		
		if (!foundRpx) {
			trace("ERROR: output.rpx not found! Checked: " + rpxPaths.join(", "));
			if (FileSystem.exists("output")) {
				trace("DEBUG - Contents of 'output/' directory: " + FileSystem.readDirectory("output").join(", "));
			} else {
				trace("DEBUG - 'output/' directory does not exist!");
			}
			return false;
		}
		
		var rootAssets = cwd + "/assets";
		var rootRomfs = cwd + "/assets/romfs";
		var rootMeta = cwd + "/resources/wiiu/meta";
		
		if (FileSystem.exists(rootAssets)) {
			recursiveCopyFiles(rootAssets, '$wupDir/content/assets');
		}
		if (FileSystem.exists(rootRomfs)) {
			recursiveCopyFiles(rootRomfs, '$wupDir/content');
		}
		
		var metaXml = '<?xml version="1.0" encoding="utf-8"?>\n' +
			'<menu type="complex" access="777">\n' +
			'  <version type="unsignedInt" length="4">33</version>\n' +
			'  <product_code type="string" length="32">WUP-N-HAXE</product_code>\n' +
			'  <content_platform type="string" length="32">WUP</content_platform>\n' +
			'  <company_code type="string" length="8">ZZZZ</company_code>\n' +
			'  <mastering_date type="string" length="32">2024-01-01 12.00.00</mastering_date>\n' +
			'  <logo_type type="unsignedInt" length="4">0</logo_type>\n' +
			'  <app_launch_type type="hexBinary" length="4">00000000</app_launch_type>\n' +
			'  <invisible_flag type="hexBinary" length="4">00000000</invisible_flag>\n' +
			'  <no_managed_flag type="hexBinary" length="4">00000000</no_managed_flag>\n' +
			'  <no_event_log type="hexBinary" length="4">00000000</no_event_log>\n' +
			'  <no_icon_database type="hexBinary" length="4">00000000</no_icon_database>\n' +
			'  <launching_flag type="hexBinary" length="4">00000004</launching_flag>\n' +
			'  <install_flag type="hexBinary" length="4">00000000</install_flag>\n' +
			'  <closing_msg type="unsignedInt" length="4">0</closing_msg>\n' +
			'  <title_version type="unsignedInt" length="4">0</title_version>\n' +
			'  <title_id type="hexBinary" length="8">' + titleId + '</title_id>\n' +
			'  <group_id type="hexBinary" length="4">00001000</group_id>\n' +
			'  <boss_id type="hexBinary" length="8">0000000000000000</boss_id>\n' +
			'  <os_version type="hexBinary" length="8">000500101000400A</os_version>\n' +
			'  <app_size type="hexBinary" length="8">0000000000000000</app_size>\n' +
			'  <common_save_size type="hexBinary" length="8">0000000000400000</common_save_size>\n' +
			'  <account_save_size type="hexBinary" length="8">0000000000200000</account_save_size>\n' +
			'  <common_boss_size type="hexBinary" length="8">0000000000000000</common_boss_size>\n' +
			'  <account_boss_size type="hexBinary" length="8">0000000000000000</account_boss_size>\n' +
			'  <save_no_rollback type="unsignedInt" length="4">0</save_no_rollback>\n' +
			'  <join_game_id type="hexBinary" length="4">00000000</join_game_id>\n' +
			'  <join_game_mode_mask type="hexBinary" length="8">0000000000000000</join_game_mode_mask>\n' +
			'  <bg_daemon_enable type="unsignedInt" length="4">1</bg_daemon_enable>\n' +
			'  <olv_accesskey type="unsignedInt" length="4">0</olv_accesskey>\n' +
			'  <wood_tin type="unsignedInt" length="4">0</wood_tin>\n' +
			'  <e_manual type="unsignedInt" length="4">1</e_manual>\n' +
			'  <e_manual_version type="unsignedInt" length="4">0</e_manual_version>\n' +
			'  <region type="hexBinary" length="4">FFFFFFFF</region>\n' +
			'  <pc_cero type="unsignedInt" length="4">0</pc_cero>\n' +
			'  <pc_esrb type="unsignedInt" length="4">0</pc_esrb>\n' +
			'  <pc_bbfc type="unsignedInt" length="4">192</pc_bbfc>\n' +
			'  <pc_usk type="unsignedInt" length="4">0</pc_usk>\n' +
			'  <pc_pegi_gen type="unsignedInt" length="4">0</pc_pegi_gen>\n' +
			'  <pc_pegi_fin type="unsignedInt" length="4">192</pc_pegi_fin>\n' +
			'  <pc_pegi_prt type="unsignedInt" length="4">0</pc_pegi_prt>\n' +
			'  <pc_pegi_bbfc type="unsignedInt" length="4">0</pc_pegi_bbfc>\n' +
			'  <pc_cob type="unsignedInt" length="4">0</pc_cob>\n' +
			'  <pc_grb type="unsignedInt" length="4">192</pc_grb>\n' +
			'  <pc_cgsrr type="unsignedInt" length="4">192</pc_cgsrr>\n' +
			'  <pc_oflc type="unsignedInt" length="4">0</pc_oflc>\n' +
			'  <pc_reserved0 type="unsignedInt" length="4">192</pc_reserved0>\n' +
			'  <pc_reserved1 type="unsignedInt" length="4">192</pc_reserved1>\n' +
			'  <pc_reserved2 type="unsignedInt" length="4">192</pc_reserved2>\n' +
			'  <pc_reserved3 type="unsignedInt" length="4">192</pc_reserved3>\n' +
			'  <ext_dev_nunchaku type="unsignedInt" length="4">0</ext_dev_nunchaku>\n' +
			'  <ext_dev_classic type="unsignedInt" length="4">0</ext_dev_classic>\n' +
			'  <ext_dev_urcc type="unsignedInt" length="4">0</ext_dev_urcc>\n' +
			'  <ext_dev_board type="unsignedInt" length="4">0</ext_dev_board>\n' +
			'  <ext_dev_usb_keyboard type="unsignedInt" length="4">0</ext_dev_usb_keyboard>\n' +
			'  <ext_dev_etc type="unsignedInt" length="4">0</ext_dev_etc>\n' +
			'  <ext_dev_etc_name type="string" length="512">EtcDevice</ext_dev_etc_name>\n' +
			'  <eula_version type="unsignedInt" length="4">0</eula_version>\n' +
			'  <drc_use type="unsignedInt" length="4">1</drc_use>\n' +
			'  <network_use type="unsignedInt" length="4">0</network_use>\n' +
			'  <online_account_use type="unsignedInt" length="4">0</online_account_use>\n' +
			'  <direct_boot type="unsignedInt" length="4">0</direct_boot>\n' +
			'  <reserved_flag0 type="hexBinary" length="4">00000000</reserved_flag0>\n' +
			'  <reserved_flag1 type="hexBinary" length="4">00000000</reserved_flag1>\n' +
			'  <reserved_flag2 type="hexBinary" length="4">00000000</reserved_flag2>\n' +
			'  <reserved_flag3 type="hexBinary" length="4">00000000</reserved_flag3>\n' +
			'  <reserved_flag4 type="hexBinary" length="4">00000000</reserved_flag4>\n' +
			'  <reserved_flag5 type="hexBinary" length="4">00000000</reserved_flag5>\n' +
			'  <reserved_flag6 type="hexBinary" length="4">00000003</reserved_flag6>\n' +
			'  <reserved_flag7 type="hexBinary" length="4">00000000</reserved_flag7>\n' +
			'  <longname_ja type="string" length="512">' + project.metadata.title + '</longname_ja>\n' +
			'  <longname_en type="string" length="512">' + project.metadata.title + '</longname_en>\n' +
			'  <longname_fr type="string" length="512">' + project.metadata.title + '</longname_fr>\n' +
			'  <longname_de type="string" length="512">' + project.metadata.title + '</longname_de>\n' +
			'  <longname_it type="string" length="512">' + project.metadata.title + '</longname_it>\n' +
			'  <longname_es type="string" length="512">' + project.metadata.title + '</longname_es>\n' +
			'  <longname_zhs type="string" length="512">' + project.metadata.title + '</longname_zhs>\n' +
			'  <longname_ko type="string" length="512">' + project.metadata.title + '</longname_ko>\n' +
			'  <longname_nl type="string" length="512">' + project.metadata.title + '</longname_nl>\n' +
			'  <longname_pt type="string" length="512">' + project.metadata.title + '</longname_pt>\n' +
			'  <longname_ru type="string" length="512">' + project.metadata.title + '</longname_ru>\n' +
			'  <longname_zht type="string" length="512">' + project.metadata.title + '</longname_zht>\n' +
			'  <shortname_ja type="string" length="256">' + project.metadata.title + '</shortname_ja>\n' +
			'  <shortname_en type="string" length="256">' + project.metadata.title + '</shortname_en>\n' +
			'  <shortname_fr type="string" length="256">' + project.metadata.title + '</shortname_fr>\n' +
			'  <shortname_de type="string" length="256">' + project.metadata.title + '</shortname_de>\n' +
			'  <shortname_it type="string" length="256">' + project.metadata.title + '</shortname_it>\n' +
			'  <shortname_es type="string" length="256">' + project.metadata.title + '</shortname_es>\n' +
			'  <shortname_zhs type="string" length="256">' + project.metadata.title + '</shortname_zhs>\n' +
			'  <shortname_ko type="string" length="256">' + project.metadata.title + '</shortname_ko>\n' +
			'  <shortname_nl type="string" length="256">' + project.metadata.title + '</shortname_nl>\n' +
			'  <shortname_pt type="string" length="256">' + project.metadata.title + '</shortname_pt>\n' +
			'  <shortname_ru type="string" length="256">' + project.metadata.title + '</shortname_ru>\n' +
			'  <shortname_zht type="string" length="256">' + project.metadata.title + '</shortname_zht>\n' +
			'  <publisher_ja type="string" length="256">' + project.metadata.author + '</publisher_ja>\n' +
			'  <publisher_en type="string" length="256">' + project.metadata.author + '</publisher_en>\n' +
			'  <publisher_fr type="string" length="256">' + project.metadata.author + '</publisher_fr>\n' +
			'  <publisher_de type="string" length="256">' + project.metadata.author + '</publisher_de>\n' +
			'  <publisher_it type="string" length="256">' + project.metadata.author + '</publisher_it>\n' +
			'  <publisher_es type="string" length="256">' + project.metadata.author + '</publisher_es>\n' +
			'  <publisher_zhs type="string" length="256">' + project.metadata.author + '</publisher_zhs>\n' +
			'  <publisher_ko type="string" length="256">' + project.metadata.author + '</publisher_ko>\n' +
			'  <publisher_nl type="string" length="256">' + project.metadata.author + '</publisher_nl>\n' +
			'  <publisher_pt type="string" length="256">' + project.metadata.author + '</publisher_pt>\n' +
			'  <publisher_ru type="string" length="256">' + project.metadata.author + '</publisher_ru>\n' +
			'  <publisher_zht type="string" length="256">' + project.metadata.author + '</publisher_zht>\n' +
			'  <add_on_unique_id0 type="hexBinary" length="4">00000000</add_on_unique_id0>\n' +
			'  <add_on_unique_id1 type="hexBinary" length="4">00000000</add_on_unique_id1>\n' +
			'  <add_on_unique_id2 type="hexBinary" length="4">00000000</add_on_unique_id2>\n' +
			'  <add_on_unique_id3 type="hexBinary" length="4">00000000</add_on_unique_id3>\n' +
			'  <add_on_unique_id4 type="hexBinary" length="4">00000000</add_on_unique_id4>\n' +
			'  <add_on_unique_id5 type="hexBinary" length="4">00000000</add_on_unique_id5>\n' +
			'  <add_on_unique_id6 type="hexBinary" length="4">00000000</add_on_unique_id6>\n' +
			'  <add_on_unique_id7 type="hexBinary" length="4">00000000</add_on_unique_id7>\n' +
			'  <add_on_unique_id8 type="hexBinary" length="4">00000000</add_on_unique_id8>\n' +
			'  <add_on_unique_id9 type="hexBinary" length="4">00000000</add_on_unique_id9>\n' +
			'  <add_on_unique_id10 type="hexBinary" length="4">00000000</add_on_unique_id10>\n' +
			'  <add_on_unique_id11 type="hexBinary" length="4">00000000</add_on_unique_id11>\n' +
			'  <add_on_unique_id12 type="hexBinary" length="4">00000000</add_on_unique_id12>\n' +
			'  <add_on_unique_id13 type="hexBinary" length="4">00000000</add_on_unique_id13>\n' +
			'  <add_on_unique_id14 type="hexBinary" length="4">00000000</add_on_unique_id14>\n' +
			'  <add_on_unique_id15 type="hexBinary" length="4">00000000</add_on_unique_id15>\n' +
			'  <add_on_unique_id16 type="hexBinary" length="4">00000000</add_on_unique_id16>\n' +
			'  <add_on_unique_id17 type="hexBinary" length="4">00000000</add_on_unique_id17>\n' +
			'  <add_on_unique_id18 type="hexBinary" length="4">00000000</add_on_unique_id18>\n' +
			'  <add_on_unique_id19 type="hexBinary" length="4">00000000</add_on_unique_id19>\n' +
			'  <add_on_unique_id20 type="hexBinary" length="4">00000000</add_on_unique_id20>\n' +
			'  <add_on_unique_id21 type="hexBinary" length="4">00000000</add_on_unique_id21>\n' +
			'  <add_on_unique_id22 type="hexBinary" length="4">00000000</add_on_unique_id22>\n' +
			'  <add_on_unique_id23 type="hexBinary" length="4">00000000</add_on_unique_id23>\n' +
			'  <add_on_unique_id24 type="hexBinary" length="4">00000000</add_on_unique_id24>\n' +
			'  <add_on_unique_id25 type="hexBinary" length="4">00000000</add_on_unique_id25>\n' +
			'  <add_on_unique_id26 type="hexBinary" length="4">00000000</add_on_unique_id26>\n' +
			'  <add_on_unique_id27 type="hexBinary" length="4">00000000</add_on_unique_id27>\n' +
			'  <add_on_unique_id28 type="hexBinary" length="4">00000000</add_on_unique_id28>\n' +
			'  <add_on_unique_id29 type="hexBinary" length="4">00000000</add_on_unique_id29>\n' +
			'  <add_on_unique_id30 type="hexBinary" length="4">00000000</add_on_unique_id30>\n' +
			'  <add_on_unique_id31 type="hexBinary" length="4">00000000</add_on_unique_id31>\n' +
			'</menu>';
		File.saveContent('$wupDir/meta/meta.xml', metaXml);
		
		if (!FileSystem.exists('$rootAssets/icon.png')) {
			trace("ERROR: " + rootAssets + "/icon.png is missing!");
			trace("The Wii U requires this file to generate the system menu icons.");
			trace("Please add an 'icon.png' to your root 'assets/' folder and rebuild.");
			return false;
		}
		
		trace("Generating meta images from " + rootAssets + "/icon.png...");
		execute('convert "' + rootAssets + '/icon.png" -resize 128x128 "' + wupDir + '/meta/iconTex.tga"');
		
		if (FileSystem.exists('$rootAssets/banner.png')) {
			execute('convert "' + rootAssets + '/banner.png" -resize 854x480 "' + wupDir + '/meta/bootDrcTex.tga"');
			execute('convert "' + rootAssets + '/banner.png" -resize 1280x720 "' + wupDir + '/meta/bootTvTex.tga"');
		} else {
			trace("Warning: banner.png not found in assets/, using icon.png for boot screens.");
			execute('convert "' + rootAssets + '/icon.png" -resize 854x480 "' + wupDir + '/meta/bootDrcTex.tga"');
			execute('convert "' + rootAssets + '/icon.png" -resize 1280x720 "' + wupDir + '/meta/bootTvTex.tga"');
		}

		if (FileSystem.exists('$rootMeta/bootLogoTex.tga')) {
			File.saveBytes('$wupDir/meta/bootLogoTex.tga', File.getBytes('$rootMeta/bootLogoTex.tga'));
			trace("Added custom bootLogoTex.tga");
		}
		if (FileSystem.exists('$rootMeta/bootSound.btsnd')) {
			File.saveBytes('$wupDir/meta/bootSound.btsnd', File.getBytes('$rootMeta/bootSound.btsnd'));
			trace("Added custom bootSound.btsnd");
		}
		
		if (!FileSystem.exists('$wupDir/meta/iconTex.tga') || 
		    !FileSystem.exists('$wupDir/meta/bootDrcTex.tga') || 
		    !FileSystem.exists('$wupDir/meta/bootTvTex.tga')) {
			trace("ERROR: Failed to generate .tga files!");
			trace("Make sure 'imagemagick' is installed in the workflow and the source images are valid.");
			return false;
		}
		
		trace("Meta images generated successfully!");
		
		var appXml = '<?xml version="1.0" encoding="utf-8"?>\n' +
			'<app type="complex" access="777">\n' +
			'  <version type="unsignedInt" length="4">16</version>\n' +
			'  <os_version type="hexBinary" length="8">000500101000400A</os_version>\n' +
			'  <title_id type="hexBinary" length="8">' + titleId + '</title_id>\n' +
			'  <title_version type="hexBinary" length="2">0000</title_version>\n' +
			'  <sdk_version type="unsignedInt" length="4">21213</sdk_version>\n' +
			'  <app_type type="hexBinary" length="4">80000000</app_type>\n' +
			'  <group_id type="hexBinary" length="4">00001000</group_id>\n' +
			'  <os_mask type="hexBinary" length="32">0000000000000000000000000000000000000000000000000000000000000000</os_mask>\n' +
			'  <common_id type="hexBinary" length="8">0000000000000000</common_id>\n' +
			'</app>';
		File.saveContent('$wupDir/code/app.xml', appXml);
		
		var cosXml = '<?xml version="1.0" encoding="utf-8"?>\n' +
			'<app type="complex" access="777">\n' +
			'  <version type="unsignedInt" length="4">20</version>\n' +
			'  <cmdFlags type="unsignedInt" length="4">0</cmdFlags>\n' +
			'  <argstr type="string" length="4096">Deltarune.rpx</argstr>\n' +
			'  <avail_size type="hexBinary" length="4">00000000</avail_size>\n' +
			'  <codegen_size type="hexBinary" length="4">00000000</codegen_size>\n' +
			'  <codegen_core type="hexBinary" length="4">00000001</codegen_core>\n' +
			'  <max_size type="hexBinary" length="4">80000000</max_size>\n' +
			'  <max_codesize type="hexBinary" length="4">0e000000</max_codesize>\n' +
			'  <overlay_arena type="hexBinary" length="4">00000000</overlay_arena>\n' +
			'  <default_stack0_size type="hexBinary" length="4">00000000</default_stack0_size>\n' +
			'  <default_stack1_size type="hexBinary" length="4">00000000</default_stack1_size>\n' +
			'  <default_stack2_size type="hexBinary" length="4">00000000</default_stack2_size>\n' +
			'  <default_redzone0_size type="hexBinary" length="4">00000000</default_redzone0_size>\n' +
			'  <default_redzone1_size type="hexBinary" length="4">00000000</default_redzone1_size>\n' +
			'  <default_redzone2_size type="hexBinary" length="4">00000000</default_redzone2_size>\n' +
			'  <exception_stack0_size type="hexBinary" length="4">00001000</exception_stack0_size>\n' +
			'  <exception_stack1_size type="hexBinary" length="4">00001000</exception_stack1_size>\n' +
			'  <exception_stack2_size type="hexBinary" length="4">00001000</exception_stack2_size>\n' +
			'  <num_codearea_heap_blocks type="unsignedInt" length="4">0</num_codearea_heap_blocks>\n' +
			'  <num_workarea_heap_blocks type="unsignedInt" length="4">0</num_workarea_heap_blocks>\n' +
			'</app>';
		File.saveContent('$wupDir/code/cos.xml', cosXml);
		
		var commonKey = Sys.getEnv("WIIU_COMMON_KEY");
		
		var outDir = "../installable_build/" + titleId;
		makeDirs(outDir);
		
		var cmd = "java -jar /opt/devkitpro/tools/bin/NUSPacker.jar -in \"" + wupDir + "\" -out \"" + outDir + "\"";
		
		if (commonKey != null) {
			var cleanKey = commonKey.trim();
			if (cleanKey.length == 32) {
				cmd += ' -encryptKeyWith "' + cleanKey + '"';
				trace("Successfully using WIIU_COMMON_KEY for encryption.");
			} else {
				trace("Warning: WIIU_COMMON_KEY is set but is " + cleanKey.length + " characters long (needs 32). Building unencrypted.");
			}
		} else {
			trace("Warning: WIIU_COMMON_KEY not set. Building unencrypted WUP.");
		}

		var success = execute(cmd);

		if (success) {
			trace("WUP package built successfully at " + outDir + " !");
			return true;
		} else {
			trace("ERROR: NUSPacker failed to build the WUP package.");
			return false;
		}
	}

	static function main() {
		haxe.Log.trace = (v, ?infos) -> Sys.println(v);
		Sys.println("========================================================");
		Sys.println("  Haxe3DS Unified Console Tool");
		Sys.println("========================================================");

		var args = Sys.args();
		if (args.length == 1) {
			Sys.println("\nArgs (haxelib run haxe3ds [arg]):");
			Sys.println("\t[-g]: Generates a New JSON for Console format.");
			Sys.println("\t[-c]: Compiles to a compatible working application.");
			Sys.println("\t[-e]: Calls addr2line for Error Lookup.");
			Sys.println("\t[-s]: Wrapper for Sending the built application.");
			Sys.println("\tUse -Dnx or -D3ds for 3DS, and -Dwiiu or -Dcafe for Wii U.\n");
			return;
		}

		{
			var path = args[args.length - 1];
			Sys.setCwd(path);
			args.remove(path);
		}

		cwd = Sys.getCwd().replace("\\", "/");
		cwd = cwd.substr(0, cwd.length - 1);
		var isWiiU = args.contains("-Dwiiu") || args.contains("-Dcafe");

		switch args.shift() {
			case "-g":
				if (FileSystem.exists('3dsSettings.json') && !askForInput("3dsSettings.json EXISTS! Overwrite?")) return;
				var out:Haxe3DSProject = {
					settings: {
						deleteTempFiles: false,
						compileAsCIA: false,
						compileAsWUP: false,
						compileAsPlugin: false,
						defines: [],
						libraries: ["hxcpp"],
						linkOptions: { ip: "192.168.1.100", linkToConsole: false, openEmuIfTransferFailed: false },
						optimizations: { gFlag: false, o2Flag: true }
					},
					metadata: { title: "HaxeConsole", description: "Made with Haxe!", author: "Author" }
				};
				File.saveContent('3dsSettings.json', Json.stringify(out, null, "\t"));
				trace("Generated Console Settings Config!");

			case "-c":
				function sanityCheck(info:String, func:()->Bool, ngText:String = "") {
					var out = Sys.stdout();
					Sys.print('> $info...');
					if (func()) { out.writeString(" OK. \n"); } 
					else { out.writeString(' NG. $ngText \n'); Sys.exit(1); }
				}

				sanityCheck("Checking for Config", () -> FileSystem.exists("3dsSettings.json"), 'Run "-g" first.');
				
				var project:Haxe3DSProject = null;
				sanityCheck("Loading the Project", () -> {
					try { project = readConfig(); return true; } catch(_) { return false; }
				}, 'JSON is not Formatted Correctly!');

				var goodHaxeLibs:Array<String> = [];
				var flagsKey = isWiiU ? "[HAXEWIIU_FLAGS]" : "[HAXE3DS_FLAGS]";
				var attributes:Map<String, Array<String>> = [ flagsKey => [] ];

				if (isWiiU) {
					attributes[flagsKey] = ['-lHAXEWIIU', '-lwut', '-lcoreinit', '-lfs', '-lgx2', '-lhxcpp', '-Iexport/include', '-L[DKP_PATH]/wut/lib', '-I[DKP_PATH]/wut/include', '-I[DKP_PATH]/wut/include/wut', '-L[DKP_PATH]/portlibs/wiiu/lib', '-I[DKP_PATH]/portlibs/wiiu/include', '-lSDL2'];
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

				if (isWiiU) {
					var metaXml = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n' +
						'<app version="1">\n' +
						'  <name>${project.metadata.title}</name>\n' +
						'  <coder>${project.metadata.author}</coder>\n' +
						'  <version>1.0.0</version>\n' +
						'  <release_date>20240101000000</release_date>\n' +
						'  <short_description>${project.metadata.description}</short_description>\n' +
						'  <long_description>${project.metadata.description}</long_description>\n' +
						'</app>';
					File.saveContent("export/meta.xml", metaXml);
					if (FileSystem.exists("assets/icon.png")) File.saveBytes("export/icon.png", File.getBytes("assets/icon.png"));
				}

				var targetDefine = isWiiU ? (project.settings.compileAsPlugin ? "-D IS_WUPS_PLUGIN" : "-D IS_WUT_RPX") : (project.settings.compileAsCIA ? "-D IS_CIA" : "-D IS_3DSX");
				var platformDefine = isWiiU ? "-D wiiu\n-D cafe\n-D HAXEWIIU" : "-D nx\n-D haxe3ds";
				
				HXML_TEMP = HXML_TEMP.replace("{1}", [for (lib in goodHaxeLibs) if (lib != "hxcpp") '-lib $lib\n-D ${lib.toUpperCase()}'].join("\n"));
				HXML_TEMP = HXML_TEMP.replace("{2}", targetDefine + "\n" + platformDefine);
				
				if (isWiiU) {
					HXML_TEMP = HXML_TEMP.replace("-D HAXE3DS\n", "");
					HXML_TEMP = HXML_TEMP.replace("-D HAXE3DS", "");
				}
				
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
							for (flag in flags) {
								var cleanFlag = flag.replace("\\", "/").trim();
								values += '<flag value=\'' + cleanFlag + '\'/>\n';
							}
							xmlContent = xmlContent.replace(key, values);
						}
						File.saveContent('$toolchainPath/linux-toolchain.xml', toDKPPath(xmlContent));
						return true;
					} catch(error) { trace(error); return false; }
				}, "Something went wrong!");

				trace("Initial Setup Complete! Compiling Library");
				sanityCheck("Compiling using the custom HXML file", () -> execute("haxe build.hxml"), "Failed to compile!");
				
				Sys.setCwd('export');
				
				var makefileName = isWiiU ? (project.settings.compileAsPlugin ? "Makefile.wups" : "Makefile.wut") : "Makefile";
				
				trace("=== DEBUG: Makefile Selection ===");
				trace("Platform detected: " + (isWiiU ? "Wii U" : "3DS"));
				trace("Looking for source Makefile in parent dir: ../" + makefileName);
				
				if (FileSystem.exists('../$makefileName')) {
					trace("SUCCESS: Found " + makefileName + ", copying to export/Makefile");
					File.copy('../$makefileName', 'Makefile');
				} else {
					trace("WARNING: " + makefileName + " NOT FOUND in parent directory!");
				}

				if (FileSystem.exists('Makefile')) {
					var content = File.getContent('Makefile');
					var lines = content.split("\n");
					trace("First 3 lines of the active Makefile to verify it's correct:");
					for (i in 0...Std.int(Math.min(3, lines.length))) {
						trace("  > " + lines[i]);
					}
				} else {
					trace("CRITICAL ERROR: No Makefile exists in the export directory at all!");
				}

				var makeTarget = isWiiU ? (project.settings.compileAsWUP ? "rpx" : (project.settings.compileAsPlugin ? "wps" : "rpx")) : (project.settings.compileAsCIA ? "cia" : "3dsx");
				trace("Make target to execute: " + makeTarget);
				trace("=================================");
				
				sanityCheck("Finally Compiling to Working Application", () -> execute('make clean && make $makeTarget'), "Failed to compile!");

				if (isWiiU && project.settings.compileAsWUP) {
					sanityCheck("Building Installable WUP Package", () -> buildWUP(project, "0005000010100100"), "Failed to build WUP!");
				}

				recursiveCopyFiles("output", "../buildFiles");
				Sys.setCwd("..");

				if (project.settings.deleteTempFiles) {
					recursiveRMTree("export");
					deleteFileIfExist("build.hxml");
				} else {
					recursiveRMTree("export/output");
				}
				trace("Successfully Compiled!");
				fileHandler(project, isWiiU);

			case "-s": 
				fileHandler(null, isWiiU);
			case "-e":
				var devkitpro = toDKPPath("[DKP_PATH]");
				var addr2line = isWiiU 
					? (Sys.systemName() == "Windows" ? '$devkitpro/devkitPPC/bin/powerpc-eabi-addr2line.exe' : '$devkitpro/devkitPPC/bin/powerpc-eabi-addr2line')
					: (Sys.systemName() == "Windows" ? '$devkitpro/devkitARM/bin/arm-none-eabi-addr2line.exe' : '$devkitpro/devkitARM/bin/arm-none-eabi-addr2line');
				execute('$addr2line -i -p -s -f -C -r -a -e buildFiles/output.elf ${args.join(" ")}');
		}
	}
}
