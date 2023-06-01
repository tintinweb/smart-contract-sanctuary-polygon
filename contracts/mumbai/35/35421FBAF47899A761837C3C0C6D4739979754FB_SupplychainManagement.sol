// SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;


contract SupplychainManagement {
    uint256[] public userIdList;
    mapping(uint256 => bool) public userIsPresent;
    uint256 public userCount;
    uint256 public cropCount;
    uint256 public livestockCount;
    uint256 public storeCount;
    uint256 public transportCount;
    uint256 public buyerOrderCount;
    uint256 public storeOrderCount;
    uint256 public transportOrderCount;

    struct UserDetails {
        string name;
        string contact;
        uint256 userId;
        string userType;
        string location;
        string email;
        string password;
        uint256 balance;
        address ethereumAddress;
        // Add more fields as needed
    }

    struct Crop {
        uint256 id;
        string name;
        uint256 ownerId;
        uint256 quantity;
        uint256 price;
        uint256 amountSold;
        // Add more fields as needed
    }

    struct Livestock {
        uint256 id;
        string name;
        uint256 ownerId;
        uint256 quantity;
        uint256 price;
        uint256 amountSold;
        // Add more fields as needed
    }

    struct Store {
        uint256 id;
        uint256 ownerId;
        uint256 capacity;
        uint256 price;
        uint256 remainingCapacity;
        // Add more fields as needed
    }

    struct Transport {
        uint256 id;
        uint256 ownerId;
        uint256 capacity;
        uint256 price;
        // Add more fields as needed
    }

    struct BuyerOrder {
        uint256 orderId;
        uint256 cropId;
        uint256 livestockId;
        uint256 buyerId;
        uint256 transportId;
        uint256 transportOrderId;
        uint256 storeId;
        uint256 quantity;
        bool isOrderTaken;
        // Add more fields as needed
    }

    struct StoreOrder {
        uint256 orderId;
        uint256 cropId;
        uint256 livestockId;
        uint256 buyerId;
        uint256 transportId;
        uint256 transportOrderId;
        uint256 storeId;
        uint256 quantity;
        bool isOrderTaken;
        // Add more fields as needed
    }

    struct TransportOrder {
        uint256 orderId;
        string orderType;
        uint256 cropId;
        uint256 livestockId;
        uint256 storeId;
        bool isOrderTaken;
        uint256 transportId;
        uint256 senderId;
        uint256 receiverId;
        uint256 quantity;
        // Add more fields as needed
    }

    mapping(string => uint256) public emailToId;
    mapping(uint256 => UserDetails) public userInfo;
    mapping(uint256 => Crop) public cropInfo;
    mapping(uint256 => Livestock) public livestockInfo;
    mapping(uint256 => Store) public storeInfo;
    mapping(uint256 => Transport) public transportInfo;
    mapping(uint256 => BuyerOrder) public buyerOrderInfo;
    mapping(uint256 => StoreOrder) public storeOrderInfo;
    mapping(uint256 => TransportOrder) public transportOrderInfo;

    function getUserId(string memory email) public view returns (uint256) {
        return emailToId[email];
    }

    function getUserName(uint256 userId) public view returns (string memory) {
        return userInfo[userId].name;
    }

    function registerMe(
        string memory name,
        string memory contact,
        string memory userType,
        string memory location,
        string memory email,
        string memory password,
        uint256 balance,
        address ethereumAddress
    ) public {
        uint256 newUserId = userIdList.length;
        userIdList.push(newUserId);
        userIsPresent[newUserId] = true;
        emailToId[email] = newUserId;

        UserDetails storage user = userInfo[newUserId];
        user.name = name;
        user.contact = contact;
        user.userId = newUserId;
        user.userType = userType;
        user.location = location;
        user.email = email;
        user.password = password;
        user.balance = balance;
        user.ethereumAddress = ethereumAddress;

        userCount++;
    }

    function addCrop(
        uint256 id,
        string memory name,
        uint256 ownerId,
        uint256 quantity,
        uint256 price
    ) public {
        Crop storage newCrop = cropInfo[id];
        newCrop.id = id;
        newCrop.name = name;
        newCrop.ownerId = ownerId;
        newCrop.quantity = quantity;
        newCrop.price = price;

        cropCount++;
    }

    function addLivestock(
        uint256 id,
        string memory name,
        uint256 ownerId,
        uint256 quantity,
        uint256 price
    ) public {
        Livestock storage newLivestock = livestockInfo[id];
        newLivestock.id = id;
        newLivestock.name = name;
        newLivestock.ownerId = ownerId;
        newLivestock.quantity = quantity;
        newLivestock.price = price;

        livestockCount++;
    }

    function addStore(
        uint256 id,
        uint256 ownerId,
        uint256 capacity,
        uint256 price,
        uint256 remainingCapacity
    ) public {
        Store storage newStore = storeInfo[id];
        newStore.id = id;
        newStore.ownerId = ownerId;
        newStore.capacity = capacity;
        newStore.price = price;
        newStore.remainingCapacity = remainingCapacity;

        storeCount++;
    }

    function addTransport(
        uint256 id,
        uint256 ownerId,
        uint256 capacity,
        uint256 price
    ) public {
        Transport storage newTransport = transportInfo[id];
        newTransport.id = id;
        newTransport.ownerId = ownerId;
        newTransport.capacity = capacity;
        newTransport.price = price;

        transportCount++;
    }

    function createBuyerOrder(
        uint256 cropId,
        uint256 livestockId,
        uint256 buyerId,
        uint256 transportId,
        uint256 transportOrderId,
        uint256 storeId,
        uint256 quantity
    ) public {
        uint256 newOrderId = buyerOrderCount;
        buyerOrderCount++;

        BuyerOrder storage newBuyerOrder = buyerOrderInfo[newOrderId];
        newBuyerOrder.orderId = newOrderId;
        newBuyerOrder.cropId = cropId;
        newBuyerOrder.livestockId = livestockId;
        newBuyerOrder.buyerId = buyerId;
        newBuyerOrder.transportId = transportId;
        newBuyerOrder.transportOrderId = transportOrderId;
        newBuyerOrder.storeId = storeId;
        newBuyerOrder.quantity = quantity;

        // Set additional fields and flags as needed
    }

    function createStoreOrder(
        uint256 cropId,
        uint256 livestockId,
        uint256 buyerId,
        uint256 transportId,
        uint256 transportOrderId,
        uint256 storeId,
        uint256 quantity
    ) public {
        uint256 newOrderId = storeOrderCount;
        storeOrderCount++;

        StoreOrder storage newStoreOrder = storeOrderInfo[newOrderId];
        newStoreOrder.orderId = newOrderId;
        newStoreOrder.cropId = cropId;
        newStoreOrder.livestockId = livestockId;
        newStoreOrder.buyerId = buyerId;
        newStoreOrder.transportId = transportId;
        newStoreOrder.transportOrderId = transportOrderId;
        newStoreOrder.storeId = storeId;
        newStoreOrder.quantity = quantity;

        // Set additional fields and flags as needed
    }

    function createTransportOrder(
        string memory orderType,
        uint256 cropId,
        uint256 livestockId,
        uint256 storeId,
        bool isOrderTaken,
        uint256 transportId,
        uint256 senderId,
        uint256 receiverId,
        uint256 quantity
    ) public {
        uint256 newOrderId = transportOrderCount;
        transportOrderCount++;

        TransportOrder storage newTransportOrder = transportOrderInfo[newOrderId];
        newTransportOrder.orderId = newOrderId;
        newTransportOrder.orderType = orderType;
        newTransportOrder.cropId = cropId;
        newTransportOrder.livestockId = livestockId;
        newTransportOrder.storeId = storeId;
        newTransportOrder.isOrderTaken = isOrderTaken;
        newTransportOrder.transportId = transportId;
        newTransportOrder.senderId = senderId;
        newTransportOrder.receiverId = receiverId;
        newTransportOrder.quantity = quantity;

        // Set additional fields and flags as needed
    }
}