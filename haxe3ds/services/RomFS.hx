package haxe3ds.services;

import haxe3ds.types.Result;

#if HAXE3DS
@:cppInclude("3ds.h")
#end
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
