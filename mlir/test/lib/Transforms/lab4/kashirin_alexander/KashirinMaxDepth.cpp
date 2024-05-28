#include "mlir/Dialect/Func/IR/FuncOps.h"
#include "mlir/Dialect/LLVMIR/LLVMDialect.h"
#include "mlir/Dialect/SCF/IR/SCF.h"
#include "mlir/IR/BuiltinOps.h"
#include "mlir/IR/Operation.h"
#include "mlir/IR/PatternMatch.h"
#include "mlir/IR/Region.h"
#include "mlir/Pass/Pass.h"
#include "mlir/Tools/Plugins/PassPlugin.h"
#include <stack>

using namespace mlir;

namespace {
class KashirinMaxDepthPass
    : public PassWrapper<KashirinMaxDepthPass, OperationPass<func::FuncOp>> {
public:
  StringRef getArgument() const final { return "KashirinMaxDepthPass"; }
  StringRef getDescription() const final {
    return "Counts the max depth of region nests in the function.";
  }
  void runOnOperation() override {
    getOperation()->walk([&](Operation *op) {
      std::stack<std::pair<Operation *, int>> stack;
      stack.push({op, 0});
      int maxDepth = 0;
      while (!stack.empty()) {
        auto [currentOp, depth] = stack.top();
        stack.pop();
        maxDepth = std::max(maxDepth, depth);
        for (Region &region : currentOp->getRegions()) {
          for (Block &block : region) {
            for (Operation &op2 : block) {
              stack.push({&op2, depth + 1});
            }
          }
        }
      }
      op->setAttr(
          "maxDepth",
          IntegerAttr::get(IntegerType::get(op->getContext(), 32), maxDepth));
    });
  }
};
} // namespace

MLIR_DECLARE_EXPLICIT_TYPE_ID(KashirinMaxDepthPass)
MLIR_DEFINE_EXPLICIT_TYPE_ID(KashirinMaxDepthPass)

PassPluginLibraryInfo getFunctionCallCounterPassPluginInfo() {
  return {MLIR_PLUGIN_API_VERSION, "KashirinMaxDepthPass", LLVM_VERSION_STRING,
          []() { PassRegistration<KashirinMaxDepthPass>(); }};
}

extern "C" LLVM_ATTRIBUTE_WEAK PassPluginLibraryInfo mlirGetPassPluginInfo() {
  return getFunctionCallCounterPassPluginInfo();
}