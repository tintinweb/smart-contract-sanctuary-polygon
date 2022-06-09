// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/structs/EnumerableSet.sol)

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
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
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
        return _values(set._inner);
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
     * @dev Returns the number of values on the set. O(1).
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

        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { ReentrancyGuardStorage } from './ReentrancyGuardStorage.sol';

/**
 * @title Utility contract for preventing reentrancy attacks
 */
abstract contract ReentrancyGuard {
    modifier nonReentrant() {
        ReentrancyGuardStorage.Layout storage l = ReentrancyGuardStorage
            .layout();
        require(l.status != 2, 'ReentrancyGuard: reentrant call');
        l.status = 2;
        _;
        l.status = 1;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library ReentrancyGuardStorage {
    struct Layout {
        uint256 status;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256('solidstate.contracts.storage.ReentrancyGuard');

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import "@solidstate/contracts/utils/ReentrancyGuard.sol";

import "../interfaces/PortToken/IPortTokenControllable.sol";
import {Modifiers} from "../libraries/Modifiers.sol";
import "../libraries/LibPriceInterface.sol";
import "../libraries/LibTrackedToken.sol";
import "../libraries/LibDexInterface.sol";

contract DexInterfaceFacet is Modifiers, ReentrancyGuard {
    using EnumerableSet for EnumerableSet.AddressSet;

    struct SwapCallParams {
        address dex;
        address fromToken;
        address toToken;
        uint256 fromAmount;
        uint256 toAmount;
        bytes dexCalldata;
    }

    event DexEnabled(address indexed dexAddr);
    event DexDisabled(address indexed dexAddr);
    event RebalancedUsingDex(address indexed portTokenAddr, address indexed from, address indexed to, uint256 fromAmount, uint256 toAmount);

    // see LibTrackedToken for original definition, needed for ethers.js catch event
    event TrackedTokenBalancesChanged(address indexed portTokenAddress, uint256 portTokenSupply, address[] tokenAddrs, uint256[] amounts);
    event TrackedTokenTargetAmountsChanged(address indexed addr, address[] trackedTokens, uint256[] targetAmounts);

    /// @notice Adds dex address to white list
    /// @param _dexAddr dex address
    function allowDex(address _dexAddr) external onlyOwner {
        LibDexInterface.diamondStorage().dexAddressWhitelist.add(_dexAddr);
        emit DexEnabled(_dexAddr);
    }

    /// @notice Removes dex address from white list
    /// @param _dexAddr dex address
    function disallowDex(address _dexAddr) external onlyOwner {
        LibDexInterface.diamondStorage().dexAddressWhitelist.remove(_dexAddr);
        emit DexDisabled(_dexAddr);
    }

    /// @notice Check if dex address is in whitelist
    /// @param _dexAddr dex address
    function isDexAllowed(address _dexAddr) public view returns (bool) {
        return LibDexInterface.diamondStorage().dexAddressWhitelist.contains(_dexAddr);
    }

    /// @notice Get All allowed dexes, offchain use intended
    function getAllowedDexList() external view returns (address[] memory) {
        return LibDexInterface.diamondStorage().dexAddressWhitelist.values();
    }

    // TODO Move to library
    function _approveTrackedToken(
        address _addr,
        address _dexAddr,
        address _trackedAddr,
        uint256 _amount
    ) internal {
        IPortTokenControllable token = IPortTokenControllable(_addr);
        bytes memory res;

        res = token.externalCall(_trackedAddr, abi.encodeWithSelector(IERC20.approve.selector, _dexAddr, 0), 0, "Allowance reset failed");
        if (res.length > 0) {
            require(abi.decode(res, (bool)), "Allowance reset failed");
        }
        if (_amount > 0) {
            res = token.externalCall(_trackedAddr, abi.encodeWithSelector(IERC20.approve.selector, _dexAddr, _amount), 0, "Allowance change failed");
            if (res.length > 0) {
                require(abi.decode(res, (bool)), "Allowance change failed");
            }
        }
    }

    /**
     @notice trade amount of tracked token for equaly valuable amount of other tracked token, 
             adjust target amounts afterwards,
             doesn't add or remove tracked tokens
     @dev checks: 
        - Dex is whitelisted
        - Not paused
        - From and to are not the same
        - Function call was initiated by portfolio token manager
        - To token is tracked and allowed (no check for from token to allow to absorb untracked tokens into portfolio)
        - There is enough from tokens for requested call
        - Utility token share constraints hold after the swap
        - Portfolio receives at least toAmount of to token

        No extra check for from balance needed, dex wont be able to spend more than approval
     @param _addr port token address
     @param _call SwapCallParams structure with parameters for dex call
    */
    function swapUsingDexCalldata(address _addr, SwapCallParams memory _call) external onlyTokenManager(_addr) whenNotPaused nonReentrant {
        require(LibDexInterface.diamondStorage().dexAddressWhitelist.contains(_call.dex), "Unknown DEX address");
        require(_call.fromAmount > 0, "Zero swap amount provided");
        require(_call.fromToken != _call.toToken, "Same source and target");
        require(
            LibTrackedToken.configForToken(_addr).trackedTokens.contains(_call.toToken) && LibTokenWhitelist.isAllowed(_call.toToken),
            "Target not tracked/allowed"
        );

        uint256 oldToBalance = IERC20(_call.toToken).balanceOf(_addr);
        uint256 oldFromBalance = IERC20(_call.fromToken).balanceOf(_addr);
        require(oldFromBalance >= _call.fromAmount, "Swap amount exceeds balance");

        _approveTrackedToken(_addr, _call.dex, _call.fromToken, _call.fromAmount);

        IPortTokenControllable portToken = IPortTokenControllable(_addr);
        portToken.externalCall(_call.dex, _call.dexCalldata, 0, "DEX call failed");
        _approveTrackedToken(_addr, _call.dex, _call.fromToken, 0);

        LibTrackedToken.TrackedTokensList memory tl = LibTrackedToken.getTotalRealAmount(_addr);
        require(LibPriceInterface.checkUtilityTokenShare(portToken.manager(), tl.tokens, tl.amounts), "Need more utility token");

        // no extra check for from balance needed, dex wont be able to spend more than approval
        uint256 newFromBalance = IERC20(_call.fromToken).balanceOf(_addr);
        uint256 newToBalance = IERC20(_call.toToken).balanceOf(_addr);
        require(newToBalance >= oldToBalance + _call.toAmount, "Not enough to tokens received");

        emit RebalancedUsingDex(_addr, _call.fromToken, _call.toToken, oldFromBalance - newFromBalance, newToBalance - oldToBalance);
        LibTrackedToken.emitTrackedTokenBalancesChanged(_addr);

        // adjust target amounts after rebalance
        LibTrackedToken.syncTargetAmount(_addr);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IAggregatorV3Minimal {
    function decimals() external view returns (uint8);

    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IOffchainOracle {
    function getRate(IERC20 srcToken, IERC20 dstToken, bool useWrappers) external view returns (uint256 weightedRate);    
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./IPortTokenControllable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";


interface IPortToken is IERC20Upgradeable, IERC20MetadataUpgradeable, IPortTokenControllable {
    function burn(uint256 amount) external;
    function burnFrom(address account, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPortTokenControllable {
    function controller() external view returns (address);

    function manager() external view returns (address);

    function changeController(address newController) external;

    function changeManager(address newManager) external;

    function controllerMint(address account, uint256 amount) external;

    function controllerBurn(address account, uint256 amount) external;

    function externalCall(
        address target,
        bytes calldata data,
        uint256 value,
        string memory errorMessage
    ) external returns (bytes memory returndata);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

library LibDexInterface {
    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("portfolio.dexinterface");
    struct DiamondStorage {
        EnumerableSet.AddressSet dexAddressWhitelist;
    }

    function diamondStorage() internal pure returns (DiamondStorage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import "../interfaces/PortToken/IPortToken.sol";
import "./LibTrackedToken.sol";
import "./LibTokenWhitelist.sol";

library LibFee {
    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("portfolio.streamingfee.v2");
    uint256 constant FEE_DENOMINATOR = 1000;
    /* 14 % platform fee */
    uint256 constant PLATFORM_FEE = 140;

    struct TokenFeeSettings {
        uint16 streamingFeeValue;
        uint16 successFeeValue;
        address successFeeBaseToken;
    }

    struct FeeLimits {
        uint16 minSuccessFee;
        uint16 maxSuccessFee;
        uint16 minStreamingFee;
        uint16 maxStreamingFee;
    }

    struct FeeData {
        uint16 successFee;
        uint16 streamingFee;
        uint256 lastMintedAt;
        address successFeeBase;
        uint256 lastMaxPrice;
    }

    // struct StreamingFeeData {
    //     uint16 value;
    //     uint256 lastAccumulatedAt;
    //     uint256 lastReleasedAt;
    //     uint256 accumulatedAmount;
    //     uint256 releasedAmount;
    // }

    // struct SuccessFeeData {
    //     uint16 value;
    //     address baseToken;
    //     uint256 lastMaxPrice;
    //     uint256 lastAccumulatedAt;
    //     uint256 accumulatedAmount;
    // }

    struct DiamondStorage {
        // mapping(address => StreamingFeeData) streamingFeeData;
        // mapping(address => SuccessFeeData) successFeeData;
        FeeLimits feeLimits;
        mapping(address => FeeData) feeData;
        address feeVault;
    }

    event StreamingFeeChanged(address indexed portTokenAddr, uint32 feeValue);
    event StreamingFeeAccumulated(address indexed portTokenAddr, uint256 amount);

    event SuccessFeeInitialized(address indexed portTokenAddr, address baseTokenAddr, uint256 initialPrice);
    event SuccessFeeChanged(address indexed portTokenAddr, uint32 feeValue);
    event SuccessFeeAccumulated(address indexed portTokenAddr, uint256 amount);
    event HighTideUpdated(address indexed portTokenAddr, uint256 newMaxPrice);

    event FeeMinted(address indexed portTokenAddr, uint256 amount);

    function diamondStorage() internal pure returns (DiamondStorage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    // function streamingFeeDataForToken(address _addr) internal view returns (StreamingFeeData storage) {
    //     DiamondStorage storage ds = diamondStorage();
    //     return ds.streamingFeeData[_addr];
    // }

    // function successFeeDataForToken(address _addr) internal view returns (SuccessFeeData storage) {
    //     DiamondStorage storage ds = diamondStorage();
    //     return ds.successFeeData[_addr];
    // }

    function feeDataForToken(address _addr) internal view returns (FeeData storage) {
        DiamondStorage storage ds = diamondStorage();
        return ds.feeData[_addr];
    }

    function setStreamingFee(address _addr, uint16 _value) internal {
        DiamondStorage storage ds = diamondStorage();
        require(_value <= ds.feeLimits.maxStreamingFee && _value >= ds.feeLimits.minStreamingFee, "Invalid streaming fee");

        feeDataForToken(_addr).streamingFee = _value;

        emit StreamingFeeChanged(_addr, _value);
    }

    function setSuccessFee(address _addr, uint16 _value) internal {
        DiamondStorage storage ds = diamondStorage();
        require(_value <= ds.feeLimits.maxSuccessFee && _value >= ds.feeLimits.minSuccessFee, "Invalid success fee");

        feeDataForToken(_addr).successFee = _value;

        emit SuccessFeeChanged(_addr, _value);
    }

    /// @notice set high tide value to target token price without minting success fee
    function initSuccessFee(
        address portTokenAddr,
        address baseToken,
        uint256 price
    ) internal {
        if (baseToken == address(0)) {
            baseToken = LibPriceInterface.diamondStorage().baseToken;
        }

        require(LibTokenWhitelist.isAllowed(baseToken), "invalid base token");

        FeeData storage d = feeDataForToken(portTokenAddr);
        require(d.lastMaxPrice == 0, "success fee already initialized");

        d.successFeeBase = baseToken;
        d.lastMaxPrice = price;

        emit SuccessFeeInitialized(portTokenAddr, baseToken, price);
    }

    function initFees(
        address portTokenAddr,
        TokenFeeSettings memory feeSettings,
        uint256 initialPrice
    ) internal {
        initSuccessFee(portTokenAddr, feeSettings.successFeeBaseToken, initialPrice);
        setStreamingFee(portTokenAddr, feeSettings.streamingFeeValue);
        setSuccessFee(portTokenAddr, feeSettings.successFeeValue);

        feeDataForToken(portTokenAddr).lastMintedAt = block.timestamp;
    }

    /// @notice get amount of already minted, but unclaimed fees
    function getUnclaimedFeeAmount(address portTokenAddr) internal view returns (uint256) {
        return IPortToken(portTokenAddr).balanceOf(diamondStorage().feeVault);
    }

    /// @notice calculate amount of not yet accumulated success fee with current portfolio token price
    // TODO  extend natspec
    function getPendingSuccessFee(address portTokenAddr) internal view returns (uint256 amount, uint256 currentTokenPrice) {
        FeeData storage d = feeDataForToken(portTokenAddr);
        if (d.successFeeBase == address(0)) {
            return (0, 0);
        }

        uint256 pendingStreamingFee = getPendingStreamingFee(portTokenAddr);
        currentTokenPrice = LibTrackedToken.getRealPortTokenPriceInOtherToken(portTokenAddr, d.successFeeBase, pendingStreamingFee);

        if (d.successFee > 0 && currentTokenPrice > d.lastMaxPrice) {
            // amount in % is A%=(OLD_MAX-NEW_MAX)/OLD_MAX*FEE_VALUE
            // amount in token units is AABS = A%*TotalSupply

            amount =
                ((currentTokenPrice - d.lastMaxPrice) * d.successFee * (IERC20(portTokenAddr).totalSupply() + pendingStreamingFee)) /
                d.lastMaxPrice /
                FEE_DENOMINATOR;
        }
    }

    /// @notice calculate amount of not yet accumulated streaming fee for provided timestamp, use block.timestamp if 0 timestamp was provided
    function getPendingStreamingFee(address portTokenAddr, uint256 timestamp) internal view returns (uint256 amount) {
        FeeData storage d = feeDataForToken(portTokenAddr);

        if (d.streamingFee > 0) {
            if (timestamp == 0) {
                timestamp = block.timestamp;
            }
            if (timestamp <= d.lastMintedAt) {
                return 0;
            }

            //streaming fee value d.value is in 1/1000 (1000==100%) per year
            //means streaming fee per second = d.value/31536000 (seconds in one year)
            uint256 unclaimedAmount = getUnclaimedFeeAmount(portTokenAddr);

            amount =
                ((IPortToken(portTokenAddr).totalSupply() - unclaimedAmount) * d.streamingFee * (timestamp - d.lastMintedAt)) /
                31536000 /
                LibFee.FEE_DENOMINATOR;
        }
    }

    /// @notice calculate amount of not yet accumulated streaming fee for current block time
    function getPendingStreamingFee(address portTokenAddr) internal view returns (uint256 amount) {
        return getPendingStreamingFee(portTokenAddr, 0);
    }

    function accumulateAndMintFees(address portTokenAddr) internal {
        FeeData storage d = feeDataForToken(portTokenAddr);

        // avoid double mint in same block
        if (d.lastMintedAt >= block.timestamp) {
            return;
        }

        uint256 accumulatedStreamingFee = getPendingStreamingFee(portTokenAddr);
        if (accumulatedStreamingFee > 0) {
            emit StreamingFeeAccumulated(portTokenAddr, accumulatedStreamingFee);
        }

        (uint256 accumulatedSuccessFee, uint256 currentTokenPrice) = getPendingSuccessFee(portTokenAddr);

        // accumulate new fees if success fee not 0 and if old high tide was not 0
        if (currentTokenPrice > d.lastMaxPrice) {
            d.lastMaxPrice = currentTokenPrice;

            if (accumulatedSuccessFee > 0) {
                emit SuccessFeeAccumulated(portTokenAddr, accumulatedSuccessFee);
            }

            emit HighTideUpdated(portTokenAddr, currentTokenPrice);
        }

        uint256 totalAccumulatedFee = accumulatedStreamingFee + accumulatedSuccessFee;

        d.lastMintedAt = block.timestamp;

        if (totalAccumulatedFee == 0) {
            return;
        }

        address feeVault = diamondStorage().feeVault;
        require(feeVault != address(0), "fee distributor should be initialized");
        IPortToken(portTokenAddr).controllerMint(feeVault, totalAccumulatedFee);

        emit FeeMinted(portTokenAddr, totalAccumulatedFee);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

library LibPause {
    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("portfolio.pause.v1");
    struct DiamondStorage {
        bool isPaused;
        mapping(address => bool) pausedManagers;
    }

    function diamondStorage() internal pure returns (DiamondStorage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    function isPaused() internal view returns (bool) {
        return diamondStorage().isPaused;
    }

    function isManagerPaused(address _manager) internal view returns (bool) {
        return diamondStorage().pausedManagers[_manager];
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "../interfaces/IAggregatorV3.sol";
import "../interfaces/IOffchainOracle.sol";

library LibChainlinkUtils {
    function getAnswer(address _feed) internal view returns (uint8 decimals, int256 price) {
        require(_feed != address(0));
        IAggregatorV3Minimal feed = IAggregatorV3Minimal(_feed);
        (, price, , , ) = feed.latestRoundData();
        decimals = feed.decimals();
    }

    function getDerivedPrice(
        address _tokenFeed,
        address _baseFeed,
        uint8 _baseTokenDecimals
    ) internal view returns (uint256 price) {
        (uint8 tokenFeedDecimals, int256 tokenPrice) = getAnswer(_tokenFeed);
        (uint8 baseFeedDecimals, int256 basePrice) = getAnswer(_baseFeed);
        require(tokenPrice >= 0 && basePrice >= 0);

        //price in base units
        price = (uint256(tokenPrice) * (10**_baseTokenDecimals)) / uint256(basePrice);

        //  adjust if price feed have different decimals
        if (tokenFeedDecimals > baseFeedDecimals) {
            price = price / (10**(tokenFeedDecimals - baseFeedDecimals));
        } else if (tokenFeedDecimals < baseFeedDecimals) {
            price = price * (10**(baseFeedDecimals - tokenFeedDecimals));
        }
    }
}

library LibPriceInterface {
    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("portfolio.priceinterface.v1");
    uint256 constant SHARE_DENOMINATOR = 10000;

    // feedType: feedTypes with id>=200 considered unsafe and shouldn't be used in production
    // 1: chainlink usdc feed
    // 254: 1inch offchain oracle
    struct PriceSourceSettings {
        address feed;
        uint8 feedType;
    }

    struct DiamondStorage {
        address baseToken; // token to price against
        address utilityToken; // utility token address
        uint16 minUtilityTokenShare; // desired minimum utility token share in 1/10000 (1%=100)
        mapping(address => PriceSourceSettings) priceSources;
        bool allowUnreliablePriceSources;
        uint256 minTokenValuation; // portfolio token has a significant balance of tracked token if locked tracked token valuation exceeds this value (converted to base token)
        uint256 minUtilityTokenBalance; // utility token balance required to skip utility token share check
    }

    function diamondStorage() internal pure returns (DiamondStorage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    function hasPriceSource(address _addr) internal view returns (bool) {
        DiamondStorage storage ds = diamondStorage();
        PriceSourceSettings storage os = ds.priceSources[_addr];
        return (os.feed != address(0) && os.feedType > 0 && (os.feedType < 200 || ds.allowUnreliablePriceSources));
    }

    /// @notice checks if price of provided amount of token in greater than minTokenValuation
    /// @param _addr ERC20 token address
    /// @param _amount amount of token
    /// @return isSignificant
    function amountIsSignificant(address _addr, uint256 _amount) internal view returns (bool isSignificant) {
        return priceIsSignificant(_addr, getTokenPrice(_addr, _amount));
    }

    // TODO description
    function priceIsSignificant(address /*_addr*/, uint256 _price)  internal view returns (bool isSignificant) {
        return _price > diamondStorage().minTokenValuation;
    }

    // get amount of base token  per _amount of token
    function getTokenPrice(address _addr, uint256 _amount) internal view returns (uint256 price) {
        DiamondStorage storage ds = diamondStorage();
        if (ds.baseToken == _addr) {
            return _amount;
        }

        PriceSourceSettings storage os = ds.priceSources[_addr];
        require(hasPriceSource(_addr), "No price source for token");

        if (os.feedType == 1) {
            PriceSourceSettings storage bs = ds.priceSources[ds.baseToken];
            require(os.feed != address(0), "No chainlink price feed for base");

            price =
                (LibChainlinkUtils.getDerivedPrice(os.feed, bs.feed, IERC20Metadata(ds.baseToken).decimals()) * _amount) /
                (10**IERC20Metadata(_addr).decimals());
        } else if (os.feedType == 254) {
            price = (IOffchainOracle(os.feed).getRate(IERC20(_addr), IERC20(ds.baseToken), true) * _amount) / (10**IERC20Metadata(_addr).decimals());
        }
    }

    // get amount of token per _amount of base token
    function getTokenForPrice(address _addr, uint256 _price) internal view returns (uint256 amount) {
        DiamondStorage storage ds = diamondStorage();
        if (ds.baseToken == _addr) {
            return _price;
        }

        PriceSourceSettings storage os = ds.priceSources[_addr];
        require(hasPriceSource(_addr), "No price source for token");

        if (os.feedType == 1) {
            PriceSourceSettings storage bs = ds.priceSources[ds.baseToken];
            require(os.feed != address(0), "No chainlink price feed for base");

            amount =
                (LibChainlinkUtils.getDerivedPrice(bs.feed, os.feed, IERC20Metadata(_addr).decimals()) * _price) /
                (10**IERC20Metadata(ds.baseToken).decimals());
        } else if (os.feedType == 254) {
            amount = (IOffchainOracle(os.feed).getRate(IERC20(ds.baseToken), IERC20(_addr), true) * _price) / 10**IERC20Metadata(_addr).decimals();
            // * rate multiplicator / rate denumenator * amount / amount denumerator,  and rate multiplicator == amount denumenator
        }
    }

    // get total amount of base token units equal to amounts of tokens
    function getTokensTotalPrice(address[] memory _tokens, uint256[] memory _amounts) internal view returns (uint256) {
        uint256 totalPrice = 0;
        for (uint256 i = 0; i < _tokens.length; i++) {
            address _addr = _tokens[i];
            totalPrice += getTokenPrice(_addr, _amounts[i]);
        }

        return totalPrice;
    }

    function getUtilityTokenShare(address[] memory _tokens, uint256[] memory _amounts) internal view returns (uint256) {
        uint256 totalPrice;
        uint256 utilityPrice;

        for (uint256 i = 0; i < _tokens.length; i++) {
            uint256 price = getTokenPrice(_tokens[i], _amounts[i]);
            totalPrice += price;

            if (_tokens[i] == diamondStorage().utilityToken) {
                utilityPrice = price;
            }
        }
        require(totalPrice > 0, "Total token price is 0");

        return (utilityPrice * SHARE_DENOMINATOR) / totalPrice;
    }

    function checkUtilityTokenShare(
        address portTokenOwner,
        address[] memory _tokens,
        uint256[] memory _amounts
    ) internal view returns (bool) {
        DiamondStorage storage ds = diamondStorage();
        if (ds.minUtilityTokenShare == 0) {
            return true;
        }

        if (
            portTokenOwner != address(0) &&
            ds.minUtilityTokenBalance > 0 &&
            IERC20(ds.utilityToken).balanceOf(portTokenOwner) >= ds.minUtilityTokenBalance
        ) {
            return true;
        }

        return getUtilityTokenShare(_tokens, _amounts) >= ds.minUtilityTokenShare;
    }

    function estimateMinUtilityTokenAmount(address[] memory _tokens, uint256[] memory _amounts) internal view returns (uint256) {
        DiamondStorage storage ds = diamondStorage();
        if (ds.minUtilityTokenShare == 0) {
            return 0;
        }

        uint256 totalPrice = getTokensTotalPrice(_tokens, _amounts);
        uint256 utilityUnit = 10**IERC20Metadata(ds.utilityToken).decimals();
        uint256 utilityPrice = getTokenPrice(ds.utilityToken, utilityUnit);

        return (((totalPrice * ds.minUtilityTokenShare) / SHARE_DENOMINATOR) * utilityUnit) / utilityPrice;
    }

    function estimateAmountsFromTotalPrice(
        uint256 _totalPrice,
        address[] memory _tokens,
        uint256[] memory _ratios
    ) internal view returns (uint256[] memory _amounts) {
        _amounts = new uint256[](_tokens.length);
        for (uint256 i = 0; i < _tokens.length; i++) {
            _amounts[i] = getTokenForPrice(_tokens[i], (_totalPrice * _ratios[i]) / SHARE_DENOMINATOR);
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "../libraries/LibPriceInterface.sol";

library LibTokenWhitelist {
    using EnumerableSet for EnumerableSet.AddressSet;
    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("portfolio.tokenlist.v1");

    struct DiamondStorage {
        EnumerableSet.AddressSet whitelist;
    }

    event TokenEnabled(address indexed tokenAddr);
    event TokenDisabled(address indexed tokenAddr);

    function diamondStorage() internal pure returns (DiamondStorage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    function enableToken(address _addr) internal {
        DiamondStorage storage ds = diamondStorage();
        if (!ds.whitelist.contains(_addr)) {
            ds.whitelist.add(_addr);
            emit TokenEnabled(_addr);
        }
    }

    function disableToken(address _addr) internal {
        DiamondStorage storage ds = diamondStorage();
        if (ds.whitelist.contains(_addr)) {
            ds.whitelist.remove(_addr);
            emit TokenDisabled(_addr);
        }
    }

    function isAllowed(address _addr) internal view returns (bool) {
        DiamondStorage storage ds = diamondStorage();
        return ds.whitelist.contains(_addr) && LibPriceInterface.hasPriceSource(_addr);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./LibTokenWhitelist.sol";
import "./LibPriceInterface.sol";
import "./LibFee.sol";

library LibTrackedToken {
    using EnumerableSet for EnumerableSet.AddressSet;

    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("portfolio.trackedtokens.v1");
    uint256 constant MAX_TRACKED_TOKENS = 10;

    struct TrackedTokensList {
        address[] tokens;
        uint256[] amounts;
        uint256 length;
    }

    struct TrackedTokensConfig {
        // Set of tracked token addresses
        EnumerableSet.AddressSet trackedTokens;
        // Amount of base units of tracked token per one (10^18 units) portfolio token
        mapping(address => uint256) targetAmounts;
    }

    struct DiamondStorage {
        mapping(address => TrackedTokensConfig) tokenConfig;
    }

    event TrackedTokenAdded(address indexed portTokenAddr, address tokenAddr, uint256 amount);
    event TrackedTokenRemoved(address indexed portTokenAddr, address tokenAddr);
    event TrackedTokenBalancesChanged(address indexed portTokenAddress, uint256 portTokenSupply, address[] tokenAddrs, uint256[] amounts);
    event TrackedTokenTargetAmountsChanged(address indexed addr, address[] trackedTokens, uint256[] targetAmounts);

    function diamondStorage() internal pure returns (DiamondStorage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    function configForToken(address _addr) internal view returns (TrackedTokensConfig storage tc) {
        return diamondStorage().tokenConfig[_addr];
    }

    function addTrackedToken(
        address _addr,
        address _trackedAddr,
        uint256 _amount
    ) internal {
        TrackedTokensConfig storage tc = configForToken(_addr);

        require(_trackedAddr != _addr, "Can`t track itself"); // even if portToken is whitelisted, it shouldn't be allowed
        require(LibTokenWhitelist.isAllowed(_trackedAddr), "Token not allowed");
        require(!tc.trackedTokens.contains(_trackedAddr), "Token already tracked");
        require(tc.trackedTokens.length() <= LibTrackedToken.MAX_TRACKED_TOKENS, "Tracked tokens limit reached");

        tc.targetAmounts[_trackedAddr] = _amount;
        tc.trackedTokens.add(_trackedAddr);

        emit TrackedTokenAdded(_addr, _trackedAddr, _amount);
    }

    /// @notice get target amounts of tracked tokens per one (10**18) portfolio token
    function getTargetAmount(address _addr) internal view returns (TrackedTokensList memory tl) {
        TrackedTokensConfig storage tc = configForToken(_addr);
        tl.length = tc.trackedTokens.length();

        tl.tokens = new address[](tl.length);
        tl.amounts = new uint256[](tl.length);

        for (uint256 i; i < tl.length; i++) {
            tl.tokens[i] = tc.trackedTokens.at(i);
            tl.amounts[i] = tc.targetAmounts[tc.trackedTokens.at(i)];
        }

        return tl;
    }

    /// @notice get target amounts of tracked tokens per provided amount of portfolio token
    function getTargetAmount(address _addr, uint256 _amount) internal view returns (TrackedTokensList memory tl) {
        require(_amount > 0);

        tl = getTargetAmount(_addr);

        for (uint256 i; i < tl.length; i++) {
            tl.amounts[i] = (tl.amounts[i] * _amount) / (10**18);
        }

        return tl;
    }

    
    /// @notice syncronize target amounts with real amounts for all tracked tokens
    function syncTargetAmount(address _addr) internal {
        uint256 supply = IERC20(_addr).totalSupply();
        require(supply > 0 && hasTrackedTokenBalance(_addr), "Cant sync without tracked token balance or supply");

        TrackedTokensConfig storage tc = configForToken(_addr);

        TrackedTokensList memory tl = getRealAmount(_addr, 10**18);
        for (uint256 i = 0; i < tl.length; i++) {
            tc.targetAmounts[tl.tokens[i]] = tl.amounts[i];
        }

        emit TrackedTokenTargetAmountsChanged(_addr, tl.tokens, tl.amounts);

    }

    /// @notice get total locked amounts of tracked tokens
    function getTotalRealAmount(address _addr) internal view returns (TrackedTokensList memory tl) {
        TrackedTokensConfig storage tc = configForToken(_addr);
        tl.length = tc.trackedTokens.length();
        tl.tokens = new address[](tl.length);
        tl.amounts = new uint256[](tl.length);

        for (uint256 i; i < tl.length; i++) {
            tl.tokens[i] = tc.trackedTokens.at(i);
            tl.amounts[i] = IERC20(tl.tokens[i]).balanceOf(_addr);
        }

        return tl;
    }

    /// @notice get amount of locked tockens per provided amount of port token for provided supply
    function getRealAmount(
        address _addr,
        uint256 _amount,
        uint256 _supply
    ) internal view returns (TrackedTokensList memory tl) {
        require(_amount > 0);
        tl = getTotalRealAmount(_addr);

        for (uint256 i; i < tl.length; i++) {
            if (_supply > 0) {
                tl.amounts[i] = (tl.amounts[i] * _amount) / _supply;
            } else {
                tl.amounts[i] = 0;
            }
        }

        return tl;
    }

    /// @notice get amount of locked tockens per provided amount of port token for current total supply
    function getRealAmount(address _addr, uint256 _amount) internal view returns (TrackedTokensList memory tl) {
        return getRealAmount(_addr, _amount, IERC20(_addr).totalSupply());
    }

    /// @notice get amount of locked tockens per provided amount of port token including not yet minted fees in supply value
    ///  @param _timestamp timestamp to be used for streaming fee calculation, block.timestamp will be used if 0 providedtreaming fee calculation
    function getAdjustedRealAmount(
        address _addr,
        uint256 _amount,
        uint256 _timestamp
    ) internal view returns (TrackedTokensList memory tl) {
        uint256 adjustedSupply = IERC20(_addr).totalSupply();
        {
            (uint256 pendingSuccess, ) = LibFee.getPendingSuccessFee(_addr);
            adjustedSupply += pendingSuccess;
        }

        adjustedSupply += LibFee.getPendingStreamingFee(_addr,_timestamp);

        return getRealAmount(_addr, _amount, adjustedSupply);
    }

    function getActualAmount(address _addr, uint256 _amount) internal view returns (TrackedTokensList memory tl) {
        if (hasTrackedTokenBalance(_addr) && IERC20(_addr).totalSupply() > 0) {
            return getRealAmount(_addr, _amount);
        } else {
            return getTargetAmount(_addr, _amount);
        }
    }

    function emitTrackedTokenBalancesChanged(address _addr) internal {
        TrackedTokensList memory tl = getTotalRealAmount(_addr);
        emit TrackedTokenBalancesChanged(_addr, IERC20(_addr).totalSupply(), tl.tokens, tl.amounts);
    }

    /// @notice checks if portfolio token has significant amount of at least one tracked token
    /// @param _addr portfolio token address
    /// @return bool
    function hasTrackedTokenBalance(address _addr) internal view returns (bool) {
        TrackedTokensConfig storage tc = configForToken(_addr);

        uint256 _l = tc.trackedTokens.length();

        for (uint256 i = 0; i < _l; i++) {
            if (LibPriceInterface.amountIsSignificant(tc.trackedTokens.at(i), IERC20(tc.trackedTokens.at(i)).balanceOf(_addr))) {
                return true;
            }
        }

        return false;
    }

    /**
        @notice get value of locked tracked tokens per one portfolio token
                requires all tokens to have significant balances
        @param portTokenAddr port token address
        @param additionalSupply value to be added to current total supply during price calculation, 
                                for example used to calculate price accounting for unminted fees
    */
    function getRealPortTokenPrice(address portTokenAddr, uint256 additionalSupply) internal view returns (uint256 totalPrice) {
        uint256 totalSupply = IERC20(portTokenAddr).totalSupply();

        // zero real price for token without supply
        if (totalSupply == 0) {
            return 0;
        }

        totalSupply += additionalSupply;

        TrackedTokensList memory tl = getTotalRealAmount(portTokenAddr);

        //not using LibPriceInterface.getTokensTotalPrice to query oracle once
        for (uint256 i = 0; i < tl.length; i++) {
            if (tl.amounts[i] > 0) {
                uint256 price = LibPriceInterface.getTokenPrice(tl.tokens[i], tl.amounts[i]);

                if (LibPriceInterface.priceIsSignificant(tl.tokens[i], price)) {
                    totalPrice += price;
                }
            }
        }

        if (totalPrice > 0) {
            totalPrice = (totalPrice * 10**18) / totalSupply;
        }
    }

    /**
        @notice get value of locked tracked tokens per one portfolio token
                denominated in other token
                requires all tokens to have significant balances
        @param portTokenAddr port token address
        @param otherTokenAddr address of token to denominate price in
        @param additionalSupply value to be added to current total supply during price calculation, 
                                for example used to calculate price accounting for unminted fees
    */
    function getRealPortTokenPriceInOtherToken(
        address portTokenAddr,
        address otherTokenAddr,
        uint256 additionalSupply
    ) internal view returns (uint256 totalPrice) {
        totalPrice = getRealPortTokenPrice(portTokenAddr, additionalSupply);

        if (totalPrice == 0) {
            return 0;
        }

        if (otherTokenAddr != LibPriceInterface.diamondStorage().baseToken) {
            totalPrice /= LibPriceInterface.getTokenPrice(otherTokenAddr, 10**IERC20Metadata(otherTokenAddr).decimals());
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "../interfaces/PortToken/IPortTokenControllable.sol";
import {LibDiamond} from "hardhat-deploy/solc_0.8/diamond/libraries/LibDiamond.sol";
import {LibPause} from "./LibPause.sol";

contract Modifiers {
    // AppStorage internal s;

    modifier onlyOwner() {
        LibDiamond.enforceIsContractOwner();
        _;
    }

    modifier onlyTokenManager(address _tokenAddr) {
        require(IPortTokenControllable(_tokenAddr).manager() == msg.sender, "Only porfolio manager allowed");
        require(!LibPause.isManagerPaused(msg.sender), "Portfolio manager paused");
        _;
    }

    modifier whenNotPaused() {
        require(!LibPause.isPaused(), "Platform paused");
        _;
    }

    modifier onlySelf() {
        require(msg.sender == address(this), "Can be called only by diamond");
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

interface IDiamondCut {
    enum FacetCutAction {Add, Replace, Remove}
    // Add=0, Replace=1, Remove=2

    struct FacetCut {
        address facetAddress;
        FacetCutAction action;
        bytes4[] functionSelectors;
    }

    /// @notice Add/replace/remove any number of functions and optionally execute
    ///         a function with delegatecall
    /// @param _diamondCut Contains the facet addresses and function selectors
    /// @param _init The address of the contract or facet to execute _calldata
    /// @param _calldata A function call, including function selector and arguments
    ///                  _calldata is executed with delegatecall on _init
    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external;

    event DiamondCut(FacetCut[] _diamondCut, address _init, bytes _calldata);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/
import { IDiamondCut } from "../interfaces/IDiamondCut.sol";

library LibDiamond {
    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("diamond.standard.diamond.storage");

    struct FacetAddressAndPosition {
        address facetAddress;
        uint96 functionSelectorPosition; // position in facetFunctionSelectors.functionSelectors array
    }

    struct FacetFunctionSelectors {
        bytes4[] functionSelectors;
        uint256 facetAddressPosition; // position of facetAddress in facetAddresses array
    }

    struct DiamondStorage {
        // maps function selector to the facet address and
        // the position of the selector in the facetFunctionSelectors.selectors array
        mapping(bytes4 => FacetAddressAndPosition) selectorToFacetAndPosition;
        // maps facet addresses to function selectors
        mapping(address => FacetFunctionSelectors) facetFunctionSelectors;
        // facet addresses
        address[] facetAddresses;
        // Used to query if a contract implements an interface.
        // Used to implement ERC-165.
        mapping(bytes4 => bool) supportedInterfaces;
        // owner of the contract
        address contractOwner;
    }

    function diamondStorage() internal pure returns (DiamondStorage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function setContractOwner(address _newOwner) internal {
        DiamondStorage storage ds = diamondStorage();
        address previousOwner = ds.contractOwner;
        ds.contractOwner = _newOwner;
        emit OwnershipTransferred(previousOwner, _newOwner);
    }

    function contractOwner() internal view returns (address contractOwner_) {
        contractOwner_ = diamondStorage().contractOwner;
    }

    function enforceIsContractOwner() internal view {
        require(msg.sender == diamondStorage().contractOwner, "LibDiamond: Must be contract owner");
    }

    event DiamondCut(IDiamondCut.FacetCut[] _diamondCut, address _init, bytes _calldata);

    // Internal function version of diamondCut
    function diamondCut(
        IDiamondCut.FacetCut[] memory _diamondCut,
        address _init,
        bytes memory _calldata
    ) internal {
        for (uint256 facetIndex; facetIndex < _diamondCut.length; facetIndex++) {
            IDiamondCut.FacetCutAction action = _diamondCut[facetIndex].action;
            if (action == IDiamondCut.FacetCutAction.Add) {
                addFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
            } else if (action == IDiamondCut.FacetCutAction.Replace) {
                replaceFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
            } else if (action == IDiamondCut.FacetCutAction.Remove) {
                removeFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
            } else {
                revert("LibDiamondCut: Incorrect FacetCutAction");
            }
        }
        emit DiamondCut(_diamondCut, _init, _calldata);
        initializeDiamondCut(_init, _calldata);
    }

    function addFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        DiamondStorage storage ds = diamondStorage();        
        require(_facetAddress != address(0), "LibDiamondCut: Add facet can't be address(0)");
        uint96 selectorPosition = uint96(ds.facetFunctionSelectors[_facetAddress].functionSelectors.length);
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            addFacet(ds, _facetAddress);            
        }
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            require(oldFacetAddress == address(0), "LibDiamondCut: Can't add function that already exists");
            addFunction(ds, selector, selectorPosition, _facetAddress);
            selectorPosition++;
        }
    }

    function replaceFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        DiamondStorage storage ds = diamondStorage();
        require(_facetAddress != address(0), "LibDiamondCut: Add facet can't be address(0)");
        uint96 selectorPosition = uint96(ds.facetFunctionSelectors[_facetAddress].functionSelectors.length);
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            addFacet(ds, _facetAddress);
        }
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            require(oldFacetAddress != _facetAddress, "LibDiamondCut: Can't replace function with same function");
            removeFunction(ds, oldFacetAddress, selector);
            addFunction(ds, selector, selectorPosition, _facetAddress);
            selectorPosition++;
        }
    }

    function removeFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        DiamondStorage storage ds = diamondStorage();
        // if function does not exist then do nothing and return
        require(_facetAddress == address(0), "LibDiamondCut: Remove facet address must be address(0)");
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            removeFunction(ds, oldFacetAddress, selector);
        }
    }

    function addFacet(DiamondStorage storage ds, address _facetAddress) internal {
        enforceHasContractCode(_facetAddress, "LibDiamondCut: New facet has no code");
        ds.facetFunctionSelectors[_facetAddress].facetAddressPosition = ds.facetAddresses.length;
        ds.facetAddresses.push(_facetAddress);
    }    


    function addFunction(DiamondStorage storage ds, bytes4 _selector, uint96 _selectorPosition, address _facetAddress) internal {
        ds.selectorToFacetAndPosition[_selector].functionSelectorPosition = _selectorPosition;
        ds.facetFunctionSelectors[_facetAddress].functionSelectors.push(_selector);
        ds.selectorToFacetAndPosition[_selector].facetAddress = _facetAddress;
    }

    function removeFunction(DiamondStorage storage ds, address _facetAddress, bytes4 _selector) internal {        
        require(_facetAddress != address(0), "LibDiamondCut: Can't remove function that doesn't exist");
        // an immutable function is a function defined directly in a diamond
        require(_facetAddress != address(this), "LibDiamondCut: Can't remove immutable function");
        // replace selector with last selector, then delete last selector
        uint256 selectorPosition = ds.selectorToFacetAndPosition[_selector].functionSelectorPosition;
        uint256 lastSelectorPosition = ds.facetFunctionSelectors[_facetAddress].functionSelectors.length - 1;
        // if not the same then replace _selector with lastSelector
        if (selectorPosition != lastSelectorPosition) {
            bytes4 lastSelector = ds.facetFunctionSelectors[_facetAddress].functionSelectors[lastSelectorPosition];
            ds.facetFunctionSelectors[_facetAddress].functionSelectors[selectorPosition] = lastSelector;
            ds.selectorToFacetAndPosition[lastSelector].functionSelectorPosition = uint96(selectorPosition);
        }
        // delete the last selector
        ds.facetFunctionSelectors[_facetAddress].functionSelectors.pop();
        delete ds.selectorToFacetAndPosition[_selector];

        // if no more selectors for facet address then delete the facet address
        if (lastSelectorPosition == 0) {
            // replace facet address with last facet address and delete last facet address
            uint256 lastFacetAddressPosition = ds.facetAddresses.length - 1;
            uint256 facetAddressPosition = ds.facetFunctionSelectors[_facetAddress].facetAddressPosition;
            if (facetAddressPosition != lastFacetAddressPosition) {
                address lastFacetAddress = ds.facetAddresses[lastFacetAddressPosition];
                ds.facetAddresses[facetAddressPosition] = lastFacetAddress;
                ds.facetFunctionSelectors[lastFacetAddress].facetAddressPosition = facetAddressPosition;
            }
            ds.facetAddresses.pop();
            delete ds.facetFunctionSelectors[_facetAddress].facetAddressPosition;
        }
    }

    function initializeDiamondCut(address _init, bytes memory _calldata) internal {
        if (_init == address(0)) {
            require(_calldata.length == 0, "LibDiamondCut: _init is address(0) but_calldata is not empty");
        } else {
            require(_calldata.length > 0, "LibDiamondCut: _calldata is empty but _init is not address(0)");
            if (_init != address(this)) {
                enforceHasContractCode(_init, "LibDiamondCut: _init address has no code");
            }
            (bool success, bytes memory error) = _init.delegatecall(_calldata);
            if (!success) {
                if (error.length > 0) {
                    // bubble up the error
                    revert(string(error));
                } else {
                    revert("LibDiamondCut: _init function reverted");
                }
            }
        }
    }

    function enforceHasContractCode(address _contract, string memory _errorMessage) internal view {
        uint256 contractSize;
        assembly {
            contractSize := extcodesize(_contract)
        }
        require(contractSize > 0, _errorMessage);
    }
}