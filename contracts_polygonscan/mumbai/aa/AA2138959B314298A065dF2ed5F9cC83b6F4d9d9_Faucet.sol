// SPDX-License-Identifier: MIT
// @dev size: 1.726 Kbytes
pragma solidity 0.8.4;

import { IERC20 } from "../ERC20/IERC20.sol";

contract Faucet{

    IERC20 public amptToken;
    address public owner;

    uint256 public tokensPerUser = 10e18;

    mapping(address => bool) public distributions;

    constructor(IERC20 amptToken_) {
        amptToken = amptToken_;
        owner = msg.sender;
    }

    function balanceOf() public view returns (uint256) {
        return amptToken.balanceOf(address(this));
    }

    function updateTokensPerUser(uint256 value) external {
        require(msg.sender == owner, "Only owner can update");

        require(value > 0, "Value must be greater than 0");
        tokensPerUser = value;
    }

    function withdraw() external returns (bool) {
        require(msg.sender == owner, "Only owner can withdraw");

        uint256 amount = amptToken.balanceOf(address(this));
        require(amount > 0, "No tokens to withdraw");

        return amptToken.transfer(owner, amount);
    }

    function getTokens() external returns (bool) {
        require(!distributions[msg.sender], "You have already received your tokens");
        require(amptToken.balanceOf(address(this)) >= tokensPerUser, "Not enough tokens in the contract");
        distributions[msg.sender] = true;

        return amptToken.transfer(msg.sender, tokensPerUser);
    }
 }

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface IERC20Base {
    function balanceOf(address owner) external view returns (uint);

    function transfer(address recipient, uint amount) external returns (bool);
    function transferFrom(address src, address dst, uint amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint value);
}

interface IERC20 is IERC20Base {
    function totalSupply() external view returns (uint);

    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);

    event Approval(address indexed owner, address indexed spender, uint value);
}

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

interface IERC20Burnable is IERC20 {
    function burn(uint256 amount) external;
    function burnFrom(address account, uint256 amount) external;
}