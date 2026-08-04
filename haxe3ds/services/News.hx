package haxe3ds.services;

import cpp.UInt8;
import cpp.UInt64;
import cpp.UInt32;
import sys.FileSystem;
import sys.io.File;
import haxe3ds.types.OutOfBoundsException;
import haxe3ds.types.Result;

using StringTools;

/**
 * The Notification Header.
 * * @since 1.3.0
 */
typedef NEWSHeader = {
	/**
	 * Whether or not the data's fully set or not.
	 */
	var dataSet:Bool;

	/**
	 * Whether or not the notification is unread by the News Applet.
	 */
	var unread:Bool;

	/**
	 * Whether or not the image is a JPEG or not.
	 */
	var enableJPEG:Bool;

	/**
	 * Whether or not the notification is a SpotPass or a StreetPass using CECD.
	 */
	var isSpotPass:Bool;

	/**
	 * Whether or not this notification was opted out.
	 */
	var isOptedOut:Bool;

	/**
	 * Notification Program ID Source (`0` if it's System Notifications) 
	 */
	var processID:UInt64;

	/**
	 * Specified by source app and later retrieved via APT.
	 */
	var jumpParam:UInt64;

	/**
	 * Milliseconds since January 1, 2000.
	 */
	var time:UInt64;

	/**
	 * UTF-16 to String Converted for the notification title.
	 */
	var title:String;
}

/**
 * Built-in Sets of Patterns that the NEWS Service has.
 * @since 1.8.0
 */
enum abstract NewsLampPattern(UInt8) {
	/**
	 * BOSS Pattern, Flashes `CYAN`.
	 */
	var BOSS = 3;

	/**
	 * StreetPass Pattern, Flashes `GREEN`.
	 */
	var CEC = 5;

	/**
	 * Friend is Online, Flashes `ORANGE`.
	 */
	var FRIEND_ONLINE = 7;
}

@:cppInclude("haxe3ds_Utils.h")
class News {
	public static inline function init():Result {
		return untyped __cpp__('newsInit()');
	};

	public static inline function exit() {
		untyped __cpp__('newsExit()');
	}

	public static function addNotification(title:String, message:String, imagePath:Null<String> = null):Result {
		untyped __cpp__("
			u16 OutTitle[0x40] = { 0};
			u16 OutMessage[0x1780] = { 0};

			u32 tsize = (u32)TRANSFER(title.c_str(), OutTitle);
			u32 msize = (u32)TRANSFER(message.c_str(), OutMessage);

			u64 size = 0;
			u8* image = NULL;
		");

		var jpeg = false;
		if (imagePath != null && FileSystem.exists(imagePath)) {
			var sz = FileSystem.stat(imagePath).size;
			if (sz < 0xC800) {
				jpeg = imagePath.endsWith(".jpg") || imagePath.endsWith(".jpeg");
				var bytes = File.getBytes(imagePath);
				untyped __cpp__('
					image = (u8*){0}->b->getBase();
					size = {1}
				', bytes, sz);
			}
		}

		return untyped __cpp__('NEWS_AddNotification(OutTitle, tsize, OutMessage, msize, image, size, {0})', jpeg);
	}

	public static function getHeader(newsID:Int):Null<NEWSHeader> {
		untyped __cpp__('
			NotificationHeader h;
			RETURN_NULL_IF_FAILED(NEWS_GetNotificationHeader(newsID, &h));
		');

		return {
			dataSet:    untyped __cpp__('h.dataSet'),
			unread:     untyped __cpp__('h.unread'),
			enableJPEG: untyped __cpp__('h.enableJPEG'),
			isSpotPass: untyped __cpp__('h.isSpotPass'),
			isOptedOut: untyped __cpp__('h.isOptedOut'),
			processID:  untyped __cpp__('h.processID'),
			jumpParam:  untyped __cpp__('h.jumpParam'),
			time:       untyped __cpp__('h.time'),
			title:      untyped __cpp__('u16ToString(h.title)')
		}
	}

	public static function setHeader(newsID:Int, out:NEWSHeader):Result {
		untyped __cpp__('
			NotificationHeader h;
			NEWS_GetNotificationHeader(newsID, &h);

			h.dataSet = out->__Field(String("dataSet"),hx::paccDynamic);
			h.unread = out->__Field(String("unread"),hx::paccDynamic);
			h.enableJPEG = out->__Field(String("enableJPEG"),hx::paccDynamic);
			h.isSpotPass = out->__Field(String("isSpotPass"),hx::paccDynamic);
			h.isOptedOut = out->__Field(String("isOptedOut"),hx::paccDynamic);
			h.processID = out->__Field(String("processID"),hx::paccDynamic);
			h.jumpParam = out->__Field(String("jumpParam"),hx::paccDynamic);
			h.time = out->__Field(String("time"),hx::paccDynamic);

			String title = (String)(out->__Field(String("title"),hx::paccDynamic));
			TRANSFER(title.c_str(), h.title);
		');

		return untyped __cpp__('NEWS_SetNotificationHeader(newsID, &h)');
	}

	public static function dumpImage(newsID:UInt32, dumpDest:String):Result {
		var ret:Result = 0;

		untyped __cpp__('
			u32 size;
			FILE* f;
			void* data = malloc(0x10000);

			ret = NEWS_GetNotificationImage(newsID, data, &size);
			if (R_FAILED(ret)) {
				goto fail;
			}

			if (!(f = fopen(dumpDest.c_str(), "wb"))) {
				ret = -1;
				goto fail;
			}

			fwrite(data, 1, size, f);
			fclose(f);

			fail:
			free(data);
		');

		return ret;
	}

	public static function flashLEDPattern(lamp:NewsLampPattern):Result {
		var i = cast lamp;
		if (i < 3 || i > 7) {
			throw new OutOfBoundsException('Expected Value BOSS - FRIEND_ONLINE, Instead got an Out of Bound Value: $i');
		}

		var res:Result = 0;
		untyped __cpp__('
			u32* cmdbuf = getThreadCommandBuffer();
			cmdbuf[0] = 0x000E0040;
			cmdbuf[1] = lamp;
			Handle newsHandle = *newsGetSessionHandle();
			if (R_SUCCEEDED((res = svcSendSyncRequest(newsHandle)))) res = cmdbuf[1];
		');

		return res;
	}

	public static var totalNotifications(get, null):UInt32;
	static function get_totalNotifications():UInt32 {
		return untyped __cpp__('API_GETTER(u32, NEWS_GetTotalNotifications, 0)');
	}
}
