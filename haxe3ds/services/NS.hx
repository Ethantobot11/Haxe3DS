package haxe3ds.services;

import haxe3ds.types.Result;

#if HAXE3DS
@:cppInclude("3ds.h")
#end
class NS {
	public static inline function init():Result {
		#if HAXE3DS return untyped __cpp__('nsInit()'); #else return 0; #end
	}

	public static inline function exit() {
		#if HAXE3DS untyped __cpp__('nsExit()'); #end
	}

	public static inline function rebootSystem():Result {
		#if HAXE3DS return untyped __cpp__('NS_RebootSystem()'); #else return 0; #end
	}

	public static inline function terminate():Result {
		#if HAXE3DS return untyped __cpp__('NS_TerminateTitle()'); #else Sys.exit(0); return 0; #end
	}
}
