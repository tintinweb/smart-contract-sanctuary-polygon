/**
 *Submitted for verification at polygonscan.com on 2022-04-10
*/

// File: contracts/CropChain.sol

// SPDX-License-Identifier= GPL-3.0

pragma solidity ^0.8.7;

contract CropChain {

    //Buyers

    struct Buyer {
        string first_name;
        string last_name;
        uint256 phone_number;
        string email_address;
        string delivery_address;
        string password;
    }

    struct Product {
        uint Product_id;
        string Product_name;
        string description;
        uint256 price;
        uint rating;
        uint128 quantity;
        uint128 sales;
        address owner_address;
    }

    struct Cart {
        Product [] cart_items;
        uint itemcount;
    }

    struct Wishlist {
        Product [] wishlist_items;
        uint itemcount;
    }
    
    mapping(address => Buyer) public buyers;
    mapping(address => Cart) public carts;
    mapping(address => Wishlist) public wishlists;

    // Sellers

    uint public number_of_sellers = 0;

    struct Seller {
        string first_name;
        string last_name;
        uint256 phone_number;
        string location_address;
        string password;
    }

    struct Warehouse {
        string warehouse_name;
        Product [] products;
        uint itemcount;
        
    }

    mapping(uint=>address) public id_to_address;
    mapping(address => Seller) public sellers;
    mapping(address => Warehouse) public warehouses;



    function OrderProduct(uint Product_id, address owner_address, uint128 quantity1) public{
        Product memory product_instance;
        product_instance = GetProductDetails(Product_id, owner_address);
        Warehouse storage warehouse_instance = warehouses[owner_address];
        uint i=0;
        for (i=0;i<warehouse_instance.products.length; i++){
            if (warehouse_instance.products[i].Product_id == Product_id){
                warehouse_instance.products[i].Product_name = product_instance.Product_name;
                warehouse_instance.products[i].description = product_instance.description;
                warehouse_instance.products[i].price = product_instance.price;
                warehouse_instance.products[i].quantity = product_instance.quantity - quantity1;
                break;
            }
        }
    }

    
    function AddToWishlist(uint Product_id, address owner_address) public{
        Wishlist storage wishlist_instance = wishlists[msg.sender];
        Product memory product_instance;
        product_instance = GetProductDetails(Product_id, owner_address);        
        uint i;
        bool done;
        for (i=0; i<wishlist_instance.wishlist_items.length; i++){
            if (wishlist_instance.wishlist_items[i].Product_id == 0){
                wishlist_instance.wishlist_items[i] = product_instance;
                wishlist_instance.itemcount =  wishlist_instance.wishlist_items.length;
                done = true;
                break;
            }
        }

        if(done==false){
            product_instance.Product_id =wishlist_instance.itemcount + 1;
            wishlist_instance.wishlist_items.push(product_instance);
            wishlist_instance.itemcount =  wishlist_instance.itemcount + 1;
        }
    
    }

    function RemoveFromWishlist(uint Product_id, address owner_address) public {
        Wishlist storage wishlist_instance = wishlists[msg.sender];
        require(wishlist_instance.wishlist_items.length > 0);
        uint i;
        for (i=0; i<wishlist_instance.wishlist_items.length; i++){
            if (wishlist_instance.wishlist_items[i].Product_id == Product_id && wishlist_instance.wishlist_items[i].owner_address == owner_address){
                delete wishlist_instance.wishlist_items[i];
                wishlist_instance.itemcount =  wishlist_instance.itemcount - 1;
                break;
            }
        } 
        
    }

    function GetWishlistDetails() public view returns(Product[] memory){
        Wishlist storage wishlist_instance = wishlists[msg.sender];
        return wishlist_instance.wishlist_items;
    }

    function AddToCart(uint Product_id, address owner_address) public{
        Cart storage cart_instance = carts[msg.sender];
        Product memory product_instance;
        product_instance = GetProductDetails(Product_id, owner_address);        
        uint i;
        bool done;
        for (i=0; i<cart_instance.cart_items.length; i++){
            if (cart_instance.cart_items[i].Product_id == 0){
                cart_instance.cart_items[i] = product_instance;
                cart_instance.itemcount =  cart_instance.cart_items.length;
                done = true;
                break;
            }
        }

        if(done==false){
            product_instance.Product_id =cart_instance.itemcount + 1;
            cart_instance.cart_items.push(product_instance);
            cart_instance.itemcount =  cart_instance.itemcount + 1;
        }
    
    }

    function RemoveFromCart(uint Product_id, address owner_address) public {
        Wishlist storage wishlist_instance = wishlists[msg.sender];
        require(wishlist_instance.wishlist_items.length > 0);
        uint i;
        for (i=0; i<wishlist_instance.wishlist_items.length; i++){
            if (wishlist_instance.wishlist_items[i].Product_id == Product_id && wishlist_instance.wishlist_items[i].owner_address == owner_address){
                delete wishlist_instance.wishlist_items[i];
                wishlist_instance.itemcount =  wishlist_instance.itemcount - 1;
                break;
            }
        } 
        
    }

    function GetCartDetails() public view returns(Product[] memory){
        Cart storage cart_instance = carts[msg.sender];
        return cart_instance.cart_items;
    }
    

    function AddUser(string memory first_name, string memory last_name, uint256 phone_number, string memory email_address, string memory delivery_address, string memory password) public{
        Buyer storage buyer_instance = buyers[msg.sender];
        buyer_instance.first_name = first_name;
        buyer_instance.last_name = last_name;
        buyer_instance.phone_number = phone_number;
        buyer_instance.email_address = email_address;
        buyer_instance.delivery_address = delivery_address;
        buyer_instance.password = password;

    }

    // Setter Functions

    function set_first_nameB(string memory first_name_setter) public{
        Buyer storage buyer_instance = buyers[msg.sender];
        buyer_instance.first_name = first_name_setter;

    }

    function set_last_nameB(string memory last_name_setter) public{
        Buyer storage buyer_instance = buyers[msg.sender];
        buyer_instance.last_name = last_name_setter;

    }

    function set_phone_numberB(uint256 phone_number_setter) public {
        Buyer storage buyer_instance = buyers[msg.sender];
        buyer_instance.phone_number = phone_number_setter;

    }

    function set_email_addressB(string memory email_address_setter) public{
        Buyer storage buyer_instance = buyers[msg.sender];
        buyer_instance.email_address = email_address_setter;

    }    

    function set_delivery_addressB(string memory delivery_address_setter) public{
        Buyer storage buyer_instance = buyers[msg.sender];
        buyer_instance.delivery_address = delivery_address_setter;

    }

    function set_passwordB(string memory password_setter) public{
        Buyer storage buyer_instance = buyers[msg.sender];
        buyer_instance.password = password_setter;

    }

    // Getter Functions

    function get_first_nameB() public view returns(string memory){
        Buyer storage buyer_instance = buyers[msg.sender];
        string memory first_name = buyer_instance.first_name;
        return first_name;

    }

    function get_last_nameB() public view returns(string memory){
        Buyer storage buyer_instance = buyers[msg.sender];
        string memory last_name = buyer_instance.last_name;
        return last_name;

    }

    function get_phone_numberB() public view returns(uint256){
        Buyer storage buyer_instance = buyers[msg.sender];
        uint256 number = buyer_instance.phone_number;
        return number;

    }

    function get_email_addressB() public view returns(string memory){
        Buyer storage buyer_instance = buyers[msg.sender];
        string memory email_address = buyer_instance.email_address;
        return email_address;

    }    

    function get_delivery_addressB() public view returns(string memory){
        Buyer storage buyer_instance = buyers[msg.sender];
        string memory delivery_address = buyer_instance.delivery_address;
        return delivery_address;

    }

    function get_passwordB() public view returns(string memory){
        Buyer storage buyer_instance = buyers[msg.sender];
        string memory password = buyer_instance.password;
        return password;

    }


    // Warehouse related stuff
    function MakeWarehouse(string memory warehouse_name) public {
        Warehouse storage warehouse_instance = warehouses[msg.sender];
        warehouse_instance.warehouse_name = warehouse_name;
        warehouse_instance.itemcount = warehouse_instance.products.length;
    }

    function AddProduct(string memory Product_name, string memory description, uint256 price, uint128 quantity) public{
        Warehouse storage warehouse_instance = warehouses[msg.sender];
        Product memory product_instance;
        product_instance.owner_address = msg.sender;
        product_instance.Product_name = Product_name;
        product_instance.description = description;
        product_instance.price = price;
        product_instance.quantity = quantity;

        uint i;
        bool done;
        for (i=0;i<warehouse_instance.itemcount;i++){
            if (warehouse_instance.products[i].Product_id == 0){
                product_instance.Product_id = i+1;                
                warehouse_instance.products[i] = product_instance;
                warehouse_instance.itemcount =  warehouse_instance.products.length;
                done = true;
                break;
            }
        }
        if (done == false){
            product_instance.Product_id = warehouse_instance.itemcount + 1;
            warehouse_instance.products.push(product_instance);
            warehouse_instance.itemcount =  warehouse_instance.itemcount + 1;
        }
    }

    function RemoveProduct(uint Product_id, address owner_address) public {
        Warehouse storage warehouse_instance = warehouses[msg.sender];
        require(warehouse_instance.products.length > 0);
        uint i;
        for (i=0; i<warehouse_instance.products.length; i++){
            if (warehouse_instance.products[i].Product_id == Product_id && warehouse_instance.products[i].owner_address == owner_address){
                delete warehouse_instance.products[i];
                warehouse_instance.itemcount =  warehouse_instance.itemcount - 1;
                break;
            }
        } 
        
    }

    function EditProduct(uint Product_id, string memory Product_name, string memory  description, uint256 price, uint128 quantity) public {
        Warehouse storage warehouse_instance = warehouses[msg.sender];
        uint i=0;
        for (i=0;i<warehouse_instance.products.length; i++){
            if (warehouse_instance.products[i].Product_id == Product_id){
                warehouse_instance.products[i].Product_name = Product_name;
                warehouse_instance.products[i].description = description;
                warehouse_instance.products[i].price = price;
                warehouse_instance.products[i].quantity = quantity;
                break;
            }
        }
        
    }

    function GetProductDetails(uint Product_id, address seller_address) public view returns (
        // string memory  Product_name, string memory  description, uint256 price, uint128 quantity, address owner_address, uint rating, uint128 sales
        Product memory product
        ){
        Warehouse storage warehouse_instance = warehouses[seller_address];
        uint i=0;
        for (i=0;i<warehouse_instance.products.length; i++){
            if (warehouse_instance.products[i].Product_id == Product_id){
                return warehouse_instance.products[i];
                // Product_name = warehouse_instance.products[i].Product_name;
                // description = warehouse_instance.products[i].description;
                // price = warehouse_instance.products[i].price;
                // quantity = warehouse_instance.products[i].quantity;
                // owner_address = warehouse_instance.products[i].owner_address;
                // rating = warehouse_instance.products[i].rating;
                // sales = warehouse_instance.products[i].sales;
                // return (
                // Product_name, description, price, quantity, owner_address, rating, sales
                // );
            }
        }
    }    

    function AddSeller(string memory  first_name, string memory  last_name, uint256 phone_number, string memory  location_address, string memory  password) public{
        
        Seller storage seller_instance = sellers[msg.sender];
        number_of_sellers = number_of_sellers + 1;
        id_to_address[number_of_sellers] = msg.sender;
        seller_instance.first_name = first_name;
        seller_instance.last_name = last_name;
        seller_instance.phone_number = phone_number;
        seller_instance.location_address = location_address;
        seller_instance.password = password;

    }

    // Setter Functions

    function set_first_nameS(string memory  first_name_setter) public{
        Seller storage seller_instance = sellers[msg.sender];
        seller_instance.first_name = first_name_setter;

    }

    function set_last_nameS(string memory  last_name_setter) public{
        Seller storage seller_instance = sellers[msg.sender];
        seller_instance.last_name = last_name_setter;

    }

    function set_phone_numberS(uint256 phone_number_setter) public{
        Seller storage seller_instance = sellers[msg.sender];
        seller_instance.phone_number = phone_number_setter;

    }

    function set_location_addressS(string memory  location_address_setter) public{
        Seller storage seller_instance = sellers[msg.sender];
        seller_instance.location_address = location_address_setter;

    }

    // Getter Functions

    function get_first_nameS() public view returns(string memory ){
        Seller storage seller_instance = sellers[msg.sender];
        string memory  first_name = seller_instance.first_name;
        return first_name;

    }

    function get_last_nameS() public view returns(string memory ){
        Seller storage seller_instance = sellers[msg.sender];
        string memory  last_name = seller_instance.last_name;
        return last_name;

    }

    function get_phone_numberS() public view returns(uint256){
        Seller storage seller_instance = sellers[msg.sender];
        uint256 number = seller_instance.phone_number;
        return number;

    }   

    function get_location_addressS() public view returns(string memory ){
        Seller storage seller_instance = sellers[msg.sender];
        string memory  location_address = seller_instance.location_address;
        return location_address;

    }

    function get_passwordS() public view returns(string memory  ){
        Seller storage seller_instance = sellers[msg.sender];
        string memory  password = seller_instance.password;
        return password;

    }

}