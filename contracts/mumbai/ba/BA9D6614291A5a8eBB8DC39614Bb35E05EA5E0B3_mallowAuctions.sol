// SPDX-License-Identifier: MIT LICENSE
pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./PLOVE.sol";
import "./Strings.sol";
contract mallowAuctions is Ownable{
    using Strings for uint;
    struct Auction{
        uint256 id;
        uint auctionType;   //0: normal, 1: dutch
        string projectName;
        uint256 startTime;
        uint256 dutchPriceRate;
        uint256 dutchTimeRate;
        uint256 startPrice;
        uint256 minPrice;
        string imgSrc;
        string discordLink;
        string twitterLink;
        uint256 maxWhitelists;
        bool exists;
    }
    /* struct userBid{
        address userAddress;
        bool iswhiteListed;
        uint256 amount;
    } */
    event auctionEntry(address indexed _user, uint256 indexed _auctionID, uint256 _entryPrice, uint256 _entryTime);
    PLOVE ploveAddress;
    uint256 public totalAuctions = 0;
    mapping(address => bool) isApprovedAddress;

    mapping(string => bool) public auctionExists;
    mapping(uint256 => Auction) auctionSettings; // map id => auction settings
    mapping(uint256 => address[]) whitelists; // auction id => to WL users
    mapping(address => uint256) public _nonces;    //maps nonces
    //mapping(uint256 => mapping(address => userBid)) auctionEntries; 
    //mapping (address => Auction.id);
    struct AuctionRequest {
        uint256 Auction_ID;
        string Auction_Type;
        uint256 Entry_Price;
        uint256 Nonce;
    }
    bytes32 DOMAIN_SEPARATOR;
    bytes32 constant EIP712DOMAIN_TYPEHASH = keccak256(
        "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
    );
    bytes32 constant AuctionRequest_TYPEHASH = keccak256(
        "AuctionRequest(uint256 Auction_ID,string Auction_Type,uint256 Entry_Price,uint256 Nonce)"
    );
    modifier onlyApprovedAddresses{
        require(isApprovedAddress[msg.sender], "You are not authorized!");
        _;
    }
    constructor(){//address _ploveAddress){
        //ploveAddress = PLOVE(_ploveAddress);
        DOMAIN_SEPARATOR = keccak256(abi.encode(
            EIP712DOMAIN_TYPEHASH,
            keccak256(bytes("Auctions")),   //name:
            keccak256(bytes('1')),          //version:
            4,                              //chainId:
            address(this)                            //verifyingContract:
        ));     
    }
    function setDependency(address _ploveAddress) public onlyOwner{
        ploveAddress = PLOVE(_ploveAddress);
    }
    function setDOMAIN_SEPARATOR(string memory _name, string memory _version, uint256 _chainId) public onlyOwner{
        DOMAIN_SEPARATOR = keccak256(abi.encode(
            EIP712DOMAIN_TYPEHASH,
            keccak256(bytes(_name)),   //name:
            keccak256(bytes(_version)),          //version:
            _chainId,                              //chainId:
            address(this)                            //verifyingContract:
        ));
    }
    function setApprovedAddresses(address _approvedAddress, bool _set) external onlyOwner(){
        isApprovedAddress[_approvedAddress] = _set;
    }
    function createDutch (string memory _projectName, uint256 _startTime, uint _dutchRate, uint256 _timeRate,
    uint256 _startPrice,uint256 _minPrice, string memory _imgSrcLink, string memory _discordLink, string memory _twitterLink, uint256 _maxWhitelists) external onlyApprovedAddresses{
        require(!auctionExists[_projectName],"The name is already defined");
        require(!auctionSettings[totalAuctions].exists,"This auction already exists");
        require(_startTime > 0 ,"Incorret start time value");
        require(_startPrice > 0 ,"Incorret start price value");
        require(_minPrice > 0 ,"Incorret min price value");
        require(_maxWhitelists > 0 ,"Incorret maxWL value");

        auctionSettings[totalAuctions] = Auction({
            id: totalAuctions,
            auctionType: 1,   //dutch type
            projectName: _projectName,
            startTime: _startTime,
            dutchPriceRate: _dutchRate,
            dutchTimeRate: _timeRate,
            startPrice: _startPrice,
            minPrice: _minPrice,
            imgSrc: _imgSrcLink,
            discordLink: _discordLink,
            twitterLink: _twitterLink,
            maxWhitelists: _maxWhitelists,
            exists: true
        });
        auctionExists[_projectName] = true;
        totalAuctions++;
    }
    function createBuyNow (string memory _projectName, uint _startTime, uint256 _startPrice, string memory _imgSrcLink, 
    string memory _discordLink, string memory _twitterLink, uint256 _maxWhitelists) external onlyApprovedAddresses{
        require(!auctionExists[_projectName],"The name is already defined");
        require(!auctionSettings[totalAuctions].exists,"This auction already exists");
        require(_startTime > 0 ,"Incorret start time value");
        require(_startPrice > 0 ,"Incorret start price value");
        require(_maxWhitelists > 0 ,"Incorret maxWL value");

        auctionSettings[totalAuctions] = Auction({
            id: totalAuctions,
            auctionType: 0,   //buy now type
            projectName: _projectName,
            startTime: _startTime,
            dutchPriceRate: 0,
            dutchTimeRate: 0,
            startPrice: _startPrice,
            minPrice: _startPrice,
            imgSrc: _imgSrcLink,
            discordLink: _discordLink,
            twitterLink: _twitterLink,
            maxWhitelists: _maxWhitelists,
            exists: true
        });
        auctionExists[_projectName] = true;
        totalAuctions++;
    }
    function enterAuction(uint256 _auctionId, string memory _auctionType, uint256 _entryPrice, uint256 _nonce, uint8 _v, 
    bytes32 _r, bytes32 _s, address _sender) external onlyApprovedAddresses{
        require(_sender != address(0), "INVALID-ADDRESS");
        require(verify(_auctionId, _auctionType, _entryPrice, _nonce, _v, _r, _s, _sender), "INVALID-SIGNATURE");
        require(auctionSettings[_auctionId].exists, "Auction does not exist or removed");
        require(block.timestamp >= auctionSettings[_auctionId].startTime, "Auction not open");
        require(!isWhiteListed(_sender,_auctionId), "Already whiteListed");
        require(viewAuctionState(_auctionId), "Auction Sold Out");
        uint256 auctionPrice = getCurrentPrice(_auctionId);
        require(ploveAddress.balanceOf(_sender)>= auctionPrice *1 ether, "Not enough LOVE");
        ploveAddress.burn(_sender,auctionPrice * 1 ether);
        whitelists[_auctionId].push(_sender);
        _nonces[_sender]++;
        emit auctionEntry(_sender,_auctionId, auctionPrice, block.timestamp);
    }
    function updateAuction(uint256 _auctionId, string memory _projectName, uint256 _startTime, uint _dutchRate,uint256 _timeRate,
    uint256 _startPrice, uint256 _minPrice, string memory _imgSrcLink, string memory _discordLink, string memory _twitterLink, uint256 _maxWhitelists) external onlyApprovedAddresses{
        require(auctionSettings[_auctionId].exists,"Auction does not exist or removed");
        auctionSettings[_auctionId].projectName = _projectName;
        auctionSettings[_auctionId].startTime = _startTime;
        auctionSettings[_auctionId].dutchPriceRate = _dutchRate;
        auctionSettings[_auctionId].dutchTimeRate = _timeRate;
        auctionSettings[_auctionId].startPrice = _startPrice;
        auctionSettings[_auctionId].minPrice = _minPrice;
        auctionSettings[_auctionId].imgSrc = _imgSrcLink;
        auctionSettings[_auctionId].discordLink = _discordLink;
        auctionSettings[_auctionId].twitterLink = _twitterLink;
        auctionSettings[_auctionId].maxWhitelists = _maxWhitelists;
    }
    function removeAuction(uint256 _auctionId) external onlyApprovedAddresses{
        auctionSettings[_auctionId].exists = false;
    }
    /* 
        VIEW FUNCTIONS 
     */
    function viewAuction(uint256 _auctionId) public view returns (Auction memory){
        return auctionSettings[_auctionId];
    }
    function viewAuctionState(uint256 _auctionId) public view returns (bool){
        return getAuctionWhitelists(_auctionId).length < auctionSettings[_auctionId].maxWhitelists
        ? true:false;
    }
    function getAuction(uint256 _auctionId) public view returns (Auction memory){
        return auctionSettings[_auctionId];
    }
    function getAuctionWhitelists(uint256 _auctionId) public view returns (address [] memory){
        return whitelists[_auctionId];
    }
    function getCurrentPrice(uint256 _auctionId) public view returns (uint256){
        require(auctionSettings[_auctionId].exists,"Auction does not exist or removed");
        Auction memory auxAuction = auctionSettings[_auctionId];
        if(auxAuction.auctionType == 1){    //DUTCH auction
            if(block.timestamp < auxAuction.startTime){
                return auxAuction.startPrice;
            }
            uint256 reduction = (block.timestamp-auxAuction.startTime)/auxAuction.dutchTimeRate
            *auxAuction.dutchPriceRate;
            uint256 newPrice =  auxAuction.startPrice >= reduction ? 
            (auxAuction.startPrice - reduction) : 0;
            return newPrice >= auxAuction.minPrice ? newPrice : auxAuction.minPrice;
        }
        else{    //Buy now auction
            return auxAuction.startPrice;
        }
    }
    function isWhiteListed(address _wallet, uint256 _auctionId) public view returns (bool) {
        for (uint i = 0; i < whitelists[_auctionId].length; i++) {
            if (whitelists[_auctionId][i] == _wallet) {
                return true;
            }
        }
        return false;
    }
    function verify(uint256 _Auction_ID,string memory _Auction_Type,uint256 _Entry_Price,uint256 _Nonce, 
    uint8 _v, bytes32 _r, bytes32 _s, address _sender) public view returns (bool) {
        // Note: we need to use `encodePacked` here instead of `encode`.
        bytes32 digest = keccak256(abi.encodePacked(
            "\x19\x01",
            DOMAIN_SEPARATOR,
            keccak256(abi.encode(
                AuctionRequest_TYPEHASH,
                _Auction_ID,
                keccak256(bytes(_Auction_Type)),
                _Entry_Price,
                _Nonce
            ))
        ));
        return ecrecover(digest, _v, _r, _s) == _sender;
    }
}