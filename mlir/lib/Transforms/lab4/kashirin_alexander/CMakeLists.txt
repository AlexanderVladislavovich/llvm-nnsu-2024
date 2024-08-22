set(PluginNames KashirinMaxDepthPass KashirinMaxDepthPassLLVMfunc)

file(GLOB_RECURSE ALL_SOURCE_FILES *.cpp *.h)

foreach(PluginName ${PluginNames})
    add_llvm_pass_plugin(${PluginName}
            ${ALL_SOURCE_FILES}
            DEPENDS
            intrinsics_gen
            MLIRBuiltinLocationAttributesIncGen
            BUILDTREE_ONLY
            )
    set(MLIR_TEST_DEPENDS ${PluginName} ${MLIR_TEST_DEPENDS} PARENT_SCOPE)
endforeach()