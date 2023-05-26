/**
 *Submitted for verification at polygonscan.com on 2023-05-25
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ERC721 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    function _mint(address to, uint256 tokenId) internal {}
}

contract Ownable {
    address private _owner;

    modifier onlyOwner() {
        require(msg.sender == _owner, "Only the owner can call this function");
        _;
    }

    constructor() {
        _owner = msg.sender;
    }

    function owner() public view returns (address) {
        return _owner;
    }
}

contract PolygonInvestmentContract is ERC721, Ownable {
    struct Investment {
        uint256 amount;
        bool exists;
    }

    mapping(address => Investment) public investments;
    mapping(uint256 => address) public tokenOwners;
    mapping(address => uint256) public tokenBalances;
    uint256 public totalInvestment;
    int256 public totalProfit;

    event Invested(address indexed investor, uint256 amount);
    event Withdrawn(address indexed owner, uint256 amount);
    event Deposit(address indexed depositor, uint256 amount);

    constructor() {
        totalInvestment = 0;
    }

    function invest() external payable {
        require(msg.value > 0, "Investment amount must be greater than 0");
        require(investments[msg.sender].exists == false, "Investor already exists");

        investments[msg.sender] = Investment(msg.value, true);
        totalInvestment += msg.value;

        uint256 tokenId = totalInvestment;
        _mint(msg.sender, tokenId);
        tokenOwners[tokenId] = msg.sender;
        tokenBalances[msg.sender] += 1;

        emit Invested(msg.sender, msg.value);
        emit Transfer(address(0), msg.sender, tokenId);
    }

    function distributeProfitAndLoss(int256 amount) external onlyOwner {
        require(totalInvestment > 0, "No investments to distribute profit or loss");

        int256 netAmount = int256(address(this).balance) + amount;

        require(netAmount >= 0, "Loss amount exceeds contract balance");

        int256 totalInvestmentSigned = int256(totalInvestment);

        for (uint256 i = 1; i <= totalInvestment; i++) {
            address investor = tokenOwners[i];
            uint256 investmentAmount = investments[investor].amount;

            int256 investorShare = (int256(investmentAmount) * amount) / totalInvestmentSigned;
            uint256 totalAmount;

            if (investorShare >= 0) {
                totalAmount = investmentAmount + uint256(investorShare);
            } else {
                totalAmount = investmentAmount - uint256(-investorShare);
            }

            investments[investor].amount = totalAmount;

            // Transfer the funds to the investor's wallet
            payable(investor).transfer(totalAmount);
        }
    }

    function depositFunds() external payable onlyOwner {
        require(msg.value > 0, "Deposit amount must be greater than 0");
        emit Deposit(msg.sender, msg.value);
    }

    function withdrawFunds() external onlyOwner {
        uint256 contractBalance = address(this).balance;
        require(contractBalance > 0, "No funds available to withdraw");

        payable(msg.sender).transfer(contractBalance);
        emit Withdrawn(msg.sender, contractBalance);
    }
}