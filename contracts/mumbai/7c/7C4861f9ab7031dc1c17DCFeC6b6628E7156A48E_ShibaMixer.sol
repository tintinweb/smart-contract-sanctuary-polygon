// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract ShibaMixer {

    struct Deal {
        mapping(address => uint256) deposit;
        uint256 depositSum;
        mapping(address => bool) claims;
        uint256 numClaims;
        uint256 claimSum;
        uint256 startTime;
        uint256 depositDurationInSec;
        uint256 claimDurationInSec;
        uint256 claimDepositInWei;
        uint256 claimValueInWei;
        uint256 minNumClaims;
        bool active;
        bool fullyFunded;
    }

    Deal[] public _deals;

    event NewDeal(address indexed user, uint indexed _dealId, uint _startTime, uint _depositDurationInHours, uint _claimDurationInHours, uint _claimUnitValueInWei, uint _claimDepositInWei, uint _minNumClaims, bool _success, string _err);
    event Claim(address indexed _claimer, uint indexed _dealId, bool _success, string _err);
    event Deposit(address indexed _depositor, uint indexed _dealId, uint _value, bool _success, string _err);
    event Withdraw(address indexed _withdrawer, uint indexed _dealId, uint _value, bool _public, bool _success, string _err);

    event EnoughClaims(uint indexed _dealId);
    event DealFullyFunded(uint indexed _dealId);

    enum ReturnValue {Ok, Error}

    constructor() {
    }

    function newDeal(uint _depositDurationInHours, uint _claimDurationInHours, uint _claimUintValueInWei, uint _claimDepositInWei, uint _minNumClaims) public returns (uint _dealId, ReturnValue _retVal) {
        uint256 dealId = _deals.length;
        if (_depositDurationInHours == 0 || _claimDurationInHours == 0) {
            emit NewDeal(msg.sender, dealId, 0, _depositDurationInHours, _claimDurationInHours, _claimUintValueInWei, _claimDepositInWei, _minNumClaims, false, "Duration must be > 0");
            return (dealId, ReturnValue.Error);
        }

        Deal storage deal = _deals[dealId];
        deal.depositSum = 0;
        deal.numClaims = 0;
        deal.claimSum = 0;
        deal.startTime = block.timestamp;
        deal.depositDurationInSec = _depositDurationInHours * 1 hours;
        deal.claimDurationInSec = _claimDurationInHours * 1 hours;
        deal.claimDepositInWei = _claimDepositInWei;
        deal.claimValueInWei = _claimUintValueInWei;
        deal.minNumClaims = _minNumClaims;
        deal.fullyFunded = false;
        deal.active = true;
        emit NewDeal(msg.sender, dealId, deal.startTime, _depositDurationInHours, _claimDurationInHours, _claimUintValueInWei, _claimDepositInWei, _minNumClaims, true, "");
        return (dealId, ReturnValue.Ok);
    }

    function makeClaim(uint256 _dealId) public payable returns (ReturnValue){
        Deal storage deal = _deals[_dealId];
        require(deal.active, "Deal is not active");
        require(!deal.fullyFunded, "Deal is fully funded");
        require(block.timestamp <= deal.startTime + deal.claimDurationInSec, "Claim period has ended");
        require(!deal.claims[msg.sender], "You have already claimed");
        require(msg.value == deal.claimDepositInWei, "Claim deposit must be equal to claim deposit in deal");

        deal.claims[msg.sender] = true;

        deal.numClaims++;
        deal.claimSum += msg.value;

        emit Claim(msg.sender, _dealId, true, "");
        if (deal.numClaims >= deal.minNumClaims) {
            emit EnoughClaims(_dealId);
        }
        return ReturnValue.Ok;
    }

    function makeDeposit(uint256 _dealId) public payable returns (ReturnValue){
        Deal storage deal = _deals[_dealId];
        require(msg.value > 0, "Deposit must be > 0");
        require(deal.active, "Deal is not active");
        require(!deal.fullyFunded, "Deal is fully funded");
        require(block.timestamp <= deal.startTime + deal.depositDurationInSec, "Deposit period has ended");
        require(!deal.claims[msg.sender], "You have already claimed");
        require(deal.deposit[msg.sender] == 0, "You have already deposited");

        deal.deposit[msg.sender] += msg.value;
        deal.depositSum += msg.value;

        emit Deposit(msg.sender, _dealId, msg.value, true, "");
        if (deal.depositSum >= deal.claimSum) {
            deal.fullyFunded = true;
            emit DealFullyFunded(_dealId);
        }
        return ReturnValue.Ok;
    }

    function withdraw(uint256 _dealId, uint256 _amount) public returns (ReturnValue){
        Deal storage deal = _deals[_dealId];
        bool enoughClaims = deal.numClaims >= deal.minNumClaims;

        if (enoughClaims) {
            require(block.timestamp > deal.startTime + deal.depositDurationInSec + deal.claimDurationInSec, "Claim period has not ended");
        } else {
            require(block.timestamp > deal.startTime + deal.depositDurationInSec, "Deposit period has not ended");
        }

        bool publicWithdraw = deal.fullyFunded && enoughClaims;
        uint withdrawAmount = publicWithdraw ? deal.deposit[msg.sender] : deal.deposit[msg.sender] - deal.claimDepositInWei;

        payable(msg.sender).transfer(_amount);

        emit Withdraw(msg.sender, _dealId, _amount, false, true, "");
        return ReturnValue.Ok;
    }

    function dealStatus(uint256 _dealId) public view returns (uint256 _depositSum, uint256 _numClaims, uint256 _claimSum, uint256 _startTime, uint256 _depositDurationInSec, uint256 _claimDurationInSec, uint256 _claimDepositInWei, uint256 _minNumClaims, bool _active, bool _fullyFunded) {
        Deal storage deal = _deals[_dealId];
        return (deal.depositSum, deal.numClaims, deal.claimSum, deal.startTime, deal.depositDurationInSec, deal.claimDurationInSec, deal.claimDepositInWei, deal.minNumClaims, deal.active, deal.fullyFunded);
    }

}