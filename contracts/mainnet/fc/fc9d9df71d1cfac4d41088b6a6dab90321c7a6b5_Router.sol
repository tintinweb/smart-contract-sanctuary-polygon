// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC777/IERC777.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC777Token standard as defined in the EIP.
 *
 * This contract uses the
 * https://eips.ethereum.org/EIPS/eip-1820[ERC1820 registry standard] to let
 * token holders and recipients react to token movements by using setting implementers
 * for the associated interfaces in said registry. See {IERC1820Registry} and
 * {ERC1820Implementer}.
 */
interface IERC777 {
    /**
     * @dev Emitted when `amount` tokens are created by `operator` and assigned to `to`.
     *
     * Note that some additional user `data` and `operatorData` can be logged in the event.
     */
    event Minted(address indexed operator, address indexed to, uint256 amount, bytes data, bytes operatorData);

    /**
     * @dev Emitted when `operator` destroys `amount` tokens from `account`.
     *
     * Note that some additional user `data` and `operatorData` can be logged in the event.
     */
    event Burned(address indexed operator, address indexed from, uint256 amount, bytes data, bytes operatorData);

    /**
     * @dev Emitted when `operator` is made operator for `tokenHolder`.
     */
    event AuthorizedOperator(address indexed operator, address indexed tokenHolder);

    /**
     * @dev Emitted when `operator` is revoked its operator status for `tokenHolder`.
     */
    event RevokedOperator(address indexed operator, address indexed tokenHolder);

    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the smallest part of the token that is not divisible. This
     * means all token operations (creation, movement and destruction) must have
     * amounts that are a multiple of this number.
     *
     * For most token contracts, this value will equal 1.
     */
    function granularity() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by an account (`owner`).
     */
    function balanceOf(address owner) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * If send or receive hooks are registered for the caller and `recipient`,
     * the corresponding functions will be called with `data` and empty
     * `operatorData`. See {IERC777Sender} and {IERC777Recipient}.
     *
     * Emits a {Sent} event.
     *
     * Requirements
     *
     * - the caller must have at least `amount` tokens.
     * - `recipient` cannot be the zero address.
     * - if `recipient` is a contract, it must implement the {IERC777Recipient}
     * interface.
     */
    function send(
        address recipient,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev Destroys `amount` tokens from the caller's account, reducing the
     * total supply.
     *
     * If a send hook is registered for the caller, the corresponding function
     * will be called with `data` and empty `operatorData`. See {IERC777Sender}.
     *
     * Emits a {Burned} event.
     *
     * Requirements
     *
     * - the caller must have at least `amount` tokens.
     */
    function burn(uint256 amount, bytes calldata data) external;

    /**
     * @dev Returns true if an account is an operator of `tokenHolder`.
     * Operators can send and burn tokens on behalf of their owners. All
     * accounts are their own operator.
     *
     * See {operatorSend} and {operatorBurn}.
     */
    function isOperatorFor(address operator, address tokenHolder) external view returns (bool);

    /**
     * @dev Make an account an operator of the caller.
     *
     * See {isOperatorFor}.
     *
     * Emits an {AuthorizedOperator} event.
     *
     * Requirements
     *
     * - `operator` cannot be calling address.
     */
    function authorizeOperator(address operator) external;

    /**
     * @dev Revoke an account's operator status for the caller.
     *
     * See {isOperatorFor} and {defaultOperators}.
     *
     * Emits a {RevokedOperator} event.
     *
     * Requirements
     *
     * - `operator` cannot be calling address.
     */
    function revokeOperator(address operator) external;

    /**
     * @dev Returns the list of default operators. These accounts are operators
     * for all token holders, even if {authorizeOperator} was never called on
     * them.
     *
     * This list is immutable, but individual holders may revoke these via
     * {revokeOperator}, in which case {isOperatorFor} will return false.
     */
    function defaultOperators() external view returns (address[] memory);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient`. The caller must
     * be an operator of `sender`.
     *
     * If send or receive hooks are registered for `sender` and `recipient`,
     * the corresponding functions will be called with `data` and
     * `operatorData`. See {IERC777Sender} and {IERC777Recipient}.
     *
     * Emits a {Sent} event.
     *
     * Requirements
     *
     * - `sender` cannot be the zero address.
     * - `sender` must have at least `amount` tokens.
     * - the caller must be an operator for `sender`.
     * - `recipient` cannot be the zero address.
     * - if `recipient` is a contract, it must implement the {IERC777Recipient}
     * interface.
     */
    function operatorSend(
        address sender,
        address recipient,
        uint256 amount,
        bytes calldata data,
        bytes calldata operatorData
    ) external;

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the total supply.
     * The caller must be an operator of `account`.
     *
     * If a send hook is registered for `account`, the corresponding function
     * will be called with `data` and `operatorData`. See {IERC777Sender}.
     *
     * Emits a {Burned} event.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     * - the caller must be an operator for `account`.
     */
    function operatorBurn(
        address account,
        uint256 amount,
        bytes calldata data,
        bytes calldata operatorData
    ) external;

    event Sent(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 amount,
        bytes data,
        bytes operatorData
    );
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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.17;

import {CurvePool} from "src/handlers/CurvePool.sol";
import {Superfluid} from "src/handlers/Superfluid.sol";
import {Aggregators} from "src/handlers/Aggregators.sol";
import {SynthereumV6} from "src/handlers/SynthereumV6.sol";
import {CurveExchange} from "src/handlers/CurveExchange.sol";
import {StakeDaoVault} from "src/handlers/StakeDaoVault.sol";

/// @title Router
contract Router is Aggregators, CurveExchange, CurvePool, StakeDaoVault, Superfluid, SynthereumV6 {}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.17;

import {Constants} from "src/libraries/Constants.sol";
import {ERC20, SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";

/// @title TokenUtils
/// @notice Utility functions for tokens.
library TokenUtils {
    using SafeTransferLib for ERC20;

    /// @notice Approves a spender to spend an ERC20 token if not already approved.
    /// @param token The ERC20 token to approve.
    /// @param spender The address to approve.
    function _approve(address token, address spender) internal {
        if (spender == address(0)) {
            return;
        }
        if (ERC20(token).allowance(address(this), spender) == 0) {
            ERC20(token).safeApprove(spender, type(uint256).max);
        }
    }

    /// @notice Transfer funds from the sender to the contract, if needed.
    /// @param amountIn The amount of funds to transfer.
    /// @param token The token to transfer.
    function _amountIn(uint256 amountIn, address token) internal returns (uint256) {
        if (amountIn == Constants.CONTRACT_BALANCE) {
            return ERC20(token).balanceOf(address(this));
        } else if (token == Constants._ETH) {
            return msg.value;
        } else {
            ERC20(token).safeTransferFrom(msg.sender, address(this), amountIn);
        }
        return amountIn;
    }

    /// @notice Transfer utils from the contract to the recipient, if needed.
    /// @param _token The token to transfer.
    /// @param _to The recipient address.
    /// @param _amount The amount of funds to transfer.
    function _transfer(address _token, address _to, uint256 _amount) internal returns (uint256) {
        if (_amount == type(uint256).max) {
            _amount = _balanceInOf(_token, address(this));
        }

        if (_to != address(0) && _to != address(this) && _amount != 0) {
            if (_token != Constants._ETH) {
                ERC20(_token).safeTransfer(_to, _amount);
            } else {
                SafeTransferLib.safeTransferETH(_to, _amount);
            }

            return _amount;
        }

        return 0;
    }

    /// @notice Get the balance of an account.
    /// @param _token The token to get the balance of.
    /// @param _acc The account to get the balance of.
    function _balanceInOf(address _token, address _acc) internal view returns (uint256) {
        if (_token == Constants._ETH) {
            return _acc.balance;
        } else {
            return ERC20(_token).balanceOf(_acc);
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.17;

import {TokenUtils} from "src/common/TokenUtils.sol";
import {Constants} from "src/libraries/Constants.sol";

/// @title Aggregators
/// @notice Enables to interact with different aggregators.
abstract contract Aggregators {
    /// @notice AugustusSwapper contract address.
    address public constant AUGUSTUS = 0xDEF171Fe48CF0115B1d80b88dc8eAB59176FEe57;

    /// @notice 1nch Router v5 contract address.
    address public constant INCH_ROUTER = 0x1111111254EEB25477B68fb85Ed929f73A960582;

    /// @notice LiFi Diamond contract address.
    address public constant LIFI_DIAMOND = 0x1231DEB6f5749EF6cE6943a275A1D3E7486F4EaE;

    /// @notice Paraswap Token pull contract address.
    address public constant TOKEN_TRANSFER_PROXY = 0x216B4B4Ba9F3e719726886d34a177484278Bfcae;

    /// @notice Emitted when tokens are exchanged.
    /// @param _from Address of the sender.
    /// @param _to Address of the recipient.
    /// @param _tokenFrom Address of the source token.
    /// @param _tokenTo Address of the destination token.
    /// @param _amountFrom Amount of source token exchanged.
    /// @param _amountTo Amount of destination token received.
    event Exchanged(
        address indexed _from,
        address indexed _to,
        address _tokenFrom,
        address _tokenTo,
        uint256 _amountFrom,
        uint256 _amountTo
    );

    /// @notice Checks if the aggregator is valid.
    modifier onlyValidAggregator(address aggregator) {
        if (aggregator != AUGUSTUS && aggregator != INCH_ROUTER && aggregator != LIFI_DIAMOND) {
            revert Constants.NOT_ALLOWED();
        }
        _;
    }

    /// @notice Exchanges tokens using different aggregators.
    /// @param aggregator Aggregator contract address.
    /// @param srcToken Source token address.
    /// @param destToken Destination token address.
    /// @param underlyingAmount Amount of source token to exchange.
    /// @param callData Data to call the aggregator.
    /// @return received Amount of destination token received.
    function exchange(
        address aggregator,
        address srcToken,
        address destToken,
        uint256 underlyingAmount,
        bytes memory callData,
        address recipient
    ) external payable onlyValidAggregator(aggregator) returns (uint256 received) {
        underlyingAmount = TokenUtils._amountIn(underlyingAmount, srcToken);

        bool success;
        if (srcToken == Constants._ETH) {
            (success,) = aggregator.call{value: underlyingAmount}(callData);
        } else {
            TokenUtils._approve(srcToken, aggregator == AUGUSTUS ? TOKEN_TRANSFER_PROXY : aggregator);
            (success,) = aggregator.call(callData);
        }
        if (!success) revert Constants.SWAP_FAILED();

        if (recipient == Constants.MSG_SENDER) {
            recipient = msg.sender;

            if (destToken == Constants._ETH) {
                received = TokenUtils._balanceInOf(Constants._ETH, address(this));
                TokenUtils._transfer(Constants._ETH, recipient, received);
            } else {
                received = TokenUtils._balanceInOf(destToken, address(this));
                TokenUtils._transfer(destToken, recipient, received);
            }
        }

        emit Exchanged(msg.sender, recipient, srcToken, destToken, underlyingAmount, received);
    }

    receive() external payable {}
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.17;

import {ICurve} from "src/interfaces/ICurve.sol";
import {Constants, TokenUtils} from "src/common/TokenUtils.sol";

/// @title Curve Exchange Handler
/// @notice Handles exchanges through Curve.
abstract contract CurveExchange {
    /// @notice Exchange Contract for Curve Pools.
    ICurve private constant exchangeContract = ICurve(0xF52e46bEE287aAef56Fb2F8af961d9f1406cF476);

    /// @notice Exchange Contract for Factory/Meta Pools.
    ICurve private immutable exchangeFactoryContract = ICurve(0x5ab5C56B9db92Ba45a0B46a207286cD83C15C939);

    /// @notice Emit when tokens are exchanged through Curve.
    /// @param _from Address token from.
    /// @param _to Address to receive token.
    /// @param _tokenFrom Token to exchange from.
    /// @param _tokenTo Token to exchange to.
    /// @param _amountFrom Amount of tokens to exchange.
    /// @param _amountTo Minimum amount of tokens to receive.
    event Exchange(
        address indexed _from,
        address indexed _to,
        address _tokenFrom,
        address _tokenTo,
        uint256 _amountFrom,
        uint256 _amountTo
    );

    /// @notice Emit when tokens are exchanged through Curve Factory/Meta Pools.
    /// @param _from Address token from.
    /// @param _to The token to exchange from.
    /// @param _tokenFrom The token to exchange from.
    /// @param _tokenTo The token to exchange to.
    /// @param _amountFrom The amount of tokens exchanged.
    /// @param _amountTo The minimum amount of tokens received.
    event ExchangeUnderlying(
        address indexed _from,
        address indexed _to,
        int128 _tokenFrom,
        int128 _tokenTo,
        uint256 _amountFrom,
        uint256 _amountTo
    );

    /// @notice Exchange tokens through Curve.
    /// @param pool The Curve pool to use.
    /// @param from The token to exchange from.
    /// @param to The token to exchange to.
    /// @param amountIn The amount of tokens to exchange.
    /// @param amountOutMin The minimum amount of tokens to receive.
    /// @param recipient The address to receive the tokens.
    /// @return received The amount of tokens received.
    function exchange(address pool, address from, address to, uint256 amountIn, uint256 amountOutMin, address recipient)
        external
        returns (uint256 received)
    {
        amountIn = TokenUtils._amountIn(amountIn, from);

        if (recipient == Constants.MSG_SENDER) recipient = msg.sender;
        else if (recipient == Constants.ADDRESS_THIS) recipient = address(this);

        TokenUtils._approve(from, address(exchangeContract));
        received = exchangeContract.exchange(pool, from, to, amountIn, 0, recipient);

        if (received < amountOutMin) revert Constants.NOT_ENOUGH_RECEIVED();

        emit Exchange(msg.sender, recipient, from, to, amountIn, received);
    }

    /// @notice Exchange tokens through Curve Factory/Meta Pools.
    /// @param pool The Curve pool to use.
    /// @param indexFrom The index of From token in the pool.
    /// @param indexTo The index of To token in the pool.
    /// @param amountIn The amount of tokens to exchange.
    /// @param amountOutMin The minimum amount of tokens to receive.
    /// @param recipient The address to receive the tokens.
    function exchangeUnderlying(
        address pool,
        address from,
        int128 indexFrom,
        int128 indexTo,
        uint256 amountIn,
        uint256 amountOutMin,
        address recipient
    ) external returns (uint256 received) {
        amountIn = TokenUtils._amountIn(amountIn, from);
        if (recipient == Constants.MSG_SENDER) recipient = msg.sender;
        else if (recipient == Constants.ADDRESS_THIS) recipient = address(this);

        TokenUtils._approve(from, address(exchangeFactoryContract));
        received =
            exchangeFactoryContract.exchange_underlying(pool, indexFrom, indexTo, amountIn, amountOutMin, recipient);

        if (received < amountOutMin) revert Constants.NOT_ENOUGH_RECEIVED();

        emit ExchangeUnderlying(msg.sender, recipient, indexFrom, indexTo, amountIn, received);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.17;

import {Constants, TokenUtils} from "src/common/TokenUtils.sol";
import {ICurve} from "src/interfaces/ICurve.sol";
import {ICurveLp} from "src/interfaces/ICurveLp.sol";

/// @title Curve Pool Handler
/// @notice Handles liquidity actions through Curve Pools.
abstract contract CurvePool {
    /// @notice Emit when liquidity is added to a Curve Pool.
    /// @param _from Address token from.
    /// @param _to Address to receive token.
    /// @param _tokenIn Token to add liquidity with.
    /// @param _amountIn Amount of tokens to add.
    /// @param _lpToken The lp token of the pool.
    /// @param _amountOut The amount of lpToken received.
    event AddLiquidity(
        address indexed _from,
        address indexed _to,
        address _tokenIn,
        uint256 _amountIn,
        address _lpToken,
        uint256 _amountOut
    );
    /// @notice Emit when liquidity is removed from a Curve Pool.
    /// @param _from Address token from.
    /// @param _to Address to receive token.
    /// @param _lpToken The lp token of the pool.
    /// @param _amountIn Amount of lpToken to remove.
    /// @param _tokenOut Token to receive.
    /// @param _amountOut The amount of tokens received.
    event RemoveLiquidity(
        address indexed _from,
        address indexed _to,
        address _lpToken,
        uint256 _amountIn,
        address _tokenOut,
        uint256 _amountOut
    );

    /// @notice Add Liquidity to a Curve Pool
    /// @param lpToken The lp token of the pool.
    /// @param tokenIn The token to use to add liquidity.
    /// @param amountIn The amount of tokenIn to add.
    /// @param amountMinOut The min amount of lpToken to receive.
    /// @param index index ot tokenIn in the curve pool
    /// @param useUnderlying If true, deposit underlying assets instead of wrapped tokens
    /// @param recipient The address to receive the tokens.
    /// @return received The amount of tokens received.
    function addLiquidity(
        address lpToken,
        address tokenIn,
        uint256 amountIn,
        uint256 amountMinOut,
        uint256 index,
        bool useUnderlying,
        address recipient
    ) external returns (uint256 received) {
        amountIn = TokenUtils._amountIn(amountIn, tokenIn);

        uint256[3] memory amountsIn;
        amountsIn[index] = amountIn;

        address poolAddress = ICurveLp(lpToken).minter();

        TokenUtils._approve(tokenIn, poolAddress);
        if (useUnderlying) {
            received = ICurve(poolAddress).add_liquidity(amountsIn, amountMinOut, true);
        } else {
            received = ICurve(poolAddress).add_liquidity(amountsIn, amountMinOut);
        }

        if (received < amountMinOut) revert Constants.NOT_ENOUGH_RECEIVED();

        if (recipient == Constants.MSG_SENDER) {
            recipient = msg.sender;
            TokenUtils._transfer(lpToken, recipient, received);
        }

        emit AddLiquidity(msg.sender, recipient, tokenIn, amountIn, lpToken, received);
    }

    /// @notice Remove Liquidity from a Curve Pool
    /// @param lpToken The lp token of the pool.
    /// @param tokenOut The token to remove from liquidity.
    /// @param amountIn The amount of lpToken to burn.
    /// @param amountMinOut The min amount of tokenOut to receive.
    /// @param index index ot tokenOut in the curve pool
    /// @param receiveUnderlying If true, receive underlying assets instead of wrapped tokens
    /// @param recipient The address to receive the tokens.
    /// @return received The amount of tokens received.
    function removeLiquidity(
        address lpToken,
        address tokenOut,
        uint256 amountIn,
        uint256 amountMinOut,
        int128 index,
        bool receiveUnderlying,
        address recipient
    ) external returns (uint256 received) {
        amountIn = TokenUtils._amountIn(amountIn, lpToken);

        address poolAddress = ICurveLp(lpToken).minter();

        if (receiveUnderlying) {
            received = ICurve(poolAddress).remove_liquidity_one_coin(amountIn, index, amountMinOut, true);
        } else {
            received = ICurve(poolAddress).remove_liquidity_one_coin(amountIn, index, amountMinOut);
        }

        if (received < amountMinOut) revert Constants.NOT_ENOUGH_RECEIVED();

        if (recipient == Constants.MSG_SENDER) {
            recipient = msg.sender;
            TokenUtils._transfer(tokenOut, recipient, received);
        }

        emit RemoveLiquidity(msg.sender, recipient, lpToken, amountIn, tokenOut, received);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.17;

import {Constants, TokenUtils} from "src/common/TokenUtils.sol";
import {IStakeDaoVault} from "src/interfaces/IStakeDaoVault.sol";

/// @title StakeDao Vault Handler
/// @notice Handles StakeDao vault actions.
abstract contract StakeDaoVault {
    /// @notice Emitted when tokens are deposited to StakeDao vault.
    /// @param _from The address that deposited the tokens.
    /// @param _to The address that received the vault tokens.
    /// @param _token The token that was deposited.
    /// @param _amount The amount of tokens that were deposited.
    event Deposited(address indexed _from, address indexed _to, address _token, uint256 _amount);

    /// @notice Emitted when tokens are withdrawn from StakeDao vault.
    /// @param _from The address that withdrew the vault tokens.
    /// @param _to The address that received the tokens.
    /// @param _token The token that was received.
    /// @param _amount The amount of tokens that were received.
    event Withdrawn(address indexed _from, address indexed _to, address _token, uint256 _amount);

    /// @notice Deposit tokens to StakeDao vault
    /// @param vault The vault address.
    /// @param tokenIn The token to deposit.
    /// @param amountIn The amount of tokenIn to deposit.
    /// @param recipient The address to receive the tokens.
    function deposit(address vault, address tokenIn, uint256 amountIn, address recipient) external {
        amountIn = TokenUtils._amountIn(amountIn, tokenIn);

        TokenUtils._approve(tokenIn, vault);
        IStakeDaoVault(vault).deposit(amountIn);

        if (recipient == Constants.MSG_SENDER) {
            recipient = msg.sender;
            TokenUtils._transfer(vault, recipient, type(uint256).max);
        }

        emit Deposited(msg.sender, recipient, tokenIn, amountIn);
    }

    /// @notice Withdraw tokens from StakeDao vault
    /// @param vault The vault address.
    /// @param tokenOut The token to withdraw.
    /// @param amountIn The amount of vault tokens to withdraw.
    /// @param recipient The address to receive the tokens.
    function withdraw(address vault, address tokenOut, uint256 amountIn, address recipient) external {
        amountIn = TokenUtils._amountIn(amountIn, vault);

        IStakeDaoVault(vault).withdraw(amountIn);

        if (recipient == Constants.MSG_SENDER) {
            recipient = msg.sender;
            TokenUtils._transfer(tokenOut, recipient, type(uint256).max);
        }

        emit Withdrawn(msg.sender, recipient, vault, amountIn);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.17;

import {Constants, TokenUtils} from "src/common/TokenUtils.sol";
import {IStandardERC20} from "src/interfaces/IStandardERC20.sol";
import {ISuperToken} from "src/interfaces/ISuperToken.sol";

/// @title Superfluid Handler
/// @notice Handles exchanges through Superfluid Tokens.
abstract contract Superfluid {
    /// @notice Emitted when tokens are upgraded to Super tokens.
    /// @param _from The address that upgraded the tokens.
    /// @param _to The address that received the super tokens.
    /// @param _token The token that was upgraded.
    /// @param _amount The amount of tokens that were upgraded.
    event Upgrade(address indexed _from, address indexed _to, address _token, uint256 _amount);

    /// @notice Emitted when Super tokens are downgraded to tokens.
    /// @param _from The address that downgraded the super tokens.
    /// @param _to The address that received the tokens.
    /// @param _token The token that was received.
    /// @param _amount The amount of tokens that were received.
    event Downgrade(address indexed _from, address indexed _to, address _token, uint256 _amount);

    /// @notice Upgrade tokens to Super tokens through Superfluid.
    /// @param superToken The super token to receive.
    /// @param token The token to upgrade.
    /// @param amountIn The amount of tokens to upgrade.
    /// @param recipient The address to receive the super tokens.
    function upgrade(address superToken, address token, uint256 amountIn, address recipient) external {
        amountIn = TokenUtils._amountIn(amountIn, token);

        TokenUtils._approve(token, superToken);

        // To handle tokens with less than 18 decimals
        ISuperToken(superToken).upgrade(amountIn * 10 ** (18 - IStandardERC20(token).decimals()));

        if (recipient == Constants.MSG_SENDER) {
            recipient = msg.sender;
            TokenUtils._transfer(superToken, recipient, type(uint256).max);
        }

        emit Upgrade(msg.sender, recipient, token, amountIn);
    }

    /// @notice Downgrade Super tokens to tokens through Superfluid.
    /// @param superToken The super token to exchange.
    /// @param token The token to receive.
    /// @param amountIn The amount of super tokens to downgrade.
    /// @param recipient The address to receive the tokens.
    function downgrade(address superToken, address token, uint256 amountIn, address recipient) external {
        amountIn = TokenUtils._amountIn(amountIn, superToken);

        ISuperToken(superToken).downgrade(amountIn);

        if (recipient == Constants.MSG_SENDER) {
            recipient = msg.sender;
            TokenUtils._transfer(token, recipient, type(uint256).max);
        }

        emit Downgrade(msg.sender, recipient, token, amountIn);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.17;

import {Constants, TokenUtils} from "src/common/TokenUtils.sol";
import {ISynthereumFixedRateWrapper} from "src/interfaces/ISynthereumFixedRateWrapper.sol";
import {ISynthereumMultiLpLiquidityPool} from "src/interfaces/ISynthereumMultiLpLiquidityPool.sol";

/// @title Synthereum V6 Handler
/// @notice Handles exchanges through Synthereum V6.
abstract contract SynthereumV6 {
    /// @notice USDC Collateral.
    address private constant USDC = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;

    /// @notice Emit when jFIATs are minted.
    /// @param _from Address token from.
    /// @param _to Address to receive token.
    /// @param _tokenTo Token to exchange to.
    /// @param _amountFrom Amount of tokens to exchange.
    /// @param _amountTo Minimum amount of tokens to receive.
    event Mint(address indexed _from, address indexed _to, address _tokenTo, uint256 _amountFrom, uint256 _amountTo);

    /// @notice Emit when jFIATs are redeemed.
    /// @param _from Address token from.
    /// @param _to Address to receive token.
    /// @param _tokenFrom Token to exchange from.
    /// @param _amountFrom Amount of tokens to exchange.
    /// @param _amountTo Minimum amount of tokens to receive.
    event Redeem(
        address indexed _from, address indexed _to, address _tokenFrom, uint256 _amountFrom, uint256 _amountTo
    );

    /// @notice Emit when tokens are wrapped.
    /// @param _from Address token from.
    /// @param _to Address to receive token.
    /// @param _tokenFrom Token to exchange from.
    /// @param _wrapper Wrapper to use.
    /// @param _amountFrom Amount of tokens to exchange.
    /// @param _amountTo Minimum amount of tokens to receive.
    event Wrap(
        address indexed _from,
        address indexed _to,
        address _tokenFrom,
        address _wrapper,
        uint256 _amountFrom,
        uint256 _amountTo
    );

    /// @notice Emit when tokens are unwrapped.
    /// @param _from Address token from.
    /// @param _to Address to receive token.
    /// @param _tokenTo Token to exchange to.
    /// @param _wrapper Wrapper to use.
    /// @param _amountFrom Amount of tokens to exchange.
    /// @param _amountTo Minimum amount of tokens to receive.
    event Unwrap(
        address indexed _from,
        address indexed _to,
        address _tokenTo,
        address _wrapper,
        uint256 _amountFrom,
        uint256 _amountTo
    );

    /// @notice Mint tokens through Synthereum.
    /// @param destPool The Synthereum pool to use.
    /// @param amountIn The amount of tokens to exchange.
    /// @param amountMinOut The minimum amount of tokens to receive.
    /// @param recipient The address to receive the tokens.
    /// @return received The amount of tokens received.
    function mint(address destPool, uint256 amountIn, uint256 amountMinOut, address recipient)
        external
        returns (uint256 received)
    {
        amountIn = TokenUtils._amountIn(amountIn, USDC);

        ISynthereumMultiLpLiquidityPool.MintParams memory mintParams =
            ISynthereumMultiLpLiquidityPool.MintParams(amountMinOut, amountIn, block.timestamp + 1800, address(this));

        TokenUtils._approve(USDC, destPool);
        (received,) = ISynthereumMultiLpLiquidityPool(destPool).mint(mintParams);

        if (recipient == Constants.MSG_SENDER) {
            recipient = msg.sender;
            address token = address(ISynthereumMultiLpLiquidityPool(destPool).syntheticToken());
            TokenUtils._transfer(token, recipient, received);
        }

        if (received < amountMinOut) revert Constants.NOT_ENOUGH_RECEIVED();

        emit Mint(msg.sender, recipient, destPool, amountIn, received);
    }

    /// @notice Redeem tokens through Synthereum.
    /// @param token The token to redeem.
    /// @param pool The Synthereum pool to use.
    /// @param amountIn The amount of tokens to exchange.
    /// @param amountMinOut The minimum amount of tokens to receive.
    /// @param recipient The address to receive the tokens.
    function redeem(address token, address pool, uint256 amountIn, uint256 amountMinOut, address recipient)
        external
        returns (uint256 received)
    {
        amountIn = TokenUtils._amountIn(amountIn, token);

        ISynthereumMultiLpLiquidityPool.RedeemParams memory redeemParams =
            ISynthereumMultiLpLiquidityPool.RedeemParams(amountIn, amountMinOut, block.timestamp + 1800, address(this));

        TokenUtils._approve(token, pool);
        (received,) = ISynthereumMultiLpLiquidityPool(pool).redeem(redeemParams);

        if (recipient == Constants.MSG_SENDER) TokenUtils._transfer(USDC, msg.sender, received);
        if (received < amountMinOut) revert Constants.NOT_ENOUGH_RECEIVED();

        emit Redeem(msg.sender, recipient, token, amountIn, received);
    }

    /// @notice Wrap tokens through Synthereum.
    /// @param fixedRateWrapper The Synthereum fixed rate wrapper to use.
    /// @param token The token to wrap.
    /// @param amountIn The amount of tokens to exchange.
    /// @param recipient The address to receive the tokens.
    /// @return received The amount of tokens received.
    function wrap(address fixedRateWrapper, address token, uint256 amountIn, address recipient)
        external
        returns (uint256 received)
    {
        amountIn = TokenUtils._amountIn(amountIn, token);

        if (recipient == Constants.MSG_SENDER) recipient = msg.sender;
        else if (recipient == Constants.ADDRESS_THIS) recipient = address(this);

        TokenUtils._approve(token, fixedRateWrapper);
        received = ISynthereumFixedRateWrapper(fixedRateWrapper).wrap(amountIn, recipient);

        emit Wrap(msg.sender, recipient, token, fixedRateWrapper, amountIn, received);
    }

    /// @notice Unwrap tokens through Synthereum.
    /// @param fixedRateWrapper The Synthereum fixed rate wrapper to use.
    /// @param token The token to wrap.
    /// @param amountIn The amount of tokens to exchange.
    /// @param recipient The address to receive the tokens.
    /// @return received The amount of tokens received.
    function unwrap(address fixedRateWrapper, address token, uint256 amountIn, address recipient)
        external
        returns (uint256 received)
    {
        amountIn = TokenUtils._amountIn(amountIn, token);

        if (recipient == Constants.MSG_SENDER) recipient = msg.sender;
        else if (recipient == Constants.ADDRESS_THIS) recipient = address(this);

        TokenUtils._approve(token, fixedRateWrapper);
        received = ISynthereumFixedRateWrapper(fixedRateWrapper).unwrap(amountIn, recipient);

        emit Unwrap(msg.sender, recipient, token, fixedRateWrapper, amountIn, received);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.17;

/// @title Curve interface
/// @notice Interface for Curve
interface ICurve {
    function add_liquidity(uint256[3] calldata _amounts, uint256 _min_mint_amount) external returns (uint256);

    function add_liquidity(uint256[3] calldata _amounts, uint256 _min_mint_amount, bool _use_underlying)
        external
        returns (uint256);

    function remove_liquidity_one_coin(uint256 _token_amount, int128 i, uint256 _min_amount)
        external
        returns (uint256);

    function remove_liquidity_one_coin(uint256 _token_amount, int128 i, uint256 _min_amount, bool _use_underlying)
        external
        returns (uint256);

    function exchange(address _pool, address _from, address _to, uint256 _amount, uint256 _expected, address _receiver)
        external
        payable
        returns (uint256);

    function exchange_underlying(address pool, int128 i, int128 j, uint256 dx, uint256 min_dy, address recipient)
        external
        payable
        returns (uint256);

    function coins(uint256 i) external view returns (address);

    function calc_token_amount(uint256[3] calldata _amounts, bool is_deposit) external view returns (uint256);

    function calc_withdraw_one_coin(uint256 _token_amount, int128 i) external view returns (uint256);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.17;

/// @title Curve LP interface
/// @notice Interface for Curve LP
interface ICurveLp {
    function minter() external view returns (address);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title ERC20 interface that includes burn mint and roles methods.
 */
interface IMintableBurnableERC20 is IERC20 {
    /**
     * @notice Burns a specific amount of the caller's tokens.
     * @dev This method should be permissioned to only _allow designated parties to burn tokens.
     */
    function burn(uint256 value) external;

    /**
     * @notice Mints tokens and adds them to the balance of the `to` address.
     * @dev This method should be permissioned to only _allow designated parties to mint tokens.
     */
    function mint(address to, uint256 value) external returns (bool);

    /**
     * @notice Returns the number of decimals used to get its user representation.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.17;

/// @title StakeDao Vault interface
/// @notice Interface for StakeDao Vault
interface IStakeDaoVault {
    function deposit(uint256 _amount) external;

    function withdraw(uint256 _shares) external;

    function getPricePerFullShare() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IStandardERC20 is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: AGPLv3
pragma solidity >= 0.8.4;

import {ISuperfluidToken} from "./ISuperfluidToken.sol";
import {IStandardERC20} from "./IStandardERC20.sol";
import {IERC777} from "@openzeppelin/contracts/token/ERC777/IERC777.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title Super token (Superfluid Token + ERC20 + ERC777) interface
 * @author Superfluid
 */
interface ISuperToken is ISuperfluidToken, IStandardERC20, IERC777 {
    /**
     *
     * Errors
     *
     */
    error SUPER_TOKEN_CALLER_IS_NOT_OPERATOR_FOR_HOLDER(); // 0xf7f02227
    error SUPER_TOKEN_NOT_ERC777_TOKENS_RECIPIENT(); // 0xfe737d05
    error SUPER_TOKEN_INFLATIONARY_DEFLATIONARY_NOT_SUPPORTED(); // 0xe3e13698
    error SUPER_TOKEN_NO_UNDERLYING_TOKEN(); // 0xf79cf656
    error SUPER_TOKEN_ONLY_SELF(); // 0x7ffa6648
    error SUPER_TOKEN_ONLY_HOST(); // 0x98f73704
    error SUPER_TOKEN_APPROVE_FROM_ZERO_ADDRESS(); // 0x81638627
    error SUPER_TOKEN_APPROVE_TO_ZERO_ADDRESS(); // 0xdf070274
    error SUPER_TOKEN_BURN_FROM_ZERO_ADDRESS(); // 0xba2ab184
    error SUPER_TOKEN_MINT_TO_ZERO_ADDRESS(); // 0x0d243157
    error SUPER_TOKEN_TRANSFER_FROM_ZERO_ADDRESS(); // 0xeecd6c9b
    error SUPER_TOKEN_TRANSFER_TO_ZERO_ADDRESS(); // 0xe219bd39

    /**
     * @dev Initialize the contract
     */
    function initialize(IERC20 underlyingToken, uint8 underlyingDecimals, string calldata n, string calldata s)
        external;

    /**
     *
     * IStandardERC20 & ERC777
     *
     */

    /**
     * @dev Returns the name of the token.
     */
    function name() external view override(IERC777, IStandardERC20) returns (string memory);

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() external view override(IERC777, IStandardERC20) returns (string memory);

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * @custom:note SuperToken always uses 18 decimals.
     *
     * This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() external view override(IStandardERC20) returns (uint8);

    /**
     *
     * ERC20 & ERC777
     *
     */

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() external view override(IERC777, IERC20) returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by an account (`owner`).
     */
    function balanceOf(address account) external view override(IERC777, IERC20) returns (uint256 balance);

    /**
     *
     * ERC20
     *
     */

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * @return Returns Success a boolean value indicating whether the operation succeeded.
     *
     * @custom:emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external override(IERC20) returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     *         allowed to spend on behalf of `owner` through {transferFrom}. This is
     *         zero by default.
     *
     * @notice This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view override(IERC20) returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * @return Returns Success a boolean value indicating whether the operation succeeded.
     *
     * @custom:note Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * @custom:emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external override(IERC20) returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     *         allowance mechanism. `amount` is then deducted from the caller's
     *         allowance.
     *
     * @return Returns Success a boolean value indicating whether the operation succeeded.
     *
     * @custom:emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external override(IERC20) returns (bool);

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * @custom:emits an {Approval} event indicating the updated allowance.
     *
     * @custom:requirements
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * @custom:emits an {Approval} event indicating the updated allowance.
     *
     * @custom:requirements
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);

    /**
     *
     * ERC777
     *
     */

    /**
     * @dev Returns the smallest part of the token that is not divisible. This
     *         means all token operations (creation, movement and destruction) must have
     *         amounts that are a multiple of this number.
     *
     * @custom:note For super token contracts, this value is always 1
     */
    function granularity() external view override(IERC777) returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * @dev If send or receive hooks are registered for the caller and `recipient`,
     *      the corresponding functions will be called with `data` and empty
     *      `operatorData`. See {IERC777Sender} and {IERC777Recipient}.
     *
     * @custom:emits a {Sent} event.
     *
     * @custom:requirements
     * - the caller must have at least `amount` tokens.
     * - `recipient` cannot be the zero address.
     * - if `recipient` is a contract, it must implement the {IERC777Recipient}
     * interface.
     */
    function send(address recipient, uint256 amount, bytes calldata data) external override(IERC777);

    /**
     * @dev Destroys `amount` tokens from the caller's account, reducing the
     * total supply and transfers the underlying token to the caller's account.
     *
     * If a send hook is registered for the caller, the corresponding function
     * will be called with `data` and empty `operatorData`. See {IERC777Sender}.
     *
     * @custom:emits a {Burned} event.
     *
     * @custom:requirements
     * - the caller must have at least `amount` tokens.
     */
    function burn(uint256 amount, bytes calldata data) external override(IERC777);

    /**
     * @dev Returns true if an account is an operator of `tokenHolder`.
     * Operators can send and burn tokens on behalf of their owners. All
     * accounts are their own operator.
     *
     * See {operatorSend} and {operatorBurn}.
     */
    function isOperatorFor(address operator, address tokenHolder) external view override(IERC777) returns (bool);

    /**
     * @dev Make an account an operator of the caller.
     *
     * See {isOperatorFor}.
     *
     * @custom:emits an {AuthorizedOperator} event.
     *
     * @custom:requirements
     * - `operator` cannot be calling address.
     */
    function authorizeOperator(address operator) external override(IERC777);

    /**
     * @dev Revoke an account's operator status for the caller.
     *
     * See {isOperatorFor} and {defaultOperators}.
     *
     * @custom:emits a {RevokedOperator} event.
     *
     * @custom:requirements
     * - `operator` cannot be calling address.
     */
    function revokeOperator(address operator) external override(IERC777);

    /**
     * @dev Returns the list of default operators. These accounts are operators
     * for all token holders, even if {authorizeOperator} was never called on
     * them.
     *
     * This list is immutable, but individual holders may revoke these via
     * {revokeOperator}, in which case {isOperatorFor} will return false.
     */
    function defaultOperators() external view override(IERC777) returns (address[] memory);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient`. The caller must
     * be an operator of `sender`.
     *
     * If send or receive hooks are registered for `sender` and `recipient`,
     * the corresponding functions will be called with `data` and
     * `operatorData`. See {IERC777Sender} and {IERC777Recipient}.
     *
     * @custom:emits a {Sent} event.
     *
     * @custom:requirements
     * - `sender` cannot be the zero address.
     * - `sender` must have at least `amount` tokens.
     * - the caller must be an operator for `sender`.
     * - `recipient` cannot be the zero address.
     * - if `recipient` is a contract, it must implement the {IERC777Recipient}
     * interface.
     */
    function operatorSend(
        address sender,
        address recipient,
        uint256 amount,
        bytes calldata data,
        bytes calldata operatorData
    ) external override(IERC777);

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the total supply.
     * The caller must be an operator of `account`.
     *
     * If a send hook is registered for `account`, the corresponding function
     * will be called with `data` and `operatorData`. See {IERC777Sender}.
     *
     * @custom:emits a {Burned} event.
     *
     * @custom:requirements
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     * - the caller must be an operator for `account`.
     */
    function operatorBurn(address account, uint256 amount, bytes calldata data, bytes calldata operatorData)
        external
        override(IERC777);

    /**
     *
     * SuperToken custom token functions
     *
     */

    /**
     * @dev Mint new tokens for the account
     *
     * @custom:modifiers
     *  - onlySelf
     */
    function selfMint(address account, uint256 amount, bytes memory userData) external;

    /**
     * @dev Burn existing tokens for the account
     *
     * @custom:modifiers
     *  - onlySelf
     */
    function selfBurn(address account, uint256 amount, bytes memory userData) external;

    /**
     * @dev Transfer `amount` tokens from the `sender` to `recipient`.
     * If `spender` isn't the same as `sender`, checks if `spender` has allowance to
     * spend tokens of `sender`.
     *
     * @custom:modifiers
     *  - onlySelf
     */
    function selfTransferFrom(address sender, address spender, address recipient, uint256 amount) external;

    /**
     * @dev Give `spender`, `amount` allowance to spend the tokens of
     * `account`.
     *
     * @custom:modifiers
     *  - onlySelf
     */
    function selfApproveFor(address account, address spender, uint256 amount) external;

    /**
     *
     * SuperToken extra functions
     *
     */

    /**
     * @dev Transfer all available balance from `msg.sender` to `recipient`
     */
    function transferAll(address recipient) external;

    /**
     *
     * ERC20 wrapping
     *
     */

    /**
     * @dev Return the underlying token contract
     * @return tokenAddr Underlying token address
     */
    function getUnderlyingToken() external view returns (address tokenAddr);

    /**
     * @dev Upgrade ERC20 to SuperToken.
     * @param amount Number of tokens to be upgraded (in 18 decimals)
     *
     * @custom:note It will use `transferFrom` to get tokens. Before calling this
     * function you should `approve` this contract
     */
    function upgrade(uint256 amount) external;

    /**
     * @dev Upgrade ERC20 to SuperToken and transfer immediately
     * @param to The account to receive upgraded tokens
     * @param amount Number of tokens to be upgraded (in 18 decimals)
     * @param data User data for the TokensRecipient callback
     *
     * @custom:note It will use `transferFrom` to get tokens. Before calling this
     * function you should `approve` this contract
     *
     * @custom:warning
     * - there is potential of reentrancy IF the "to" account is a registered ERC777 recipient.
     * @custom:requirements
     * - if `data` is NOT empty AND `to` is a contract, it MUST be a registered ERC777 recipient otherwise it reverts.
     */
    function upgradeTo(address to, uint256 amount, bytes calldata data) external;

    /**
     * @dev Token upgrade event
     * @param account Account where tokens are upgraded to
     * @param amount Amount of tokens upgraded (in 18 decimals)
     */
    event TokenUpgraded(address indexed account, uint256 amount);

    /**
     * @dev Downgrade SuperToken to ERC20.
     * @dev It will call transfer to send tokens
     * @param amount Number of tokens to be downgraded
     */
    function downgrade(uint256 amount) external;

    /**
     * @dev Downgrade SuperToken to ERC20 and transfer immediately
     * @param to The account to receive downgraded tokens
     * @param amount Number of tokens to be downgraded (in 18 decimals)
     */
    function downgradeTo(address to, uint256 amount) external;

    /**
     * @dev Token downgrade event
     * @param account Account whose tokens are downgraded
     * @param amount Amount of tokens downgraded
     */
    event TokenDowngraded(address indexed account, uint256 amount);

    /**
     *
     * Batch Operations
     *
     */

    /**
     * @dev Perform ERC20 approve by host contract.
     * @param account The account owner to be approved.
     * @param spender The spender of account owner's funds.
     * @param amount Number of tokens to be approved.
     *
     * @custom:modifiers
     *  - onlyHost
     */
    function operationApprove(address account, address spender, uint256 amount) external;

    /**
     * @dev Perform ERC20 transferFrom by host contract.
     * @param account The account to spend sender's funds.
     * @param spender The account where the funds is sent from.
     * @param recipient The recipient of the funds.
     * @param amount Number of tokens to be transferred.
     *
     * @custom:modifiers
     *  - onlyHost
     */
    function operationTransferFrom(address account, address spender, address recipient, uint256 amount) external;

    /**
     * @dev Perform ERC777 send by host contract.
     * @param spender The account where the funds is sent from.
     * @param recipient The recipient of the funds.
     * @param amount Number of tokens to be transferred.
     * @param data Arbitrary user inputted data
     *
     * @custom:modifiers
     *  - onlyHost
     */
    function operationSend(address spender, address recipient, uint256 amount, bytes memory data) external;

    /**
     * @dev Upgrade ERC20 to SuperToken by host contract.
     * @param account The account to be changed.
     * @param amount Number of tokens to be upgraded (in 18 decimals)
     *
     * @custom:modifiers
     *  - onlyHost
     */
    function operationUpgrade(address account, uint256 amount) external;

    /**
     * @dev Downgrade ERC20 to SuperToken by host contract.
     * @param account The account to be changed.
     * @param amount Number of tokens to be downgraded (in 18 decimals)
     *
     * @custom:modifiers
     *  - onlyHost
     */
    function operationDowngrade(address account, uint256 amount) external;

    /**
     *
     * Function modifiers for access control and parameter validations
     *
     * While they cannot be explicitly stated in function definitions, they are
     * listed in function definition comments instead for clarity.
     *
     * NOTE: solidity-coverage not supporting it
     *
     */

    /// @dev The msg.sender must be the contract itself
    //modifier onlySelf() virtual
}

// SPDX-License-Identifier: AGPLv3
pragma solidity >= 0.8.4;

/**
 * @title Superfluid token interface
 * @author Superfluid
 */
interface ISuperfluidToken {
    /**
     *
     * Errors
     *
     */
    error SF_TOKEN_AGREEMENT_ALREADY_EXISTS(); // 0xf05521f6
    error SF_TOKEN_AGREEMENT_DOES_NOT_EXIST(); // 0xdae18809
    error SF_TOKEN_BURN_INSUFFICIENT_BALANCE(); // 0x10ecdf44
    error SF_TOKEN_MOVE_INSUFFICIENT_BALANCE(); // 0x2f4cb941
    error SF_TOKEN_ONLY_LISTED_AGREEMENT(); // 0xc9ff6644
    error SF_TOKEN_ONLY_HOST(); // 0xc51efddd

    /**
     *
     * Basic information
     *
     */

    /**
     * @dev Get superfluid host contract address
     */
    function getHost() external view returns (address host);

    /**
     * @dev Encoded liquidation type data mainly used for handling stack to deep errors
     *
     * @custom:note
     * - version: 1
     * - liquidationType key:
     *    - 0 = reward account receives reward (PIC period)
     *    - 1 = liquidator account receives reward (Pleb period)
     *    - 2 = liquidator account receives reward (Pirate period/bailout)
     */
    struct LiquidationTypeData {
        uint256 version;
        uint8 liquidationType;
    }

    /**
     *
     * Real-time balance functions
     *
     */

    /**
     * @dev Calculate the real balance of a user, taking in consideration all agreements of the account
     * @param account for the query
     * @param timestamp Time of balance
     * @return availableBalance Real-time balance
     * @return deposit Account deposit
     * @return owedDeposit Account owed Deposit
     */
    function realtimeBalanceOf(address account, uint256 timestamp)
        external
        view
        returns (int256 availableBalance, uint256 deposit, uint256 owedDeposit);

    /**
     * @notice Calculate the realtime balance given the current host.getNow() value
     * @dev realtimeBalanceOf with timestamp equals to block timestamp
     * @param account for the query
     * @return availableBalance Real-time balance
     * @return deposit Account deposit
     * @return owedDeposit Account owed Deposit
     */
    function realtimeBalanceOfNow(address account)
        external
        view
        returns (int256 availableBalance, uint256 deposit, uint256 owedDeposit, uint256 timestamp);

    /**
     * @notice Check if account is critical
     * @dev A critical account is when availableBalance < 0
     * @param account The account to check
     * @param timestamp The time we'd like to check if the account is critical (should use future)
     * @return isCritical Whether the account is critical
     */
    function isAccountCritical(address account, uint256 timestamp) external view returns (bool isCritical);

    /**
     * @notice Check if account is critical now (current host.getNow())
     * @dev A critical account is when availableBalance < 0
     * @param account The account to check
     * @return isCritical Whether the account is critical
     */
    function isAccountCriticalNow(address account) external view returns (bool isCritical);

    /**
     * @notice Check if account is solvent
     * @dev An account is insolvent when the sum of deposits for a token can't cover the negative availableBalance
     * @param account The account to check
     * @param timestamp The time we'd like to check if the account is solvent (should use future)
     * @return isSolvent True if the account is solvent, false otherwise
     */
    function isAccountSolvent(address account, uint256 timestamp) external view returns (bool isSolvent);

    /**
     * @notice Check if account is solvent now
     * @dev An account is insolvent when the sum of deposits for a token can't cover the negative availableBalance
     * @param account The account to check
     * @return isSolvent True if the account is solvent, false otherwise
     */
    function isAccountSolventNow(address account) external view returns (bool isSolvent);

    /**
     *
     * Super Agreement hosting functions
     *
     */

    /**
     * @dev Create a new agreement
     * @param id Agreement ID
     * @param data Agreement data
     */
    function createAgreement(bytes32 id, bytes32[] calldata data) external;
    /**
     * @dev Agreement created event
     * @param agreementClass Contract address of the agreement
     * @param id Agreement ID
     * @param data Agreement data
     */

    event AgreementCreated(address indexed agreementClass, bytes32 id, bytes32[] data);

    /**
     * @dev Get data of the agreement
     * @param agreementClass Contract address of the agreement
     * @param id Agreement ID
     * @return data Data of the agreement
     */
    function getAgreementData(address agreementClass, bytes32 id, uint256 dataLength)
        external
        view
        returns (bytes32[] memory data);

    /**
     * @dev Create a new agreement
     * @param id Agreement ID
     * @param data Agreement data
     */
    function updateAgreementData(bytes32 id, bytes32[] calldata data) external;
    /**
     * @dev Agreement updated event
     * @param agreementClass Contract address of the agreement
     * @param id Agreement ID
     * @param data Agreement data
     */

    event AgreementUpdated(address indexed agreementClass, bytes32 id, bytes32[] data);

    /**
     * @dev Close the agreement
     * @param id Agreement ID
     */
    function terminateAgreement(bytes32 id, uint256 dataLength) external;
    /**
     * @dev Agreement terminated event
     * @param agreementClass Contract address of the agreement
     * @param id Agreement ID
     */

    event AgreementTerminated(address indexed agreementClass, bytes32 id);

    /**
     * @dev Update agreement state slot
     * @param account Account to be updated
     *
     * @custom:note
     * - To clear the storage out, provide zero-ed array of intended length
     */
    function updateAgreementStateSlot(address account, uint256 slotId, bytes32[] calldata slotData) external;
    /**
     * @dev Agreement account state updated event
     * @param agreementClass Contract address of the agreement
     * @param account Account updated
     * @param slotId slot id of the agreement state
     */

    event AgreementStateUpdated(address indexed agreementClass, address indexed account, uint256 slotId);

    /**
     * @dev Get data of the slot of the state of an agreement
     * @param agreementClass Contract address of the agreement
     * @param account Account to query
     * @param slotId slot id of the state
     * @param dataLength length of the state data
     */
    function getAgreementStateSlot(address agreementClass, address account, uint256 slotId, uint256 dataLength)
        external
        view
        returns (bytes32[] memory slotData);

    /**
     * @notice Settle balance from an account by the agreement
     * @dev The agreement needs to make sure that the balance delta is balanced afterwards
     * @param account Account to query.
     * @param delta Amount of balance delta to be settled
     *
     * @custom:modifiers
     *  - onlyAgreement
     */
    function settleBalance(address account, int256 delta) external;

    /**
     * @dev Make liquidation payouts (v2)
     * @param id Agreement ID
     * @param liquidationTypeData Data regarding the version of the liquidation schema and the type
     * @param liquidatorAccount Address of the executor of the liquidation
     * @param useDefaultRewardAccount Whether or not the default reward account receives the rewardAmount
     * @param targetAccount Account to be liquidated
     * @param rewardAmount The amount the rewarded account will receive
     * @param targetAccountBalanceDelta The delta amount the target account balance should change by
     *
     * @custom:note
     * - If a bailout is required (bailoutAmount > 0)
     *   - the actual reward (single deposit) goes to the executor,
     *   - while the reward account becomes the bailout account
     *   - total bailout include: bailout amount + reward amount
     *   - the targetAccount will be bailed out
     * - If a bailout is not required
     *   - the targetAccount will pay the rewardAmount
     *   - the liquidator (reward account in PIC period) will receive the rewardAmount
     *
     * @custom:modifiers
     *  - onlyAgreement
     */
    function makeLiquidationPayoutsV2(
        bytes32 id,
        bytes memory liquidationTypeData,
        address liquidatorAccount,
        bool useDefaultRewardAccount,
        address targetAccount,
        uint256 rewardAmount,
        int256 targetAccountBalanceDelta
    ) external;
    /**
     * @dev Agreement liquidation event v2 (including agent account)
     * @param agreementClass Contract address of the agreement
     * @param id Agreement ID
     * @param liquidatorAccount Address of the executor of the liquidation
     * @param targetAccount Account of the stream sender
     * @param rewardAmountReceiver Account that collects the reward or bails out insolvent accounts
     * @param rewardAmount The amount the reward recipient account balance should change by
     * @param targetAccountBalanceDelta The amount the sender account balance should change by
     * @param liquidationTypeData The encoded liquidation type data including the version (how to decode)
     *
     * @custom:note
     * Reward account rule:
     * - if the agreement is liquidated during the PIC period
     *   - the rewardAmountReceiver will get the rewardAmount (remaining deposit), regardless of the liquidatorAccount
     *   - the targetAccount will pay for the rewardAmount
     * - if the agreement is liquidated after the PIC period AND the targetAccount is solvent
     *   - the rewardAmountReceiver will get the rewardAmount (remaining deposit)
     *   - the targetAccount will pay for the rewardAmount
     * - if the targetAccount is insolvent
     *   - the liquidatorAccount will get the rewardAmount (single deposit)
     *   - the default reward account (governance) will pay for both the rewardAmount and bailoutAmount
     *   - the targetAccount will receive the bailoutAmount
     */

    event AgreementLiquidatedV2(
        address indexed agreementClass,
        bytes32 id,
        address indexed liquidatorAccount,
        address indexed targetAccount,
        address rewardAmountReceiver,
        uint256 rewardAmount,
        int256 targetAccountBalanceDelta,
        bytes liquidationTypeData
    );

    /**
     *
     * Function modifiers for access control and parameter validations
     *
     * While they cannot be explicitly stated in function definitions, they are
     * listed in function definition comments instead for clarity.
     *
     * NOTE: solidity-coverage not supporting it
     *
     */

    /// @dev The msg.sender must be host contract
    //modifier onlyHost() virtual;

    /// @dev The msg.sender must be a listed agreement.
    //modifier onlyAgreement() virtual;

    /**
     *
     * DEPRECATED
     *
     */

    /**
     * @dev Agreement liquidation event (DEPRECATED BY AgreementLiquidatedBy)
     * @param agreementClass Contract address of the agreement
     * @param id Agreement ID
     * @param penaltyAccount Account of the agreement to be penalized
     * @param rewardAccount Account that collect the reward
     * @param rewardAmount Amount of liquidation reward
     *
     * @custom:deprecated Use AgreementLiquidatedV2 instead
     */
    event AgreementLiquidated(
        address indexed agreementClass,
        bytes32 id,
        address indexed penaltyAccount,
        address indexed rewardAccount,
        uint256 rewardAmount
    );

    /**
     * @dev System bailout occurred (DEPRECATED BY AgreementLiquidatedBy)
     * @param bailoutAccount Account that bailout the penalty account
     * @param bailoutAmount Amount of account bailout
     *
     * @custom:deprecated Use AgreementLiquidatedV2 instead
     */
    event Bailout(address indexed bailoutAccount, uint256 bailoutAmount);

    /**
     * @dev Agreement liquidation event (DEPRECATED BY AgreementLiquidatedV2)
     * @param liquidatorAccount Account of the agent that performed the liquidation.
     * @param agreementClass Contract address of the agreement
     * @param id Agreement ID
     * @param penaltyAccount Account of the agreement to be penalized
     * @param bondAccount Account that collect the reward or bailout accounts
     * @param rewardAmount Amount of liquidation reward
     * @param bailoutAmount Amount of liquidation bailouot
     *
     * @custom:deprecated Use AgreementLiquidatedV2 instead
     *
     * @custom:note
     * Reward account rule:
     * - if bailout is equal to 0, then
     *   - the bondAccount will get the rewardAmount,
     *   - the penaltyAccount will pay for the rewardAmount.
     * - if bailout is larger than 0, then
     *   - the liquidatorAccount will get the rewardAmouont,
     *   - the bondAccount will pay for both the rewardAmount and bailoutAmount,
     *   - the penaltyAccount will pay for the rewardAmount while get the bailoutAmount.
     */
    event AgreementLiquidatedBy(
        address liquidatorAccount,
        address indexed agreementClass,
        bytes32 id,
        address indexed penaltyAccount,
        address indexed bondAccount,
        uint256 rewardAmount,
        uint256 bailoutAmount
    );
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.0;

import "src/interfaces/ISynthereumFinder.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title Interface that a pool MUST have in order to be included in the deployer
 */

interface ISynthereumDeployment {
    /**
     * @notice Get Synthereum finder of the pool/self-minting derivative
     * @return finder Returns finder contract
     */
    function synthereumFinder() external view returns (ISynthereumFinder finder);

    /**
     * @notice Get Synthereum version
     * @return contractVersion Returns the version of this pool/self-minting derivative
     */
    function version() external view returns (uint8 contractVersion);

    /**
     * @notice Get the collateral token of this pool/self-minting derivative
     * @return collateralCurrency The ERC20 collateral token
     */
    function collateralToken() external view returns (IERC20 collateralCurrency);

    /**
     * @notice Get the synthetic token associated to this pool/self-minting derivative
     * @return syntheticCurrency The ERC20 synthetic token
     */
    function syntheticToken() external view returns (IERC20 syntheticCurrency);

    /**
     * @notice Get the synthetic token symbol associated to this pool/self-minting derivative
     * @return symbol The ERC20 synthetic token symbol
     */
    function syntheticTokenSymbol() external view returns (string memory symbol);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.0;

/**
 * @title Provides addresses of the contracts implementing certain interfaces.
 */
interface ISynthereumFinder {
    /**
     * @notice Updates the address of the contract that implements `interfaceName`.
     * @param interfaceName bytes32 encoding of the interface name that is either changed or registered.
     * @param implementationAddress address of the deployed contract that implements the interface.
     */
    function changeImplementationAddress(bytes32 interfaceName, address implementationAddress) external;

    /**
     * @notice Gets the address of the contract that implements the given `interfaceName`.
     * @param interfaceName queried interface.
     * @return implementationAddress Address of the deployed contract that implements the interface.
     */
    function getImplementationAddress(bytes32 interfaceName) external view returns (address);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.0;

import {ITypology} from "src/interfaces/ITypology.sol";
import {ISynthereumDeployment} from "src/interfaces/ISynthereumDeployment.sol";

interface ISynthereumFixedRateWrapper is ITypology, ISynthereumDeployment {
    // Describe role structure
    struct Roles {
        address admin;
        address maintainer;
    }

    /**
     * @notice This function is used to mint new fixed rate synthetic tokens by depositing peg collateral tokens
     * @notice The conversion is based on a fixed rate
     * @param _collateral The amount of peg collateral tokens to be deposited
     * @param _recipient The address of the recipient to receive the newly minted fixed rate synthetic tokens
     * @return amountTokens The amount of newly minted fixed rate synthetic tokens
     */
    function wrap(uint256 _collateral, address _recipient) external returns (uint256 amountTokens);

    /**
     * @notice This function is used to burn fixed rate synthetic tokens and receive the underlying peg collateral tokens
     * @notice The conversion is based on a fixed rate
     * @param _tokenAmount The amount of fixed rate synthetic tokens to be burned
     * @param _recipient The address of the recipient to receive the underlying peg collateral tokens
     * @return amountCollateral The amount of peg collateral tokens withdrawn
     */
    function unwrap(uint256 _tokenAmount, address _recipient) external returns (uint256 amountCollateral);

    /**
     * @notice A function that allows a maintainer to pause the execution of some functions in the contract
     * @notice This function suspends minting of new fixed rate synthetic tokens
     * @notice Pausing does not affect redeeming the peg collateral by burning the fixed rate synthetic tokens
     * @notice Pausing the contract is necessary in situations to prevent an issue with the smart contract or if the rate
     * between the fixed rate synthetic token and the peg collateral token changes
     */
    function pauseContract() external;

    /**
     * @notice A function that allows a maintainer to resume the execution of all functions in the contract
     * @notice After the resume contract function is called minting of new fixed rate synthetic assets is open again
     */
    function resumeContract() external;

    /**
     * @notice Check the conversion rate between peg-collateral and fixed-rate synthetic token
     * @return Coversion rate
     */
    function conversionRate() external view returns (uint256);

    /**
     * @notice Amount of peg collateral stored in the contract
     * @return Total peg collateral deposited
     */
    function totalPegCollateral() external view returns (uint256);

    /**
     * @notice Amount of synthetic tokens minted from the contract
     * @return Total synthetic tokens minted so far
     */
    function totalSyntheticTokensMinted() external view returns (uint256);

    /**
     * @notice Check if wrap can be performed or not
     * @return True if minting is paused, otherwise false
     */
    function isPaused() external view returns (bool);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.0;

import "src/interfaces/ITypology.sol";
import "src/interfaces/ISynthereumDeployment.sol";

import {IStandardERC20} from "src/interfaces/IStandardERC20.sol";
import {IMintableBurnableERC20} from "src/interfaces/IMintableBurnableERC20.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

/**
 * @title Multi LP pool interface
 */
interface ISynthereumMultiLpLiquidityPool is ITypology, ISynthereumDeployment {
    struct Storage {
        EnumerableSet.AddressSet registeredLPs;
        EnumerableSet.AddressSet activeLPs;
        mapping(address => LPPosition) lpPositions;
        string lendingModuleId;
        bytes32 priceIdentifier;
        uint256 totalSyntheticAsset;
        IStandardERC20 collateralAsset;
        uint64 fee;
        uint8 collateralDecimals;
        bool isInitialized;
        uint8 poolVersion;
        uint128 overCollateralRequirement;
        uint64 liquidationBonus;
        IMintableBurnableERC20 syntheticAsset;
    }

    // Describe role structure
    struct Roles {
        address admin;
        address maintainer;
    }

    struct InitializationParams {
        // Synthereum finder
        ISynthereumFinder finder;
        // Synthereum pool version
        uint8 version;
        // ERC20 collateral token
        IStandardERC20 collateralToken;
        // ERC20 synthetic token
        IMintableBurnableERC20 syntheticToken;
        // The addresses of admin and maintainer
        Roles roles;
        // The fee percentage
        uint64 fee;
        // Identifier of price to be used in the price feed
        bytes32 priceIdentifier;
        // Percentage of overcollateralization to which a liquidation can triggered
        uint128 overCollateralRequirement;
        // Percentage of reward for correct liquidation by a liquidator
        uint64 liquidationReward;
        // Name of the lending protocol used
        string lendingModuleId;
    }

    struct LPPosition {
        // Actual collateral owned
        uint256 actualCollateralAmount;
        // Number of tokens collateralized
        uint256 tokensCollateralized;
        // Overcollateralization percentage
        uint128 overCollateralization;
    }

    struct MintParams {
        // Minimum amount of synthetic tokens that a user wants to mint using collateral (anti-slippage)
        uint256 minNumTokens;
        // Amount of collateral that a user wants to spend for minting
        uint256 collateralAmount;
        // Expiration time of the transaction
        uint256 expiration;
        // Address to which send synthetic tokens minted
        address recipient;
    }

    struct RedeemParams {
        // Amount of synthetic tokens that user wants to use for redeeming
        uint256 numTokens;
        // Minimium amount of collateral that user wants to redeem (anti-slippage)
        uint256 minCollateral;
        // Expiration time of the transaction
        uint256 expiration;
        // Address to which send collateral tokens redeemed
        address recipient;
    }

    struct LPInfo {
        // Actual collateral owned
        uint256 actualCollateralAmount;
        // Number of tokens collateralized
        uint256 tokensCollateralized;
        // Overcollateralization percentage
        uint256 overCollateralization;
        // Actual Lp capacity of the Lp in synth asset  (actualCollateralAmount/overCollateralization) * price - numTokens
        uint256 capacity;
        // Utilization ratio: (numTokens * price_inv * overCollateralization) / actualCollateralAmount
        uint256 utilization;
        // Collateral coverage: (actualCollateralAmount + numTokens * price_inv) / (numTokens * price_inv)
        uint256 coverage;
        // Mint shares percentage
        uint256 mintShares;
        // Redeem shares percentage
        uint256 redeemShares;
        // Interest shares percentage
        uint256 interestShares;
        // True if it's overcollateralized, otherwise false
        bool isOvercollateralized;
    }

    /**
     * @notice Initialize pool
     * @param _params Params used for initialization (see InitializationParams struct)
     */
    function initialize(InitializationParams calldata _params) external;

    /**
     * @notice Register a liquidity provider to the LP's whitelist
     * @notice This can be called only by the maintainer
     * @param _lp Address of the LP
     */
    function registerLP(address _lp) external;

    /**
     * @notice Add the Lp to the active list of the LPs and initialize collateral and overcollateralization
     * @notice Only a registered and inactive LP can call this function to add himself
     * @param _collateralAmount Collateral amount to deposit by the LP
     * @param _overCollateralization Overcollateralization to set by the LP
     * @return collateralDeposited Net collateral deposited in the LP position
     */
    function activateLP(uint256 _collateralAmount, uint128 _overCollateralization)
        external
        returns (uint256 collateralDeposited);

    /**
     * @notice Add collateral to an active LP position
     * @notice Only an active LP can call this function to add collateral to his position
     * @param _collateralAmount Collateral amount to deposit by the LP
     * @return collateralDeposited Net collateral deposited in the LP position
     * @return newLpCollateralAmount Amount of collateral of the LP after the increase
     */
    function addLiquidity(uint256 _collateralAmount)
        external
        returns (uint256 collateralDeposited, uint256 newLpCollateralAmount);

    /**
     * @notice Withdraw collateral from an active LP position
     * @notice Only an active LP can call this function to withdraw collateral from his position
     * @param _collateralAmount Collateral amount to withdraw by the LP
     * @return collateralRemoved Net collateral decreased form the position
     * @return collateralReceived Collateral received from the withdrawal
     * @return newLpCollateralAmount Amount of collateral of the LP after the decrease
     */
    function removeLiquidity(uint256 _collateralAmount)
        external
        returns (uint256 collateralRemoved, uint256 collateralReceived, uint256 newLpCollateralAmount);

    /**
     * @notice Set the overCollateralization by an active LP
     * @notice This can be called only by an active LP
     * @param _overCollateralization New overCollateralizations
     */
    function setOvercollateralization(uint128 _overCollateralization) external;

    /**
     * @notice Mint synthetic tokens using fixed amount of collateral
     * @notice This calculate the price using on chain price feed
     * @notice User must approve collateral transfer for the mint request to succeed
     * @param mintParams Input parameters for minting (see MintParams struct)
     * @return syntheticTokensMinted Amount of synthetic tokens minted by a user
     * @return feePaid Amount of collateral paid by the user as fee
     */
    function mint(MintParams calldata mintParams) external returns (uint256 syntheticTokensMinted, uint256 feePaid);

    /**
     * @notice Redeem amount of collateral using fixed number of synthetic token
     * @notice This calculate the price using on chain price feed
     * @notice User must approve synthetic token transfer for the redeem request to succeed
     * @param redeemParams Input parameters for redeeming (see RedeemParams struct)
     * @return collateralRedeemed Amount of collateral redeem by user
     * @return feePaid Amount of collateral paid by user as fee
     */
    function redeem(RedeemParams calldata redeemParams)
        external
        returns (uint256 collateralRedeemed, uint256 feePaid);

    /**
     * @notice Liquidate Lp position for an amount of synthetic tokens undercollateralized
     * @notice Revert if position is not undercollateralized
     * @param lp LP that the the user wants to liquidate
     * @param numSynthTokens Number of synthetic tokens that user wants to liquidate
     * @return Amount of collateral received (Amount of collateral + bonus)
     */
    function liquidate(address lp, uint256 numSynthTokens) external returns (uint256);

    /**
     * @notice Update interests and positions ov every LP
     * @notice Everyone can call this function
     */
    function updatePositions() external;

    /**
     * @notice Set new liquidation reward percentage
     * @notice This can be called only by the maintainer
     * @param _newLiquidationReward New liquidation reward percentage
     */
    function setLiquidationReward(uint64 _newLiquidationReward) external;

    /**
     * @notice Set new fee percentage
     * @notice This can be called only by the maintainer
     * @param _fee New fee percentage
     */
    function setFee(uint64 _fee) external;

    /**
     * @notice Get all the registered LPs of this pool
     * @return lps The list of addresses of all the registered LPs in the pool.
     */
    function getRegisteredLPs() external view returns (address[] memory lps);

    /**
     * @notice Get all the active LPs of this pool
     * @return lps The list of addresses of all the active LPs in the pool.
     */
    function getActiveLPs() external view returns (address[] memory lps);

    /**
     * @notice Check if the input LP is registered
     * @param _lp Address of the LP
     * @return isRegistered Return true if the LP is regitered, otherwise false
     */
    function isRegisteredLP(address _lp) external view returns (bool isRegistered);

    /**
     * @notice Check if the input LP is active
     * @param _lp Address of the LP
     * @return isActive Return true if the LP is active, otherwise false
     */
    function isActiveLP(address _lp) external view returns (bool isActive);

    /**
     * @notice Get the decimals of the collateral
     * @return Number of decimals of the collateral
     */
    function collateralTokenDecimals() external view returns (uint8);

    /**
     * @notice Returns the percentage of overcollateralization to which a liquidation can triggered
     * @return requirement Thresold percentage on a liquidation can be triggered
     */
    function collateralRequirement() external view returns (uint256 requirement);

    /**
     * @notice Returns the percentage of reward for correct liquidation by a liquidator
     * @return reward Percentage of reward
     */
    function liquidationReward() external view returns (uint256 reward);

    /**
     * @notice Returns price identifier of the pool
     * @return identifier Price identifier
     */
    function priceFeedIdentifier() external view returns (bytes32 identifier);

    /**
     * @notice Returns fee percentage of the pool
     * @return fee Fee percentage
     */
    function feePercentage() external view returns (uint256 fee);

    /**
     * @notice Returns total number of synthetic tokens generated by this pool
     * @return totalTokens Number of total synthetic tokens in the pool
     */
    function totalSyntheticTokens() external view returns (uint256 totalTokens);

    /**
     * @notice Returns the total amounts of collateral
     * @return usersCollateral Total collateral amount currently holded by users
     * @return lpsCollateral Total collateral amount currently holded by LPs
     * @return totalCollateral Total collateral amount currently holded by users + LPs
     */
    function totalCollateralAmount()
        external
        view
        returns (uint256 usersCollateral, uint256 lpsCollateral, uint256 totalCollateral);

    /**
     * @notice Returns the max capacity in synth assets of all the LPs
     * @return maxCapacity Total max capacity of the pool
     */
    function maxTokensCapacity() external view returns (uint256 maxCapacity);

    /**
     * @notice Returns the LP parametrs info
     * @notice Mint, redeem and intreest shares are round down (division dust not included)
     * @param _lp Address of the LP
     * @return info Info of the input LP (see LPInfo struct)
     */
    function positionLPInfo(address _lp) external view returns (LPInfo memory info);

    /**
     * @notice Returns the lending protocol info
     * @return lendingId Name of the lending module
     * @return bearingToken Address of the bearing token held by the pool for interest accrual
     */
    function lendingProtocolInfo() external view returns (string memory lendingId, address bearingToken);

    /**
     * @notice Returns the synthetic tokens will be received and fees will be paid in exchange for an input collateral amount
     * @notice This function is only trading-informative, it doesn't check edge case conditions like lending manager dust and reverting due to dust splitting
     * @param _collateralAmount Input collateral amount to be exchanged
     * @return synthTokensReceived Synthetic tokens will be minted
     * @return feePaid Collateral fee will be paid
     */
    function getMintTradeInfo(uint256 _collateralAmount)
        external
        view
        returns (uint256 synthTokensReceived, uint256 feePaid);

    /**
     * @notice Returns the collateral amount will be received and fees will be paid in exchange for an input amount of synthetic tokens
     * @notice This function is only trading-informative, it doesn't check edge case conditions like lending manager dust
     * @param  _syntTokensAmount Amount of synthetic tokens to be exchanged
     * @return collateralAmountReceived Collateral amount will be received by the user
     * @return feePaid Collateral fee will be paid
     */
    function getRedeemTradeInfo(uint256 _syntTokensAmount)
        external
        view
        returns (uint256 collateralAmountReceived, uint256 feePaid);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.0;

interface ITypology {
    /**
     * @notice Return typology of the contract
     */
    function typology() external view returns (string memory);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.17;

/// @title Constants
library Constants {
    /// @dev The address of the Ether token.
    address internal constant _ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    /// @dev Used for identifying cases when this contract's balance of a token is to be used
    uint256 internal constant CONTRACT_BALANCE = 0;

    /// @dev Used as a flag for identifying msg.sender, saves gas by sending more 0 bytes
    address internal constant MSG_SENDER = address(1);

    /// @dev Used as a flag for identifying address(this), saves gas by sending more 0 bytes
    address internal constant ADDRESS_THIS = address(2);

    /// @dev Error message when a swap from aggregator fails.
    error SWAP_FAILED();

    /// @dev Error message when the caller is not allowed to call the function.
    error NOT_ALLOWED();

    /// @dev Error message when the deadline has passed.
    error DEADLINE_EXCEEDED();

    /// @dev Error message for when the amount of received tokens is less than the minimum amount
    error NOT_ENOUGH_RECEIVED();

    /// @dev Error message when Stable Router is already initialized.
    error ALREADY_INITIALIZED();
}