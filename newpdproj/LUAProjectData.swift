//
//  LUAProjectData.swift
//  newpdproj
//
//  Created by Galt Johnson on 1/12/23.
//

import Foundation

let LUAProjectFiles: [ (path: String, contents: String) ] = [
    ("makefile", """
        .PHONY: clean
        .PHONY: build
        .PHONY: run
        .PHONY: copy

        SDK = $(shell egrep '^\\s*SDKRoot' ~/.Playdate/config | head -n 1 | cut -c9-)
        SDKBIN=$(SDK)/bin
        GAME=$(notdir $(CURDIR))
        SIM=Playdate Simulator

        build: clean compile run

        run: open

        clean:
        \trm -rf '$(GAME).pdx'

        compile: Source/main.lua
        \t"$(SDKBIN)/pdc" 'Source' '$(GAME).pdx'

        open:
        \topen -a '$(SDKBIN)/$(SIM).app/Contents/MacOS/$(SIM)' '$(GAME).pdx'
        """),
    ("Source/main.lua", #"""
        --[[
         *
         *  main.lua
         *  #PROJECT#
         *
         *  Created by #CREATOR# on #DATE#
         *
        --]]
        local gfx = playdate.graphics

        function playdate.update()
            ;
        end

        """#),
    ("Source/pdxinfo", #"""
        name=#APPNAME#
        author=#CREATOR#
        description=#DESCRIPTION#
        bundleID=#BUNDLEID#
        imagePath=ProjectAssets
        """#)

]
