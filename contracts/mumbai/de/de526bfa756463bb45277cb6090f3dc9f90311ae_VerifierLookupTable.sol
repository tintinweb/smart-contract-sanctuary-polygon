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
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
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
// OpenZeppelin Contracts (last updated v4.8.0) (access/Ownable2Step.sol)

pragma solidity ^0.8.0;

import "./Ownable.sol";

/**
 * @dev Contract module which provides access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership} and {acceptOwnership}.
 *
 * This module is used through inheritance. It will make available all functions
 * from parent (Ownable).
 */
abstract contract Ownable2Step is Ownable {
    address private _pendingOwner;

    event OwnershipTransferStarted(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Returns the address of the pending owner.
     */
    function pendingOwner() public view virtual returns (address) {
        return _pendingOwner;
    }

    /**
     * @dev Starts the ownership transfer of the contract to a new account. Replaces the pending transfer if there is one.
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual override onlyOwner {
        _pendingOwner = newOwner;
        emit OwnershipTransferStarted(owner(), newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`) and deletes any pending owner.
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual override {
        delete _pendingOwner;
        super._transferOwnership(newOwner);
    }

    /**
     * @dev The new owner accepts the ownership transfer.
     */
    function acceptOwnership() public virtual {
        address sender = _msgSender();
        require(pendingOwner() == sender, "Ownable2Step: caller is not the new owner");
        _transferOwnership(sender);
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
pragma solidity ^0.8.19;

import {Ownable2Step} from "openzeppelin-contracts/access/Ownable2Step.sol";

import {ITreeVerifier} from "../interfaces/ITreeVerifier.sol";

/// @title Batch Lookup Table
/// @author Worldcoin
/// @notice A table that provides the correct tree verifier based on the provided batch size.
/// @dev It should be used to query the correct verifier before using that verifier for verifying a
///      tree modification proof.
contract VerifierLookupTable is Ownable2Step {
    ////////////////////////////////////////////////////////////////////////////////
    ///                                   DATA                                   ///
    ////////////////////////////////////////////////////////////////////////////////

    /// The null address.
    address internal constant nullAddress = address(0x0);

    /// The null verifier.
    ITreeVerifier internal constant nullVerifier = ITreeVerifier(nullAddress);

    /// The lookup table for routing batches.
    ///
    /// As we expect to only have a few batch sizes per contract, a mapping is used due to its
    /// natively sparse storage.
    mapping(uint256 => ITreeVerifier) internal verifier_lut;

    ////////////////////////////////////////////////////////////////////////////////
    ///                                  ERRORS                                  ///
    ////////////////////////////////////////////////////////////////////////////////

    /// @notice Raised if a batch size is requested that the lookup table doesn't know about.
    error NoSuchVerifier();

    /// @notice Raised if an attempt is made to add a verifier for a batch size that already exists.
    error VerifierExists();

    /// @notice Thrown when an attempt is made to renounce ownership.
    error CannotRenounceOwnership();

    ////////////////////////////////////////////////////////////////////////////////
    ///                                  EVENTS                                  ///
    ////////////////////////////////////////////////////////////////////////////////

    /// @notice Emitted when a verifier is added to the lookup table.
    ///
    /// @param batchSize The size of the batch that the verifier has been added for.
    /// @param verifierAddress The address of the verifier that was associated with `batchSize`.
    event VerifierAdded(uint256 indexed batchSize, address indexed verifierAddress);

    /// @notice Emitted when a verifier is updated in the lookup table.
    ///
    /// @param batchSize The size of the batch that the verifier has been updated for.
    /// @param oldVerifierAddress The address of the old verifier for `batchSize`.
    /// @param newVerifierAddress The address of the new verifier for `batchSize`.
    event VerifierUpdated(
        uint256 indexed batchSize,
        address indexed oldVerifierAddress,
        address indexed newVerifierAddress
    );

    /// @notice Emitted when a verifier is disabled in the lookup table.
    ///
    /// @param batchSize The batch size that had its verifier disabled.
    event VerifierDisabled(uint256 indexed batchSize);

    ////////////////////////////////////////////////////////////////////////////////
    ///                               CONSTRUCTION                               ///
    ////////////////////////////////////////////////////////////////////////////////

    /// @notice Constructs a new batch lookup table.
    /// @dev It is initially constructed without any verifiers.
    constructor() Ownable2Step() {}

    ////////////////////////////////////////////////////////////////////////////////
    ///                                ACCESSORS                                 ///
    ////////////////////////////////////////////////////////////////////////////////

    /// @notice Obtains the verifier for the provided `batchSize`.
    ///
    /// @param batchSize The batch size to get the associated verifier for.
    ///
    /// @return verifier The tree verifier for the provided `batchSize`.
    ///
    /// @custom:reverts NoSuchVerifier If there is no verifier associated with the `batchSize`.
    function getVerifierFor(uint256 batchSize) public view returns (ITreeVerifier verifier) {
        // Check the preconditions for querying the verifier.
        validateVerifier(batchSize);

        // With the preconditions checked, we can return the verifier.
        verifier = verifier_lut[batchSize];
    }

    /// @notice Adds a verifier for the provided `batchSize`.
    ///
    /// @param batchSize The batch size to add the verifier for.
    /// @param verifier The verifier for a batch of size `batchSize`.
    ///
    /// @custom:reverts VerifierExists If `batchSize` already has an associated verifier.
    /// @custom:reverts string If the caller is not the owner.
    function addVerifier(uint256 batchSize, ITreeVerifier verifier) public onlyOwner {
        // Check that there is no entry for that batch size.
        if (verifier_lut[batchSize] != nullVerifier) {
            revert VerifierExists();
        }

        // Add the verifier.
        updateVerifier(batchSize, verifier);
        emit VerifierAdded(batchSize, address(verifier));
    }

    /// @notice Updates the verifier for the provided `batchSize`.
    ///
    /// @param batchSize The batch size to add the verifier for.
    /// @param verifier The verifier for a batch of size `batchSize`.
    ///
    /// @return oldVerifier The old verifier instance associated with this batch size.
    ///
    /// @custom:reverts string If the caller is not the owner.
    function updateVerifier(uint256 batchSize, ITreeVerifier verifier)
        public
        onlyOwner
        returns (ITreeVerifier oldVerifier)
    {
        oldVerifier = verifier_lut[batchSize];
        verifier_lut[batchSize] = verifier;
        emit VerifierUpdated(batchSize, address(oldVerifier), address(verifier));
    }

    /// @notice Disables the verifier for the provided batch size.
    ///
    /// @param batchSize The batch size to disable the verifier for.
    ///
    /// @return oldVerifier The old verifier associated with the batch size.
    ///
    /// @custom:reverts string If the caller is not the owner.
    function disableVerifier(uint256 batchSize)
        public
        onlyOwner
        returns (ITreeVerifier oldVerifier)
    {
        oldVerifier = updateVerifier(batchSize, ITreeVerifier(nullAddress));
        emit VerifierDisabled(batchSize);
    }

    ////////////////////////////////////////////////////////////////////////////////
    ///                          INTERNAL FUNCTIONALITY                          ///
    ////////////////////////////////////////////////////////////////////////////////

    /// @notice Checks if the entry for the provided `batchSize` is a valid verifier.
    ///
    /// @param batchSize The batch size to check.
    ///
    /// @custom:reverts NoSuchVerifier If `batchSize` does not have an associated verifier.
    /// @custom:reverts BatchTooLarge If `batchSize` exceeds the maximum batch size.
    function validateVerifier(uint256 batchSize) internal view {
        if (verifier_lut[batchSize] == nullVerifier) {
            revert NoSuchVerifier();
        }
    }

    ////////////////////////////////////////////////////////////////////////////////
    ///                           OWNERSHIP MANAGEMENT                           ///
    ////////////////////////////////////////////////////////////////////////////////

    /// @notice Ensures that ownership of the lookup table cannot be renounced.
    /// @dev This function is intentionally not `virtual` as we do not want it to be possible to
    ///      renounce ownership for the lookup table.
    /// @dev This function is marked as `onlyOwner` to maintain the access restriction from the base
    ///      contract.
    function renounceOwnership() public view override onlyOwner {
        revert CannotRenounceOwnership();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/// @title Tree Verifier Interface
/// @author Worldcoin
/// @notice An interface representing a merkle tree verifier.
interface ITreeVerifier {
    /// @notice Verifies the provided proof data for the provided public inputs.
    /// @dev It is highly recommended that the implementation is restricted to `view` if possible.
    ///
    /// @param a The first G1Point of the proof (ar).
    /// @param b The G2Point for the proof (bs).
    /// @param c The second G1Point of the proof (kr).
    /// @param input The public inputs to the function, reduced such that it is a member of the
    ///              field `Fr` where `r` is `SNARK_SCALAR_FIELD`.
    ///
    /// @return result True if the proof verifies successfully, false otherwise.
    /// @custom:reverts string If the proof elements are not < `PRIME_Q` or if the `input` is not
    ///                 less than `SNARK_SCALAR_FIELD`.
    function verifyProof(
        uint256[2] memory a,
        uint256[2][2] memory b,
        uint256[2] memory c,
        uint256[1] memory input
    ) external returns (bool result);
}