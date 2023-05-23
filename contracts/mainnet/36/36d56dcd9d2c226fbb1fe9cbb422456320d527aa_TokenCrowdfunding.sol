/**
 *Submitted for verification at polygonscan.com on 2023-05-23
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TokenCrowdfunding {
    string public tokenName;
    string public tokenSymbol;
    uint256 public tokenDecimals;
    uint256 public tokenTotalSupply;
    uint256 public tokenPrice;
    uint256 public targetAmount;
    uint256 public minContribution;
    uint256 public maxContribution;
    address payable public beneficiary;
    address public contractOwner;
    uint256 public totalContributions;
    bool public isActive;

    mapping(address => uint256) public tokenBalances;
    mapping(address => uint256) public contributions;
    mapping(address => mapping(address => uint256)) private allowances;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Contribution(address indexed contributor, uint256 amount);
    event FundingCompleted(uint256 totalContributions);

    modifier onlyOwner() {
        require(msg.sender == contractOwner, "Only the contract owner can perform this action");
        _;
    }

    constructor(
        string memory _tokenName,
        string memory _tokenSymbol,
        uint256 _tokenDecimals,
        uint256 _tokenTotalSupply,
        uint256 _tokenPrice,
        uint256 _targetAmount,
        uint256 _minContribution,
        uint256 _maxContribution,
        address payable _beneficiary
    ) {
        tokenName = _tokenName;
        tokenSymbol = _tokenSymbol;
        tokenDecimals = _tokenDecimals;
        tokenTotalSupply = _tokenTotalSupply * (10**tokenDecimals);
        tokenPrice = _tokenPrice;
        targetAmount = _targetAmount;
        minContribution = _minContribution;
        maxContribution = _maxContribution;
        beneficiary = _beneficiary;
        contractOwner = msg.sender;
        isActive = true;

        tokenBalances[beneficiary] = tokenTotalSupply;
    }

    function contribute() external payable {
        require(isActive, "Funding is currently not active");
        require(msg.value >= minContribution, "Contribution amount is below the minimum");
        require(msg.value <= maxContribution, "Contribution amount exceeds the maximum");

        totalContributions += msg.value;
        contributions[msg.sender] += msg.value;
        emit Contribution(msg.sender, msg.value);

        if (totalContributions >= targetAmount) {
            emit FundingCompleted(totalContributions);
            isActive = false;
            uint256 tokensToTransfer = totalContributions * (10**tokenDecimals) / tokenPrice;
            require(tokenBalances[beneficiary] >= tokensToTransfer, "Insufficient tokens in the contract");
            tokenBalances[beneficiary] -= tokensToTransfer;
            tokenBalances[msg.sender] += tokensToTransfer;
            beneficiary.transfer(address(this).balance);
        }
    }

    function balanceOf(address account) public view returns (uint256) {
        return tokenBalances[account];
    }

    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        uint256 currentAllowance = allowances[sender][msg.sender];
        require(currentAllowance >= amount, "Transfer amount exceeds allowance");
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, currentAllowance - amount);
        return true;
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function allowance(address tokenOwner, address spender) public view returns (uint256) {
        return allowances[tokenOwner][spender];
    }

    function withdrawFunds() external onlyOwner {
    require(address(this).balance > 0, "No funds available to withdraw");
    payable(contractOwner).transfer(address(this).balance);
}


    function end() external onlyOwner {
        require(!isActive, "Funding is still active");
        isActive = false;
    }

    function renounceOwnership() external onlyOwner {
        contractOwner = address(0);
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "Transfer from the zero address");
        require(recipient != address(0), "Transfer to the zero address");
        require(tokenBalances[sender] >= amount, "Insufficient balance");

        tokenBalances[sender] -= amount;
        tokenBalances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "Approve from the zero address");
        require(spender != address(0), "Approve to the zero address");

        allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}