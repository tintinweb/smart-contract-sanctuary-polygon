// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC721.sol";
import "./ReentrancyGuard.sol";
import "./Strings.sol";
import "./Address.sol";
import "./Pausable.sol";


contract AgoraSeller is ERC721, Ownable , ReentrancyGuard,Pausable{
    
    using Address for address payable;

    using Strings for uint256;

    //max supply
    uint256 public MAX_SUPPLY = 3210;

    //current minted supply
    uint256 public totalSupply;

   

    address public fundsReceiver = 0xFC4CD73C117b2749e954c8e299532cbA6690871D;
    
    bool public isPublic = false;

    uint256 public publicPrice = 400000000000000;
      
    

    //metadatas
    string public baseURI = "https://storage.googleapis.com/devmetata666666/Wag-wan/metadata/";

    constructor()
    ERC721("test", "LEB")
        {
        }


    function setBaseUri(string memory  _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }
   
    function buy(address to, uint256 quantity) external payable {
        require(!paused(), "is on pause !");        
         require(totalSupply<MAX_SUPPLY, "supply limit reached");
        require(msg.value >= publicPrice * quantity ,"unvalid price");
       // require(isWhitelistedAddress(msg.sender, _proof), "Invalid merkle proof");
        //collection.mint(to,quantity * 3);
    }
  

    function tokenURI(uint256 tokenId) public view override
        returns (string memory)
    {
        require(_exists(tokenId), "URI query for nonexistent token");
        // Concatenate the baseURI and the tokenId as the tokenId should
        // just be appended at the end to access the token metadata
        return string(abi.encodePacked(baseURI, tokenId.toString(), ".json"));
    }

    function setFundsReceiver(address  _fundsReceiver) external onlyOwner {
        fundsReceiver = _fundsReceiver;
    }
 function setPublicPrice(uint  _publicPrice) external onlyOwner {
        publicPrice = _publicPrice;
    }

    function timeBlock256() external view returns(uint256){
        return block.timestamp;
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

}