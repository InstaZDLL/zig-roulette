const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "zig-roulette",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });

    exe.root_module.link_libc = true;
    exe.root_module.linkSystemLibrary("gtk4", .{ .use_pkg_config = .yes });
    exe.root_module.linkSystemLibrary("libadwaita-1", .{ .use_pkg_config = .yes });

    b.installArtifact(exe);
    b.installFile("assets/logo.svg", "share/icons/hicolor/scalable/apps/dev.instazdll.ZigRoulette.svg");
    b.installFile("assets/icons/logo-16.png", "share/icons/hicolor/16x16/apps/dev.instazdll.ZigRoulette.png");
    b.installFile("assets/icons/logo-32.png", "share/icons/hicolor/32x32/apps/dev.instazdll.ZigRoulette.png");
    b.installFile("assets/icons/logo-48.png", "share/icons/hicolor/48x48/apps/dev.instazdll.ZigRoulette.png");
    b.installFile("assets/icons/logo-64.png", "share/icons/hicolor/64x64/apps/dev.instazdll.ZigRoulette.png");
    b.installFile("assets/icons/logo-128.png", "share/icons/hicolor/128x128/apps/dev.instazdll.ZigRoulette.png");
    b.installFile("assets/icons/logo-256.png", "share/icons/hicolor/256x256/apps/dev.instazdll.ZigRoulette.png");
    b.installFile("assets/icons/logo-512.png", "share/icons/hicolor/512x512/apps/dev.instazdll.ZigRoulette.png");
    b.installFile("data/dev.instazdll.ZigRoulette.desktop", "share/applications/dev.instazdll.ZigRoulette.desktop");
    b.installFile("data/dev.instazdll.ZigRoulette.metainfo.xml", "share/metainfo/dev.instazdll.ZigRoulette.metainfo.xml");

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    run_cmd.setEnvironmentVariable("GTK_THEME", "Adwaita");
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the roulette app");
    run_step.dependOn(&run_cmd.step);

    const game_tests = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/game.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });
    const run_game_tests = b.addRunArtifact(game_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_game_tests.step);
}
