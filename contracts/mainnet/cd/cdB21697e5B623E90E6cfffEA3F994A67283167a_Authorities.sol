// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IERC1271.sol";

contract Authorities is Ownable, IERC1271 {
    event AuthoritySet(address authority, PermOptions options);
    event SignatureSet(bytes32 _hash, bytes signature, address authority);
    event SignatureDisabled(bytes32 _hash, bytes signature, address authority);

    struct PermOptions {
        bool signing;
        bool ejecting;
    }

    modifier onlySigningAuthority() {
        require(isSigningAuthority(msg.sender), "Not a signing authority");
        _;
    }

    mapping(address => PermOptions) private permissions;
    mapping(bytes32 => mapping(bytes => address)) public validSignatures;

    function setAuthority(address _authority, PermOptions calldata status)
        external
        onlyOwner
    {
        permissions[_authority] = PermOptions(status.signing, status.ejecting);

        emit AuthoritySet(_authority, status);
    }

    function setSignature(bytes32 _hash, bytes memory signature)
        external
        onlySigningAuthority
    {
        validSignatures[_hash][signature] = msg.sender;

        emit SignatureSet(_hash, signature, msg.sender);
    }

    function disableSignature(bytes32 _hash, bytes memory signature)
        external
        onlySigningAuthority
    {
        validSignatures[_hash][signature] = address(0);

        emit SignatureDisabled(_hash, signature, msg.sender);
    }

    function isSigningAuthority(address _signingAuthority)
        public
        view
        returns (bool)
    {
        return permissions[_signingAuthority].signing;
    }

    function isEjectingAuthority(address _ejectingAuthority)
        external
        view
        returns (bool)
    {
        return permissions[_ejectingAuthority].ejecting;
    }

    function isValidSignature(bytes32 _hash, bytes memory signature)
        external
        view
        returns (bytes4 magicValue)
    {
        return (
            (validSignatures[_hash][signature] != address(0))
                ? bytes4(0x1626ba7e)
                : bytes4(0xffffffff)
        );
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// code borrowed from @uniswap/v3-periphery
pragma solidity ^0.8.0;

/// @title Interface for verifying contract-based account signatures
/// @notice Interface that verifies provided signature for the data
/// @dev Interface defined by EIP-1271
interface IERC1271 {
    /// @notice Returns whether the provided signature is valid for the provided data
    /// @dev MUST return the bytes4 magic value 0x1626ba7e when function passes.
    /// MUST NOT modify state (using STATICCALL for solc < 0.5, view modifier for solc > 0.5).
    /// MUST allow external calls.
    /// @param hash Hash of the data to be signed
    /// @param signature Signature byte array associated with _data
    /// @return magicValue The bytes4 magic value 0x1626ba7e
    function isValidSignature(bytes32 hash, bytes memory signature)
        external
        view
        returns (bytes4 magicValue);
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