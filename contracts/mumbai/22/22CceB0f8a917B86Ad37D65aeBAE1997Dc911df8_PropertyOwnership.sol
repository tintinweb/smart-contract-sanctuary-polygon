// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface IERC20 {
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
}

contract PropertyOwnership {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    address public owner;
    mapping(address => uint256) public pptBalance;
    mapping(address => uint256) public ercBalance;
    mapping(address => address) public userERC20Tokens;

    event TokensPurchased(address indexed buyer, uint256 pptAmount, uint256 ercAmount);

    constructor(address _ownerERC20Token, uint256 _totalSupply) {
        owner = msg.sender;
        userERC20Tokens[owner] = _ownerERC20Token;
        name = "PropertyOwnership";
        symbol = "PPT";
        decimals = 18;
        totalSupply = _totalSupply;
        pptBalance[address(this)] = totalSupply;
    }

    function setUserERC20Token(address userERC20Token) external {
        require(userERC20Token != address(0), "Invalid ERC20 token address");
        require(userERC20Tokens[msg.sender] == address(0), "ERC20 token address already set for the user");
        userERC20Tokens[msg.sender] = userERC20Token;
    }

   function buyTokens(uint256 pptAmount) external {
    require(pptAmount > 0, "Invalid PPT amount");
    require(pptAmount <= pptBalance[address(this)], "Insufficient PPT token balance");

    address userERC20Token = userERC20Tokens[msg.sender];
    require(userERC20Token != address(0), "User ERC20 token address not set");

    IERC20 ercToken = IERC20(userERC20Token);

    uint256 userERC20Balance = ercToken.balanceOf(msg.sender);
    require(userERC20Balance >= pptAmount, "Insufficient ERC20 token balance");

    uint256 userERC20Allowance = ercToken.allowance(msg.sender, address(this));
    require(userERC20Allowance >= pptAmount, "Insufficient ERC20 token allowance");

    bool ercTransferSuccess = ercToken.transferFrom(msg.sender, owner, pptAmount);
    require(ercTransferSuccess, "Failed to transfer ERC20 tokens to the owner");

    pptBalance[msg.sender] += pptAmount;
    pptBalance[address(this)] -= pptAmount;
    ercBalance[msg.sender] -= pptAmount;
    ercBalance[owner] += pptAmount;

    emit TokensPurchased(msg.sender, pptAmount, userERC20Balance);
}


   function getERC20Balance(address user, address ercTokenAddress) external view returns (uint256) {
    IERC20 ercToken = IERC20(ercTokenAddress);
    return ercToken.balanceOf(user);
}

    function getPPTBalance(address account) external view returns (uint256) {
        return pptBalance[account];
    }
}