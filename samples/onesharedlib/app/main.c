#if defined(_WIN32)
__declspec(dllimport) void ExportA();
#endif

int main()
{
	ExportA();
}

