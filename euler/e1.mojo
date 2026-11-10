def sum_multiples(
    limit: Int, a: Int = 3, b: Int = 5, *, verbose: Bool = False
) -> Int:
    """Return the Int sum of all multiples of two divisors below a given limit.
    """
    var total = 0
    for n in range(limit):
        # check if n is a mult of 3 or 5
        if n % a == 0 or n % b == 0:
            if verbose:
                print(n)
            total += n
    return total


def sum_multiples(limit: Int, *divisors: Int) -> Int:
    """Return the Int sum of all multiples of two divisors below a given limit.
    """
    var total = 0
    for n in range(limit):
        for d in divisors:
            if n % d == 0:
                total += n
    return total


def main():
    print(sum_multiples(1000))
