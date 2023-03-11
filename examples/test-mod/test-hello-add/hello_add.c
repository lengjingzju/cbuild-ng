#include <linux/module.h>
#include <linux/init.h>

// 模块导出符号
int test_add(int a, int b)
{
    return a + b;
}
EXPORT_SYMBOL(test_add);

// 模块加载函数
static int __init hello_init(void)
{
    int a = 10, b = 20;
    printk("hello_add: %d + %d = %d --> module_init.\n", a, b, test_add(a, b));
    return 0;
}
module_init(hello_init);

// 模块卸载函数
static void __exit hello_exit(void)
{
    int a = 1, b = 8;
    printk("hello_add: %d + %d = %d --> module_exit.\n", a, b, test_add(a, b));
}
module_exit(hello_exit);

MODULE_AUTHOR("lengjing <lengjingzju@163.com>");
MODULE_DESCRIPTION("A simple module for add");

// 模块许可证声明
MODULE_LICENSE("GPL v2");
