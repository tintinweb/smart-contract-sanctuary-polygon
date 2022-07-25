/**
 *Submitted for verification at polygonscan.com on 2022-07-25
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract LabsProductTesting {
    event NewProduct(uint productId, string name);

    struct Product {
        string name;
        address owner;
    }

    Product[] public products;

    mapping (uint => address) public productToOwner;
    mapping (address => uint) ownerProductCount;

    function createProduct (string memory _name) public {
        products.push(Product(_name, msg.sender));
        uint id = products.length - 1;
        productToOwner[id] = msg.sender;
        ownerProductCount[msg.sender]++;
        emit NewProduct(id, _name);
    }

    function productQuantity() public view returns(uint count) {
        return products.length;
    }
}