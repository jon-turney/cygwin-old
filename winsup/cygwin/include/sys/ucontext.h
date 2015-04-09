/* ucontext.h

   Copyright 2015 Red Hat, Inc.

This file is part of Cygwin.

This software is a copyrighted work licensed under the terms of the
Cygwin license.  Please consult the file "CYGWIN_LICENSE" for
details. */

#ifndef _SYS_UCONTEXT_H_
#define _SYS_UCONTEXT_H_

#include <signal.h>

typedef struct __mcontext mcontext_t;

typedef __attribute__ ((aligned (16))) struct __ucontext {
	mcontext_t	uc_mcontext;
	struct __ucontext *uc_link;
	sigset_t	uc_sigmask;
	stack_t	uc_stack;
	unsigned long int	uc_flags;
} ucontext_t;

#ifdef __cplusplus
extern "C" {
#endif

int getcontext(ucontext_t *ucp);
int setcontext(const ucontext_t *ucp);
void makecontext(ucontext_t *ucp, void (*func)(), int argc, ...);
int swapcontext(ucontext_t *oucp, const ucontext_t *ucp);

#ifdef __cplusplus
}
#endif

#endif /* !_SYS_UCONTEXT_H_ */
