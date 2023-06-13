// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Strings.sol";
import "./Address.sol";
import "./Pausable.sol";
import "./AggregatorV3Interface.sol";
import "./IMintable.sol";

contract CelarisSeller is  Ownable , ReentrancyGuard,Pausable{
    
    using Address for address payable;

    using Strings for uint256;    

    uint256 public totalSupply;   

    address private fundsReceiver = 0xBe6a961bba5fd3242FD9e62d1c35E1a0bEB5869c;    
    
    uint256 maxSupply = 50;

    uint256 public euroPrice = 1; // cents

    uint256 public maxNftPerSale = 1;

    uint256 public maxNftPerWallet = 1;

    AggregatorV3Interface private usdByMaticFeed;        

    AggregatorV3Interface private eurUsdFeed;        

    mapping(address => uint256) public tokenOwner;

    IMintable public collection;

    address public minter;

    uint256[] public tokenIdsToMint;

    constructor(address _usdByMaticFeed,address _euroUsdFeedAddress,address _collectionAddress){
        usdByMaticFeed = AggregatorV3Interface(_usdByMaticFeed);
        eurUsdFeed = AggregatorV3Interface(_euroUsdFeedAddress);   
        collection = IMintable(_collectionAddress);
    }
          

    function mint(address to, uint256 quantity) external payable {
        require(!paused(), "is on pause !");
        require(totalSupply + quantity < maxSupply, "supply limit reached");
        require(quantity <= maxNftPerSale, "unvalid quantity");
        tokenOwner[to] += quantity;
        require(tokenOwner[to] <= maxNftPerWallet, "Max token par wallet limit");                
        uint256 weiPrice = getWeiPrice(quantity);
        uint256 minPrice = (weiPrice * 995) / 1000;
        uint256 maxPrice = (weiPrice * 1005) / 1000;
        require(msg.value >=  minPrice ,"bad price");
        require(msg.value <=  maxPrice ,"bad price");                
        for(uint256 i = 0; i < quantity; i++) {
            uint256 tokenId = tokenIdsToMint[tokenIdsToMint.length-1];
            tokenIdsToMint.pop();
            collection.mint(to,tokenId);
        }        
        totalSupply += quantity;
    }

    function drop(address to, uint256 quantity)  external onlyOwner  {
        require(!paused(), "is on pause !");
        require(totalSupply + quantity < maxSupply, "supply limit reached");
        tokenOwner[to] += quantity;
        totalSupply += quantity;
    }

    function addTokensToMint(uint256[] memory tokenIds) external {
        require(msg.sender==minter||msg.sender==owner(), "not allowed");
        for(uint256 i=0;i<tokenIds.length;i++){
            tokenIdsToMint.push(tokenIds[i]);
        }
    }

    function checkClaimEligibility(address _to, uint256 _quantity) external view returns (string memory) {
        if (paused()) {
            return "is on pause !";
        } else if (tokenOwner[_to] + _quantity > maxSupply) {
             return "Not enough supply";            
        } else if (tokenOwner[_to] + _quantity > maxNftPerWallet) {
            return "Max mints per wallet exceeded";
        } else if ( _quantity > maxNftPerSale) {
            return "Max mints per sales exceeded";
        }else{
            return "";
        }
        
    }

    function setFundsReceiver(address  _fundsReceiver) external onlyOwner {
        fundsReceiver = _fundsReceiver;
    }

    function setMaxSupply(uint256  _maxSupply) external onlyOwner {
        maxSupply = _maxSupply;
    }

    function setEuroPrice(uint256  _euroPrice) external onlyOwner {
        euroPrice = _euroPrice;
    }
    

    function setCollection(address  _collection) external onlyOwner {
        collection = IMintable(_collection);
    }
    
    function setMinter(address  _minter) external onlyOwner {
        minter = _minter;
    }

     function retrieveFunds() external {
        require(
            msg.sender == owner() ||
            msg.sender == fundsReceiver,
            "Not allowed"
        );        
       payable(fundsReceiver).sendValue(address(this).balance);
    }

    
    function getMaticByUsd() private view returns (uint256) {
        (, int256 price, , , ) = usdByMaticFeed.latestRoundData();
        return uint256(price);
    }

    function getUsdByEuro() private view returns (uint256) {
        (, int256 price, , , ) = eurUsdFeed.latestRoundData();
        return uint256(price);
    }

   

     function getWeiPrice(uint256 quantity) public view returns (uint256) {
        uint256 priceInDollar = (quantity * euroPrice * getUsdByEuro() * 10**18) / 10**eurUsdFeed.decimals();
        uint256 weiPrice = (priceInDollar * 10**usdByMaticFeed.decimals()) / getMaticByUsd();
        return weiPrice / 100;
    }
      


    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }


    

         
}