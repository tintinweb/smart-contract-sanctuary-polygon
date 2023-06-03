// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract Store {
    address payable internal receiving_account;
    address payable internal ownerApp;
    uint256 numberOfUsers = 0;
    uint256 numberOfProducts = 0;
    uint256 numberOfCategories = 0;
    uint256 numberOfOrders = 0;
    uint256 randNonce = 0;

    constructor() {
        ownerApp = payable(msg.sender);
        receiving_account = payable(0);
    }

    struct User {
        uint256 userIdx;
        uint256 userId;
        address user_address;
        string name;
        string email;
        string avatar;
        string shipping_address;
        string rol;
        bool root;
        bool isActive;
        uint256 createdAt;
        uint256 updatedAt;
    }

    struct Product {
        uint256 productIdx;
        uint256 productId;
        string name;
        uint256 price;
        string description;
        string[] imageUrls;
        uint256 categoryId;
        bool isActive;
        uint256 inStock;
        uint256 sold;
        uint256 createdAt;
        uint256 updatedAt;
    }

    struct Category {
        uint256 categoryId;
        string name;
        bool isActive;
        uint256 createdAt;
        uint256 updatedAt;
    }

    struct Order {
        uint256 orderId;
        address userAddress;
        uint256[] productIds;
        uint256[] quantity;
        uint256 totalQuantity;
        uint256 totalAmount;
        bool isPaid;
        bool isDelivered;
        bool isActive;
        uint256 createdAt;
        uint256 updatedAt;
    }

    mapping(uint256 => User) public users;
    mapping(address => uint256) public userIndexes;
    mapping(uint256 => Product) public products;
    mapping(uint256 => Category) public categories;
    mapping(uint256 => Order) public orders;

    event UserCreated(
        uint256 userIdx,
        uint256 userId,
        address userAddress,
        string name,
        string email,
        bool isActive,
        uint256 createdAt
    );

    event UserUpdated(
        address userAddress,
        string name,
        string email,
        string rol,
        string avatar,
        string shipping_address,
        bool root,
        bool isActive,
        uint256 updatedAt
    );
    event ProductCreated(
        uint256 productIdx,
        uint256 productId,
        string name,
        uint256 price,
        string description,
        string[] imageUrls,
        uint256 categoryId,
        bool isActive,
        uint256 inStock,
        uint256 createdAt
    );
    event CategoryCreated(
        uint256 categoryId,
        string name,
        bool isActive,
        uint256 createdAt
    );
    event OrderCreated(
        uint256 orderId,
        address userAddress,
        uint256[] productIds,
        uint256[] quantity,
        uint256 totalQuantity,
        uint256 totalAmount,
        bool isPaid,
        bool isDelivered,
        bool isActive,
        uint256 createdAt
    );
    event OrderPaid(uint256 orderId, address userAddress, uint256 amountPaid);

    function createUser(
        string memory _name,
        string memory _email
    ) external returns (User memory) {
        User storage user = users[numberOfUsers];
        user.userIdx = numberOfUsers;
        user.userId = createId(100000000000000000000);
        user.name = _name;
        user.email = _email;
        user.user_address = msg.sender;
        user.isActive = true;
        user.createdAt = block.timestamp;
        user.updatedAt = block.timestamp;

        if (ownerApp == msg.sender) {
            user.rol = "admin";
            user.root = true;
        } else {
            user.rol = "user";
            user.root = false;
        }
        userIndexes[msg.sender] = numberOfUsers;
        numberOfUsers++;

        emit UserCreated(
            user.userIdx,
            user.userId,
            msg.sender,
            user.name,
            user.email,
            user.isActive,
            user.createdAt
        );
        return user;
    }

    function updateUser(
        address _address_user,
        string memory _name,
        string memory _email,
        string memory _rol,
        bool _root,
        string memory _avatar,
        string memory _shipping_address
    ) external returns (User memory) {
        for (uint256 i = 0; i < numberOfUsers; i++) {
            User storage user = users[i];
            if (user.user_address == _address_user) {
                if (bytes(_name).length != 0) {
                    user.name = _name;
                }
                if (bytes(_email).length != 0) {
                    user.email = _email;
                }
                if (bytes(_rol).length != 0) {
                    user.rol = _rol;
                }
                if (_root == true || _root == false) {
                    user.root = _root;
                }
                if (bytes(_avatar).length != 0) {
                    user.avatar = _avatar;
                }
                if (bytes(_shipping_address).length != 0) {
                    user.shipping_address = _shipping_address;
                }

                user.updatedAt = block.timestamp;
                emit UserUpdated(
                    user.user_address,
                    user.name,
                    user.email,
                    user.rol,
                    user.avatar,
                    user.shipping_address,
                    user.root,
                    user.isActive,
                    user.updatedAt
                );

                return user;
            }
        }

        revert("User no encontrado");
    }

    function createProduct(
        string memory _name,
        uint256 _price,
        uint256 _inStock,
        string memory _description,
        uint256 _category,
        string[] memory _image
    ) external onlyOwner {
        Product storage product = products[numberOfProducts];
        product.productIdx = numberOfProducts;
        product.productId = createId(100000000000000000000);
        product.name = _name;
        product.price = _price;
        product.inStock = _inStock;
        product.description = _description;
        product.categoryId = _category;
        product.isActive = true;
        product.imageUrls = _image;
        product.createdAt = block.timestamp;
        product.updatedAt = block.timestamp;
        numberOfProducts++;

        emit ProductCreated(
            product.productIdx,
            product.productId,
            product.name,
            product.price,
            product.description,
            product.imageUrls,
            product.categoryId,
            product.isActive,
            product.inStock,
            product.createdAt
        );
    }

    function createCategory(string memory _name) external onlyOwner {
        Category storage category = categories[numberOfCategories];
        category.categoryId = createId(100000000000000000000);
        category.name = _name;
        category.isActive = true;
        category.createdAt = block.timestamp;
        category.updatedAt = block.timestamp;
        numberOfCategories++;

        emit CategoryCreated(
            category.categoryId,
            category.name,
            category.isActive,
            category.createdAt
        );
    }

    function createOrder(
        uint256 userId,
        uint256[] memory _productIdxs,
        uint256[] memory _quantities
    ) public returns (Order memory) {
        require(_productIdxs.length > 0, "At least one product is required");
        require(users[userId].isActive == true, "User is not registered");

        uint256 _totalQuantity;
        uint256 total_price;
        for (uint256 i = 0; i < _productIdxs.length; i++) {
            uint256 productIdxs = uint256(_productIdxs[i]);
            uint256 quantity = 0;
            quantity = _quantities[i];

            require(
                products[productIdxs].inStock >= quantity,
                "Insufficient stock"
            );

            total_price += products[productIdxs].price * quantity;
            products[productIdxs].inStock -= quantity;
            products[productIdxs].sold += quantity;
            _totalQuantity += quantity;
        }
        Order storage order = orders[numberOfOrders];

        uint256 _totalAmount = total_price;

        order.orderId = createId(100000000000000000000);
        order.userAddress = msg.sender;
        order.productIds = _productIdxs;
        order.quantity = _quantities;
        order.totalQuantity = _totalQuantity;
        order.totalAmount = _totalAmount;
        order.isActive = true;
        order.isPaid = false;
        order.isDelivered = false;
        order.createdAt = block.timestamp;
        order.updatedAt = block.timestamp;
        numberOfOrders++;

        emit OrderCreated(
            order.orderId,
            order.userAddress,
            order.productIds,
            order.quantity,
            order.totalQuantity,
            order.totalAmount,
            order.isPaid,
            order.isDelivered,
            order.isActive,
            order.createdAt
        );

        // Llamar a getOrderbyCode y almacenar el resultado
        Order memory orderResult = getOrderbyCode(order.orderId);

        // Devolver el resultado
        return orderResult;
        //return order.orderId;
    }

    function getLastOrder() public view returns (Order memory) {
        require(numberOfOrders > 0, "No orders found");

        return orders[numberOfOrders - 1];
    }

    function payOrder(uint256 orderId) external payable {
        require(orders[orderId].isActive == true, "Invalid order");
        require(orders[orderId].isPaid == false, "Order already paid");
        require(
            orders[orderId].totalAmount == msg.value,
            "Incorrect amount sent"
        );

        uint256 totalPay = (orders[orderId].totalAmount);

        payable(ownerApp).transfer(totalPay);

        orders[orderId].isPaid = true;
        emit OrderPaid(orderId, msg.sender, totalPay);
    }

    function getAllUsers() external view returns (User[] memory) {
        User[] memory allUsers = new User[](numberOfUsers);

        for (uint256 i = 0; i < numberOfUsers; i++) {
            User storage user = users[i];
            allUsers[i] = user;
        }
        return allUsers;
    }

    function getAllProducts() external view returns (Product[] memory) {
        Product[] memory allProducts = new Product[](numberOfProducts);

        for (uint256 i = 0; i < numberOfProducts; i++) {
            Product storage product = products[i];
            allProducts[i] = product;
        }
        return allProducts;
    }

    function getAllCategories() external view returns (Category[] memory) {
        Category[] memory allCategories = new Category[](numberOfCategories);

        for (uint256 i = 0; i < numberOfCategories; i++) {
            Category storage categorie = categories[i];
            allCategories[i] = categorie;
        }
        return allCategories;
    }

    function getAllOrders() external view returns (Order[] memory) {
        Order[] memory allOrders = new Order[](numberOfOrders);

        for (uint256 i = 0; i < numberOfOrders; i++) {
            Order storage order = orders[i];
            allOrders[i] = order;
        }
        return allOrders;
    }

    function getOrderbyCode(
        uint256 _orderId
    ) internal view returns (Order memory) {
        for (uint256 i = 0; i < numberOfOrders; i++) {
            Order memory order = orders[i];
            if (order.orderId == _orderId) {
                return order;
            }
        }
        revert("Order not found");
    }

    function getProductbyId(
        uint256 _productId
    ) internal view returns (Product memory) {
        for (uint256 i = 0; i < numberOfProducts; i++) {
            Product memory product = products[i];
            if (product.productIdx == _productId) {
                return product;
            }
        }
        revert("Product not found");
    }

    function getUserbyAddress(
        address _address
    ) public view returns (User memory) {
        for (uint256 i = 0; i < numberOfUsers; i++) {
            User memory user = users[i];
            if (user.user_address == _address) {
                return user;
            }
        }
        revert("User not found");
    }

    function updateCategory(
        uint256 _categoryId,
        string memory _name
    ) external onlyOwner returns (Category memory) {
        for (uint256 i = 0; i < numberOfCategories; i++) {
            Category storage categorie = categories[i];
            if (categorie.categoryId == _categoryId) {
                if (bytes(_name).length != 0) {
                    categorie.name = _name;
                }

                categorie.updatedAt = block.timestamp;
                return categorie;
            }
        }

        revert("Category no encontrado");
    }

    function updateProduct(
        uint256 _productId,
        string memory _name,
        uint256 _price,
        uint256 _inStock,
        string memory _description,
        uint256 _category,
        string[] memory _image
    ) external onlyOwner returns (Product memory) {
        for (uint256 i = 0; i < numberOfProducts; i++) {
            Product storage product = products[i];
            if (product.productId == _productId) {
                if (bytes(_name).length != 0) {
                    product.name = _name;
                }
                if (_price != 0) {
                    product.price = _price;
                }
                if (_inStock != 0) {
                    product.inStock = _inStock;
                }
                if (bytes(_description).length != 0) {
                    product.description = _description;
                }
                if (_category != 0) {
                    product.categoryId = _category;
                }
                if (string[](_image).length != 0) {
                    product.imageUrls = _image;
                }
                product.updatedAt = block.timestamp;
                return product;
            }
        }

        revert("Product no encontrado");
    }

    function deleteProduct(uint256 _product_id) external onlyOwner {
        for (uint256 i = 0; i < numberOfProducts; i++) {
            if (products[i].productId == _product_id) {
                delete products[i];
                products[i] = products[numberOfProducts - 1];
                delete products[numberOfProducts - 1];
                numberOfProducts--;
                break;
            }
        }
    }

    function deleteCatgory(uint256 _category_id) external onlyOwner {
        for (uint256 i = 0; i < numberOfCategories; i++) {
            if (categories[i].categoryId == _category_id) {
                delete categories[i];
                categories[i] = categories[numberOfCategories - 1];
                delete categories[numberOfCategories - 1];
                numberOfCategories--;
                break;
            }
        }
    }

    function createId(uint256 _modulus) internal returns (uint256) {
        randNonce++;
        return
            uint256(
                keccak256(
                    abi.encodePacked(block.timestamp, msg.sender, randNonce)
                )
            ) % _modulus;
    }

    modifier onlyOwner() {
        require(
            msg.sender == ownerApp,
            "No tienes permisos para ejecutar esta funcion"
        );
        _;
    }

    function getAddressOwner() external view returns (address) {
        return ownerApp;
    }
}