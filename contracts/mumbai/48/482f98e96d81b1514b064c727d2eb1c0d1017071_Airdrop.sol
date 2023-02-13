/**
 *Submitted for verification at polygonscan.com on 2023-02-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface TokenSultan {
    function transfer(address _to, uint256 _value) external;
}

contract Airdrop {
    TokenSultan public token;
    address[] public addresses;
    uint256[] public amounts;

    function setToken(address _tokenAddress) public {
    token = TokenSultan(_tokenAddress);

    }

    function DropAddress(address _address, uint256 _amount) public {
        addresses.push(_address);
        amounts.push(_amount);
    }

    function distribute() public {
        for (uint256 i = 0; i < addresses.length; i++) {
            token.transfer(addresses[i], amounts[i]);
        }
    }
}