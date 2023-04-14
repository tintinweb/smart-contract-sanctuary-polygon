// SPDX-License-Identifier: MIT
// solium-disable security/no-assign-params

pragma solidity 0.8.17;
import "../interfaces/IBN256G2.sol";

/**
 * @title Elliptic curve operations on twist points on bn256 (G2)
 * @dev Adaptation of https://github.com/musalbas/solidity-BN256G2 to 0.6.0 and then 0.8.17
 */
// slither-disable-next-line missing-inheritance
contract BN256G2 is IBN256G2 {
    uint256 internal constant FIELD_MODULUS = 0x30644e72e131a029b85045b68181585d97816a916871ca8d3c208c16d87cfd47;
    uint256 internal constant TWISTBX = 0x2b149d40ceb8aaae81be18991be06ac3b5b4c5e559dbefa33267e6dc24a138e5;
    uint256 internal constant TWISTBY = 0x9713b03af0fed4cd2cafadeed8fdf4a74fa084e52d1852e4a2bd0685c315d2;
    uint256 internal constant PTXX = 0;
    uint256 internal constant PTXY = 1;
    uint256 internal constant PTYX = 2;
    uint256 internal constant PTYY = 3;
    uint256 internal constant PTZX = 4;
    uint256 internal constant PTZY = 5;

    // This is the generator negated, to use for pairing
    uint256 public constant G2_NEG_X_RE = 0x198E9393920D483A7260BFB731FB5D25F1AA493335A9E71297E485B7AEF312C2;
    uint256 public constant G2_NEG_X_IM = 0x1800DEEF121F1E76426A00665E5C4479674322D4F75EDADD46DEBD5CD992F6ED;
    // slither-disable-next-line similar-names
    uint256 public constant G2_NEG_Y_RE = 0x275dc4a288d1afb3cbb1ac09187524c7db36395df7be3b99e673b13a075a65ec;
    // slither-disable-next-line similar-names
    uint256 public constant G2_NEG_Y_IM = 0x1d9befcd05a5323e6da4d435f3b617cdb3af83285c2df711ef39c01571827f9d;

    /**
     * @notice Add two twist points
     * @param pt1xx Coefficient 1 of x on point 1
     * @param pt1xy Coefficient 2 of x on point 1
     * @param pt1yx Coefficient 1 of y on point 1
     * @param pt1yy Coefficient 2 of y on point 1
     * @param pt2xx Coefficient 1 of x on point 2
     * @param pt2xy Coefficient 2 of x on point 2
     * @param pt2yx Coefficient 1 of y on point 2
     * @param pt2yy Coefficient 2 of y on point 2
     * @return (pt3xx, pt3xy, pt3yx, pt3yy)
     */
    function ecTwistAdd(
        uint256 pt1xx,
        uint256 pt1xy,
        uint256 pt1yx,
        uint256 pt1yy,
        uint256 pt2xx,
        uint256 pt2xy,
        uint256 pt2yx,
        uint256 pt2yy
    ) external view returns (uint256, uint256, uint256, uint256) {
        if (pt1xx == 0 && pt1xy == 0 && pt1yx == 0 && pt1yy == 0) {
            if (!(pt2xx == 0 && pt2xy == 0 && pt2yx == 0 && pt2yy == 0)) {
                require(_isOnCurve(pt2xx, pt2xy, pt2yx, pt2yy), "point not in curve");
            }
            return (pt2xx, pt2xy, pt2yx, pt2yy);
        } else if (pt2xx == 0 && pt2xy == 0 && pt2yx == 0 && pt2yy == 0) {
            require(_isOnCurve(pt1xx, pt1xy, pt1yx, pt1yy), "point not in curve");
            return (pt1xx, pt1xy, pt1yx, pt1yy);
        }

        require(_isOnCurve(pt1xx, pt1xy, pt1yx, pt1yy), "point not in curve");

        require(_isOnCurve(pt2xx, pt2xy, pt2yx, pt2yy), "point not in curve");

        uint256[6] memory pt3 = ecTwistAddJacobian(pt1xx, pt1xy, pt1yx, pt1yy, 1, 0, pt2xx, pt2xy, pt2yx, pt2yy, 1, 0);

        return _fromJacobian(pt3[PTXX], pt3[PTXY], pt3[PTYX], pt3[PTYY], pt3[PTZX], pt3[PTZY]);
    }

    /**
     * @notice Multiply a twist point by a scalar
     * @param s     Scalar to multiply by
     * @param pt1xx Coefficient 1 of x
     * @param pt1xy Coefficient 2 of x
     * @param pt1yx Coefficient 1 of y
     * @param pt1yy Coefficient 2 of y
     * @return (pt2xx, pt2xy, pt2yx, pt2yy)
     */
    function ecTwistMul(
        uint256 s,
        uint256 pt1xx,
        uint256 pt1xy,
        uint256 pt1yx,
        uint256 pt1yy
    ) external view returns (uint256, uint256, uint256, uint256) {
        uint256 pt1zx = 1;
        if (pt1xx == 0 && pt1xy == 0 && pt1yx == 0 && pt1yy == 0) {
            pt1xx = 1;
            pt1yx = 1;
            pt1zx = 0;
        } else {
            require(_isOnCurve(pt1xx, pt1xy, pt1yx, pt1yy), "point not in curve");
        }
        uint256[6] memory pt2 = _ecTwistMulJacobian(s, pt1xx, pt1xy, pt1yx, pt1yy, pt1zx, 0);

        return _fromJacobian(pt2[PTXX], pt2[PTXY], pt2[PTYX], pt2[PTYY], pt2[PTZX], pt2[PTZY]);
    }

    /**
     * @notice Get the field modulus
     * @return The field modulus
     */
    function getFieldModulus() external pure returns (uint256) {
        return FIELD_MODULUS;
    }

    /**
     * @notice a-b mod n
     * @param a First operand
     * @param b Second operand
     * @param n modulus
     * @return The result of the operation
     */
    function submod(uint256 a, uint256 b, uint256 n) internal pure returns (uint256) {
        return addmod(a, n - b, n);
    }

    /**
     * @notice FQ2*FQ2 multiplication operation
     * @param xx First FQ2 operands first coordinate
     * @param xy First FQ2 operands second coordinate
     * @param yx Second FQ2 operands first coordinate
     * @param yy Second FQ2 operands second coordinate
     * @return [xx*yx-xy*yy, xx*yy+xy*yx]
     */
    function _fq2mul(uint256 xx, uint256 xy, uint256 yx, uint256 yy) internal pure returns (uint256, uint256) {
        return (
            submod(mulmod(xx, yx, FIELD_MODULUS), mulmod(xy, yy, FIELD_MODULUS), FIELD_MODULUS),
            addmod(mulmod(xx, yy, FIELD_MODULUS), mulmod(xy, yx, FIELD_MODULUS), FIELD_MODULUS)
        );
    }

    /**
     * @notice Fq2*k multiplication operation
     * @param xx FQ2 operands first coordinate
     * @param xy FQ2 operands second coordinate
     * @param k scalar to multiply with
     * @return [xx*k, xy*k]
     */
    function _fq2muc(uint256 xx, uint256 xy, uint256 k) internal pure returns (uint256, uint256) {
        return (mulmod(xx, k, FIELD_MODULUS), mulmod(xy, k, FIELD_MODULUS));
    }

    /**
     * @notice FQ2+FQ2 addition operation
     * @param xx First FQ2 operands first coordinate
     * @param xy First FQ2 operands second coordinate
     * @param yx Second FQ2 operands first coordinate
     * @param yy Second FQ2 operands second coordinate
     * @return [xx+yx, xy+yy]
     */
    // function _fq2add(
    //     uint256 xx,
    //     uint256 xy,
    //     uint256 yx,
    //     uint256 yy
    // ) internal pure returns (uint256, uint256) {
    //     return (addmod(xx, yx, FIELD_MODULUS), addmod(xy, yy, FIELD_MODULUS));
    // }

    /**
     * @notice FQ2-FQ2 substraction operation
     * @param xx First FQ2 operands first coordinate
     * @param xy First FQ2 operands second coordinate
     * @param yx Second FQ2 operands first coordinate
     * @param yy Second FQ2 operands second coordinate
     * @return [xx-yx, xy-yy]
     */
    function _fq2sub(uint256 xx, uint256 xy, uint256 yx, uint256 yy) internal pure returns (uint256, uint256) {
        return (submod(xx, yx, FIELD_MODULUS), submod(xy, yy, FIELD_MODULUS));
    }

    /**
     * @notice FQ2/FQ2 division operation
     * @param xx First FQ2 operands first coordinate
     * @param xy First FQ2 operands second coordinate
     * @param yx Second FQ2 operands first coordinate
     * @param yy Second FQ2 operands second coordinate
     * @return [xx, xy] * Inv([yx, yy])
     */
    // function _fq2div(
    //     uint256 xx,
    //     uint256 xy,
    //     uint256 yx,
    //     uint256 yy
    // ) internal view returns (uint256, uint256) {
    //     (yx, yy) = _fq2inv(yx, yy);
    //     return _fq2mul(xx, xy, yx, yy);
    // }

    /**
     * @notice 1/FQ2 inverse operation
     * @param x FQ2 operands first coordinate
     * @param y FQ2 operands second coordinate
     * @return Inv([xx, xy])
     */
    function _fq2inv(uint256 x, uint256 y) internal view returns (uint256, uint256) {
        uint256 inv = _modInv(
            addmod(mulmod(y, y, FIELD_MODULUS), mulmod(x, x, FIELD_MODULUS), FIELD_MODULUS),
            FIELD_MODULUS
        );
        return (mulmod(x, inv, FIELD_MODULUS), FIELD_MODULUS - mulmod(y, inv, FIELD_MODULUS));
    }

    /**
     * @notice Checks if FQ2 is on G2
     * @param xx First FQ2 operands first coordinate
     * @param xy First FQ2 operands second coordinate
     * @param yx Second FQ2 operands first coordinate
     * @param yy Second FQ2 operands second coordinate
     * @return True if the FQ2 is on G2
     */
    function _isOnCurve(uint256 xx, uint256 xy, uint256 yx, uint256 yy) internal pure returns (bool) {
        uint256 yyx;
        uint256 yyy;
        uint256 xxxx;
        uint256 xxxy;
        (yyx, yyy) = _fq2mul(yx, yy, yx, yy);
        (xxxx, xxxy) = _fq2mul(xx, xy, xx, xy);
        (xxxx, xxxy) = _fq2mul(xxxx, xxxy, xx, xy);
        (yyx, yyy) = _fq2sub(yyx, yyy, xxxx, xxxy);
        (yyx, yyy) = _fq2sub(yyx, yyy, TWISTBX, TWISTBY);
        return yyx == 0 && yyy == 0;
    }

    /**
     * @notice Calculates the modular inverse of a over n
     * @param a The operand to calcualte the inverse of
     * @param n The modulus
     * @return result Inv(a)modn
     **/
    function _modInv(uint256 a, uint256 n) internal view returns (uint256 result) {
        bool success;
        // prettier-ignore
        // slither-disable-next-line assembly
        assembly { // solhint-disable-line no-inline-assembly
            let freemem := mload(0x40)
            mstore(freemem, 0x20)
            mstore(add(freemem, 0x20), 0x20)
            mstore(add(freemem, 0x40), 0x20)
            mstore(add(freemem, 0x60), a)
            mstore(add(freemem, 0x80), sub(n, 2))
            mstore(add(freemem, 0xA0), n)
            success := staticcall(
                sub(gas(), 2000),
                5,
                freemem,
                0xC0,
                freemem,
                0x20
            )
            result := mload(freemem)
        }
        require(success, "error with modular inverse");
    }

    /**
  * @notice Converts a point from jacobian to affine
  * @param pt1xx First point x real coordinate
  * @param pt1xy First point x imaginary coordinate
  * @param pt1yx First point y real coordinate
  * @param pt1yy First point y imaginary coordinate
  * @param pt1zx First point z real coordinate
  * @param pt1zy First point z imaginary coordinate
  * @return pt2xx (x real affine coordinate)
            pt2xy (x imaginary affine coordinate)
            pt2yx (y real affine coordinate)
            pt1zy (y imaginary affine coordinate)
  **/
    function _fromJacobian(
        uint256 pt1xx,
        uint256 pt1xy,
        uint256 pt1yx,
        uint256 pt1yy,
        uint256 pt1zx,
        uint256 pt1zy
    ) internal view returns (uint256, uint256, uint256, uint256) {
        uint256 invzx;
        uint256 invzy;
        uint256[4] memory pt2;
        (invzx, invzy) = _fq2inv(pt1zx, pt1zy);
        (pt2[0], pt2[1]) = _fq2mul(pt1xx, pt1xy, invzx, invzy);
        (pt2[2], pt2[3]) = _fq2mul(pt1yx, pt1yy, invzx, invzy);
        return (pt2[0], pt2[1], pt2[2], pt2[3]);
    }

    /**
     * @notice Adds two points in jacobian coordinates
     * @param pt1xx First point x real coordinate
     * @param pt1xy First point x imaginary coordinate
     * @param pt1yx First point y real coordinate
     * @param pt1yy First point y imaginary coordinate
     * @param pt1zx First point z real coordinate
     * @param pt1zy First point z imaginary coordinate
     * @param pt2xx Second point x real coordinate
     * @param pt2xy Second point x imaginary coordinate
     * @param pt2yx Second point y real coordinate
     * @param pt2yy Second point y imaginary coordinate
     * @param pt2zx Second point z real coordinate
     * @param pt2zy Second point z imaginary coordinate
     * @return pt3 = pt1+pt2 in jacobian
     **/
    function ecTwistAddJacobian(
        uint256 pt1xx,
        uint256 pt1xy,
        uint256 pt1yx,
        uint256 pt1yy,
        uint256 pt1zx,
        uint256 pt1zy,
        uint256 pt2xx,
        uint256 pt2xy,
        uint256 pt2yx,
        uint256 pt2yy,
        uint256 pt2zx,
        uint256 pt2zy
    ) internal pure returns (uint256[6] memory pt3) {
        if (pt1zx == 0 && pt1zy == 0) {
            (pt3[PTXX], pt3[PTXY], pt3[PTYX], pt3[PTYY], pt3[PTZX], pt3[PTZY]) = (
                pt2xx,
                pt2xy,
                pt2yx,
                pt2yy,
                pt2zx,
                pt2zy
            );
            return pt3;
        } else if (pt2zx == 0 && pt2zy == 0) {
            (pt3[PTXX], pt3[PTXY], pt3[PTYX], pt3[PTYY], pt3[PTZX], pt3[PTZY]) = (
                pt1xx,
                pt1xy,
                pt1yx,
                pt1yy,
                pt1zx,
                pt1zy
            );
            return pt3;
        }

        (pt2yx, pt2yy) = _fq2mul(pt2yx, pt2yy, pt1zx, pt1zy); // U1 = y2 * z1
        (pt3[PTYX], pt3[PTYY]) = _fq2mul(pt1yx, pt1yy, pt2zx, pt2zy); // U2 = y1 * z2
        (pt2xx, pt2xy) = _fq2mul(pt2xx, pt2xy, pt1zx, pt1zy); // V1 = x2 * z1
        (pt3[PTZX], pt3[PTZY]) = _fq2mul(pt1xx, pt1xy, pt2zx, pt2zy); // V2 = x1 * z2

        if (pt2xx == pt3[PTZX] && pt2xy == pt3[PTZY]) {
            if (pt2yx == pt3[PTYX] && pt2yy == pt3[PTYY]) {
                (pt3[PTXX], pt3[PTXY], pt3[PTYX], pt3[PTYY], pt3[PTZX], pt3[PTZY]) = _ecTwistDoubleJacobian(
                    pt1xx,
                    pt1xy,
                    pt1yx,
                    pt1yy,
                    pt1zx,
                    pt1zy
                );
                return pt3;
            }
            (pt3[PTXX], pt3[PTXY], pt3[PTYX], pt3[PTYY], pt3[PTZX], pt3[PTZY]) = (1, 0, 1, 0, 0, 0);
            return pt3;
        }

        (pt2zx, pt2zy) = _fq2mul(pt1zx, pt1zy, pt2zx, pt2zy); // W = z1 * z2
        (pt1xx, pt1xy) = _fq2sub(pt2yx, pt2yy, pt3[PTYX], pt3[PTYY]); // U = U1 - U2
        (pt1yx, pt1yy) = _fq2sub(pt2xx, pt2xy, pt3[PTZX], pt3[PTZY]); // V = V1 - V2
        (pt1zx, pt1zy) = _fq2mul(pt1yx, pt1yy, pt1yx, pt1yy); // V_squared = V * V
        (pt2yx, pt2yy) = _fq2mul(pt1zx, pt1zy, pt3[PTZX], pt3[PTZY]); // V_squared_times_V2 = V_squared * V2
        (pt1zx, pt1zy) = _fq2mul(pt1zx, pt1zy, pt1yx, pt1yy); // V_cubed = V * V_squared
        (pt3[PTZX], pt3[PTZY]) = _fq2mul(pt1zx, pt1zy, pt2zx, pt2zy); // newz = V_cubed * W
        (pt2xx, pt2xy) = _fq2mul(pt1xx, pt1xy, pt1xx, pt1xy); // U * U
        (pt2xx, pt2xy) = _fq2mul(pt2xx, pt2xy, pt2zx, pt2zy); // U * U * W
        (pt2xx, pt2xy) = _fq2sub(pt2xx, pt2xy, pt1zx, pt1zy); // U * U * W - V_cubed
        (pt2zx, pt2zy) = _fq2muc(pt2yx, pt2yy, 2); // 2 * V_squared_times_V2
        (pt2xx, pt2xy) = _fq2sub(pt2xx, pt2xy, pt2zx, pt2zy); // A = U * U * W - V_cubed - 2 * V_squared_times_V2
        (pt3[PTXX], pt3[PTXY]) = _fq2mul(pt1yx, pt1yy, pt2xx, pt2xy); // newx = V * A
        (pt1yx, pt1yy) = _fq2sub(pt2yx, pt2yy, pt2xx, pt2xy); // V_squared_times_V2 - A
        (pt1yx, pt1yy) = _fq2mul(pt1xx, pt1xy, pt1yx, pt1yy); // U * (V_squared_times_V2 - A)
        (pt1xx, pt1xy) = _fq2mul(pt1zx, pt1zy, pt3[PTYX], pt3[PTYY]); // V_cubed * U2
        (pt3[PTYX], pt3[PTYY]) = _fq2sub(pt1yx, pt1yy, pt1xx, pt1xy); // newy = U * (V_squared_times_V2 - A) - V_cubed * U2
    }

    /**
     * @notice Doubls a point in jacobian coordinates
     * @param pt1xx Point x real coordinate
     * @param pt1xy Point x imaginary coordinate
     * @param pt1yx Point y real coordinate
     * @param pt1yy Point y imaginary coordinate
     * @param pt1zx Point z real coordinate
     * @param pt1zy Point z imaginary coordinate
     * @return pt2xx, pt2xy, pt2yx, pt2yy, pt2zx, pt2zy the coordinates of pt2 = 2*pt1
     **/
    function _ecTwistDoubleJacobian(
        uint256 pt1xx,
        uint256 pt1xy,
        uint256 pt1yx,
        uint256 pt1yy,
        uint256 pt1zx,
        uint256 pt1zy
    ) internal pure returns (uint256, uint256, uint256, uint256, uint256, uint256) {
        uint256[6] memory pt2;
        (pt2[0], pt2[1]) = _fq2muc(pt1xx, pt1xy, 3); // 3 * x
        (pt2[0], pt2[1]) = _fq2mul(pt2[0], pt2[1], pt1xx, pt1xy); // W = 3 * x * x
        (pt1zx, pt1zy) = _fq2mul(pt1yx, pt1yy, pt1zx, pt1zy); // S = y * z
        (pt2[2], pt2[3]) = _fq2mul(pt1xx, pt1xy, pt1yx, pt1yy); // x * y
        (pt2[2], pt2[3]) = _fq2mul(pt2[2], pt2[3], pt1zx, pt1zy); // B = x * y * S
        (pt1xx, pt1xy) = _fq2mul(pt2[0], pt2[1], pt2[0], pt2[1]); // W * W
        (pt2[4], pt2[5]) = _fq2muc(pt2[2], pt2[3], 8); // 8 * B
        (pt1xx, pt1xy) = _fq2sub(pt1xx, pt1xy, pt2[4], pt2[5]); // H = W * W - 8 * B
        (pt2[4], pt2[5]) = _fq2mul(pt1zx, pt1zy, pt1zx, pt1zy); // S_squared = S * S
        (pt2[2], pt2[3]) = _fq2muc(pt2[2], pt2[3], 4); // 4 * B
        (pt2[2], pt2[3]) = _fq2sub(pt2[2], pt2[3], pt1xx, pt1xy); // 4 * B - H
        (pt2[2], pt2[3]) = _fq2mul(pt2[2], pt2[3], pt2[0], pt2[1]); // W * (4 * B - H)
        (pt2[0], pt2[1]) = _fq2muc(pt1yx, pt1yy, 8); // 8 * y
        (pt2[0], pt2[1]) = _fq2mul(pt2[0], pt2[1], pt1yx, pt1yy); // 8 * y * y
        (pt2[0], pt2[1]) = _fq2mul(pt2[0], pt2[1], pt2[4], pt2[5]); // 8 * y * y * S_squared
        (pt2[2], pt2[3]) = _fq2sub(pt2[2], pt2[3], pt2[0], pt2[1]); // newy = W * (4 * B - H) - 8 * y * y * S_squared
        (pt2[0], pt2[1]) = _fq2muc(pt1xx, pt1xy, 2); // 2 * H
        (pt2[0], pt2[1]) = _fq2mul(pt2[0], pt2[1], pt1zx, pt1zy); // newx = 2 * H * S
        (pt2[4], pt2[5]) = _fq2mul(pt1zx, pt1zy, pt2[4], pt2[5]); // S * S_squared
        (pt2[4], pt2[5]) = _fq2muc(pt2[4], pt2[5], 8); // newz = 8 * S * S_squared

        return (pt2[0], pt2[1], pt2[2], pt2[3], pt2[4], pt2[5]);
    }

    /**
     * @notice Doubls a point in jacobian coordinates
     * @param d scalar to multiply the point with
     * @param pt1xx Point x real coordinate
     * @param pt1xy Point x imaginary coordinate
     * @param pt1yx Point y real coordinate
     * @param pt1yy Point y imaginary coordinate
     * @param pt1zx Point z real coordinate
     * @param pt1zy Point z imaginary coordinate
     * @return pt2 a point representing pt2 = d*pt1 in jacobian coordinates
     **/
    function _ecTwistMulJacobian(
        uint256 d,
        uint256 pt1xx,
        uint256 pt1xy,
        uint256 pt1yx,
        uint256 pt1yy,
        uint256 pt1zx,
        uint256 pt1zy
    ) internal pure returns (uint256[6] memory pt2) {
        while (d != 0) {
            if ((d & 1) != 0) {
                pt2 = ecTwistAddJacobian(
                    pt2[PTXX],
                    pt2[PTXY],
                    pt2[PTYX],
                    pt2[PTYY],
                    pt2[PTZX],
                    pt2[PTZY],
                    pt1xx,
                    pt1xy,
                    pt1yx,
                    pt1yy,
                    pt1zx,
                    pt1zy
                );
            }
            (pt1xx, pt1xy, pt1yx, pt1yy, pt1zx, pt1zy) = _ecTwistDoubleJacobian(
                pt1xx,
                pt1xy,
                pt1yx,
                pt1yy,
                pt1zx,
                pt1zy
            );

            d = d / 2;
        }
        return pt2;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IBN256G2 {
    function ecTwistAdd(
        uint256 pt1xx,
        uint256 pt1xy,
        uint256 pt1yx,
        uint256 pt1yy,
        uint256 pt2xx,
        uint256 pt2xy,
        uint256 pt2yx,
        uint256 pt2yy
    ) external view returns (uint256, uint256, uint256, uint256);
}