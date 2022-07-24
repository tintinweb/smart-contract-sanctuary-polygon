// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

library PublicSaleLibrary {
    function calcPercent2Decimal(uint128 _a, uint128 _b) internal pure returns(uint128) {
        return (_a * _b) / 10000;
    }

    function calcAllocFromKom(uint128 _staked, uint128 _totalStaked, uint128 _sale) internal pure returns(uint128){
        return (((_staked * 10**8) / _totalStaked) * _sale) / 10**8;
    }

    function calcTokenReceived(uint128 _amountIn, uint128 _price) internal pure returns(uint128){
        return (_amountIn * 10**18) / _price;
    }

    function calcAmountIn(uint128 _received, uint128 _price) internal pure returns(uint128){
        return (_received * _price) / 10**18;
    }

    function calcWhitelist6Decimal(uint128 _allocation) internal pure returns(uint128){
        return (_allocation * 10**18) / 10**6;
    }
}