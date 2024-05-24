add_llvm_library( rename_id_plugin MODULE Rename_Plugin.cpp PLUGIN_TOOL clang)

if(WIN32 OR CYGWIN)
    set(LLVM_LINK_COMPONENTS
            Support
    )
    clang_target_link_libraries(rename_id_plugin PRIVATE
            clangAST
            clangBasic
            clangFrontend
    )
endif()

set(CLANG_TEST_DEPS "rename_id_plugin" ${CLANG_TEST_DEPS} PARENT_SCOPE)