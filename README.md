# audio-test-harness
A utility to make testing audio code easier.

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
