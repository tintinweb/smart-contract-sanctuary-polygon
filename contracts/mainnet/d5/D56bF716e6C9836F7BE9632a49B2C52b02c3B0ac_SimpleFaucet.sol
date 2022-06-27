// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.3;

contract SimpleFaucet {
    event DonationReceived(address sender, uint256 amount);
    event LockPeriodSet(uint256 amount);
    event AmountAllowedSet(uint256 amount);
    event TokensDistributed(address receiver, uint256 amount);

    address internal owner;
    uint256 internal distributionAmount = 20000000000000000; //0.02
    uint256 internal lockPeriod = 86400; // 24 hours

    mapping(address => uint256) public unlockTime;

    constructor() payable {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "SF:E-001");
        _;
    }

    function setOwner(address newOwner) public onlyOwner {
        owner = newOwner;
    }

    function setLockPeriod(uint256 newLockPeriod) public onlyOwner {
        lockPeriod = newLockPeriod;
        emit LockPeriodSet(newLockPeriod);
    }

    function distributeTokens(address[] memory receivers) public payable {
        for (uint256 i = 0; i < receivers.length; ) {
            require(block.timestamp > unlockTime[receivers[i]], "SF:E-002");
            require(address(this).balance >= distributionAmount, "SF:E-003");
            unlockTime[receivers[i]] = block.timestamp + lockPeriod;
            payable(receivers[i]).transfer(distributionAmount);

            unchecked {
                i++;
            }
        }
    }

    function getUnlockTime(address account) external view returns (uint256) {
        return unlockTime[account];
    }

    function getOwner() external view returns (address) {
        return owner;
    }

    function getDistributionAmount() external view returns (uint256) {
        return distributionAmount;
    }

    receive() external payable {
        emit DonationReceived(msg.sender, msg.value);
    }
}