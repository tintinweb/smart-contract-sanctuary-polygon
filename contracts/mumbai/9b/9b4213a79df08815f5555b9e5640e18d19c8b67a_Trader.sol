// SPDX-License-Identifier: MIT


pragma solidity ^0.8.0;

import "./mint_matic.sol";


contract Trader {

    mapping(address => mapping(uint256 => Listing)) public listings;

    mapping (uint256 => uint256) public previousOwnersCount;

    mapping(uint => mapping(uint => address)) public royalties;


    uint256 public adminFeesCollected;


    address public adminAccount;

    constructor(){
        adminAccount = msg.sender;
    }

   
    struct Listing {
        uint256 price;
        address seller;
        bool royalty;
    }




    function changeAdmin(address _newAccount)public{
        require(msg.sender == adminAccount , "Only admin allowed to change");
        adminAccount = _newAccount;
    }


    function addListing(uint256 price, address contractAddr, uint256 tokenId,bool tokenRoyalty) public {
        ERC721 token = ERC721(contractAddr);
        require(token.ownerOf(tokenId) == msg.sender, "caller must own given token");
        require(token.getApproved(tokenId) == address(this), "contract must be approved");
        listings[contractAddr][tokenId] = Listing(price,msg.sender,tokenRoyalty);
    }

 


    function purchase(address contractAddr, uint256 tokenId) public payable {
        Listing memory item = listings[contractAddr][tokenId];
        address payable seller = payable(item.seller); 
        require(msg.value >= item.price, "insufficient funds sent");
        ERC721 token = ERC721(contractAddr);
        address tokenCreator = token.getCreator(tokenId);
        address tokenOwner = token.ownerOf(tokenId);
        uint256 royalty = token.royaltyFee(tokenId); 
  
        if(tokenOwner != tokenCreator && item.royalty == false){
            //transfer with royalty
            uint256 royaltyFee = (msg.value * royalty/100)/(previousOwnersCount[tokenId]+2);
            
            for(uint i =0; i<previousOwnersCount[tokenId];i++){
                payable(royalties[tokenId][i]).transfer(royaltyFee * 10);
            }
            payable(adminAccount).transfer(royaltyFee * 10);
            seller.transfer(msg.value - (msg.value * royalty/100 * 10 + royaltyFee * 10));   
        }
        else
        {           
            //transfer without royalty
            seller.transfer(msg.value);           
        }
        royalties[tokenId][previousOwnersCount[tokenId]] = seller;
        previousOwnersCount[tokenId] +=1; 
        token.transferFrom(item.seller,msg.sender,tokenId);
        delete listings[contractAddr][tokenId];
    }
}