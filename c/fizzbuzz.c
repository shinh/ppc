#include "../libc.h"
#include "util.h"

int main() {
  int i;
  for (i = 1; i <= 100; i++) {
    if (i % 3 == 0) {
      print_str("Fizz");
    }
    if (i % 5 == 0) {
      print_str("Buzz");
    }
    if (i % 3 && i % 5) {
      print_int(i);
    }
    puts("");
  }
}
