struct AddFibonacci:
    var total: Int
    var t1: Int
    var t2: Int
    var t3: Int

    def __init__(out self):
        self.total = 0
        self.t1 = 1
        self.t2 = 2
        self.t3 = 0

    def add_evens(mut self, max: Int) -> Int:
        self.total += self.t2
        while self.t3 <= max:
            self.t3 = self.t1 + self.t2
            self.t1 = self.t2.copy()
            self.t2 = self.t3.copy()
            if self.t3 % 2 == 0:
                self.total += self.t3
                print(self.t3)
        return self.total


def main():
    var num = AddFibonacci()

    print(num.add_evens(4000000))
