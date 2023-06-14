// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract Store2 {
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
        string avatars;
        string shipping_address;
        string phone;
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
        uint256 orderIdx;
        uint256 orderId;
        address user;
        string habitation;
        string phone;
        mapping(uint256 => CartItem) cartItems;
        uint256 cartSize;
        uint256 total;
        bool delivered;
        bool paid;
        uint256 createdAt;
    }

    struct CartItem {
        string idx;
        string pId;
        string name;
        string description;
        string price;
        string[] imageUrls;
        string inStock;
        string category;
        string quantity;
    }

    mapping(uint256 => User) private users;
    mapping(address => uint256) private userIndexes;
    mapping(uint256 => Product) private products;
    mapping(uint256 => Category) private categories;
    mapping(uint256 => Order) private orders;

    uint256 private orderCount;

    event UserCreated(
        uint256 userIdx,
        uint256 userId,
        address userAddress,
        string name,
        string email,
        string rol,
        string avatars,
        string shipping_address,
        string phone,
        bool root,
        bool isActive,
        uint256 createdAt
    );

    event UserUpdated(
        address userAddress,
        string name,
        string email,
        string rol,
        string avatars,
        string shipping_address,
        string phone,
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
        uint256 indexed orderId,
        address indexed user,
        string habitation,
        string phone,
        CartItem[] cartItems,
        uint256 cartSize,
        uint256 total,
        bool delivered,
        bool paid,
        uint256 createdAt
    );

    event OrderPaid(uint256 orderId, address userAddress, uint256 amountPaid);

    function createUser(
        string memory _name,
        string memory _email,
        string memory _avatar
    ) external returns (User memory) {
        User storage user = users[numberOfUsers];
        user.userIdx = numberOfUsers;
        user.userId = createId(100000000000000000000);
        user.name = _name;
        user.email = _email;
        user.avatars = _avatar;
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
            user.rol,
            user.avatars,
            user.shipping_address,
            user.phone,
            user.root,
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
        string memory _shipping_address,
        string memory _phone
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
                    user.avatars = _avatar;
                }
                if (bytes(_shipping_address).length != 0) {
                    user.shipping_address = _shipping_address;
                }
                if (bytes(_phone).length != 0) {
                    user.phone = _phone;
                }

                user.updatedAt = block.timestamp;
                emit UserUpdated(
                    user.user_address,
                    user.name,
                    user.email,
                    user.rol,
                    user.avatars,
                    user.shipping_address,
                    user.phone,
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
        address user,
        string memory habitation,
        string memory phone,
        CartItem[] memory cartItems,
        uint256 total,
        bool delivered,
        bool paid,
        uint256 createdAt
    ) public {
        Order storage newOrder = orders[numberOfOrders];
        newOrder.orderIdx = numberOfOrders;
        newOrder.orderId = createId(100000000000000000000);
        newOrder.user = user;
        newOrder.habitation = habitation;
        newOrder.phone = phone;
        newOrder.total = total;
        newOrder.delivered = delivered;
        newOrder.paid = paid;
        newOrder.createdAt = createdAt;

        for (uint256 i = 0; i < cartItems.length; i++) {
            CartItem memory item = cartItems[i];
            newOrder.cartItems[i] = item;

            // Actualizar la variable 'sold' del producto correspondiente
            /*  Product storage product = products[
                uint256(keccak256(bytes(item.pId)))
            ]; */

            //product.sold += 1;

            // Actualizar la variable 'inStock' del producto correspondiente
            //product.inStock -= 1;
        }

        newOrder.cartSize = cartItems.length;

        /* nuevo */
        // Copiar los cartItems en un arreglo para emitirlo en el evento
        CartItem[] memory cartItemsArray = new CartItem[](cartItems.length);
        for (uint256 i = 0; i < cartItems.length; i++) {
            cartItemsArray[i] = newOrder.cartItems[i];
        }

        emit OrderCreated(
            newOrder.orderId,
            newOrder.user,
            newOrder.habitation,
            newOrder.phone,
            cartItemsArray, //nuevo
            newOrder.cartSize, //nuevo
            newOrder.total,
            newOrder.delivered,
            newOrder.paid,
            newOrder.createdAt
        );

        numberOfOrders++;
    }

    function getAllOrders()
        external
        view
        returns (
            uint256[] memory orderIds,
            address[] memory userAddresses,
            string[] memory habitations,
            string[] memory phones,
            CartItem[][] memory carts,
            uint256[] memory cartSizes,
            uint256[] memory totals,
            bool[] memory delivered,
            bool[] memory paid,
            uint256[] memory createdAts
        )
    {
        orderIds = new uint256[](orderCount);
        userAddresses = new address[](orderCount);
        habitations = new string[](orderCount);
        phones = new string[](orderCount);
        carts = new CartItem[][](orderCount);
        cartSizes = new uint256[](orderCount);
        totals = new uint256[](orderCount);
        delivered = new bool[](orderCount);
        paid = new bool[](orderCount);
        createdAts = new uint256[](orderCount);

        for (uint256 i = 0; i < orderCount; i++) {
            Order storage order = orders[i];
            orderIds[i] = order.orderId;
            userAddresses[i] = order.user;
            habitations[i] = order.habitation;
            phones[i] = order.phone;
            cartSizes[i] = order.cartSize;
            totals[i] = order.total;
            delivered[i] = order.delivered;
            paid[i] = order.paid;
            createdAts[i] = order.createdAt;

            CartItem[] memory cartItems = new CartItem[](order.cartSize);
            for (uint256 j = 0; j < order.cartSize; j++) {
                cartItems[j] = order.cartItems[j];
            }
            carts[i] = cartItems;
        }

        return (
            orderIds,
            userAddresses,
            habitations,
            phones,
            carts,
            cartSizes,
            totals,
            delivered,
            paid,
            createdAts
        );
    }

    /*  function getOrderById(
        uint256 orderId
    )
        external
        view
        returns (
            address user,
            string memory habitation,
            string memory phone,
            CartItem[] memory cartItems,
            uint256 total,
            bool delivered,
            bool paid,
            uint256 createdAt
        )
    {
        for (uint256 i = 0; i < orderCount; i++) {
            Order storage order = orders[i];
            if (order.orderId == orderId) {
                return (
                    order.user,
                    order.habitation,
                    order.phone,
                    getCartItems(order.cartItems),
                    order.total,
                    order.delivered,
                    order.paid,
                    order.createdAt
                );
            }
        }

        revert("Order not found");
    }

    function getCartItems(
        mapping(uint256 => CartItem) storage cartItemsMapping
    ) internal view returns (CartItem[] memory) {
        uint256 itemCount = getCartItemCount(cartItemsMapping);
        CartItem[] memory items = new CartItem[](itemCount);

        for (uint256 i = 0; i < itemCount; i++) {
            items[i] = cartItemsMapping[i];
        }

        return items;
    }

    function getCartItemCount(
        mapping(uint256 => CartItem) storage cartItemsMapping
    ) internal view returns (uint256) {
        uint256 count = 0;

        for (uint256 i = 0; i < orderCount; i++) {
            if (bytes(cartItemsMapping[i].pId).length > 0) {
                count++;
            }
        }

        return count;
    }
 */
    /* function getLastOrder() public view returns (Order memory) {
        require(numberOfOrders > 0, "No orders found");

        return orders[numberOfOrders - 1];
    } */

    /* function payOrder(uint256 orderId) external payable {
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
    } */

    /* function payOrder(uint256 orderId) external payable {
        require(orders[orderId].paid == false, "Order already paid");
       require(orders[orderId].delivered == true, "Invalid order");
       
        require(
            orders[orderId].total == msg.value,
            "Incorrect amount sent"
        ); 

        uint256 totalPay = (orders[orderId].total);

        payable(ownerApp).transfer(totalPay);

        orders[orderId].paid = true;
        emit OrderPaid(orderId, msg.sender, totalPay);
    } */

    function payOrder(uint256 _orderIdx) external payable {
        Order storage order = orders[_orderIdx];
        require(order.orderIdx == _orderIdx, "Invalid order ID"); // Verificar que el ID de la orden sea válido

        require(!order.paid, "Order already paid"); // Verificar que la orden no haya sido pagada anteriormente

        uint256 amountPaid = msg.value;
        require(amountPaid >= order.total, "Insufficient payment amount"); // Verificar que el monto pagado sea suficiente para cubrir el total de la orden

        // Realizar acciones adicionales relacionadas con el pago, como registrar el pago en un sistema externo o transferir los fondos a otra dirección
        uint256 totalPay = order.total;
        payable(ownerApp).transfer(totalPay);


        // Marcar la orden como pagada
        order.paid = true;

        // Actualizar los valores de 'sold' e 'inStock' en la estructura 'Product'
        for (uint256 i = 0; i < order.cartSize; i++) {
            string memory productId = order.cartItems[i].pId;
            Product storage product = products[
                uint256(keccak256(bytes(productId)))
            ];
            product.sold += 1;
            product.inStock -= 1;
        }

        emit OrderPaid(_orderIdx, msg.sender, amountPaid);
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

    /*   function getAllOrders() external view returns (Order[] memory) {
        Order[] memory allOrders = new Order[](numberOfOrders);

        for (uint256 i = 0; i < numberOfOrders; i++) {
            Order storage order = orders[i];
            allOrders[i] = order;
        }
        return allOrders;
    } */

    /* function getOrderbyCode(
        uint256 _orderId
    ) internal view returns (Order memory) {
        for (uint256 i = 0; i < numberOfOrders; i++) {
            Order memory order = orders[i];
            if (order.orderId == _orderId) {
                return order;
            }
        }
        revert("Order not found");
    } */

    function getProductbyId(
        uint256 _productId
    ) external view returns (Product memory) {
        for (uint256 i = 0; i < numberOfProducts; i++) {
            Product memory product = products[i];
            if (product.productId == _productId) {
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
                //products[i].productIdx = i;
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
                //categories[i].categoryIdx = i;
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

    /*  function createId(uint256 seed) public pure returns (uint256) {
    return uint256(keccak256(abi.encodePacked(seed)));
} */

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