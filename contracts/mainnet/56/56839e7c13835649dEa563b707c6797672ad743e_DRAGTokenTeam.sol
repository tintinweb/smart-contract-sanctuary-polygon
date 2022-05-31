pragma solidity ^0.8.0;

import "./DRAGTokenUnlock.sol";

contract DRAGTokenTeam is DRAGTokenUnlock
{
    constructor(address dragTokenAddress) DRAGTokenUnlock(dragTokenAddress) public
    {
        uint256[] memory unlockTokens = new uint256[](17);
        for (uint256 i = 4; i <= 16; i+=2)
        {
            unlockTokens[i] = 5400000;
        }
        unlockTokens[0] = 16200000;
        setUnlockData(3, unlockTokens);
    }

    function withdraw(uint256 amount) external whenNotPaused nonReentrant
    {
        withdrawUnlockTokenToWallet(amount);
    }
}