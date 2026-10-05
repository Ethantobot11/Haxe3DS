package haxe3ds;

import cpp.UInt8;
import cpp.UInt16;
import cpp.UInt64;
import haxe3ds.types.NanoTime;
import haxe3ds.types.Result;

enum abstract SVCUserBreakType(Int) {
	var PANIC;
	var ASSERT;
	var USER;
}

enum abstract SVCEmulatorID(UInt8) {
	var CITRA = 1;
	var AZAHAR;
}

enum abstract SVCEmulatorPlatform(UInt8) {
	var UNKNOWN;
	var WINDOWS;
	var LINUX;
	var APPLE;
	var ANDROID;
}

typedef SVCEmulatorInfo = {
	var emulatorID:SVCEmulatorID;
	var hostTick:NanoTime;
	var emulationSpeed:UInt16;
	var platform:SVCEmulatorPlatform;
}

#if HAXE3DS
@:cppInclude("3ds.h")
#end
class SVC {
	public static inline function sleep(ns:UInt64) {
		#if HAXE3DS
		untyped __cpp__('svcSleepThread({0})', ns.toInt());
		#else
		#end
	}

	public static var wifiEnabled(default, set):Bool;
	static function set_wifiEnabled(wifiEnabled:Bool):Bool {
		#if HAXE3DS
		return untyped __cpp__('svcSetWifiEnabled(wifiEnabled)');
		#else
		return false;
		#end
	}

	public static inline function breakExecution(type:SVCUserBreakType) {
		#if HAXE3DS
		untyped __cpp__('svcBreak((UserBreakType)type)');
		#else
		#end
	}

	public static inline function debugString(str:String):Result {
		#if HAXE3DS
		return untyped __cpp__('svcOutputDebugString(str.c_str(), str.length)');
		#else
		trace(str);
		return 0;
		#end
	}

	public static function getProcessNames():Null<Array<String>> {
		#if HAXE3DS
		var out:Array<String> = [];
		untyped __cpp__('
			u32 processIDs[0x50] = { 0};
			s32 count = 0;
			if (R_FAILED(svcGetProcessList(&count, processIDs, 0x50))) return null();
			for (s32 i = 0; i < count; i++) {
				Handle process;
				if (R_FAILED(svcOpenProcess(&process, processIDs[i]))) continue;
				char procName[8] = { 0};
				if (R_FAILED(svcGetProcessInfo((s64*)procName, process, 0x10000))) {
					svcCloseHandle(process);
					continue;
		}
				out->push(String(procName));
				svcCloseHandle(process);
			}
		');
		return out;
		#else
		return null;
		#end
	}

	public static var emulator(get, null):Null<SVCEmulatorInfo>;
	static function get_emulator():Null<SVCEmulatorInfo> {
		#if HAXE3DS
		untyped __cpp__('
			#define SVC_PROPERTY(index) \\
				([&]{ \\
					s64 OUT; \\
					svcGetSystemInfo(&OUT, 0x20000, (s32)index); \\
					return OUT; \\
				})()
			s8 eID = SVC_PROPERTY(0);
			if (eID == 0) return null();
		');
		return {
			emulatorID: untyped __cpp__('eID'),
			hostTick: untyped __cpp__('SVC_PROPERTY(1)'),
			emulationSpeed: untyped __cpp__('SVC_PROPERTY(2)'),
			platform: untyped __cpp__('SVC_PROPERTY(12)')
		};
		#else
		return null;
		#end
	}
}
