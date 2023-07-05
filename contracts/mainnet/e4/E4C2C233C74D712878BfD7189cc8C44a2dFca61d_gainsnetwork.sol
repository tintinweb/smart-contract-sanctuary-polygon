/**
 *Submitted for verification at polygonscan.com on 2023-07-05
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract gainsnetwork {
    enum LimitOrder {
        TP,
        SL,
        LIQ,
        OPEN
    }
    struct Trade {
        address trader;
        uint pairIndex;
        uint index;
        uint initialPosToken; // 1e18
        uint positionSizeDai; // 1e18
        uint openPrice; // PRECISION
        bool buy;
        uint leverage;
        uint tp; // PRECISION
        uint sl; // PRECISION
    }
    function gain_network883718828(
        Trade memory t,
        LimitOrder orderType, // LEGACY => market
        uint spreadReductionId,
        uint slippageP, // for market orders only
        address referrer
    ) external {
        return;
    }
}