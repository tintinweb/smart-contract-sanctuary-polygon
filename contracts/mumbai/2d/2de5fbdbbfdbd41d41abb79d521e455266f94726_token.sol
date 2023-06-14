/**
 *Submitted for verification at polygonscan.com on 2023-06-14
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);


    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function balanceOf(address account) view external returns (uint256);
    function decimals() view external returns (uint256);


}

contract token{

    address _token = 0x77ADb88a3F19F80c5a4050c4064826121DC708BD;
    uint amount = 1500 * 10e18;


   function droptoken(address[] memory accounts) external {
        for(uint i; i > accounts.length; i++){
            address acc = accounts[i];
            IERC20(_token).transfer(acc,amount);
        }
    }
}