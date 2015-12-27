void print_str(const char* p) {
  for (; *p; p++)
    putchar(*p);
}

void print_int(long v) {
  char buf[99];
  char* p = buf + 98;
  if (v < 0) {
    v = -v;
    print_str("-");
  }
  *p = '\0';
  do {
    --p;
    *p = v % 10 + '0';
    v /= 10;
  } while (v);
  print_str(p);
}
