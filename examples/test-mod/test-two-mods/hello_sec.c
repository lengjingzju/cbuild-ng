#include <linux/module.h>
#include <linux/init.h>

// 模块加载函数
static int __init hello_init(void)
{
    printk("Hello World! --> module_init.\n");
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
MODULE_DESCRIPTION("A simple Hello World module.");

// 模块许可证声明
MODULE_LICENSE("GPL v2");
