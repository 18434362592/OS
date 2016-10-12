#define ELF_MAGIC	0x464c457FU

//file header
struct elfhdr
{
	uint	magic;
	uchar	elf[12];
	ushort 	type;
	ushort 	machine;
	uint 	version;
	uint 	entry;
	uint	phoff;		//program header table's file offset in bytes
	uint 	shoff;
	uint 	flags;
	ushort 	ehsize;
	ushort	phentsize;
	ushort	phnum;		//holds the number of entries in the program header table
	ushort 	shentsize;
	ushort 	shnum;
	ushort	shstrndx;
};

struct proghdr
{
	uint	type;
	uint 	off;
	uint 	vaddr;
	uint 	paddr;
	uint 	filesz;
	uint 	memsz;
	uint 	flags;
	uint 	align;
};
