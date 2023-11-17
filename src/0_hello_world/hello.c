#include <linux/module.h>
#include <linux/kernel.h>

static int __init hello_world_init(void)
{
	pr_info("%s done\n", __func__);
	return 0;
}

static void __exit hello_world_exit(void)
{
	pr_info("%s done\n", __func__);
}

module_init(hello_world_init);
module_exit(hello_world_exit);

MODULE_LICENSE("GPL");
MODULE_AUTHOR("junan <junan76@163.com>");
MODULE_DESCRIPTION("The hello_world kernel module");