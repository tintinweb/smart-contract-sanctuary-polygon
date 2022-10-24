// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "./NFTicketsTic.sol";
import "./NFTicketsUtils.sol";

//Custom Errors
error Not20PercentOfListing(); // "Listing fee must equal 20% of expected sales"
error NotEnoughTokensForListing(); // "You don't own enough for this sale"
error NoLongerOnSale(); // "No longer on sale"
error NotEnoughItemsForSale(); // "There are no more items to sell"
error NotAskingPrice(); // "Please submit the asking price in order to complete the purchase"
error ItemNotListed(); // "This item hasn't been listed yet"
error ItemSoldOut(); // "This item has sold out, create a new listing"
error NotOriginalSeller(); // "Only the original seller can relist"
error InvalidSignatureLength(); // "invalid signature length"
error InvalidStatus(); // "Invalid status"
error SellerOnlyFunction(); // "Only for seller"
error NoSales(); // "No Sales"
error NothingToRefund(); // "Nothing to refund"
error NotDisputed(); // "Not in dispute"
error NoBuyers(); // "No Buyers"
error NotOwner();
error AlreadyRefunded();


//contract NFTicketsMarket is ReentrancyGuard, ERC1155Holder, NFTicketsUtilities {
contract NFTicketsMarket is ReentrancyGuard, ERC1155Holder {
    using Counters for Counters.Counter;
    // ********* These can revert back to private soon **********
    Counters.Counter public _itemIds;
    Counters.Counter public _itemsSold;

    address payable immutable owner; // The contract owner is going to remain unchanged
    //uint256 listingPrice = 1 ether;
    uint256 constant listingFee = 5; // used to divide the price an get to the percentage i.e. 20%
    uint256 constant successFee = 4; // used to divide the listing fees and chare the seller 5% in undisputed transactions
    uint256 constant internal DAY = 86400;


    NFTicketsUtils utils;
    
    constructor(address _owner, address _utils) {
        //owner = payable(msg.sender); // This needs to be looked at - the owner is not used anywhere yet and should be a higher level contract
        owner = payable(_owner);
        utils = NFTicketsUtils(_utils);
    }

    struct MarketItem {
        uint itemId;
        address nftContract;
        uint256 tokenId;
        string name;
        address payable seller;
        address payable owner; // ********* does the owner need to be payable? ********
        uint256 price;
        uint256 amount;
        uint256 initialQuantity;
        uint256 totalSales;
        //bool onSale;
        uint8 status;
        /* Status codes
        0 Unprocessed
        1 Seller paid (and most of listing fee refunded)
        2 In dispute (complaint raised)
        3 Porcessed - Dispute resolved in seller's favour - buyer penalised (can be automated or by DAO vote)
        4 Porcessed - Dispute resolved in buyer's favour - seller penalised (can be automated or by DAO vote)
        5 Dispute raised to DAO - await extra time
        6 Porcessed - Refunded by seller - seller will need to select this once dispute is raised - most of the listing fee will be refunded to seller
        */
        uint256 finalCommision;
    }

    struct MyItems {
        uint itemId;
        address nftContract;
        uint256 tokenId;
        uint256 price;
        uint256 amount;
    }

    mapping(uint256 => MarketItem) private idToMarketItem; //Maps each market item
    mapping(uint256 => address[]) internal marketItemIdToBuyers; // Maps each market item to an array of addresses that purchased the item
    mapping(address => mapping(uint256 => uint256)) public addressToSpending; // Maps how much each address has spent on each item
    mapping(address => mapping(uint256 => uint256)) public sellerToDepositPerItem; // Maps how much each seller has deposited per peach market item

    event MarketItemCreated (
        uint indexed itemId,
        address indexed nftContract,
        uint256 indexed tokenId,
        string name,
        address seller,
        address owner,
        uint256 price,
        uint256 amount,
        uint256 initialQuantity,
        uint256 totalSales,
        //bool onSale,
        uint8 status,
        uint256 finalCommision
    );
  
    // !*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*
    // ********** Need to ensure the listing fee distribution methods are looked into **********
    // This lists a new item onto the market - the seller must pay 20% fee calculated based of the per ticket price and number of tickets placed for sale
    function listNewMarketItem(address nftContract, uint256 tokenId, uint256 amount, bytes memory data, string memory name) public payable nonReentrant {
        //if(msg.value != (getConversion(utils.getPrice(nftContract, tokenId)) * amount / listingFee)) { revert Not20PercentOfListing();}  // offline for testing
        if(msg.value != (utils.getPrice(nftContract, tokenId) * amount / listingFee)) { revert Not20PercentOfListing();}
        NFTicketsTic temp = NFTicketsTic(nftContract);
        if(temp.balanceOf(msg.sender, tokenId) < amount) { revert NotEnoughTokensForListing();}

        _itemIds.increment();
        uint256 itemId = _itemIds.current();
        
        idToMarketItem[itemId] =  MarketItem(
            itemId,
            nftContract,
            tokenId,
            name,
            payable(msg.sender),
            payable(address(0)),
            utils.getPrice(nftContract, tokenId), 
            amount,
            amount,
            0,
            //true,
            0,
            0
        );

        emit MarketItemCreated(
            itemId,
            nftContract,
            tokenId,
            name,
            msg.sender,
            address(0),
            utils.getPrice(nftContract, tokenId),
            amount,
            amount,
            0,
            //true,
            0,
            0
        );    
        temp.useUnderscoreTransfer(msg.sender, address(this), tokenId, amount, data);
        sellerToDepositPerItem[msg.sender][itemId] = sellerToDepositPerItem[msg.sender][itemId] + msg.value; // records how much deposit was paid by a seller/wallet for the market item
    }


    // Returns the total value deposited by a seller on a particular market item listing - needs to become internal
    function getDeposit (address depositor, uint256 marketItem) private view returns (uint256) {
        return sellerToDepositPerItem[depositor][marketItem];
    }      

    // !*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*
    // Buys one or more tickets from the marketplace, ensuring there are enough tickets to buy, and the buyer is paying the asking price as per current native token to USD conversion.
    // ********* Payment is automatically paid the the tickets lister. This will need to be modified so that funds remain in escrow until keeper pays out the proceeds if there are no justified complaints *********
    function buyMarketItem (address nftContract, uint256 itemId, uint256 amount, bytes memory data) public payable nonReentrant {
        //if(idToMarketItem[itemId].onSale != true) { revert NoLongerOnSale();} // Need to replace the on sale flag
        
        if(idToMarketItem[itemId].amount < amount) { revert NotEnoughItemsForSale();}
        //if(msg.value != getConversion(idToMarketItem[itemId].price) * amount) { revert NotEnoughItemsForSale();} //testing with no conversion
        if(msg.value != idToMarketItem[itemId].price * amount) { revert NotAskingPrice();}

        NFTicketsTic temp = NFTicketsTic(nftContract);    
        if(temp.getFinishTime(idToMarketItem[itemId].tokenId) <= block.timestamp) { revert NoLongerOnSale();}    // this should replace the onsale flag
        //idToMarketItem[itemId].seller.transfer(msg.value); // payment should come to this contract for escrow - right now it pays directly to the seller - commenting out will need this functionality in the future
        addressToSpending[msg.sender][itemId] = addressToSpending[msg.sender][itemId] + msg.value; // records how much was paid by a buyer/wallet for the item id
        addBuyerToItem (itemId, msg.sender);
        temp.useUnderscoreTransfer(address(this), msg.sender, idToMarketItem[itemId].tokenId, amount, data);
        idToMarketItem[itemId].amount = idToMarketItem[itemId].amount - amount;
        idToMarketItem[itemId].totalSales = idToMarketItem[itemId].totalSales + msg.value;
        idToMarketItem[itemId].owner = payable(msg.sender); // *********** This actually makes the buyer listed as the owner - but it only means they are the last buyer or the last to become an owner of this NFT - NEEDS LOOKING INTO
        if(idToMarketItem[itemId].amount == 0){
            _itemsSold.increment();
            //idToMarketItem[itemId].onSale = false; // ************ need to replace this with a different status code and also check if adding more listings needs to look at changing status code
        }
    }

    // Returns array of information from the MarketItem Struct - used by the front end to display relevant data
    function getMarketItem(uint256 marketItemId) public view returns (MarketItem memory) {
        return idToMarketItem[marketItemId];
    }

    // Returns number of remaining tickets on sale on the Market for a particular market listing
    function checkRemaining (uint256 id) public view returns (uint256) {
        return idToMarketItem[id].amount;
    }

    // Returns all items currently on sale on the market including all the data of each item
    function fetchItemsOnSale() public view returns (MarketItem[] memory) {
        uint itemCount = _itemIds.current();
        uint unsoldItemCount = _itemIds.current() - _itemsSold.current();
        uint currentIndex = 0;

        MarketItem[] memory items = new MarketItem[](unsoldItemCount);
        for (uint i = 0; i < itemCount; i++) {
            NFTicketsTic temp = NFTicketsTic(idToMarketItem[i + 1].nftContract);
            if (idToMarketItem[i + 1].status != 6 && temp.getFinishTime(idToMarketItem[i + 1].tokenId) < block.timestamp) {
                uint currentId = i + 1;
                MarketItem storage currentItem = idToMarketItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }

    // !*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*
    // ******** Need to check if the below description is accurate - does this function actually fail or does it return the market items that are owned by the msg.sender? **********
    // ******** Need to update this because the owner field can be reset - should be checking using the balanceOf function of the IERC1155 standard i.e. balanceOf(msg.sender, MarketItem.tokenId)
    //This function will need to be rewritten as the owner field will no longer accurately reflect
    function fetchMyNFTs() public view returns (MarketItem[] memory) {
        uint totalItemCount = _itemIds.current();
        uint itemCount = 0;
        uint currentIndex = 0;

        for (uint i = 0; i < totalItemCount; i++) {
            if (idToMarketItem[i + 1].owner == msg.sender) {
                itemCount += 1;
            }
        }

        MarketItem[] memory items = new MarketItem[](itemCount);
        for (uint i = 0; i < totalItemCount; i++) {
            if (idToMarketItem[i + 1].owner == msg.sender) {
                uint currentId = i + 1;
                MarketItem storage currentItem = idToMarketItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }

    // Finds makret items using the tokenId of the NFT - useful to determine if any current listings exist
    function findMarketItemId(address _nftContract, uint256 _tokenId) private view returns(uint) {
        uint totalItemCount = _itemIds.current();
        uint itemCount = 0;

        for (uint i = 0; i < totalItemCount; i++) {
            if (idToMarketItem[i + 1].nftContract == _nftContract && idToMarketItem[i + 1].tokenId == _tokenId) {
                    itemCount = i + 1;
            }
        }
        return itemCount;
    }

    // !*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*
    // ********** Need to ensure the listing fee distribution methods are looked into **********
    // Lists additional tickets to the market item if a listing on the market is still open and has tickets remaining on sale
    // Checks if the item has already been listed, if the listing is still active, ensures only the original lister can add more tickets and ensures listing fee is paid to the marketplace.
    function listMoreOfMarketItem(address nftContract, uint256 tokenId, uint256 amount, bytes memory data, string memory name) public payable nonReentrant {
        if(findMarketItemId(nftContract, tokenId) <= 0) { revert ItemNotListed();}
        if(idToMarketItem[findMarketItemId(nftContract, tokenId)].amount == 0) { revert ItemSoldOut();}
        if(msg.sender != idToMarketItem[findMarketItemId(nftContract, tokenId)].seller) { revert NotOriginalSeller();}
        if(msg.value != (utils.getConversion(utils.getPrice(nftContract, tokenId)) * amount / listingFee)) { revert Not20PercentOfListing();}
        NFTicketsTic temp = NFTicketsTic(nftContract);
        if(temp.balanceOf(msg.sender, tokenId) < amount) { revert NotEnoughTokensForListing();}

        uint256 itemId = findMarketItemId(nftContract, tokenId);
        uint newAmount = idToMarketItem[itemId].amount + amount;
        uint256 updatedQuantity = idToMarketItem[itemId].initialQuantity + amount;
        
        idToMarketItem[itemId] =  MarketItem(
            itemId,
            nftContract,
            tokenId,
            name,
            payable(msg.sender),
            payable(address(0)), // ******** Need to check if this needs to be payable? *********
            utils.getPrice(nftContract, tokenId), 
            newAmount,
            updatedQuantity,
            idToMarketItem[itemId].totalSales,
            //true,
            0,
            0
        );
        temp.useUnderscoreTransfer(msg.sender, address(this), tokenId, amount, data);
        //IERC1155(nftContract).safeTransferFrom(msg.sender, address(this), tokenId, amount, data);  
        sellerToDepositPerItem[msg.sender][itemId] = sellerToDepositPerItem[msg.sender][itemId] + msg.value; // records how much deposit was paid by a seller/wallet for the market item
    }

    // Runs through all listings on the market and checks how many belong to the user
    function fetchUserNFTs(address user) public view returns (MyItems[] memory) {
        uint totalItemCount = _itemIds.current();
        uint itemCount = 0;
        uint currentIndex = 0;
    
        for (uint i = 0; i < totalItemCount; i++) {
            NFTicketsTic temp = NFTicketsTic(idToMarketItem[i +1].nftContract); 
            if (temp.balanceOf(user, idToMarketItem[i + 1].tokenId) > 0) {
                itemCount += 1;
            }
        }

        MyItems[] memory personalItems = new MyItems[](itemCount);
        for (uint i = 0; i < totalItemCount; i++) {
            NFTicketsTic temp = NFTicketsTic(idToMarketItem[i +1].nftContract); 
            if (temp.balanceOf(user, idToMarketItem[i + 1].tokenId) > 0) {
                uint currentId = i + 1;
                MarketItem storage currentItem = idToMarketItem[currentId];
                personalItems[currentIndex] = MyItems(currentItem.itemId, currentItem.nftContract, currentItem.tokenId, currentItem.price, temp.balanceOf(user, idToMarketItem[i + 1].tokenId));
                currentIndex += 1;
            }
        }
        return personalItems;
    }


    // -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
    // This section deals with checking if the ticket (QR) presenter is actually the owner of the ticket

    // Generates a hash for a message
    function getMessageHash(string memory _message) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_message));
    }

    // Signs the message hash
    function getEthSignedMessageHash(bytes32 _messageHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash));
    }

    // Verifies that the QR code was generated by the wallet address the QR code says the ticket belongs to, and that wallet owns a ticket to the event.
    function verify(address _signer, string memory _message, bytes memory signature, uint256 _itemId, address nftContract) internal view returns (string memory _result) {
        bytes32 messageHash = getMessageHash(_message);
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);
        //This is the address used for testing that is being checked - will actually be list of NFT owners in real app
        //address _testAddress = 0xc88Ad52065A113EbE503a4Cb6bCcE02B4802c264;
        NFTicketsTic temp = NFTicketsTic(nftContract);
        _result = "Not on the list";
        if (temp.balanceOf(_signer, idToMarketItem[_itemId].tokenId) > 0 && (recoverSigner(ethSignedMessageHash, signature) == _signer)) {
            _result = "On the list";
        } 
        return _result;
    }

    // Determines which wallet signed the message hash
    function recoverSigner(bytes32 _ethSignedMessageHash, bytes memory _signature) internal pure returns (address) {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);
        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    // Splits the signature for the recoverSigner function
    function splitSignature(bytes memory sig) internal pure returns (bytes32 r, bytes32 s, uint8 v) {
        if(sig.length != 65) { revert InvalidSignatureLength();}
        assembly {
            r := mload(add(sig, 32))  
            s := mload(add(sig, 64))  
            v := byte(0, mload(add(sig, 96)))
        }
    }

    // !*!*!*!*!*!*!*!*!*!*!*!*!*!*!*
    // ******* Need to update this to ensure that the _message that is being hashed is not using the name of the event but rather a unique identifier such as the marketItem itemId *********
    // ******* Need to rename this funciton to a more appropriate name like confirmTicketAuthenticity
    // Allows the host or ticket checker to check the QR code and ensure the ticket holder is on the list, and that the QR code was generated by the wallet that is on the list for the event.
    function hostActions(uint256 _itemId, bytes memory _sig, address nftContract) public view returns (string memory) {
        string memory _message = idToMarketItem[_itemId].name; // This needs to be updated - need to stop using the name of the event as there could be conflicts - need to use the itemId from the marketItem
        bytes32 _messageHash = getMessageHash(_message);
        bytes32 _ethSignedMessageHash = getEthSignedMessageHash(_messageHash);
        address _signer = recoverSigner(_ethSignedMessageHash, _sig);
        return verify(_signer, _message, _sig, _itemId, nftContract);
    }

    // !*!*!*!*!*!*!*!*!*!*!*!*!*!*!*
    // ************* Need to add another function to be able to mark attendance, this will need to have a sub function to ensure only authorised people/wallets can mark attendance ********

    // -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

    // Works out Deposit to refund in undisputed transactions
    function depositRefundAmount (address _depositor, uint256 _marketItem) private view returns (uint256) {
        return getDeposit(_depositor, _marketItem) - (getDeposit(_depositor, _marketItem) / successFee);
    }

    // Changes the status code of the market item - testing function only
    // ******* This function will need to become restricted to the DAO Timelock or keeper contract - _newStatus must refer to the decision from the DAO Governor / Controller *******
    function changeStatus (uint256 _marketItem, uint8 _newStatus) public onlyOwner {
        if(_newStatus < 0 || _newStatus >= 7) { revert InvalidStatus();}
        idToMarketItem[_marketItem].status = _newStatus;
    }

    //function to pay the seller - work out deposit refund, total sales, combine both and pay out, update deposit amount and sales amount to 0
    // ************* Need to make this onlyOwner ********
    function paySellers () external payable onlyOwner nonReentrant{ 
        uint totalItemCount = _itemIds.current();
        uint itemCount = 0;
        uint currentIndex = 0;

        uint256 marketComission = 0;

        // Determine how many items there are to be processed
        for (uint i = 0; i < totalItemCount; i++) {
            //if (idToMarketItem[i + 1].onSale == false && (idToMarketItem[i + 1].status == 0 || idToMarketItem[i + 1].status == 3 || idToMarketItem[i + 1].status == 6)) { // check to make sure the item is no longer on sale // check to make sure the item is not in dispute - this needs to be updated to include status codes 3 & 6
            if (idToMarketItem[i + 1].status == 0 || idToMarketItem[i + 1].status == 3 || idToMarketItem[i + 1].status == 6) { // check to make sure the item is no longer on sale // check to make sure the item is not in dispute 
                itemCount += 1;
            }
        }

        // Create an array of only the item ids that need to be processed at this time
        uint256[] memory itemsForProcessing = new uint256[](itemCount);

        for (uint i = 0; i < totalItemCount; i++) {
            //if (idToMarketItem[i + 1].onSale == false && (idToMarketItem[i + 1].status == 0 || idToMarketItem[i + 1].status == 3 || idToMarketItem[i + 1].status == 6)) {
            if (idToMarketItem[i + 1].status == 0 || idToMarketItem[i + 1].status == 3 || idToMarketItem[i + 1].status == 6) {
                NFTicketsTic temp = NFTicketsTic(idToMarketItem[i + 1].nftContract);
                if((temp.getFinishTime(idToMarketItem[i + 1].tokenId) + DAY) < block.timestamp) {
                    itemsForProcessing[currentIndex] = idToMarketItem[i + 1].itemId;
                    currentIndex += 1;
                }
            }
        }
    
        for (uint i = 0; i < itemCount; i++) {
            uint256 owedToSeller = idToMarketItem[itemsForProcessing[i]].totalSales + depositRefundAmount(idToMarketItem[itemsForProcessing[i]].seller, itemsForProcessing[i]); // Add up all sales for this item with the deposit amount to be refunded
            idToMarketItem[itemsForProcessing[i]].finalCommision = getDeposit(idToMarketItem[itemsForProcessing[i]].seller, itemsForProcessing[i]) / successFee; // record commision for this time
            marketComission = marketComission + (getDeposit(idToMarketItem[itemsForProcessing[i]].seller, itemsForProcessing[i]) / successFee); // adds up the 5% market commision fees that can be transfered out in the round
            idToMarketItem[itemsForProcessing[i]].totalSales = 0; // Clear out total sales figure
            sellerToDepositPerItem[idToMarketItem[itemsForProcessing[i]].seller][itemsForProcessing[i]] = 0; // Clear out deposits figure
            idToMarketItem[itemsForProcessing[i]].seller.transfer(owedToSeller); // Transfer ballance owed to the seller (5% commision has be subtracted)           
            idToMarketItem[itemsForProcessing[i]].status = 1; // Set the market item status to processed so it won't be looked at again - this line is causing the issue but it seems to only mark the paid ones as processed ???
        }
        (bool sent, bytes memory data) = owner.call{value: marketComission}(""); // Send the 5% comission to the owner (arbitration contract) for distribution
        require(sent, "Failed to send Ether");
    } 

    // Adds the buyers wallet address to array of buyers of that Market Item
    function addBuyerToItem (uint256 marketItem, address buyer) internal {
        bool already = false;
        if (marketItemIdToBuyers[marketItem].length == 0) {
            marketItemIdToBuyers[marketItem].push(buyer);
             already = true;
        } else {
            uint256 totalBuyers = marketItemIdToBuyers[marketItem].length;
            for (uint i = 0; i < totalBuyers; i++){ 
                if (marketItemIdToBuyers[marketItem][i] == buyer) {
                    already = true;                
                } 
            }
        }
        if (already == false) {
            marketItemIdToBuyers[marketItem].push(buyer);
        }
    }

    // Seller refunds all buyers for a market item - all spending records reset to 0
    function sellerRefundAll (uint256 marketItem) public nonReentrant {
        if(msg.sender != idToMarketItem[marketItem].seller) { revert SellerOnlyFunction();}
        if(idToMarketItem[marketItem].initialQuantity == idToMarketItem[marketItem].amount) { revert NoSales();}
        uint256 totalBuyers = marketItemIdToBuyers[marketItem].length;
        for (uint i = 0; i < totalBuyers; i++){
            payable(marketItemIdToBuyers[marketItem][i]).transfer(addressToSpending[marketItemIdToBuyers[marketItem][i]][marketItem]);
            addressToSpending[marketItemIdToBuyers[marketItem][i]][marketItem] = 0;
        }
        idToMarketItem[marketItem].name = string.concat("Refunded: ", idToMarketItem[marketItem].name);
        idToMarketItem[marketItem].status = 6;
    }

    function sellerRefundOne (uint256 marketItem, address buyer) public nonReentrant {
        if(msg.sender != idToMarketItem[marketItem].seller) { revert SellerOnlyFunction();}
        utils.sellerRefundOneUtils(marketItem, buyer);
        addressToSpending[buyer][marketItem] = 0;  
    }

    // DAO Timelock / Keeper slashed seller's deposit, half goes to DAO, half gets distributed to buyers in proportion, all payments refunded
    // ******* Need to make this something only the DAO Timelock/Keeper can implement after a vote
    // ******* Need to update this to only take 5% for the dao each time *******
    function refundWithPenalty (uint256 marketItem) public onlyOwner nonReentrant {
        if(idToMarketItem[marketItem].status != 4) { revert NotDisputed();}
        if(marketItemIdToBuyers[marketItem].length <= 0) { revert NoBuyers();}
        if(idToMarketItem[marketItem].finalCommision > 0) { revert AlreadyRefunded();}

        uint256 depositShare = (getDeposit(idToMarketItem[marketItem].seller, marketItem) / 4 * 3) / marketItemIdToBuyers[marketItem].length; // works out share of total deposit - in this event the seller forfits their entire deposit amount - quarter to DAO and the rest to buyers
        uint256 marketComission = getDeposit(idToMarketItem[marketItem].seller, marketItem) / 4; //Works out 5% of the deposit as market comission
        idToMarketItem[marketItem].finalCommision = marketComission;

        uint256 totalBuyers = marketItemIdToBuyers[marketItem].length;
        for (uint i = 0; i < totalBuyers; i++){
            payable(marketItemIdToBuyers[marketItem][i]).transfer(addressToSpending[marketItemIdToBuyers[marketItem][i]][marketItem] + depositShare);
            addressToSpending[marketItemIdToBuyers[marketItem][i]][marketItem] = 0;
        }
        (bool sent, bytes memory data) = owner.call{value: marketComission}(""); // Send comission to the owner (arbitration contract)
        require(sent, "Failed to send Ether");
        sellerToDepositPerItem[idToMarketItem[marketItem].seller][marketItem] = 0;
        idToMarketItem[marketItem].name = string.concat("Refunded: ", idToMarketItem[marketItem].name);
    }

    // Basic Access control
    modifier onlyOwner {
        if(msg.sender != owner) {revert NotOwner();}
        _;
    }

    function getTokenByMarketId (uint256 _itemId) public view returns (uint256) {
        return idToMarketItem[_itemId].tokenId;
    }

    function getTotalSalesByMarketId (uint256 _itemId) public view returns (uint256) {
        return (idToMarketItem[_itemId].initialQuantity - idToMarketItem[_itemId].amount);
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155URIStorage.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";



contract NFTicketsTic is ERC1155URIStorage, ReentrancyGuard {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    address immutable marketAddress; // replaced previous testing address - now injected via constructor

    constructor(address _marketAddress) ERC1155("") {
        marketAddress = _marketAddress;
    }

    mapping (uint256 => string) private _uris;
    mapping (uint256 => address) private _tokenCreator;
    mapping (uint256 => uint256) public _price;
    mapping (uint256 => int64[2]) private coordinates;
    mapping (uint256 => uint256) private eventFinishTime;

    //need to create a mapping for price that will be used in the market contract as well and price cannot be set twice - to prevent scalping

    // Returns the uri address of content on IPFS for the given tokenId
    function uri(uint256 tokenId) override public view returns (string memory) {
        return(_uris[tokenId]);
    }

    // Returns the maximum per unit price of the tokenId (i.e. per ticket)
    function price(uint256 tokenId) public view returns (uint256) {
      return(_price[tokenId]);
    }

    // Creates general admitance tokens - all have same value and no seat specific data
    function createToken(string memory tokenURI, uint256 amount, bytes memory data, uint256 price, uint256 finishTime, int64 lat, int64 lon) public returns (uint) {
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();
        require(bytes(_uris[newItemId]).length == 0, "Cannot set URI twice");
        require((_price[newItemId]) == 0, "Cannot set price twice");
        require(price > 0, "price cannot be 0");
        _tokenCreator[newItemId] = msg.sender;
        _mint(msg.sender, newItemId, amount, data);
        _uris[newItemId] = tokenURI;
        _price[newItemId] = price;
        eventFinishTime[newItemId] = finishTime;
        coordinates[newItemId] = [lat, lon];
        setApprovalForAll(marketAddress, true);
        return newItemId;
    }

    // Creates more general admitance tokens - all have samve value and no seat specific data
    function createMoreTokens(uint256 tokenId, uint256 amount, bytes memory data) public {
        require(_tokenCreator[tokenId] == msg.sender, "You are not the token creator");
        _mint(msg.sender, tokenId, amount, data);
    }

    // *********** This send function hasn't been used in the marketplace yet - tagged for possible deletion *************
    function sendFree (address to, uint256 tokenId, uint256 amount, bytes memory data) public {
        _safeTransferFrom(msg.sender, to, tokenId, amount, data);
        setApprovalForAll(to, true);
    }

    // ********* Need to rename function *********
    function useUnderscoreTransfer (address from, address to, uint256 tokenId, uint256 amount, bytes memory data) public {
        _safeTransferFrom(from, to, tokenId, amount, data);
    }

    // Lists all token IDs that were created by the message sender
    function listMyTokens(address testMe) public view returns (uint256[] memory) {
        uint totalItemCount = _tokenIds.current();
        uint itemCount = 0;
        uint currentIndex = 0;

        for (uint i = 0; i < totalItemCount; i++) {
            if (_tokenCreator[i+1] == testMe) {
                itemCount += 1;
            }
        }

        uint256[] memory tokens = new uint256[](itemCount);
            for (uint i = 0; i < totalItemCount; i++) {
            if (_tokenCreator[i+1] == testMe) {
                tokens[currentIndex] = i+1;
                currentIndex += 1;
            }
        }
        return tokens;
    }

    function getFinishTime (uint256 tokenId) public view returns (uint256) {
        return eventFinishTime[tokenId];
    }
    function getCoordinates (uint256 tokenId) public view returns (int64[2] memory) {
        return coordinates[tokenId];
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./NFTicketsTic.sol";
import "./NFTicketsMarket.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


error NothingToRefundHere();

contract NFTicketsUtils is ReentrancyGuard, Ownable { 

    AggregatorV3Interface internal priceFeed;
    NFTicketsMarket public market;

    constructor() {
        priceFeed = AggregatorV3Interface(0x5498BB86BC934c8D34FDA08E81D444153d0D06aD); //Address of Oracle pricefeed - used to convert USD prices listed for each item into the native chain token price i.e. in AVAX
    }
   
    function setUp (address _market) public onlyOwner {
        market = NFTicketsMarket(_market);
    }

   // Converts the given price in USD into the actual price in native chain token (i.e. AVAX), taking into account he decimal places
    function getConversion (uint256 _price) public view returns (uint256 conversion) {
        uint256 dataFeed = uint256(getLatestPrice()); //this will be the token to USD exchange rate from the pricefeed
        uint256 multiplier = 100000; //this will get it to the right number of decimal places assuming that the price passed by the app could have cents - and has been multiplied by 100 to remove decimal places.
        return conversion = _price * dataFeed * multiplier;
    }

    function getLatestPrice() public view returns (int) {
        (
            /*uint80 roundID*/,
            int price,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = priceFeed.latestRoundData();
        return price;
    }

   function getPrice(address nftContract, uint256 tokenId) public view returns (uint256) {
        NFTicketsTic temp = NFTicketsTic(nftContract);
        uint256 tempPrice = temp.price(tokenId); 
        return tempPrice;
    }   

    function sellerRefundOneUtils (uint256 marketItem, address buyer) public nonReentrant { //This used to be nonRentrant
        if(market.addressToSpending(buyer, marketItem) <= 0) { revert NothingToRefundHere();}
        payable(buyer).transfer(market.addressToSpending(buyer, marketItem));
    }

    function getCurrentTime () public view returns (uint) {
        return block.timestamp;
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/utils/ERC1155Holder.sol)

pragma solidity ^0.8.0;

import "./ERC1155Receiver.sol";

/**
 * Simple implementation of `ERC1155Receiver` that will allow a contract to hold ERC1155 tokens.
 *
 * IMPORTANT: When inheriting this contract, you must include a way to use the received tokens, otherwise they will be
 * stuck.
 *
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC1155/extensions/ERC1155URIStorage.sol)

pragma solidity ^0.8.0;

import "../../../utils/Strings.sol";
import "../ERC1155.sol";

/**
 * @dev ERC1155 token with storage based token URI management.
 * Inspired by the ERC721URIStorage extension
 *
 * _Available since v4.6._
 */
abstract contract ERC1155URIStorage is ERC1155 {
    using Strings for uint256;

    // Optional base URI
    string private _baseURI = "";

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the concatenation of the `_baseURI`
     * and the token-specific uri if the latter is set
     *
     * This enables the following behaviors:
     *
     * - if `_tokenURIs[tokenId]` is set, then the result is the concatenation
     *   of `_baseURI` and `_tokenURIs[tokenId]` (keep in mind that `_baseURI`
     *   is empty per default);
     *
     * - if `_tokenURIs[tokenId]` is NOT set then we fallback to `super.uri()`
     *   which in most cases will contain `ERC1155._uri`;
     *
     * - if `_tokenURIs[tokenId]` is NOT set, and if the parents do not have a
     *   uri value set, then the result is empty.
     */
    function uri(uint256 tokenId) public view virtual override returns (string memory) {
        string memory tokenURI = _tokenURIs[tokenId];

        // If token URI is set, concatenate base URI and tokenURI (via abi.encodePacked).
        return bytes(tokenURI).length > 0 ? string(abi.encodePacked(_baseURI, tokenURI)) : super.uri(tokenId);
    }

    /**
     * @dev Sets `tokenURI` as the tokenURI of `tokenId`.
     */
    function _setURI(uint256 tokenId, string memory tokenURI) internal virtual {
        _tokenURIs[tokenId] = tokenURI;
        emit URI(uri(tokenId), tokenId);
    }

    /**
     * @dev Sets `baseURI` as the `_baseURI` for all tokens
     */
    function _setBaseURI(string memory baseURI) internal virtual {
        _baseURI = baseURI;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/ERC1155.sol)

pragma solidity ^0.8.0;

import "./IERC1155.sol";
import "./IERC1155Receiver.sol";
import "./extensions/IERC1155MetadataURI.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155 is Context, ERC165, IERC1155, IERC1155MetadataURI {
    using Address for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /**
     * @dev See {_setURI}.
     */
    constructor(string memory uri_) {
        _setURI(uri_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256) public view virtual override returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: address zero is not a valid owner");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not token owner nor approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not token owner nor approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        _balances[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `from`
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `id`.
     */
    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }

        emit TransferSingle(operator, from, address(0), id, amount);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
        }

        emit TransferBatch(operator, from, address(0), ids, amounts);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC1155: setting approval status for self");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `ids` and `amounts` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    /**
     * @dev Hook that is called after any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155Receiver.onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;

import "../IERC1155.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../IERC1155Receiver.sol";
import "../../../utils/introspection/ERC165.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }
}