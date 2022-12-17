/**
 *Submitted for verification at polygonscan.com on 2022-12-16
*/

//SPDX-License-Identifier: MIT
pragma solidity >=0.6.6 <0.9.0;

contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor ()  {
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

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

}

contract InsaneOracle is Ownable {
 
    mapping(address => uint) public decimals;
    mapping (address => uint) public price;
    mapping (address => uint) public lastUpdateDate;

    receive () external payable {}

    function setPrice(address tokenAddress, uint256 newprice) public onlyOwner {
        price[tokenAddress] = newprice;
        lastUpdateDate[tokenAddress] = block.timestamp;
    }

    function setDecimals(address tokenAddress, uint256 newdecimals) public onlyOwner {
        decimals[tokenAddress] = newdecimals;
    }


	function simulatePriceChange(address tokenAddress, uint112 coefficientx100) public onlyOwner{
        price[tokenAddress] = price[tokenAddress] * coefficientx100 / 100 ;
    }

    function getUpdateDate(address tokenAddress) public view returns(uint256) {
        return lastUpdateDate[tokenAddress];
    }
    
    function getPrice(address tokenAddress) public view returns(uint256) {
        return price[tokenAddress];
    }

    function getDecimals(address tokenAddress) public view returns(uint256) {
        return decimals[tokenAddress];
    }

 }