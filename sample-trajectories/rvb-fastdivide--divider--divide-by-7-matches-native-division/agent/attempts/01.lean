import Benchmark.Cases.Fastdivide.Divider.Specs

open CoreModels Aeneas Aeneas.Std.WP
open Aeneas.Std hiding namespace core alloc
open RustM
open fastdivide

namespace Benchmark.Cases.Fastdivide.Divider

/-! ## Arithmetic core of the `General` path for `d = 7` -/

private lemma div7_core (N : ℕ) (hN : N < 18446744073709551615)
    (hQ : (2635249153387078803 * N) / 18446744073709551616 ≤ N) :
    (((N - (2635249153387078803 * N) / 18446744073709551616) / 2
        + (2635249153387078803 * N) / 18446744073709551616) % 18446744073709551616) / 4
      = N / 7 := by
  have hN' : N ≤ 18446744073709551614 := by omega
  set Q := (2635249153387078803 * N) / 18446744073709551616 with hQdef
  have hkey : (21081993227096630419 * N) / 18446744073709551616 = Q + N := by
    have hm : 21081993227096630419 = 18446744073709551616 + 2635249153387078803 := by norm_num
    omega
  have hsum : (N - Q) / 2 + Q = (N + Q) / 2 := by omega
  have hlt : (N + Q) / 2 ≤ N := by omega
  have hmod : (N - Q) / 2 + Q < 18446744073709551616 := by omega
  rw [Nat.mod_eq_of_lt hmod, hsum, Nat.div_div_eq_div_mul]
  norm_num
  have hNQ : N + Q = (21081993227096630419 * N) / 18446744073709551616 := by rw [hkey]; omega
  rw [hNQ, Nat.div_div_eq_div_mul]
  norm_num
  omega

/-! ## Value of `libdivide_mullhi_u64` -/

private lemma mullhi_val (x y : Std.U64) (h : x.val * y.val < 2^128) :
    fastdivide.libdivide_mullhi_u64 x y
      ⦃ r => r.val = x.val * y.val / 18446744073709551616 ⦄ := by
  norm_num at h
  unfold fastdivide.libdivide_mullhi_u64
  simp only [lift, bind_tc_ok]
  have hx : (UScalar.cast .U128 x).val = x.val := U64.cast_U128_val_eq x
  have hy : (UScalar.cast .U128 y).val = y.val := U64.cast_U128_val_eq y
  refine spec_bind
    (Pₘ := fun i => i.val = (UScalar.cast .U128 x).val * (UScalar.cast .U128 y).val) ?_ ?_
  · refine spec_of_partialSpec (Std.U128.mul_spec) ?_ ?_
    · intro e
      have hv : (64#i32).val = 64 := rfl
      have hto : (64#i32).toNat = 64 := rfl
      cases e <;> simp [hx, hy]
      scalar_tac
    · simp
  · intro i hi
    refine spec_bind
      (Pₘ := fun i1 => i1.val = i.val >>> (64#i32).toNat) ?_ ?_
    · refine spec_mono
        (spec_of_partialSpec (Std.U128.ShiftRight_IScalar_spec i 64#i32) ?_ ?_)
        (fun z hz => hz.1)
      · intro e
        have hv : (64#i32).val = 64 := rfl
        cases e <;> simp [hv]
      · simp
    · intro i1 hi1
      simp only [WP.spec_ok]
      rw [UScalar.cast_val_eq]
      show i1.val % 18446744073709551616 = x.val * y.val / 18446744073709551616
      rw [hi1, Nat.shiftRight_eq_div_pow]
      show i.val / 18446744073709551616 % 18446744073709551616 = _
      rw [hi, hx, hy]
      rw [Nat.mod_eq_of_lt ?_]
      · omega

/-! ## `core.num.U64.wrapping_add` computes modular addition -/

private lemma wrapping_add_val (x y : Std.U64) :
    core.num.U64.wrapping_add x y
      ⦃ r => r.val = (x.val + y.val) % 18446744073709551616 ⦄ := by
  rw [show core.num.U64.wrapping_add x y = ok (Aeneas.Std.core.num.U64.wrapping_add x y) from rfl]
  simp only [WP.spec_ok]
  rw [Aeneas.Std.core.num.U64.wrapping_add_val_eq]
  rw [show UScalar.size UScalarTy.U64 = 18446744073709551616 from by
    norm_num [UScalar.size, UScalar.rMax, U64.rMax, U64.size, U64.numBits]]

/-! ## The theorem -/

theorem divide_by_7_matches_native_division (n : Std.U64)
    (h_n : n.val < 2^64 - 1) :
    divide_by_7_matches_native_division_spec n := by
  unfold divide_by_7_matches_native_division_spec
  rw [show DividerU64.divide_by 7#u64 = ok (DividerU64.General 2635249153387078803#u64 2#u8) from rfl]
  simp only [bind_tc_ok]
  simp only [DividerU64.divide]
  have hN : n.val < 18446744073709551615 := by norm_num at h_n ⊢; omega
  have hM : (2635249153387078803#u64).val = 2635249153387078803 := rfl
  refine spec_bind (mullhi_val _ _ ?_) ?_
  · rw [hM, show (2:Nat)^128 = 18446744073709551616 * 18446744073709551616 from by norm_num]
    omega
  · intro q hq
    rw [hM] at hq
    have hqn : q.val ≤ n.val := by omega
    refine spec_bind (Pₘ := fun i => i.val = n.val - q.val) ?_ ?_
    · refine spec_mono (spec_of_partialSpec (Std.U64.sub_spec) ?_ ?_) ?_
      · intro e
        cases e <;> simp
        omega
      · simp
      · intro i hi
        exact hi.1
    · intro i hi
      refine spec_bind
        (Pₘ := fun i1 => i1.val = i.val >>> (1#i32).toNat) ?_ ?_
      · refine spec_mono
          (spec_of_partialSpec (Std.U64.ShiftRight_IScalar_spec i 1#i32) ?_ ?_)
          (fun z hz => hz.1)
        · intro e
          have hv : (1#i32).val = 1 := rfl
          cases e <;> simp [hv]
        · simp
      · intro i1 hi1
        refine spec_bind (wrapping_add_val i1 q) ?_
        · intro t ht
          refine spec_mono (spec_of_partialSpec (Std.U64.ShiftRight_spec t 2#u8) ?_ ?_) ?_
          · intro e
            have hv : (2#u8).val = 2 := rfl
            cases e <;> simp [hv]
          · simp
          · intro r hr
            rw [hr.1, show (2#u8).val = 2 from rfl, Nat.shiftRight_eq_div_pow,
                show (2:Nat)^2 = 4 from by norm_num, ht,
                hi1, hi, show (1#i32).toNat = 1 from rfl,
                Nat.shiftRight_eq_div_pow, show (2:Nat)^1 = 2 from by norm_num]
            rw [hq]
            exact div7_core n.val hN (by omega)

end Benchmark.Cases.Fastdivide.Divider
