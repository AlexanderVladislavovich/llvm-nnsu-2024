add_llvm_library(RenamePlugin MODULE RenameIds.cpp PLUGIN_TOOL clang)

if(WIN32 OR CYGWIN)
    set(LLVM_LINK_COMPONENTS
            Support
    )
    clang_target_link_libraries(RenamePlugin PRIVATE
            clangAST
            clangBasic
            clangFrontend
    )
endif()

set(CLANG_TEST_DEPS "RenamePlugin" ${CLANG_TEST_DEPS} PARENT_SCOPE)