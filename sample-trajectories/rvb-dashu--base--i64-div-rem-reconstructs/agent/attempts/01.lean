import Benchmark.Cases.Dashu.Base.Specs

open CoreModels Aeneas Aeneas.Std.WP
open Aeneas.Std hiding namespace core alloc
open RustM
open dashu_base

namespace Benchmark.Cases.Dashu.Base

/-- Truncating remainders are strictly smaller than the divisor in absolute value. -/
theorem abs_tmod_lt_abs {a b : Int} (hb : b ≠ 0) : |a.tmod b| < |b| := by
  rw [Int.abs_eq_natAbs, Int.natAbs_tmod, Int.abs_eq_natAbs]
  exact_mod_cast Nat.mod_lt _ (Int.natAbs_pos.2 hb)

/--
For `i64` operands with a nonzero divisor (excluding `i64::MIN / -1`),
dashu's truncating `DivRem::div_rem` never panics, reconstructs the dividend
(`q * b + r == a`) and returns a remainder smaller than the divisor in
absolute value.
-/
theorem i64_div_rem_reconstructs (a b : Std.I64)
    (h_assume_b_nonzero : b.val ≠ 0)
    (h_assume_no_overflow : ¬ (a.val = -2^63 ∧ b.val = -1)) :
    i64_div_rem_reconstructs_spec a b := by
  unfold i64_div_rem_reconstructs_spec
    I64.Insts.Dashu_baseRingDivRemI64I64I64.div_rem
  -- Chase the two checked scalar operations with their registered step specs;
  -- the `div`/`rem` panic side conditions are discharged from the hypotheses
  -- (`b.val ≠ 0`, `¬(a.val = i64::MIN ∧ b.val = -1)`).
  step*
  rw [i_post, i1_post]
  refine ⟨?_, ?_⟩
  · -- `q * b + r = a` for truncating division: `Int.mul_tdiv_add_tmod`
    rw [Int.mul_comm _ _, Int.mul_tdiv_add_tmod]
  · -- `|r| < |b|`: `|tmod a b| = natAbs a % natAbs b < natAbs b`
    exact abs_tmod_lt_abs h_assume_b_nonzero

end Benchmark.Cases.Dashu.Base
