// SPDX-License-Identifier: MIT LICENSE
pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./PLOVE.sol";
contract mallowAuctions is Ownable{
    struct Auction{
        uint256 id;
        uint auctionType;   //0: normal, 1: dutch
        string projectName;
        uint256 startTime;
        uint256 closeTime;
        uint256 dutchPriceRate;
        uint256 dutchTimeRate;
        uint256 startPrice;
        uint256 minPrice;
        string discord;
        uint256 maxWhiteLists;
        bool exists;
    }
    /* struct userBid{
        address userAddress;
        bool iswhiteListed;
        uint256 amount;
    } */
    PLOVE ploveAddress;
    uint256 public totalAuctions = 0;
    mapping(address => bool) isApprovedAddress;

    mapping(string => bool) public auctionExists;
    mapping(uint256 => Auction) auctionSettings; // map id => auction settings
    mapping(uint256 => address[]) public whitelists; // auction id => to WL users
    //mapping(uint256 => mapping(address => userBid)) auctionEntries; 
    //mapping (address => Auction.id);
    modifier onlyApprovedAddresses{
        require(isApprovedAddress[msg.sender], "You are not authorized!");
        _;
    }
    constructor(address _ploveAddress){
        ploveAddress = PLOVE(_ploveAddress);
    }
    function setApprovedAddresses(address _approvedAddress, bool _set) external onlyOwner(){
        isApprovedAddress[_approvedAddress] = _set;
    }
    function isWhiteListed(address _wallet,uint256 _auctionId) public view returns (bool) {
        for (uint i = 0; i < whitelists[_auctionId].length; i++) {
            if (whitelists[_auctionId][i] == _wallet) {
                return true;
            }
        }
        return false;
    }
    function createDutch (string memory _projectName, uint256 _startTime, uint256 _closeTime, uint _dutchRate,uint256 _timeRate,
    uint256 _startPrice,uint256 _minPrice, string memory _discordLink, uint256 _maxWhiteLists) external onlyApprovedAddresses{
        require(!auctionExists[_projectName],"The name is already defined");
        require(!auctionSettings[totalAuctions].exists,"This auction already exists");
        require(_startTime > 0 ,"Incorret start time value");
        require(_closeTime > 0 ,"Incorret close time value");
        require(_startPrice > 0 ,"Incorret start price value");
        require(_minPrice > 0 ,"Incorret min price value");
        require(_maxWhiteLists > 0 ,"Incorret maxWL value");

        auctionSettings[totalAuctions] = Auction({
            id: totalAuctions,
            auctionType: 1,   //dutch type
            projectName: _projectName,
            startTime: _startTime,
            closeTime: _closeTime,
            dutchPriceRate: _dutchRate,
            dutchTimeRate: _timeRate,
            startPrice: _startPrice,
            minPrice: _minPrice,
            discord: _discordLink,
            maxWhiteLists: _maxWhiteLists,
            exists: true
        });
        auctionExists[_projectName] = true;
        totalAuctions++;
    }
    function createBuyNow (string memory _projectName, uint _startTime, uint _closeTime,
    uint256 _startPrice, string memory _discordLink, uint256 _maxWhiteLists) external onlyApprovedAddresses{
        require(!auctionExists[_projectName],"The name is already defined");
        require(!auctionSettings[totalAuctions].exists,"This auction already exists");
        require(_startTime > 0 ,"Incorret start time value");
        require(_closeTime > 0 ,"Incorret close time value");
        require(_startPrice > 0 ,"Incorret start price value");
        require(_maxWhiteLists > 0 ,"Incorret maxWL value");

        auctionSettings[totalAuctions] = Auction({
            id: totalAuctions,
            auctionType: 0,   //buy now type
            projectName: _projectName,
            startTime: _startTime,
            closeTime: _closeTime,
            dutchPriceRate: 0,
            dutchTimeRate: 0,
            startPrice: _startPrice,
            minPrice: _startPrice,
            discord: _discordLink,
            maxWhiteLists: _maxWhiteLists,
            exists: true
        });
        auctionExists[_projectName] = true;
        totalAuctions++;
    }
    function enterAuction(uint256 _auctionId) external{
        require(auctionSettings[_auctionId].exists,"Auction does not exist or removed");
        require(viewAuctionState(_auctionId),"Auction not open");
        require(!isWhiteListed(msg.sender,_auctionId),"Already whiteListed");
        require(whitelists[_auctionId].length<auctionSettings[_auctionId].maxWhiteLists,
        "Auction Sold Out");
        uint256 auctionPrice = getCurrentPrice(_auctionId);
        require(ploveAddress.balanceOf(msg.sender)>= auctionPrice *1 ether, "Not enough LOVE");
        ploveAddress.burn(msg.sender,auctionPrice * 1 ether);
        whitelists[_auctionId].push(msg.sender);

    }
    function updateAuction(uint256 _auctionId, string memory _projectName, uint256 _startTime, 
    uint256 _closeTime, uint _dutchRate,uint256 _timeRate,uint256 _startPrice,uint256 _minPrice, 
    string memory _discordLink, uint256 _maxWhiteLists) external onlyApprovedAddresses{
        require(auctionSettings[_auctionId].exists,"Auction does not exist or removed");
        auctionSettings[_auctionId].projectName = _projectName;
        auctionSettings[_auctionId].startTime = _startTime;
        auctionSettings[_auctionId].closeTime = _closeTime;
        auctionSettings[_auctionId].dutchPriceRate = _dutchRate;
        auctionSettings[_auctionId].dutchTimeRate = _timeRate;
        auctionSettings[_auctionId].startPrice = _startPrice;
        auctionSettings[_auctionId].minPrice = _minPrice;
        auctionSettings[_auctionId].discord = _discordLink;
        auctionSettings[_auctionId].maxWhiteLists = _maxWhiteLists;
    }
    function removeAuction(uint256 _auctionId) external onlyApprovedAddresses{
        auctionSettings[_auctionId].exists = false;
    }
    function viewAuction(uint256 _auctionId)public view returns (Auction memory){
        return auctionSettings[_auctionId];
    }
    function viewAuctionState(uint256 _auctionId)public view returns (bool){
        return (block.timestamp >= auctionSettings[_auctionId].startTime
        && block.timestamp< auctionSettings[_auctionId].closeTime) ? true:false;
    }
    function getAuction(uint256 _auctionId)public view returns (Auction memory){
        return auctionSettings[_auctionId];
    }
    function getAuctionWL(uint256 _auctionId)public view returns (address [] memory){
        return whitelists[_auctionId];
    }
    function getCurrentPrice(uint256 _auctionId)public view returns (uint256){
        require(auctionSettings[_auctionId].exists,"Auction does not exist or removed");
        Auction memory auxAuction = auctionSettings[_auctionId];
        if(block.timestamp > auxAuction.startTime && block.timestamp <= auxAuction.closeTime){
            if(auxAuction.auctionType == 1){    //DUTCH auction
                uint256 reduction = (block.timestamp-auxAuction.startTime)/auxAuction.dutchTimeRate
                *auxAuction.dutchPriceRate;
                uint256 newPrice =  auxAuction.startPrice >= reduction ? 
				(auxAuction.startPrice - reduction) : 0;
                return newPrice >= auxAuction.minPrice ? newPrice : auxAuction.minPrice;
            }
            else if(auxAuction.auctionType == 0){    //Buy now auction
                return auxAuction.startPrice;
            }
        }
        return 0;
    }
}