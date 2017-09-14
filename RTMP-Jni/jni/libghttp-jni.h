#include <unistd.h>
#include <stdlib.h>
#include "../libghttp/jni/ghttp.h"

#define DEV  1
#define TEST2 0
#define UAT   0
#define PROD  0

#ifndef bool
#define bool int
#endif

#ifndef true
#define true 1
#endif

#ifndef false
#define false 0
#endif

int64_t getAbsTime();
