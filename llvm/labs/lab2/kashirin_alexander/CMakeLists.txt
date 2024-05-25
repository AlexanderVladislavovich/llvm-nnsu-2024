set(PluginName KashirinBitShiftPlugin)

if (NOT WIN32 AND NOT CYGWIN)
  file(GLOB_RECURSE ALL_SOURCE_FILES *.cpp *.h *.hpp)
  
  add_llvm_pass_plugin(${PluginName} 
    ${ALL_SOURCE_FILES}     
    DEPENDS
    intrinsics_gen
    BUILDTREE_ONLY
    )

  target_link_libraries(${PluginName}
    PUBLIC
    LLVMSupport
    LLVMCore
    LLVMipo
    LLVMPasses
    )

  set(LLVM_TEST_DEPENDS ${PluginName} ${LLVM_TEST_DEPENDS} PARENT_SCOPE)
endif()