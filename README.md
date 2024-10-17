# audio-test-harness
A utility to make testing audio code easier.

## Install
```
zig fetch git+https://github.com/iamcdonald/audio-test-harness.git
```

## Setup
```
...
const ath = b.dependency("audio-test-harness", .{
    .optimize = optimize,
    .target = target,
});
...
lib_or_exe.root_module.addImport("audio-test-harness", ath.module("audio-test-harness"));

```

## Usage
```
const AudioTestHarness = @import("audio-test-harness").AudioTestHarness;

test "listen to output" {
  try AudioTestHarness(.{}).build({render_function}).render(.{})
}

test "write to wav" {
  try AudioTestHarness(.{}).build({render_function}).render(.{ .file_name: "test.wav" })
}

```
