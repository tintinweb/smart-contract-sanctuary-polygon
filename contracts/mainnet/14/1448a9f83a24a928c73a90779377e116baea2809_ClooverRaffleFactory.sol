// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";

import {ERC20, SafeTransferLib} from "@solmate/utils/SafeTransferLib.sol";
import {ERC721} from "@solmate/tokens/ERC721.sol";
import {Permit2Lib} from "@permit2/libraries/Permit2Lib.sol";

import {IImplementationManager} from "../interfaces/IImplementationManager.sol";
import {IClooverRaffleFactory} from "../interfaces/IClooverRaffleFactory.sol";
import {INFTWhitelist} from "../interfaces/INFTWhitelist.sol";
import {ITokenWhitelist} from "../interfaces/ITokenWhitelist.sol";

import {Errors} from "../libraries/Errors.sol";
import {ClooverRaffleFactoryEvents} from "../libraries/Events.sol";
import {ImplementationInterfaceNames} from "../libraries/ImplementationInterfaceNames.sol";
import {ClooverRaffleTypes} from "../libraries/Types.sol";
import {InsuranceLib} from "../libraries/InsuranceLib.sol";
import {PercentageMath} from "../libraries/PercentageMath.sol";

import {ClooverRaffle} from "../raffle/ClooverRaffle.sol";

import {ClooverRaffleFactoryGetters} from "./ClooverRaffleFactoryGetters.sol";
import {ClooverRaffleFactorySetters} from "./ClooverRaffleFactorySetters.sol";

/// @title ClooverRaffleFactory
/// @author Cloover
/// @notice The main RaffleFactory contract exposing user entry points.
contract ClooverRaffleFactory is IClooverRaffleFactory, ClooverRaffleFactoryGetters, ClooverRaffleFactorySetters {
    using EnumerableSet for EnumerableSet.AddressSet;
    using Clones for address;
    using InsuranceLib for uint16;
    using PercentageMath for uint16;
    using SafeTransferLib for ERC20;

    //----------------------------------------
    // Constructor
    //----------------------------------------
    constructor(address implementationManager, ClooverRaffleTypes.FactoryConfigParams memory data) {
        if (data.protocolFeeRate > PercentageMath.PERCENTAGE_FACTOR) revert Errors.EXCEED_MAX_PERCENTAGE();
        if (data.insuranceRate > PercentageMath.PERCENTAGE_FACTOR) revert Errors.EXCEED_MAX_PERCENTAGE();
        if (data.minTicketSalesDuration >= data.maxTicketSalesDuration) revert Errors.WRONG_DURATION_LIMITS();
        if (data.maxTicketSupplyAllowed == 0) revert Errors.CANT_BE_ZERO();
        _config = ClooverRaffleTypes.FactoryConfig({
            maxTicketSupplyAllowed: data.maxTicketSupplyAllowed,
            protocolFeeRate: data.protocolFeeRate,
            insuranceRate: data.insuranceRate,
            minTicketSalesDuration: data.minTicketSalesDuration,
            maxTicketSalesDuration: data.maxTicketSalesDuration
        });
        _implementationManager = implementationManager;
        _raffleImplementation = address(new ClooverRaffle());
    }

    //----------------------------------------
    // External functions
    //----------------------------------------

    /// @inheritdoc IClooverRaffleFactory
    function createRaffle(
        ClooverRaffleTypes.CreateRaffleParams calldata params,
        ClooverRaffleTypes.PermitDataParams calldata permitData
    ) external payable override whenNotPaused returns (address newRaffle) {
        _validateParams(params);
        newRaffle = address(_raffleImplementation.clone());
        _registeredRaffles.add(newRaffle);

        if (params.minTicketThreshold > 0) {
            uint256 insuranceCost =
                params.minTicketThreshold.calculateInsuranceCost(_config.insuranceRate, params.ticketPrice);
            if (params.purchaseCurrency == address(0)) {
                if (msg.value != insuranceCost) revert Errors.INSURANCE_AMOUNT();
            } else {
                if (permitData.deadline > 0) {
                    if (permitData.amount < insuranceCost) revert Errors.INSURANCE_AMOUNT();
                    ERC20(params.purchaseCurrency).permit(
                        msg.sender,
                        address(this),
                        permitData.amount,
                        permitData.deadline,
                        permitData.v,
                        permitData.r,
                        permitData.s
                    );
                }
                ERC20(params.purchaseCurrency).safeTransferFrom(msg.sender, newRaffle, insuranceCost);
            }
        }

        ERC721(params.nftContract).safeTransferFrom(msg.sender, newRaffle, params.nftId);
        ClooverRaffleTypes.InitializeRaffleParams memory raffleParams =
            _convertParams(params, params.purchaseCurrency == address(0));
        ClooverRaffle(newRaffle).initialize{value: msg.value}(raffleParams);

        emit ClooverRaffleFactoryEvents.NewRaffle(newRaffle, raffleParams);
    }

    /// @inheritdoc IClooverRaffleFactory
    function removeRaffleFromRegister() external override {
        if (!_registeredRaffles.remove(msg.sender)) revert Errors.NOT_WHITELISTED();
        emit ClooverRaffleFactoryEvents.RemovedFromRegister(msg.sender);
    }

    //----------------------------------------
    // Internal functions
    //----------------------------------------

    function _convertParams(ClooverRaffleTypes.CreateRaffleParams calldata params, bool isEthRaffle)
        internal
        view
        returns (ClooverRaffleTypes.InitializeRaffleParams memory raffleParams)
    {
        raffleParams = ClooverRaffleTypes.InitializeRaffleParams({
            creator: msg.sender,
            implementationManager: _implementationManager,
            purchaseCurrency: params.purchaseCurrency,
            nftContract: params.nftContract,
            nftId: params.nftId,
            ticketPrice: params.ticketPrice,
            endTicketSales: params.endTicketSales,
            maxTicketSupply: params.maxTicketSupply,
            maxTicketPerWallet: params.maxTicketPerWallet,
            minTicketThreshold: params.minTicketThreshold,
            protocolFeeRate: _config.protocolFeeRate,
            insuranceRate: _config.insuranceRate,
            royaltiesRate: params.royaltiesRate,
            isEthRaffle: isEthRaffle
        });
    }

    /// @notice check that the raffle can be created
    function _validateParams(ClooverRaffleTypes.CreateRaffleParams calldata params) internal {
        IImplementationManager implementationManager = IImplementationManager(_implementationManager);
        INFTWhitelist nftWhitelist =
            INFTWhitelist(implementationManager.getImplementationAddress(ImplementationInterfaceNames.NFTWhitelist));
        if (!nftWhitelist.isWhitelisted(address(params.nftContract))) revert Errors.COLLECTION_NOT_WHITELISTED();

        if (params.purchaseCurrency != address(0)) {
            if (msg.value > 0) revert Errors.NOT_ETH_RAFFLE();

            ITokenWhitelist tokenWhitelist = ITokenWhitelist(
                implementationManager.getImplementationAddress(ImplementationInterfaceNames.TokenWhitelist)
            );
            if (!tokenWhitelist.isWhitelisted(params.purchaseCurrency)) revert Errors.TOKEN_NOT_WHITELISTED();
        }

        if (params.ticketPrice < MIN_TICKET_PRICE) revert Errors.WRONG_AMOUNT();

        if (params.maxTicketSupply == 0) revert Errors.CANT_BE_ZERO();
        if (params.maxTicketSupply > _config.maxTicketSupplyAllowed) revert Errors.EXCEED_MAX_VALUE_ALLOWED();
        if (params.maxTicketSupply < 2) revert Errors.BELOW_MIN_VALUE_ALLOWED();
        uint64 saleDuration = params.endTicketSales - uint64(block.timestamp);
        if (saleDuration < _config.minTicketSalesDuration || saleDuration > _config.maxTicketSalesDuration) {
            revert Errors.OUT_OF_RANGE();
        }

        if (params.royaltiesRate > 0) {
            if (nftWhitelist.getCollectionRoyaltiesRecipient(address(params.nftContract)) == address(0)) {
                revert Errors.ROYALTIES_NOT_POSSIBLE();
            }
            if (_config.protocolFeeRate + params.royaltiesRate > PercentageMath.PERCENTAGE_FACTOR) {
                revert Errors.EXCEED_MAX_PERCENTAGE();
            }
        }
    }
}

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
 * ```solidity
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
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create(0, 0x09, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create2(0, 0x09, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(add(ptr, 0x38), deployer)
            mstore(add(ptr, 0x24), 0x5af43d82803e903d91602b57fd5bf3ff)
            mstore(add(ptr, 0x14), implementation)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73)
            mstore(add(ptr, 0x58), salt)
            mstore(add(ptr, 0x78), keccak256(add(ptr, 0x0c), 0x37))
            predicted := keccak256(add(ptr, 0x43), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt
    ) internal view returns (address predicted) {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {ERC20} from "../tokens/ERC20.sol";

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/SafeTransferLib.sol)
/// @dev Use with caution! Some functions in this library knowingly create dirty bits at the destination of the free memory pointer.
/// @dev Note that none of the functions in this library check that a token has code at all! That responsibility is delegated to the caller.
library SafeTransferLib {
    /*//////////////////////////////////////////////////////////////
                             ETH OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferETH(address to, uint256 amount) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Transfer the ETH and store if it succeeded or not.
            success := call(gas(), to, amount, 0, 0, 0, 0)
        }

        require(success, "ETH_TRANSFER_FAILED");
    }

    /*//////////////////////////////////////////////////////////////
                            ERC20 OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferFrom(
        ERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x23b872dd00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), from) // Append the "from" argument.
            mstore(add(freeMemoryPointer, 36), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 68), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 100 because the length of our calldata totals up like so: 4 + 32 * 3.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 100, 0, 32)
            )
        }

        require(success, "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0xa9059cbb00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "TRANSFER_FAILED");
    }

    function safeApprove(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x095ea7b300000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "APPROVE_FAILED");
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern, minimalist, and gas efficient ERC-721 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 indexed id);

    event Approval(address indexed owner, address indexed spender, uint256 indexed id);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /*//////////////////////////////////////////////////////////////
                         METADATA STORAGE/LOGIC
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    function tokenURI(uint256 id) public view virtual returns (string memory);

    /*//////////////////////////////////////////////////////////////
                      ERC721 BALANCE/OWNER STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => address) internal _ownerOf;

    mapping(address => uint256) internal _balanceOf;

    function ownerOf(uint256 id) public view virtual returns (address owner) {
        require((owner = _ownerOf[id]) != address(0), "NOT_MINTED");
    }

    function balanceOf(address owner) public view virtual returns (uint256) {
        require(owner != address(0), "ZERO_ADDRESS");

        return _balanceOf[owner];
    }

    /*//////////////////////////////////////////////////////////////
                         ERC721 APPROVAL STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => address) public getApproved;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    /*//////////////////////////////////////////////////////////////
                              ERC721 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 id) public virtual {
        address owner = _ownerOf[id];

        require(msg.sender == owner || isApprovedForAll[owner][msg.sender], "NOT_AUTHORIZED");

        getApproved[id] = spender;

        emit Approval(owner, spender, id);
    }

    function setApprovalForAll(address operator, bool approved) public virtual {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        require(from == _ownerOf[id], "WRONG_FROM");

        require(to != address(0), "INVALID_RECIPIENT");

        require(
            msg.sender == from || isApprovedForAll[from][msg.sender] || msg.sender == getApproved[id],
            "NOT_AUTHORIZED"
        );

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        unchecked {
            _balanceOf[from]--;

            _balanceOf[to]++;
        }

        _ownerOf[id] = to;

        delete getApproved[id];

        emit Transfer(from, to, id);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, "") ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes calldata data
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    /*//////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 id) internal virtual {
        require(to != address(0), "INVALID_RECIPIENT");

        require(_ownerOf[id] == address(0), "ALREADY_MINTED");

        // Counter overflow is incredibly unrealistic.
        unchecked {
            _balanceOf[to]++;
        }

        _ownerOf[id] = to;

        emit Transfer(address(0), to, id);
    }

    function _burn(uint256 id) internal virtual {
        address owner = _ownerOf[id];

        require(owner != address(0), "NOT_MINTED");

        // Ownership check above ensures no underflow.
        unchecked {
            _balanceOf[owner]--;
        }

        delete _ownerOf[id];

        delete getApproved[id];

        emit Transfer(owner, address(0), id);
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL SAFE MINT LOGIC
    //////////////////////////////////////////////////////////////*/

    function _safeMint(address to, uint256 id) internal virtual {
        _mint(to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, "") ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _safeMint(
        address to,
        uint256 id,
        bytes memory data
    ) internal virtual {
        _mint(to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }
}

/// @notice A generic interface for a contract which properly accepts ERC721 tokens.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721TokenReceiver {
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC721TokenReceiver.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {ERC20} from "solmate/src/tokens/ERC20.sol";

import {IDAIPermit} from "../interfaces/IDAIPermit.sol";
import {IAllowanceTransfer} from "../interfaces/IAllowanceTransfer.sol";
import {SafeCast160} from "./SafeCast160.sol";

/// @title Permit2Lib
/// @notice Enables efficient transfers and EIP-2612/DAI
/// permits for any token by falling back to Permit2.
library Permit2Lib {
    using SafeCast160 for uint256;
    /*//////////////////////////////////////////////////////////////
                                CONSTANTS
    //////////////////////////////////////////////////////////////*/

    /// @dev The unique EIP-712 domain domain separator for the DAI token contract.
    bytes32 internal constant DAI_DOMAIN_SEPARATOR = 0xdbb8cf42e1ecb028be3f3dbc922e1d878b963f411dc388ced501601c60f7c6f7;

    /// @dev The address for the WETH9 contract on Ethereum mainnet, encoded as a bytes32.
    bytes32 internal constant WETH9_ADDRESS = 0x000000000000000000000000c02aaa39b223fe8d0a0e5c4f27ead9083c756cc2;

    /// @dev The address of the Permit2 contract the library will use.
    IAllowanceTransfer internal constant PERMIT2 =
        IAllowanceTransfer(address(0x000000000022D473030F116dDEE9F6B43aC78BA3));

    /// @notice Transfer a given amount of tokens from one user to another.
    /// @param token The token to transfer.
    /// @param from The user to transfer from.
    /// @param to The user to transfer to.
    /// @param amount The amount to transfer.
    function transferFrom2(ERC20 token, address from, address to, uint256 amount) internal {
        // Generate calldata for a standard transferFrom call.
        bytes memory inputData = abi.encodeCall(ERC20.transferFrom, (from, to, amount));

        bool success; // Call the token contract as normal, capturing whether it succeeded.
        assembly {
            success :=
                and(
                    // Set success to whether the call reverted, if not we check it either
                    // returned exactly 1 (can't just be non-zero data), or had no return data.
                    or(eq(mload(0), 1), iszero(returndatasize())),
                    // Counterintuitively, this call() must be positioned after the or() in the
                    // surrounding and() because and() evaluates its arguments from right to left.
                    // We use 0 and 32 to copy up to 32 bytes of return data into the first slot of scratch space.
                    call(gas(), token, 0, add(inputData, 32), mload(inputData), 0, 32)
                )
        }

        // We'll fall back to using Permit2 if calling transferFrom on the token directly reverted.
        if (!success) PERMIT2.transferFrom(from, to, amount.toUint160(), address(token));
    }

    /*//////////////////////////////////////////////////////////////
                              PERMIT LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Permit a user to spend a given amount of
    /// another user's tokens via native EIP-2612 permit if possible, falling
    /// back to Permit2 if native permit fails or is not implemented on the token.
    /// @param token The token to permit spending.
    /// @param owner The user to permit spending from.
    /// @param spender The user to permit spending to.
    /// @param amount The amount to permit spending.
    /// @param deadline  The timestamp after which the signature is no longer valid.
    /// @param v Must produce valid secp256k1 signature from the owner along with r and s.
    /// @param r Must produce valid secp256k1 signature from the owner along with v and s.
    /// @param s Must produce valid secp256k1 signature from the owner along with r and v.
    function permit2(
        ERC20 token,
        address owner,
        address spender,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        // Generate calldata for a call to DOMAIN_SEPARATOR on the token.
        bytes memory inputData = abi.encodeWithSelector(ERC20.DOMAIN_SEPARATOR.selector);

        bool success; // Call the token contract as normal, capturing whether it succeeded.
        bytes32 domainSeparator; // If the call succeeded, we'll capture the return value here.

        assembly {
            // If the token is WETH9, we know it doesn't have a DOMAIN_SEPARATOR, and we'll skip this step.
            // We make sure to mask the token address as its higher order bits aren't guaranteed to be clean.
            if iszero(eq(and(token, 0xffffffffffffffffffffffffffffffffffffffff), WETH9_ADDRESS)) {
                success :=
                    and(
                        // Should resolve false if its not 32 bytes or its first word is 0.
                        and(iszero(iszero(mload(0))), eq(returndatasize(), 32)),
                        // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                        // Counterintuitively, this call must be positioned second to the and() call in the
                        // surrounding and() call or else returndatasize() will be zero during the computation.
                        // We send a maximum of 5000 gas to prevent tokens with fallbacks from using a ton of gas.
                        // which should be plenty to allow tokens to fetch their DOMAIN_SEPARATOR from storage, etc.
                        staticcall(5000, token, add(inputData, 32), mload(inputData), 0, 32)
                    )

                domainSeparator := mload(0) // Copy the return value into the domainSeparator variable.
            }
        }

        // If the call to DOMAIN_SEPARATOR succeeded, try using permit on the token.
        if (success) {
            // We'll use DAI's special permit if it's DOMAIN_SEPARATOR matches,
            // otherwise we'll just encode a call to the standard permit function.
            inputData = domainSeparator == DAI_DOMAIN_SEPARATOR
                ? abi.encodeCall(IDAIPermit.permit, (owner, spender, token.nonces(owner), deadline, true, v, r, s))
                : abi.encodeCall(ERC20.permit, (owner, spender, amount, deadline, v, r, s));

            assembly {
                success := call(gas(), token, 0, add(inputData, 32), mload(inputData), 0, 0)
            }
        }

        if (!success) {
            // If the initial DOMAIN_SEPARATOR call on the token failed or a
            // subsequent call to permit failed, fall back to using Permit2.
            simplePermit2(token, owner, spender, amount, deadline, v, r, s);
        }
    }

    /// @notice Simple unlimited permit on the Permit2 contract.
    /// @param token The token to permit spending.
    /// @param owner The user to permit spending from.
    /// @param spender The user to permit spending to.
    /// @param amount The amount to permit spending.
    /// @param deadline  The timestamp after which the signature is no longer valid.
    /// @param v Must produce valid secp256k1 signature from the owner along with r and s.
    /// @param r Must produce valid secp256k1 signature from the owner along with v and s.
    /// @param s Must produce valid secp256k1 signature from the owner along with r and v.
    function simplePermit2(
        ERC20 token,
        address owner,
        address spender,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        (,, uint48 nonce) = PERMIT2.allowance(owner, address(token), spender);

        PERMIT2.permit(
            owner,
            IAllowanceTransfer.PermitSingle({
                details: IAllowanceTransfer.PermitDetails({
                    token: address(token),
                    amount: amount.toUint160(),
                    // Use an unlimited expiration because it most
                    // closely mimics how a standard approval works.
                    expiration: type(uint48).max,
                    nonce: nonce
                }),
                spender: spender,
                sigDeadline: deadline
            }),
            bytes.concat(r, s, bytes1(v))
        );
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

interface IImplementationManager {
    /// @notice Updates the address of the contract that implements `interfaceName`
    function changeImplementationAddress(bytes32 interfaceName, address implementationAddress) external;

    /// @notice Return the address of the contract that implements the given `interfaceName`
    function getImplementationAddress(bytes32 interfaceName) external view returns (address implementationAddress);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import {ClooverRaffleTypes} from "../libraries/Types.sol";

interface IClooverRaffleFactoryGetters {
    /// @notice Return the implementation manager contract
    function implementationManager() external view returns (address);

    /// @notice Return the fees rate to apply on ticket sales amount
    function protocolFeeRate() external view returns (uint256);

    /// @notice Return the rate that creator will have to pay on the min sales defined
    function insuranceRate() external view returns (uint256);

    /// @notice Return the max ticket supply allowed in a raffle
    function maxTicketSupplyAllowed() external view returns (uint256);

    /// @notice Return the min duration for the ticket sales
    function minTicketSalesDuration() external view returns (uint256);

    /// @notice Return the max duration for the ticket sales
    function maxTicketSalesDuration() external view returns (uint256);

    /// @notice Return the limit of duration for the ticket sales
    function ticketSalesDurationLimits() external view returns (uint256 minDuration, uint256 maxDuration);

    /// @notice Return Ture if raffle is registered
    function isRegistered(address raffle) external view returns (bool);

    /// @notice Return all raffle address that are currently included in the whitelist
    function getRegisteredRaffle() external view returns (address[] memory);

    /// @notice Return the version of the contract
    function version() external pure returns (string memory);
}

interface IClooverRaffleFactorySetters {
    /// @notice Set the protocol fees rate to apply on new raffle deployed
    function setProtocolFeeRate(uint16 newFeeRate) external;

    /// @notice Set the insurance rate to apply on new raffle deployed
    function setInsuranceRate(uint16 newinsuranceRate) external;

    /// @notice Set the min duration for the ticket sales
    function setMinTicketSalesDuration(uint64 newMinTicketSalesDuration) external;

    /// @notice Set the max duration for the ticket sales
    function setMaxTicketSalesDuration(uint64 newMaxTicketSalesDuration) external;

    /// @notice Set the max ticket supply allowed in a raffle
    function setMaxTicketSupplyAllowed(uint16 newMaxTotalSupplyAllowed) external;

    /// @notice Pause the contract preventing new raffle to be deployed
    /// @dev can only be called by the maintainer
    function pause() external;

    /// @notice Unpause the contract allowing new raffle to be deployed
    /// @dev can only be called by the maintainer
    function unpause() external;
}

interface IClooverRaffleFactory is IClooverRaffleFactoryGetters, IClooverRaffleFactorySetters {
    /// @notice Deploy a new raffle contract
    /// @dev must transfer the nft to the contract before initialize()
    function createRaffle(
        ClooverRaffleTypes.CreateRaffleParams memory params,
        ClooverRaffleTypes.PermitDataParams calldata permitData
    ) external payable returns (address newRaffle);

    /// @notice remove msg.sender from the list of registered raffles
    /// @dev can only be called by the raffle contract itself
    function removeRaffleFromRegister() external;
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

interface INFTWhitelist {
    /// @notice Whitelist a nft collection with the creator address of it
    function addToWhitelist(address newNftCollection, address creator) external;

    /// @notice Removes a collection from the whitelist
    function removeFromWhitelist(address nftCollectionToRemove) external;

    /// @notice Return True if the address is whitelisted
    function isWhitelisted(address nftCollectionToCheck) external view returns (bool);

    /// @notice Return all addresses that are currently included in the whitelist.
    function getWhitelist() external view returns (address[] memory);

    /// @notice Return creator address for a specific nft collection
    function getCollectionRoyaltiesRecipient(address nftCollection) external view returns (address creator);

    /// @notice Return the implementationManager contract address
    function implementationManager() external view returns (address);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

interface ITokenWhitelist {
    /// @notice Adds an address to the whitelist
    function addToWhitelist(address newToken) external;

    /// @notice Removes an address from the whitelist
    function removeFromWhitelist(address tokenToRemove) external;

    /// @notice Return True if the address is whitelisted
    function isWhitelisted(address tokenToCheck) external view returns (bool);

    /// @notice Return all addresses that are currently included in the whitelist.
    function getWhitelist() external view returns (address[] memory);

    /// @notice Return the implementationManager contract address
    function implementationManager() external view returns (address);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

/// @title Errors library
/// @author Cloover
/// @notice Library exposing errors used in Cloover's contracts
library Errors {
    error CANT_BE_ZERO(); // 'Value can't must be higher than 0'
    error NOT_MAINTAINER(); // 'Caller is not the maintainer'
    error IMPLEMENTATION_NOT_FOUND(); // 'Implementation interfaces is not registered'
    error ALREADY_WHITELISTED(); //'address already whitelisted'
    error NOT_WHITELISTED(); //'address not whitelisted'
    error EXCEED_MAX_PERCENTAGE(); //'Percentage value must be lower than max allowed'
    error EXCEED_MAX_VALUE_ALLOWED(); //'Value must be lower than max allowed'
    error BELOW_MIN_VALUE_ALLOWED(); //'Value must be higher than min allowed'
    error WRONG_DURATION_LIMITS(); //'The min duration must be lower than the max one'
    error OUT_OF_RANGE(); //'The value is not in the allowed range'
    error SALES_ALREADY_STARTED(); // 'At least one ticket has already been sold'
    error RAFFLE_CLOSE(); // 'Current timestamps greater or equal than the close time'
    error RAFFLE_STILL_OPEN(); // 'Current timestamps lesser or equal than the close time'
    error DRAW_NOT_POSSIBLE(); // 'Raffle is status forwards than DRAWING'
    error TICKET_SUPPLY_OVERFLOW(); // 'Maximum amount of ticket sold for the raffle has been reached'
    error WRONG_MSG_VALUE(); // 'msg.value not valid'
    error WRONG_AMOUNT(); // 'msg.value not valid'
    error MSG_SENDER_NOT_WINNER(); // 'msg.sender is not winner address'
    error NOT_CREATOR(); // 'msg.sender is not the creator of the raffle'
    error TICKET_NOT_DRAWN(); // 'ticket must be drawn'
    error TICKET_ALREADY_DRAWN(); // 'ticket has already be drawn'
    error NOT_REGISTERED_RAFFLE(); // 'Caller is not a raffle contract registered'
    error NOT_RANDOM_PROVIDER_CONTRACT(); // 'Caller is not the random provider contract'
    error COLLECTION_NOT_WHITELISTED(); //'NFT collection not whitelisted'
    error ROYALTIES_NOT_POSSIBLE(); //'NFT collection creator '
    error TOKEN_NOT_WHITELISTED(); //'Token not whitelisted'
    error IS_ETH_RAFFLE(); //'Ticket can only be purchase with native token (ETH)'
    error NOT_ETH_RAFFLE(); //'Ticket can only be purchase with ERC20 token'
    error NO_INSURANCE_TAKEN(); //'ClooverRaffle's creator didn't took insurance to claim prize refund'
    error INSURANCE_AMOUNT(); //'insurance cost paid'
    error SALES_EXCEED_MIN_THRESHOLD_LIMIT(); //'Ticket sales exceed min ticket sales covered by the insurance paid'
    error ALREADY_CLAIMED(); //'User already claimed his part'
    error NOTHING_TO_CLAIM(); //'User has nothing to claim'
    error EXCEED_MAX_TICKET_ALLOWED_TO_PURCHASE(); //'User exceed allowed ticket to purchase limit'
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import {ClooverRaffleTypes} from "./Types.sol";

/// @title ClooverRaffleEvents
/// @author Cloover
/// @notice Library exposing events used in ClooverRaffle.
library ClooverRaffleEvents {
    /// @notice Emitted when a purchase tickets happens.
    /// @param user The address of the user that purchased tickets
    /// @param firstTicketnumber The first ticket number purchased at the call (use to calculate tickets number purchased)
    /// @param nbOfTicketsPurchased The number of tickets purchased
    event TicketsPurchased(address indexed user, uint16 firstTicketnumber, uint16 nbOfTicketsPurchased);

    /// @notice Emitted when a user claim his price.
    event WinnerClaimed(address winner);

    /// @notice Emitted when the creator claim tickets sales.
    /// @param creatorAmountReceived The amount received by the creator
    /// @param protocolFeeAmount The amount received by the protocol
    /// @param royaltiesAmount The amount received by the nft collection creator as royalties
    event CreatorClaimed(uint256 creatorAmountReceived, uint256 protocolFeeAmount, uint256 royaltiesAmount);

    /// @notice Emitted when the random ticket number is drawn.
    event WinningTicketDrawn(uint16 winningTicket);

    /// @notice Emitted when the creator claim prize refund.
    event CreatorClaimedRefund();

    /// @notice Emitted when the user claim his refund.
    /// @param user The address of the user that claimed his refund
    /// @param amountReceived The amount received by the user (refund tickets cost + part of creator's insurance paid)
    event UserClaimedRefund(address indexed user, uint256 amountReceived);

    /// @notice Emitted when the raffle is cancelled by the creator
    event RaffleCancelled();

    /// @notice Emitted when the raffle status is updated
    event RaffleStatus(ClooverRaffleTypes.Status indexed status);
}

/// @title ClooverRaffleFactoryEvents
/// @author Cloover
/// @notice Library exposing events used in ClooverRaffleFactory.
library ClooverRaffleFactoryEvents {
    /// @notice Emitted when a new raffle is created
    event NewRaffle(address indexed raffleContract, ClooverRaffleTypes.InitializeRaffleParams raffleParams);

    /// @notice Emitted when a raffle contract is removed from register
    event RemovedFromRegister(address indexed raffleContract);

    /// @notice Emitted when protocol fee rate is updated
    event ProtocolFeeRateUpdated(uint256 newProtocolFeeRate);

    /// @notice Emitted when insurance rate is updated
    event InsuranceRateUpdated(uint256 newInsuranceRate);

    /// @notice Emitted when max total supply allowed is updated
    event MaxTotalSupplyAllowedUpdated(uint256 newMaxTicketSupply);

    /// @notice Emitted when min ticket sales duration is updated
    event MinTicketSalesDurationUpdated(uint256 newMinTicketSalesDuration);

    /// @notice Emitted when max ticket sales duration is updated
    event MaxTicketSalesDurationUpdated(uint256 newMaxTicketSalesDuration);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

/// @title ImplementationInterfaceNames
/// @author Cloover
/// @notice Library exposing interfaces names used in Cloover
library ImplementationInterfaceNames {
    bytes32 public constant AccessController = "AccessController";
    bytes32 public constant RandomProvider = "RandomProvider";
    bytes32 public constant NFTWhitelist = "NFTWhitelist";
    bytes32 public constant TokenWhitelist = "TokenWhitelist";
    bytes32 public constant ClooverRaffleFactory = "ClooverRaffleFactory";
    bytes32 public constant Treasury = "Treasury";
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

/// @title ClooverRaffleTypes
/// @author Cloover
/// @notice Library exposing all Types used in ClooverRaffle & ClooverRaffleFactory.
library ClooverRaffleTypes {
    /* ENUMS */
    /// @notice Enumeration of the different status of the raffle
    enum Status {
        OPEN,
        DRAWING,
        DRAWN,
        REFUNDABLE,
        CANCELLED
    }

    /* STORAGE STRUCTS */

    /// @notice Contains the immutable config of a raffle
    struct ConfigData {
        // SLOT 0
        address creator; // 160 bits
        uint64 endTicketSales; // 64 bits
        // SLOT 1
        address implementationManager; // 160 bits
        uint16 maxTicketSupply; // 16 bits
        // SLOT 2
        address purchaseCurrency; // 160 bits
        uint16 maxTicketPerWallet; // 16 bits
        // SLOT 3
        address nftContract; // 160 bits
        uint16 minTicketThreshold; // 24 bits
        uint16 protocolFeeRate; // 16 bits
        uint16 insuranceRate; // 16 bits
        uint16 royaltiesRate; // 16 bits
        bool isEthRaffle; // 8 bits
        // SLOT 4
        uint256 nftId; // 256 bits
        // SLOT 5
        uint256 ticketPrice; // 256 bits
    }

    /// @notice Contains the current state of the raffle
    struct LifeCycleData {
        Status status; // 8 bits
        uint16 currentTicketSupply; // 16 bits
        uint16 winningTicketNumber; // 16 bits
    }

    /// @notice Contains the info of a purchased entry
    struct PurchasedEntries {
        address owner; // 160 bits
        uint16 currentTicketsSold; // 16 bits
        uint16 nbOfTickets; // 16 bits
    }

    ///@notice Contains the info of a participant
    struct ParticipantInfo {
        uint16 nbOfTicketsPurchased; // 16 bits
        uint16[] purchasedEntriesIndexes; // 16 bits
        bool hasClaimedRefund; // 8 bits
    }

    /// @notice Contains the base info and limit for raffles
    struct FactoryConfig {
        uint16 maxTicketSupplyAllowed; // 16 bits
        uint16 protocolFeeRate; // 16 bits
        uint16 insuranceRate; // 16 bits
        uint64 minTicketSalesDuration; // 64 bits
        uint64 maxTicketSalesDuration; // 64 bits
    }

    /* STACK AND RETURN STRUCTS */

    /// @notice The parameters used by the raffle factory to create a new raffle
    struct CreateRaffleParams {
        address purchaseCurrency;
        address nftContract;
        uint256 nftId;
        uint256 ticketPrice;
        uint64 endTicketSales;
        uint16 maxTicketSupply;
        uint16 maxTicketPerWallet;
        uint16 minTicketThreshold;
        uint16 royaltiesRate;
    }

    /// @notice The parameters used for ERC20 permit function
    struct PermitDataParams {
        uint256 amount;
        uint256 deadline;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    /// @notice The parameters used to initialize the raffle
    struct InitializeRaffleParams {
        address creator;
        address implementationManager;
        address purchaseCurrency;
        address nftContract;
        uint256 nftId;
        uint256 ticketPrice;
        uint64 endTicketSales;
        uint16 maxTicketSupply;
        uint16 maxTicketPerWallet;
        uint16 minTicketThreshold;
        uint16 protocolFeeRate;
        uint16 insuranceRate;
        uint16 royaltiesRate;
        bool isEthRaffle;
    }

    /// @notice The parameters used to initialize the raffle factory
    struct FactoryConfigParams {
        uint16 maxTicketSupplyAllowed;
        uint16 protocolFeeRate;
        uint16 insuranceRate;
        uint64 minTicketSalesDuration;
        uint64 maxTicketSalesDuration;
    }
}

/// @title RandomProviderTypes
/// @author Cloover
/// @notice Library exposing all Types used in RandomProvider.
library RandomProviderTypes {
    struct ChainlinkVRFData {
        // see https://docs.chain.link/docs/vrf-contracts/#configurations
        address vrfCoordinator;
        // The gas lane to use, which specifies the maximum gas price to bump to.
        // For a list of available gas lanes on each network,
        // see https://docs.chain.link/docs/vrf-contracts/#configurations
        bytes32 keyHash; // 256 bits
        // A reasonable default is 100000, but this value could be different
        // on other networks.
        uint32 callbackGasLimit;
        // The default is 3, but you can set this higher.
        uint16 requestConfirmations;
        uint64 subscriptionId;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import {PercentageMath} from "./PercentageMath.sol";

/// @title InsuranceLib
/// @author Cloover
/// @notice Library used to ease insurance maths
library InsuranceLib {
    using PercentageMath for uint256;

    /// @notice calculate the insurance cost
    function calculateInsuranceCost(uint16 minTicketSalesInsurance, uint16 insuranceRate, uint256 ticketPrice)
        internal
        pure
        returns (uint256 insuranceCost)
    {
        insuranceCost = (minTicketSalesInsurance * ticketPrice).percentMul(insuranceRate);
    }

    /// @notice calculate the part of insurance asign to each ticket and the protocol
    function splitInsuranceAmount(
        uint16 minTicketThreshold,
        uint16 insuranceRate,
        uint16 procolFeeRate,
        uint16 ticketSupply,
        uint256 ticketPrice
    ) internal pure returns (uint256 protocolFeeAmount, uint256 amountPerTicket) {
        uint256 insuranceAmount = calculateInsuranceCost(minTicketThreshold, insuranceRate, ticketPrice);
        amountPerTicket = (insuranceAmount - insuranceAmount.percentMul(procolFeeRate)) / ticketSupply;
        protocolFeeAmount = insuranceAmount - amountPerTicket * ticketSupply;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

/// @title PercentageMath library
/// @author Cloover
/// @notice Optimized version of Aave V3 math library PercentageMath to conduct percentage manipulations: https://github.com/aave/aave-v3-core/blob/master/contracts/protocol/libraries/math/PercentageMath.sol
library PercentageMath {
    uint256 internal constant PERCENTAGE_FACTOR = 100_00;
    uint256 internal constant HALF_PERCENTAGE_FACTOR = 50_00;
    uint256 internal constant MAX_UINT256 = 2 ** 256 - 1;
    uint256 internal constant MAX_UINT256_MINUS_HALF_PERCENTAGE_FACTOR = 2 ** 256 - 1 - 50_00;

    /// @notice Executes the bps-based multiplication (x * p), rounded half up.
    /// @param x The value to multiply by the percentage.
    /// @param percentage The percentage of the value to multiply (in bps).
    /// @return y The result of the multiplication.
    function percentMul(uint256 x, uint256 percentage) internal pure returns (uint256 y) {
        // to avoid overflow, value <= (type(uint256).max - HALF_PERCENTAGE_FACTOR) / percentage
        assembly {
            if mul(percentage, gt(x, div(MAX_UINT256_MINUS_HALF_PERCENTAGE_FACTOR, percentage))) { revert(0, 0) }

            y := div(add(mul(x, percentage), HALF_PERCENTAGE_FACTOR), PERCENTAGE_FACTOR)
        }
    }

    /// @notice Executes the bps-based division (x / p), rounded half up.
    /// @param x The value to divide by the percentage.
    /// @param percentage The percentage of the value to divide (in bps).
    /// @return y The result of the division.
    function percentDiv(uint256 x, uint256 percentage) internal pure returns (uint256 y) {
        // 1. Division by 0 if
        //        percentage == 0
        // 2. Overflow if
        //        x * PERCENTAGE_FACTOR + percentage / 2 > type(uint256).max
        //    <=> x > (type(uint256).max - percentage / 2) / PERCENTAGE_FACTOR
        assembly {
            y := div(percentage, 2) // Temporary assignment to save gas.

            if iszero(mul(percentage, iszero(gt(x, div(sub(MAX_UINT256, y), PERCENTAGE_FACTOR))))) { revert(0, 0) }

            y := div(add(mul(PERCENTAGE_FACTOR, x), y), percentage)
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import {ERC20, SafeTransferLib} from "@solmate/utils/SafeTransferLib.sol";
import {ERC721} from "@solmate/tokens/ERC721.sol";
import {Permit2Lib} from "@permit2/libraries/Permit2Lib.sol";

import {ImplementationInterfaceNames} from "../libraries/ImplementationInterfaceNames.sol";
import {Errors} from "../libraries/Errors.sol";
import {PercentageMath} from "../libraries/PercentageMath.sol";
import {ClooverRaffleTypes} from "../libraries/Types.sol";
import {ClooverRaffleEvents} from "../libraries/Events.sol";

import {IClooverRaffle} from "../interfaces/IClooverRaffle.sol";
import {IClooverRaffleFactory} from "../interfaces/IClooverRaffleFactory.sol";
import {IRandomProvider} from "../interfaces/IRandomProvider.sol";
import {INFTWhitelist} from "../interfaces/INFTWhitelist.sol";
import {ITokenWhitelist} from "../interfaces/ITokenWhitelist.sol";
import {IImplementationManager} from "../interfaces/IImplementationManager.sol";

import {ClooverRaffleStorage} from "./ClooverRaffleStorage.sol";
import {ClooverRaffleGetters} from "./ClooverRaffleGetters.sol";
import {ClooverRaffleInternal} from "./ClooverRaffleInternal.sol";

/// @title ClooverRaffle
/// @author Cloover
/// @notice The main Raffle contract exposing all user entry points.
contract ClooverRaffle is IClooverRaffle, Initializable, ClooverRaffleGetters {
    using PercentageMath for uint256;
    using SafeTransferLib for ERC20;
    using Permit2Lib for ERC20;

    //----------------------------------------
    // Modifiers
    //----------------------------------------

    modifier ticketSalesOpen() {
        if (block.timestamp >= _config.endTicketSales) revert Errors.RAFFLE_CLOSE();
        _;
    }

    modifier ticketSalesOver() {
        if (block.timestamp < _config.endTicketSales) {
            revert Errors.RAFFLE_STILL_OPEN();
        }
        _;
    }

    modifier ticketHasNotBeDrawn() {
        if (_lifeCycleData.status == ClooverRaffleTypes.Status.DRAWN) revert Errors.TICKET_ALREADY_DRAWN();
        _;
    }

    modifier winningTicketDrawn() {
        if (_lifeCycleData.status != ClooverRaffleTypes.Status.DRAWN) revert Errors.TICKET_NOT_DRAWN();
        _;
    }

    modifier onlyCreator() {
        if (_config.creator != msg.sender) {
            revert Errors.NOT_CREATOR();
        }
        _;
    }

    //----------------------------------------
    // Initializer
    //----------------------------------------

    function initialize(ClooverRaffleTypes.InitializeRaffleParams calldata params)
        external
        payable
        override
        initializer
    {
        _config = ClooverRaffleTypes.ConfigData({
            creator: params.creator,
            implementationManager: params.implementationManager,
            purchaseCurrency: params.purchaseCurrency,
            nftContract: params.nftContract,
            nftId: params.nftId,
            ticketPrice: params.ticketPrice,
            endTicketSales: params.endTicketSales,
            maxTicketSupply: params.maxTicketSupply,
            minTicketThreshold: params.minTicketThreshold,
            maxTicketPerWallet: params.maxTicketPerWallet,
            protocolFeeRate: params.protocolFeeRate,
            insuranceRate: params.insuranceRate,
            royaltiesRate: params.royaltiesRate,
            isEthRaffle: params.isEthRaffle
        });
    }

    //----------------------------------------
    // Externals Functions
    //----------------------------------------

    /// @inheritdoc IClooverRaffle
    function purchaseTickets(uint16 nbOfTickets) external override ticketSalesOpen {
        _purchaseTicketsInToken(nbOfTickets);
    }

    /// @inheritdoc IClooverRaffle
    function purchaseTicketsWithPermit(uint16 nbOfTickets, ClooverRaffleTypes.PermitDataParams calldata permitData)
        external
        override
        ticketSalesOpen
    {
        ERC20(_config.purchaseCurrency).permit(
            msg.sender, address(this), permitData.amount, permitData.deadline, permitData.v, permitData.r, permitData.s
        );
        _purchaseTicketsInToken(nbOfTickets);
    }

    /// @inheritdoc IClooverRaffle
    function purchaseTicketsInEth(uint16 nbOfTickets) external payable override ticketSalesOpen {
        if (!_config.isEthRaffle) revert Errors.NOT_ETH_RAFFLE();
        if (_calculateTicketsCost(nbOfTickets) != msg.value) {
            revert Errors.WRONG_MSG_VALUE();
        }
        _purchaseTickets(nbOfTickets);
    }

    /// @inheritdoc IClooverRaffle
    function draw() external override ticketSalesOver {
        if (uint256(_lifeCycleData.status) >= uint256(ClooverRaffleTypes.Status.DRAWING)) {
            revert Errors.DRAW_NOT_POSSIBLE();
        }
        uint16 _currentSupply = _lifeCycleData.currentTicketSupply;
        if (_currentSupply == 0) {
            _lifeCycleData.status = ClooverRaffleTypes.Status.CANCELLED;
        } else if (_currentSupply < _config.minTicketThreshold) {
            _lifeCycleData.status = ClooverRaffleTypes.Status.REFUNDABLE;
        } else {
            _lifeCycleData.status = ClooverRaffleTypes.Status.DRAWING;
            IRandomProvider(
                IImplementationManager(_config.implementationManager).getImplementationAddress(
                    ImplementationInterfaceNames.RandomProvider
                )
            ).requestRandomNumbers(1);
        }
        emit ClooverRaffleEvents.RaffleStatus(_lifeCycleData.status);
    }

    /// @inheritdoc IClooverRaffle
    function draw(uint256[] calldata randomNumbers) external override {
        if (
            IImplementationManager(_config.implementationManager).getImplementationAddress(
                ImplementationInterfaceNames.RandomProvider
            ) != msg.sender
        ) revert Errors.NOT_RANDOM_PROVIDER_CONTRACT();

        if (randomNumbers[0] == 0) {
            _lifeCycleData.status = ClooverRaffleTypes.Status.OPEN;
        } else {
            uint16 winningTicketNumber = uint16((randomNumbers[0] % _lifeCycleData.currentTicketSupply) + 1);
            _lifeCycleData.winningTicketNumber = winningTicketNumber;
            _lifeCycleData.status = ClooverRaffleTypes.Status.DRAWN;
            emit ClooverRaffleEvents.WinningTicketDrawn(winningTicketNumber);
        }
        emit ClooverRaffleEvents.RaffleStatus(_lifeCycleData.status);
    }

    /// @inheritdoc IClooverRaffle
    function claimTicketSales() external override winningTicketDrawn onlyCreator {
        if (_config.isEthRaffle) revert Errors.IS_ETH_RAFFLE();
        ERC20 purchaseCurrency = ERC20(_config.purchaseCurrency);
        IImplementationManager _implementationManager = IImplementationManager(_config.implementationManager);

        (uint256 creatorAmount, uint256 protocolFees, uint256 royaltiesAmount) =
            _calculateAmountToTransfer(purchaseCurrency.balanceOf(address(this)));

        purchaseCurrency.safeTransfer(
            _implementationManager.getImplementationAddress(ImplementationInterfaceNames.Treasury), protocolFees
        );

        if (royaltiesAmount > 0) {
            purchaseCurrency.safeTransfer(
                INFTWhitelist(
                    _implementationManager.getImplementationAddress(ImplementationInterfaceNames.NFTWhitelist)
                ).getCollectionRoyaltiesRecipient(address(_config.nftContract)),
                royaltiesAmount
            );
        }

        purchaseCurrency.safeTransfer(msg.sender, creatorAmount);

        emit ClooverRaffleEvents.CreatorClaimed(creatorAmount, protocolFees, royaltiesAmount);
    }

    /// @inheritdoc IClooverRaffle
    function claimTicketSalesInEth() external override winningTicketDrawn onlyCreator {
        if (!_config.isEthRaffle) revert Errors.NOT_ETH_RAFFLE();
        IImplementationManager _implementationManager = IImplementationManager(_config.implementationManager);

        (uint256 creatorAmount, uint256 protocolFees, uint256 royaltiesAmount) =
            _calculateAmountToTransfer(address(this).balance);

        SafeTransferLib.safeTransferETH(
            _implementationManager.getImplementationAddress(ImplementationInterfaceNames.Treasury), protocolFees
        );

        if (royaltiesAmount > 0) {
            SafeTransferLib.safeTransferETH(
                INFTWhitelist(
                    _implementationManager.getImplementationAddress(ImplementationInterfaceNames.NFTWhitelist)
                ).getCollectionRoyaltiesRecipient(address(_config.nftContract)),
                royaltiesAmount
            );
        }

        SafeTransferLib.safeTransferETH(msg.sender, creatorAmount);

        emit ClooverRaffleEvents.CreatorClaimed(creatorAmount, protocolFees, royaltiesAmount);
    }

    /// @inheritdoc IClooverRaffle
    function claimPrize() external override winningTicketDrawn {
        if (msg.sender != _winnerAddress()) {
            revert Errors.MSG_SENDER_NOT_WINNER();
        }
        ERC721(_config.nftContract).safeTransferFrom(address(this), msg.sender, _config.nftId);
        emit ClooverRaffleEvents.WinnerClaimed(msg.sender);
    }

    /// @inheritdoc IClooverRaffle
    function claimParticipantRefund() external override ticketSalesOver ticketHasNotBeDrawn {
        if (_config.isEthRaffle) revert Errors.IS_ETH_RAFFLE();

        uint256 totalRefundAmount = _calculateUserRefundAmount();

        ERC20(_config.purchaseCurrency).safeTransfer(msg.sender, totalRefundAmount);

        emit ClooverRaffleEvents.UserClaimedRefund(msg.sender, totalRefundAmount);
    }

    /// @inheritdoc IClooverRaffle
    function claimParticipantRefundInEth() external override ticketSalesOver ticketHasNotBeDrawn {
        if (!_config.isEthRaffle) revert Errors.NOT_ETH_RAFFLE();

        uint256 totalRefundAmount = _calculateUserRefundAmount();

        SafeTransferLib.safeTransferETH(msg.sender, totalRefundAmount);

        emit ClooverRaffleEvents.UserClaimedRefund(msg.sender, totalRefundAmount);
    }

    /// @inheritdoc IClooverRaffle
    function claimCreatorRefund() external override ticketSalesOver ticketHasNotBeDrawn onlyCreator {
        if (_config.isEthRaffle) revert Errors.IS_ETH_RAFFLE();

        (uint256 treasuryAmountToTransfer, address treasuryAddress) = _handleCreatorInsurance();

        ERC20(_config.purchaseCurrency).safeTransfer(treasuryAddress, treasuryAmountToTransfer);

        ERC721(_config.nftContract).safeTransferFrom(address(this), _config.creator, _config.nftId);

        emit ClooverRaffleEvents.CreatorClaimedRefund();
    }

    /// @inheritdoc IClooverRaffle
    function claimCreatorRefundInEth() external override ticketSalesOver ticketHasNotBeDrawn onlyCreator {
        if (!_config.isEthRaffle) revert Errors.NOT_ETH_RAFFLE();

        (uint256 treasuryAmountToTransfer, address treasuryAddress) = _handleCreatorInsurance();

        SafeTransferLib.safeTransferETH(treasuryAddress, treasuryAmountToTransfer);

        ERC721(_config.nftContract).safeTransferFrom(address(this), _config.creator, _config.nftId);
        emit ClooverRaffleEvents.CreatorClaimedRefund();
    }

    /// @inheritdoc IClooverRaffle
    function cancel() external override onlyCreator {
        if (_lifeCycleData.currentTicketSupply > 0) revert Errors.SALES_ALREADY_STARTED();
        if (_lifeCycleData.status != ClooverRaffleTypes.Status.CANCELLED) {
            _lifeCycleData.status = ClooverRaffleTypes.Status.CANCELLED;
            emit ClooverRaffleEvents.RaffleStatus(ClooverRaffleTypes.Status.CANCELLED);
        }
        IClooverRaffleFactory(
            IImplementationManager(_config.implementationManager).getImplementationAddress(
                ImplementationInterfaceNames.ClooverRaffleFactory
            )
        ).removeRaffleFromRegister();

        if (_config.minTicketThreshold > 0) {
            uint256 insurancePaid = _calculateInsuranceCost();
            if (_config.isEthRaffle) {
                SafeTransferLib.safeTransferETH(_config.creator, insurancePaid);
            } else {
                ERC20(_config.purchaseCurrency).safeTransfer(_config.creator, insurancePaid);
            }
        }

        ERC721(_config.nftContract).safeTransferFrom(address(this), _config.creator, _config.nftId);
        emit ClooverRaffleEvents.RaffleCancelled();
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import {IImplementationManager} from "../interfaces/IImplementationManager.sol";
import {IClooverRaffleFactoryGetters} from "../interfaces/IClooverRaffleFactory.sol";

import {ClooverRaffleFactoryStorage} from "./ClooverRaffleFactoryStorage.sol";

/// @title ClooverRaffleFactoryGetters
/// @author Cloover
/// @notice Abstract contract exposing all accessible getters.
abstract contract ClooverRaffleFactoryGetters is IClooverRaffleFactoryGetters, ClooverRaffleFactoryStorage {
    using EnumerableSet for EnumerableSet.AddressSet;
    /// @inheritdoc IClooverRaffleFactoryGetters

    function protocolFeeRate() external view override returns (uint256) {
        return _config.protocolFeeRate;
    }

    /// @inheritdoc IClooverRaffleFactoryGetters
    function insuranceRate() external view override returns (uint256) {
        return _config.insuranceRate;
    }

    /// @inheritdoc IClooverRaffleFactoryGetters
    function minTicketSalesDuration() external view override returns (uint256) {
        return _config.minTicketSalesDuration;
    }

    /// @inheritdoc IClooverRaffleFactoryGetters
    function maxTicketSalesDuration() external view override returns (uint256) {
        return _config.maxTicketSalesDuration;
    }

    /// @inheritdoc IClooverRaffleFactoryGetters
    function maxTicketSupplyAllowed() external view override returns (uint256) {
        return _config.maxTicketSupplyAllowed;
    }

    /// @inheritdoc IClooverRaffleFactoryGetters
    function implementationManager() external view returns (address) {
        return _implementationManager;
    }

    /// @inheritdoc IClooverRaffleFactoryGetters
    function ticketSalesDurationLimits() external view returns (uint256 minDuration, uint256 maxDuration) {
        return (_config.minTicketSalesDuration, _config.maxTicketSalesDuration);
    }

    /// @inheritdoc IClooverRaffleFactoryGetters
    function isRegistered(address raffle) external view override returns (bool) {
        return _registeredRaffles.contains(raffle);
    }

    /// @inheritdoc IClooverRaffleFactoryGetters
    function getRegisteredRaffle() external view returns (address[] memory) {
        uint256 numberOfElements = _registeredRaffles.length();
        address[] memory activeNftCollections = new address[](numberOfElements);
        for (uint256 i = 0; i < numberOfElements; ++i) {
            activeNftCollections[i] = _registeredRaffles.at(i);
        }
        return activeNftCollections;
    }

    /// @inheritdoc IClooverRaffleFactoryGetters
    function version() external pure override returns (string memory) {
        return "1";
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";

import {IAccessController} from "../interfaces/IAccessController.sol";
import {IImplementationManager} from "../interfaces/IImplementationManager.sol";
import {IClooverRaffleFactorySetters} from "../interfaces/IClooverRaffleFactory.sol";

import {Errors} from "../libraries/Errors.sol";
import {ClooverRaffleFactoryEvents} from "../libraries/Events.sol";
import {ImplementationInterfaceNames} from "../libraries/ImplementationInterfaceNames.sol";
import {PercentageMath} from "../libraries/PercentageMath.sol";

import {ClooverRaffleFactoryStorage} from "./ClooverRaffleFactoryStorage.sol";

/// @title ClooverRaffleFactorySetters
/// @author Cloover
/// @notice Abstract contract exposing all setters and maintainer-related functions.
abstract contract ClooverRaffleFactorySetters is IClooverRaffleFactorySetters, ClooverRaffleFactoryStorage, Pausable {
    using PercentageMath for uint16;

    //----------------------------------------
    // Modifiers
    //----------------------------------------

    modifier onlyMaintainer() {
        IAccessController accessController = IAccessController(
            IImplementationManager(_implementationManager).getImplementationAddress(
                ImplementationInterfaceNames.AccessController
            )
        );
        if (!accessController.hasRole(accessController.MAINTAINER_ROLE(), msg.sender)) revert Errors.NOT_MAINTAINER();
        _;
    }

    //----------------------------------------
    // External function
    //----------------------------------------

    /// @inheritdoc IClooverRaffleFactorySetters
    function setProtocolFeeRate(uint16 newFeeRate) external onlyMaintainer {
        if (newFeeRate > PercentageMath.PERCENTAGE_FACTOR) revert Errors.EXCEED_MAX_PERCENTAGE();
        _config.protocolFeeRate = newFeeRate;
        emit ClooverRaffleFactoryEvents.ProtocolFeeRateUpdated(newFeeRate);
    }

    /// @inheritdoc IClooverRaffleFactorySetters
    function setInsuranceRate(uint16 newinsuranceRate) external onlyMaintainer {
        if (newinsuranceRate > PercentageMath.PERCENTAGE_FACTOR) revert Errors.EXCEED_MAX_PERCENTAGE();
        _config.insuranceRate = newinsuranceRate;
        emit ClooverRaffleFactoryEvents.InsuranceRateUpdated(newinsuranceRate);
    }

    /// @inheritdoc IClooverRaffleFactorySetters
    function setMinTicketSalesDuration(uint64 newMinTicketSalesDuration) external onlyMaintainer {
        if (newMinTicketSalesDuration >= _config.maxTicketSalesDuration) revert Errors.WRONG_DURATION_LIMITS();
        _config.minTicketSalesDuration = newMinTicketSalesDuration;
        emit ClooverRaffleFactoryEvents.MinTicketSalesDurationUpdated(newMinTicketSalesDuration);
    }

    /// @inheritdoc IClooverRaffleFactorySetters
    function setMaxTicketSalesDuration(uint64 newMaxTicketSalesDuration) external onlyMaintainer {
        if (newMaxTicketSalesDuration <= _config.minTicketSalesDuration) revert Errors.WRONG_DURATION_LIMITS();
        _config.maxTicketSalesDuration = newMaxTicketSalesDuration;
        emit ClooverRaffleFactoryEvents.MaxTicketSalesDurationUpdated(newMaxTicketSalesDuration);
    }

    /// @inheritdoc IClooverRaffleFactorySetters
    function setMaxTicketSupplyAllowed(uint16 newMaxTotalSupplyAllowed) external onlyMaintainer {
        _config.maxTicketSupplyAllowed = newMaxTotalSupplyAllowed;
        emit ClooverRaffleFactoryEvents.MaxTotalSupplyAllowedUpdated(newMaxTotalSupplyAllowed);
    }

    /// @inheritdoc IClooverRaffleFactorySetters
    function pause() external onlyMaintainer {
        _pause();
    }

    /// @inheritdoc IClooverRaffleFactorySetters
    function unpause() external onlyMaintainer {
        _unpause();
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                            METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*//////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*//////////////////////////////////////////////////////////////
                            EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*//////////////////////////////////////////////////////////////
                               ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*//////////////////////////////////////////////////////////////
                             EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            address recoveredAddress = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                keccak256(
                                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                                ),
                                owner,
                                spender,
                                value,
                                nonces[owner]++,
                                deadline
                            )
                        )
                    )
                ),
                v,
                r,
                s
            );

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                            METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*//////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*//////////////////////////////////////////////////////////////
                            EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*//////////////////////////////////////////////////////////////
                               ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*//////////////////////////////////////////////////////////////
                             EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            address recoveredAddress = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                keccak256(
                                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                                ),
                                owner,
                                spender,
                                value,
                                nonces[owner]++,
                                deadline
                            )
                        )
                    )
                ),
                v,
                r,
                s
            );

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IDAIPermit {
    /// @param holder The address of the token owner.
    /// @param spender The address of the token spender.
    /// @param nonce The owner's nonce, increases at each call to permit.
    /// @param expiry The timestamp at which the permit is no longer valid.
    /// @param allowed Boolean that sets approval amount, true for type(uint256).max and false for 0.
    /// @param v Must produce valid secp256k1 signature from the owner along with r and s.
    /// @param r Must produce valid secp256k1 signature from the owner along with v and s.
    /// @param s Must produce valid secp256k1 signature from the owner along with r and v.
    function permit(
        address holder,
        address spender,
        uint256 nonce,
        uint256 expiry,
        bool allowed,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/// @title AllowanceTransfer
/// @notice Handles ERC20 token permissions through signature based allowance setting and ERC20 token transfers by checking allowed amounts
/// @dev Requires user's token approval on the Permit2 contract
interface IAllowanceTransfer {
    /// @notice Thrown when an allowance on a token has expired.
    /// @param deadline The timestamp at which the allowed amount is no longer valid
    error AllowanceExpired(uint256 deadline);

    /// @notice Thrown when an allowance on a token has been depleted.
    /// @param amount The maximum amount allowed
    error InsufficientAllowance(uint256 amount);

    /// @notice Thrown when too many nonces are invalidated.
    error ExcessiveInvalidation();

    /// @notice Emits an event when the owner successfully invalidates an ordered nonce.
    event NonceInvalidation(
        address indexed owner, address indexed token, address indexed spender, uint48 newNonce, uint48 oldNonce
    );

    /// @notice Emits an event when the owner successfully sets permissions on a token for the spender.
    event Approval(
        address indexed owner, address indexed token, address indexed spender, uint160 amount, uint48 expiration
    );

    /// @notice Emits an event when the owner successfully sets permissions using a permit signature on a token for the spender.
    event Permit(
        address indexed owner,
        address indexed token,
        address indexed spender,
        uint160 amount,
        uint48 expiration,
        uint48 nonce
    );

    /// @notice Emits an event when the owner sets the allowance back to 0 with the lockdown function.
    event Lockdown(address indexed owner, address token, address spender);

    /// @notice The permit data for a token
    struct PermitDetails {
        // ERC20 token address
        address token;
        // the maximum amount allowed to spend
        uint160 amount;
        // timestamp at which a spender's token allowances become invalid
        uint48 expiration;
        // an incrementing value indexed per owner,token,and spender for each signature
        uint48 nonce;
    }

    /// @notice The permit message signed for a single token allownce
    struct PermitSingle {
        // the permit data for a single token alownce
        PermitDetails details;
        // address permissioned on the allowed tokens
        address spender;
        // deadline on the permit signature
        uint256 sigDeadline;
    }

    /// @notice The permit message signed for multiple token allowances
    struct PermitBatch {
        // the permit data for multiple token allowances
        PermitDetails[] details;
        // address permissioned on the allowed tokens
        address spender;
        // deadline on the permit signature
        uint256 sigDeadline;
    }

    /// @notice The saved permissions
    /// @dev This info is saved per owner, per token, per spender and all signed over in the permit message
    /// @dev Setting amount to type(uint160).max sets an unlimited approval
    struct PackedAllowance {
        // amount allowed
        uint160 amount;
        // permission expiry
        uint48 expiration;
        // an incrementing value indexed per owner,token,and spender for each signature
        uint48 nonce;
    }

    /// @notice A token spender pair.
    struct TokenSpenderPair {
        // the token the spender is approved
        address token;
        // the spender address
        address spender;
    }

    /// @notice Details for a token transfer.
    struct AllowanceTransferDetails {
        // the owner of the token
        address from;
        // the recipient of the token
        address to;
        // the amount of the token
        uint160 amount;
        // the token to be transferred
        address token;
    }

    /// @notice A mapping from owner address to token address to spender address to PackedAllowance struct, which contains details and conditions of the approval.
    /// @notice The mapping is indexed in the above order see: allowance[ownerAddress][tokenAddress][spenderAddress]
    /// @dev The packed slot holds the allowed amount, expiration at which the allowed amount is no longer valid, and current nonce thats updated on any signature based approvals.
    function allowance(address user, address token, address spender)
        external
        view
        returns (uint160 amount, uint48 expiration, uint48 nonce);

    /// @notice Approves the spender to use up to amount of the specified token up until the expiration
    /// @param token The token to approve
    /// @param spender The spender address to approve
    /// @param amount The approved amount of the token
    /// @param expiration The timestamp at which the approval is no longer valid
    /// @dev The packed allowance also holds a nonce, which will stay unchanged in approve
    /// @dev Setting amount to type(uint160).max sets an unlimited approval
    function approve(address token, address spender, uint160 amount, uint48 expiration) external;

    /// @notice Permit a spender to a given amount of the owners token via the owner's EIP-712 signature
    /// @dev May fail if the owner's nonce was invalidated in-flight by invalidateNonce
    /// @param owner The owner of the tokens being approved
    /// @param permitSingle Data signed over by the owner specifying the terms of approval
    /// @param signature The owner's signature over the permit data
    function permit(address owner, PermitSingle memory permitSingle, bytes calldata signature) external;

    /// @notice Permit a spender to the signed amounts of the owners tokens via the owner's EIP-712 signature
    /// @dev May fail if the owner's nonce was invalidated in-flight by invalidateNonce
    /// @param owner The owner of the tokens being approved
    /// @param permitBatch Data signed over by the owner specifying the terms of approval
    /// @param signature The owner's signature over the permit data
    function permit(address owner, PermitBatch memory permitBatch, bytes calldata signature) external;

    /// @notice Transfer approved tokens from one address to another
    /// @param from The address to transfer from
    /// @param to The address of the recipient
    /// @param amount The amount of the token to transfer
    /// @param token The token address to transfer
    /// @dev Requires the from address to have approved at least the desired amount
    /// of tokens to msg.sender.
    function transferFrom(address from, address to, uint160 amount, address token) external;

    /// @notice Transfer approved tokens in a batch
    /// @param transferDetails Array of owners, recipients, amounts, and tokens for the transfers
    /// @dev Requires the from addresses to have approved at least the desired amount
    /// of tokens to msg.sender.
    function transferFrom(AllowanceTransferDetails[] calldata transferDetails) external;

    /// @notice Enables performing a "lockdown" of the sender's Permit2 identity
    /// by batch revoking approvals
    /// @param approvals Array of approvals to revoke.
    function lockdown(TokenSpenderPair[] calldata approvals) external;

    /// @notice Invalidate nonces for a given (token, spender) pair
    /// @param token The token to invalidate nonces for
    /// @param spender The spender to invalidate nonces for
    /// @param newNonce The new nonce to set. Invalidates all nonces less than it.
    /// @dev Can't invalidate more than 2**16 nonces per transaction.
    function invalidateNonces(address token, address spender, uint48 newNonce) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

library SafeCast160 {
    /// @notice Thrown when a valude greater than type(uint160).max is cast to uint160
    error UnsafeCast();

    /// @notice Safely casts uint256 to uint160
    /// @param value The uint256 to be cast
    function toUint160(uint256 value) internal pure returns (uint160) {
        if (value > type(uint160).max) revert UnsafeCast();
        return uint160(value);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                // Solidity will revert if denominator == 0, unlike the div opcode on its own.
                // The surrounding unchecked block does not change this fact.
                // See https://docs.soliditylang.org/en/latest/control-structures.html#checked-or-unchecked-arithmetic.
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1, "Math: mulDiv overflow");

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator, Rounding rounding) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10 ** 64) {
                value /= 10 ** 64;
                result += 64;
            }
            if (value >= 10 ** 32) {
                value /= 10 ** 32;
                result += 32;
            }
            if (value >= 10 ** 16) {
                value /= 10 ** 16;
                result += 16;
            }
            if (value >= 10 ** 8) {
                value /= 10 ** 8;
                result += 8;
            }
            if (value >= 10 ** 4) {
                value /= 10 ** 4;
                result += 4;
            }
            if (value >= 10 ** 2) {
                value /= 10 ** 2;
                result += 2;
            }
            if (value >= 10 ** 1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10 ** result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 256, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result << 3) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.1) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/Address.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```solidity
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 *
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!Address.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized != type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import {ClooverRaffleTypes} from "../libraries/Types.sol";

interface IClooverRaffleGetters {
    /// @notice Return the total amount of tickets sold
    function currentTicketSupply() external view returns (uint16);

    /// @notice Return the max amount of tickets that can be sold
    function maxTicketSupply() external view returns (uint16);

    /// @notice Return the max amount of tickets that can be sold per participant
    /// @dev 0 means no limit
    function maxTicketPerWallet() external view returns (uint16);

    /// @notice Return the address of the wallet that initiated the raffle
    function creator() external view returns (address);

    /// @notice Return the address of the token used to buy tickets
    /// @dev If the raffle is in Eth mode, this value will be address(0)
    function purchaseCurrency() external view returns (address);

    /// @notice Return if the raffle accept only ETH
    function isEthRaffle() external view returns (bool);

    /// @notice Return the price of one ticket
    function ticketPrice() external view returns (uint256);

    /// @notice Return the end time where ticket sales closing
    function endTicketSales() external view returns (uint64);

    /// @notice Return the winning ticket number
    function winningTicketNumber() external view returns (uint16);

    /// @notice get the winner address
    function winnerAddress() external view returns (address);

    /// @notice Return info regarding the nft to win
    function nftInfo() external view returns (address nftContractAddress, uint256 nftId);

    /// @notice Return the current status of the raffle
    function raffleStatus() external view returns (ClooverRaffleTypes.Status);

    /// @notice Return all tickets number own by the address
    /// @dev This function should not be call by any contract as it can be very expensive in term of gas usage due to the nested loop
    /// should be use only by front end to display the tickets number own by an address
    function getParticipantTicketsNumber(address user) external view returns (uint16[] memory);

    /// @notice Return the address that own a specific ticket number
    function ownerOf(uint16 id) external view returns (address);

    /// @notice Return the randomProvider contract address
    function randomProvider() external view returns (address);

    /// @notice Return the amount of REFUNDABLE paid by the creator
    function insurancePaid() external view returns (uint256);

    /// @notice Return the amount of ticket that is covered by the REFUNDABLE
    /// @dev If the raffle is not in REFUNDABLE mode, this value will be 0
    function minTicketThreshold() external view returns (uint16);

    /// @notice Return the royalties rate to apply on ticket sales amount to pay to the nft collection creator
    function royaltiesRate() external view returns (uint16);

    /// @notice Return the version of the contract
    function version() external pure returns (string memory);
}

interface IClooverRaffle is IClooverRaffleGetters {
    /// @notice Function to initialize contract
    function initialize(ClooverRaffleTypes.InitializeRaffleParams memory params) external payable;

    /// @notice Allows users to purchase tickets with ERC20 tokens
    function purchaseTickets(uint16 nbOfTickets) external;

    /// @notice Allows users to purchase tickets with ERC20Permit tokens
    function purchaseTicketsWithPermit(uint16 nbOfTickets, ClooverRaffleTypes.PermitDataParams calldata permitData)
        external;

    /// @notice Allows users to purchase tickets with ETH
    function purchaseTicketsInEth(uint16 nbOfTickets) external payable;

    /// @notice Request a random numbers to the RandomProvider contract
    function draw() external;

    /// @notice Select the winning ticket number using the random number from Chainlink's VRFConsumerBaseV2
    /// @dev must be only called by the RandomProvider contract
    /// function must not revert to avoid multi drawn to revert and block contract in case of wrong value received
    function draw(uint256[] memory randomNumbers) external;

    /// @notice Allows the creator to exerce the REFUNDABLE he paid in ERC20 token for and claim back his nft
    function claimCreatorRefund() external;

    /// @notice Allows the creator to exerce the REFUNDABLE he paid in Eth for and claim back his nft
    function claimCreatorRefundInEth() external;

    /// @notice Allows the creator to claim the amount link to the ticket sales in ERC20 token
    function claimTicketSales() external;

    /// @notice Allows the creator to claim the amount link to the ticket sales in Eth
    function claimTicketSalesInEth() external;

    /// @notice Allows the winner to claim his price
    function claimPrize() external;

    /// @notice Allow tickets owner to claim refund if raffle is in REFUNDABLE mode in ERC20 token
    function claimParticipantRefund() external;

    /// @notice Allow tickets owner to claim refund if raffle is in REFUNDABLE mode in Eth
    function claimParticipantRefundInEth() external;

    /// @notice Allow the creator to cancel the raffle if no ticket has been sold
    function cancel() external;
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import {RandomProviderTypes} from "../libraries/Types.sol";

interface IRandomProvider {
    /// @notice Request a random numbers using ChainLinkVRFv2
    function requestRandomNumbers(uint32 numWords) external returns (uint256 requestId);

    /// @notice Return the raffle factory contract addres
    function clooverRaffleFactory() external view returns (address);

    /// @notice Return the implementationManager contract address
    function implementationManager() external view returns (address);

    /// @notice Return the address of the contract that requested the random number from the requestId
    function requestorAddressFromRequestId(uint256 requestId) external view returns (address);

    /// @notice Return the ChainlinkVRFData struct
    function chainlinkVRFData() external view returns (RandomProviderTypes.ChainlinkVRFData memory);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";

import {ClooverRaffleTypes} from "../libraries/Types.sol";

/// @title ClooverRaffleStorage
/// @author Cloover
/// @notice The storage shared by ClooverRaffle's contracts.
abstract contract ClooverRaffleStorage is Initializable {
    /// @dev the raffle config data
    ClooverRaffleTypes.ConfigData internal _config;

    /// @dev The life cycle data of the raffle
    ClooverRaffleTypes.LifeCycleData internal _lifeCycleData;

    /// @dev The list of entries purchased by participants
    ClooverRaffleTypes.PurchasedEntries[] internal _purchasedEntries;

    /// @dev Map of participant address to their purchase info
    mapping(address => ClooverRaffleTypes.ParticipantInfo) internal _participantInfoMap;

    //----------------------------------------
    // Constructor
    //----------------------------------------
    /// @notice Contract constructor.
    /// @dev The implementation contract disables initialization upon deployment to avoid being hijacked.
    constructor() {
        _disableInitializers();
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

import {IClooverRaffleGetters} from "../interfaces/IClooverRaffle.sol";
import {IImplementationManager} from "../interfaces/IImplementationManager.sol";

import {ClooverRaffleTypes} from "../libraries/Types.sol";
import {ImplementationInterfaceNames} from "../libraries/ImplementationInterfaceNames.sol";

import {ClooverRaffleInternal} from "./ClooverRaffleInternal.sol";

/// @title ClooverRaffleGetters
/// @author Cloover
/// @notice Abstract contract exposing all accessible getters.
abstract contract ClooverRaffleGetters is IClooverRaffleGetters, IERC721Receiver, ClooverRaffleInternal {
    //----------------------------------------
    // Getter functions
    //----------------------------------------

    /// @inheritdoc IClooverRaffleGetters
    function maxTicketSupply() external view override returns (uint16) {
        return _config.maxTicketSupply;
    }

    /// @inheritdoc IClooverRaffleGetters
    function currentTicketSupply() external view override returns (uint16) {
        return _lifeCycleData.currentTicketSupply;
    }

    /// @inheritdoc IClooverRaffleGetters
    function maxTicketPerWallet() external view override returns (uint16) {
        return _config.maxTicketPerWallet;
    }

    /// @inheritdoc IClooverRaffleGetters
    function creator() external view override returns (address) {
        return _config.creator;
    }

    /// @inheritdoc IClooverRaffleGetters
    function purchaseCurrency() external view override returns (address) {
        return _config.purchaseCurrency;
    }

    /// @inheritdoc IClooverRaffleGetters
    function ticketPrice() external view override returns (uint256) {
        return _config.ticketPrice;
    }

    /// @inheritdoc IClooverRaffleGetters
    function endTicketSales() external view override returns (uint64) {
        return _config.endTicketSales;
    }

    /// @inheritdoc IClooverRaffleGetters
    function winningTicketNumber() external view override returns (uint16) {
        return _lifeCycleData.winningTicketNumber;
    }

    /// @inheritdoc IClooverRaffleGetters
    function winnerAddress() external view override returns (address) {
        return _winnerAddress();
    }

    /// @inheritdoc IClooverRaffleGetters
    function nftInfo() external view override returns (address nftContractAddress, uint256 nftId) {
        return (_config.nftContract, _config.nftId);
    }

    /// @inheritdoc IClooverRaffleGetters
    function raffleStatus() external view override returns (ClooverRaffleTypes.Status) {
        return _lifeCycleData.status;
    }

    /// @inheritdoc IClooverRaffleGetters
    function getParticipantTicketsNumber(address user) external view override returns (uint16[] memory) {
        ClooverRaffleTypes.ParticipantInfo memory participantInfo = _participantInfoMap[user];
        if (participantInfo.nbOfTicketsPurchased == 0) return new uint16[](0);

        ClooverRaffleTypes.PurchasedEntries[] memory entries = _purchasedEntries;
        uint16[] memory userTickets = new uint16[](participantInfo.nbOfTicketsPurchased);
        uint16 entriesLength = uint16(participantInfo.purchasedEntriesIndexes.length);
        uint16 startIndex;
        for (uint16 i; i < entriesLength;) {
            uint16 entryIndex = participantInfo.purchasedEntriesIndexes[i];
            uint16 nbOfTicketsPurchased = entries[entryIndex].nbOfTickets;
            uint16 startNumber = entries[entryIndex].currentTicketsSold - nbOfTicketsPurchased;
            for (uint16 j; j < nbOfTicketsPurchased;) {
                userTickets[startIndex + j] = startNumber + j + 1;
                unchecked {
                    ++j;
                }
            }
            startIndex += nbOfTicketsPurchased;
            unchecked {
                ++i;
            }
        }
        return userTickets;
    }

    /// @inheritdoc IClooverRaffleGetters
    function ownerOf(uint16 id) external view override returns (address) {
        if (id > _lifeCycleData.currentTicketSupply || id == 0) return address(0);

        uint16 index = uint16(findUpperBound(_purchasedEntries, id));
        return _purchasedEntries[index].owner;
    }

    /// @inheritdoc IClooverRaffleGetters
    function randomProvider() external view override returns (address) {
        return IImplementationManager(_config.implementationManager).getImplementationAddress(
            ImplementationInterfaceNames.RandomProvider
        );
    }

    /// @inheritdoc IClooverRaffleGetters
    function isEthRaffle() external view override returns (bool) {
        return _config.isEthRaffle;
    }

    /// @inheritdoc IClooverRaffleGetters
    function insurancePaid() external view override returns (uint256) {
        return _calculateInsuranceCost();
    }

    /// @inheritdoc IClooverRaffleGetters
    function minTicketThreshold() external view override returns (uint16) {
        return _config.minTicketThreshold;
    }

    /// @inheritdoc IClooverRaffleGetters
    function royaltiesRate() external view override returns (uint16) {
        return _config.royaltiesRate;
    }

    /// @inheritdoc IClooverRaffleGetters
    function version() external pure override returns (string memory) {
        return "1";
    }

    /// @notice required by ERC721Receiver interface for ERC721 safeTransferFrom
    function onERC721Received(address, address, uint256, bytes calldata) external pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {ERC20, SafeTransferLib} from "@solmate/utils/SafeTransferLib.sol";
import {ERC721} from "@solmate/tokens/ERC721.sol";

import {IImplementationManager} from "../interfaces/IImplementationManager.sol";

import {ImplementationInterfaceNames} from "../libraries/ImplementationInterfaceNames.sol";
import {Errors} from "../libraries/Errors.sol";
import {ClooverRaffleEvents} from "../libraries/Events.sol";
import {ClooverRaffleTypes} from "../libraries/Types.sol";
import {PercentageMath} from "../libraries/PercentageMath.sol";
import {InsuranceLib} from "../libraries/InsuranceLib.sol";

import {ClooverRaffleStorage} from "./ClooverRaffleStorage.sol";

/// @title ClooverRaffleInternal
/// @author Cloover
/// @notice Abstract contract exposing `Raffle`'s internal functions.
abstract contract ClooverRaffleInternal is ClooverRaffleStorage {
    using PercentageMath for uint256;
    using InsuranceLib for uint16;
    using SafeTransferLib for ERC20;

    //----------------------------------------
    // Internal functions
    //----------------------------------------

    /// @notice handle the purchase of tickets in ERC20
    function _purchaseTicketsInToken(uint16 nbOfTickets) internal {
        if (_config.isEthRaffle) revert Errors.IS_ETH_RAFFLE();

        uint256 ticketCost = _calculateTicketsCost(nbOfTickets);

        _purchaseTickets(nbOfTickets);

        ERC20(_config.purchaseCurrency).safeTransferFrom(msg.sender, address(this), ticketCost);
    }

    /// @notice attribute ticket to msg.sender
    function _purchaseTickets(uint16 nbOfTickets) internal {
        if (nbOfTickets == 0) revert Errors.CANT_BE_ZERO();

        uint16 maxTicketPerWallet = _config.maxTicketPerWallet;
        if (
            maxTicketPerWallet > 0
                && _participantInfoMap[msg.sender].nbOfTicketsPurchased + nbOfTickets > maxTicketPerWallet
        ) {
            revert Errors.EXCEED_MAX_TICKET_ALLOWED_TO_PURCHASE();
        }

        uint16 currentTicketSupply = _lifeCycleData.currentTicketSupply;
        if (currentTicketSupply + nbOfTickets > _config.maxTicketSupply) {
            revert Errors.TICKET_SUPPLY_OVERFLOW();
        }

        uint16 purchasedEntriesIndex = uint16(_purchasedEntries.length);
        uint16 currentTicketsSold = _lifeCycleData.currentTicketSupply + nbOfTickets;

        _purchasedEntries.push(
            ClooverRaffleTypes.PurchasedEntries({
                owner: msg.sender,
                currentTicketsSold: currentTicketsSold,
                nbOfTickets: nbOfTickets
            })
        );

        _participantInfoMap[msg.sender].nbOfTicketsPurchased += nbOfTickets;
        _participantInfoMap[msg.sender].purchasedEntriesIndexes.push(purchasedEntriesIndex);

        _lifeCycleData.currentTicketSupply = currentTicketsSold;

        emit ClooverRaffleEvents.TicketsPurchased(msg.sender, currentTicketSupply, nbOfTickets);
    }

    /// @notice calculate the amount to transfer to the creator, protocol and royalties
    function _calculateAmountToTransfer(uint256 totalBalance)
        internal
        view
        returns (uint256 creatorAmount, uint256 protocolFeesAmount, uint256 royaltiesAmount)
    {
        uint256 insuranceCost = _calculateInsuranceCost();
        uint256 ticketSalesAmount = totalBalance - insuranceCost;
        protocolFeesAmount = ticketSalesAmount.percentMul(_config.protocolFeeRate);
        royaltiesAmount = ticketSalesAmount.percentMul(_config.royaltiesRate);
        creatorAmount = ticketSalesAmount - protocolFeesAmount - royaltiesAmount + insuranceCost;
    }

    /// @notice check raffle can be in REFUNDABLE mode and return the amount to transfer to the treasury and its address
    function _handleCreatorInsurance() internal returns (uint256 treasuryAmountToTransfer, address treasuryAddress) {
        uint16 minTicketThreshold = _config.minTicketThreshold;
        if (minTicketThreshold == 0) revert Errors.NO_INSURANCE_TAKEN();
        uint16 currentTicketSupply = _lifeCycleData.currentTicketSupply;
        if (currentTicketSupply == 0) revert Errors.NOTHING_TO_CLAIM();

        if (currentTicketSupply >= minTicketThreshold) {
            revert Errors.SALES_EXCEED_MIN_THRESHOLD_LIMIT();
        }

        _lifeCycleData.status = ClooverRaffleTypes.Status.REFUNDABLE;

        (treasuryAmountToTransfer,) = minTicketThreshold.splitInsuranceAmount(
            _config.insuranceRate, _config.protocolFeeRate, currentTicketSupply, _config.ticketPrice
        );
        treasuryAddress = IImplementationManager(_config.implementationManager).getImplementationAddress(
            ImplementationInterfaceNames.Treasury
        );
    }

    function _calculateUserRefundAmount() internal returns (uint256 totalRefundAmount) {
        if (_lifeCycleData.currentTicketSupply >= _config.minTicketThreshold) {
            revert Errors.SALES_EXCEED_MIN_THRESHOLD_LIMIT();
        }

        ClooverRaffleTypes.ParticipantInfo storage participantInfo = _participantInfoMap[msg.sender];
        if (participantInfo.hasClaimedRefund) revert Errors.ALREADY_CLAIMED();
        participantInfo.hasClaimedRefund = true;

        uint256 nbOfTicketPurchased = participantInfo.nbOfTicketsPurchased;
        if (nbOfTicketPurchased == 0) revert Errors.NOTHING_TO_CLAIM();

        totalRefundAmount =
            _calculateTicketsCost(nbOfTicketPurchased) + _calculateUserInsurancePart(nbOfTicketPurchased);
    }

    /// @notice calculate the amount of REFUNDABLE assign to the user
    function _calculateUserInsurancePart(uint256 nbOfTicketPurchased)
        internal
        view
        returns (uint256 userAmountToReceive)
    {
        (, uint256 amountPerTicket) = _config.minTicketThreshold.splitInsuranceAmount(
            _config.insuranceRate, _config.protocolFeeRate, _lifeCycleData.currentTicketSupply, _config.ticketPrice
        );
        userAmountToReceive = amountPerTicket * nbOfTicketPurchased;
    }

    /// @notice calculate the amount of REFUNDABLE paid by the creator
    function _calculateInsuranceCost() internal view returns (uint256 insuranceCost) {
        if (_config.minTicketThreshold == 0) return insuranceCost;
        insuranceCost = _config.minTicketThreshold.calculateInsuranceCost(_config.insuranceRate, _config.ticketPrice);
    }

    /// @notice calculate the total price that must be paid regarding the amount of tickets to buy
    function _calculateTicketsCost(uint256 nbOfTickets) internal view returns (uint256 amountPrice) {
        amountPrice = _config.ticketPrice * nbOfTickets;
    }

    /// @notice return the address of the winner
    function _winnerAddress() internal view returns (address) {
        if (_lifeCycleData.winningTicketNumber == 0) return address(0);
        uint256 index = findUpperBound(_purchasedEntries, _lifeCycleData.winningTicketNumber);
        return _purchasedEntries[index].owner;
    }

    /// @notice Searches a sorted `array` and returns the first index that contains the `ticketNumberToSearch`
    /// https://docs.openzeppelin.com/contracts/3.x/api/utils#Arrays-findUpperBound-uint256---uint256-
    function findUpperBound(ClooverRaffleTypes.PurchasedEntries[] memory array, uint256 ticketNumberToSearch)
        internal
        pure
        returns (uint256)
    {
        if (array.length == 0) return 0;

        uint256 low = 0;
        uint256 high = array.length;

        while (low < high) {
            uint256 mid = Math.average(low, high);
            if (array[mid].currentTicketsSold > ticketNumberToSearch) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }

        if (low > 0 && array[low - 1].currentTicketsSold == ticketNumberToSearch) {
            return low - 1;
        } else {
            return low;
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import {ClooverRaffleTypes} from "../libraries/Types.sol";

/// @title ClooverRaffleFactoryStorage
/// @author Cloover
/// @notice The storage shared by ClooverRaffleFactory's contracts.
abstract contract ClooverRaffleFactoryStorage {
    uint256 internal constant MIN_TICKET_PRICE = 10000;

    /// @notice The implementationManager contract
    address internal _implementationManager;

    /// @notice The raffle implementation contract address
    address internal _raffleImplementation;

    /// @notice Map of registered raffle
    EnumerableSet.AddressSet internal _registeredRaffles;

    /// @notice The global config and limits for raffles
    ClooverRaffleTypes.FactoryConfig internal _config;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";

interface IAccessController is IAccessControl {
    function MAINTAINER_ROLE() external view returns (bytes32);
    function MANAGER_ROLE() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.8.0/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
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
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}