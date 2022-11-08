// SPDX-License-Identifier:  MIT
pragma solidity ^0.8.4;

interface IStakedToken {

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function balanceOf(address owner) external view returns (uint256);

    function totalSupply() external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "./Interfaces/ISTAKEDToken.sol";

contract Pool {
    
    uint256 public liquidity;
    IStakedToken public token;

    constructor(IStakedToken _token) {
        token = _token;
    }

    function stake(uint256 amount) external returns(bool) {
        require(amount > 0 && amount < token.balanceOf(msg.sender), "FMPOOL: Buy More Tokens");
        liquidity += amount;
        bool success = IStakedToken(token).transferFrom(
            msg.sender,
            address(this),
            amount
        );
        require(success == true,"FMPOOL: Transfer was not successful");
        return success;
    }

    function unStake(uint256 amount) external returns(bool) {
        require (amount < token.balanceOf(address(this)), "FMPOOL: Not enough balance to unstake");
        liquidity -= amount;
        bool success = IStakedToken(token).transfer(msg.sender, amount);
        require(success == true,"FMPOOL: Transfer was not successful");
        return success;

    }


}