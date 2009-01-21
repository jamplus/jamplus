#if _MSC_VER
__declspec(dllimport) void ExportA();
__declspec(dllimport) void ExportB();
#endif

int main()
{
	ExportA();
	ExportB();
}
