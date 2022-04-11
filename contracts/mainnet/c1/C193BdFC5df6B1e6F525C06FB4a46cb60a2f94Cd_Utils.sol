// SPDX-License-Identifier: MIT
pragma solidity >=0.5.16;

import "./UintWei.sol";

library Utils {
    using UintWei for uint;

    uint constant e6 = 10 ** 6;

    // from @uniawap/v2-core/contracts/libraries/Math.sol

    function sqrt(uint y) public pure returns (uint) {
        uint z;
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
        return z;
    }

    function sqrtWei(uint y) public pure returns (uint) {
        uint z;
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y.div(x) + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
        return z;
    }

    function sqrtE6(uint y) public pure returns (uint) {
        uint z;
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y * e6 / x  + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
        return z;
    }
}

pragma solidity >=0.5.16;

library UintWei {
    // wei単位の値の乗算時のオーバーフロー防止
    uint constant EthWei = 10 ** 18;

    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b / EthWei;
    }

    function div(uint a, uint b) internal pure returns (uint c) {
        c = a * EthWei / b;
    }
}