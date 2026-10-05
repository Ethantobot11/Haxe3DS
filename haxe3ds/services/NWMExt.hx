package haxe3ds.services;

#if HAXE3DS
@:cppInclude("3ds.h")
#end
class NWMExt {
	@:native("nwmExtInit")
	public static function init() {
		#if HAXE3DS #end
	}

	@:native("nwmExtExit")
	public static function exit() {
		#if HAXE3DS #end
	}

	public static var wireless(null, set):Bool;
	static function set_wireless(wireless):Bool {
		#if HAXE3DS untyped __cpp__('NWMEXT_ControlWirelessEnabled(wireless)'); #end
		return wireless;
	}
}
