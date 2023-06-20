// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";

contract ERC20 is IERC20 {
    string private _name;
    string private _symbol;
    uint8 public _decimals;
    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    function name() public view override returns (string memory) {
        return _name;
    }

    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    function decimals() external view override returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender] - amount);
    return true;        
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] -= amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;

        emit Approval(owner, spender, amount);
    }

    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply += amount;
        _balances[account] += amount;

        emit Transfer(address(0), account, amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Import the ERC20 token contract
import "./ERC20.sol";

contract PropertyContract {
    // Define the PPT-1 token
    ERC20 public ppt1Token;
    
    // Define the owner's address
    address public owner;
    
    // Mapping to track PPT-1 token balances
    mapping(address => uint256) public ppt1Balances;
    
    // Event to emit when PPT-1 tokens are purchased
    event PPT1TokensPurchased(address buyer, uint256 ppt1Amount);
    
    constructor(address _ppt1TokenAddress) {
        // Set the owner to the deployer of the contract
        owner = msg.sender;
        
        // Initialize the PPT-1 token contract
        ppt1Token = ERC20(_ppt1TokenAddress);
        
        // Assign 1000 PPT-1 tokens to the contract's address
        ppt1Balances[address(this)] = 1000;
    }
    
    function buyPPT1Tokens(address userERC20Token, uint256 erc20Amount) external {
        require(erc20Amount > 0, "Invalid ERC20 amount");
        
        // Calculate the corresponding PPT-1 token amount
        uint256 ppt1Amount = erc20Amount;
        
        // Ensure the contract has enough PPT-1 tokens
        require(ppt1Balances[address(this)] >= ppt1Amount, "Insufficient PPT-1 tokens");
        
        // Transfer ERC20 tokens from the buyer to the owner
        ppt1Token.transferFrom(userERC20Token, owner, erc20Amount);
        
        // Transfer PPT-1 tokens from the contract to the buyer
        ppt1Token.transfer(userERC20Token, ppt1Amount);
        
        // Update the PPT-1 token balances
        ppt1Balances[address(this)] -= ppt1Amount;
        ppt1Balances[userERC20Token] += ppt1Amount;
        
        emit PPT1TokensPurchased(userERC20Token, ppt1Amount);
    }
}