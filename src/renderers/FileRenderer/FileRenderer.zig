const std = @import("std");
const Renderer = @import("../Renderer.zig").Renderer;
const Options = @import("../../Options.zig");
const Wav = @import("Wav.zig");

fn sampleFormatToBitDepth(sample_format: Options.SampleFormat) !struct { u16, Wav.WavFormat } {
    return switch (sample_format) {
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

    const bit_depth, const format = try sampleFormatToBitDepth(harness_opts.sample_format);
    const wav = Wav.Wav(.{
        .sample_rate = @intFromFloat(harness_opts.sample_rate),
        .channels = harness_opts.channels,
        .bit_depth = bit_depth,
        .format = format,
    }){};
    const fr = struct {
        pub fn render(opts: Options.Harness, render_opts: Options.Render(T), render_fn: RenderFnType) !void {
            if (render_opts.file_name) |file_name| {
                const output = try std.testing.allocator.alloc(T, @as(u32, @intFromFloat(opts.sample_rate * opts.seconds)) * opts.channels);
                defer std.testing.allocator.free(output);

                const total_samples = (opts.sample_rate * opts.seconds);
                const buffer_size = render_opts.buffer_size orelse output.len;
                const iterations: usize = @intFromFloat(@ceil(total_samples / @as(f32, @floatFromInt(buffer_size))));

                for (0..iterations) |i| {
                    const input = &[0]T{};
                    const slice_start = (i * buffer_size * opts.channels);
                    const slice_end = @min(output.len, ((i + 1) * buffer_size * opts.channels));
                    const outs = output[slice_start..slice_end];
                    if (render_opts.input) |in| {
                        const ins = in[slice_start..slice_end];
                        render_fn(ins, outs);
                    } else {
                        render_fn(input, outs);
                    }
                }

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

test "FileRenderer - different sample format" {
    const TestSynthesis = struct {
        var phase: f32 = 0;
        pub fn render(_: []const i32, output: []i32) void {
            for (0..output.len) |i| {
                phase += 0.025;
                if (phase > 1) {
                    phase -= 1;
                }
                const amp: f32 = @as(f32, @floatFromInt(std.math.maxInt(i32))) / 4.0;
                const x: i32 = @intFromFloat(@sin(phase * 360.0 * std.math.pi / 180.0) * amp);
                output[i] = x;
            }
        }
    };

    try FileRenderer(.{ .sample_format = Options.SampleFormat.i32 }).build(&TestSynthesis.render).render(.{
        .file_name = "./test-output/test_i32.wav",
    });
}
