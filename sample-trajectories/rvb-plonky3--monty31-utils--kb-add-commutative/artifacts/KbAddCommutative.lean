import Benchmark.Cases.Plonky3.Monty31Utils.Specs

open CoreModels Aeneas Aeneas.Std.WP
open Aeneas.Std hiding namespace core alloc
open RustM
open p3_monty_31

namespace Benchmark.Cases.Plonky3.Monty31Utils

/-- On inputs `x, y < p ≤ 2^31`, `utils.add` cannot panic and returns
`(x.val + y.val) % p.val`: the checked sum cannot overflow, and the conditional
subtraction of `P` reduces the sum modulo `P`. -/
theorem add_val {MP : Type} (inst : data_traits.MontyParameters MP) (p : Std.U32)
    (hprime : inst.PRIME = ok p) (x y : Std.U32)
    (hx : x.val < p.val) (hy : y.val < p.val) (hp2 : 2 * p.val ≤ 4294967296) :
    utils.add inst x y ⦃ r => r.val = (x.val + y.val) % p.val ⦄ := by
  unfold utils.add
  rw [hprime]
  simp only [core.num.U32.overflowing_sub, rust_primitives.arithmetic.overflowing_sub_u32]
  step*
  · simp only [uoverflowing_sub]
    show (if decide (sum.val < p.val) = true then ok sum
          else ok ({ bv := sum.bv - p.bv } : Std.U32)) ⦃
      r => r.val = (x.val + y.val) % p.val ⦄
    split
    · rename_i htrue
      simp only [decide_eq_true_eq] at htrue
      simp only [spec_ok]
      rw [sum_post, Nat.mod_eq_of_lt (by omega)]
    · rename_i hfalse
      have hno : p.val ≤ sum.val := by
        simp only [decide_eq_true_eq] at hfalse
        omega
      simp only [spec_ok]
      have h1 : ({ bv := sum.bv - p.bv } : Std.U32).val = (sum.bv - p.bv).toNat := rfl
      have e1 : sum.bv.toNat = sum.val := rfl
      have e2 : p.bv.toNat = p.val := rfl
      rw [h1, BitVec.toNat_sub_of_le (by
        refine BitVec.le_def.mpr ?_
        rw [e1, e2]
        omega),
        e1, e2, sum_post, Nat.mod_eq_sub_mod (by omega), Nat.mod_eq_of_lt (by omega)]

theorem kb_add_commutative {MP : Type} (inst : data_traits.MontyParameters MP)
    (h_params : KBParams inst) (a b : Std.U32)
    (h_a : a.val < 2130706433) (h_b : b.val < 2130706433) :
    kb_add_commutative_spec inst a b := by
  unfold kb_add_commutative_spec
  have hprime : inst.PRIME = ok 2130706433#u32 := h_params.1
  have hab : utils.add inst a b ⦃ r => r.val = (a.val + b.val) % 2130706433 ⦄ :=
    add_val inst 2130706433#u32 hprime a b h_a h_b (by decide)
  have hba : utils.add inst b a ⦃ r => r.val = (b.val + a.val) % 2130706433 ⦄ :=
    add_val inst 2130706433#u32 hprime b a h_b h_a (by decide)
  apply spec_bind (Pₘ := fun r => r.val = (a.val + b.val) % 2130706433)
  · exact hab
  · intro ab habv
    apply spec_bind (Pₘ := fun r => r.val = (b.val + a.val) % 2130706433)
    · exact hba
    · intro ba hbav
      simp only [spec_ok, habv, hbav, Nat.add_comm]

end Benchmark.Cases.Plonky3.Monty31Utils
