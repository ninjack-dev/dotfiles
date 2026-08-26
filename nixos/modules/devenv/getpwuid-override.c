/*
 * getpwuid-override.c - force the login shell reported by getpwuid(3)
 */
#define _GNU_SOURCE
#include <dlfcn.h>
#include <pwd.h>
#include <stddef.h>
#include <stdio.h>
#include <stdlib.h>

static const char kOverrideShell[] = "/run/current-system/sw/bin/bash";

/* Interpose the non-reentrant getpwuid(3). */
struct passwd *getpwuid(uid_t uid)
{
  static struct passwd *(*real_getpwuid)(uid_t) = NULL;
  if (real_getpwuid == NULL)
    real_getpwuid = (struct passwd *(*)(uid_t))dlsym(RTLD_NEXT, "getpwuid");

  struct passwd *pw = real_getpwuid(uid);
  if (pw != NULL)
    pw->pw_shell = (char *)kOverrideShell;
  return pw;
}

/* Interpose the reentrant getpwuid_r(3). */
int getpwuid_r(uid_t uid, struct passwd *pwd, char *buf, size_t buflen,
               struct passwd **result)
{
  static int (*real_getpwuid_r)(uid_t, struct passwd *, char *, size_t,
                                struct passwd **) = NULL;
  if (real_getpwuid_r == NULL)
    real_getpwuid_r = (int (*)(uid_t, struct passwd *, char *, size_t,
                               struct passwd **))dlsym(RTLD_NEXT,
                                                       "getpwuid_r");

  int rc = real_getpwuid_r(uid, pwd, buf, buflen, result);
  if (rc == 0 && *result != NULL)
    (*result)->pw_shell = (char *)kOverrideShell;
  return rc;
}

__attribute__((constructor))
static void strip_preload(void)
{
  unsetenv("LD_PRELOAD");
}
