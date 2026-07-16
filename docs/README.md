# Documentation

This directory holds durable writeups promoted from raw research.

Use `docs/frameworks/<Name>/` for framework, daemon, service, and subsystem writeups. Keep raw dumps, generated headers, command transcripts, and scratch notes under `research/<Name>/` until they are cleaned up enough to be useful later.

Each target writeup should include:

- scope
- environment
- evidence inventory
- types and symbols
- interesting functions and signatures
- hooks, notifications, callbacks, XPC, and daemon edges
- permissions, entitlements, sandbox, and SIP notes
- experiments
- open questions
- references

Current writeups:

- [`MediaRemote`](frameworks/MediaRemote/README.md)
- [`WallpaperAgent`](frameworks/WallpaperAgent/README.md)
