// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "./IERC20.sol";
import "./Ownable.sol";

contract GamePool is Ownable {
    
    IERC20 private token;
    address public tokenAddress;

    constructor(address _tokenAddress) {
        tokenAddress = _tokenAddress;
        token = IERC20(_tokenAddress);
    }

    function releaseToken(uint amount, address to) public onlyOwner {   
        token.transfer(to, amount);
    }

    function setAddress(address _tokenAddress) public onlyOwner {
        tokenAddress = _tokenAddress;
        token = IERC20(_tokenAddress);
    }
}