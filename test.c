#include <stdio.h>
#include <unistd.h>

int main(void) {
   printf("pid: %d\n", getpid());
   while (1) {
      printf("Parent process running...\n");
      sleep(1);
   }
}
