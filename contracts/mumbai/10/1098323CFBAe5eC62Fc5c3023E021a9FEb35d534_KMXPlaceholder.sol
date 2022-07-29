//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract KMXPlaceholder {
    event Transfer(address indexed from, address indexed to, uint256 value);

    function purchaseBurn(address user, uint256 amount)
        public
        returns (bool success)
    {
        emit Transfer(user, address(0), amount);
        return true;
    }

    function getTotalClaimable(address user) external view returns (uint256) {
        return 100000000000000000000000; // 100K in wei
    }

    function claimAllRewards(uint256[] memory tokensOfOwner)
        external
        returns (bool)
    {
        return true;
    }
}