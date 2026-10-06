#ifdef __WIIU__
#include <wut.h>
#include <proc_ui/procui.h>
#include <hxcpp.h>
#include <hx/Boot.h>
#include <cstdio>
#include <cstdlib>

extern "C" void __hxcpp_main();

static uint32_t SaveCallback() {
    return 0;
}

extern "C" int main(int argc, char **argv) {
    ProcUIInit(SaveCallback);
    hx::Boot();
    
    int exitCode = EXIT_SUCCESS;
    
    try {
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
