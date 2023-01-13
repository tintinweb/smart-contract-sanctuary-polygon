// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

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
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
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

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;


//import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "./interfaces/ICurrenciesERC20.sol";

//../node_modules/
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

/**
 *      CurrenciesERC20
 * @title CurrenciesERC20
 * @author JackBekket https://github.com/JackBekket
 * @dev This contract allow to use erc20 tokens as a currency in crowdsale-like contracts
 *
 */
contract CurrenciesERC20 is ReentrancyGuard, Ownable, ERC165 {
    using SafeMath for uint256;
    //  using SafeERC20 for IERC20;

    // Interface to currency token
    //IERC20 public _currency_token;

    // Supported erc20 currencies: .. to be extended.  This is hard-coded values
    /**
     * @dev Hardcoded (not-extetiable after deploy) erc20 currencies
     */
    enum CurrencyERC20 {
        USDT,
        USDC,
        DAI,
        WETH,
        WBTC,
        VXPPL
    }

    struct CurrencyERC20_Custom {
        address contract_address;
        IERC20Metadata itoken; // contract interface
    }

    // map currency contract addresses
    mapping(CurrencyERC20 => IERC20Metadata) public _currencies_hardcoded; // should be internal?

    // mapping from name to currency contract (protected)
    mapping(string => CurrencyERC20_Custom) public _currencies_custom;

    // mapping from name to currency contract defined by users (not protected against scum)
    mapping(string => CurrencyERC20_Custom) public _currencies_custom_user;

    
    bytes4 private _INTERFACE_ID_CURRECIES = 0x033a36bd;

    function AddCustomCurrency(address _token_contract) public {
        IERC20Metadata _currency_contract = IERC20Metadata(_token_contract);

        // if (_currency_contract.name != '0x0')

        string memory _name_c = _currency_contract.name(); // @note -- some contracts just have name as public string, but do not have name() function!!! see difference between 0.4.0 and 0.8.0 OZ standarts need future consideration
        //  uint8 _dec = _currency_contract.decimals();

        address _owner_c = owner();
        if (msg.sender == _owner_c) {
            require(
                _currencies_custom[_name_c].contract_address == address(0),
                "AddCustomCurrency[admin]: Currency token contract with this address is already exists"
            );
            _currencies_custom[_name_c].itoken = _currency_contract;
            //   _currencies_custom[_name_c].decimals = _dec;
            _currencies_custom[_name_c].contract_address = _token_contract;
        } else {
            require(
                _currencies_custom_user[_name_c].contract_address == address(0),
                "AddCustomCurrency[user]: Currency token contract with this address is already exists"
            );
            _currencies_custom_user[_name_c].itoken = _currency_contract;
            //  _currencies_custom_user[_name_c].decimals = _dec;
            _currencies_custom_user[_name_c].contract_address = _token_contract;
        }
    }

    constructor(
        address US_Tether,
        address US_Circle,
        address DAI,
        address W_Ethereum,
        address WBTC,
        address VXPPL
    ) {
        require(US_Tether != address(0), "USDT contract address is zero!");
        require(US_Circle != address(0), "US_Circle contract address is zero!");
        require(DAI != address(0), "DAI contract address is zero!");
        require(
            W_Ethereum != address(0),
            "W_Ethereum contract address is zero!"
        );
        require(WBTC != address(0), "WBTC contract address is zero!");

        _currencies_hardcoded[CurrencyERC20.USDT] = IERC20Metadata(US_Tether);
        _currencies_hardcoded[CurrencyERC20.USDT] == IERC20Metadata(US_Tether);
        _currencies_hardcoded[CurrencyERC20.USDC] = IERC20Metadata(US_Circle);
        _currencies_hardcoded[CurrencyERC20.DAI] = IERC20Metadata(DAI);
        _currencies_hardcoded[CurrencyERC20.WETH] = IERC20Metadata(W_Ethereum);
        _currencies_hardcoded[CurrencyERC20.WBTC] = IERC20Metadata(WBTC);
        _currencies_hardcoded[CurrencyERC20.VXPPL] = IERC20Metadata(VXPPL);


    }

    function get_hardcoded_currency(CurrencyERC20 currency)
        public
        view
        returns (IERC20Metadata)
    {
        return _currencies_hardcoded[currency];
    }

    function supportsInterface(bytes4 interfaceId)
    public view override
    returns (bool) {
       return interfaceId == type(ICurrenciesERC20).interfaceId || super.supportsInterface(interfaceId);
    }
}

pragma solidity ^0.8.0;

// SPDX-License-Identifier: UNLICENSED


/**
 *  @author Jack Bekket
 *  ALL RIGHTS RESERVED
 */
library FeesCalculator {

    /**
    *   Calculate fee (UnSafeMath) -- use it only if it ^0.8.0
    *   @dev calculate fee
    *   @param amount number from whom we take fee
    *   @param scale scale for rounding. 100 is 1/100 (percent). we can encreace scale if we want better division (like we need to take 0.5% instead of 5%, then scale = 1000)
    */
    function calculateAbstractFee(uint256 amount, uint256 scale, uint256 promille_fee_) public pure returns(uint256) {
        uint a = amount / scale;
        uint b = amount % scale;
        uint c = promille_fee_ / scale;
        uint d = promille_fee_ % scale;
        return a * c * scale + a * d + b * c + (b * d + scale - 1) / scale;
    }
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

//../../node_modules/

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


/*
import "../../node_modules/@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "../../node_modules/@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../../node_modules/@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../../node_modules/@openzeppelin/contracts/access/Ownable.sol";
*/




interface ICurrenciesERC20 {
    /**
     * @dev Hardcoded (not-extetiable after deploy) erc20 currencies
     */
    enum CurrencyERC20 {USDT, USDC, DAI, MST, WETH, WBTC} 
    /**
     *  @dev add new currency for using
     *  @param _token_contract address of a new token
     */
    function AddCustomCurrency(address _token_contract) external;

    /**
     *  @dev get hardcoded currency
     *  @param currency CurrencyERC20 enum id
     */
    function get_hardcoded_currency(CurrencyERC20 currency)
        external
        view
        returns (IERC20Metadata);
}

pragma solidity ^0.8.0;

// SPDX-License-Identifier: UNLICENSED


//../node_modules/
import './CurrenciesERC20.sol';
import './FeesCalculator.sol';
//import "./interfaces/IMetaMarketplace.sol";


import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";


// direct imports
/*
import "../node_modules/@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "../node_modules/@openzeppelin/contracts/utils/introspection/ERC165.sol";
*/




//import "@openzeppelin/contracts/access/Ownable.sol";




/**
 * @title NFT MetaMarketplace with ERC-165 support
 * @author JackBekket https://github.com/JackBekket
 * original idea from https://github.com/benber86/nft_royalties_market
 * @notice Defines a marketplace to bid on and sell NFTs.
 *         each marketplace is a struct tethered to nft-token contract
 * @notice This contract is COPYRIGHTED, ALL RIGHTS RESERVED 
 *         
 */
contract MetaMarketplace is ERC165, Ownable {


    /**
     *  @notice offers from owner of nft-s, who are willing to sell them
     */
    struct SellOffer {
        address seller;
        mapping(CurrenciesERC20.CurrencyERC20 => uint256) minPrice; // price tethered to currency
    }

    /**
     *  @notice offers from users, who want to buy nfts
     */
    struct BuyOffer {
        address buyer;
        uint256 price; 
        uint256 createTime;
    }

    struct Receipt {
        uint256 lastPriceSold;
        CurrenciesERC20.CurrencyERC20 currencyUsed;
    }

    // URI, 721Enumerable,721Metadata, erc721(common) // TODO: delete MoonShard type, add Telegram type and URIStorage general type
    enum NftType {Telegram, Enum, Meta, Common,URIStorage}

    struct Marketplace {
        // Store all active sell offers  and maps them to their respective token ids
        mapping(uint256 => SellOffer) activeSellOffers;
        // Store all active buy offers and maps them to their respective token ids
        mapping(uint256 => mapping(CurrenciesERC20.CurrencyERC20 => BuyOffer)) activeBuyOffers;
        // Store the last price & currency item was sold for
        mapping(uint256 => Receipt) lastPrice;
        // Escrow for buy offers
        // buyer_address => token_id => Currency => locked_funds
        mapping(address => mapping(uint256 => mapping(CurrenciesERC20.CurrencyERC20 => uint256))) buyOffersEscrow;
       
        // defines which interface to use for interaction with NFT
        NftType nft_standard;
        bool initialized;

        //TODO : add royalties reciver address and royalties fee percentage here
        // this value can be hold by *owners of collection*
        address payable collectionOwner;
        uint ownerFee;
    }

    // from nft token contract address to marketplace
    mapping(address => Marketplace) public Marketplaces;


    // Currencies lib
    CurrenciesERC20 _currency_contract;


    uint public promille_fee = 15; // service fee (1.5%)
    // Address where we collect comission
    address payable public _treasure_fund;
    
  //  uint public royalty_fee = 15;


    //Hardcode interface_id's
    bytes4 private constant _INTERFACE_ID_MSNFT = 0x780e9d63;
    bytes4 private constant _INTERFACE_ID_IERC721ENUMERABLE = 0x780e9d63;
    bytes4 private constant _INTERFACE_ID_IERC721METADATA = 0x5b5e139f;
    bytes4 private constant _INTERFACE_ID_IERC721= 0x80ac58cd;    
    // TODO: add InterfaceID to URIStorage, Telegram
    //bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;


    // Events
    event NewSellCategory(string indexed category, address nft_contract_, uint256 tokenId);
    event NewSellOffer(address nft_contract_, uint256 tokenId, address seller, uint256 value);
    event NewBuyOffer(address nft_contract_, uint256 tokenId, address buyer, uint256 value);
    event SellOfferWithdrawn(address indexed nft_contract_, uint256 indexed tokenId, address seller);
    event BuyOfferWithdrawn(address indexed nft_contract_, uint256 indexed tokenId, address buyer);
    event CalculatedFees(uint256 initial_value, uint256 fees, uint256 transfered_amount, address feeAddress);
    event RoyaltiesPaid(address nft_contract_,uint256 tokenId, address recepient, uint value);
    event Sale(address indexed nft_contract_, uint256 indexed tokenId, address seller, address buyer, uint256 value);
    event NewMarketplace(address nft_contract_);
    

    constructor(address currency_contract_, address telegram_collection_,address payable treasure_fund_) 
    {
        _currency_contract = CurrenciesERC20(currency_contract_);
        require(_checkStandard(telegram_collection_, NftType.Telegram), "Standard not supported");
        SetUpMarketplace(telegram_collection_, NftType.Telegram,treasure_fund_,30);      // set up Telegram ready for sale
        _treasure_fund = treasure_fund_;
    }



    function SetUpMarketplace(address nft_contract_, NftType standard_, address payable collection_owner_, uint collection_fee_) public 
    {   
        require(Marketplaces[nft_contract_].initialized == false, "Marketplace is already setted up");

        Marketplace storage metainfo = Marketplaces[nft_contract_];
        metainfo.nft_standard = standard_;
        metainfo.initialized = true;
        metainfo.collectionOwner = collection_owner_;
        metainfo.ownerFee = collection_fee_; 
        emit NewMarketplace(nft_contract_);
    }

    // admin can change royalties reciver and fee in extreme cases
    function editMarketplace(address nft_contract_, address payable collection_owner_, uint collection_fee_) onlyOwner public {
        require(Marketplaces[nft_contract_].initialized == true, "Marketplace is not exist yet");
        Marketplace storage metainfo = Marketplaces[nft_contract_];
        metainfo.collectionOwner = collection_owner_;
        metainfo.ownerFee = collection_fee_; 
    }

    /**
     *  @dev set service global fee (onlyOwner)
     */
    function SetServiceFee(uint promille_fee_, address payable treasure_fund_) onlyOwner public
    {
        promille_fee = promille_fee_;
        _treasure_fund = treasure_fund_;
    }

    /**
    *   @notice check if contract support specific nft standard
    *   @param standard_ is one of ERC721 standards (MSNFT, 721Enumerable,721Metadata, erc721(common))
    *   it will return false if contract not support specific interface
    *   
    */
    function _checkStandard(address contract_, NftType standard_) internal view returns (bool) {

        
         if(standard_ == NftType.Enum) {
            (bool success) = IERC721Enumerable(contract_).
            supportsInterface(_INTERFACE_ID_IERC721ENUMERABLE);
            return success;
        }
        if (standard_ == NftType.Meta) {
            (bool success) = IERC721Metadata(contract_).
            supportsInterface(_INTERFACE_ID_IERC721METADATA);
            return success;
        }
        if (standard_ == NftType.Common) {
            (bool success) = IERC721(contract_).
            supportsInterface(_INTERFACE_ID_IERC721);
            return success;
        }
        if (standard_ == NftType.Telegram) {             // Telegram is URIStorage
            (bool success) = IERC721Metadata(contract_).  
            supportsInterface(_INTERFACE_ID_IERC721METADATA);
            return success;
        }
        if(standard_ == NftType.URIStorage) {           // URIStorage is MetaData
            (bool success) = IERC721Metadata(contract_).
            supportsInterface(_INTERFACE_ID_IERC721METADATA);
            return success;
        }
    }
    


    /** 
    * @notice Puts a token on sale at a given price
    * @param tokenId - id of the token to sell
    * @param minPrice - minimum price at which the token can be sold
    * @param nft_contract_ -- address of nft contract
    */
    function makeSellOffer(uint256 tokenId, uint256 minPrice, address nft_contract_, CurrenciesERC20.CurrencyERC20 currency_, string memory category_)
    external marketplaceSetted(nft_contract_) isMarketable(tokenId,nft_contract_) tokenOwnerOnly(tokenId,nft_contract_) 
    {
        Marketplace storage metainfo = Marketplaces[nft_contract_];
        // Create sell offer
        metainfo.activeSellOffers[tokenId].minPrice[currency_] = minPrice;
        metainfo.activeSellOffers[tokenId].seller = msg.sender;

        // Broadcast sell offer
        emit NewSellOffer(nft_contract_,tokenId, msg.sender, minPrice);
        emit NewSellCategory(category_,nft_contract_,tokenId);
    }


    /**
    * @notice Withdraw a sell offer. It's called by the owner of nft. 
    *         it will remove offer for every currency (it's intended behaviour)
    * @param tokenId - id of the token whose sell order needs to be cancelled
    * @param nft_contract_ - address of nft contract
    */
    function withdrawSellOffer(address nft_contract_,uint256 tokenId)
    external marketplaceSetted(nft_contract_) isMarketable(tokenId, nft_contract_)
    {
        Marketplace storage metainfo = Marketplaces[nft_contract_];
        require(metainfo.activeSellOffers[tokenId].seller != address(0),
            "No sale offer");
        require(metainfo.activeSellOffers[tokenId].seller == msg.sender,
            "Not seller");
        // Removes the current sell offer
        delete (metainfo.activeSellOffers[tokenId]);
        // Broadcast offer withdrawal
        emit SellOfferWithdrawn(nft_contract_,tokenId, msg.sender);
    }


    // deduct royalties, Service fee is promille_fee (taken when sale) + royalties to those who setted up marketplace
    function _deductRoyalties(address nft_token_contract_, uint256 grossSaleValue) internal view returns (address royalties_reciver,uint256 royalties_amount) {

        // check nft type
        NftType standard = Marketplaces[nft_token_contract_].nft_standard;
        if (standard == NftType.Telegram) 
        {
            royalties_reciver = _treasure_fund;
            royalties_amount = FeesCalculator.calculateAbstractFee(grossSaleValue,1000,promille_fee);
        } else
        {
            Marketplace storage m = Marketplaces[nft_token_contract_];
            royalties_reciver = m.collectionOwner;
            //uint256 royalties_ct = m.ownerFee;
            royalties_amount = FeesCalculator.calculateAbstractFee(grossSaleValue,1000,m.ownerFee);
        }
           return (royalties_reciver,royalties_amount);
    }



    /**
    * @notice Purchases a nft-token. Require active sell offer from owner of nft. Otherwise use makeBuyOffer
    *         also require bid_price_ equal or bigger than desired price from sell offer
    * @param tokenId - id of the token to sell
    * @param bid_price_ -- price buyer is willing to pay to the seller
    */
    function purchase(address token_contract_,uint256 tokenId,CurrenciesERC20.CurrencyERC20 currency_, uint256 bid_price_)
    external marketplaceSetted(token_contract_) tokenOwnerForbidden(tokenId,token_contract_) {
       
        Marketplace storage metainfo = Marketplaces[token_contract_];
        address seller = metainfo.activeSellOffers[tokenId].seller;
        require(seller != address(0),
            "No active sell offer");


        // If, for some reason, the token is not approved anymore (transfer or
        // sale on another market place for instance), we remove the sell order
        // and throw
        IERC721 token = IERC721(token_contract_);
        if (token.getApproved(tokenId) != address(this)) {
            delete (metainfo.activeSellOffers[tokenId]);
            // Broadcast offer withdrawal
            emit SellOfferWithdrawn(token_contract_,tokenId, seller);
            // Revert
            revert("Invalid sell offer");
        }

        //require(metainfo.activeSellOffers[tokenId].minPrice[currency_] > 0, "price for this currency has not been setted, use makeBuyOffer() instead");
        require(metainfo.activeSellOffers[tokenId].minPrice[currency_] > 0, "use makeBuyOffer()");
        require(bid_price_ >= metainfo.activeSellOffers[tokenId].minPrice[currency_],
            "Bid amount lesser than desired price!");


        // Transfer funds (ERC20-currency) to the seller and distribute fees
        if(_processPurchase(token_contract_,tokenId,currency_,msg.sender,seller,bid_price_) == false) {
          //  delete metainfo.activeBuyOffers[tokenId][currency_];                    // if we can't move funds from buyer to seller, then buyer either don't have enough balance nor approved spending this much, so we delete this order
            revert("Approved amount is lesser than (bid_price_)");
        }

        // Save the price & currency used
        metainfo.lastPrice[tokenId].lastPriceSold = bid_price_;
        metainfo.lastPrice[tokenId].currencyUsed = currency_;

        // And transfer nft_token to the buyer
        token.safeTransferFrom(
            seller,
            msg.sender,
            tokenId
        );

        // Remove all sell and buy[currency_] offers
        delete (metainfo.activeSellOffers[tokenId]);            // this nft is SOLD, remove all SellOffers
        // @note: next line will delete offers by specific currency, which help us to avoid situtation when buyer offers made in another currency clog in this contract
      //  delete (metainfo.activeBuyOffers[tokenId][currency_]);  // at least it was most successful order from BuyOffers by *this* currency. Orders for buy for other currencies still alive
        
        // Broadcast the sale
        emit Sale( token_contract_,
            tokenId,
            seller,
            msg.sender,
            bid_price_);
    }



    /**
    * @notice Makes a buy offer for a token. The token does not need to have
    *         been put up for sale. A buy offer can not be withdrawn or
    *         replaced for 24 hours. Amount of the offer is put in escrow
    *         until the offer is withdrawn or superceded
    *
    * @param tokenId - id of the token to buy
    * @param currency_ - in what currency we want to pay
    * @param bid_price_ - how much we are willing to offer for this nft
    */
    function makeBuyOffer(address token_contract_, uint256 tokenId,CurrenciesERC20.CurrencyERC20 currency_, uint256 bid_price_)
    external marketplaceSetted(token_contract_) tokenOwnerForbidden(tokenId,token_contract_)
     {

        Marketplace storage metainfo = Marketplaces[token_contract_];
        // Reject the offer if item is already available for purchase at a
        // lower or identical price
        if (metainfo.activeSellOffers[tokenId].minPrice[currency_] != 0) {
        require((bid_price_ > metainfo.activeSellOffers[tokenId].minPrice[currency_]),
            "Sell order at this price or lower exists");
        }

        // Only process the offer if it is higher than the previous one or the
        // previous one has expired
        require(metainfo.activeBuyOffers[tokenId][currency_].createTime <
                (block.timestamp - 1 days) || bid_price_ >
                metainfo.activeBuyOffers[tokenId][currency_].price,
                "Previous buy offer higher or not expired");

        address previousBuyOfferOwner = metainfo.activeBuyOffers[tokenId][currency_].buyer;
        uint256 refundBuyOfferAmount = metainfo.buyOffersEscrow[previousBuyOfferOwner][tokenId][currency_];
        // Refund the owner of the previous buy offer
        if (refundBuyOfferAmount > 0) {
           _sendRefund(currency_, previousBuyOfferOwner, refundBuyOfferAmount);
        }
        metainfo.buyOffersEscrow[previousBuyOfferOwner][tokenId][currency_] = 0;    // zero escrow after refund
        
        // pull bid payment for lock
        require(_pullFunds(currency_,msg.sender,bid_price_), "can't pull funds from buyer to Marketplace contract");

        // Create a new buy offer
        metainfo.activeBuyOffers[tokenId][currency_].buyer = msg.sender;
        metainfo.activeBuyOffers[tokenId][currency_].price = bid_price_;
        metainfo.activeBuyOffers[tokenId][currency_].createTime = block.timestamp;
        // Create record of funds deposited for this offer
        metainfo.buyOffersEscrow[msg.sender][tokenId][currency_] = bid_price_;    


        // Broadcast the buy offer
        emit NewBuyOffer(token_contract_,tokenId, msg.sender, bid_price_);
    }

    

    /**  @notice Withdraws a buy offer. Can only be withdrawn a day after being posted
    *    @param tokenId - id of the token whose buy order to remove
    *    @param currency_ -- in which currency we want to remove offer
    */
    function withdrawBuyOffer(address token_contract_,uint256 tokenId,CurrenciesERC20.CurrencyERC20 currency_)
    external marketplaceSetted(token_contract_) lastBuyOfferExpired(tokenId,token_contract_,currency_) {
        
        Marketplace storage metainfo = Marketplaces[token_contract_];
        require(metainfo.activeBuyOffers[tokenId][currency_].buyer == msg.sender,
            "Not buyer");
        uint256 refundBuyOfferAmount = metainfo.buyOffersEscrow[msg.sender][tokenId][currency_];
        // Set the buyer balance to 0 before refund ---- ??? why? (i removed this but stick this comment in case of fire)
 
        // Refund the current buy offer if it is non-zero
        if (refundBuyOfferAmount > 0) {
            _sendRefund(currency_, msg.sender, refundBuyOfferAmount);
        }

        // Set the buyer balance to 0 after refund 
        metainfo.buyOffersEscrow[msg.sender][tokenId][currency_] = 0;
        // Remove the current buy offer
        delete(metainfo.activeBuyOffers[tokenId][currency_]);

        // Broadcast offer withdrawal
        emit BuyOfferWithdrawn(token_contract_,tokenId, msg.sender);
    }



    /** @notice Lets a token owner accept the current buy offer
    *         (even without a sell offer)
    * @param tokenId - id of the token whose buy order to accept
    * @param currency_ - in which currency we want to accept offer
    */
    function acceptBuyOffer(address token_contract_, uint256 tokenId,CurrenciesERC20.CurrencyERC20 currency_ )
    external isMarketable(tokenId,token_contract_) tokenOwnerOnly(tokenId,token_contract_) {
        Marketplace storage metainfo = Marketplaces[token_contract_];
        address currentBuyer = metainfo.activeBuyOffers[tokenId][currency_].buyer;
        require(currentBuyer != address(0),
            "No buy offer");
        uint256 bid_value = metainfo.activeBuyOffers[tokenId][currency_].price;

        // Delete the current sell offer whether it exists or not
        delete (metainfo.activeSellOffers[tokenId]);
        // Delete the buy offer that was accepted
        delete (metainfo.activeBuyOffers[tokenId][currency_]);
        // Withdraw buyer's balance
        metainfo.buyOffersEscrow[currentBuyer][tokenId][currency_] = 0;

        
        // Transfer funds to the seller
        // Tries to forward funds from this contract (which already has been locked when makeBuyOffer executed) to seller and distribute fees
        require(_forwardFunds(token_contract_,tokenId,currency_, msg.sender, bid_value), "Can't forward funds to seller");
        
        // Save the price & currency used
        metainfo.lastPrice[tokenId].lastPriceSold = bid_value;
        metainfo.lastPrice[tokenId].currencyUsed = currency_;

        // And transfer nft token to the buyer
       // MSNFT token = MSNFT(token_contract_);
        IERC721 token = IERC721(token_contract_);
        token.safeTransferFrom(msg.sender,currentBuyer,tokenId);
    
        // Broadcast the sale
        emit Sale( token_contract_,
            tokenId,
            msg.sender,
            currentBuyer,
            bid_value);
    }
    


    /*
    function calculateAbstractFee(uint256 amount, uint256 scale, uint256 promille_fee_) public pure returns(uint256) {
        uint a = amount / scale;
        uint b = amount % scale;
        uint c = promille_fee_ / scale;
        uint d = promille_fee_ % scale;
        return a * c * scale + a * d + b * c + (b * d + scale - 1) / scale;
    }
    */

    /**
     * @dev Determines how ERC20 is stored/forwarded on *purchases*. Here we take our fee. This function can be tethered to buy tx or can be separate from buy flow.
     * @notice transferFrom(from_) to this contract and then split payments into treasure_fund fee and send rest of it to_ .  Will return false if approved_balance < amount
     * @param currency_ ERC20 currency. Seller should specify what exactly currency he/she want to out
     */
    function _processPurchase(address nft_contract_, uint256 tokenId, CurrenciesERC20.CurrencyERC20 currency_, address from_, address to_, uint256 amount) internal returns (bool){
       
        IERC20 _currency_token = _currency_contract.get_hardcoded_currency(currency_);
        uint256 approved_balance = _currency_token.allowance(from_, address(this));
        if(approved_balance < amount) {
           // revert("Bad buy offer");
           return false;    // return false if spender have not approved balance for deal
        }

        //uint256 scale = 1000;
        uint256 fees = FeesCalculator.calculateAbstractFee(amount,1000,promille_fee);  // service fees

        // check royalties
        address r_reciver;
        uint256 r_amount;
        (r_reciver,r_amount) = _deductRoyalties(nft_contract_,amount);

        uint256 net_amount = amount - fees - r_amount;
        require(_currency_token.transferFrom(from_, address(this), amount), "transferFrom buyer to metamarketplace contract failed");  // pull funds
        _currency_token.transfer(to_, net_amount);      // forward funds to seller
        _currency_token.transfer(_treasure_fund, fees); // collect fees
        
        if (r_amount > 0) 
        {
            _currency_token.transfer(r_reciver, r_amount);
            emit RoyaltiesPaid(nft_contract_,tokenId,r_reciver, r_amount);
        }

        emit CalculatedFees(amount,fees,net_amount,_treasure_fund);
        return true;
    }



    /**
     * @dev Determines how ERC20 is forwarded on *accepting* buy offer. Here we take our fee. 
     * @notice this function do not pull funds (cause it's already has been pulled from buyer when he/she makes makeBuyOffer)
     * @param currency_ ERC20 currency. Seller should specify what exactly currency he/she want to out 
     * @param to_ seller address
     */
    function _forwardFunds(address nft_contract_, uint256 tokenId, CurrenciesERC20.CurrencyERC20 currency_, address to_, uint256 amount) internal returns(bool) {
       
        IERC20 _currency_token = _currency_contract.get_hardcoded_currency(currency_);
        
       // uint256 scale = 1000;
        uint256 fees = FeesCalculator.calculateAbstractFee(amount,1000,promille_fee);

        // check royalties
        address r_reciver;
        uint256 r_amount;
        (r_reciver,r_amount) = _deductRoyalties(nft_contract_, amount);

        uint256 net_amount = amount - fees - r_amount;
        _currency_token.transfer(to_, net_amount);      // forward funds
        _currency_token.transfer(_treasure_fund, fees); // collect fees
        if (r_amount > 0) 
        {
            _currency_token.transfer(r_reciver, r_amount);  // forward royalties if appliciable
            emit RoyaltiesPaid(nft_contract_,tokenId,r_reciver, r_amount);
        }

        emit CalculatedFees(amount,fees,net_amount,_treasure_fund);
        return true;
    }

    /**
    * @dev  pull funds from buyer to this contract
    * @param from_ address of buyer where we make pull from
    */
    function _pullFunds(CurrenciesERC20.CurrencyERC20 currency_, address from_, uint256 amount) internal returns(bool) {
        IERC20 _currency_token = _currency_contract.get_hardcoded_currency(currency_);
        require(_currency_token.transferFrom(from_, address(this), amount), "transferFrom buyer to marketplace contract failed, check approval");  // pull funds
        return true;
    }

    // Unsafe refund
    function _sendRefund(CurrenciesERC20.CurrencyERC20 currency_, address to_, uint256 amount_) internal {
        IERC20 _currency_token = _currency_contract.get_hardcoded_currency(currency_);
        require(_currency_token.transfer(to_, amount_), "Can't send refund");
    }

    /**
     *  @dev get last SOLD price, will return null if token is has not been sold at least one time
     */
    function getLastPrice(address token_contract_, uint256 _tokenId) public view returns (uint256 _lastPrice, CurrenciesERC20.CurrencyERC20 currency_ ) { 
        Marketplace storage metainfo = Marketplaces[token_contract_];
        _lastPrice = metainfo.lastPrice[_tokenId].lastPriceSold;
        currency_ = metainfo.lastPrice[_tokenId].currencyUsed;
        return (_lastPrice, currency_);
    }

    /*
    function getMarketplace(address nft_contract) internal view returns (Marketplace storage) {
        Marketplace storage metainfo = Marketplaces[nft_contract];
        return metainfo;
    }
    */

    /*
    function getSellOffer(address nft_contract, uint256 token_id) internal view returns (SellOffer storage) {
        Marketplace storage metainfo = Marketplaces[nft_contract];
        SellOffer storage offer = metainfo.activeSellOffers[token_id];
        return offer;
    }
    */

    /**
     *  dev get minimal prices which has been setted by seller
     *  typically we assume that seller have one desired currency, but it may differ
     *  if you need to get desired currency you need to get this array and then ask if some element is not zero
     *  kinda if (prices[0] != 0 || prices [0] != undefined, then desired currency is USDT
     */
    /*
    function getFloorPrices(address nft_contract, uint256 token_id) public view returns (uint256[] memory prices) {
      //  Marketplace storage metainfo = Marketplaces[nft_contract];
        SellOffer storage offer = Marketplaces[nft_contract].activeSellOffers[token_id];
        //SellOffer storage offer = getSellOffer(nft_contract,token_id);
        //mapping (CurrenciesERC20.CurrencyERC20 => uint256) storage prices = offer.minPrice;
        //uint256[] memory prices;
        prices[0] = offer.minPrice[CurrenciesERC20.CurrencyERC20.USDT];
        prices[1] = offer.minPrice[CurrenciesERC20.CurrencyERC20.USDC];
        prices[2] = offer.minPrice[CurrenciesERC20.CurrencyERC20.DAI];
        prices[3] = offer.minPrice[CurrenciesERC20.CurrencyERC20.WETH];
        prices[4] = offer.minPrice[CurrenciesERC20.CurrencyERC20.WBTC];
        prices[5] = offer.minPrice[CurrenciesERC20.CurrencyERC20.VXPPL];
        return prices;
    }
    */

    /**
     *  @dev get minimal prices which has been setted by seller
     *  typically we assume that seller have one desired currency, but it may differ
     *  if you need to get desired currency you need to get call this function for each currency and if it returns non-zero, then it is desired currency
     */
   function getFloorPriceByCurrency(address nft_contract, uint256 token_id, CurrenciesERC20.CurrencyERC20 currency) external view returns (uint256 floor_price) {
     // SellOffer storage offer = Marketplaces[nft_contract].activeSellOffers[token_id];
      floor_price = Marketplaces[nft_contract].activeSellOffers[token_id].minPrice[currency];
      if (floor_price == 0) {
        return 0;
      } else {
        return floor_price;
      }
   }


    
    function getSeller(address nft_contract, uint256 token_id) public view returns (address seller) {
       // SellOffer storage offer = Marketplaces[nft_contract].activeSellOffers[token_id];
        return seller = Marketplaces[nft_contract].activeSellOffers[token_id].seller;
       // return seller;
    }
    

    /**
     *  @dev get buy offer by token_id and currency
     */
   function getBuyOffer(address nft_contract, uint256 token_id,CurrenciesERC20.CurrencyERC20 currency) external view returns (BuyOffer memory b_offer) {
        return b_offer = Marketplaces[nft_contract].activeBuyOffers[token_id][currency];
   }


    modifier marketplaceSetted(address mplace_) {
        require(Marketplaces[mplace_].initialized == true,
            "Marketplace for this token is not setup yet!");
        _; 
    }



    modifier isMarketable(uint256 tokenId, address nft_contract_) {
        require(Marketplaces[nft_contract_].initialized == true,
            "Marketplace for this nft_contract is not setup yet!");
        IERC721 token = IERC721(nft_contract_);
        require(token.getApproved(tokenId) == address(this),
            "Not approved");
        _;
    }

    // TODO: check this 
    modifier tokenOwnerOnly(uint256 tokenId, address nft_contract_) {
       IERC721 token = IERC721(nft_contract_);
        require(token.ownerOf(tokenId) == msg.sender,
            "Not token owner");
        _;
    }

    modifier tokenOwnerForbidden(uint256 tokenId,address nft_contract_) {
        IERC721 token = IERC721(nft_contract_);
        require(token.ownerOf(tokenId) != msg.sender,
            "You can't buy nft from yourself!");
        _;
    }


    modifier lastBuyOfferExpired(uint256 tokenId,address nft_contract_,CurrenciesERC20.CurrencyERC20 currency_) {
       Marketplace storage metainfo = Marketplaces[nft_contract_];
        require(
            metainfo.activeBuyOffers[tokenId][currency_].createTime < (block.timestamp - 1 days),   // TODO: check this
            "Buy offer not expired");
        _;
    }

    /*
    function supportsInterface(bytes4 interfaceId)
    public view override
    returns (bool) {
       return interfaceId == type(IMetaMarketplace).interfaceId || super.supportsInterface(interfaceId);
    }
    */
}