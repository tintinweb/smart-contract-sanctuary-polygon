// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./Ownable.sol";
import "./Address.sol";
import "./Pausable.sol";
import "./AggregatorV3Interface.sol";

contract AgoraSeller is  Ownable , Pausable{
    using Address for address payable;

    uint256 public constant ZEUS = 0;

    uint256 public constant HERA = 1;

    uint256 public constant POSEIDON = 2;

    uint256 public constant ATHENA = 3;

    uint256 public constant APPOLO = 4;

    uint256 public constant ARTEMIS = 5;

    uint256 public constant ARES = 6;

    uint256 public constant APHRODITE = 7;

    uint256 public constant HEPHAESTUS = 8;

    uint256 public constant HADES = 9;

    uint256 public constant DIONYSUS = 10;
    
    uint256 public constant HERMES = 11;

    uint256 public maxSupply = 500;    

    uint256[] public totalSupply;   

    address private fundsReceiver = 0xBe6a961bba5fd3242FD9e62d1c35E1a0bEB5869c;

    address private fundsReceiver2 = 0x840398cbAFCC90d4748768EE533B5fd9607eA8e7;   

    uint256 public preSalesPriceDollar = 80;

    AggregatorV3Interface private usdByEthFeed;        
        

    struct  Chart  {
            address preSalesAddress;
            uint256[] tokenType;
            uint256[] quantity;            
    }

    Chart[] private preSales ;
    
    function getPreSalesQuantity(uint256 index) public view returns ( Chart memory) {        
      Chart memory c = preSales[index];
      return c;
    }

    constructor(address usdByEthFeedAddress){
        usdByEthFeed = AggregatorV3Interface(usdByEthFeedAddress);
    }

    function presales(address to,  uint256[] memory divinity, uint256[] memory quantity) external payable {
        require(!paused(), "is on pause !");
        require(divinity.length == quantity.length , "unvalid quantity");
        uint256 totalCount = 0;
        for(uint i = 0 ; i < divinity.length;i++){
            uint256 divinityId = divinity[i];
            require(divinityId >= 0 && divinityId <= 11, "bad divinity id");
            require(quantity[i] > 0, "unvalid quantity");
            require(totalSupply[divinityId]  + quantity[i] <= maxSupply,"supply limit reached");
            totalSupply[divinityId] += quantity[i];
            totalCount += quantity[i];
        }
        require(msg.value >=  getWeiPrice(totalCount) ,"unvalid price");
        preSales.push(Chart(to,divinity,quantity));
        
    }

    function setFundsReceiver(address  _fundsReceiver) external {
         require(msg.sender == fundsReceiver, "Not allowed" );        
        fundsReceiver = _fundsReceiver;
    }

    function setFundsReceiver2(address  _fundsReceiver) external {
         require(msg.sender == fundsReceiver2, "Not allowed" );        
        fundsReceiver2 = _fundsReceiver;
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
            msg.sender == fundsReceiver ||
            msg.sender == fundsReceiver2,
            "Not allowed"
        );
       require(address(this).balance > 0,"LOW BALANCE") ;
       payable(fundsReceiver).sendValue(address(this).balance / 2);
       payable(fundsReceiver2).sendValue(address(this).balance);
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