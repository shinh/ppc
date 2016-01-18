#include "../libc.h"

int main() {
  int result;
  asm volatile("mullw %0, %1, %2"
               :"=r"(result)
               :"r"(2999999), "r"(3000000));
  printf("%d\n", result);
  asm volatile("mullw %0, %1, %2"
               :"=r"(result)
               :"r"(2999999), "r"(-3000000));
  printf("%d\n", result);
  asm volatile("mullw %0, %1, %2"
               :"=r"(result)
               :"r"(-2999999), "r"(3000000));
  printf("%d\n", result);
  asm volatile("mullw %0, %1, %2"
               :"=r"(result)
               :"r"(-2999999), "r"(-3000000));
  printf("%d\n", result);
}
