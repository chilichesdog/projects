# prime factors
#
# <p>The prime factors of $13195$ are $5, 7, 13$ and $29$.</p>
# <p>What is the largest prime factor of the number $600851475143$?</p>
from std.collections import Dict, Set
from std.math import sqrt
from std.time import perf_counter_ns


struct PrimeFactors:
    var factors: List[Int]
    var fac_dict: Dict[Int, Bool]
    var num: Int
    var start_time: UInt

    def __init__(out self, num: Int):
        self.start_time = perf_counter_ns()
        self.factors = List[Int]()
        self.fac_dict = Dict[Int, Bool]()
        self.num = num
        self.get_factors()
        self.get_fac_dict()

    def get_factors(mut self):
        if self.num % 2 == 0:
            self.factors.append(2)
        var n = 1
        while n <= sqrt(self.num):
            if self.num % n == 0:
                self.factors.append(n)
            n += 2

    def get_fac_dict(mut self):
        var fac_facs: Set[Int] = {1}
        for f in self.factors:
            if f % 2 == 0:
                continue
            var n = 1
            while n <= sqrt(f):
                if f % n == 0:
                    fac_facs.add(n)
                n += 2
            if len(fac_facs) > 1:
                self.fac_dict[f] = False
            else:
                self.fac_dict[f] = True

    def max_prime(self) raises -> Int:
        var primes = List[Int]()
        for i in self.fac_dict:
            if self.fac_dict[Int(i)]:
                primes.append(i)
        var max = 0
        for x in primes:
            if x > max:
                max = x.copy()
        print(t"Operation completed in {perf_counter_ns()-self.start_time}")
        return max


def main() raises:
    var prime = PrimeFactors(600851475143)
    print(prime.max_prime())
