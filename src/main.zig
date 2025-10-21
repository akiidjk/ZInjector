//! The effective injector main
const std = @import("std");
const lib = @import("lib");
const logger = @import("logger");
const win = @import("win");
const cli = @import("cli");
const dll = @import("./lib/attacks/dll-injection.zig");
const thread = @import("./lib/attacks/thread.zig");
const hijacking = @import("./lib/attacks/hijacking.zig");

var config = struct {
    pid: ?u32 = null,
    processName: ?[]u8 = null,
    dllPath: []const u8 = "",
}{};

pub fn main() !void {
    var r = try cli.AppRunner.init(std.heap.page_allocator);

    const app = cli.App{
        .version = "1.0.0",
        .author = "akiidjk",
        .command = cli.Command{
            .name = "zinjector",
            .description = cli.Description{
                .one_line = "Windows process injection toolkit (DLL injection, remote thread, thread hijacking)",
                .detailed = "zinjector is a small command-line toolkit for performing common Windows process injection techniques.\n" ++
                    "Use --help on each subcommand to see detailed options and examples.\n" ++
                    "WARNING: These techniques modify other processes and are potentially dangerous or malicious if used improperly. Use only on systems you own or have explicit permission to test.\n",
            },
            .target = cli.CommandTarget{
                .subcommands = try r.allocCommands(
                    &.{
                        cli.Command{
                            .name = "dll",
                            .description = cli.Description{
                                .one_line = "Inject a DLL into a target process",
                                .detailed = "Performs a standard DLL injection by opening the target process, allocating memory for the DLL path,\n" ++
                                    "writing the path, and creating a remote thread that calls LoadLibraryA (or equivalent).\n\n" ++
                                    "Examples:\n" ++
                                    "  zinjector dll -d C:\\\\payload.dll -p 1234\n" ++
                                    "  zinjector dll -d ./payload.dll -n notepad.exe\n",
                            },
                            .options = try r.allocOptions(&.{
                                .{
                                    .long_name = "dll_path",
                                    .short_alias = 'd',
                                    .help = "Path to the DLL to inject (required). Example: C:\\\\tools\\\\payload.dll or .\\payload.dll",
                                    .required = true,
                                    .value_ref = r.mkRef(&config.dllPath),
                                },
                                .{
                                    .long_name = "pid",
                                    .help = "PID of the target process (numeric). Example: 1234",
                                    .required = false,
                                    .short_alias = 'p',
                                    .value_ref = r.mkRef(&config.pid),
                                },
                                .{
                                    .long_name = "process_name",
                                    .help = "Alternative to PID: target process executable name (e.g. Notepad.exe) case sensitive for now.",
                                    .required = false,
                                    .short_alias = 'n',
                                    .value_ref = r.mkRef(&config.processName),
                                },
                            }),
                            .target = cli.CommandTarget{ .action = cli.CommandAction{ .exec = dllInjectionWrapper } },
                        },
                        cli.Command{
                            .name = "thread",
                            .description = cli.Description{
                                .one_line = "Create a remote thread and run an in-memory payload in the target process",
                                .detailed = "Allocates executable memory in the target process, writes a shellcode there,\n" ++
                                    "and creates a remote thread to start execution. Useful for running raw shellcode without a DLL.\n\n" ++
                                    "Payload delivery is implementation-specific (stdin, file, embedded). Ensure the payload is compatible\n" ++
                                    "with the target architecture (x86 vs x64) and calling conventions.\n\n" ++
                                    "Examples:\n" ++
                                    "  zinjector thread -p 4321\n" ++
                                    "  zinjector thread -n explorer.exe\n",
                            },
                            .options = try r.allocOptions(&.{
                                .{
                                    .long_name = "pid",
                                    .help = "PID of the target process (numeric).",
                                    .required = false,
                                    .short_alias = 'p',
                                    .value_ref = r.mkRef(&config.pid),
                                },
                                .{
                                    .long_name = "process_name",
                                    .help = "Alternative to PID: target process executable name (e.g. Notepad.exe) case sensitive for now.",
                                    .required = false,
                                    .short_alias = 'n',
                                    .value_ref = r.mkRef(&config.processName),
                                },
                            }),
                            .target = cli.CommandTarget{ .action = cli.CommandAction{ .exec = createRemoteThreadWrapper } },
                        },
                        cli.Command{
                            .name = "hijacking",
                            .description = cli.Description{
                                .one_line = "Hijack an existing thread in a target process and redirect its execution",
                                .detailed = "Performs thread hijacking by suspending a target thread, changing its instruction pointer\n" ++
                                    "to a payload area (or trampoline), and resuming the thread. This avoids creating new threads and\n" ++
                                    "can be stealthier in some scenarios.\n\n" ++
                                    "Target selection (required):\n" ++
                                    "Notes:\n" ++
                                    "  - Now the attack isn't working, and I don't know why lol" ++
                                    "  - Thread selection may target the main thread or choose a suitable thread automatically.\n" ++
                                    "  - Ensure payload size and memory protection are handled correctly before resuming the thread.\n\n" ++
                                    "Example:\n" ++
                                    "  zinjector hijacking -p 5555\n",
                            },
                            .options = try r.allocOptions(&.{
                                .{
                                    .long_name = "pid",
                                    .help = "PID of the target process whose thread will be hijacked.",
                                    .required = false,
                                    .short_alias = 'p',
                                    .value_ref = r.mkRef(&config.pid),
                                },
                            }),
                            .target = cli.CommandTarget{ .action = cli.CommandAction{ .exec = threadHijakingWrapper } },
                        },
                    },
                ),
            },
        },
    };
    return r.run(&app);
}

fn run() !void {
    logger.info("run --help", .{});
}

fn dllInjectionWrapper() !void {
    try dll.dllInjection(config.pid, config.processName, config.dllPath);
}

fn createRemoteThreadWrapper() !void {
    try thread.createRemoteThreadShellocode(config.pid, config.processName);
}

fn threadHijakingWrapper() !void {
    try hijacking.threadHijacking(config.pid);
}
