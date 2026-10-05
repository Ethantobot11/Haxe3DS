package haxe3ds.services;

import cpp.UInt8;
import cpp.UInt32;

class HIDKey {
	@:native("KEY_START") public static var START:UInt32;
	@:native("KEY_A") public static var A:UInt32;
	@:native("KEY_B") public static var B:UInt32;
	@:native("KEY_Y") public static var Y:UInt32;
	@:native("KEY_X") public static var X:UInt32;
	@:native("KEY_SELECT") public static var SELECT:UInt32;
	@:native("KEY_DLEFT") public static var DLEFT:UInt32;
	@:native("KEY_DDOWN") public static var DDOWN:UInt32;
	@:native("KEY_DUP") public static var DUP:UInt32;
	@:native("KEY_DRIGHT") public static var DRIGHT:UInt32;
	@:native("KEY_R") public static var R:UInt32;
	@:native("KEY_L") public static var L:UInt32;
	@:native("KEY_ZL") public static var ZL:UInt32;
	@:native("KEY_ZR") public static var ZR:UInt32;
	@:native("KEY_TOUCH") public static var TOUCH:UInt32;
	@:native("KEY_CSTICK_RIGHT") public static var CSTICK_RIGHT:UInt32;
	@:native("KEY_CSTICK_LEFT") public static var CSTICK_LEFT:UInt32;
	@:native("KEY_CSTICK_UP") public static var CSTICK_UP:UInt32;
	@:native("KEY_CSTICK_DOWN") public static var CSTICK_DOWN:UInt32;
	@:native("KEY_CPAD_RIGHT") public static var CPAD_RIGHT:UInt32;
	@:native("KEY_CPAD_LEFT") public static var CPAD_LEFT:UInt32;
	@:native("KEY_CPAD_UP") public static var CPAD_UP:UInt32;
	@:native("KEY_CPAD_DOWN") public static var CPAD_DOWN:UInt32;
	@:native("KEY_UP") public static var UP:UInt32;
	@:native("KEY_DOWN") public static var DOWN:UInt32;
	@:native("KEY_LEFT") public static var LEFT:UInt32;
	@:native("KEY_RIGHT") public static var RIGHT:UInt32;
}

typedef CirclePosition = { var dx:Int; var dy:Int; }
typedef TouchPosition = { var px:Int; var py:Int; }
typedef AccelVector = { var x:Int; var y:Int; var z:Int; }
typedef AngularRate = { var x:Int; var y:Int; var z:Int; }

#if !wiiu
@:headerInclude("3ds.h")
#else
@:headerInclude("vpad/input.h")
@:headerInclude("vpadbase/base.h")
#end
class HID {
	public static inline function scanInput() {
		#if !wiiu
		untyped __cpp__("hidScanInput(); irrstScanInput()");
		#else
		untyped __cpp__('
			static VPADStatus vpadStatus;
			static VPADReadError vpadError;
			VPADRead(VPAD_CHAN_0, &vpadStatus, 1, &vpadError);
		');
		#end
	}

	public static inline function keyPressed(key:UInt32):Bool {
		#if !wiiu
		return untyped __cpp__("(hidKeysDown() & ({0}))", key);
		#else
		return untyped __cpp__('
			static VPADStatus vpadStatus;
			static VPADReadError vpadError;
			VPADRead(VPAD_CHAN_0, &vpadStatus, 1, &vpadError);
			uint32_t vpadKey = 0;
			switch({0}) {
				case 0x00000001: vpadKey = VPAD_BUTTON_A; break;
				case 0x00000002: vpadKey = VPAD_BUTTON_B; break;
				case 0x00000004: vpadKey = VPAD_BUTTON_X; break;
				case 0x00000008: vpadKey = VPAD_BUTTON_Y; break;
				case 0x00000010: vpadKey = VPAD_BUTTON_LEFT; break;
				case 0x00000020: vpadKey = VPAD_BUTTON_RIGHT; break;
				case 0x00000040: vpadKey = VPAD_BUTTON_UP; break;
				case 0x00000080: vpadKey = VPAD_BUTTON_DOWN; break;
				case 0x00000100: vpadKey = VPAD_BUTTON_ZL; break;
				case 0x00000200: vpadKey = VPAD_BUTTON_ZR; break;
				case 0x00000400: vpadKey = VPAD_BUTTON_L; break;
				case 0x00000800: vpadKey = VPAD_BUTTON_R; break;
				case 0x00001000: vpadKey = VPAD_BUTTON_PLUS; break;
				case 0x00002000: vpadKey = VPAD_BUTTON_MINUS; break;
				default: vpadKey = 0; break;
			}
			return (vpadStatus.trigger & vpadKey) != 0;
		', key);
		#end
	}

	public static inline function keyHeld(key:UInt32):Bool {
		#if !wiiu
		return untyped __cpp__("(hidKeysHeld() & ({0}))", key);
		#else
		return untyped __cpp__('
			static VPADStatus vpadStatus;
			static VPADReadError vpadError;
			VPADRead(VPAD_CHAN_0, &vpadStatus, 1, &vpadError);
			uint32_t vpadKey = 0;
			switch({0}) {
				case 0x00000001: vpadKey = VPAD_BUTTON_A; break;
				case 0x00000002: vpadKey = VPAD_BUTTON_B; break;
				case 0x00000004: vpadKey = VPAD_BUTTON_X; break;
				case 0x00000008: vpadKey = VPAD_BUTTON_Y; break;
				case 0x00000010: vpadKey = VPAD_BUTTON_LEFT; break;
				case 0x00000020: vpadKey = VPAD_BUTTON_RIGHT; break;
				case 0x00000040: vpadKey = VPAD_BUTTON_UP; break;
				case 0x00000080: vpadKey = VPAD_BUTTON_DOWN; break;
				case 0x00000100: vpadKey = VPAD_BUTTON_ZL; break;
				case 0x00000200: vpadKey = VPAD_BUTTON_ZR; break;
				case 0x00000400: vpadKey = VPAD_BUTTON_L; break;
				case 0x00000800: vpadKey = VPAD_BUTTON_R; break;
				case 0x00001000: vpadKey = VPAD_BUTTON_PLUS; break;
				case 0x00002000: vpadKey = VPAD_BUTTON_MINUS; break;
				default: vpadKey = 0; break;
			}
			return (vpadStatus.hold & vpadKey) != 0;
		', key);
		#end
	}

	public static inline function keyUp(key:UInt32):Bool {
		#if !wiiu
		return untyped __cpp__("(hidKeysUp() & ({0}))", key);
		#else
		return untyped __cpp__('
			static VPADStatus vpadStatus;
			static VPADReadError vpadError;
			VPADRead(VPAD_CHAN_0, &vpadStatus, 1, &vpadError);
			uint32_t vpadKey = 0;
			switch({0}) {
				case 0x00000001: vpadKey = VPAD_BUTTON_A; break;
				case 0x00000002: vpadKey = VPAD_BUTTON_B; break;
				case 0x00000004: vpadKey = VPAD_BUTTON_X; break;
				case 0x00000008: vpadKey = VPAD_BUTTON_Y; break;
				case 0x00000010: vpadKey = VPAD_BUTTON_LEFT; break;
				case 0x00000020: vpadKey = VPAD_BUTTON_RIGHT; break;
				case 0x00000040: vpadKey = VPAD_BUTTON_UP; break;
				case 0x00000080: vpadKey = VPAD_BUTTON_DOWN; break;
				case 0x00000100: vpadKey = VPAD_BUTTON_ZL; break;
				case 0x00000200: vpadKey = VPAD_BUTTON_ZR; break;
				case 0x00000400: vpadKey = VPAD_BUTTON_L; break;
				case 0x00000800: vpadKey = VPAD_BUTTON_R; break;
				case 0x00001000: vpadKey = VPAD_BUTTON_PLUS; break;
				case 0x00002000: vpadKey = VPAD_BUTTON_MINUS; break;
				default: vpadKey = 0; break;
			}
			return (vpadStatus.release & vpadKey) != 0;
		', key);
		#end
	}

	public static var touch(get, null):TouchPosition;
	static function get_touch():TouchPosition {
		#if !wiiu
		untyped __cpp__("touchPosition temp; hidTouchRead(&temp);");
		return {
			px: untyped __cpp__('temp.px'),
			py: untyped __cpp__('temp.py')
		};
		#else
		untyped __cpp__('
			static VPADStatus vpadStatus;
			static VPADReadError vpadError;
			VPADRead(VPAD_CHAN_0, &vpadStatus, 1, &vpadError);
		');
		return {
			px: untyped __cpp__('vpadStatus.tpNormal.x'),
			py: untyped __cpp__('vpadStatus.tpNormal.y')
		};
		#end
	}
}
