//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title Library for access related errors.
 */
library AccessError {
    /**
     * @dev Thrown when an address tries to perform an unauthorized action.
     * @param addr The address that attempts the action.
     */
    error Unauthorized(address addr);
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title ERC20 token implementation.
 */
interface IERC20 {
    /**
     * @notice Emitted when tokens have been transferred.
     * @param from The address that originally owned the tokens.
     * @param to The address that received the tokens.
     * @param amount The number of tokens that were transferred.
     */
    event Transfer(address indexed from, address indexed to, uint amount);

    /**
     * @notice Emitted when a user has provided allowance to another user for transferring tokens on its behalf.
     * @param owner The address that is providing the allowance.
     * @param spender The address that received the allowance.
     * @param amount The number of tokens that were added to `spender`'s allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint amount);

    /**
     * @notice Thrown when the address interacting with the contract does not have sufficient allowance to transfer tokens from another contract.
     * @param required The necessary allowance.
     * @param existing The current allowance.
     */
    error InsufficientAllowance(uint required, uint existing);

    /**
     * @notice Thrown when the address interacting with the contract does not have sufficient tokens.
     * @param required The necessary balance.
     * @param existing The current balance.
     */
    error InsufficientBalance(uint required, uint existing);

    /**
     * @notice Retrieves the name of the token, e.g. "Synthetix Network Token".
     * @return A string with the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @notice Retrieves the symbol of the token, e.g. "SNX".
     * @return A string with the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @notice Retrieves the number of decimals used by the token. The default is 18.
     * @return The number of decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @notice Returns the total number of tokens in circulation (minted - burnt).
     * @return The total number of tokens.
     */
    function totalSupply() external view returns (uint);

    /**
     * @notice Returns the balance of a user.
     * @param owner The address whose balance is being retrieved.
     * @return The number of tokens owned by the user.
     */
    function balanceOf(address owner) external view returns (uint);

    /**
     * @notice Returns how many tokens a user has allowed another user to transfer on its behalf.
     * @param owner The user who has given the allowance.
     * @param spender The user who was given the allowance.
     * @return The amount of tokens `spender` can transfer on `owner`'s behalf.
     */
    function allowance(address owner, address spender) external view returns (uint);

    /**
     * @notice Transfer tokens from one address to another.
     * @param to The address that will receive the tokens.
     * @param amount The amount of tokens to be transferred.
     * @return A boolean which is true if the operation succeeded.
     */
    function transfer(address to, uint amount) external returns (bool);

    /**
     * @notice Allows users to provide allowance to other users so that they can transfer tokens on their behalf.
     * @param spender The address that is receiving the allowance.
     * @param amount The amount of tokens that are being added to the allowance.
     * @return A boolean which is true if the operation succeeded.
     */
    function approve(address spender, uint amount) external returns (bool);

    /**
     * @notice Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);

    /**
     * @notice Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);

    /**
     * @notice Allows a user who has been given allowance to transfer tokens on another user's behalf.
     * @param from The address that owns the tokens that are being transferred.
     * @param to The address that will receive the tokens.
     * @param amount The number of tokens to transfer.
     * @return A boolean which is true if the operation succeeded.
     */
    function transferFrom(address from, address to, uint amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title ERC721 non-fungible token (NFT) contract.
 */
interface IERC721 {
    /**
     * @notice Thrown when an address attempts to provide allowance to itself.
     * @param addr The address attempting to provide allowance.
     */
    error CannotSelfApprove(address addr);

    /**
     * @notice Thrown when attempting to transfer a token to an address that does not satisfy IERC721Receiver requirements.
     * @param addr The address that cannot receive the tokens.
     */
    error InvalidTransferRecipient(address addr);

    /**
     * @notice Thrown when attempting to specify an owner which is not valid (ex. the 0x00000... address)
     */
    error InvalidOwner(address addr);

    /**
     * @notice Thrown when attempting to operate on a token id that does not exist.
     * @param id The token id that does not exist.
     */
    error TokenDoesNotExist(uint256 id);

    /**
     * @notice Thrown when attempting to mint a token that already exists.
     * @param id The token id that already exists.
     */
    error TokenAlreadyMinted(uint256 id);

    /**
     * @notice Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @notice Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @notice Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @notice Returns the number of tokens in ``owner``'s account.
     *
     * Requirements:
     *
     * - `holder` must be a valid address
     */
    function balanceOf(address holder) external view returns (uint256 balance);

    /**
     * @notice Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @notice Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @notice Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @notice Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @notice Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @notice Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @notice Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @notice Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import "./IERC721.sol";

/**
 * @title ERC721 extension with helper functions that allow the enumeration of NFT tokens.
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @notice Thrown calling *ByIndex function with an index greater than the number of tokens existing
     * @param requestedIndex The index requested by the caller
     * @param length The length of the list that is being iterated, making the max index queryable length - 1
     */
    error IndexOverrun(uint requestedIndex, uint length);

    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     *
     * Requirements:
     * - `owner` must be a valid address
     * - `index` must be less than the balance of the tokens for the owner
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     *
     * Requirements:
     * - `index` must be less than the total supply of the tokens
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import "../errors/AccessError.sol";

library OwnableStorage {
    bytes32 private constant _SLOT_OWNABLE_STORAGE =
        keccak256(abi.encode("io.synthetix.core-contracts.Ownable"));

    struct Data {
        address owner;
        address nominatedOwner;
    }

    function load() internal pure returns (Data storage store) {
        bytes32 s = _SLOT_OWNABLE_STORAGE;
        assembly {
            store.slot := s
        }
    }

    function onlyOwner() internal view {
        if (msg.sender != getOwner()) {
            revert AccessError.Unauthorized(msg.sender);
        }
    }

    function getOwner() internal view returns (address) {
        return OwnableStorage.load().owner;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * Utilities that convert numeric types avoiding silent overflows.
 */
import "./SafeCast/SafeCastU32.sol";
import "./SafeCast/SafeCastI32.sol";
import "./SafeCast/SafeCastI24.sol";
import "./SafeCast/SafeCastU56.sol";
import "./SafeCast/SafeCastI56.sol";
import "./SafeCast/SafeCastU64.sol";
import "./SafeCast/SafeCastI128.sol";
import "./SafeCast/SafeCastI256.sol";
import "./SafeCast/SafeCastU128.sol";
import "./SafeCast/SafeCastU160.sol";
import "./SafeCast/SafeCastU256.sol";
import "./SafeCast/SafeCastAddress.sol";
import "./SafeCast/SafeCastBytes32.sol";

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title See SafeCast.sol.
 */
library SafeCastAddress {
    function toBytes32(address x) internal pure returns (bytes32) {
        return bytes32(uint256(uint160(x)));
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title See SafeCast.sol.
 */
library SafeCastBytes32 {
    function toAddress(bytes32 x) internal pure returns (address) {
        return address(uint160(uint256(x)));
    }

    function toUint(bytes32 x) internal pure returns (uint) {
        return uint(x);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title See SafeCast.sol.
 */
library SafeCastI128 {
    error OverflowInt128ToUint128();
    error OverflowInt128ToInt32();

    function toUint(int128 x) internal pure returns (uint128) {
        // ----------------<==============o==============>-----------------
        // ----------------xxxxxxxxxxxxxxxo===============>----------------
        if (x < 0) {
            revert OverflowInt128ToUint128();
        }

        return uint128(x);
    }

    function to256(int128 x) internal pure returns (int256) {
        return int256(x);
    }

    function to32(int128 x) internal pure returns (int32) {
        // ----------------<==============o==============>-----------------
        // ----------------xxxxxxxxxxxx<==o==>xxxxxxxxxxxx-----------------
        if (x < int(type(int32).min) || x > int(type(int32).max)) {
            revert OverflowInt128ToInt32();
        }

        return int32(x);
    }

    function zero() internal pure returns (int128) {
        return int128(0);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title See SafeCast.sol.
 */
library SafeCastI24 {
    function to256(int24 x) internal pure returns (int256) {
        return int256(x);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title See SafeCast.sol.
 */
library SafeCastI256 {
    error OverflowInt256ToUint256();
    error OverflowInt256ToInt128();
    error OverflowInt256ToInt24();

    function to128(int256 x) internal pure returns (int128) {
        // ----<==========================o===========================>----
        // ----xxxxxxxxxxxx<==============o==============>xxxxxxxxxxxxx----
        if (x < int256(type(int128).min) || x > int256(type(int128).max)) {
            revert OverflowInt256ToInt128();
        }

        return int128(x);
    }

    function to24(int256 x) internal pure returns (int24) {
        // ----<==========================o===========================>----
        // ----xxxxxxxxxxxxxxxxxxxx<======o=======>xxxxxxxxxxxxxxxxxxxx----
        if (x < int256(type(int24).min) || x > int256(type(int24).max)) {
            revert OverflowInt256ToInt24();
        }

        return int24(x);
    }

    function toUint(int256 x) internal pure returns (uint256) {
        // ----<==========================o===========================>----
        // ----xxxxxxxxxxxxxxxxxxxxxxxxxxxo===============================>
        if (x < 0) {
            revert OverflowInt256ToUint256();
        }

        return uint256(x);
    }

    function zero() internal pure returns (int256) {
        return int256(0);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title See SafeCast.sol.
 */
library SafeCastI32 {
    error OverflowInt32ToUint32();

    function toUint(int32 x) internal pure returns (uint32) {
        // ----------------------<========o========>----------------------
        // ----------------------xxxxxxxxxo=========>----------------------
        if (x < 0) {
            revert OverflowInt32ToUint32();
        }

        return uint32(x);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title See SafeCast.sol.
 */
library SafeCastI56 {
    error OverflowInt56ToInt24();

    function to24(int56 x) internal pure returns (int24) {
        // ----------------------<========o========>-----------------------
        // ----------------------xxx<=====o=====>xxx-----------------------
        if (x < int(type(int24).min) || x > int(type(int24).max)) {
            revert OverflowInt56ToInt24();
        }

        return int24(x);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title See SafeCast.sol.
 */
library SafeCastU128 {
    error OverflowUint128ToInt128();

    function to256(uint128 x) internal pure returns (uint256) {
        return uint256(x);
    }

    function toInt(uint128 x) internal pure returns (int128) {
        // -------------------------------o===============>----------------
        // ----------------<==============o==============>x----------------
        if (x > uint128(type(int128).max)) {
            revert OverflowUint128ToInt128();
        }

        return int128(x);
    }

    function toBytes32(uint128 x) internal pure returns (bytes32) {
        return bytes32(uint256(x));
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title See SafeCast.sol.
 */
library SafeCastU160 {
    function to256(uint160 x) internal pure returns (uint256) {
        return uint256(x);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title See SafeCast.sol.
 */
library SafeCastU256 {
    error OverflowUint256ToUint128();
    error OverflowUint256ToInt256();
    error OverflowUint256ToUint64();
    error OverflowUint256ToUint32();
    error OverflowUint256ToUint160();

    function to128(uint256 x) internal pure returns (uint128) {
        // -------------------------------o===============================>
        // -------------------------------o===============>xxxxxxxxxxxxxxxx
        if (x > type(uint128).max) {
            revert OverflowUint256ToUint128();
        }

        return uint128(x);
    }

    function to64(uint256 x) internal pure returns (uint64) {
        // -------------------------------o===============================>
        // -------------------------------o======>xxxxxxxxxxxxxxxxxxxxxxxxx
        if (x > type(uint64).max) {
            revert OverflowUint256ToUint64();
        }

        return uint64(x);
    }

    function to32(uint256 x) internal pure returns (uint32) {
        // -------------------------------o===============================>
        // -------------------------------o===>xxxxxxxxxxxxxxxxxxxxxxxxxxxx
        if (x > type(uint32).max) {
            revert OverflowUint256ToUint32();
        }

        return uint32(x);
    }

    function to160(uint256 x) internal pure returns (uint160) {
        // -------------------------------o===============================>
        // -------------------------------o==================>xxxxxxxxxxxxx
        if (x > type(uint160).max) {
            revert OverflowUint256ToUint160();
        }

        return uint160(x);
    }

    function toBytes32(uint256 x) internal pure returns (bytes32) {
        return bytes32(x);
    }

    function toInt(uint256 x) internal pure returns (int256) {
        // -------------------------------o===============================>
        // ----<==========================o===========================>xxxx
        if (x > uint256(type(int256).max)) {
            revert OverflowUint256ToInt256();
        }

        return int256(x);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title See SafeCast.sol.
 */
library SafeCastU32 {
    error OverflowUint32ToInt32();

    function toInt(uint32 x) internal pure returns (int32) {
        // -------------------------------o=========>----------------------
        // ----------------------<========o========>x----------------------
        if (x > uint32(type(int32).max)) {
            revert OverflowUint32ToInt32();
        }

        return int32(x);
    }

    function to256(uint32 x) internal pure returns (uint256) {
        return uint256(x);
    }

    function to56(uint32 x) internal pure returns (uint56) {
        return uint56(x);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title See SafeCast.sol.
 */
library SafeCastU56 {
    error OverflowUint56ToInt56();

    function toInt(uint56 x) internal pure returns (int56) {
        // -------------------------------o=========>----------------------
        // ----------------------<========o========>x----------------------
        if (x > uint56(type(int56).max)) {
            revert OverflowUint56ToInt56();
        }

        return int56(x);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title See SafeCast.sol.
 */
library SafeCastU64 {
    error OverflowUint64ToInt64();

    function toInt(uint64 x) internal pure returns (int64) {
        // -------------------------------o=========>----------------------
        // ----------------------<========o========>x----------------------
        if (x > uint64(type(int64).max)) {
            revert OverflowUint64ToInt64();
        }

        return int64(x);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import "./SafeCast.sol";

library SetUtil {
    using SafeCastAddress for address;
    using SafeCastBytes32 for bytes32;
    using SafeCastU256 for uint256;

    // ----------------------------------------
    // Uint support
    // ----------------------------------------

    struct UintSet {
        Bytes32Set raw;
    }

    function add(UintSet storage set, uint value) internal {
        add(set.raw, value.toBytes32());
    }

    function remove(UintSet storage set, uint value) internal {
        remove(set.raw, value.toBytes32());
    }

    function replace(UintSet storage set, uint value, uint newValue) internal {
        replace(set.raw, value.toBytes32(), newValue.toBytes32());
    }

    function contains(UintSet storage set, uint value) internal view returns (bool) {
        return contains(set.raw, value.toBytes32());
    }

    function length(UintSet storage set) internal view returns (uint) {
        return length(set.raw);
    }

    function valueAt(UintSet storage set, uint position) internal view returns (uint) {
        return valueAt(set.raw, position).toUint();
    }

    function positionOf(UintSet storage set, uint value) internal view returns (uint) {
        return positionOf(set.raw, value.toBytes32());
    }

    function values(UintSet storage set) internal view returns (uint[] memory) {
        bytes32[] memory store = values(set.raw);
        uint[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // ----------------------------------------
    // Address support
    // ----------------------------------------

    struct AddressSet {
        Bytes32Set raw;
    }

    function add(AddressSet storage set, address value) internal {
        add(set.raw, value.toBytes32());
    }

    function remove(AddressSet storage set, address value) internal {
        remove(set.raw, value.toBytes32());
    }

    function replace(AddressSet storage set, address value, address newValue) internal {
        replace(set.raw, value.toBytes32(), newValue.toBytes32());
    }

    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return contains(set.raw, value.toBytes32());
    }

    function length(AddressSet storage set) internal view returns (uint) {
        return length(set.raw);
    }

    function valueAt(AddressSet storage set, uint position) internal view returns (address) {
        return valueAt(set.raw, position).toAddress();
    }

    function positionOf(AddressSet storage set, address value) internal view returns (uint) {
        return positionOf(set.raw, value.toBytes32());
    }

    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = values(set.raw);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // ----------------------------------------
    // Core bytes32 support
    // ----------------------------------------

    error PositionOutOfBounds();
    error ValueNotInSet();
    error ValueAlreadyInSet();

    struct Bytes32Set {
        bytes32[] _values;
        mapping(bytes32 => uint) _positions; // Position zero is never used.
    }

    function add(Bytes32Set storage set, bytes32 value) internal {
        if (contains(set, value)) {
            revert ValueAlreadyInSet();
        }

        set._values.push(value);
        set._positions[value] = set._values.length;
    }

    function remove(Bytes32Set storage set, bytes32 value) internal {
        uint position = set._positions[value];
        if (position == 0) {
            revert ValueNotInSet();
        }

        uint index = position - 1;
        uint lastIndex = set._values.length - 1;

        // If the element being deleted is not the last in the values,
        // move the last element to its position.
        if (index != lastIndex) {
            bytes32 lastValue = set._values[lastIndex];

            set._values[index] = lastValue;
            set._positions[lastValue] = position;
        }

        // Remove the last element in the values.
        set._values.pop();
        delete set._positions[value];
    }

    function replace(Bytes32Set storage set, bytes32 value, bytes32 newValue) internal {
        if (!contains(set, value)) {
            revert ValueNotInSet();
        }

        if (contains(set, newValue)) {
            revert ValueAlreadyInSet();
        }

        uint position = set._positions[value];
        delete set._positions[value];

        uint index = position - 1;

        set._values[index] = newValue;
        set._positions[newValue] = position;
    }

    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return set._positions[value] != 0;
    }

    function length(Bytes32Set storage set) internal view returns (uint) {
        return set._values.length;
    }

    function valueAt(Bytes32Set storage set, uint position) internal view returns (bytes32) {
        if (position == 0 || position > set._values.length) {
            revert PositionOutOfBounds();
        }

        uint index = position - 1;

        return set._values[index];
    }

    function positionOf(Bytes32Set storage set, bytes32 value) internal view returns (uint) {
        if (!contains(set, value)) {
            revert ValueNotInSet();
        }

        return set._positions[value];
    }

    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return set._values;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import "@synthetixio/core-contracts/contracts/interfaces/IERC721Enumerable.sol";

/**
 * @title Module wrapping an ERC721 token implementation.
 */
interface INftModule is IERC721Enumerable {
    /**
     * @notice Returns whether the token has been initialized.
     * @return A boolean with the result of the query.
     */
    function isInitialized() external returns (bool);

    /**
     * @notice Initializes the token with name, symbol, and uri.
     */
    function initialize(
        string memory tokenName,
        string memory tokenSymbol,
        string memory uri
    ) external;

    /**
     * @notice Allows the owner to mint tokens.
     * @param to The address to receive the newly minted tokens.
     * @param tokenId The ID of the newly minted token
     */
    function mint(address to, uint tokenId) external;

    /**
     * @notice Allows the owner to mint tokens. Verifies that the receiver can receive the token
     * @param to The address to receive the newly minted token.
     * @param tokenId The ID of the newly minted token
     * @param data any data which should be sent to the receiver
     */
    function safeMint(address to, uint256 tokenId, bytes memory data) external;

    /**
     * @notice Allows the owner to burn tokens.
     * @param tokenId The token to burn
     */
    function burn(uint tokenId) external;

    /**
     * @notice Allows an address that holds tokens to provide allowance to another.
     * @param tokenId The token which should be allowed to spender
     * @param spender The address that is given allowance.
     */
    function setAllowance(uint tokenId, address spender) external;

    /**
     * @notice Allows the owner to update the base token URI.
     * @param uri The new base token uri
     */
    function setBaseTokenURI(string memory uri) external;
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import "@synthetixio/core-contracts/contracts/interfaces/IERC20.sol";

/**
 * @title Module wrapping an ERC20 token implementation.
 */
interface ITokenModule is IERC20 {
    /**
     * @notice Returns wether the token has been initialized.
     * @return A boolean with the result of the query.
     */
    function isInitialized() external returns (bool);

    /**
     * @notice Initializes the token with name, symbol, and decimals.
     */
    function initialize(
        string memory tokenName,
        string memory tokenSymbol,
        uint8 tokenDecimals
    ) external;

    /**
     * @notice Allows the owner to mint tokens.
     * @param to The address to receive the newly minted tokens.
     * @param amount The amount of tokens to mint.
     */
    function mint(address to, uint amount) external;

    /**
     * @notice Allows the owner to burn tokens.
     * @param from The address whose tokens will be burnt.
     * @param amount The amount of tokens to burn.
     */
    function burn(address from, uint amount) external;

    /**
     * @notice Allows an address that holds tokens to provide allowance to another.
     * @param from The address that is providing allowance.
     * @param spender The address that is given allowance.
     * @param amount The amount of allowance being given.
     */
    function setAllowance(address from, address spender, uint amount) external;
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import "../interfaces/ITokenModule.sol";
import "../interfaces/INftModule.sol";

library AssociatedSystem {
    struct Data {
        address proxy;
        address impl;
        bytes32 kind;
    }

    error MismatchAssociatedSystemKind(bytes32 expected, bytes32 actual);

    bytes32 public constant KIND_ERC20 = "erc20";
    bytes32 public constant KIND_ERC721 = "erc721";
    bytes32 public constant KIND_UNMANAGED = "unmanaged";

    function load(bytes32 id) internal pure returns (Data storage store) {
        bytes32 s = keccak256(abi.encode("io.synthetix.core-modules.AssociatedSystem", id));
        assembly {
            store.slot := s
        }
    }

    function getAddress(Data storage self) internal view returns (address) {
        return self.proxy;
    }

    function asToken(Data storage self) internal view returns (ITokenModule) {
        expectKind(self, KIND_ERC20);
        return ITokenModule(self.proxy);
    }

    function asNft(Data storage self) internal view returns (INftModule) {
        expectKind(self, KIND_ERC721);
        return INftModule(self.proxy);
    }

    function set(Data storage self, address proxy, address impl, bytes32 kind) internal {
        self.proxy = proxy;
        self.impl = impl;
        self.kind = kind;
    }

    function expectKind(Data storage self, bytes32 kind) internal view {
        bytes32 actualKind = self.kind;

        if (actualKind != kind && actualKind != KIND_UNMANAGED) {
            revert MismatchAssociatedSystemKind(kind, actualKind);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**
 * @title Input related errors.
 */
library InputErrors {
    /**
     * @notice Error when an input has unexpected zero uint256.
     *
     * Cases:
     * - `FundsModule.depositunds()`
     * - `FundsModule.withdrawFunds()`
     *
     */
    error ZeroAmount();

    /**
     * @notice Error when an input has unexpected zero address.
     *
     * Cases:
     * - `ProfilesModule.allowProfile()`
     * - `ProfilesModule.disallowProfile()`
     * - `VaultsModule.addVault()`
     *
     */
    error ZeroAddress();

    /**
     * @notice Error when an input has unexpected zero bytes32 ID.
     *
     * Cases:
     * - `FeesModule.initializeFeesModule()`
     * - `FeesModule.setGratefulFeeTreasury()`
     * - `VaultsModule.addVault()`
     *
     */
    error ZeroId();

    /**
     * @notice Error when an input has unexpected zero uint for time.
     *
     * Cases:
     * - `ConfigModule.initializeConfigModule()`
     * - `ConfigModule.setSolvencyTimeRequired()`
     * - `ConfigModule.setLiquidationTimeRequired()`
     *
     */
    error ZeroTime();

    /**
     * @notice Error when trying to initialize a module that has already been.
     *
     * Cases:
     * - `ConfigModule.initializeConfigModule()`
     * - `FeesModule.initializeFeesModule()`
     * - `VaultModule.addVault()`
     *
     */
    error AlreadyInitialized();
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**
 * @title Profile related errors.
 */
library ProfileErrors {
    /**
     * @notice Thrown when a profile attempts to renounce a permission that it didn't have.
     *
     * Cases:
     * - `ProfilesModules.renouncePermission()`
     *
     */
    error PermissionNotGranted();

    /**
     * @dev Thrown when the given target address does not have the given permission with the given profile.
     *
     * Thrown in:
     * - `Profile.loadProfileAndValidatePermission()`
     *
     * Cases:
     * - `FundsModule.withdrawFunds()`
     * - `SubscriptionsModule.subscribe()`
     * - `SubscriptionsModule.unsubscribe()`
     *
     */
    error PermissionDenied();

    /**
     * @dev Thrown when a profile cannot be found.
     *
     * Thrown in:
     * - `Profile.exists()`
     *
     * Cases:
     * - `FundsModule.depositFunds()`
     * - `SubscriptionsModule.subscribe()`
     * - `SubscriptionsModule.unsubscribe()`
     *
     */
    error ProfileNotFound();

    /**
     * @dev Thrown when a permission specified by a user does not exist or is invalid.
     *
     * Cases:
     *  - `ProfilesModules.grantPermission()`
     *
     */
    error InvalidPermission();

    /**
     * @notice Thrown when the profile interacting with the system is expected to be the associated profile token, but is not.
     *
     * Cases:
     * - `ProfilesModules.notifyProfileTransfer()`
     *
     */
    error OnlyGratefulProfileProxy();

    /**
     * @notice Thrown when trying to create a profile with a salt that was already used.
     *
     * Cases:
     * - `ProfilesModules.createProfile()`
     *
     */
    error ProfileAlreadyCreated();
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**
 * @title Module for managing profiles.
 */
interface IProfilesModule {
    /**
     * @dev Data structure for tracking each user's permissions.
     */
    struct ProfilePermissions {
        /**
         * @dev The address for which all the permissions are granted.
         */
        address user;
        /**
         * @dev The array of permissions given to the associated address.
         */
        bytes32[] permissions;
    }

    /**************************************************************************
     * User functions
     *************************************************************************/

    /**
     * @notice Create a new profile
     *
     * Uses a salt to mint the same profile ID in different chains.
     *
     * The profile ID resulting from the salt must not be already created.
     *
     * Mint a Grateful Profile NFT / Emits `ProfileCreated` event.
     *
     * @param to The address to mint the profile NFT
     * @param salt The salt for creating a specific profile ID
     */
    function createProfile(address to, bytes32 salt) external;

    /**
     * @notice Grants `permission` to `user` for profile `profileId`.
     *
     * Requirements:
     *
     * - `msg.sender` must own the profile token with ID `profileId` or have the "admin" permission.
     * - Emits a `PermissionGranted` event.
     *
     * @param profileId The id of the profile that granted the permission.
     * @param permission The bytes32 identifier of the permission.
     * @param user The target address that received the permission.
     */
    function grantPermission(
        bytes32 profileId,
        bytes32 permission,
        address user
    ) external;

    /**
     * @notice Revokes `permission` from `user` for profile `profileId`.
     *
     * Requirements:
     *
     * - `msg.sender` must own the profile token with ID `profileId` or have the "admin" permission.
     * - Emits a `PermissionRevoked` event.
     *
     * @param profileId The id of the profile that revoked the permission.
     * @param permission The bytes32 identifier of the permission.
     * @param user The target address that no longer has the permission.
     */
    function revokePermission(
        bytes32 profileId,
        bytes32 permission,
        address user
    ) external;

    /**
     * @notice Revokes `permission` from `msg.sender` for profile `profileId`.
     *
     * Emits a `PermissionRevoked` event.
     *
     * @param profileId The id of the profile whose permission was renounced.
     * @param permission The bytes32 identifier of the permission.
     */
    function renouncePermission(bytes32 profileId, bytes32 permission) external;

    /**************************************************************************
     * Profile functions
     *************************************************************************/

    /**
     * @notice Called by GratefulProfile to notify the system when the profile token is transferred.
     *
     * Requirements:
     *
     * - `msg.sender` must be the profile token.
     *
     * @dev Resets user permissions and assigns ownership of the profile token to the new holder.
     * @param to The new holder of the profile NFT.
     * @param tokenId The token ID of the profile that was just transferred.
     */
    function notifyProfileTransfer(address to, uint256 tokenId) external;

    /**************************************************************************
     * View functions
     *************************************************************************/

    /**
     * @notice Returns the address for the Grateful profile used by the module.
     * @return profileNftToken The address of the profile token.
     */
    function getGratefulProfileAddress() external view returns (address);

    /**
     * @notice Returns an array of `ProfilePermission` for the provided `profileId`.
     * @param profileId The id of the profile whose permissions are being retrieved.
     * @return profilePerms An array of ProfilePermission objects describing the permissions granted to the profile.
     */
    function getProfilePermissions(
        bytes32 profileId
    ) external view returns (ProfilePermissions[] memory profilePerms);

    /**
     * @notice Returns `true` if `user` has been granted `permission` for profile `profileId`.
     * @param profileId The id of the profile whose permission is being queried.
     * @param permission The bytes32 identifier of the permission.
     * @param user The target address whose permission is being queried.
     * @return hasPermission A boolean with the response of the query.
     */
    function hasPermission(
        bytes32 profileId,
        bytes32 permission,
        address user
    ) external view returns (bool);

    /**
     * @notice Returns `true` if `target` is authorized to `permission` for profile `profileId`.
     * @param profileId The id of the profile whose permission is being queried.
     * @param permission The bytes32 identifier of the permission.
     * @param user The target address whose permission is being queried.
     * @return isAuthorized A boolean with the response of the query.
     */
    function isAuthorized(
        bytes32 profileId,
        bytes32 permission,
        address user
    ) external view returns (bool);

    /**
     * @notice Returns the address that owns a given profile, as recorded by the system.
     * @param profileId The profile id whose owner is being retrieved.
     * @return owner The owner of the given profile id.
     */
    function getProfileOwner(bytes32 profileId) external view returns (address);

    /**
     * @notice Return a profile ID
     * @param profile The profile NFT address
     * @param tokenId The token ID from the profile NFT
     * @return The profile ID
     */
    function getProfileId(
        address profile,
        uint256 tokenId
    ) external view returns (bytes32);

    /**
     * @notice Return if profile ID exists
     * @param profileId The id of the profile for checking the exitence.
     * @return A boolean with the response of the query.
     */
    function exists(bytes32 profileId) external view returns (bool);

    /**************************************************************************
     * Events
     *************************************************************************/

    /**
     * @notice Emits the new profile created
     * @param owner The new profile owner address
     * @param profileAddress The Grateful Profile NFT address
     * @param tokenId The Grateful Profile NFT token ID minted
     * @param profileId The profile ID
     * @param salt The salt used for creating this profile ID
     */
    event ProfileCreated(
        address indexed owner,
        address indexed profileAddress,
        uint256 tokenId,
        bytes32 profileId,
        bytes32 salt
    );

    /**
     * @notice Emitted when `user` is granted `permission` by `sender` for profile `profileId`.
     * @param profileId The id of the profile that granted the permission.
     * @param permission The bytes32 identifier of the permission.
     * @param user The target address to whom the permission was granted.
     * @param sender The Address that granted the permission.
     */
    event PermissionGranted(
        bytes32 indexed profileId,
        bytes32 indexed permission,
        address indexed user,
        address sender
    );

    /**
     * @notice Emitted when `user` has `permission` renounced or revoked by `sender` for profile `profileId`.
     * @param profileId The id of the profile that has had the permission revoked.
     * @param permission The bytes32 identifier of the permission.
     * @param user The target address for which the permission was revoked.
     * @param sender The address that revoked the permission.
     */
    event PermissionRevoked(
        bytes32 indexed profileId,
        bytes32 indexed permission,
        address indexed user,
        address sender
    );

    /**
     * @notice Emitted when a profile `profileId` is transfered and all `user` permissions are revoked.
     * @param profileId The id of the profile that has had all the permissions revoked.
     * @param user The target address for which all the permissions were revoked.
     */
    event AllPermissionsRevoked(
        bytes32 indexed profileId,
        address indexed user
    );
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IProfilesModule} from "../interfaces/IProfilesModule.sol";
import {Profile} from "../storage/Profile.sol";
import {ProfileRBAC} from "../storage/ProfileRBAC.sol";
import {ProfileNft} from "../storage/ProfileNft.sol";
import {INftModule} from "@synthetixio/core-modules/contracts/interfaces/INftModule.sol";
import {OwnableStorage} from "@synthetixio/core-contracts/contracts/ownership/OwnableStorage.sol";
import {AssociatedSystem} from "@synthetixio/core-modules/contracts/storage/AssociatedSystem.sol";
import {SetUtil} from "@synthetixio/core-contracts/contracts/utils/SetUtil.sol";
import {InputErrors} from "../errors/InputErrors.sol";
import {ProfileErrors} from "../errors/ProfileErrors.sol";

/**
 * @title Module for managing profiles.
 * @dev See IProfilesModule.
 */
contract ProfilesModule is IProfilesModule {
    using SetUtil for SetUtil.AddressSet;
    using SetUtil for SetUtil.Bytes32Set;
    using Profile for Profile.Data;
    using ProfileRBAC for ProfileRBAC.Data;
    using ProfileNft for ProfileNft.Data;
    using AssociatedSystem for AssociatedSystem.Data;

    bytes32 private constant _GRATEFUL_PROFILE_NFT = "gratefulProfileNft";

    /// @inheritdoc	IProfilesModule
    function createProfile(address to, bytes32 salt) external override {
        address profileAddress = getGratefulProfileAddress();
        INftModule profile = INftModule(profileAddress);

        uint256 tokenId = profile.totalSupply() + 1;
        bytes32 profileId = Profile.getProfileId(to, salt);

        Profile.notExists(profileId);

        ProfileNft.load(profileAddress, tokenId).set(profileId);
        Profile.create(profileId, to);

        profile.safeMint(to, tokenId, "");

        emit ProfileCreated(to, profileAddress, tokenId, profileId, salt);
    }

    /// @inheritdoc	IProfilesModule
    function notifyProfileTransfer(
        address to,
        uint256 tokenId
    ) external override {
        _onlyGratefulProfile();

        address profileAddress = getGratefulProfileAddress();
        bytes32 profileId = ProfileNft.load(profileAddress, tokenId).profileId;

        Profile.Data storage profile = Profile.load(profileId);

        address[] memory permissionedAddresses = profile
            .rbac
            .permissionAddresses
            .values();

        for (uint i = 0; i < permissionedAddresses.length; i++) {
            address user = permissionedAddresses[i];
            profile.rbac.revokeAllPermissions(user);
            emit AllPermissionsRevoked(profileId, user);
        }

        profile.rbac.setOwner(to);
    }

    /// @inheritdoc	IProfilesModule
    function grantPermission(
        bytes32 profileId,
        bytes32 permission,
        address user
    ) external override {
        ProfileRBAC.isPermissionValid(permission);

        Profile.Data storage profile = Profile.loadProfileAndValidatePermission(
            profileId,
            ProfileRBAC._ADMIN_PERMISSION
        );

        profile.rbac.grantPermission(permission, user);

        emit PermissionGranted(profileId, permission, user, msg.sender);
    }

    /// @inheritdoc	IProfilesModule
    function revokePermission(
        bytes32 profileId,
        bytes32 permission,
        address user
    ) external override {
        Profile.Data storage profile = Profile.loadProfileAndValidatePermission(
            profileId,
            ProfileRBAC._ADMIN_PERMISSION
        );

        profile.rbac.revokePermission(permission, user);

        emit PermissionRevoked(profileId, permission, user, msg.sender);
    }

    /// @inheritdoc	IProfilesModule
    function renouncePermission(
        bytes32 profileId,
        bytes32 permission
    ) external override {
        if (!Profile.load(profileId).rbac.hasPermission(permission, msg.sender))
            revert ProfileErrors.PermissionNotGranted();

        Profile.load(profileId).rbac.revokePermission(permission, msg.sender);

        emit PermissionRevoked(profileId, permission, msg.sender, msg.sender);
    }

    /// @inheritdoc	IProfilesModule
    function getGratefulProfileAddress()
        public
        view
        override
        returns (address)
    {
        return AssociatedSystem.load(_GRATEFUL_PROFILE_NFT).proxy;
    }

    /// @inheritdoc	IProfilesModule
    function getProfilePermissions(
        bytes32 profileId
    )
        external
        view
        override
        returns (ProfilePermissions[] memory profilePerms)
    {
        ProfileRBAC.Data storage profileRbac = Profile.load(profileId).rbac;

        uint256 allPermissionsLength = profileRbac.permissionAddresses.length();
        profilePerms = new ProfilePermissions[](allPermissionsLength);
        for (uint256 i = 1; i <= allPermissionsLength; i++) {
            address permissionAddress = profileRbac.permissionAddresses.valueAt(
                i
            );
            profilePerms[i - 1] = ProfilePermissions({
                user: permissionAddress,
                permissions: profileRbac.permissions[permissionAddress].values()
            });
        }
    }

    /// @inheritdoc	IProfilesModule
    function hasPermission(
        bytes32 profileId,
        bytes32 permission,
        address user
    ) external view override returns (bool) {
        return Profile.load(profileId).rbac.hasPermission(permission, user);
    }

    /// @inheritdoc	IProfilesModule
    function isAuthorized(
        bytes32 profileId,
        bytes32 permission,
        address user
    ) external view override returns (bool) {
        return Profile.load(profileId).rbac.authorized(permission, user);
    }

    /// @inheritdoc	IProfilesModule
    function getProfileOwner(
        bytes32 profileId
    ) external view override returns (address) {
        return Profile.load(profileId).rbac.owner;
    }

    /// @inheritdoc	IProfilesModule
    function getProfileId(
        address profile,
        uint256 tokenId
    ) external view override returns (bytes32) {
        return ProfileNft.load(profile, tokenId).profileId;
    }

    /// @inheritdoc	IProfilesModule
    function exists(bytes32 profileId) external view returns (bool) {
        return Profile.load(profileId).rbac.owner != address(0);
    }

    function _onlyGratefulProfile() private view {
        if (msg.sender != address(getGratefulProfileAddress())) {
            revert ProfileErrors.OnlyGratefulProfileProxy();
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {ProfileRBAC} from "./ProfileRBAC.sol";
import {ProfileErrors} from "../errors/ProfileErrors.sol";

/**
 * @title Object for tracking profiles with access control.
 */
library Profile {
    using ProfileRBAC for ProfileRBAC.Data;

    struct Data {
        /**
         * @dev Role based access control data for the profile.
         */
        ProfileRBAC.Data rbac;
    }

    /**
     * @dev Returns the profile stored at the specified profile ID.
     */
    function load(
        bytes32 profileId
    ) internal pure returns (Data storage store) {
        bytes32 s = keccak256(abi.encode("Profile", profileId));
        assembly {
            store.slot := s
        }
    }

    /**
     * @dev Creates a profile for the given profileId, and associates it to the given owner.
     *
     * Note: Will not fail if the profile already exists, and if so, will overwrite the existing owner.
     * Whatever calls this internal function must first check that the profile doesn't exist before re-creating it.
     */
    function create(
        bytes32 profileId,
        address owner
    ) internal returns (Data storage profile) {
        profile = load(profileId);

        profile.rbac.owner = owner;
    }

    /**
     * @dev Reverts if the profile does not exist with appropriate error.
     */
    function exists(bytes32 profileId) internal view {
        if (load(profileId).rbac.owner == address(0)) {
            revert ProfileErrors.ProfileNotFound();
        }
    }

    /**
     * @dev Reverts if the profile exists with appropriate error.
     */
    function notExists(bytes32 profileId) internal view {
        if (load(profileId).rbac.owner != address(0)) {
            revert ProfileErrors.ProfileAlreadyCreated();
        }
    }

    /**
     * @dev Loads the Profile object for the specified profileId,
     * and validates that sender has the specified permission. These
     * are different actions but they are merged in a single function
     * because loading a profile and checking for a permission is a very
     * common use case in other parts of the code.
     */
    function loadProfileAndValidatePermission(
        bytes32 profileId,
        bytes32 permission
    ) internal view returns (Data storage profile) {
        profile = load(profileId);

        if (!profile.rbac.authorized(permission, msg.sender)) {
            revert ProfileErrors.PermissionDenied();
        }
    }

    /**
     * @dev Returns a profile ID.
     *
     * It is the hash from the profile NFT owner address and a salt.
     *
     * It must be unique for the system.
     */
    function getProfileId(
        address owner,
        bytes32 salt
    ) internal pure returns (bytes32 profileId) {
        profileId = keccak256(abi.encode(owner, salt));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**
 * @title Stores the data of the Grateful subscription NFT.
 */
library ProfileNft {
    struct Data {
        /**
         * @dev Hash identifier for the profile. Must be unique.
         */
        bytes32 profileId;
    }

    function load(
        address profile,
        uint256 tokenId
    ) internal pure returns (Data storage store) {
        bytes32 s = keccak256(abi.encode("ProfileNft", profile, tokenId));
        assembly {
            store.slot := s
        }
    }

    function set(Data storage self, bytes32 profileId) internal {
        self.profileId = profileId;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {SetUtil} from "@synthetixio/core-contracts/contracts/utils/SetUtil.sol";
import {ProfileErrors} from "../errors/ProfileErrors.sol";
import {InputErrors} from "../errors/InputErrors.sol";

/**
 * @title Object for tracking an profiles permissions (role based access control).
 */
library ProfileRBAC {
    using SetUtil for SetUtil.Bytes32Set;
    using SetUtil for SetUtil.AddressSet;

    /**
     * @dev All permissions used by the system
     * need to be hardcoded here.
     */
    bytes32 internal constant _ADMIN_PERMISSION = "ADMIN";
    bytes32 internal constant _WITHDRAW_PERMISSION = "WITHDRAW";
    bytes32 internal constant _SUBSCRIBE_PERMISSION = "SUBSCRIBE";
    bytes32 internal constant _UNSUBSCRIBE_PERMISSION = "UNSUBSCRIBE";
    bytes32 internal constant _EDIT_PERMISSION = "EDIT";

    struct Data {
        /**
         * @dev The owner of the profile and admin of all permissions.
         */
        address owner;
        /**
         * @dev Set of permissions for each address enabled by the profile.
         */
        mapping(address => SetUtil.Bytes32Set) permissions;
        /**
         * @dev Array of addresses that this profile has given permissions to.
         */
        SetUtil.AddressSet permissionAddresses;
    }

    /**
     * @dev Reverts if the specified permission is unknown to the profile RBAC system.
     */
    function isPermissionValid(bytes32 permission) internal pure {
        if (
            permission != _ADMIN_PERMISSION &&
            permission != _WITHDRAW_PERMISSION &&
            permission != _SUBSCRIBE_PERMISSION &&
            permission != _UNSUBSCRIBE_PERMISSION &&
            permission != _EDIT_PERMISSION
        ) {
            revert ProfileErrors.InvalidPermission();
        }
    }

    /**
     * @dev Sets the owner of the profile.
     */
    function setOwner(Data storage self, address owner) internal {
        self.owner = owner;
    }

    /**
     * @dev Grants a particular permission to the specified target address.
     */
    function grantPermission(
        Data storage self,
        bytes32 permission,
        address target
    ) internal {
        if (target == address(0)) {
            revert InputErrors.ZeroAddress();
        }

        if (!self.permissionAddresses.contains(target)) {
            self.permissionAddresses.add(target);
        }

        self.permissions[target].add(permission);
    }

    /**
     * @dev Revokes a particular permission from the specified target address.
     */
    function revokePermission(
        Data storage self,
        bytes32 permission,
        address target
    ) internal {
        self.permissions[target].remove(permission);

        if (self.permissions[target].length() == 0) {
            self.permissionAddresses.remove(target);
        }
    }

    /**
     * @dev Revokes all permissions for the specified target address.
     * @notice only removes permissions for the given address, not for the entire profile
     */
    function revokeAllPermissions(Data storage self, address target) internal {
        bytes32[] memory permissions = self.permissions[target].values();

        for (uint256 i = 0; i < permissions.length; i++) {
            self.permissions[target].remove(permissions[i]);
        }

        self.permissionAddresses.remove(target);
    }

    /**
     * @dev Returns wether the specified address has the given permission.
     */
    function hasPermission(
        Data storage self,
        bytes32 permission,
        address target
    ) internal view returns (bool) {
        return
            target != address(0) &&
            self.permissions[target].contains(permission);
    }

    /**
     * @dev Returns wether the specified target address has the given permission, or has the high level admin permission.
     */
    function authorized(
        Data storage self,
        bytes32 permission,
        address target
    ) internal view returns (bool) {
        return ((target == self.owner) ||
            hasPermission(self, _ADMIN_PERMISSION, target) ||
            hasPermission(self, permission, target));
    }
}