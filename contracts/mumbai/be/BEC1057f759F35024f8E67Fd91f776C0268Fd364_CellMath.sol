//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

library CellMath {
    // find closest number n to m
    function closestNumber(int256 n, int256 m) public pure returns (int256) {
        // find the quotient
        int256 q = n / m;

        // 1st possible closest number
        int256 n1 = m * q;

        // 2nd possible closest number
        int256 n2 = (n * m) > 0 ? (m * (q + 1)) : (m * (q - 1));

        if (abs(n - n1) < abs(n - n2)) {
            return n1;
        } else {
            return n2;
        }
    }

    function abs(int256 n) public pure returns (int256) {
        if (n > 0) {
            return n;
        } else if (n == 0) {
            return 0;
        } else {
            return -n;
        }
    }

    function belongsToCell(
        int256 x,
        int256 y,
        uint256 radius
    ) public pure returns (int256, int256) {
        int256 d = int256(radius) * 2 + 1; // Radius to diameter
        int256 resultX = closestNumber(x, d) / d;
        int256 resultY = closestNumber(y, d) / d;
        return (resultX, resultY);
    }

    function cellCircumference(uint256 cellRadius)
        public
        pure
        returns (uint256)
    {
        return (((cellRadius) * 2 + 1) * 4 - 4);
    }
}