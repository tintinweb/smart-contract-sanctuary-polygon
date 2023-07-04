// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Strings.sol";
import "./Address.sol";
import "./Pausable.sol";
import "./AggregatorV3Interface.sol";
import "./IMintables.sol";

contract CelarisSeller is  Ownable , ReentrancyGuard,Pausable{
    
    using Address for address payable;

    using Strings for uint256;    

    uint256 public totalSupply;   

    address private fundsReceiver = 0xBe6a961bba5fd3242FD9e62d1c35E1a0bEB5869c;    
    
    uint256 public whiteBottlePrice = 1; // cents

    uint256 public redBottlePrice = 1; // cents

    uint256 public maxNftPerSale = 1;

    uint256 public maxNftPerWallet = 1;

    AggregatorV3Interface private usdByMaticFeed;        

    AggregatorV3Interface private eurUsdFeed;        

    mapping(address => uint256) public tokenOwner;

    IMintable public collection;

    address public minter;

    uint256[] public whiteWineIdsToMint;

    uint256[] public redWineIdsToMint;

    constructor(address _usdByMaticFeed,address _euroUsdFeedAddress,address _collectionAddress){
        usdByMaticFeed = AggregatorV3Interface(_usdByMaticFeed);
        eurUsdFeed = AggregatorV3Interface(_euroUsdFeedAddress);   
        collection = IMintable(_collectionAddress);
    }
          

    function mint(address to, uint256 qWhite, uint256 qRed) external payable {
        require(!paused(), "is on pause !");
        tokenOwner[to] = tokenOwner[to]  + qWhite + qRed;
        require(tokenOwner[to] <= maxNftPerWallet, "Max token par wallet limit");                
        uint256 weiPrice = getWeiPrice(qWhite,qRed);
        uint256 minPrice = (weiPrice * 995) / 1000;
        uint256 maxPrice = (weiPrice * 1005) / 1000;
        require(msg.value >=  minPrice ,"bad price");
        require(msg.value <=  maxPrice ,"bad price");
        require(whiteWineIdsToMint.length >=  qWhite ,"Max supply reached for white");
        require(redWineIdsToMint.length >=  qRed ,"Max supply reached for red");                
        require(maxNftPerSale <= qWhite + qRed,"Max token per sell reached");
        uint256[] memory idsToMint = new uint256[](qWhite+qRed);
        uint256 counter = 0;
        for(uint256 i = 0 ; i < qWhite; i++ ){
            uint256 tokenId =  whiteWineIdsToMint[whiteWineIdsToMint.length - 1];
            whiteWineIdsToMint.pop();
            idsToMint[counter++] = tokenId;                        
        }
        for(uint256 i = 0 ; i < qRed; i++ ){
            uint256 tokenId =  redWineIdsToMint[redWineIdsToMint.length - 1];
            redWineIdsToMint.pop();
            idsToMint[counter++] = tokenId;                           
        }
        totalSupply = qWhite + qRed;
        collection.mints(to,idsToMint);
    }

    function addWhiteWineIdsToMint(uint256[] memory tokenIds) external {
        require(msg.sender==minter||msg.sender==owner(), "not allowed");
        for(uint256 i=0;i<tokenIds.length;i++){
            whiteWineIdsToMint.push(tokenIds[i]);
        }
    }

    function resetWhiteWineIdsToMint() external {
        require(msg.sender==minter||msg.sender==owner(), "not allowed");
        delete whiteWineIdsToMint;
    }

    function addRedWineIdsToMint(uint256[] memory tokenIds) external {
        require(msg.sender==minter||msg.sender==owner(), "not allowed");
        for(uint256 i=0;i<tokenIds.length;i++){
            redWineIdsToMint.push(tokenIds[i]);
        }
    }

    function resetRedWineIdsToMint() external {
        require(msg.sender==minter||msg.sender==owner(), "not allowed");
        delete redWineIdsToMint;
    }

    // is for withpaper pre mint check.
    function checkClaimEligibility(address _to, uint256 qWhite,uint256 qRed, uint256 weiPrice) external view returns (string memory) {
        if (paused()) {
            return "is on pause !";
        } 
        if (tokenOwner[_to] + qWhite + qRed > maxNftPerWallet) {
            return "Max mints per wallet exceeded";
        }
        if(whiteWineIdsToMint.length < qWhite){
            return "Max supply reach for white";
        }

        if(redWineIdsToMint.length < qRed){
            return "Max supply reach for white";
        }
        uint256 currentWeiPrice = getWeiPrice(qWhite,qRed);
        uint256 minPrice = (currentWeiPrice * 995) / 1000;
        uint256 maxPrice = (currentWeiPrice * 1005) / 1000;
        if(weiPrice <  minPrice){
            return "bad price";
        }
        if(weiPrice >  maxPrice){
            return "bad price";
        }        
        return "";                                    
    }

    function setFundsReceiver(address  _fundsReceiver) external onlyOwner {
        fundsReceiver = _fundsReceiver;
    }

    function setWhiteBottlePrice(uint256  _euroPrice) external onlyOwner {
        whiteBottlePrice = _euroPrice;
    }

    function setRedBottlePrice(uint256  _euroPrice) external onlyOwner {
        redBottlePrice = _euroPrice;
    }

    function setCollection(address  _collection) external onlyOwner {
        collection = IMintable(_collection);
    }


    function setMaxNftPerWallet(uint256 _maxNftPerWallet) external onlyOwner {
        maxNftPerWallet = _maxNftPerWallet;
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

    function getWeiPrice(uint256 qWhite,uint256 qRed) public view returns (uint256) {
        uint256 priceInDollar = ((whiteBottlePrice * qWhite + redBottlePrice * qRed) * getUsdByEuro() * 10**18) / 10**eurUsdFeed.decimals();
        uint256 weiPrice = (priceInDollar * 10**usdByMaticFeed.decimals()) / getMaticByUsd();
        return weiPrice / 100;
    }

    function getContractData() public view returns (uint256,uint256,uint256,uint256,uint256,uint256) {        
        return (whiteWineIdsToMint.length,redWineIdsToMint.length,whiteBottlePrice,redBottlePrice,getWeiPrice(1,0),getWeiPrice(0,1));
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }
}