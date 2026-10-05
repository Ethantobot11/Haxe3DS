package haxe3ds.services;

import cpp.UInt8;
import cpp.UInt16;
import cpp.UInt32;
import haxe3ds.types.Result;

#if HAXE3DS
@:cppInclude("haxe3ds_Utils.h")
#end
class PTMU {
	public static function init():Result {
		#if HAXE3DS return untyped __cpp__('ptmuInit()'); #else return 0; #end
	}

	@:native("ptmuExit")
	public static function exit() {
		#if HAXE3DS #end
	}

	public static var shellClosed(get, null):Bool;
	static function get_shellClosed():Bool {
		#if HAXE3DS return untyped __cpp__("API_GETTER(u8, PTMU_GetShellState, 1) == 0"); #else return false; #end
	}

	public static var batteryLevel(get, null):UInt8;
	static function get_batteryLevel():UInt8 {
		#if HAXE3DS return untyped __cpp__("API_GETTER(u8, PTMU_GetBatteryLevel, 5)"); #else return 5; #end
	}

	public static var isCharging(get, null):Bool;
	static function get_isCharging():Bool {
		#if HAXE3DS return untyped __cpp__("API_GETTER(u8, PTMU_GetBatteryChargeState, 1)"); #else return true; #end
	}

	public static var isWalking(get, null):Bool;
	static function get_isWalking():Bool {
		#if HAXE3DS return untyped __cpp__("API_GETTER(u8, PTMU_GetPedometerState, 0)"); #else return false; #end
	}

	public static function getStepHistory(hours:UInt32):UInt16 {
		#if HAXE3DS
		var ret:UInt16 = 0; untyped __cpp__("PTMU_GetStepHistory(hours, &ret)"); return ret;
		#else return 0; #end
	}

	public static var totalSteps(get, null):UInt32;
	static function get_totalSteps():UInt32 {
		#if HAXE3DS return untyped __cpp__("API_GETTER(u32, PTMU_GetTotalStepCount, 0)"); #else return 0; #end
	}

	public static var adapterState(get, null):Bool;
	static function get_adapterState():Bool {
		#if HAXE3DS return untyped __cpp__("API_GETTER(bool, PTMU_GetAdapterState, 0)"); #else return true; #end
	}
}

#if HAXE3DS
@:cppInclude("3ds.h")
#end
class PTMSYSM {
	public static function init():Result {
		#if HAXE3DS return untyped __cpp__('ptmSysmInit()'); #else return 0; #end
	}

	@:native("ptmSysmExit")
	public static function exit() {
		#if HAXE3DS #end
	}

	public static function requestSleep():Result {
		#if HAXE3DS return untyped __cpp__('PTMSYSM_RequestSleep()'); #else return 0; #end
	}

	public static function clearStepHistory():Result {
		#if HAXE3DS return untyped __cpp__('PTMSYSM_ClearStepHistory()'); #else return 0; #end
	}

	public static function clearPlayHistory():Result {
		#if HAXE3DS return untyped __cpp__('PTMSYSM_ClearPlayHistory()'); #else return 0; #end
	}

	public static function invalidateSystemTime():Result {
		#if HAXE3DS return untyped __cpp__('PTMSYSM_InvalidateSystemTime()'); #else return 0; #end
	}
}
