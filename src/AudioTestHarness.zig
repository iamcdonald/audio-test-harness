const std = @import("std");
const Renderers = @import("./renderers/root.zig");
const Options = @import("./Options.zig");

pub const SampleFormat = Options.SampleFormat;

pub fn AudioTestHarness(comptime harness_opts: Options.Harness) type {
    const T = Options.sampleFormatToType(harness_opts.sample_format);
    const RenderFnType = *const fn (input: []const T, output: []T) void;

    return struct {
        const Self = @This();
        const opts = harness_opts;
        _render_fn: RenderFnType,
        pub fn build(render_fn: RenderFnType) Self {
            return .{ ._render_fn = render_fn };
        }
        pub fn render(self: *const Self, render_opts: Options.Render(T)) anyerror!void {
            if (render_opts.file_name) |_| {
                return Renderers.File(opts).build(self._render_fn).render(render_opts);
            }
            return Renderers.Stream(opts).build(self._render_fn).render(render_opts);
        }
    };
}

const TestSynthesis = struct {
    var phase: f32 = 0;
    pub fn render(_: []const i16, output: []i16) void {
        for (0..output.len) |i| {
            phase += 0.025;
            if (phase > 1) {
                phase -= 1;
            }
            const x: i16 = @intFromFloat(@sin(phase * 360.0 * std.math.pi / 180.0) * 3000);
            output[i] = x;
        }
    }
};

test "AudioTestHarness - file" {
    try AudioTestHarness(.{}).build(&TestSynthesis.render).render(.{
        .file_name = "test.wav",
    });
}

test "AudioTestHarness - stream" {
    try AudioTestHarness(.{}).build(TestSynthesis.render).render(.{});
}
