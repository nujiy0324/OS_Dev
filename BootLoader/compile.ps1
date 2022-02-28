

#compile asm
Write-Output "Start compiling asm..."
nasm boot.asm -o boot.bin;


#write into floppy
Write-Output "Start write boot.bin to floppy..." 
dd if=boot.bin of=boot.img bs=512 count=1 conv=notrunc;

#run bochs
Write-Output "Start run bochs..."
bochs -f .\bochsrc.bxrc;