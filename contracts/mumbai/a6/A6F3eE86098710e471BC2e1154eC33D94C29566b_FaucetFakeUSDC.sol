/**
 *Submitted for verification at polygonscan.com on 2022-09-27
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

/**
 * @title Simple USDC token
 * @dev Test Implementation of the a simple ERC20 implementation.
 *  See https://github.com/ethereum/EIPs/issues/20
 */
contract SimpleUSDCToken {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    mapping(address => mapping(address => uint256)) public allowance;
    mapping(address => uint256) public balanceOf;
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    constructor(uint256 _initialAmount) {
        totalSupply = _initialAmount;
        balanceOf[msg.sender] = _initialAmount;
        name = "USD Coin";
        symbol = "USDC";
        decimals = 6;
    }

    function transfer(address dst, uint256 amount)
        external
        virtual
        returns (bool)
    {
        require(
            amount <= balanceOf[msg.sender],
            "ERC20: transfer amount exceeds balance"
        );
        balanceOf[msg.sender] = balanceOf[msg.sender] - amount;
        balanceOf[dst] = balanceOf[dst] + amount;
        emit Transfer(msg.sender, dst, amount);
        return true;
    }

    function transferFrom(
        address src,
        address dst,
        uint256 amount
    ) external virtual returns (bool) {
        require(
            amount <= allowance[src][msg.sender],
            "ERC20: transfer amount exceeds allowance"
        );
        require(
            amount <= balanceOf[src],
            "ERC20: transfer amount exceeds balance"
        );
        allowance[src][msg.sender] = allowance[src][msg.sender] - amount;
        balanceOf[src] = balanceOf[src] - amount;
        balanceOf[dst] = balanceOf[dst] + amount;
        emit Transfer(src, dst, amount);
        return true;
    }

    function approve(address _spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][_spender] = amount;
        emit Approval(msg.sender, _spender, amount);
        return true;
    }
}

/**
 * @title Faucet Test Token
 * @notice A simple test token that lets anyone get more of it.
 */
contract FaucetFakeUSDC is SimpleUSDCToken {
    constructor(uint256 _initialAmount) SimpleUSDCToken(_initialAmount) {}

    function allocateTo(address _owner, uint256 value) public {
        balanceOf[_owner] += value;
        totalSupply += value;
        emit Transfer(address(this), _owner, value);
    }
}