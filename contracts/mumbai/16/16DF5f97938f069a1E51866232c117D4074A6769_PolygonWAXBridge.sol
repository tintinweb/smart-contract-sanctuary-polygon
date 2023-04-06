pragma solidity ^0.6.0;

import "../GSN/Context.sol";
import "../Initializable.sol";
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
contract OwnableUpgradeSafe is Initializable, ContextUpgradeSafe {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */

    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {


        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);

    }


    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    uint256[49] private __gap;
}

pragma solidity ^0.6.0;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        // Check the signature length
        if (signature.length != 65) {
            revert("ECDSA: invalid signature length");
        }

        // Divide the signature in r, s and v variables
        bytes32 r;
        bytes32 s;
        uint8 v;

        // ecrecover takes the signature parameters, and the only way to get them
        // currently is to use assembly.
        // solhint-disable-next-line no-inline-assembly
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            revert("ECDSA: invalid signature 's' value");
        }

        if (v != 27 && v != 28) {
            revert("ECDSA: invalid signature 'v' value");
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0), "ECDSA: invalid signature");

        return signer;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * replicates the behavior of the
     * https://github.com/ethereum/wiki/wiki/JSON-RPC#eth_sign[`eth_sign`]
     * JSON-RPC method.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
}

pragma solidity ^0.6.0;
import "../Initializable.sol";

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract ContextUpgradeSafe is Initializable {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.

    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {


    }


    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }

    uint256[50] private __gap;
}

pragma solidity >=0.4.24 <0.7.0;


/**
 * @title Initializable
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */
contract Initializable {

  /**
   * @dev Indicates that the contract has been initialized.
   */
  bool private initialized;

  /**
   * @dev Indicates that the contract is in the process of being initialized.
   */
  bool private initializing;

  /**
   * @dev Modifier to use in the initializer function of a contract.
   */
  modifier initializer() {
    require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

    bool isTopLevelCall = !initializing;
    if (isTopLevelCall) {
      initializing = true;
      initialized = true;
    }

    _;

    if (isTopLevelCall) {
      initializing = false;
    }
  }

  /// @dev Returns true if and only if the function is running in the constructor
  function isConstructor() private view returns (bool) {
    // extcodesize checks the size of the code stored in an address, and
    // address returns the current address. Since the code is still not
    // deployed when running a constructor, any checks on its code size will
    // yield zero, making it an effective way to detect if a contract is
    // under construction or not.
    address self = address(this);
    uint256 cs;
    assembly { cs := extcodesize(self) }
    return cs == 0;
  }

  // Reserved storage space to allow for layout changes in the future.
  uint256[50] private ______gap;
}

pragma solidity ^0.6.0;

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

pragma solidity ^0.6.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

pragma solidity ^0.6.0;

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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

pragma solidity ^0.6.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

pragma solidity ^0.6.2;

import "../../introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of NFTs in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the NFT specified by `tokenId`.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Transfers a specific NFT (`tokenId`) from one account (`from`) to
     * another (`to`).
     *
     *
     *
     * Requirements:
     * - `from`, `to` cannot be zero.
     * - `tokenId` must be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this
     * NFT by either {approve} or {setApprovalForAll}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    /**
     * @dev Transfers a specific NFT (`tokenId`) from one account (`from`) to
     * another (`to`).
     *
     * Requirements:
     * - If the caller is not `from`, it must be approved to move this NFT by
     * either {approve} or {setApprovalForAll}.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;
    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address operator);

    function setApprovalForAll(address operator, bool _approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);


    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

pragma solidity ^0.6.2;

import "./IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    function totalSupply() external view returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    function tokenByIndex(uint256 index) external view returns (uint256);
}

pragma solidity ^0.6.2;

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
     */
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

pragma solidity ^0.6.0;
import "../Initializable.sol";

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
contract ReentrancyGuardUpgradeSafe is Initializable {
    bool private _notEntered;


    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {


        // Storing an initial non-zero value makes deployment a bit more
        // expensive, but in exchange the refund on every call to nonReentrant
        // will be lower in amount. Since refunds are capped to a percetange of
        // the total transaction's gas, it is best to keep them low in cases
        // like this one, to increase the likelihood of the full refund coming
        // into effect.
        _notEntered = true;

    }


    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_notEntered, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _notEntered = false;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _notEntered = true;
    }

    uint256[49] private __gap;
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.12;

interface IWETH {
  event Approval(address indexed src, address indexed guy, uint256 wad);
  event Transfer(address indexed src, address indexed dst, uint256 wad);
  event Deposit(address indexed dst, uint256 wad);
  event Withdrawal(address indexed src, uint256 wad);

  function allowance(address _owner, address _spender)
    external
    view
    returns (uint256);

  function balanceOf(address account) external view returns (uint256);

  function deposit() external payable;

  function withdraw(uint256) external;

  function totalSupply() external view returns (uint256);

  function approve(address, uint256) external returns (bool);

  function transfer(address, uint256) external returns (bool);

  function transferFrom(
    address,
    address,
    uint256
  ) external returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.12;

import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC721/IERC721Enumerable.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/Initializable.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/cryptography/ECDSA.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/access/Ownable.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC721/IERC721.sol";
import "./IWETH.sol";

interface IOwnable {
  function transferOwnership(address newOwner) external;
}

interface IERC721FactoryUpgradeable {
  function createERC721(
    address _collectionOwner,
    string calldata _collectionName,
    string calldata _baseMetadataURI
  ) external returns (address contractAddress);
}

interface IERC721TradableUpgradeable is IERC721Enumerable {
  function setBaseMetadataURI(string memory _baseMetadataURI) external;

  function mintTo(address _to, uint256 _newTokenId) external;

  function isExist(uint256 _tokenId) external view returns (bool);
}

/**
 @notice Upgradeable Polygon to WAX Bridge, allowing:
 - receiving transfers from WAX to Polygon, generating 1 WAXE for every 1000 WAXP burned on the WAX Chain
 - Transfer NFT from Wax to Polygon and vice versa
*/
contract PolygonWAXBridge is
  Initializable,
  ReentrancyGuardUpgradeSafe,
  OwnableUpgradeSafe
{
  using SafeERC20 for IERC20;
  using ECDSA for bytes32;

  uint256 public constant MAX_NFT_RELEASE = 20;

  string public constant CONTRACT_NAME = "POLYGON2WAX BRIDGE";

  bytes32 private constant TOKEN_TYPEHASH =
    keccak256(
      "TOKEN(address _token,address _to,uint256 _amount,uint256 _txHash)"
    );

  bytes32 private constant NFT_TYPEHASH =
    keccak256(
      "NFT(address _token,address _to,uint256[] _tokenIDs,uint256 _txHash)"
    );

  bytes32 private constant ERC721_TYPEHASH =
    keccak256(
      "ERC721(address _collectionOwner,string _collectionName,uint256 _txHash)"
    );

  /**
    Mapping to ensure uniqueness of a token/nft transfer
   */
  mapping(uint256 => bool) public transfers;
  /**
    erc20 WAXE token
   */
  IERC20 public waxeToken;
  /**
    erc20 WAXE token escrow account
    waxeEscrow is used when token balance on this bridge is not enough for a bridge transfer
   */
  address public waxeEscrow;

  /** 
    Account that sign the signature in release and releaseNFT function.
    The signature need to check for originating from this waxAuthority account.
  */
  address public waxAuthority;

  /**
    Active status of the contract. Contract will refuse to do many action when active status is false.
  */
  bool public isActive;

  /**
    Track the token that allow to bridge
   */
  mapping(IERC20 => TrackedToken) public trackedTokens;
  // upgrade 1
  /** 
    @dev deprecated variable. Maintained only to preserve storage layout for upgrades
   WETH token address
  */
  IWETH public wethToken;

  // upgrade 2
  /** 
   Base URI for created ERC721 collection
  */
  string public baseURI;
  /** 
    @dev deprecated variable. Maintained only to preserve storage layout for upgrades
    Old ERC721 Factory, not used anymore but keep as storage layout unchange.
  */
  address public erc721Factory;
  /**
  List of ERC721 collections are created by this bridge
   */
  address[] public createdErc721Contracts; // NFTs original from WAX
  /**
  Mapping to check if an ERC721 collection is created by this bridge
   */
  mapping(address => bool) public createdERC721;
  /**
  Mapping beetween collectionName (on Wax chain) and ERC721 collection (Polygon) chain)
   */
  mapping(string => address) public createdERC721ByCollection;
  /**
  List of ERC721 collections are approved for bridging
   */
  address[] public approvedErc721Contracts; // NFTs original from POLYGON
  /**
  Mapping to check if an ERC721 collection is approved for bridging
  @dev The keys of this mapping are the addresses of the approved ERC721
  @dev The values of this mapping are the corresponding index + 1 of the approved ERC721 address key into the approvedErc721Contracts list above
  @dev Therefore, approvedErc721Contracts[approvedERC721[0x123...] + 1] references the contract 0x123... in the approvedErc721Contracts list.
   */
  mapping(address => uint256) public approvedERC721;

  /**
  The factory address to create new ERC721 collection on demand
   */
  address public erc721FactoryUpgradeable;

  /**
  EIP-712 The domain separator
   */
  bytes32 public domainSeparator;

  /**
   * @dev triggered when tokens are transferred from the smart contract
   * @param _to  account that the tokens are sent to
   * @param _amount  amount transferred
   */
  event TokensTransfer(
    IERC20 indexed _token,
    address indexed _to,
    uint256 _amount,
    uint256 _txHash
  );

  event TransferToWax(
    IERC20 indexed _token,
    string _to,
    uint256 _amount,
    address indexed _from
  );

  struct TrackedToken {
    bool approved;
    uint256 ethDecimals;
    uint256 waxDecimals;
  }

  event TransferNFTToWax(
    address indexed _token,
    string _to,
    uint256[] _tokenIDs,
    address _from
  );

  event ERC721Created(address indexed _contract, string _collection, uint256);

  modifier checkActive() {
    require(isActive == true, "MAINTAINING...");
    _;
  }

  /**
   @notice Mofigier to check if an address is valid 
   @param _address Address input
   */
  modifier validAddress(address _address) {
    _validAddress(_address);
    _;
  }

  /**
   @notice Verify the allowance of an address is greater than an amount
   @param _token Token to check
   @param _allower Address of the allower
   @param _amount Amount to check
   */
  modifier _hasAllowance(
    IERC20 _token,
    address _allower,
    uint256 _amount
  ) {
    uint256 ourAllowance = _token.allowance(_allower, address(this));
    require(_amount <= ourAllowance, "ERR::NOT_ENOUGH_ALLOWANCE");
    _;
  }

  /**
   @notice Check if an address is valid 
   @param _address Address input
   */
  function _validAddress(address _address) internal pure {
    require(_address != address(0), "ERR_INVALID_ADDRESS");
  }

  /**
   @notice initializes a new PolygonWaxBridge instance
   @dev deprecated function, Only for upgradable testing purposes
   @param _waxeToken erc20 WAXE token
   @param _waxAuthority waxAuthority address
   */
  function initialize(
    IERC20 _waxeToken,
    address _waxeEscrow,
    address _waxAuthority
  )
    external
    initializer
    validAddress(address(_waxeToken))
    validAddress(_waxeEscrow)
    validAddress(_waxAuthority)
  {
    __Context_init_unchained();
    ReentrancyGuardUpgradeSafe.__ReentrancyGuard_init();
    __Ownable_init_unchained();
    OwnableUpgradeSafe.__Ownable_init();
    waxeToken = _waxeToken;
    waxeEscrow = _waxeEscrow;
    waxAuthority = _waxAuthority;
    isActive = true;
  }

  /**
   @notice Implementation of ERC721Receiver. Accepts all token transfers.
   @dev Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
  */
  function onERC721Received(
    address,
    address,
    uint256,
    bytes memory
  ) public pure returns (bytes4) {
    return this.onERC721Received.selector;
  }

  /**
   @dev upgrade to fixed issue IERC20 does not compatible with IWETH
   @dev deprecated function, Only for upgradable testing purposes
   */
  function upgradeV110(address _wethToken)
    external
    onlyOwner
    validAddress(_wethToken)
  {
    wethToken = IWETH(_wethToken);
  }

  /**
   @dev Upgrade the contract, set the default baseURI and erc721Factory
   @dev deprecated function, Only for upgradable testing purposes
  */
  function upgradeV120(string memory _baseURI, address _erc721Factory)
    external
    onlyOwner
    validAddress(_erc721Factory)
  {
    baseURI = _baseURI;
    erc721Factory = _erc721Factory;
  }

  /**
   @dev Upgrade the contract, use new erc721FactoryUpgradeable
  */
  function upgradeV130(address _erc721FactoryUpgradeable)
    external
    validAddress(_erc721FactoryUpgradeable)
    onlyOwner
  {
    erc721FactoryUpgradeable = _erc721FactoryUpgradeable;

    // migrate the approvedERC721 map to the new indexing scheme for referencing corresponding approvedErc721Contracts entries
    uint256 _length = approvedErc721Contracts.length;
    for (uint256 i = 0; i < _length; i++) {
      approvedERC721[approvedErc721Contracts[i]] = i + 1;
    }
  }

  /**
   @dev Initialize EIP712 Domain in contract V1.4.0
  */
  function upgradeV140() external onlyOwner {
    uint256 chainId;
    assembly {
      chainId := chainid()
    }
    domainSeparator = keccak256(
      abi.encode(
        keccak256(
          "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        ),
        keccak256(bytes(CONTRACT_NAME)),
        keccak256(bytes("1")),
        chainId,
        address(this)
      )
    );
  }

  /**
  @notice Release the ERC20 token when bridge from Wax to Polygon
  @notice The ERC20 token address (_to), recipient (_to) and the amount are baked into this request by the signature field
  @notice which is provided by the WAX back end at the request of the token holder of the corresponding fungible token amount on the WAX side.
  @notice Note that the _txHash value is also baked into the signature, which deduplicates these requests as it is the wax transaction hash, which
  @notice initiated this request by transfering the corresponding assets on the WAX side
  @param _token Address of token
  @param _to Address of the receiver account
  @param _amount Amount of token
  @param _txHash Transaction hash on Wax chain
  @param _signature Signature generated by the WAX bridge oracle to verify the release request
  */
  function release(
    IERC20 _token,
    address _to,
    uint256 _amount,
    uint256 _txHash,
    bytes memory _signature
  )
    external
    nonReentrant
    validAddress(address(_token))
    validAddress(_to)
    checkActive
  {
    bytes32 hash = keccak256(
      abi.encodePacked(
        "\x19\x01",
        domainSeparator,
        keccak256(
          abi.encode(TOKEN_TYPEHASH, address(_token), _to, _amount, _txHash)
        )
      )
    );
    address signer = hash.recover(_signature);
    require(signer == waxAuthority, "INVALID_SIGNATURE");
    require(!transfers[_txHash], "TX_HASH_ALREADY_EXIST");
    transfers[_txHash] = true;
    if (_token.balanceOf(address(this)) < _amount) {
      // transfer token from waxeEscrow If this contract address has insufficient token balance
      // waxeEscrow must approval for this contract can transfer token
      _token.safeTransferFrom(waxeEscrow, _to, _amount);
    } else {
      // transfer other token from this address
      _token.safeTransfer(_to, _amount);
    }
    emit TokensTransfer(_token, _to, _amount, _txHash);
  }

  /**
  @notice Config the ERC20 token for bridging
  @param _token Address of the ERC20 token
  @param _approved Is this token approved for bridging
  @param _ethDecimals Decimal number in Polygon chain
  @param _waxDecimals Decimal number in Wax chain
  */
  function configToken(
    IERC20 _token,
    bool _approved,
    uint256 _ethDecimals,
    uint256 _waxDecimals
  ) external onlyOwner checkActive {
    require(_ethDecimals >= _waxDecimals, "INVALID_DECIMALS");
    TrackedToken storage _trackedToken = trackedTokens[_token];
    _trackedToken.approved = _approved;
    _trackedToken.ethDecimals = _ethDecimals;
    _trackedToken.waxDecimals = _waxDecimals;
  }

  /**
  @notice Initiate a transfer of ERC20 token from Polygon to Wax chain
  @notice Token amount will be held on this contract in escrow
  @notice The WAX back end will see this request, initiating a transaction to
  @notice release the corresponding WAX amount in tokens
  @param _token Address of token want to transfer
  @param _toWaxAccount Wax account that will receive the token
  @param _amount Amount of token
  */

  function transfer(
    IERC20 _token,
    string calldata _toWaxAccount,
    uint256 _amount
  )
    external
    checkActive
    validAddress(address(_token))
    _hasAllowance(_token, msg.sender, _amount)
  {
    address from = msg.sender;
    TrackedToken storage _trackedToken = trackedTokens[_token];
    require(_trackedToken.approved, "ERR_UNAPPROVED_TOKEN");
    require(
      _isWaxAccount(_toWaxAccount) && _isWCWName(_toWaxAccount),
      "ERR_INVALID_WCW_WAX_ACCOUNT"
    );
    require(
      _amount % (10**(_trackedToken.ethDecimals - _trackedToken.waxDecimals)) ==
        0,
      "ERR_INVALID_AMOUNT"
    );

    _token.safeTransferFrom(from, address(this), _amount);

    emit TransferToWax(_token, _toWaxAccount, _amount, from);
  }

  /**
  @notice Update the authority to new address
  @param _waxAuthority Address of new authority
  */
  function updateAuthority(address _waxAuthority)
    external
    onlyOwner
    validAddress(_waxAuthority)
  {
    waxAuthority = _waxAuthority;
  }

  /**
  @notice Enable/Disable the active status of this bridge.
  @param _activeStatus Active status to set
  */
  function setActive(bool _activeStatus) external onlyOwner {
    isActive = _activeStatus;
  }

  /**
  @notice Approve an ERC721 collection on Polygon to support bridging
  @param _token Address of ERC721 collection
  @param _approved A boolean indicate the collection is allow or not
  */
  function approveERC721Token(address _token, bool _approved)
    external
    onlyOwner
  {
    uint256 tokenIndexPlusOne = approvedERC721[_token];
    bool alreadyApproved = tokenIndexPlusOne > 0;

    require(alreadyApproved != _approved, "ERR_NOTHING_CHANGE");

    if (alreadyApproved == false && _approved == true) {
      approvedErc721Contracts.push(_token);
      approvedERC721[_token] = approvedErc721Contracts.length;
    } else {
      delete approvedERC721[_token];
      address reindexContract = approvedErc721Contracts[
        approvedErc721Contracts.length - 1
      ];
      approvedErc721Contracts[tokenIndexPlusOne - 1] = reindexContract;
      approvedErc721Contracts.pop();
      approvedERC721[reindexContract] = approvedErc721Contracts.length > 0
        ? tokenIndexPlusOne
        : 0;
    }
  }

  /**
  @notice Get list of ERC721 collection that allowed to bridge
  @return tuple of approved collection and created collections
  */
  function availableErc721Contracts()
    external
    view
    returns (address[] memory, address[] memory)
  {
    return (approvedErc721Contracts, createdErc721Contracts);
  }

  /**
  @notice Receive nft on Polygon side when user bridge from Wax to Polygon
  @notice The ERC721 token address (_to), recipient (_to) and token ids are baked into this request by the signature field
  @notice which is provided by the WAX back end at the request of the token ids owner of the corresponding assets on the WAX side.
  @notice Note that the _txHash value is also baked into the signature, which deduplicates these requests as it is the wax transaction hash, which
  @notice initiated this request by transfering the corresponding assets on the WAX side
  @param _token address of ERC721 collection
  @param _to address to receive nft tokens
  @param _tokenIDs list of token Ids
  @param _txHash transaction hash on Wax chain
  @param _signature signature generated by the WAX bridge oracle which verifies if the release is valid
  */

  function releaseNFT(
    address _token,
    address _to,
    uint256[] calldata _tokenIDs,
    uint256 _txHash,
    bytes calldata _signature
  ) external validAddress(_to) checkActive {
    require(!transfers[_txHash], "TX_HASH_ALREADY_EXIST");
    transfers[_txHash] = true;
    bytes32 hash = keccak256(
      abi.encodePacked(
        "\x19\x01",
        domainSeparator,
        keccak256(
          abi.encode(NFT_TYPEHASH, address(_token), _to, _tokenIDs, _txHash)
        )
      )
    );

    address signer = hash.recover(_signature);
    require(signer == waxAuthority, "INVALID_SIGNATURE");
    uint256 _length = _tokenIDs.length;
    require(_length <= MAX_NFT_RELEASE, "EXCEEDS_MAX_NFT_RELEASE");
    if (approvedERC721[_token] > 0) {
      for (uint256 i = 0; i < _length; i++) {
        require(
          address(this) == IERC721(_token).ownerOf(_tokenIDs[i]),
          "TOKEN_ID_DOES_NOT_EXIST"
        );
        IERC721(_token).safeTransferFrom(address(this), _to, _tokenIDs[i]);
      }
    } else if (createdERC721[_token]) {
      for (uint256 i = 0; i < _length; i++) {
        if (IERC721TradableUpgradeable(_token).isExist(_tokenIDs[i])) {
          require(
            address(this) == IERC721(_token).ownerOf(_tokenIDs[i]),
            "TOKEN_ID_DOES_NOT_EXIST"
          );
          IERC721(_token).safeTransferFrom(address(this), _to, _tokenIDs[i]);
        } else {
          IERC721TradableUpgradeable(_token).mintTo(_to, _tokenIDs[i]);
        }
      }
    } else {
      revert("UNAVAILABLE_ERC721_CONTRACT");
    }
  }

  /**
  @notice Transfer a list of nft token(s) to bridge from this EVM chain to the WAX side
  @notice Tokens will be held on this contract in escrow
  @notice The WAX back end will see this request, initiating a transaction to
  @notice release the corresponding WAX tokens (or mint them as needed)
  @notice to the indicated WAX account
  @param _token address of ERC721 collection
  @param _toWaxAccount account name on Wax chain, this account will receive the nft ids
  @param _tokenIDs a list of nft ids to send through
  */
  function transferNFT(
    address _token,
    string calldata _toWaxAccount,
    uint256[] calldata _tokenIDs
  ) external checkActive {
    address from = msg.sender;
    require(
      _isWaxAccount(_toWaxAccount) && _isWCWName(_toWaxAccount),
      "ERR_INVALID_WAX_WCW_ACCOUNT"
    );
    require(
      approvedERC721[_token] > 0 || createdERC721[_token],
      "UNAPPROVED_ERC721_CONTRACT"
    );
    uint256 _length = _tokenIDs.length;
    for (uint256 i = 0; i < _length; i++) {
      IERC721(_token).safeTransferFrom(from, address(this), _tokenIDs[i]);
    }
    emit TransferNFTToWax(_token, _toWaxAccount, _tokenIDs, from);
  }

  /**
  @notice Create an ERC721 collection for bridging WAX originating Fungible tokens to this EVM based chain
  @notice The collection owner and name is baked into this request by the signature field which is provided by the WAX back end
  @notice at the request of the collection owner of the corresponding collection on the WAX side.
  @notice Note that the _txHash value is also baked into the signature, which deduplicates these requests as it is the wax transaction hash, which
  @notice initiated this request
  @param _collectionOwner Owner of the newly created ERC721
  @param _collectionName Collection name on Wax chain that pair with this ERC721
  @param _txHash Transaction hash of the mapping request
  @param _signature Signature generated by oracle, need to check to verify the request to create new collectionName and collectionOwner is valid
  */
  function createERC721(
    address _collectionOwner,
    string calldata _collectionName,
    uint256 _txHash,
    bytes calldata _signature
  ) external checkActive returns (address) {
    if (_collectionOwner != address(this)) {
      // we need the above check to set up tests where this contract owns the brawlers contract
      require(msg.sender == _collectionOwner, "COLLECTION_OWNER_ONLY");
    }
    require(!transfers[_txHash], "TX_HASH_ALREADY_EXIST");
    transfers[_txHash] = true;
    require(_isWaxAccount(_collectionName), "ERR_INVALID_WAX_COL_ACCOUNT");
    bytes32 hash = keccak256(
      abi.encodePacked(
        "\x19\x01",
        domainSeparator,
        keccak256(
          abi.encode(
            ERC721_TYPEHASH,
            _collectionOwner,
            _collectionName,
            _txHash
          )
        )
      )
    );
    address signer = hash.recover(_signature);
    require(signer == waxAuthority, "INVALID_SIGNATURE");

    require(
      createdERC721ByCollection[_collectionName] == address(0),
      "ERC721_ALREADY_CREATED"
    );

    address newERC721 = IERC721FactoryUpgradeable(erc721FactoryUpgradeable)
      .createERC721(_collectionOwner, _collectionName, baseURI);
    createdErc721Contracts.push(newERC721);
    createdERC721[newERC721] = true;
    createdERC721ByCollection[_collectionName] = newERC721;
    emit ERC721Created(
      newERC721,
      _collectionName,
      createdErc721Contracts.length
    );
    return newERC721;
  }

  /**
  @notice Transfer the ownership of an ERC721 collection to new owner
  @param _createdERC721 collection address
  @param _newOwner new owner address
  */
  function transferCollectionOwnership(
    address _createdERC721,
    address _newOwner
  ) external onlyOwner {
    require(
      createdERC721ByCollection["bcbrawlers"] == _createdERC721,
      "only allow bcbrawlers"
    );
    IOwnable(_createdERC721).transferOwnership(_newOwner);
  }

  /**
  @notice Update the metadata URI for all created collections. Realize that metadata of all bridge ERC721's are held externally offchain at these metadata url's
  @param _baseURI new base Uri
  @param _from Managed ERC721 contract index to start updating at
  @param _to Managed ERC721 contract index to stop updating at
  */
  function updateMetadataUri(
    string memory _baseURI,
    uint256 _from,
    uint256 _to
  ) external onlyOwner checkActive {
    _to = _to <= createdErc721Contracts.length
      ? _to
      : createdErc721Contracts.length;
    for (uint256 i = _from; i < _to; i++) {
      IERC721TradableUpgradeable(createdErc721Contracts[i]).setBaseMetadataURI(
        _baseURI
      );
    }
    baseURI = _baseURI;
  }

  /**
   @notice Verify if a wax account name valid
   @param _waxAccount String name of wax account
   */
  function _isWaxAccount(string calldata _waxAccount)
    private
    pure
    returns (bool)
  {
    bytes memory nameBytes = bytes(_waxAccount);
    if (nameBytes.length > 12) return false;
    uint256 _length = nameBytes.length;
    for (uint256 i; i < _length; i++) {
      bytes1 char = nameBytes[i];
      if (
        !(char >= 0x31 && char <= 0x35) && //1-5
        !(char >= 0x61 && char <= 0x7A) && //a-z
        !(char == 0x2E) //.
      ) return false;
    }
    return true;
  }

  /**
   @notice Verify if a wax cloud wallet name is valid
   @param _waxAccount String name of wax account wallet
   */
  function _isWCWName(string calldata _waxAccount) private pure returns (bool) {
    bytes memory waxNameBytes = bytes(_waxAccount);
    bytes memory wcwBytes = bytes(".wam");
    uint256 _length = wcwBytes.length;
    if (waxNameBytes.length <= _length) return false;
    for (uint256 i = 0; i < _length; i++) {
      if (
        wcwBytes[i] != waxNameBytes[waxNameBytes.length - wcwBytes.length + i]
      ) {
        return false;
      }
    }
    return true;
  }
}