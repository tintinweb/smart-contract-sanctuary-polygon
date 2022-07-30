//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/**
 * @title Balancer
 * @author Jack Chuma
 * @dev Computes out-given-in amounts based on balancer trading formulas that maintain a ratio of tokens in a contract
 * @dev wI and wO currently omitted from this implementation since they will always be equal for MHU
 */
library Balancer {
    /*
     * aO - amount of token o being bought by trader
     * bO - balance of token o, the token being bought by the trader
     * bI - balance of token i, the token being sold by the trader
     * aI - amount of token i being sold by the trader
     * wI - the normalized weight of token i
     * wO - the normalized weight of token o
    */
    uint256 public constant BONE = 10 ** 18;

    /**********************************************************************************
    // Out-Given-In                                                                  //
    // aO = amountO                                                                  //
    // bO = balanceO                    /      /     bI        \    (wI / wO) \      //
    // bI = balanceI         aO = bO * |  1 - | --------------  | ^            |     //
    // aI = amountI                     \      \   bI + aI     /              /      //
    // wI = weightI                                                                  //
    // wO = weightO                                                                  //
    **********************************************************************************/
    function outGivenIn(
        uint256 balanceO,
        uint256 balanceI,
        uint256 amountI
    ) internal pure returns (uint256 amountO) {
        uint y = bdiv(balanceI, (balanceI + amountI));
        uint foo = BONE - y;
        amountO = bmul(balanceO, foo);
    }

    /**********************************************************************************
    // calcInGivenOut                                                                //
    // aI = tokenAmountIn                 /  /     bO      \       \                 //
    // bO = tokenBalanceOut   aI =  bI * |  | ------------  |  - 1  |                //
    // bI = tokenBalanceIn                \  \ ( bO - aO ) /       /                 //
    // aO = tokenAmountOut                                                           //
    **********************************************************************************/
    function inGivenOut(
        uint tokenBalanceIn,
        uint tokenBalanceOut,
        uint tokenAmountOut
    )
        public pure
        returns (uint tokenAmountIn)
    {
        uint y = bdiv(tokenBalanceOut, (tokenBalanceOut - tokenAmountOut));
        tokenAmountIn = bmul(tokenBalanceIn, (y - BONE));
    }

    function bdiv(uint a, uint b)
        internal pure
        returns (uint)
    {
        uint c0 = a * BONE;
        uint c1 = c0 + (b / 2);
        uint c2 = c1 / b;
        return c2;
    }

    function bmul(uint a, uint b)
        internal pure
        returns (uint)
    {
        uint c0 = a * b;
        uint c1 = c0 + (BONE / 2);
        uint c2 = c1 / BONE;
        return c2;
    }
}