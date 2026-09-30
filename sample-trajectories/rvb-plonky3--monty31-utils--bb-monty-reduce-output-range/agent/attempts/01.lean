import Benchmark.Cases.Plonky3.Monty31Utils.Specs

open CoreModels Aeneas Aeneas.Std.WP
open Aeneas.Std hiding namespace core alloc
open RustM
open p3_monty_31

namespace Benchmark.Cases.Plonky3.Monty31Utils

/-- `2^k - 1` is a mask for the low `k` bits. -/
theorem land_sub_one_eq_mod (n k : Nat) : n &&& (2^k - 1) = n % 2^k := by
  apply Nat.eq_of_testBit_eq
  intro i
  rw [Nat.testBit_and, Nat.testBit_two_pow_sub_one, Nat.testBit_mod_two_pow]
  by_cases h : i < k <;> simp [h]

/-- The value of the result of the extracted `overflowing_sub` on `u64`. -/
theorem u64_ovsub_val (x y : U64) :
    (⟨x.bv - y.bv⟩ : U64).val = (x.val + 2^64 - y.val) % 2^64 := by
  have hx : x.val < 2^64 := UScalar.hBounds x
  have hy : y.val < 2^64 := UScalar.hBounds y
  show (x.bv - y.bv).toNat = _
  rw [BitVec.toNat_sub, UScalar.bv_toNat, UScalar.bv_toNat]
  have h1 : x.val + 2^64 - y.val = 2^64 - y.val + x.val := by omega
  rw [h1]

/-- Shift right on `u64` by an `u32` shift amount, as long as it is `< 64`. -/
theorem u64_shiftRight_spec (x : U64) (s : U32) (hs : s.val < 64) :
    (x >>> s) ⦃ z => z.val = x.val >>> s.val ⦄ := by
  have h := spec_of_partialSpec (U64.ShiftRight_spec x s)
    (fun e he => by
      cases e with
      | panic => have h2 : s.val ≥ 64 := he; omega
      | undef => exact he.elim)
    (by simp)
  exact spec_mono h (fun z hz => hz.1)

/-- Specification of the extracted `overflowing_sub` on `u64`. -/
theorem u64_overflowing_sub_ok (x y : U64) :
    (core.num.U64.overflowing_sub x y)
      ⦃ r => r = ((⟨x.bv - y.bv⟩, decide (↑x < ↑y)) : U64 × Bool) ⦄ := by
  rw [show core.num.U64.overflowing_sub x y
        = ok ((⟨x.bv - y.bv⟩, decide (↑x < ↑y)) : U64 × Bool) from rfl, spec_ok]

/-- Overflow branch: `(x - u) mod 2^64 >>> 32` lies in `[2^32 - P, 2^32)`. -/
theorem over_branch_bound {xv uv i8v : Nat} (hu : uv ≤ (2^32 - 1) * 2013265921)
    (hlt : xv < uv) (hi8 : i8v = (xv + 2^64 - uv) % 2^64 / 2^32) :
    2^32 - 2013265921 ≤ i8v ∧ i8v < 2^32 := by
  have hdam := Nat.div_add_mod ((xv + 2^64 - uv) % 2^64) (2^32 : Nat)
  rw [← hi8] at hdam
  have hmlt := Nat.mod_lt ((xv + 2^64 - uv) % 2^64) (by norm_num : (0:Nat) < 2^32)
  have hWeq : (xv + 2^64 - uv) % 2^64 = xv + 2^64 - uv := by omega
  rw [hWeq] at hdam hmlt
  omega

/-- No-overflow branch: `(x - u) mod 2^64 >>> 32 < P`. -/
theorem nobranch_bound {xv uv i8v : Nat} (hx : xv < 2013265921 * 2^32) (hge : uv ≤ xv)
    (hi8 : i8v = (xv + 2^64 - uv) % 2^64 / 2^32) : i8v < 2013265921 := by
  have hWeq : (xv + 2^64 - uv) % 2^64 = xv - uv := by omega
  rw [hWeq] at hi8
  omega

/-- Montgomery reduction `monty_reduce` never panics on inputs below `P * 2^32` and returns a
canonical BabyBear value (`< P`). -/
theorem bb_monty_reduce_output_range {MP : Type} (inst : data_traits.MontyParameters MP)
    (h_params : BBParams inst) (x : Std.U64)
    (h_x : x.val < 2013265921 * 2^32) :
    bb_monty_reduce_output_range_spec inst x := by
  unfold bb_monty_reduce_output_range_spec utils.monty_reduce
  obtain ⟨hP, hB, hMU, hMASKd⟩ := h_params
  -- The parameters of `BB` as concrete values.
  have hmask : inst.MONTY_MASK = ok 4294967295#u32 := by
    rw [hMASKd]
    simp only [data_traits.MontyParameters.MONTY_MASK.default, hB]
    rfl
  simp only [lift]
  rw [hMU, hmask, hP, hB]
  simp only [core.num.U64.wrapping_mul, rust_primitives.arithmetic.wrapping_mul_u64,
             core.num.U32.wrapping_add, rust_primitives.arithmetic.wrapping_add_u32,
             bind_tc_ok]
  -- concrete value facts
  have h4295 : (4294967295 : Nat) = 2^32 - 1 := by norm_num
  have hmask64 : (UScalar.cast UScalarTy.U64 4294967295#u32).val = 4294967295 := rfl
  have hp64 : (UScalar.cast UScalarTy.U64 2013265921#u32).val = 2013265921 := rfl
  have hwm : (x.wrapping_mul (UScalar.cast UScalarTy.U64 2281701377#u32)).val
      = x.val * 2281701377 % 2^64 := by
    simp only [U64.wrapping_mul_val_eq, UScalar.size]
    rfl
  -- value of `t = (x * MU) & MASK`
  have htval : (x.wrapping_mul (UScalar.cast UScalarTy.U64 2281701377#u32) &&&
      UScalar.cast UScalarTy.U64 4294967295#u32).val = x.val * 2281701377 % 2^32 := by
    have hvaland : (x.wrapping_mul (UScalar.cast UScalarTy.U64 2281701377#u32) &&&
        UScalar.cast UScalarTy.U64 4294967295#u32).val =
        (x.wrapping_mul (UScalar.cast UScalarTy.U64 2281701377#u32)).val &&&
        (UScalar.cast UScalarTy.U64 4294967295#u32).val := rfl
    rw [hvaland, hwm, hmask64, h4295, land_sub_one_eq_mod]
    exact Nat.mod_mod_of_dvd _ (Nat.pow_dvd_pow 2 (by omega))
  -- the checked multiply: u = t * P < 2^64
  refine WP.spec_bind (UScalar.mul_spec ?_) ?_
  · rw [htval, hp64, UScalar.max_UScalarTy_U64_eq, U64.max_eq]
    omega
  -- the overflowing subtraction
  · intro u hu
    have hu_eq : u.val = x.val * 2281701377 % 2^32 * 2013265921 := by
      rw [hu, htval, hp64]
    have htle1 : x.val * 2281701377 % 2^32 ≤ 2^32 - 1 := by omega
    have hxb : x.val < 2^64 := UScalar.hBounds x
    have hub : u.val ≤ (2^32 - 1) * 2013265921 := by
      rw [hu_eq]
      exact Nat.mul_le_mul_right _ htle1
    have hsz : UScalar.size UScalarTy.U32 = 2^32 := by
      simp only [UScalar.size]
      norm_num
    refine WP.spec_bind (u64_overflowing_sub_ok x u) ?_
    intro p hp
    cases hp
    simp only [uncurry_apply_pair]
    split
    · rename_i hdec
      have hlt : x.val < u.val := of_decide_eq_true hdec
      refine WP.spec_bind (u64_shiftRight_spec (⟨x.bv - u.bv⟩ : U64) 32#u32 (by decide)) ?_
      intro i8 hi8
      simp only [bind_tc_ok, WP.spec_ok]
      rw [u64_ovsub_val x u, Nat.shiftRight_eq_div_pow, show (32#u32).val = 32 from rfl] at hi8
      obtain ⟨hi8lo, hi8hi⟩ := over_branch_bound hub hlt hi8
      rw [U32.wrapping_add_val_eq, show (UScalar.cast UScalarTy.U32 i8).val = i8.val % 2^32 from rfl,
          show (2013265921#u32).val = 2013265921 from rfl, hsz,
          show i8.val % 2^32 = i8.val from Nat.mod_eq_of_lt hi8hi]
      omega
    · rename_i hdec
      have hge : u.val ≤ x.val := by simpa using hdec
      refine WP.spec_bind (u64_shiftRight_spec (⟨x.bv - u.bv⟩ : U64) 32#u32 (by decide)) ?_
      intro i8 hi8
      simp only [bind_tc_ok, WP.spec_ok]
      rw [u64_ovsub_val x u, Nat.shiftRight_eq_div_pow, show (32#u32).val = 32 from rfl] at hi8
      have hi8hi := nobranch_bound h_x hge hi8
      rw [U32.wrapping_add_val_eq, show (UScalar.cast UScalarTy.U32 i8).val = i8.val % 2^32 from rfl,
          show (0#u32).val = 0 from rfl, hsz, Nat.add_zero,
          show i8.val % 2^32 = i8.val from Nat.mod_eq_of_lt (by omega)]
      omega

end Benchmark.Cases.Plonky3.Monty31Utils
