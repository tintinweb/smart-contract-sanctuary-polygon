/**
 *Submitted for verification at polygonscan.com on 2023-06-28
*/

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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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

// File: SegMint_Addresses/SegMint_Addresses.sol



pragma solidity ^0.8.18;

interface ISegmintAddresses {
    /**
    * @notice Get SegmintERC1155 address.
    * @return The SegmintERC1155 address.
    */
    function getSegmintERC1155() external view returns (address);

    /**
    * @notice Get SegmintERC1155DB address.
    * @return The SegmintERC1155DB address.
    */
    function getSegmintERC1155DB() external view returns (address);

    /**
    * @notice Get SegmintERC1155PlatformManagement address.
    * @return The SegmintERC1155PlatformManagement address.
    */
    function getSegmintERC1155PlatformManagement() external view returns (address);

    /**
    * @notice Get SegmintERC1155WhitelistManagement address.
    * @return The SegmintERC1155WhitelistManagement address.
    */
    function getSegmintERC1155WhitelistManagement() external view returns (address);

    /**
    * @notice Get SegmintERC1155AssetProtection address.
    * @return The SegmintERC1155AssetProtection address.
    */
    function getSegmintERC1155AssetProtection() external view returns (address);

    /**
    * @notice Get SegmintERC1155FeeManagement address.
    * @return The SegmintERC1155FeeManagement address.
    */
    function getSegmintERC1155FeeManagement() external view returns (address);

    /**
    * @notice Get SegmintExchange address.
    * @return The SegmintExchange address.
    */
    function getSegmintExchange() external view returns (address);

    /**
    * @notice Get SegmintExchangeDB address.
    * @return The SegmintExchangeDB address.
    */
    function getSegmintExchangeDB() external view returns (address);

    /**
    * @notice Get SegmintKeyGenerator address.
    * @return The SegmintKeyGenerator address.
    */
    function getSegmintKeyGenerator() external view returns (address);

    /**
    * @notice Get SegmintKYC address.
    * @return The SegmintKYC address.
    */
    function getSegmintKYC() external view returns (address);

    /**
    * @notice Get SegmintERC721Factory address.
    * @return The SegmintERC721Factory address.
    */
    function getSegmintERC721Factory() external view returns (address);

    /**
    * @notice Get SegmintLockingFactory address.
    * @return The SegmintLockingFactory address.
    */
    function getSegmintLockingFactory() external view returns (address);
}


contract SegmintAddresses is ISegmintAddresses, Ownable {

    // Declare private address variables
    address private SegmintERC1155;
    address private SegmintERC1155DB;
    address private SegmintERC1155PlatformManagement;
    address private SegmintERC1155WhitelistManagement;
    address private SegmintERC1155AssetProtection;
    address private SegmintERC1155FeeManagement;
    address private SegmintExchange;
    address private SegmintExchangeDB;
    address private SegmintKeyGenerator;
    address private SegmintKYC;
    address private SegmintERC721Factory;
    address private SegmintLockingFactory;

    
    // Declare events
    event SegmintERC1155Updated(address indexed oldAddress, address indexed newAddress);
    event SegmintERC1155DBUpdated(address indexed oldAddress, address indexed newAddress);
    event SegmintERC1155PlatformManagementUpdated(address indexed oldAddress, address indexed newAddress);
    event SegmintERC1155WhitelistManagementUpdated(address indexed oldAddress, address indexed newAddress);
    event SegmintERC1155AssetProtectionUpdated(address indexed oldAddress, address indexed newAddress);
    event SegmintERC1155FeeManagementUpdated(address indexed oldAddress, address indexed newAddress);
    event SegmintExchangeUpdated(address indexed oldAddress, address indexed newAddress);
    event SegmintExchangeDBUpdated(address indexed oldAddress, address indexed newAddress);
    event SegmintKeyGeneratorUpdated(address indexed oldAddress, address indexed newAddress);
    event SegmintKYCUpdated(address indexed oldAddress, address indexed newAddress);
    event SegmintERC721FactoryUpdated(address indexed oldAddress, address indexed newAddress);
    event SegmintLockingFactoryUpdated(address indexed oldAddress, address indexed newAddress);


    // not Null Address
    modifier notNullAddress(address account_) {
        // require account not be the zero address
        require(
            account_ != address(0),
            "Address should be zero address"
        );
        _;
    }
    // Setters for each address - only callable by the owner
   
    /**
    * @notice Set SegmintERC1155 address.
    * @dev Only callable by the owner and ensures a non-zero address is passed.
    * @param SegmintERC1155_ The new SegmintERC1155 address.
    */
    function setSegmintERC1155(address SegmintERC1155_) external onlyOwner notNullAddress(SegmintERC1155_) {
        address previousSegmintERC1155 = SegmintERC1155;
        SegmintERC1155 = SegmintERC1155_;
        emit SegmintERC1155Updated(previousSegmintERC1155, SegmintERC1155_);
    }

    /**
    * @notice Set SegmintERC1155DB address.
    * @dev Only callable by the owner and ensures a non-zero address is passed.
    * @param SegmintERC1155DB_ The new SegmintERC1155DB address.
    */
    function setSegmintERC1155DB(address SegmintERC1155DB_) external onlyOwner notNullAddress(SegmintERC1155DB_) {
        address previousSegmintERC1155DB = SegmintERC1155DB;
        SegmintERC1155DB = SegmintERC1155DB_;
        emit SegmintERC1155DBUpdated(previousSegmintERC1155DB, SegmintERC1155DB_);
    }

    /**
    * @notice Set SegmintERC1155PlatformManagement address.
    * @dev Only callable by the owner and ensures a non-zero address is passed.
    * @param SegmintERC1155PlatformManagement_ The new SegmintERC1155PlatformManagement address.
    */
    function setSegmintERC1155PlatformManagement(address SegmintERC1155PlatformManagement_) external onlyOwner notNullAddress(SegmintERC1155PlatformManagement_) {
        address previousSegmintERC1155PlatformManagement = SegmintERC1155PlatformManagement;
        SegmintERC1155PlatformManagement = SegmintERC1155PlatformManagement_;
        emit SegmintERC1155PlatformManagementUpdated(previousSegmintERC1155PlatformManagement, SegmintERC1155PlatformManagement_);
    }

    /**
    * @notice Set SegmintERC1155WhitelistManagement address.
    * @dev Only callable by the owner and ensures a non-zero address is passed.
    * @param SegmintERC1155WhitelistManagement_ The new SegmintERC1155WhitelistManagement address.
    */
    function setSegmintERC1155WhitelistManagement(address SegmintERC1155WhitelistManagement_) external onlyOwner notNullAddress(SegmintERC1155WhitelistManagement_) {
        address previousSegmintERC1155WhitelistManagement = SegmintERC1155WhitelistManagement;
        SegmintERC1155WhitelistManagement = SegmintERC1155WhitelistManagement_;
        emit SegmintERC1155WhitelistManagementUpdated(previousSegmintERC1155WhitelistManagement, SegmintERC1155WhitelistManagement_);
    }

    /**
    * @notice Set SegmintERC1155AssetProtection address.
    * @dev Only callable by the owner and ensures a non-zero address is passed.
    * @param SegmintERC1155AssetProtection_ The new SegmintERC1155AssetProtection address.
    */
    function setSegmintERC1155AssetProtection(address SegmintERC1155AssetProtection_) external onlyOwner notNullAddress(SegmintERC1155AssetProtection_) {
        address previousSegmintERC1155AssetProtection = SegmintERC1155AssetProtection;
        SegmintERC1155AssetProtection = SegmintERC1155AssetProtection_;
        emit SegmintERC1155AssetProtectionUpdated(previousSegmintERC1155AssetProtection, SegmintERC1155AssetProtection_);
    }

    /**
    * @notice Set SegmintERC1155FeeManagement address.
    * @dev Only callable by the owner and ensures a non-zero address is passed.
    * @param SegmintERC1155FeeManagement_ The new SegmintERC1155FeeManagement address.
    */
    function setSegmintERC1155FeeManagement(address SegmintERC1155FeeManagement_) external onlyOwner notNullAddress(SegmintERC1155FeeManagement_) {
        address previousSegmintERC1155FeeManagement = SegmintERC1155FeeManagement;
        SegmintERC1155FeeManagement = SegmintERC1155FeeManagement_;
        emit SegmintERC1155FeeManagementUpdated(previousSegmintERC1155FeeManagement, SegmintERC1155FeeManagement_);
    }

    /**
    * @notice Set SegmintExchange address.
    * @dev Only callable by the owner and ensures a non-zero address is passed.
    * @param SegmintExchange_ The new SegmintExchange address.
    */
    function setSegmintExchange(address SegmintExchange_) external onlyOwner notNullAddress(SegmintExchange_) {
        address previousSegmintExchange = SegmintExchange;
        SegmintExchange = SegmintExchange_;
        emit SegmintExchangeUpdated(previousSegmintExchange, SegmintExchange_);
    }

    /**
    * @notice Set SegmintExchangeDB address.
    * @dev Only callable by the owner and ensures a non-zero address is passed.
    * @param SegmintExchangeDB_ The new SegmintExchangeDB address.
    */
    function setSegmintExchangeDB(address SegmintExchangeDB_) external onlyOwner notNullAddress(SegmintExchangeDB_) {
        address previousSegmintExchangeDB = SegmintExchangeDB;
        SegmintExchangeDB = SegmintExchangeDB_;
        emit SegmintExchangeDBUpdated(previousSegmintExchangeDB, SegmintExchangeDB_);
    }

    /**
    * @notice Set SegmintKeyGenerator address.
    * @dev Only callable by the owner and ensures a non-zero address is passed.
    * @param SegmintKeyGenerator_ The new SegmintKeyGenerator address.
    */
    function setSegmintKeyGenerator(address SegmintKeyGenerator_) external onlyOwner notNullAddress(SegmintKeyGenerator_) {
        address previousSegmintKeyGenerator = SegmintKeyGenerator;
        SegmintKeyGenerator = SegmintKeyGenerator_;
        emit SegmintKeyGeneratorUpdated(previousSegmintKeyGenerator, SegmintKeyGenerator_);
    }

    /**
    * @notice Set SegmintKYC address.
    * @dev Only callable by the owner and ensures a non-zero address is passed.
    * @param SegmintKYC_ The new SegmintKYC address.
    */
    function setSegmintKYC(address SegmintKYC_) external onlyOwner notNullAddress(SegmintKYC_) {
        address previousSegmintKYC = SegmintKYC;
        SegmintKYC = SegmintKYC_;
        emit SegmintKYCUpdated(previousSegmintKYC, SegmintKYC_);
    }

    /**
    * @notice Set SegmintERC721Factory address.
    * @dev Only callable by the owner and ensures a non-zero address is passed.
    * @param SegmintERC721Factory_ The new SegmintERC721Factory address.
    */
    function setSegmintERC721Factory(address SegmintERC721Factory_) external onlyOwner notNullAddress(SegmintERC721Factory_) {
        address previousSegmintERC721Factory = SegmintERC721Factory;
        SegmintERC721Factory = SegmintERC721Factory_;
        emit SegmintERC721FactoryUpdated(previousSegmintERC721Factory, SegmintERC721Factory_);
    }

    /**
    * @notice Set SegmintLockingFactory address.
    * @dev Only callable by the owner and ensures a non-zero address is passed.
    * @param SegmintLockingFactory_ The new SegmintLockingFactory address.
    */
    function setSegmintLockingFactory(address SegmintLockingFactory_) external onlyOwner notNullAddress(SegmintLockingFactory_) {
        address previousSegmintLockingFactory = SegmintLockingFactory;
        SegmintLockingFactory = SegmintLockingFactory_;
        emit SegmintLockingFactoryUpdated(previousSegmintLockingFactory, SegmintLockingFactory_);
    }


    // Getters for each address
    
        /**
    * @notice Get SegmintERC1155 address.
    * @return The SegmintERC1155 address.
    */
    function getSegmintERC1155() external view returns (address) {
        return SegmintERC1155;
    }

    /**
    * @notice Get SegmintERC1155DB address.
    * @return The SegmintERC1155DB address.
    */
    function getSegmintERC1155DB() external view returns (address) {
        return SegmintERC1155DB;
    }

    /**
    * @notice Get SegmintERC1155PlatformManagement address.
    * @return The SegmintERC1155PlatformManagement address.
    */
    function getSegmintERC1155PlatformManagement() external view returns (address) {
        return SegmintERC1155PlatformManagement;
    }

    /**
    * @notice Get SegmintERC1155WhitelistManagement address.
    * @return The SegmintERC1155WhitelistManagement address.
    */
    function getSegmintERC1155WhitelistManagement() external view returns (address) {
        return SegmintERC1155WhitelistManagement;
    }

    /**
    * @notice Get SegmintERC1155AssetProtection address.
    * @return The SegmintERC1155AssetProtection address.
    */
    function getSegmintERC1155AssetProtection() external view returns (address) {
        return SegmintERC1155AssetProtection;
    }

    /**
    * @notice Get SegmintERC1155FeeManagement address.
    * @return The SegmintERC1155FeeManagement address.
    */
    function getSegmintERC1155FeeManagement() external view returns (address) {
        return SegmintERC1155FeeManagement;
    }

    /**
    * @notice Get SegmintExchange address.
    * @return The SegmintExchange address.
    */
    function getSegmintExchange() external view returns (address) {
        return SegmintExchange;
    }

    /**
    * @notice Get SegmintExchangeDB address.
    * @return The SegmintExchangeDB address.
    */
    function getSegmintExchangeDB() external view returns (address) {
        return SegmintExchangeDB;
    }

    /**
    * @notice Get SegmintKeyGenerator address.
    * @return The SegmintKeyGenerator address.
    */
    function getSegmintKeyGenerator() external view returns (address) {
        return SegmintKeyGenerator;
    }

    /**
    * @notice Get SegmintKYC address.
    * @return The SegmintKYC address.
    */
    function getSegmintKYC() external view returns (address) {
        return SegmintKYC;
    }

    /**
    * @notice Get SegmintERC721Factory address.
    * @return The SegmintERC721Factory address.
    */
    function getSegmintERC721Factory() external view returns (address) {
        return SegmintERC721Factory;
    }

    /**
    * @notice Get SegmintLockingFactory address.
    * @return The SegmintLockingFactory address.
    */
    function getSegmintLockingFactory() external view returns (address) {
        return SegmintLockingFactory;
    }

}