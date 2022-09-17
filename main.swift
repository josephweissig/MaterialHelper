//
//  main.swift
//  MaterialHelper
//
//  Created by Gold on 9/7/22.
//

import Foundation

extension StringProtocol {
    var isNumber: Bool {
        return !isEmpty && rangeOfCharacter(from: CharacterSet.decimalDigits.inverted) == nil
    }
}

class LineUtils {
    private let filename: String
    
    init(_ filename: String) {
        self.filename = filename
    }
    
    func splitLines() -> [String]? {
        do {
            let fileContents = try String(contentsOfFile: filename)
            let splitFile = fileContents.split(separator: "\n")
            return splitFile.map { String.init($0) }
        } catch {
            return nil
        }
    }
    
    static func useRegex(for text: String, using regex: NSRegularExpression) -> Bool {
        let range = NSRange(location: 0, length: text.count)
        let matches = regex.matches(in: text, options: [], range: range)
        return matches.first != nil
    }
}

class MaterialCollector {
    public var materials: [String: Int]
    
    init() {
        materials = [:]
    }
    
    private func addMaterial(_ name: String, _ amount: Int) {
        if let existingAmount = materials[name] {
//            materials.updateValue(name, existingAmount + amount)
            materials.updateValue(existingAmount + amount, forKey: name)
        } else {
//            materials.updateValue(name, amount)
            materials.updateValue(amount, forKey: name)
        }
        print("\(name): \(materials[name])")
    }
    
    func extractMaterial(_ line: String) {
        var materialName: String = ""
        var materialAmount: Int = 0
//        let splitLine = line.split(separator: " ")
        for word in line.split(separator: " ") {
            if word == "-" {
                continue
            } else if word.isNumber {
                materialAmount = Int(word)!
            } else {
                materialName += word + " "
            }
        }
        addMaterial(materialName, materialAmount)
    }
    
    private func exportMaterial(_ name: String, _ count: Int) -> String {
        return "- \(count) \(name)"
    }
    
    func exportMaterials() {
        let currentURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        let filename = currentURL.appendingPathComponent("materials.md")
        for (name, count) in materials {
            do {
                let line = exportMaterial(name, count)
                print(line)
            } catch {
                // failed to write file
            }
        }
    }
}

private func absURL(_ path: String) -> URL {
    guard path != "~" else {
        return FileManager.default.homeDirectoryForCurrentUser
    }
    guard path.hasPrefix("~/") else {
        return URL(fileURLWithPath: path)
    }

    var relativePath = path
    relativePath.removeFirst(2)
    return URL(fileURLWithPath: relativePath,
        relativeTo: FileManager.default.homeDirectoryForCurrentUser
    )
}

private func absPath(_ path: String) -> String {
    return absURL(path).path
}

guard CommandLine.argc > 1 else {
    print("You need to put a path to a Markdown file in!")
    exit(1)
}
let args = CommandLine.arguments.dropFirst()
print("\(args)")
let filepath = absPath(args[1])
let utils = LineUtils(filepath)
guard let lines = utils.splitLines() else {
    exit(1)
}
let materialCollector = MaterialCollector()

for line in lines {
    let regex = try! NSRegularExpression(pattern: "- [0-9]+ ([a-zA-Z]+( [a-zA-Z]+)+)", options: [.caseInsensitive])
    if LineUtils.useRegex(for: line, using: regex) {
        materialCollector.extractMaterial(line)
    }
}

let currentURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let filename = currentURL.appendingPathComponent("materials.md")
if !materialCollector.materials.isEmpty {
    materialCollector.exportMaterials()
}
