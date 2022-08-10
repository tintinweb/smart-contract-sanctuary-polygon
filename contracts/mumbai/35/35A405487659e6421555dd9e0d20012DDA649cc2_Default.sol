// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.7;

contract Default {
    address immutable i_owner;
    uint favNumber;
    mapping(address => uint) addressToFavNum;

    constructor() {
        i_owner = msg.sender;
    }

    function setNumber(uint _myFavNum) public {
        addressToFavNum[msg.sender] = _myFavNum;
    }

    function getMyNum() public view returns (uint) {
        return addressToFavNum[msg.sender];
    }

    function getUserNum(address _numOwner) public view returns (uint) {
        return addressToFavNum[_numOwner];
    }

    // Function to receive Ether. msg.data must be empty
    receive() external payable {}

    // Fallback function is called when msg.data is not empty
    fallback() external payable {}
}