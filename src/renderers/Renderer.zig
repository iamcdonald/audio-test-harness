const Options = @import("../Options.zig");

pub fn Renderer(comptime harness_opts: Options.Harness) type {
    const T = Options.sampleFormatToType(harness_opts.sample_format);
    const RenderFnType = *const fn (input: []const T, output: []T) void;
    const RendererFnType = *const fn (harness_opts: Options.Harness, render_opts: Options.Render(T), render_fn: RenderFnType) anyerror!void;
    return struct {
        pub fn build(renderer: RendererFnType) type {
            return struct {
                const Self = @This();
                const _opts = harness_opts;
                const _renderer = renderer;
                _render_fn: RenderFnType,
                pub fn build(render_fn: RenderFnType) Self {
                    return .{ ._render_fn = render_fn };
                }
                pub fn render(self: *const Self, render_opts: Options.Render(T)) anyerror!void {
                    return _renderer(_opts, render_opts, self._render_fn);
                }
            };
        }
    };
}
