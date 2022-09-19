/**
 *Submitted for verification at polygonscan.com on 2022-09-18
*/

pragma solidity ^0.8.7;
// SPDX-License-Identifier: MIT

/**
 * @title Owner
 * @dev Set & change owner
 */
contract CheckOwner {

    address private owner;

    event OwnerSet(address indexed oldOwner, address indexed newOwner);

    modifier isOwner() {
        require(msg.sender == owner, "Caller is not owner");
        _;
    }

    constructor() {
        owner = msg.sender; // 'msg.sender' is sender of current call, contract deployer for a constructor
        emit OwnerSet(address(0), owner);
    }

    function getOwner() public isOwner view returns (address) {
        return owner;
    }
}