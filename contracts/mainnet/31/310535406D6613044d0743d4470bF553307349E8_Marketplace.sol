//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

import "./Tokens.sol";
import "./SafeMath.sol";
import "./Counters.sol";
contract Marketplace is Tokens {
    // Function for owner to withdraw all funds from contract 
    // Use only in emergencies and make sure all users' pending payouts are recorded so no one loses funds
    function withdrawAll() public onlyMultisig {
        require(address(this).balance > 0, "Marketplace: No funds in contract.");
        (bool success,) = pay.call{value: address(this).balance}("");
        require(success, "Transfer fail");
    }

    // Function for owner to put a batch for sale on the marketplace
    // Buying this batch/pack gives the buyer ownership of all contents in the pack
    function sellPack(string memory packName, uint256[] memory _ids, uint256[] memory _amounts, uint256 price) public onlyOwner {
        // Pack size will be from 3 to 7 items
        for(uint i = 0; i < _ids.length; i++) {
            require(balanceOf(owner(), _ids[i]) >= _amounts[i], "Marketplace: Owner does not own enough of each item");
            require(activeItems[_msgSender()][_ids[i]] == true, "Marketplace: Already in pack or sold");
            activeItems[_msgSender()][_ids[i]] = false;
        }
        
        uint newBatchId = Counters.current(batchID);
        batchesForSale.push(Pack(_ids, price, _amounts, packName, false));

        emit batchAddedForSale(packName, newBatchId, _ids, price);
        Counters.increment(batchID);
    }
    
    // Takes a pack off of the marketplace
    function dissolvePack(uint256 batchId) public onlyOwner {
        require(batchesForSale[batchId].isSold == false, "Marketplace: Pack has already been sold or dissovled.");
        //require(activeBatches[_msgSender()][batchId] == true, "Marketplace: Pack has already been sold or removed from sale.");
        batchesForSale[batchId].isSold = true;
        //activeBatches[_msgSender()][batchId] = false;
    }
    
    // Function to remove an item from marketplace.
    // Can be used to take item off of primary or secondary marketplace
    function removeFromSale(uint256 _id) public whenNotPaused {
        require(activeItems[_msgSender()][_id] == true);
        require(itemsForSale[_id].owner == _msgSender());
        
        activeItems[_msgSender()][_id] = false;
        setApprovalForAll(owner(), false);
    }
    
    // Function for user to sell an item they own 
    // on the secondary marketplace, which allows crypto payments only 
    // Payments must be on Polygon network 
    function sellItem(uint256 id, uint256 _price) public whenNotPaused {
        require(itemsForSale[id].owner == _msgSender(), "Marketplace: you do not own this item");
        require(balanceOf(_msgSender(), id) > 0, "Marketplace: you do not own this item");
        require(!activeItems[_msgSender()][id], "Marketplace: item is already for sale by message sender");
        require(_price >= 3000000000000000000, "Marketplace: item price must be at least 3 MATIC");

        activeItems[_msgSender()][id] = true;
        setApprovalForAll(address(this), true);
        itemsForSale[id].price = _price;
        emit itemAddedForSale(id, _msgSender(), _price, itemsForSale[id].URI);
    }
    
    function buy(uint256 id, address recipient, bool wert) public payable whenNotPaused {
        require(activeItems[itemsForSale[id].owner][id] == true, "Marketplace: item is not for sale by owner");
        require(itemsForSale[id].owner != owner(), "Marketplace: item is not purchasable via this function");
        activeItems[itemsForSale[id].owner][id] = false;
        //uint256 cost = itemsForSale[id].price * 1000000;
        uint256 cost = itemsForSale[id].price;
        uint256 fee = 0;
        
        if(!wert) {
            fee = cost / 20;
        }
        require(msg.value == (cost + fee), "Value sent is not equal to price + fee");

        uint256 royalty = cost / royaltyPortion;
        uint256 payout = cost - royalty;
        
        // Should probably make royalty recipient different account 
        // from owner, for security reasons
        // Done, using address pay 
        // usdc.transferFrom(_msgSender(), itemsForSale[id].owner, payout);
        // usdc.transferFrom(_msgSender(), pay, royalty + fee);
        
        itemsForSale[id].owner.transfer(payout);
        (bool success,) = pay.call{value: royalty + fee}("");
        require(success, "Transfer fail");

        isLocal[id][recipient] = true;
        setSaleApproval(recipient, id, true);
        address oldOwner = itemsForSale[id].owner;
        safeTransferFrom(itemsForSale[id].owner, recipient, id, 1, data);
        itemsForSale[id].owner = payable(recipient);
        emit itemBought(id, cost, payout, royalty, oldOwner, recipient);
    }
    
    function buyPack(uint256[] memory packId, address recipient, bool wert) public payable whenNotPaused{
        uint256 totalCost;
        for(uint k = 0; k < packId.length; k++) {
            require(batchesForSale[packId[k]].price != 0, "Starter Packs not purchasable");
            totalCost += batchesForSale[packId[k]].price * 1000000000000000000;
        }
        uint256 fee = 0;
        if(!wert) {
            fee = totalCost / 20;
        }
        
        require(msg.value == (totalCost + fee), "Value sent is not equal to price + fee");

        (bool success, ) = pay.call{value: msg.value}(""); // This forwards all available gas
        require(success, "Transfer failed."); // Return value is checked   

        
        for(uint i = 0; i < packId.length; i++) {
            require(batchesForSale[packId[i]].isSold == false, "Marketplace: Pack has already been sold.");
            batchesForSale[packId[i]].isSold = true;
            
            isPackPurchase[owner()][recipient] = true;
            for(uint256 j = 0; j < batchesForSale[packId[i]].tokenIds.length; j++) {
                isLocal[batchesForSale[packId[i]].tokenIds[j]][recipient] = true;
                itemsForSale[batchesForSale[packId[i]].tokenIds[j]].owner = payable(recipient);
            }
            safeBatchTransferFrom(owner(), recipient, batchesForSale[packId[i]].tokenIds, batchesForSale[packId[i]].amounts, data);   
        }
        
        emit packBought(packId, totalCost + fee, recipient);
    }
    
    // Function to send a batch of NFTs to a user account
    // Batch is minted to recipient's account
    // To be used for NFT giveaways and promotions
    function sendPack(uint256 packId, address recipient) public onlyOwner {
        require(batchesForSale[packId].isSold == false, "Pack has already been sold.");
        require(batchesForSale[packId].price == 0, "Pack is not a starter pack");
        
        // Take pack off of marketplace 
        batchesForSale[packId].isSold = true;

        isLocal[batchesForSale[packId].tokenIds[0]][recipient] = true;
        itemsForSale[batchesForSale[packId].tokenIds[0]].owner = payable(recipient);
            
        safeBatchTransferFrom(_msgSender(), recipient, batchesForSale[packId].tokenIds, batchesForSale[packId].amounts, data);
    }
}