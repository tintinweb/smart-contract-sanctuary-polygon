/**
 *Submitted for verification at polygonscan.com on 2022-08-02
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface IERC20 {
    function totalSupply() external view returns (uint supply);
    function balanceOf(address _owner) external view returns (uint balance);
    function transfer(address _to, uint _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint _value) external returns (bool success);
    function approve(address _spender, uint _value) external returns (bool success);
    function allowance(address _owner, address _spender) external view returns (uint remaining);
    function decimals() external view returns(uint digits);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}

contract Survey {
    enum Status {
        pending,
        active,
        terminated
    }

    string public surveyIpfsAddress;
    uint256 public fundingTotal;
    uint256 public bounty;
    address public currency;
    address public owner;
    Status public status;
    mapping(address => string) public submissions;

    constructor(string memory _surveyIpfsAddress, address _currency, uint256 _bounty, address _owner){
        owner = _owner;
        surveyIpfsAddress = _surveyIpfsAddress;
        currency = _currency;
        bounty = _bounty;
        status = Status.pending;
    }

    modifier OnlyOwner {
        require(msg.sender == owner, "Only owner");
        _;
    }

    function initiateSurvey(uint256 _value) external OnlyOwner {
        require(status == Status.pending, "Survey already initiated");
        // TODO: add merkle tree root
        require(IERC20(currency).balanceOf(msg.sender) >= _value, "Not enough funds");
        IERC20(currency).transferFrom(msg.sender, address(this), _value);
        fundingTotal = IERC20(currency).balanceOf(address(this));
        status = Status.active;
    }

    function submitSurvey(string memory ipfsAddress) external returns (bool success) {
        require(bytes(submissions[msg.sender]).length == 0,"Existing submission");
        require(status == Status.active, "Survey not active");
        bool _success = claimBounty();

        if (_success) {
            submissions[msg.sender] = ipfsAddress;
            emit Submission(msg.sender, ipfsAddress, block.timestamp, surveyIpfsAddress, owner);
            return true;
        } else {
            status = Status.terminated;
            return false;
        }
    }

    function claimBounty() internal returns (bool success) {
        if (fundingTotal < bounty) {
            return false;
        } else {
            fundingTotal -= bounty;
            IERC20(currency).transfer(msg.sender, bounty);
            return true;
        }
    }

    function terminateSurvey() external OnlyOwner {
        require(status != Status.terminated, "Already terminated");
        status = Status.terminated;
        uint256 balance = IERC20(currency).balanceOf(address(this));
        IERC20(currency).transfer(owner, balance);
    }

    event Submission(address indexed contributor, string surveyIpfsAddress, uint256 submissionDate, string surveyAddress, address surveyOwner);
}