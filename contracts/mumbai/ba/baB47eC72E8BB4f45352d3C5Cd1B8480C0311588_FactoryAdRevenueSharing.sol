// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

contract FactoryAdRevenueSharing {
    address public immutable operator;
    uint8 public operatorFee;
    uint256 public feeBalance;

    mapping(bytes32 => AdRevenueShare) public adRegistry;
    mapping(address => bytes32) public adOperator;

    error NotOperator();
    error FailedToWithdraw();

    constructor() {
        operator = msg.sender;
    }

    modifier onlyOperator() {
        if (msg.sender != operator) {
            revert NotOperator();
        }
        _;
    }

    function create(bytes32 adHash_) public {
        AdRevenueShare _ad = new AdRevenueShare(adHash_);
        adRegistry[adHash_] = _ad;
        adOperator[msg.sender] = adHash_;
    }

    function launchCampaign(bytes32 adHash_, uint256 toBlockTimestamp_) external payable {
        AdRevenueShare ad = adRegistry[adHash_];

        require(address(ad) != address(0), "Invalid adHash"); // Check if the adHash exists in the adRegistry
        require(adOperator[msg.sender] == adHash_, "Unauthorized"); // Check if the sender is the operator for the specified adHash

        uint256 factor = 100;
        uint256 _operatorFee = (operatorFee * factor * msg.value) / (100 * factor);

        feeBalance += _operatorFee;
        uint256 left = msg.value - _operatorFee;
        ad.launchCampaign{value: left}(toBlockTimestamp_);
    }

    function setOperatorFee(uint8 operatorFee_) external onlyOperator {
        require(operatorFee_ > 0 && operatorFee_ <= 100, "Invalid operator fee"); // Check if the operatorFee is within a valid range
        operatorFee = operatorFee_;
    }

    function withtdrawFees(address payable to, uint256 tokenAmount_) external onlyOperator {
        feeBalance -= tokenAmount_;

        (bool sent, ) = to.call{value: tokenAmount_}("");
        if (!sent) {
            revert FailedToWithdraw();
        }
    }
}

contract AdRevenueShare {
    address public campaignOperator;
    uint256 public fromBlockTimestamp;
    uint256 public toBlockTimestamp;

    uint256 public stakePoolBalance;
    uint256 public adCampaignBalance;

    bytes32 public adHash;

    address public registry;

    mapping(address => uint256) public userStake;

    error FailedToUnstake();
    error NotRegistry();

    modifier onlyRegistry() {
        if (msg.sender != registry) {
            revert NotRegistry();
        }
        _;
    }

    constructor(bytes32 adHash_) {
        adHash = adHash_;
        campaignOperator = msg.sender;
        registry = msg.sender;
    }

    function launchCampaign(uint256 toBlockTimestamp_) public payable onlyRegistry {
        require(adCampaignBalance == 0, "LC01");
        require(toBlockTimestamp_ > block.timestamp, "LC02");
        require(msg.value > 0, "LC03");

        fromBlockTimestamp = block.timestamp;
        toBlockTimestamp = toBlockTimestamp_;
        adCampaignBalance = msg.value;
    }

    function stake() public payable {
        require(fromBlockTimestamp < block.timestamp && block.timestamp < toBlockTimestamp);
        require(msg.value > 0);
        stakePoolBalance += msg.value;
        userStake[msg.sender] += msg.value;
    }

    function unstake() public {
        require(block.timestamp >= toBlockTimestamp);

        uint _userStake = userStake[msg.sender];
        require(_userStake > 0);
        userStake[msg.sender] = 0;

        // receive add revenue proportional to stake
        uint _adRevenue = (_userStake * adCampaignBalance) / stakePoolBalance;

        uint256 _reward = _userStake + _adRevenue;
        uint256 _balance = address(this).balance;
        // check if contract has sufficient balance
        require(_balance >= _reward);

        bool sent = payable(msg.sender).send(_reward);
        if (!sent) {
            revert FailedToUnstake();
        }
    }
}