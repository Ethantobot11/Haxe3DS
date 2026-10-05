package haxe3ds.services;

import cpp.UInt8;
import cpp.UInt32;

class HIDKey {
    #if !wiiu
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
    #else
    public static inline var START:UInt32 = 0x0008;
    public static inline var A:UInt32 = 0x8000;
    public static inline var B:UInt32 = 0x4000;
    public static inline var Y:UInt32 = 0x1000;
    public static inline var X:UInt32 = 0x2000;
    public static inline var SELECT:UInt32 = 0x0004;
    public static inline var DLEFT:UInt32 = 0x0800;
    public static inline var DDOWN:UInt32 = 0x0100;
    public static inline var DUP:UInt32 = 0x0200;
    public static inline var DRIGHT:UInt32 = 0x0400;
    public static inline var R:UInt32 = 0x0010;
    public static inline var L:UInt32 = 0x0020;
    public static inline var ZL:UInt32 = 0x0080;
    public static inline var ZR:UInt32 = 0x0040;
    public static inline var TOUCH:UInt32 = 0;
    public static inline var CSTICK_RIGHT:UInt32 = 0x02000000;
    public static inline var CSTICK_LEFT:UInt32 = 0x04000000;
    public static inline var CSTICK_UP:UInt32 = 0x01000000;
    public static inline var CSTICK_DOWN:UInt32 = 0x00800000;
    public static inline var CPAD_RIGHT:UInt32 = 0x20000000;
    public static inline var CPAD_LEFT:UInt32 = 0x40000000; 
    public static inline var CPAD_UP:UInt32 = 0x10000000;
    public static inline var CPAD_DOWN:UInt32 = 0x08000000;
    public static inline var UP:UInt32 = 0x0200;
    public static inline var DOWN:UInt32 = 0x0100;
    public static inline var LEFT:UInt32 = 0x0800;
    public static inline var RIGHT:UInt32 = 0x0400;
    #end
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
            [&]() -> bool {
                static VPADStatus vpadStatus;
                static VPADReadError vpadError;
                VPADRead(VPAD_CHAN_0, &vpadStatus, 1, &vpadError);
                return (vpadStatus.trigger & {0}) != 0;
            }()
        ', key);
        #end
    }

    public static inline function keyHeld(key:UInt32):Bool {
        #if !wiiu
        return untyped __cpp__("(hidKeysHeld() & ({0}))", key);
        #else
        return untyped __cpp__('
            [&]() -> bool {
                static VPADStatus vpadStatus;
                static VPADReadError vpadError;
                VPADRead(VPAD_CHAN_0, &vpadStatus, 1, &vpadError);
                return (vpadStatus.hold & {0}) != 0;
            }()
        ', key);
        #end
    }

    public static inline function keyUp(key:UInt32):Bool {
        #if !wiiu
        return untyped __cpp__("(hidKeysUp() & ({0}))", key);
        #else
        return untyped __cpp__('
            [&]() -> bool {
                static VPADStatus vpadStatus;
                static VPADReadError vpadError;
                VPADRead(VPAD_CHAN_0, &vpadStatus, 1, &vpadError);
                return (vpadStatus.release & {0}) != 0;
            }()
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
