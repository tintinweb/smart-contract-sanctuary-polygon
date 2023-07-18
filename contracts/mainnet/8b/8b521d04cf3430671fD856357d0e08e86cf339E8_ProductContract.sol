/**
 *Submitted for verification at polygonscan.com on 2023-07-18
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ProductContract {
    struct Product {
        string name;
        string brand;
        string fileUrl;
        string fileHash;
    }

    mapping(string => Product) private products;
    address private contractOwner;

    event ProductAdded(string indexed productName);

    modifier onlyOwner() {
        require(msg.sender == contractOwner, "Only contract owner can call this function");
        _;
    }

    constructor() {
        contractOwner = msg.sender;
    }

    function addProduct(
        string memory _index,
        string memory _name,
        string memory _brand,
        string memory _fileUrl,
        string memory _fileHash
    ) external onlyOwner {
        Product memory newProduct = Product(_name, _brand, _fileUrl, _fileHash);
        products[_index] = newProduct;
        emit ProductAdded(_index);
    }

    function getProduct(string memory _productIndex)
        external
        view
        returns (
            string memory name,
            string memory brand,
            string memory fileUrl,
            string memory fileHash
        )
    {
        Product storage product = products[_productIndex];
        require(bytes(product.name).length > 0, "Product not found");
        return (
            product.name,
            product.brand,
            product.fileUrl,
            product.fileHash
        );
    }

    function isOwner() external view returns (bool) {
        return msg.sender == contractOwner;
    }
}