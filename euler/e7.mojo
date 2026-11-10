# <p>By listing the first six prime numbers: $2, 3, 5, 7, 11$, and $13$, we can see that the $6$th prime is $13$.</p>
# <p>What is the $10\,001$st prime number?</p>
from std.math import sqrt, log, ceil
from std.time import perf_counter
from std.random import random_ui64, seed

# first try: 88 sec for 10,000,001
# def nth_prime(n: SIMD[DType.uint32, 1]) -> SIMD[DType.uint32, 1]:
#     var iter: SIMD[DType.uint32, 1] = 5
#     var num: SIMD[DType.uint32, 1] = 11
#     var div: SIMD[DType.uint32, 1]
#
#     while iter < n:
#         # print(t"new check started: {num}")
#         div = 3
#         var is_prime = False
#         while div <= sqrt(num):
#             # print(t"checking div {div}")
#             if num % div == 0:
#                 # print(t"num {num} is divisible by {div}. {num} is not prime.")
#                 num += 2
#                 is_prime = False
#                 break
#
#             else:
#                 # print(
#                 # t"num {num} is not divisible by {div}. {num} may be prime."
#                 # )
#                 is_prime = True
#
#                 div += 2
#         if is_prime:
#             # print(t"num {num} is prime #{iter}.")
#
#             if iter == n:
#                 break
#             else:
#                 num += 2
#                 iter += 1
#             continue
#     return num


comptime BASE_PRIMES = [
    2,
    3,
    5,
    7,
    11,
    13,
    17,
    19,
    23,
    29,
    31,
    37,
    41,
    43,
    47,
]


struct BitSet:
    var list: List[UInt64]
    var length: Int

    def __init__(out self, length: Int):
        self.list = List[UInt64]()
        self.length = length
        self.allocate_list()

    def __init__(out self, length: UInt64):
        self.list = List[UInt64]()
        self.length = Int(length)
        self.allocate_list()

    def allocate_list(mut self):
        var nlength: Int = (self.length + 63) >> 6
        self.list.resize(nlength, UInt64(0))

    def set_bit(mut self, bit: Int):
        var w: Int = bit >> 6
        var b: Int = bit & 63
        if bit + 1 > self.list.byte_length() << 3:
            print(t"Cannot set bit {bit}: Out of bounds")
            return
        self.list[w] = self.list[w] | UInt64(1) << UInt64(b)

    def check_bit(self, bit: Int) -> Optional[Bool]:
        var w: Int = bit >> 6
        var b: Int = bit & 63
        if bit + 1 > self.list.byte_length() << 3:
            print(t"Cannot check bit {bit}: Out of bounds")
            return

        return (self.list[w] & (UInt64(1) << UInt64(b))) != 0

    def _check_primes(self, cur: List[Int]) -> List[Int]:
        """Checks all bits in a BitSet. Returns a list of prime numbers."""
        var max_prime: Int = cur[len(cur) - 1]

        var primes: List[Int] = List[Int]()
        for i in range(((max_prime - 1) // 2) + 1, self.length + 1):
            if not self.check_bit(i).value():
                primes.append((i * 2) + 1)
        return primes^


def nth_prime[testing: Bool = False](mut n: Int) -> Int:
    # odd-only mapping:
    #   value = 1 + index * 2
    #   index = (value - 1) // 2

    # estimate of num with 10% padded
    if testing:
        seed()
        n = Int(random_ui64(50, 10000000))
        BASE_LENGTH: Int = Int(
            ceil(
                Float64(n)
                * (
                    log(SIMD[DType.float64, 1](Float64(n)))
                    + log(log(SIMD[DType.float64, 1](Float64(n))))
                )
                * 1.1
            )
        )
    else:
        BASE_LENGTH: Int = Int(
            ceil(
                Float64(n)
                * (
                    log(SIMD[DType.float64, 1](Float64(n)))
                    + log(log(SIMD[DType.float64, 1](Float64(n))))
                )
                * 1.1
            )
        )

    var base: List[Int] = materialize[BASE_PRIMES]()

    var primes: List[Int] = base.copy()
    while len(primes) < n:
        var max_value: Int = min(primes[len(primes) - 1] ** 2, BASE_LENGTH)
        var max_index: Int = (max_value - 1) // 2
        var bits: BitSet = BitSet(max_index)

        for p in primes:
            if p == 2:
                continue

            var p2: Int = p * p
            if p2 > max_value:
                break
            var x: Int = (p2 - 1) // 2
            while x <= max_index:
                bits.set_bit(x)
                x += p
        # add new primes to the list
        primes.extend(bits._check_primes(primes))
    # print(t"{len(primes)}\n{primes}")
    return primes[n - 1]


def is_prime(num: Int) -> Bool:
    if num % 2 == 0:
        return False
    var i = 3
    while i <= sqrt(num):
        if num % i == 0:
            return False
        i += 2
    return True


def main():
    start = perf_counter()
    # crashed at 10 billion. too much memory?
    var x = 1000001
    print(t"Prime {x} is {nth_prime[](x)}")
    seed()
    # var i = 100
    # for _ in range(50):
    #     var n = nth_prime[True](i)
    #
    #     if is_prime(n):
    #         print(t"{n} is prime")
    #     else:
    #         print(t"{n} is not prime")
    print(t"completed in {perf_counter()-start}")
