// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract SupplyChain {
    // Product struct
    struct Product {
        uint id;
        string name;
        string description;
        uint quantity;
        address owner;
    }

    // Array of products
    Product[] public products;

    // Mapping from product id to index in products array
    mapping(uint => uint) public productIdToIndex;

    // Add a new product to the supply chain
    function addProduct(uint _id, string memory _name, string memory _description, uint _quantity) public {
        products.push(Product(_id, _name, _description, _quantity, msg.sender));
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

        // Update the quantity
        product.quantity = _quantity;
    }

    // Get the details of a product
    function getProduct(uint _id) public view returns (uint, string memory, string memory, uint, address) {
        uint index = productIdToIndex[_id];
        Product storage product = products[index];

        // Check that the product exists
        require(product.id == _id, "Product does not exist");

        return (product.id, product.name, product.description, product.quantity, product.owner);
    }
}