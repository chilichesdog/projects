#
# <p>A palindromic number reads the same both ways. The largest palindrome made from the product of two $2$-digit numbers is $9009 = 91 \times 99$.</p>
# <p>Find the largest palindrome made from the product of two $3$-digit numbers.</p>
# PLAN:
#   check all 899 palindromic numbers for their factors.
#   assume the number is high so start from the top end and go down.
#   only check 3-digit factors.
#   avoid collections.


# this is clever but not a great idea.
# checking all the factors for every palindromic number is slower than just multiplying all the numbers together
# def pal_num() raises -> Int:
#     # how to make pal nums?
#     # maybe make 3-num strings, reverse one, put them together
#     var pal_str: String
#     var pal_int: Int
#
#     for i in reversed(range(10, 100)):
#         num = String(i)
#         num_rev = num.graphemes_reversed()
#         rev = ""
#         for ref g in num_rev:
#             rev += g
#         pal_str = num + rev
#         # + String(num_rev.next())
#         # + String(num_rev.next())
#         # + String(num_rev.next())
#
#         pal_int = Int(pal_str)
#         print(pal_int)
#     return 0


def is_pal(num: Int) -> Bool:
    num_str = String(num)
    num_len = num_str.byte_length()
    num_rev = num_str.graphemes_reversed()
    num_fwd = num_str.graphemes()
    for i in range(num_len // 2):
        if num_rev.nth(i) == num_fwd.nth(i):
            continue
        else:
            return False

    return True


def get_max_pal() -> Int:
    var max = 0
    for a in range(100, 1000):
        for b in range(100, 1000):
            c = a * b
            if is_pal(c) and c > max:
                max = c
    return max


def main():
    print(get_max_pal())
