#include <linux/module.h>

int test_div(int a, int b)
{
    return a / b;
}

EXPORT_SYMBOL(test_div);

