//OPIS: case primer
//RETURN: 2

int main()
{
	int a;
	int s;
	a = 20;
	
	switch(a) 
	{
		case 10: { s = 1; } break;
		case 20: s = 2;
		default: s = 0;
	}
	
	switch(a)
	{
		case 10: s = 5; break;
		case 20: s = 30;
		case 30: s = 20;
	}
	
	return s;
}
