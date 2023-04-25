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

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IAddressResolver.sol";
import "./MixinResolver.sol";

/**
 * @title This contract stores addresses that inherited contracts of the MixinResolver can use
 */
contract AddressResolver is Ownable, IAddressResolver {
    /// @dev Holds a mapping of hashes of contract names to the addresses.
    mapping(bytes32 => address) public repository;

    /**
     * @notice Adding contract addresses
     * @param names Array of the bytes of contract names
     * @param destinations Array of the contract addresses
     * @dev In the `names` array, need to be passed the bytes received as a result of calling
     * keccak256 for the name of the contact. For example keccak256(bytes("Deforex")).
     */
    function importAddresses(
        bytes32[] calldata names,
        address[] calldata destinations
    ) external onlyOwner {
        require(
            names.length == destinations.length,
            "Input lengths must match"
        );

        for (uint256 i = 0; i < names.length; i++) {
            bytes32 name = names[i];
            address destination = destinations[i];
            repository[name] = destination;
            // emit AddressImported(name, destination);
        }
    }

    /**
     * @dev Must be called for those contracts for which the addresses they use have been updated
     * @param destinations Addresses of contracts for which addresses have been updated
     */
    function rebuildCaches(MixinResolver[] calldata destinations) external {
        for (uint256 i = 0; i < destinations.length; i++) {
            destinations[i].rebuildCache();
        }
    }

    /**
     * @notice Checking if the contract address was previously imported
     * @param names Array of the bytes of contract names
     * @param destinations Array of the contract addresses
     * @return boolean that indicate are addresses imported
     * @dev In the `names` array, need to be passed the bytes received as a result of calling
     * keccak256 for the name of the contact. For example keccak256(bytes("Deforex")).
     */
    function areAddressesImported(
        bytes32[] calldata names,
        address[] calldata destinations
    ) external view returns (bool) {
        for (uint256 i = 0; i < names.length; i++) {
            if (repository[names[i]] != destinations[i]) {
                return false;
            }
        }
        return true;
    }

    /**
     * @notice Get contract address by name
     * @param name Contract name in bytes
     * @return address Address of the contract or address(0) if the contract was not imported
     * @dev `name` need to be passed in the bytes received as a result of calling keccak256 for
     * the name of the contact. For example keccak256(bytes("Deforex")).
     */
    function getAddress(bytes32 name) external view returns (address) {
        return repository[name];
    }

    /**
     * @notice Get the address of the contract, which must be imported before.
     * @param name Contract name in bytes
     * @param reason Error message in case of missing contract
     * @return address of the contract
     * @dev `name` need to be passed in the bytes received as a result of calling keccak256 for
     * the name of the contact. For example keccak256(bytes("Deforex")).
     */
    function requireAndGetAddress(bytes32 name, string calldata reason)
        external
        view
        returns (address)
    {
        address _foundAddress = repository[name];
        require(_foundAddress != address(0), reason);
        return _foundAddress;
    }

    event AddressImported(bytes32 name, address destination);
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.9;

interface IAddressResolver {
    function getAddress(bytes32 name) external view returns (address);

    function requireAndGetAddress(bytes32 name, string calldata reason)
        external
        view
        returns (address);
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.9;

import "./AddressResolver.sol";

/**
 * @title Gives inherited contracts the ability to work with AddressResolver and improves the
 * security of working with addresses. Reduces the chance of missing the necessary addresses in the
 * contracts.
 */

abstract contract MixinResolver {
    AddressResolver public resolver;

    /// @dev Holds a mapping of caches to the addresses.
    mapping(bytes32 => address) private addressCache;

    constructor(address _resolver) {
        resolver = AddressResolver(_resolver);
    }

    /// @return combination of the two arrays: `first` and `seond`
    function combineArrays(
        bytes32[] memory first,
        bytes32[] memory second
    ) internal pure returns (bytes32[] memory combination) {
        combination = new bytes32[](first.length + second.length);

        for (uint256 i = 0; i < first.length; i++) {
            combination[i] = first[i];
        }

        for (uint256 j = 0; j < second.length; j++) {
            combination[first.length + j] = second[j];
        }
    }

    // Note: this function is public not external in order for it to be overridden and invoked via super in subclasses
    function resolverAddressesRequired()
        public
        pure
        virtual
        returns (bytes32[] memory addresses)
    {}

    function _resolveAddressesFinish() internal virtual {}

    /**
     * @notice Checking for the necessary addresses
     * Emits a `CacheUpdated` event
     */
    function rebuildCache() public {
        bytes32[] memory requiredAddresses = resolverAddressesRequired();
        // The resolver must call this function whenver it updates its state
        for (uint256 i = 0; i < requiredAddresses.length; i++) {
            bytes32 name = requiredAddresses[i];
            // Note: can only be invoked once the resolver has all the targets needed added
            address destination = resolver.requireAndGetAddress(
                name,
                string(abi.encodePacked("Resolver missing target: ", name))
            );
            addressCache[name] = destination;
            emit CacheUpdated(name, destination);
        }

        _resolveAddressesFinish();
    }

    /**
     * @notice Checking if the call to the rebuildCache() method will succeed.
     * @dev This may be important as rebuildCache() may result in a revert
     */
    function isResolverCached() external view returns (bool) {
        bytes32[] memory requiredAddresses = resolverAddressesRequired();
        for (uint256 i = 0; i < requiredAddresses.length; i++) {
            bytes32 name = requiredAddresses[i];
            // false if our cache is invalid or if the resolver doesn't have the required address
            if (
                resolver.getAddress(name) != addressCache[name] ||
                addressCache[name] == address(0)
            ) {
                return false;
            }
        }

        return true;
    }

    /**
     * @dev Getting an address that must exist in the address cache
     */
    function requireAndGetAddress(
        bytes32 name
    ) internal view returns (address) {
        address _foundAddress = addressCache[name];
        require(
            _foundAddress != address(0),
            string(abi.encodePacked("Missing address: ", name))
        );
        return _foundAddress;
    }

    event CacheUpdated(bytes32 name, address destination);
}