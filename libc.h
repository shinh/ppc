int main();

// stddef.h
typedef unsigned long size_t;

// stdio.h - output
int write(int fd, const void* buf, int cnt);
int putchar(int c);
int puts(const char* s);
int printf(const char* fmt, ...);
int fprintf(void* fp, const char* fmt, ...);
int fputc(int c, void* fp);

// stdio.h - input
int read(int fd, void* buf, int cnt);
int getchar(void);
int scanf(const char* fmt, ...);

// stdlib.h - alloc
void* malloc(size_t s);
void* calloc(size_t n, size_t s);
void free(void* p);

// stdlib.h
void exit(int s);

// string.h
void* memcpy(void* d, const void* s, size_t n);
void* memset(void* s, int c, size_t n);
size_t strlen(const char* s);
char* strcat(char* d, const char* s);

// math.h
double sqrt(double x);
double sin(double x);
double cos(double x);
double atan(double x);
double floor(double x);

#define NULL 0
