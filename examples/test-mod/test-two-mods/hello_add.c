#include <linux/module.h>

int test_add(int a, int b)
{
    return a + b;
}

EXPORT_SYMBOL(test_add);

