package haxe3ds.applet;

import cpp.UInt32;
import cpp.UInt16;
import haxe3ds.services.CFG.CFGLanguage;
import haxe3ds.types.Result;

enum abstract ErrorType(Int) {
	var CODE;
	var TEXT;
	var EULA;
	var CODE_LANGUAGE = 256;
	var TEXT_LANGUAGE;
	var EULA_LANGUAGE;
	var TEXT_WORD_WRAP = 513;
	var TEXT_LANGUAGE_WORD_WRAP = 769;
}

enum ErrorReturnCode {
	UNKNOWN;
	NONE;
	SUCCESS;
	NOT_SUPPORTED;
	HOME_BUTTON;
	SOFTWARE_RESET;
	POWER_BUTTON;
}

typedef ErrorResult = {
	var returnCode:ErrorReturnCode;
	var eulaVersion:UInt16;
}

#if HAXE3DS
@:cppInclude("3ds.h")
@:cppInclude("haxe3ds_Utils.h")
#end
class Error {
	public static inline extern final MAX_TEXT_LENGTH = 2048;
	public var type:ErrorType;
	public var errorCode:UInt32 = 0;
	public var useLanguage(default, null):UInt16;
	public var homeButton:Bool = true;
	public var softwareReset:Bool;
	public var appJump:Bool;
	public var text = "An error has occurred.";

	public function new(errType:ErrorType = TEXT, language:CFGLanguage = English) {
		this.type = errType;
		this.useLanguage = (cast language) + 1;
	}

	public function display():ErrorResult {
		#if !wiiu
		if (text.length > MAX_TEXT_LENGTH) {
			text = text.substr(0, MAX_TEXT_LENGTH);
		}

		untyped __cpp__('
			errorConf conf = {0 };
			conf.type = type;
			conf.errorCode = errorCode;
			conf.useLanguage = useLanguage;
			conf.homeButton = homeButton;
			conf.softwareReset = softwareReset;
			conf.appJump = appJump;
			errorText(&conf, text.c_str());
			errorDisp(&conf)
		');

		return {
			returnCode: switch untyped __cpp__('conf.returnCode') {
				case 0: NONE;
				case 1: SUCCESS;
				case 2: NOT_SUPPORTED;
				case 10: HOME_BUTTON;
				case 11: SOFTWARE_RESET;
				case 12: POWER_BUTTON;
				default: UNKNOWN;
			},
			eulaVersion: untyped __cpp__('conf.eulaVersion')
		};
		#else
		trace("Error Applet Stub: " + text + " (Code: " + errorCode + ")");
		return { returnCode: NONE, eulaVersion: 0 };
		#end
	}
}
