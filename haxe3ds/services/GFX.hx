package haxe3ds.services;

import haxe.Log;

#if HAXE3DS
@:headerInclude("3ds.h")
#end
class GFX {
	public static inline extern function init() {
		#if HAXE3DS
		untyped __cpp__('gfxInitDefault()');
		Log.trace = (v, ?infos) -> {
			final str = Log.formatOutput(v, infos);
			Sys.println(str);
			SVC.debugString(str);
		};
		#end
	}

	public static var current3D(get, set):Bool;
	static function get_current3D():Bool {
		#if HAXE3DS return untyped __cpp__('gfxIs3D()'); #else return false; #end
	}
	static function set_current3D(current3D):Bool {
		#if HAXE3DS untyped __cpp__('gfxSet3D(current3D)'); #end
		return current3D;
	}

	public static var isWide(get, set):Bool;
	static function get_isWide():Bool {
		#if HAXE3DS return untyped __cpp__('gfxIsWide()'); #else return false; #end
	}
	static function set_isWide(isWide):Bool {
		#if HAXE3DS untyped __cpp__('gfxSetWide(isWide)'); #end
		return isWide;
	}

	public static inline extern function exit() {
		#if HAXE3DS untyped __cpp__('gfxExit()'); #end
	}
}
