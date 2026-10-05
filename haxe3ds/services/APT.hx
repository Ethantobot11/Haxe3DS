package haxe3ds.services;

import cpp.UInt32;
import cpp.UInt64;
import haxe3ds.types.Result;

#if !wiiu
@:include("3ds.h")
#end
#if HAXEWIIU
@:include("vpad/input.h")
@:include("proc_ui/procui.h")
@:include("coreinit/exit.h")
#end

class APT {
	public static var isNew3DS(get, null):Bool;
	static function get_isNew3DS():Bool {
		#if !wiiu
		return untyped __cpp__('API_GETTER(bool, APT_CheckNew3DS, false)');
		#else
		return true;
		#end
	}

	public static var programID(get, null):UInt64;
	static function get_programID():UInt64 {
		#if !wiiu
		return untyped __cpp__('API_GETTER(u64, APT_GetProgramID, 0)');
		#else
		return untyped __cpp__('0x0005000010100000ULL');
		#end
	}

	public static var homeMenu(get, set):Bool;
	static function get_homeMenu():Bool {
		#if !wiiu
		return untyped __cpp__('aptIsHomeAllowed()');
		#else
		return true;
		#end
	}
	static function set_homeMenu(homeMenu):Bool {
		#if !wiiu
		untyped __cpp__('aptSetHomeAllowed(homeMenu)');
		#end
		return homeMenu;
	}

	public static inline function jumpToHomeMenu() {
		#if !wiiu
		untyped __cpp__('aptJumpToHomeMenu()');
		#else
		untyped __cpp__('exit(0);');
		#end
	}

	public static function mainLoop():Bool {
		#if !wiiu
		HID.scanInput();
		#if CITROENGINE
		return untyped __cpp__("aptMainLoop()");
		#else
		return untyped __cpp__("gspWaitForVBlank(), gfxSwapBuffers(), aptMainLoop()");
		#end
		#else
		HID.scanInput();
		return untyped __cpp__('ProcUIProcessMessages(true) != PROCUI_STATUS_EXITING');
		#end
	}

	public static function isActive():Bool {
		#if !wiiu
		return untyped __cpp__('aptIsActive()');
		#else
		return untyped __cpp__('ProcUIProcessMessages(false) != PROCUI_STATUS_EXITING');
		#end
	}
}
