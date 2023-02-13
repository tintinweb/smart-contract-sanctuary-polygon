// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.9;

contract Supplychain {

    address public admin;

    constructor() {
        admin=msg.sender;
    }

    struct Product {
        address manufacturer;
        string name;
        string desc;
        uint256 price;
        uint256 quantity;
    }

    struct Order{
        address buyer;
        uint256 product_id;
        uint256 dist_id;
    }

    struct Buyer{
        string name;
        string cert_hash;
        bool verified;
    }

    struct Distributor{
        address dist_addr;
        string name;
        mapping(address => bool) addr_to_staff;
    }

    struct Manufacturer{
        string name;
        string cert_hash_mfr;
        bool verified;
    }

    event ProductCreated(address manufacturer, string name, string desc, uint256 price, uint256 quantity, uint256 id);
    event ProductBought(address buyer, uint256 product_id, uint256 product_id_counter);
    event BuyerCreated(address buyer_addr, string name, string cert_hash);
    event DistributorCreated(address dist_addr, string name, uint256 dist_id_counter);
    event ManufacturerCreated(address manufacturer_addr, string name, string cert_hash, uint256 manufacturer_id);

    uint256 id_counter = 0;
    mapping(uint256 => Product) public id_to_product;
    uint256 product_id_counter = 0;
    mapping(uint256 => Order) public id_to_order;
    mapping(address => Buyer) public addr_to_buyer;
    uint256 dist_id_counter = 0;
    mapping(uint256 => Distributor) public id_to_distributor;
    uint256 manufacturer_to_counter = 0;
    mapping(address => Manufacturer) public addr_to_manufacturer;

    modifier onlyBuyer(){
        require(bytes(addr_to_buyer[msg.sender].name).length != 0, "buyer doesn't exist");
        _;
    }

    modifier onlyDistributor(uint256 dist_id){
        require(id_to_distributor[dist_id].dist_addr == msg.sender, "you are not admin of distributor chain");
        _;
    }

    modifier onlyStaff(uint256 dist_id){
        require(id_to_distributor[dist_id].addr_to_staff[msg.sender], "you are not staff of distributor chain");
        _;
    }
    
    modifier onlyManfacturer(){
        require(bytes(addr_to_manufacturer[msg.sender].name).length != 0, "manufacturer doesn't exist");
        _;
    }

    function createProduct(
     string memory name,
     string memory desc,
     uint256 price, 
     uint256  quantity
     ) public {
        id_to_product[id_counter].manufacturer=msg.sender;
        id_to_product[id_counter].name=name;
        id_to_product[id_counter].desc=desc;
        id_to_product[id_counter].price=price;
        id_to_product[id_counter].quantity=quantity;
        emit ProductCreated(msg.sender, name, desc, price,quantity,id_counter);
        id_counter++;
    }

    function buyProduct(uint256[] memory ids) public payable onlyBuyer{
        uint256 total_price_to_pay = 0;
        for (uint256 i = 0; i < ids.length; i++) {
            total_price_to_pay += id_to_product[ids[i]].price;
        }


        require(msg.value == total_price_to_pay, "total price doesn't match");
        for (uint256 i = 0; i < ids.length; i++) {
            id_to_order[product_id_counter].buyer = msg.sender;
            id_to_order[product_id_counter].product_id = ids[i];
            payable(id_to_product[ids[i]].manufacturer).transfer(id_to_product[ids[i]].price);
            emit ProductBought(msg.sender, ids[i], product_id_counter);
            product_id_counter++;
        }
    }

    function createBuyer(
     string memory name,
     string memory cert_hash
    ) public {
        bytes(name).length != 0;
        addr_to_buyer[msg.sender].name=name;
        addr_to_buyer[msg.sender].cert_hash=cert_hash;
        emit BuyerCreated(msg.sender, name, cert_hash);
    }

    function createDistributor(
     string memory name
    ) public {
        id_to_distributor[dist_id_counter].dist_addr=msg.sender;
        id_to_distributor[dist_id_counter].name=name;
        emit DistributorCreated(msg.sender, name, dist_id_counter);
        dist_id_counter++;
    }

    function addStaff(address staff, uint256 dist_id) public onlyDistributor(dist_id) {
        id_to_distributor[dist_id].addr_to_staff[staff]=true;
    }

    function createManufacturer(string memory name, string memory cert_hash_mfr) public {
        addr_to_manufacturer[msg.sender].name=name;
        addr_to_manufacturer[msg.sender].cert_hash_mfr=cert_hash_mfr;
        emit ManufacturerCreated(msg.sender, name, cert_hash_mfr, manufacturer_to_counter);
        manufacturer_to_counter++;
    }
}