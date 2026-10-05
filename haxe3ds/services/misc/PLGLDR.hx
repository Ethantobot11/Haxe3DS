package haxe3ds.services.misc;

import haxe3ds.types.Result;

/**
 * A Miscellaneous Plugin Loader Service.
 * 
 * On 3DS: Uses Luma3DS's plg:ldr service for plugin loading and notifications.
 * On Wii U: WUPS handles plugin loading automatically. This is stubbed for compatibility.
 * 
 * @since 1.8.0
 */
#if HAXE3DS
@:cppInclude('haxe3ds_Utils.h')
@:cppNamespaceCode('
static int	plgldr_refcount;
static Handle plgldr_handle;
')
#end
class PLGLDR {
	/**
	 * Initializes Plugin Loader.
	 * On 3DS: Connects to the plg:ldr service port.
	 * On Wii U: Does nothing (WUPS handles this automatically).
	 */
	public static function init():Result {
		#if HAXE3DS
		var result:Result = 0;
		untyped __cpp__('
			if (AtomicPostIncrement(&plgldr_refcount) == 0) {
				result = svcConnectToPort(&plgldr_handle, "plg:ldr");
			}
		');
		return result;
		#else
		trace("PLGLDR: Wii U uses WUPS for plugin loading (no init needed)");
		return 0;
		#end
	}

	/**
	 * Exits Plugin Loader.
	 * On 3DS: Closes the plg:ldr service handle.
	 * On Wii U: Does nothing.
	 */
	public static function exit() {
		#if HAXE3DS
		untyped __cpp__('
			if (AtomicDecrement(&plgldr_refcount)) {
				return;
			} if (plgldr_handle) {
				svcCloseHandle(plgldr_handle);
			}
			plgldr_handle = 0;
		');
		#else
		#end
	}

	/**
	 * Displays a notification message.
	 * 
	 * On 3DS: Sends an IPC request to Luma3DS to show a message on the bottom screen.
	 * On Wii U: Stubbed. To show real notifications on Wii U, you would use
	 * the `libnotifications` library (OSDynLoad_Acquire("notifications", ...)).
	 * 
	 * @param title The title of the notification.
	 * @param message The body of the notification.
	 * @param result The result code to display (3DS only), leave as 0 to exclude.
	 * @return Result to indicate success or failure.
	 */
	public static function displayMessage(title:String, message:String, result:Result = 0):Result {
		#if HAXE3DS
		var res:Result = 0;

		untyped __cpp__('
			bool resultIsNone = result != 0;

			u32 *cmdBuf = getThreadCommandBuffer();
			cmdBuf[0] = IPC_MakeHeader(resultIsNone ? 7 : 6, resultIsNone ? 1 : 0, 4);
			if (resultIsNone) cmdBuf[1] = (u32)result;
			cmdBuf[1 + resultIsNone] = IPC_Desc_Buffer(title.length, IPC_BUFFER_R);
			cmdBuf[2 + resultIsNone] = (u32)title.c_str();
			cmdBuf[3 + resultIsNone] = IPC_Desc_Buffer(message.length, IPC_BUFFER_R);
			cmdBuf[4 + resultIsNone] = (u32)message.c_str();

			if (R_SUCCEEDED((res = svcSendSyncRequest(plgldr_handle)))) res = cmdBuf[1];
		');
		return res;
		#else
		//   OSDynLoad_Acquire("notifications.rpl", &handle);
		//   OSDynLoad_FindExport(handle, ..., "NotificationModule_AddInfoNotification", ...);
		trace('PLGLDR Notification: [$title] $message');
		return 0;
		#end
	}
}
