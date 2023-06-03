// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract SupplyChain {
    struct User {
        string name;
        string contact;
        string location;
        string email;
        string password;
        Role role;
    }

    enum Role {Farmer, Manufacturer, Distributor, Retailer, Consumer}

    struct Product {
        string name;
        uint256 quantity;
        uint256 price;
        bool isUploaded;
    }

    struct Order {
        address buyer;
        string productName;
        uint256 quantity;
        bool delivered;
        bool paid;
    }

    mapping(address => User) public users;
    mapping(address => Product) public products;
    mapping(address => Order[]) public orders;

    event UserSignedUp(address indexed user);
    event ProductUploaded(address indexed manufacturer, string name, uint256 quantity, uint256 price);
    event OrderPlaced(address indexed buyer, address indexed seller, string productName, uint256 quantity);
    event DeliveryStatusUpdated(address indexed seller, address indexed buyer, string productName, bool delivered);
    event PaymentMade(address indexed buyer, address indexed seller, string productName, bool paid);

    modifier onlyExistingUser() {
        require(bytes(users[msg.sender].name).length != 0, "User does not exist.");
        _;
    }

    modifier onlyManufacturer() {
        require(users[msg.sender].role == Role.Manufacturer, "Only manufacturer can access this function.");
        _;
    }

    address public manufacturer;

    constructor() {
        manufacturer = msg.sender;
    }

    function signupUser(
        string memory _name,
        string memory _contact,
        string memory _location,
        string memory _email,
        string memory _password,
        Role _role
    ) public {
        require(bytes(users[msg.sender].name).length == 0, "User already signed up.");

        User memory newUser = User(_name, _contact, _location, _email, _password, _role);
        users[msg.sender] = newUser;

        emit UserSignedUp(msg.sender);
    }

    function uploadProduct(string memory _name, uint256 _quantity, uint256 _price) public onlyManufacturer {
        require(!products[manufacturer].isUploaded, "Product already uploaded.");

        Product memory newProduct = Product(_name, _quantity, _price, true);
        products[manufacturer] = newProduct;

        emit ProductUploaded(manufacturer, _name, _quantity, _price);
    }

    function placeOrder(address _seller, string memory _productName, uint256 _quantity) public payable {
        require(products[_seller].isUploaded, "Product not uploaded.");
        require(_quantity > 0, "Quantity must be greater than zero.");

        Order memory newOrder = Order(msg.sender, _productName, _quantity, false, false);
        orders[_seller].push(newOrder);

        emit OrderPlaced(msg.sender, _seller, _productName, _quantity);
    }

    function updateDeliveryStatus(address _buyer, string memory _productName, bool _delivered) public onlyManufacturer {
        Order[] storage buyerOrders = orders[msg.sender];
        bool found = false;

        for (uint256 i = 0; i < buyerOrders.length; i++) {
            if (
                buyerOrders[i].buyer == _buyer &&
                keccak256(bytes(buyerOrders[i].productName)) == keccak256(bytes(_productName))
            ) {
                buyerOrders[i].delivered = _delivered;
                found = true;

                emit DeliveryStatusUpdated(msg.sender, _buyer, _productName, _delivered);
                break;
            }
        }

        require(found, "Order not found.");
    }

    function makePayment(address _seller, string memory _productName) public payable {
        Order[] storage buyerOrders = orders[_seller];
        bool found = false;

        for (uint256 i = 0; i < buyerOrders.length; i++) {
            if (
                buyerOrders[i].buyer == msg.sender &&
                keccak256(bytes(buyerOrders[i].productName)) == keccak256(bytes(_productName))
            ) {
                require(!buyerOrders[i].paid, "Payment already made.");

                buyerOrders[i].paid = true;
                found = true;

                emit PaymentMade(msg.sender, _seller, _productName, true);
                break;
            }
        }

        require(found, "Order not found.");
    }

    function getOrders() public view returns (Order[] memory) {
        return orders[msg.sender];
    }

    function viewAvailableProduct() public view returns (string memory, uint256, uint256) {
        Product memory product = products[manufacturer];
        require(product.isUploaded, "Product not uploaded.");

        return (product.name, product.quantity, product.price);
    }

    function getUserRole() public view onlyExistingUser returns (Role) {
        return users[msg.sender].role;
    }
}