// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./Address.sol";
import "./Pausable.sol";
import "./AggregatorV3Interface.sol";


contract AgoraSeller is  Ownable , Pausable{
    
    using Address for address payable;

    uint256 public maxSupply = 10000;    

    uint256 public totalSupply;   

    address private fundsReceiver = 0xBe6a961bba5fd3242FD9e62d1c35E1a0bEB5869c;    

    uint256 public preSalesPriceDollar = 80;

    AggregatorV3Interface private usdByEthFeed;        
    
    //mapping(address => uint256) public preSalesUsers;
    address[] public preSalesAddress;
    uint256[] public preSalesQuantity;
    
    constructor(address usdByEthFeedAddress){
        usdByEthFeed = AggregatorV3Interface(usdByEthFeedAddress);
    }
    
    function presales(address to, uint256 quantity) external payable {
        require(!paused(), "is on pause !");
        require(quantity > 0, "unvalid quantity");
        require(totalSupply + quantity < maxSupply, "supply limit reached");        
        require(msg.value >=  getWeiPrice(quantity) ,"unvalid price");
        preSalesAddress.push(to);
        preSalesQuantity.push(quantity);
        totalSupply += quantity;
    }

    function setFundsReceiver(address  _fundsReceiver) external {
         require(msg.sender == fundsReceiver, "Not allowed" );        
        fundsReceiver = _fundsReceiver;
    }
    
    function setPreSalesPrice(uint256  _preSalesPrice) external onlyOwner {
        preSalesPriceDollar = _preSalesPrice;
    }

    function setMaxSupply(uint256  _maxSupply) external onlyOwner {
        maxSupply = _maxSupply;
    }

     function retrieveFunds() external {
        require(
            msg.sender == owner() ||
            msg.sender == fundsReceiver,
            "Not allowed"
        );        
       payable(fundsReceiver).sendValue(address(this).balance);
    }
    
    function getEthByUsd() private view returns (uint256) {
        (, int256 price, , , ) = usdByEthFeed.latestRoundData();
        return uint256(price);
    }
    
    function getWeiPrice(uint256 quantity) public view returns (uint256) {        
        uint256 power  = 18 + usdByEthFeed.decimals();
        return quantity * preSalesPriceDollar*10**power / getEthByUsd();
    }
       
    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }
         
}