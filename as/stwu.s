_start:
        subi r3, r1, 48
        li r2, 0x1234
        stwu r2, 4(r3)
        li r2, 0x2345
        stwu r2, 4(r3)
        li r2, 0x3456
        stwu r2, 4(r3)
        lwz r4, 0(r3)
        lwz r5, -4(r3)
        lwz r6, -8(r3)
        trap
