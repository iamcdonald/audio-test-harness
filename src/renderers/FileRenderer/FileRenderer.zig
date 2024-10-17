const std = @import("std");
const Renderer = @import("../Renderer.zig").Renderer;
const Options = @import("../../Options.zig");
const Wav = @import("./Wav.zig");

fn sampleFormatToBitDepth(sample_format: Options.SampleFormat) !struct { u16, Wav.WavFormat } {
    return switch (sample_format) {
        Options.SampleFormat.i8 => .{ 8, Wav.WavFormat.PCM },
        Options.SampleFormat.i16 => .{ 16, Wav.WavFormat.PCM },
        Options.SampleFormat.i24 => .{ 24, Wav.WavFormat.PCM },
        Options.SampleFormat.i32 => .{ 32, Wav.WavFormat.PCM },
        Options.SampleFormat.f32 => .{ 32, Wav.WavFormat.FLOAT },
        else => error.NotSupported,
    };
}

pub fn FileRenderer(comptime harness_opts: Options.Harness) type {
    const T = Options.sampleFormatToType(harness_opts.sample_format);
    const RenderFnType = *const fn (input: []const T, output: []T) void;
    const fr = struct {
        pub fn render(opts: Options.Harness, render_opts: Options.Render(T), render_fn: RenderFnType) !void {
            if (render_opts.file_name) |file_name| {
                //WRITE FILE
                const bit_depth, const format = try sampleFormatToBitDepth(opts.sample_format);
                const wav = Wav.Wav.init(.{
                    .sample_rate = @intFromFloat(opts.sample_rate),
                    .channels = opts.channels,
                    .bit_depth = bit_depth,
                    .format = format,
                });
                const output = try std.testing.allocator.alloc(T, @as(u32, @intFromFloat(opts.sample_rate)) * opts.seconds * opts.channels);
                defer std.testing.allocator.free(output);

                render_fn(render_opts.input orelse &[0]T{}, output);

                const file = try std.fs.cwd().createFile(file_name, .{});
                defer file.close();
                try wav.write(file.writer().any(), output);
            } else {
                return error.NoFileName;
            }
        }
    };
    return Renderer(harness_opts).build(&fr.render);
}
