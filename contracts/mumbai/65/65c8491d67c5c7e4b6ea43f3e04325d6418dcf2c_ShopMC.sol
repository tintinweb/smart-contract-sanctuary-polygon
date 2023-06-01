/**
 *Submitted for verification at polygonscan.com on 2023-06-01
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ShopMC {
    struct User {
        bool exists;
        string[] shops;
    }
    struct Shop {
        bool exists;
        address owner;
        string config;
        string[] orders;
        string[] products;
        string[] pages;
        string[] servers;
    }
    mapping(string => Shop) private shops;
    mapping(address => User) private users;
    uint256 public shopCount = 0;
    uint256 public userCount = 0;
    uint256 public orderCount = 0;
    address private webhooker;
    event Order(string _shopId, string _orderData);

    //webhooker
    constructor(address _webhooker) {
        webhooker = _webhooker;
    }

    function newOrder(
        string memory _shopId,
        string memory _orderData
    ) external {
        require(msg.sender == webhooker, "You are not the webhooker");
        shops[_shopId].orders.push(_orderData);
        orderCount++;
        emit Order(_shopId, _orderData);
    }

    //getters
    function getShop(
        string memory _shopId
    )
        public
        view
        returns (
            bool,
            address,
            string memory,
            string[] memory,
            string[] memory,
            string[] memory,
            string[] memory
        )
    {
        Shop memory shop = shops[_shopId];
        return (
            shop.exists,
            shop.owner,
            shop.config,
            shop.orders,
            shop.products,
            shop.pages,
            shop.servers
        );
    }

    function getUser(
        address _user
    ) public view returns (bool, string[] memory) {
        User memory user = users[_user];
        return (user.exists, user.shops);
    }

    //user
    function register() external {
        require(!users[msg.sender].exists, "User already registered");
        users[msg.sender].exists = true;
        userCount++;
    }

    //shop
    function newShop(string memory _shopId, string memory _shopData) external {
        require(users[msg.sender].exists, "User not registered");
        require(!shops[_shopId].exists, "Shop already exists");
        shops[_shopId].config = _shopData;
        shops[_shopId].exists = true;
        shops[_shopId].owner = msg.sender;
        users[msg.sender].shops.push(_shopId);
        shopCount++;
    }

    function editShop(string memory _shopId, string memory _shopData) external {
        require(users[msg.sender].exists, "User not registered");
        require(
            msg.sender == shops[_shopId].owner,
            "You are not the owner of this shop"
        );
        shops[_shopId].config = _shopData;
    }

    function removeShop(uint256 _shopIdNum) external {
        require(users[msg.sender].exists, "User not registered");
        string memory _shopId = users[msg.sender].shops[_shopIdNum];
        require(
            msg.sender == shops[_shopId].owner,
            "You are not the owner of this shop"
        );
        delete users[msg.sender].shops[_shopIdNum];
        delete shops[_shopId];
        shopCount--;
    }

    //pages
    function newPage(string memory _shopId, string memory _pageData) external {
        require(users[msg.sender].exists, "User not registered");
        require(
            msg.sender == shops[_shopId].owner,
            "You are not the owner of this shop"
        );
        shops[_shopId].pages.push(_pageData);
    }

    function editPage(
        string memory _shopId,
        uint256 _pageNum,
        string memory _pageData
    ) external {
        require(users[msg.sender].exists, "User not registered");
        require(
            msg.sender == shops[_shopId].owner,
            "You are not the owner of this shop"
        );
        shops[_shopId].pages[_pageNum] = _pageData;
    }

    function removePage(string memory _shopId, uint256 _pageNum) external {
        require(users[msg.sender].exists, "User not registered");
        require(
            msg.sender == shops[_shopId].owner,
            "You are not the owner of this shop"
        );
        delete shops[_shopId].pages[_pageNum];
    }

    //products
    function newProduct(
        string memory _shopId,
        string memory _productData
    ) external {
        require(users[msg.sender].exists, "User not registered");
        require(
            msg.sender == shops[_shopId].owner,
            "You are not the owner of this shop"
        );
        shops[_shopId].products.push(_productData);
    }

    function editProduct(
        string memory _shopId,
        uint256 _productNum,
        string memory _productData
    ) external {
        require(users[msg.sender].exists, "User not registered");
        require(
            msg.sender == shops[_shopId].owner,
            "You are not the owner of this shop"
        );
        shops[_shopId].products[_productNum] = _productData;
    }

    function removeProduct(
        string memory _shopId,
        uint256 _productNum
    ) external {
        require(users[msg.sender].exists, "User not registered");
        require(
            msg.sender == shops[_shopId].owner,
            "You are not the owner of this shop"
        );
        delete shops[_shopId].products[_productNum];
    }

    //servers
    function newServer(
        string memory _shopId,
        string memory _serverData
    ) external {
        require(users[msg.sender].exists, "User not registered");
        require(
            msg.sender == shops[_shopId].owner,
            "You are not the owner of this shop"
        );
        shops[_shopId].servers.push(_serverData);
    }

    function editServer(
        string memory _shopId,
        uint256 _serverNum,
        string memory _serverData
    ) external {
        require(users[msg.sender].exists, "User not registered");
        require(
            msg.sender == shops[_shopId].owner,
            "You are not the owner of this shop"
        );
        shops[_shopId].servers[_serverNum] = _serverData;
    }

    function removeServer(string memory _shopId, uint256 _serverNum) external {
        require(users[msg.sender].exists, "User not registered");
        require(
            msg.sender == shops[_shopId].owner,
            "You are not the owner of this shop"
        );
        delete shops[_shopId].servers[_serverNum];
    }
}