#include <stdio.h>
#include "main.h"

int main()
{
	int a = 99, b = 9;

	printf("%d + %d = %d\n", a, b, add(a, b));
	printf("%d - %d = %d\n", a, b, sub(a, b));

	return 0;
}
