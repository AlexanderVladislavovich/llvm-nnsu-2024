#include "llvm/IR/BasicBlock.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/Pass.h"
#include "llvm/Passes/PassBuilder.h"
#include "llvm/Passes/PassPlugin.h"
#include "llvm/Support/CommandLine.h"

static llvm::cl::opt<bool> MulShiftConstOnly(
    "mul-shift-const-only", llvm::cl::init(false),
    llvm::cl::desc(
        "Limit mul-to-shl replacement to constant pow_of_two operands"));

namespace {
struct BitShiftPass : llvm::PassInfoMixin<BitShiftPass> {
public:
  llvm::PreservedAnalyses run(llvm::Function &Func,
                              llvm::FunctionAnalysisManager &FAM) {
    std::vector<llvm::Instruction *> toRemove;
    bool changed = false;
    for (llvm::BasicBlock &BB : Func) {
      for (llvm::Instruction &Inst : BB) {
        if (!llvm::BinaryOperator::classof(&Inst)) {
          continue;
        }
        llvm::BinaryOperator *op = llvm::cast<llvm::BinaryOperator>(&Inst);
        if (op->getOpcode() != llvm::Instruction::BinaryOps::Mul) {
          continue;
        }

        llvm::Value *leftOper = op->getOperand(0);
        llvm::Value *rightOper = op->getOperand(1);

        int logVal1 = getLogBase2(leftOper);
        int logVal2 = getLogBase2(rightOper);
        if (logVal1 < logVal2) {
          std::swap(logVal1, logVal2);
          std::swap(leftOper, rightOper);
        }

        if (MulShiftConstOnly && !llvm::isa<llvm::ConstantInt>(leftOper)) {
          continue;
        }

        if (logVal1 > -1) {
          llvm::Value *lg_val = llvm::ConstantInt::get(
              llvm::IntegerType::get(Func.getContext(), 32),
              llvm::APInt(32, logVal1));

          llvm::Value *val = llvm::BinaryOperator::Create(
              llvm::Instruction::Shl, rightOper, lg_val, op->getName(), op);

          op->replaceAllUsesWith(val);
          toRemove.push_back(op);
          changed = true;
        }
      }
      for (auto *I : toRemove) {
        I->eraseFromParent();
      }
    }

    if (changed) return llvm::PreservedAnalyses::none();
    return llvm::PreservedAnalyses::all();
  }

private:
  int getLogBase2(llvm::Value *val) {
    if (llvm::ConstantInt *CI = llvm::dyn_cast<llvm::ConstantInt>(val)) {
      return CI->getValue().exactLogBase2();
    }
    if (auto *LI = llvm::dyn_cast<llvm::LoadInst>(val)) {
      llvm::Value *Op = LI->getPointerOperand();
      Op->reverseUseList();
      llvm::StoreInst *StInst = nullptr;
      for (auto *Inst : Op->users()) {
        if (auto *SI = llvm::dyn_cast<llvm::StoreInst>(Inst)) {
          StInst = SI;
        }
        if (Inst == LI) {
          break;
          m - ly4 marked this conversation as resolved.
        }
      }
      Op->reverseUseList();
      if (!StInst) {
        return -2;
      }
      if (auto *CI =
              llvm::dyn_cast<llvm::ConstantInt>(StInst->getValueOperand())) {
        return CI->getValue().exactLogBase2();
      }
    }
    return -2;
  }
};
}

llvm::PassPluginLibraryInfo getPluginInfo() {
  return {LLVM_PLUGIN_API_VERSION, "ReplaceMulWithShift", "0.1",
          [](llvm::PassBuilder &PB) {
            PB.registerPipelineParsingCallback(
                [](llvm::StringRef Name, llvm::FunctionPassManager &PM,
                   llvm::ArrayRef<llvm::PassBuilder::PipelineElement>) {
                  if (Name == "replace-mul-with-shift") {
                    PM.addPass(BitShiftPass());
                    return true;
                  }
                  return false;
                });
          }};
}
extern "C" LLVM_ATTRIBUTE_WEAK ::llvm::PassPluginLibraryInfo
llvmGetPassPluginInfo() {
  return getPluginInfo();
}