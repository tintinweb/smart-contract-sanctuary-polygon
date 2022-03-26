/**
 *Submitted for verification at polygonscan.com on 2022-03-26
*/

/**
 *Submitted for verification at Etherscan.io on 2020-07-17
*/

/*! SPDX-License-Identifier: MIT License */

pragma solidity 0.6.8;

interface IMaticpro {
    function drawPool() external;
    function pool_last_draw() view external returns(uint40);
}

contract Ownable {
    address payable private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() internal {
        _owner = msg.sender;

        emit OwnershipTransferred(address(0), msg.sender);
    }

    function owner() public view returns(address payable) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function transferOwnership(address payable _new_owner) public onlyOwner {
        require(_new_owner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, _new_owner);
        _owner = _new_owner;
    }
}

contract ReOwner is Ownable {
    IMaticpro public maticpro;

    constructor() public {
        maticpro = IMaticpro(0xb18ffC48F72dAf5e5dF128e7C8471418c49E0292);
    }

    receive() payable external {}

    function drawPool() external onlyOwner {
        require(maticpro.pool_last_draw() + 1 days < block.timestamp); 

        maticpro.drawPool();
    }

    function withdraw() external onlyOwner {
        owner().transfer(address(this).balance);
    }
}