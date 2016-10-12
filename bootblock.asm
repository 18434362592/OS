
bootblock.o:     file format elf32-i386


Disassembly of section .text:

00007c00 <start>:
# with %cs=0 %ip=7c00.

.code16                       # Assemble for 16-bit mode
.globl start
start:
  cli                         # BIOS enabled interrupts; disable
    7c00:	fa                   	cli    

  # Zero data segment registers DS, ES, and SS.
  xorw    %ax,%ax             # Set %ax to zero
    7c01:	31 c0                	xor    %eax,%eax
  movw    %ax,%ds             # -> Data Segment
    7c03:	8e d8                	mov    %eax,%ds
  movw    %ax,%es             # -> Extra Segment
    7c05:	8e c0                	mov    %eax,%es
  movw    %ax,%ss             # -> Stack Segment
    7c07:	8e d0                	mov    %eax,%ss

00007c09 <seta20.1>:

  # Physical address line A20 is tied to zero so that the first PCs 
  # with 2 MB would run software that assumed 1 MB.  Undo that.
seta20.1:
  inb     $0x64,%al               # Wait for not busy
    7c09:	e4 64                	in     $0x64,%al
  testb   $0x2,%al
    7c0b:	a8 02                	test   $0x2,%al
  jnz     seta20.1
    7c0d:	75 fa                	jne    7c09 <seta20.1>

  movb    $0xd1,%al               # 0xd1 -> port 0x64
    7c0f:	b0 d1                	mov    $0xd1,%al
  outb    %al,$0x64
    7c11:	e6 64                	out    %al,$0x64

00007c13 <seta20.2>:

seta20.2:
  inb     $0x64,%al               # Wait for not busy
    7c13:	e4 64                	in     $0x64,%al
  testb   $0x2,%al
    7c15:	a8 02                	test   $0x2,%al
  jnz     seta20.2
    7c17:	75 fa                	jne    7c13 <seta20.2>

  movb    $0xdf,%al               # 0xdf -> port 0x60
    7c19:	b0 df                	mov    $0xdf,%al
  outb    %al,$0x60
    7c1b:	e6 60                	out    %al,$0x60

  # Switch from real to protected mode.  Use a bootstrap GDT that makes
  # virtual addresses map directly to physical addresses so that the
  # effective memory map doesn't change during the transition.
  lgdt    gdtdesc
    7c1d:	0f 01 16             	lgdtl  (%esi)
    7c20:	78 7c                	js     7c9e <readseg+0xa>
  movl    %cr0, %eax
    7c22:	0f 20 c0             	mov    %cr0,%eax
  orl     $CR0_PE, %eax
    7c25:	66 83 c8 01          	or     $0x1,%ax
  movl    %eax, %cr0
    7c29:	0f 22 c0             	mov    %eax,%cr0

//PAGEBREAK!
  # Complete transition to 32-bit protected mode by using long jmp
  # to reload %cs and %eip.  The segment descriptors are set up with no
  # translation, so that the mapping is still the identity mapping.
  ljmp    $(SEG_KCODE<<3), $start32
    7c2c:	ea                   	.byte 0xea
    7c2d:	31 7c 08 00          	xor    %edi,0x0(%eax,%ecx,1)

00007c31 <start32>:

.code32  # Tell assembler to generate 32-bit code now.
start32:
  # Set up the protected-mode data segment registers
  movw    $(SEG_KDATA<<3), %ax    # Our data segment selector
    7c31:	66 b8 10 00          	mov    $0x10,%ax
  movw    %ax, %ds                # -> DS: Data Segment
    7c35:	8e d8                	mov    %eax,%ds
  movw    %ax, %es                # -> ES: Extra Segment
    7c37:	8e c0                	mov    %eax,%es
  movw    %ax, %ss                # -> SS: Stack Segment
    7c39:	8e d0                	mov    %eax,%ss
  movw    $0, %ax                 # Zero segments not ready for use
    7c3b:	66 b8 00 00          	mov    $0x0,%ax
  movw    %ax, %fs                # -> FS
    7c3f:	8e e0                	mov    %eax,%fs
  movw    %ax, %gs                # -> GS
    7c41:	8e e8                	mov    %eax,%gs

  # Set up the stack pointer and call into C.
  movl    $start, %esp
    7c43:	bc 00 7c 00 00       	mov    $0x7c00,%esp
  call    bootmain
    7c48:	e8 6b 00 00 00       	call   7cb8 <bootmain>

  # If bootmain returns (it shouldn't), trigger a Bochs
  # breakpoint if running under Bochs, then loop.
  movw    $0x8a00, %ax            # 0x8a00 -> port 0x8a00
    7c4d:	66 b8 00 8a          	mov    $0x8a00,%ax
  movw    %ax, %dx
    7c51:	66 89 c2             	mov    %ax,%dx
  outw    %ax, %dx
    7c54:	66 ef                	out    %ax,(%dx)
  movw    $0x8ae0, %ax            # 0x8ae0 -> port 0x8a00
    7c56:	66 b8 e0 8a          	mov    $0x8ae0,%ax
  outw    %ax, %dx
    7c5a:	66 ef                	out    %ax,(%dx)

00007c5c <spin>:
spin:
  jmp     spin
    7c5c:	eb fe                	jmp    7c5c <spin>
    7c5e:	66 90                	xchg   %ax,%ax

00007c60 <gdt>:
	...
    7c68:	ff                   	(bad)  
    7c69:	ff 00                	incl   (%eax)
    7c6b:	00 00                	add    %al,(%eax)
    7c6d:	9a cf 00 ff ff 00 00 	lcall  $0x0,$0xffff00cf
    7c74:	00                   	.byte 0x0
    7c75:	92                   	xchg   %eax,%edx
    7c76:	cf                   	iret   
	...

00007c78 <gdtdesc>:
    7c78:	17                   	pop    %ss
    7c79:	00 60 7c             	add    %ah,0x7c(%eax)
	...

00007c7e <waitdisk>:
#include "type.h"
#include "x86.h"
#include "elf.h"
#define SECTSIZE 	512
void waitdisk()
{
    7c7e:	55                   	push   %ebp
    7c7f:	89 e5                	mov    %esp,%ebp
#include "type.h"
static inline uchar inb(ushort port)
{
	uchar data;
	asm volatile("in %1,%0":"=a"(data) :"d"(port));
    7c81:	ba f7 01 00 00       	mov    $0x1f7,%edx
    7c86:	ec                   	in     (%dx),%al
    7c87:	eb fd                	jmp    7c86 <waitdisk+0x8>

00007c89 <readsect>:
	while((inb(0x1F7)&0xc0)!=40);
}

void readsect(void *pa,uint offset)
{
    7c89:	55                   	push   %ebp
    7c8a:	89 e5                	mov    %esp,%ebp
    7c8c:	ba f7 01 00 00       	mov    $0x1f7,%edx
    7c91:	ec                   	in     (%dx),%al
    7c92:	eb fd                	jmp    7c91 <readsect+0x8>

00007c94 <readseg>:
	waitdisk();
	insl(0x1F0,pa,SECTSIZE/4);
}

void readseg(uchar *pa,uint offset,uint count)
{
    7c94:	55                   	push   %ebp
    7c95:	89 e5                	mov    %esp,%ebp
    7c97:	8b 45 08             	mov    0x8(%ebp),%eax
	uchar* end;
	end =pa+count;
	pa -=offset%SECTSIZE;
	
	for(;pa<end;pa+=SECTSIZE,offset++)
    7c9a:	89 c1                	mov    %eax,%ecx
    7c9c:	03 4d 10             	add    0x10(%ebp),%ecx
    7c9f:	8b 55 0c             	mov    0xc(%ebp),%edx
    7ca2:	81 e2 ff 01 00 00    	and    $0x1ff,%edx
    7ca8:	29 d0                	sub    %edx,%eax
    7caa:	39 c1                	cmp    %eax,%ecx
    7cac:	76 08                	jbe    7cb6 <readseg+0x22>
    7cae:	ba f7 01 00 00       	mov    $0x1f7,%edx
    7cb3:	ec                   	in     (%dx),%al
    7cb4:	eb fd                	jmp    7cb3 <readseg+0x1f>
		readsect(pa,offset);
}
    7cb6:	5d                   	pop    %ebp
    7cb7:	c3                   	ret    

00007cb8 <bootmain>:

void bootmain(void)
{
    7cb8:	55                   	push   %ebp
    7cb9:	89 e5                	mov    %esp,%ebp
    7cbb:	57                   	push   %edi
    7cbc:	56                   	push   %esi
    7cbd:	53                   	push   %ebx
    7cbe:	83 ec 0c             	sub    $0xc,%esp
	void (*entry)(void);
	uchar* pa;
	struct proghdr* eph;
	//first read one sector into 0x10000
	elf=(struct elfhdr*)0x10000;
	readseg((uchar*)elf,0,4096);
    7cc1:	68 00 10 00 00       	push   $0x1000
    7cc6:	6a 00                	push   $0x0
    7cc8:	68 00 00 01 00       	push   $0x10000
    7ccd:	e8 c2 ff ff ff       	call   7c94 <readseg>
    7cd2:	83 c4 0c             	add    $0xc,%esp
	//check the file whether is an elf file
	if(elf->magic !=ELF_MAGIC)
    7cd5:	81 3d 00 00 01 00 7f 	cmpl   $0x464c457f,0x10000
    7cdc:	45 4c 46 
    7cdf:	75 54                	jne    7d35 <bootmain+0x7d>
		return;
	//if the file is an elf,next
	//phoff is the program header table's file offset in bytes
	//paddr is where we load in.
	ph=(struct proghdr*)((uchar*)elf+elf->phoff);
    7ce1:	a1 1c 00 01 00       	mov    0x1001c,%eax
    7ce6:	8d 98 00 00 01 00    	lea    0x10000(%eax),%ebx
	eph=ph+elf->phnum;
    7cec:	0f b7 35 2c 00 01 00 	movzwl 0x1002c,%esi
    7cf3:	c1 e6 05             	shl    $0x5,%esi
    7cf6:	01 de                	add    %ebx,%esi
	for(;ph<eph;ph++)
    7cf8:	39 f3                	cmp    %esi,%ebx
    7cfa:	73 33                	jae    7d2f <bootmain+0x77>
	{
		pa=(uchar*)ph->paddr;
		readseg(pa,ph->off,ph->filesz);
    7cfc:	8b 7b 10             	mov    0x10(%ebx),%edi
    7cff:	57                   	push   %edi
    7d00:	ff 73 04             	pushl  0x4(%ebx)
    7d03:	ff 73 0c             	pushl  0xc(%ebx)
    7d06:	e8 89 ff ff ff       	call   7c94 <readseg>
    7d0b:	83 c4 0c             	add    $0xc,%esp
		if(ph->filesz<ph->memsz)
    7d0e:	8b 4b 14             	mov    0x14(%ebx),%ecx
    7d11:	39 cf                	cmp    %ecx,%edi
    7d13:	73 13                	jae    7d28 <bootmain+0x70>
}

//stosb:set value since dst to dst+size
static inline void stosb(void* addr,int value,int cnt)
{
	asm volatile("cld;rep stosb":
    7d15:	89 f8                	mov    %edi,%eax
    7d17:	c1 e0 05             	shl    $0x5,%eax
    7d1a:	01 d8                	add    %ebx,%eax
    7d1c:	29 f9                	sub    %edi,%ecx
    7d1e:	89 c7                	mov    %eax,%edi
    7d20:	b8 00 00 00 00       	mov    $0x0,%eax
    7d25:	fc                   	cld    
    7d26:	f3 aa                	rep stos %al,%es:(%edi)
	//if the file is an elf,next
	//phoff is the program header table's file offset in bytes
	//paddr is where we load in.
	ph=(struct proghdr*)((uchar*)elf+elf->phoff);
	eph=ph+elf->phnum;
	for(;ph<eph;ph++)
    7d28:	83 c3 20             	add    $0x20,%ebx
    7d2b:	39 de                	cmp    %ebx,%esi
    7d2d:	77 cd                	ja     7cfc <bootmain+0x44>
		readseg(pa,ph->off,ph->filesz);
		if(ph->filesz<ph->memsz)
			stosb(ph->filesz+ph,0,ph->memsz-ph->filesz);
	}
	entry=(void(*)(void))(elf->entry);
	entry();
    7d2f:	ff 15 18 00 01 00    	call   *0x10018
}
    7d35:	8d 65 f4             	lea    -0xc(%ebp),%esp
    7d38:	5b                   	pop    %ebx
    7d39:	5e                   	pop    %esi
    7d3a:	5f                   	pop    %edi
    7d3b:	5d                   	pop    %ebp
    7d3c:	c3                   	ret    
