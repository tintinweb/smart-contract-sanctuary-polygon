pragma solidity ^0.8.0;

import "./DRAGTokenSale.sol";

contract DRAGTokenPrivateSale is DRAGTokenSale
{
    constructor(address dragTokenAddress, uint256 _beginTime, uint256 _endTime, uint256 _minBuyAmount, uint256 _maxBuyAmount) DRAGTokenSale(dragTokenAddress, _beginTime, _endTime, _minBuyAmount, _maxBuyAmount) public
    {
        uint256[] memory unlockTokens = new uint256[](17);
        for (uint256 i = 0; i <= 8; i+=2)
        {
            unlockTokens[i] = 2160000;
        }
        setUnlockData(3, unlockTokens);
    }
}