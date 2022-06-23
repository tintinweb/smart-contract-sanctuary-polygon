/**
 *Submitted for verification at polygonscan.com on 2022-06-23
*/

// File contracts/IPair.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

interface IPair {
        function getReserves() external view returns (uint112, uint112, uint32);

        function token0() external view returns (address);

        function token1() external view returns (address);
}


// File contracts/IPairdyst.sol

interface IPairdyst {
        function getAmountOut(uint amountIn, address tokenIn) external view returns (uint);

        function token0() external view returns (address);

        function token1() external view returns (address);
}


// File contracts/SafeMath.sol

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


// File contracts/Utils.sol

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

        function dystGetAmountOut(address poolAddr, uint amountIn, bool zfo) public view returns (uint amountOut) {
                IPairdyst pool = IPairdyst(poolAddr);
                address tokenIn = zfo ? pool.token0() : pool.token1();
                amountOut = pool.getAmountOut(amountIn, tokenIn);
        }

        function getMultiPoolAmountOut(address[] calldata pools, uint[] calldata amountIns, bool[] calldata zfos, uint[] calldata types) public view returns (address[] memory resPool, uint[] memory amountsOut) {
                require(pools.length == amountIns.length, "pools and amountIn must be the same length");
                require(pools.length == zfos.length, "pools and zfo must be the same length");
                require(pools.length == types.length, "pools and types must be the same length");
                for (uint i = 0; i < pools.length; i++) {
                        address poolAddr = pools[i];
                        uint amountIn = amountIns[i];
                        bool zfo = zfos[i];
                        uint t = types[i];
                        if (t == 0) {
                                resPool[i] = poolAddr;
                                amountsOut[i] = getAmountOut(poolAddr, amountIn, zfo);
                        } else {
                                resPool[i] = poolAddr;
                                amountsOut[i] = dystGetAmountOut(poolAddr, amountIn, zfo);
                        }
                }
        }
}