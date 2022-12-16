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
 
    uint256 private priceETH;
	uint256 private priceBTC;
    uint256 public decimalsETH;
    uint256 public decimalsBTC;
    uint256 public lastUpdateDate;


    receive () external payable {}

    function setPrice(uint256 newpriceETH, uint256 newpriceBTC, uint256 newUpdateDate) public onlyOwner {
        priceETH = newpriceETH;
		priceBTC = newpriceBTC;
        lastUpdateDate = newUpdateDate;
    }

	function simulatePriceChange(uint112 coefficientx100) public onlyOwner{
        priceETH = priceETH * coefficientx100 / 100 ;
		priceBTC = priceBTC * coefficientx100 / 100 ;
    }

    function getUpdateDate() public view returns(uint256 price) {
        return lastUpdateDate;
    }
    
    function getPriceETH() public view returns(uint256 price) {
        return priceETH;
    }

	function getPriceBTC() public view returns(uint256 price) {
        return priceBTC;
    }

    function getDecimalsETH() public view returns(uint256 price) {
        return decimalsETH;
    }

    function getDecimalsBTC() public view returns(uint256 price) {
        return decimalsBTC;
    }

 }