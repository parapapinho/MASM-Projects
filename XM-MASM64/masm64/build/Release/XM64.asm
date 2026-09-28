;EasyCodeName=XM64,1
; Original example by Everdoh, ported to the Windows x64 ABI.
option casemap:none
include XMPlayer64.inc

EXTERN GetModuleHandleA:PROC
EXTERN DialogBoxParamA:PROC
EXTERN EndDialog:PROC
EXTERN MessageBoxA:PROC
EXTERN SetDlgItemTextA:PROC
EXTERN wsprintfA:PROC
EXTERN ExitProcess:PROC
PUBLIC start

WM_INITDIALOG EQU 0110h
WM_COMMAND EQU 0111h
WM_CLOSE EQU 0010h
IDD_MAIN EQU 101
IDR_MUSIC EQU 400
IDC_STATUS EQU 1000
IDC_PLAY EQU 1001
IDC_PAUSE EQU 1002
IDC_RESUME EQU 1003
IDC_STOP EQU 1004
IDC_ABOUT EQU 1005
IDCANCEL EQU 2

.data
hInstance QWORD 0
errorTitle BYTE 'XM Music - error',0
errorFormat BYTE 'Audio operation failed. Error code: %d',13,10,
    'See README.md for the error codes.',0
dialogError BYTE 'The dialog could not be created. Check the compiled resources.',0
aboutTitle BYTE 'About',0
aboutText BYTE 'Original MASM example by Everdoh.',13,10,
    'RadASM original preserved alongside this MASM64 port.',13,10,
    'XMPlayer64 uses BASS 2.4 x64 for XM playback.',0
playingText BYTE 'Playing - embedded yul.xm (loop enabled)',0
pausedText BYTE 'Paused',0
stoppedText BYTE 'Stopped - click Play / Restart',0
.data?
errorBuffer BYTE 256 DUP (?)

.code
ShowAudioError PROC FRAME
    sub rsp, 38h
    .allocstack 38h
    .endprolog
    mov QWORD PTR [rsp+20h], rcx
    call XM_GetLastError
    mov r8d, eax
    lea rcx, errorBuffer
    lea rdx, errorFormat
    call wsprintfA
    mov rcx, QWORD PTR [rsp+20h]
    lea rdx, errorBuffer
    lea r8, errorTitle
    mov r9d, 10h
    call MessageBoxA
    add rsp, 38h
    ret
ShowAudioError ENDP

DlgProc PROC FRAME
    sub rsp, 38h
    .allocstack 38h
    .endprolog
    mov QWORD PTR [rsp+20h], rcx ; HWND must survive API calls
    cmp edx, WM_INITDIALOG
    je dlg_init
    cmp edx, WM_COMMAND
    je dlg_command
    cmp edx, WM_CLOSE
    je dlg_close
    jmp dlg_unhandled
dlg_init:
    call XM_Init
    test eax, eax
    jz dlg_init_failed
    mov rcx, hInstance
    mov edx, IDR_MUSIC
    call XM_PlayResource
    test eax, eax
    jz dlg_init_failed
    lea r8, playingText
    jmp dlg_status
dlg_command:
    mov eax, r8d
    shr eax, 16
    test eax, eax             ; BN_CLICKED only
    jnz dlg_unhandled
    and r8d, 0FFFFh
    cmp r8d, IDCANCEL
    je dlg_close
    cmp r8d, IDC_PLAY
    je dlg_play
    cmp r8d, IDC_PAUSE
    je dlg_pause
    cmp r8d, IDC_RESUME
    je dlg_resume
    cmp r8d, IDC_STOP
    je dlg_stop
    cmp r8d, IDC_ABOUT
    je dlg_about
    jmp dlg_unhandled
dlg_play:
    mov rcx, hInstance
    mov edx, IDR_MUSIC
    call XM_PlayResource
    test eax, eax
    jz dlg_action_failed
    lea r8, playingText
    jmp dlg_status
dlg_pause:
    call XM_Pause
    test eax, eax
    jz dlg_action_failed
    lea r8, pausedText
    jmp dlg_status
dlg_resume:
    call XM_Resume
    test eax, eax
    jz dlg_action_failed
    lea r8, playingText
    jmp dlg_status
dlg_stop:
    call XM_Stop
    test eax, eax
    jz dlg_action_failed
    lea r8, stoppedText
    jmp dlg_status
dlg_status:
    mov rcx, QWORD PTR [rsp+20h]
    mov edx, IDC_STATUS
    call SetDlgItemTextA
    jmp dlg_handled
dlg_about:
    mov rcx, QWORD PTR [rsp+20h]
    lea rdx, aboutText
    lea r8, aboutTitle
    mov r9d, 40h
    call MessageBoxA
    jmp dlg_handled
dlg_action_failed:
    mov rcx, QWORD PTR [rsp+20h]
    call ShowAudioError
    jmp dlg_handled
dlg_init_failed:
    mov rcx, QWORD PTR [rsp+20h]
    call ShowAudioError
    mov rcx, QWORD PTR [rsp+20h]
    mov edx, 1
    call EndDialog
    jmp dlg_handled
dlg_close:
    mov rcx, QWORD PTR [rsp+20h]
    xor edx, edx
    call EndDialog
dlg_handled:
    mov eax, 1
    jmp dlg_done
dlg_unhandled:
    xor eax, eax
dlg_done:
    add rsp, 38h
    ret
DlgProc ENDP

start PROC FRAME
    sub rsp, 38h
    .allocstack 38h
    .endprolog
    xor ecx, ecx
    call GetModuleHandleA
    mov hInstance, rax
    mov rcx, rax
    mov edx, IDD_MAIN
    xor r8d, r8d
    lea r9, DlgProc
    mov QWORD PTR [rsp+20h], 0
    call DialogBoxParamA
    mov DWORD PTR [rsp+28h], eax
    cmp rax, -1
    jne start_cleanup
    xor ecx, ecx
    lea rdx, dialogError
    lea r8, errorTitle
    mov r9d, 10h
    call MessageBoxA
    mov DWORD PTR [rsp+28h], 1
start_cleanup:
    call XM_Shutdown
    test eax, eax
    jnz start_exit
    xor ecx, ecx
    call ShowAudioError
    mov DWORD PTR [rsp+28h], 1
start_exit:
    mov ecx, DWORD PTR [rsp+28h]
    call ExitProcess
    add rsp, 38h
    ret
start ENDP
END
