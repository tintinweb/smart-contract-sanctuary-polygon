// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

contract AgroStake {
    address public owner;

    struct AgroInvestment {
        address investorAddress;
        string investCategory;
        uint investmentId;
        uint startDate;
        uint maturityDate;
        uint interestRate;
        uint investedToken;
        uint investmentInterest;
        bool open;
    }

    AgroInvestment investment;

    uint public currentInvestmentId;

    uint[] investmentDuration;

    mapping(uint => AgroInvestment) public investments;

    mapping(address => uint[]) public investmentIdsByAddress;

    mapping(uint => uint) public agroStakePeriod;

    constructor() payable {
        owner = msg.sender;

        currentInvestmentId = 0;

        agroStakePeriod[60] = 200;
        agroStakePeriod[90] = 450;
        agroStakePeriod[180] = 600;
        agroStakePeriod[365] = 1000;

        investmentDuration.push(60);
        investmentDuration.push(90);
        investmentDuration.push(180);
        investmentDuration.push(365);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not the owner");
        _;
    }
    modifier onlyNonEmptyAddress(address addr) {
        require(addr != address(0), "Address cannot be empty");
        _;
    }

    function invest(uint numDays, string memory _category) external payable {
        require(agroStakePeriod[numDays] > 0, "Bad Duration");

        investments[currentInvestmentId] = AgroInvestment(
            msg.sender,
            _category,
            currentInvestmentId,
            block.timestamp,
            block.timestamp + (numDays * 1 days),
            agroStakePeriod[numDays],
            msg.value,
            calculateInvestmentInterest(agroStakePeriod[numDays], msg.value),
            true
        );

        investmentIdsByAddress[msg.sender].push(currentInvestmentId);

        currentInvestmentId += 1;
    }

    function calculateInvestmentInterest(
        uint basisPoints,
        uint amountInWei
    ) private pure returns (uint) {
        require(amountInWei > 0, "Invalid amount");

        uint totalInterest = (basisPoints * amountInWei) / 10000;

        return totalInterest;
    }

    function modifyInvestmentDuration(uint numDays, uint basisPoints) external {
        require(
            owner == msg.sender,
            "Only fund Manager can modify Investment Duration"
        );

        agroStakePeriod[numDays] = basisPoints;

        investmentDuration.push(numDays);
    }

    function getInvestmentDuration() external view returns (uint[] memory) {
        return investmentDuration;
    }

    function getInterestRate(uint numDays) external view returns (uint) {
        return agroStakePeriod[numDays];
    }

    function retrieveInvestment(
        uint investmentId
    ) external view returns (AgroInvestment memory) {
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
                investments[investmentId].investmentInterest;
        } else {
            totalAmount = investments[investmentId].investedToken;
        }

        investments[investmentId].investedToken = 0;
        investments[investmentId].investmentInterest = 0;

        require(totalAmount > 0, "Investment amount is zero");

        (bool success, ) = payable(msg.sender).call{value: totalAmount}("");
        require(success, "Failed to send ether");
    }
}