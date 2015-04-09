/* context.cc

   Copyright 2015 Red Hat, Inc.

This file is part of Cygwin.

This software is a copyrighted work licensed under the terms of the
Cygwin license.  Please consult the file "CYGWIN_LICENSE" for
details. */

#define CYGTLS_HANDLE
#include "winsup.h"
#include "cygtls.h"

#include <ucontext.h>
#include <stdarg.h>

// XXX: define SIGSTKSZ somewhere

//
// XXX: MSDN says you should not call Get/SetThreadContext() on any running
// thread.  Calling it on the *current* thread (which must be running) seems to
// work, though, and we rely on that here.
//

//
// transfer control to the context ucp (which was created by getcontext(),
// makecontext() or a signal handler)
//
// does not return if successful
//
int setcontext(const ucontext_t *ucp)
{
  if (ucp == NULL)
    return -1;

  // XXX:set stack???
  // XXX:set sigmask

  SetThreadContext(GetCurrentThread(), (CONTEXT *)&(ucp->uc_mcontext));

  return -1;
}

//
// save current context into ucp
//
int getcontext(ucontext_t *ucp)
{
  if (ucp == NULL)
    return -1;

  ucp->uc_link = 0;
  ucp->uc_flags = 0;
  ucp->uc_sigmask = ucp->uc_mcontext.oldmask = _my_tls.sigmask;
  ucp->uc_mcontext.cr2 = 0;

  ucp->uc_stack.ss_sp = 0;
  ucp->uc_stack.ss_flags = 0;
  ucp->uc_stack.ss_size = 0;

  memset(&(ucp->uc_mcontext), 0, sizeof(struct __mcontext));
  ucp->uc_mcontext.ctxflags = CONTEXT_FULL;
  int result = GetThreadContext (GetCurrentThread(), (CONTEXT *)&(ucp->uc_mcontext));

  return result ? 0 : -1;
}

static
void makecontext_return(void)
{
  // XXX: find ucp->uc_link up the stack ???
  // find it in the tls ???

  pthread_exit(NULL);
}

//
// modify the context ucp for an alternate flow of control
//
// ucp.uc_stack is already modified to a newly allocated stack
// ucp_uc_link is already modified to identify a successor context
//
void makecontext(ucontext_t *ucp, void *(func)(), int argc, ... /* integer arguments */)
{
  if ((ucp == NULL) || ucp->uc_stack.ss_sp == NULL)
      return;

  __stack_t *sp = (__stack_t *)((char *)ucp->uc_stack.ss_sp + ucp->uc_stack.ss_size);
#ifdef __x86_64__
  // x86_64 calling convention always allocates 32 bytes of "shadow space" on
  // stack for first 4 args (which are passed in registers)
  int arg_size = (argc < 4) ? 32  : argc*sizeof(int);
#else
  int arg_size = argc*sizeof(int);
#endif

  // compute where on stack we will put the function arguments
  sp -= arg_size;

  // is there room on the stack for arguments?
  if (sp < ucp->uc_stack.ss_sp)
    {
      errno = ENOMEM;
      return;
    }

#ifdef __x86_64__
  ucp->uc_mcontext.rip = (__uint64_t)func;
  ucp->uc_mcontext.rsp =  (__uint64_t)(sp - 1);
#else
  // XXX:
#endif

  // if and when func returns, we should transfer control to the context
  // ucp->uc_link, or if that is NULL, exit the thread
  *sp = (uintptr_t)makecontext_return;

  // copy the arguments onto the context's stack
  va_list ap;
  va_start(ap, argc);
  for (int i = 0; i < argc; i++)
    {
      int a = va_arg(ap, int);
      memcpy(sp, &a, sizeof(int));
#ifdef __x86_64__
      switch (i)
	{
	case 0:
	  ucp->uc_mcontext.rcx = a;
	  break;
	case 1:
	  ucp->uc_mcontext.rdx = a;
	  break;
	case 2:
	  ucp->uc_mcontext.r8 = a;
	  break;
	case 3:
	  ucp->uc_mcontext.r9 = a;
	  break;
	default:
	  break;
	}
#endif
      sp += sizeof(int);
    }
  va_end(ap);
}

//
// save current context in oucp, then transfer control to context ucp
//
int swapcontext(ucontext_t *oucp, const ucontext_t *ucp)
{
  if ((oucp == NULL) || (ucp == NULL))
    return -1;

  int result = getcontext(oucp);
  if (result)
    return result;

  if (oucp->uc_flags)
    return 0;

  // modify the saved context so when we transfer control back to it, we will
  // return from swapcontext, rather than continuing into setcontext() again...
  oucp->uc_flags = 1;

  return setcontext(ucp);
}
