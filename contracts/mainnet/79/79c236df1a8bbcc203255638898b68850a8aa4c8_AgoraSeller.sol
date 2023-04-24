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

    uint256[12] public totalSupply;   

    address private fundsReceiver = 0x43Bc2ad796237DE7c4026cdb6177986B9a8B7a2d;

    address private fundsReceiver2 = 0x81BbaEE90549f320a78121dA40888c786eE27bcB;   

    uint256 public preSalesPriceDollar = 450;

    AggregatorV3Interface private usdByEthFeed;        
        

    struct  Chart  {
            address preSalesAddress;
            uint256 tokenType;
            uint256 quantity;            
    }

    Chart[] public preSales ;
    
    function getPreSalesQuantity(uint256 index) public view returns ( Chart memory) {        
      Chart memory c = preSales[index];
      return c;
    }

    constructor(address usdByEthFeedAddress){
        usdByEthFeed = AggregatorV3Interface(usdByEthFeedAddress);
    }

    function presales(address to,  uint256[] memory divinity, uint256[] memory dquantity) external payable {
        require(!paused(), "paused");
        require(divinity.length == dquantity.length , "bad quantity");
        uint256 totalCount = 0;
        for(uint i = 0 ; i < divinity.length;i++){
            uint256 divinityId = divinity[i];
            require(divinityId >= 0 && divinityId <= 11, "bad divinity id");
            require(dquantity[i] > 0, "bad quantity");
            require(totalSupply[divinityId]  + dquantity[i] <= maxSupply,"supply limit reached");
            totalSupply[divinityId] = totalSupply[divinityId] + dquantity[i];
            totalCount = totalCount + dquantity[i];
            preSales.push(Chart(to,divinityId,dquantity[i]));      
        }
        uint256 weiPrice = getWeiPrice(totalCount);
        uint256 minPrice = (weiPrice * 995) / 1000;
        uint256 maxPrice = (weiPrice * 1005) / 1000;
        require(msg.value >=  minPrice ,"bad price");
        require(msg.value <=  maxPrice ,"bad price");
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