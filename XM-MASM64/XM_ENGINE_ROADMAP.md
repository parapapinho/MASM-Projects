# A native MASM64 XM engine

The current `XMPlayer64` source provides the application-facing API. Its decoder and mixer are still BASS. A future independent engine can retain the public API while replacing that backend.

## Start with the actual bundled song

The supplied `yul.xm` is a useful first compatibility target. A structural inspection found:

| Property | Value |
| --- | --- |
| Title | shortone for arachno |
| File size | 21,990 bytes |
| XM version | 1.04 |
| Channels | 4 |
| Order entries / patterns | 14 / 14 |
| Restart order | 2 |
| Instrument / sample entries | 31 / 31 |
| Sample resolution | 8-bit entries |
| Sample loop modes | Forward or no loop |
| Pitch mode | Linear periods |
| Initial speed / BPM | 3 / 125 |
| Enabled volume / panning envelopes | None |

The pattern scan found effect commands `0xy`, `4xy`, `9xx`, `Axy` and `Cxx`: arpeggio, vibrato, sample offset, volume slide and set volume. The volume column also uses direct volume values and `6x` volume slides. Correct effect memory and tick timing matter even for this small song. These observations cover this file, not arbitrary XM compatibility.

## Implementation order

1. **Parser and sample decoder.** Validate each header, count, offset, packed event and sample span against the supplied byte count. Decode patterns and delta-encoded samples. Start with this song's 8-bit samples and forward loops; explicitly reject unsupported features.
2. **Offline renderer.** Implement note-to-frequency calculation, per-channel sample position, mixing, volume/panning and a frame-based tick scheduler. Render to PCM/WAV first so timing and output can be compared without an audio callback.
3. **Tracker effects.** Implement the commands present in this song, their parameter memory and tick-zero versus later-tick behavior. Compare complete song output and restart behavior with a reference player, allowing for interpolation differences.
4. **Windows output.** Feed the PCM renderer through a buffered output backend, initially `waveOut`. Implement clean stop/reset, worker synchronization and buffer lifetime before replacing BASS in the UI.
5. **Broader XM support.** Add 16-bit samples, ping-pong loops, envelopes, fadeout, instrument vibrato, Amiga periods and the remaining effects. Use several small test modules for each feature before advertising general XM support.

Suggested source split: `xm_parse.asm`, `xm_samples.asm`, `xm_sequence.asm`, `xm_effects.asm`, `xm_mix.asm` and `xm_waveout.asm`. Keep audio output separate from decoding so the renderer can be tested offline.

Writing only `XM_Play` around an existing DLL creates a wrapper. Removing BASS requires implementing and validating the parser, tracker sequencer, sample mixer and output backend above. That independent engine is proposed work; it is not included as a completed decoder in this package.

References:

- [MilkyTracker effect command reference](https://milkytracker.org/docs/manual/MilkyTracker.html)
- [Microsoft waveOutWrite](https://learn.microsoft.com/en-us/windows/win32/api/mmeapi/nf-mmeapi-waveoutwrite)
- [libxm source, for reference and comparison](https://github.com/Artefact2/libxm)
