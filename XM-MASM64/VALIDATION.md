# Validation

## Completed

- Read all source/include/resource/project files needed for the legacy playback path.
- Identified machine `0x014C` (x86) in `mfmplayer.obj` inside the legacy static library.
- Checked the new BASS DLL/import library come from the official x64 package.
- Assembled both new sources into AMD64 COFF objects with UASM 2.57: no warnings or errors. Checked the generated library instructions for explicit stack allocation and x64 argument passing.
- Assembled the same player source into ELF64 for a Linux test harness. Calls into and out of the player use GCC's Microsoft x64 ABI attribute.
- Executed the harness covering: wrong BASS version, failed initialization, repeated initialization, null/zero-size input, absent playback, invalid IDs, all four resource failures, failed module loading, pause/resume, failed pause, failed old-module cleanup, replacement playback, repeated stop, playback-start failure, preservation of the original failure code across cleanup, failed device cleanup and reinitialization.
- Checked all patterns and sample spans in `yul.xm` against the file size. Extracted its feature inventory for the independent-engine plan.

The test harness stubs BASS and Win32 calls; it validates the wrapper and ABI, not actual decoding or Windows audio. The public API is deliberately single-threaded and single-player.

## Pending on Windows

1. Run `masm64/build.bat` with Microsoft ML64, LIB, LINK and RC.
2. Open `XM64.ecp` in Easy Code 2 and confirm custom build and Run work with the local Masm64 configuration.
3. Launch the program and listen to the embedded track through its restart point.
4. Exercise Pause, Resume, Stop, Play / Restart and Close, including repeated use.
5. Confirm the program also closes correctly with Escape and the title-bar close button.

The Easy Code project format was derived from the official classic-project example and uses the documented custom-build mechanism. The IDE was not available for an interactive check.
