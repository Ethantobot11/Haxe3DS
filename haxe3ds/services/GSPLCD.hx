package haxe3ds.services;

import haxe3ds.types.Result;
import cpp.UInt8;
import cpp.UInt32;

enum abstract GSPLCDScreen(Int) { var TOP = 1; var BOTTOM; var BOTH; }

#if HAXE3DS
@:cppInclude("haxe3ds_Utils.h")
#end
class GSPLCD {
	public static var LED(null, set):Bool;
	static function set_LED(LED):Bool {
		#if HAXE3DS untyped __cpp__('GSPLCD_SetLedForceOff(!LED)'); #end
		return LED;
	}

	public static var vendors(get, null):UInt8;
	static function get_vendors():UInt8 {
		#if HAXE3DS return untyped __cpp__('API_GETTER(u8, GSPLCD_GetVendors, 0)'); #else return 0; #end
	}

	public static inline function init() {
		#if HAXE3DS untyped __cpp__('gspLcdInit()'); #end
	}

	public static function setBacklight(screen:GSPLCDScreen, enable:Bool):Result {
		#if HAXE3DS return untyped __cpp__('enable ? GSPLCD_PowerOnBacklight(screen) : GSPLCD_PowerOffBacklight(screen)'); #else return 0; #end
	}

	public static function getScreenBrightness(screen:GSPLCDScreen):UInt8 {
		#if HAXE3DS
		var r:UInt32 = 0; untyped __cpp__('GSPLCD_GetBrightness(screen, &r)'); return r;
		#else return 0; #end
	}

	public static function setScreenBrightness(screen:GSPLCDScreen, brightness:UInt8):Result {
		#if HAXE3DS
		var res:Result = 0; untyped __cpp__('res = GSPLCD_SetBrightnessRaw(screen, (u32)(brightness < 16 ? 16 : brightness > 172 ? 172 : brightness))'); return res;
		#else return 0; #end
	}

	public static inline function exit() {
		#if HAXE3DS untyped __cpp__('gspLcdExit()'); #end
	}
}
