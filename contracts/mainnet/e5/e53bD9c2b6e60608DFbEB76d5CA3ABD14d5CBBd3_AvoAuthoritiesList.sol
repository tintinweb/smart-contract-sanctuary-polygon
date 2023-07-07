// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/structs/EnumerableSet.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableSet.js.

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableSet.
 * ====
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        bytes32[] memory store = _values(set._inner);
        bytes32[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

import { EnumerableSet } from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import { IAvoWalletV3 } from "./interfaces/IAvoWalletV3.sol";
import { IAvoFactory } from "./interfaces/IAvoFactory.sol";
import { IAvoAuthoritiesList } from "./interfaces/IAvoAuthoritiesList.sol";

// empty interface used for Natspec docs for nice layout in automatically generated docs:
//
/// @title  AvoAuthoritiesList v3.0.0
/// @notice Tracks allowed authorities for AvoSafes, making available a list of all authorities
/// linked to an AvoSafe or all AvoSafes for a certain authority address.
///
/// If `trackInStorage` flag is set to false, then only an event will be emitted for off-chain tracking.
/// The contract itself will not track avoMultiSafes per signer!
///
/// Upgradeable through AvoAuthoritiesListProxy.
///
/// [email protected] Notes:_
/// In off-chain tracking, make sure to check for duplicates (i.e. mapping already exists).
/// This should not happen but when not tracking the data on-chain there is no way to be sure.
interface AvoAuthoritiesList_V3 {

}

abstract contract AvoAuthoritiesListErrors {
    /// @notice thrown when a method is called with invalid params (e.g. zero address)
    error AvoAuthoritiesList__InvalidParams();

    /// @notice thrown when a view method is called that would require storage mapping data,
    /// but the flag `trackInStorage` is set to false and thus data is not available.
    error AvoAuthoritiesList__NotTracked();
}

abstract contract AvoAuthoritiesListConstants is AvoAuthoritiesListErrors {
    /// @notice AvoFactory used to confirm that an address is an Avocado smart wallet
    IAvoFactory public immutable avoFactory;

    /// @notice flag to signal if tracking should happen in storage or only events should be emitted (for off-chain).
    /// This can be set to false to reduce gas cost on expensive chains
    bool public immutable trackInStorage;

    /// @notice constructor sets the immutable `avoFactory` (proxy) address and the `trackInStorage` flag
    constructor(IAvoFactory avoFactory_, bool trackInStorage_) {
        if (address(avoFactory_) == address(0)) {
            revert AvoAuthoritiesList__InvalidParams();
        }
        avoFactory = avoFactory_;

        trackInStorage = trackInStorage_;
    }
}

abstract contract AvoAuthoritiesListVariables is AvoAuthoritiesListConstants {
    using EnumerableSet for EnumerableSet.AddressSet;

    /// @dev add a gap for slot 0 to 100 to easily inherit Initializable / OwnableUpgradeable etc. later on
    uint256[101] private __gap;

    // ---------------- slot 101 -----------------

    /// @notice tracks all AvoSafes mapped to an authority: authority => EnumerableSet AvoSafes list
    /// @dev mappings to a struct with a mapping can not be public because the getter function that Solidity automatically
    /// generates for public variables cannot handle the potentially infinite size caused by mappings within the structs.
    mapping(address => EnumerableSet.AddressSet) internal _safesPerAuthority;

    // ---------------- slot 102 -----------------

    /// @notice tracks all authorities mapped to an AvoSafe: AvoSafe => EnumerableSet authorities list
    mapping(address => EnumerableSet.AddressSet) internal _authoritiesPerSafe;
}

abstract contract AvoAuthoritiesListEvents {
    /// @notice emitted when a new authority <> AvoSafe mapping is added
    event AuthorityMappingAdded(address authority, address avoSafe);

    /// @notice emitted when an authority <> AvoSafe mapping is removed
    event AuthorityMappingRemoved(address authority, address avoSafe);
}

abstract contract AvoAuthoritiesListViews is AvoAuthoritiesListVariables {
    using EnumerableSet for EnumerableSet.AddressSet;

    /// @notice returns true if `authority_` is an allowed authority of `avoSafe_`
    function isAuthorityOf(address avoSafe_, address authority_) public view returns (bool) {
        if (trackInStorage) {
            return _safesPerAuthority[authority_].contains(avoSafe_);
        } else {
            return IAvoWalletV3(avoSafe_).isAuthority(authority_);
        }
    }

    /// @notice returns all authorities for a certain `avoSafe_`.
    /// reverts with `AvoAuthoritiesList__NotTracked()` if `trackInStorage` is set to false (data not available)
    function authorities(address avoSafe_) public view returns (address[] memory) {
        if (trackInStorage) {
            return _authoritiesPerSafe[avoSafe_].values();
        } else {
            revert AvoAuthoritiesList__NotTracked();
        }
    }

    /// @notice returns all avoSafes for a certain `authority_'.
    /// reverts with `AvoAuthoritiesList__NotTracked()` if `trackInStorage` is set to false (data not available)
    function avoSafes(address authority_) public view returns (address[] memory) {
        if (trackInStorage) {
            return _safesPerAuthority[authority_].values();
        } else {
            revert AvoAuthoritiesList__NotTracked();
        }
    }

    /// @notice returns the number of mapped authorities for a certain `avoSafe_'.
    /// reverts with `AvoAuthoritiesList__NotTracked()` if `trackInStorage` is set to false (data not available)
    function authoritiesCount(address avoSafe_) public view returns (uint256) {
        if (trackInStorage) {
            return _authoritiesPerSafe[avoSafe_].length();
        } else {
            revert AvoAuthoritiesList__NotTracked();
        }
    }

    /// @notice returns the number of mapped AvoSafes for a certain `authority_'.
    /// reverts with `AvoAuthoritiesList__NotTracked()` if `trackInStorage` is set to false (data not available)
    function avoSafesCount(address authority_) public view returns (uint256) {
        if (trackInStorage) {
            return _safesPerAuthority[authority_].length();
        } else {
            revert AvoAuthoritiesList__NotTracked();
        }
    }
}

contract AvoAuthoritiesList is
    AvoAuthoritiesListErrors,
    AvoAuthoritiesListConstants,
    AvoAuthoritiesListVariables,
    AvoAuthoritiesListEvents,
    AvoAuthoritiesListViews,
    IAvoAuthoritiesList
{
    using EnumerableSet for EnumerableSet.AddressSet;

    /// @notice constructor sets the immutable `avoFactory` (proxy) address and the `trackInStorage` flag
    constructor(
        IAvoFactory avoFactory_,
        bool trackInStorage_
    ) AvoAuthoritiesListConstants(avoFactory_, trackInStorage_) {}

    /// @inheritdoc IAvoAuthoritiesList
    function syncAvoAuthorityMappings(address avoSafe_, address[] calldata authorities_) external {
        // make sure `avoSafe_` is an actual AvoSafe
        if (avoFactory.isAvoSafe(avoSafe_) == false) {
            revert AvoAuthoritiesList__InvalidParams();
        }

        uint256 authoritiesLength_ = authorities_.length;

        bool isAuthority_;
        for (uint256 i; i < authoritiesLength_; ) {
            // check if authority is an allowed authority at the AvoWallet
            isAuthority_ = IAvoWalletV3(avoSafe_).isAuthority(authorities_[i]);

            if (isAuthority_) {
                if (trackInStorage) {
                    // `.add()` method also checks if authority is already mapped to the address
                    if (_safesPerAuthority[authorities_[i]].add(avoSafe_) == true) {
                        _authoritiesPerSafe[avoSafe_].add(authorities_[i]);
                        emit AuthorityMappingAdded(authorities_[i], avoSafe_);
                    }
                    // else ignore silently if mapping is already present
                } else {
                    emit AuthorityMappingAdded(authorities_[i], avoSafe_);
                }
            } else {
                if (trackInStorage) {
                    // `.remove()` method also checks if authority is not mapped to the address
                    if (_safesPerAuthority[authorities_[i]].remove(avoSafe_) == true) {
                        _authoritiesPerSafe[avoSafe_].remove(authorities_[i]);
                        emit AuthorityMappingRemoved(authorities_[i], avoSafe_);
                    }
                    // else ignore silently if mapping is not present
                } else {
                    emit AuthorityMappingRemoved(authorities_[i], avoSafe_);
                }
            }

            unchecked {
                ++i;
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

interface AvoCoreStructs {
    /// @notice a combination of a bytes signature and its signer.
    struct SignatureParams {
        ///
        /// @param signature ECDSA signature of `getSigDigest()` for default flow or EIP1271 smart contract signature
        bytes signature;
        ///
        /// @param signer signer of the signature. Can be set to smart contract address that supports EIP1271
        address signer;
    }

    /// @notice an arbitrary executable action
    struct Action {
        ///
        /// @param target the target address to execute the action on
        address target;
        ///
        /// @param data the calldata to be passed to the call for each target
        bytes data;
        ///
        /// @param value the msg.value to be passed to the call for each target. set to 0 if none
        uint256 value;
        ///
        /// @param operation type of operation to execute:
        /// 0 -> .call; 1 -> .delegateCall, 2 -> flashloan (via .call)
        uint256 operation;
    }

    /// @notice common params for both `cast()` and `castAuthorized()`
    struct CastParams {
        Action[] actions;
        ///
        /// @param id             Required:
        ///                       id for actions, e.g. 0 = CALL, 1 = MIXED (call and delegatecall),
        ///                                           20 = FLASHLOAN_CALL, 21 = FLASHLOAN_MIXED
        uint256 id;
        ///
        /// @param avoSafeNonce   Required:
        ///                       avoSafeNonce to be used for this tx. Must equal the avoSafeNonce value on smart
        ///                       wallet or alternatively it must be set to -1 to use a non-sequential nonce instead
        int256 avoSafeNonce;
        ///
        /// @param salt           Optional:
        ///                       Salt to customize non-sequential nonce (if `avoSafeNonce` is set to -1)
        bytes32 salt;
        ///
        /// @param source         Optional:
        ///                       Source / referral for this tx
        address source;
        ///
        /// @param metadata       Optional:
        ///                       metadata for any potential additional data to be tracked in the tx
        bytes metadata;
    }

    /// @notice `cast()` input params related to forwarding validity
    struct CastForwardParams {
        ///
        /// @param gas            Optional:
        ///                       As EIP-2770: user instructed minimum amount of gas that the relayer (AvoForwarder)
        ///                       must send for the execution. Sending less gas will fail the tx at the cost of the relayer.
        ///                       Also protects against potential gas griefing attacks
        ///                       See https://ronan.eth.limo/blog/ethereum-gas-dangers/
        uint256 gas;
        ///
        /// @param gasPrice       Optional:
        ///                       Not implemented / used yet
        uint256 gasPrice;
        ///
        /// @param validAfter     Optional:
        ///                       the earliest block timestamp that the request can be forwarded in,
        ///                       or 0 if the request is not time-limited to occur after a certain time.
        ///                       Protects against relayers executing a certain transaction at an earlier moment
        ///                       not intended by the user, where it might have a completely different effect.
        uint256 validAfter;
        ///
        /// @param validUntil     Optional:
        ///                       Similar to EIP-2770: the latest block timestamp (instead of block number) the request
        ///                       can be forwarded, or 0 if request should be valid forever.
        ///                       Protects against relayers executing a certain transaction at a later moment
        ///                       not intended by the user, where it might have a completely different effect.
        uint256 validUntil;
    }

    /// @notice `castAuthorized()` input params
    struct CastAuthorizedParams {
        ///
        /// @param maxFee         Optional:
        ///                       the maximum Avocado charge-up allowed to be paid for tx execution
        uint256 maxFee;
        ///
        /// @param gasPrice       Optional:
        ///                       Not implemented / used yet
        uint256 gasPrice;
        ///
        /// @param validAfter     Optional:
        ///                       the earliest block timestamp that the request can be forwarded in,
        ///                       or 0 if the request is not time-limited to occur after a certain time.
        ///                       Protects against relayers executing a certain transaction at an earlier moment
        ///                       not intended by the user, where it might have a completely different effect.
        ///                       Has no effect for AvoWallet (Solo), only used for AvoMultisig.
        uint256 validAfter;
        ///
        /// @param validUntil     Optional:
        ///                       Similar to EIP-2770: the latest block timestamp (instead of block number) the request
        ///                       can be forwarded, or 0 if request should be valid forever.
        ///                       Protects against relayers executing a certain transaction at a later moment
        ///                       not intended by the user, where it might have a completely different effect.
        ///                       Has no effect for AvoWallet (Solo), only used for AvoMultisig.
        uint256 validUntil;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

interface IAvoAuthoritiesList {
    /// @notice syncs mappings of `authorities_` to an AvoSafe `avoSafe_` based on the data present at the wallet.
    /// If `trackInStorage` flag is set to false, then only an event will be emitted for off-chain tracking.
    /// The contract itself will not track avoSafes per authority on-chain!
    ///
    /// Silently ignores `authorities_` that are already mapped correctly.
    ///
    /// There is expectedly no need for this method to be called by anyone other than the AvoSafe itself.
    ///
    /// @dev Note that in off-chain tracking make sure to check for duplicates (i.e. mapping already exists).
    /// This should not happen but when not tracking the data on-chain there is no way to be sure.
    function syncAvoAuthorityMappings(address avoSafe_, address[] calldata authorities_) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

import { IAvoVersionsRegistry } from "./IAvoVersionsRegistry.sol";

interface IAvoFactory {
    /// @notice returns AvoVersionsRegistry (proxy) address
    function avoVersionsRegistry() external view returns (IAvoVersionsRegistry);

    /// @notice returns Avo wallet logic contract address that new AvoSafe deployments point to
    function avoWalletImpl() external view returns (address);

    /// @notice returns AvoMultisig logic contract address that new AvoMultiSafe deployments point to
    function avoMultisigImpl() external view returns (address);

    /// @notice           Checks if a certain address is an Avocado smart wallet (AvoSafe or AvoMultisig).
    ///                   Only works for already deployed wallets.
    /// @param avoSafe_   address to check
    /// @return           true if address is an avoSafe
    function isAvoSafe(address avoSafe_) external view returns (bool);

    /// @notice                    Computes the deterministic address for `owner_` based on Create2
    /// @param owner_              AvoSafe owner
    /// @return computedAddress_   computed address for the contract (AvoSafe)
    function computeAddress(address owner_) external view returns (address computedAddress_);

    /// @notice                     Computes the deterministic Multisig address for `owner_` based on Create2
    /// @param owner_               AvoMultiSafe owner
    /// @return computedAddress_    computed address for the contract (AvoSafe)
    function computeAddressMultisig(address owner_) external view returns (address computedAddress_);

    /// @notice         Deploys an AvoSafe for a certain owner deterministcally using Create2.
    ///                 Does not check if contract at address already exists (AvoForwarder does that)
    /// @param owner_   AvoSafe owner
    /// @return         deployed address for the contract (AvoSafe)
    function deploy(address owner_) external returns (address);

    /// @notice                  Deploys a non-default version AvoSafe for an `owner_` deterministcally using Create2.
    ///                          ATTENTION: Only supports AvoWallet version > 2.0.0
    ///                          Does not check if contract at address already exists (AvoForwarder does that)
    /// @param owner_            AvoSafe owner
    /// @param avoWalletVersion_ Version of AvoWallet logic contract to deploy
    /// @return                  deployed address for the contract (AvoSafe)
    function deployWithVersion(address owner_, address avoWalletVersion_) external returns (address);

    /// @notice         Deploys an Avocado Multisig for a certain `owner_` deterministcally using Create2.
    ///                 Does not check if contract at address already exists (AvoForwarder does that)
    /// @param owner_   AvoMultiSafe owner
    /// @return         deployed address for the contract (AvoMultiSafe)
    function deployMultisig(address owner_) external returns (address);

    /// @notice                    Deploys an Avocado Multisig with non-default version for an `owner_`
    ///                            deterministcally using Create2.
    ///                            Does not check if contract at address already exists (AvoForwarder does that)
    /// @param owner_              AvoMultiSafe owner
    /// @param avoMultisigVersion_ Version of AvoMultisig logic contract to deploy
    /// @return                    deployed address for the contract (AvoMultiSafe)
    function deployMultisigWithVersion(address owner_, address avoMultisigVersion_) external returns (address);

    /// @notice                registry can update the current AvoWallet implementation contract set as default
    ///                        `_avoWalletImpl` logic contract address for new deployments
    /// @param avoWalletImpl_  the new avoWalletImpl address
    function setAvoWalletImpl(address avoWalletImpl_) external;

    /// @notice                 registry can update the current AvoMultisig implementation contract set as default
    ///                         `_avoMultisigImpl` logic contract address for new deployments
    /// @param avoMultisigImpl_ the new avoWalletImpl address
    function setAvoMultisigImpl(address avoMultisigImpl_) external;

    /// @notice returns the byteCode for the AvoSafe contract used for Create2 address computation
    function avoSafeBytecode() external view returns (bytes32);

    /// @notice returns the byteCode for the AvoMultiSafe contract used for Create2 address computation
    function avoMultiSafeBytecode() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

interface IAvoFeeCollector {
    /// @notice fee config params used to determine the fee for Avocado smart wallet `castAuthorized()` calls
    struct FeeConfig {
        /// @param feeCollector address that the fee should be paid to
        address payable feeCollector;
        /// @param mode current fee mode: 0 = percentage fee (gas cost markup); 1 = static fee (better for L2)
        uint8 mode;
        /// @param fee current fee amount:
        /// - for mode percentage: fee in 1e6 percentage (1e8 = 100%, 1e6 = 1%)
        /// - for static mode: absolute amount in native gas token to charge
        ///                    (max value 30_9485_009,821345068724781055 in 1e18)
        uint88 fee;
    }

    /// @notice calculates the `feeAmount_` for an AvoSafe (`msg.sender`) transaction `gasUsed_` based on
    ///         fee configuration present on the contract
    /// @param gasUsed_       amount of gas used, required if mode is percentage. not used if mode is static fee.
    /// @return feeAmount_    calculate fee amount to be paid
    /// @return feeCollector_ address to send the fee to
    function calcFee(uint256 gasUsed_) external view returns (uint256 feeAmount_, address payable feeCollector_);
}

interface IAvoVersionsRegistry is IAvoFeeCollector {
    /// @notice                   checks if an address is listed as allowed AvoWallet version, reverts if not.
    /// @param avoWalletVersion_  address of the Avo wallet logic contract to check
    function requireValidAvoWalletVersion(address avoWalletVersion_) external view;

    /// @notice                      checks if an address is listed as allowed AvoForwarder version, reverts if not.
    /// @param avoForwarderVersion_  address of the AvoForwarder logic contract to check
    function requireValidAvoForwarderVersion(address avoForwarderVersion_) external view;

    /// @notice                     checks if an address is listed as allowed AvoMultisig version, reverts if not.
    /// @param avoMultisigVersion_  address of the AvoMultisig logic contract to check
    function requireValidAvoMultisigVersion(address avoMultisigVersion_) external view;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

import { AvoCoreStructs } from "../AvoCore/AvoCoreStructs.sol";

// @dev base interface without getters for storage variables (to avoid overloads issues)
interface IAvoWalletV3Base is AvoCoreStructs {
    /// @notice        initializer called by AvoFactory after deployment, sets the `owner_` as owner
    /// @param owner_  the owner (immutable) of this smart wallet
    function initialize(address owner_) external;

    /// @notice                   initialize contract same as `initialize()` but also sets a different
    ///                           logic contract implementation address `avoWalletVersion_`
    /// @param owner_             the owner (immutable) of this smart wallet
    /// @param avoWalletVersion_  version of AvoMultisig logic contract to initialize
    function initializeWithVersion(address owner_, address avoWalletVersion_) external;

    /// @notice returns the domainSeparator for EIP712 signature
    function domainSeparatorV4() external view returns (bytes32);

    /// @notice                    returns non-sequential nonce that will be marked as used when the request with the
    ///                            matching `params_` and `authorizedParams_` is executed via `castAuthorized()`.
    /// @param params_             Cast params such as id, avoSafeNonce and actions to execute
    /// @param authorizedParams_   Cast params related to execution through owner such as maxFee
    /// @return                    bytes32 non sequential nonce
    function nonSequentialNonceAuthorized(
        CastParams calldata params_,
        CastAuthorizedParams calldata authorizedParams_
    ) external view returns (bytes32);

    /// @notice               gets the digest (hash) used to verify an EIP712 signature
    ///
    ///                       This is also used as the non-sequential nonce that will be marked as used when the
    ///                       request with the matching `params_` and `forwardParams_` is executed via `cast()`.
    /// @param params_        Cast params such as id, avoSafeNonce and actions to execute
    /// @param forwardParams_ Cast params related to validity of forwarding as instructed and signed
    /// @return               bytes32 digest to verify signature (or used as non-sequential nonce)
    function getSigDigest(
        CastParams calldata params_,
        CastForwardParams calldata forwardParams_
    ) external view returns (bytes32);

    /// @notice                 Verify the transaction signature is valid and can be executed.
    ///                         This does not guarantuee that the tx will not revert, simply that the params are valid.
    ///                         Does not revert and returns successfully if the input is valid.
    ///                         Reverts if input params, signature or avoSafeNonce etc. are invalid.
    /// @param params_          Cast params such as id, avoSafeNonce and actions to execute
    /// @param forwardParams_   Cast params related to validity of forwarding as instructed and signed
    /// @param signatureParams_ struct for signature and signer:
    ///                         - signature: the EIP712 signature, 65 bytes ECDSA signature for a default EOA.
    ///                           For smart contract signatures it must fulfill the requirements for the relevant
    ///                           smart contract `.isValidSignature()` EIP1271 logic
    ///                         - signer: address of the signature signer.
    ///                           Must match the actual signature signer or refer to the smart contract
    ///                           that must be an allowed signer and validates signature via EIP1271
    /// @return                 returns true if everything is valid, otherwise reverts
    function verify(
        CastParams calldata params_,
        CastForwardParams calldata forwardParams_,
        SignatureParams calldata signatureParams_
    ) external view returns (bool);

    /// @notice                 Executes arbitrary `actions_` with valid signature. Only executable by AvoForwarder.
    ///                         If one action fails, the transaction doesn't revert, instead emits the `CastFailed` event.
    ///                         In that case, all previous actions are reverted.
    ///                         On success, emits CastExecuted event.
    /// @dev                    validates EIP712 signature then executes each action via .call or .delegatecall
    /// @param params_          Cast params such as id, avoSafeNonce and actions to execute
    /// @param forwardParams_   Cast params related to validity of forwarding as instructed and signed
    /// @param signatureParams_ struct for signature and signer:
    ///                         - signature: the EIP712 signature, 65 bytes ECDSA signature for a default EOA.
    ///                           For smart contract signatures it must fulfill the requirements for the relevant
    ///                           smart contract `.isValidSignature()` EIP1271 logic
    ///                         - signer: address of the signature signer.
    ///                           Must match the actual signature signer or refer to the smart contract
    ///                           that must be an allowed signer and validates signature via EIP1271
    /// @return success         true if all actions were executed succesfully, false otherwise.
    /// @return revertReason    revert reason if one of the actions fails in the following format:
    ///                         The revert reason will be prefixed with the index of the action.
    ///                         e.g. if action 1 fails, then the reason will be "1_reason".
    ///                         if an action in the flashloan callback fails (or an otherwise nested action),
    ///                         it will be prefixed with with two numbers: "1_2_reason".
    ///                         e.g. if action 1 is the flashloan, and action 2 of flashloan actions fails,
    ///                         the reason will be 1_2_reason.
    function cast(
        CastParams calldata params_,
        CastForwardParams calldata forwardParams_,
        SignatureParams calldata signatureParams_
    ) external payable returns (bool success, string memory revertReason);

    /// @notice                  Executes arbitrary `actions_` through authorized transaction sent by owner.
    ///                          Includes a fee in native network gas token, amount depends on registry `calcFee()`.
    ///                          If one action fails, the transaction doesn't revert, instead emits the `CastFailed` event.
    ///                          In that case, all previous actions are reverted.
    ///                          On success, emits CastExecuted event.
    /// @dev                     executes a .call or .delegateCall for every action (depending on params)
    /// @param params_           Cast params such as id, avoSafeNonce and actions to execute
    /// @param authorizedParams_ Cast params related to execution through owner such as maxFee
    /// @return success          true if all actions were executed succesfully, false otherwise.
    /// @return revertReason     revert reason if one of the actions fails in the following format:
    ///                          The revert reason will be prefixed with the index of the action.
    ///                          e.g. if action 1 fails, then the reason will be "1_reason".
    ///                          if an action in the flashloan callback fails (or an otherwise nested action),
    ///                          it will be prefixed with with two numbers: "1_2_reason".
    ///                          e.g. if action 1 is the flashloan, and action 2 of flashloan actions fails,
    ///                          the reason will be 1_2_reason.
    function castAuthorized(
        CastParams calldata params_,
        CastAuthorizedParams calldata authorizedParams_
    ) external payable returns (bool success, string memory revertReason);

    /// @notice checks if an address `authority_` is an allowed authority (returns true if allowed)
    function isAuthority(address authority_) external view returns (bool);
}

// @dev full interface with some getters for storage variables
interface IAvoWalletV3 is IAvoWalletV3Base {
    /// @notice AvoWallet Owner
    function owner() external view returns (address);

    /// @notice Domain separator name for signatures
    function DOMAIN_SEPARATOR_NAME() external view returns (string memory);

    /// @notice Domain separator version for signatures
    function DOMAIN_SEPARATOR_VERSION() external view returns (string memory);

    /// @notice incrementing nonce for each valid tx executed (to ensure uniqueness)
    function avoSafeNonce() external view returns (uint88);
}