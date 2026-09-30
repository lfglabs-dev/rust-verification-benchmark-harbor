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
  -- The extracted `cmp` on `UnsignedIntValue` canonicalizes both sides to `u64`
  -- and compares the zero-extended values; comparisons of naturals reverse
  -- symmetrically, so every width pair of variants matches the `u8` ordering.
  have main :
      ∀ (x y : Std.U8) (lhs_value : value.int.unsigned.UnsignedIntValue),
        uval lhs_value = x.val →
        ∀ rhs_value : value.int.unsigned.UnsignedIntValue,
          uval rhs_value = y.val →
            (do
              let int_ordering ← core.U8.Insts.CoreCmpOrd.cmp x y
              let a ← value.int.unsigned.UnsignedIntValue.Insts.CoreCmpOrd.cmp
                lhs_value rhs_value
              let b ← value.int.unsigned.UnsignedIntValue.Insts.CoreCmpOrd.cmp
                rhs_value lhs_value
              let reversed ← core.cmp.Ordering.reverse int_ordering
              ok (int_ordering, reversed, a, b)) ⦃ r => r.2.2.1 = r.1 ∧ r.2.2.2 = r.2.1 ⦄ := by
    intro x y lhs_value hl rhs_value hr
    simp only [u8cmp_eq, vcmp_eq, reverse_ordOf, bind_tc_ok, WP.spec_ok, hl, hr, and_self]
  intro lhs_value hlhs rhs_value hrhs
  have hl := uval_of_unsignedValues lhs lhs_value hlhs
  have hr := uval_of_unsignedValues rhs rhs_value hrhs
  exact main lhs rhs lhs_value hl rhs_value hr

end Benchmark.Cases.Lilliput.IntValue
