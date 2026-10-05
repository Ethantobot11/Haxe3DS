package haxe3ds;

import sys.io.File;

class BuildInfo {
	public static var BUILD(get, null):Int;
	static function get_BUILD():Int {
		#if HAXE3DS
		try {
			return Std.parseInt(File.getContent("romfs:/haxe3ds/build")) ?? -1;
		} catch(e) {
			return -1;
		}
		#else
		return -1;
		#end
	}

	public static var VERSION(get, null):String;
	static function get_VERSION():String {
		#if HAXE3DS
		try {
			return File.getContent("romfs:/haxe3ds/version");
		} catch(e) {
			return "?";
		}
		#else
		return "?";
		#end
	}

	public static var DATE(get, null):Null<Date>;
	static function get_DATE() {
		#if HAXE3DS
		try {
			return Date.fromString(File.getContent("romfs:/haxe3ds/buildDate"));
		} catch(e) {
			return null;
		}
		#else
		return null;
		#end
	}
}
