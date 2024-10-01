#include "X86.h"
#include "X86InstrInfo.h"
#include "X86Subtarget.h"
#include "llvm/CodeGen/MachineFunctionPass.h"
#include "llvm/CodeGen/MachineInstrBuilder.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/IntrinsicsX86.h"
#include "llvm/Pass.h"
#include "llvm/Support/raw_ostream.h"

using namespace llvm;

namespace {
class X86KashirinMulPass : public MachineFunctionPass {
public:
  static char ID;
  X86KashirinMulPass() : MachineFunctionPass(ID) {}

  bool runOnMachineFunction(MachineFunction &MF) override {
    SmallVector<MachineInstr *> deletedInstrPtr;
    bool Changed = false;

    for (auto &MBB : MF) {
      for (auto MI = MBB.begin(); MI != MBB.end(); ++MI) {
        if (MI->getOpcode() == X86::MULPDrr) {
          Register Reg = MI->getOperand(0).getReg();
          Changed |= processMulAddPair(MF, MBB, MI, Reg, deletedInstrPtr);
        }
      }
    }

    for (auto it : deletedInstrPtr)
      it->eraseFromParent();

    return Changed;
  }

private:
  bool processMulAddPair(MachineFunction &MF, MachineBasicBlock &MBB,
                         MachineBasicBlock::iterator MI, Register Reg,
                         SmallVectorImpl<MachineInstr *> &deletedInstrPtr) {
    for (auto NextMI = std::next(MI); NextMI != MBB.end(); ++NextMI) {
      if (NextMI->getOpcode() == X86::ADDPDrr) {
        if (NextMI->getOperand(1).getReg() == Reg ||
            NextMI->getOperand(2).getReg() == Reg) {
          bool hasDependency = checkDependency(MBB, NextMI, Reg);
          if (!hasDependency) {
            createVFMADD213PDr(MF, MBB, MI, NextMI, Reg, deletedInstrPtr);
            return true;
          }
          break;
        }
      } else if (hasOperand(NextMI, Reg)) {
        break;
      }
    }
    return false;
  }

  bool checkDependency(const MachineBasicBlock &MBB,
                       MachineBasicBlock::iterator NextMI, Register Reg) {
    if (NextMI->getOperand(0).getReg() != Reg) {
      for (auto CheckMI = std::next(NextMI); CheckMI != MBB.end(); ++CheckMI) {
        if (hasOperand(CheckMI, Reg))
          return true;
      }
    }
    return false;
  }

  bool hasOperand(MachineBasicBlock::iterator MI, Register Reg) {
    for (unsigned i = 0, e = MI->getNumOperands(); i != e; ++i) {
      if (MI->getOperand(i).getReg() == Reg)
        return true;
    }
    return false;
  }

  void createVFMADD213PDr(MachineFunction &MF, MachineBasicBlock &MBB,
                          MachineBasicBlock::iterator MI,
                          MachineBasicBlock::iterator NextMI, Register Reg,
                          SmallVectorImpl<MachineInstr *> &deletedInstrPtr) {
    MachineInstrBuilder BuilderMI =
        BuildMI(MBB, MI, MI->getDebugLoc(),
                MF.getSubtarget().getInstrInfo()->get(X86::VFMADD213PDr));
    BuilderMI.addReg(NextMI->getOperand(0).getReg(), RegState::Define);
    BuilderMI.addReg(MI->getOperand(1).getReg());
    BuilderMI.addReg(MI->getOperand(2).getReg());
    BuilderMI.addReg(NextMI->getOperand(2).getReg());
    deletedInstrPtr.push_back(&*MI);
    deletedInstrPtr.push_back(&*NextMI);
  }
};
} // namespace

char X86KashirinMulPass::ID = 0;
static RegisterPass<X86KashirinMulPass> X("x86-kashirin-mul-pass",
                                          "X86KashirinMulPass");