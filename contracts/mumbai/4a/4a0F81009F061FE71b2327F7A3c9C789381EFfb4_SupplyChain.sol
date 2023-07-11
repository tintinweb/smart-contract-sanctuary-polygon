// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
    @title SupplyChain Contract
*/

contract SupplyChain {

    enum OrderStatus {
        Delivered,
        Shipped,
        Processing,
        Cancelled
    }

    struct User {
        uint id;
        string name;
        address account;
    }

    struct Manufacturer {
        uint id;
        string name;
        address account;
    }

    struct Product {
        uint id;
        string name;
        uint price;
        uint manufacturerId;
    }

    struct Order {
        uint id;
        uint customerId;
        uint productId;
        uint quantity;
        uint price;
        OrderStatus status;
    }

    mapping (uint => User) public users;
    mapping (uint => Manufacturer) public manufacturers;
    mapping (uint => Product) public products;
    mapping (uint => Order) public orders;

    uint commissionPercentage = 5;
    address owner;

    uint productId = 1;
    uint orderId = 1;
    uint userId = 1;
    uint manufacturerId = 1;

    event OrderCreated(uint orderId);
    event OrderCancelled(uint orderId);
    event CommissionRecieved(uint amount);

    /*
        @dev Modifier that allows only owner to call a function
    */
    modifier onlyOwner {
        require(msg.sender == owner, "Not an Owner");
        _;
    }

    /*
        @dev Modifier that allows only Manufacturer to call a function
    */
    modifier onlyManufacturer(uint _mid) {
        require(msg.sender == manufacturers[_mid].account, "Not a Manufacturer");
        _;
    }

    constructor (address _owner) {
        owner =_owner;
    }

    /*
        @dev Adds a new user with the given name and account
        @param _name The name of the user
        @param _account The wallet address of the user
    */
    function addUser(string memory _name, address _account) public {
        users[userId] = User(userId, _name, _account);
        userId ++;
    }

    /*
        @dev Adds a new Manufacturer with the given name and account
        @param _name The name of the Manufacturer
        @param _account The wallet address of the Manufacturer
    */
    function addManufacturer(string memory _name, address _account) public {
        manufacturers[manufacturerId] = Manufacturer(manufacturerId, _name, _account);
        manufacturerId++;
    }

    /*
        @dev Adds a new Product with the given name, price and manufacturerId
        @param _name The name of the Product
        @param price The price of the Product
        @param manufacturerId The manufacturer Id of the Product
    */
    function addProduct(string memory _name, uint price, uint _manufacturerId) public onlyManufacturer(_manufacturerId) {
        products[productId] = Product(productId, _name, price, _manufacturerId);
        productId++;
    }

    /*
        @dev Update a Product with the given name and price
        @param _name The name of the Product
        @param price The price of the Product
        @param productId The product Id of the Product
        @param manufacturerId The manufacturer Id of the Product
    */
    function updateProduct(string memory _name, uint _price, uint _productId, uint _manufacturerId) public onlyManufacturer(_manufacturerId) {
        Product memory product = products[_productId];
        product.name = _name;
        product.price = _price;
        products[_productId] = product;
    }

    /*
        @dev delete a Product with the given id
        @param productId The product Id of the Product
        @param manufacturerId The manufacturer Id of the Product
    */
    function deleteProduct(uint _productId, uint _manufacturerId) public onlyManufacturer(_manufacturerId){
        delete products[_productId];
    }

    /*
        @dev Gets all the products in the supply chain
        @returns An array of all the products
    */
    function getAllProducts() public view returns(Product[] memory) {
        Product[] memory allProducts = new Product[](productId);
        for(uint i = 1; i <= productId; i++) {
            allProducts[i-1] = products[i];
        }
        return allProducts;
    }

    /*
        @dev Purchase a product
        @param _productId The product Id of the Product
        @param _quantity The quantity of the Product
        @param _userId The user id of the user trying to purchase the product
    */
    function purchaseProduct(uint _productId, uint _quantity, uint _userId) public payable {
        uint totalPrice = products[_productId].price * _quantity;
        require(totalPrice == msg.value, "Insufficient Payment");

        orders[orderId] = Order(orderId, _userId, _productId, _quantity, totalPrice, OrderStatus.Processing);

        uint commissionAmount = (totalPrice * commissionPercentage) / 100;
        uint manufacturerAmount = totalPrice - commissionAmount;

        (bool success, ) = address(this).call{value: commissionAmount}(""); // Transfer Native tokens
        require(success, "Commission transfer failed!");

        (success, ) = address(manufacturers[products[_productId].manufacturerId].account).call{value: manufacturerAmount}("");
        require(success, "Manufacturer amount transfer failed!");

        emit OrderCreated(orderId);
        orderId ++;
    }

    /*
        @dev Deliver a product
        @param _orderId The order id of the order
        @param manufacturerId The manufacturer Id of the Product
    */
    function deliverOrder(uint _orderId, uint _manufacturerId) public onlyManufacturer(_manufacturerId) {
        orders[_orderId].status = OrderStatus.Delivered;
    }

    /*
        @dev Shipped a product
        @param _orderId The order id of the order
        @param manufacturerId The manufacturer Id of the Product
    */
    function shippedOrder(uint _orderId, uint _manufacturerId) public onlyManufacturer(_manufacturerId) {
        orders[_orderId].status = OrderStatus.Shipped;
    }

    /*
        @dev Cancel an Order
        @param _orderId The order id of the order
        @param manufacturerId The manufacturer Id of the Product
    */
    function cencelOrder(uint _orderId, uint _manufacturerId) public onlyManufacturer(_manufacturerId) {
        orders[_orderId].status = OrderStatus.Cancelled;
        emit OrderCancelled(_orderId);
    }

    /*
        @dev Withdraw Commission
    */
    function withdrawCommission() public payable onlyOwner() {
        uint balance = address(this).balance; // Native Token balance
        require(balance > 0, "No commission available to withdraw");

        (bool success, ) = address(owner).call{value: balance}(""); // Transfer Native tokens
        require(success, "Commission withdraw failed!");
    }

    receive() external payable {
        emit CommissionRecieved(msg.value);
    }

}