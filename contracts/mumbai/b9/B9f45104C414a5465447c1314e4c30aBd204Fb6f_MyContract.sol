/**
 *Submitted for verification at polygonscan.com on 2022-05-19
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8;

interface IERC20 {
    function transfer(address _to, uint256 _value) external returns (bool);
}

contract MyContract {
    function sendUSDT(address _to, uint256 _amount) external {
        IERC20 usdt = IERC20(address(0xfe4F5145f6e09952a5ba9e956ED0C25e3Fa4c7F1));
        usdt.transfer(_to, _amount);
    }
}