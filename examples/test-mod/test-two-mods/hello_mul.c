#include <linux/module.h>

int test_mul(int a, int b)
{
    return a * b;
}

EXPORT_SYMBOL(test_mul);

