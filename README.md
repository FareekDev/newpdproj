# newpdproj
Create a new Playdate project for LUA or C

This a simple command-line utility written in Swift to create empty Playdate projects in C or Lua. To use the resulting project, you must have installed the Playdate SDK available [here.](https://play.date/dev/)

The utility creates a bare-bones project with both a launch screen and card image containing the name of your application as well as boilerplate code and makefiles.

The command line options are:
```
USAGE: newpdproj [--force] [--creator <creator>] [--description <description>] --cproject --luaproject <project-dir> <project-name> <application-name> <bundle-identifier>

ARGUMENTS:
  <project-dir>           Project directory.
  <project-name>          The name of the project (e.g. "nifty")
  <application-name>      Full application name as it appears on Playdate (e.g. "My Nifty
                          Application")
  <bundle-identifier>     The bundle identifier in reverse domain notation (e.g. "org.foo.niftyapp

OPTIONS:
  -f, --force             Force creation of the project.
  -r, --creator <creator> Name of the project creator. Defaults to user's full name
  -d, --description <description>
                          Description of the project.
  -c, --cproject/-l, --luaproject
                          Project type
  -h, --help              Show help information.
```

Building the project requires Xcode, and makes use of some Cocoa APIs for image generation.
