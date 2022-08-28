//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract test {
    string public name = "A Test Contract";
    uint256 public number = 1234567890;

    address public mainAddress;

    event AddressSet(address indexed _newAddress, uint256 aNum);

    function SetAddress(address addr) public {
        mainAddress = addr;
        emit AddressSet(addr, number);
    }

    function GetName() public view returns(string memory) {
        return name;
    }

    function GetNumber() public view returns(uint256) {
        return number;
    }
}