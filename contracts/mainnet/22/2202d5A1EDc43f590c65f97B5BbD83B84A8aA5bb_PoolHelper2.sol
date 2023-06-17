// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IPoolHelper {
    function getSlippage(uint256 cov, uint256 slippageA, uint256 slippageN, uint256 slippageK) external pure returns (uint256);
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.4;

import "./interfaces/IPoolHelper.sol";

contract PoolHelper2 is IPoolHelper {
    /*
     *  Constants
     */
    // This is equal to 1 in our calculations
    uint public constant ONE_18 = 1e18;
    uint public constant ONE = 0x10000000000000000;
    uint public constant LN2 = 0xb17217f7d1cf79ac;
    uint public constant LOG2_E = 0x171547652b82fe177;

    /*
     *  Public functions
     */
    /// @dev Returns natural exponential function value of given x
    /// @param x x
    /// @return e**x
    function exp(int x) internal pure returns (uint) {
        // revert if x is > MAX_POWER, where
        // MAX_POWER = int(mp.floor(mp.log(mpf(2**256 - 1) / ONE) * ONE))
        require(x <= 2454971259878909886679, "ERR");
        // return 0 if exp(x) is tiny, using
        // MIN_POWER = int(mp.floor(mp.log(mpf(1) / ONE) * ONE))
        if (x < -818323753292969962227) return 0;
        // Transform so that e^x -> 2^x
        x = x * int(ONE) / int(LN2);
        // 2^x = 2^whole(x) * 2^frac(x)
        //       ^^^^^^^^^^ is a bit shift
        // so Taylor expand on z = frac(x)
        int shift;
        uint z;
        if (x >= 0) {
            shift = x / int(ONE);
            z = uint(x % int(ONE));
        } else {
            shift = x / int(ONE) - 1;
            z = ONE - uint(-x % int(ONE));
        }
        // 2^x = 1 + (ln 2) x + (ln 2)^2/2! x^2 + ...
        //
        // Can generate the z coefficients using mpmath and the following lines
        // >>> from mpmath import mp
        // >>> mp.dps = 100
        // >>> ONE =  0x10000000000000000
        // >>> print('\n'.join(hex(int(mp.log(2)**i / mp.factorial(i) * ONE)) for i in range(1, 7)))
        // 0xb17217f7d1cf79ab
        // 0x3d7f7bff058b1d50
        // 0xe35846b82505fc5
        // 0x276556df749cee5
        // 0x5761ff9e299cc4
        // 0xa184897c363c3
        uint zpow = z;
        uint result = ONE;
        result += 0xb17217f7d1cf79ab * zpow / ONE;
        zpow = zpow * z / ONE;
        result += 0x3d7f7bff058b1d50 * zpow / ONE;
        zpow = zpow * z / ONE;
        result += 0xe35846b82505fc5 * zpow / ONE;
        zpow = zpow * z / ONE;
        result += 0x276556df749cee5 * zpow / ONE;
        zpow = zpow * z / ONE;
        result += 0x5761ff9e299cc4 * zpow / ONE;
        zpow = zpow * z / ONE;
        result += 0xa184897c363c3 * zpow / ONE;
        zpow = zpow * z / ONE;
        result += 0xffe5fe2c4586 * zpow / ONE;
        zpow = zpow * z / ONE;
        result += 0x162c0223a5c8 * zpow / ONE;
        zpow = zpow * z / ONE;
        result += 0x1b5253d395e * zpow / ONE;
        zpow = zpow * z / ONE;
        result += 0x1e4cf5158b * zpow / ONE;
        zpow = zpow * z / ONE;
        result += 0x1e8cac735 * zpow / ONE;
        zpow = zpow * z / ONE;
        result += 0x1c3bd650 * zpow / ONE;
        zpow = zpow * z / ONE;
        result += 0x1816193 * zpow / ONE;
        zpow = zpow * z / ONE;
        result += 0x131496 * zpow / ONE;
        zpow = zpow * z / ONE;
        result += 0xe1b7 * zpow / ONE;
        zpow = zpow * z / ONE;
        result += 0x9c7 * zpow / ONE;
        if (shift >= 0) {
            if (result >> (uint(256) - uint(shift)) > 0) return (2 ** 256 - 1);
            return result << uint(shift);
        } else return result >> uint(-shift);
    }

    function positiveExponential(uint _x) internal pure returns (uint) {
        int x = int(_x * ONE / ONE_18);
        return exp(x) * ONE_18 / ONE;
    }

    function negativeExponential(uint _x) internal pure returns (uint) {
        int x = -1 * int(_x * ONE / ONE_18);
        return exp(x) * ONE_18 / ONE;
    }

    /// @notice Calculates the slippage value Si for a token i
    /// @dev if lr <= k, slippage = a*e^(-n*lr)
    /// @dev if 2k > lr > k, slippage = a*(e^(n(lr - 2k)) - 2(e^(-n*k) - e^(-n*lr)))
    /// @param lr liquidity ratio of the token
    /// @param slippageA slippage parameter A
    /// @param slippageN slippage parameter N
    /// @param slippageK slippage parameter K
    /// @return Slippage value in 18 decimals
    function getSlippage(uint256 lr, uint256 slippageA, uint256 slippageN, uint256 slippageK) external pure override returns (uint256) {
        if (lr <= slippageK) {
            return slippageA * negativeExponential(slippageN * lr) / 10;
        } else if (lr < 2 * slippageK) {
            return
                (slippageA *
                    (negativeExponential(slippageN * (2 * slippageK - lr)) -
                        2 *
                        (negativeExponential(slippageN * slippageK) - negativeExponential(slippageN * lr)))) / 10;
        } else {    // cap slippage for very high lr
            return slippageA * ONE_18 / 10;
        }
    }

}