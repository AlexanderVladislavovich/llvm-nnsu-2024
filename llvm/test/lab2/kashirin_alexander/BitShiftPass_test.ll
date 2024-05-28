; RUN: opt -load-pass-plugin=%llvmshlibdir/KashirinMulToBitShiftPlugin%shlibext -passes=KashirinMulToBitShiftPlugin -S %s | FileCheck %s

;int foo1() {
;  int a = 3;
;  int b = 3 * 2;
;  return 16 * b;
;}
;
;int foo2() {
;  int a = 2;
;  int b = 3 * a;
;  return 3 * b;
;}
;
;int foo3() {
;  int b = 4 * 2;
;  int c = b * 1;
;  return c * 0;
;}
;
;int foo4() {
;  int a = -4;
;  int b = 2;
;  a = a * b;
;  return a * 8;
;}
;
;int foo5() {
;  double a = 2;
;  double b = a * 4.0;
;  return b * 8;
;}
;
;void foo6() {
;  int a = 2;
;  int b = a + 8;
;  int c = 8 - a;
;  a = c / 8;
;}

define dso_local noundef i32 @_Z4foo1v() #0 {
  %1 = alloca i32, align 4
  %2 = alloca i32, align 4
  store i32 3, ptr %1, align 4
  store i32 6, ptr %2, align 4
  %3 = load i32, ptr %2, align 4
  %4 = mul nsw i32 16, %3
  ret i32 %4
}

; CHECK-LABEL: @_Z4foo1v
; CHECK: %3 = load i32, ptr %2, align 4
; CHECK-NEXT: %4 = shl i32 %3, 4
; CHECK-NEXT: ret i32 %4

define dso_local noundef i32 @_Z4foo2v() #0 {
  %1 = alloca i32, align 4
  %2 = alloca i32, align 4
  store i32 2, ptr %1, align 4
  %3 = load i32, ptr %1, align 4
  %4 = mul nsw i32 3, %3
  store i32 %4, ptr %2, align 4
  %5 = load i32, ptr %2, align 4
  %6 = mul nsw i32 3, %5
  ret i32 %6
}

; CHECK-LABEL: @_Z4foo2v
; CHECK: %3 = load i32, ptr %1, align 4
; CHECK-NEXT: %4 = mul nsw i32 3, %3
; CHECK-NEXT: store i32 %4, ptr %2, align 4

; CHECK: %5 = load i32, ptr %2, align 4
; CHECK-NEXT: %6 = mul nsw i32 3, %5
; CHECK-NEXT: ret i32 %6

define dso_local noundef i32 @_Z4foo3v() #0 {
  %1 = alloca i32, align 4
  %2 = alloca i32, align 4
  store i32 8, ptr %1, align 4
  %3 = load i32, ptr %1, align 4
  %4 = mul nsw i32 %3, 1
  store i32 %4, ptr %2, align 4
  %5 = load i32, ptr %2, align 4
  %6 = mul nsw i32 %5, 0
  ret i32 %6
}

; CHECK-LABEL: @_Z4foo3v
; CHECK: %3 = load i32, ptr %1, align 4
; CHECK-NEXT: %4 = shl i32 %3, 0
; CHECK-NEXT: store i32 %4, ptr %2, align 4

; CHECK: %5 = load i32, ptr %2, align 4
; CHECK-NEXT: %6 = mul nsw i32 %5, 0
; CHECK-NEXT: ret i32 %6

define dso_local noundef i32 @_Z4foo4v() #0 {
  %1 = alloca i32, align 4
  %2 = alloca i32, align 4
  store i32 -4, ptr %1, align 4
  store i32 2, ptr %2, align 4
  %3 = load i32, ptr %1, align 4
  %4 = load i32, ptr %2, align 4
  %5 = mul nsw i32 %3, %4
  store i32 %5, ptr %1, align 4
  %6 = load i32, ptr %1, align 4
  %7 = mul nsw i32 %6, 8
  ret i32 %7
}

; CHECK-LABEL: @_Z4foo4v
; CHECK: %4 = load i32, ptr %2, align 4
; CHECK-NEXT: %5 = mul nsw i32 %3, %4
; CHECK-NEXT: store i32 %5, ptr %1, align 4

; CHECK: %6 = load i32, ptr %1, align 4
; CHECK-NEXT: %7 = shl i32 %6, 3
; CHECK-NEXT: ret i32 %7

define dso_local noundef i32 @_Z4foo5v() #0 {
  %1 = alloca double, align 8
  %2 = alloca double, align 8
  store double 2.000000e+00, ptr %1, align 8
  %3 = load double, ptr %1, align 8
  %4 = fmul double %3, 4.000000e+00
  store double %4, ptr %2, align 8
  %5 = load double, ptr %2, align 8
  %6 = fmul double %5, 8.000000e+00
  %7 = fptosi double %6 to i32
  ret i32 %7
}

; CHECK-LABEL: @_Z4foo5v
; CHECK: %3 = load double, ptr %1, align 8
; CHECK-NEXT: %4 = fmul double %3, 4.000000e+00
; CHECK-NEXT: store double %4, ptr %2, align 8

; CHECK: %5 = load double, ptr %2, align 8
; CHECK-NEXT: %6 = fmul double %5, 8.000000e+00
; CHECK-NEXT: %7 = fptosi double %6 to i32

define dso_local void @_Z4foo6v() #0 {
  %1 = alloca i32, align 4
  %2 = alloca i32, align 4
  %3 = alloca i32, align 4
  store i32 2, ptr %1, align 4
  %4 = load i32, ptr %1, align 4
  %5 = add nsw i32 %4, 8
  store i32 %5, ptr %2, align 4
  %6 = load i32, ptr %1, align 4
  %7 = sub nsw i32 8, %6
  store i32 %7, ptr %3, align 4
  %8 = load i32, ptr %3, align 4
  %9 = sdiv i32 %8, 8
  store i32 %9, ptr %1, align 4
  ret void
}

; CHECK-LABEL: @_Z4foo6v
; CHECK: %4 = load i32, ptr %1, align 4
; CHECK-NEXT: %5 = add nsw i32 %4, 8
; CHECK-NEXT: store i32 %5, ptr %2, align 4

; CHECK: %6 = load i32, ptr %1, align 4
; CHECK-NEXT: %7 = sub nsw i32 8, %6
; CHECK-NEXT: store i32 %7, ptr %3, align 4

; CHECK: %8 = load i32, ptr %3, align 4
; CHECK-NEXT: %9 = sdiv i32 %8, 8
; CHECK-NEXT: store i32 %9, ptr %1, align 4