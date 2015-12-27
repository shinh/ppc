#include "../libc.h"

void func() {}

int main() {
  putchar('y');
  func();
  putchar('a');
  putchar('y');
  putchar('\n');
  return 0;
}