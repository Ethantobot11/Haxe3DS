package haxe3ds;

enum abstract GFXScreen(Int) {
	var TOP;
	var BOTTOM;
}

enum abstract ConsoleColor(String) {
	var BLACK_TEXT = "\x1b[30;1m";
	var RED_TEXT = "\x1b[31;1m";
	var GREEN_TEXT = "\x1b[32;1m";
	var YELLOW_TEXT = "\x1b[33;1m";
	var BLUE_TEXT = "\x1b[34;1m";
	var MAGENTA_TEXT = "\x1b[35;1m";
	var CYAN_TEXT = "\x1b[36;1m";
	var WHITE_TEXT = "\x1b[37;1m";
	var BLACK_BORDER = "\x1b[40;1m";
	var RED_BORDER = "\x1b[41;1m";
	var GREEN_BORDER = "\x1b[42;1m";
	var YELLOW_BORDER = "\x1b[43;1m";
	var BLUE_BORDER = "\x1b[44;1m";
	var MAGENTA_BORDER = "\x1b[45;1m";
	var CYAN_BORDER = "\x1b[46;1m";
	var WHITE_BORDER = "\x1b[47;1m";
}

enum abstract ConsolePUA(String) {
	var A = "\uE000";
	var B = "\uE001";
	var Y = "\uE002";
	var X = "\uE003";
	var L = "\uE004";
	var R = "\uE005";
	var DPAD = "\uE006";
	var TARGET = "\uE01D";
	var CAMERA = "\uE01E";
	var DPAD_ANY = "\uE041";
	var QUESTION_BLOCK = "\uE06B";
	var CLOSE = "\uE070";
	var CLOSE_HIGHLIGHT = "\uE071";
	var BACK = "\uE072";
	var HOME = "\uE073";
	var STEPS = "\uE074";
	var PLAY_COIN = "\uE075";
	var FILM = "\uE076";
	var CIRCLE_PAD = "\uE077";
	var POWER = "\uE078";
	var DPAD_UP = "\uE079";
	var DPAD_DOWN = "\uE07A";
	var DPAD_LEFT = "\uE07B";
	var DPAD_RIGHT = "\uE07C";
	var DPAD_VERTICAL = "\uE07D";
	var DPAD_HORIZONTAL = "\uE07E";
}

#if HAXE3DS
@:cppInclude("haxe3ds_Utils.h")
#end
class Console {
	public static inline final WIDTH_TOP = 400;
	public static inline final WIDTH_BOTTOM = 320;
	public static inline final HEIGHT = 240;

	public static inline function init(screen:GFXScreen = TOP) {
		#if HAXE3DS
		untyped __cpp__('consoleInit((gfxScreen_t)({0}), NULL)', screen);
		#else
		#end
	}

	public static inline function clear() {
		#if HAXE3DS
		Sys.print("\\x1b[2J");
		#else
		#end
	}
}
