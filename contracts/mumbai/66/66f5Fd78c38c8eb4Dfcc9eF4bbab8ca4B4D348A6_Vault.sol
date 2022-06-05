/**
 *Submitted for verification at polygonscan.com on 2022-06-04
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 * @custom:dev-run-script ./scripts/deploy_with_ethers.ts
 */
contract Vault {

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);

    function deposit(uint256 amount) public {
        emit Deposit(msg.sender, amount);
    }

    function withdraw(uint256 amount) public {
        emit Withdraw(msg.sender, amount);
    }
}