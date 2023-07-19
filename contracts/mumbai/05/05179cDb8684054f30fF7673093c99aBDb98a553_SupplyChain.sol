// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SupplyChain {
    struct User {
        string name;
        string contact;
        string location;
        string email;
        string password;
        string role;
    }

    struct Product {
        string name;
        string quantity;
        uint256 price;
        string quality;
        bool isUploaded;
    }

    struct Order {
        address buyer;
        string productName;
        string quantity;
        bool delivered;
        bool paid;
    }

    mapping(address => User) public users;
    mapping(address => Product) public products;
    mapping(address => Order[]) public orders;
    mapping(address => bool) public loggedInUsers; // Mapping to store user login status

    event UserSignedUp(address indexed user);
    event ProductUploaded(address indexed manufacturer, string name, string quantity, uint256 price, string quality);
    event OrderPlaced(address indexed buyer, address indexed seller, string productName, string quantity);
    event DeliveryStatusUpdated(address indexed seller, address indexed buyer, string productName, bool delivered);
    event PaymentMade(address indexed buyer, address indexed seller, string productName, bool paid);

    modifier onlyExistingUser() {
        require(bytes(users[msg.sender].name).length != 0, "User does not exist.");
        _;
    }

    modifier onlyManufacturer() {
        require(keccak256(bytes(users[msg.sender].role)) == keccak256(bytes("Manufacturer")), "Only manufacturer can access this function.");
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
        string memory _role
    ) public {
        require(bytes(users[msg.sender].name).length == 0, "User already signed up.");

        User memory newUser = User(_name, _contact, _location, _email, _password, _role);
        users[msg.sender] = newUser;

        emit UserSignedUp(msg.sender);
    }

    function loginUser(string memory _email, string memory _password) public {
        require(bytes(users[msg.sender].name).length != 0, "User does not exist.");
        require(keccak256(bytes(users[msg.sender].email)) == keccak256(bytes(_email)), "Invalid email.");
        require(keccak256(bytes(users[msg.sender].password)) == keccak256(bytes(_password)), "Invalid password.");

        loggedInUsers[msg.sender] = true;
    }

    function logoutUser() public {
        require(loggedInUsers[msg.sender], "User is not logged in.");

        delete loggedInUsers[msg.sender];
    }

    function uploadProduct(string memory _name, string memory _quantity, uint256 _price, string memory _quality) public onlyManufacturer {
        require(!products[manufacturer].isUploaded, "Product already uploaded.");

        Product memory newProduct = Product(_name, _quantity, _price, _quality, true);
        products[manufacturer] = newProduct;

        emit ProductUploaded(manufacturer, _name, _quantity, _price, _quality);
    }

    function placeOrder(address _seller, string memory _productName, string memory _quantity) public payable {
        require(products[_seller].isUploaded, "Product not uploaded.");
        require(bytes(_quantity).length > 0, "Quantity must not be empty.");

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

    function viewAvailableProduct() public view returns (string memory, string memory, uint256, string memory) {
        Product memory product = products[manufacturer];
        require(product.isUploaded, "Product not uploaded.");

        return (product.name, product.quantity, product.price, product.quality);
    }

    function getUserRole() public view onlyExistingUser returns (string memory) {
        return users[msg.sender].role;
    }
}