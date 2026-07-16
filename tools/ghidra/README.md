# Ghidra and Malimite Notes

Local discovery on 2026-07-16 found:

- Ghidra: `/Applications/Ghidra/ghidra_12.1.2_PUBLIC`
- Headless analyzer:
  `/Applications/Ghidra/ghidra_12.1.2_PUBLIC/support/analyzeHeadless`
- Malimite: `/Applications/Malimite/Malimite-1-2/malimite`
- Malimite configuration:
  `/Applications/Malimite/Malimite-1-2/malimite.properties`

`malimite` is not currently on `PATH`; run it by absolute path if launching
Malimite directly.

The current Malimite config was installed with a stale Ghidra path:

```properties
ghidra.path=/Users/laurie/Downloads/ghidra_11.4.1_PUBLIC
```

For this machine, point it at:

```properties
ghidra.path=/Applications/Ghidra/ghidra_12.1.2_PUBLIC
```

The Malimite launcher is a shell script that changes into its own install
directory and runs:

```zsh
java -jar /Applications/Malimite/Malimite-1-2/Malimite-1-2.jar
```

It does not pass a Ghidra path on the command line, so the persistent
configuration file appears to be the relevant setup surface.

For non-GUI Ghidra scripting, use `analyzeHeadless` with this repository's
Ghidra scripts. Example shape:

```zsh
/Applications/Ghidra/ghidra_12.1.2_PUBLIC/support/analyzeHeadless \
  /tmp/wallpaper-ghidra-project WallpaperAgent \
  -import /System/Library/CoreServices/WallpaperAgent.app/Contents/MacOS/WallpaperAgent \
  -postScript DumpWallpaperDebugReferences.java \
  -scriptPath tools/ghidra \
  -readOnly
```

Use a disposable project directory for imports and preserve generated reports
under `research/WallpaperAgent/` when the output becomes evidence.
