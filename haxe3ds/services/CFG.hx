package haxe3ds.services;

import haxe3ds.types.OutOfBoundsException;
import haxe3ds.types.Result;
import cpp.UInt16;
import cpp.UInt8;
import cpp.UInt32;

enum abstract CFGLanguage(Int) {
	var Default = -1;
	var Japanese; var English; var French; var German; var Italian; var Spanish;
	var SimplifiedChinese; var Korean; var Dutch; var Portuguese; var Russian; var TraditionalChinese;
}

enum CFGRestrictBitmask {
	GPCE; INTERNET_BROWSER; THREED_IMAGES; SHARING; ONLINE; STREETPASS;
	FRIEND_REGISTER; DS_DP; ESHOP; DISTRIBUTED; MIIVERSE_VIEW; MIIVERSE_POST; COPPA;
}

typedef CFGParental = {
	var restriction:Array<CFGRestrictBitmask>;
	var ratingSystem:UInt8;
	var maxAllowedAge:UInt8;
	var secretQuestion:UInt8;
	var pin:UInt16;
	var secretAnswer:String;
	var enabled:Bool;
}

typedef CFGUsername = { var name:String; var hasProfanity:Bool; var version:UInt32; }
typedef CFGBacklightControl = { var powerSaving:Bool; var brightness:UInt8; }

enum abstract CFGSoundOutput(UInt8) { var MONO; var STEREO; var SURROUND; }

#if HAXE3DS
@:cppFileCode('
#include "haxe3ds_Utils.h"
#include <deque>
#include <string>
#define CFGU_UPDATE(size, blockID, block) \\
	if (R_FAILED(CFG_SetConfigInfoBlk8(size, blockID, (void*)&block)) || R_FAILED(CFG_UpdateConfigSavegame())) return null()
typedef struct { bool pse; u8 bl; } CFGBC;
')
#end
class CFG {
	public static inline function init():Result {
		#if HAXE3DS return untyped __cpp__('cfguInit()'); #else return 0; #end
	}
	public static inline function exit() {
		#if HAXE3DS untyped __cpp__('cfguExit()'); #end
	}

	public static var username(get, null):Null<CFGUsername>;
	static function get_username():Null<CFGUsername> {
		#if HAXE3DS
		untyped __cpp__('
			union { u16 user[11]; bool ngWord; u8 pad; u32 ngVersion; } usern;
			if R_FAILED(CFG_GetConfigInfoBlk8(28, 0x000A0000, &usern)) return null();
		');
		return { name: untyped __cpp__('u16ToString(usern.user)'), hasProfanity: untyped __cpp__('usern.ngWord'), version: untyped __cpp__('(int)usern.ngVersion') };
		#else return { name: "Wii U User", hasProfanity: false, version: 0 }; #end
	}

	public static var birthday(get, null):Null<String>;
	static function get_birthday():Null<String> {
		#if HAXE3DS
		untyped __cpp__('
			u8 birt[2] = { 0}; RETURN_NULL_IF_FAILED(CFG_GetConfigInfoBlk8(2, 0x000A0001, birt));
			std::deque<String> arr = {"January","February","March","April","May","June","July","August","September","October","November","December"};
			char date[15] = { 0 }; snprintf(date, 15, "%s %02d", arr[birt[0]].c_str(), birt[1]);
		');
		return untyped __cpp__('String(date)');
		#else return "January 01"; #end
	}

	public static var model(get, null):Null<String>;
	static function get_model():Null<String> {
		#if HAXE3DS
		untyped __cpp__('u8 r; RETURN_NULL_IF_FAILED(CFGU_GetSystemModel(&r)); std::deque<String> arr = {"CTR","SPR","KTR","FTR","RED","JAN"};');
		return untyped __cpp__('arr[r]');
		#else return "WUP"; #end
	}

	public static var region(get, null):Null<String>;
	static function get_region():Null<String> {
		#if HAXE3DS
		untyped __cpp__('u8 r; RETURN_NULL_IF_FAILED(CFGU_SecureInfoGetRegion(&r)); std::deque<String> arr = {"JPN","USA","EUR","AUS","CHN","KOR","TWN"};');
		return untyped __cpp__('arr[r]');
		#else return "USA"; #end
	}

	public static var language(default, null):Null<String>;
	static function get_language():Null<String> {
		#if HAXE3DS
		untyped __cpp__('u8 r; RETURN_NULL_IF_FAILED(CFGU_GetSystemLanguage(&r)); std::deque<String> arr = {"Japanese","English","French","German","Italian","Spanish","Simplified Chinese","Korean","Dutch","Portuguese","Russian","Traditional Chinese"};');
		return untyped __cpp__('arr[r]');
		#else return "English"; #end
	}

	public static var isCanadaUSA(get, null):Bool;
	static function get_isCanadaUSA():Bool {
		#if HAXE3DS return untyped __cpp__('API_GETTER(u8, CFGU_GetRegionCanadaUSA, 0) == 1'); #else return false; #end
	}

	public static var supportsNFC(default, null):Bool;
	static function get_supportsNFC():Bool {
		#if HAXE3DS return untyped __cpp__('API_GETTER(bool, CFGU_IsNFCSupported, false)'); #else return false; #end
	}

	public static var soundOutput(get, set):Null<CFGSoundOutput>;
	static function get_soundOutput():Null<CFGSoundOutput> {
		#if HAXE3DS
		var r:Null<CFGSoundOutput> = null;
		untyped __cpp__('RETURN_NULL_IF_FAILED(CFG_GetConfigInfoBlk8(1, 0x00070001, &{0}))', r);
		return r;
		#else return STEREO; #end
	}
	static function set_soundOutput(soundOutput):Null<CFGSoundOutput> {
		if (soundOutput == null) return null;
		var i = cast soundOutput;
		if (i < 0 || i > 2) throw new OutOfBoundsException('Expected Value MONO - SURROUND, Instead got: $i');
		#if !wiiu untyped __cpp__('CFGU_UPDATE(1, 0x00070001, {0})', soundOutput); #end
		return soundOutput;
	}

	public static var parentalControlsInfo(get, null):Null<CFGParental>;
	static function get_parentalControlsInfo():Null<CFGParental> {
		#if HAXE3DS
		untyped __cpp__('
			struct { u32 restrictionBitmask; u32 unknown0x4; u8 ratingSystem; u8 maxAllowedAge; u8 secretQuestion; u8 unknown0xB; char pinCode[4]; u32 pad; u16 secretAnswer[34]; u8 pad2[104]; } out = { 0};
			RETURN_NULL_IF_FAILED(CFG_GetConfigInfoBlk8(0xC0, 0x000C0000, &out));
			using m = haxe3ds::services::CFGRestrictBitmask_obj;
			Array<Dynamic> bitmask = Array_obj<Dynamic>::__new(0);
			for (int i = 0; i < 32; i++) {
				if (i > 11 && i < 31) continue;
				if (BIT(i) & out.restrictionBitmask) {
					switch (i) {
						case 0: {bitmask->push(m::GPCE_dyn()); break;} case 1: {bitmask->push(m::INTERNET_BROWSER_dyn()); break;}
						case 2: {bitmask->push(m::THREED_IMAGES_dyn()); break;} case 3: {bitmask->push(m::SHARING_dyn()); break;}
						case 4: {bitmask->push(m::ONLINE_dyn()); break;} case 5: {bitmask->push(m::STREETPASS_dyn()); break;}
						case 6: {bitmask->push(m::FRIEND_REGISTER_dyn()); break;} case 7: {bitmask->push(m::DS_DP_dyn()); break;}
						case 8: {bitmask->push(m::ESHOP_dyn()); break;} case 9: {bitmask->push(m::DISTRIBUTED_dyn()); break;}
						case 10: {bitmask->push(m::MIIVERSE_VIEW_dyn()); break;} case 11: {bitmask->push(m::MIIVERSE_POST_dyn()); break;}
						case 31: {bitmask->push(m::COPPA_dyn()); break;}
					}
				}
			}
		');
		return {
			restriction: untyped __cpp__('bitmask'), ratingSystem: untyped __cpp__('out.ratingSystem'), maxAllowedAge: untyped __cpp__('out.maxAllowedAge'),
			secretQuestion: untyped __cpp__('out.secretQuestion'), pin: untyped __cpp__('std::stoi(out.pinCode)'),
			secretAnswer: untyped __cpp__('u16ToString(out.secretAnswer)'), enabled: untyped __cpp__('*(u64*)&out & 1')
		};
		#else return null; #end
	}

	public static function checkPCPinCode(code:UInt16):Bool {
		final pin = parentalControlsInfo;
		if (pin == null) return false;
		return pin.pin == code;
	}

	public static var backlightControl(get, set):Null<CFGBacklightControl>;
	static function get_backlightControl():Null<CFGBacklightControl> {
		#if HAXE3DS
		untyped __cpp__('CFGBC block; RETURN_NULL_IF_FAILED(CFG_GetConfigInfoBlk8(2, 0x00050001, &block))');
		return { powerSaving: untyped __cpp__('block.pse'), brightness: untyped __cpp__('block.bl') };
		#else return { powerSaving: false, brightness: 3 }; #end
	}
	static function set_backlightControl(backlightControl):Null<CFGBacklightControl> {
		if (backlightControl == null) return null;
		#if !wiiu untyped __cpp__('CFGBC block = {.pse = {0}, .bl = {1}}; CFGU_UPDATE(2, 0x00050001, block);', backlightControl.powerSaving, backlightControl.brightness); #end
		return backlightControl;
	}
}
