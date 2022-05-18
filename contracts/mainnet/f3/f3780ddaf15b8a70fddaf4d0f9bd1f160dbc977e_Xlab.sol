/**
 *Submitted for verification at polygonscan.com on 2022-05-18
*/

/**
 *Submitted for verification at polygonscan.com on 2022-04-28
*/

// SPDX-License-Identifier: GPL-3.0

// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: contracts/Xlab.sol



pragma solidity >=0.7.0 <0.9.0;


/**
 * @title Storage Owner contract XLAB's product
 * @dev Store & retrieve value in a variable if is owner send message
 */
contract Xlab is Ownable {

    struct Wood {    
        uint id;
        string origin;
        uint age;
        uint seasoning;
        string typeseasoning;        
        string essence;
        uint humidity;
        string message;
    }

    struct Product {                
        uint id;               
        string title;
        uint woodId;
        string woodHash;
    }
    
    struct Order {        
        uint id;
        uint rank;
        uint prevState;
        uint currentState;
        uint pay;
        string pay_date;
        string message;
        string url;
        string photo;  
        uint[] product_ids; 
    }

    uint public orderscount;  
    uint public woodscount;  
    uint public productscount;
    string public topic;

    event NewWood(uint woodId, string essence);
    event NewProduct(uint prouctdId, string title);
    event NewOrder(uint orderId, string message);    
    event ChangeStatus(uint orderId, string message);    
    event ShowRandomOrder(uint orderId);

    mapping (uint => Wood) public woods;    
    mapping (uint => Product) public products;    
    mapping (uint => Order) public orders;    

    function _random() private view returns(uint){
        return uint(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender))) % orderscount;
    }

    function _createWood( uint woodId, string memory origin, uint age, uint seasoning, string memory typeseasoning, string memory essence, uint humidity, string memory message ) private {
        Wood memory _wood = Wood(woodId, origin, age, seasoning, typeseasoning, essence, humidity, message);        
        woods[woodId] = _wood;
        woodscount++;
        emit NewWood(woodId, essence);
    }

    function _createProduct( uint productId, string memory title, uint woodId, string memory woodHash ) private {        
        Product memory _product = Product(productId, title, woodId, woodHash);
        products[productId] = _product; 
        productscount++;
        emit NewProduct(productId, title);
    }

    function _createOrder(uint _id, uint _rank, uint _prevState, uint _currentState, string memory _commit, string memory _url, string memory _photo, uint[] memory _product_ids) private {        
        Order memory _order = Order(_id, _rank, _prevState, _currentState, 0, '', _commit, _url, _photo, _product_ids);
        orders[_id] = _order;
        orderscount++;
        emit NewOrder(_id, _commit);
    }  

    function getOrder(uint _id) external view returns (Order memory) {        
        return orders[_id];
    }

    function getWood(uint _id) external view returns (Wood memory) {        
        return woods[_id];
    }

    function getProduct(uint _id) external view returns (Product memory) {        
        return products[_id];
    }

    function getLastOrder() public view returns (Order memory) {   
        return orders[orderscount];
    }

    function getLastProduct() external view returns (Product memory) {   
        return products[productscount];
    }
    
    function getLastWood() external view returns (Wood memory) {   
        return woods[woodscount];
    }
    
    function getNumOrders() public view returns (uint) {   
        return orderscount;
    }

    function getNumProducts() public view returns (uint) {   
        return productscount;
    }

    function getNumWoods() public view returns (uint) {   
        return woodscount;
    }

    function getRandomOrder() external view returns (Order memory) {
        Order memory _order = orders[_random()];        
        return _order;
    }

    function changeStatusOrder(uint _id, uint _prevState, uint currentState, string memory _commit) public {        
        orders[_id].prevState = _prevState;        
        orders[_id].currentState = currentState;
        orders[_id].message = _commit;
        emit ChangeStatus(_id, "cambio status avvenuto");
    }    

    function setOrderPay(uint _id, string memory _timestamp) public {         
        orders[_id].pay = 1; 
        orders[_id].pay_date = _timestamp;         
    }

    function createOrder(uint _id, uint _rank, uint _prevState, uint _currentState, string memory _commit, string memory _url, string memory _photo, uint[] memory _product_ids) public payable {
        _createOrder(_id, _rank, _prevState, _currentState, _commit, _url, _photo, _product_ids);        
    }

    function createProduct(uint productId, string memory title, uint woodId, string memory woodHash) public payable {
        _createProduct(productId, title, woodId, woodHash);        
    }

    function createWood(uint woodId, string memory origin, uint age, uint seasoning, string memory typeseasoning, string memory essence, uint humidity, string memory message) public payable {
        _createWood(woodId, origin, age, seasoning, typeseasoning, essence, humidity, message);        
    }    

    function store(string memory _message) public {
        topic = _message;
    }

    function retrieve() public view returns (string memory){
        return topic;
    }
    
}