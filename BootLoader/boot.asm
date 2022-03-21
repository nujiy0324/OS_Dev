org 0x7c00


;;; define
stack_base equ 0x7c00
loader_base equ 0x1000
loader_offset equ 0x00
; PA = loader_base << 4 + loader_offset 

root_dir_sectors equ 14
sector_num_of_root_dir_start equ 19
sector_num_of_FAT12_start equ 1
sector_balance equ 17

;;; tmp var
root_dir_size_for_loop dw root_dir_sectors
sector_No dw 0
odd db 0


;	jmp short _start
	jmp _start
	nop
;;; initialize FAT12 
	BS_OEMName			db 'my_boot'
	BPB_BytesPerSec 	dw 512
	BPB_SecPerClus 		db 1
	BPB_RsvdSecCnt 		dw 1
	BPB_NumFATs 		db 2
	BPB_RootEntCnt 		dw 224
	BPB_TotSec16 		dw 2280
	BPB_Media 			db 0xf0
	BPB_FATSz16 		dw 9
	BPB_SecPerTrk 		dw 18
	BPB_NumHeads 		dw 2
	BPB_HiddSec 		dd 0
	BPB_TotSec32 		dd 0
	BS_DrvNum 			db 0
	BS_Reserved1 		db 0
	BS_BootSig 			db 29h
	BS_VolID 			db 0
	BS_VolLab 			db 'boot loader'
	BS_FilSysType 		db 'FAT12   '

;;; read one sector from floppy
; pramaters: 
; ax = start sector number
; cl = numbers of sectors to read
; es:bx = target buffer start address
func_read_one_sector:
	push bp
	mov bp, sp
	sub esp,2
	mov byte[bp-2],cl
	push bx
	mov bl,[BPB_SecPerTrk]
	div bl
	inc ah
	mov cl,ah
	mov dh,al
	shr al,1
	mov ch,al
	and dh,1
	pop bx
	mov dl,[BS_DrvNum]
reading_loop:
	mov ah,02h
	mov al,byte[bp-2]
	int 13h
	jc reading_loop
	add esp,02h
	pop bp
	ret

;;; search loader.bin
	mov word[sector_No],sector_num_of_root_dir_start
search_in_root_dir_begin:
	cmp word[root_dir_size_for_loop],0
	jz no_loaderbin
	dec word[root_dir_size_for_loop]
	mov ax,0000h
	mov es,ax
	mov bx,8000h
	mov ax,[sector_No]
	mov cl,1
	call func_read_one_sector
	mov si,loader_file_name
	mov di,8000h
	cld
	mov dx,10h
search_for_loaderbin:
	cmp dx,0
	jz goto_next_sector_in_root_dir
	dec dx
	mov cx,0bh
cmp_file_name:
	cmp cx,0
	jz _file_name_found
	dec cx
	lodsb
	cmp al,byte[es:di]
	jz searching_loop
	jmp searching_different
searching_loop:
	inc di
	;dec dx
	jmp cmp_file_name
searching_different:
	and di,0ffe0h
	add di,20h
	mov si,loader_file_name
	jmp search_for_loaderbin
goto_next_sector_in_root_dir:
	add word[sector_No],1
	jmp search_in_root_dir_begin

;;; display on screen ERROR: No loader.bin found
no_loaderbin:
	mov ax,1301h
	mov bx,008ch ; foreground red & shining
	mov dx,0100h
	mov cx,26
	push ax
	mov ax,ds
	mov es,ax
	pop ax
	mov bp,no_loaderbin_message
	int 10h
	jmp $


;;; get FAT12 Entry
func_get_FAT_entry:
;根据当前FAT表项引出下一个FAT表项
	push es
	push bx
	push ax
	mov ax,00
	mov es,ax
	pop ax
	mov byte[odd],0
	mov bx,3
	mul bx
	mov bx,2
	div bx
	cmp dx,0
	jz _even
	mov byte[odd],1
_even:
	xor dx,dx
	mov bx,[BPB_BytesPerSec]
	div bx
	push dx
	mov bx,8000h
	add ax,sector_num_of_FAT12_start
	mov cl,2
	call func_read_one_sector

	pop dx
	add bx,dx
	mov ax,[es:bx]
	cmp byte[odd],1
	jnz _even_2
	shr ax,4
_even_2:
	and ax,0fffh
	pop bx
	pop es
	ret

;;; found loader.bin name in root director struct
_file_name_found:
	mov ax,root_dir_sectors
	and di,0ffe0h
	add di,01ah
	mov cx,word[es:di]
	push cx
	add cx,ax
	add cx,sector_balance
	mov ax,loader_base
	mov es,ax
	mov bx,loader_offset
	mov ax,cx

_go_on_loading_file:
	push ax
	push bx
	mov ah,0eh
	mov al,'.'
	mov bl,0fh
	int 10h
	pop bx
	pop ax

	mov cl,1
	call func_read_one_sector
	pop ax
	call func_get_FAT_entry
	;current sector is the final one
	cmp ax,0fffh
	jz _file_loaded
	push ax
	mov dx,root_dir_sectors
	add ax,dx
	add ax,sector_balance
	add bx,[BPB_BytesPerSec]
	jmp _go_on_loading_file

;jump to loader.bin from boot
_file_loaded:
	jmp loader_base:loader_offset
	;;;cUR

_start:
	mov ax,cs
	mov ds,ax
	mov es,ax
	mov ss,ax
	mov sp,stack_base
; clear screen
	mov ax,0600h
	mov bx,0700h
	mov cx,0
	mov dx,0184fh
	int 10h
; set focus
	mov ax,0200h
	mov bx,0000h
	mov dx,0
	int 10h
; display on screen
	mov ax,1301h
	mov bx,000ah
	mov dx,0
	mov cx,0dh	; length of string
	push ax
	mov ax,ds
	mov es,ax
	pop ax
	mov bp,boot_display_message ; address of boot message
	int 10h
; reset floppy
	xor ah,ah
	xor dl,dl 
	int 13h
	jmp $ ;dead loop

;;; display message 
loader_file_name:
	db "LOADER  BIN",0
no_loaderbin_message: 
	db "ERROR: No loader.bin found" ;length 26
boot_display_message: 
	db "start boot..."

	times 510-($-$$)  db  0
	dw 0xaa55