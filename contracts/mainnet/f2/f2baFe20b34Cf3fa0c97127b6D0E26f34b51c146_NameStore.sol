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

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";

contract NameStore is Ownable {
    mapping(uint256 => mapping(bytes32 => mapping(bytes32 => address))) public reservedNames;
    mapping(bytes32 => uint256) public reservedNamesVersion;

    mapping(bytes32 => bool) public registrationsPaused;

    event NameReserved(bytes32 indexed node, string name, address recipient);
    event ReservedNamesCleared(bytes32 indexed node);
    event RegistrationsPauseChanged(bytes32 indexed node, bool paused);

    function reserved(bytes32 node, bytes32 label) external view returns (address) {
        return reservedNames[reservedNamesVersion[node]][node][label];
    }

    function available(bytes32 node, bytes32 label) external view returns (bool) {
        return reservedNames[reservedNamesVersion[node]][node][label] == address(0) && !registrationsPaused[node];
    }

    function pauseRegistrations(bytes32 node) external onlyOwner {
        registrationsPaused[node] = true;
        emit RegistrationsPauseChanged(node, true);
    }

    function unpauseRegistrations(bytes32 node) external onlyOwner {
        registrationsPaused[node] = false;
        emit RegistrationsPauseChanged(node, false);
    }

    function reserve(bytes32 node, string calldata name, address recipient) external onlyOwner {
        _reserve(node, name, recipient);
    }

    function _reserve(bytes32 node, string calldata name, address recipient) internal {
        bytes32 label = keccak256(bytes(name));
        reservedNames[reservedNamesVersion[node]][node][label] = recipient;
        emit NameReserved(node, name, recipient);
    }

    function bulkReserve(bytes32 node, string[] calldata names, address[] calldata recipients) external onlyOwner {
        require(names.length == recipients.length, "Names and recipients must have the same length");
        for (uint i = 0; i < names.length; i++) {
            bytes32 label = keccak256(bytes(names[i]));
            reservedNames[reservedNamesVersion[node]][node][label] = recipients[i];
            emit NameReserved(node, names[i], recipients[i]);
        }
    }

    function clearReservedNames(bytes32 node) external onlyOwner {
        reservedNamesVersion[node]++;
        emit ReservedNamesCleared(node);
    }
}