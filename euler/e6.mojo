struct SumTracker:
    var sum: Int
    var sum_of_squares: Int

    def __init__(out self):
        self.sum = 0
        self.sum_of_squares = 0

    def add(mut self, n: Int):
        self.sum += n
        self.sum_of_squares += n * n

    def difference(self) -> Int:
        return self.sum * self.sum - self.sum_of_squares


def main():
    var tracker = SumTracker()
    for i in range(1, 101):
        tracker.add(i)

    print(tracker.difference())
