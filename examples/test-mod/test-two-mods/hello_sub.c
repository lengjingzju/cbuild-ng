#include <linux/module.h>

int test_sub(int a, int b)
{
    return a - b;
}

EXPORT_SYMBOL(test_sub);
