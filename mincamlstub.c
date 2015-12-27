#include "libc.h"

int main() {
  char *hp, *sp;
  hp = malloc(40000); sp = malloc(10000);
  _min_caml_start(sp, hp);
  return 0;
}
