#include "../libc.h"

int main() {
  int result;
  asm volatile("mulli %0, %1, 30000"
               :"=r"(result)
               :"r"(29999));
  printf("%d\n", result);
  asm volatile("mulli %0, %1, -30000"
               :"=r"(result)
               :"r"(29999));
  printf("%d\n", result);
  asm volatile("mulli %0, %1, 30000"
               :"=r"(result)
               :"r"(-29999));
  printf("%d\n", result);
  asm volatile("mulli %0, %1, -30000"
               :"=r"(result)
               :"r"(-29999));
  printf("%d\n", result);
  asm volatile("mulli %0, %1, 30000"
               :"=r"(result)
               :"r"(-2999999));
  printf("%d\n", result);
  asm volatile("mulli %0, %1, -30000"
               :"=r"(result)
               :"r"(-2999999));
  printf("%d\n", result);
}
