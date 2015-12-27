_start:
        bl func
        li r4, 0x4567
        mtlr r4
        trap
func:
        mflr r2
        li r3, 0x1234
        blr
