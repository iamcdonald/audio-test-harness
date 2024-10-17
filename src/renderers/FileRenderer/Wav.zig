const std = @import("std");

pub const WavFormat = enum(u16) { PCM = 0x0001, FLOAT = 0x0003 };

const PackWriter = struct {
    const Self = @This();

    _type: type,
    pub fn init(T: type) Self {
        return .{ ._type = T };
    }

    pub fn write(self: Self, writer: std.io.AnyWriter, comptime V: type, value: V) !void {
        const valueBitSize = @bitSizeOf(V);
        const tBitSize = @bitSizeOf(self._type);
        const size = comptime try std.math.divCeil(u16, valueBitSize, tBitSize);
        var x = std.mem.zeroes([size]self._type);
        std.mem.writePackedInt(V, &x, 0, value, std.builtin.Endian.little);
        try writer.writeAll(&x);
    }

    pub fn writeAll(self: Self, writer: std.io.AnyWriter, comptime V: type, values: []const V) !void {
        for (values) |value| {
            try self.write(writer, V, value);
        }
    }
};

const pwu8 = PackWriter.init(u8);

const WavMetaData = struct { sample_rate: u32, channels: u16, bit_depth: u16, format: WavFormat };

pub const Wav = struct {
    const Self = @This();

    _meta_data: WavMetaData,

    pub fn init(meta: WavMetaData) Self {
        return .{ ._meta_data = meta };
    }

    fn _writeHeader(self: Self, writer: std.io.AnyWriter, samples: u32) !void {
        try writer.writeAll("RIFF");
        // File Size
        // 36(header length) + samples * 2
        try pwu8.write(writer, u32, @truncate(36 + (samples * 2))); // file size

        try writer.writeAll("WAVE");

        try writer.writeAll("fmt ");
        try pwu8.write(writer, u32, 16); // length of format data
        try pwu8.write(writer, u16, @intFromEnum(self._meta_data.format)); // type of format
        try pwu8.write(writer, u16, self._meta_data.channels); // channels
        try pwu8.write(writer, u32, self._meta_data.sample_rate); //sample rate

        // (Sample Rate * BitsPerSample * Channels) / 8
        const sbc = (self._meta_data.sample_rate * self._meta_data.bit_depth * self._meta_data.channels) / 8;
        try pwu8.write(writer, u32, @truncate(sbc));

        // (BitsPerSample * Channels) / 8.1 - 8 bit mono2 - 8 bit stereo/16 bit mono4 - 16 bit stereo
        const bc = (self._meta_data.bit_depth * self._meta_data.channels) / 8;
        try pwu8.write(writer, u16, @truncate(bc));

        try pwu8.write(writer, u16, self._meta_data.bit_depth); // Bits per sample

        try writer.writeAll("data");
        try pwu8.write(writer, u32, samples * 2); // file size
    }

    pub fn write(self: Self, writer: std.io.AnyWriter, samples: []const i16) !void {
        try self._writeHeader(writer, @truncate(samples.len));
        try pwu8.writeAll(writer, i16, samples);
    }
};
