/**
 *Submitted for verification at polygonscan.com on 2023-05-31
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract ProjectToken is IERC20 {
    string public name;
    string public symbol;
    uint8  public decimals = 18;
    
    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowances;
    uint256 private totalTokenSupply;

    IERC20 public rocketToken;
    
    uint256 public taxRate; // Tax rate in percentage (e.g., 1%)
    
    struct Presale {
        uint256 amount;
        uint256 price;
        uint256 startTime;
        uint256 endTime;
        uint256 tokensSold;
        bool closed;
    }
    
    mapping(address => Presale) private presales;
    
    constructor(
        string memory tokenName,
        string memory tokenSymbol,
        uint256 initialSupply,
        uint256 presaleAmount,
        uint256 price,
        uint256 startTime,
        uint256 endTime,
        address rocketTokenAddr
    ) {
        rocketToken = IERC20(rocketTokenAddr);
        name = tokenName;
        symbol = tokenSymbol;
        totalTokenSupply = initialSupply * 10 ** decimals;
        balances[msg.sender] = totalTokenSupply - (totalTokenSupply * 6) / 100;
        balances[rocketTokenAddr] = (totalTokenSupply * 6) / 100;
        taxRate = 0;
       
        addPresale(address(this), presaleAmount, price, startTime, endTime);
        emit Transfer(address(0), msg.sender, totalTokenSupply);
    }
    
    function addPresale(
        address recipient,
        uint256 amount,
        uint256 price,
        uint256 startTime,
        uint256 endTime
    ) internal  {
        require(presales[recipient].startTime == 0, "Presale already exists for the recipient");
        require(endTime > startTime, "Invalid presale end time");  
        presales[recipient] = Presale(amount, price, startTime, endTime, 0, false);
    }
    
    function totalSupply() external view override returns (uint256) {
        return totalTokenSupply;
    }
    
    function balanceOf(address account) external view override returns (uint256) {
        return balances[account];
    }
    
    function transfer(address recipient, uint256 amount) external override returns (bool) {
        require(amount > 0, "Invalid transfer amount");
        require(balances[msg.sender] >= amount, "Insufficient balance");
        
        uint256 taxAmount = amount * taxRate / 100;
        uint256 transferAmount = amount - taxAmount;
        
        balances[msg.sender] -= amount;
        balances[recipient] += transferAmount;
        balances[address(this)] += taxAmount;
        
        emit Transfer(msg.sender, recipient, transferAmount);
        emit Transfer(msg.sender, address(this), taxAmount);
        
        return true;
    }
    
    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        require(amount > 0, "Invalid transfer amount");
        require(balances[sender] >= amount, "Insufficient balance");
        require(allowances[sender][msg.sender] >= amount, "Insufficient allowance");
        
        uint256 taxAmount = amount * taxRate / 100;
        uint256 transferAmount = amount - taxAmount;
        
        balances[sender] -= amount;
        balances[recipient] += transferAmount;
        balances[address(this)] += taxAmount;
        allowances[sender][msg.sender] -= amount;
        
        emit Transfer(sender, recipient, transferAmount);
        emit Transfer(sender, address(this), taxAmount);
        
        return true;
    }
    
    function approve(address spender, uint256 amount) external override returns (bool) {
        allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }
    
    function allowance(address owner, address spender) external view override returns (uint256) {
        return allowances[owner][spender];
    }
}

contract FactoryContract {
    struct TokenInfo {
        address tokenAddress;
        string name;
        string symbol;
    }
    
    TokenInfo[] public deployedTokens;
    
    event TokenDeployed(address indexed tokenAddress, string name, string symbol);
    
    function createToken(
        string memory name,
        string memory symbol,
        uint256 initialSupply,
        uint256 presaleAmount,
        uint256 price,
        uint256 startTime,
        uint256 endTime,
        address rocketTokenAddr
    ) external {
        ProjectToken newToken = new ProjectToken(
            name,
            symbol,
            initialSupply,
            presaleAmount,
            price,
            startTime,
            endTime,
            rocketTokenAddr
        );
        
        address tokenAddress = address(newToken);
        
        TokenInfo memory tokenInfo = TokenInfo(tokenAddress, name, symbol);
        deployedTokens.push(tokenInfo);
        
        emit TokenDeployed(tokenAddress, name, symbol);
    }
}