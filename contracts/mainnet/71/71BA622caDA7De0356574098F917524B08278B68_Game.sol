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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

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
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
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
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @dev Game is the base contract with game logic
contract Game is Ownable {
    using SafeERC20 for IERC20;

    /// @dev Move - enum with kinds of move
    enum Move {
        MoveUnknown,
        MoveRock,
        MoveScissors,
        MovePaper
    }

    /// @dev Round - struct with round information
    struct Round {
        uint256 startedAt; // when round was started
        bytes32 firstPlayerHash; // first player hash
        Move firstPlayerMove; // first player move
        uint256 firstMoveAt; // first move timestamp
        Move secondPlayerMove; // second player move
        uint256 secondMoveAt; // second move timestamp
        uint256 finishedAt; // round finish timestamp
    }

    /// @dev SingleGame - struct with game parameters
    struct SingleGame {
        IERC20 token;
        address payable firstPlayerAddress; // first player address
        address payable secondPlayerAddress; // second player address
        uint256 createdAt; // game creation timestamp
        uint256 startedAt; // game start timestamp
        uint256 maxMoveDuration; // max move duration
        uint256 bet; // game bet
        uint8 winsRequired; // wins required for win
        uint8 firstPlayerWins; // first player wins
        uint8 secondPlayerWins; // second player wins
    }

    /// @dev emitted when new game is created
    event GameCreation(
        address token,
        string gameId,
        address firstPlayer,
        uint256 createdAt,
        uint256 bet,
        uint256 maxMoveDuration,
        uint8 winsRequired
    );

    /// @dev emitted when second player join the game
    event GameJoin(string gameId, address secondPlayer);

    /// @dev emitted when second player left the game
    event GameLeft(string gameId, address secondPlayer);

    /// @dev emitted when the game is started
    event GameStart(string gameId, uint256 startedAt);

    /// @dev emitted when new round is started
    event GameRoundStart(string gameId, uint256 roundNum, uint256 startedAt);

    /// @dev emitted when first move is done
    event FirstMove(
        string gameId,
        uint256 roundNum,
        bytes32 hash,
        uint256 madeAt
    );

    /// @dev emitted when second move is done
    event SecondMove(
        string gameId,
        uint256 roundNum,
        Move move,
        uint256 madeAt
    );

    /// @dev emitted when the round is finished
    event FinishRound(
        string gameId,
        uint256 roundNum,
        Move firstMove,
        address winner,
        uint256 finishedAt
    );

    /// @dev emitted when the round is finished with timeout
    event FinishRoundWithTimeout(
        string gameId,
        uint256 roundNum,
        address winner,
        uint256 finishedAt
    );

    /// @dev emitted when the game is finished
    event FinishGame(string gameId, address winner);

    /// @dev emitted when the game is camceled
    event GameCancellation(string gameId);

    mapping(string => SingleGame) public games; // id to game map
    mapping(string => Round[]) public rounds; // id to rounds map
    mapping(IERC20 => bool) public availableTokens;
    mapping(IERC20 => uint256) public tokenBalances;
    uint256 public constant fullCommission = 100000; // full commission constant
    uint256 public commission = 0; // commission (100000==100%)
    uint256 public gameTimeout = 0; // game timeout
    uint256 public balance = 0; // balance from fees

    /// @dev constructor
    /// @param  _commission - commission of the game
    constructor(uint256 _commission) {
        require(
            _commission < 100000,
            "GamePlay: commission must be less than 100%"
        );
        _transferOwnership(_msgSender());
        commission = _commission;
    }

    /// @dev update commission setter-function
    /// @param _commission - commission to set
    function updCommission(uint256 _commission) public onlyOwner {
        require(
            _commission < 100000,
            "GamePlay: commission must be less than 100%"
        );
        commission = _commission;
    }

    /// @dev withdraw collected fees
    /// @param receiver - receiver
    /// @param value - value to withdraw
    function withdraw(address payable receiver, uint256 value)
        public
        onlyOwner
    {
        require(
            value <= balance,
            "Game: value should be less or equal than current balance"
        );
        receiver.transfer(value);
        balance -= value;
    }

    function withdrawToken(
        address payable receiver,
        uint256 value,
        IERC20 token
    ) public onlyOwner {
        require(
            value <= tokenBalances[token],
            "Game: value should be less or equal than current balance"
        );
        token.safeTransfer(receiver, value);
        tokenBalances[token] -= value;
    }

    function allowToken(IERC20 token) public onlyOwner {
        require(token != IERC20(address(0)), "Token: invalid token");
        availableTokens[token] = true;
    }

    function banToken(IERC20 token) public onlyOwner {
        require(token != IERC20(address(0)), "Token: invalid token");
        availableTokens[token] = false;
    }

    /// @dev update timeout setter-function
    /// @param _timeout - timeout to set
    function updTimeout(uint256 _timeout) public onlyOwner {
        gameTimeout = _timeout;
    }

    /// @dev function for creating the game
    /// @param gameId - game id
    /// @param maxMoveDuration - max move duration
    /// @param winsRequired - wins required for win
    /// @param bet - token count for game bet
    /// Emits GameCreation event
    function createGame(
        string calldata gameId,
        uint256 maxMoveDuration,
        uint8 winsRequired,
        IERC20 token,
        uint256 bet
    ) external payable {
        require(games[gameId].bet == 0, "GamePlay: game exists");
        require(
            (msg.value > 0 && token == IERC20(address(0))) ||
                (token != IERC20(address(0)) &&
                    availableTokens[token] == true &&
                    bet > 0),
            "GamePlay: bet must be positive"
        );
        require(
            maxMoveDuration <= 5 * 60,
            "GamePlay: max move duration must be less than 5 minutes"
        );
        if (token == IERC20(address(0))) {
            bet = msg.value;
        }
        uint256 createdAt = block.timestamp;
        if (availableTokens[token]) {
            token.safeTransferFrom(_msgSender(), address(this), bet);
        }
        SingleGame memory newGame = SingleGame(
            token,
            payable(_msgSender()),
            payable(address(0)),
            createdAt,
            0,
            maxMoveDuration,
            bet,
            winsRequired,
            0,
            0
        );
        games[gameId] = newGame;
        emit GameCreation(
            address(token),
            gameId,
            _msgSender(),
            createdAt,
            bet,
            maxMoveDuration,
            winsRequired
        );
    }

    /// @dev function for joining the game
    /// @param gameId - game id
    /// Emits GameJoin event
    function joinGame(string calldata gameId) external payable {
        SingleGame storage game = games[gameId];
        require(game.bet > 0, "GamePlay: game doesn't exist");
        require(
            game.secondPlayerAddress == address(0),
            "GamePlay: another player has already joined game"
        );
        if (game.token == IERC20(address(0))) {
            require(msg.value == game.bet, "GamePlay: tx value must equal bet");
        } else {
            game.token.safeTransferFrom(_msgSender(), address(this), game.bet);
        }
        game.secondPlayerAddress = payable(_msgSender());
        emit GameJoin(gameId, _msgSender());
    }

    /// @dev function for leaving the game
    /// @param gameId - game id
    /// Emits GameLeft event
    function leaveGame(string calldata gameId) external {
        SingleGame storage game = games[gameId];
        require(game.bet > 0, "GamePlay: game doesn't exist");
        require(
            game.secondPlayerAddress == _msgSender(),
            "GamePlay: you are not second player"
        );
        require(game.startedAt == 0, "GamePlay: game started");
        if (game.token == IERC20(address(0))) {
            payable(_msgSender()).transfer(game.bet);
        } else {
            game.token.safeTransfer(_msgSender(), game.bet);
        }
        game.secondPlayerAddress = payable(0);
        emit GameLeft(gameId, _msgSender());
    }

    /// @dev function for canceling the game
    /// @param gameId - game id
    /// Emits GameCancellation event
    function cancelGame(string calldata gameId) external {
        SingleGame storage game = games[gameId];
        require(game.bet > 0, "GamePlay: game doesn't exist");
        require(
            game.firstPlayerAddress == _msgSender(),
            "GamePlay: you are not game creator"
        );
        require(game.startedAt == 0, "GamePlay: game started");
        if (game.token == IERC20(address(0))) {
            game.firstPlayerAddress.transfer(game.bet);
            if (game.secondPlayerAddress != address(0)) {
                game.secondPlayerAddress.transfer(game.bet);
            }
        } else {
            game.token.safeTransfer(game.firstPlayerAddress, game.bet);
            if (game.secondPlayerAddress != address(0)) {
                game.token.safeTransfer(game.secondPlayerAddress, game.bet);
            }
        }
        emit GameCancellation(gameId);
        delete games[gameId];
    }

    /// @dev function for starting the game
    /// @param gameId - game id
    /// Emits GameStart event
    /// Emits GameRoundStart event
    function startGame(string calldata gameId) external {
        SingleGame storage game = games[gameId];
        require(game.bet > 0, "GamePlay: game doesn't exist");
        require(
            game.firstPlayerAddress == _msgSender(),
            "GamePlay: you are not game creator"
        );
        require(
            game.secondPlayerAddress != address(0),
            "GamePlay: no second player"
        );
        require(game.startedAt == 0, "GamePlay: game started");
        game.startedAt = block.timestamp;
        rounds[gameId].push(
            Round(
                block.timestamp,
                0x00000000000000000000000000000000,
                Move.MoveUnknown,
                0,
                Move.MoveUnknown,
                0,
                0
            )
        );
        emit GameStart(gameId, game.startedAt);
        emit GameRoundStart(gameId, 0, block.timestamp);
    }

    /// @dev function for making the first move
    /// @param gameId - game id
    /// @param moveHash - hash of the move
    /// Emits FirstMove event
    function makeFirstMove(string calldata gameId, bytes32 moveHash) external {
        SingleGame storage game = games[gameId];
        require(game.bet > 0, "GamePlay: game doesn't exist");
        require(game.startedAt > 0, "GamePlay: not started game");
        Round storage round = rounds[gameId][rounds[gameId].length - 1];
        require(round.firstMoveAt == 0, "GamePlay: move done");
        round.firstPlayerHash = moveHash;
        round.firstMoveAt = block.timestamp;
        emit FirstMove(
            gameId,
            rounds[gameId].length - 1,
            moveHash,
            block.timestamp
        );
    }

    /// @dev function for making the second move
    /// @param gameId - game id
    /// @param move - move
    /// Emits SecondMove event
    function makeSecondMove(string calldata gameId, Move move) external {
        SingleGame storage game = games[gameId];
        require(game.bet > 0, "GamePlay: game doesn't exist");
        require(game.startedAt > 0, "GamePlay: not started game");
        Round storage round = rounds[gameId][rounds[gameId].length - 1];
        require(round.firstMoveAt > 0, "GamePlay: no first move");
        require(round.secondMoveAt == 0, "GamePlay: move done");
        require(
            move == Move.MoveRock ||
                move == Move.MoveScissors ||
                move == Move.MovePaper,
            "GamePlay: move unknown"
        );
        round.secondPlayerMove = move;
        round.secondMoveAt = block.timestamp;
        emit SecondMove(
            gameId,
            rounds[gameId].length - 1,
            move,
            block.timestamp
        );
    }

    /// @dev function for finishing the round
    /// @param gameId - game id
    /// @param data - salt for hashing the move
    /// @param move - move
    /// Emits FinishRound event
    function finishRound(
        string calldata gameId,
        bytes memory data,
        Move move
    ) external {
        SingleGame storage game = games[gameId];
        require(game.bet > 0, "GamePlay: game doesn't exist");
        require(game.startedAt > 0, "GamePlay: not started game");
        Round storage round = rounds[gameId][rounds[gameId].length - 1];
        require(round.firstMoveAt > 0, "GamePlay: no first move");
        require(round.secondMoveAt > 0, "GamePlay: no second move");
        require(
            move == Move.MoveRock ||
                move == Move.MoveScissors ||
                move == Move.MovePaper,
            "GamePlay: move unknown"
        );
        bytes32 hash = calcMoveHash(data, move);
        round.finishedAt = block.timestamp;

        address winner;
        if (hash == round.firstPlayerHash) {
            round.firstPlayerMove = move;
            winner = determineWinner(
                game.firstPlayerAddress,
                game.secondPlayerAddress,
                round.firstPlayerMove,
                round.secondPlayerMove
            );
        } else {
            winner = game.secondPlayerAddress;
        }
        emit FinishRound(
            gameId,
            rounds[gameId].length - 1,
            round.firstPlayerMove,
            winner,
            block.timestamp
        );
        processWinner(gameId, game, winner);
    }

    /// @dev function for finishing the round with timeout
    /// @param gameId - game id
    function finishRoundWithTimeout(string calldata gameId) external {
        SingleGame storage game = games[gameId];
        require(game.bet > 0, "GamePlay: game doesn't exist");
        require(game.startedAt > 0, "GamePlay: not started game");
        Round storage round = rounds[gameId][rounds[gameId].length - 1];
        round.finishedAt = block.timestamp;
        if (round.firstMoveAt == 0) {
            require(
                _msgSender() == game.secondPlayerAddress,
                "GamePlay: you are not second player"
            );
            require(
                block.timestamp > round.startedAt + game.maxMoveDuration,
                "GamePlay: timeout hasn't reached"
            );
            emit FinishRoundWithTimeout(
                gameId,
                rounds[gameId].length - 1,
                game.secondPlayerAddress,
                block.timestamp
            );
            processWinner(gameId, game, game.secondPlayerAddress);
        } else if (round.secondMoveAt == 0) {
            require(
                _msgSender() == game.firstPlayerAddress,
                "GamePlay: you are not first player"
            );
            require(
                block.timestamp > round.firstMoveAt + game.maxMoveDuration,
                "GamePlay: timeout hasn't reached"
            );
            emit FinishRoundWithTimeout(
                gameId,
                rounds[gameId].length - 1,
                game.firstPlayerAddress,
                block.timestamp
            );
            processWinner(gameId, game, game.firstPlayerAddress);
        } else {
            require(
                _msgSender() == game.secondPlayerAddress,
                "GamePlay: you are not second player"
            );
            require(
                block.timestamp > round.secondMoveAt + game.maxMoveDuration,
                "GamePlay: timeout hasn't reached"
            );
            emit FinishRoundWithTimeout(
                gameId,
                rounds[gameId].length - 1,
                game.secondPlayerAddress,
                block.timestamp
            );
            processWinner(gameId, game, game.secondPlayerAddress);
        }
    }

    /// @dev function for processing the winner
    /// @param gameId - game id
    /// @param game - game from the storage
    /// @param winner - winner address
    /// Emits GameRoundStart event when there is no winner yet
    function processWinner(
        string calldata gameId,
        SingleGame storage game,
        address winner
    ) internal {
        if (winner == game.firstPlayerAddress) {
            game.firstPlayerWins++;
        } else if (winner == game.secondPlayerAddress) {
            game.secondPlayerWins++;
        }

        if (game.firstPlayerWins == game.winsRequired) {
            finishGame(gameId, game.bet, game.firstPlayerAddress);
        } else if (game.secondPlayerWins == game.winsRequired) {
            finishGame(gameId, game.bet, game.secondPlayerAddress);
        } else {
            rounds[gameId].push(
                Round(
                    block.timestamp,
                    0x00000000000000000000000000000000,
                    Move.MoveUnknown,
                    0,
                    Move.MoveUnknown,
                    0,
                    0
                )
            );
            emit GameRoundStart(
                gameId,
                rounds[gameId].length - 1,
                block.timestamp
            );
        }
    }

    /// @dev function for finishing the game
    /// @param gameId - game id
    /// @param bet - bet
    /// @param winner - winner address
    /// Emits FinishGame event
    function finishGame(
        string calldata gameId,
        uint256 bet,
        address payable winner
    ) internal {
        SingleGame storage game = games[gameId];
        uint256 win = (bet * (fullCommission - commission)) / fullCommission;
        uint256 fee = bet - win;
        if (game.token == IERC20(address(0))) {
            balance += fee;
            winner.transfer(win);
        } else {
            tokenBalances[game.token] += fee;
            game.token.safeTransfer(winner, win);
        }
        delete games[gameId];
        delete rounds[gameId];
        emit FinishGame(gameId, winner);
    }

    /// @dev function for calculating move hash
    /// @param data- salt
    /// @param move - move
    function calcMoveHash(bytes memory data, Move move)
        internal
        pure
        returns (bytes32)
    {
        bytes memory appended = new bytes(data.length + 1);
        for (uint256 i = 0; i < data.length; i++) {
            appended[i] = data[i];
        }
        if (move == Move.MoveRock) {
            appended[data.length] = abi.encodePacked(uint8(0x1))[0];
        } else if (move == Move.MoveScissors) {
            appended[data.length] = abi.encodePacked(uint8(0x2))[0];
        } else {
            appended[data.length] = abi.encodePacked(uint8(0x3))[0];
        }
        return sha256(appended);
    }

    /// @dev function for determining the winner
    /// @param first - address of the first player
    /// @param second - address of the second player
    /// @param firstMove - move of the first player
    /// @param secondMove - move of the second player
    function determineWinner(
        address first,
        address second,
        Move firstMove,
        Move secondMove
    ) internal pure returns (address) {
        if (isWin(firstMove, secondMove)) {
            return first;
        } else if (isWin(secondMove, firstMove)) {
            return second;
        }
        return address(0);
    }

    /// @dev function for checking the victory
    /// @param firstMove - first player move
    /// @param secondMove - second player move
    /// @return bool - if this is win function return true
    function isWin(Move firstMove, Move secondMove)
        internal
        pure
        returns (bool)
    {
        if (firstMove == Move.MoveRock && secondMove == Move.MoveScissors) {
            return true;
        } else if (
            firstMove == Move.MoveScissors && secondMove == Move.MovePaper
        ) {
            return true;
        } else if (firstMove == Move.MovePaper && secondMove == Move.MoveRock) {
            return true;
        }
        return false;
    }
}