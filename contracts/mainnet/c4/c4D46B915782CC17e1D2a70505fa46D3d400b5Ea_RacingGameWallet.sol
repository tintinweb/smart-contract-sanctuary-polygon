// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract RacingGameWallet {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    function deposit() public payable {}

    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function withdrawAll() public {
        address payable to = payable(msg.sender);

        (bool success, ) = to.call{value: getContractBalance()}("");
        require(success, "Transfer failed.");
    }

    function withdrawToAddress(address payable to) public {
        (bool success, ) = to.call{value: getContractBalance()}("");
        require(success, "Transfer failed.");
    }

    receive() external payable {}
}