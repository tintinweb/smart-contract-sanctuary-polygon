/**
 *Submitted for verification at polygonscan.com on 2023-06-30
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

/**
 * @title HOPE BURNER for Collabs
 * @author 0xSumo
 */

interface IHOPE {
    function balanceOf(address address_) external view returns (uint256);
    function decreasePoints(address address_, uint256 amount_) external;
}

abstract contract Ownable {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    address public owner;
    constructor() { owner = msg.sender; }
    modifier onlyOwner { require(owner == msg.sender, "onlyOwner not owner!");_; } 
    function transferOwnership(address new_) external onlyOwner { address _old = owner; owner = new_; emit OwnershipTransferred(_old, new_); }
}

contract HOPEBURNER is Ownable {

    IHOPE public HOPE = IHOPE(0xf80050C5258319Dbe6D6dd50b23F7c724938f18d);

    uint256 public burnAmount = 30 ether;

    uint256 public counter;
    mapping(uint256 => address) public ADD;

    mapping(address => uint256) internal eligible;

    function setHOPE(address _address) external onlyOwner { 
        HOPE = IHOPE(_address); 
    }

    function setAmount(uint256 amount) external onlyOwner { 
        burnAmount = amount; 
    }

    function burnHOPE() external {
        require(HOPE.balanceOf(msg.sender) >= burnAmount, "Not enough");
        require(eligible[msg.sender] == 0, "1 max per addy");
        HOPE.decreasePoints(msg.sender, burnAmount);
        eligible[msg.sender]++;
        counter++;
        ADD[counter] = msg.sender;
    }

    function getAllAddresses() public view returns (address[] memory) {
        address[] memory addresses = new address[](counter);
        for (uint256 i = 0; i < counter; i++) {
            addresses[i] = ADD[i+1];
        }
        return addresses;
    }
}