from std.random import random_ui64, seed

# TODO: make it analyze the row for hexachords, intervals, trichords, cominatoriality
# TODO: keep famous row stored and check if generated row is famous


def main() raises:
    seed()

    var row_ints = List[String]()
    var row_names = List[String]()
    var row_pcs = List[String]()
    # fmt: off
    var ints = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "11"]
    var names = ["C", "Db", "D", "Eb", "E", "F", "Gb", "G", "Ab", "A", "Bb", "B"]
    var pcs = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "t", "e"]
    # fmt: on

    var int_name_pc_dict = {i: (n, p) for i, n, p in zip(ints, names, pcs)}

    while row_ints.__len__() < 12:
        var num = String(random_ui64(0, 11))
        if row_ints.__contains__(num):
            pass
        else:
            row_ints.append(num)
            row_names.append(int_name_pc_dict[num][0])
            row_pcs.append(int_name_pc_dict[num][1])

    print(t"Row:\nints:{row_ints}\nnames:{row_names}\npcs:{row_pcs}")
