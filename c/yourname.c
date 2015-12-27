#include "../libc.h"

char buf[256];

int main() {
  char c;
  int i;
  puts("your name?");
  for (i = 0; (c = getchar()) != '\n'; i++) {
    buf[i] = c;
  }
  buf[i] = 0;
  puts("Hello");
  puts(buf);
  return 0;
}
