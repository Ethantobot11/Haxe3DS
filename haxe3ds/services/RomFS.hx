package haxe3ds.services;

import haxe3ds.types.Result;

@:cppInclude("3ds.h")
@:cppInclude("coreinit.h")
class RomFS {
	public static inline function init():Result {
		#if HAXE3DS
		return untyped __cpp__('romfsInit()');
		#else
		return 0; 
		#end
	}

	public static inline function exit():Result {
		#if HAXE3DS
		return untyped __cpp__('romfsExit()');
		#else
		return 0;
		#end
	}
}
