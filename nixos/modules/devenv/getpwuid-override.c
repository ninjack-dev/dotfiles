/*
 * getpwuid-override.c - force the login shell reported by getpwuid(3)
 */
#define _GNU_SOURCE
#include <dlfcn.h>
#include <pwd.h>
#include <stddef.h>
#include <stdlib.h>
#include <string.h>

static const char kOverrideShell[] = "/run/current-system/sw/bin/bash";

/* Lazily drop our own .so from LD_PRELOAD at first lookup so that children
   don't inherit the override, but other preloads survive. */
static void strip_self_from_preload(void) {
  static int stripped;
  if (stripped)
    return;
  stripped = 1;

  Dl_info info;
  if (dladdr((void *)&strip_self_from_preload, &info) == 0 ||
      info.dli_fname == NULL)
    return;

  const char *cur = getenv("LD_PRELOAD");
  if (cur == NULL || cur[0] == '\0')
    return;

  /* Entries are separated by whitespace or colons; drop tokens equal to our
     own path and keep the rest. */
  const size_t fname_len = strlen(info.dli_fname);
  char *filtered = malloc(strlen(cur) + 1);
  char *dst = filtered;
  const char *src = cur;
  while (*src != '\0') {
    while (*src == ':' || *src == ' ' || *src == '\t')
      src++;
    if (*src == '\0')
      break;
    const char *tok = src;
    while (*src != '\0' && *src != ':' && *src != ' ' && *src != '\t')
      src++;
    const size_t tok_len = (size_t)(src - tok);
    if (tok_len != fname_len || strncmp(tok, info.dli_fname, tok_len) != 0) {
      if (dst != filtered)
        *dst++ = ':';
      memcpy(dst, tok, tok_len);
      dst += tok_len;
    }
  }
  *dst = '\0';

  if (dst == filtered)
    unsetenv("LD_PRELOAD");
  else
    setenv("LD_PRELOAD", filtered, 1);
  free(filtered);
}

/* Interpose the non-reentrant getpwuid(3). */
struct passwd *getpwuid(uid_t uid) {
  static struct passwd *(*real_getpwuid)(uid_t) = NULL;
  if (real_getpwuid == NULL)
    real_getpwuid = (struct passwd * (*)(uid_t)) dlsym(RTLD_NEXT, "getpwuid");

  strip_self_from_preload();

  struct passwd *pw = real_getpwuid(uid);
  if (pw != NULL)
    pw->pw_shell = (char *)kOverrideShell;
  return pw;
}

/* Interpose the reentrant getpwuid_r(3). */
int getpwuid_r(uid_t uid, struct passwd *pwd, char *buf, size_t buflen,
               struct passwd **result) {
  static int (*real_getpwuid_r)(uid_t, struct passwd *, char *, size_t,
                                struct passwd **) = NULL;
  if (real_getpwuid_r == NULL)
    real_getpwuid_r = (int (*)(uid_t, struct passwd *, char *, size_t,
                               struct passwd **))dlsym(RTLD_NEXT, "getpwuid_r");

  strip_self_from_preload();

  int rc = real_getpwuid_r(uid, pwd, buf, buflen, result);
  if (rc == 0 && *result != NULL)
    (*result)->pw_shell = (char *)kOverrideShell;
  return rc;
}
