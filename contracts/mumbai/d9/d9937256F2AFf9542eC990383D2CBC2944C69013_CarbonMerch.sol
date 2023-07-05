// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

interface ICarbonMarketplace {
    function isAdmin(address addr) external view returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

error CarbonMerch__notAdmin();
error CarbonMerch__zeroQty();
error CarbonMerch__invalidProductId();
error CarbonMerch__invalidOrderId();
error CarbonMerch__buyAtLeastOneProduct();
error CarbonMerch__qtyError();
error CarbonMerch__alreadyPacked();
error CarbonMerch__alreadyShipped();
error CarbonMerch__alreadyOutForDelivery();
error CarbonMerch__alreadyDelivered();

contract CarbonMerch {
    enum Category {
        electronics,
        stationary,
        household,
        fashion,
        organic
    }

    enum OrderStatus {
        Booked,
        Packed,
        Shipped,
        OutForDelivery,
        Delivered
    }

    struct Product {
        string name;
        string description;
        uint256 qty;
        uint256 cost;
        string imageURI;
        Category category;
    }

    struct Order {
        uint256 orderId;
        address consumer;
        uint256 purchaseTime;
        string residentialAddress;
        OrderStatus status;
        uint256[] productIds;
        uint256[] qty;
    }

    ICarbonMarketplace private carbonMarketplace;
    Product[] private products;
    Order[] private orders;
    mapping(address => uint256[]) private consumerToOrderIds;

    // Events
    event productAdded(string indexed name, uint256 indexed id);
    event orderPlaced(uint256 indexed orderId, address indexed consumer, uint256 indexed bill);
    event orderPacked(uint256 indexed orderId);
    event orderShipped(uint256 indexed orderId);
    event orderOutForDelivery(uint256 indexed orderId);
    event orderDelivered(uint256 indexed orderId);

    constructor(address carbonMarketplaceAddr) {
        carbonMarketplace = ICarbonMarketplace(carbonMarketplaceAddr);
    }

    modifier onlyAdmins() {
        if (!carbonMarketplace.isAdmin(msg.sender)) {
            revert CarbonMerch__notAdmin();
        }
        _;
    }

    modifier orderIdExist(uint256 orderId) {
        if (orderId >= orders.length) {
            revert CarbonMerch__invalidOrderId();
        }
        _;
    }

    function addProduct(
        string memory name, 
        string memory desc, 
        uint256 initQty, 
        uint256 cost,
        string memory imageURI, 
        Category category
    ) public onlyAdmins {
        if (initQty == 0) {
            revert CarbonMerch__zeroQty();
        }

        products.push(Product({
            name: name,
            description: desc,
            qty: initQty,
            cost: cost,
            imageURI: imageURI,
            category: category
        }));

        emit productAdded(name, products.length);
    }

    function addQty(uint256 productId, uint256 extraQty) public onlyAdmins {
        if (productId >= products.length) {
            revert CarbonMerch__invalidProductId();
        }

        if (extraQty == 0) {
            revert CarbonMerch__zeroQty();
        }

        products[productId].qty += extraQty;
    }

    /**@param productIds It contains the ids of products the consumer wants to buy
     * @param qty It contains the corresponding quantity of product in productIds array
     * @param residentialAddress The address of consumer to deliver the swags 
    */
    function buyProduct(uint256[] memory productIds, uint256[] memory qty, string memory residentialAddress) public {
        require(productIds.length == qty.length);

        if (productIds.length == 0) {
            revert CarbonMerch__buyAtLeastOneProduct();
        }

        uint256 bill = 0;

        uint256 totalProducts = products.length;

        for (uint256 i = 0; i < productIds.length; i++) {
            if (productIds[i] >= totalProducts) {
                revert CarbonMerch__invalidProductId();
            }

            Product memory product = products[productIds[i]];

            if (qty[i] == 0 || qty[i] > product.qty) {
                revert CarbonMerch__qtyError();
            }

            products[productIds[i]].qty -= qty[i];
            bill += product.cost;
        }

        // Pay Amount
        carbonMarketplace.transferFrom(msg.sender, address(this), bill);

        uint256 orderId = orders.length;

        orders.push(Order({
            orderId: orderId,
            consumer: msg.sender,
            purchaseTime: block.timestamp,
            residentialAddress: residentialAddress,
            status: OrderStatus.Booked,
            productIds: productIds,
            qty: qty
        }));

        consumerToOrderIds[msg.sender].push(orderId);

        emit orderPlaced(orderId, msg.sender, bill);
    }

    function markAsPacked(uint256 orderId) public onlyAdmins orderIdExist(orderId) {
        if (uint256(orders[orderId].status) >= uint256(OrderStatus.Booked)) {
            revert CarbonMerch__alreadyPacked();
        }

        orders[orderId].status = OrderStatus.Packed;
        
        emit orderPacked(orderId);
    } 

    function markAsShipped(uint256 orderId) public onlyAdmins orderIdExist(orderId) {
        if (uint256(orders[orderId].status) >= uint256(OrderStatus.Shipped)) {
            revert CarbonMerch__alreadyShipped();
        }

        orders[orderId].status = OrderStatus.Shipped;

        emit orderShipped(orderId);
    }

    function markAsOutForDelivery(uint256 orderId) public onlyAdmins orderIdExist(orderId) {
        if (uint256(orders[orderId].status) >= uint256(OrderStatus.OutForDelivery)) {
            revert CarbonMerch__alreadyOutForDelivery();
        }

        orders[orderId].status = OrderStatus.OutForDelivery;

        emit orderOutForDelivery(orderId);
    }

    function markAsDelivered(uint256 orderId) public onlyAdmins orderIdExist(orderId) {
        if (uint256(orders[orderId].status) >= uint256(OrderStatus.Delivered)) {
            revert CarbonMerch__alreadyDelivered();
        }

        orders[orderId].status = OrderStatus.Delivered;

        emit orderDelivered(orderId);
    }

    function trackOrder(uint256 orderId) external view returns (Order memory) {
        return orders[orderId];
    } 

    function getAllConsumerOrders(address consumer) external view returns (Order[] memory) {
        uint256 length = consumerToOrderIds[consumer].length;

        Order[] memory myOrder = new Order[](length);

        for (uint i = 0; i < length; i++) {
            myOrder[i] = orders[consumerToOrderIds[consumer][i]];
        }

        return myOrder;
    }

    function getAllProducts() external view returns (Product[] memory) {
        return products;
    }

    function getProductAtIdx(uint256 productId) external view returns (Product memory) {
        return products[productId];
    }

    function getCarbonMarketplace() external view returns (address) {
        return address(carbonMarketplace);
    }
}