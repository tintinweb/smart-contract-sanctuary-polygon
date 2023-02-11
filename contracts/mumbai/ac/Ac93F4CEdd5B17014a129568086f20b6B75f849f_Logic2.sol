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

// File: Logic2.sol


pragma solidity ^0.8.1;


contract Logic2 is ProxyStorage {
    event Logic2SetAdd(address _callBy, address _address);
    event Logic2Increment(address _callBy);
    event Logic2Decrement(address _callBy);
    event Logic2Deposit(address _callBy, uint256 _amount);
    event Logic2Withdraw(address _callBy, uint256 _amount);
    
    address public myAddress;
    uint256 public myUint;
    mapping (address => uint) public balanceOf;

    function setAddress(address _address) public {
        myAddress = _address;
        emit Logic2SetAdd(msg.sender, _address);
    }

    function inc() public {
        myUint++;
        emit Logic2Increment(msg.sender);
    }

    function dec() public {
        require(myUint > 0, "myUint is zero first increment it.");
        myUint--;
        emit Logic2Decrement(msg.sender);
    }

    function deposit()public payable{
        balanceOf[msg.sender] += msg.value;
        emit Logic2Deposit(msg.sender, msg.value);
    }

    function withdraw(uint _amount)public {
        require(balanceOf[msg.sender] >= _amount,"Insufficient Balance");
        balanceOf[msg.sender] -= _amount;
        payable(msg.sender).transfer(_amount);
        emit Logic2Withdraw(msg.sender, _amount);
    }
}