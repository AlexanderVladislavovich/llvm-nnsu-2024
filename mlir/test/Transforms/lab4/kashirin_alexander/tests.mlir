// RUN: split-file %s %t
// RUN: mlir-opt -load-pass-plugin=%mlir_lib_dir/KashirinMaxDepthPass%shlibext --pass-pipeline="builtin.module(func.func(KashirinMaxDepthPass))" %t/func1.mlir | FileCheck %t/func1.mlir
// RUN: mlir-opt -load-pass-plugin=%mlir_lib_dir/KashirinMaxDepthPass%shlibext --pass-pipeline="builtin.module(func.func(KashirinMaxDepthPass))" %t/func2.mlir | FileCheck %t/func2.mlir
// RUN: mlir-opt -load-pass-plugin=%mlir_lib_dir/KashirinMaxDepthPass%shlibext --pass-pipeline="builtin.module(func.func(KashirinMaxDepthPass))" %t/func3.mlir | FileCheck %t/func3.mlir
// RUN: mlir-opt -load-pass-plugin=%mlir_lib_dir/KashirinMaxDepthPassLLVMfunc%shlibext --pass-pipeline="builtin.module(llvm.func(KashirinMaxDepthPassLLVMfunc))" %t/func4.mlir | FileCheck %t/func4.mlir

//--- func1.mlir
func.func @func1(%arg0: i32) -> i32 {
// CHECK: func.func @func1(%arg0: i32) -> i32 attributes {maxDepth = 1 : i32}
  %0 = arith.muli %arg0, %arg0 : i32
  func.return %0 : i32
}

//--- func2.mlir
func.func @func2() {
// CHECK: func.func @func2() attributes {maxDepth = 2 : i32}
  %cond = arith.constant 1 : i1
    %0 = scf.if %cond -> (i1) {
        scf.yield %cond : i1
    } else {
        scf.yield %cond : i1
    }
    func.return
}

//--- func3.mlir
func.func @func3() {
// CHECK: func.func @func3() attributes {maxDepth = 3 : i32}
  %c3 = arith.constant 3 : i32
  %c5 = arith.constant 5 : i32
  %0 = arith.constant 0 : i32
  %1 = arith.constant 1 : i32
  %2 = arith.subi %c5, %1 : i32
  %3 = arith.subi %c3, %1 : i32
  %4 = arith.cmpi sgt, %c5, %0 : i32
  %cond = arith.constant 1 : i1
  %cond2 = arith.constant 1 : i1
  %10 = scf.if %cond  -> (i32) {
    %5 = arith.cmpi sgt, %c3, %0 : i32
    %11 = scf.if %cond2 -> (i32) {
      %6 = arith.subi %c5, %1 : i32
      %7 = arith.subi %3, %1 : i32
      scf.yield %7 : i32
    } else {
      %8 = arith.subi %3, %1 : i32
      scf.yield %8 : i32
    }
    scf.yield %11 : i32
  } else {
    scf.yield %0 : i32
  }
  func.return
}


//--- func4.mlir
llvm.func @func4() {
  // CHECK: llvm.func @func4() attributes {maxDepth = 1 : i32}
  %cond = llvm.mlir.constant(1 : i1) : i1
  llvm.cond_br %cond, ^then, ^else
^then:
  llvm.br ^cont(%cond : i1)
^else:
  llvm.br ^cont(%cond : i1)
^cont(%0: i1):
  llvm.return
}