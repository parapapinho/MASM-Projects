;EasyCodeName=XMPlayer64,1
; Plain Microsoft ML64 syntax; no INVOKE/.IF/third-party assembler macros.
; Single player, single calling thread, exclusive ownership of the BASS device.
option casemap:none

EXTERN BASS_GetVersion:PROC
EXTERN BASS_Init:PROC
EXTERN BASS_Free:PROC
EXTERN BASS_ErrorGetCode:PROC
EXTERN BASS_MusicLoad:PROC
EXTERN BASS_MusicFree:PROC
EXTERN BASS_ChannelPlay:PROC
EXTERN BASS_ChannelPause:PROC
EXTERN FindResourceA:PROC
EXTERN SizeofResource:PROC
EXTERN LoadResource:PROC
EXTERN LockResource:PROC

PUBLIC XM_Init, XM_PlayMemory, XM_PlayResource
PUBLIC XM_Pause, XM_Resume, XM_Stop, XM_Shutdown, XM_GetLastError

BASS_VERSION        EQU 0204h
BASS_FILE_MEM       EQU 1
BASS_SAMPLE_LOOP    EQU 4
BASS_MUSIC_RAMP     EQU 0200h
BASS_MUSIC_FT2PAN   EQU 2000h

.data
audioReady DWORD 0
musicHandle DWORD 0             ; HMUSIC is a DWORD, even on x64
lastError SDWORD 0

.code
XM_GetLastError PROC
    mov eax, lastError
    ret
XM_GetLastError ENDP

; Internal helper: capture BASS's error BEFORE any cleanup calls.
CaptureBassError PROC FRAME
    sub rsp, 28h
    .allocstack 28h
    .endprolog
    call BASS_ErrorGetCode
    mov lastError, eax
    xor eax, eax
    add rsp, 28h
    ret
CaptureBassError ENDP

XM_Init PROC FRAME
    sub rsp, 38h
    .allocstack 38h
    .endprolog
    mov QWORD PTR [rsp+28h], rcx
    mov lastError, 0
    cmp audioReady, 0
    jne init_ok
    call BASS_GetVersion
    shr eax, 16
    cmp eax, BASS_VERSION
    jne init_version
    mov ecx, -1
    mov edx, 44100
    xor r8d, r8d
    mov r9, QWORD PTR [rsp+28h]
    mov QWORD PTR [rsp+20h], 0   ; 5th argument: clsid
    call BASS_Init
    test eax, eax
    jz init_bass_error
    mov audioReady, 1
init_ok:
    mov eax, 1
    jmp init_done
init_version:
    mov lastError, -100
    xor eax, eax
    jmp init_done
init_bass_error:
    call CaptureBassError
init_done:
    add rsp, 38h
    ret
XM_Init ENDP

XM_Stop PROC FRAME
    sub rsp, 28h
    .allocstack 28h
    .endprolog
    mov lastError, 0
    mov ecx, musicHandle
    test ecx, ecx
    jz stop_ok
    call BASS_MusicFree
    test eax, eax
    jz stop_error
    mov musicHandle, 0
stop_ok:
    mov eax, 1
    jmp stop_done
stop_error:
    call CaptureBassError
stop_done:
    add rsp, 28h
    ret
XM_Stop ENDP

XM_PlayMemory PROC FRAME
    sub rsp, 48h
    .allocstack 48h
    .endprolog
    mov QWORD PTR [rsp+30h], rcx
    mov DWORD PTR [rsp+38h], edx
    mov lastError, 0
    cmp audioReady, 0
    je play_not_init
    test rcx, rcx
    jz play_bad_input
    test edx, edx
    jz play_bad_input
    call XM_Stop
    test eax, eax
    jz play_done
    mov ecx, BASS_FILE_MEM
    mov rdx, QWORD PTR [rsp+30h]
    xor r8d, r8d               ; offset is a 64-bit QWORD
    mov r9d, DWORD PTR [rsp+38h]
    mov QWORD PTR [rsp+20h], BASS_SAMPLE_LOOP OR BASS_MUSIC_RAMP OR BASS_MUSIC_FT2PAN
    mov QWORD PTR [rsp+28h], 0 ; render at the rate selected by BASS_Init
    call BASS_MusicLoad
    test eax, eax
    jz play_bass_error
    mov musicHandle, eax
    mov ecx, eax
    mov edx, 1
    call BASS_ChannelPlay
    test eax, eax
    jnz play_ok
    call CaptureBassError
    ; Preserve lastError while releasing the newly loaded music.
    mov ecx, musicHandle
    call BASS_MusicFree
    mov musicHandle, 0
    xor eax, eax
    jmp play_done
play_not_init:
    mov lastError, -102
    xor eax, eax
    jmp play_done
play_bad_input:
    mov lastError, -101
    xor eax, eax
    jmp play_done
play_bass_error:
    call CaptureBassError
    jmp play_done
play_ok:
    mov eax, 1
play_done:
    add rsp, 48h
    ret
XM_PlayMemory ENDP

XM_PlayResource PROC FRAME
    sub rsp, 48h
    .allocstack 48h
    .endprolog
    mov QWORD PTR [rsp+20h], rcx
    mov lastError, 0
    test edx, edx
    jz resource_bad_id
    cmp edx, 0FFFFh
    ja resource_bad_id
    mov edx, edx              ; MAKEINTRESOURCE: zero-extended integer ID
    mov r8d, 10               ; RT_RCDATA
    call FindResourceA
    test rax, rax
    jz resource_missing
    mov QWORD PTR [rsp+28h], rax
    mov rcx, QWORD PTR [rsp+20h]
    mov rdx, rax
    call SizeofResource
    test eax, eax
    jz resource_empty
    mov DWORD PTR [rsp+30h], eax
    mov rcx, QWORD PTR [rsp+20h]
    mov rdx, QWORD PTR [rsp+28h]
    call LoadResource
    test rax, rax
    jz resource_load_error
    mov rcx, rax
    call LockResource
    test rax, rax
    jz resource_lock_error
    mov rcx, rax
    mov edx, DWORD PTR [rsp+30h]
    call XM_PlayMemory
    jmp resource_done
resource_bad_id:
    mov lastError, -101
    jmp resource_failure
resource_missing:
    mov lastError, -110
    jmp resource_failure
resource_empty:
    mov lastError, -111
    jmp resource_failure
resource_load_error:
    mov lastError, -112
    jmp resource_failure
resource_lock_error:
    mov lastError, -113
resource_failure:
    xor eax, eax
resource_done:
    add rsp, 48h
    ret
XM_PlayResource ENDP

XM_Pause PROC FRAME
    sub rsp, 28h
    .allocstack 28h
    .endprolog
    mov lastError, 0
    mov ecx, musicHandle
    test ecx, ecx
    jz pause_empty
    call BASS_ChannelPause
    test eax, eax
    jnz pause_done
    call CaptureBassError
    jmp pause_done
pause_empty:
    mov lastError, -103
    xor eax, eax
pause_done:
    add rsp, 28h
    ret
XM_Pause ENDP

XM_Resume PROC FRAME
    sub rsp, 28h
    .allocstack 28h
    .endprolog
    mov lastError, 0
    mov ecx, musicHandle
    test ecx, ecx
    jz resume_empty
    xor edx, edx
    call BASS_ChannelPlay
    test eax, eax
    jnz resume_done
    call CaptureBassError
    jmp resume_done
resume_empty:
    mov lastError, -103
    xor eax, eax
resume_done:
    add rsp, 28h
    ret
XM_Resume ENDP

XM_Shutdown PROC FRAME
    sub rsp, 28h
    .allocstack 28h
    .endprolog
    mov lastError, 0
    cmp audioReady, 0
    je shutdown_ok
    ; BASS_Free stops and releases all channels owned by this device.
    call BASS_Free
    test eax, eax
    jz shutdown_error
    mov musicHandle, 0
    mov audioReady, 0
shutdown_ok:
    mov eax, 1
    jmp shutdown_done
shutdown_error:
    call CaptureBassError
shutdown_done:
    add rsp, 28h
    ret
XM_Shutdown ENDP
END
