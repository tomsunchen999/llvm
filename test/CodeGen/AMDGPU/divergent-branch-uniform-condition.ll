; Modifications Copyright (c) 2019 Advanced Micro Devices, Inc. All rights reserved.
; Notified per clause 4(b) of the license.
; NOTE: Assertions have been autogenerated by utils/update_llc_test_checks.py
; RUN: llc -march=amdgcn -mcpu=gfx900 -verify-machineinstrs < %s | FileCheck %s

; This module creates a divergent branch. The branch is marked as divergent by
; the divergence analysis but the condition is not. This test ensures that the
; divergence of the branch is tested, not its condition, so that branch is
; correctly emitted as divergent.

target triple = "amdgcn-mesa-mesa3d"

define amdgpu_ps void @main(i32, float) {
; CHECK-LABEL: main:
; CHECK:       ; %bb.0: ; %start
; CHECK-NEXT:    v_readfirstlane_b32 s0, v0
; CHECK-NEXT:    s_mov_b32 m0, s0
; CHECK-NEXT:    s_mov_b64 s[6:7], 0
; CHECK-NEXT:    v_interp_p1_f32_e32 v0, v1, attr0.x
; CHECK-NEXT:    v_cmp_nlt_f32_e64 s[0:1], 0, v0
; CHECK-NEXT:    v_mov_b32_e32 v1, 0
; CHECK-NEXT:    ; implicit-def: $sgpr8_sgpr9
; CHECK-NEXT:    ; implicit-def: $sgpr4_sgpr5
; CHECK-NEXT:    ; implicit-def: $sgpr2_sgpr3
; CHECK-NEXT:  BB0_1: ; %loop
; CHECK-NEXT:    ; =>This Inner Loop Header: Depth=1
; CHECK-NEXT:    v_cmp_gt_u32_e32 vcc, 32, v1
; CHECK-NEXT:    s_and_b64 vcc, exec, vcc
; CHECK-NEXT:    s_or_b64 s[4:5], s[4:5], exec
; CHECK-NEXT:    s_or_b64 s[8:9], s[8:9], exec
; CHECK-NEXT:    s_cbranch_vccz BB0_5
; CHECK-NEXT:  ; %bb.2: ; %endif1
; CHECK-NEXT:    ; in Loop: Header=BB0_1 Depth=1
; CHECK-NEXT:    s_mov_b64 s[4:5], -1
; CHECK-NEXT:    s_and_saveexec_b64 s[8:9], s[0:1]
; CHECK-NEXT:    s_xor_b64 s[8:9], exec, s[8:9]
; CHECK-NEXT:    ; mask branch BB0_4
; CHECK-NEXT:  BB0_3: ; %endif2
; CHECK-NEXT:    ; in Loop: Header=BB0_1 Depth=1
; CHECK-NEXT:    v_add_u32_e32 v1, 1, v1
; CHECK-NEXT:    s_xor_b64 s[4:5], exec, -1
; CHECK-NEXT:  BB0_4: ; %Flow1
; CHECK-NEXT:    ; in Loop: Header=BB0_1 Depth=1
; CHECK-NEXT:    s_or_b64 exec, exec, s[8:9]
; CHECK-NEXT:    s_mov_b64 s[8:9], 0
; CHECK-NEXT:  BB0_5: ; %Flow
; CHECK-NEXT:    ; in Loop: Header=BB0_1 Depth=1
; CHECK-NEXT:    s_and_b64 s[10:11], exec, s[4:5]
; CHECK-NEXT:    s_or_b64 s[10:11], s[10:11], s[6:7]
; CHECK-NEXT:    s_andn2_b64 s[2:3], s[2:3], exec
; CHECK-NEXT:    s_and_b64 s[6:7], s[8:9], exec
; CHECK-NEXT:    s_or_b64 s[2:3], s[2:3], s[6:7]
; CHECK-NEXT:    s_mov_b64 s[6:7], s[10:11]
; CHECK-NEXT:    s_andn2_b64 exec, exec, s[10:11]
; CHECK-NEXT:    s_cbranch_execnz BB0_1
; CHECK-NEXT:  ; %bb.6: ; %Flow2
; CHECK-NEXT:    s_or_b64 exec, exec, s[10:11]
; CHECK-NEXT:    v_mov_b32_e32 v1, 0
; this is the divergent branch with the condition not marked as divergent
; CHECK-NEXT:    s_and_saveexec_b64 s[0:1], s[2:3]
; CHECK-NEXT:    ; mask branch BB0_8
; CHECK-NEXT:  BB0_7: ; %if1
; CHECK-NEXT:    v_sqrt_f32_e32 v1, v0
; CHECK-NEXT:  BB0_8: ; %endloop
; CHECK-NEXT:    s_or_b64 exec, exec, s[0:1]
; CHECK-NEXT:    exp mrt0 v1, v1, v1, v1 done vm
; CHECK-NEXT:    s_endpgm
start:
  %v0 = call float @llvm.amdgcn.interp.p1(float %1, i32 0, i32 0, i32 %0)
  br label %loop

loop:
  %v1 = phi i32 [ 0, %start ], [ %v5, %endif2 ]
  %v2 = icmp ugt i32 %v1, 31
  br i1 %v2, label %if1, label %endif1

if1:
  %v3 = call float @llvm.sqrt.f32(float %v0)
  br label %endloop

endif1:
  %v4 = fcmp ogt float %v0, 0.000000e+00
  br i1 %v4, label %endloop, label %endif2

endif2:
  %v5 = add i32 %v1, 1
  br label %loop

endloop:
  %v6 = phi float [ %v3, %if1 ], [ 0.0, %endif1 ]
  call void @llvm.amdgcn.exp.v4f32(i32 0, i32 15, float %v6, float %v6, float %v6, float %v6, i1 true, i1 true)
  ret void
}

declare float @llvm.sqrt.f32(float) #1
declare float @llvm.amdgcn.interp.p1(float, i32, i32, i32) #1
declare void @llvm.amdgcn.exp.v4f32(i32, i32, float, float, float, float, i1, i1) #0

attributes #0 = { nounwind }
attributes #1 = { nounwind readnone }
