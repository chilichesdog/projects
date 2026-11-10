# <p>$2520$ is the smallest number that can be divided by each of the numbers from $1$ to $10$ without any remainder.</p>
# <p>What is the smallest positive number that is <strong class="tooltip">evenly divisible<span class="tooltiptext">divisible with no remainder</span></strong> by all of the numbers from $1$ to $20$?</p>


def num_no_rem(a: Int, b: Int) -> Int:
    var no_rem: Bool = False
    var num = 2520
    while not no_rem:
        for i in range(11, 21):
            if num % i == 0:
                no_rem = True
                continue
            else:
                num += 2520
                no_rem = False
                break
    return num


def main():
    # this is my guess based on logic
    num = 5 * 7 * 9 * 11 * 13 * 16 * 17 * 19
    print(num)
    print(num_no_rem(1, 1))
