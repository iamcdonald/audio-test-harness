const std = @import("std");
const Audio = @import("audio");
const Options = @import("../Options.zig");
const Renderer = @import("Renderer.zig").Renderer;

fn sampleFormatToAudio(sample_format: Options.SampleFormat) Audio.SampleFormat {
    return switch (sample_format) {
        Options.SampleFormat.u8 => Audio.SampleFormat.u8,
        Options.SampleFormat.i8 => Audio.SampleFormat.i8,
        Options.SampleFormat.i16 => Audio.SampleFormat.i16,
        Options.SampleFormat.i24 => Audio.SampleFormat.i24,
        Options.SampleFormat.i32 => Audio.SampleFormat.i32,
        Options.SampleFormat.f32 => Audio.SampleFormat.f32,
    };
}

pub fn StreamRenderer(comptime harness_opts: Options.Harness) type {
    const T = Options.sampleFormatToType(harness_opts.sample_format);
    const RenderFnType = *const fn (input: []const T, output: []T) void;
    const sr = struct {
        const _opts = harness_opts;
        pub fn render(opts: Options.Harness, render_opts: Options.Render(T), render_fn: RenderFnType) !void {
            const RenderWrapper = struct {
                var wrapper_input: ?[]const T = undefined;
                var render_wrapper_cb: RenderFnType = undefined;
                pub fn render(_: []const T, output: []T) void {
                    render_wrapper_cb(wrapper_input orelse &[0]T{}, output);
                }
            };
            RenderWrapper.wrapper_input = render_opts.input;
            RenderWrapper.render_wrapper_cb = render_fn;

            //REAL-TIME OUTPUT
            const audio = try Audio.Audio.init(std.testing.allocator);
            defer audio.terminate();

            const device = try audio.getDefaultDevice();
            const stream_opts: Audio.StreamOptions = .{
                .device = device,
                .sample_rate = opts.sample_rate,
                .channels = opts.channels,
                .bit_depth = sampleFormatToAudio(opts.sample_format),
            };
            const stream = try audio.createStream(sampleFormatToAudio(_opts.sample_format), stream_opts);
            defer stream.close();
            try stream.start(RenderWrapper.render);
            audio.sleep(1000);
            try stream.stop();
        }
    };
    return Renderer(harness_opts).build(&sr.render);
}
