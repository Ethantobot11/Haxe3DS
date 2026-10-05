package haxe3ds;

import cpp.UInt64;
import cpp.UInt8;

#if HAXE3DS
@:cppInclude("3ds.h")
#else
@:cppInclude("wut.h")
@:cppInclude("coreinit/system.h")
#end
class OS {
	public static var time(get, null):UInt64;
	static function get_time():UInt64 {
		#if HAXE3DS
		return untyped __cpp__('osGetTime()');
		#else
		return untyped __cpp__('(uint64_t)(OSGetSystemTime() / (OSGetSystemInfo()->busSpeed / 4))');
		#end
	}

	public static var wifiStrength(get, null):UInt8;
	static function get_wifiStrength():UInt8 {
		#if HAXE3DS
		return untyped __cpp__('osGetWifiStrength()');
		#else
		return 3;
		#end
	}

	public static var sliderState3D(get, null):Float;
	static function get_sliderState3D():Float {
		#if HAXE3DS
		return untyped __cpp__('osGet3DSliderState()');
		#else
		return 0.0;
		#end
	}
}
