/**
*   Owner               --> 0x2A42F54197b2a18390a138bF0c479AC0ab807372
*   Contract address    --> 0x64d4d0b7be64004ef98a4e63ed6051f497088507
*   MumbaiScan          --> https://mumbai.polygonscan.com/address/0x64d4d0b7be64004ef98a4e63ed6051f497088507
*   Twitter             --> @yasmaniaco
*   Github              --> https://github.com/yasmanets
**/


// SPDX-License-Identifier: MIT
pragma solidity >=0.4.4 <0.7.0;
pragma experimental ABIEncoderV2;
import "./ERC20.sol";

contract Payments {

    ERC20Basic private token;
    address payable public owner;

    constructor() public {
        token = new ERC20Basic(10000);
        owner = msg.sender;
    }

    // Struct for storing customers
    struct client {
        uint bought_tokens;
        string [] products;
    }

    // Clients list
    mapping(address => client) public Clients;


    // ---- TOKENS MANAGEMENT ----

    function tokenPrice(uint _tokens) internal pure returns (uint) {
        return _tokens * (0.0001 ether);
    }

    // Function to buy tokens
    function buyTokens(uint _tokens) public payable {
        uint price = tokenPrice(_tokens);
        require(msg.value >= price, "You can't buy that many tokens");
        uint returnValue = msg.value - price;
        msg.sender.transfer(returnValue);
        uint balance = balanceOf();
        require(_tokens <= balance, "Enought tokens");
        token.transfer(msg.sender, _tokens);
        Clients[msg.sender].bought_tokens += _tokens;
    }

    // Contract tokens balance
    function balanceOf() public view returns (uint256) {
        return token.balanceOf(address(this));
    }

    // Display the number of tokens for a client
    function myTokens() public view returns (uint) {
        return token.balanceOf(msg.sender);
    }

    // Function to generate tokens
    function generateTokens(uint _tokens) public onlyOwner(msg.sender) {
        token.increaseTotalSupply(_tokens);
    }

    // ---- CONTRACT OWNER MANAGEMENT ---- //
    // Events
    event BoughtProduct(string, address);
    event NewProduct(string, uint);
    event RemoveProduct(string);

    // Product data
    struct product {
        string name;
        uint price;
        bool status;
    }

    mapping(string => product) public products;
    string[] product_names;
    mapping(address => string[]) public products_historical;

    // Add new product
    function addProduct(string memory _name, uint _price) public onlyOwner(msg.sender) {
        products[_name] = product(_name, _price, true);
        product_names.push(_name);
        emit NewProduct(_name, _price);
    }

    // Revome product
    function removeProduct(string memory _name) public onlyOwner(msg.sender) {
        bytes32 name_hash = keccak256(abi.encodePacked(_name));
        bytes32 empty_hash = keccak256(abi.encodePacked(""));
        require(name_hash != empty_hash, "The product does not exist");
        products[_name].status = false;
        emit RemoveProduct(_name);
    }

    // List available products
    function availableProducts() public view returns(string[] memory) {
        string[] memory _products = new string[](product_names.length);
        for (uint i=0; i < product_names.length; i++) {
            if (products[product_names[i]].status == true) {
                _products[i] = product_names[i];
            }
        }
        return _products;
    }

    // Función para pagar los productos
    function payProduct(string memory _name) public {
        uint price = products[_name].price;
        require(products[_name].status == true, "The product is not available");
        require(price <= myTokens(), "You don't have enough tokens");
        token.transferToCompany(msg.sender, address(this), price);
        products_historical[msg.sender].push(_name);
        emit BoughtProduct(_name, msg.sender);
    }

    // Function to list a customer's purchases
    function listBoughtProducts() public view returns(string[] memory){
        return products_historical[msg.sender];
    }

    // Function to return tokens
    function returnTokens(uint _tokens) public payable {
        require(_tokens > 0, "You need to return a positive amount of tokens.");
        require(_tokens <= myTokens(), "You don't have enough tokens");
        token.transferToCompany(msg.sender, address(this), _tokens);
        msg.sender.transfer(tokenPrice(_tokens));
    }


    // ---- MODIFIERS ----

    modifier onlyOwner(address _sender) {
        require(_sender == owner, "You don't have permissions");
        _;
    }
}