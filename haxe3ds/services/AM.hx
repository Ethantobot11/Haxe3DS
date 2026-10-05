package haxe3ds.services;

import cpp.UInt16;
import haxe3ds.services.FS.FSSMDH;
import haxe3ds.services.FS.FSMediaType;
import haxe3ds.types.Result;
import cpp.UInt32;
import cpp.UInt64;

enum AMContentType { ENCRYPTED; DISC; HASHED; CFM; SHA1_HASH; OPTIONAL; SHARED; }

typedef AMTitleInfo = {
	var titleID:UInt64; var size:UInt64; var version:String; var rawVersion:UInt16;
	var contentType:Array<AMContentType>; var productCode:String; var title:String;
	var description:String; var publisher:String;
};

#if HAXE3DS
@:cppInclude("haxe3ds_Utils.h")
#end
class AM {
	public static function init():Result {
		#if HAXE3DS return untyped __cpp__('amAppInit()'); #else return 0; #end
	}
	public static function exit() {
		#if HAXE3DS untyped __cpp__('amExit()'); #end
	}

	public static function getTitleInfos(media:FSMediaType):Null<Array<AMTitleInfo>> {
		#if HAXE3DS
		var out:Array<AMTitleInfo> = [];
		var titleLen:UInt32 = 0;
		untyped __cpp__('
			u64 tids[300] = { 0}; AM_TitleInfo infos[300] = { 0}; FS_MediaType t = (FS_MediaType)media;
			RETURN_NULL_IF_FAILED(AM_GetTitleList(&titleLen, t, 300, tids));
			RETURN_NULL_IF_FAILED(AM_GetTitleInfo(t, titleLen, tids, infos))
		');
		final contents:Map<UInt32, AMContentType> = [1 => ENCRYPTED, 2 => DISC, 4 => HASHED, 8 => CFM, 8192 => SHA1_HASH, 16384 => OPTIONAL, 32768 => SHARED];
		for (i in 0...titleLen) {
			untyped __cpp__('char product[16] = { 0}; AM_TitleInfo inf = infos[{0}]; AM_GetTitleProductCode(t, tids[{0}], product)', i);
			final raw:UInt16 = untyped __cpp__('inf.version');
			untyped __cpp__('char ver[10]; sprintf(ver, "%d.%d.%d", (inf.version >> 10) & 0x3F, (inf.version >> 4) & 0x3F, inf.version & 0xF)');
			final filtered:Array<AMContentType> = [];
			for (num => key in contents.keyValueIterator()) {
				if ((num & untyped __cpp__('inf.titleType')) != 0) filtered.push(key);
			}
			final titleID = untyped __cpp__('tids[i]');
			final smdh = new FSSMDH(untyped __cpp__('titleID >> 32'), untyped __cpp__('titleID & 0xFFFFFFFF'), media);
			inline function get(data:Void->String) return smdh.valid ? data() : "???";
			out.push({
				titleID: titleID, productCode: untyped __cpp__('product'), contentType: filtered, version: untyped __cpp__("ver"),
				rawVersion: raw, size: untyped __cpp__('inf.size'), title: get(() -> smdh.applicationTitles[1].shortDescription),
				description: get(() -> smdh.applicationTitles[1].longDescription), publisher: get(() -> smdh.applicationTitles[1].publisher)
			});
		}
		return out;
		#else return []; #end
	}

	public static var deviceID(get, null):UInt32;
	static function get_deviceID():UInt32 {
		#if HAXE3DS
		var out:UInt32 = 0; untyped __cpp__('AM_GetDeviceId(0, &out)'); return out;
		#else return 0; #end
	}

	public static inline function toBlocks(size:Int):Int {
		return Std.int(size / 131072);
	}
}
