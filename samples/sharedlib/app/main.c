#if defined(_WIN32)
__declspec(dllimport) void ExportA();
__declspec(dllimport) void ExportB();
#endif

int main()
{
	ExportA();
	ExportB();
}

