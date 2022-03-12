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
    address payable private withdrawaddress;
    mapping (string => bool) public payers;
    uint game = 0;

    constructor() payable {
        withdrawaddress = payable(msg.sender);
    }

    function changePrice(uint newPrice) public onlyOwner{
        price = newPrice;
    }

    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    function payment() public payable returns (uint256, uint256) {
        require(msg.value == price, "Failed to send Ether hence sending ether is not equal to price");
        payers[string(abi.encodePacked(msg.sender,uint2str(game)))] = true;
        game++;
        return (msg.value, (game-1));
    }

    function checkpayer(address payer, uint256 i) public returns (bool) {
        if(payers[string(abi.encodePacked(payer,uint2str(i)))] == true){
            delete payers[string(abi.encodePacked(payer,uint2str(i)))];
            return true;
        }
        return false;
    }

    function changeWithDrawAddress(address payable _withdrawaddress) public onlyOwner{
        withdrawaddress = _withdrawaddress;
    }

    function getBalance() public view returns (uint) {
        return address(this).balance;
    }

    function withDraw() public payable onlyOwner {
        (bool res,) = withdrawaddress.call{value: address(this).balance}("");
        require(res);
    }
}