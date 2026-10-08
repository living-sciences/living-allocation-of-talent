#define _GNU_SOURCE
#include <string.h>
#include <stdlib.h>
#include <dlfcn.h>
#include <fcntl.h>
#include <stdarg.h>
#include <stdio.h>

/* Redirect opens of the (missing) compiled-in freefont path to installed DejaVu TTFs. */
static const char *remap(const char *path, char *buf, size_t n){
  if(!path) return path;
  if(strstr(path, "/freefont/")){
    const char *repl = "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf";
    if(strstr(path,"Bold")&&strstr(path,"Oblique")) repl="/usr/share/fonts/truetype/dejavu/DejaVuSans-BoldOblique.ttf";
    else if(strstr(path,"Bold")) repl="/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf";
    else if(strstr(path,"Oblique")||strstr(path,"Italic")) repl="/usr/share/fonts/truetype/dejavu/DejaVuSans-Oblique.ttf";
    else if(strstr(path,"Mono")) repl="/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf";
    else if(strstr(path,"Serif")) repl="/usr/share/fonts/truetype/dejavu/DejaVuSerif.ttf";
    snprintf(buf,n,"%s",repl);
    return buf;
  }
  return path;
}

typedef FILE* (*fopen_t)(const char*, const char*);
typedef int (*open_t)(const char*, int, ...);

FILE *fopen(const char *path, const char *mode){
  static fopen_t real=NULL; if(!real) real=(fopen_t)dlsym(RTLD_NEXT,"fopen");
  char buf[1024]; return real(remap(path,buf,sizeof buf), mode);
}
FILE *fopen64(const char *path, const char *mode){
  static fopen_t real=NULL; if(!real) real=(fopen_t)dlsym(RTLD_NEXT,"fopen64");
  char buf[1024]; return real(remap(path,buf,sizeof buf), mode);
}
int open(const char *path, int flags, ...){
  static open_t real=NULL; if(!real) real=(open_t)dlsym(RTLD_NEXT,"open");
  char buf[1024]; const char* p=remap(path,buf,sizeof buf);
  mode_t m=0; if(flags&O_CREAT){va_list a; va_start(a,flags); m=va_arg(a,int); va_end(a);} 
  return real(p,flags,m);
}
int open64(const char *path, int flags, ...){
  static open_t real=NULL; if(!real) real=(open_t)dlsym(RTLD_NEXT,"open64");
  char buf[1024]; const char* p=remap(path,buf,sizeof buf);
  mode_t m=0; if(flags&O_CREAT){va_list a; va_start(a,flags); m=va_arg(a,int); va_end(a);} 
  return real(p,flags,m);
}
