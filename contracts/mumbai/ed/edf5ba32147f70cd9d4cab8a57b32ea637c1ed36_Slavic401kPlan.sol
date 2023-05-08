/**
 *Submitted for verification at polygonscan.com on 2023-05-08
*/

pragma solidity ^0.8.0;

interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
}

contract Slavic401kPlan {
    address private _owner;
    uint private _totalBalance;
    uint private _withdrawalPeriod;
    mapping(address => uint) private _balances;
    mapping(address => uint) private _employeeDeposits;
    mapping(address => uint) private _employerDeposits;
    IERC20 private _token;
    uint private _percentageReturn;

    constructor(
        // address tokenAddress, 
    uint withdrawalPeriod, uint percentageReturn) {
        _owner = msg.sender;
        // _token = IERC20(tokenAddress);
        _withdrawalPeriod = withdrawalPeriod;
        _percentageReturn = percentageReturn;
    }

    modifier onlyOwner() {
        require(msg.sender == _owner, "Only the contract owner can perform this action.");
        _;
    }

    function employeeDeposit(uint amount ,address _tokenaddress) external {
        _token = IERC20(_tokenaddress);
        require(_token.allowance(msg.sender, address(this)) >= amount, "You must first approve the transfer of tokens.");
        require(_token.balanceOf(msg.sender) >= amount, "You do not have enough tokens to perform this transaction.");

        _employeeDeposits[msg.sender] += amount;
        _balances[msg.sender] += amount;
        _totalBalance += amount;
    }

    function employerDeposit(address employee, uint amount,address _tokenaddress) external onlyOwner {
        _token = IERC20(_tokenaddress);
        require(_token.allowance(msg.sender, address(this)) >= amount, "You must first approve the transfer of tokens.");
        require(_token.balanceOf(msg.sender) >= amount, "You do not have enough tokens to perform this transaction.");

        _employerDeposits[employee] += amount;
        _balances[employee] += amount;
        _totalBalance += amount;
    }

    function withdraw(address _tokenaddress) external {
        require(_balances[msg.sender] > 0, "You do not have any tokens to withdraw.");
        require(block.timestamp >= _withdrawalPeriod, "The withdrawal period has not yet ended.");

        uint totalWithdrawalAmount = _balances[msg.sender] + calculateInterest(_balances[msg.sender]);
        _token = IERC20(_tokenaddress);
        require(_token.transfer(msg.sender, totalWithdrawalAmount), "Token transfer failed.");

        _balances[msg.sender] = 0;
        _employeeDeposits[msg.sender] = 0;
        _totalBalance -= totalWithdrawalAmount;
    }

    function calculateInterest(uint amount) private view returns (uint) {
        return (amount * _percentageReturn) / 100;
    }

    function changePercentageReturn(uint percentageReturn) external onlyOwner {
        _percentageReturn = percentageReturn;
    }

    function getTotalBalance() external view returns (uint) {
        return _totalBalance;
    }

    function getBalance(address account) external view returns (uint) {
        return _balances[account];
    }

    function getEmployeeDeposit(address employee) external view returns (uint) {
        return _employeeDeposits[employee];
    }

    function getEmployerDeposit(address employee) external view onlyOwner returns (uint) {
        return _employerDeposits[employee];
    }
}