//
//  CProjectData.swift
//  newpdproj
//
//  Created by Galt Johnson on 1/12/23.
//

import Foundation

let CProjectFiles: [ (path: String, contents: String) ] = [
    ("CMakeLists.txt", #"""
        cmake_minimum_required(VERSION 3.14)
        set(CMAKE_C_STANDARD 11)

        set(ENVSDK $ENV{PLAYDATE_SDK_PATH})

        if (NOT ${ENVSDK} STREQUAL "")
            # Convert path from Windows
            file(TO_CMAKE_PATH ${ENVSDK} SDK)
        else()
            execute_process(
                    COMMAND bash -c "egrep '^\\s*SDKRoot' $HOME/.Playdate/config"
                    COMMAND head -n 1
                    COMMAND cut -c9-
                    OUTPUT_VARIABLE SDK
                    OUTPUT_STRIP_TRAILING_WHITESPACE
            )
        endif()

        if (NOT EXISTS ${SDK})
            message(FATAL_ERROR "SDK Path not found; set ENV value PLAYDATE_SDK_PATH")
            return()
        endif()

        set(CMAKE_CONFIGURATION_TYPES "Debug;Release")
        set(CMAKE_XCODE_GENERATE_SCHEME TRUE)

        # Game Name Customization
        set(PLAYDATE_GAME_NAME #PROJECT#)
        set(PLAYDATE_GAME_DEVICE #PROJECT#_DEVICE)

        project(${PLAYDATE_GAME_NAME} C ASM)

        set(SOURCE_FILES src/main.c src/update.c src/globals.c)

        if (TOOLCHAIN STREQUAL "armgcc")
            add_executable(${PLAYDATE_GAME_DEVICE} ${SDK}/C_API/buildsupport/setup.c ${SOURCE_FILES} )
        else()
            add_library(${PLAYDATE_GAME_NAME} SHARED ${SOURCE_FILES} )
        endif()

        include(${SDK}/C_API/buildsupport/playdate_game.cmake)
        """#),
    ("createProjects.sh", #"""
        #!/bin/sh

        if ! [ -e Source ]; then
            echo "No Source direcctory" 1>&2
            exit 1
        fi

        SDK="${PLAYDATE_SDK_PATH}"
        if [ -z "$SDK" ]; then
            if [ -f ~/.Playdate/config ]; then
                SDK=$(sed -Ene "s/[[:space:]]*SDKRoot[[:space:]]+(.*)[[:space:]]*/\1/p" < ~/.Playdate/config)
            else
                echo "Could not find Playdate SDK. Please set PLAYDATE_SDK_PATH environment variable" 1>&2
                exit 1
            fi
        fi

        if [ -z "$SDK" ]; then
            echo "Could not find Playdate SDK. Please set PLAYDATE_SDK_PATH environment variable" 1>&2
            exit 1
        fi

        mkdir devbuild
        cd devbuild
        cmake -DCMAKE_TOOLCHAIN_FILE="${SDK}/C_API/buildsupport/arm.cmake" ..

        cd ..
        mkdir xcodebuild
        cd xcodebuild
        cmake -G Xcode ..

        exit 0
        """#),
    ("Makefile", #"""
        HEAP_SIZE      = 8388208
        STACK_SIZE     = 61800

        PRODUCT = #BUNDLEID#.pdx

        # Locate the SDK
        SDK = ${PLAYDATE_SDK_PATH}
        ifeq ($(SDK),)
            SDK = $(shell egrep '^\s*SDKRoot' ~/.Playdate/config | head -n 1 | cut -c9-)
        endif

        ifeq ($(SDK),)
        $(error SDK path not found; set ENV value PLAYDATE_SDK_PATH)
        endif

        ######
        # IMPORTANT: You must add your source folders to VPATH for make to find them
        # ex: VPATH += src1:src2
        ######

        VPATH += src

        # List C source files here
        SRC = src/main.c src/globals.c src/update.c

        # List all user directories here
        UINCDIR =

        # List user asm files
        UASRC =

        # List all user C define here, like -D_DEBUG=1
        UDEFS =

        # Define ASM defines here
        UADEFS =

        # List the user directory to look for the libraries here
        ULIBDIR =

        # List all user libraries here
        ULIBS =

        include $(SDK)/C_API/buildsupport/common.mk
        """#),
    ("Source/pdxinfo", #"""
        name=#APPNAME#
        author=#CREATOR#
        description=#DESCRIPTION#
        bundleID=#BUNDLEID#
        imagePath=ProjectAssets
        """#),
    ("src/update.c", #"""
        //
        //  update.c
        //  #PROJECT#
        //
        //  Created by #CREATOR# on #DATE#
        //

        #include <stdio.h>
        #include <stdlib.h>

        #include "pd_api.h"

        #include "globals.h"
        #include "update.h"

        void gameInit(const PlaydateAPI * const pd) {
            Log("Game initialized");

            pd->system->setUpdateCallback(update, (void *)pd);
        }

        int update(void *userdata)
        {
            return 1;
        }
        """#),
    ("src/globals.h", #"""
        //
        //  globals.h
        //  #PROJECT#
        //
        //  Created by #CREATOR# on #DATE#
        //

        #pragma once

        struct PlaydateAPI;
        extern const PlaydateAPI *api;

        extern void initializeGlobals(PlaydateAPI *api);

        extern void (*Log)(const char *fmt, ...) __attribute__((format(printf, 1, 2)));
        extern void (*LogError)(const char *fmt, ...) __attribute__((format(printf, 1, 2)));

        //#define ALLOC_DEBUG

        #if defined(ALLOC_DEBUG)

        extern void *(*debugpdrealloc)(const char *file, int line, void *ptr, size_t size);
        #define pdrealloc(ptr, size) debugpdrealloc(__FILE__, __LINE__, ptr, size)

        #else

        extern void *(*pdrealloc)(void *ptr, size_t size);

        #endif
        """#),
    ("src/main.c", #"""
        //
        //  main.c
        //  #PROJECT#
        //
        //  Created by #CREATOR# on #DATE#
        //

        #include <stdio.h>
        #include <stdlib.h>

        #include "pd_api.h"

        #include "globals.h"
        #include "update.h"

        int eventHandler(PlaydateAPI* pd, PDSystemEvent event, uint32_t arg)
        {
            switch (event) {
                case kEventInit: {
                    initializeGlobals(pd);
                    gameInit(pd);
                    break;
                }

        #if 0
                case kEventPause:
                    Log("Pause event");
                    break;

                case kEventLock:
                    Log("Lock event");
                    break;

                case kEventUnlock:
                    Log("Unlock event");
                    break;

                case kEventResume:
                    Log("Resume event");
                    break;

                case kEventTerminate:
                    Log("Terminate event");
                    break;

                case kEventLowPower:
                    Log("Low power event");
                    break;

                case kEventKeyPressed:
                    Log("Key down: %d", arg);
                    break;

                case kEventKeyReleased:
                    Log("Key up: %d", arg);
                    break;

                case kEventInitLua:
                    Log("Lua?!?");
                    break;
        #endif
                default:
                    Log("%s:%d: Unexpected event: %d", __FILE__, __LINE__, event);
                    break;
            }

            return 0;
        }
        """#),
    ("src/globals.c", #"""
        //
        //  globals.c
        //  #PROJECT#
        //
        //  Created by #CREATOR# on #DATE#
        //

        #include <stdio.h>
        #include <stdlib.h>

        #include "pd_api.h"

        #include "globals.h"

        const PlaydateAPI *api;

        void (*Log)(const char *fmt, ...) __attribute__((format(printf, 1, 2)));
        void (*LogError)(const char *fmt, ...) __attribute__((format(printf, 1, 2)));
        void *(*pdrealloc)(void *ptr, size_t size);

        #if defined(ALLOC_DEBUG)

        static void *(*real_pdrealloc)(void *ptr, size_t size);
        static void *_debug_realloc(const char *file, int line, void *ptr, size_t size) {
            if (ptr == NULL) {
                void *result = real_pdrealloc(ptr, size);
                Log("*a %s:%d %p %u", file, line, result, (unsigned)size);
                return result;
            }
            else if (size == 0) {
                Log("*f %s:%d %p", file, line, ptr);
                return real_pdrealloc(ptr, size);
            }
            else {
                void *result = real_pdrealloc(ptr, size);
                Log("*r %s:%d %p %u %p", file, line, ptr, (unsigned)size, result);
                return result;
            }
        }

        void *(*debugpdrealloc)(const char *file, int line, void *ptr, size_t size);

        static void initRealloc(void *(*func)(void *ptr, size_t size)) {
            debugpdrealloc = _debug_realloc;
            real_pdrealloc = func;
        }
        #else

        void *(*pdrealloc)(void *ptr, size_t size);

        static void initRealloc(void *(*func)(void *ptr, size_t size)) {
            pdrealloc = func;
        }

        #endif

        void initializeGlobals(PlaydateAPI *pd) {
            api = pd;
            Log = pd->system->logToConsole;
            LogError = pd->system->error;

            initRealloc(pd->system->realloc);
        }
        """#),
    ("src/update.h", #"""
        //
        //  update.h
        //  #PROJECT#
        //
        //  Created by #CREATOR# on #DATE#
        //

        #pragma once
        extern int update(void * userdata);

        extern void gameInit(const PlaydateAPI * const pd);
        """#)
]
