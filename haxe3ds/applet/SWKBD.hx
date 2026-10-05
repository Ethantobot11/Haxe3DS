package haxe3ds.applet;

import cpp.UInt16;
import cpp.UInt32;

/**
 * The types that you can use for your Software Keyboard, they do stuff differently.
 */
enum abstract SWKBDType(Int) {
	var NORMAL;
	var QWERTY;
	var NUMPAD;
	var WESTERN;
}

/**
 * A password like mode for delay hiding, or just hiding instantly.
 */
enum abstract SWKBDPasswordMode(Int) {
	var NONE;
	var HIDE;
	var HIDE_DELAY;
}

/**
 * Valid input handler.
 */
enum abstract SWKBDValidInputHandler(Int) {
	var ANYTHING;
	var NOT_EMPTY;
	var NOT_EMPTY_OR_BLANK;
	var NOT_BLANK;
	var FIXED_LEN;
}

/**
 * The literal button data.
 */
typedef SWKBDButtonData = {
	var input:String;
	var buttonWillSubmit:Bool;
}

/**
 * The Callback Types that's only used for the `callbackFN` function.
 */
enum abstract SWKBDCallbackTypes(Int) {
	var OK;
	var CLOSE;
	var CONTINUE;
}

/**
 * The return typedef that can be used for the rest of the callback session.
 */
typedef SWKBDCallbackReturn = {
	var outMessage:String;
	var resultCallback:SWKBDCallbackTypes;
}

/**
 * Filters to use in the SWKBD.
 */
enum abstract SWKBDFilter(UInt32) {
	var DIGITS = 1;
	var AT;
	var PERCENT = 4;
	var BACKSLASH = 8;
	var PROFANITY = 16;
	var CALLBACK = 32;
}

/**
 * The class of the applet call-up library for the LIBCTRU software keyboard.
 * 
 * @since 1.1.0
 */
#if HAXE3DS
@:cppFileCode('
SwkbdCallbackResult haxe3ds::applet::SWKBDHandler_obj::callbackOut(void* user, const char** ppMessage, const char* text, size_t textlen) {
	haxe3ds::applet::SWKBDHandler_obj* handler = reinterpret_cast<haxe3ds::applet::SWKBDHandler_obj*>(user);
	if (handler->callbackFN != null()) {
		Dynamic out = handler->callbackFN(String::create(text, textlen));
		*ppMessage = ((String)(out->__Field(String("outMessage"),hx::paccDynamic))).c_str();
		switch((int)out->__Field(String("resultCallback"),hx::paccDynamic)) {
			case 0: return SWKBD_CALLBACK_OK;
			case 1: return SWKBD_CALLBACK_CLOSE;
			case 2: return SWKBD_CALLBACK_CONTINUE;
			default: return SWKBD_CALLBACK_CLOSE;
		}
	}
	return SWKBD_CALLBACK_CLOSE;
}
static SwkbdStatusData swkbdStatus;
static SwkbdLearningData swkbdLearning;')
@:headerInclude("3ds.h")
@:headerClassCode("static SwkbdCallbackResult callbackOut(void* user, const char** ppMessage, const char* text, size_t textlen);")
#end
class SWKBDHandler {
	public var type(default, null):SWKBDType;
	public var numButtonsM1(default, null):Int = 0;
	public var maxTextLen(default, null):UInt16 = 0;
	public var passwordMode:SWKBDPasswordMode = NONE;
	public var numpadKeys:Array<UInt16> = [0, 0];
	public var multiline:Bool;
	public var fixedWidth:Bool;
	public var homeMenu:Bool;
	public var softwareReset:Bool;
	public var powerButton:Bool;
	public var darkenTopScreen:Bool;
	public var hintText:String = "Enter text here.";
	public var predictiveInput:Bool = true;
	public var buttonData:Array<SWKBDButtonData> = [for (_ in 0...3) {input: "OK", buttonWillSubmit: true}];
	public var initialText:String = "";
	public var dict:Map<String, String> = [];
	public var validInput:SWKBDValidInputHandler = ANYTHING;
	public var defaultQWERTY:Bool;
	public var filterFlags:Array<SWKBDFilter> = [];
	public var maxDigits:Int = 0;
	public var callbackFN:String->SWKBDCallbackReturn;

	public function new(type:SWKBDType = NORMAL, numButtons:Int = 1, maxTextLength:Int = -1) {
		this.type = type;
		this.numButtonsM1 = numButtons - 1;
		this.maxTextLen = maxTextLength > 0 ? maxTextLength : 0xFDE8;
	}

	public function display():String {
		#if HAXE3DS
		var filter:UInt32 = 0;
		for (flags in filterFlags) {
			final f32:UInt32 = cast flags;
			if ((filter & f32) == 0) {
				filter += f32;
			}
		}

		untyped __cpp__('
			SwkbdState out;
			swkbdInit(&out, (SwkbdType)this->type, this->numButtonsM1 + 1, this->maxTextLen);

			out.type = this->type;
			out.num_buttons_m1 = this->numButtonsM1;
			out.password_mode = this->passwordMode;
			out.multiline = this->multiline;
			out.fixed_width = this->fixedWidth;
			out.allow_home = this->homeMenu;
			out.allow_reset = this->softwareReset;
			out.allow_power = this->powerButton;
			out.darken_top_screen = (u8)this->darkenTopScreen;
			out.default_qwerty = (u8)this->defaultQWERTY;
			out.predictive_input = this->predictiveInput;
			swkbdSetHintText(&out, this->hintText.c_str());
			swkbdSetInitialText(&out, this->initialText.c_str());
			swkbdSetValidation(&out, (SwkbdValidInput)this->validInput, {0}, this->maxDigits);
			for (int i = 0; i < 2; i++) out.numpad_keys[i] = this->numpadKeys->__get(i);
			if (this->callbackFN != null()) swkbdSetFilterCallback(&out, &haxe3ds::applet::SWKBDHandler_obj::callbackOut, this);
		', filter);

		for (i in 0...3) {
			untyped __cpp__('swkbdSetButton(&out, (SwkbdButton){0}, ((String)({1})).c_str(), {2})', i, this.buttonData[i].input, this.buttonData[i].buttonWillSubmit);
		}

		final len:Int = {
			var count:Int = 0;
			for (_ in this.dict.keys()) count++;
			count;
		};

		if (len != 0 && this.predictiveInput) {
			untyped __cpp__('SwkbdDictWord words[len]');

			var iter:Int = 0;
			for (key => value in this.dict.keyValueIterator()) {
				untyped __cpp__('swkbdSetDictWord(&words[{2}], {0}.c_str(), {1}.c_str())', key, value, iter);
				iter++;
			}

			untyped __cpp__('
				swkbdSetDictionary(&out, words, len);
				swkbdSetStatusData(&out, &swkbdStatus, false, true);
				swkbdSetLearningData(&out, &swkbdLearning, false, true)
			');
		}

		untyped __cpp__('
			char output[1700];
			swkbdInputText(&out, output, 1700)
		');

		return untyped __cpp__('String(output)');
		#else
		trace("SWKBDHandler.display() is stubbed on Wii U. Returning initial text.");
		return this.initialText != "" ? this.initialText : "Stubbed Input";
		#end
	}
}
