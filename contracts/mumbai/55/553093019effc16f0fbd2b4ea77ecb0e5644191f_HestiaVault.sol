/**
 *Submitted for verification at polygonscan.com on 2023-05-24
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

contract HestiaVault {

    address private owner;

    constructor() {
        owner = msg.sender;
    }

    receive() external payable { }

    fallback() external {
        revert("Hestia Vault. Fallback: Not function found");
    }
    
    /**
     * @dev Withdraw function that can to extract balance.
     * @param to: is address destined to receive the pay.
     * @param amount: is amount to extract.
     */
    function withdraw(address payable to, uint amount) external {
        require(msg.sender == owner, "Caller is not owner");
        require(address(this).balance >= amount, "The amount to be withdrawn exceeds the contract balance");
        to.transfer(amount);
    }
}