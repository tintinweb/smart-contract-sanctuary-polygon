// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./libraries/UnorderedKeySetLib.sol";
import "./interfaces/IMasterBox.sol";


contract MasterBox is Ownable, IMasterBox {

    uint256 private constant DEFAULT_BOX_PRICE = 11000;  // 110€ in cents
    uint256 private constant DEFAULT_MAX_SUPPLY = 1000;
    uint256 private constant DEFAULT_MAX_PER_MINT = 1;
    uint256 private constant DEFAULT_MAX_MUSEUM_BY_RAFFLING = 3;
    uint256 private constant DEFAULT_FEES_BASIS_POINTS = 0; // 0%

    using UnorderedKeySetLib for UnorderedKeySetLib.Set;
    UnorderedKeySetLib.Set masterBoxKeys;

    mapping(bytes32 => masterBoxStruct) masterBoxes;

    function add(bytes32 key, masterBoxStruct memory masterBox) public onlyOwner {
        masterBoxKeys.insert(key);
        // Note that this will fail automatically if the key already exists.
        masterBoxStruct storage m = masterBoxes[key];
        m.key = key;
        m.name = masterBox.name;
        m.description = masterBox.description;
        m.artistName = masterBox.artistName;
        m.uri = masterBox.uri;
        m.creationDate = masterBox.creationDate;
        m.startSaleDate = masterBox.startSaleDate;
        m.endSaleDate = masterBox.endSaleDate;
        m.rafflingStartDate = masterBox.rafflingStartDate;
        m.rafflingEndDate = masterBox.rafflingEndDate;
        m.boxPrice = (masterBox.boxPrice != 0) ? masterBox.boxPrice : DEFAULT_BOX_PRICE;
        m.maxSupply = (masterBox.maxSupply != 0) ? masterBox.maxSupply : DEFAULT_MAX_SUPPLY;
        m.maxPerMint = (masterBox.maxPerMint != 0) ? masterBox.maxPerMint : DEFAULT_MAX_PER_MINT;
        m.maxMuseumByRaffling = (masterBox.maxMuseumByRaffling != 0) ? masterBox.maxMuseumByRaffling : DEFAULT_MAX_MUSEUM_BY_RAFFLING;
        m.feesBasisPoints = (masterBox.feesBasisPoints != 0) ? masterBox.feesBasisPoints : DEFAULT_FEES_BASIS_POINTS;

        emit LogNewMasterBox(msg.sender, key, m);
    }

    function update(bytes32 key, masterBoxStruct memory masterBox) public onlyOwner {
        require(masterBoxKeys.exists(key), "bad key");
        IMasterBox.masterBoxStruct storage m = masterBoxes[key];
        m.name = (bytes(masterBox.name).length > 0) ? masterBox.name : m.name;
        m.description = (bytes(masterBox.description).length > 0) ? masterBox.description : m.description;
        m.artistName = (bytes(masterBox.artistName).length > 0) ? masterBox.artistName : m.artistName;
        m.uri = (bytes(masterBox.uri).length > 0) ? masterBox.uri : m.uri;
        m.creationDate = (masterBox.creationDate != 0) ? masterBox.creationDate : m.creationDate;
        m.startSaleDate = (masterBox.startSaleDate != 0) ? masterBox.startSaleDate : m.startSaleDate;
        m.endSaleDate = (masterBox.endSaleDate != 0) ? masterBox.endSaleDate : m.endSaleDate;
        m.rafflingStartDate = (masterBox.rafflingStartDate != 0) ? masterBox.rafflingStartDate : m.rafflingStartDate;
        m.rafflingEndDate = (masterBox.rafflingEndDate != 0) ? masterBox.rafflingEndDate : m.rafflingEndDate;
        m.boxPrice = (masterBox.boxPrice != 0) ? masterBox.boxPrice : m.boxPrice;
        m.maxSupply = (masterBox.maxSupply != 0) ? masterBox.maxSupply : m.maxSupply;
        m.maxPerMint = (masterBox.maxPerMint != 0) ? masterBox.maxPerMint : m.maxPerMint;
        m.maxMuseumByRaffling = (masterBox.maxMuseumByRaffling != 0) ? masterBox.maxMuseumByRaffling : m.maxMuseumByRaffling;
        m.feesBasisPoints = (masterBox.feesBasisPoints != 0) ? masterBox.feesBasisPoints : m.feesBasisPoints;

        emit LogUpdateMasterBox(msg.sender, key, m);
    }

    function remove(bytes32 key) public onlyOwner {
        masterBoxKeys.remove(key);
        // Note that this will fail automatically if the key doesn't exist
        delete masterBoxes[key];
        emit LogRemMasterBox(msg.sender, key);
    }

    function get(bytes32 key) public view returns (masterBoxStruct memory) {
        require(masterBoxKeys.exists(key), "bad key");
        return masterBoxes[key];
    }

    function exist(bytes32 key) public view returns (bool){
        return masterBoxKeys.exists(key);
    }

    function count() public view returns (uint256) {
        return masterBoxKeys.count();
    }

    function getAtIndex(uint index) public view returns (bytes32 key) {
        return masterBoxKeys.keyAtIndex(index);
    }

    function all() public view returns (masterBoxStruct[] memory) {
        masterBoxStruct[] memory ret = new masterBoxStruct[](count());
        for (uint i = 0; i < count(); i++) {
            ret[i] = get(getAtIndex(i));
        }
        return ret;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library UnorderedKeySetLib {

    struct Set {
        mapping(bytes32 => uint) keyPointers;
        bytes32[] keyList;
    }

    function insert(Set storage self, bytes32 key) internal {
        require(key != 0x0, "UnorderedKeySet(100) - Key cannot be 0x0");
        require(!exists(self, key), "UnorderedKeySet(101) - Key already exists in the set.");
        self.keyList.push(key);
        self.keyPointers[key] = self.keyList.length - 1;
    }

    function remove(Set storage self, bytes32 key) internal {
        require(exists(self, key), "UnorderedKeySet(102) - Key does not exist in the set.");
        bytes32 keyToMove = self.keyList[count(self)-1];
        uint rowToReplace = self.keyPointers[key];
        self.keyPointers[keyToMove] = rowToReplace;
        self.keyList[rowToReplace] = keyToMove;
        delete self.keyPointers[key];
        self.keyList.pop();
    }

    function count(Set storage self) internal view returns(uint) {
        return(self.keyList.length);
    }

    function exists(Set storage self, bytes32 key) internal view returns(bool) {
        if(self.keyList.length == 0) return false;
        return self.keyList[self.keyPointers[key]] == key;
    }

    function keyAtIndex(Set storage self, uint index) internal view returns(bytes32) {
        return self.keyList[index];
    }

    function nukeSet(Set storage self) public {
        delete self.keyList;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

interface IMasterBox {

    struct masterBoxStruct {
        bytes32 key;
        uint256 creationDate;
        uint256 boxPrice;
        uint256 startSaleDate;
        uint256 endSaleDate;
        uint256 rafflingStartDate;
        uint256 rafflingEndDate;
        uint256 maxSupply;
        uint256 maxPerMint;
        uint256 maxMuseumByRaffling; // /!\ Max is 5 ! More and raffling can cost too much gaz and revert
        uint256 feesBasisPoints;     // Commissions fees in percent * 100 (e.g. 25% is 2500)
        string name;
        string description;
        string uri;
        string artistName;
    }

    event LogNewMasterBox(address sender, bytes32 key, masterBoxStruct masterBox);
    event LogUpdateMasterBox(address sender, bytes32 key, masterBoxStruct masterBox);
    event LogRemMasterBox(address sender, bytes32 key);

    function add(bytes32 key, masterBoxStruct memory masterBox) external;

    function update(bytes32 key, masterBoxStruct memory masterBox) external;

    function remove(bytes32 key) external;

    function get(bytes32 key) external view returns(masterBoxStruct memory masterBox);

    function exist(bytes32 key) external view returns (bool);

    function count() external view returns(uint256);

    function getAtIndex(uint index) external view returns(bytes32 key);

    function all() external view returns (masterBoxStruct[] memory masterBoxes);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

// SPDX-License-Identifier: MIT
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