#include "../libc.h"

char buf[99];

int main() {
  buf[0] = 'f';
  buf[1] = 'o';
  buf[2] = 'o';
  buf[3] = 'b';
  buf[4] = 'a';
  buf[5] = 'r';
  buf[6] = '\0';
  return puts(buf);
}
