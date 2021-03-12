#include <stdio.h>

extern void func(char *s);


int main () {
  func("123");
  return 0;
}
