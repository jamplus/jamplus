#if _MSC_VER
__declspec(dllimport) void ExportA();
#endif

int main()
{
	ExportA();
}

