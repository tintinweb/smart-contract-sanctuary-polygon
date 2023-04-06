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

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/Counters.sol";
import "./SalesTransaction.sol";

contract OnlineShop {
    using Counters for Counters.Counter;
    Counters.Counter private _productId;
    Counters.Counter private _itemsSold;

    //Trasaction ID
    Counters.Counter private _transactionId;

    //Transaction Mapping
    mapping(uint256 => SalesTransaction) private idToSalesTransactionMap;

    address payable owner;
    mapping(uint256 => ProductItem) private idToProductItemMap;
    mapping(address => User) private addressToUserDtl;

    //Key Handling
    mapping(address => string[]) private userToPublicKeyArry; //Track Number of Public key each user have
    mapping(address => mapping(string => KeyPairDtl)) private userToKeyPairList; //Address map of ("PK","privateKeyDtl")

    struct User {
        address userOwnerAddr;
        string name;
        string contact;
    }

    struct ProductItem {
        uint256 productId;
        address payable seller;
        address payable owner;
        string sellerPublicKey;
        string title;
        string desp;
        uint256 price;
        string productImage; 
        bool isActive;
        bool isSold;
    }

    struct KeyPairDtl {
        string publicKey;
        string encPrivateKey;
        uint lastUpdDate;
        bool isActive;
    }

    struct inputKeyPair {
        string publicKey;
        string encPrivateKey;
    }

    function createProductItem (
        string memory sellerPublicKey,
        string memory sellerEncPrivateKey,
        string memory title,
        string memory desp,
        uint256 price,
        string memory productImage
    ) public {
        require(price > 0, "Price must be at least 1 wei");

        _productId.increment();
        uint256 productId = _productId.current();

        //Construct Key Mapping Entry
        addUpdateUserKeyPair(msg.sender, sellerPublicKey, sellerEncPrivateKey);

        //Add Item
        idToProductItemMap [productId] = ProductItem (
            productId,
            payable(msg.sender), //seller
            payable(msg.sender), //owner
            sellerPublicKey,
            title,
            desp,
            price,
            productImage,
            true,
            false
        ); 

    }

    function addUpdateUserKeyPair (
        address userAddr,
        string memory sellerPublicKey,
        string memory sellerEncPrivateKey
    ) internal {

        //Update user public key entry
        addUpdateUserPublicKeyList(userAddr, sellerPublicKey);

        //New Object 
        uint256 currentTime = block.timestamp;
        KeyPairDtl memory newPkDtl = KeyPairDtl(sellerPublicKey, sellerEncPrivateKey, currentTime, true);
        //Update value or insert if not exist
        userToKeyPairList[userAddr][sellerPublicKey] = newPkDtl;
    }

    function createUpdateUser (
        string memory name,
        string memory contact
    )
    public {
        require(bytes(name).length > 0, "Name cannot empty ");
        require(bytes(contact).length > 0, "Contact cannot empty ");

        addressToUserDtl[msg.sender] = User (
            msg.sender,
            name,
            contact
        );
    }

    function updateAllUserKeyPair(inputKeyPair[] memory _data) public {
        for(uint i = 0; i<_data.length; i++){
            addUpdateUserKeyPair(msg.sender, _data[i].publicKey, _data[i].encPrivateKey);
        }
    }

    function addUpdateUserPublicKeyList(address userAddr, string memory inputStr) internal {

        string[] memory userPublicKeyArray = userToPublicKeyArry[userAddr];
        bool isFound = false;
        uint foundIdx;
        for (uint i=0; i<userPublicKeyArray.length; i++) {
            string memory publicKey = userPublicKeyArray[i];
            if (keccak256(bytes(publicKey)) == keccak256(bytes(inputStr))) {
                isFound = true;
                foundIdx = i;
                break;
            }
        }

        //Add new value if not found 
        if (isFound) {
            //userToPublicKeyArry[userAddr][foundIdx] = inputStr;
        }else {
            userToPublicKeyArry[userAddr].push(inputStr);
        }
    } 

    //Get Encrypted Keypair Details
    function getKeyPairsByAddress (address userAddr) public view returns(KeyPairDtl[] memory) {
        string[] memory publicKeyArray = userToPublicKeyArry[userAddr];
        uint currentItemIndex = 0;
        KeyPairDtl[] memory keyPairItems = new KeyPairDtl[](publicKeyArray.length);
        for (uint i=0; i<publicKeyArray.length; i++) {
            string memory publicKey = publicKeyArray[i];
            keyPairItems[currentItemIndex] = (userToKeyPairList[userAddr][publicKey]);
            currentItemIndex += 1;
        }
        return keyPairItems;
    }

    //Get a single key if also provide public key
    // function getKeyPairByAddWithPublicKey (address userAddr, string memory publicKey) public view returns(KeyPairDtl memory) {
    //     return userToKeyPairList[userAddr][publicKey];
    // }

    //Get Product Item By ID
    function getProductItemById (uint256 productId) public view returns(ProductItem memory)  {
        require(idToProductItemMap[productId].price > 0, "Product not exist !");
        return idToProductItemMap[productId];
    }

    //Get User By Address
    function getUserByAddress (address userAddr) public view returns(User memory) {
        require(bytes(addressToUserDtl[userAddr].name).length > 0, "User not exist !");
        return addressToUserDtl[userAddr];
    }

    //Get Product List
    function fetchProductItems() public view returns (ProductItem[] memory) {
      uint itemCount = _productId.current();
      uint currentIndex = 0;
      uint activeItem = 0;

      //Count Active item
      for (uint i = 0; i < itemCount; i++) {
          if (idToProductItemMap[i + 1].isActive == true) {
              activeItem +=1;
          }
      }

      //Add item
      ProductItem[] memory productItems = new ProductItem[](activeItem);
      for (uint i = 0; i < itemCount; i++) {
          if (idToProductItemMap[i + 1].isActive == true) {
              productItems[currentIndex] = idToProductItemMap[i + 1];
              currentIndex +=1;
          }
      }

      //Return
      return productItems;
    }

    //Create Sales Transaction
    function createSalesTransaction (
        uint256 productId, //Input Item Id
        uint256 qty,
        string memory shipAddr,
        string memory tel,
        string memory buyerPublicKey,
        string memory encBuyerPrivateKey,
        string memory verifyStr
        ) public payable{ 
        //Get Sales Item Details By ID
        ProductItem memory productItem = idToProductItemMap[productId];
        require(productItem.price > 0, "Product not exist !");
        require(productItem.isActive == true, "Product not active");
        uint256 price = productItem.price;
        uint256 paidAmt = price * qty;
        require(msg.value == paidAmt, "Please submit the asking price to complete the transaction");
        //Construct Key Mapping Entry
        addUpdateUserKeyPair(msg.sender, buyerPublicKey, encBuyerPrivateKey);

        //Internal Function to add transaction
        _addSalesTransaction(productId, buyerPublicKey, paidAmt, qty, shipAddr, tel, productItem, verifyStr);

        //Update to Product to Sold
        idToProductItemMap[productId].isSold = true;
    }

    function _addSalesTransaction(uint256 productId, string memory buyerPublicKey,
     uint256 paidAmt, uint256 qty, string memory shipAddr,
      string memory tel, ProductItem memory productItem,
      string memory verifyStr) internal {
        
        //Create Transaction Object
        _transactionId.increment();
        uint256 transactionId = _transactionId.current();

        SalesTransaction salesTransaction = new SalesTransaction{ value:msg.value }(
            address(this),
            productId,
            msg.sender,
            buyerPublicKey, //Optional, if need to communicate with seller
            paidAmt,
            qty,
            shipAddr,
            tel,
            productItem.seller,
            verifyStr
        );
        idToSalesTransactionMap[transactionId] = salesTransaction;
    }

    //Get Transaction By Buyer
    function getTransactionByBuyer (address userAddr) public view returns(SalesTransaction.SalesTransactionView[] memory)  {
        uint transactionCount = _transactionId.current();
        uint currentIndex = 0;
        uint numOfItem = 0;
        for (uint i = 0; i < transactionCount; i++) {
          if (idToSalesTransactionMap[i + 1].buyer() == userAddr) {
              numOfItem +=1;
          }
        }
        SalesTransaction.SalesTransactionView[] memory salesTransactionList = new SalesTransaction.SalesTransactionView[](numOfItem);
        for (uint i = 0; i < transactionCount; i++) {
          if (idToSalesTransactionMap[i + 1].buyer() == userAddr) {
              salesTransactionList[currentIndex] = idToSalesTransactionMap[i + 1].toViewObject();
              salesTransactionList[currentIndex].transactionId = i + 1;

              //Set Product Details
              ProductItem memory product = idToProductItemMap[salesTransactionList[currentIndex].salesProductId];
              salesTransactionList[currentIndex].title = product.title;
              salesTransactionList[currentIndex].desp = product.desp;
              salesTransactionList[currentIndex].productImage = product.productImage;
              salesTransactionList[currentIndex].sellerPublicKey = product.sellerPublicKey;

              currentIndex +=1;
          }
        }
        return salesTransactionList;
    }

    //Get Transaction By Seller
    function getTransactionBySeller (address userAddr) public view returns(SalesTransaction.SalesTransactionView[] memory)  {
        uint transactionCount = _transactionId.current();
        uint currentIndex = 0;
        uint numOfItem = 0;
        for (uint i = 0; i < transactionCount; i++) {
            SalesTransaction salesTransaction = idToSalesTransactionMap[i + 1];
            //If it is seller
            if (idToProductItemMap[salesTransaction.salesProductId()].seller == userAddr) {
              numOfItem +=1;
            }
        }
        SalesTransaction.SalesTransactionView[] memory salesTransactionList = new SalesTransaction.SalesTransactionView[](numOfItem);
        for (uint i = 0; i < transactionCount; i++) {
            SalesTransaction salesTransaction = idToSalesTransactionMap[i + 1];
            //If it is seller
            if (idToProductItemMap[salesTransaction.salesProductId()].seller == userAddr) {
                salesTransactionList[currentIndex] = idToSalesTransactionMap[i + 1].toViewObject();
                salesTransactionList[currentIndex].transactionId = i + 1;

                //Set Product Details
                ProductItem memory product = idToProductItemMap[salesTransactionList[currentIndex].salesProductId];
                salesTransactionList[currentIndex].title = product.title;
                salesTransactionList[currentIndex].desp = product.desp;
                salesTransactionList[currentIndex].productImage = product.productImage;
                salesTransactionList[currentIndex].sellerPublicKey = product.sellerPublicKey;

                currentIndex +=1;
            }
        }
        return salesTransactionList;
    }

    //Seller Deliver the product and update status
    function shipTransactionProduct(uint256 transactionId, string memory shipDtl) public {
        idToSalesTransactionMap[transactionId].shipTransactionProduct(msg.sender, shipDtl);
    }

    //Buyer Confirm Shipment Receive
    function buyerCfmReceiveProduct(uint256 transactionId) public {
        idToSalesTransactionMap[transactionId].buyerCfmReceiveProduct(msg.sender);
    }

    //Seller Complete Transction
    function sellerCompleteTransaction(uint256 transactionId) public {
        idToSalesTransactionMap[transactionId].sellerCompleteTransaction(msg.sender);
    }

    //Buyer can collect transaction payment back if seller does not deliver the product in time
    function buyerRetriveNotDeliverTransaction(uint256 transactionId) public {
        idToSalesTransactionMap[transactionId].buyerRetriveNotDeliverTransaction(msg.sender);
    }

    //Buyer Msg Action
    function addBuyerMsg(uint256 transactionId, string memory inputMsg) public{
        idToSalesTransactionMap[transactionId].addBuyerMsg(msg.sender, inputMsg);
    }

    function getAllSellerMsg(uint256 transactionId) public view returns(SalesTransaction.Message[] memory) {
        return idToSalesTransactionMap[transactionId].getAllSellerMsg(msg.sender);
    }

    //Seller Msg Action
    function getBuyerEncKey(uint256 transactionId) public view returns(string memory) {
        return idToSalesTransactionMap[transactionId].getBuyerEncKey(msg.sender);
    }

    function addSellerMsg(uint256 transactionId, string memory inputMsg) public {
        idToSalesTransactionMap[transactionId].addSellerMsg(msg.sender, inputMsg);
    }

    function getAllBuyerMsg(uint256 transactionId) public view returns(SalesTransaction.Message[] memory) {
        return idToSalesTransactionMap[transactionId].getAllBuyerMsg(msg.sender);
    }

    //Seller deactivate product
    // function sellerInactiveProduct(uint256 productId) public {
    //     ProductItem memory productItem = idToProductItemMap[productId];
    //     require(productItem.owner == msg.sender,"You must be the product owner");
    //     productItem.isActive = false;
    //     idToProductItemMap[productId] = productItem;
    // }

}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.9;

contract SalesTransaction {

    address private onlineShopAddr;
    //Shipping Status
    enum TransactionStatus {PENDING, SHIPPED, DELIVERED, COMPLETE, CANCELLED}
    TransactionStatus private STATUS_PENDING = TransactionStatus.PENDING;
    TransactionStatus private STATUS_SHIPPED = TransactionStatus.SHIPPED;
    TransactionStatus private STATUS_DELIVERED =TransactionStatus.DELIVERED;
    TransactionStatus private STATUS_COMPLETE = TransactionStatus.COMPLETE;
    TransactionStatus private STATUS_CANCELLED = TransactionStatus.CANCELLED;

    uint256 public salesProductId;
    address public buyer;
    address public seller;
    string public buyerPublicKey;
    uint public status;
    uint public salesAmt;
    uint256 public qty;
    
    //Verify String
    string public verifyStr;

    //Buyer Contact
    string public shipAddr;
    string public tel;

    //Shipping Details
    string public trackingDtl;

    //Create time
    uint256 public createTime;

    //Item delivery time
    uint256 public deliverTime;

    //Buyer Message
    Message[] private buyerMsgList;
    //Seller Message
    Message[] private sellerMsgList;

    struct SalesTransactionView {
        uint256 salesProductId;
        address buyer;
        uint status;
        uint salesAmt;
        uint256 qty;
        string shipAddr;
        string tel;

        //View Content
        uint256 transactionId;
        string title;
        string desp;
        string productImage;
        string buyerPublicKey;
        string sellerPublicKey;
        string trackingDtl;
    }

    struct Message {
        bool isBuyer;
        address sender;
        string msgContent;
        uint256 msgCreTime;
    }

    constructor (
        address _shopAddr,
        uint256 _productId, //Input Item Id
        address _buyer,
        string memory _buyerPublicKey,
        uint256 _paidAmt,
        uint256 _qty,
        string memory _shipAddr,
        string memory _tel,
        address _seller,
        string memory _verifyStr
    ) payable {
        onlineShopAddr = _shopAddr;
        salesProductId = _productId;
        buyer = _buyer;
        buyerPublicKey = _buyerPublicKey;
        status = uint(STATUS_PENDING);
        salesAmt = _paidAmt;
        qty = _qty;
        shipAddr = _shipAddr;
        tel = _tel;
        createTime = block.timestamp;
        seller = _seller;
        verifyStr = _verifyStr;
    }

    function toViewObject() external view returns(SalesTransactionView memory) {
        SalesTransactionView memory viewObj = SalesTransactionView (
            salesProductId,
            buyer,
            status,
            salesAmt,
            qty,
            shipAddr,
            tel,
            0,
            "",
            "",
            "",
            buyerPublicKey,
            "",
            trackingDtl
        );
        return viewObj;
    }

    //Seller Deliver the product and update status
    function shipTransactionProduct(address userAddr, string memory inputShipDtl) external {

        require(salesAmt > 0, "Transaction not exist !");
        require(status !=  uint(STATUS_COMPLETE) , "Status Not Correct");
        require(status !=  uint(STATUS_CANCELLED) , "Status Not Correct");
        require(userAddr == seller , "Only Seller Can Perform The Action ");

        // Supply shipping details and update status
        trackingDtl = inputShipDtl;
        deliverTime = block.timestamp;
        status = uint(STATUS_SHIPPED);
    }

    //Buyer Acknowledge Shipment Receive
    function buyerCfmReceiveProduct(address userAddr) external {
        require(status == uint(STATUS_SHIPPED) , "Transaction must be Shipped");
        require(userAddr == buyer , "Only Buyer Can Perform The Action ");
        // Update Transaction Status
        status = uint(STATUS_DELIVERED);
    }

    //Complete transaction and seller retrieve
    function sellerCompleteTransaction (address userAddr) external {

        if (status == uint(STATUS_SHIPPED)) {
            uint256 curTime = block.timestamp;
            uint256 expireTime = deliverTime + (60 * 60 * 24 * 10); //Add Ten Days
            require(curTime >= expireTime , "Not yet expired");
            status = uint(STATUS_COMPLETE);
            payable(seller).transfer(salesAmt);
        } else {
            require(status ==  uint(STATUS_DELIVERED) , "Status Not Correct");
            require(userAddr == seller , "Only Seller Can Perform The Action ");
            status = uint(STATUS_COMPLETE);
            payable(seller).transfer(salesAmt);
        }

    }

    //Buyer can collect transaction payment if seller does not deliver the product
    function buyerRetriveNotDeliverTransaction(address userAddr) external {
        require(status ==  uint(STATUS_PENDING) , "Status Not Correct");
        require(userAddr == buyer , "Only Buyer Can Perform The Action ");
        uint256 curTime = block.timestamp;
        //uint256 expireTime = createTime + (60 * 60 * 24 * 7); //Add Seven Days
        uint256 expireTime = createTime + (60 * 2);
        require(curTime >= expireTime , "Transaction Not Expired");
        status = uint(STATUS_COMPLETE);
        payable(buyer).transfer(salesAmt);
    }

    //Buyer Msg Action
    function addBuyerMsg(address userAddr, string memory inputMsg) external{
        require(userAddr == buyer , "Only Buyer Can Perform The Action ");
        //Message Should encrypt off chain before insert

        Message memory message = Message(
            true,
            userAddr,
            inputMsg,
            block.timestamp
        );

        buyerMsgList.push(message);
        sellerMsgList.push(message);
    }

    function getAllSellerMsg(address userAddr) external view returns(Message[] memory) {
        //require(userAddr == buyer , "Only Buyer Can Perform The Action ");
        //Encrypted, should decrpt off chain
        return sellerMsgList;
    }

    //Seller Msg Action
    function getBuyerEncKey(address userAddr) external view returns(string memory) {
        //require(userAddr == seller , "Only Seller Can Perform The Action ");
        return buyerPublicKey;
    }

    function addSellerMsg(address userAddr, string memory inputMsg) external{
        //OnlineShop onlineShop = OnlineShop(onlineShopAddr);
        //OnlineShop.ProductItem memory productItem = onlineShop.getProductItemById(salesProductId);
        //address seller = productItem.seller;
        require(userAddr == seller , "Only Seller Can Perform The Action ");
        //Message Should encrypt off chain before insert

        Message memory message = Message(
            false,
            userAddr,
            inputMsg,
            block.timestamp
        );

        buyerMsgList.push(message);
        sellerMsgList.push(message);
    }

    function getAllBuyerMsg(address userAddr) external view returns(Message[] memory) {
        //require(userAddr == seller , "Only Seller Can Perform The Action ");
        //Encrypted, should decrpt off chain
        return buyerMsgList;
    }
    
}