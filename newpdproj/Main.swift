//
//  main.swift
//  newpdproj
//
//  Created by Galt Johnson on 1/12/23.
//

import AppKit
import ArgumentParser
import Darwin
import Foundation
import RegexBuilder

/*
 #APPNAME#
 #PROJECT#
 #BUNDLEID#
 #CREATOR#
 #DATE#
 #DESCRIPTION#
 */

extension String : Error {}

@main
struct CreateProject : ParsableCommand {
    private static let projectAssetsPath = "Source/ProjectAssets"

    enum ProjectType : EnumerableFlag {
        case cproject, luaproject

        var sourceDirectories: [String] {
            switch self {
            case .cproject:
                return ["src", CreateProject.projectAssetsPath]

            case .luaproject:
                return [CreateProject.projectAssetsPath]
            }
        }

        static func name(for value: CreateProject.ProjectType) -> NameSpecification {
            switch value {
            case .cproject:
                return [.long, .customShort("c")]

            case .luaproject:
                return [.long, .customShort("l")]
            }
        }
    }

    static var configuration = CommandConfiguration(commandName: "newpdproj", abstract: "Create empty Playdate projects")

    @Flag(name: [.long, .short], help: "Force creation of the project.")
    var force = false

    @Option(name: [.long, .customShort("r")], help: "Name of the project creator. Defaults to user's full name")
    var creator: String?

    @Option(name: .shortAndLong, help: "Description of the project.")
    var description: String?

    @Flag(help: "Project type")
    var projectType: ProjectType

    @Argument(help: "Project directory.")
    var projectDir: String

    @Argument(help: "The name of the project (e.g. \"nifty\")")
    var projectName: String

    @Argument(help: "Full application name as it appears on Playdate (e.g. \"My Nifty Application\")")
    var applicationName: String

    @Argument(help: "The bundle identifier in reverse domain notation (e.g. \"org.foo.niftyapp")
    var bundleIdentifier: String

    private var substitutions: [String : String]!

    fileprivate func createCProject(projectURL: URL) throws {
        let fileManager = FileManager.default

        for file in CProjectFiles {
            try create(file.path, with: file.contents, at: projectURL)
        }

        let createScriptPath = URL(fileURLWithPath: "createProjects.sh", relativeTo: projectURL).absoluteURL.path(percentEncoded: false)

        try fileManager.setAttributes([.posixPermissions : 0o766], ofItemAtPath: createScriptPath)
    }

    fileprivate func createLUAProject(projectURL: URL) throws {
        for file in LUAProjectFiles {
            try create(file.path, with: file.contents, at: projectURL)
        }
    }

    mutating func run() throws {
        let fileManager = FileManager.default

        guard force || !fileManager.fileExists(atPath: projectDir) else {
            throw "\(projectDir) already exists"
        }

        substitutions = [
            "APPNAME" : applicationName,
            "PROJECT" : projectName,
            "BUNDLEID" : bundleIdentifier,
            "CREATOR" : creator ?? NSFullUserName(),
            "DATE" : Date().formatted(date: .abbreviated, time: .omitted),
            "DESCRIPTION" : description ?? ""
        ]

        let projectURL = URL(fileURLWithPath: projectDir, isDirectory: true)

        for dir in projectType.sourceDirectories{
            let srcURL = URL(fileURLWithPath: dir, isDirectory: true, relativeTo: projectURL)
            try fileManager.createDirectory(at: srcURL, withIntermediateDirectories: true)
        }

        if projectType == .cproject {
            try createCProject(projectURL: projectURL)
        }
        else {
            try createLUAProject(projectURL: projectURL)
        }

        let (card, launchImage) = createProjectBitmaps()
        let assetsURL = URL(fileURLWithPath: CreateProject.projectAssetsPath, isDirectory: true, relativeTo: projectURL)

        let cardPath = URL(fileURLWithPath: "card.png", isDirectory: false, relativeTo: assetsURL).absoluteURL.path(percentEncoded: false)
        let launchImagePath = URL(fileURLWithPath: "launchImage.png", isDirectory: false, relativeTo: assetsURL).absoluteURL.path(percentEncoded: false)

        fileManager.createFile(atPath: cardPath, contents: card)
        fileManager.createFile(atPath: launchImagePath, contents: launchImage)
    }

    private func create(_ filePath: String, with contents: String, at baseURL: URL) throws {
        let filePath = URL(fileURLWithPath: filePath, relativeTo: baseURL).absoluteURL.path(percentEncoded: false)

        let fileContents = replaceTokens(in: contents)

        FileManager.default.createFile(atPath: filePath, contents: fileContents)
    }

    private func replaceTokens(in contents: String) -> Data {
        let pattern = Regex {
            "#"
            Capture {
                ChoiceOf {
                    "APPNAME"
                    "PROJECT"
                    "BUNDLEID"
                    "CREATOR"
                    "DATE"
                    "DESCRIPTION"
                }
            }
            "#"
        }

        var result = Data()
        for lineSubstr in contents.split(separator: "\n", omittingEmptySubsequences: false) {
            var line = String(lineSubstr)

            while let match = try? pattern.firstMatch(in: line) {
                line.replaceSubrange(match.range, with: substitutions[String(match.output.1), default: "***MISSING***"])
            }

            result.append(line.data(using: .utf8)!)
            result.append(contentsOf: [0x0a])
        }

        return result
    }

    private func createProjectBitmaps() -> (card: Data, launchImage: Data) {
        return (createImage(size: NSSize(width: 350, height: 155)), createImage(size: NSSize(width: 400, height: 240)))
    }

    private func createImage(size: NSSize) -> Data {
        let name = substitutions["APPNAME"]! as NSString

        let image = NSImage(size: size, flipped: true) { rect in
            NSColor.black.setStroke()
            rect.frame(withWidth: 3.0)

            rect.insetBy(dx: 10, dy: 10).frame(withWidth: 2)

            var fontSize: Double = 50
            var nameSize: NSSize
            var font: NSFont
            var attributes: [NSAttributedString.Key : Any]

            repeat {
                if let herculanum = NSFont(name: "Copperplate", size: fontSize) {
                    font = herculanum
                }
                else {
                    font = NSFont.systemFont(ofSize: fontSize, weight: .bold)
                }

                attributes = [.font : font]
                nameSize = name.size(withAttributes: attributes)

                fontSize -= 1
            } while nameSize.width > rect.width - 20 && fontSize > 9

            font.set()

            let drawLocation = NSPoint(x: rect.midX - nameSize.width / 2, y: rect.midY - nameSize.height / 2)
            name.draw(at: drawLocation, withAttributes: attributes)

            return true
        }

        let tiffData = image.tiffRepresentation!
        let pngData = NSBitmapImageRep(data: tiffData)!.representation(using: .png, properties: [:])!

        return pngData
    }
}
