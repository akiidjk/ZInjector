//! The effective injector main
const std = @import("std");
const lib = @import("lib");
const logger = @import("logger");
const win = @import("win");
const cli = @import("cli");
const dll = @import("dll-injection");
const thread = @import("thread-hijacking");
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
            .description = cli.Description{ .one_line = "main commnad" },
            .target = cli.CommandTarget{
                .subcommands = try r.allocCommands(
                    &.{
                        cli.Command{
                            .name = "dll",
                            .description = cli.Description{ .one_line = "execute a DLL Injection" },
                            .options = try r.allocOptions(&.{
                                .{
                                    .long_name = "dll_path",
                                    .short_alias = 'd',
                                    .help = "Path to DLL",
                                    .required = true,
                                    .value_ref = r.mkRef(&config.dllPath),
                                },
                                .{
                                    .long_name = "pid",
                                    .help = "Pid of the process",
                                    .required = false,
                                    .short_alias = 'p',
                                    .value_ref = r.mkRef(&config.pid),
                                },
                                .{
                                    .long_name = "process_name",
                                    .help = "Alternative to the process PID the name process (.exe)",
                                    .required = false,
                                    .short_alias = 'n',
                                    .value_ref = r.mkRef(&config.processName),
                                },
                            }),
                            .target = cli.CommandTarget{ .action = cli.CommandAction{ .exec = dllInjectionWrapper } },
                        },
                        cli.Command{
                            .name = "thread",
                            .description = cli.Description{ .one_line = "execute a Thread Hijacking attack" },
                            .options = try r.allocOptions(&.{
                                .{
                                    .long_name = "pid",
                                    .help = "Pid of the process",
                                    .required = true,
                                    .short_alias = 'p',
                                    .value_ref = r.mkRef(&config.pid),
                                },
                                // .{
                                //     .long_name = "process_name",
                                //     .help = "Alternative to the process PID the name process (.exe)",
                                //     .required = false,
                                //     .short_alias = 'n',
                                //     .value_ref = r.mkRef(&config.processName),
                                // },
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

fn threadHijakingWrapper() !void {
    try thread.threadHijacking(config.pid);
}
