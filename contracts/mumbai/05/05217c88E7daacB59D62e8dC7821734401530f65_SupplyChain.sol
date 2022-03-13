/**
 *Submitted for verification at polygonscan.com on 2022-03-12
*/

// File: @openzeppelin/contracts/utils/Strings.sol


// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

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

// File: contracts/SupplyChain.sol


pragma solidity ^0.8.0;



contract SupplyChain is Ownable {

    using Strings for uint;

    //companies
    struct Company {
        address addr;
        string name;
        string domain;
        uint industry;
    }
    mapping(address => Company) company;
    Company[] companies;
    uint numberOfCompanies;
    string[] industries = [
        "Food & Beverage",
        "Technology",
        "Vehicles",
        "Boats",
        "Apparel",
        "Planes",
        "Textile",
        "Forniture",
        "Machinery",
        "Agricolture",
        "Travel",
        "Construction",
        "Pharmaceutical",
        "Cosmetics",
        "Healthcare",
        "Chemical",
        "Culture"
    ];

    //products
    struct Product {
        address company;
        string name;
        string info;
        string code;
    }   
    struct ReducedProduct {
        uint id;
        string name;
        string code;
    }
    uint nextProductId;
    uint numberOfProducts;
    Product[] products;
    mapping(address => ReducedProduct[]) myProducts;

    //supppliers and clients
    mapping(string => address) supplyRequest; //who requested the parent-child link
    mapping(string => address) supplyConfirm; //who confirmed the parent-child link
    mapping(uint => ReducedProduct[]) supplierList; //suppliers (confirmed or not)
    mapping(uint => ReducedProduct[]) clientList; //clients (confirmed or not)
    mapping(uint => ReducedProduct[]) pendingSupplierList; //suppliers to confirm
    mapping(uint => ReducedProduct[]) pendingClientList; //clients to confirm
    mapping(uint => ReducedProduct[]) suppliers; //confirmed suppliers
    mapping(uint => ReducedProduct[]) clients; //confirmed clients

    //fees
    address wallet;
    uint newCompanyFee;
    uint newProductFee;
    uint supplyFee;
    mapping(address => bool) noFee; //companies that do not pay any fees

    //events
    event NewCompany(
        uint indexed date,
        string name,
        string domain
    );
    event NewProduct(
        uint indexed date,
        uint indexed productId,
        string name
    );
    event NewSupplier(
        uint indexed date,
        uint indexed parentId,
        uint indexed childId
    );

    constructor(uint _newCompanyFee, uint _newProductFee, uint _supplyFee) {
        numberOfCompanies = 0;
        numberOfProducts = 0;
        nextProductId = 0;
        wallet = msg.sender;
        newCompanyFee = _newCompanyFee;
        newProductFee = _newProductFee;
        supplyFee = _supplyFee;
    }

    /* companies */

    function addCompany(string memory _name, string memory _domain, uint _industry) external payable {
        require(bytes(_name).length > 0, "Empty name");
        require(bytes(_domain).length > 0, "Empty domain");
        require(industries.length > _industry, "Wrong industry index");
        require(bytes(company[msg.sender].name).length == 0, "Company already added");
        if (noFee[msg.sender]) require(msg.value == 0, "Wrong fee amount: you do not pay any fees");
        else require(msg.value == newCompanyFee, "Wrong fee amount");
        company[msg.sender] = Company({
            addr: msg.sender,
            name: _name,
            domain: _domain,
            industry: _industry
        });
        companies.push(Company({
            addr: msg.sender,
            name: _name,
            domain: _domain,
            industry: _industry
        }));
        payable(wallet).transfer(msg.value);
        emit NewCompany(block.timestamp, _name, _domain);
        numberOfCompanies++;
    }

    function getNumberOfCompanies() external view returns(uint) {
        return numberOfCompanies;
    }

    function getAllCompanies() external view returns(Company[] memory) {
        return companies;
    }

    function getCompany(address _addr) external view returns(Company memory) {
        return company[_addr];
    }

    function addIndustry(string memory _industry) external onlyOwner {
        industries.push(_industry);
    }

    function getIndustries() external view returns(string[] memory) {
        return industries;
    }

    function getIndustry(uint _index) external view returns(string memory) {
        return industries[_index];
    }

    /* products */

    function addProduct(string memory _name, string memory _info, string memory _code) external payable {
        require(bytes(_name).length > 0, "Empty name");
        require(bytes(_info).length > 0, "Empty info");
        require(bytes(_code).length > 0, "Empty code");
        if (noFee[msg.sender]) require(msg.value == 0, "Wrong fee amount: you do not pay any fees");
        else require(msg.value == newProductFee, "Wrong fee amount");
        products.push(Product({
            company: msg.sender,
            name: _name,
            info: _info,
            code: _code        
        }));
        myProducts[msg.sender].push(ReducedProduct({
            id: nextProductId,
            name: _name,
            code: _code
        }));
        payable(wallet).transfer(msg.value);
        emit NewProduct(block.timestamp, nextProductId, _name);
        numberOfProducts++;
        nextProductId++;
    }

    function getNumberOfProducts() external view returns(uint) {
        return numberOfProducts;
    }

    function getMyProducts(address _addr) external view returns(ReducedProduct[] memory) {
        return myProducts[_addr];
    }

    function getProduct(uint _productId) external view returns(Product memory) {
        require(_productId < products.length, "Non-existent product");
        return products[_productId];
    }

    /* suppliers and clients */

    function addSupplier(uint _parent, uint _child, uint _operation) external payable {
        require(_parent != _child, "Parent cannot be the same as child");
        require(_parent < products.length && _child < products.length, "Non-existent product(s)");
        require(products[_parent].company == msg.sender || products[_child].company == msg.sender, "Not a product of yours");
        require(products[_parent].company != products[_child].company, "Supplier must come from another company");
        if (noFee[msg.sender]) require(msg.value == 0, "Wrong fee amount: you do not pay any fees");
        else require(msg.value == supplyFee, "Wrong fee amount");
        payable(wallet).transfer(msg.value);
        //request
        if (supplyRequest[uintConcatenate(_parent, _child)] == address(0)) {
            supplyRequest[uintConcatenate(_parent, _child)] = msg.sender;
            //adding a supplier
            if(_operation == 1) {
                supplierList[_parent].push(ReducedProduct({
                    id: _child,
                    name: products[_child].name,
                    code: products[_child].code
                }));
                pendingClientList[_child].push(ReducedProduct({
                    id: _parent,
                    name: products[_parent].name,
                    code: products[_parent].code
                }));
            }
            //adding a client
            else if(_operation == 2) {
                clientList[_child].push(ReducedProduct({
                    id: _parent,
                    name: products[_parent].name,
                    code: products[_parent].code
                }));
                pendingSupplierList[_parent].push(ReducedProduct({
                    id: _child,
                    name: products[_child].name,
                    code: products[_child].code
                }));
            }
        } 
        //confirmation
        else {
            require(supplyRequest[uintConcatenate(_parent, _child)] != msg.sender, "Confirmator must be different from Requestor");
            require(supplyConfirm[uintConcatenate(_parent, _child)] == address(0), "Already confirmed");
            supplyConfirm[uintConcatenate(_parent, _child)] = msg.sender;
            //adding a supplier
            if(_operation == 1) {
                supplierList[_parent].push(ReducedProduct({
                    id: _child,
                    name: products[_child].name,
                    code: products[_child].code
                }));
            }
            //adding a client
            else if(_operation == 2) {
                clientList[_child].push(ReducedProduct({
                    id: _parent,
                    name: products[_parent].name,
                    code: products[_parent].code
                }));
            }
            //supply chain confirmed
            suppliers[_parent].push(ReducedProduct({
                id: _child,
                name: products[_child].name,
                code: products[_child].code
            }));
            clients[_child].push(ReducedProduct({
                id: _parent,
                name: products[_parent].name,
                code: products[_parent].code
            }));
            emit NewSupplier(block.timestamp, _parent, _child);
        }
    }

    function getSupplyRequestor(uint _parent, uint _child) external view returns(address) {
        return supplyRequest[uintConcatenate(_parent, _child)];
    }

    function getSupplyConfirmator(uint _parent, uint _child) external view returns(address) {
        return supplyConfirm[uintConcatenate(_parent, _child)];
    }

    function getSupplierList(uint _parent) external view returns(ReducedProduct[] memory) {
        return supplierList[_parent];
    }

    function getClientList(uint _child) external view returns(ReducedProduct[] memory) {
        return clientList[_child];
    }

    function getPendingSupplierList(uint _parent) external view returns(ReducedProduct[] memory) {
        return pendingSupplierList[_parent];
    }

    function getPendingClientList(uint _parent) external view returns(ReducedProduct[] memory) {
        return pendingClientList[_parent];
    }

    function getSuppliers(uint _parent) external view returns(ReducedProduct[] memory) {
        return suppliers[_parent];
    }

    function getClients(uint _child) external view returns(ReducedProduct[] memory) {
        return clients[_child];
    }

    /* fees */

    function setWallet(address _newAddress) external onlyOwner {
        wallet = _newAddress;
    }

    function getWallet() external view onlyOwner returns(address) {
        return wallet;
    }

    function setFees(uint _newCompanyFee, uint _newProductFee, uint _supplyFee) external onlyOwner {
        newCompanyFee = _newCompanyFee;
        newProductFee = _newProductFee;
        supplyFee = _supplyFee;
    }

    function getNewCompanyFee(address _addr) external view returns(uint) {
        if (noFee[_addr]) return 0;
        else return newCompanyFee;
    }

    function getNewProductFee(address _addr) external view returns(uint) {
        if (noFee[_addr]) return 0;
        else return newProductFee;
    }

    function getSupplyFee(address _addr) external view returns(uint) {
        if (noFee[_addr]) return 0;
        else return supplyFee;
    }

    function setNoFee(address _addr, bool _boolean) external onlyOwner {
        noFee[_addr] = _boolean;
    }

    function getNoFee(address _addr) external view onlyOwner returns(bool) {
        return noFee[_addr];
    }

    /* miscellaneous */

    function uintConcatenate(uint _a, uint _b) private pure returns(string memory) {
        return string(bytes.concat(bytes(_a.toString()), "-", bytes(_b.toString())));
    }
}