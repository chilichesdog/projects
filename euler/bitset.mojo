# example from copilot


# Bitset mapping: index i -> element i
struct BitSet(Movable):
    var words: List[UInt64]

    def __init__(out self):
        self.words = List[UInt64]()


def make_bitset(max_value: Int) -> BitSet:
    """Allocate and zero the backing array sized to hold bits for indices 0..max_value.
    """
    # adjust for list indices
    var nbits = max_value + 1
    # round up to nearest 64 bits
    var nwords = (nbits + 63) // 64
    var s = BitSet()
    s.words = List[UInt64]()
    # initialize words to 0
    #   all bits clear = all elements absent
    s.words.resize(nwords, UInt64(0))
    return s^


def set_bit(mut s: BitSet, i: Int):
    var w = i >> 6
    var b = i & 63
    s.words[w] = s.words[w] | (UInt64(1) << UInt64(b))


def clear_bit(mut s: BitSet, i: Int):
    var w = i >> 6
    var b = i & 63
    s.words[w] = s.words[w] & ~(UInt64(1) << UInt64(b))


def test_bit(s: BitSet, i: Int) -> Bool:
    var w = i >> 6
    var b = i & 63
    return (s.words[w] & (UInt64(1) << UInt64(b))) != 0


# Word-wise union and intersection
def union(mut out: BitSet, a: BitSet, b: BitSet):
    var n = len(out.words)
    for i in range(0, n):
        out.words[i] = a.words[i] | b.words[i]


def intersection(mut out: BitSet, a: BitSet, b: BitSet):
    var n = len(out.words)
    for i in range(0, n):
        out.words[i] = a.words[i] & b.words[i]


# Count set bits (popcount) - placeholder loop using simple bit trick
def popcount_word(x: UInt64) -> Int:
    # Replace with hardware popcount if available for speed
    var cnt: Int = 0
    var v = x
    while v != 0:
        v = v & (v - 1)  # clear lowest set bit
        cnt += 1
    return cnt


def count_bits(s: BitSet) -> Int:
    var total: Int = 0
    for w in s.words:
        total += popcount_word(w)
    return total


# Example usage
def main():
    var max_id: Int = 1000
    var a = make_bitset(max_id)
    var b = make_bitset(max_id)
    # mark some active IDs
    set_bit(a, 3)
    set_bit(a, 10)
    set_bit(a, 500)
    set_bit(b, 10)
    set_bit(b, 200)
    set_bit(b, 500)

    var out = make_bitset(max_id)
    intersection(out, a, b)
    print(
        t"common active count = {count_bits(out)}"
    )  # should print 2(10 and 500)
