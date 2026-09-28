; Public API, Microsoft x64 calling convention. All calls on one UI thread.
; Functions return EAX=1 on success, 0 on failure, except GetLastError.
; This library wraps BASS 2.4 x64. It is NOT an independent XM decoder.
EXTERN XM_Init:PROC             ; RCX = owner HWND (or NULL)
EXTERN XM_PlayMemory:PROC       ; RCX = raw XM bytes, EDX = byte count
EXTERN XM_PlayResource:PROC     ; RCX = HMODULE, EDX = integer RCDATA ID
EXTERN XM_Pause:PROC
EXTERN XM_Resume:PROC
EXTERN XM_Stop:PROC             ; stops playback and frees the current module
EXTERN XM_Shutdown:PROC         ; frees the audio device owned by this wrapper
EXTERN XM_GetLastError:PROC     ; EAX = signed error code
