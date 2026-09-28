.386
.model flat, stdcall  ;32 bit memory model
option casemap :none  ;case sensitive

include XM.inc

.code

start:

	invoke GetModuleHandle,NULL
	mov		hInstance,eax

    invoke InitCommonControls
push esi
INVOKE FindResource, hInstance, 400, RT_RCDATA ;400 es el ID del XM 
push eax
INVOKE SizeofResource, hInstance, eax
mov nMusicSize, eax
pop eax
INVOKE LoadResource, hInstance, eax
INVOKE LockResource, eax
mov esi, eax
mov eax, nMusicSize
add eax, SIZEOF nMusicSize
INVOKE GlobalAlloc, GPTR, eax
mov pMusic, eax
mov ecx, nMusicSize
mov dword ptr [eax], ecx
add eax, SIZEOF nMusicSize
mov edi, eax
rep movsb
pop esi
    
    
    
    
 
	invoke DialogBoxParam,hInstance,IDD_DIALOG1,NULL,addr DlgProc,NULL
	invoke GlobalFree, pMusic
	
	
	
	invoke ExitProcess,0

;########################################################################

DlgProc proc hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM

	mov		eax,uMsg
	.if eax==WM_INITDIALOG
	invoke LoadBitmap,hInstance,101
    invoke SendDlgItemMessage,hWin,1001,BM_SETIMAGE,IMAGE_BITMAP,eax
    invoke mfmPlay, pMusic
	.elseif eax==WM_COMMAND
	mov eax,wParam
	invoke MessageBox,hWin,offset msg,offset txt,MB_ICONINFORMATION

	.elseif eax==WM_CLOSE
		invoke EndDialog,hWin,0
	.else
		mov		eax,FALSE
		ret
	.endif
	mov		eax,TRUE
	ret

DlgProc endp

end start
