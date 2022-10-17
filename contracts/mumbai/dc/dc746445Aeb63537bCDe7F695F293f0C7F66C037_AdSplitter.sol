//SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

contract AdSplitter {
    
    uint256 public percentage;
    address payable public owner;

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    constructor(uint256 _percentage, address payable _owner) {
        percentage = _percentage;
        owner = _owner;
    }

    function transferOwnerShip(address payable _newOwner) external onlyOwner {
        owner = _newOwner;
    }

    function setPercentage(uint256 _percentage) external onlyOwner {
        percentage = _percentage;
    }

    function splitAdRevenue(address payable _adOwner) external payable {
        uint256 adminShare = msg.value * percentage / 100;
        owner.transfer(adminShare);
        _adOwner.transfer(address(this).balance);
    }


}