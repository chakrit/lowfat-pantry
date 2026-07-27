// One failing test among passing ones. A run where everything fails tells the
// filter nothing about whether it keeps the failure and drops the passes.
using Xunit;

public class CheckoutTests {
    [Fact] public void Totals_add_up() { Assert.Equal(2, 1 + 1); }
    [Fact] public void Totals_subtract() { Assert.Equal(0, 1 - 1); }
    [Fact] public void Checkout_totals_round_tax() { Assert.Equal(10.82, 10.80); }
}
