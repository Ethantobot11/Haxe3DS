package haxe3ds.services;

import haxe3ds.types.Result;
import cpp.UInt16;
import cpp.UInt32;

typedef ACProxy = { var enable:Bool; var host:String; var port:UInt16; var username:String; var password:String; }

enum abstract ACWifiStatus(UInt32) {
	var NONE; var SLOT_1; var SLOT_2; var SLOT_3 = 4; var USB_CONNECTOR = 8;
	var NINTENDO_ZONE_AP = 16; var WIFI_STATION = 32; var FREESPOT = 64; var HOTSPOT = 128; var TEMP_APP_SETTINGS = 256;
}

#if HAXE3DS
@:cppInclude("haxe3ds_Utils.h")
#end
class AC {
	public static var wifiStatus(get, null):ACWifiStatus;
	static function get_wifiStatus():ACWifiStatus {
		#if HAXE3DS return untyped __cpp__('API_GETTER(u32, ACU_GetWifiStatus, -1)'); #else return NONE; #end
	}

	public static var connected(get, null):Bool = false;
	static function get_connected():Bool {
		#if HAXE3DS return untyped __cpp__('API_GETTER(u32, ACU_GetStatus, 1) == 3'); #else return false; #end
	}

	public static var ssid(get, null):Null<String>;
	static function get_ssid():Null<String> {
		#if HAXE3DS
		untyped __cpp__('char s[32] = { 0}; RETURN_NULL_IF_FAILED(ACI_GetNetworkWirelessEssidSecuritySsid(s));');
		return untyped __cpp__('String(s)');
		#else return null; #end
	}

	public static var proxy(get, null):Null<ACProxy>;
	static function get_proxy():Null<ACProxy> {
		#if HAXE3DS
		untyped __cpp__('char host[0x100], user[0x100], pass[0x100]; RETURN_NULL_IF_FAILED(ACU_GetProxyHost(host)); RETURN_NULL_IF_FAILED(ACU_GetProxyUserName(user)); RETURN_NULL_IF_FAILED(ACU_GetProxyPassword(pass));');
		return {
			enable: untyped __cpp__('API_GETTER(bool, ACU_GetProxyEnable, false)'), host: untyped __cpp__('String(host)'),
			port: untyped __cpp__('API_GETTER(u16, ACU_GetProxyPort, 0)'), username: untyped __cpp__('String(user)'), password: untyped __cpp__('String(pass)')
		};
		#else return null; #end
	}

	public static function init():Result {
		#if HAXE3DS return untyped __cpp__('acInit()'); #else return 0; #end
	}

	public static function loadNetworkSetting(slot:UInt32):Result {
		#if HAXE3DS return untyped __cpp__('ACI_LoadNetworkSetting(slot)'); #else return 0; #end
	}

	public static function exit() {
		#if HAXE3DS untyped __cpp__('acExit()'); #end
	}
}
