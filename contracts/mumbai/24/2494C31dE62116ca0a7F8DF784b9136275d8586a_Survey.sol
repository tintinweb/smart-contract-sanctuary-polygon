// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;
import "./IERC20.sol";

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
        //TODO: check whitelist
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