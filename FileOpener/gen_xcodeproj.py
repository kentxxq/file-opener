#!/usr/bin/env python3
"""生成 FileOpener 的 Xcode project.pbxproj 文件"""

import os
import uuid

def gen_id():
    return uuid.uuid4().hex[:24].upper()

# 固定 UUID，方便重复生成一致的结果
IDS = {
    'project':          'AAAA000000000000000001',
    'main_group':       'AAAA000000000000000002',
    'products_group':   'AAAA000000000000000003',
    'app_target':       'AAAA000000000000000004',
    'sources_phase':    'AAAA000000000000000005',
    'resources_phase':  'AAAA000000000000000006',
    'frameworks_phase': 'AAAA000000000000000007',
    'app_product':      'AAAA000000000000000008',
    'debug_config':     'AAAA000000000000000009',
    'release_config':   'AAAA000000000000000010',
    'project_config_list': 'AAAA000000000000000011',
    'target_config_list':  'AAAA000000000000000012',
    'sources_group':    'AAAA000000000000000013',
    'lproj_en_group':   'AAAA000000000000000014',
    'lproj_zh_group':   'AAAA000000000000000015',
    'loc_strings_vargroup': 'AAAA000000000000000016',
}

LOC_STRINGS_VARGROUP = IDS['loc_strings_vargroup']

# 源文件列表
SOURCE_FILES = [
    'FileOpenerApp.swift',
    'Models.swift',
    'FileAssocService.swift',
    'L10n.swift',
    'ContentView.swift',
    'ChangeAppSheet.swift',
    'BatchReplaceSheet.swift',
]

# 为每个文件分配 file ref ID 和 build file ID
file_refs = {}
build_files = {}
for i, f in enumerate(SOURCE_FILES):
    file_refs[f] = f'BB{i:022d}'
    build_files[f] = f'BC{i:022d}'

# en/zh-Hans Localizable.strings
LOC_STRINGS_FILEREF = 'AAAA000000000000000020'
LOC_STRINGS_BUILDFILE = 'AAAA000000000000000021'
EN_STRINGS_FILEREF = 'AAAA000000000000000022'
ZH_STRINGS_FILEREF = 'AAAA000000000000000023'

TEMPLATE = '''\
// !$*UTF8*$!
{{
\tarchiveVersion = 1;
\tclasses = {{
\t}};
\tobjectVersion = 56;
\tobjects = {{

/* Begin PBXBuildFile section */
{build_file_section}
/* End PBXBuildFile section */

/* Begin PBXFileReference section */
{file_ref_section}
/* End PBXFileReference section */

/* Begin PBXFrameworksBuildPhase section */
\t\t{frameworks_phase} /* Frameworks */ = {{
\t\t\tisa = PBXFrameworksBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tfiles = (
\t\t\t);
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t}};
/* End PBXFrameworksBuildPhase section */

/* Begin PBXGroup section */
\t\t{main_group} = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
\t\t\t\t{sources_group} /* FileOpener */,
\t\t\t\t{products_group} /* Products */,
\t\t\t);
\t\t\tsourceTree = "<group>";
\t\t}};
\t\t{products_group} /* Products */ = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
\t\t\t\t{app_product} /* FileOpener.app */,
\t\t\t);
\t\t\tname = Products;
\t\t\tsourceTree = "<group>";
\t\t}};
\t\t{sources_group} /* FileOpener */ = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
{source_group_children}
\t\t\t\t{loc_strings_vargroup} /* Localizable.strings */,
\t\t\t);
\t\t\tpath = FileOpener;
\t\t\tsourceTree = "<group>";
\t\t}};
\t\t{loc_strings_vargroup} /* Localizable.strings */ = {{
\t\t\tisa = PBXVariantGroup;
\t\t\tchildren = (
\t\t\t\t{en_strings_fileref} /* en */,
\t\t\t\t{zh_strings_fileref} /* zh-Hans */,
\t\t\t);
\t\t\tname = Localizable.strings;
\t\t\tsourceTree = "<group>";
\t\t}};
/* End PBXGroup section */

/* Begin PBXNativeTarget section */
\t\t{app_target} /* FileOpener */ = {{
\t\t\tisa = PBXNativeTarget;
\t\t\tbuildConfigurationList = {target_config_list} /* Build configuration list for PBXNativeTarget "FileOpener" */;
\t\t\tbuildPhases = (
\t\t\t\t{sources_phase} /* Sources */,
\t\t\t\t{frameworks_phase} /* Frameworks */,
\t\t\t\t{resources_phase} /* Resources */,
\t\t\t);
\t\t\tbuildRules = (
\t\t\t);
\t\t\tdependencies = (
\t\t\t);
\t\t\tname = FileOpener;
\t\t\tproductName = FileOpener;
\t\t\tproductReference = {app_product} /* FileOpener.app */;
\t\t\tproductType = "com.apple.product-type.application";
\t\t}};
/* End PBXNativeTarget section */

/* Begin PBXProject section */
\t\t{project} /* Project object */ = {{
\t\t\tisa = PBXProject;
\t\t\tattributes = {{
\t\t\t\tBuildIndependentTargetsInParallel = 1;
\t\t\t\tLastSwiftUpdateCheck = 1540;
\t\t\t\tLastUpgradeCheck = 1540;
\t\t\t\tTargetAttributes = {{
\t\t\t\t\t{app_target} = {{
\t\t\t\t\t\tCreatedOnToolsVersion = 15.4;
\t\t\t\t\t}};
\t\t\t\t}};
\t\t\t}};
\t\t\tbuildConfigurationList = {project_config_list} /* Build configuration list for PBXProject "FileOpener" */;
\t\t\tcompatibilityVersion = "Xcode 14.0";
\t\t\tdevelopmentRegion = en;
\t\t\thasScannedForEncodings = 0;
\t\t\tknownRegions = (
\t\t\t\ten,
\t\t\t\tBase,
\t\t\t\t"zh-Hans",
\t\t\t);
\t\t\tmainGroup = {main_group};
\t\t\tproductRefGroup = {products_group} /* Products */;
\t\t\tprojectDirPath = "";
\t\t\tprojectRoot = "";
\t\t\ttargets = (
\t\t\t\t{app_target} /* FileOpener */,
\t\t\t);
\t\t}};
/* End PBXProject section */

/* Begin PBXResourcesBuildPhase section */
\t\t{resources_phase} /* Resources */ = {{
\t\t\tisa = PBXResourcesBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tfiles = (
\t\t\t\t{loc_strings_buildfile} /* Localizable.strings in Resources */,
\t\t\t);
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t}};
/* End PBXResourcesBuildPhase section */

/* Begin PBXSourcesBuildPhase section */
\t\t{sources_phase} /* Sources */ = {{
\t\t\tisa = PBXSourcesBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tfiles = (
{sources_files}
\t\t\t);
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t}};
/* End PBXSourcesBuildPhase section */

/* Begin XCBuildConfiguration section */
\t\t{debug_config} /* Debug */ = {{
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {{
{common_settings}
\t\t\t\tSWIFT_OPTIMIZATION_LEVEL = "-Onone";
\t\t\t}};
\t\t\tname = Debug;
\t\t}};
\t\t{release_config} /* Release */ = {{
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {{
{common_settings}
\t\t\t\tSWIFT_OPTIMIZATION_LEVEL = "-O";
\t\t\t}};
\t\t\tname = Release;
\t\t}};
/* End XCBuildConfiguration section */

/* Begin XCConfigurationList section */
\t\t{project_config_list} /* Build configuration list for PBXProject "FileOpener" */ = {{
\t\t\tisa = XCConfigurationList;
\t\t\tbuildConfigurations = (
\t\t\t\t{debug_config} /* Debug */,
\t\t\t\t{release_config} /* Release */,
\t\t\t);
\t\t\tdefaultConfigurationIsVisible = 0;
\t\t\tdefaultConfigurationName = Release;
\t\t}};
\t\t{target_config_list} /* Build configuration list for PBXNativeTarget "FileOpener" */ = {{
\t\t\tisa = XCConfigurationList;
\t\t\tbuildConfigurations = (
\t\t\t\t{debug_config} /* Debug */,
\t\t\t\t{release_config} /* Release */,
\t\t\t);
\t\t\tdefaultConfigurationIsVisible = 0;
\t\t\tdefaultConfigurationName = Release;
\t\t}};
/* End XCConfigurationList section */
\t}};
\trootObject = {project} /* Project object */;
}}
'''

def main():
    base = IDS

    # Build file section
    bf_lines = []
    for f in SOURCE_FILES:
        bf_lines.append(f'\t\t{build_files[f]} /* {f} in Sources */ = {{isa = PBXBuildFile; fileRef = {file_refs[f]} /* {f} */; }};')
    bf_lines.append(f'\t\t{LOC_STRINGS_BUILDFILE} /* Localizable.strings in Resources */ = {{isa = PBXBuildFile; fileRef = {LOC_STRINGS_VARGROUP} /* Localizable.strings */; }};')

    # File ref section
    fr_lines = []
    for f in SOURCE_FILES:
        fr_lines.append(f'\t\t{file_refs[f]} /* {f} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = {f}; sourceTree = "<group>"; }};')
    fr_lines.append(f'\t\t{IDS["app_product"]} /* FileOpener.app */ = {{isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = FileOpener.app; sourceTree = BUILT_PRODUCTS_DIR; }};')
    fr_lines.append(f'\t\t{EN_STRINGS_FILEREF} /* en */ = {{isa = PBXFileReference; lastKnownFileType = text.plist.strings; name = en; path = en.lproj/Localizable.strings; sourceTree = "<group>"; }};')
    fr_lines.append(f'\t\t{ZH_STRINGS_FILEREF} /* zh-Hans */ = {{isa = PBXFileReference; lastKnownFileType = text.plist.strings; name = "zh-Hans"; path = "zh-Hans.lproj/Localizable.strings"; sourceTree = "<group>"; }};')

    # Source group children
    sg_children = []
    for f in SOURCE_FILES:
        sg_children.append(f'\t\t\t\t{file_refs[f]} /* {f} */,')

    # Sources build phase files
    src_files = []
    for f in SOURCE_FILES:
        src_files.append(f'\t\t\t\t{build_files[f]} /* {f} in Sources */,')

    # Common build settings
    common = '''\t\t\t\tALWAYS_SEARCH_USER_PATHS = NO;
\t\t\t\tASSET_CATALOG_COMPILER_OPTIMIZATION_LEVEL = space;
\t\t\t\tCLANG_ANALYZER_NONNULL = YES;
\t\t\t\tCLANG_ANALYZER_NUMBER_OBJECT_CONVERSION = YES_AGGRESSIVE;
\t\t\t\tCLANG_CXX_LANGUAGE_STANDARD = "gnu++20";
\t\t\t\tCLANG_ENABLE_MODULES = YES;
\t\t\t\tCLANG_ENABLE_OBJC_ARC = YES;
\t\t\t\tCLANG_ENABLE_OBJC_WEAK = YES;
\t\t\t\tCOPY_PHASE_STRIP = NO;
\t\t\t\tCURRENT_PROJECT_VERSION = 1;
\t\t\t\tDEBUG_INFORMATION_FORMAT = "dwarf-with-dsym";
\t\t\t\tGCC_C_LANGUAGE_STANDARD = gnu17;
\t\t\t\tGCC_NO_COMMON_BLOCKS = YES;
\t\t\t\tINFOPLIST_FILE = FileOpener/Info.plist;
\t\t\t\tINFOPLIST_KEY_NSHumanReadableCopyright = "Copyright 2025 kentxxq. MIT License.";
\t\t\t\tINFOPLIST_KEY_NSPrincipalClass = NSApplication;
\t\t\t\tINFOPLIST_KEY_CFBundleDisplayName = "File Opener";
\t\t\t\tMACOS_DEPLOYMENT_TARGET = 14.0;
\t\t\t\tMARKETING_VERSION = 1.0;
\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = "com.kentxxq.file-opener";
\t\t\t\tPRODUCT_NAME = "$(TARGET_NAME)";
\t\t\t\tSWIFT_EMIT_LOC_STRINGS = YES;
\t\t\t\tSWIFT_VERSION = 5.0;
\t\t\t\tCODE_SIGN_STYLE = Automatic;
\t\t\t\tDEVELOPMENT_TEAM = "";
\t\t\t\tCODE_SIGNING_REQUIRED = NO;
\t\t\t\tCODE_SIGNING_ALLOWED = NO;'''

    content = TEMPLATE.format(
        build_file_section='\n'.join(bf_lines),
        file_ref_section='\n'.join(fr_lines),
        source_group_children='\n'.join(sg_children),
        sources_files='\n'.join(src_files),
        common_settings=common,
        loc_strings_buildfile=LOC_STRINGS_BUILDFILE,
        en_strings_fileref=EN_STRINGS_FILEREF,
        zh_strings_fileref=ZH_STRINGS_FILEREF,
        **IDS
    )

    out_dir = os.path.join(os.path.dirname(__file__), 'FileOpener.xcodeproj')
    os.makedirs(out_dir, exist_ok=True)
    out_path = os.path.join(out_dir, 'project.pbxproj')
    with open(out_path, 'w', encoding='utf-8') as f:
        f.write(content)
    print(f'Generated: {out_path}')

if __name__ == '__main__':
    main()
