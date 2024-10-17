const Audio = @import("audio");
const Wav = @import("../render/Wav.zig");

pub const SampleFormat = enum {
    u8,
    i8,
    i16,
    i24,
    i32,
    f32,
};

pub const Harness = struct {
    sample_rate: f32 = 44100,
    channels: u8 = 1,
    sample_format: SampleFormat = SampleFormat.i16,
    seconds: f32 = 1.0,
};

pub fn Render(comptime T: type) type {
    return struct {
        file_name: ?[:0]const u8 = undefined,
        input: ?[]const T = undefined,
        buffer_size: ?u32 = undefined,
    };
}

pub fn sampleFormatToType(sample_format: SampleFormat) type {
    return switch (sample_format) {
        SampleFormat.u8 => u8,
        SampleFormat.i8 => i8,
        SampleFormat.i16 => i16,
        SampleFormat.i24 => i24,
        SampleFormat.i32 => i32,
        SampleFormat.f32 => f32,
    };
}
