// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;
contract SupplyChain {
    // Product struct
    struct Product {
        uint id;
        string materialType;
        string category;
        uint totalQuantity;
        uint utilizedQuantity;
        address owner;
    }
    // Array of products
    Product[] public products;

    struct Allocate {
        uint id;
        uint deliveryId;
        uint totalQuantity;
        uint allocatedQuantity;
        address owner;
        address brand;
    }

    // Array of Allocations
    Allocate[] public allocations;
    // Mapping from product id to index in products array
    mapping(uint => uint) public productIdToIndex;

    // Mapping from product id to index in products array
    mapping(uint => uint) public allocationIdToIndex;

    // Add a new product to the supply chain
    function addProduct(uint _id, string memory _materialType, string memory _category, uint _totalQuantity) public {
        products.push(Product(_id, _materialType, _category, _totalQuantity, 0, msg.sender));
        productIdToIndex[_id] = products.length - 1;
    }
    // Transfer ownership of a product
    function transferProduct(uint _id, address _to) public {
        uint index = productIdToIndex[_id];
        Product storage product = products[index];
        // Check that the product exists and the sender is the owner
        require(product.id == _id, "Product does not exist");
        require(product.owner == msg.sender, "Sender is not the owner of the product");
        // Transfer ownership
        product.owner = _to;
    }
    // Update the quantity of a product
    function updateQuantity(uint _id, uint _quantity) public {
        uint index = productIdToIndex[_id];
        Product storage product = products[index];
        // Check that the product exists and the sender is the owner
        require(product.id == _id, "Product does not exist");
        require(product.owner == msg.sender, "Sender is not the owner of the product");
        require(product.totalQuantity > _quantity, "New Quantity should be greater than the current quantity");
        // Update the quantity
        product.totalQuantity = _quantity;
    }
    // Get the details of a product
    function getProduct(uint _id) public view returns (uint, string memory, string memory, uint,uint, address) {
        uint index = productIdToIndex[_id];
        Product storage product = products[index];
        // Check that the product exists
        require(product.id == _id, "Product does not exist");
        return (product.id, product.materialType, product.category, product.totalQuantity,product.utilizedQuantity, product.owner);
    }

        // Get the Allocations by Id
    function getAllocation(uint _id) public view returns (uint, uint, uint,uint,address, address) {
        uint index = allocationIdToIndex[_id];
        Allocate storage allocate = allocations[index];
        // Check that the product exists
        require(allocate.id == _id, "Product does not exist");
        return (allocate.id, allocate.deliveryId, allocate.totalQuantity,allocate.allocatedQuantity, allocate.owner, allocate.brand);
    }

    //Add a new allocation to the supply chain
    function addAllocation(uint _id, uint _deliveryId, uint _allocatedQuantity, address _brand) public {
        uint index = productIdToIndex[_deliveryId];
        Product storage product = products[index];
        // Check that the product exists and the sender is the owner
        require(product.id == _deliveryId, "Product does not exist");
        require(product.owner == msg.sender, "Sender is not the owner of the product");
        require(product.utilizedQuantity + _allocatedQuantity <= product.totalQuantity, "Required quantity is not available in the delivery");
        product.utilizedQuantity = product.utilizedQuantity + _allocatedQuantity;
        allocations.push(Allocate(_id, _deliveryId, product.totalQuantity, _allocatedQuantity, msg.sender, _brand));
        allocationIdToIndex[_id] = products.length - 1;
    }

}