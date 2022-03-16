// SPDX-License-Identifier: MIT LICENSE
pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./PLOVE.sol";
import "./ECDSA.sol";
import "./Strings.sol";
contract mallowAuctions is Ownable{
    using Strings for uint;
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
    event auctionEntry(address indexed _user, uint256 indexed _auctionID, uint256 _entryPrice, uint256 _entryTime);
    PLOVE ploveAddress;
    uint256 public totalAuctions = 0;
    mapping(address => bool) isApprovedAddress;

    mapping(string => bool) public auctionExists;
    mapping(uint256 => Auction) auctionSettings; // map id => auction settings
    mapping(uint256 => address[]) public whitelists; // auction id => to WL users
    mapping(address => uint256) _nonces;    //maps nonces
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
    constructor(address _ploveAddress){
        ploveAddress = PLOVE(_ploveAddress);
        DOMAIN_SEPARATOR = keccak256(abi.encode(
            EIP712DOMAIN_TYPEHASH,
            keccak256(bytes("Auctions")),   //name:
            keccak256(bytes('1')),          //version:
            80001,                              //chainId:
            address(this)                            //verifyingContract:
        ));     
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
    function setApprovedAddresses(address _approvedAddress, bool _set) external onlyOwner(){
        isApprovedAddress[_approvedAddress] = _set;
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
    function enterAuction(uint256 _Auction_ID,string memory _Auction_Type,uint256 _Entry_Price, uint256 _Nonce, uint8 _v, 
    bytes32 _r, bytes32 _s, address _sender) external onlyApprovedAddresses{
  
        require(_sender != address(0), "INVALID-ADDRESS");
        require(verify(_Auction_ID,_Auction_Type,_Entry_Price,_Nonce,_v,_r,_s,_sender),"INVALID-SIGNATURE");
        require(auctionSettings[_Auction_ID].exists,"Auction does not exist or removed");
        require(viewAuctionState(_Auction_ID),"Auction not open");
        require(!isWhiteListed(msg.sender,_Auction_ID),"Already whiteListed");
        require(whitelists[_Auction_ID].length<auctionSettings[_Auction_ID].maxWhiteLists,
        "Auction Sold Out");
        uint256 auctionPrice = getCurrentPrice(_Auction_ID);
        require(ploveAddress.balanceOf(msg.sender)>= auctionPrice *1 ether, "Not enough LOVE");
        ploveAddress.burn(msg.sender,auctionPrice * 1 ether);
        whitelists[_Auction_ID].push(msg.sender);
        emit auctionEntry(msg.sender,_Auction_ID, auctionPrice, block.timestamp);
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
    function isWhiteListed(address _wallet,uint256 _auctionId) public view returns (bool) {
        for (uint i = 0; i < whitelists[_auctionId].length; i++) {
            if (whitelists[_auctionId][i] == _wallet) {
                return true;
            }
        }
        return false;
    }
    function getNonce(address _wallet) public view returns (uint256){
        return _nonces[_wallet];
    }
}