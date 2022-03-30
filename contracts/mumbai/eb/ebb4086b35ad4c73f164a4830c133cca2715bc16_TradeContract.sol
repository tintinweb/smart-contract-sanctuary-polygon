// SPDX-License-Identifier: MIT


pragma solidity ^0.8.0;


import "./Xverse1155.sol";

contract TradeContract {


    mapping(address => mapping(uint256 => CollectibleListing)) public collectibleListings;


    uint256 public adminFeesCollected;



    struct CollectibleListing {
        uint256 price;
        address seller;
        uint256 amount;
    }



   address public adminWallet = address(0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2);

   function changeAdmin(address newAdminAddress) public{
       require(msg.sender == address(0x3A086e37DDdfc792B5ac38CD651d6C640B7F85A9), "Only admin can perform this action");
        adminWallet = newAdminAddress;
   }



    function addCollectibleListing(uint256 price, address contractAddr, uint256 tokenId, uint256 amount) public {
        ERC1155 token = ERC1155(contractAddr);
        require(token.balanceOf(msg.sender,tokenId) >= amount, "caller must own given token");
        require(token.isApprovedForAll(msg.sender,address(this)) , "contract must be approved");
        collectibleListings[msg.sender][tokenId] = CollectibleListing(price,msg.sender,amount);


    }




    function purchaseCollectible(address contractAddr, uint256 tokenId, uint256 amount, address owner) public payable {
        CollectibleListing memory item = collectibleListings[owner][tokenId];
        address payable seller = payable(item.seller); 
        address payable admin = payable(adminWallet);
        require(msg.value >= item.price*amount, "insufficient funds sent");
        require(amount < item.amount, "amount greater than avaialable balance");
        
        uint256 adminFee = (msg.value * 2/100);
        adminFeesCollected += adminFee;

        ERC1155 token = ERC1155(contractAddr);

        address tokenCreator = token.getCreator(tokenId);
        address tokenOwner = item.seller;
        uint256 royalty = token.royaltyFee(tokenId); 

        
        if(tokenOwner != tokenCreator){

            //transfer with royalty
         
            uint256 royaltyFee = (msg.value * royalty/100);
            
   
            payable(tokenCreator).transfer(royaltyFee);
            admin.transfer(adminFee);
            seller.transfer(msg.value - (adminFee)- (royaltyFee));       
      
        }

        else
        {           
            //transfer without royalty
            admin.transfer(adminFee);
            seller.transfer(msg.value - (adminFee));           
        }

        token.safeTransferFrom(item.seller,msg.sender,tokenId,amount,"data");
        collectibleListings[owner][tokenId].amount -= amount;

    }
}