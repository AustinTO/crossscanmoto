#define _GNU_SOURCE
#include <elf.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <dlfcn.h>
#include <sys/mman.h>
#include <errno.h>
#include <unistd.h>
#include <stdarg.h>
static int prop(const char*a,char*b){*b=0;return 0;}
static void abortmsg(const char*a){}
static size_t slenchk(const char*a,size_t n){size_t l=strlen(a);if(l>=n)abort();return l;}
static int *errloc(void){return &errno;}
static unsigned char sf[4096];
static void* external(const char*n){
 if(!strcmp(n,"__system_property_get"))return prop;
 if(!strcmp(n,"android_set_abort_message"))return abortmsg;
 if(!strcmp(n,"__strlen_chk"))return slenchk;
 if(!strcmp(n,"__errno"))return errloc;
 if(!strcmp(n,"__sF"))return sf;
 void*p=dlsym(RTLD_DEFAULT,n);
 if(!p){fprintf(stderr,"Unresolved import %s\n",n);exit(2);}return p;
}
static const char* jchars(void*env,const char*value,void*copy){return value;}
static void jrelease(void*env,const char*value,const char*chars){}
static char* jnew(void*env,const char*value){return strdup(value);}
typedef struct{unsigned char bytes[24];}Str;
typedef struct{uint64_t count;char** rows;}Rows;
int main(int argc,char**argv){
 if(argc!=4){fprintf(stderr,"usage: probe library ecu table\n");return 2;}
 FILE*f=fopen(argv[1],"rb");if(!f)return 2;fseek(f,0,SEEK_END);size_t len=ftell(f);rewind(f);unsigned char*b=malloc(len);if(fread(b,1,len,f)!=len)return 2;fclose(f);
 Elf64_Ehdr*e=(void*)b;if(memcmp(e->e_ident,ELFMAG,4)||e->e_machine!=EM_AARCH64)return 2;
 Elf64_Phdr*ph=(void*)(b+e->e_phoff);size_t span=0;
 for(int i=0;i<e->e_phnum;i++)if(ph[i].p_type==PT_LOAD&&ph[i].p_vaddr+ph[i].p_memsz>span)span=ph[i].p_vaddr+ph[i].p_memsz;
 unsigned char*base=mmap(NULL,(span+4095)&~4095UL,PROT_READ|PROT_WRITE|PROT_EXEC,MAP_PRIVATE|MAP_ANONYMOUS,-1,0);if(base==MAP_FAILED)return 2;
 for(int i=0;i<e->e_phnum;i++)if(ph[i].p_type==PT_LOAD)memcpy(base+ph[i].p_vaddr,b+ph[i].p_offset,ph[i].p_filesz);
 Elf64_Shdr*sh=(void*)(b+e->e_shoff);Elf64_Sym*syms=NULL;char*strings=NULL;
 for(int i=0;i<e->e_shnum;i++)if(sh[i].sh_type==SHT_DYNSYM){syms=(void*)(b+sh[i].sh_offset);strings=(void*)(b+sh[sh[i].sh_link].sh_offset);}
 if(!syms||!strings)return 2;
 for(int i=0;i<e->e_shnum;i++)if(sh[i].sh_type==SHT_RELA){
  Elf64_Rela*r=(void*)(b+sh[i].sh_offset);size_t count=sh[i].sh_size/sizeof(*r);
  for(size_t j=0;j<count;j++){
   unsigned type=ELF64_R_TYPE(r[j].r_info),si=ELF64_R_SYM(r[j].r_info);uintptr_t value=0;
   if(type==R_AARCH64_RELATIVE)value=(uintptr_t)base+r[j].r_addend;
   else if(type==R_AARCH64_ABS64||type==R_AARCH64_GLOB_DAT||type==R_AARCH64_JUMP_SLOT){
    value=syms[si].st_shndx==SHN_UNDEF?(uintptr_t)external(strings+syms[si].st_name):(uintptr_t)(base+syms[si].st_value);value+=r[j].r_addend;
   }else{fprintf(stderr,"Unsupported relocation %u\n",type);return 2;}
   if(r[j].r_offset+8>span)return 2;*(uintptr_t*)(base+r[j].r_offset)=value;
  }
 }
 __builtin___clear_cache((char*)base,(char*)base+span);
 if(!strcmp(argv[2],"--ids")){
  void*methods[240]={0};methods[167]=jnew;void*env=methods;
  uintptr_t addresses[]={0x6f9f7c,0x6f9c4c,0x6f9d18,0x6f9de4,0x6f9eb0,0x6fa048,0x6fa114};
  const char*names[]={"q","r","s","t","u","v","y"};
  FILE*in=fopen(argv[3],"r");if(!in)return 2;int id;
  while(fscanf(in,"%d",&id)==1)for(int i=0;i<7;i++){
   char*(*fn)(void*,void*,int)=(void*)(base+addresses[i]);char*v=fn(&env,NULL,id);
   if(v&&*v&&strcmp(v,"unknown text")){printf("{\"id\":%d,\"method\":\"%s\",\"text\":\"",id,names[i]);
    for(unsigned char*c=(void*)v;*c;c++){if(*c=='"'||*c=='\\')putchar('\\');if(*c<32)printf("\\u%04x",*c);else putchar(*c);}puts("\"}");}
   free(v);
  }
  fclose(in);return 0;
 }
 if(!strcmp(argv[2],"--id")){
  void*methods[240]={0};methods[167]=jnew;void*env=methods;
  uintptr_t addresses[]={0x6f9f7c,0x6f9c4c,0x6f9d18,0x6f9de4,0x6f9eb0,0x6fa048,0x6fa114};
  const char*names[]={"q","r","s","t","u","v","y"};
  for(int i=0;i<7;i++){char*(*fn)(void*,void*,int)=(void*)(base+addresses[i]);char*v=fn(&env,NULL,atoi(argv[3]));printf("%s\t%s\n",names[i],v?v:"<null>");}
  return 0;
 }
 if(!strcmp(argv[2],"--text")||!strcmp(argv[2],"--dtc")){
  void* methods[240]={0};methods[169]=jchars;methods[170]=jrelease;methods[167]=jnew;void* env=methods;
  char*(*querytext)(void*,void*,const char*,const char*,int)=(void*)(base+0x6f7c10);
  char*sep=strchr(argv[3],':');if(!sep)return 2;*sep=0;
  char*(*querydtc)(void*,void*,const char*,int,int)=(void*)(base+0x6f8c80);
  for(int flag=0;flag<7;flag++){char*value=!strcmp(argv[2],"--dtc")?querydtc(&env,NULL,argv[3],atoi(sep+1),flag):querytext(&env,NULL,argv[3],sep+1,flag);printf("%d\t%s\n",flag,value?value:"<null>");}
  return 0;
 }
 if(strlen(argv[2])>22||strlen(argv[3])>22)return 2;
 Str ecu={0},table={0};ecu.bytes[0]=strlen(argv[2])*2;memcpy(ecu.bytes+1,argv[2],strlen(argv[2]));table.bytes[0]=strlen(argv[3])*2;memcpy(table.bytes+1,argv[3],strlen(argv[3]));
 void*(*factory)(Str*)=(void*)(base+0x88e3d0);void*object=factory(&ecu);if(!object)return 3;
 Rows(*query)(void*,Str*)=(void*)(*(uintptr_t**)(object))[0];Rows rows=query(object,&table);
 if(rows.count>100000){fprintf(stderr,"Invalid row count %lu\n",rows.count);return 3;}
 fprintf(stderr,"rows=%lu\n",rows.count);
 for(size_t i=0;i<rows.count;i++){if(!rows.rows[i])return 3;puts(rows.rows[i]);}
 return 0;
}
