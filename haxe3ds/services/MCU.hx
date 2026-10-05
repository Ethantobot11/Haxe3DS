package haxe3ds.services;

import haxe3ds.types.Result;
import cpp.UInt8;

#if HAXE3DS
@:cppInclude("haxe3ds_Utils.h")
#end
class MCUWUC {
	public static function init():Result {
		#if HAXE3DS return untyped __cpp__('mcuHwcInit()'); #else return 0; #end
	}

	@:native("mcuHwcExit")
	public static function exit() {
		#if HAXE3DS #end
	}

	public static var batteryVoltage(get, null):UInt8 = 0;
	static function get_batteryVoltage():UInt8 {
		#if HAXE3DS return untyped __cpp__('API_GETTER(u8, MCUHWC_GetBatteryVoltage, 0)'); #else return 0; #end
	}

	public static var batteryPercentage(get, null):UInt8;
	static function get_batteryPercentage():UInt8 {
		#if HAXE3DS return untyped __cpp__('API_GETTER(u8, MCUHWC_GetBatteryLevel, 0)'); #else return 100; #end
	}

	public static var wifiLEDState(null, set):Bool;
	static function set_wifiLEDState(wifiLEDState):Bool {
		#if HAXE3DS untyped __cpp__('MCUHWC_SetWifiLedState(wifiLEDState)'); #end
		return wifiLEDState;
	}

	public static var mcuVersion(get, null):Null<String>;
	static function get_mcuVersion():Null<String> {
		#if HAXE3DS
		untyped __cpp__('u8 a, b; MCUHWC_GetFwVerHigh(&a); MCUHWC_GetFwVerLow(&b); char out[8]; std::snprintf(out, 8, "%u-%u", a, b);');
		return untyped __cpp__('String(out)');
		#else return "0-0"; #end
	}

	public static var temperature(get, null):Null<UInt8>;
	static function get_temperature():Null<UInt8> {
		#if HAXE3DS
		untyped __cpp__('u32 *cmdbuf = getThreadCommandBuffer(); cmdbuf[0] = IPC_MakeHeader(0xE,2,0); RETURN_NULL_IF_FAILED(svcSendSyncRequest(*mcuHwcGetSessionHandle()));');
		var ret:UInt8 = untyped __cpp__('cmdbuf[2]'); return ret;
		#else return 0; #end
	}
}
