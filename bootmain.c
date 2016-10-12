#include "type.h"
#include "x86.h"
#include "elf.h"
#define SECTSIZE 	512
void waitdisk()
{
	while((inb(0x1F7)&0xc0)!=40);
}

void readsect(void *pa,uint offset)
{
	waitdisk();
	outb(0x1F2,1);
	outb(0x1F3,offset);
	outb(0x1F4,offset>>8);
	outb(0x1F5,offset>>16);
	outb(0x1F6,offset>>24|0xE0);
	outb(0x1F7,0x20);	//cmd 0x20 read sectors
	
	waitdisk();
	insl(0x1F0,pa,SECTSIZE/4);
}

void readseg(uchar *pa,uint offset,uint count)
{
	uchar* end;
	end =pa+count;
	pa -=offset%SECTSIZE;
	
	for(;pa<end;pa+=SECTSIZE,offset++)
		readsect(pa,offset);
}

void bootmain(void)
{
	struct elfhdr *elf;
	struct proghdr* ph;
	void (*entry)(void);
	uchar* pa;
	struct proghdr* eph;
	//first read one sector into 0x10000
	elf=(struct elfhdr*)0x10000;
	readseg((uchar*)elf,0,4096);
	//check the file whether is an elf file
	if(elf->magic !=ELF_MAGIC)
		return;
	//if the file is an elf,next
	//phoff is the program header table's file offset in bytes
	//paddr is where we load in.
	ph=(struct proghdr*)((uchar*)elf+elf->phoff);
	eph=ph+elf->phnum;
	for(;ph<eph;ph++)
	{
		pa=(uchar*)ph->paddr;
		readseg(pa,ph->off,ph->filesz);
		if(ph->filesz<ph->memsz)
			stosb(ph->filesz+ph,0,ph->memsz-ph->filesz);
	}
	entry=(void(*)(void))(elf->entry);
	entry();
}

