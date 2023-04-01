// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./Strings.sol";
import "./Address.sol";
import "./ReentrancyGuard.sol";
import "./MerkleProof.sol";
import "./Pausable.sol";
import "./IMintable.sol";


contract AgoraSeller is Ownable, ReentrancyGuard,Pausable {

   using Address for address payable;
 
    address[] private whiteListedAddresses;
    
    uint256 private constant MAX_TOKEN_PER_ADDRESS = 25;
    
    bytes32 public merkleRoot;
    
    address public fundsReceiver = 0xFC4CD73C117b2749e954c8e299532cbA6690871D;
    
    bool public isPublic = false;

    uint256 public publicPrice = 400000000000000;
      
    IMintable private collection;
/*
    constructor(address _collection){
        collection = IMintable(_collection);
    }
    */
    constructor(){
        
    }
    function mint(address to, uint256 quantity, bytes32[] calldata  _proof) external payable {        
        require(!paused(), "is on pause !");        
        require(msg.value >= publicPrice * quantity ,"unvalid price");
       // require(isWhitelistedAddress(msg.sender, _proof), "Invalid merkle proof");
        //collection.mint(to,quantity * 3);
    }

     function buy(address to, uint256 quantity) external payable {        
        require(!paused(), "is on pause !");        
        require(msg.value >= publicPrice * quantity ,"unvalid price");
       // require(isWhitelistedAddress(msg.sender, _proof), "Invalid merkle proof");
        //collection.mint(to,quantity * 3);
    }

    
    function airDrop(address to, uint256 quantity)  external onlyOwner {
        collection.mint(to,quantity);
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

    function setPublicPrice(uint  _publicPrice) external onlyOwner {
        publicPrice = _publicPrice;
    }

    function setCollection(address _collection) external onlyOwner {
        collection = IMintable(_collection);
    }

    function timeBlock256() external view returns(uint256){
        return block.timestamp;
    }

    

}