if (NOT WIN32 AND NOT CYGWIN)
  set(PluginName KashirinMulToBitShiftPlugin)

  file(GLOB_RECURSE ALL_SOURCE_FILES *.cpp *.h)
  add_llvm_pass_plugin(${PluginName} 
  ${ALL_SOURCE_FILES}     
  DEPENDS
  intrinsics_gen
  BUILDTREE_ONLY)

  set(LLVM_TEST_DEPENDS ${PluginName} ${LLVM_TEST_DEPENDS} PARENT_SCOPE)
endif()