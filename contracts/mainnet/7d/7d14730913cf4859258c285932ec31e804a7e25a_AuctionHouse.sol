/**
 *Submitted for verification at polygonscan.com on 2022-06-21
*/

// File: @openzeppelin/contracts/token/ERC721/IERC721Receiver.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

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
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// File: @openzeppelin/contracts/utils/Strings.sol


// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// File: @openzeppelin/contracts/utils/math/SafeMath.sol


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

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/utils/Address.sol


// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
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
        return functionCall(target, data, "Address: low-level call failed");
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
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
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
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
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


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

// File: ah.sol


pragma solidity ^0.8.7;







interface INFT {
    function tokenURI(uint256 tokenId) external view returns (string memory);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

interface IMID {
    function userLevel(address _user) external view returns (uint256);
}

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

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
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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

abstract contract Ownable is Context {
    address private _owner;
    uint256 private _certifieds;

    mapping(address => bool) private _isCertified;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
    event CertifiedAdded(address indexed added);
    event CertifiedRemoved(address indexed removed);

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
     * @dev Return True if address is Certified.
     */
    function isCertified(address who) public view returns (bool) {
        return _isCertified[who];
    }

    /**
     * @dev Return total number of Certified.
     */
    function certifieds() public view returns (uint256) {
        return _certifieds;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Caller is not the owner");
        _;
    }

    /**
     * @dev Throws if called by any account other than the certified.
     */
    modifier onlyCertified() {
        require(
            _isCertified[_msgSender()] || owner() == _msgSender(),
            "Caller is not certified"
        );
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
        require(newOwner != address(0), "New owner is the zero address");
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

    /**
     * @dev Add a new account (`user`) as a certified.
     * Can only be called by the current owner.
     */
    function addCertified(address user) public onlyOwner {
        require(user != address(0), "New user is the zero address");
        require(!_isCertified[user], "This address is certified");
        emit CertifiedAdded(user);
        _isCertified[user] = true;
        _certifieds += 1;
    }

    /**
     * @dev Remove a certified (`user`).
     * Can only be called by the current owner.
     */
    function removeCertified(address user) public onlyOwner {
        require(_isCertified[user], "This address is not certified");
        emit CertifiedRemoved(user);
        _isCertified[user] = false;
        _certifieds -= 1;
    }
}

abstract contract AuctionBase is Ownable, ReentrancyGuard, IERC721Receiver {
    using SafeMath for uint256;
    using Strings for address;
    using Strings for uint256;

    struct Auction {
        address owner;
        address bidder;
        uint256 nft;
        uint256 startBlock;
        uint256 endBlock;
        uint256 startingPrice;
        uint256 buyoutPrice;
        uint256 price;
        uint256 bids;
        string uri;
        bool end;
    }

    string internal _name;
    IMID internal _mid;
    INFT internal _nft;
    IERC20 internal _usdc;
    bool internal _bidPaused = false;
    bool internal _ahPaused = false;
    uint256 internal _extraSpace = 1;
    uint256 internal _minPrice = 100000;
    uint256 internal _duration = 76800;
    uint256 internal _extension = 128;
    uint256 internal _rates = 100; // 100‱
    uint256 internal _markupRate = 499; // 500‱
    uint256 internal _markupMin = 1000000; // 1 USDC

    Auction[] internal _auctions;

    mapping(address => uint256[]) _listing;

    // Event
    event CreateAuction(
        address indexed owner,
        uint256 indexed auctionId,
        uint256 indexed nft,
        uint256 startingPrice,
        uint256 buyoutPrice,
        string uri
    );

    event CancelAuction(
        address indexed owner,
        uint256 indexed auctionId,
        uint256 indexed nft
    );

    event FulfillAuction(
        address indexed owner,
        uint256 indexed auctionId,
        uint256 indexed nft,
        uint256 price
    );

    event Bid(
        address indexed user,
        uint256 indexed auctionId,
        uint256 nft,
        uint256 price
    );

    event Exceeded(
        address indexed user,
        uint256 auctionId,
        uint256 nft,
        uint256 price
    );

    event Win(
        address indexed user,
        uint256 indexed auctionId,
        uint256 nft,
        uint256 price
    );

    event TokenReceived(
        address operator,
        address from,
        uint256 tokenId,
        bytes data
    );

    // Modifiers
    modifier bidNotPause() {
        require(!_bidPaused, "Bid is paused");
        _;
    }

    modifier ahNotPause() {
        require(!_ahPaused, "Auction house is paused");
        _;
    }

    // View
    function name() external view returns (string memory) {
        return _name;
    }

    function auctionDetail(uint256 _id) public view returns (Auction memory) {
        return _auctions[_id];
    }

    function userListing(address _user) public view returns (uint256[] memory list, uint256 space) {
        list = _listing[_user];
        space = _mid.userLevel(_msgSender()) + _extraSpace;
        return (list, space);
    }

    function validBidPrice(uint256 _id) public view returns (uint256) {
        Auction memory auction = _auctions[_id];
        if (auction.bids == 0) {
            return auction.startingPrice;
        } else {
            uint256 markup = auction.price.mul(_markupRate).div(10000);
            markup = markup < _markupMin ? _markupMin : markup;
            uint256 price = auction.price.add(markup);
            price = price > auction.buyoutPrice ? auction.buyoutPrice : price;
            return price;
        }
    }

    // Methods
    function toggleBidPaused() external onlyCertified {
        _bidPaused = !_bidPaused;
    }

    function toggleAhPaused() external onlyCertified {
        _ahPaused = !_ahPaused;
    }

    function setExtraSpace(uint256 _value) external onlyCertified {
        _extraSpace = _value;
    }

    function setMinPrice(uint256 _value) external onlyCertified {
        _minPrice = _value;
    }

    function setDuration(uint256 _value) external onlyCertified {
        _duration = _value;
    }

    function setExtension(uint256 _value) external onlyCertified {
        _extension = _value;
    }

    function setFeeRates(uint256 _value) external onlyCertified {
        _rates = _value;
    }

    function setMarkups(uint256 _rate, uint256 _min) external onlyCertified {
        _markupRate = _rate;
        _markupMin = _min;
    }

    function setMID(address _value) external onlyCertified {
        _mid = IMID(_value);
    }

    function setNFT(address _value) external onlyCertified {
        _nft = INFT(_value);
    }

    function setUSDC(address _value) external onlyCertified {
        _usdc = IERC20(_value);
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) public override returns (bytes4) {
        emit TokenReceived(operator, from, tokenId, data);
        return this.onERC721Received.selector;
    }

    function transferToken(
        address _token,
        address _to,
        uint256 _amount
    ) external onlyCertified returns (bool) {
        require(_transferToken(_token, _to, _amount));
        return true;
    }

    function transferNFT(address _to, uint256 _tokenId)
        external
        onlyCertified
        returns (bool)
    {
        require(_transferNFT(address(this), _to, _tokenId));
        return true;
    }

    function transferUSDC(address _to, uint256 _amount)
        external
        onlyCertified
        returns (bool)
    {
        require(_transferUSDC(address(this), _to, _amount));
        return true;
    }

    function _transferNFT(
        address _from,
        address _to,
        uint256 _tokenId
    ) internal returns (bool) {
        _nft.safeTransferFrom(_from, _to, _tokenId, bytes(_name));
        return true;
    }

    function _transferUSDC(
        address _from,
        address _to,
        uint256 _amount
    ) internal returns (bool) {
        if (_from == address(this)) {
            return _usdc.transfer(_to, _amount);
        } else {
            return _usdc.transferFrom(_from, _to, _amount);
        }
    }

    function _transferToken(
        address _token,
        address _to,
        uint256 _amount
    ) internal returns (bool) {
        IERC20 token = IERC20(_token);
        return token.transfer(_to, _amount);
    }
}

contract AuctionHouse is AuctionBase {
    using SafeMath for uint256;
    using Address for address;

    constructor() {
        _name = "Auction House - crystal.network";
        _mid = IMID(0x92235Ce2CC98cb685dA8D70b2d0Aa86134440286);
        _nft = INFT(0x30a8C517b35e7D635f77AaeeBb0C704015dFaa6A);
        _usdc = IERC20(0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174);
    }

    function createAuction(
        uint256 _nftId,
        uint256 _startingPrice,
        uint256 _buyoutPrice
    ) external ahNotPause returns (uint256) {
        require(!_msgSender().isContract(), "Contracts are not supported");
        require(
            _listing[_msgSender()].length <
                _mid.userLevel(_msgSender()) + _extraSpace,
            "Can not list more."
        );
        require(_startingPrice >= _minPrice, "Invalid starting price.");
        require(_buyoutPrice >= _startingPrice, "Invalid buyout price.");

        _transferNFT(_msgSender(), address(this), _nftId);
        uint256 id = _auctions.length;
        _createAuction(_msgSender(), _nftId, _startingPrice, _buyoutPrice);
        _listing[_msgSender()].push(id);

        emit CreateAuction(
            _msgSender(),
            id,
            _nftId,
            _startingPrice,
            _buyoutPrice,
            _auctions[id].uri
        );

        return id;
    }

    function cancelAuction(uint256 _auctionId) external ahNotPause {
        require(
            _auctions[_auctionId].owner == _msgSender(),
            "Only owner can cancel."
        );
        require(
            _auctions[_auctionId].bids == 0,
            "The auction has started and cannot be cancelled."
        );
        require(
            !_auctions[_auctionId].end,
            "Auction has ended and cannot be cancelled."
        );

        _cancelAuction(_auctionId);
        _removeAuctionFromUser(_auctions[_auctionId].owner, _auctionId);

        emit CancelAuction(
            _auctions[_auctionId].owner,
            _auctionId,
            _auctions[_auctionId].nft
        );
    }

    function fulfillAuction(uint256 _auctionId) external ahNotPause {
        require(
            _auctions[_auctionId].owner == _msgSender() ||
                _auctions[_auctionId].bidder == _msgSender(),
            "Only owner or winner can fulfill."
        );
        require(
            !_auctions[_auctionId].end,
            "Auction has ended and cannot be fulfilled."
        );
        require(_auctions[_auctionId].bids > 0, "No one bid.");
        require(
            _auctions[_auctionId].endBlock < block.number,
            "Auction is in progress and cannot be fulfilled."
        );

        _fulfillAuction(_auctionId);
        _removeAuctionFromUser(_auctions[_auctionId].owner, _auctionId);

        emit FulfillAuction(
            _auctions[_auctionId].owner,
            _auctionId,
            _auctions[_auctionId].nft,
            _auctions[_auctionId].price
        );
        emit Win(
            _auctions[_auctionId].bidder,
            _auctionId,
            _auctions[_auctionId].nft,
            _auctions[_auctionId].price
        );
    }

    function bidAuction(uint256 _auctionId, uint256 _price)
        external
        bidNotPause
    {
        require(!_msgSender().isContract(), "Contracts are not supported");
        require(
            _auctions[_auctionId].owner != _msgSender(),
            "Owner cannot bid."
        );
        require(
            !_auctions[_auctionId].end,
            "Auction has ended and cannot bid."
        );
        require(
            _auctions[_auctionId].endBlock > block.number,
            "Auction is not in progress and cannot bid."
        );

        if (_price < validBidPrice(_auctionId)) {
            emit Exceeded(
                _msgSender(),
                _auctionId,
                _auctions[_auctionId].nft,
                _auctions[_auctionId].price
            );
            return;
        } else {
            emit Bid(
                _msgSender(),
                _auctionId,
                _auctions[_auctionId].nft,
                _price
            );
        }

        require(_price >= validBidPrice(_auctionId), "Invalid bid price.");
        _transferUSDC(_msgSender(), address(this), _price);
        _bidAuction(_msgSender(), _auctionId, _price);

        if (_price >= _auctions[_auctionId].buyoutPrice) {
            _fulfillAuction(_auctionId);
            _removeAuctionFromUser(_auctions[_auctionId].owner, _auctionId);

            emit FulfillAuction(
                _auctions[_auctionId].owner,
                _auctionId,
                _auctions[_auctionId].nft,
                _auctions[_auctionId].price
            );
            emit Win(
                _auctions[_auctionId].bidder,
                _auctionId,
                _auctions[_auctionId].nft,
                _auctions[_auctionId].price
            );
        }
    }

    function _createAuction(
        address _user,
        uint256 _nftId,
        uint256 _startingPrice,
        uint256 _buyoutPrice
    ) internal returns (bool) {
        _auctions.push(
            Auction({
                owner: _user,
                bidder: address(0),
                nft: _nftId,
                startBlock: block.number,
                endBlock: block.number.add(_duration),
                startingPrice: _startingPrice,
                buyoutPrice: _buyoutPrice,
                price: _startingPrice,
                bids: uint256(0),
                uri: _nft.tokenURI(_nftId),
                end: false
            })
        );

        return true;
    }

    function _cancelAuction(uint256 _auctionId) internal returns (bool) {
        Auction storage auction = _auctions[_auctionId];
        auction.end = true;
        _transferNFT(address(this), auction.owner, auction.nft);
        return true;
    }

    function _fulfillAuction(uint256 _auctionId) internal returns (bool) {
        Auction storage auction = _auctions[_auctionId];
        auction.end = true;

        uint256 fee = auction.price.mul(_rates).div(10000);
        uint256 profit = auction.price.sub(fee);

        _transferNFT(address(this), auction.bidder, auction.nft);
        _transferUSDC(address(this), owner(), fee);
        _transferUSDC(address(this), auction.owner, profit);

        return true;
    }

    function _bidAuction(
        address _bidder,
        uint256 _auctionId,
        uint256 _price
    ) internal returns (bool) {
        Auction storage auction = _auctions[_auctionId];
        address preBidder = auction.bidder;
        uint256 prePrice = auction.price;
        auction.bidder = _bidder;
        auction.price = _price;
        auction.bids++;

        if (
            auction.endBlock.sub(block.number) < _extension &&
            auction.price < auction.buyoutPrice
        ) {
            auction.endBlock = block.number.add(_extension);
        }

        if (preBidder != address(0) && prePrice > 0) {
            _transferUSDC(address(this), preBidder, prePrice);
            emit Exceeded(preBidder, _auctionId, auction.nft, _price);
        }

        return true;
    }

    function _removeAuctionFromUser(address _user, uint256 _id)
        internal
        returns (bool)
    {
        uint256[] storage list = _listing[_user];
        bool hasId = false;

        if (list.length > 1) {
            uint256 index = 0;
            for (uint256 i = 0; i < list.length; i++) {
                if (list[i] == _id) {
                    index = i;
                    hasId = true;
                    break;
                }
            }
            for (uint256 i = index; i < list.length - 1; i++) {
                list[i] = list[i + 1];
            }
        }

        if (hasId || list[list.length - 1] == _id) {
            list.pop();
        }

        return true;
    }
}