// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

// error Aalkam__ProductAlreadyExiest();
// error Aalkam__ProductNotExiest();
// error Aalkam__UnArthorized();
// error Aalkam__NotValidPrice();

contract Aalkam {
    /* State variables */
    struct Product {
        string ipfsUri;
        address owner;
        string id;
        bool exist;
        uint256 price;
        bool soldInCrypto;
    }

    struct Record {
        string ipfsUri;
        uint256 date;
    }

    mapping(string => Product) public Products;
    mapping(string => Record[]) public History;

    /* Events */
    event ProductAdded(string id, string ipfsHash);
    event ProductUpdeted(string id, string ipfsHash);
    event ProductSelled(string id, string ipfsHash);
    event ProductDeleted(string id);

    /* Modifires */

    modifier productExiest(string calldata _id) {
        require(Products[_id].exist, "Product not exiest");
        _;
    }

    modifier productOwnerCheck(string calldata _id) {
        // if (!Products[_id].exist) {
        //     revert Aalkam__ProductNotExiest();
        // }
        // if (Products[_id].owner != msg.sender) {
        //     revert Aalkam__UnArthorized();
        // }
        require(
            Products[_id].owner == msg.sender,
            "You are not owner of this product"
        );
        _;
    }

    /* Functions */
    // create product
    function addProduct(
        string calldata id,
        string calldata ipfsUri,
        uint256 price,
        bool soldInCrypto
    ) public {
        // if (Products[id].exist) {
        //     revert Aalkam__ProductAlreadyExiest();
        // }
        require(!Products[id].exist, "Product already exiest");
        Products[id] = Product({
            ipfsUri: ipfsUri,
            owner: msg.sender,
            id: id,
            exist: true,
            price: price,
            soldInCrypto: soldInCrypto
        });
        History[id].push(Record({ipfsUri: ipfsUri, date: block.timestamp}));

        emit ProductAdded(id,ipfsUri);
    }

    // update product
    function updateProduct(
        string calldata _id,
        uint256 _price,
        string calldata _hash
    ) public productExiest(_id) productOwnerCheck(_id) {
        Products[_id].ipfsUri = _hash;
        Products[_id].price = _price;
        History[_id].push(Record({ipfsUri: _hash, date: block.timestamp}));
        emit ProductUpdeted(_id, _hash);
    }

    //sell product
    function sellProducts(
        string calldata id,
        string calldata ipfsUri,
        uint256 price,
        address owner
    ) public productExiest(id) {
        // if (Products[id].price != price) {
        //     revert Aalkam__NotValidPrice();
        // }
        if (Products[id].soldInCrypto) {
            require(Products[id].price == price, "Price did not match");
        }
        Products[id].id = id;
        Products[id].owner = owner;
        Products[id].ipfsUri = ipfsUri;

        History[id].push(Record({ipfsUri: ipfsUri, date: block.timestamp}));

        emit ProductSelled(id, ipfsUri);
    }

    //remove products
    function removeProduct(
        string calldata _id
    ) public productExiest(_id) productOwnerCheck(_id) {
        delete Products[_id];
        emit ProductDeleted(_id);
    }
}