/**
 *Submitted for verification at polygonscan.com on 2022-10-07
*/

/**
 *Submitted for verification at polygonscan.com on 2022-10-03
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0 <0.9.0;

contract Testing {
    address private owner;
//     mapping (address => uint) private balance;
//     mapping (address => mapping(address => uint)) private deposites;
//     mapping (address => address) private referer;
//     mapping (address => bool) private referer_set;


//    // event for EVM logging
//     event OwnerSet(address indexed oldOwner, address indexed newOwner);
//    // Log the event about a deposit being made by an address and its amount
//     event LogDepositMade(address indexed accountAddress, uint amount);
//    // Log the event about a deposit being withdraw by an address and its amount
//     event LogDepositWithdraw(address indexed accountAddress, uint amount);
//  // Log the event about a deposit being withdraw by an address and its amount
//     event LogPayment(address indexed accountFrom, address accountTo, uint amount);
//  // Log the event about a deposit being withdraw by an address and its amount
//     event LogTransfer(address indexed accountFrom, address accountTo, uint amount);


    // modifier to check if caller is owner
    modifier isOwner() {
        require(msg.sender == owner, "Caller is not owner");
        _;
    }

    /**
     * @dev Set contract deployer as owner
     */
    constructor() {
     //   console.log("Owner contract deployed by:", msg.sender);
        owner = msg.sender; // 'msg.sender' is sender of current call, contract deployer for a constructor
    }



    function getOwner() external view returns (address) {
        return owner;
    }
}