/**
 *Submitted for verification at polygonscan.com on 2022-08-17
*/

// Sources flattened with hardhat v2.9.9 https://hardhat.org

// File @chainlink/contracts/src/v0.8/interfaces/[email protected]
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

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


// File @openzeppelin/contracts/utils/[email protected]

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


// File @openzeppelin/contracts/access/[email protected]

// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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


// File @openzeppelin/contracts/token/ERC20/[email protected]

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


// File @openzeppelin/contracts/utils/introspection/[email protected]

// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}


// File @openzeppelin/contracts/token/ERC721/[email protected]

// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
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
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
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
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
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
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}


// File @openzeppelin/contracts/token/ERC721/[email protected]

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


// File @openzeppelin/contracts/utils/math/[email protected]

// OpenZeppelin Contracts v4.4.1 (utils/math/SafeCast.sol)

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= type(int128).min && value <= type(int128).max, "SafeCast: value doesn't fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= type(int64).min && value <= type(int64).max, "SafeCast: value doesn't fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= type(int32).min && value <= type(int32).max, "SafeCast: value doesn't fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= type(int16).min && value <= type(int16).max, "SafeCast: value doesn't fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= type(int8).min && value <= type(int8).max, "SafeCast: value doesn't fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}


// File @openzeppelin/contracts/security/[email protected]

// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}


// File src/contracts/enums/IDrissEnums.sol

pragma solidity ^0.8.7;

enum AssetType {
    Coin,
    Token,
    NFT
}


// File src/contracts/interfaces/ISendToHash.sol

pragma solidity ^0.8.7;

interface ISendToHash {
    function sendToAnyone (
        bytes32 _IDrissHash,
        uint256 _amount,
        AssetType _assetType,
        address _assetContractAddress,
        uint256 _assetId,
        string memory _message
    ) external payable;

    function claim (
        string memory _IDrissHash,
        string memory _claimPassword,
        AssetType _assetType,
        address _assetContractAddress
    ) external;

    function revertPayment (
        bytes32 _IDrissHash,
        AssetType _assetType,
        address _assetContractAddress
    ) external;

    function moveAssetToOtherHash (
        bytes32 _FromIDrissHash,
        bytes32 _ToIDrissHash,
        AssetType _assetType,
        address _assetContractAddress
    ) external;

    function balanceOf (
        bytes32 _IDrissHash,
        AssetType _assetType,
        address _assetContractAddress
    ) external view returns (uint256);

    function hashIDrissWithPassword (
        string memory  _IDrissHash,
        string memory _claimPassword
    ) external pure returns (bytes32);

    function getPaymentFee(
        uint256 _value,
        AssetType _assetType
    ) external view returns (uint256);
}


// File src/contracts/interfaces/IIDrissRegistry.sol

pragma solidity ^0.8.7;

interface IIDrissRegistry {
    function getIDriss(string memory hashPub) external view returns (string memory);
    function IDrissOwners(string memory _address) external view returns (address);
}


// File src/contracts/structs/IDrissStructs.sol

pragma solidity ^0.8.7;

struct AssetLiability {
    uint256 amount;
    // IMPORTANT - when deleting AssetLiability, please remove assetIds array first. Reference:
    // https://github.com/crytic/slither/wiki/Detector-Documentation#deletion-on-mapping-containing-a-structure
    mapping (address => uint256[]) assetIds;
}


// File src/contracts/libs/ConversionUtils.sol

pragma solidity ^0.8.7;

//TODO: add documentation
library ConversionUtils {
    /**
    * @notice Change a single character from ASCII to 0-F hex value; revert on unparseable value
    */
    function fromHexChar(uint8 c) internal pure returns (uint8) {
        if (bytes1(c) >= bytes1('0') && bytes1(c) <= bytes1('9')) {
            return c - uint8(bytes1('0'));
        } else if (bytes1(c) >= bytes1('a') && bytes1(c) <= bytes1('f')) {
            return 10 + c - uint8(bytes1('a'));
        } else if (bytes1(c) >= bytes1('A') && bytes1(c) <= bytes1('F')) {
            return 10 + c - uint8(bytes1('A'));
        } else {
            revert("Unparseable hex character found in address.");
        }
    }

    /**
    * @notice Get address from string. Revert if address is invalid.
    */    
    function safeHexStringToAddress(string memory s) internal pure returns (address) {
        bytes memory ss = bytes(s);
        require(ss.length == 42, "Address length is invalid");
        bytes memory _bytes = new bytes(ss.length / 2);
        address resultAddress;

        for (uint256 i = 1; i < ss.length / 2; i++) {
            _bytes[i] = bytes1(fromHexChar(uint8(ss[2*i])) * 16 +
                        fromHexChar(uint8(ss[2*i+1])));
        }

        assembly {
            resultAddress := div(mload(add(add(_bytes, 0x20), 1)), 0x1000000000000000000000000)
        }

        return resultAddress;
    }
}


// File src/contracts/SendToHash.sol

pragma solidity ^0.8.7;











/**
 * @title SendToHash
 * @author Rafał Kalinowski
 * @notice This contract is used to pay to the IDriss address without a need for it to be registered
 */
contract SendToHash is ISendToHash, Ownable, ReentrancyGuard, IERC721Receiver, IERC165 {
    using SafeCast for int256;

    // payer => beneficiaryHash => assetType => assetAddress => AssetLiability
    mapping(address => mapping(bytes32 => mapping(AssetType => mapping(address => AssetLiability)))) payerAssetMap;
    // beneficiaryHash => assetType => assetAddress => AssetLiability
    mapping(bytes32 => mapping(AssetType => mapping(address => AssetLiability))) beneficiaryAssetMap;
    // beneficiaryHash => assetType => assetAddress => payer[]
    mapping(bytes32 => mapping(AssetType => mapping(address => address[]))) beneficiaryPayersArray;
    // beneficiaryHash => assetType => assetAddress => payer => didPay
    mapping(bytes32 => mapping(AssetType => mapping(address => mapping(address => bool)))) beneficiaryPayersMap;

    AggregatorV3Interface internal immutable MATIC_USD_PRICE_FEED;
    address public immutable IDRISS_ADDR;
    uint256 public constant PAYMENT_FEE_SLIPPAGE_PERCENT = 5;
    uint256 public PAYMENT_FEE_PERCENTAGE = 10;
    uint256 public PAYMENT_FEE_PERCENTAGE_DENOMINATOR = 1000;
    uint256 public MINIMAL_PAYMENT_FEE = 1;
    uint256 public MINIMAL_PAYMENT_FEE_DENOMINATOR = 1;
    uint256 public paymentFeesBalance;

    event AssetTransferred(bytes32 indexed toHash, address indexed from,
        address indexed assetContractAddress, uint256 amount, AssetType assetType, string message);
    event AssetMoved(bytes32 indexed fromHash, bytes32 indexed toHash,
        address indexed from, address assetContractAddress, AssetType assetType);
    event AssetClaimed(bytes32 indexed toHash, address indexed beneficiary,
        address indexed assetContractAddress, uint256 amount, AssetType assetType);
    event AssetTransferReverted(bytes32 indexed toHash, address indexed from,
        address indexed assetContractAddress, uint256 amount, AssetType assetType);

    constructor( address _IDrissAddr, address _maticUsdAggregator) {
        _checkNonZeroAddress(_IDrissAddr, "IDriss address cannot be 0");
        _checkNonZeroAddress(_IDrissAddr, "Matic price feed address cannot be 0");

        IDRISS_ADDR = _IDrissAddr;
        MATIC_USD_PRICE_FEED = AggregatorV3Interface(_maticUsdAggregator);
    }

    /**
     * @notice This function allows a user to send tokens or coins to other IDriss. They are
     *         being kept in an escrow until it's claimed by beneficiary or reverted by payer
     * @dev Note that you have to approve this contract address in ERC to handle them on user's behalf.
     *      It's best to approve contract by using non standard function just like
     *      `increaseAllowance` in OpenZeppelin to mitigate risk of race condition and double spend.
     */
    function sendToAnyone (
        bytes32 _IDrissHash,
        uint256 _amount,
        AssetType _assetType,
        address _assetContractAddress,
        uint256 _assetId,
        string memory _message
    ) external override nonReentrant() payable {
        address adjustedAssetAddress = _adjustAddress(_assetContractAddress, _assetType);
        (uint256 fee, uint256 paymentValue) = _splitPayment(msg.value);
        if (_assetType != AssetType.Coin) { fee = msg.value; }
        if (_assetType == AssetType.Token) { paymentValue = _amount; }
        if (_assetType == AssetType.NFT) { paymentValue = 1; }

        setStateForSendToAnyone(_IDrissHash, paymentValue, fee, _assetType, _assetContractAddress, _assetId);

        if (_assetType == AssetType.Token) {
            _sendTokenAssetFrom(paymentValue, msg.sender, address(this), _assetContractAddress);
        } else if (_assetType == AssetType.NFT) {
            uint256 [] memory assetIds = new uint[](1);
            assetIds[0] = _assetId;
            _sendNFTAsset(assetIds, msg.sender, address(this), _assetContractAddress);
        }

        emit AssetTransferred(_IDrissHash, msg.sender, adjustedAssetAddress, paymentValue, _assetType, _message);
    }

    /**
     * @notice Sets state for sendToAnyone function invocation
     */
    function setStateForSendToAnyone (
        bytes32 _IDrissHash,
        uint256 _amount,
        uint256 _fee,
        AssetType _assetType,
        address _assetContractAddress,
        uint256 _assetId
    ) internal {
        address adjustedAssetAddress = _adjustAddress(_assetContractAddress, _assetType);

        AssetLiability storage beneficiaryAsset = beneficiaryAssetMap[_IDrissHash][_assetType][adjustedAssetAddress];
        AssetLiability storage payerAsset = payerAssetMap[msg.sender][_IDrissHash][_assetType][adjustedAssetAddress];


        if (_assetType == AssetType.Coin) {
            _checkNonZeroValue(_amount, "Transferred value has to be bigger than 0");
        } else {
            _checkNonZeroValue(_amount, "Asset amount has to be bigger than 0");
            _checkNonZeroAddress(_assetContractAddress, "Asset address cannot be 0");
            require(_isContract(_assetContractAddress), "Asset address is not a contract");
        }

        if (!beneficiaryPayersMap[_IDrissHash][_assetType][adjustedAssetAddress][msg.sender]) {
            beneficiaryPayersArray[_IDrissHash][_assetType][adjustedAssetAddress].push(msg.sender);
            beneficiaryPayersMap[_IDrissHash][_assetType][adjustedAssetAddress][msg.sender] = true;
        }

        if (_assetType == AssetType.NFT) { _amount = 1; }
        beneficiaryAsset.amount += _amount;
        payerAsset.amount += _amount;
        paymentFeesBalance += _fee;

        if (_assetType == AssetType.NFT) {
            beneficiaryAsset.assetIds[msg.sender].push(_assetId);
            payerAsset.assetIds[msg.sender].push(_assetId);
        }
    }

    /**
     * @notice Calculates payment fee 
     * @param _value - payment value
     * @param _assetType - asset type, required as ERC20 & ERC721 only take minimal fee
     * @return fee - processing fee, few percent of slippage is allowed
     */
    function getPaymentFee(uint256 _value, AssetType _assetType) public view override returns (uint256) {
        uint256 minimumPaymentFee = _getMinimumFee();
        if (_assetType == AssetType.Token || _assetType == AssetType.NFT) {
            return minimumPaymentFee;
        }

        uint256 percentageFee = _getPercentageFee(_value);
        if (percentageFee > minimumPaymentFee) return percentageFee; else return minimumPaymentFee;
    }

    function _getMinimumFee() internal view returns (uint256) {
        return (_dollarToWei() * MINIMAL_PAYMENT_FEE) / MINIMAL_PAYMENT_FEE_DENOMINATOR;
    }

    function _getPercentageFee(uint256 _value) internal view returns (uint256) {
        return (_value * PAYMENT_FEE_PERCENTAGE) / PAYMENT_FEE_PERCENTAGE_DENOMINATOR;
    }

    /**
     * @notice Calculates value of a fee from sent msg.value
     * @param _value - payment value, taken from msg.value 
     * @return fee - processing fee, few percent of slippage is allowed
     * @return value - payment value after substracting fee
     */
    function _splitPayment(uint256 _value) internal view returns (uint256 fee, uint256 value) {
        uint256 minimalPaymentFee = _getMinimumFee();
        uint256 feeFromValue = _getPercentageFee(_value);

        if (feeFromValue > minimalPaymentFee) {
            fee = feeFromValue;
        // we accept slippage of matic price
        } else if (_value >= minimalPaymentFee * (100 - PAYMENT_FEE_SLIPPAGE_PERCENT) / 100
                        && _value <= minimalPaymentFee) {
            fee = _value;
        } else {
            fee = minimalPaymentFee;
        }

        require (_value >= fee, "Value sent is smaller than minimal fee.");

        value = _value - fee;
    }

    /**
     * @notice Allows claiming assets by an IDriss owner
     */
    function claim (
        string memory _IDrissHash,
        string memory _claimPassword,
        AssetType _assetType,
        address _assetContractAddress
    ) external override nonReentrant() {
        address ownerIDrissAddr = _getAddressFromHash(_IDrissHash);
        bytes32 hashWithPassword = hashIDrissWithPassword(_IDrissHash, _claimPassword);

        address adjustedAssetAddress = _adjustAddress(_assetContractAddress, _assetType);
        AssetLiability storage beneficiaryAsset = beneficiaryAssetMap[hashWithPassword][_assetType][adjustedAssetAddress];
        address [] memory payers = beneficiaryPayersArray[hashWithPassword][_assetType][adjustedAssetAddress];
        uint256 amountToClaim = beneficiaryAsset.amount;

        _checkNonZeroValue(amountToClaim, "Nothing to claim.");
        require(ownerIDrissAddr == msg.sender, "Only owner can claim payments.");
 
        beneficiaryAsset.amount = 0;

        for (uint256 i = 0; i < payers.length; i++) {
            beneficiaryPayersArray[hashWithPassword][_assetType][adjustedAssetAddress].pop();
            delete payerAssetMap[payers[i]][hashWithPassword][_assetType][adjustedAssetAddress].assetIds[payers[i]];
            delete payerAssetMap[payers[i]][hashWithPassword][_assetType][adjustedAssetAddress];
            delete beneficiaryPayersMap[hashWithPassword][_assetType][adjustedAssetAddress][payers[i]];
            if (_assetType == AssetType.NFT) {
                uint256[] memory assetIds = beneficiaryAsset.assetIds[payers[i]];
                delete beneficiaryAsset.assetIds[payers[i]];
                _sendNFTAsset(assetIds, address(this), ownerIDrissAddr, _assetContractAddress);
            }
        }

        delete beneficiaryAssetMap[hashWithPassword][_assetType][adjustedAssetAddress];

        if (_assetType == AssetType.Coin) {
            _sendCoin(ownerIDrissAddr, amountToClaim);
        } else if (_assetType == AssetType.Token) {
            _sendTokenAsset(amountToClaim, ownerIDrissAddr, _assetContractAddress);
        }

        emit AssetClaimed(hashWithPassword, ownerIDrissAddr, adjustedAssetAddress, amountToClaim, _assetType);
    }

    /**
     * @notice Get balance of given asset for IDrissHash
     */
    function balanceOf (
        bytes32 _IDrissHash,
        AssetType _assetType,
        address _assetContractAddress
    ) external override view returns (uint256) {
        address adjustedAssetAddress = _adjustAddress(_assetContractAddress, _assetType);
        return beneficiaryAssetMap[_IDrissHash][_assetType][adjustedAssetAddress].amount;
    }

    /**
     * @notice Reverts sending tokens to an IDriss hash and claim them back
     */
    function revertPayment (
        bytes32 _IDrissHash,
        AssetType _assetType,
        address _assetContractAddress
    ) external override nonReentrant() {
        address adjustedAssetAddress = _adjustAddress(_assetContractAddress, _assetType);
        uint256[] memory assetIds = beneficiaryAssetMap[_IDrissHash][_assetType][adjustedAssetAddress].assetIds[msg.sender];
        uint256 amountToRevert = setStateForRevertPayment(_IDrissHash, _assetType, _assetContractAddress);

        if (_assetType == AssetType.Coin) {
            _sendCoin(msg.sender, amountToRevert);
        } else if (_assetType == AssetType.Token) {
            _sendTokenAsset(amountToRevert, msg.sender, _assetContractAddress);
        } else if (_assetType == AssetType.NFT) {
            _sendNFTAsset(assetIds, address(this), msg.sender, _assetContractAddress);
        } 

        emit AssetTransferReverted(_IDrissHash, msg.sender, adjustedAssetAddress, amountToRevert, _assetType);
    }

    /**
     * @notice Sets the state for reverting the payment for a user
     */
    function setStateForRevertPayment (
        bytes32 _IDrissHash,
        AssetType _assetType,
        address _assetContractAddress
    ) internal returns(uint256 amountToRevert) {
        address adjustedAssetAddress = _adjustAddress(_assetContractAddress, _assetType);
        amountToRevert = payerAssetMap[msg.sender][_IDrissHash][_assetType][adjustedAssetAddress].amount;
        AssetLiability storage beneficiaryAsset = beneficiaryAssetMap[_IDrissHash][_assetType][adjustedAssetAddress];

        _checkNonZeroValue(amountToRevert, "Nothing to revert.");

        delete payerAssetMap[msg.sender][_IDrissHash][_assetType][adjustedAssetAddress].assetIds[msg.sender];
        delete payerAssetMap[msg.sender][_IDrissHash][_assetType][adjustedAssetAddress];
        beneficiaryAsset.amount -= amountToRevert;

        address [] storage payers = beneficiaryPayersArray[_IDrissHash][_assetType][adjustedAssetAddress];

        for (uint256 i = 0; i < payers.length; i++) {
            if (msg.sender == payers[i]) {
                delete beneficiaryPayersMap[_IDrissHash][_assetType][adjustedAssetAddress][payers[i]];
                if (_assetType == AssetType.NFT) {
                    delete beneficiaryAsset.assetIds[payers[i]];
                }
                payers[i] = payers[payers.length - 1];
                payers.pop();
            }
        }

        if (_assetType == AssetType.NFT) {
            delete beneficiaryAsset.assetIds[msg.sender];
        }
}

    /**
     * @notice This function allows a user to move tokens or coins they already sent to other IDriss
     */
    function moveAssetToOtherHash (
        bytes32 _FromIDrissHash,
        bytes32 _ToIDrissHash,
        AssetType _assetType,
        address _assetContractAddress
    ) external override nonReentrant() {
        address adjustedAssetAddress = _adjustAddress(_assetContractAddress, _assetType);
        uint256[] memory assetIds = beneficiaryAssetMap[_FromIDrissHash][_assetType][adjustedAssetAddress].assetIds[msg.sender];
        uint256 _amount = setStateForRevertPayment(_FromIDrissHash, _assetType, _assetContractAddress);

        _checkNonZeroValue(_amount, "Nothing to transfer");

        if (_assetType == AssetType.NFT) {
            for (uint256 i = 0; i < assetIds.length; i++) {
                setStateForSendToAnyone(_ToIDrissHash, _amount, 0, _assetType, _assetContractAddress, assetIds[i]);
            }
        } else {
            setStateForSendToAnyone(_ToIDrissHash, _amount, 0, _assetType, _assetContractAddress, 0);
        }

        emit AssetMoved(_FromIDrissHash, _ToIDrissHash, msg.sender, adjustedAssetAddress, _assetType);
    }

    /**
     * @notice Claim fees gathered from sendToAnyone(). Only owner can execute this function
     */
    function claimPaymentFees() onlyOwner external {
        uint256 amountToClaim = paymentFeesBalance;
        paymentFeesBalance = 0;

        _sendCoin(msg.sender, amountToClaim);
    }

    /**
    * @notice Wrapper for sending native Coin via call function
    * @dev When using this function please make sure to not send it to anyone, verify the
    *      address in IDriss registry
    */
    function _sendCoin (address _to, uint256 _amount) internal {
        (bool sent, ) = payable(_to).call{value: _amount}("");
        require(sent, "Failed to withdraw");
    }

    /**
     * @notice Wrapper for sending NFT asset with additional checks and iteraton over an array
     */
    function _sendNFTAsset (
        uint256[] memory _assetIds,
        address _from,
        address _to,
        address _contractAddress
    ) internal {
        require(_assetIds.length > 0, "Nothing to send");

        IERC721 nft = IERC721(_contractAddress);
        for (uint256 i = 0; i < _assetIds.length; i++) {
            nft.safeTransferFrom(_from, _to, _assetIds[i], "");
        }
    }

    /**
     * @notice Wrapper for sending ERC20 Token asset with additional checks
     */
    function _sendTokenAsset (
        uint256 _amount,
        address _to,
        address _contractAddress
    ) internal {
        IERC20 token = IERC20(_contractAddress);

        bool sent = token.transfer(_to, _amount);
        require(sent, "Failed to transfer token");
    }

    /**
     * @notice Wrapper for sending ERC20 token from specific account with additional checks and iteraton over an array
     */
    function _sendTokenAssetFrom (
        uint256 _amount,
        address _from,
        address _to,
        address _contractAddress
    ) internal {
        IERC20 token = IERC20(_contractAddress);

        bool sent = token.transferFrom(_from, _to, _amount);
        require(sent, "Failed to transfer token");
    }

    /**
    * @notice Check if an address is a deployed contract
    * @dev IMPORTANT!! This function is used for very specific reason, i.e. to check
    *      if ERC20 or ERC721 is already deployed before trying to interact with it.
    *      It should not be used to detect if msg.sender is an user, as any code run
    *      in a contructor has code size of 0
    */    
    function _isContract(address addr) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }

    /**
    * @notice Helper function to set asset address to 0 for coins for asset mapping
    */
    function _adjustAddress(address _addr, AssetType _assetType)
        internal
        pure
        returns (address) {
            if (_assetType == AssetType.Coin) {
                return address(0);
            }
            return _addr;
    }

    /**
    * @notice Helper function to retrieve address string from IDriss hash and transforming it into address type
    */
    function _getAddressFromHash (string memory _IDrissHash)
        internal
        view
        returns (address IDrissAddress)
    {
        string memory IDrissString = IIDrissRegistry(IDRISS_ADDR).getIDriss(_IDrissHash);
        require(bytes(IDrissString).length > 0, "IDriss not found.");
        IDrissAddress = ConversionUtils.safeHexStringToAddress(IDrissString);
        _checkNonZeroAddress(IDrissAddress, "Address for the IDriss hash cannot resolve to 0x0");
    }

    /*
    * @notice Get current amount of wei in a dollar
    * @dev ChainLink officially supports only USD -> MATIC,
    *      so we have to convert it back to get current amount of wei in a dollar
    */
    function _dollarToWei() internal view returns (uint256) {
        (,int256 maticPrice,,,) = MATIC_USD_PRICE_FEED.latestRoundData();
        require (maticPrice > 0, "Unable to retrieve MATIC price.");

        uint256 maticPriceMultiplier = 10**MATIC_USD_PRICE_FEED.decimals();

        return(10**18 * maticPriceMultiplier) / uint256(maticPrice);
    }

    /**
    * @notice Helper function to check if address is non-zero. Reverts with passed message in that casee.
    */
    function _checkNonZeroAddress (address _addr, string memory message) internal pure {
        require(_addr != address(0), message);
    }

    /**
    * @notice Helper function to check if value is bigger than 0. Reverts with passed message in that casee.
    */
    function _checkNonZeroValue (uint256 _value, string memory message) internal pure {
        require(_value > 0, message);
    }

    /**
    * @notice adjust payment fee percentage for big native currenct transfers
    * @dev Solidity is not good when it comes to handling floats. We use denominator then, 
    *      e.g. to set payment fee to 1.5% , just pass paymentFee = 15 & denominator = 1000 => 15 / 1000 = 0.015 = 1.5%
    */
    function changePaymentFeePercentage (uint256 _paymentFeePercentage, uint256 _paymentFeeDenominator) external onlyOwner {
        _checkNonZeroValue(_paymentFeePercentage, "Payment fee has to be bigger than 0");
        _checkNonZeroValue(_paymentFeeDenominator, "Payment fee denominator has to be bigger than 0");

        PAYMENT_FEE_PERCENTAGE = _paymentFeePercentage;
        PAYMENT_FEE_PERCENTAGE_DENOMINATOR = _paymentFeeDenominator;
    }

    /**
    * @notice adjust minimal payment fee for all asset transfers
    * @dev Solidity is not good when it comes to handling floats. We use denominator then, 
    *      e.g. to set minimal payment fee to 2.2$ , just pass paymentFee = 22 & denominator = 10 => 22 / 10 = 2.2
    */
    function changeMinimalPaymentFee (uint256 _minimalPaymentFee, uint256 _paymentFeeDenominator) external onlyOwner {
        _checkNonZeroValue(_minimalPaymentFee, "Payment fee has to be bigger than 0");
        _checkNonZeroValue(_paymentFeeDenominator, "Payment fee denominator has to be bigger than 0");

        MINIMAL_PAYMENT_FEE = _minimalPaymentFee;
        MINIMAL_PAYMENT_FEE_DENOMINATOR = _paymentFeeDenominator;
    }

    /**
    * @notice Get bytes32 hash of IDriss and password. It's used to obfuscate real IDriss that received a payment until the owner claims it.
    *         Because it's a pure function, it won't be visible in mempool, and it's safe to execute.
    */
    function hashIDrissWithPassword (
        string memory  _IDrissHash,
        string memory _claimPassword
    ) public pure override returns (bytes32) {
        return keccak256(abi.encodePacked(_IDrissHash, _claimPassword));
    }

    /*
    * @notice Always reverts. By default Ownable supports renouncing ownership, that is setting owner to address 0.
    *         However in this case it would disallow receiving payment fees by anyone.
    */
    function renounceOwnership() public override view onlyOwner {
        revert("Renouncing ownership is not supported");
    }

   function onERC721Received (
        address,
        address,
        uint256,
        bytes calldata
    ) external override pure returns (bytes4) {
       return IERC721Receiver.onERC721Received.selector;
    }

    function supportsInterface (bytes4 interfaceId) public pure override returns (bool) {
        return interfaceId == type(IERC165).interfaceId
         || interfaceId == type(IERC721Receiver).interfaceId
         || interfaceId == type(ISendToHash).interfaceId;
    }
}