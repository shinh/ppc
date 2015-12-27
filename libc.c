#include "libc.h"

#include <limits.h>
#include <stdarg.h>

static void print_str(const char* p) {
  for (; *p; p++)
    putchar(*p);
}

static char* stringify_int(long v, char* p) {
  int is_negative = 0;
  *p = '\0';
  if (v < 0) {
    if (v == LONG_MIN) {
      --p;
      // The last digit is 8 for both 32bit and 64bit long.
      *p = '8';
      // This heavily depends on C99's division.
      v /= 10;
    }
    v = -v;
    is_negative = 1;
  }
  do {
    --p;
    *p = v % 10 + '0';
    v /= 10;
  } while (v);
  if (is_negative)
    *--p = '-';
  return p;
}

static void print_int(long v) {
  char buf[32];
  print_str(stringify_int(v, buf + sizeof(buf) - 1));
}

static char* stringify_hex(long v, char* p) {
  int is_negative = 0;
  int c;
  *p = '\0';
  if (v < 0) {
    if (v == LONG_MIN) {
      --p;
      *p = '0';
      // This heavily depends on C99's division.
      v /= 16;
    }
    v = -v;
    is_negative = 1;
  }
  do {
    --p;
    c = v % 16;
    *p = c < 10 ? c + '0' : c - 10 + 'A';
    v /= 16;
  } while (v);
  *--p = 'x';
  *--p = '0';
  if (is_negative)
    *--p = '-';
  return p;
}

int write(int fd, const void* buf, int cnt) {
  int r = -1;
  asm volatile("mr r3, %1\n"
               "mr r4, %2\n"
               "mr r5, %3\n"
               "li r0, 4\n"
               "sc\n"
               "mr %0, r3\n"
               :"=r"(r): "r"(fd), "r"(buf), "r"(cnt)
               : "r0", "r3", "r4", "r5");
  return r;
}

int putchar(int c) {
  char b = c;
  write(1, &b, 1);
  return c;
}

int puts(const char* s) {
  for (; *s; s++) {
    putchar(*s);
  }
  putchar('\n');
  return 1;
}

int fputc(int c, void* fp) {
  puts("fputc!");
  return 0;
}

int printf(const char* fmt, ...) {
  static const char kOverflowMsg[] = " *** OVERFLOW! ***\n";
  char buf[300] = {0};
  const size_t kMaxFormattedStringSize = sizeof(buf) - sizeof(kOverflowMsg);
  char* outp = buf;
  const char* inp;
  va_list ap;
  int is_overflow = 0;

  va_start(ap, fmt);
  for (inp = fmt; *inp && (outp - buf) < kMaxFormattedStringSize; inp++) {
    if (*inp != '%') {
      *outp++ = *inp;
      if (outp - buf >= kMaxFormattedStringSize) {
        is_overflow = 1;
        break;
      }
      continue;
    }

    char cur_buf[32];
    char* cur_p;
    switch (*++inp) {
      case 'd':
        // This is unsafe if we pass more than 6 integer values to
        // this function on x86-64, because it starts using stack.
        // You need to cast to long in the call site for such cases.
        cur_p = stringify_int(va_arg(ap, long), cur_buf + sizeof(cur_buf) - 1);
        break;
      case 'x':
        cur_p = stringify_hex(va_arg(ap, long), cur_buf + sizeof(cur_buf) - 1);
        break;
      case 's':
        cur_p = va_arg(ap, char*);
        break;
      default:
        print_str("unknown format!\n");
        exit(1);
    }

    size_t len = strlen(cur_p);
    if (outp + len - buf >= kMaxFormattedStringSize) {
      is_overflow = 1;
      break;
    }
    strcat(buf, cur_p);
    outp += len;
  }
  va_end(ap);

  if (strlen(buf) > kMaxFormattedStringSize) {
    print_str(buf);
    if (is_overflow)
      print_str(kOverflowMsg);
    // This should not happen.
    exit(1);
  }
  if (is_overflow)
    strcat(buf, kOverflowMsg);
  print_str(buf);
  return 0;
}

int fprintf(void* fp, const char* fmt, ...) {
  puts("fprintf!");
  return 0;
}

int read(int fd, void* buf, int cnt) {
  int r = -1;
  asm volatile("mr r3, %1\n"
               "mr r4, %2\n"
               "mr r5, %3\n"
               "li r0, 3\n"
               "sc\n"
               "mr %0, r3\n"
               :"=r"(r): "r"(fd), "r"(buf), "r"(cnt)
               : "r0", "r3", "r4", "r5");
  return r;
}

int getchar(void) {
  char c;
  if (read(0, &c, 1) <= 0)
    return -1;
  return c;
}

int scanf(const char* fmt, ...) {
  puts("scanf!");
  return 0;
}

__attribute__((section(".heap")))
char heap[0x8000];

void* malloc(size_t s) {
  static char* p = heap;
  char* r = p;
  p += s;
  return r;
}

void* calloc(size_t n, size_t s) {
  return malloc(n * s);
}

void free(void* p) {
}

void exit(int s) {
  asm volatile("mr r3, %0\n"
               "li r0, 1\n"
               "sc\n"
               ::"r"(s): "r0", "r3");
}

void* memset(void* d, int c, size_t n) {
  size_t i;
  for (i = 0; i < n; i++) {
    ((char*)d)[i] = c;
  }
  return d;
}

void* memcpy(void* d, const void* s, size_t n) {
  size_t i;
  for (i = 0; i < n; i++) {
    ((char*)d)[i] = ((char*)s)[i];
  }
  return d;
}

size_t strlen(const char* s) {
  size_t r;
  for (r = 0; s[r]; r++) {}
  return r;
}

char* strcat(char* d, const char* s) {
  char* r = d;
  for (; *d; d++) {}
  for (; *s; s++, d++)
    *d = *s;
  return r;
}

double sqrt(double x) {
  puts(__func__);
  puts("called!");
  return 0.0;
}

double sin(double x) {
  puts(__func__);
  puts("called!");
  return 0.0;
}

double cos(double x) {
  puts(__func__);
  puts("called!");
  return 0.0;
}

double atan(double x) {
  puts(__func__);
  puts("called!");
  return 0.0;
}

double floor(double x) {
  puts(__func__);
  puts("called!");
  return 0.0;
}

// Abuse .init section, to let the address of _start be 0x1000.
asm(".section .init\n"
    ".globl _start\n"
    "_start:\n"
    "lis r1, 1\n"
    "li r3, 0\n"
    "li r4, 0\n"
    "li r5, 0\n"
    "li r6, 0\n"
    "bl main\n"
    "li r0, 1\n"
    "sc\n");
