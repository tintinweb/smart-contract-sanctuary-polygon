// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Address.sol";
import "./Pausable.sol";
import "./AggregatorV3Interface.sol";


contract AgoraSeller is  Ownable , ReentrancyGuard,Pausable{
    
    using Address for address payable;

    uint256 public maxSupply = 10000;    

    uint256 public totalSupply;   

    address private fundsReceiver = 0xBe6a961bba5fd3242FD9e62d1c35E1a0bEB5869c;    

    uint256 public preSalesPriceDollar = 80;

    AggregatorV3Interface private usdByEthFeed;        
    
    mapping(address => uint256) public preSalesUsers;

    constructor(address usdByEthFeedAddress){
        usdByEthFeed = AggregatorV3Interface(usdByEthFeedAddress);
    }
    
    function presales(address to, uint256 quantity) external payable nonReentrant{
        require(!paused(), "is on pause !");
        require(quantity > 0, "unvalid quantity");
        require(totalSupply < maxSupply, "supply limit reached");        
        require(msg.value >=  getWeiPrice(quantity) ,"unvalid price");
        preSalesUsers[to] += quantity;
        totalSupply += quantity;
    }

    function setFundsReceiver(address  _fundsReceiver) external onlyOwner {
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
    
    function getWeiDollarValue(uint256 priceInDollar) public view returns (uint256) {        
       return priceInDollar*10**26 / getEthByUsd(); // wei conversion
    }

    function getWeiPrice(uint256 amount) public view returns (uint256) {        
        return amount * preSalesPriceDollar*10**26 / getEthByUsd();
    }
   
    function getPreSalesUserCount(address userAddress) public view returns (uint256) {        
       return preSalesUsers[userAddress];
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }
         
}