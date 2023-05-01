// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

contract ImpactChainInvest {
    address public owner;
// 
    struct ImpactChain {
        address investorAddress;
        string category;
        uint investmentId;
        uint startDate;
        uint maturityDate;
        uint profitRate;
        uint investedToken;
        uint investmentProfit;
        bool open;
    }

    ImpactChain investment;

    uint public currentInvestmentId;

    uint[] investmentDuration;

    mapping(uint => ImpactChain) public investments;

    mapping(address => uint[]) public investmentIdsByAddress;

    mapping(uint => uint) public waitPeriod;

    constructor() payable {
        owner = msg.sender;

        currentInvestmentId = 0;

        waitPeriod[60] = 200;
        waitPeriod[90] = 450;
        waitPeriod[180] = 600;
        waitPeriod[365] = 1000;

        investmentDuration.push(60);
        investmentDuration.push(90);
        investmentDuration.push(180);
        investmentDuration.push(365);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not the owner");
        _;
    }
    modifier onlyNonEmptyAddress(address _userAddress) {
        require(_userAddress != address(0), "Empty address");
        _;
    }

    function invest(uint numDays, string memory _category) external payable {
        require(waitPeriod[numDays] > 0, "Bad Duration");

        investments[currentInvestmentId] = ImpactChain(
            msg.sender,
            _category,
            currentInvestmentId,
            block.timestamp,
            block.timestamp + (numDays * 1 days),
            waitPeriod[numDays],
            msg.value,
            calculateInvestmentProfit(waitPeriod[numDays], msg.value),
            true
        );

        investmentIdsByAddress[msg.sender].push(currentInvestmentId);

        currentInvestmentId += 1;
    }

    function calculateInvestmentProfit(
        uint basisPoints,
        uint amountInWei
    ) internal pure returns (uint) {
        require(amountInWei > 0, "Invalid amount");

        uint totalProfit = (basisPoints * amountInWei) / 10000;

        return totalProfit;
    }

    function modifyInvestmentDuration(uint numDays, uint basisPoints) external onlyOwner {

        waitPeriod[numDays] = basisPoints;

        investmentDuration.push(numDays);
    }

    function getInvestmentDuration() external view returns (uint[] memory) {
        return investmentDuration;
    }

    function getProfitRate(uint numDays) external view returns (uint) {
        return waitPeriod[numDays];
    }

    function retrieveInvestment(
        uint investmentId
    ) external view returns (ImpactChain memory) {
        return investments[investmentId];
    }

    function getUserAddressInvestmentId(
        address investorAddress
    ) external view returns (uint[] memory) {
        return investmentIdsByAddress[investorAddress];
    }

    function setNewMaturityDate(
        uint investmentId,
        uint newMaturityDate
    ) external onlyOwner {
        require(investments[investmentId].open == true, "Investment is closed");
        require(
            newMaturityDate > investments[investmentId].maturityDate,
            "New unlock date must be after the current unlock date"
        );
        investments[investmentId].maturityDate = newMaturityDate;
    }

    function endInvestment(
        uint investmentId
    ) external onlyNonEmptyAddress(msg.sender) {
        require(
            investments[investmentId].investorAddress == msg.sender,
            "only investment creator may modify investment"
        );
        require(investments[investmentId].open == true, "Investment is closed");

        investments[investmentId].open = false;

        uint totalAmount = 0;

        if (block.timestamp > investments[investmentId].maturityDate) {
            totalAmount =
                investments[investmentId].investedToken +
                investments[investmentId].investmentProfit;
        } else {
            totalAmount = investments[investmentId].investedToken;
        }

        investments[investmentId].investedToken = 0;
        investments[investmentId].investmentProfit = 0;

        require(totalAmount > 0, "Investment amount is zero");

        (bool success, ) = payable(msg.sender).call{value: totalAmount}("");
        require(success, "Failed to send ether");
    }
}