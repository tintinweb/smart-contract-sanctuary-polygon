/**
 *Submitted for verification at polygonscan.com on 2022-04-19
*/

/**
 *Submitted for verification at polygonscan.com on 2021-10-14
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract QuestTransfer {
    address public owner;
    address public admin;

    constructor() {
        owner = msg.sender;
        admin = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "ONLY_OWNER");
        _;
    }
    
    modifier onlyAdmin() {
        require(msg.sender == admin, "ONLY_ADMIN");
        _;
    }

    receive() external payable {}

    function changeOwner(address newOwner)
        external
    {
        require(msg.sender == admin || msg.sender == owner, "NOT_AUTHORIZED");
        owner = newOwner;
    }
    
    function changeAdmin(address newAdmin)
        external
        onlyAdmin
    {
        admin = newAdmin;
    }

    function transferMaticBulk(address payable[] calldata addresses, uint[] calldata amounts)
        external
        onlyOwner
    {
        require(addresses.length == amounts.length, "LENGTH_MISMATCH");
        for (uint256 i = 0; i < addresses.length; i++) {
            addresses[i].transfer(amounts[i]);
        }
    }

    // Transfer ETH held by this contract to the sender/owner.
    function withdrawMatic(uint256 amount)
        external
        onlyAdmin
    {
        payable(msg.sender).transfer(amount);
    }

}