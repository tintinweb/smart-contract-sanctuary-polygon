/**
 *Submitted for verification at polygonscan.com on 2022-06-23
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

library SafeMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }
}

interface IPair {
        function getReserves() external view returns (uint112, uint112, uint32);

        function token0() external view returns (address);

        function token1() external view returns (address);
}

contract Utils {
        using SafeMath for uint;

        function getAmountOut(address poolAddr, uint amountIn, bool zfo) public view returns (uint amountOut) {
                IPair pool = IPair(poolAddr);
                (uint rs0, uint rs1,) = pool.getReserves();
                uint reserve0 = zfo ? rs0 : rs1;
                uint reserve1 = zfo ? rs1 : rs0;
                require(amountIn > 0, "amountIn must be greater than 0");
                require(reserve0 > 0, "Insufficient liquidity in pool");
                require(reserve1 > 0, "Insufficient liquidity in pool");
                uint amountInWithFee = amountIn.mul(997);
                uint numerator = amountInWithFee.mul(reserve1);
                uint denominator = reserve0.mul(1000).add(amountInWithFee);
                amountOut = numerator / denominator;
        }
}