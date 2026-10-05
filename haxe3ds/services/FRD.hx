package haxe3ds.services;

import sys.thread.Thread;
import haxe3ds.types.Event;
import haxe3ds.types.NanoTime;
import haxe3ds.types.Result;
import cpp.UInt8;
import cpp.UInt32;
import cpp.UInt64;

enum FRDRelationship { NOT_REGISTERED; REGISTERED; NOT_FOUND; DELETED; LOCAL_ADDED; UNKNOWN; }
typedef FRDPreference = { var publicMode:Bool; var showGameName:Bool; var showPlayedGame:Bool; }
typedef FRDProfile = { var region:UInt8; var country:UInt8; var area:UInt8; var language:UInt8; }
typedef FRDFriendDetail = {
	var comment:String; var displayName:String; var profile:FRDProfile; var addedTimestamp:NanoTime;
	var principalID:UInt32; var male:Bool; var relationship:FRDRelationship; var favoriteGameTID:UInt64;
}
enum abstract FRDNotifTypes(Int) {
	var SELF_ONLINE = 1; var SELF_OFFLINE; var FRIEND_ONLINE; var FRIEND_PRESENCE_CHANGED;
	var FRIEND_MII_CHANGED; var FRIEND_PROFILE_CHANGED; var FRIEND_OFFLINE; var FRIEND_REGISTERED; var FRIEND_GOT_INVITED;
}

#if HAXE3DS
@:cppFileCode('
#include "haxe3ds_Utils.h"
Handle frd_Handle; bool frd_ShouldExit = false;
Dynamic fiToFD(FriendInfo& f) {
	using r = haxe3ds::services::FRDRelationship_obj;
	haxe3ds::services::FRDRelationship relation = null();
	switch(f.relationship) {
		case 0: {relation = r::NOT_REGISTERED_dyn(); break;} case 1: {relation = r::REGISTERED_dyn(); break;}
		case 2: {relation = r::NOT_FOUND_dyn(); break;} case 3: {relation = r::DELETED_dyn(); break;}
		case 4: {relation = r::LOCAL_ADDED_dyn(); break;} default:{relation = r::UNKNOWN_dyn(); break;}
	};
	Dynamic temp = Dynamic(hx::Anon_obj::Create(4)->setFixed(0,String("region"),f.friendProfile.profile.region)->setFixed(1,String("country"),f.friendProfile.profile.country)->setFixed(2,String("area"),f.friendProfile.profile.area)->setFixed(3,String("language"),f.friendProfile.profile.language));
	return Dynamic(hx::Anon_obj::Create(8)->setFixed(0,String("comment"),u16ToString(f.friendProfile.personalMessage))->setFixed(1,String("favoriteGameTID"),f.friendProfile.favoriteGame.titleId)->setFixed(2,String("principalID"),(int)f.friendKey.principalId)->setFixed(3,String("addedTimestamp"),f.addedTimestamp)->setFixed(4,String("profile"),temp)->setFixed(5,String("relationship"),relation)->setFixed(6,String("displayName"),u16ToString(f.screenName))->setFixed(7,String("male"),!f.mii.miiData.mii_details.sex));
}
void NotificationThread() {
	while (!frd_ShouldExit) {
		if (svcWaitSynchronization(frd_Handle, 1e9) == 0) {
			auto caller = haxe3ds::services::FRD_obj::notifCallback;
			if (caller == null()) continue;
			NotificationEvent event; FriendInfo f; u32 totalNotifs;
			if R_FAILED(FRD_GetEventNotification(&event, 1, &totalNotifs)) continue;
			if R_FAILED(FRD_GetFriendInfo(&f, &event.sender, 1, false, false)) continue;
			caller->callEvents(Dynamic(hx::Anon_obj::Create(2)->setFixed(0,String("types"),event.type)->setFixed(1,String("detail"),fiToFD(f))));
		}
	}
}')
#end
class FRD {
	public static var loggedIn(get, null):Bool;
	static function get_loggedIn():Bool {
		#if HAXE3DS return untyped __cpp__('API_GETTER(bool, FRD_HasLoggedIn, 0)'); #else return false; #end
	}

	public static var isOnline(get, null):Bool;
	static function get_isOnline():Bool {
		#if HAXE3DS return untyped __cpp__('API_GETTER(bool, FRD_IsOnline, 0)'); #else return false; #end
	}

	public static var serverTime(get, null):NanoTime;
	static function get_serverTime():NanoTime {
		#if HAXE3DS return untyped __cpp__('API_GETTER(u64, FRD_GetServerTimeDifference, 0)'); #else return 0; #end
	}

	public static var localAccountId(get, null):UInt8;
	static function get_localAccountId():UInt8 {
		#if HAXE3DS return untyped __cpp__('API_GETTER(u8, FRD_GetMyLocalAccountId, 0)'); #else return 0; #end
	}

	public static var myProfile(get, null):Null<FRDFriendDetail>;
	static function get_myProfile():Null<FRDFriendDetail> {
		#if HAXE3DS
		untyped __cpp__('FriendKey key = API_GETTER(FriendKey, FRD_GetMyFriendKey, 0); FriendInfo f; if (R_FAILED(FRD_GetFriendInfo(&f, &key, 1, false, false))) return null();');
		return untyped __cpp__('fiToFD(f)');
		#else return null; #end
	}

	public static var notifCallback = new Event<{detail:FRDFriendDetail, types:FRDNotifTypes}>();

	public static function init(enableNotifications:Bool = true):Result {
		#if HAXE3DS
		var res:Result = 0;
		untyped __cpp__('res = frdInit(false); if (R_SUCCEEDED(res) && enableNotifications) { if R_FAILED(res = svcCreateEvent(&frd_Handle, RESET_ONESHOT)) return res; if R_FAILED(res = FRD_AttachToEventNotification(frd_Handle)) return res; {0}; }', Thread.create(() -> untyped __cpp__('NotificationThread()')));
		return res;
		#else return 0; #end
	}

	public static function updatePresence(textToUse:String):Result {
		#if HAXE3DS
		untyped __cpp__('FriendGameModeDescription desc = { 0}; TRANSFER(textToUse.c_str(), desc);');
		return untyped __cpp__('FRD_UpdateGameModeDescription(&desc)');
		#else return 0; #end
	}

	public static function updateComment(textToUse:String):Result {
		#if HAXE3DS
		untyped __cpp__('FriendComment desc = { 0}; TRANSFER(textToUse.c_str(), desc)');
		return untyped __cpp__('FRDA_UpdateComment(&desc)');
		#else return 0; #end
	}

	public static var halfAwake(null, set):Bool;
	static function set_halfAwake(halfAwake:Bool):Bool {
		#if HAXE3DS untyped __cpp__('FRD_AllowHalfAwake(halfAwake)'); #end
		return halfAwake;
	}

	public static function getFriendsProfile():Null<Array<FRDFriendDetail>> {
		#if HAXE3DS
		var out:Array<FRDFriendDetail> = [];
		untyped __cpp__('FriendKey list[100] = {}; FriendInfo prof[100] = {}; u32 l = 0; if R_FAILED(FRD_GetFriendKeyList(list, &l, 0, 100)) return null(); if R_FAILED(FRD_GetFriendInfo(prof, list, l, false, false)) return null();');
		for (i in 0...untyped __cpp__('l')) out.push(untyped __cpp__('fiToFD(prof[{0}])', i));
		return out;
		#else return []; #end
	}

	public static var preference(get, set):Null<FRDPreference>;
	static function get_preference():Null<FRDPreference> {
		#if HAXE3DS
		var publicP = false, gameName = false, showPlayed = false;
		untyped __cpp__('RETURN_NULL_IF_FAILED(FRD_GetMyPreference(&publicP, &gameName, &showPlayed))');
		return { publicMode: publicP, showPlayedGame: showPlayed, showGameName: gameName };
		#else return null; #end
	}
	static function set_preference(preference):Null<FRDPreference> {
		if (preference == null) return null;
		#if HAXE3DS untyped __cpp__('RETURN_NULL_IF_FAILED(FRDA_UpdatePreference({0}, {1}, {2}))', preference.publicMode, preference.showGameName, preference.showPlayedGame); #end
		return preference;
	}

	public static function exit() {
		notifCallback.clear();
		#if HAXE3DS untyped __cpp__('frd_ShouldExit = true; svcCloseHandle(frd_Handle); frdExit()'); #end
	}
}
