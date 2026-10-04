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
		#if HAXE3DS
		return untyped __cpp__('API_GETTER(bool, FSUSER_IsSdmcDetected, 0)');
		#else
		return true;
		#end
	}

	public static var isSDMCWritable(get, null):Bool;
	static function get_isSDMCWritable():Bool {
		#if HAXE3DS
		return untyped __cpp__('API_GETTER(bool, FSUSER_IsSdmcWritable, 0)');
		#else
		return true;
		#end
	}

	#if HAXE3DS
	#if IS_CIA
	public static function mountSaveData(partition:String = "ext", files:Int = 1, dirs:Int = 1):Result {
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
	}

	public static function flushAndCommit(partition:String = "ext"):Result {
		return untyped __cpp__('archiveCommitSaveData(partition.c_str())');
	}
	#end
	#end

	public static var playCoins(get, set):UInt16;
	
	static function get_playCoins():UInt16 {
		#if HAXE3DS
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
		#if HAXE3DS
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
		#if HAXE3DS
		return untyped __cpp__('FSUSER_DeleteFile(FSD::get_sdmcRoot(), fsMakePath(PATH_ASCII, path.c_str()))');
		#else
		return 0;
		#end
	}

	public static function renameFile(source:String, destination:String):Result {
		#if HAXE3DS
		return untyped __cpp__('FSUSER_RenameFile(FSD::get_sdmcRoot(), fsMakePath(PATH_ASCII, source.c_str()), FSD::get_sdmcRoot(), fsMakePath(PATH_ASCII, destination.c_str()))');
		#else
		return 0;
		#end
	}

	public static function deleteDir(source:String, recursive:Bool = false):Result {
		#if HAXE3DS
		untyped __cpp__('FS_Path p = fsMakePath(PATH_ASCII, source.c_str())');
		return untyped __cpp__('recursive ? FSUSER_DeleteDirectoryRecursively(FSD::get_sdmcRoot(), p) : FSUSER_DeleteDirectory(FSD::get_sdmcRoot(), p)');
		#else
		return 0;
		#end
	}

	public static var ctrRootPath(default, null):String = "";
	static function get_ctrRootPath():String {
		#if HAXE3DS
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
		#if HAXE3DS
		untyped __cpp__('
			FSUSER_CloseArchive(FSD::get_sdmcRoot());
			fsExit()
		');
		#else
		#end
	}
}
