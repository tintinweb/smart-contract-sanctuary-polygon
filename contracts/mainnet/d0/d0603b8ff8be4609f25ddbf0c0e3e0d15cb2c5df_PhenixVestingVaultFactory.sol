/**
 *Submitted for verification at polygonscan.com on 2022-12-06
*/

// File: contracts/IPool.sol


pragma solidity >=0.5.0;

interface IPool {
  function token0() external view returns (address);
  function token1() external view returns (address);
}
// File: contracts/IUniswapV2Router01.sol

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

// File: contracts/IUniswapV2Router02.sol

pragma solidity >=0.6.2;


interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

// File: @openzeppelin/contracts/utils/math/SafeMath.sol


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

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


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

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol


// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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

// File: contracts/PhenixVestingVault.sol


pragma solidity ^0.8.9;





contract PhenixVestingVault is Ownable {
    using SafeMath for uint256;

    uint256 public maximumLockDuration = 31536000; // 1 year
    mapping(address => uint256) public tokenERC20UnlockTimestamp;
    mapping(address => uint256) public tokenERC721UnlockTimestamp;
    mapping(address => bool) public isAuthorizedAddress;

    constructor(address _owner, address[] memory _authorizedAddresses) {
        _transferOwnership(_owner);

        for (uint256 i = 0; i < _authorizedAddresses.length; i++) {
            isAuthorizedAddress[_authorizedAddresses[i]] = true;
        }
    }

    modifier isERC20Unlocked(address _tokenERC20Address) {
        require(
            tokenERC20UnlockTimestamp[_tokenERC20Address] == 0 ||
                block.timestamp >=
                tokenERC20UnlockTimestamp[_tokenERC20Address],
            "ERC20 Tokens are not unlocked."
        );
        _;
    }

    modifier isERC721Unlocked(address _tokenERC721Address) {
        require(
            tokenERC721UnlockTimestamp[_tokenERC721Address] == 0 ||
                block.timestamp >=
                tokenERC721UnlockTimestamp[_tokenERC721Address],
            "ERC271 Tokens are not unlocked"
        );
        _;
    }

    modifier isAuthorized() {
        require(
            msg.sender == owner() || isAuthorizedAddress[msg.sender] == true,
            "Not authorized."
        );
        _;
    }

    function updateMaximumLockDuration(uint256 _maximumLockDuration)
        external
        isAuthorized
    {
        maximumLockDuration = _maximumLockDuration;
    }

    function setAuthorizedAddress(address _address, bool _status)
        external
        onlyOwner
    {
        require(_address != owner(), "Cannot set as owner.");
        isAuthorizedAddress[_address] = _status;
    }

    function withdrawERC721Token(uint256 _tokenId, address _tokenERC721Address)
        external
        isAuthorized
        isERC721Unlocked(_tokenERC721Address)
    {
        IERC721(_tokenERC721Address).transferFrom(
            address(this),
            msg.sender,
            _tokenId
        );
    }

    function transferERC721Token(
        uint256 _tokenId,
        address _tokenERC721Address,
        address _to
    ) external isAuthorized isERC721Unlocked(_tokenERC721Address) {
        IERC721(_tokenERC721Address).transferFrom(address(this), _to, _tokenId);
    }

    function withdrawERC20Token(uint256 _amount, address _tokenERC20Address)
        external
        isAuthorized
        isERC20Unlocked(_tokenERC20Address)
    {
        IERC20(_tokenERC20Address).transfer(msg.sender, _amount);
    }

    function transferERC20Token(
        uint256 _amount,
        address _tokenERC20Address,
        address _to
    ) external isAuthorized isERC20Unlocked(_tokenERC20Address) {
        IERC20(_tokenERC20Address).transfer(_to, _amount);
    }

    function setERC20UnlockTime(
        address _tokenERC20Address,
        uint256 _unlockTimestamp
    ) external isAuthorized {
        require(
            _unlockTimestamp > tokenERC20UnlockTimestamp[_tokenERC20Address] &&
                _unlockTimestamp > block.timestamp,
            "Unlock timestamp doesn't exceed existing unlock time."
        );

        require(
            _unlockTimestamp.sub(block.timestamp) <= maximumLockDuration,
            "Lock duration exceeds max lock interval"
        );

        tokenERC20UnlockTimestamp[_tokenERC20Address] = _unlockTimestamp;
    }

    function increaseERC20UnlockTime(
        address _tokenERC20Address,
        uint256 _timestampIncrease
    ) external isAuthorized {
        require(
            tokenERC20UnlockTimestamp[_tokenERC20Address] != 0,
            "Token unlock not initialized."
        );

        require(
            _timestampIncrease <= maximumLockDuration,
            "Lock timestamp increase exceeds max lock interval"
        );

        tokenERC20UnlockTimestamp[
            _tokenERC20Address
        ] = tokenERC20UnlockTimestamp[_tokenERC20Address].add(
            _timestampIncrease
        );
    }

    function setERC721UnlockTime(
        address _tokenERC721Address,
        uint256 _unlockTimestamp
    ) external isAuthorized {
        require(
            _unlockTimestamp >
                tokenERC721UnlockTimestamp[_tokenERC721Address] &&
                _unlockTimestamp > block.timestamp,
            "Unlock timestamp doesn't exceed existing unlock time or does not exceed current block timestamp."
        );

        require(
            _unlockTimestamp.sub(block.timestamp) <= maximumLockDuration,
            "Lock duration exceeds max lock interval"
        );

        tokenERC721UnlockTimestamp[_tokenERC721Address] = _unlockTimestamp;
    }

    function increaseERC721UnlockTime(
        address _tokenERC721Address,
        uint256 _timestampIncrease
    ) external isAuthorized {
        require(
            tokenERC721UnlockTimestamp[_tokenERC721Address] != 0,
            "Token unlock not initialized."
        );

        require(
            _timestampIncrease <= maximumLockDuration,
            "Lock timestamp increase exceeds max lock interval"
        );

        tokenERC721UnlockTimestamp[
            _tokenERC721Address
        ] = tokenERC721UnlockTimestamp[_tokenERC721Address].add(
            _timestampIncrease
        );
    }

    function withdrawETHFunds(uint256 _amount) external isAuthorized {
        require(
            _amount > 0 && address(this).balance >= _amount,
            "Invalid amount or not enough ETH."
        );
        (bool success, ) = payable(msg.sender).call{value: _amount}("");

        require(success, "Failed to withdrawal funds!");
    }

    function transferETHFunds(uint256 _amount, address _to)
        external
        isAuthorized
    {
        require(
            _amount > 0 && address(this).balance >= _amount,
            "Invalid amount or not enough ETH."
        );
        (bool success, ) = payable(_to).call{value: _amount}("");

        require(success, "Failed to transfer funds!");
    }

    receive() external payable {}
}

// File: contracts/PhenixVestingVaultDeployer.sol


pragma solidity ^0.8.9;



contract PhenixVestingVaultDeployer is Ownable {
    constructor() {}

    function deployVestingVault(
        address _address,
        address[] memory _authorizesAddresses
    ) external onlyOwner returns (address) {
        PhenixVestingVault _vault = new PhenixVestingVault(
            _address,
            _authorizesAddresses
        );
        return address(_vault);
    }
}

// File: contracts/PhenixVestingVaultFactory.sol


pragma solidity ^0.8.9;








contract PhenixVestingVaultFactory is Ownable {
    using SafeMath for uint256;

    address constant DEAD = 0x000000000000000000000000000000000000dEaD;
    address public payableTokenAddress;
    address public erc721TokenAddress;
    uint256 public erc721DiscountPercentage;
    uint256 public erc721DiscountPercentageDenominator;
    address public routerAddress = 0x7E5E5957De93D00c352dF75159FbC37d5935f8bF;
    address public usdcPairAddress = 0xAE81FAc689A1b4b1e06e7ef4a2ab4CD8aC0A087D;

    bool public isEnabled;

    struct Fees {
        uint256 feeETH;
        uint256 feeToken;
        bool usdcMode;
    }

    address public deployerAddress;
    mapping(address => address) public contractToOwnerMapping;
    mapping(address => address[]) public ownerToContractMapping;
    mapping(address => bool) public factoryAdmins;
    Fees public vestingVaultTypeFees;

    address[] public deployedContracts;

    constructor(
        uint256 _vestingVaultDeploymentETHFee,
        uint256 _vestingVaultDeploymentTokenFee,
        address _payableTokenAddress,
        address _erc721TokenAddress
    ) {
        payableTokenAddress = _payableTokenAddress;
        erc721TokenAddress = _erc721TokenAddress;

        erc721DiscountPercentage = 50;
        erc721DiscountPercentageDenominator = 100;

        PhenixVestingVaultDeployer deployer = new PhenixVestingVaultDeployer();
        deployerAddress = address(deployer);

        isEnabled = true;

        _setAdminAddress(msg.sender, true);
        _setFees(
            _vestingVaultDeploymentETHFee,
            _vestingVaultDeploymentTokenFee,
            false
        );
    }

    modifier canPayTokenFee() {
        require(
            IERC20(payableTokenAddress).allowance(
                address(msg.sender),
                address(this)
            ) >= userCost(getFeeTokenAmount(), msg.sender),
            "PhenixVestingVaultFactory contract does not have enough allowance to spend tokens on behalf of the user."
        );

        require(
            IERC20(payableTokenAddress).balanceOf(address(msg.sender)) >=
                userCost(getFeeTokenAmount(), msg.sender),
            "User does not have enough tokens to pay for PhenixVestingVault deployment fee."
        );

        _;
    }

    modifier canGenerateVestingVault() {
        require(
            isEnabled == true,
            "PhenixVestingVaultFactory is not currently enabled."
        );
        _;
    }

    function _setFees(
        uint256 _ethFee,
        uint256 _tokenFee,
        bool _usdcMode
    ) internal {
        vestingVaultTypeFees.feeETH = _ethFee;
        vestingVaultTypeFees.feeToken = _tokenFee;
        vestingVaultTypeFees.usdcMode = _usdcMode;
    }

    function setFees(
        uint256 _ethFee,
        uint256 _tokenFee,
        bool _usdcMode
    ) external onlyOwner {
        _setFees(_ethFee, _tokenFee, _usdcMode);
    }

    function setRouterAddress(address _routerAddress) external onlyOwner {
        routerAddress = _routerAddress;
    }

    function setUSDCPairAddress(address _usdcPairAddress) external onlyOwner {
        usdcPairAddress = _usdcPairAddress;
    }

    function _setAdminAddress(address _admin, bool _state) internal {
        factoryAdmins[_admin] = _state;
    }

    function setAdminAddress(address _admin, bool _state) external onlyOwner {
        _setAdminAddress(_admin, _state);
    }

    function setERC721DiscountFee(uint256 _percentage, uint256 _denominator)
        external
        onlyOwner
    {
        erc721DiscountPercentage = _percentage;
        erc721DiscountPercentageDenominator = _denominator;
    }

    function setPayableTokenAddress(address _tokenAddress) external onlyOwner {
        payableTokenAddress = _tokenAddress;
    }

    function setIsEnabled(bool _state) external onlyOwner {
        isEnabled = _state;
    }

    function getPayableTokenBalance() external view returns (uint256) {
        return IERC20(payableTokenAddress).balanceOf(address(this));
    }

    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }

    function getOwnerOfContract(address _address)
        public
        view
        returns (address)
    {
        return contractToOwnerMapping[_address];
    }

    function getContractsOfOwner(address _address)
        public
        view
        returns (address[] memory)
    {
        return ownerToContractMapping[_address];
    }

    function getDeployedContracts(uint256 _startIndex, uint256 _endIndex)
        external
        view
        returns (address[] memory)
    {
        if (_startIndex == 0 && _endIndex == 0) {
            return deployedContracts;
        } else {
            address[] memory _addresses = new address[](
                _endIndex.sub(_startIndex)
            );

            for (uint256 i = _startIndex; i < _endIndex; i++) {
                _addresses[i] = deployedContracts[i];
            }

            return _addresses;
        }
    }

    function numberOfDeployedContracts() external view returns (uint256) {
        return deployedContracts.length;
    }

    function takeETHFees() external onlyOwner {
        require(address(this).balance > 0, "No ETH to claim.");
        (bool success, ) = address(msg.sender).call{
            value: address(this).balance
        }("");
        require(success, "Failed to claim ETH.");
    }

    function takeTokenFees() external onlyOwner {
        require(
            IERC20(payableTokenAddress).balanceOf(address(this)) > 0,
            "No tokens to claim."
        );
        IERC20(payableTokenAddress).transfer(
            msg.sender,
            IERC20(payableTokenAddress).balanceOf(address(this))
        );
    }

    function userCost(uint256 _amount, address _user)
        public
        view
        returns (uint256)
    {
        uint256 _result = _amount;
        if (IERC721(erc721TokenAddress).balanceOf(_user) > 0) {
            // Apply NFT Fee to amount
            _result = _result.mul(erc721DiscountPercentage).div(
                erc721DiscountPercentageDenominator
            );
            _result = _amount - _result;
        }
        return factoryAdmins[_user] == false ? _result : 0;
    }

    function getFeeAmounts()
        external
        view
        returns (
            uint256,
            uint256,
            bool
        )
    {
        return (
            getFeeETHAmount(),
            getFeeTokenAmount(),
            vestingVaultTypeFees.usdcMode
        );
    }

    function getFeeETHAmount() public view returns (uint256) {
        if (vestingVaultTypeFees.usdcMode) {
            IPool pair = IPool(usdcPairAddress);
            uint256 reserve0 = IERC20(pair.token0()).balanceOf(usdcPairAddress);
            uint256 reserve1 = IERC20(pair.token1()).balanceOf(usdcPairAddress);

            uint256 ethPerUsdc = (reserve0 / reserve1) * 1000000;
            return ethPerUsdc * (vestingVaultTypeFees.feeETH / 1 ether);
        } else {
            return vestingVaultTypeFees.feeETH;
        }
    }

    function getFeeTokenAmount() public view returns (uint256) {
        if (vestingVaultTypeFees.usdcMode) {
            IPool pair = IPool(usdcPairAddress);
            uint256 reserve0 = IERC20(pair.token0()).balanceOf(usdcPairAddress);
            uint256 reserve1 = IERC20(pair.token1()).balanceOf(usdcPairAddress);

            uint256 ethPerUsdc = (reserve0 / reserve1) * 1000000;

            address[] memory path = new address[](2);
            path[0] = IUniswapV2Router02(routerAddress).WETH();
            path[1] = payableTokenAddress;

            uint256[] memory amountsOut = IUniswapV2Router02(routerAddress)
                .getAmountsOut(
                    ethPerUsdc * (vestingVaultTypeFees.feeToken / 1 ether),
                    path
                );

            return amountsOut[1];
        } else {
            return vestingVaultTypeFees.feeToken;
        }
    }

    function generateVestingVaultWalletWithETH(
        address _owner,
        address[] memory _authorizedAddresses
    ) external payable canGenerateVestingVault {
        uint256 amountToPay = userCost(getFeeETHAmount(), msg.sender);
        require(
            msg.value >= userCost(amountToPay, msg.sender),
            "Not enough ETH to cover cost."
        );

        if (msg.value > amountToPay) {
            (bool success, ) = address(msg.sender).call{
                value: uint256(msg.value).sub(amountToPay)
            }("");

            require(success, "Failed to transfer ETH.");
        }

        _generateVestingVaultWallet(_owner, _authorizedAddresses);
    }

    function generateVestingVaultWalletWithTokens(
        address _owner,
        address[] memory _authorizedAddresses
    ) external canPayTokenFee canGenerateVestingVault {
        uint256 amountToPay = userCost(getFeeTokenAmount(), msg.sender);
        IERC20(payableTokenAddress).transferFrom(
            msg.sender,
            address(this),
            amountToPay
        );

        _generateVestingVaultWallet(_owner, _authorizedAddresses);
    }

    function _generateVestingVaultWallet(
        address _owner,
        address[] memory _authorizedAddresses
    ) internal {
        address _newVestingVaultWallet = PhenixVestingVaultDeployer(
            deployerAddress
        ).deployVestingVault(_owner, _authorizedAddresses);

        deployedContracts.push(address(_newVestingVaultWallet));
        contractToOwnerMapping[address(_newVestingVaultWallet)] = _owner;
        ownerToContractMapping[_owner].push(address(_newVestingVaultWallet));
    }

    function adminWithdrawTokenFunds(address _tokenAddress, uint256 _amount)
        external
        onlyOwner
    {
        uint256 withdrawalAmount = _amount == 0
            ? IERC20(_tokenAddress).balanceOf(address(this))
            : _amount;

        require(withdrawalAmount > 0, "Invalid withdraw amount.");

        IERC20(_tokenAddress).transfer(msg.sender, withdrawalAmount);
    }

    function adminWithdrawETHFunds(uint256 _amount) external onlyOwner {
        uint256 withdrawalAmount = _amount == 0
            ? address(this).balance
            : _amount;

        require(withdrawalAmount > 0, "Invalid withdraw amount.");

        (bool success, ) = payable(msg.sender).call{value: withdrawalAmount}(
            ""
        );

        require(success, "Failed to withdrawal funds!");
    }

    receive() external payable {}
}