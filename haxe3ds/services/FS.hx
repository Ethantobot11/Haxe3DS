package haxe3ds.services;

import cpp.UInt16;
import haxe3ds.types.Result;

enum abstract FSMediaType(Int) {
	var NAND = 0;
	var SD = 1;
	var CARD = 2;
}

#if HAXE3DS
@:cppFileCode('
int getHashTableLength(int numEntries) {
	int count = numEntries;
	if (count < 3) count = 3;
	else if (count < 19) count |= 1;
	else {
		while (count % 2 == 0 || count % 3 == 0 || count % 5 == 0 || count % 7 == 0 || count % 11 == 0 || count % 13 == 0 || count % 17 == 0) count++;
	}
	return count;
}')
@:headerCode('
#include "haxe3ds_Utils.h"
namespace FSD {
    inline FS_Archive sdmcRoot = 0;
    inline FS_Archive get_sdmcRoot() {
        if (sdmcRoot == 0) FSUSER_OpenArchive(&sdmcRoot, ARCHIVE_SDMC, fsMakePath(PATH_EMPTY, ""));
        return sdmcRoot;
    }
}
')
#end

class FS {
	public static var isSDMCDetected(get, null):Bool;
	static function get_isSDMCDetected():Bool {
		#if !wiiu
		return untyped __cpp__('API_GETTER(bool, FSUSER_IsSdmcDetected, 0)');
		#else
		return true;
		#end
	}

	public static var isSDMCWritable(get, null):Bool;
	static function get_isSDMCWritable():Bool {
		#if !wiiu
		return untyped __cpp__('API_GETTER(bool, FSUSER_IsSdmcWritable, 0)');
		#else
		return true;
		#end
	}

	public static function mountSaveData(partition:String = "ext", files:Int = 1, dirs:Int = 1):Result {
		#if !wiiu
		#if IS_CIA
		var res:Result = 0;
		untyped __cpp__('
			const char* p = partition.c_str();
			FS_Path path = fsMakePath(PATH_EMPTY, "");
			if ((res = archiveMount(ARCHIVE_SAVEDATA, path, p)) == 0xC8A04554) {
				if R_FAILED(res = FSUSER_FormatSaveData(ARCHIVE_SAVEDATA, path, 0x200, dirs, files, getHashTableLength(dirs), getHashTableLength(files), false)) return res;
				res = archiveMount(ARCHIVE_SAVEDATA, path, p);
			}
		');
		return res;
		#else
		return 0;
		#end
		#else
		return 0;
		#end
	}

	public static function flushAndCommit(partition:String = "ext"):Result {
		#if !wiiu
		#if IS_CIA
		return untyped __cpp__('archiveCommitSaveData(partition.c_str())');
		#else
		return 0;
		#end
		#else
		return 0;
		#end
	}

	public static var playCoins(get, set):UInt16;
	
	static function get_playCoins():UInt16 {
		#if !wiiu
		var out:UInt16 = -1;
		untyped __cpp__('
			FS_Archive archive;
			u32 path[3] = {MEDIATYPE_NAND, 0xF000000B, 0x00048000};
			if (R_FAILED(FSUSER_OpenArchive(&archive, ARCHIVE_SHARED_EXTDATA, (FS_Path){PATH_BINARY, 0xC, path}))) goto end1;
			Handle fileHandle;
			if (R_FAILED(FSUSER_OpenFile(&fileHandle, archive, fsMakePath(PATH_UTF16, u"/gamecoin.dat"), FS_OPEN_READ | FS_OPEN_WRITE, FS_ATTRIBUTE_ARCHIVE))) goto end2;
			u32 _;
			FSFILE_Read(fileHandle, &_, 4, &out, sizeof(out));
			FSFILE_Close(fileHandle);
			end2: FSUSER_CloseArchive(archive);
			end1:
		');
		return out;
		#else
		return 0;
		#end
	}
	
	static function set_playCoins(playCoins):UInt16 {
		#if !wiiu
		playCoins = playCoins > 300 ? 300 : playCoins < 0 ? 0 : playCoins;
		untyped __cpp__('
			FS_Archive archive;
			u32 path[3] = {MEDIATYPE_NAND, 0xF000000B, 0x00048000};
			u8 coinBytes[2] = {(u8)(playCoins & 0xFF), (u8)((playCoins >> 8) & 0xFF)};
			bool fail = true;
			if (R_FAILED(FSUSER_OpenArchive(&archive, ARCHIVE_SHARED_EXTDATA, (FS_Path){PATH_BINARY, 0xC, path}))) goto end1;
			Handle fileHandle;
			if (R_FAILED(FSUSER_OpenFile(&fileHandle, archive, fsMakePath(PATH_UTF16, u"/gamecoin.dat"), FS_OPEN_READ | FS_OPEN_WRITE, FS_ATTRIBUTE_ARCHIVE))) goto end2;
			u32 _;
			fail = R_FAILED(FSFILE_Write(fileHandle, &_, 4, coinBytes, sizeof(coinBytes), FS_WRITE_FLUSH));
			FSFILE_Close(fileHandle);
			end2: FSUSER_CloseArchive(archive);
			end1:
			if (fail) return -1;
		');
		return playCoins;
		#else
		return playCoins;
		#end
	}

	public static function deleteFile(path:String):Result {
		#if !wiiu
		return untyped __cpp__('FSUSER_DeleteFile(FSD::get_sdmcRoot(), fsMakePath(PATH_ASCII, path.c_str()))');
		#else
		return 0;
		#end
	}

	public static function renameFile(source:String, destination:String):Result {
		#if !wiiu
		return untyped __cpp__('FSUSER_RenameFile(FSD::get_sdmcRoot(), fsMakePath(PATH_ASCII, source.c_str()), FSD::get_sdmcRoot(), fsMakePath(PATH_ASCII, destination.c_str()))');
		#else
		return 0;
		#end
	}

	public static function deleteDir(source:String, recursive:Bool = false):Result {
		#if !wiiu
		untyped __cpp__('FS_Path p = fsMakePath(PATH_ASCII, source.c_str())');
		return untyped __cpp__('recursive ? FSUSER_DeleteDirectoryRecursively(FSD::get_sdmcRoot(), p) : FSUSER_DeleteDirectory(FSD::get_sdmcRoot(), p)');
		#else
		return 0;
		#end
	}

	public static var ctrRootPath(default, null):String = "";
	static function get_ctrRootPath():String {
		#if !wiiu
		untyped __cpp__('
			u16 root[256] = { 0};
			FSUSER_GetSdmcCtrRootPath((u8*)root, 512)
		');
		return untyped __cpp__('u16ToString(root)');
		#else
		return "/vol/external01/";
		#end
	}

	public static function exit() {
		#if !wiiu
		untyped __cpp__('
			FSUSER_CloseArchive(FSD::get_sdmcRoot());
			fsExit()
		');
		#else
		#end
	}
}

/**
 * The Application Title Metadata.
 * @since 1.6.0
 */
typedef FSSMDHAppTitle = {
	/**
	 * The short description (length = 0x40) for this title.
	 */
	var shortDescription:String;

	/**
	 * The long description (length = 0x80) for this title.
	 */
	var longDescription:String;

	/**
	 * The Publisher (length = 0x40) for this title.
	 */
	var publisher:String;
}

/**
 * App Title's Game Rating Flag depending by region's bit.
 * @since 1.6.0
 */
enum FSSMDHAppGameRatingsFlag {
	CERO;
	ESRB;
	USK;
	PEGI_GEN;
	PEGI_PRT;
	PEGI_BBFC;
	COB;
	GRB;
	CGSRR;
}

/**
 * App Title's Region Lockout Flag depending by bitmask value.
 * @since 1.6.0
 */
enum FSSMDHAppRegionLockout {
	JAPAN;
	NORTH_AMERICA;
	EUROPE;
	AUSTRALIA;
	CHINA;
	KOREA;
	TAIWAN;
}

/**
 * @since 1.6.0
 * The Title's App Settings.
 */
typedef FSSMDHAppSettings = {
	var gameRatings:Array<FSSMDHAppGameRatingsFlag>;
	var regionLock:Array<FSSMDHAppRegionLockout>;
};

/**
 * SMDH Metadata for a specific title.
 * 
 * TODO: Finish these.
 * @since 1.6.0
 */
@:cppFileCode('
#include "haxe3ds_Utils.h"

struct SMDH {
	struct Header {
		u32 magic;
		u16 version;
		u16 reserved;
	};

	struct ApplicationTitle {
		u16 shortDescription[0x40];
		u16 longDescription[0x80];
		u16 publisher[0x40];
	};

	struct Settings {
		u8 gameRatings[0x10];
		u32 regionLock;
		u32 matchmaker_id;
		u64 matchmaker_id_bit;
		u32 flags;
		u16 eulaVersion;
		u16 reserved;
		u32 defaultFrame;
		u32 cecId;
	};

	Header header;
	ApplicationTitle applicationTitles[16];
	Settings settings;
	u64 reserved;
	u8 smallIconData[0x480];
	u16 bigIconData[0x900];
};
')
class FSSMDH {
	public var result(default, null):Result = 0;
	public var valid(default, null):Bool = false;
	public var applicationTitles(default, null):Array<FSSMDHAppTitle> = [];
	public var appSettings(default, null):FSSMDHAppSettings = {
		gameRatings: [],
		regionLock: []
	};

	public function new(highTID:Int, lowTID:Int, media:FSMediaType) {
		untyped __cpp__('
			u32 archPath[] = {lowTID, highTID, (FS_MediaType)media, 0x0};
			static const u32 filePath[] = {0x0, 0x0, 0x2, 0x6E6F6369, 0x0};

			SMDH smdhData;
			FS_Path binArchPath = {PATH_BINARY, 0x10, archPath};
			FS_Path binFilePath = {PATH_BINARY, 0x14, filePath};
			Handle file;
			u32 read;

			#define RETURN_IF_FAILED(x) {\\
				Result y = x; \\
				if (R_FAILED(y)) { \\
					this->result = y; \\
					if (file) FSUSER_CloseArchive(file); \\
					return; \\
				} \\
			} \\

			RETURN_IF_FAILED(FSUSER_OpenFileDirectly(&file, ARCHIVE_SAVEDATA_AND_CONTENT, binArchPath, binFilePath, FS_OPEN_READ, 0));
			RETURN_IF_FAILED(FSFILE_Read(file, &read, 0, &smdhData, sizeof(SMDH)));
			FSUSER_CloseArchive(file);

			if (!(valid = (smdhData.header.magic == 0x48444D53))) {
				return;
			}

			#undef RETURN_IF_FAILED
		');

		for (i in 0...12) {
			applicationTitles.push({
				shortDescription: untyped __cpp__('u16ToString(smdhData.applicationTitles[{0}].shortDescription)', i),
				longDescription: untyped __cpp__('u16ToString(smdhData.applicationTitles[{0}].longDescription)', i),
				publisher: untyped __cpp__('u16ToString(smdhData.applicationTitles[{0}].publisher)', i)
			});
		}

		final flags:Array<FSSMDHAppGameRatingsFlag> = [CERO, ESRB, USK, PEGI_GEN, PEGI_PRT, PEGI_BBFC, COB, GRB, CGSRR];
		for (i in 0...12) {
			if (i == 2 || i == 5) continue;

			if (untyped __cpp__('smdhData.settings.gameRatings[{0}]', i)) {
				var j:Int = i;
				if (i > 1) j--;
				if (i > 4) j--;
				this.appSettings.gameRatings.push(flags[j]);
			}
		}

		final Lflags:Array<FSSMDHAppRegionLockout> = [JAPAN, NORTH_AMERICA, EUROPE, AUSTRALIA, CHINA, KOREA, TAIWAN];
		for (i in 0...7) {
			if (untyped __cpp__('BIT({0}) & smdhData.settings.regionLock', i)) {
				this.appSettings.regionLock.push(Lflags[i]);
			}
		}
	}
}