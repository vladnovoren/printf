#include <stdio.h>

extern void func(char *s);


int main () {
  func("12341234\n");
  return 0;
}
