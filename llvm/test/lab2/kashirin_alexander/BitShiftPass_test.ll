; RUN: split-file %s %t
; RUN: opt -passes="kashirin-replace-mul-with-shift" -S %t/test1.ll | FileCheck %t/test1.ll
; RUN: opt -passes="kashirin-replace-mul-with-shift" -S %t/test2.ll | FileCheck %t/test2.ll
; RUN: opt -passes="kashirin-replace-mul-with-shift" -S %t/test3.ll | FileCheck %t/test3.ll
; RUN: opt -passes="kashirin-replace-mul-with-shift" -S %t/test4.ll | FileCheck %t/test4.ll
; RUN: opt -passes="kashirin-replace-mul-with-shift" -S %t/test5.ll | FileCheck %t/test5.ll
; RUN: opt -passes="kashirin-replace-mul-with-shift" -S %t/test6.ll | FileCheck %t/test6.ll
; RUN: opt -passes="kashirin-replace-mul-with-shift" -S %t/test7.ll | FileCheck %t/test7.ll

;--- test1.ll

;int f1(int a){
;    int c = a + 16;
;    return c;

define dso_local i32 @f1(i32 noundef %0) #0 {
  %2 = alloca i32, align 4
  %3 = alloca i32, align 4
  store i32 %0, ptr %2, align 4
  %4 = load i32, ptr %2, align 4
  %5 = add nsw i32 %4, 16
  store i32 %5, ptr %3, align 4
  %6 = load i32, ptr %3, align 4
  ret i32 %6
}

; CHECK-LABEL: @f1
; CHECK: %4 = load i32, ptr %2, align 4
; CHECK-NEXT: %5 = add nsw i32 %4, 16
; CHECK-NEXT: store i32 %5, ptr %3, align 4
;}

;--- test2.ll

;int f2(int a){
;    int c = a * 16;
;    return c;

define dso_local i32 @f2(i32 noundef %0) #0 {
  %2 = alloca i32, align 4
  %3 = alloca i32, align 4
  store i32 %0, ptr %2, align 4
  %4 = load i32, ptr %2, align 4
  %5 = mul nsw i32 %4, 16
  store i32 %5, ptr %3, align 4
  %6 = load i32, ptr %3, align 4
  ret i32 %6
}

; CHECK-LABEL: @f2
; CHECK: %4 = load i32, ptr %2, align 4
; CHECK-NEXT: %5 = shl i32 %4, 4
; CHECK-NEXT: store i32 %5, ptr %3, align 4
;}

;--- test3.ll

;void f3(){
;    int a = 53;
;    int c = a * 16;

define dso_local void @f3() #0 {
  %1 = alloca i32, align 4
  %2 = alloca i32, align 4
  store i32 53, ptr %1, align 4
  %3 = load i32, ptr %1, align 4
  %4 = mul nsw i32 %3, 16
  store i32 %4, ptr %2, align 4
  ret void
}

; CHECK-LABEL: @f3
; CHECK: %3 = load i32, ptr %1, align 4
; CHECK-NEXT: %4 = shl i32 %3, 4
; CHECK-NEXT: store i32 %4, ptr %2, align 4
;}

;--- test4.ll

;void f4(){
;    int a = 66;
;    int c = 16 * a;

define dso_local void @f4() #0 {
  %1 = alloca i32, align 4
  %2 = alloca i32, align 4
  store i32 66, ptr %1, align 4
  %3 = load i32, ptr %1, align 4
  %4 = mul nsw i32 16, %3
  store i32 %4, ptr %2, align 4
  ret void
}

; CHECK-LABEL: @f4
; CHECK: %3 = load i32, ptr %1, align 4
; CHECK-NEXT: %4 = shl i32 %3, 4
; CHECK-NEXT: store i32 %4, ptr %2, align 4
;}

;--- test5.ll

;void f5(){
;    int a = 16;
;    int c = a * 1;
;}

define dso_local void @f5() #0 {
  %1 = alloca i32, align 4
  %2 = alloca i32, align 4
  store i32 16, ptr %1, align 4
  %3 = load i32, ptr %1, align 4
  %4 = mul nsw i32 %3, 1
  store i32 %4, ptr %2, align 4
  ret void
}

; CHECK-LABEL: @f5
; CHECK: %3 = load i32, ptr %1, align 4
; CHECK-NEXT: %4 = shl i32 1, 4
; CHECK-NEXT: store i32 %4, ptr %2, align 4

;--- test6.ll

;void f6(){
;    int a = 55;
;    int c = 0 * a;
;}

define dso_local void @f6() #0 {
  %1 = alloca i32, align 4
  %2 = alloca i32, align 4
  store i32 55, ptr %1, align 4
  %3 = load i32, ptr %1, align 4
  %4 = mul nsw i32 0, %3
  store i32 %4, ptr %2, align 4
  ret void
}

; CHECK-LABEL: @f6
; CHECK: %3 = load i32, ptr %1, align 4
; CHECK-NEXT: %4 = mul nsw i32 0, %3
; CHECK-NEXT: store i32 %4, ptr %2, align 4

;--- test7.ll

;void f7(){
;    int a = 4;
;    int c = a * 10;
;}

define dso_local void @f7() #0 {
  %1 = alloca i32, align 4
  %2 = alloca i32, align 4
  store i32 4, ptr %1, align 4
  %3 = load i32, ptr %1, align 4
  %4 = mul nsw i32 %3, 10
  store i32 %4, ptr %2, align 4
  ret void
}

; CHECK-LABEL: @f7
; CHECK: %3 = load i32, ptr %1, align 4
; CHECK-NEXT: %4 = shl i32 10, 2
; CHECK-NEXT: store i32 %4, ptr %2, align 4