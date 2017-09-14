/*
 *  Copyright 2006 The WebRTC Project Authors. All rights reserved.
 *
 *  Use of this source code is governed by a BSD-style license
 *  that can be found in the LICENSE file in the root of the source
 *  tree. An additional intellectual property rights grant can be found
 *  in the file PATENTS.  All contributing project authors may
 *  be found in the AUTHORS file in the root of the source tree.
 */

// Most of this was borrowed (with minor modifications) from V8's and Chromium's
// src/base/logging.cc.

// Use the C++ version to provide __GLIBCXX__.
#include <cstdarg>
#include <cstdio>
#include <cstdlib>

#if defined(__GLIBCXX__) && !defined(__UCLIBC__)
#include <cxxabi.h>
#include <execinfo.h>
#endif

#if defined(WEBRTC_ANDROID)
#define RTC_LOG_TAG "rtc"
#include <android/log.h>  // NOLINT

#include <unwind.h>
#include <dlfcn.h>
#include <cxxabi.h>

#endif

#if defined(WEBRTC_WIN)
#include <windows.h>
#endif

#include "webrtc/base/checks.h"
#include "webrtc/base/logging.h"

#if defined(_MSC_VER)
// Warning C4722: destructor never returns, potential memory leak.
// FatalMessage's dtor very intentionally aborts.
#pragma warning(disable:4722)
#endif

namespace rtc {

void VPrintError(const char* format, va_list args) {
#if defined(WEBRTC_ANDROID)
  __android_log_vprint(ANDROID_LOG_ERROR, RTC_LOG_TAG, format, args);
#else
  vfprintf(stderr, format, args);
#endif
}

void PrintError(const char* format, ...) {
  va_list args;
  va_start(args, format);
  VPrintError(format, args);
  va_end(args);
}

#if defined(WEBRTC_ANDROID)
struct android_backtrace_state
{
    void **current;
    void **end;
};

_Unwind_Reason_Code android_unwind_callback(struct _Unwind_Context* context, 
                                            void* arg)
{
    android_backtrace_state* state = (android_backtrace_state *)arg;
    uintptr_t pc = _Unwind_GetIP(context);
    if (pc)
    {
        if (state->current == state->end) 
        {
            return _URC_END_OF_STACK;
        }
        else
        {
            *state->current++ = reinterpret_cast<void*>(pc);
        }
    }
    return _URC_NO_REASON;
}

void dump_stack(void)
{
    PrintError("android stack dump");

    const int max = 100;
    void* buffer[max];

    android_backtrace_state state;
    state.current = buffer;
    state.end = buffer + max;

    _Unwind_Backtrace(android_unwind_callback, &state);

    int count = (int)(state.current - buffer);

    for (int idx = 0; idx < count; idx++)
    {
        const void* addr = buffer[idx];
        const char* symbol = "";

        Dl_info info;
        if (dladdr(addr, &info) && info.dli_sname)
        {
            symbol = info.dli_sname;
        }
        int status = 0;
        char *demangled = __cxxabiv1::__cxa_demangle(symbol, 0, 0, &status); 
        const void *abs_addr = (const void *)((uint32_t)addr - (uint32_t)info.dli_fbase);

        PrintError("%03d: %p %s",
                idx,
                abs_addr,
                (NULL != demangled && 0 == status) ?
                demangled : symbol);

        if (NULL != demangled)
            free(demangled);
    }

    PrintError("android stack dump done");
}

#endif

// TODO(ajm): This works on Mac (although the parsing fails) but I don't seem
// to get usable symbols on Linux. This is copied from V8. Chromium has a more
// advanced stace trace system; also more difficult to copy.
void DumpBacktrace() {
#if defined(__GLIBCXX__) && !defined(__UCLIBC__)
  void* trace[100];
  int size = backtrace(trace, sizeof(trace) / sizeof(*trace));
  char** symbols = backtrace_symbols(trace, size);
  PrintError("\n==== C stack trace ===============================\n\n");
  if (size == 0) {
    PrintError("(empty)\n");
  } else if (symbols == NULL) {
    PrintError("(no symbols)\n");
  } else {
    for (int i = 1; i < size; ++i) {
      char mangled[201];
      if (sscanf(symbols[i], "%*[^(]%*[(]%200[^)+]", mangled) == 1) {  // NOLINT
        PrintError("%2d: ", i);
        int status;
        size_t length;
        char* demangled = abi::__cxa_demangle(mangled, NULL, &length, &status);
        PrintError("%s\n", demangled != NULL ? demangled : mangled);
        free(demangled);
      } else {
        // If parsing failed, at least print the unparsed symbol.
        PrintError("%s\n", symbols[i]);
      }
    }
  }
  free(symbols);
#endif
#if defined(WEBRTC_ANDROID)
	dump_stack();
#endif
}

FatalMessage::FatalMessage(const char* file, int line) {
  Init(file, line);
}

FatalMessage::FatalMessage(const char* file, int line, std::string* result) {
  Init(file, line);
  stream_ << "Check failed: " << *result << std::endl << "# ";
  delete result;
}

NO_RETURN FatalMessage::~FatalMessage() {
  fflush(stdout);
  fflush(stderr);
  stream_ << std::endl << "#" << std::endl;
  PrintError(stream_.str().c_str());
  DumpBacktrace();
  fflush(stderr);
  abort();
}

void FatalMessage::Init(const char* file, int line) {
  stream_ << std::endl << std::endl
          << "#" << std::endl
          << "# Fatal error in " << file << ", line " << line << std::endl
          << "# last system error: " << LAST_SYSTEM_ERROR << std::endl
          << "# ";
}

// MSVC doesn't like complex extern templates and DLLs.
#if !defined(COMPILER_MSVC)
// Explicit instantiations for commonly used comparisons.
template std::string* MakeCheckOpString<int, int>(
    const int&, const int&, const char* names);
template std::string* MakeCheckOpString<unsigned long, unsigned long>(
    const unsigned long&, const unsigned long&, const char* names);
template std::string* MakeCheckOpString<unsigned long, unsigned int>(
    const unsigned long&, const unsigned int&, const char* names);
template std::string* MakeCheckOpString<unsigned int, unsigned long>(
    const unsigned int&, const unsigned long&, const char* names);
template std::string* MakeCheckOpString<std::string, std::string>(
    const std::string&, const std::string&, const char* name);
#endif

}  // namespace rtc
