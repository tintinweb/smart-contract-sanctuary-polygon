// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./Strings.sol";
import "./Address.sol";
import "./ReentrancyGuard.sol";
import "./MerkleProof.sol";
import "./Pausable.sol";
import "./IMintable.sol";


contract DutchAuctionSeller is Ownable, ReentrancyGuard,Pausable {

   using Address for address payable;
 
    address[] private whiteListedAddresses;
    
    uint256 private constant MAX_TOKEN_PER_ADDRESS = 25;
    
    bytes32 public merkleRoot;
    
    address public fundsReceiver = 0x7EFFC0db5d98e2fD82bc9aD495452A032092225f;
    
    bool public isPublic = false;

    uint256 public publicPrice = 400000000000000000;


    struct Auction {
        uint256 startPrice;
        uint256 endPrice;
        uint256 startDate;
        uint256 endDate;
    }
    
    Auction public auction;
    
    IMintable private collection;

    constructor(address _collection){
        collection = IMintable(_collection);
    }

    function mint(address to, uint256 quantity, bytes32[] calldata  _proof) external payable {
        require(quantity > 0 &&  quantity < 11  , "unvalid quantity");
        require(msg.value >= getCurrentPrice() * quantity ,"unvalid price");
        require(isWhitelistedAddress(msg.sender, _proof), "Invalid merkle proof");
        collection.mint(to,quantity * 3);
    }

    function publicMint(address to, uint256 quantity) external payable {      
        require(isPublic  , "public is not opened");
        require(quantity > 0 &&  quantity < 11  , "unvalid quantity");
        require(msg.value >= publicPrice * quantity ,"unvalid price");            
        collection.mint(to,quantity);
    }

    function airDrop(address to, uint256 quantity)  external onlyOwner {
        collection.mint(to,quantity);
    }
  
    function setDetails(uint256 _startDate, uint256 _endDate, uint256 _startPrice, uint256 _endPrice) external onlyOwner{
        uint256 nowSeconds = block.timestamp; 
        require(_startDate > nowSeconds,"startdate can't be past");
        require(_endDate >= _startDate,"endate must be superior to startdate");
        require(_startPrice > _endPrice,"startprice must be superior to endprice");
        require(_endPrice > 0,"endprice must be superior or egal to 0");
        auction = Auction(_startPrice, _endPrice, _startDate, _endDate);
    }

    

    function getCurrentPrice() public view returns(uint256) {
        require(!paused(), "Auction is on pause !");        
        uint256 nowSeconds = block.timestamp;       
        require(nowSeconds>=auction.startDate, "Auction didn't start yet");
        if(nowSeconds >= auction.endDate) {
            return auction.endPrice;
        }
        uint256 gap = auction.startPrice - auction.endPrice;
        uint256 duree = auction.endDate - auction.startDate;
        uint256 distanceFin = auction.endDate - nowSeconds;
        uint256 r = distanceFin * gap / duree;
        r = r + auction.endPrice;
        return  r;
    }
   
    function isWhitelistedAddress(address _address, bytes32[] calldata _proof) private view returns(bool) {
        bytes32 addressHash = keccak256(abi.encodePacked(_address));
        return MerkleProof.verifyCalldata(_proof, merkleRoot, addressHash);
    }

    function setMerkleRoot(bytes32 root) external onlyOwner {
        merkleRoot = root;
    }

    function setFundsReceiver(address  _fundsReceiver) external onlyOwner {
        fundsReceiver = _fundsReceiver;
    }

    
    function retrieveFunds() external {
        require(
            msg.sender == owner() ||
            msg.sender == fundsReceiver,
            "Not allowed"
        );        
       payable(fundsReceiver).sendValue(address(this).balance);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function setIsPublic(bool  _isPublic) external onlyOwner {
        isPublic = _isPublic;
    }

    function setPublicPrice(uint  _publicPrice) external onlyOwner {
        publicPrice = _publicPrice;
    }

    function timeBlock256() external view returns(uint256){
        return block.timestamp;
    }

}