// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./libraries/UnorderedKeySetLib.sol";
import "./interfaces/IMasterPiece.sol";


contract MasterPiece is Ownable, IMasterPiece {

    using UnorderedKeySetLib for UnorderedKeySetLib.Set;
    UnorderedKeySetLib.Set masterPieceSet;

    mapping(bytes32 => masterPieceStruct) private _masterPieces;

    function add(bytes32 key, masterPieceStruct memory masterPiece) public onlyOwner {
        masterPieceSet.insert(key);
        // Note that this will fail automatically if the key already exists.
        masterPieceStruct storage m = _masterPieces[key];
        m.key = key;
        m.maxSupply = masterPiece.maxSupply;
        m.feesBasisPoints = masterPiece.feesBasisPoints;
        m.floorPrice = masterPiece.floorPrice;
        m.name = masterPiece.name;
        m.description = masterPiece.description;
        m.museumKey = masterPiece.museumKey;
        m.museumName = masterPiece.museumName;
        m.museumDate = masterPiece.museumDate;
        m.museumId = masterPiece.museumId;
        m.museumCollection = masterPiece.museumCollection;
        m.artistName = masterPiece.artistName;
        m.artistNationality = masterPiece.artistNationality;
        m.artistBirthDeath = masterPiece.artistBirthDeath;
        m.creationDate = masterPiece.creationDate;
        m.period = masterPiece.period;
        m.style = masterPiece.style;
        m.category = masterPiece.category;
        m.uri = masterPiece.uri;

        emit LogNewMasterPiece(msg.sender, key, m);
    }

    function update(bytes32 key, masterPieceStruct memory masterpiece) public onlyOwner {
        require(masterPieceSet.exists(key), "bad key");
        masterPieceStruct storage m = _masterPieces[key];

        m.name = (bytes(masterpiece.name).length > 0) ? masterpiece.name : m.name;
        m.description = (bytes(masterpiece.description).length > 0) ? masterpiece.description : m.description;
        // TODO maybe check if the museum exists?
        // TODO maybe handle the masterPiece relationship update by calling the museumContract removeMasterPiece / addMasterPiece functions?
        m.museumKey = (masterpiece.museumKey.length > 0) ? masterpiece.museumKey : m.museumKey;
        m.museumName = (bytes(masterpiece.museumName).length > 0) ? masterpiece.museumName : m.museumName;
        m.museumDate = (bytes(masterpiece.museumDate).length > 0) ? masterpiece.museumDate : m.museumDate;
        m.museumId = (bytes(masterpiece.museumId).length > 0) ? masterpiece.museumId : m.museumId;
        m.museumCollection = (bytes(masterpiece.museumCollection).length > 0) ? masterpiece.museumCollection : m.museumCollection;
        m.artistName = (bytes(masterpiece.artistName).length > 0) ? masterpiece.artistName : m.artistName;
        m.artistNationality = (bytes(masterpiece.artistNationality).length > 0) ? masterpiece.artistNationality : m.artistNationality;
        m.artistBirthDeath = (bytes(masterpiece.artistBirthDeath).length > 0) ? masterpiece.artistBirthDeath : m.artistBirthDeath;
        m.creationDate = (bytes(masterpiece.creationDate).length > 0) ? masterpiece.creationDate : m.creationDate;
        m.period = (bytes(masterpiece.period).length > 0) ? masterpiece.period : m.period;
        m.style = (bytes(masterpiece.style).length > 0) ? masterpiece.style : m.style;
        m.category = (bytes(masterpiece.category).length > 0) ? masterpiece.category : m.category;
        m.uri = (bytes(masterpiece.uri).length > 0) ? masterpiece.uri : m.uri;
        m.floorPrice = (masterpiece.floorPrice > 0) ? masterpiece.floorPrice : m.floorPrice;
        m.feesBasisPoints = (masterpiece.feesBasisPoints > 0) ? masterpiece.feesBasisPoints : m.feesBasisPoints;
        m.maxSupply = (masterpiece.maxSupply > 0) ? masterpiece.maxSupply : m.maxSupply;

        emit LogUpdateMasterPiece(msg.sender, key, m);
    }

    function remove(bytes32 key) public onlyOwner {
        masterPieceSet.remove(key);
        // Note that this will fail automatically if the key doesn't exist
        delete _masterPieces[key];
        emit LogRemMasterPiece(msg.sender, key);
    }

    function get(bytes32 key) public view returns (masterPieceStruct memory masterPiece) {
        require(masterPieceSet.exists(key), "bad key");
        return _masterPieces[key];
    }

    function exist(bytes32 key) public view returns (bool) {
        return masterPieceSet.exists(key);
    }

    function count() public view returns (uint256) {
        return masterPieceSet.count();
    }

    function getAtIndex(uint index) public view returns (bytes32 key) {
        return masterPieceSet.keyAtIndex(index);
    }

    function all() public view returns (masterPieceStruct[] memory) {
        masterPieceStruct[] memory ret = new masterPieceStruct[](count());
        for (uint i = 0; i < count(); i++) {
            ret[i] = get(getAtIndex(i));
        }
        return ret;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

interface IMasterPiece {

    struct masterPieceStruct {
        bytes32 key;                // Unique identifier of the masterpiece.
        bytes32 museumKey;          // Unique identifier of the museum
        uint256 maxSupply;          // Max supply of the masterpiece, default to 30001
        uint256 feesBasisPoints;    // Commissions fees in percent * 100 (e.g. 25% is 2500)
        uint256 floorPrice;         // Minimum price in 2nd market in € cents: 15 € is saved as 1500
        string name;                // Titre de l’oeuvre
        string description;         // description de l’oeuvre
        string creationDate;        // date de création de l’oeuvre
        string museumName;          // nom du musée
        string museumId;            // identifiant museal de l’oeuvre
        string museumDate;          // date d’acquisition par le musée
        string museumCollection;    // collection de rattachement de l’oeuvre
        string artistName;          // nom de l’artiste
        string artistNationality;   // nationalité de l’artiste
        string artistBirthDeath;    // date de naissance de l’artiste (year) - date de décès de l’artiste (year)
        string period;              // période de l’oeuvre
        string style;               // style de l’oeuvre (ex. réalisme, expressionism, pointillisme, etc.)
        string category;            // catégorie de l’oeuvre (peinture, sculpture, etc.)
        string uri;                 // TokenUri de la MasterPiece
    }

    event LogNewMasterPiece(address sender, bytes32 key, masterPieceStruct masterPiece);
    event LogUpdateMasterPiece(address sender, bytes32 key, masterPieceStruct masterPiece);
    event LogRemMasterPiece(address sender, bytes32 key);

    function add(bytes32 key, masterPieceStruct memory masterPiece) external;

    function update(bytes32 key, masterPieceStruct memory masterPiece) external;

    function remove(bytes32 key) external;

    function get(bytes32 key) external view returns (masterPieceStruct memory masterPiece);

    function exist(bytes32 key) external view returns (bool);

    function count() external view returns (uint256);

    function getAtIndex(uint index) external view returns (bytes32 key);

    function all() external view returns (masterPieceStruct[] memory);
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