// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.18;

library ECCommitment {
    uint256 public constant gx =
        0x79BE667EF9DCBBAC55A06295CE870B07029BFCDB2DCE28D959F2815B16F81798;
    uint256 public constant gy =
        0x483ADA7726A3C4655DA4FBFC0E1108A8FD17B448A68554199C47D08FFB10D4B8;
    uint256 public constant a = 0;
    uint256 public constant b = 7;
    uint8 public constant gyParity = 27;
    uint256 public constant n =
        0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFC2F;
    uint256 public constant q =
        0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141;

    /**
     * @dev Returns the address from a given point.
     * @param qx x-coordinate of the point.
     * @param qy y-coordinate of the point.
     * @return The address.
     */
    function commitmentFromPoint(
        uint256 qx,
        uint256 qy
    ) public pure returns (bytes32) {
        return
            bytes32(
                uint256(keccak256(abi.encodePacked(qx, qy))) &
                    0x00FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
            );
    }

    /**
     * Calculates the commitment from an initial commitment and a shared secret.
     * This function should be used as a tool to calculate the mirror commitment.
     * @param qx x-coordinate of the initial commitment.
     * @param qy y-coordinate of the initial commitment.
     * @param sharedSecret that generates the commitment.
     * @return x- and y-coordinates of the new commitment.
     */
    function commitmentFromSharedSecret(
        uint256 qx,
        uint256 qy,
        bytes32 sharedSecret
    ) external pure returns (bytes32) {
        (uint256 _qx, uint256 _qy) = ecmul(gx, gy, uint256(sharedSecret));

        (uint256 _qsx, uint256 _qsy) = ecadd(qx, qy, _qx, _qy);
        return commitmentFromPoint(_qsx, _qsy);
    }

    /**
     * @dev Returns the commitment ID from a given secret.
     * @param secret The secret.
     * @return The commitment ID.
     */
    function commitmentFromSecret(
        bytes32 secret
    ) public pure returns (bytes32) {
        address _addr = ecrecover(
            0,
            gyParity,
            bytes32(gx),
            bytes32(mulmod(uint256(secret), gx, q))
        );

        return bytes32(uint256(uint160(_addr)));
    }

    function _jAdd(
        uint256 x1,
        uint256 z1,
        uint256 x2,
        uint256 z2
    ) public pure returns (uint256 x3, uint256 z3) {
        (x3, z3) = (
            addmod(mulmod(z2, x1, n), mulmod(x2, z1, n), n),
            mulmod(z1, z2, n)
        );
    }

    function _jSub(
        uint256 x1,
        uint256 z1,
        uint256 x2,
        uint256 z2
    ) public pure returns (uint256 x3, uint256 z3) {
        (x3, z3) = (
            addmod(mulmod(z2, x1, n), mulmod(n - x2, z1, n), n),
            mulmod(z1, z2, n)
        );
    }

    function _jMul(
        uint256 x1,
        uint256 z1,
        uint256 x2,
        uint256 z2
    ) public pure returns (uint256 x3, uint256 z3) {
        (x3, z3) = (mulmod(x1, x2, n), mulmod(z1, z2, n));
    }

    function _jDiv(
        uint256 x1,
        uint256 z1,
        uint256 x2,
        uint256 z2
    ) public pure returns (uint256 x3, uint256 z3) {
        (x3, z3) = (mulmod(x1, z2, n), mulmod(z1, x2, n));
    }

    function _inverse(uint256 val) public pure returns (uint256 invVal) {
        uint256 t = 0;
        uint256 newT = 1;
        uint256 r = n;
        uint256 newR = val;
        uint256 q;
        while (newR != 0) {
            q = r / newR;

            (t, newT) = (newT, addmod(t, (n - mulmod(q, newT, n)), n));
            (r, newR) = (newR, r - q * newR);
        }

        return t;
    }

    function _ecAdd(
        uint256 x1,
        uint256 y1,
        uint256 z1,
        uint256 x2,
        uint256 y2,
        uint256 z2
    ) public pure returns (uint256 x3, uint256 y3, uint256 z3) {
        uint256 lx;
        uint256 lz;
        uint256 da;
        uint256 db;

        if (x1 == 0 && y1 == 0) {
            return (x2, y2, z2);
        }

        if (x2 == 0 && y2 == 0) {
            return (x1, y1, z1);
        }

        if (x1 == x2 && y1 == y2) {
            (lx, lz) = _jMul(x1, z1, x1, z1);
            (lx, lz) = _jMul(lx, lz, 3, 1);
            (lx, lz) = _jAdd(lx, lz, a, 1);

            (da, db) = _jMul(y1, z1, 2, 1);
        } else {
            (lx, lz) = _jSub(y2, z2, y1, z1);
            (da, db) = _jSub(x2, z2, x1, z1);
        }

        (lx, lz) = _jDiv(lx, lz, da, db);

        (x3, da) = _jMul(lx, lz, lx, lz);
        (x3, da) = _jSub(x3, da, x1, z1);
        (x3, da) = _jSub(x3, da, x2, z2);

        (y3, db) = _jSub(x1, z1, x3, da);
        (y3, db) = _jMul(y3, db, lx, lz);
        (y3, db) = _jSub(y3, db, y1, z1);

        if (da != db) {
            x3 = mulmod(x3, db, n);
            y3 = mulmod(y3, da, n);
            z3 = mulmod(da, db, n);
        } else {
            z3 = da;
        }
    }

    function _ecDouble(
        uint256 x1,
        uint256 y1,
        uint256 z1
    ) public pure returns (uint256 x3, uint256 y3, uint256 z3) {
        (x3, y3, z3) = _ecAdd(x1, y1, z1, x1, y1, z1);
    }

    function _ecMul(
        uint256 d,
        uint256 x1,
        uint256 y1,
        uint256 z1
    ) public pure returns (uint256 x3, uint256 y3, uint256 z3) {
        uint256 remaining = d;
        uint256 px = x1;
        uint256 py = y1;
        uint256 pz = z1;
        uint256 acx = 0;
        uint256 acy = 0;
        uint256 acz = 1;

        if (d == 0) {
            return (0, 0, 1);
        }

        while (remaining != 0) {
            if ((remaining & 1) != 0) {
                (acx, acy, acz) = _ecAdd(acx, acy, acz, px, py, pz);
            }
            remaining = remaining / 2;
            (px, py, pz) = _ecDouble(px, py, pz);
        }

        (x3, y3, z3) = (acx, acy, acz);
    }

    function ecadd(
        uint256 x1,
        uint256 y1,
        uint256 x2,
        uint256 y2
    ) public pure returns (uint256 x3, uint256 y3) {
        uint256 z;
        (x3, y3, z) = _ecAdd(x1, y1, 1, x2, y2, 1);
        z = _inverse(z);
        x3 = mulmod(x3, z, n);
        y3 = mulmod(y3, z, n);
    }

    function ecmul(
        uint256 x1,
        uint256 y1,
        uint256 scalar
    ) public pure returns (uint256 x2, uint256 y2) {
        uint256 z;
        (x2, y2, z) = _ecMul(scalar, x1, y1, 1);
        z = _inverse(z);
        x2 = mulmod(x2, z, n);
        y2 = mulmod(y2, z, n);
    }
}