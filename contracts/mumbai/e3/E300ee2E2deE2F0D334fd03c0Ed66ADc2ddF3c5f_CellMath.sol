//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

library CellMath {
    // find closest number n to m
    function ClosestNumber(int256 n, int256 m) public pure returns (int256) {
        // find the quotient
        int256 q = n / m;

        // 1st possible closest number
        int256 n1 = m * q;

        // 2nd possible closest number
        int256 n2 = (n * m) > 0 ? (m * (q + 1)) : (m * (q - 1));

        if (Abs(n - n1) < Abs(n - n2)) {
            return n1;
        } else {
            return n2;
        }
    }

    function Abs(int256 n) public pure returns (int256) {
        if (n > 0) {
            return n;
        } else if (n == 0) {
            return 0;
        } else {
            return -n;
        }
    }

    //  ---- Examples ----
    // x=0,y=0,diameter=3   BelongsToCell 0,0
    // x=1,y=0,diameter=3   BelongsToCell 0,0
    // x=2,y=0,diameter=3   BelongsToCell 1,0
    // x=4,y=0,diameter=3   BelongsToCell 1,0
    // x=5,y=0,diameter=3   BelongsToCell 2,0
    function BelongsToCell(
        int256 x,
        int256 y,
        uint256 diameter
    ) public pure returns (int256, int256) {
        int256 diameter_INT = int256(diameter);

        int256 resultX = ClosestNumber(x, diameter_INT) / diameter_INT;
        int256 resultY = ClosestNumber(y, diameter_INT) / diameter_INT;

        return (resultX, resultY);
    }
}