package haxe3ds;

#if HAXE3DS
@:headerInclude("3ds.h")
#end

class Env {
	public static var is3DSX(get, null):Bool;
	static inline function get_is3DSX():Bool {
		#if HAXE3DS
		return untyped __cpp__('envIsHomebrew()');
		#else
		return false;
		#end
	}

	public static var isUsing3DS(get, null):Bool;
	static function get_isUsing3DS():Bool {
		#if HAXE3DS
		var isLuma:Bool = false;
		untyped __cpp__('
			Handle lumaCheck;
			isLuma = R_SUCCEEDED(svcConnectToPort(&lumaCheck, "hb:ldr"));
			if(isLuma) svcCloseHandle(lumaCheck);
		');
		return isLuma;
		#else
		return false;
		#end
	}

	public static var isWiiU(get, null):Bool;
	static inline function get_isWiiU():Bool {
		#if HAXEWIIU
		return true;
		#else
		return false;
		#end
	}
}
