import Benchmark.Cases.Lilliput.IntValue.Specs

open CoreModels Aeneas Aeneas.Std.WP
open Aeneas.Std hiding namespace core alloc
open RustM
open lilliput_core

namespace Benchmark.Cases.Lilliput.IntValue

/--
`UnsignedIntValue`'s `Ord` agrees with the integer order regardless of the
storage width: for all `u8` values `lhs`, `rhs` and every pair of width
variants (`U8`, `U16`, `U32`, `U64` holding the zero-extended values),
`lhs_value.cmp(rhs_value)` equals `lhs.cmp(&rhs)` and
`rhs_value.cmp(lhs_value)` equals `lhs.cmp(&rhs).reverse()`.
-/
theorem unsigned_int_value_cmp_across_widths (lhs rhs : Std.U8) :
    unsigned_int_value_cmp_across_widths_spec lhs rhs := by
  -- The `cmp` implementations all reduce to comparisons of naturals: the `u8`
  -- comparison on `lhs`/`rhs`, and (via `canonicalized`) the comparison of the
  -- zero-extended values stored in the two variants.  Reversing a comparison of
  -- naturals swaps the operands.
  have reverse_ok : ∀ m n : Nat,
      core.cmp.Ordering.reverse
        (match compare m n with
        | .lt => core.cmp.Ordering.Less
        | .eq => core.cmp.Ordering.Equal
        | .gt => core.cmp.Ordering.Greater) =
        ok (match compare n m with
        | .lt => core.cmp.Ordering.Less
        | .eq => core.cmp.Ordering.Equal
        | .gt => core.cmp.Ordering.Greater) := by
    intro m n
    rcases Nat.lt_trichotomy m n with h | h | h
    · simp only [Nat.compare_eq_lt.2 h, Nat.compare_eq_gt.2 h,
        core.cmp.Ordering.reverse]
    · subst h
      simp only [Nat.compare_eq_eq.2 rfl, core.cmp.Ordering.reverse]
    · simp only [Nat.compare_eq_gt.2 h, Nat.compare_eq_lt.2 h,
        core.cmp.Ordering.reverse]
  have cmp8 : ∀ x y : Std.U8,
      core.U8.Insts.CoreCmpOrd.cmp x y =
        ok (match compare x.val y.val with
        | .lt => core.cmp.Ordering.Less
        | .eq => core.cmp.Ordering.Equal
        | .gt => core.cmp.Ordering.Greater) := fun _ _ => rfl
  have cmp64 : ∀ x y : Std.U64,
      core.U64.Insts.CoreCmpOrd.cmp x y =
        ok (match compare x.val y.val with
        | .lt => core.cmp.Ordering.Less
        | .eq => core.cmp.Ordering.Equal
        | .gt => core.cmp.Ordering.Greater) := fun _ _ => rfl
  intro lhs_value hlhs rhs_value hrhs
  simp only [unsignedValues, List.mem_cons, List.not_mem_nil, or_false] at hlhs hrhs
  rcases hlhs with h | h | h | h <;>
    rcases hrhs with h' | h' | h' | h' <;>
    simp only [h, h', value.int.unsigned.UnsignedIntValue.Insts.CoreCmpOrd.cmp,
      value.int.unsigned.UnsignedIntValue.canonicalized, cmp8, cmp64, reverse_ok,
      U8.cast_U64_val_eq, U16.cast_U64_val_eq, U32.cast_U64_val_eq,
      U8.cast_U16_val_eq, U8.cast_U32_val_eq, bind_tc_ok, WP.spec_ok, and_self]

end Benchmark.Cases.Lilliput.IntValue
