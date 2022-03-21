org 10000h

    mov ax,cs
    mov ds,ax
    mov es,ax
    mov ax,0x00
    mov ss,ax
    mov sp,0x7c00

;;; display on screen 
    mov ax,1301h
    mov bx,000ah
    mov dx,0200h;row 2
    mov cx,0fh
    push ax
    mov ax,ds
    mov es,ax
    pop ax
    mov bp,start_loader_message


;;; display message
    start_loader_message: db "start loader..."