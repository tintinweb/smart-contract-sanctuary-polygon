/**
 *Submitted for verification at polygonscan.com on 2022-05-20
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8;

interface IERC20 {
    function transfer(address _to, uint256 _value) external returns (bool);
}

contract MyContract {
    function sendUSDT(address _to, uint256 _amount, address erc20Address) external {
        IERC20 erc20 = IERC20(erc20Address);
        erc20.transfer(_to, _amount);
    }
}