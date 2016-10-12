
static inline uchar inb(ushort port)
{
	uchar data;
	asm volatile("in %1,%0":"=a"(data) :"d"(port));
	return data;
}

//stosb:set value since dst to dst+size
static inline void stosb(void* addr,int value,int cnt)
{
	asm volatile("cld;rep stosb":
				 "=D"(addr),"=c"(cnt):
				 "0"(addr),"1"(cnt),"a"(value):
				 "memory","cc");
}

static inline void outb(ushort port,int value)
{
	asm volatile("out %0,%1" : :
				 "a"(value),"d"(port));
}

//the size is the mutiply of the sizeof(long int)
static inline void insl(ushort port,void *addr,int cnt)
{
	asm volatile("cld;rep insl":
				 "=D"(addr),"=c"(cnt):
				 "d"(port),"0"(addr),"1"(cnt):
				 "memory","cc");
}
