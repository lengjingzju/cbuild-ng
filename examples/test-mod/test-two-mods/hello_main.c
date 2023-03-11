#include <linux/module.h>
#include <linux/init.h>

extern int test_add(int a, int b);
extern int test_sub(int a, int b);
extern int test_mul(int a, int b);
extern int test_div(int a, int b);

// 模块加载函数
static int __init hello_init(void)
{
    int a = 99, b = 24;
    printk("Hello Operation! --> module_init.\n");
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
    printk("Hello Operation! --> module_exit.\n");
}
module_exit(hello_exit);

MODULE_AUTHOR("lengjing <lengjingzju@163.com>");
MODULE_DESCRIPTION("A simple operation module.");

// 模块许可证声明
MODULE_LICENSE("GPL v2");
