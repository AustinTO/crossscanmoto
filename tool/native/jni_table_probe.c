#define _GNU_SOURCE
#include <elf.h>
#include <errno.h>
#include <dlfcn.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <sys/mman.h>

static int prop(const char *name, char *value) { (void)name; *value = 0; return 0; }
static void abortmsg(const char *message) { (void)message; }
static size_t slenchk(const char *value, size_t size) {
  size_t length = strlen(value); if (length >= size) abort(); return length;
}
static int *errloc(void) { return &errno; }
static unsigned char fake_stderr[4096];
#ifdef TRACE_JNI
#define TRACE(...) fprintf(stderr, __VA_ARGS__)
#else
#define TRACE(...) ((void)0)
#endif

static void *external(const char *name) {
  if (!strcmp(name, "__system_property_get")) return prop;
  if (!strcmp(name, "android_set_abort_message")) return abortmsg;
  if (!strcmp(name, "__strlen_chk")) return slenchk;
  if (!strcmp(name, "__errno")) return errloc;
  if (!strcmp(name, "__sF")) return fake_stderr;
  void *symbol = dlsym(RTLD_DEFAULT, name);
  if (!symbol) { fprintf(stderr, "Unresolved import %s\n", name); exit(2); }
  return symbol;
}

typedef struct { size_t length; char **values; } FakeArray;
static const char *get_utf(void *env, const char *value, void *copy) {
  TRACE("GetStringUTFChars %s\n", value);
  (void)env; (void)copy; return value;
}
static void release_utf(void *env, const char *value, const char *chars) {
  (void)env; (void)value; (void)chars;
}
static char *new_utf(void *env, const char *value) {
  TRACE("NewStringUTF %s\n", value);
  (void)env; return strdup(value);
}
static void *find_class(void *env, const char *name) {
  TRACE("FindClass %s\n", name);
  (void)env; (void)name; return (void *)1;
}
static FakeArray *new_object_array(void *env, int length, void *clazz, void *initial) {
  TRACE("NewObjectArray %d\n", length);
  (void)env; (void)clazz; (void)initial;
  if (length < 0 || length > 100000) return NULL;
  FakeArray *array = calloc(1, sizeof(*array));
  if (!array) return NULL;
  array->length = (size_t)length;
  array->values = calloc(array->length ? array->length : 1, sizeof(char *));
  if (!array->values) { free(array); return NULL; }
  return array;
}
static void set_array_element(void *env, FakeArray *array, int index, char *value) {
  (void)env;
  TRACE("SetObjectArrayElement %d %s\n", index, value);
  if (!array || index < 0 || (size_t)index >= array->length) abort();
  array->values[index] = value;
}
static void delete_local_ref(void *env, void *object) { (void)env; (void)object; }

int main(int argc, char **argv) {
  if (argc != 4) { fprintf(stderr, "usage: probe library ecu table\n"); return 2; }
  FILE *file = fopen(argv[1], "rb"); if (!file) return 2;
  fseek(file, 0, SEEK_END); size_t file_len = (size_t)ftell(file); rewind(file);
  unsigned char *bytes = malloc(file_len);
  if (!bytes || fread(bytes, 1, file_len, file) != file_len) return 2;
  fclose(file);
  Elf64_Ehdr *elf = (void *)bytes;
  if (memcmp(elf->e_ident, ELFMAG, SELFMAG) || elf->e_machine != EM_AARCH64) return 2;
  Elf64_Phdr *programs = (void *)(bytes + elf->e_phoff); size_t span = 0;
  for (int i = 0; i < elf->e_phnum; i++)
    if (programs[i].p_type == PT_LOAD && programs[i].p_vaddr + programs[i].p_memsz > span)
      span = (size_t)(programs[i].p_vaddr + programs[i].p_memsz);
  unsigned char *base = mmap(NULL, (span + 4095) & ~4095UL,
      PROT_READ | PROT_WRITE | PROT_EXEC, MAP_PRIVATE | MAP_ANONYMOUS, -1, 0);
  if (base == MAP_FAILED) return 2;
  for (int i = 0; i < elf->e_phnum; i++) if (programs[i].p_type == PT_LOAD)
    memcpy(base + programs[i].p_vaddr, bytes + programs[i].p_offset, programs[i].p_filesz);
  Elf64_Shdr *sections = (void *)(bytes + elf->e_shoff);
  Elf64_Sym *symbols = NULL; char *strings = NULL;
  for (int i = 0; i < elf->e_shnum; i++) if (sections[i].sh_type == SHT_DYNSYM) {
    symbols = (void *)(bytes + sections[i].sh_offset);
    strings = (void *)(bytes + sections[sections[i].sh_link].sh_offset);
  }
  if (!symbols || !strings) return 2;
  for (int i = 0; i < elf->e_shnum; i++) if (sections[i].sh_type == SHT_RELA) {
    Elf64_Rela *relas = (void *)(bytes + sections[i].sh_offset);
    size_t count = sections[i].sh_size / sizeof(*relas);
    for (size_t j = 0; j < count; j++) {
      unsigned type = ELF64_R_TYPE(relas[j].r_info), symbol_index = ELF64_R_SYM(relas[j].r_info);
      uintptr_t value = 0;
      if (type == R_AARCH64_RELATIVE) value = (uintptr_t)base + relas[j].r_addend;
      else if (type == R_AARCH64_ABS64 || type == R_AARCH64_GLOB_DAT || type == R_AARCH64_JUMP_SLOT) {
        value = symbols[symbol_index].st_shndx == SHN_UNDEF
            ? (uintptr_t)external(strings + symbols[symbol_index].st_name)
            : (uintptr_t)(base + symbols[symbol_index].st_value);
        value += relas[j].r_addend;
      } else { fprintf(stderr, "Unsupported relocation %u\n", type); return 2; }
      if (relas[j].r_offset + sizeof(uintptr_t) > span) return 2;
      *(uintptr_t *)(base + relas[j].r_offset) = value;
    }
  }
  __builtin___clear_cache((char *)base, (char *)base + span);

  void *jni_methods[240] = {0};
  jni_methods[6] = find_class;
  jni_methods[23] = delete_local_ref;
  jni_methods[167] = new_utf;
  jni_methods[169] = get_utf;
  jni_methods[170] = release_utf;
  jni_methods[172] = new_object_array;
  jni_methods[174] = set_array_element;
  void *env = jni_methods;
  FakeArray *(*query)(void *, void *, const char *, const char *) =
      (void *)(base + 0x6f6d84);
  TRACE("Calling private native j (target of public NativeLibMotoScan.n(String,String))\n");
  FakeArray *result = query(&env, NULL, argv[2], argv[3]);
  TRACE("native j returned %p\n", (void *)result);
  if (!result) { fprintf(stderr, "native j returned null\n"); return 3; }
  if (result->length > 100000) { fprintf(stderr, "invalid array length %zu\n", result->length); return 3; }
  fprintf(stderr, "rows=%zu\n", result->length);
  for (size_t i = 0; i < result->length; i++) {
    if (!result->values[i]) { fprintf(stderr, "null row at %zu\n", i); return 3; }
    puts(result->values[i]);
  }
  return 0;
}
