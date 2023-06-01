// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IContractRegistry.sol";

/// @title The Shoply Contract Registry
/// @dev This contract maintains contract addresses by name.
/// @dev Note that contract names are limited to 32 bytes UTF8 encoded ASCII strings to optimize gas costs
contract ContractRegistry is IContractRegistry, Ownable {
    struct RegistryItem {
        address contractAddress;
        uint256 nameIndex; // index of the item in the list of contract names
    }

    /// @notice The fee address
    address public feeAddress;
    /// @notice The wrapped native currency (e.g. weth)
    address public wrappedNative;

    // the mapping between contract names and RegistryItem items
    mapping(bytes32 => RegistryItem) private _items;
    mapping(address => address) private _priceDataFeed;

    /// @dev List of all contracts registered (append-only)
    string[] private _contractNames; // TODO: research internal vs private

    modifier nonZeroAddress(address _address) {
        if (_address == address(0)) {
            revert ZeroAddress();
        }
        _;
    }

    /// @notice Set the fee address
    /// @param _feeAddress The fee address
    function setFeeAddress(address _feeAddress) external onlyOwner nonZeroAddress(_feeAddress) {
        feeAddress = _feeAddress;
        emit FeeAddressSet(_feeAddress);
    }


    /// @notice Registers a new address for the contract name in the registry
    /// @param contractName The name of the contract
    /// @param contractAddress The address of the contract
    function registerAddress(bytes32 contractName, address contractAddress)
        external
        onlyOwner
        nonZeroAddress(contractAddress)
    {
        if (contractName.length == 0) {
            revert InvalidName();
        }

        // check if any change is needed
        address currentAddress = _items[contractName].contractAddress;
        if (contractAddress == currentAddress) {
            return;
        }

        if (currentAddress == address(0)) {
            // update the item's index in the list
            _items[contractName].nameIndex = _contractNames.length;

            // add the contract name to the name list
            _contractNames.push(_bytes32ToString(contractName));
        }

        // update the address in the registry
        _items[contractName].contractAddress = contractAddress;

        // dispatch the address update event
        emit AddressUpdate(contractName, contractAddress);
    }

    /// @notice Sets the price data feed for an array of tokens
    /// @param tokens An array of tokens
    /// @param dataFeeds An array of data feeds
    function setPriceDataFeeds(address[] calldata tokens, address[] calldata dataFeeds) external onlyOwner {
        if (tokens.length != dataFeeds.length) {
            revert InvalidArrayLengths();
        }

        for (uint256 i = 0; i < tokens.length; i++) {
            _priceDataFeed[tokens[i]] = dataFeeds[i];
        }
        emit PriceDataFeedsSet(tokens, dataFeeds);
    }

    /// @notice Sets the wrapped native currency address (e.g. weth)
    /// @param _wrappedNative The wrapped native currency address
    function setWrappedNative(address _wrappedNative) external onlyOwner {
        if (_wrappedNative == address(0)) {
            revert ZeroAddress();
        }
        wrappedNative = _wrappedNative;
        emit WrappedNativeSet(_wrappedNative);
    }

    /// @notice Returns the address of the price data feed for a token
    /// @param token The token
    /// @return The price data feed address for the token
    function priceDataFeed(address token) external view returns (address) {
        return _priceDataFeed[token];
    }

    /// @dev returns the number of items in the registry
    /// @return The number of contracts in the registry
    function itemCount() external view returns (uint256) {
        return _contractNames.length;
    }

    /// @notice Get the contract name of index `index`
    /// @param index The index of the contract name
    /// @dev returns a registered contract name
    /// @return A registered contract name
    function contractNames(uint256 index) external view returns (string memory) {
        return _contractNames[index];
    }

    /// @dev removes an existing contract address from the registry
    /// @param contractName The name of the contract
    function unregisterAddress(bytes32 contractName) external onlyOwner {
        if (contractName.length == 0 || _items[contractName].contractAddress == address(0)) {
            revert InvalidName();
        }

        // remove the address from the registry
        _items[contractName].contractAddress = address(0);

        // if there are multiple items in the registry, move the last element to the deleted element's position
        // and modify last element's registryItem.nameIndex in the items collection to point to the right position in contractNames
        if (_contractNames.length > 1) {
            string memory lastContractNameString = _contractNames[_contractNames.length - 1];
            uint256 unregisterIndex = _items[contractName].nameIndex;

            _contractNames[unregisterIndex] = lastContractNameString;
            bytes32 lastContractName = _stringToBytes32(lastContractNameString);
            RegistryItem storage registryItem = _items[lastContractName];
            registryItem.nameIndex = unregisterIndex;
        }

        // remove the last element from the name list
        _contractNames.pop();

        // zero the deleted element's index
        _items[contractName].nameIndex = 0;

        // dispatch the address update event
        emit AddressUpdate(contractName, address(0));
    }

    /// @dev returns the address associated with the given contract name
    /// @param contractName The name of the contract
    function addressOf(bytes32 contractName) external view override returns (address) {
        return _items[contractName].contractAddress;
    }

    /// @dev utility, converts bytes32 to a string
    /// @dev note that the bytes32 argument is assumed to be UTF8 encoded ASCII string
    /// @param data The bytes32 value to convert to a string
    function _bytes32ToString(bytes32 data) private pure returns (string memory) {
        bytes memory byteArray = new bytes(32);
        for (uint256 i = 0; i < 32; i++) {
            byteArray[i] = data[i];
        }

        return string(byteArray);
    }

    /// @dev utility, converts string to bytes32
    /// @param str The string to convert to bytes
    /// @dev note that the bytes32 argument is assumed to be UTF8 encoded ASCII string
    function _stringToBytes32(string memory str) private pure returns (bytes32) {
        bytes32 result;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            result := mload(add(str, 32))
        }

        return result;
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
pragma solidity ^0.8.17;

error ZeroAddress();
error InvalidAddress();
error InvalidName();
/// @notice Input arrays must be the same length
error InvalidArrayLengths();

/// @dev Contract Registry interface
interface IContractRegistry {

    /// @notice Emitted when an address pointed to by a contract name is modified
    /// @param contractName The contract name
    /// @param contractAddress The contract address
    event AddressUpdate(bytes32 indexed contractName, address contractAddress);
    
    /// @notice Emitted when the fee address is set
    /// @param feeAddress The fee address
    event FeeAddressSet(address feeAddress);

    /// @notice Emitted when price data feeds are set
    /// @param tokens An array of tokens
    /// @param feeds An array of data feeds
    event PriceDataFeedsSet(address[] tokens, address[] feeds);

    /// @notice Emitted when the wrapped native address is set
    /// @param wrappedNative The wrapped native address (e.g. weth)
    event WrappedNativeSet(address wrappedNative);

    function addressOf(bytes32 contractName) external view returns (address);
    function feeAddress() external view returns (address);
    function priceDataFeed(address token) external view returns (address);
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