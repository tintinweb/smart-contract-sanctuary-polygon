/**
 *Submitted for verification at polygonscan.com on 2022-10-17
*/

// File: @openzeppelin/contracts/utils/Address.sol


// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
                /// @solidity memory-safe-assembly
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

// File: @openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
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

// File: @openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol


// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;




/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
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

// File: contracts/Raffle.sol


pragma solidity ^0.8.7;





interface StakingPoints {
    function pointsOf(address user) external view returns (uint);
}

interface Lootbox2 {
    function mint(address player, uint quality, uint count) external;
}

interface UniswapRouter {
    function getAmountsOut(uint amountIn, address[] memory path)
        external
        view
        returns (uint[] memory amounts);
}


contract Raffle is Ownable, ReentrancyGuard {

    using SafeERC20 for IERC20;

    address public TRY_CONTRACT;
    address public STAKING_POINTS;
    address public LOOTBOX_CONTRACT;
    address public UNISWAP_ROUTER = 0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff;

    struct Ticket {
        address player;
        uint price;
        bool win; 
    }

    struct Deposit {
        uint roundId;
        uint amount;
    }

    struct Round {
        uint price;
        bool resolved; 
    }

    uint public constant MONDAY = 1654473600;
    uint public DURATION  = 1 weeks;

    uint public TICKET_PRICE_USD = 5 * 10 ** 6;
 
    struct RoundKey {
        uint key;
        bool exists;
    }

    mapping (uint => Round) public rounds;
    mapping (uint => mapping (address => uint)) public playerTicketCounts; 
    mapping (address => uint) public playerWonTicketCounts; 
    mapping (uint => Ticket[]) public tickets;
    mapping (uint => uint) public ticketsWon;
    mapping (address => Deposit[]) public deposits;
    mapping (address => mapping (uint=>RoundKey)) public depositsRoundKeys;
    mapping (address => uint) public balances;

    uint public profitAmount;

    constructor() {

        TRY_CONTRACT = 0xEFeE2de82343BE622Dcb4E545f75a3b9f50c272D;
        STAKING_POINTS = 0x7D605e6E873b8A49B089D398112D7d7deA05168d;
        LOOTBOX_CONTRACT = 0x514419A2b1d5321cB109870ABD2ef3290C791905;
        
        if (block.chainid!=137) {
            TRY_CONTRACT = 0x70FF9b4E261CbeD4EDC4F1a61b408eF9B0416a7d;
            STAKING_POINTS = 0xCDe3dc277De176643dACC17a69c81fdF45B196C3;
            LOOTBOX_CONTRACT = 0xEe12EabEBB6795c3b32E9996bA6a86Afb33E9025;
            DURATION = 5 minutes;
        }

        if (block.chainid==1) {
            DURATION = 5 minutes;
        }

        uint[] memory points = new uint[](8);
        points[0] = 3000;
        points[1] = 15000;
        points[2] = 30000;
        points[3] = 75000;
        points[4] = 150000;
        points[5] = 300000;
        points[6] = 500000;
        points[7] = 2**256-1;

        uint[] memory counts = new uint[](8);
        counts[0] = 1;
        counts[1] = 3;
        counts[2] = 15;
        counts[3] = 25;
        counts[4] = 40;
        counts[5] = 60;           
        counts[6] = 80;           
        counts[7] = 100;           

        setTicketCaps(points, counts);

        address[] memory path = new address[](3);
        path[0] = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;
        path[1] = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;
        path[2] = 0xEFeE2de82343BE622Dcb4E545f75a3b9f50c272D;
        setTokenPricePath(path);
    }

    address[] public tokenPricePath;
    function setTokenPricePath(address[] memory path) public onlyOwner {
        tokenPricePath = path;
    }

    function setUniswapRouter(address value) public onlyOwner {
        UNISWAP_ROUTER = value;
    }

    function setDuration(uint value) public onlyOwner {
        DURATION = value;
    }
 
    function currentRoundId() public view returns(uint) {
        return MONDAY+((block.timestamp - MONDAY)/DURATION)*DURATION;
    }

    function prevRoundId() public view returns(uint) {
        return MONDAY+((block.timestamp - MONDAY - DURATION)/DURATION)*DURATION;
    }

    function nextRoundId() public view returns(uint) {
        return MONDAY+((block.timestamp - MONDAY + DURATION)/DURATION)*DURATION;
    }

    function getRoundPrice() public view returns (uint) {
        return rounds[currentRoundId()].price;
    }

    function roundStarted() public view returns (bool) {
        return (rounds[currentRoundId()].price>0);
    }

    function fetchTicketPrice() public view returns(uint) {
        if (block.chainid!=137) {
            return 1000*10**18+1;
        }
        uint[] memory prices = UniswapRouter(UNISWAP_ROUTER).getAmountsOut(TICKET_PRICE_USD, tokenPricePath);
        return prices[prices.length-1];
    }

    function getTicketPrice() public view returns (uint) {
        uint result = rounds[currentRoundId()].price;
        if (result>0) {
            return result;
        }
        return fetchTicketPrice();
    }

    function setRoundPrice() internal {
       rounds[currentRoundId()].price = fetchTicketPrice();
    }

    function updateRoundPrice() public onlyOwner {
        setRoundPrice();
    }

    function updateRoundPriceCustom(uint value) public onlyOwner {
       rounds[currentRoundId()].price = value;    
    }

    function setRoundPriceNext() public onlyOwner {
       rounds[nextRoundId()].price = fetchTicketPrice();    
    }

    function setRoundPriceNextCustom(uint value) public onlyOwner {
       rounds[nextRoundId()].price = value;    
    }

    function setTicketPriceUSD(uint value) public onlyOwner {
       TICKET_PRICE_USD = value;    
    }


    function getPlayerTicketCap() public view returns (uint) {
        return getPlayerTicketCap(msg.sender);
    }


    uint ticketCapDefault = 1;

    function setTicketCapDefault(uint value) public onlyOwner {
        ticketCapDefault = value;
    }

    struct ticketCap{
        uint points;
        uint counts;
    }

    ticketCap[] public ticketCaps;

    function setTicketCaps(uint[] memory points, uint[] memory counts) public onlyOwner {
        require (points.length>0, 'Invalid input');
        require (points.length==counts.length, 'Invalid input');
        for (uint i=1; i<points.length; i++){
            require(points[i]>points[i-1], 'Points not ordered');
            require(counts[i]>counts[i-1], 'Counts not ordered');
        }
        while (ticketCaps.length>0) {
            ticketCaps.pop();
        }
        for (uint i=0; i<points.length; i++){
            uint pointsConverted;
            if (points[i]!=2**256-1) {
                pointsConverted = points[i]*10**18;
            } else {
                pointsConverted = points[i];
            }
            ticketCaps.push(ticketCap({
                points: pointsConverted,
                counts: counts[i]
            }));
        }
    }

    function getStakingPointsOf(address player) public view returns (uint) {
        return StakingPoints(STAKING_POINTS).pointsOf(player);        
    }

    function getStakingPointsOf() public view returns (uint) {
        return StakingPoints(STAKING_POINTS).pointsOf(msg.sender);        
    }

    function getPlayerTicketCap(address player) public view returns(uint) {
        if (block.chainid!=80001 && block.chainid!=137) {
            return 5;
        }
        uint points = StakingPoints(STAKING_POINTS).pointsOf(player);
        if (points>0) {
            uint ticketCapsLength = ticketCaps.length;
            for (uint i=0; i<ticketCapsLength; i++) {
                if (points<ticketCaps[i].points) {
                    return ticketCaps[i].counts;
                }
            }
        }
        return ticketCapDefault;
    }

    function chargeTry(uint amount) internal {
        if (tokenEnabled) {
            IERC20(TRY_CONTRACT).safeTransferFrom(msg.sender, address(this), amount);
        }
    }

    function withdrawTry(address player, uint amount) internal {
        if (tokenEnabled) {
            IERC20(TRY_CONTRACT).safeTransfer(player, amount);
        }
    }

    bool public tokenEnabled = true;
    function enableToken() public onlyOwner {
        tokenEnabled = true;
    }

    function getMaxWinningTickets(uint roundId) public view returns (uint) {
        uint ticketCount = tickets[roundId].length;
        if (ticketCount==0) {
            return 0;
        }
        if (maxWinningTicketCount>0) {
            return maxWinningTicketCount;
        }
        uint result = (tickets[roundId].length * maxWinningTicketPercent) / 100;
        if (result>0) {
            return result;
        }
        return 1;
    }

    function getMaxWinningTickets() public view returns (uint) {
        return getMaxWinningTickets(currentRoundId());
    }

    function roundResolved(uint roundId) public view returns(bool) {
        return rounds[roundId].resolved;
    }

    function mergeDeposits(address player) public {
        Deposit[] storage playerDeposits = deposits[player];
        uint depositCount = playerDeposits.length;
        if (depositCount==0) {
            return;
        }
        for (int i=0; i<int(depositCount); i++) {
            if (roundResolved(playerDeposits[uint(i)].roundId)) {
                balances[player] += playerDeposits[uint(i)].amount;
                playerDeposits[uint(i)] = playerDeposits[depositCount-1];
                // Rewrite new key for swapped element round
                depositsRoundKeys[player][playerDeposits[uint(i)].roundId].key = uint(i);
                playerDeposits.pop();
                depositCount--;
                if (depositCount==0) {
                    break;
                }
                i--;
            }
        }
    }

    function getFreeBalance(address player) public view returns (uint) {
        Deposit[] storage playerDeposits = deposits[player];
        uint depositCount = playerDeposits.length;
        if (depositCount==0) {
            return balances[player];
        }
        uint unlockableBalance;
        for (uint i=0; i<depositCount; i++) {
            if (roundResolved(playerDeposits[i].roundId)) {
                unlockableBalance += playerDeposits[i].amount;
            }
        }
        return balances[player] + unlockableBalance;

    }

    function getFreeBalance() public view returns (uint) {
        return getFreeBalance(msg.sender);
    }

    function getTotalBalance(address player) public view returns(uint) {
        Deposit[] storage playerDeposits = deposits[player];
        uint depositCount = playerDeposits.length;
        if (depositCount==0) {
            return balances[player];
        }
        uint depositBalance;
        for (uint i=0; i<depositCount; i++) {
            depositBalance += playerDeposits[i].amount;
        }
        return balances[player] + depositBalance;
    }

    function getTotalBalance() public view returns (uint) {
        return getTotalBalance(msg.sender);
    }

    function withdraw(uint amount) public {
        mergeDeposits(msg.sender);
        require(amount<=balances[msg.sender], 'Not enough amount');
        balances[msg.sender] -= amount;
        withdrawTry(msg.sender, amount);
    }

    event TicketBuy(
        address player,
        uint roundId,
        uint ticketId
    );

    function buyTicket(uint count) public nonReentrant {
        uint roundId = currentRoundId();

        //Round storage round = rounds[roundId];
        
        uint ticketPrice = getRoundPrice();
        if (ticketPrice==0) {
            setRoundPrice();
            ticketPrice = getRoundPrice();
        }

        require (playerTicketCounts[roundId][msg.sender]+count<=getPlayerTicketCap(), 'Ticket cap reached in round');
        playerTicketCounts[roundId][msg.sender] += count;
        
        
        uint totalRequired = count*ticketPrice;
        uint depositRequired;

        mergeDeposits(msg.sender);

        if (balances[msg.sender]>0) {
            if (balances[msg.sender]>=totalRequired) {
                balances[msg.sender] -= totalRequired;
                depositRequired = 0;
            } else {
                depositRequired = totalRequired - balances[msg.sender];
                balances[msg.sender] = 0; // New
            }
        } else {
            depositRequired = totalRequired;
        }

        if (depositRequired>0) {
            
            RoundKey storage foundRound = depositsRoundKeys[msg.sender][roundId];
            Deposit[] storage playerDeposits = deposits[msg.sender];
            
            if (foundRound.exists) {
                playerDeposits[foundRound.key].amount += totalRequired; //depositRequired
            } else {
                uint depositsLength = playerDeposits.length;
                playerDeposits.push(Deposit({roundId:roundId, amount:totalRequired})); // depositRequired
                depositsRoundKeys[msg.sender][roundId].key = depositsLength;
                depositsRoundKeys[msg.sender][roundId].exists = true;
            }

            chargeTry(depositRequired);
        }

        uint ticketCount = tickets[roundId].length; 
        for (uint i=0; i<count; i++) {
            tickets[roundId].push(Ticket({player:msg.sender, price: ticketPrice, win:false}));
            emit TicketBuy(msg.sender, roundId, ticketCount);
            ticketCount++;
        }
    }

    event TicketWon(
        uint roundKey,
        uint ticketId
    );

    function winTicket(uint roundId, uint ticketKey) internal returns (bool) {
        Ticket storage ticket = tickets[roundId][ticketKey];
        if (ticket.win) {
            return false;
        }
        ticket.win = true;
        emit TicketWon(roundId, ticketKey);
        RoundKey storage playerRoundKey = depositsRoundKeys[ticket.player][roundId];
        Deposit storage playerRoundDeposit = deposits[ticket.player][playerRoundKey.key];
        playerRoundDeposit.amount -= ticket.price;
        profitAmount += ticket.price;
        playerWonTicketCounts[ticket.player]++;
        return true;
    }

    event RoundResolved (
        uint roundId,
        uint wonTicketCount
    );

    function resolveRound(uint roundId, uint limit) public nonReentrant {
        require (roundId<currentRoundId(), 'Not yet time');
        require (!roundResolved(roundId), 'Round already resolved');
        uint totalTickets = tickets[roundId].length;
        require(totalTickets>0, 'No tickets');
        uint maxWinningTickets = getMaxWinningTickets(roundId);
        uint ticketsWonInRound = ticketsWon[roundId];
        require(ticketsWonInRound<maxWinningTickets && ticketsWonInRound<totalTickets, 'Round already resolved');
        while (ticketsWonInRound<maxWinningTickets && ticketsWonInRound<totalTickets) {
            ticketsWonInRound++;
            uint ticketKey = random_keccak() % tickets[roundId].length;
            while (tickets[roundId][ticketKey].win) {
                ticketKey = random_keccak() % tickets[roundId].length;
            }
            winTicket(roundId, ticketKey);
            limit--;
            if (limit==0) {
                break;
            }
        }
        ticketsWon[roundId] = ticketsWonInRound;
        if (ticketsWonInRound==maxWinningTickets || ticketsWonInRound==totalTickets) {
            rounds[roundId].resolved = true;
            //withdrawProfit();
            emit RoundResolved(roundId, ticketsWonInRound);
        }
    }

    uint public nonce = 1988;
    function random_keccak () internal returns (uint256)
    {
        nonce++;
        if (block.chainid==1) {
            return uint256(keccak256(abi.encodePacked(nonce)));
        }
        return uint256(keccak256(abi.encodePacked(block.number, block.timestamp, nonce, blockhash(block.number - 1))));
    }

    function getProfitAmount() public view returns(uint) {
        return profitAmount;
    }

    function withdrawProfit() public onlyOwner {
        if (profitAmount>0) {
            profitAmount = 0;
            withdrawTry(msg.sender, profitAmount);
        }
    }

    function withdrawProfit(address admin) public onlyOwner {
        if (profitAmount>0) {
            profitAmount = 0;
            withdrawTry(admin, profitAmount);
        }
    }

    uint public maxWinningTicketCount;
    function setMaxWinningTicketCount(uint value) public onlyOwner {
        maxWinningTicketCount = value;
    }


    uint public maxWinningTicketPercent = 20;
    function setMaxWinningTicketPercent(uint value) public onlyOwner {
        maxWinningTicketPercent = value;
    }

    function getPlayerTicketCount () public view returns (uint){
        return playerTicketCounts[currentRoundId()][msg.sender];
    }

    function getPlayerTicketCount (address player) public view returns (uint){
        return playerTicketCounts[currentRoundId()][player];
    }

    function getPlayerWonTicketCount(address player) public view returns (uint) {
        return playerWonTicketCounts[player];
    }

    function getPlayerWonTicketCount() public view returns (uint) {
        return playerWonTicketCounts[msg.sender];        
    }

    function getCurrentRoundTicketCount() public view returns (uint) {
        return getRoundTicketCount(currentRoundId());
    }

    function getRoundTicketCount(uint roundId) public view returns (uint) {
        return tickets[roundId].length;
    }

    event TicketsClaimed(
        address player,
        uint lootboxType,
        uint ticketCount
    );

    function claimLootbox(uint lootboxType, uint count) public nonReentrant {
        require(playerWonTicketCounts[msg.sender]>=count, 'Not enough won tickets');
        playerWonTicketCounts[msg.sender] -= count;
        require(lootboxType==1 || lootboxType==2, 'Invalid type');
        Lootbox2(LOOTBOX_CONTRACT).mint(msg.sender, lootboxType*10+1, count);
        emit TicketsClaimed(msg.sender, lootboxType, count);        
    }

    function addTestWin(address player, uint value) public {
        if (block.chainid!=137) {
            playerWonTicketCounts[player] += value;
        }
    }

    function addTestWin(uint value) public {
        if (block.chainid!=137) {
            playerWonTicketCounts[msg.sender] += value;
        }
    }

    function getChainId() public view returns (uint) {
        return block.chainid;
    }

    function getTime() public view returns (uint) {
        return block.timestamp;
    }

}