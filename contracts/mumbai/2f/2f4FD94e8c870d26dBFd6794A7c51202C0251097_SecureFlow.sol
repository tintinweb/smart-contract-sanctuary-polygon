// SPDX-License-Identifier: ISC
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract SecureFlow {

    uint256 balance;

    enum ParticipantType { Manufacturer, Wholesaler, Retailer, Consumer }

    struct Product {
        uint256 id;
        string name;
        uint256 quantity;
        uint256 price;
        address manufacturer;
        address wholesaler;
        address retailer;
        address consumer;
    }

    uint256 public productCount; 
    mapping(address => mapping(uint256 => Product)) public products;


    event ProductAdded(uint256 indexed productId, string name, uint256 quantity, uint256 price);
    event ProductDelivered(uint256 indexed productId);

     struct Order {
        uint256 id;
        uint256 productId;
        address buyer;
        address seller;
        ParticipantType buyerType;
        uint256 quantity;
        uint256 amount;
        uint orderTime;
        bool isDelivered;
        uint deliveryTime;
    }

    uint256 public orderCount;
    mapping(address => mapping(uint256 => Order)) public orders;
    
    function addProduct(string memory name, uint256 quantity, uint256 price, ParticipantType partType) external {
        require(quantity > 0, "Quantity must be greater than 0");
        require(partType == ParticipantType.Manufacturer, "Only Manufacturer can add the product");

        Product storage newProduct = products[msg.sender][productCount];
        newProduct.id = productCount;
        newProduct.name = name;
        newProduct.quantity = quantity;
        newProduct.price = price * 1 ether;
        newProduct.manufacturer = msg.sender;
        products[msg.sender][productCount] = newProduct;
        productCount++;

        emit ProductAdded(productCount, name, quantity, price);
    }

    function placeOrder(
        uint256 productId,
        address seller,
        ParticipantType buyerType,
        uint256 quantity
    ) external payable {
        require(productId >= 0 && productId <= productCount, "Invalid product ID");
        require(seller != address(0), "Invalid seller address");
        require(quantity > 0, "Quantity must be greater than 0");

        Product storage product = products[seller][productId];
        require(product.quantity >= quantity, "Insufficient stock");

        uint256 amount = quantity * (product.price * 1 ether);
        require(msg.value >= amount, "Not the correct amount");

        balance = msg.value;

        Order storage newOrder = orders[seller][orderCount];
        newOrder.id = orderCount;
        newOrder.productId = productId;
        newOrder.buyer = msg.sender;
        newOrder.seller = seller;
        newOrder.quantity = quantity;
        newOrder.amount = amount;
        newOrder.isDelivered = false;
        newOrder.buyerType = buyerType;

        orders[seller][orderCount] = newOrder;
        orderCount++;
    }

     function markOrderDelivered(uint256 orderId) external payable {
        require(orderId >= 0 && orderId <= orderCount, "Invalid order ID");
        Order storage order = orders[msg.sender][orderId];

        require(!order.isDelivered, "Order is already delivered");
        require(order.seller == msg.sender, "You are not the seller of this order");

        address buyer = order.buyer;
        Product storage product = products[msg.sender][order.productId];

        product.quantity -= order.quantity;

        Product storage newProduct = products[buyer][order.productId];
        newProduct.id = order.productId;
        newProduct.name = product.name;
        newProduct.quantity = order.quantity;
        newProduct.price = product.price;
     


        if(order.buyerType == ParticipantType.Wholesaler) {
            product.wholesaler = buyer;
        } else if(order.buyerType == ParticipantType.Retailer) {
            product.retailer = buyer;
        } else if(order.buyerType == ParticipantType.Consumer) {
            product.consumer = buyer;
        }

        newProduct.manufacturer = product.manufacturer;
        newProduct.wholesaler = product.wholesaler;
        newProduct.retailer = product.retailer;

        products[buyer][order.productId] = newProduct;
        payable(order.seller).transfer(balance);
        balance = 0;

        order.isDelivered = true;
    }

    function getManufacturer(uint256 productId) external view returns (address) {
        require(productId > 0 && productId <= productCount, "Invalid product ID");
        Product storage product = products[msg.sender][productId];
        return product.manufacturer;
    }

    function getWholeSaler(uint256 productId) external view returns (address) {
        require(productId > 0 && productId <= productCount, "Invalid product ID");
        Product storage product = products[msg.sender][productId];
        return product.wholesaler;
    }

    function getRetailer(uint256 productId) external view returns (address) {
        require(productId > 0 && productId <= productCount, "Invalid product ID");
        Product storage product = products[msg.sender][productId];
        return product.wholesaler;
    }

    function getConsumer(uint256 productId) external view returns (address) {
        require(productId > 0 && productId <= productCount, "Invalid Product ID");
        Product storage product = products[msg.sender][productId];
        return product.consumer;
    }

    function getBalance() public view returns (uint256) {
        return balance;
    }

		function getAddress() public view returns (address) {
			return msg.sender;
		}

}