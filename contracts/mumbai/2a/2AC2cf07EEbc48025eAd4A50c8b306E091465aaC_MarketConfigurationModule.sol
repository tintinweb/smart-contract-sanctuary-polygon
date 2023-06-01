//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title ERC165 interface for determining if a contract supports a given interface.
 */
interface IERC165 {
    /**
     * @notice Determines if the contract in question supports the specified interface.
     * @param interfaceID XOR of all selectors in the contract.
     * @return True if the contract supports the specified interface.
     */
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
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

import "./SafeCast.sol";

/**
 * @title Utility library used to represent "decimals" (fixed point numbers) with integers, with two different levels of precision.
 *
 * They are represented by N * UNIT, where UNIT is the number of decimals of precision in the representation.
 *
 * Examples:
 * 1) Given UNIT = 100
 * then if A = 50, A represents the decimal 0.50
 * 2) Given UNIT = 1000000000000000000
 * then if A = 500000000000000000, A represents the decimal 0.500000000000000000
 *
 * Note: An accompanying naming convention of the postfix "D<Precision>" is helpful with this utility. I.e. if a variable "myValue" represents a low resolution decimal, it should be named "myValueD18", and if it was a high resolution decimal "myValueD27". While scaling, intermediate precision decimals like "myValue45" could arise. Non-decimals should have no postfix, i.e. just "myValue".
 *
 * Important: Multiplication and division operations are currently not supported for high precision decimals. Using these operations on them will yield incorrect results and fail silently.
 */
library DecimalMath {
    using SafeCastU256 for uint256;
    using SafeCastI256 for int256;

    // solhint-disable numcast/safe-cast

    // Numbers representing 1.0 (low precision).
    uint256 public constant UNIT = 1e18;
    int256 public constant UNIT_INT = int256(UNIT);
    uint128 public constant UNIT_UINT128 = uint128(UNIT);
    int128 public constant UNIT_INT128 = int128(UNIT_INT);

    // Numbers representing 1.0 (high precision).
    uint256 public constant UNIT_PRECISE = 1e27;
    int256 public constant UNIT_PRECISE_INT = int256(UNIT_PRECISE);
    int128 public constant UNIT_PRECISE_INT128 = int128(UNIT_PRECISE_INT);

    // Precision scaling, (used to scale down/up from one precision to the other).
    uint256 public constant PRECISION_FACTOR = 9; // 27 - 18 = 9 :)

    // solhint-enable numcast/safe-cast

    // -----------------
    // uint256
    // -----------------

    /**
     * @dev Multiplies two low precision decimals.
     *
     * Since the two numbers are assumed to be fixed point numbers,
     * (x * UNIT) * (y * UNIT) = x * y * UNIT ^ 2,
     * the result is divided by UNIT to remove double scaling.
     */
    function mulDecimal(uint256 x, uint256 y) internal pure returns (uint256 z) {
        return (x * y) / UNIT;
    }

    /**
     * @dev Divides two low precision decimals.
     *
     * Since the two numbers are assumed to be fixed point numbers,
     * (x * UNIT) / (y * UNIT) = x / y (Decimal representation is lost),
     * x is first scaled up to end up with a decimal representation.
     */
    function divDecimal(uint256 x, uint256 y) internal pure returns (uint256 z) {
        return (x * UNIT) / y;
    }

    /**
     * @dev Scales up a value.
     *
     * E.g. if value is not a decimal, a scale up by 18 makes it a low precision decimal.
     * If value is a low precision decimal, a scale up by 9 makes it a high precision decimal.
     */
    function upscale(uint x, uint factor) internal pure returns (uint) {
        return x * 10 ** factor;
    }

    /**
     * @dev Scales down a value.
     *
     * E.g. if value is a high precision decimal, a scale down by 9 makes it a low precision decimal.
     * If value is a low precision decimal, a scale down by 9 makes it a regular integer.
     *
     * Scaling down a regular integer would not make sense.
     */
    function downscale(uint x, uint factor) internal pure returns (uint) {
        return x / 10 ** factor;
    }

    // -----------------
    // uint128
    // -----------------

    // Note: Overloading doesn't seem to work for similar types, i.e. int256 and int128, uint256 and uint128, etc, so explicitly naming the functions differently here.

    /**
     * @dev See mulDecimal for uint256.
     */
    function mulDecimalUint128(uint128 x, uint128 y) internal pure returns (uint128) {
        return (x * y) / UNIT_UINT128;
    }

    /**
     * @dev See divDecimal for uint256.
     */
    function divDecimalUint128(uint128 x, uint128 y) internal pure returns (uint128) {
        return (x * UNIT_UINT128) / y;
    }

    /**
     * @dev See upscale for uint256.
     */
    function upscaleUint128(uint128 x, uint factor) internal pure returns (uint128) {
        return x * (10 ** factor).to128();
    }

    /**
     * @dev See downscale for uint256.
     */
    function downscaleUint128(uint128 x, uint factor) internal pure returns (uint128) {
        return x / (10 ** factor).to128();
    }

    // -----------------
    // int256
    // -----------------

    /**
     * @dev See mulDecimal for uint256.
     */
    function mulDecimal(int256 x, int256 y) internal pure returns (int256) {
        return (x * y) / UNIT_INT;
    }

    /**
     * @dev See divDecimal for uint256.
     */
    function divDecimal(int256 x, int256 y) internal pure returns (int256) {
        return (x * UNIT_INT) / y;
    }

    /**
     * @dev See upscale for uint256.
     */
    function upscale(int x, uint factor) internal pure returns (int) {
        return x * (10 ** factor).toInt();
    }

    /**
     * @dev See downscale for uint256.
     */
    function downscale(int x, uint factor) internal pure returns (int) {
        return x / (10 ** factor).toInt();
    }

    // -----------------
    // int128
    // -----------------

    /**
     * @dev See mulDecimal for uint256.
     */
    function mulDecimalInt128(int128 x, int128 y) internal pure returns (int128) {
        return (x * y) / UNIT_INT128;
    }

    /**
     * @dev See divDecimal for uint256.
     */
    function divDecimalInt128(int128 x, int128 y) internal pure returns (int128) {
        return (x * UNIT_INT128) / y;
    }

    /**
     * @dev See upscale for uint256.
     */
    function upscaleInt128(int128 x, uint factor) internal pure returns (int128) {
        return x * ((10 ** factor).toInt()).to128();
    }

    /**
     * @dev See downscale for uint256.
     */
    function downscaleInt128(int128 x, uint factor) internal pure returns (int128) {
        return x / ((10 ** factor).toInt().to128());
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import "../interfaces/IERC165.sol";

library ERC165Helper {
    function safeSupportsInterface(
        address candidate,
        bytes4 interfaceID
    ) internal returns (bool supportsInterface) {
        (bool success, bytes memory response) = candidate.call(
            abi.encodeWithSelector(IERC165.supportsInterface.selector, interfaceID)
        );

        if (!success) {
            return false;
        }

        if (response.length == 0) {
            return false;
        }

        assembly {
            supportsInterface := mload(add(response, 32))
        }
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

/**
 * @title Module for connecting a system with other associated systems.

 * Associated systems become available to all system modules for communication and interaction, but as opposed to inter-modular communications, interactions with associated systems will require the use of `CALL`.
 *
 * Associated systems can be managed or unmanaged.
 * - Managed systems are connected via a proxy, which means that their implementation can be updated, and the system controls the execution context of the associated system. Example, an snxUSD token connected to the system, and controlled by the system.
 * - Unmanaged systems are just addresses tracked by the system, for which it has no control whatsoever. Example, Uniswap v3, Curve, etc.
 *
 * Furthermore, associated systems are typed in the AssociatedSystem utility library (See AssociatedSystem.sol):
 * - KIND_ERC20: A managed associated system specifically wrapping an ERC20 implementation.
 * - KIND_ERC721: A managed associated system specifically wrapping an ERC721 implementation.
 * - KIND_UNMANAGED: Any unmanaged associated system.
 */
interface IAssociatedSystemsModule {
    /**
     * @notice Emitted when an associated system is set.
     * @param kind The type of associated system (managed ERC20, managed ERC721, unmanaged, etc - See the AssociatedSystem util).
     * @param id The bytes32 identifier of the associated system.
     * @param proxy The main external contract address of the associated system.
     * @param impl The address of the implementation of the associated system (if not behind a proxy, will equal `proxy`).
     */
    event AssociatedSystemSet(
        bytes32 indexed kind,
        bytes32 indexed id,
        address proxy,
        address impl
    );

    /**
     * @notice Emitted when the function you are calling requires an associated system, but it
     * has not been registered
     */
    error MissingAssociatedSystem(bytes32 id);

    /**
     * @notice Creates or initializes a managed associated ERC20 token.
     * @param id The bytes32 identifier of the associated system. If the id is new to the system, it will create a new proxy for the associated system.
     * @param name The token name that will be used to initialize the proxy.
     * @param symbol The token symbol that will be used to initialize the proxy.
     * @param decimals The token decimals that will be used to initialize the proxy.
     * @param impl The ERC20 implementation of the proxy.
     */
    function initOrUpgradeToken(
        bytes32 id,
        string memory name,
        string memory symbol,
        uint8 decimals,
        address impl
    ) external;

    /**
     * @notice Creates or initializes a managed associated ERC721 token.
     * @param id The bytes32 identifier of the associated system. If the id is new to the system, it will create a new proxy for the associated system.
     * @param name The token name that will be used to initialize the proxy.
     * @param symbol The token symbol that will be used to initialize the proxy.
     * @param uri The token uri that will be used to initialize the proxy.
     * @param impl The ERC721 implementation of the proxy.
     */
    function initOrUpgradeNft(
        bytes32 id,
        string memory name,
        string memory symbol,
        string memory uri,
        address impl
    ) external;

    /**
     * @notice Registers an unmanaged external contract in the system.
     * @param id The bytes32 identifier to use to reference the associated system.
     * @param endpoint The address of the associated system.
     *
     * Note: The system will not be able to control or upgrade the associated system, only communicate with it.
     */
    function registerUnmanagedSystem(bytes32 id, address endpoint) external;

    /**
     * @notice Retrieves an associated system.
     * @param id The bytes32 identifier used to reference the associated system.
     * @return addr The external contract address of the associated system.
     * @return kind The type of associated system (managed ERC20, managed ERC721, unmanaged, etc - See the AssociatedSystem util).
     */
    function getAssociatedSystem(bytes32 id) external view returns (address addr, bytes32 kind);
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import "./ITokenModule.sol";

/**
 * @title Module wrapping an ERC20 token implementation.
 * @notice the contract uses A = P(1 + r/n)**nt formula compounded every second to calculate decay amount at any moment
 */
interface IDecayTokenModule is ITokenModule {
    /**
     * @notice Emitted when the decay rate is set to a value higher than the maximum
     */
    error InvalidDecayRate();

    /**
     * @notice Updates the decay rate for a year
     * @param _rate The decay rate with 18 decimals (1e16 means 1% decay per year).
     */
    function setDecayRate(uint256 _rate) external;

    /**
     * @notice get decay rate for a year
     */
    function decayRate() external returns (uint256);

    /**
     * @notice advance epoch manually in order to avoid precision loss
     */
    function advanceEpoch() external returns (uint256);
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

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import "@synthetixio/oracle-manager/contracts/interfaces/INodeModule.sol";

/// @title Effective interface for the oracle manager
interface IOracleManager is INodeModule {

}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title Module for allowing markets to directly increase their credit capacity by providing their own collateral.
 */
interface IMarketCollateralModule {
    /**
     * @notice Thrown when a user attempts to deposit more collateral than that allowed by a market.
     */
    error InsufficientMarketCollateralDepositable(
        uint128 marketId,
        address collateralType,
        uint256 tokenAmountToDeposit
    );

    /**
     * @notice Thrown when a user attempts to withdraw more collateral from the market than what it has provided.
     */
    error InsufficientMarketCollateralWithdrawable(
        uint128 marketId,
        address collateralType,
        uint256 tokenAmountToWithdraw
    );

    /**
     * @notice Emitted when `amount` of collateral of type `collateralType` is deposited to market `marketId` by `sender`.
     * @param marketId The id of the market in which collateral was deposited.
     * @param collateralType The address of the collateral that was directly deposited in the market.
     * @param tokenAmount The amount of tokens that were deposited, denominated in the token's native decimal representation.
     * @param sender The address that triggered the deposit.
     */
    event MarketCollateralDeposited(
        uint128 indexed marketId,
        address indexed collateralType,
        uint256 tokenAmount,
        address indexed sender
    );

    /**
     * @notice Emitted when `amount` of collateral of type `collateralType` is withdrawn from market `marketId` by `sender`.
     * @param marketId The id of the market from which collateral was withdrawn.
     * @param collateralType The address of the collateral that was withdrawn from the market.
     * @param tokenAmount The amount of tokens that were withdrawn, denominated in the token's native decimal representation.
     * @param sender The address that triggered the withdrawal.
     */
    event MarketCollateralWithdrawn(
        uint128 indexed marketId,
        address indexed collateralType,
        uint256 tokenAmount,
        address indexed sender
    );

    /**
     * @notice Emitted when the system owner specifies the maximum depositable collateral of a given type in a given market.
     * @param marketId The id of the market for which the maximum was configured.
     * @param collateralType The address of the collateral for which the maximum was configured.
     * @param systemAmount The amount to which the maximum was set, denominated with 18 decimals of precision.
     * @param owner The owner of the system, which triggered the configuration change.
     */
    event MaximumMarketCollateralConfigured(
        uint128 indexed marketId,
        address indexed collateralType,
        uint256 systemAmount,
        address indexed owner
    );

    /**
     * @notice Allows a market to deposit collateral.
     * @param marketId The id of the market in which the collateral was directly deposited.
     * @param collateralType The address of the collateral that was deposited in the market.
     * @param amount The amount of collateral that was deposited, denominated in the token's native decimal representation.
     */
    function depositMarketCollateral(
        uint128 marketId,
        address collateralType,
        uint256 amount
    ) external;

    /**
     * @notice Allows a market to withdraw collateral that it has previously deposited.
     * @param marketId The id of the market from which the collateral was withdrawn.
     * @param collateralType The address of the collateral that was withdrawn from the market.
     * @param amount The amount of collateral that was withdrawn, denominated in the token's native decimal representation.
     */
    function withdrawMarketCollateral(
        uint128 marketId,
        address collateralType,
        uint256 amount
    ) external;

    /**
     * @notice Allow the system owner to configure the maximum amount of a given collateral type that a specified market is allowed to deposit.
     * @param marketId The id of the market for which the maximum is to be configured.
     * @param collateralType The address of the collateral for which the maximum is to be applied.
     * @param amount The amount that is to be set as the new maximum, denominated with 18 decimals of precision.
     */
    function configureMaximumMarketCollateral(
        uint128 marketId,
        address collateralType,
        uint256 amount
    ) external;

    /**
     * @notice Return the total maximum amount of a given collateral type that a specified market is allowed to deposit.
     * @param marketId The id of the market for which the maximum is being queried.
     * @param collateralType The address of the collateral for which the maximum is being queried.
     * @return amountD18 The maximum amount of collateral set for the market, denominated with 18 decimals of precision.
     */
    function getMaximumMarketCollateral(
        uint128 marketId,
        address collateralType
    ) external returns (uint256 amountD18);

    /**
     * @notice Return the total amount of a given collateral type that a specified market has deposited.
     * @param marketId The id of the market for which the directly deposited collateral amount is being queried.
     * @param collateralType The address of the collateral for which the amount is being queried.
     * @return amountD18 The total amount of collateral of this type delegated to the market, denominated with 18 decimals of precision.
     */
    function getMarketCollateralAmount(
        uint128 marketId,
        address collateralType
    ) external view returns (uint256 amountD18);

    /**
     * @notice Return the total value of collateral that a specified market has deposited.
     * @param marketId The id of the market for which the directly deposited collateral amount is being queried.
     * @return valueD18 The total value of collateral deposited by the market, denominated with 18 decimals of precision.
     */
    function getMarketCollateralValue(uint128 marketId) external returns (uint256 valueD18);
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import "@synthetixio/core-contracts/contracts/interfaces/IERC20.sol";
import "./external/IOracleManager.sol";

/**
 * @title System-wide entry point for the management of markets connected to the system.
 */
interface IMarketManagerModule {
    /**
     * @notice Thrown when a market does not have enough liquidity for a withdrawal.
     */
    error NotEnoughLiquidity(uint128 marketId, uint256 amount);

    /**
     * @notice Thrown when an attempt to register a market that does not conform to the IMarket interface is made.
     */
    error IncorrectMarketInterface(address market);

    /**
     * @notice Emitted when a new market is registered in the system.
     * @param market The address of the external market that was registered in the system.
     * @param marketId The id with which the market was registered in the system.
     * @param sender The account that trigger the registration of the market.
     */
    event MarketRegistered(
        address indexed market,
        uint128 indexed marketId,
        address indexed sender
    );

    /**
     * @notice Emitted when a market deposits snxUSD in the system.
     * @param marketId The id of the market that deposited snxUSD in the system.
     * @param target The address of the account that provided the snxUSD in the deposit.
     * @param amount The amount of snxUSD deposited in the system, denominated with 18 decimals of precision.
     * @param market The address of the external market that is depositing.
     */
    event MarketUsdDeposited(
        uint128 indexed marketId,
        address indexed target,
        uint256 amount,
        address indexed market
    );

    /**
     * @notice Emitted when a market withdraws snxUSD from the system.
     * @param marketId The id of the market that withdrew snxUSD from the system.
     * @param target The address of the account that received the snxUSD in the withdrawal.
     * @param amount The amount of snxUSD withdrawn from the system, denominated with 18 decimals of precision.
     * @param market The address of the external market that is withdrawing.
     */
    event MarketUsdWithdrawn(
        uint128 indexed marketId,
        address indexed target,
        uint256 amount,
        address indexed market
    );

    event MarketSystemFeePaid(uint128 indexed marketId, uint256 feeAmount);

    /**
     * @notice Emitted when a market sets an updated minimum delegation time
     * @param marketId The id of the market that the setting is applied to
     * @param minDelegateTime The minimum amount of time between delegation changes
     */
    event SetMinDelegateTime(uint128 indexed marketId, uint32 minDelegateTime);

    /**
     * @notice Emitted when a market-specific minimum liquidity ratio is set
     * @param marketId The id of the market that the setting is applied to
     * @param minLiquidityRatio The new market-specific minimum liquidity ratio
     */
    event SetMarketMinLiquidityRatio(uint128 indexed marketId, uint256 minLiquidityRatio);

    /**
     * @notice Connects an external market to the system.
     * @dev Creates a Market object to track the external market, and returns the newly created market id.
     * @param market The address of the external market that is to be registered in the system.
     * @return newMarketId The id with which the market will be registered in the system.
     */
    function registerMarket(address market) external returns (uint128 newMarketId);

    /**
     * @notice Allows an external market connected to the system to deposit USD in the system.
     * @dev The system burns the incoming USD, increases the market's credit capacity, and reduces its issuance.
     * @dev See `IMarket`.
     * @param marketId The id of the market in which snxUSD will be deposited.
     * @param target The address of the account on who's behalf the deposit will be made.
     * @param amount The amount of snxUSD to be deposited, denominated with 18 decimals of precision.
     * @return feeAmount the amount of fees paid (billed as additional debt towards liquidity providers)
     */
    function depositMarketUsd(
        uint128 marketId,
        address target,
        uint256 amount
    ) external returns (uint256 feeAmount);

    /**
     * @notice Allows an external market connected to the system to withdraw snxUSD from the system.
     * @dev The system mints the requested snxUSD (provided that the market has sufficient credit), reduces the market's credit capacity, and increases its net issuance.
     * @dev See `IMarket`.
     * @param marketId The id of the market from which snxUSD will be withdrawn.
     * @param target The address of the account that will receive the withdrawn snxUSD.
     * @param amount The amount of snxUSD to be withdraw, denominated with 18 decimals of precision.
     * @return feeAmount the amount of fees paid (billed as additional debt towards liquidity providers)
     */
    function withdrawMarketUsd(
        uint128 marketId,
        address target,
        uint256 amount
    ) external returns (uint256 feeAmount);

    /**
     * @notice Get the amount of fees paid in USD for a call to `depositMarketUsd` and `withdrawMarketUsd` for the given market and amount
     * @param marketId The market to check fees for
     * @param amount The amount deposited or withdrawn in USD
     * @return depositFeeAmount the amount of USD paid for a call to `depositMarketUsd`
     * @return withdrawFeeAmount the amount of USD paid for a call to `withdrawMarketUsd`
     */
    function getMarketFees(
        uint128 marketId,
        uint256 amount
    ) external view returns (uint256 depositFeeAmount, uint256 withdrawFeeAmount);

    /**
     * @notice Returns the total withdrawable snxUSD amount for the specified market.
     * @param marketId The id of the market whose withdrawable USD amount is being queried.
     * @return withdrawableD18 The total amount of snxUSD that the market could withdraw at the time of the query, denominated with 18 decimals of precision.
     */
    function getWithdrawableMarketUsd(
        uint128 marketId
    ) external view returns (uint256 withdrawableD18);

    /**
     * @notice Returns the net issuance of the specified market (snxUSD withdrawn - snxUSD deposited).
     * @param marketId The id of the market whose net issuance is being queried.
     * @return issuanceD18 The net issuance of the market, denominated with 18 decimals of precision.
     */
    function getMarketNetIssuance(uint128 marketId) external view returns (int128 issuanceD18);

    /**
     * @notice Returns the reported debt of the specified market.
     * @param marketId The id of the market whose reported debt is being queried.
     * @return reportedDebtD18 The market's reported debt, denominated with 18 decimals of precision.
     */
    function getMarketReportedDebt(
        uint128 marketId
    ) external view returns (uint256 reportedDebtD18);

    /**
     * @notice Returns the total debt of the specified market.
     * @param marketId The id of the market whose debt is being queried.
     * @return totalDebtD18 The total debt of the market, denominated with 18 decimals of precision.
     */
    function getMarketTotalDebt(uint128 marketId) external view returns (int256 totalDebtD18);

    /**
     * @notice Returns the total snxUSD value of the collateral for the specified market.
     * @param marketId The id of the market whose collateral is being queried.
     * @return valueD18 The market's total snxUSD value of collateral, denominated with 18 decimals of precision.
     */
    function getMarketCollateral(uint128 marketId) external view returns (uint256 valueD18);

    /**
     * @notice Returns the value per share of the debt of the specified market.
     * @dev This is not a view function, and actually updates the entire debt distribution chain.
     * @param marketId The id of the market whose debt per share is being queried.
     * @return debtPerShareD18 The market's debt per share value, denominated with 18 decimals of precision.
     */
    function getMarketDebtPerShare(uint128 marketId) external returns (int256 debtPerShareD18);

    /**
     * @notice Returns whether the capacity of the specified market is locked.
     * @param marketId The id of the market whose capacity is being queried.
     * @return isLocked A boolean that is true if the market's capacity is locked at the time of the query.
     */
    function isMarketCapacityLocked(uint128 marketId) external view returns (bool isLocked);

    /**
     * @notice Returns the USD token associated with this synthetix core system
     */
    function getUsdToken() external view returns (IERC20);

    /**
     * @notice Retrieve the systems' configured oracle manager address
     */
    function getOracleManager() external view returns (IOracleManager);

    /**
     * @notice Update a market's current debt registration with the system.
     * This function is provided as an escape hatch for pool griefing, preventing
     * overwhelming the system with a series of very small pools and creating high gas
     * costs to update an account.
     * @param marketId the id of the market that needs pools bumped
     * @return finishedDistributing whether or not all bumpable pools have been bumped and target price has been reached
     */
    function distributeDebtToPools(
        uint128 marketId,
        uint256 maxIter
    ) external returns (bool finishedDistributing);

    /**
     * @notice allows for a market to set its minimum delegation time. This is useful for preventing stakers from frontrunning rewards or losses
     * by limiting the frequency of `delegateCollateral` (or `setPoolConfiguration`) calls. By default, there is no minimum delegation time.
     * @param marketId the id of the market that wants to set delegation time.
     * @param minDelegateTime the minimum number of seconds between delegation calls. Note: this value must be less than the globally defined maximum minDelegateTime
     */
    function setMarketMinDelegateTime(uint128 marketId, uint32 minDelegateTime) external;

    /**
     * @notice Retrieve the minimum delegation time of a market
     * @param marketId the id of the market
     */
    function getMarketMinDelegateTime(uint128 marketId) external view returns (uint32);

    /**
     * @notice Allows the system owner (not the pool owner) to set a market-specific minimum liquidity ratio.
     * @param marketId the id of the market
     * @param minLiquidityRatio The new market-specific minimum liquidity ratio, denominated with 18 decimals of precision. (100% is represented by 1 followed by 18 zeros.)
     */
    function setMinLiquidityRatio(uint128 marketId, uint256 minLiquidityRatio) external;

    /**
     * @notice Retrieves the market-specific minimum liquidity ratio.
     * @param marketId the id of the market
     * @return minRatioD18 The current market-specific minimum liquidity ratio, denominated with 18 decimals of precision. (100% is represented by 1 followed by 18 zeros.)
     */
    function getMinLiquidityRatio(uint128 marketId) external view returns (uint256 minRatioD18);
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import {IERC165} from "@synthetixio/core-contracts/contracts/interfaces/IERC165.sol";

/**
 * @title Module with assorted utility functions.
 */
interface IUtilsModule is IERC165 {
    /**
     * @notice Emitted when a new cross chain network becomes supported by the protocol
     */
    event NewSupportedCrossChainNetwork(uint64 newChainId);

    /**
     * @notice Configure CCIP addresses on the stablecoin.
     * @param ccipRouter The address on this chain to which CCIP messages will be sent or received.
     * @param ccipTokenPool The address where CCIP fees will be sent to when sending and receiving cross chain messages.
     */
    function configureChainlinkCrossChain(
        address ccipRouter,
        address ccipTokenPool,
        address chainlinkFunctions
    ) external;

    /**
     * @notice Used to add new cross chain networks to the protocol
     * Ignores a network if it matches the current chain id
     * Ignores a network if it has already been added
     * @param supportedNetworks array of all networks that are supported by the protocol
     * @param ccipSelectors the ccip "selector" which maps to the chain id on the same index. must be same length as `supportedNetworks`
     * @return numRegistered the number of networks that were actually registered
     */
    function setSupportedCrossChainNetworks(
        uint64[] memory supportedNetworks,
        uint64[] memory ccipSelectors
    ) external returns (uint256 numRegistered);

    /**
     * @notice Configure the system's single oracle manager address.
     * @param oracleManagerAddress The address of the oracle manager.
     */
    function configureOracleManager(address oracleManagerAddress) external;

    /**
     * @notice Configure a generic value in the KV system
     * @param k the key of the value to set
     * @param v the value that the key should be set to
     */
    function setConfig(bytes32 k, bytes32 v) external;

    /**
     * @notice Read a generic value from the KV system
     * @param k the key to read
     * @return v the value set on the specified k
     */
    function getConfig(bytes32 k) external view returns (bytes32 v);

    /**
     * @notice Read a UINT value from the KV system
     * @param k the key to read
     * @return v the value set on the specified k
     */
    function getConfigUint(bytes32 k) external view returns (uint256 v);

    /**
     * @notice Read a Address value from the KV system
     * @param k the key to read
     * @return v the value set on the specified k
     */
    function getConfigAddress(bytes32 k) external view returns (address v);
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import "../storage/NodeOutput.sol";
import "../storage/NodeDefinition.sol";

/// @title Module for managing nodes
interface INodeModule {
    /**
     * @notice Thrown when the specified nodeId has not been registered in the system.
     */
    error NodeNotRegistered(bytes32 nodeId);

    /**
     * @notice Thrown when a node is registered without a valid definition.
     */
    error InvalidNodeDefinition(NodeDefinition.Data nodeType);

    /**
     * @notice Thrown when a node cannot be processed
     */
    error UnprocessableNode(bytes32 nodeId);

    /**
     * @notice Emitted when `registerNode` is called.
     * @param nodeId The id of the registered node.
     * @param nodeType The nodeType assigned to this node.
     * @param parameters The parameters assigned to this node.
     * @param parents The parents assigned to this node.
     */
    event NodeRegistered(
        bytes32 nodeId,
        NodeDefinition.NodeType nodeType,
        bytes parameters,
        bytes32[] parents
    );

    /**
     * @notice Registers a node
     * @param nodeType The nodeType assigned to this node.
     * @param parameters The parameters assigned to this node.
     * @param parents The parents assigned to this node.
     * @return nodeId The id of the registered node.
     */
    function registerNode(
        NodeDefinition.NodeType nodeType,
        bytes memory parameters,
        bytes32[] memory parents
    ) external returns (bytes32 nodeId);

    /**
     * @notice Returns the ID of a node, whether or not it has been registered.
     * @param parents The parents assigned to this node.
     * @param nodeType The nodeType assigned to this node.
     * @param parameters The parameters assigned to this node.
     * @return nodeId The id of the node.
     */
    function getNodeId(
        NodeDefinition.NodeType nodeType,
        bytes memory parameters,
        bytes32[] memory parents
    ) external returns (bytes32 nodeId);

    /**
     * @notice Returns a node's definition (type, parameters, and parents)
     * @param nodeId The node ID
     * @return node The node's definition data
     */
    function getNode(bytes32 nodeId) external view returns (NodeDefinition.Data memory node);

    /**
     * @notice Returns a node current output data
     * @param nodeId The node ID
     * @return node The node's output data
     */
    function process(bytes32 nodeId) external view returns (NodeOutput.Data memory node);
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

library NodeDefinition {
    enum NodeType {
        NONE,
        REDUCER,
        EXTERNAL,
        CHAINLINK,
        UNISWAP,
        PYTH,
        PRICE_DEVIATION_CIRCUIT_BREAKER,
        STALENESS_CIRCUIT_BREAKER,
        CONSTANT
    }

    struct Data {
        /**
         * @dev Oracle node type enum
         */
        NodeType nodeType;
        /**
         * @dev Node parameters, specific to each node type
         */
        bytes parameters;
        /**
         * @dev Parent node IDs, if any
         */
        bytes32[] parents;
    }

    /**
     * @dev Returns the node stored at the specified node ID.
     */
    function load(bytes32 id) internal pure returns (Data storage node) {
        bytes32 s = keccak256(abi.encode("io.synthetix.oracle-manager.Node", id));
        assembly {
            node.slot := s
        }
    }

    /**
     * @dev Register a new node for a given node definition. The resulting node is a function of the definition.
     */
    function create(
        Data memory nodeDefinition
    ) internal returns (NodeDefinition.Data storage node, bytes32 id) {
        id = getId(nodeDefinition);

        node = load(id);

        node.nodeType = nodeDefinition.nodeType;
        node.parameters = nodeDefinition.parameters;
        node.parents = nodeDefinition.parents;
    }

    /**
     * @dev Returns a node ID based on its definition
     */
    function getId(Data memory nodeDefinition) internal pure returns (bytes32 id) {
        return
            keccak256(
                abi.encode(
                    nodeDefinition.nodeType,
                    nodeDefinition.parameters,
                    nodeDefinition.parents
                )
            );
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

library NodeOutput {
    struct Data {
        /**
         * @dev Price returned from the oracle node, expressed with 18 decimals of precision
         */
        int256 price;
        /**
         * @dev Timestamp associated with the price
         */
        uint256 timestamp;
        // solhint-disable-next-line private-vars-leading-underscore
        uint256 __slotAvailableForFutureUse1;
        // solhint-disable-next-line private-vars-leading-underscore
        uint256 __slotAvailableForFutureUse2;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import "@synthetixio/core-contracts/contracts/interfaces/IERC165.sol";

/// @title Spot Market Interface
interface IFeeCollector is IERC165 {
    /**
     * @notice  .This function is called by the spot market proxy to get the fee amount to be collected.
     * @dev     .The quoted fee amount is then transferred directly to the fee collector.
     * @param   marketId  .synth market id value
     * @param   feeAmount  .max fee amount that can be collected
     * @param   transactor  .the trader the fee was collected from
     * @param   tradeType  .transaction type (see Transaction.Type)
     * @return  feeAmountToCollect  .quoted fee amount
     */
    function quoteFees(
        uint128 marketId,
        uint256 feeAmount,
        address transactor,
        uint8 tradeType
    ) external returns (uint256 feeAmountToCollect);
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import "@synthetixio/core-modules/contracts/interfaces/IAssociatedSystemsModule.sol";
import "@synthetixio/main/contracts/interfaces/IMarketManagerModule.sol";
import "@synthetixio/main/contracts/interfaces/IMarketCollateralModule.sol";
import "@synthetixio/main/contracts/interfaces/IUtilsModule.sol";

interface ISynthetixSystem is
    IAssociatedSystemsModule,
    IMarketCollateralModule,
    IMarketManagerModule,
    IUtilsModule
{}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title Module for market-specific configuration.
 */
interface IMarketConfigurationModule {
    /**
     * @notice thrown when wrap + unwrap fees are being set to a negative value in total
     */
    error InvalidWrapperFees();

    /**
     * @notice emitted when market utilization fees are set for specified market
     * @param synthMarketId market id
     * @param utilizationFeeRate utilization fee rate value
     */
    event MarketUtilizationFeesSet(uint256 indexed synthMarketId, uint256 utilizationFeeRate);

    /**
     * @notice emitted when the skew scale is set for a market
     * @param synthMarketId market id
     * @param skewScale skew scale value
     */
    event MarketSkewScaleSet(uint256 indexed synthMarketId, uint256 skewScale);

    /**
     * @notice emitted when the collateral leverage is set for a market
     * @param synthMarketId market id
     * @param collateralLeverage leverage value
     */
    event CollateralLeverageSet(uint256 indexed synthMarketId, uint256 collateralLeverage);

    /**
     * @notice emitted when the fixed fee for atomic orders is set.
     * @param synthMarketId market id
     * @param atomicFixedFee fee value
     */
    event AtomicFixedFeeSet(uint256 indexed synthMarketId, uint256 atomicFixedFee);

    /**
     * @notice emitted when the fixed fee for async orders is set.
     * @param synthMarketId market id
     * @param asyncFixedFee fee value
     */
    event AsyncFixedFeeSet(uint256 indexed synthMarketId, uint256 asyncFixedFee);

    /**
     * @notice emitted when the fixed fee is set for a given transactor
     * @dev this overrides the async/atomic fixed fees for a given transactor
     * @param synthMarketId Id of the market to set the fees for.
     * @param transactor fixed fee for the transactor (overrides the global fixed fee)
     * @param fixedFeeAmount the fixed fee for the corresponding market, and transactor
     */
    event TransactorFixedFeeSet(
        uint256 indexed synthMarketId,
        address transactor,
        uint256 fixedFeeAmount
    );

    /**
     * @notice emitted when custom fee collector is set for a given market
     * @param synthMarketId Id of the market to set the collector for.
     * @param feeCollector the address of the fee collector to set.
     */
    event FeeCollectorSet(uint256 indexed synthMarketId, address feeCollector);

    /**
     * @notice emitted when wrapper fees are set for a given market
     * @param synthMarketId Id of the market to set the wrapper fees.
     * @param wrapFee wrapping fee in %, 18 decimals. Can be negative.
     * @param unwrapFee unwrapping fee in %, 18 decimals. Can be negative.
     */
    event WrapperFeesSet(uint256 indexed synthMarketId, int256 wrapFee, int256 unwrapFee);

    /**
     * @notice Emitted when the owner of the market has changed.
     * @param marketId Id of the market
     * @param referrer The address of the referrer
     * @param sharePercentage The new share percentage for the referrer
     */
    event ReferrerShareUpdated(uint128 indexed marketId, address referrer, uint256 sharePercentage);

    /**
     * @notice Thrown when the fee collector does not implement the IFeeCollector interface
     */
    error InvalidFeeCollectorInterface(address invalidFeeCollector);

    /**
     * @notice gets the atomic fixed fee for a given market
     * @param synthMarketId Id of the market the fee applies to.
     * @return atomicFixedFee fixed fee amount represented in bips with 18 decimals.
     * @return asyncFixedFee fixed fee amount represented in bips with 18 decimals.
     * @return wrapFee wrapping fee in %, 18 decimals. Can be negative.
     * @return unwrapFee unwrapping fee in %, 18 decimals. Can be negative.
     */
    function getMarketFees(
        uint128 synthMarketId
    )
        external
        returns (uint256 atomicFixedFee, uint256 asyncFixedFee, int256 wrapFee, int256 unwrapFee);

    /**
     * @notice sets the atomic fixed fee for a given market
     * @dev only marketOwner can set the fee
     * @param synthMarketId Id of the market the fee applies to.
     * @param atomicFixedFee fixed fee amount represented in bips with 18 decimals.
     */
    function setAtomicFixedFee(uint128 synthMarketId, uint256 atomicFixedFee) external;

    /**
     * @notice sets the async fixed fee for a given market
     * @dev only marketOwner can set the fee
     * @param synthMarketId Id of the market the fee applies to.
     * @param asyncFixedFee fixed fee amount represented in bips with 18 decimals.
     */
    function setAsyncFixedFee(uint128 synthMarketId, uint256 asyncFixedFee) external;

    /**
     * @notice sets the skew scale for a given market
     * @dev only marketOwner can set the skew scale
     * @param synthMarketId Id of the market the skew scale applies to.
     * @param skewScale max amount of synth which makes the skew 100%. the fee is derived as a % of the max value.  100% premium means outstanding synth == skewScale.
     */
    function setMarketSkewScale(uint128 synthMarketId, uint256 skewScale) external;

    /**
     * @notice gets the skew scale for a given market
     * @param synthMarketId Id of the market the skew scale applies to.
     * @return skewScale max amount of synth which makes the skew 100%. the fee is derived as a % of the max value.  100% premium means outstanding synth == skewScale.
     */
    function getMarketSkewScale(uint128 synthMarketId) external returns (uint256 skewScale);

    /**
     * @notice sets the market utilization fee for a given market
     * @dev only marketOwner can set the fee
     * @dev 100% utilization means the fee is 0.  120% utilization means the fee is 20% * this fee rate (in bips).
     * @param synthMarketId Id of the market the utilization fee applies to.
     * @param utilizationFeeRate the rate is represented in bips with 18 decimals and is the rate at which fee increases based on the % above 100% utilization of the delegated collateral for the market.
     */
    function setMarketUtilizationFees(uint128 synthMarketId, uint256 utilizationFeeRate) external;

    /**
     * @notice gets the market utilization fee for a given market
     * @dev 100% utilization means the fee is 0.  120% utilization means the fee is 20% * this fee rate (in bips).
     * @param synthMarketId Id of the market the utilization fee applies to.
     * @return utilizationFeeRate the rate is represented in bips with 18 decimals and is the rate at which fee increases based on the % above 100% utilization of the delegated collateral for the market.
     */
    function getMarketUtilizationFees(
        uint128 synthMarketId
    ) external returns (uint256 utilizationFeeRate);

    /**
     * @notice sets the collateral leverage for a given market
     * @dev only marketOwner can set the leverage
     * @dev this leverage value is a value applied to delegated collateral which is compared to outstanding synth to determine utilization of market, and locked amounts
     * @param synthMarketId Id of the market the collateral leverage applies to.
     * @param collateralLeverage the leverage is represented as % with 18 decimals. 1 = 1x leverage
     */
    function setCollateralLeverage(uint128 synthMarketId, uint256 collateralLeverage) external;

    /**
     * @notice gets the collateral leverage for a given market
     * @dev this leverage value is a value applied to delegated collateral which is compared to outstanding synth to determine utilization of market, and locked amounts
     * @param synthMarketId Id of the market the collateral leverage applies to.
     * @return collateralLeverage the leverage is represented as % with 18 decimals. 1 = 1x leverage
     */
    function getCollateralLeverage(
        uint128 synthMarketId
    ) external returns (uint256 collateralLeverage);

    /**
     * @notice sets the fixed fee for a given market and transactor
     * @dev overrides both the atomic and async fixed fees
     * @dev only marketOwner can set the fee
     * @dev especially useful for direct integrations where configured traders get a discount
     * @param synthMarketId Id of the market the custom transactor fee applies to.
     * @param transactor address of the trader getting discounted fees.
     * @param fixedFeeAmount the fixed fee applying to the provided transactor.
     */
    function setCustomTransactorFees(
        uint128 synthMarketId,
        address transactor,
        uint256 fixedFeeAmount
    ) external;

    /**
     * @notice gets the fixed fee for a given market and transactor
     * @dev overrides both the atomic and async fixed fees
     * @dev especially useful for direct integrations where configured traders get a discount
     * @param synthMarketId Id of the market the custom transactor fee applies to.
     * @param transactor address of the trader getting discounted fees.
     * @return fixedFeeAmount the fixed fee applying to the provided transactor.
     */
    function getCustomTransactorFees(
        uint128 synthMarketId,
        address transactor
    ) external returns (uint256 fixedFeeAmount);

    /**
     * @notice sets a custom fee collector for a given market
     * @dev only marketOwner can set the fee collector
     * @dev a use case here would be if the market owner wants to collect the fees via this contract and distribute via rewards distributor to SNX holders for example.
     * @dev if fee collector is not set, the fees are deposited into the market manager.
     * @param synthMarketId Id of the market the fee collector applies to.
     * @param feeCollector address of the fee collector inheriting the IFeeCollector interface.
     */
    function setFeeCollector(uint128 synthMarketId, address feeCollector) external;

    /**
     * @notice gets a custom fee collector for a given market
     * @param synthMarketId Id of the market the fee collector applies to.
     * @return feeCollector address of the fee collector inheriting the IFeeCollector interface.
     */
    function getFeeCollector(uint128 synthMarketId) external returns (address feeCollector);

    /**
     * @notice sets wrapper related fees.
     * @dev only marketOwner can set the wrapper fees
     * @dev fees can be negative.  this is a way to unwind the wrapper if needed by providing incentives.
     * @param synthMarketId Id of the market the wrapper fees apply to.
     * @param wrapFee wrapping fee in %, 18 decimals. Can be negative.
     * @param unwrapFee unwrapping fee in %, 18 decimals. Can be negative.
     */
    function setWrapperFees(uint128 synthMarketId, int256 wrapFee, int256 unwrapFee) external;

    /**
     * @notice Update the referral share percentage for a given market
     * @param marketId id of the market
     * @param referrer The address of the referrer
     * @param sharePercentage The new share percentage for the referrer
     */
    function updateReferrerShare(
        uint128 marketId,
        address referrer,
        uint256 sharePercentage
    ) external;

    /**
     * @notice get the referral share percentage for a given market
     * @param marketId id of the market
     * @param referrer The address of the referrer
     * @return sharePercentage The new share percentage for the referrer
     */
    function getReferrerShare(
        uint128 marketId,
        address referrer
    ) external returns (uint256 sharePercentage);
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import {IDecayTokenModule} from "@synthetixio/core-modules/contracts/interfaces/IDecayTokenModule.sol";

/**
 * @title Module for market synth tokens
 */
// solhint-disable-next-line no-empty-blocks
interface ISynthTokenModule is IDecayTokenModule {

}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import {ERC165Helper} from "@synthetixio/core-contracts/contracts/utils/ERC165Helper.sol";
import {IMarketConfigurationModule} from "../interfaces/IMarketConfigurationModule.sol";
import {IFeeCollector} from "../interfaces/external/IFeeCollector.sol";
import {SpotMarketFactory} from "../storage/SpotMarketFactory.sol";
import {MarketConfiguration} from "../storage/MarketConfiguration.sol";

/**
 * @title Module for configuring fees for registered synth markets.
 * @dev See IFeeConfigurationModule.
 */
contract MarketConfigurationModule is IMarketConfigurationModule {
    using SpotMarketFactory for SpotMarketFactory.Data;

    /**
     * @inheritdoc IMarketConfigurationModule
     */
    function setAtomicFixedFee(uint128 synthMarketId, uint256 atomicFixedFee) external override {
        SpotMarketFactory.load().onlyMarketOwner(synthMarketId);

        MarketConfiguration.load(synthMarketId).atomicFixedFee = atomicFixedFee;

        emit AtomicFixedFeeSet(synthMarketId, atomicFixedFee);
    }

    /**
     * @inheritdoc IMarketConfigurationModule
     */
    function getMarketFees(
        uint128 synthMarketId
    )
        external
        view
        override
        returns (uint256 atomicFixedFee, uint256 asyncFixedFee, int256 wrapFee, int256 unwrapFee)
    {
        MarketConfiguration.Data storage marketConfiguration = MarketConfiguration.load(
            synthMarketId
        );
        atomicFixedFee = marketConfiguration.atomicFixedFee;
        asyncFixedFee = marketConfiguration.asyncFixedFee;
        wrapFee = marketConfiguration.wrapFixedFee;
        unwrapFee = marketConfiguration.unwrapFixedFee;
    }

    /**
     * @inheritdoc IMarketConfigurationModule
     */
    function setAsyncFixedFee(uint128 synthMarketId, uint256 asyncFixedFee) external override {
        SpotMarketFactory.load().onlyMarketOwner(synthMarketId);

        MarketConfiguration.load(synthMarketId).asyncFixedFee = asyncFixedFee;

        emit AsyncFixedFeeSet(synthMarketId, asyncFixedFee);
    }

    /**
     * @inheritdoc IMarketConfigurationModule
     */
    function setMarketSkewScale(uint128 synthMarketId, uint256 skewScale) external override {
        SpotMarketFactory.load().onlyMarketOwner(synthMarketId);

        MarketConfiguration.load(synthMarketId).skewScale = skewScale;

        emit MarketSkewScaleSet(synthMarketId, skewScale);
    }

    /**
     * @inheritdoc IMarketConfigurationModule
     */
    function getMarketSkewScale(
        uint128 synthMarketId
    ) external view override returns (uint256 skewScale) {
        skewScale = MarketConfiguration.load(synthMarketId).skewScale;
    }

    /**
     * @inheritdoc IMarketConfigurationModule
     */
    function setMarketUtilizationFees(
        uint128 synthMarketId,
        uint256 utilizationFeeRate
    ) external override {
        SpotMarketFactory.load().onlyMarketOwner(synthMarketId);

        MarketConfiguration.load(synthMarketId).utilizationFeeRate = utilizationFeeRate;

        emit MarketUtilizationFeesSet(synthMarketId, utilizationFeeRate);
    }

    /**
     * @inheritdoc IMarketConfigurationModule
     */
    function getMarketUtilizationFees(
        uint128 synthMarketId
    ) external view override returns (uint256 utilizationFeeRate) {
        utilizationFeeRate = MarketConfiguration.load(synthMarketId).utilizationFeeRate;
    }

    /**
     * @inheritdoc IMarketConfigurationModule
     */
    function setCollateralLeverage(
        uint128 synthMarketId,
        uint256 collateralLeverage
    ) external override {
        SpotMarketFactory.load().onlyMarketOwner(synthMarketId);
        MarketConfiguration.isValidLeverage(collateralLeverage);

        MarketConfiguration.load(synthMarketId).collateralLeverage = collateralLeverage;

        emit CollateralLeverageSet(synthMarketId, collateralLeverage);
    }

    /**
     * @inheritdoc IMarketConfigurationModule
     */
    function getCollateralLeverage(
        uint128 synthMarketId
    ) external view override returns (uint256 collateralLeverage) {
        collateralLeverage = MarketConfiguration.load(synthMarketId).collateralLeverage;
    }

    /**
     * @inheritdoc IMarketConfigurationModule
     */
    function setCustomTransactorFees(
        uint128 synthMarketId,
        address transactor,
        uint256 fixedFeeAmount
    ) external override {
        SpotMarketFactory.load().onlyMarketOwner(synthMarketId);
        MarketConfiguration.setFixedFeeOverride(synthMarketId, transactor, fixedFeeAmount);

        emit TransactorFixedFeeSet(synthMarketId, transactor, fixedFeeAmount);
    }

    /**
     * @inheritdoc IMarketConfigurationModule
     */
    function getCustomTransactorFees(
        uint128 synthMarketId,
        address transactor
    ) external view override returns (uint256 fixedFeeAmount) {
        fixedFeeAmount = MarketConfiguration.getFixedFeeOverride(synthMarketId, transactor);
    }

    /**
     * @inheritdoc IMarketConfigurationModule
     */
    function setFeeCollector(uint128 synthMarketId, address feeCollector) external override {
        SpotMarketFactory.Data storage spotMarketFactory = SpotMarketFactory.load();
        spotMarketFactory.onlyMarketOwner(synthMarketId);
        if (feeCollector != address(0)) {
            if (
                !ERC165Helper.safeSupportsInterface(feeCollector, type(IFeeCollector).interfaceId)
            ) {
                revert InvalidFeeCollectorInterface(feeCollector);
            }
        }

        MarketConfiguration.load(synthMarketId).feeCollector = IFeeCollector(feeCollector);
        emit FeeCollectorSet(synthMarketId, feeCollector);
    }

    /**
     * @inheritdoc IMarketConfigurationModule
     */
    function getFeeCollector(
        uint128 synthMarketId
    ) external view override returns (address feeCollector) {
        feeCollector = address(MarketConfiguration.load(synthMarketId).feeCollector);
    }

    /**
     * @inheritdoc IMarketConfigurationModule
     */
    function setWrapperFees(
        uint128 synthMarketId,
        int256 wrapFee,
        int256 unwrapFee
    ) external override {
        SpotMarketFactory.load().onlyMarketOwner(synthMarketId);

        if (wrapFee + unwrapFee < 0) {
            revert InvalidWrapperFees();
        }

        MarketConfiguration.Data storage marketConfiguration = MarketConfiguration.load(
            synthMarketId
        );
        marketConfiguration.wrapFixedFee = wrapFee;
        marketConfiguration.unwrapFixedFee = unwrapFee;

        emit WrapperFeesSet(synthMarketId, wrapFee, unwrapFee);
    }

    /**
     * @inheritdoc IMarketConfigurationModule
     */
    function updateReferrerShare(
        uint128 synthMarketId,
        address referrer,
        uint256 sharePercentage
    ) external override {
        SpotMarketFactory.load().onlyMarketOwner(synthMarketId);

        MarketConfiguration.load(synthMarketId).referrerShare[referrer] = sharePercentage;

        emit ReferrerShareUpdated(synthMarketId, referrer, sharePercentage);
    }

    /**
     * @inheritdoc IMarketConfigurationModule
     */
    function getReferrerShare(
        uint128 synthMarketId,
        address referrer
    ) external view override returns (uint256 sharePercentage) {
        sharePercentage = MarketConfiguration.load(synthMarketId).referrerShare[referrer];
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import {SafeCastU256, SafeCastI256} from "@synthetixio/core-contracts/contracts/utils/SafeCast.sol";
import {DecimalMath} from "@synthetixio/core-contracts/contracts/utils/DecimalMath.sol";

import {IFeeCollector} from "../interfaces/external/IFeeCollector.sol";
import {SpotMarketFactory} from "./SpotMarketFactory.sol";
import {Wrapper} from "./Wrapper.sol";
import {OrderFees} from "./OrderFees.sol";
import {SynthUtil} from "../utils/SynthUtil.sol";
import {MathUtil} from "../utils/MathUtil.sol";
import {Transaction} from "../utils/TransactionUtil.sol";

/**
 * @title Fee storage that tracks all fees for a given market Id.
 */
library MarketConfiguration {
    using SpotMarketFactory for SpotMarketFactory.Data;
    using OrderFees for OrderFees.Data;
    using SafeCastU256 for uint256;
    using SafeCastI256 for int256;
    using DecimalMath for uint256;
    using DecimalMath for int256;

    error InvalidUtilizationLeverage();
    error InvalidCollateralLeverage(uint256);

    struct Data {
        /**
         * @dev The fixed fee rate for a specific transactor.  Useful for direct integrations to set custom fees for specific addresses.
         */
        mapping(address => uint256) fixedFeeOverrides;
        /**
         * @dev atomic buy/sell fixed fee that's applied on all trades. Percentage, 18 decimals
         */
        uint256 atomicFixedFee;
        /**
         * @dev buy/sell fixed fee that's applied on all async trades. Percentage, 18 decimals
         */
        uint256 asyncFixedFee;
        /**
         * @dev utilization fee rate (in percentage) is the rate of fees applied based on the ratio of delegated collateral to total outstanding synth exposure. 18 decimals
         * applied on buy trades only.
         */
        uint256 utilizationFeeRate;
        /**
         * @dev a configurable leverage % that is applied to delegated collateral which is used as a ratio for determining utilization, and locked amounts. D18
         */
        uint256 collateralLeverage;
        /**
         * @dev wrapping fee rate represented as a percent, 18 decimals
         */
        int256 wrapFixedFee;
        /**
         * @dev unwrapping fee rate represented as a percent, 18 decimals
         */
        int256 unwrapFixedFee;
        /**
         * @dev skewScale is used to determine % of fees that get applied based on the ratio of outstanding synths to skewScale.
         * if outstanding synths = skew scale, then 100% premium is applied to the trade.
         * A negative skew, derived based on the mentioned ratio, is applied on sell trades
         */
        uint256 skewScale;
        /**
         * @dev Once fees are calculated, the quote function is called with the totalFees.  The returned quoted amount is then transferred to this fee collector address
         */
        IFeeCollector feeCollector;
        /**
         * @dev Percentage share for each referrer address
         */
        mapping(address => uint256) referrerShare;
    }

    function load(uint128 marketId) internal pure returns (Data storage marketConfig) {
        bytes32 s = keccak256(abi.encode("io.synthetix.spot-market.Fee", marketId));
        assembly {
            marketConfig.slot := s
        }
    }

    function isValidLeverage(uint256 leverage) internal pure {
        // add upper bounds for leverage here
        if (leverage == 0) {
            revert InvalidCollateralLeverage(leverage);
        }
    }

    /**
     * @dev Set custom fee for transactor
     */
    function setFixedFeeOverride(uint128 marketId, address transactor, uint256 fixedFee) internal {
        load(marketId).fixedFeeOverrides[transactor] = fixedFee;
    }

    /**
     * @dev Get custom fee for transactor
     */
    function getFixedFeeOverride(
        uint128 marketId,
        address transactor
    ) internal view returns (uint256 fixedFee) {
        fixedFee = load(marketId).fixedFeeOverrides[transactor];
    }

    /**
     * @dev Get quote for amount of collateral (`baseAmountD18`) to receive in synths (`synthAmount`)
     */
    function quoteWrap(
        uint128 marketId,
        uint256 baseAmountD18,
        uint256 synthPrice
    ) internal view returns (uint256 synthAmount, OrderFees.Data memory fees, Data storage config) {
        config = load(marketId);
        uint256 usdAmount = baseAmountD18.mulDecimal(synthPrice);
        fees.wrapperFees = config.wrapFixedFee.mulDecimal(usdAmount.toInt());
        usdAmount = (usdAmount.toInt() - fees.wrapperFees).toUint();

        synthAmount = usdAmount.divDecimal(synthPrice);
    }

    /**
     * @dev Get quote for amount of synth (`synthAmount`) to receive in collateral (`amount`)
     */
    function quoteUnwrap(
        uint128 marketId,
        uint256 synthAmount,
        uint256 synthPrice
    ) internal view returns (uint256 amount, OrderFees.Data memory fees, Data storage config) {
        config = load(marketId);
        uint256 usdAmount = synthAmount.mulDecimal(synthPrice);
        fees.wrapperFees = config.unwrapFixedFee.mulDecimal(usdAmount.toInt());
        usdAmount = (usdAmount.toInt() - fees.wrapperFees).toUint();

        amount = usdAmount.divDecimal(synthPrice);
    }

    /**
     * @dev Get quote for amount of usd (`usdAmount`) to charge trader for the specified synth amount (`synthAmount`)
     */
    function quoteBuyExactOut(
        uint128 marketId,
        uint256 synthAmount,
        uint256 synthPrice,
        address transactor,
        Transaction.Type transactionType
    ) internal view returns (uint256 usdAmount, OrderFees.Data memory fees, Data storage config) {
        config = load(marketId);
        // this amount gets fees applied below and is the return amount to charge user
        usdAmount = synthAmount.mulDecimal(synthPrice);

        int256 amountInt = usdAmount.toInt();

        // compute skew fee based on amount out
        int256 skewFee = calculateSkewFeeRatioExact(
            config,
            marketId,
            amountInt,
            synthPrice,
            transactionType
        );

        fees.skewFees = skewFee.mulDecimal(amountInt);
        // apply fees by adding to the amount
        usdAmount = (amountInt + fees.skewFees).toUint();

        uint256 utilizationFee = calculateUtilizationFeeRatio(
            config,
            marketId,
            usdAmount,
            synthPrice
        );
        uint256 fixedFee = _getFixedFeeRatio(
            config,
            transactor,
            Transaction.isAsync(transactionType)
        );
        // apply utilization and fixed fees
        // Note: when calculating exact out, we need to apply fees in reverse order.  so instead of
        // multiplying by %, we divide by %
        fees.utilizationFees = usdAmount.divDecimal(DecimalMath.UNIT - utilizationFee) - usdAmount;
        fees.fixedFees = usdAmount.divDecimal(DecimalMath.UNIT - fixedFee) - usdAmount;

        usdAmount += fees.fixedFees + fees.utilizationFees;
    }

    /**
     * @dev Get quote for amount of synths (`synthAmount`) to receive for a given amount of USD (`usdAmount`)
     */
    function quoteBuyExactIn(
        uint128 marketId,
        uint256 usdAmount,
        uint256 synthPrice,
        address transactor,
        Transaction.Type transactionType
    ) internal view returns (uint256 synthAmount, OrderFees.Data memory fees, Data storage config) {
        config = load(marketId);

        uint256 utilizationFee = calculateUtilizationFeeRatio(
            config,
            marketId,
            usdAmount,
            synthPrice
        );
        uint256 fixedFee = _getFixedFeeRatio(
            config,
            transactor,
            Transaction.isAsync(transactionType)
        );

        fees.utilizationFees = utilizationFee.mulDecimal(usdAmount);
        fees.fixedFees = fixedFee.mulDecimal(usdAmount);
        // apply utilization and fixed fees by removing from the amount to be returned to trader.
        usdAmount = usdAmount - fees.fixedFees - fees.utilizationFees;

        synthAmount = calculateSkew(config, marketId, usdAmount.toInt(), synthPrice);
        fees.skewFees = usdAmount.toInt() - synthAmount.mulDecimal(synthPrice).toInt();
    }

    /**
     * @dev Get quote for amount of synth (`synthAmount`) to burn from trader for the requested
     *      amount of USD (`usdAmount`)
     */
    function quoteSellExactOut(
        uint128 marketId,
        uint256 usdAmount,
        uint256 synthPrice,
        address transactor,
        Transaction.Type transactionType
    ) internal view returns (uint256 synthAmount, OrderFees.Data memory fees, Data storage config) {
        config = load(marketId);

        uint256 synthAmountFromSkew = calculateSkew(
            config,
            marketId,
            usdAmount.toInt() * -1, // when selling, use negative amount
            synthPrice
        );

        fees.skewFees = synthAmountFromSkew.mulDecimal(synthPrice).toInt() - usdAmount.toInt();
        usdAmount = (usdAmount.toInt() + fees.skewFees).toUint();

        uint256 fixedFee = _getFixedFeeRatio(
            config,
            transactor,
            Transaction.isAsync(transactionType)
        );
        // use the usd amount _after_ skew fee is applied to the amount
        // when exact out, fees are applied by dividing by %
        fees.fixedFees = usdAmount.divDecimal(DecimalMath.UNIT - fixedFee) - usdAmount;
        // apply fixed fee
        usdAmount += fees.fixedFees;
        // convert usd amount to synth amount to return to trader
        synthAmount = usdAmount.divDecimal(synthPrice);
    }

    /**
     * @dev Get quote for amount of USD (`usdAmount`) to receive for a given amount of synths (`synthAmount`)
     */
    function quoteSellExactIn(
        uint128 marketId,
        uint256 synthAmount,
        uint256 synthPrice,
        address transactor,
        Transaction.Type transactionType
    ) internal view returns (uint256 usdAmount, OrderFees.Data memory fees, Data storage config) {
        config = load(marketId);

        usdAmount = synthAmount.mulDecimal(synthPrice);

        uint256 fixedFee = _getFixedFeeRatio(
            config,
            transactor,
            Transaction.isAsync(transactionType)
        );
        fees.fixedFees = fixedFee.mulDecimal(usdAmount);

        // apply fixed fee by removing from the amount that gets returned to user in exchange
        usdAmount -= fees.fixedFees;

        // use the amount _after_ fixed fee is applied to the amount
        // skew is calcuated based on amount after all other fees applied, to get accurate skew fee
        int256 usdAmountInt = usdAmount.toInt();
        int256 skewFee = calculateSkewFeeRatioExact(
            config,
            marketId,
            usdAmountInt * -1, // removing value so negative
            synthPrice,
            transactionType
        );
        fees.skewFees = skewFee.mulDecimal(usdAmountInt);
        usdAmount = (usdAmountInt - fees.skewFees).toUint();
    }

    /**
     * @dev Returns a skew fee based on the exact amount of synth either being added or removed from the market (`usdAmount`)
     * @dev This function is used when we call `buyExactOut` or `sellExactIn` where we know the exact synth leaving/added to the system.
     * @dev When we only know the USD amount and need to calculate expected synth after fees, we have to use
     *      `calculateSkew` instead.
     *
     * Example:
     *  Skew scale set to 1000 snxETH
     *  Before fill outstanding snxETH (minus any wrapped collateral): 100 snxETH
     *  If buy trade:
     *    - user is buying 10 ETH
     *    - skew fee = (100 / 1000 + 110 / 1000) / 2 = 0.105 = 10.5% = 1050 bips
     *  On a sell, the amount is negative, and so if there's positive skew in the system, the fee is negative to incentize selling
     *  and if the skew is negative, then the fee for a sell would be positive to incentivize neutralizing the skew.
     */
    function calculateSkewFeeRatioExact(
        Data storage self,
        uint128 marketId,
        int256 usdAmount,
        uint256 synthPrice,
        Transaction.Type transactionType
    ) internal view returns (int256 skewFee) {
        if (self.skewScale == 0) {
            return 0;
        }

        int256 skewScaleValue = self.skewScale.mulDecimal(synthPrice).toInt();

        uint256 wrappedCollateralAmount = SpotMarketFactory
            .load()
            .synthetix
            .getMarketCollateralAmount(marketId, Wrapper.load(marketId).wrapCollateralType)
            .mulDecimal(synthPrice);

        int256 initialSkew = SynthUtil
            .getToken(marketId)
            .totalSupply()
            .mulDecimal(synthPrice)
            .toInt() - wrappedCollateralAmount.toInt();

        int256 skewAfterFill = initialSkew + usdAmount;
        int256 skewAverage = (skewAfterFill + initialSkew) / 2;

        skewFee = skewAverage.divDecimal(skewScaleValue);
        // fee direction is switched on sell
        if (Transaction.isSell(transactionType)) {
            skewFee = skewFee * -1;
        }
    }

    /**
     * @dev For a given USD amount, based on the skew scale, returns the exact synth amount to return or charge the trader
     * @dev This function is used when we call `buyExactIn` or `sellExactOut` where we know the USD amount and need to calculate the synth amount
     */
    function calculateSkew(
        Data storage self,
        uint128 marketId,
        int256 usdAmount,
        uint256 synthPrice
    ) internal view returns (uint256 synthAmount) {
        if (self.skewScale == 0) {
            return MathUtil.abs(usdAmount).divDecimal(synthPrice);
        }

        uint256 wrappedCollateralAmount = SpotMarketFactory
            .load()
            .synthetix
            .getMarketCollateralAmount(marketId, Wrapper.load(marketId).wrapCollateralType);
        int256 initialSkew = SynthUtil.getToken(marketId).totalSupply().toInt() -
            wrappedCollateralAmount.toInt();

        synthAmount = MathUtil.abs(
            _calculateSkewAmountOut(self, usdAmount, synthPrice, initialSkew)
        );
    }

    /**
     * @dev Calculates utilization rate fee
     * If no utilizationFeeRate is set, then the fee is 0
     * The utilization rate fee is determined based on the ratio of outstanding synth value to the delegated collateral to the market.
     * The delegated collateral is calculated by multiplying the collateral by a configurable leverage parameter (`utilizationLeveragePercentage`)
     *
     * Example:
     *  Utilization fee rate set to 0.1%
     *  collateralLeverage: 2
     *  Total delegated collateral value: $1000 * 2 = $2000
     *  Total outstanding synth value = $2200
     *  User buys $200 worth of synths
     *  Before fill utilization rate: 2200 / 2000 = 110%
     *  After fill utilization rate: 2400 / 2000 = 120%
     *  Utilization Rate Delta = 120 - 110 = 10% / 2 (average) = 5%
     *  Fee charged = 5 * 0.001 (0.1%)  = 0.5%
     *
     * Note: we do NOT calculate the inverse of this fee on `buyExactIn` vs `buyExactOut`.  We don't
     * believe this edge case adds any risk.  This means it could be beneficial to use `buyExactIn` vs `buyExactOut`
     */
    function calculateUtilizationFeeRatio(
        Data storage self,
        uint128 marketId,
        uint256 usdAmount,
        uint256 synthPrice
    ) internal view returns (uint256 utilFee) {
        if (self.utilizationFeeRate == 0 || self.collateralLeverage == 0) {
            return 0;
        }

        uint256 leveragedDelegatedCollateralValue = SpotMarketFactory
            .load()
            .synthetix
            .getMarketCollateral(marketId)
            .mulDecimal(self.collateralLeverage);

        uint256 totalBalance = SynthUtil.getToken(marketId).totalSupply();

        // Note: take into account the async order commitment amount in escrow
        uint256 totalValueBeforeFill = totalBalance.mulDecimal(synthPrice);
        uint256 totalValueAfterFill = totalValueBeforeFill + usdAmount;

        // utilization is below 100%
        if (leveragedDelegatedCollateralValue > totalValueAfterFill) {
            return 0;
        } else {
            uint256 preUtilization = totalValueBeforeFill.divDecimal(
                leveragedDelegatedCollateralValue
            );
            // use 100% utilization if pre-fill utilization was less than 100%
            // no fees charged below 100% utilization

            uint256 preUtilizationDelta = preUtilization > DecimalMath.UNIT
                ? preUtilization - DecimalMath.UNIT
                : 0;
            uint256 postUtilization = totalValueAfterFill.divDecimal(
                leveragedDelegatedCollateralValue
            );
            uint256 postUtilizationDelta = postUtilization - DecimalMath.UNIT;

            // utilization is represented as the # of percentage points above 100%
            uint256 utilization = (preUtilizationDelta + postUtilizationDelta).mulDecimal(
                100 * DecimalMath.UNIT
            ) / 2;

            utilFee = utilization.mulDecimal(self.utilizationFeeRate);
        }
    }

    /*
     * @dev if special fee is set for a given transactor that takes precedence over the global fixed fees
     * otherwise, if async order, use async fixed fee, otherwise use atomic fixed fee
     * @dev the code does not allow setting fixed fee to 0 for a given transactor.  If you want to disable fees for a given actor, set the fee to be very low (e.g. 1 wei)
     */
    function _getFixedFeeRatio(
        Data storage self,
        address transactor,
        bool async
    ) private view returns (uint256 fixedFee) {
        if (self.fixedFeeOverrides[transactor] > 0) {
            fixedFee = self.fixedFeeOverrides[transactor];
        } else {
            fixedFee = async ? self.asyncFixedFee : self.atomicFixedFee;
        }
    }

    /**
     * @dev First sends referrer fees based on fixed fee amount and configured %
     * Then if total fees for transaction are greater than 0, gets quote from
     * fee collector and transfers the quoted amount to fee collector
     */
    function collectFees(
        Data storage self,
        uint128 marketId,
        OrderFees.Data memory fees,
        address transactor,
        address referrer,
        SpotMarketFactory.Data storage factory,
        Transaction.Type transactionType
    ) internal returns (uint256 collectedFees) {
        uint256 referrerFeesCollected = _collectReferrerFees(
            self,
            marketId,
            fees,
            referrer,
            factory,
            transactionType
        );

        int256 totalFees = fees.total();
        if (totalFees <= 0 || address(self.feeCollector) == address(0)) {
            return referrerFeesCollected;
        }
        // remove fees sent to referrer before getting quote from fee collector
        totalFees -= referrerFeesCollected.toInt();

        uint256 totalFeesUint = totalFees.toUint();
        uint256 feeCollectorQuote = self.feeCollector.quoteFees(
            marketId,
            totalFeesUint,
            transactor,
            // solhint-disable-next-line numcast/safe-cast
            uint8(transactionType)
        );

        if (feeCollectorQuote > totalFeesUint) {
            feeCollectorQuote = totalFeesUint;
        }

        // if transaction is a sell or a wrapper type, we need to withdraw the fees from the market manager
        if (Transaction.isSell(transactionType) || Transaction.isWrapper(transactionType)) {
            factory.synthetix.withdrawMarketUsd(
                marketId,
                address(self.feeCollector),
                feeCollectorQuote
            );
        } else {
            factory.usdToken.transfer(address(self.feeCollector), feeCollectorQuote);
        }

        return referrerFeesCollected + feeCollectorQuote;
    }

    /**
     * @dev Referrer fees are a % of the fixed fee amount.  The % is retrieved from `referrerShare` and can be configured by market owner.
     * @dev If this is a sell transaction, the fee to send to referrer is withdrawn from market, otherwise it's directly transferred from the contract
     *      since funds were transferred here first.
     */
    function _collectReferrerFees(
        Data storage self,
        uint128 marketId,
        OrderFees.Data memory fees,
        address referrer,
        SpotMarketFactory.Data storage factory,
        Transaction.Type transactionType
    ) private returns (uint256 referrerFeesCollected) {
        if (referrer == address(0)) {
            return 0;
        }

        uint256 referrerPercentage = self.referrerShare[referrer];
        referrerFeesCollected = fees.fixedFees.mulDecimal(referrerPercentage);

        if (referrerFeesCollected > 0) {
            if (Transaction.isSell(transactionType)) {
                factory.synthetix.withdrawMarketUsd(marketId, referrer, referrerFeesCollected);
            } else {
                factory.usdToken.transfer(referrer, referrerFeesCollected);
            }
        }
    }

    /*
     * @dev This equation allows us to calculate skew fee % from any given point on the skew scale
     * to where we should end up after a fill.  The equation is derived from the following:
     *  K/2P * sqrt((8CP/K)+(2NiP/K + 2P)^2) - K - Ni
     *  K = configured skew scale
     *  C = amount (cost in USD)
     *  Ni = initial skew
     *  P = price
     *
     *  For a given amount in USD, this equation spits out the synth amount to be returned based on skew scale/price/initial skew
     */
    function _calculateSkewAmountOut(
        Data storage self,
        int256 usdAmount,
        uint256 price,
        int256 initialSkew
    ) private view returns (int256 amountOut) {
        uint256 skewPriceRatio = self.skewScale.divDecimal(2 * price);
        int256 costPriceSkewRatio = (8 * usdAmount.mulDecimal(price.toInt())).divDecimal(
            self.skewScale.toInt()
        );
        int256 initialSkewPriceRatio = (2 * initialSkew.mulDecimal(price.toInt())).divDecimal(
            self.skewScale.toInt()
        );

        int256 ratioSquared = MathUtil.pow(initialSkewPriceRatio + 2 * price.toInt(), 2);
        int256 sqrt = MathUtil.sqrt(costPriceSkewRatio + ratioSquared);

        return skewPriceRatio.toInt().mulDecimal(sqrt) - self.skewScale.toInt() - initialSkew;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import {SafeCastU256} from "@synthetixio/core-contracts/contracts/utils/SafeCast.sol";

/**
 * @notice  A convenience library that includes a Data struct which is used to track fees across different trade types
 */
library OrderFees {
    using SafeCastU256 for uint256;

    struct Data {
        uint256 fixedFees;
        uint256 utilizationFees;
        int256 skewFees;
        int256 wrapperFees;
    }

    function total(Data memory self) internal pure returns (int256 amount) {
        return
            self.fixedFees.toInt() +
            self.utilizationFees.toInt() +
            self.skewFees +
            self.wrapperFees;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import {ITokenModule} from "@synthetixio/core-modules/contracts/interfaces/ITokenModule.sol";
import {INodeModule} from "@synthetixio/oracle-manager/contracts/interfaces/INodeModule.sol";
import {ISynthetixSystem} from "../interfaces/external/ISynthetixSystem.sol";

/**
 * @title Main factory library that registers synths.  Also houses global configuration for all synths.
 */
library SpotMarketFactory {
    bytes32 private constant _SLOT_SPOT_MARKET_FACTORY =
        keccak256(abi.encode("io.synthetix.spot-market.SpotMarketFactory"));

    error OnlyMarketOwner(address marketOwner, address sender);
    error InvalidMarket(uint128 marketId);
    error InvalidSynthImplementation(uint256 synthImplementation);

    struct Data {
        /**
         * @dev snxUSD token address
         */
        ITokenModule usdToken;
        /**
         * @dev oracle manager address used for price feeds
         */
        INodeModule oracle;
        /**
         * @dev Synthetix core v3 proxy
         */
        ISynthetixSystem synthetix;
        /**
         * @dev erc20 synth implementation address.  associated systems creates a proxy backed by this implementation.
         */
        address synthImplementation;
        /**
         * @dev mapping of marketId to marketOwner
         */
        mapping(uint128 => address) marketOwners;
        /**
         * @dev mapping of marketId to marketNominatedOwner
         */
        mapping(uint128 => address) nominatedMarketOwners;
    }

    function load() internal pure returns (Data storage spotMarketFactory) {
        bytes32 s = _SLOT_SPOT_MARKET_FACTORY;
        assembly {
            spotMarketFactory.slot := s
        }
    }

    /**
     * @notice ensures synth implementation is set before creating synth
     */
    function checkSynthImplemention(Data storage self) internal view {
        if (self.synthImplementation == address(0)) {
            revert InvalidSynthImplementation(0);
        }
    }

    /**
     * @notice only owner of market passes check, otherwise reverts
     */
    function onlyMarketOwner(Data storage self, uint128 marketId) internal view {
        address marketOwner = self.marketOwners[marketId];

        if (marketOwner != msg.sender) {
            revert OnlyMarketOwner(marketOwner, msg.sender);
        }
    }

    /**
     * @notice validates market id by checking that an owner exists for the market
     */
    function validateMarket(Data storage self, uint128 marketId) internal view {
        if (self.marketOwners[marketId] == address(0)) {
            revert InvalidMarket(marketId);
        }
    }

    /**
     * @dev first creates an allowance entry in usdToken for market manager, then deposits snxUSD amount into mm.
     */
    function depositToMarketManager(Data storage self, uint128 marketId, uint256 amount) internal {
        self.usdToken.approve(address(this), amount);
        self.synthetix.depositMarketUsd(marketId, address(this), amount);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import {ISynthetixSystem} from "../interfaces/external/ISynthetixSystem.sol";
import {SpotMarketFactory} from "./SpotMarketFactory.sol";

/**
 * @title Wrapper library servicing the wrapper module
 */
library Wrapper {
    error InvalidCollateralType(bytes32 message);
    /**
     * @notice Thrown when user tries to wrap more than the set supply cap for the market.
     */
    error WrapperExceedsMaxAmount(
        uint256 maxWrappableAmount,
        uint256 currentSupply,
        uint256 amountToWrap
    );

    struct Data {
        /**
         * @dev tracks the type of collateral used for wrapping
         * helpful for checking balances and allowances
         */
        address wrapCollateralType;
        /**
         * @dev amount of collateral that can be wrapped, denominated with 18 decimals of precision.
         */
        uint256 maxWrappableAmount;
    }

    function load(uint128 marketId) internal pure returns (Data storage wrapper) {
        bytes32 s = keccak256(abi.encode("io.synthetix.spot-market.Wrapper", marketId));
        assembly {
            wrapper.slot := s
        }
    }

    function checkMaxWrappableAmount(
        Data storage self,
        uint128 marketId,
        uint256 wrapAmount,
        ISynthetixSystem synthetix
    ) internal view {
        uint256 currentDepositedCollateral = synthetix.getMarketCollateralAmount(
            marketId,
            self.wrapCollateralType
        );
        if (currentDepositedCollateral + wrapAmount > self.maxWrappableAmount) {
            revert WrapperExceedsMaxAmount(
                self.maxWrappableAmount,
                currentDepositedCollateral,
                wrapAmount
            );
        }
    }

    function updateValid(
        uint128 marketId,
        address wrapCollateralType,
        uint256 maxWrappableAmount
    ) internal {
        Data storage self = load(marketId);
        address configuredCollateralType = self.wrapCollateralType;

        // you are only allowed to update the collateral type once for each market
        // we currently do not support multiple collateral types/market
        uint currentMarketCollateralAmount = SpotMarketFactory
            .load()
            .synthetix
            .getMarketCollateralAmount(marketId, configuredCollateralType);
        if (currentMarketCollateralAmount != 0) {
            revert InvalidCollateralType("Already set");
        }

        self.wrapCollateralType = wrapCollateralType;
        self.maxWrappableAmount = maxWrappableAmount;
    }

    function validateWrapper(Data storage self) internal view {
        if (self.wrapCollateralType == address(0)) {
            revert InvalidCollateralType("Not set");
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import {SafeCastI256, SafeCastU256} from "@synthetixio/core-contracts/contracts/utils/SafeCast.sol";
import {DecimalMath} from "@synthetixio/core-contracts/contracts/utils/DecimalMath.sol";

/**
 * @title Math helper functions
 */
library MathUtil {
    using SafeCastI256 for int256;
    using SafeCastU256 for uint256;
    using DecimalMath for int256;

    function abs(int256 x) internal pure returns (uint256) {
        return x >= 0 ? x.toUint() : (-x).toUint();
    }

    function max(int256 x, int256 y) internal pure returns (int256) {
        return x < y ? y : x;
    }

    function min(int256 x, int256 y) internal pure returns (int256) {
        return x < y ? x : y;
    }

    function min(uint256 x, uint256 y) internal pure returns (uint256) {
        return x < y ? x : y;
    }

    function sameSide(int256 a, int256 b) internal pure returns (bool) {
        return (a == 0) || (b == 0) || (a > 0) == (b > 0);
    }

    function sqrt(int256 x) internal pure returns (int256 y) {
        int256 z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x.divDecimal(z) + z) / 2;
        }
    }

    function pow(int256 x, uint256 n) internal pure returns (int256 r) {
        r = DecimalMath.UNIT_INT;
        while (n > 0) {
            if (n % 2 == 1) {
                r = r.mulDecimal(x);
                n -= 1;
            } else {
                x = x.mulDecimal(x);
                n /= 2;
            }
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import {ISynthTokenModule} from "../interfaces/ISynthTokenModule.sol";
import "@synthetixio/core-modules/contracts/storage/AssociatedSystem.sol";

/**
 * @title Helper library that creates system ids used in AssociatedSystem.
 * @dev getters used throughout spot market system to get ERC-20 synth tokens
 */
library SynthUtil {
    using AssociatedSystem for AssociatedSystem.Data;

    /**
     * @notice Gets the token proxy address and returns it as ITokenModule
     */
    function getToken(uint128 marketId) internal view returns (ISynthTokenModule) {
        bytes32 synthId = getSystemId(marketId);

        // ISynthTokenModule inherits from IDecayTokenModule, which inherits from ITokenModule so
        // this is a safe conversion as long as you know that the ITokenModule returned by the token
        // type was initialized by us
        return ISynthTokenModule(AssociatedSystem.load(synthId).proxy);
    }

    /**
     * @notice returns the system id based on the market id.  this is the id that is stored in AssociatedSystem
     */
    function getSystemId(uint128 marketId) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("synth", marketId));
    }

    /**
     * @notice returns the proxy address of the erc-20 token associated with a given market
     */
    function getSynthTokenAddress(uint128 marketId) internal view returns (address) {
        return AssociatedSystem.load(SynthUtil.getSystemId(marketId)).proxy;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title Transaction types supported by the spot market system
 */
library Transaction {
    error InvalidAsyncTransactionType(Type transactionType);

    enum Type {
        NULL, // reserved for 0 (default value)
        BUY,
        SELL,
        ASYNC_BUY,
        ASYNC_SELL,
        WRAP,
        UNWRAP
    }

    function validateAsyncTransaction(Type orderType) internal pure {
        if (orderType != Type.ASYNC_BUY && orderType != Type.ASYNC_SELL) {
            revert InvalidAsyncTransactionType(orderType);
        }
    }

    function isBuy(Type orderType) internal pure returns (bool) {
        return orderType == Type.BUY || orderType == Type.ASYNC_BUY;
    }

    function isSell(Type orderType) internal pure returns (bool) {
        return orderType == Type.SELL || orderType == Type.ASYNC_SELL;
    }

    function isWrapper(Type orderType) internal pure returns (bool) {
        return orderType == Type.WRAP || orderType == Type.UNWRAP;
    }

    function isAsync(Type orderType) internal pure returns (bool) {
        return orderType == Type.ASYNC_BUY || orderType == Type.ASYNC_SELL;
    }
}