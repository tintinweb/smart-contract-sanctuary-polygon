// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract T {
    address payable internal _addressReceiveForMint;
    uint internal _priceForMint;
    constructor(address payable addressReceiveForMint, uint priceForMint) payable {
        _addressReceiveForMint = addressReceiveForMint;
        _priceForMint = priceForMint;
    }
    function callTest() external payable {
        (bool success, ) = _addressReceiveForMint.call{ value: _priceForMint }("");

        require(success, 'Failed call');
    }

    function updateMintPrice(uint _price) public {
        _priceForMint = _price;
    }

    function updateMintAddress(address payable _address) public {
        _addressReceiveForMint = _address;
    }


}