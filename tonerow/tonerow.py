from random import randint, seed

# TODO: make it analyze the row for hexachords, intervals, trichords, cominatoriality
# TODO: keep famous row stored and check if generated row is famous


def main():
    seed()

    row_ints = []
    row_names = []
    row_pcs = []
    ints = ("0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "11")
    names = ("C", "Db", "D", "Eb", "E", "F", "Gb", "G", "Ab", "A", "Bb", "B")
    pcs = ("0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "t", "e")

    int_name_pc_dict = {i: (n, p) for i, n, p in zip(ints, names, pcs)}

    while row_ints.__len__() < 12:
        num = str(randint(0, 11))
        if row_ints.__contains__(num):
            pass
        else:
            row_ints.append(num)
            row_names.append(int_name_pc_dict[num][0])
            row_pcs.append(int_name_pc_dict[num][1])

    print(f"Row:\nints:{row_ints}\nnames:{row_names}\npcs:{row_pcs}")


if __name__ == "__main__":
    main()
