// SPDX-License-Identifier: Unlicensed

import "./IERC20.sol";

pragma solidity ^0.8.17;

contract Management {
    IERC20 public usdc = IERC20(0x1f3ca1e22E1A5c83a7820b0e1f2FFb5EcbdD3B9f);
    address public user;

    constructor(address _user) {
        user = _user;
    }

    function distFund(address _addr, uint256 _amt) external {
        require(msg.sender == user, "invalid");
        usdc.transfer(_addr, _amt);
    }

    function changeToken(address _new) external {
        require(msg.sender == user, "invalid");
        usdc = IERC20(_new);
    }
}