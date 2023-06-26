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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
import "../../../utils/Address.sol";

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

// SPDX-License-Identifier: MIT
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
pragma solidity >=0.8.1;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../general-components/AuctionERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../interfaces/IBidRouter.sol";
import "../interfaces/IAuctionPool.sol";
import "../interfaces/IAuctionCredit.sol";
import "../library/LinkedAddressList.sol";
import "../general-components/RouterMigratable.sol";

interface IDecimalsToken {
    function decimals() external view returns (uint8);
}

contract AuctionCredit is AuctionERC20, Ownable, RouterMigratable, IAuctionCredit {
    using SafeERC20 for IERC20;
    using StructuredLinkedList for StructuredLinkedList.List;

    event ExpiredTokens(address _user, uint256 _amount);
    event ForceWithdraw(address _user, address _admin, uint256 _amount);
    event SetExpiryDuration(uint256 _newExpiryDuration); 
    event SetPromoterAllowance(address _promoter, uint256 _allowance, uint256 _duration);
    event PromoterMint(address _promoter); //Transfer event will shed the rest of light of the transaction during indexing (i.e amount, to)
    event TimeExhausted(); //ExpiredTokens event emitted will shed the rest of light. Addtionally since there is only one owner, he is allways the sender, so no need to emit him.
    event RouterDeclaredPool(address _pool);
    event QueueCleanup(address _node);
    event UserExpiryUpdated(address _user,uint256 _expiryEpoch);

    /// @notice Router confirms specific transfer/wrapping privileges of itself and pools
    address public bidRouter;

    /// @notice 1:1 peg between credits and pegToken
    IERC20 public immutable pegToken;

    /// @notice handles cases where peg token speaks in decimal count smaller than 18
    uint256 public immutable pegTokenDecimalsDelta;

    /// @notice Credits expire after the duration. Modifier backlog service will return pegToken to team
    uint256 public expiryDuration;

    /// @notice The expiry duration of each user
    mapping(address => uint256) public userExpiry;

    /// @notice promoters may have allowance to mint tokens
    mapping(address => uint256) public promotionMinterAllowance;

    /// @notice promoters allowance has expiry
    mapping(address => uint256) public promotionMinterExpiry;

    /// @notice a task back log for modifier expiry service
    StructuredLinkedList.List public expiryBackLog;

    constructor(string memory _name, string memory _symbol, address _pegToken, address _bidRouter) AuctionERC20(_name, _symbol) {
        require(_bidRouter!=address(0), "Router can not be address(0)");
        pegToken = IERC20(_pegToken);
        //19+ decimal tokens will revert, contract supports up to 18 decimals. If using future compilers, confirm that this still reverts.
        pegTokenDecimalsDelta = 10 ** (18 - IDecimalsToken(_pegToken).decimals());
        bidRouter = _bidRouter;
        expiryDuration = 90 days;
    }

    modifier onlyRouter() override {
        require(msg.sender == bidRouter, "Router only");
        _;
    }

    /// @notice This modifier will help us clear the backlog pseudo-automatically
    modifier clearBackLog() {
        address userAddress = address(0);
        //We'll see if we have some backlog to clear.
        //And that's right, we're using breaks. It's not the most pretty but it is effective here
        unchecked{
            for (uint8 i = 0; i < 4; ++i) {
                (, userAddress) = expiryBackLog.getNextNode(userAddress);
                if (userAddress != address(0)) {
                    if (userExpiry[userAddress] < block.timestamp) expireUser(userAddress);
                    else break; //No more expire-able users
                }
                //End of list
                else break;
            }
        }
        _;
    }

    /// @notice During mint, expired tokens are burnt
    /**
     * @param account The address getting new tokens
     * @param amount The amount of tokens
     */
    function _mint(address account, uint256 amount) internal override clearBackLog {
        require(amount % pegTokenDecimalsDelta == 0, "!match");
        pegToken.safeTransferFrom(msg.sender, address(this), amount / pegTokenDecimalsDelta);
        if (expiryBackLog.nodeExists(account) && userExpiry[account] < block.timestamp) expireUser(account);
        super._mint(account, amount);
        _updateExpiryDate(account);
    }

    /// @notice During bid, router wraps pegToken
    /**
     * @param _amount The amount of pegToken getting wrapped into credits
     */
    function deposit(uint256 _amount) external onlyRouter {
        _mint(msg.sender, _amount);
    }

    /// @notice During finalization, pool unwrap back to pegToken
    /**
     * @param _amount The amount of credits getting unwrapped to pegToken
     */
    function withdraw(uint256 _amount) external {
        require(_amount % pegTokenDecimalsDelta == 0, "!match");
        require(IBidRouter(bidRouter).isPool(msg.sender), "Only pools can unwrap");
        pegToken.safeTransfer(msg.sender, _amount / pegTokenDecimalsDelta);

        _burn(msg.sender, _amount);
    }

    /// @notice When users bid router will transfer credits to the pool
    /**
     * @param from User paying credits on bid
     * @param to Pool address receiving credits on bid
     * @param amount Amount of credits
     */
    function transferFrom(address from, address to, uint256 amount) public override onlyRouter returns (bool) {
        require(
            IBidRouter(bidRouter).isPool(to) || IBidRouter(bidRouter).isPool(from),
            "Only pools receive or send none-minted transfers"
        );
        _transfer(from, to, amount);
        return true;
    }

    /// @notice Only used by transferFrom
    /**
     * @param from Address from which credits are taken (Allways a bidding user)
     * @param to Address to which credits are sent (allways a pool)
     * @param amount Amount being transfered
     */
    function _transfer(address from, address to, uint256 amount) internal override clearBackLog {
        require(balanceOf(from) >= amount, "ERC20: transfer amount exceeds balance"); //making sure user hasn't expired (as normal balance is check by super)
        if (IBidRouter(bidRouter).isPool(to)) {
            //Taken from user to pool during bid, reset users expiry
            _updateExpiryDate(from);
        } else {
            //Pool is refunding credits to user
            //If user expired we'll expire his old tokens first
            if (userExpiry[to] < block.timestamp && expiryBackLog.nodeExists(to)) expireUser(to);
            _updateExpiryDate(to);
        }
        super._transfer(from, to, amount);
    }

    /// @notice Will return 1:1 pegToken to team if a user had expired
    /**
     * @param _user Address of user to expire
     */
    function expireUser(address _user) public {
        require(userExpiry[_user] < block.timestamp, "Time left");
        require(expiryBackLog.nodeExists(_user));
        expiryBackLog.remove(_user);
        //Fee token is meant to be a trustable token to begin with, such as WETH, thus we will not use nonRenterant
        uint256 balance = super.balanceOf(_user);
        pegToken.safeTransfer(IBidRouter(bidRouter).teamAddress(), balance / pegTokenDecimalsDelta); //1:1 ratio with pegToken, returning pegToken to team
        _burn(_user, balance);

        IBidRouter(bidRouter).onExpireThresholdReset(_user);

        emit ExpiredTokens(_user,balance);
    }

    /// @notice Addresses with allowance may provide 1:1 pegToken to mint tokens
    /**
     * @param _to Address receiving new tokens
     * @param _amount Amount of minted tokens
     */
    function promoterMint(address _to, uint256 _amount) external {
        require(promotionMinterAllowance[msg.sender] > 0 && promotionMinterExpiry[msg.sender] > block.timestamp, "No allowance");
        require(!IBidRouter(bidRouter).isPool(_to), "Promoter can't mint to pool");
        require(promotionMinterAllowance[msg.sender] >= _amount, "No allowance left");

        promotionMinterAllowance[msg.sender] -= _amount;

        _mint(_to, _amount);
        emit PromoterMint(msg.sender);
    }

    /// @notice Resets the user's expiry date
    /**
     * @param _user Address having expiry reset
     */
    function _updateExpiryDate(address _user) internal {
        if (expiryBackLog.nodeExists(_user)) expiryBackLog.remove(_user);
        userExpiry[_user] = block.timestamp + expiryDuration;
        expiryBackLog.pushBack(_user);
        emit UserExpiryUpdated(_user,userExpiry[_user]);
    }

    /// @notice Changes the base duration before expiry, does not apply retrospectively
    /**
     * @param _newDuration The new period in seconds of until expiry
     */
    function changeExpiryDuration(uint256 _newDuration) external onlyOwner {
        require(_newDuration>=90 days,"At least 3 monthes to use");
        expiryDuration = _newDuration;
        emit SetExpiryDuration(_newDuration);
        //Note this could create backlog lag which should be cleared by team.
    }

    /// @notice Sets the minting allowance and allowance expiry time
    /**
     * @param _promoter Address getting mitting allowance set
     * @param _amount New allowance amount
     * @param _duration New duration to use allowance
     */
    function setMintingAllowance(address _promoter, uint256 _amount, uint256 _duration) external onlyOwner {
        promotionMinterAllowance[_promoter] = _amount;
        promotionMinterExpiry[_promoter] = block.timestamp + _duration;
        emit SetPromoterAllowance(_promoter,_amount,_duration);
    }

    /// @notice Privileged unwrapping of credits into pegToken
    /**
     * @param _user Address that will have all of their credits turned back into pegToken
     */
    function forceWithdraw(address _user) external onlyOwner {
        userExpiry[_user] = 0;
        require(!IBidRouter(bidRouter).isPool(_user), "Use force expire instead");
        if (expiryBackLog.nodeExists(_user)) expiryBackLog.remove(_user);
        uint256 balance = super.balanceOf(_user);
        pegToken.safeTransfer(_user, balance / pegTokenDecimalsDelta); //1:1 ratio with pegToken, returning pegToken to user
        _burn(_user, balance);
        IBidRouter(bidRouter).onExpireThresholdReset(_user);

        emit ForceWithdraw(_user, msg.sender,balance);
    }

    /// @notice Force burn. Prevents deadlocked credits on dead pools
    /**
     * @param _user Address being forced expired (Or pool in case of pool deprecation)
     */
    function forceExpire(address _user) external onlyOwner {
        userExpiry[_user] = 0;
        if (IBidRouter(bidRouter).isPool(_user)) {
            require(!IAuctionPool(_user).alive(), "Can only expire a pool that was killed");
        }
        if (!expiryBackLog.nodeExists(_user)) expiryBackLog.pushBack(_user);

        expireUser(_user);
        emit TimeExhausted();
    }

    /// @notice abuse protection function
    //Note this function handles an edge case of "brilliant" promoter minting to a pool *before it was declared*, adding it to backlog, can fuck it up.
    /**
     * @param _pool Pool address being protected
     */
    function routerProtectPoolExpiry(address _pool) external onlyRouter {
        userExpiry[_pool] = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
        emit RouterDeclaredPool(_pool);
    }

    /// @notice abuse recovery function
    //Note if promoter caused the edge case, even with protection, it will stuck the back log so we need to free the backlog
    /**
     * @param _pool Pool address being removed from backlog
     */
    function removeFromBackLog(address _pool) external onlyOwner {
        expiryBackLog.remove(_pool);
        emit QueueCleanup(_pool);
    }

    /// @notice If user have expired, his balance is 0. Pool ignore expiry
    /**
     * @param account The account whose balance is being checked
     */
    function balanceOf(address account) public view override returns (uint256) {
        if (!(userExpiry[account] < block.timestamp)) {
            return super.balanceOf(account);
        } // else if (IBidRouter(bidRouter).isPool(account)) {
        //     return super.balanceOf(account);
        // } //note This case ^ is covered by the first statement due to fool-protection design of multi-factory bidRouter
        return 0;
    }

    function availableAllowance(address _promoter) public view returns (uint256) {
        if (promotionMinterExpiry[_promoter] < block.timestamp) {
            return 0;
        }
        return promotionMinterAllowance[_promoter];
    }

    function nextBackLogEntry(address _user) public view returns (address) {
        (, address nextUser) = expiryBackLog.getNextNode(_user);
        return nextUser;
    }

    function migrateRouter(address _newRouter) external override onlyRouter {
        require(_newRouter!=address(0), "Router can not be address(0)");
        emit RouterMigrated(bidRouter, _newRouter);
        bidRouter = _newRouter;
    }

    /// @notice Overriding ERC20 function that should not be used. Reverting with a string to reduce confusion of people adding token to metamask trying to transfer.
    function transfer(address to, uint256 amount) public override returns (bool deafultval) {
        revert("Direct transfers are disabled on credit token");
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "../interfaces/IAuctionERC20.sol";
import "./extensions/IAuctionERC20Metadata.sol";
import "@openzeppelin/contracts/utils/Context.sol";

/**
 * @dev Custome Implementation of ERC20. One that does not include apporval.
 * Auction tokens are special utility tokens used on the AuctionPool, which do not require user approval.
 * Thus there are no allowances.
 */


/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * The default value of {decimals} is 18. To change this, you should override
 * this function so it returns a different value.
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract AuctionERC20 is Context, IAuctionERC20, IAuctionERC20Metadata {
    mapping(address => uint256) private _balances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the default value returned by this function, unless
     * it's overridden.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }


    /**
     * @dev Reminder that there are no allowances in our custome ERC20
     * The "transferFrom" and "transfer" function are overridden in AuctionBonus and AuctionCredit without calling super.
     * (Below is the original ERC20 comments)
    */

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(address from, address to, uint256 amount) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }


    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../../interfaces/IAuctionERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IAuctionERC20Metadata is IAuctionERC20 {
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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

abstract contract RouterMigratable {
    constructor() {}

    event RouterMigrated(address _old, address _net);

    modifier onlyRouter() virtual {
        _;
    }

    function migrateRouter(address _newRouter) external virtual onlyRouter {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

interface IAuctionCredit {
    function deposit(uint256 _amount) external;

    function withdraw(uint256 _amount) external;

    function routerProtectPoolExpiry(address _pool) external;

    function promoterMint(address _to, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IAuctionERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

struct Tokens {
    address feeToken;
    address credit;
    address bonus;
}

interface IAuctionFactory {
    function feeToken() external view returns (address);

    function creditToken() external view returns (address);

    function bonusToken() external view returns (address);

    function stakingTreasury() external view returns (address);

    function bidRouter() external view returns (address);

    function pools(uint256 id) external view returns (address);

    function isOperator(address _operator) external view returns (bool);

    function addUserVolume(address _user, uint256 _amount) external;

    function getTokens() external view returns (Tokens memory);

    function isPool(address _pool) external view returns (bool);

    function poolLength() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "./IAuctionFactory.sol";

enum BidInfoStatus {
    Untouch,
    Valid,
    Invalid,
    Revoked
}

struct BidInfo {
    address bidder;
    uint256 nftListId;
    uint256 amount;
    uint256 bidAt;
    string cipher;
    bytes32 bidHash;
    BidInfoStatus status;
    bool isBonus;
}

struct NFTInfo {
    address nftAddress;
    uint256 nftId;
    NFTInfoStatus status;
    uint256 lastActiveBidList;
    uint256 listPrice;
    address owner;
}
enum NFTInfoStatus {
    Active,
    Delisted,
    Withdrawn
}

interface IAuctionPool {
    function bid(
        address _bidder,
        uint256 _roundId,
        string[] calldata _ciphers,
        bytes32[] calldata _hash,
        uint256 _nftListId,
        bool _isBonus
    ) external;

    function bidFee() external view returns (uint256);

    function factory() external view returns (IAuctionFactory);

    function alive() external view returns (bool);

    function getRoundStatus(uint256 _roundId) external view returns (uint8 _status);

    function totalUserBidsTimeAlive(uint256 _bidListId, address _user) external view returns (uint256);

    function totalBidPerformanceRewards(uint256 _bidListId) external view returns (uint256);

    function totalBidsTimeAlive(uint256 _bidListId) external view returns (uint256);

    function sellerTotalGameReserves(uint256 _bidListId, address _user) external view returns (uint256);

    function totalReserveIncome(uint256 _bidListId) external view returns (uint256);

    function settlementTime(uint256 _roundId) external view returns (uint256);

    function roundIdToBidListId(uint256 _roundId) external view returns (uint256);

    function highestValidBid(uint256 _roundId) external view returns (uint256);

    //function bidsList(uint256 _bidListId, uint256 _bidId) external view returns (BidInfo memory);

    function reserveCount(uint256 _bidListId) external view returns (uint256);

    function roundStartTime(uint256 roundId) external view returns (uint256);

    function minBids() external view returns (uint256);

    function roundDuration() external view returns (uint256);

    function roundCount() external view returns (uint256);

    function valuedBidsLength(uint256 _bidListId) external view returns (uint256);

    function coolOffPeriodStartTime() external view returns (uint256);

    function coolOffPeriodTime() external view returns (uint256);

    function totalBidListCount() external view returns (uint256);

    function whichRoundInitedMyBids(uint256 bidListId) external view returns (uint256);

    function nftInfo(uint256 nftListId) external view returns (NFTInfo memory);

    function whichRoundFinalizedMyBids(uint256 bidList) external view returns (uint256);

    function nftExists(uint256 nftListId) external view returns (bool);

    function pid() external view returns (uint256);

    function maxOffer() external view returns (uint256);

    function slotDecimals() external view returns (uint256);

    function bidListLength(uint256 bidListId) external view returns (uint256);

    function minValue() external view returns (uint256);

    function faceValue() external view returns (uint256);

    function bidTimeAlive(uint256 bidListId, uint256 bidId) external view returns (uint256);

    function bidListSlotsDataReindexer(uint256 bidListId) external view returns (uint256);

    function SlotsData(uint256 reindexerId, uint256 slotIndex) external view returns (uint256);

    function slotBurnTime(uint256 bidListId, uint256 slot) external view returns (uint256);

    function periodOfExtension() external view returns (uint256);

    function bidsForExtension() external view returns (uint256);

    function roundExtensionChunk() external view returns (uint256);

    function extenderBids(uint256 roundId) external view returns (uint256);

    function roundExtension(uint256 roundId) external view returns (uint256);

    function extensionsHad(uint256 roundId) external view returns (uint256);

    function extensionStep() external view returns (uint256);

    //function roundExtensionChunk() external view returns (uint256);
}

abstract contract poolMock is IAuctionPool {
    mapping(uint256 => mapping(uint256 => BidInfo)) public bidsList;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

interface IBidRouter {

    function isPool(address _pool) external view returns (bool);

    function teamAddress() external view returns (address);

    function gasReceiver() external view returns (address);

    /// @notice pool function used when refunding a bid for credits
    function poolTransferTo(address _user, uint256 _amount) external;

    function onExpireThresholdReset(address _user) external;

    function gasFee() external view returns (uint256);

    function bid(
        address _token,
        uint256 _factoryId,
        uint256 _poolId,
        uint256 _roundId,
        string[] calldata _ciphers,
        bytes32[] calldata _hashes,
        uint256 _nftListId
    ) external payable;

    function bidOnBehalf(
        address _user,
        address _token,
        uint256 _factoryId,
        uint256 _poolId,
        uint256 _roundId,
        string[] calldata _ciphers,
        bytes32[] calldata _hashes,
        uint256 _nftListId
    ) external;

    function factoryDeclarePool(address _pool) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IStructureInterface {
    function getValue(address _id) external view returns (address);
}

/**
 * @title StructuredLinkedList
 * @author Vittorio Minacori (https://github.com/vittominacori)
 * @dev An utility library for using sorted linked list data structures in your Solidity project.
 */

library StructuredLinkedList {
    address private constant _NULL = address(0);
    address private constant _HEAD = address(0);

    bool private constant _PREV = false;
    bool private constant _NEXT = true;

    struct List {
        uint256 size;
        mapping(address => mapping(bool => address)) list;
    }

    function listExists(List storage self) internal view returns (bool) {
        if (self.list[_HEAD][_PREV] != _HEAD || self.list[_HEAD][_NEXT] != _HEAD) {
            return true;
        } else {
            return false;
        }
    }

    function nodeExists(List storage self, address _node) internal view returns (bool) {
        if (self.list[_node][_PREV] == _HEAD && self.list[_node][_NEXT] == _HEAD) {
            if (self.list[_HEAD][_NEXT] == _node) {
                return true;
            } else {
                return false;
            }
        } else {
            return true;
        }
    }

    function sizeOf(List storage self) internal view returns (uint256) {
        return self.size;
    }

    function getNode(List storage self, address _node) internal view returns (bool, address, address) {
        if (!nodeExists(self, _node)) {
            return (false, address(0), address(0));
        } else {
            return (true, self.list[_node][_PREV], self.list[_node][_NEXT]);
        }
    }

    function getAdjacent(List storage self, address _node, bool _direction) internal view returns (bool, address) {
        if (!nodeExists(self, _node)) {
            return (false, address(0));
        } else {
            return (true, self.list[_node][_direction]);
        }
    }


    function getNextNode(List storage self, address _node) internal view returns (bool, address) {
        return getAdjacent(self, _node, _NEXT);
    }


    function getPreviousNode(List storage self, address _node) internal view returns (bool, address) {
        return getAdjacent(self, _node, _PREV);
    }

    function getSortedSpot(List storage self, address _structure, address _value) internal view returns (address) {
        if (sizeOf(self) == 0) {
            return address(0);
        }

        address next;
        (, next) = getAdjacent(self, _HEAD, _NEXT);
        while ((next != address(0)) && ((_value < IStructureInterface(_structure).getValue(next)) != _NEXT)) {
            next = self.list[next][_NEXT];
        }
        return next;
    }

    // function insertAfter(List storage self, address _node, address _new) internal returns (bool) {
    //     return _insert(self, _node, _new, _NEXT);
    // }

    // function insertBefore(List storage self, address _node, address _new) internal returns (bool) {
    //     return _insert(self, _node, _new, _PREV);
    // }

    function remove(List storage self, address _node) internal returns (address) {
        if ((_node == _NULL) || (!nodeExists(self, _node))) {
            return address(0);
        }
        _createLink(self, self.list[_node][_PREV], self.list[_node][_NEXT], _NEXT);
        delete self.list[_node][_PREV];
        delete self.list[_node][_NEXT];

        self.size -= 1; // NOT: SafeMath library should be used here to decrement.

        return _node;
    }

    function pushFront(List storage self, address _node) internal returns (bool) {
        return _push(self, _node, _NEXT);
    }

    function pushBack(List storage self, address _node) internal returns (bool) {
        return _push(self, _node, _PREV);
    }

    function popFront(List storage self) internal returns (address) {
        return _pop(self, _NEXT);
    }

    function popBack(List storage self) internal returns (address) {
        return _pop(self, _PREV);
    }

    function _push(List storage self, address _node, bool _direction) private returns (bool) {
        return _insert(self, _HEAD, _node, _direction);
    }

    function _pop(List storage self, bool _direction) private returns (address) {
        address adj;
        (, adj) = getAdjacent(self, _HEAD, _direction);
        return remove(self, adj);
    }

    function _insert(List storage self, address _node, address _new, bool _direction) private returns (bool) {
        if (!nodeExists(self, _new) && nodeExists(self, _node)) {
            address c = self.list[_node][_direction];
            _createLink(self, _node, _new, _direction);
            _createLink(self, _new, c, _direction);

            self.size += 1; // NOT: SafeMath library should be used here to increment.

            return true;
        }

        return false;
    }

    function _createLink(List storage self, address _node, address _link, bool _direction) private {
        self.list[_link][!_direction] = _node;
        self.list[_node][_direction] = _link;
    }
}