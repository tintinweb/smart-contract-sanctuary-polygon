pragma solidity ^0.8.0;

import "./DRAGTokenUnlock.sol";

contract DRAGTokenEcosystem is DRAGTokenUnlock
{
    constructor(address dragTokenAddress) DRAGTokenUnlock(dragTokenAddress) public
    {
        uint256[] memory unlockTokens = new uint256[](32);
        for (uint256 i = 0 ; i < 32; i++)
        {
            unlockTokens[i] = 675000;
        }
        setUnlockData(1, unlockTokens);
    }

    function withdraw(uint256 amount) external whenNotPaused nonReentrant
    {
        withdrawUnlockTokenToWallet(amount);
    }
}