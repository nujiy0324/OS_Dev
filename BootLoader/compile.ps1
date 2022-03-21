#compile asm
Write-Output "Start compiling asm..."
Remove-Item loader.bin
Remove-Item boot.bin
nasm .\loader.asm-o loader.bin
nasm .\boot.asm -o boot.bin 

#write into floppy
Write-Output "Start write boot.bin to floppy..." 
dd if=boot.bin of=boot.img bs=512 count=1 conv=notrunc;
Write-Output "Start write loader.bin to floppy..."
# New-PSDrive boot.img /media/ -t vfat -o loop
# Copy-Item .\loader.bin /media/
# sync
# umount /media/

#run bochs
Write-Output "Start run bochs..."
bochs -f .\bochsrc.bxrc;