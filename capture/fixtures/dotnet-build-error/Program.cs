// A compile error (CS0103, undefined `orderTotal`) with a warning beside it
// (CS8604, a maybe-null argument) — the diagnostic shape the filter keeps.
class P {
    static void M(string s) { System.Console.WriteLine(s.Length); }
    static void Main() { string? x = null; M(x); System.Console.WriteLine(orderTotal); }
}
