# XM Music: RadASM(MASM32) to MASM64

This package preserves original RadASM(MASM32) example and adds a Windows x64 port written for **Microsoft ML64**.

- `original/`: the extracted original project, unchanged.
- `masm64/`: the new application, library source, build script and Easy Code project.

The original `mfmplayer.lib` contains an **x86 COFF object** and cannot be linked into an x64 application. Its include file describes a player based on MiniFMOD 1.60; the archive does not contain that player's source code.

The new `XMPlayer64.lib` is an assembly wrapper around **BASS 2.4 x64**. BASS performs XM decoding, mixing and audio output. This is **not yet an XM decoder written from scratch**. See `XM_ENGINE_ROADMAP.md` for that separate implementation path.

## Build on Windows

Requirements: Visual Studio or Build Tools with the C++ x64 tools and a Windows SDK (`ml64.exe`, `link.exe`, `lib.exe`, `rc.exe`).

Open an **x64 Native Tools Command Prompt**, enter `masm64`, and run:

```bat
build.bat
Release\XM64.exe
```

The script also tries to locate the Visual Studio environment automatically using `vswhere.exe`. For debug symbols, run `build.bat debug` and launch `Debug\XM64.exe`.

Build outputs:

- `Release/XM64.exe` or `Debug/XM64.exe`.
- `bass.dll` beside the executable, copied from the bundled x64 distribution.
- `lib/XMPlayer64.lib`, built from `src/XMPlayer64.asm`.

The application starts playing the embedded `yul.xm` when the dialog opens. It has Play / Restart, Pause, Resume, Stop, About and Close buttons. The old bitmap button was replaced with a text button because the referenced bitmap source was not included in the archive.

## Open in Easy Code

1. Open `masm64/XM64.ecp` in **Easy Code 2** and use the **Masm64** configuration.
2. Under **Project > Properties > Advanced > Build events**, keep **Custom build** enabled. This classic project uses `Custom/CustomBuild.bat`, which calls the supplied build script for both Release and Debug.
3. Build the project. If Easy Code cannot find the tools, first build from the x64 Native Tools Command Prompt as shown above.
4. Run `Release/XM64.exe` or `Debug/XM64.exe`. Keep the matching x64 `bass.dll` in the same directory.

Edit application code in `src/XM64.asm` and the player API in `src/XMPlayer64.asm`. Edit the dialog in `Res/XM64.rc`; it is maintained as a normal resource script, outside Easy Code's resource designer. Custom build keeps the plain ML64 sources independent of Easy Code's generated macros and startup code.

The `.ecp` follows the format of the official Easy Code classic examples. Opening/building it in the Windows IDE has **not** been tested here. The direct `build.bat` route is available independently of the project file.

## Library API

Call all functions from the same thread. This first version supports one player and owns the BASS device it initializes; do not share that device with unrelated BASS code. Except for `XM_GetLastError`, functions return `EAX=1` for success and `EAX=0` for failure.

| Function | Arguments | Purpose |
| --- | --- | --- |
| `XM_Init` | `RCX = HWND`, or zero | Initialize audio |
| `XM_PlayResource` | `RCX = HMODULE`, `EDX = RCDATA ID` | Load and play embedded music |
| `XM_PlayMemory` | `RCX = byte pointer`, `EDX = byte count` | Load and play raw XM data |
| `XM_Pause` | None | Pause playback |
| `XM_Resume` | None | Resume playback |
| `XM_Stop` | None | Stop and free the current module |
| `XM_Shutdown` | None | Release the audio device and its music |
| `XM_GetLastError` | None | Read the last signed error code |

For reuse, link `XMPlayer64.lib`, the bundled **x64** BASS import library, and `kernel32.lib`. Distribute the x64 `bass.dll` with your executable. The example UI additionally links `user32.lib`.

`XM_PlayMemory` expects the XM signature at byte zero. Do **not** prepend the DWORD length used by the old `mfmPlay` API. Playback replaces the current track. The caller's byte buffer must be readable for the supplied size during the call; BASS preloads the module. Looping is enabled by the flags in `XMPlayer64.asm`.

## Errors

Read `XM_GetLastError` immediately after a failed call. Later operations may overwrite it.

| Code | Meaning |
| --- | --- |
| `-100` | BASS API version is not 2.4 |
| `-101` | Null/empty input or invalid integer resource ID |
| `-102` | Audio has not been initialized |
| `-103` | No module is loaded |
| `-110` | RCDATA resource was not found |
| `-111` | Resource size is zero |
| `-112` | `LoadResource` failed |
| `-113` | `LockResource` failed |
| Other nonzero codes | Error returned by BASS |

A missing or wrong-architecture `bass.dll` prevents Windows from loading this application, before these wrapper error codes are available. Use the DLL from `third_party/bass/x64`, not a 32-bit copy.

## Porting details

Handles and pointers use 64-bit storage. BASS music handles remain DWORDs, as specified by its API. Calls use the Windows x64 register convention, shadow space and 16-byte stack alignment. Non-leaf procedures have unwind directives. There is no dependency on MASM32 includes, `INVOKE`, `.IF`, or the old 32-bit player.

The XM is read directly from RCDATA. The extra allocation, length prefix and memory copy from the original are unnecessary with this backend. Closing the dialog releases audio resources before the process exits.

## Validation status

Both assembly sources assembled to AMD64 COFF with **UASM 2.57**, with zero warnings/errors. The library also passed an executable test harness using the Microsoft x64 ABI and simulated BASS/Win32 functions. This checks argument widths, stack arguments, state transitions, resource loading and cleanup/error paths.

## Third-party components

The BASS x64 DLL and import library were taken from the official Windows package at <https://www.un4seen.com/files/bass24.zip>. The original `bass.txt` is included unchanged under `masm64/third_party/bass`. BASS retains its own licensing terms; it is not part of an independently implemented decoder.

The original XM and legacy player are preserved as supplied, with no ownership or license changes.

## References

- [BASS and downloads](https://www.un4seen.com/bass.html)
- [BASS_MusicLoad](https://www.un4seen.com/doc/bass/BASS_MusicLoad.html)
- [Microsoft x64 calling convention](https://learn.microsoft.com/en-us/cpp/build/x64-calling-convention)
- [Easy Code project properties and custom builds](https://www.easycode.cat/English/Help/Project.htm)
