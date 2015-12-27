#include "../libc.h"
#include "util.h"

int tarai(int x, int y, int z) {
  if (x <= y)
    return y;
  return tarai(tarai(x-1, y, z), tarai(y-1, z, x), tarai(z-1, x, y));
}

int main() {
  puts("=== START ===");
  print_int(tarai(6, 3, 0));
  //print_int(tarai(12, 6, 0));
  putchar('\n');
  puts("=== END ===");
}
