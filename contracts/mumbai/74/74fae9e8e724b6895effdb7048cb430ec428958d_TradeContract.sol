// SPDX-License-Identifier: MIT


pragma solidity ^0.8.4;


import "./multimint_matic.sol";

contract TradeContract {


    mapping(address => mapping(uint256 => CollectibleListing)) public collectibleListings;

    mapping (uint256 => uint256) public previousOwnersCount;

    mapping(uint => mapping(uint => address)) public royalties;


    uint256 public adminFeesCollected;



    struct CollectibleListing {
        uint256 price;
        address seller;
        uint256 amount;
        bool royalty;
    }



   address public adminWallet = address(0x11046969DC55F8ff757B9c91e3900a25217bbbD8);

   function changeAdmin(address newAdminAddress) public{
       require(msg.sender == address(0x11046969DC55F8ff757B9c91e3900a25217bbbD8), "Only admin can perform this action");
        adminWallet = newAdminAddress;
   }



    function addCollectibleListing(uint256 price, address contractAddr, uint256 tokenId, uint256 amount,bool tokenRoyalty) public {
        ERC1155 token = ERC1155(contractAddr);
        require(token.balanceOf(msg.sender,tokenId) >= amount, "caller must own given token");
        require(token.isApprovedForAll(msg.sender,address(this)) , "contract must be approved");
        collectibleListings[msg.sender][tokenId] = CollectibleListing(price,msg.sender,amount, tokenRoyalty);


    }




    function purchaseCollectible(address contractAddr, uint256 tokenId, uint256 amount, address owner) public payable {
        CollectibleListing memory item = collectibleListings[owner][tokenId];
        address payable seller = payable(item.seller); 
        address payable admin = payable(adminWallet);
        require(msg.value >= item.price*amount, "insufficient funds sent");
        require(amount <= item.amount, "amount greater than avaialable balance");
        
        uint256 adminFee = (msg.value * 2/100);
        adminFeesCollected += adminFee;

        ERC1155 token = ERC1155(contractAddr);

        address tokenCreator = token.getCreator(tokenId);
        address tokenOwner = item.seller;
        uint256 royalty = token.royaltyFee(tokenId); 
        
        if(tokenOwner != tokenCreator && item.royalty == false){
         
            //transfer with royalty
            uint256 royaltyFee = (msg.value * royalty/100)/(previousOwnersCount[tokenId]+1);
            for(uint i =0; i<previousOwnersCount[tokenId];i++){
                payable(royalties[tokenId][i]).transfer(royaltyFee);
            }
            payable(admin).transfer(royaltyFee);
            seller.transfer(msg.value - (msg.value * royalty/100));        
      
        }

        else
        {           
            //transfer without royalty
            seller.transfer(msg.value);         
        }

        token.safeTransferFrom(item.seller,msg.sender,tokenId,amount,"data");
        collectibleListings[owner][tokenId].amount -= amount;

    }
}