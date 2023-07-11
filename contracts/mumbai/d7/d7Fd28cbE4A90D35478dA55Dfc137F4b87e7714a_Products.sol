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
pragma solidity ^0.8.0;
import "./Counters.sol";

contract Products {
    using Counters for Counters.Counter;
    Counters.Counter private productId;
    address private owner;

    struct Product {
        uint256 id;
        string name;
        string description;
        uint256 quantity;
        uint256 totalquantity;
        uint256 price;
        address payable manufacturer;
        string imageUri;
        bool sold;
        bool releaseFund;
    }

    struct Return {
        uint256 id;
        address payable buyeraddress;
        string message;
        bool returnitem;
        bool approve;
    }

    struct Cancel {
        uint256 id;
        address payable buyerAddress;
        string message;
        bool cancel;
        bool approve;
    }

    mapping(uint256 => Product) public productsmangement;
    mapping(address => bool) public whiteList;
    mapping(address => uint256[]) public manufacturerProducts;
    mapping(address => mapping(uint256 => uint256)) public buyerPurchase;
    mapping(uint256 => Return) public returnpolicy;
    mapping(uint256 => Cancel) public cancelorder;

    address[] public manufacturerAddress;

    modifier onlyOwnerorwhitelisteduser() {
        require(
            whiteList[msg.sender] || owner == msg.sender,
            "You are not an owner or whitelisted user"
        );
        _;
    }

    modifier onlymanufacturer(uint256 _productId) {
        (
            productsmangement[_productId].manufacturer == msg.sender,
            "OnlyManuFacturer can call this Function"
        );
        _;
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "caller is not the owner");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function addWhitelisted(address userAddress) public onlyOwner {
        require(whiteList[userAddress] == false, "User already whitelisted");
        whiteList[userAddress] = true;
    }

    function removeWhitelist(address userAddress) public onlyOwner {
        require(whiteList[userAddress] == true, "User is not whitelisted");
        whiteList[userAddress] = false;
    }

    function addProduct(
        string memory name,
        string memory description,
        uint256 quantity,
        uint256 price,
        string memory uri
    ) public onlyOwnerorwhitelisteduser {
        require(price > 0, "Price should be greater than 0");
        require(quantity > 0, "quantity should be greater than 0");
        productId.increment();
        uint256 newItemId = productId.current();
        productsmangement[newItemId] = Product(
            newItemId,
            name,
            description,
            quantity,
            quantity,
            price * (10**18),
            payable(msg.sender),
            uri,
            false,
            false
        );
        manufacturerProducts[msg.sender].push(newItemId);
        manufacturerAddress.push(msg.sender);
    }

    function buyProduct(uint256 productid, uint256 _quantity) public payable {
        require(productsmangement[productid].id != 0, "Invalid product ID");
        Product storage product = productsmangement[productid];
        require(product.quantity >= _quantity, "Product out of Stock");
        uint256 totalPrice = product.price * _quantity;
        require(msg.value >= totalPrice, "Insufficient ETH sent");
        payable(address(this)).transfer(totalPrice);
        product.quantity -= _quantity;
        product.sold = true;
        buyerPurchase[msg.sender][productid] += _quantity;
    }

    function releaseFunds(uint256 _productId) public {
        Product storage product = productsmangement[_productId];
        require(
            msg.sender == product.manufacturer,
            "Unauthorized to claim funds"
        );
        require(!product.releaseFund, "Funds have already been released");
        require(product.quantity == 0, "Total quantity not sold out yet");

        address payable manufacturer = payable(product.manufacturer);
        uint256 totalPrice = product.price * product.totalquantity;
        require(
            address(this).balance >= totalPrice,
            "Insufficient contract balance"
        );
        manufacturer.transfer(totalPrice);
        product.releaseFund = true;
    }

    function returnPolicy(uint256 _productId, string memory message) public {
        uint256 quantity = buyerPurchase[msg.sender][_productId];
        require(
            quantity > 0,
            "No quantity of this product purchased by the caller"
        );
        returnpolicy[_productId] = Return(
            _productId,
            payable(msg.sender),
            message,
            true,
            false
        );
    }

    function cancelOrder(uint256 _productId, string memory message) public {
        uint256 quantity = buyerPurchase[msg.sender][_productId];
        require(
            quantity > 0,
            "No quantity of this product purchased by the caller"
        );
        cancelorder[_productId] = Cancel(
            _productId,
            payable(msg.sender),
            message,
            true,
            false
        );
    }

    function approveforReturn(uint256 _productId)
        public
        onlymanufacturer(_productId)
    {
        Product storage product = productsmangement[_productId];
        Return storage returnItems = returnpolicy[_productId];
        require(returnItems.returnitem, "Return policy not applicable");
        require(!returnItems.approve, "Your already give approval");
        address payable buyerAddress = returnItems.buyeraddress;
        uint256 quantity = buyerPurchase[buyerAddress][_productId];
        uint256 totalPrice = product.price * quantity;
        require(
            address(this).balance >= totalPrice,
            "Insufficient contract balance"
        );
        buyerAddress.transfer(totalPrice);
        returnItems.approve = true;
        productsmangement[_productId].quantity += quantity;
        buyerPurchase[buyerAddress][_productId] = 0;
    }

    function approveforcancel(uint256 _productId)
        public
        onlymanufacturer(_productId)
    {
        Product storage product = productsmangement[_productId];
        Cancel storage cancelItem = cancelorder[_productId];
        require(cancelItem.cancel, "Return policy not applicable");
        require(!cancelItem.approve, "Your already give approval");
        address payable buyerAddress = cancelItem.buyerAddress;
        uint256 quantity = buyerPurchase[buyerAddress][_productId];
        uint256 totalPrice = product.price * quantity;
        require(
            address(this).balance >= totalPrice,
            "Insufficient contract balance"
        );
        buyerAddress.transfer(totalPrice);
        cancelItem.approve = true;
        productsmangement[_productId].quantity += quantity;
        buyerPurchase[buyerAddress][_productId] = 0;
    }

    function fetchItems() public view returns (Product[] memory) {
        uint256 itemCount = productId.current();
        uint256 unsoldItemCount = productId.current();
        uint256 currentIndex = 0;

        Product[] memory items = new Product[](unsoldItemCount);
        for (uint256 i = 0; i < itemCount; i++) {
            uint256 currentId = productsmangement[i + 1].id;
            Product storage currentItem = productsmangement[currentId];
            items[currentIndex] = currentItem;
            currentIndex += 1;
        }
        return items;
    }

    function fetchManufacturerAddress() public view returns (address[] memory) {
        return manufacturerAddress;
    }

    function fetchMyProducts() public view returns (Product[] memory) {
        uint256 totalItemCount = productId.current();
        uint256 productCount = 0;
        uint256 currentIndex = 0;

        for (uint256 i = 0; i < totalItemCount; i++) {
            if (productsmangement[i + 1].manufacturer == msg.sender) {
                productCount += 1;
            }
        }

        Product[] memory products = new Product[](productCount);
        for (uint256 i = 0; i < totalItemCount; i++) {
            if (productsmangement[i + 1].manufacturer == msg.sender) {
                uint256 currentId = productsmangement[i + 1].id;
                Product storage currentItem = productsmangement[currentId];
                products[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return products;
    }

    function fetchMyPurchasedProducts() public view returns (Product[] memory) {
        uint256[] memory purchasedProductIds = new uint256[](
            productId.current()
        );
        uint256 purchasedProductCount = 0;
        uint256 currentIndex = 0;

        for (uint256 i = 0; i < productId.current(); i++) {
            if (buyerPurchase[msg.sender][i + 1] > 0) {
                purchasedProductIds[purchasedProductCount] = i + 1;
                purchasedProductCount += 1;
            }
        }

        Product[] memory purchasedProducts = new Product[](
            purchasedProductCount
        );
        for (uint256 i = 0; i < purchasedProductCount; i++) {
            uint256 currentId = purchasedProductIds[i];
            Product storage currentItem = productsmangement[currentId];
            purchasedProducts[currentIndex] = currentItem;
            currentIndex += 1;
        }
        return purchasedProducts;
    }

    function getProduct(uint256 productId)
        public
        view
        returns (Product memory)
    {
        return productsmangement[productId];
    }

    receive() external payable {}
}