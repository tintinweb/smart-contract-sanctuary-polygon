/**
 *Submitted for verification at polygonscan.com on 2022-03-23
*/

// File: contracts/ManufacturerManager.sol

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;



struct ManufacturerInfo {
uint40 companyPrefix;
bytes32 companyName;
uint expireTime;
bool isManufacturer;
}

contract MaufacturerManager{

    address private admin;
    
    constructor(){
        admin = msg.sender;
    }

    mapping (address => ManufacturerInfo) manufacturers;
    mapping (uint40 => address) companyPrefixToAddress;

    function enrollManufacturer(
    address m,                  //manufacturer Address
    uint40 companyPrefix, 
    bytes32 companyName,        //0x60298f78cc0b47170ba79c10aa3851d7648bd96f2f8e46a19dbc777c36fb0c00 - keccak256(solidity)
    uint validDurationInYear) 
    public onlyAdmin {
        manufacturers[m].companyPrefix =companyPrefix;
        manufacturers[m].companyName =companyName;
        manufacturers[m].expireTime = block.timestamp +validDurationInYear;
        manufacturers[m].isManufacturer = true;
        companyPrefixToAddress[companyPrefix] = m;
    }
    bool public isManufacturer;
    modifier onlyAdmin(){
        require(msg.sender==admin,"Not Admin");_;
    }

    function isValidManufacturer()
    external
    view
    returns (bool){
        return (manufacturers[tx.origin].isManufacturer==true);
        
    }

    function checkAuthorship(uint96 EPC)  
    public
    view
    returns(bool){
        //epc sent by the function, used to extract company prefix
        // console.log(msg.sender);
        uint40 companyPrefix = uint40(EPC);

        //comany prefix of sender, retreived from blockchain
        uint40 companyEpc = manufacturers[tx.origin].companyPrefix;
        
        if(companyPrefix == companyEpc){
            return true;
        }else{
            return false;}
    }

    function getManufacturerAddress(uint96 EPC)
    external 
    view 
    returns (address) {
        uint40 cp = uint40(EPC);
        return companyPrefixToAddress[cp];
    }

}

// File: contracts/ProductManager.sol

pragma solidity ^0.8.0;
// pragma experimental ABIEncoderV2;



interface IManufacturerManager {
    function checkAuthorship(uint96 EPC) external view returns (bool);

    function isValidManufacturer() external returns (bool);
}

contract ProductManager {

    event Transfer(address indexed from, address indexed to, uint96 EPC);

    enum ProductStatus {
        Shipped,
        Owned,
        Disposed
    }

    struct customerInfo {
        string name;
        string phone;
        uint96[] productsOwned;
        bool isCustomer;
    }
    mapping(address => customerInfo) CustomerOwnedItems;

    struct ProductInfo {
        address owner;
        address recipient;
        ProductStatus status;
        uint256 creationTime;
        uint8 nTransferred;
        bool isUsed;
    }

    uint256 private constant MAXTRANSFER = 5;
    mapping(uint96 => ProductInfo) products;

    modifier onlyNotExist(uint96 EPC) {
        //allow only non existing epc to be registered
        require(!products[EPC].isUsed, "EPC is alredy present");
        _;
    }
    modifier onlyManufacturer(address mmAddr) {
        bool isManufac = IManufacturerManager(mmAddr).isValidManufacturer();
        require(isManufac, "Not a manufacturer");
        _;
    }
    modifier onlyExist(uint96 EPC) {
        require(products[EPC].isUsed, "Product EPC does not exist");
        _;
    }
    modifier onlyOwner(uint96 EPC) {
        require(products[EPC].owner == msg.sender, "Not the original owner");
        _;
    }
    modifier onlyStatusIs(uint96 EPC, ProductStatus _status) {
        require(products[EPC].status == _status, "Status mismatch");
        _;
    }
    modifier onlyRecipient(uint96 EPC) {
        require(
            products[EPC].recipient == msg.sender,
            "Not authorised receiver"
        );
        _;
    }

    // add customer
    function createCustomer(string memory _name, string memory _phone)
        public
        payable
        returns (bool)
    {
        if (CustomerOwnedItems[msg.sender].isCustomer) {
            return false;
        }
        customerInfo memory newCustomer;
        newCustomer.name = _name;
        newCustomer.phone = _phone;
        newCustomer.isCustomer = true;

        CustomerOwnedItems[msg.sender] = newCustomer;
        return true;
    }

    function getCustomerDetails(address _addr)
        public
        view
        returns (customerInfo memory)
    {
        if (CustomerOwnedItems[_addr].isCustomer) {
            return (CustomerOwnedItems[_addr]);
        }else {
            return (CustomerOwnedItems[address(0x0)]);
        }
    }

    function enrollProduct(address mmAddr, uint96 EPC)
        public
        onlyNotExist(EPC)
        onlyManufacturer(mmAddr)
    {
        IManufacturerManager mm = IManufacturerManager(mmAddr);
        // MaufacturerManager mm = MaufacturerManager(mmAddr);
        // if (mm.checkAuthorship(EPC)) {
        require(mm.checkAuthorship(EPC), "Invalid check authorship");
        products[EPC].owner = tx.origin;
        products[EPC].status = ProductStatus.Owned;
        products[EPC].creationTime = block.timestamp;
        products[EPC].nTransferred = 0;
        products[EPC].isUsed = true;
        emit Transfer(address(0), msg.sender, EPC);
        // }
    }

    function shipProduct(address recipient, uint96 EPC)
        public
        onlyExist(EPC)
        onlyOwner(EPC)
        onlyStatusIs(EPC, ProductStatus.Owned)
    {
        // require(recipient == products[EPC].owner);
        products[EPC].status = ProductStatus.Shipped;
        products[EPC].recipient = recipient;
    }

    function receiveProduct(uint96 EPC)
        public
        onlyExist(EPC)
        onlyRecipient(EPC)
        onlyStatusIs(EPC, ProductStatus.Shipped)
    {
        emit Transfer(products[EPC].owner,msg.sender, EPC);
        products[EPC].owner = msg.sender;
        products[EPC].status = ProductStatus.Owned;
        products[EPC].nTransferred = products[EPC].nTransferred + 1;
        CustomerOwnedItems[msg.sender].productsOwned.push(EPC);
        // CustomerOwnedItems[msg.sender].productsOwned.push(products[EPC]);
        // return true;
        // if (products[EPC].nTransferred <= MAXTRANSFER) {
        // msg.sender.send(transferReward);
        // }
    }

    function getCurrentOwner(uint96 EPC)
        public
        view
        onlyExist(EPC)
        returns (address)
    {
        return products[EPC].owner;
    }

    function getRecipient(uint96 EPC)
        public
        view
        onlyExist(EPC)
        onlyStatusIs(EPC, ProductStatus.Shipped)
        returns (address)
    {
        return products[EPC].recipient;
    }

    function getProductStatus(uint96 EPC)
        public
        view
        onlyExist(EPC)
        returns (ProductStatus)
    {
        return products[EPC].status;
    }
}