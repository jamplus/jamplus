#if _MSC_VER
__declspec(dllimport) void ExportA();
__declspec(dllimport) void ExportB();
#endif

void ExportA();
void ExportB();

int main()
{
	ExportA();
	ExportB();
}
