.386
.model flat, stdcall  ;32 bit memory model
option casemap :none  ;case sensitive

include XM.inc

.code

start:

	invoke GetModuleHandle,NULL
	mov		hInstance,eax

    invoke InitCommonControls
	invoke DialogBoxParam,hInstance,IDD_DIALOG1,NULL,addr DlgProc,NULL
	invoke ExitProcess,0

;########################################################################

DlgProc proc hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM

	mov		eax,uMsg
	.if eax==WM_INITDIALOG
	invoke LoadBitmap,hInstance,101
    invoke SendDlgItemMessage,hWin,1001,BM_SETIMAGE,IMAGE_BITMAP,eax

	.elseif eax==WM_COMMAND

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
