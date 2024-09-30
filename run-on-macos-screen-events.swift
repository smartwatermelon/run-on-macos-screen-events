import Foundation

let name = (CommandLine.arguments[0] as NSString).lastPathComponent
let version = "1.1.0"
let build = "2024-09-30-001"
let author = "AJ ONeal <aj@therootcompany.com>"
let fork = "Andrew Rich <andrew.rich@gmail.com>"

let versionMessage = "\(name) \(version) (\(build))"
let copyrightMessage = "Copyright 2024 \(author)"
let copyrightMessage = "\(copyrightMessage)\nForked by \(fork)\"

let helpMessage = """
Runs user-specified commands when the screen is locked or unlocked by
listening for the "com.apple.screenIsLocked" and "com.apple.screenIsUnlocked" events.
It uses /usr/bin/command -v to find the program in the user's PATH (or the explicit path given),
and then runs it with /usr/bin/command, which can run aliases and shell functions also.

USAGE
  \(name) [OPTIONS] --lock <lock-command> [lock-command-arguments] --unlock <unlock-command> [unlock-command-arguments]

OPTIONS
  --lock <command> [args]     Specify the command to run when the screen is locked
  --unlock <command> [args]   Specify the command to run when the screen is unlocked
  --version, -V, version      Display the version information and exit
  --help, help                Display this help and exit

At least one of --lock or --unlock must be specified. If either is omitted, no action will be taken for that event.

EXAMPLES
  \(name) --lock "/path/to/lock-script.sh" --unlock "/path/to/unlock-script.sh"
  \(name) --lock "echo 'Screen locked' >> /tmp/screen-events.log" --unlock "echo 'Screen unlocked' >> /tmp/screen-events.log"
"""

signal(SIGINT) { _ in
    printForHuman("received ctrl+c, exiting...")
    exit(0)
}

func printForHuman(_ message: String) {
    if let data = "\(message)\n".data(using: .utf8) {
        FileHandle.standardError.write(data)
    }
}

func getCommandPath(_ command: String) -> String? {
    let commandv = Process()
    commandv.launchPath = "/usr/bin/command"
    commandv.arguments = ["-v", command]

    let pipe = Pipe()
    commandv.standardOutput = pipe
    commandv.standardError = FileHandle.standardError

    try! commandv.run()
    commandv.waitUntilExit()

    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    guard let commandPath = String(data: data, encoding: .utf8)?
        .trimmingCharacters(in: .whitespacesAndNewlines)
    else {
        return nil
    }

    if commandv.terminationStatus != 0, commandPath.isEmpty {
        return nil
    }

    return commandPath
}

class ScreenLockObserver {
    var lockCommandArgs: ArraySlice<String>?
    var unlockCommandArgs: ArraySlice<String>?

    init(lockCommandArgs: ArraySlice<String>?, unlockCommandArgs: ArraySlice<String>?) {
        self.lockCommandArgs = lockCommandArgs
        self.unlockCommandArgs = unlockCommandArgs

        let dnc = DistributedNotificationCenter.default()

        NSLog("Waiting for screen lock/unlock events")

        _ = dnc.addObserver(forName: NSNotification.Name("com.apple.screenIsLocked"), object: nil, queue: .main) { _ in
            NSLog("notification: com.apple.screenIsLocked")
            if let args = self.lockCommandArgs {
                self.runCommand(args)
            }
        }

        _ = dnc.addObserver(forName: NSNotification.Name("com.apple.screenIsUnlocked"), object: nil, queue: .main) { _ in
            NSLog("notification: com.apple.screenIsUnlocked")
            if let args = self.unlockCommandArgs {
                self.runCommand(args)
            }
        }
    }

    private func runCommand(_ args: ArraySlice<String>) {
        guard let commandPath = args.first else {
            NSLog("No command specified")
            return
        }

        let task = Process()
        task.launchPath = "/usr/bin/command"
        task.arguments = Array(args)
        task.standardOutput = FileHandle.standardOutput
        task.standardError = FileHandle.standardError

        do {
            try task.run()
        } catch {
            printForHuman("Failed to run \(commandPath): \(error.localizedDescription)")
            if let nsError = error as NSError? {
                printForHuman("Error details: \(nsError)")
            }
        }

        task.waitUntilExit()
    }
}

func processArgs(_ args: inout ArraySlice<String>) -> (ArraySlice<String>?, ArraySlice<String>?) {
    var lockArgs: ArraySlice<String>?
    var unlockArgs: ArraySlice<String>?

    while !args.isEmpty {
        switch args.first {
        case "--lock":
            args.removeFirst()
            lockArgs = collectCommandArgs(&args)
        case "--unlock":
            args.removeFirst()
            unlockArgs = collectCommandArgs(&args)
        case "--help", "help":
            printHelp()
            exit(0)
        case "--version", "-V", "version":
            printVersion()
            exit(0)
        default:
            printForHuman("Unknown option: \(args.first ?? "")")
            printHelp()
            exit(1)
        }
    }

    return (lockArgs, unlockArgs)
}

func collectCommandArgs(_ args: inout ArraySlice<String>) -> ArraySlice<String> {
    var commandArgs: ArraySlice<String> = []
    while !args.isEmpty && args.first != "--lock" && args.first != "--unlock" {
        commandArgs.append(args.removeFirst())
    }
    return commandArgs
}

func printHelp() {
    printForHuman(versionMessage)
    printForHuman("")
    printForHuman(helpMessage)
    printForHuman("")
    printForHuman(copyrightMessage)
}

func printVersion() {
    printForHuman(versionMessage)
    printForHuman(copyrightMessage)
}

// Main execution
var args = CommandLine.arguments[1...]
let (lockCommandArgs, unlockCommandArgs) = processArgs(&args)

if lockCommandArgs == nil && unlockCommandArgs == nil {
    printForHuman("No commands specified. Please provide at least one command.")
    printHelp()
    exit(1)
}

_ = ScreenLockObserver(lockCommandArgs: lockCommandArgs, unlockCommandArgs: unlockCommandArgs)

RunLoop.main.run()
