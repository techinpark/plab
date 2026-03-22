#!/usr/bin/env bun
/**
 * plabtokens CLI entry point.
 * Requires Bun runtime for OpenTUI's native Zig modules.
 *
 * IMPORTANT: Load OpenTUI preload BEFORE importing CLI.
 */
try {
  await import('@opentui/solid/preload');
} catch {
  // Preload may fail in non-Bun environments or if deps not installed
}
await import('./dist/cli.js');
