// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./libraries/Ownable.sol";
import "./UniverseStorage.sol";
import "./interface/IUniverseStorage.sol";
import "./interface/IUniverseFactory.sol";

/**
 * Universe Factory Contract
 */
contract UniverseFactory is Ownable, UniverseFactoryEvents, UniverseFactoryStorage {
    /**
     * @dev return the length of list
     */
    function allPairLength() public view returns (uint256 length) {
        length = allStorageList.length;
    }

    /**
     * @dev Create Universe Storage Internal Function
     */
    function _createUniverseStorage(UserData memory personlData) internal returns (address newStorageAddress ) {
        // Create New Storage Contract
        bytes memory bytecode = type(UniverseStorage).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(personlData.userAddress));
        assembly {
            newStorageAddress := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        require(newStorageAddress != address(0), "UniverseFactory: Failed on Deploy");
        IUniverseStorage(newStorageAddress).initialize(personlData.userAddress, personlData.userData);

        // Update Storage List
        getStorage[personlData.userAddress] = newStorageAddress;
        allStorageList.push(newStorageAddress);

        emit StorageCreated(personlData.userAddress, newStorageAddress, allStorageList.length);
    }

    /**
     * @dev Create Single User's Storage Contract, only Owner of UniverseFactory call it
     */
    function createSingleUniverseStorage(UserData memory personlData) external onlyOwner returns (address newStorageAddress) {
        // Check Parameters
        require(personlData.userAddress != address(0), "UniverseFactory: ZERO_USER_ADDRESS");
        require(getStorage[personlData.userAddress] == address(0), "UniverseFactory: Storage Exist");

        // Create Universe Storage Contract
        newStorageAddress = _createUniverseStorage(personlData);
    }

    /**
     * @dev Create Bulk User's Storage Contracts, only Owner of UniverseFactory call it
     */
    function createBulkUniverseStorage(UserData[] memory userDataList) external onlyOwner {
        uint256 listLength = userDataList.length;

        // For Each Users
        for (uint256 i = 0; i < listLength; i += 1) {
            // Check User's Address is zero address & already exist Storage Address
            if (userDataList[i].userAddress != address(0) && 
                getStorage[userDataList[i].userAddress] == address(0)) {
                _createUniverseStorage(userDataList[i]);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.4;

import "./Context.sol";

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "./libraries/Context.sol";
import "./interface/IUniverseStorage.sol";

/**
 * Universe Storage Contract for User
 */
contract UniverseStorage is Context {
    mapping(address => bool) private accessAllowed;

    address public userAddress;
    address public immutable universeFactory;

    bytes[] private userEncryptedPersonalInfo;

    event SetUserData(uint setTime);

    constructor() {
        universeFactory = _msgSender();
    }

    /**
     * @dev Initialize Contract
     */
    function initialize(address _userAddress, bytes[] memory _userData) external {
        require(_msgSender() == universeFactory, "Universe: FORBIDDEN");
        userAddress = _userAddress;
        userEncryptedPersonalInfo = _userData;
        accessAllowed[_userAddress] = true;
    }

    /**
     * @dev Write User's Encryped Data on contract, only User call it
     */
    function writeUserData(bytes[] memory _inputData) external {
        require(msg.sender == userAddress, "Universe: Only Owner could write data");

        userEncryptedPersonalInfo = _inputData;

        emit SetUserData(block.timestamp);
    }

    /**
     * @dev Get User's Encryped Data on contract
     */
    function getUserData() external view returns (bytes[] memory info) {
        if(accessAllowed[msg.sender]) info = userEncryptedPersonalInfo;
    }

    /**
     * @dev Check User's Access Permission
     */
    function checkAllowance(address user) external view returns(bool allowed) {
        allowed = accessAllowed[user] ? true : false;
    }

    /**
     * @dev Set Permission to User
     */
    function setAllowance(address user, bool flag) external {
        require(msg.sender == userAddress, "Not user");
        
        accessAllowed[user] = flag;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IUniverseStorage {
    function initialize(address _userAddress, bytes[] memory _userData) external;

    function writeUserData(bytes[] memory _inputData) external;
    
    function getUserData() external view returns (bytes[] memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IUniverseFactory {
    function allPairLength() external view returns (uint256 length);
    function createSingleUniverseStorage(address userAddress) external returns (address newStorageAddress);
    function createBulkUniverseStorage(address[] memory userAddressList) external ;
}

contract UniverseFactoryEvents {
    /// @notice Created Storage Event
    event StorageCreated(address indexed userAddress, address indexed storageAddress, uint);
}

contract UniverseFactoryStorage {
    /// @notice Get Storage Mapping Variable, User Address => Storage Address
    mapping(address => address) public getStorage;

    /// @notice All Storage List Array
    address[] public allStorageList;

    /// @notice The structure of User Data
    struct UserData {
        /// @notice User's Address
        address userAddress;

        /// @notice User's Data Array
        bytes[] userData;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.4;

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