#include <3ds.h>
#include <hxcpp.h>
#include <sys/stat.h>
#include <stdio.h>

extern "C" void __hxcpp_main();
extern "C" void __hxcpp_lib_main();

extern int _hxcpp_argc;
extern char **_hxcpp_argv;

#include <malloc.h>
#include <sys/socket.h>

void __hxcpp_exit(int status) {
    std::exit(status);
}

void ensureDir(const char* path) {
    mkdir(path, 0777);
}

void HAXE3DS_CTRUException(ERRF_ExceptionInfo* excep, CpuRegisters* regs) {
    const char* crashDir = "sdmc:/DELTASHIT/crash";
    const char* crashFile = "sdmc:/DELTASHIT/crash/cpp_hard_crash.log";
    
    ensureDir("sdmc:/DELTASHIT");
    ensureDir(crashDir);

    FILE* f = fopen(crashFile, "w");
    if (f) {
        fprintf(f, "=== C/C++ HARD CRASH LOG ===\n");
        fprintf(f, "App Error [");
        #define CASEPR(x, y) \
            case x: { \
                fprintf(f, y "]\n\n"); \
                break; \
            } \

        switch(excep->type) {
            CASEPR(ERRF_EXCEPTION_PREFETCH_ABORT, "Prefetch Abort")
            CASEPR(ERRF_EXCEPTION_DATA_ABORT, "Data abort")
            CASEPR(ERRF_EXCEPTION_UNDEFINED, "Undefined instruction")
            CASEPR(ERRF_EXCEPTION_VFP, "VFP (floating point) exception")
            default: {
                fprintf(f, "Unknown]\n\n");
                break;
            }
        }

        for (u8 i = 0; i < 13; i++) {
            fprintf(f, "R%02d: 0x%08lX\n", i, regs->r[i]);
        }

        fprintf(f, "\n   SP: 0x%08lX      LR:   0x%08lX\n", regs->sp, regs->lr);
        fprintf(f, "   PC: 0x%08lX    CPSR:   0x%08lX\n", regs->pc, regs->cpsr);
        fprintf(f, "  FSR: 0x%08lX     FAR:   0x%08lX\n", excep->fsr, excep->far);
        fprintf(f, "FPEXC: 0x%08lX    FPI1:   0x%08lX\n", excep->fpexc, excep->fpinst);
        fprintf(f, " FPI2: 0x%08lX\n", excep->fpinst2);

        fprintf(f, "\n\nhaxelib run haxe3ds -e 0x%lX 0x%lX\n", regs->pc, regs->lr);
        fclose(f);
    }
    consoleInit(GFX_BOTTOM, NULL);
    consoleClear();
    printf("HARD CRASH DETECTED!\n");
    printf("PC: 0x%08lX\n", regs->pc);
    printf("Check: sdmc:/DELTASHIT/crash/cpp_hard_crash.log\n");
    printf("Press [START] to exit.");
    
    while (aptMainLoop()) {
        hidScanInput();
        if (hidKeysDown() & KEY_START) break;
        gspWaitForVBlank();
    }
    svcExitProcess();
}

extern "C" EXPORT_EXTRA int main() {
    ensureDir("sdmc:/DELTASHIT");
    ensureDir("sdmc:/DELTASHIT/crash");
    FILE* bootCheck = fopen("sdmc:/DELTASHIT/crash/boot_check.txt", "w");
    if (bootCheck) {
        fprintf(bootCheck, "C++ main() started successfully.\n");
        fclose(bootCheck);
    }

    threadOnException(HAXE3DS_CTRUException, RUN_HANDLER_ON_FAULTING_STACK, WRITE_DATA_TO_HANDLER_STACK);

    HX_TOP_OF_STACK
    hx::Boot();

    u32* SOC_buffer = (u32*)memalign(0x1000, 0x100000);
    if (R_FAILED(socInit(SOC_buffer, 0x100000))) svcBreak(USERBREAK_PANIC);
    
#ifdef HAXE3DS_LINKTO3DS
    int sock = link3dsStdio();
#endif

    int exitCode = EXIT_SUCCESS;

    try {
        __boot_all();
        __hxcpp_main();
    } catch (Dynamic d) {
        ensureDir("sdmc:/DELTASHIT/crash");
        FILE* f = fopen("sdmc:/DELTASHIT/crash/unhandled_haxe_crash.log", "w");
        if (f) {
            fprintf(f, "=== UNHANDLED HAXE EXCEPTION (Reached C++) ===\n");
            fprintf(f, "%s\n", String(d).c_str());
            fprintf(f, "\nCheck the console output or use haxelib run haxe3ds -e if a stack trace is available.\n");
            fclose(f);
        }

        consoleInit(GFX_TOP, NULL);
        consoleClear();
        printf("[EXCEPTION OCCURRED!]\n%s\n\n", String(d).c_str());
        __hx_dump_stack();
        
        printf("\nPress [START] to exit");
        while (aptMainLoop()) {
            hidScanInput();
            if (hidKeysDown() & KEY_START) break;
            gspWaitForVBlank();
        }

        exitCode = EXIT_FAILURE;
    }

#ifdef HAXE3DS_LINKTO3DS
    if (sock > 0) closesocket(sock);
#endif
    socExit();
    free(SOC_buffer);

    return exitCode;
}
