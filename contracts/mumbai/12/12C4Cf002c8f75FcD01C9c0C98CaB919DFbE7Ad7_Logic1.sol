/**
 *Submitted for verification at polygonscan.com on 2023-02-10
*/

// SPDX-License-Identifier: MIT
// File: ProxyStorage.sol


pragma solidity ^0.8.1;

contract ProxyStorage {
    address public logicContractAddress;

    function setLogicAddressStorage(address _logicContract) internal {
        logicContractAddress = _logicContract;
    }

    function _contractAddress() public view returns (address) {
        return address(this);
    }
}

// File: Logic1.sol


pragma solidity ^0.8.1;


contract Logic1 is ProxyStorage {
    event Logic1SetAdd(address _callBy, address _address);
    event Logic1Increment(address _callBy);
    event Logic1Deposit(address _callBy, uint256 _amount);

    address public myAddress;
    uint public myUint;
    mapping (address => uint) public balanceOf;

    function setAddress(address _address) public {
        myAddress = _address;
        emit Logic1SetAdd(msg.sender, _address);
    }

    function inc() public {
        myUint++;
        emit Logic1Increment(msg.sender);
    }

    function deposit()public payable{
        balanceOf[msg.sender] += msg.value;
        emit Logic1Deposit(msg.sender, msg.value);
    }

}