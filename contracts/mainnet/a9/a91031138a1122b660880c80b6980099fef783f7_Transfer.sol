/**
 *Submitted for verification at polygonscan.com on 2022-03-11
*/

// SPDX-License-Identifier: MIT

// File: contracts/Token.sol

// contracts/GLDToken.sol

pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    constructor() payable {
        _owner = payable(msg.sender);
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
}

contract Transfer is Ownable {
    uint256 public price = 0.0001 ether;
    address payable private ownerAddress;

    constructor() payable {
        ownerAddress = payable(msg.sender);
    }

    function changePrice(uint newPrice) public onlyOwner{
        price = newPrice;
    }

    function payment() public payable returns (uint256) {
        require(msg.value == price, "Failed to send Ether hence sending ether is not equal to price");
        return (msg.value);
    }

    function changeOwner(address payable _ownerAddress) public onlyOwner{
        ownerAddress = _ownerAddress;
    }

    function getBalance() public view returns (uint) {
        return address(this).balance;
    }

    function withDraw() public payable onlyOwner {
        (bool res,) = ownerAddress.call{value: address(this).balance}("");
        require(res);
    }
}