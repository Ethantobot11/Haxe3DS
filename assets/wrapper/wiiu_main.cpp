#ifdef __WIIU__
#include <wut.h>
#include <proc_ui/procui.h>
#include <coreinit/thread.h>
#include <coreinit/memory.h>
#include <hxcpp.h>
#include <cstdio>
#include <cstdlib>

extern "C" void __hxcpp_main();
extern "C" void __boot_all();

static void SaveCallback() {
    OSSavesDone_ReadyToRelease();
}

extern "C" int main(int argc, char **argv) {
    ProcUIInit(&SaveCallback);
    
    hx::Boot();
    
    int exitCode = EXIT_SUCCESS;
    
    try {
        __boot_all();
        __hxcpp_main();
    } catch (Dynamic d) {
        printf("[EXCEPTION OCCURRED!]\n%s\n\n", String(d).c_str());
        __hx_dump_stack();
        exitCode = EXIT_FAILURE;
    }
    
    ProcUIShutdown();
    
    return exitCode;
}
#endif
