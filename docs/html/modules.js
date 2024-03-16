var modules =
[
    [ "Introduction", "modules.html#modules_intro", null ],
    [ "List of Jam Modules", "modules.html#modules_list", [
      [ "General Modules", "modules.html#modules_general_list", null ],
      [ "C/C++ Support Modules", "modules.html#modules_c_support_list", null ],
      [ "C# Support Modules", "modules.html#modules_csharp_support_list", null ],
      [ "Platform Support Modules", "modules.html#modules_platform_support_list", null ]
    ] ],
    [ "Directory Copy Rules", "module_copydirectory.html", [
      [ "List of Rules", "module_copydirectory.html#module_copydirectory_ruleslist", null ],
      [ "Rules", "module_copydirectory.html#module_copydirectory_rules", null ],
      [ "rule CopyDirectory PARENTS : DESTINATION_PATH : SOURCE_PATH [ : SEARCH_STRING ]", "module_copydirectory.html#rule_CopyDirectory", null ]
    ] ],
    [ "File Copy Rules", "module_copyfile.html", [
      [ "List of Rules", "module_copyfile.html#module_copyfile_ruleslist", null ],
      [ "Rules", "module_copyfile.html#module_copyfile_rules", null ],
      [ "rule CopyFile PARENTS : TARGET : SOURCE", "module_copyfile.html#rule_CopyFile", null ]
    ] ],
    [ "C++/CLI Rules", "module_hardsoftlink.html", [
      [ "List of Rules", "module_hardsoftlink.html#module_hardsoftlink_ruleslist", null ],
      [ "Rules", "module_hardsoftlink.html#module_hardsoftlink_rules", null ],
      [ "rule HardLink PARENT : TARGET : SOURCE", "module_hardsoftlink.html#rule_HardLink", null ],
      [ "rule SoftLink PARENT : TARGET : SOURCE", "module_hardsoftlink.html#rule_SoftLink", null ]
    ] ],
    [ "C/C++ Rules", "module_c.html", "module_c" ],
    [ "c/directx - C/C++ DirectX Rules", "module_c_directx.html", [
      [ "List of Rules", "module_c_directx.html#module_c_directx_ruleslist", null ],
      [ "Rules", "module_c_directx.html#module_c_directx_rules", null ],
      [ "rule C.UseDirectX TARGET [ : OPTIONS ]", "module_c_directx.html#rule_C_UseDirectX", null ]
    ] ],
    [ "c/dotnet - C++/CLI Rules", "module_c_dotnet.html", [
      [ "List of Rules", "module_c_dotnet.html#module_c_dotnet_ruleslist", null ],
      [ "Rules", "module_c_dotnet.html#module_c_dotnet_rules", null ],
      [ "rule C.ReferenceDirectories TARGET : DIRECTORIES : THE_CONFIG : THE_PLATFORM", "module_c_dotnet.html#rule_C_ReferenceDirectories", null ],
      [ "rule C.StrongName TARGET : SNK_NAME", "module_c_dotnet.html#rule_C_StrongName", null ],
      [ "rule C.UseDotNet TARGET [ : OPTIONS ]", "module_c_dotnet.html#rule_C_UseDotNet", null ]
    ] ],
    [ "c/mfc - C++ MFC Rules", "module_c_mfc.html", [
      [ "List of Rules", "module_c_mfc.html#module_c_mfc_ruleslist", null ],
      [ "Rules", "module_c_mfc.html#module_c_mfc_rules", null ],
      [ "rule C.UseMFC TARGET [ : OPTIONS ]", "module_c_mfc.html#rule_C_UseMFC", null ]
    ] ],
    [ "c/midl - IDL Rules", "module_c_midl.html", [
      [ "List of Rules", "module_c_midl.html#module_c_midl_ruleslist", null ],
      [ "Rules", "module_c_midl.html#module_c_midl_rules", null ],
      [ "rule C.MidlCompiler PARENT : SOURCE", "module_c_midl.html#rule_C_MidlCompiler", null ],
      [ "rule C.MidlFlags PARENT : BASE_NAME [ : OPTIONS ]", "module_c_midl.html#rule_C_MidlFlags", null ]
    ] ],
    [ "Win32 Resource Support", "module_c_win32resource.html", [
      [ "List of Rules", "module_c_win32resource.html#module_c_win32resource_ruleslist", null ],
      [ "Rules", "module_c_win32resource.html#module_c_win32resource_rules", null ],
      [ "rule C.RcDefines TARGET [ : RESOURCE_NAME ] : DEFINES", "module_c_win32resource.html#rule_C_RcDefines", null ],
      [ "rule C.RcFlags TARGET [ : RESOURCE_NAME ] : FLAGS", "module_c_win32resource.html#rule_C_RcFlags", null ],
      [ "rule C.RcIncludeDirectories TARGET [ : RESOURCE_NAME ] : HDRS", "module_c_win32resource.html#rule_C_RcIncludeDirectories", null ],
      [ "rule C.ResourceCompiler PARENT : SOURCES [ : OPTIONS ]", "module_c_win32resource.html#rule_C_ResourceCompiler", null ]
    ] ],
    [ "c/wxwidgets - C++ wxWidgets Rules", "module_c_wxwidgets.html", [
      [ "List of Rules", "module_c_wxwidgets.html#module_c_wxwidgets_ruleslist", null ],
      [ "Rules", "module_c_wxwidgets.html#module_c_wxwidgets_rules", null ],
      [ "rule C.UseWxWidgets TARGETS : COMPONENTS [ : OPTIONS ]", "module_c_wxwidgets.html#rule_C_UseWxWidgets", null ]
    ] ],
    [ "C# Rules", "module_csharp.html", [
      [ "List of Rules", "module_csharp.html#module_csharp_ruleslist", null ],
      [ "Rules", "module_csharp.html#module_csharp_rules", null ],
      [ "rule CSharp.CscDefines TARGET : DEFINES [ : THE_CONFIG ]", "module_csharp.html#rule_CSharp_CscDefines", null ],
      [ "rule CSharp.CscFlags TARGET : FLAGS [ : THE_CONFIG ]", "module_csharp.html#rule_CSharp_CscFlags", null ],
      [ "rule CSharp.Application TARGET : SOURCES [ : OPTIONS ]", "module_csharp.html#rule_CSharp_Application", null ],
      [ "rule CSharp.Assembly TARGET : SOURCES [ : OPTIONS ]", "module_csharp.html#rule_CSharp_Assembly", null ],
      [ "rule CSharp.Library TARGET : SOURCES [ : OPTIONS ]", "module_csharp.html#rule_CSharp_Library", null ],
      [ "rule CSharp.ReferenceAssemblies TARGET : ASSEMBLIES [ : THE_CONFIG ]", "module_csharp.html#rule_CSharp_ReferenceAssemblies", null ],
      [ "rule CSharp.ReferencePaths TARGET : PATHS [ : THE_CONFIG ]", "module_csharp.html#rule_CSharp_ReferencePaths", null ]
    ] ],
    [ "Android Rules", "module_android.html", [
      [ "List of Rules", "module_android.html#module_android_ruleslist", null ],
      [ "Rules", "module_android.html#module_android_rules", null ],
      [ "rule android.Application TARGET : SOURCES", "module_android.html#rule_android_Application", null ],
      [ "rule android.Assets TARGET : DIRECTORY", "module_android.html#rule_android_Assets", null ],
      [ "rule android.JarDirectories TARGET : DIRECTORIES", "module_android.html#rule_android_JarDirectories", null ],
      [ "rule android.Library TARGET : SOURCES : OPTIONS", "module_android.html#rule_android_Library", null ],
      [ "rule android.LinkJars TARGET : LIBRARIES", "module_android.html#rule_android_LinkJars", null ],
      [ "rule android.Manifest TARGET : MANIFEST", "module_android.html#rule_android_Manifest", null ],
      [ "rule android.NativeLibraries TARGET : NATIVE_LIBRARIES", "module_android.html#rule_android_NativeLibraries", null ],
      [ "rule android.NativePrebuiltLibraries TARGET : NATIVE_PREBUILT_LIBRARIES", "module_android.html#rule_android_NativePrebuiltLibraries", null ],
      [ "rule android.NativePrebuiltLibraryDirectories TARGET : DIRECTORIES", "module_android.html#rule_android_NativePrebuiltLibraryDirectories", null ],
      [ "rule android.Package TARGET [ : TOOLCHAINS [ : OPTIONS ] ]", "module_android.html#rule_android_Package", null ],
      [ "rule android.PackageName TARGET : PACKAGE_NAME", "module_android.html#rule_android_PackageName", null ],
      [ "rule android.PackageOutputPath TARGET : PACKAGE_OUTPUT_PATH", "module_android.html#rule_android_PackageOutputPath", null ],
      [ "rule android.PrebuiltAars TARGET : LIBRARIES", "module_android.html#rule_android_PrebuiltAars", null ],
      [ "rule android.PrebuiltJars TARGET : LIBRARIES", "module_android.html#rule_android_PrebuiltJars", null ],
      [ "rule android.ProductVersion TARGET : VERSION_NAME : VERSION_CODE", "module_android.html#rule_android_ProductVersion", null ],
      [ "rule android.Resources TARGET : DIRECTORIES", "module_android.html#rule_android_Resources", null ],
      [ "rule android.SDK SDK_VERSION : ARCHITECTURE", "module_android.html#rule_android_SDK", null ],
      [ "rule android.SDKCompileVersion TARGET : SDK_COMPILE_VERSION", "module_android.html#rule_android_SDKCompileVersion", null ],
      [ "rule android.SDKMinimumVersion TARGET : SDK_MINIMUM_VERSION", "module_android.html#rule_android_SDKMinimumVersion", null ],
      [ "rule android.Sign TARGET : KEYSTORE_PATH_PASSWORD_KEY", "module_android.html#rule_android_Sign", null ],
      [ "rule android.SourcePaths TARGET : DIRECTORIES", "module_android.html#rule_android_SourcePaths", null ],
      [ "rule android.UncompressedAssetExtensions TARGET : UNCOMPRESSED_ASSET_EXTENSIONS", "module_android.html#rule_android_UncompressedAssetExtensions", null ]
    ] ],
    [ "iOS Rules", "module_ios.html", [
      [ "List of Rules", "module_ios.html#module_ios_ruleslist", null ],
      [ "Rules", "module_ios.html#module_ios_rules", null ],
      [ "rule C.ios.FrameworkDirectories TARGET : DIRECTORIES", "module_ios.html#rule_C_ios_FrameworkDirectories", null ],
      [ "rule C.ios.LinkFrameworks TARGET : FRAMEWORKS", "module_ios.html#rule_C_ios_LinkFrameworks", null ],
      [ "rule C.ios.WeakLinkFrameworks TARGET : FRAMEWORKS", "module_ios.html#rule_C_ios_WeakLinkFrameworks", null ],
      [ "rule ios.Archive TARGET : OUTPUT_PATH : ITUNES_ARTWORK : OPTIONS", "module_ios.html#rule_ios_Archive", null ],
      [ "rule ios.AssetCatalog TARGET : ASSET_CATALOG_PATH ;", "module_ios.html#rule_ios_AssetCatalog", null ],
      [ "rule ios.Bundle TARGET [ : TOOLCHAINS ]", "module_ios.html#rule_ios_Bundle", null ],
      [ "rule ios.BundleInfoArrayBegin TARGET : KEY", "module_ios.html#rule_ios_BundleInfoArrayBegin", null ],
      [ "rule ios.BundleInfoArrayBoolean TARGET : KEY : VALUE : NO_OVERRIDE", "module_ios.html#rule_ios_BundleInfoArrayBoolean", null ],
      [ "rule ios.BundleInfoArrayDictBegin TARGET", "module_ios.html#rule_ios_BundleInfoArrayDictBegin", null ],
      [ "rule C.ios.BundleInfoArrayDictEnd TARGET", "module_ios.html#rule_ios_BundleInfoArrayDictEnd", null ],
      [ "rule ios.BundleInfoArrayEnd TARGET", "module_ios.html#rule_ios_BundleInfoArrayEnd", null ],
      [ "rule ios.BundleInfoArrayInteger TARGET : KEY : VALUE : NO_OVERRIDE", "module_ios.html#rule_ios_BundleInfoArrayInteger", null ],
      [ "rule ios.BundleInfoArrayString TARGET : KEY : VALUE : NO_OVERRIDE", "module_ios.html#rule_ios_BundleInfoArrayString", null ],
      [ "rule ios.BundleInfoBoolean TARGET : KEY : VALUE : NO_OVERRIDE", "module_ios.html#rule_ios_BundleInfoBoolean", null ],
      [ "rule ios.BundleInfoDictBegin TARGET : KEY", "module_ios.html#rule_ios_BundleInfoDictBegin", null ],
      [ "rule ios.BundleInfoDictEnd TARGET", "module_ios.html#rule_ios_BundleInfoDictEnd", null ],
      [ "rule ios.BundleInfoInteger TARGET : KEY : VALUE : NO_OVERRIDE", "module_ios.html#rule_ios_BundleInfoInteger", null ],
      [ "rule ios.BundleInfoString TARGET : KEY : VALUE : NO_OVERRIDE", "module_ios.html#rule_ios_BundleInfoString", null ],
      [ "rule ios.BundleInfo TARGET : KEY : VALUE : NO_OVERRIDE", "module_ios.html#rule_ios_BundleInfo", null ],
      [ "rule ios.BundlePath TARGET : BUNDLE_PATH", "module_ios.html#rule_ios_BundlePath", null ],
      [ "rule ios.CodeSign TARGET : SIGNING_IDENTITY : CERTIFICATE_CHAIN", "module_ios.html#rule_ios_CodeSign", null ],
      [ "rule ios.GetBundlePath TARGET", "module_ios.html#rule_ios_GetBundlePath", null ],
      [ "rule ios.GetBundleTarget TARGET", "module_ios.html#rule_ios_GetBundleTarget", null ],
      [ "rule ios.InfoPListFile TARGET : SOURCE", "module_ios.html#rule_ios_InfoPListFile", null ],
      [ "rule C.ios.Lipo TARGET : LINK_TARGETS : OUTPUT_PATH", "module_ios.html#rule_C_ios_Lipo", null ],
      [ "rule ios.MergeInfoPList TARGET : SOURCE", "module_ios.html#rule_ios_MergeInfoPList", null ],
      [ "rule ios.MinimumOSVersion TARGET : SDK_VERSION_MIN", "module_ios.html#rule_ios_MinimumOSVersion", null ],
      [ "rule ios.ProvisionFile TARGET : FILENAME", "module_ios.html#rule_ios_ProvisionFile", null ],
      [ "rule ios.Provision TARGET : PROFILE_ID", "module_ios.html#rule_ios_Provision", null ],
      [ "rule ios.SDK SDK_VERSION", "module_ios.html#rule_ios_SDK", null ],
      [ "rule ios.Storyboards TARGET : LANGUAGE_DIRECTORY [ : STORYBOARD_FILES ]", "module_ios.html#rule_ios_Storyboards", null ],
      [ "rule ios.WebServer TARGET", "module_ios.html#rule_ios_WebServer", null ]
    ] ]
];