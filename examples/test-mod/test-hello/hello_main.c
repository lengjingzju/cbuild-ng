#include <linux/module.h>
#include <linux/init.h>
#include "hello_main.h"

// 模块参数
static int num = 0;
module_param(num, int, 0644);
MODULE_PARM_DESC(num, "You can use 'num' to change num value");


// 模块导出符号
void hello_set_param(int n)
{
    printk("%s from %d to %d.\n", __func__, num, n);
    num = n;
}
EXPORT_SYMBOL(hello_set_param);

// 模块加载函数
static int __init hello_init(void)
{
    int a = 99, b = 24;
    printk("Hello World! --> module_init.\n");
    printk("num=%d! --> module_param.\n", num);
    printk("%d + %d = %d\n", a, b, test_add(a, b));
    printk("%d - %d = %d\n", a, b, test_sub(a, b));
    printk("%d * %d = %d\n", a, b, test_mul(a, b));
    printk("%d / %d = %d\n", a, b, test_div(a, b));
    return 0;
}
module_init(hello_init);

// 模块卸载函数
static void __exit hello_exit(void)
{
    printk("Hello World! --> module_exit.\n");
}
module_exit(hello_exit);

MODULE_AUTHOR("lengjing <lengjingzju@163.com>");
MODULE_DESCRIPTION("A simple module depends on hello_add.ko and hello_sub.ko.");

// 模块许可证声明
MODULE_LICENSE("GPL v2");
