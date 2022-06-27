// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.3;

contract SimpleFaucet {
    event DonationReceived(address sender, uint256 amount);
    event LockPeriodSet(uint256 amount);
    event DistributionAmountSet(uint256 amount);
    event AmountAllowedSet(uint256 amount);
    event TokensDistributed(address receiver, uint256 amount);

    address internal owner;
    uint256 internal distributionAmount = 20000000000000000; //0.02
    uint256 internal lockPeriod = 86400; // 24 hours

    mapping(address => uint256) internal unlockTime;
    mapping(address => bool) internal approvedCallers;

    constructor() payable {
        owner = msg.sender;
        approvedCallers[msg.sender] = true;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "SF:E-001");
        _;
    }

    modifier onlyApprovedCallers() {
        require(approvedCallers[msg.sender], "SF:E-002");
        _;
    }

    function setOwner(address newOwner) external onlyOwner {
        owner = newOwner;
    }

    function setApprovedCallers(address newApprovedCaller) external onlyOwner {
        approvedCallers[newApprovedCaller] = true;
    }

    function setDistributionAmount(uint256 newDistributionAmount)
        external
        onlyOwner
    {
        distributionAmount = newDistributionAmount;
        emit DistributionAmountSet(newDistributionAmount);
    }

    function setLockPeriod(uint256 newLockPeriod) external onlyOwner {
        lockPeriod = newLockPeriod;
        emit LockPeriodSet(newLockPeriod);
    }

    function distributeTokens(address[] memory receivers)
        public
        payable
        onlyApprovedCallers
    {
        require(receivers.length <= 100, "SF:E-003");
        for (uint256 i = 0; i < receivers.length; ) {
            require(block.timestamp > unlockTime[receivers[i]], "SF:E-004");
            require(address(this).balance >= distributionAmount, "SF:E-005");
            unlockTime[receivers[i]] = block.timestamp + lockPeriod;
            payable(receivers[i]).transfer(distributionAmount);

            unchecked {
                i++;
            }
        }
    }

    function getOwner() external view returns (address) {
        return owner;
    }

    function getApprovedCaller(address caller) external view returns (bool) {
        return approvedCallers[caller];
    }

    function getDistributionAmount() external view returns (uint256) {
        return distributionAmount;
    }

    function getLockPeriod() external view returns (uint256) {
        return lockPeriod;
    }

    function getUnlockTime(address account) external view returns (uint256) {
        return unlockTime[account];
    }

    receive() external payable {
        emit DonationReceived(msg.sender, msg.value);
    }
}