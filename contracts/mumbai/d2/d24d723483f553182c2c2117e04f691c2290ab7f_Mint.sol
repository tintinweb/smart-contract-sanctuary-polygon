// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "Ownable.sol";


interface IToken {
    function transferOwnership(address newOwner) external;
    function mint(address to, uint256 amount) external;
}

contract Mint is Ownable {
    IToken private token;
    uint256 public firstBlock;
    uint256 public rewardPerBlock;
    uint256 public totalReward;

    constructor() {
        token = IToken(address(0x44cC02C8b5F19a426fd4e4c2C0FC79D66efb9250));
        firstBlock = block.number;
        rewardPerBlock = 100;
    }

    function transferOwnerToken(address  _address) public onlyOwner {
        token.transferOwnership(_address);
    }

    function claimRewards() public onlyOwner {
        uint256 reward = (block.number - firstBlock) * rewardPerBlock;
        token.mint(msg.sender, reward);
        totalReward = totalReward + reward;
    }

    function claimRewardsTest(uint256  blockNumber) public onlyOwner {
        uint256 reward = (blockNumber - firstBlock) * rewardPerBlock;
        token.mint(msg.sender, reward);
        totalReward = totalReward + reward;
    }
    
}