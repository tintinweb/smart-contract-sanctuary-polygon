pragma solidity ^0.8.0;

import "./DRAGTokenSale.sol";

contract DRAGTokenPublicSale is DRAGTokenSale
{
    constructor(address dragTokenAddress, uint256 _beginTime, uint256 _endTime, uint256 _minBuyAmount, uint256 _maxBuyAmount) DRAGTokenSale(1, dragTokenAddress, _beginTime, _endTime, _minBuyAmount, _maxBuyAmount) public
    {
        uint256[] memory unlockTokens = new uint256[](17);
        unlockTokens[0] = 29700000;
        setUnlockData(3, unlockTokens);
    }
}