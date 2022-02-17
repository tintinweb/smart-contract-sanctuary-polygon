/**
 *Submitted for verification at polygonscan.com on 2022-02-17
*/

// Sources flattened with hardhat v2.8.4 https://hardhat.org

// File @openzeppelin/contracts/utils/introspection/[email protected]

// SPDX-License-Identifier: MIT
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

// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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
}


// File @openzeppelin/contracts/token/ERC721/extensions/[email protected]

// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}


// File contracts/IWearableCollection.sol

pragma solidity ^0.8.0;


abstract contract IWearableCollection is IERC721, IERC721Enumerable {

    struct Item {
        string rarity;
        uint256 maxSupply; 
        uint256 totalSupply; 
        uint256 price;
        address beneficiary;
        string metadata;
        string contentHash; 
    }

    bool public isApproved;
    
    function decodeTokenId(uint256 _id) external pure virtual returns (uint256 itemId, uint256 issuedId);
    Item[] public items;

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


// File @openzeppelin/contracts/security/[email protected]

// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

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
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
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
        require(paused(), "Pausable: not paused");
        _;
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


// File @openzeppelin/contracts/token/ERC20/[email protected]

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


// File @openzeppelin/contracts/utils/math/[email protected]

// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
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


// File contracts/IERC721CollectionFactoryV2.sol

pragma solidity ^0.8.0;

abstract contract IERC721CollectionFactoryV2 {

    mapping(address => bool) public isCollectionFromFactory;

}


// File contracts/IRarity.sol

pragma solidity ^0.8.0;

struct Rarity {

    string name;
    uint256 maxSupply;
    uint256 price;
    
}

abstract contract IRarity {

    function getRarityByName(string memory _rarity) public virtual view returns (Rarity memory);

}


// File contracts/String.sol


pragma solidity >=0.6.12;

library String {

    /**
     * @dev Convert bytes32 to string.
     * @param _x - to be converted to string.
     * @return string
     */
    function bytes32ToString(bytes32 _x) internal pure returns (string memory) {
        bytes memory bytesString = new bytes(32);
        uint charCount = 0;
        for (uint j = 0; j < 32; j++) {
            bytes1 currentChar = bytes1(bytes32(uint(_x) * 2 ** (8 * j)));
            if (currentChar != 0) {
                bytesString[charCount] = currentChar;
                charCount++;
            }
        }
        bytes memory bytesStringTrimmed = new bytes(charCount);
        for (uint j = 0; j < charCount; j++) {
            bytesStringTrimmed[j] = bytesString[j];
        }
        return string(bytesStringTrimmed);
    }

    /**
     * @dev Convert uint to string.
     * @param _i - uint256 to be converted to string.
     * @return _uintAsString uint in string
     */
    function uintToString(uint _i) internal pure returns (string memory _uintAsString) {
        uint i = _i;

        if (i == 0) {
            return "0";
        }
        uint j = i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len - 1;
        while (i != 0) {
            bstr[k--] = bytes1(uint8(48 + i % 10));
            i /= 10;
        }
        return string(bstr);
    }

    /**
     * @dev Convert an address to string.
     * @param _x - address to be converted to string.
     * @return string representation of the address
     */
    function addressToString(address _x) internal pure returns (string memory) {
        bytes memory s = new bytes(40);
        for (uint i = 0; i < 20; i++) {
            bytes1 b = bytes1(uint8(uint160(_x) / (2**(8*(19 - i)))));
            bytes1 hi = bytes1(uint8(b) / 16);
            bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
            s[2*i] = char(hi);
            s[2*i+1] = char(lo);
        }
        return string(s);
    }

    function char(bytes1 b) internal pure returns (bytes1 c) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
    }

    /**
     * @dev Lowercase a string.
     * @param _str - to be converted to string.
     * @return string
     */
    function toLowerCase(string memory _str) internal pure returns (string memory) {
        bytes memory bStr = bytes(_str);
        bytes memory bLower = new bytes(bStr.length);

        for (uint i = 0; i < bStr.length; i++) {
            // Uppercase character...
            if ((bStr[i] >= 0x41) && (bStr[i] <= 0x5A)) {
                // So we add 0x20 to make it lowercase
                bLower[i] = bytes1(uint8(bStr[i]) + 0x20);
            } else {
                bLower[i] = bStr[i];
            }
        }
        return string(bLower);
    }
}


// File contracts/ContextMixin.sol


pragma solidity ^0.8.0;


abstract contract ContextMixin {
    function _msgSender()
        internal
        view
        virtual
        returns (address sender)
    {
        if (msg.sender == address(this)) {
            bytes memory array = msg.data;
            uint256 index = msg.data.length;
            assembly {
                // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
                sender := and(
                    mload(add(array, index)),
                    0xffffffffffffffffffffffffffffffffffffffff
                )
            }
        } else {
            sender = msg.sender;
        }
        return sender;
    }
}


// File contracts/EIP712Base.sol


pragma solidity ^0.8.0;


contract EIP712Base {
    struct EIP712Domain {
        string name;
        string version;
        address verifyingContract;
        bytes32 salt;
    }

    bytes32 internal constant EIP712_DOMAIN_TYPEHASH = keccak256(
        bytes(
            "EIP712Domain(string name,string version,address verifyingContract,bytes32 salt)"
        )
    );
    bytes32 public domainSeparator;

    // supposed to be called once while initializing.
    // one of the contractsa that inherits this contract follows proxy pattern
    // so it is not possible to do this in a constructor
    function _initializeEIP712(
        string memory name,
        string memory version
    )
        internal
    {
        domainSeparator = keccak256(
            abi.encode(
                EIP712_DOMAIN_TYPEHASH,
                keccak256(bytes(name)),
                keccak256(bytes(version)),
                address(this),
                bytes32(getChainId())
            )
        );
    }

    function getChainId() public view returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }

    /**
     * Accept message hash and returns hash message in EIP712 compatible form
     * So that it can be used to recover signer from signature signed using EIP712 formatted data
     * https://eips.ethereum.org/EIPS/eip-712
     * "\\x19" makes the encoding deterministic
     * "\\x01" is the version byte to make it compatible to EIP-191
     */
    function toTypedMessageHash(bytes32 messageHash)
        internal
        view
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked("\x19\x01", domainSeparator, messageHash)
            );
    }
}


// File contracts/NativeMetaTransaction.sol


pragma solidity ^0.8.0;

contract NativeMetaTransaction is EIP712Base {
    using SafeMath for uint256;
    bytes32 private constant META_TRANSACTION_TYPEHASH = keccak256(
        bytes(
            "MetaTransaction(uint256 nonce,address from,bytes functionSignature)"
        )
    );
    event MetaTransactionExecuted(
        address userAddress,
        address relayerAddress,
        bytes functionSignature
    );
    mapping(address => uint256) nonces;

    struct MetaTransaction {
        uint256 nonce;
        address from;
        bytes functionSignature;
    }

    function executeMetaTransaction(
        address userAddress,
        bytes memory functionSignature,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    ) external payable returns (bytes memory) {
        MetaTransaction memory metaTx = MetaTransaction({
            nonce: nonces[userAddress],
            from: userAddress,
            functionSignature: functionSignature
        });

        require(
            verify(userAddress, metaTx, sigR, sigS, sigV),
            "NMT#executeMetaTransaction: SIGNER_AND_SIGNATURE_DO_NOT_MATCH"
        );

        // increase nonce for user (to avoid re-use)
        nonces[userAddress] = nonces[userAddress].add(1);

        emit MetaTransactionExecuted(
            userAddress,
            msg.sender,
            functionSignature
        );

        // Append userAddress and relayer address at the end to extract it from calling context
        (bool success, bytes memory returnData) = address(this).call{value: msg.value}(
            abi.encodePacked(functionSignature, userAddress)
        );
        require(success, "NMT#executeMetaTransaction: CALL_FAILED");

        return returnData;
    }

    function hashMetaTransaction(MetaTransaction memory metaTx)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(
                    META_TRANSACTION_TYPEHASH,
                    metaTx.nonce,
                    metaTx.from,
                    keccak256(metaTx.functionSignature)
                )
            );
    }

    function getNonce(address user) external view returns (uint256 nonce) {
        nonce = nonces[user];
    }

    function verify(
        address signer,
        MetaTransaction memory metaTx,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    ) internal view returns (bool) {
        require(signer != address(0), "NMT#verify: INVALID_SIGNER");
        return
            signer ==
            ecrecover(
                toTypedMessageHash(hashMetaTransaction(metaTx)),
                sigV,
                sigR,
                sigS
            );
    }
}


// File contracts/Marketplace.sol

pragma solidity ^0.8.0;










contract Marketplace is Ownable, Pausable, ReentrancyGuard, NativeMetaTransaction {

    using SafeMath for uint256;

    struct ItemMarketRate {
        uint256 purchaseAmount;
        uint256 refundAmount;
    }

    struct WearableNFT {
        address collection;
        uint256 tokenId;
        bool marketplaceApproved;
    }

    address payable vaultAddress;
    IERC20 public MTVRS; 
    IERC721CollectionFactoryV2 public erc721CollectionFactoryV2;
    IRarity public rarityContract; 

    address[] public approvedWearableCollections;
    mapping (address => bool) public wearableCollectionAdded;

    mapping (string => ItemMarketRate) private itemMarketRates;

    event Purchase(address indexed _customerAddress, address indexed _wearableCollection, uint256 indexed _tokenId, uint256 _price);
    event Refund(address indexed _customerAddress, address indexed _wearableCollection, uint256 indexed _tokenId, uint256 _price);
    event Exchange(address indexed _customerAddress, address indexed _wearableCollection, uint256 _tokenIdCustomer, uint256 _tokenIdVault);
    event CollectionAdded(address indexed _wearableCollection);
    event CollectionRemoved(address indexed _wearableCollection);
    event PurchaseAmountUpdated(string indexed _rarity, uint256 _purchaseAmount);
    event RefundAmountUpdated(string indexed _rarity, uint256 _returnAmount);
    
    constructor(address payable _vaultAddress, address _tokenAddress){

        _initializeEIP712("Marketplace", "1");
        
        updateVaultAddress(_vaultAddress);

        MTVRS = IERC20(_tokenAddress);
        erc721CollectionFactoryV2 = IERC721CollectionFactoryV2(0xB549B2442b2BD0a53795BC5cDcBFE0cAF7ACA9f8);
        rarityContract = IRarity(0x17113b44fdd661A156cc01b5031E3aCF72c32EB3);

        updatePurchaseAmount("common", 1 ether);
        updatePurchaseAmount("uncommon", 2 ether);
        updatePurchaseAmount("rare", 2.5 ether);
        updatePurchaseAmount("epic", 3 ether);
        updatePurchaseAmount("legendary", 4 ether);
        updatePurchaseAmount("mythic", 5 ether);
        updatePurchaseAmount("unique", 6 ether);

        updateRefundAmount("common", 0.75 ether);
        updateRefundAmount("uncommon", 1.5 ether);
        updateRefundAmount("rare", 1.875 ether);
        updateRefundAmount("epic", 2.25 ether);
        updateRefundAmount("legendary", 3 ether);
        updateRefundAmount("mythic", 3.75 ether);
        updateRefundAmount("unique", 4.5 ether);

    }

    /**
    * @notice Update Vault Address
    * @param _vaultAddress - Address of holding MTVRS tokens and Wearables
    */
    function updateVaultAddress(address payable _vaultAddress) public onlyOwner {

        require(_vaultAddress!=address(0),"Cannot update the vault to the zero address");
        require(_vaultAddress!=address(this),"Cannot set the vault to the contract");
        require(_vaultAddress!=_msgSender(),"Intentional separation of vault and contract owner");

        vaultAddress = _vaultAddress;

    }

    /**
    * @notice Add Wearable Collection
    * @param _wearableCollectionAddress - Address of wearable collection to add to the marketplace
    */
    function addWearableCollection(address _wearableCollectionAddress) public onlyOwner {

        require(_wearableCollectionAddress!=address(0),"Cannot add the zero address");
        require(!wearableCollectionAdded[_wearableCollectionAddress], "Collection already added");
        require(erc721CollectionFactoryV2.isCollectionFromFactory(_wearableCollectionAddress),"Collection must be created by the DCL Factory contract");
        
        IWearableCollection wearableCollection = IWearableCollection(_wearableCollectionAddress);
        require(wearableCollection.isApproved(),"Wearable collection must be approved by DCL wearable committe");
        require(wearableCollection.isApprovedForAll(vaultAddress,address(this)),"Marketplace must be approvedForAll on the wearable collection");

        wearableCollectionAdded[_wearableCollectionAddress] = true;
        approvedWearableCollections.push(_wearableCollectionAddress);

        emit CollectionAdded(_wearableCollectionAddress);
    }

    /**
    * @notice Remove Wearable Collection
    * @param _wearableCollectionAddress - Address of wearable collection to move from the marketplace
    */
    function removeWearableCollection(address _wearableCollectionAddress) public onlyOwner {
        require(wearableCollectionAdded[_wearableCollectionAddress], "Collection not in store");
        uint256 numCollections = approvedWearableCollections.length;

        for(uint256 i = 0; i < numCollections; i ++) {
            if(approvedWearableCollections[i]==_wearableCollectionAddress){
                approvedWearableCollections[i] = approvedWearableCollections[numCollections-1];
                approvedWearableCollections.pop();
            }
        }
        wearableCollectionAdded[_wearableCollectionAddress] = false;
        emit CollectionRemoved(_wearableCollectionAddress);
    }

    /**
    * @notice Update Purhcase Amount
    * @param _rarity - Rarity to be updated
    * @param _purchaseAmount - Amount of MTVRS tokens to purchase an item of this rarity 
    */
    function updatePurchaseAmount(string memory _rarity, uint256 _purchaseAmount) public onlyOwner() {
        string memory rarityLowerCase = String.toLowerCase(_rarity);
        Rarity memory rarityCheck = rarityContract.getRarityByName(rarityLowerCase);
        require(keccak256(bytes(rarityCheck.name)) == keccak256(bytes(rarityLowerCase)),"Rarity must be listed on rarity contract");
        require(_purchaseAmount > itemMarketRates[rarityLowerCase].refundAmount, "Cannot set purchase amount lower than the refund amount");
        itemMarketRates[rarityLowerCase].purchaseAmount = _purchaseAmount;
        emit PurchaseAmountUpdated(rarityLowerCase,_purchaseAmount);
    }

    /**
    * @notice Update Refund Amount
    * @param _rarity - Rarity to be updated
    * @param _refundAmount - Amount of MTVRS tokens given for a refund of an item of this rarity 
    */
    function updateRefundAmount(string memory _rarity, uint256 _refundAmount) public onlyOwner() {
        string memory rarityLowerCase = String.toLowerCase(_rarity);
        Rarity memory rarityCheck = rarityContract.getRarityByName(rarityLowerCase);
        require(keccak256(bytes(rarityCheck.name)) == keccak256(bytes(rarityLowerCase)),"Rarity must be listed on rarity contract");
        require(_refundAmount < itemMarketRates[rarityLowerCase].purchaseAmount, "Cannot set refund amount higher than the purchase amount");
        itemMarketRates[rarityLowerCase].refundAmount = _refundAmount;
        emit RefundAmountUpdated(rarityLowerCase,_refundAmount);
    }

    /**
    * @notice Purchase Wearable
    * @param _wearableCollectionAddress - Wearable collection address
    * @param _tokenId - Token ID on the specified wearable collection
    */
    function purchaseWearable(address _wearableCollectionAddress, uint256 _tokenId) public whenNotPaused() nonReentrant() {

        require(_msgSender()!=vaultAddress,"Vault cannot purchase wearables from the marketplace");
        require(wearableCollectionAdded[_wearableCollectionAddress],"Wearable collection not approved by marketplace");
    
        IWearableCollection wearableCollection = IWearableCollection(_wearableCollectionAddress);
        require(wearableCollection.ownerOf(_tokenId)==vaultAddress,"Wearable not owned by vault");

        uint256 purchaseAmount = getPurchaseAmountForItem(wearableCollection,_tokenId);

        require(MTVRS.allowance(_msgSender(),address(this))>=purchaseAmount,"Marketplace not approved to spend enough MTVRS tokens");
        require(MTVRS.balanceOf(_msgSender())>=purchaseAmount,"Not enough MTVRS tokens for purchase");
        
        MTVRS.transferFrom(_msgSender(),vaultAddress,purchaseAmount);
        wearableCollection.safeTransferFrom(vaultAddress,_msgSender(),_tokenId);

        emit Purchase(_msgSender(), _wearableCollectionAddress, _tokenId, purchaseAmount);
    }

    /**
    * @notice Refund Wearable
    * @param _wearableCollectionAddress - Wearable collection address
    * @param _tokenId - Token ID on the specified wearable collection
    */
    function returnWearable(address _wearableCollectionAddress, uint256 _tokenId) public whenNotPaused() nonReentrant() {

        require(_msgSender()!=vaultAddress,"Vault cannot return wearables to the marketplace");
        require(wearableCollectionAdded[_wearableCollectionAddress],"Wearable collection not approved by marketplace");

        IWearableCollection wearableCollection = IWearableCollection(_wearableCollectionAddress);
        require(wearableCollection.ownerOf(_tokenId)==_msgSender(),"Wearable not owned by customer");
        require(wearableCollection.isApprovedForAll(_msgSender(), address(this)),"Marketplace must be approved by customer to pull wearables");

        uint256 refundAmount = getRefundAmountForItem(wearableCollection,_tokenId);

        require(MTVRS.balanceOf(vaultAddress)>refundAmount,"Not enough MTVRS tokens in the vault");
        require(MTVRS.allowance(vaultAddress,address(this))>refundAmount,"Marketplace not approved to return enough MTVRS tokens");

        MTVRS.transferFrom(vaultAddress,_msgSender(),refundAmount);
        wearableCollection.safeTransferFrom(_msgSender(),vaultAddress,_tokenId);

        emit Refund(_msgSender(), _wearableCollectionAddress, _tokenId, refundAmount);
    }

    /**
    * @notice Exchange Wearable
    * @param _wearableCollectionAddress - Wearable collection address
    * @param _tokenIdVault - Token ID owned by the Vault Address on the specified wearable collection
    * @param _tokenIdCustomer- Token ID owned by the Sender on the specified wearable collection
    */
    function exchangeWearable(address _wearableCollectionAddress, uint256 _tokenIdVault, uint256 _tokenIdCustomer) public whenNotPaused() nonReentrant() {

        require(_msgSender()!=vaultAddress,"Vault cannot return wearables to the marketplace");
        require(wearableCollectionAdded[_wearableCollectionAddress],"Wearable collection not approved by marketplace");

        IWearableCollection wearableCollection = IWearableCollection(_wearableCollectionAddress);
        require(wearableCollection.ownerOf(_tokenIdCustomer)==_msgSender(),"Wearable not owned by customer");
        require(wearableCollection.ownerOf(_tokenIdVault)==vaultAddress,"Wearable not owned by vault");
        require(wearableCollection.isApprovedForAll(_msgSender(), address(this)),"Marketplace must be approved by customer to pull wearables");
        require(wearableCollection.isApprovedForAll(vaultAddress, address(this)),"Marketplace must be approved by vault to pull wearables");

        uint256 exchangeValueCustomer = getPurchaseAmountForItem(wearableCollection, _tokenIdCustomer);
        uint256 exchangeValueVault = getPurchaseAmountForItem(wearableCollection, _tokenIdVault);

        require(exchangeValueCustomer >= exchangeValueVault,"Exchange value must equal or exceed value of item in marketplace");

        wearableCollection.safeTransferFrom(_msgSender(),vaultAddress,_tokenIdCustomer);
        wearableCollection.safeTransferFrom(vaultAddress,_msgSender(),_tokenIdVault);

        emit Exchange(_msgSender(), _wearableCollectionAddress, _tokenIdCustomer, _tokenIdVault);
    }

    
    /**
    * @notice Get Item Market Rates
    * @param _wearableCollection - Wearable collection address
    * @param _tokenId - Token ID on the specified wearable collection
    */
    function getItemMarketRateForItem(IWearableCollection _wearableCollection, uint256 _tokenId) public view returns (ItemMarketRate memory) {
    
        (uint256 itemId,) = _wearableCollection.decodeTokenId(_tokenId);
        (string memory itemRarity,,,,,,) = _wearableCollection.items(itemId);
        return itemMarketRates[itemRarity];

    }

    function getPurchaseAmountForItem(IWearableCollection _wearableCollection, uint256 _tokenId) public view returns (uint256) {
    
        return getItemMarketRateForItem(_wearableCollection, _tokenId).purchaseAmount;

    }

    function getRefundAmountForItem(IWearableCollection _wearableCollection, uint256 _tokenId) public view returns (uint256) {
    
        return getItemMarketRateForItem(_wearableCollection, _tokenId).refundAmount;

    }

    function getItemMarketRateByRarity(string memory _rarity) public view returns (ItemMarketRate memory){

        string memory rarityLowerCase = String.toLowerCase(_rarity);
        return itemMarketRates[rarityLowerCase];

    }

    /**
    * @notice Get Tokens in Wallet
    * @param _address - Wallet address to check for wearables
    */
    function getTokensInWallet(address _address) public view returns (WearableNFT[] memory) {

        require(_address!=address(0),"Cannot look up the zero address balance");
        require(_address!=address(this),"Marketplace does not own any tokens");

        uint256 totalTokens = 0;
        IWearableCollection wearableCollection;

        for(uint256 i = 0; i < approvedWearableCollections.length; i++){
            wearableCollection = IWearableCollection(approvedWearableCollections[i]);
            totalTokens += wearableCollection.balanceOf(_address);
        }

        WearableNFT[] memory tokens = new WearableNFT[](totalTokens);
        uint256 index = 0;

        for(uint256 i = 0; i < approvedWearableCollections.length; i++){
            wearableCollection = IWearableCollection(approvedWearableCollections[i]);

            uint256 balanceOnContract = wearableCollection.balanceOf(_address);
            for(uint256 j = 0; j < balanceOnContract; j++){
                uint256 tokenId = wearableCollection.tokenOfOwnerByIndex(_address,j);
                tokens[index] = WearableNFT(
                    {
                        collection: approvedWearableCollections[i], 
                        tokenId: tokenId,
                        marketplaceApproved: wearableCollection.isApprovedForAll(_address, address(this))
                    });
                index++;
            }
        }

        return tokens;

    }

}