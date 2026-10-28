import Foundation
import AstorkaCore

print("\u{001B}[1;36m")
print("==================================================================")
print("     ASTORKA ENGINE - NATIVE macOS NO-CODE RUNTIME (CLI)         ")
print("==================================================================")
print("\u{001B}[0m")

var targetProject: GameProject? = nil

// 1. Check command line arguments (e.g., astorka-cli game.astorkaproject)
let args = CommandLine.arguments
if args.count > 1 {
    let filePath = args[1]
    if let data = try? Data(contentsOf: URL(fileURLWithPath: filePath)),
       let loaded = try? GameProject.fromJSONData(data) {
        targetProject = loaded
    } else {
        print("\u{001B}[31mError: Could not read file '\(filePath)' or format is invalid.\u{001B}[0m")
        exit(1)
    }
}

// 2. Scan ~/Documents/AstorkaProjects and current directory for .astorkaproject files
let projectsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent("AstorkaProjects")
var foundProjectFiles: [URL] = []

if let pDir = projectsDir, let files = try? FileManager.default.contentsOfDirectory(at: pDir, includingPropertiesForKeys: nil) {
    foundProjectFiles.append(contentsOf: files.filter { $0.pathExtension == "astorkaproject" })
}
if let cwdFiles = try? FileManager.default.contentsOfDirectory(at: URL(fileURLWithPath: FileManager.default.currentDirectoryPath), includingPropertiesForKeys: nil) {
    for f in cwdFiles where f.pathExtension == "astorkaproject" || f.lastPathComponent == "AstorkaProject.json" {
        if !foundProjectFiles.contains(where: { $0.path == f.path }) {
            foundProjectFiles.append(f)
        }
    }
}

// 3. If no file argument, present project menu to user
if targetProject == nil {
    if !foundProjectFiles.isEmpty {
        print("📁 Saved Projects:")
        for (i, p) in foundProjectFiles.enumerated() {
            print("  [\(i + 1)] 🎮 \(p.deletingPathExtension().lastPathComponent) (\(p.lastPathComponent))")
        }
        print("  [N] ➕ Start New Blank CLI Game")
        print("  [Q] Quit\n")
        print("\u{001B}[33mSelect an option (1-\(foundProjectFiles.count) / N / Q): \u{001B}[0m", terminator: "")
        fflush(stdout)

        guard let choice = readLine()?.trimmingCharacters(in: .whitespacesAndNewlines) else {
            exit(0)
        }

        if let idx = Int(choice), idx >= 1 && idx <= foundProjectFiles.count {
            let selected = foundProjectFiles[idx - 1]
            if let data = try? Data(contentsOf: selected),
               let loaded = try? GameProject.fromJSONData(data) {
                targetProject = loaded
            }
        } else if choice.lowercased() == "n" {
            print("Game Title: ", terminator: "")
            fflush(stdout)
            let name = readLine()?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "New CLI Game"
            targetProject = GameProject.empty(title: name.isEmpty ? "New CLI Game" : name, type: .cli)
        } else {
            exit(0)
        }
    } else {
        print("No saved projects found.")
        print("  [1] 💻 Start New Blank CLI Game")
        print("  [2] 💾 Enter File Path (.astorkaproject / .json)")
        print("  [Q] Quit\n")
        print("\u{001B}[33mSelect an option (1-2 / Q): \u{001B}[0m", terminator: "")
        fflush(stdout)

        guard let choice = readLine()?.trimmingCharacters(in: .whitespacesAndNewlines) else {
            exit(0)
        }

        switch choice.lowercased() {
        case "1":
            print("Game Title: ", terminator: "")
            fflush(stdout)
            let name = readLine()?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "New CLI Game"
            targetProject = GameProject.empty(title: name.isEmpty ? "New CLI Game" : name, type: .cli)
        case "2":
            print("Enter file path: ", terminator: "")
            fflush(stdout)
            guard let path = readLine()?.trimmingCharacters(in: .whitespacesAndNewlines),
                  let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
                  let loaded = try? GameProject.fromJSONData(data) else {
                print("\u{001B}[31mFile not found or could not be opened!\u{001B}[0m")
                exit(1)
            }
            targetProject = loaded
        default:
            exit(0)
        }
    }
}

guard let project = targetProject else {
    exit(1)
}

let runner = CLIRunner(project: project)
runner.startInteractiveLoop()
