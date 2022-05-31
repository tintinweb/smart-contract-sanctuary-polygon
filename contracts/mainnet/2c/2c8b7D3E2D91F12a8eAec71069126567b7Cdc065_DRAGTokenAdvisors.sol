pragma solidity ^0.8.0;

import "./DRAGTokenUnlock.sol";

contract DRAGTokenAdvisors is DRAGTokenUnlock
{
    constructor(address dragTokenAddress) DRAGTokenUnlock(dragTokenAddress) public
    {
        uint256[] memory unlockTokens = new uint256[](17);
        unlockTokens[0] = 4725000;
        unlockTokens[2] = 1890000;
        unlockTokens[4] = 2835000;
        unlockTokens[6] = 2835000;
        unlockTokens[8] = 2835000;
        unlockTokens[10] = 2835000;
        unlockTokens[12] = 945000;
        setUnlockData(3, unlockTokens);
    }

    function withdraw(uint256 amount) external whenNotPaused nonReentrant
    {
        withdrawUnlockTokenToWallet(amount);
    }
}