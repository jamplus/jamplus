__declspec(dllimport) void ExportA();
__declspec(dllimport) void ExportB();

int main()
{
	ExportA();
	ExportB();
}
