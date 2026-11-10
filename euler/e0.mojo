# 2310831-VCLKHm9HrAkWmNB1FQZM3upukbMm7NZw2LkNieSp
# recovery code


struct SumSquares:
    var total: Int

    def __init__(out self):
        self.total = 0

    def add_squares(mut self, limit: Int, *, odds: Bool = True) -> Int:
        """Adds squares of all roots up to a given limit.
        @args:
            limit: Number of roots to add.
        """
        for i in range(1, limit + 1):
            if odds and i % 2 == 1:
                self.total += i * i
            elif not odds and i % 2 == 0:
                self.total += i * i
        return self.total


def main():
    """
    Among the first 811 thousand square numbers, what is the sum of all the odd squares?
    """
    var sum = SumSquares()
    # print(1 + 4 + 9 + 16 + 25 + 36 + 49 + 64 + 81 + 100)
    #
    # print(1 + 9 + 25 + 49 + 81)
    print(sum.add_squares(811000))
