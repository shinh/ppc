_start:
        lis r2, 0x1234
        ori r2, r2, 0x5678
        rlwinm r3, r2, 0, 0, 31
        rlwinm r4, r2, 5, 0, 31
        rlwinm r5, r2, 25, 7, 31
        rlwinm r6, r2, 0, 0, 20

        li r0, 1
        sc
