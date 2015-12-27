_start:
        subi r6, r1, 16
        lis r2, 0x1234
        addi r2, r2, 0x5678
        stw r2, 0(r6)
        lwz r3, 0(r6)

        addi r4, r6, 4
        stw r2, 4(r6)
        lwz r5, 0(r4)

        trap
