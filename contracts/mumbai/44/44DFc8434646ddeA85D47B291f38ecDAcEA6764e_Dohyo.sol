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
pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./libs/IDohyo.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Dohyo is IDohyo, Ownable {
  using SafeERC20 for IERC20;

  /// @notice Community information
  struct CommunityInfo {
    uint communityId; // Unique id of the community
    address communityOwner; // Community owner address
    address[] communityAdmins; // Community admin addresses
    address[] communityMembers; // Community member addresses
    uint communityGamesCounter; // Total games started
    uint joinedAt; // Time when the community joined
  }

  /// @notice Gets incremented for each new community
  uint public communitiesCounter = 0;

  /// @notice Mapping of community ids to CommunityInfo
  mapping(uint => CommunityInfo) public communityInfo;

  /// @notice Mapping of community id to user address to bool
  mapping(uint => mapping(address => bool)) public communityAdmin;

  /// @notice Mapping of community id to user address to bool
  mapping(uint => mapping(address => bool)) public communityMember;

  /// @notice Mapping of all gameIds by a community for each game
  mapping(uint => mapping(address => uint[])) public communityGame;

  /// @notice Mapping of total bets by a community for each token
  mapping(uint => mapping(address => uint)) public communityBetAmount;

  /// @notice Mapping of total winnings by a community for each token
  mapping(uint => mapping(address => uint)) public communityWinAmount;

  /// @notice Mapping of community id to game address to gameId to bool
  mapping(uint => mapping(address => mapping(uint => bool))) public communityGameCounted;

  /// @notice Player information
  struct PlayerInfo {
    uint playerId; // Unique id of the player
    address playerAddress; // Player address
    bytes32 playerName; // Player name
    uint playerGamesCounter; // Total entries in all games
    uint playerWinsCounter; // Total wins in all games
    uint joinedAt; // Time when the player joined
    uint[] memberCommunities; // Communities the player is member of
    uint[] adminCommunities; // Communities the player is admin of
  }

  /// @notice Gets incremented for each new player
  uint public playersCounter = 0;

  /// @notice Mapping of player address to PlayerInfo
  mapping(address => PlayerInfo) public playerInfo;

  /// @notice Mapping of all gameIds by a player for each game
  mapping(address => mapping(address => uint[])) public playerGame;

  /// @notice Mapping of total bets by a player for each token
  mapping(address => mapping(address => uint)) public playerBetAmount;

  /// @notice Mapping of total winnings by a player for each token
  mapping(address => mapping(address => uint)) public playerWinAmount;

  /// @notice Mapping of player address to bool
  mapping(address => bool) public blacklistedPlayer;

  /// @notice Struct of token pairs, addresses and their corresponding pool address
  struct PairInfo {
    bool pairActive;
    address pairAddress;
    address token0Address;
    address token1Address;
  }

  /// @notice Mapping of pairId to PairInfo
  mapping(uint => PairInfo) public pairInfo;

  /// @notice Struct of token addresses, their corresponding pool address
  struct SupportedToken {
    bool tokenActive;
    uint tokenEdge;
    uint tokenGamesCounter;
    uint tokenMaxBet;
    uint tokenMaxPot;
    bool isPartner;
    address partnerAddress;
  }

  /// @notice Gets incremented for each new supported token which is dohyo partner
  uint public partnersCounter = 0;

  /// @notice List of supported token addresses
  mapping(address => SupportedToken) public supportedToken;

  /// @notice Mapping of all gameIds by a token for each game
  mapping(address => mapping(address => uint[])) public supportedTokenGame;

  /// @notice Mapping of total bets for each supported token per game
  mapping(address => mapping(address => uint)) public supportedTokenBetAmount;

  /// @notice Mapping of total winnings for each supported token per game
  mapping(address => mapping(address => uint)) public supportedTokenWinAmount;

  /// @notice Mapping of supported token to game address to gameId to bool
  mapping(address => mapping(address => mapping(uint => bool)))
    public supportedTokenGameCounted;

  /// @notice Mapping of supported token to game address to biggest bet
  mapping(address => mapping(address => uint)) public supportedTokenGameBiggestBet;

  /// @notice Mapping of supported token to game address to biggest pot
  mapping(address => mapping(address => uint)) public supportedTokenGameBiggestPot;

  /// @notice Mapping of game addresses to bool
  mapping(address => bool) public gameOperator;

  /// @notice Mapping of game addresses to bool
  mapping(address => bool) public gameDeprecated;

  /// @notice 5% Edge
  uint public edge = 50;

  /// @notice Treasury address
  address public treasuryAddress;

  /// @notice Max 5% Edge
  uint public constant MAXIMUM_EDGE = 50;

  /// @notice Max 250 members in a community
  uint public constant MAXIMUM_COMMUNITY_SIZE = 250;

  /// @notice An event emitted when a operator gets added
  event OperatorAdded(address indexed operator);

  /// @notice An event emitted when a community is recorded
  event CommunityRecorded(uint indexed communityId);

  /// @notice An event emitted when a community ownership is transferred
  event TransferCommunityOwnership(
    uint indexed communityId,
    address indexed previousOwner,
    address indexed newOwner
  );

  /// @notice An event emitted when a community admin is added
  event CommunityAdminAdded(uint indexed communityId, address indexed adminAddress);

  /// @notice An event emitted when a community admin is removed
  event CommunityAdminRemoved(uint indexed communityId, address indexed adminAddress);

  /// @notice An event emitted when a community member is added
  event CommunityMemberAdded(uint indexed communityId, address indexed memberAddress);

  /// @notice An event emitted when a community member is removed
  event CommunityMemberRemoved(uint indexed communityId, address indexed memberAddress);

  /// @notice An event emitted when a player is recorded
  event PlayerRecorded(uint indexed playerId);

  /// @notice An event emitted when a player name is updated
  event PlayerNameUpdated(
    address indexed playerAddress,
    bytes32 indexed previousName,
    bytes32 indexed newName
  );

  /// @notice An event emmitted when a player enters a game
  event EntryRecorded(
    address indexed playerAddress,
    address gameAddress,
    uint gameId,
    address indexed tokenAddress,
    uint indexed amount
  );

  /// @notice An event emmitted when a player cancels an entry in a game
  event EntryCancelRecorded(
    address indexed playerAddress,
    address indexed tokenAddress,
    uint indexed amount
  );

  /// @notice An event emmitted when a player bets in a game
  event BetRecorded(
    address indexed playerAddress,
    address indexed tokenAddress,
    uint indexed amount
  );

  /// @notice An event emmitted when a player wins in a game
  event WinRecorded(
    address indexed playerAddress,
    address indexed tokenAddress,
    uint indexed amount
  );

  /// @notice An event emitted when a player gets blacklisted or whitelisted
  event BlacklistUpdated(address indexed playerAddress, bool indexed status);

  /// @notice An event emitted when a new token is added to the supported tokens list
  event TokenAdded(address indexed tokenAddress);

  /// @notice An event emitted when a token is removed from the supported tokens list
  event TokenUpdated(address indexed tokenAddress);

  /// @notice An event emitted when a token is removed from the supported tokens list
  event SupportedTokenPartnerUpdated(
    address indexed tokenAddress,
    bool isPartner,
    address indexed partnerAddress
  );

  /// @notice An event emitted when a token pair is updated
  event TokenPairSet(
    uint indexed pairId,
    address indexed pairAddress,
    address token0Address,
    address token1Address
  );

  /// @notice An event emitted the edge rate is updated
  event TokenEdgeUpdated(address indexed caller, uint previousAmount, uint newAmount);

  /// @notice An event emitted when the edge address is updated
  event TreasuryAddressUpdated(
    address indexed caller,
    address indexed previousAddress,
    address indexed newAddress
  );

  /// @notice An event emitted when a game is being deprecated
  event GameDeprecated(address indexed gameAddress);

  modifier onlyGameOperator() {
    require(gameOperator[msg.sender], "Operator: caller is not a operator");
    _;
  }

  function recordCommunity() public {
    recordPlayer(msg.sender);

    communitiesCounter += 1;

    communityInfo[communitiesCounter] = CommunityInfo(
      communitiesCounter,
      msg.sender,
      new address[](1),
      new address[](1),
      0,
      block.timestamp
    );

    CommunityInfo storage community = communityInfo[communitiesCounter];

    community.communityAdmins[0] = msg.sender;
    community.communityMembers[0] = msg.sender;

    communityAdmin[communitiesCounter][msg.sender] = true;
    communityMember[communitiesCounter][msg.sender] = true;

    PlayerInfo storage player = playerInfo[msg.sender];

    player.memberCommunities.push(communitiesCounter);
    player.adminCommunities.push(communitiesCounter);

    emit CommunityRecorded(communitiesCounter);
  }

  function transferCommunityOwnership(uint _communityId, address _newOwner) public {
    CommunityInfo storage community = communityInfo[_communityId];

    require(
      community.communityOwner == msg.sender,
      "Community: caller is not the community owner"
    );

    community.communityOwner = _newOwner;

    emit TransferCommunityOwnership(_communityId, msg.sender, _newOwner);
  }

  function addCommunityAdmin(uint _communityId, address _adminAddress) public {
    CommunityInfo storage community = communityInfo[_communityId];

    require(
      community.communityOwner == msg.sender,
      "Community: caller is not the community owner"
    );
    require(
      communityMember[_communityId][_adminAddress],
      "Community: address is not a member"
    );
    require(
      !communityAdmin[_communityId][_adminAddress],
      "Community: address is already an admin"
    );

    community.communityAdmins.push(_adminAddress);
    communityAdmin[_communityId][_adminAddress] = true;

    emit CommunityAdminAdded(_communityId, _adminAddress);
  }

  function removeCommunityAdmin(uint _communityId, address _adminAddress) public {
    CommunityInfo storage community = communityInfo[_communityId];

    require(
      community.communityOwner == msg.sender,
      "Community: caller is not the community owner"
    );
    require(
      communityAdmin[_communityId][_adminAddress],
      "Community: address is not an admin"
    );

    for (uint i = 0; i < community.communityAdmins.length; i++) {
      if (community.communityAdmins[i] == _adminAddress) {
        community.communityAdmins[i] = community.communityAdmins[
          community.communityAdmins.length - 1
        ];
        community.communityAdmins.pop();
        communityAdmin[_communityId][_adminAddress] = false;
        break;
      }
    }

    PlayerInfo storage player = playerInfo[_adminAddress];

    bool adminRemoved = false;
    for (uint i = 0; i < player.adminCommunities.length; i++) {
      if (player.adminCommunities[i] == _communityId) {
        player.adminCommunities[i] = player.adminCommunities[
          player.adminCommunities.length - 1
        ];
        player.adminCommunities.pop();
        adminRemoved = true;
      }
    }
    require(adminRemoved, "Address not found in array");

    emit CommunityAdminRemoved(_communityId, _adminAddress);
  }

  function addCommunityMember(uint _communityId, address _memberAddress) public {
    CommunityInfo storage community = communityInfo[_communityId];

    require(
      community.communityOwner == msg.sender || communityAdmin[_communityId][msg.sender],
      "Community: caller is not the community owner or admin"
    );
    require(
      !communityMember[_communityId][_memberAddress],
      "Community: address is already a member"
    );
    require(
      community.communityMembers.length < MAXIMUM_COMMUNITY_SIZE,
      "Community: community is full"
    );

    community.communityMembers.push(_memberAddress);
    communityMember[_communityId][_memberAddress] = true;

    PlayerInfo storage player = playerInfo[_memberAddress];

    player.memberCommunities.push(_communityId);

    emit CommunityMemberAdded(_communityId, _memberAddress);
  }

  function removeCommunityMember(uint _communityId, address _memberAddress) public {
    CommunityInfo storage community = communityInfo[_communityId];

    require(
      community.communityOwner == msg.sender || communityAdmin[_communityId][msg.sender],
      "Community: caller is not the community owner or admin"
    );
    require(
      communityMember[_communityId][_memberAddress],
      "Community: address is not a member"
    );
    require(
      !communityAdmin[_communityId][_memberAddress],
      "Community: address is still an admin, remove admin role first"
    );

    for (uint i = 0; i < community.communityMembers.length; i++) {
      if (community.communityMembers[i] == _memberAddress) {
        community.communityMembers[i] = community.communityMembers[
          community.communityMembers.length - 1
        ];
        community.communityMembers.pop();
        communityMember[_communityId][_memberAddress] = false;
        break;
      }
    }

    PlayerInfo storage player = playerInfo[_memberAddress];
    bool memberRemoved = false;
    for (uint i = 0; i < player.memberCommunities.length; i++) {
      if (player.memberCommunities[i] == _communityId) {
        player.memberCommunities[i] = player.memberCommunities[
          player.memberCommunities.length - 1
        ];
        player.memberCommunities.pop();
        memberRemoved = true;
      }
    }

    require(memberRemoved, "Address not found in array");

    emit CommunityMemberRemoved(_communityId, _memberAddress);
  }

  function getCommunityGames(
    uint _communityId,
    address _gameAddress
  ) public view override returns (uint[] memory) {
    return communityGame[_communityId][_gameAddress];
  }

  function getCommunity(
    uint _communityId
  ) public view returns (address, address[] memory, address[] memory, uint, uint) {
    CommunityInfo storage community = communityInfo[_communityId];

    return (
      community.communityOwner,
      community.communityAdmins,
      community.communityMembers,
      community.communityGamesCounter,
      community.joinedAt
    );
  }

  function isCommunityAdmin(
    uint _communityId,
    address _adminAddress
  ) public view override returns (bool) {
    return communityAdmin[_communityId][_adminAddress];
  }

  function isCommunityMember(
    uint _communityId,
    address _memberAddress
  ) public view override returns (bool) {
    return communityMember[_communityId][_memberAddress];
  }

  function recordEntry(
    address _tokenAddress,
    address _playerAddress,
    uint _amount,
    uint _gameId,
    bool _isCommunityGame,
    uint _communityId
  ) public override onlyGameOperator {
    recordPlayer(_playerAddress);

    PlayerInfo storage player = playerInfo[_playerAddress];
    player.playerGamesCounter += 1;

    playerBetAmount[_playerAddress][_tokenAddress] += _amount;
    playerGame[_playerAddress][msg.sender].push(_gameId);

    emit EntryRecorded(_playerAddress, msg.sender, _gameId, _tokenAddress, _amount);

    SupportedToken storage token = supportedToken[_tokenAddress];

    if (!supportedTokenGameCounted[_tokenAddress][msg.sender][_gameId]) {
      supportedTokenGameCounted[_tokenAddress][msg.sender][_gameId] = true;
      supportedTokenGame[_tokenAddress][msg.sender].push(_gameId);
      token.tokenGamesCounter += 1;
    }
    if (_amount > token.tokenMaxBet) {
      token.tokenMaxBet = _amount;
    }
    if (_amount > supportedTokenGameBiggestBet[_tokenAddress][msg.sender]) {
      supportedTokenGameBiggestBet[_tokenAddress][msg.sender] = _amount;
    }
    supportedTokenBetAmount[msg.sender][_tokenAddress] += _amount;

    if (_isCommunityGame) {
      if (!communityGameCounted[_communityId][msg.sender][_gameId]) {
        communityGameCounted[_communityId][msg.sender][_gameId] = true;
        communityGame[_communityId][msg.sender].push(_gameId);

        CommunityInfo storage community = communityInfo[_communityId];
        community.communityGamesCounter += 1;
      }

      communityBetAmount[_communityId][_tokenAddress] += _amount;
    }
  }

  function recordBet(
    address _playerAddress,
    address _tokenAddress,
    uint _amount,
    bool _isCommunityGame,
    uint _communityId
  ) public override onlyGameOperator {
    recordPlayer(_playerAddress);

    playerBetAmount[_playerAddress][_tokenAddress] += _amount;

    SupportedToken storage token = supportedToken[_tokenAddress];

    if (_amount > token.tokenMaxBet) {
      token.tokenMaxBet = _amount;
    }
    if (_amount > supportedTokenGameBiggestBet[_tokenAddress][msg.sender]) {
      supportedTokenGameBiggestBet[_tokenAddress][msg.sender] = _amount;
    }
    supportedTokenBetAmount[msg.sender][_tokenAddress] += _amount;

    emit BetRecorded(_playerAddress, _tokenAddress, _amount);

    if (_isCommunityGame) {
      communityBetAmount[_communityId][_tokenAddress] += _amount;
    }
  }

  function recordEntryCancel(
    address _playerAddress,
    address _tokenAddress,
    uint _amount
  ) public override onlyGameOperator {
    playerBetAmount[_playerAddress][_tokenAddress] -= _amount;

    PlayerInfo storage player = playerInfo[_playerAddress];
    player.playerGamesCounter -= 1;

    SupportedToken storage token = supportedToken[_tokenAddress];

    token.tokenGamesCounter -= 1;
    supportedTokenBetAmount[msg.sender][_tokenAddress] -= _amount;

    emit EntryCancelRecorded(_playerAddress, _tokenAddress, _amount);
  }

  function recordWin(
    address _playerAddress,
    address _tokenAddress,
    uint _amount,
    bool _isCommunityGame,
    uint _communityId
  ) public override onlyGameOperator {
    recordPlayer(_playerAddress);

    playerWinAmount[_playerAddress][_tokenAddress] += _amount;

    PlayerInfo storage player = playerInfo[_playerAddress];
    player.playerWinsCounter += 1;

    SupportedToken storage token = supportedToken[_tokenAddress];

    if (_amount > token.tokenMaxPot) {
      token.tokenMaxPot = _amount;
    }
    if (_amount > supportedTokenGameBiggestPot[_tokenAddress][msg.sender]) {
      supportedTokenGameBiggestPot[_tokenAddress][msg.sender] = _amount;
    }
    supportedTokenWinAmount[msg.sender][_tokenAddress] += _amount;

    emit WinRecorded(_playerAddress, _tokenAddress, _amount);

    if (_isCommunityGame) {
      communityWinAmount[_communityId][_tokenAddress] += _amount;
    }
  }

  function recordPlayer(address _playerAddress) internal {
    PlayerInfo storage player = playerInfo[_playerAddress];
    if (player.playerAddress == address(0)) {
      playerInfo[_playerAddress] = PlayerInfo(
        playersCounter,
        _playerAddress,
        0,
        0,
        0,
        block.timestamp,
        new uint[](0),
        new uint[](0)
      );

      emit PlayerRecorded(playersCounter);

      playersCounter += 1;
    }
  }

  function setPlayerName(bytes32 _name) public {
    recordPlayer(msg.sender);

    PlayerInfo storage player = playerInfo[msg.sender];

    bytes32 oldName = player.playerName;
    player.playerName = _name;

    emit PlayerNameUpdated(msg.sender, oldName, _name);
  }

  function getPlayer(
    address _playerAddress
  )
    public
    view
    returns (uint, address, bytes32, uint, uint, uint[] memory, uint[] memory, uint)
  {
    PlayerInfo storage player = playerInfo[_playerAddress];

    return (
      player.playerId,
      player.playerAddress,
      player.playerName,
      player.playerGamesCounter,
      player.playerWinsCounter,
      player.memberCommunities,
      player.adminCommunities,
      player.joinedAt
    );
  }

  function getPlayerGames(
    address _playerAddress,
    address _gameAddress
  ) public view override returns (uint[] memory) {
    return playerGame[_gameAddress][_playerAddress];
  }

  function getPlayerBets(
    address _playerAddress,
    address _tokenAddress
  ) public view returns (uint) {
    return playerBetAmount[_tokenAddress][_playerAddress];
  }

  function getPlayerWinAmount(
    address _playerAddress,
    address _tokenAddress
  ) public view returns (uint) {
    return playerWinAmount[_tokenAddress][_playerAddress];
  }

  function updateBlacklist(address _playerAddress, bool _status) public onlyOwner {
    blacklistedPlayer[_playerAddress] = _status;

    emit BlacklistUpdated(_playerAddress, _status);
  }

  function isBlacklisted(address _playerAddress) public view override returns (bool) {
    return blacklistedPlayer[_playerAddress];
  }

  function addSupportedToken(
    address _tokenAddress,
    uint _tokenEdge,
    bool _isPartner,
    address _partnerAddress
  ) public onlyOwner {
    SupportedToken storage token = supportedToken[_tokenAddress];

    require(
      _tokenEdge <= MAXIMUM_EDGE,
      "Dohyo::addSupportedToken: Edge should be less than 50 (5%)"
    );
    require(!token.tokenActive, "Dohyo::addSupportedToken: Token was already added");

    supportedToken[_tokenAddress] = SupportedToken(
      true,
      _tokenEdge,
      0,
      0,
      0,
      _isPartner,
      _partnerAddress
    );

    if (_isPartner) {
      partnersCounter++;
    }

    emit TokenAdded(_tokenAddress);
  }

  function removeSupportedToken(address _tokenAddress) public onlyOwner {
    SupportedToken storage token = supportedToken[_tokenAddress];

    require(token.tokenActive, "Dohyo::removeSupportedToken: Token is not active");

    token.tokenActive = false;
    if (token.isPartner) {
      token.isPartner = false;
      partnersCounter--;
    }

    emit TokenUpdated(_tokenAddress);
  }

  function updateSupportedTokenPartner(
    address _tokenAddress,
    bool _isPartner,
    address _partnerAddress
  ) public onlyOwner {
    SupportedToken storage token = supportedToken[_tokenAddress];

    token.isPartner = _isPartner;
    if (_isPartner) {
      token.partnerAddress = _partnerAddress;
      partnersCounter++;
    } else {
      partnersCounter--;
    }

    emit SupportedTokenPartnerUpdated(_tokenAddress, _isPartner, _partnerAddress);
  }

  function updateSupportedTokenEdge(address _tokenAddress, uint _edge) public onlyOwner {
    require(
      _edge < MAXIMUM_EDGE,
      "Dohyo::updateTokenEdge: Edge should be less than 50 (5%)"
    );

    SupportedToken storage token = supportedToken[_tokenAddress];

    uint oldEdge = token.tokenEdge;
    token.tokenEdge = _edge;

    emit TokenEdgeUpdated(msg.sender, oldEdge, _edge);
  }

  function isSupportedToken(address _tokenAddress) public view override returns (bool) {
    SupportedToken storage token = supportedToken[_tokenAddress];

    return token.tokenActive;
  }

  function getSupportedToken(
    address _tokenAddress
  ) public view override returns (bool, bool, address, uint) {
    SupportedToken storage token = supportedToken[_tokenAddress];

    return (token.tokenActive, token.isPartner, token.partnerAddress, token.tokenEdge);
  }

  function setTokenPair(
    uint _pairId,
    bool active,
    address _pairAddress,
    address _token0Address,
    address _token1Address
  ) public onlyOwner {
    pairInfo[_pairId] = PairInfo(active, _pairAddress, _token0Address, _token1Address);

    emit TokenPairSet(_pairId, _pairAddress, _token0Address, _token1Address);
  }

  function getTokenPair(
    uint _pairId
  ) public view override returns (bool, address, address, address) {
    PairInfo storage pair = pairInfo[_pairId];

    return (pair.pairActive, pair.pairAddress, pair.token0Address, pair.token1Address);
  }

  function addGameOperator(address _operator) external onlyOwner {
    gameOperator[_operator] = true;
    emit OperatorAdded(_operator);
  }

  function setGameDeprecated(address _gameAddress) external onlyOwner {
    gameDeprecated[_gameAddress] = true;
    emit GameDeprecated(_gameAddress);
  }

  function isDeprecatedGame(address _gameAddress) external view override returns (bool) {
    return gameDeprecated[_gameAddress];
  }

  function getEdge(address _tokenAddress) public view override returns (uint) {
    SupportedToken storage token = supportedToken[_tokenAddress];

    return token.tokenEdge;
  }

  function setTreasuryRouterAddress(address _treasuryAddress) public onlyOwner {
    require(_treasuryAddress != address(0), "Dohyo::setTreasuryRouterAddress: ZERO");

    address oldTreasuryAddress = treasuryAddress;
    treasuryAddress = _treasuryAddress;

    emit TreasuryAddressUpdated(msg.sender, oldTreasuryAddress, treasuryAddress);
  }

  function getTreasuryAddress() public view override returns (address) {
    return treasuryAddress;
  }

  function drainERC20Token(IERC20 _token, uint _amount, address _to) external onlyOwner {
    _token.safeTransfer(_to, _amount);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface IDohyo {
  function recordEntry(
    address tokenAddress,
    address playerAddress,
    uint amount,
    uint gameId,
    bool isCommunityGame,
    uint communityId
  ) external;

  function recordEntryCancel(
    address playerAddress,
    address tokenAddress,
    uint amount
  ) external;

  function recordBet(
    address playerAddress,
    address tokenAddress,
    uint amount,
    bool isCommunityGame,
    uint communityId
  ) external;

  function recordWin(
    address playerAddress,
    address tokenAddress,
    uint amount,
    bool isCommunityGame,
    uint communityId
  ) external;

  function isSupportedToken(address tokenAddress) external returns (bool);

  function getSupportedToken(
    address tokenAddress
  ) external returns (bool, bool, address, uint);

  function getPlayerGames(
    address playerAddress,
    address gameAddress
  ) external view returns (uint[] memory);

  function getCommunityGames(
    uint communityId,
    address gameAddress
  ) external view returns (uint[] memory);

  function isCommunityAdmin(
    uint communityId,
    address adminAddress
  ) external returns (bool);

  function isCommunityMember(
    uint communityId,
    address adminAddress
  ) external view returns (bool);

  function getEdge(address tokenAddress) external returns (uint);

  function getTreasuryAddress() external returns (address);

  function getTokenPair(uint pairId) external returns (bool, address, address, address);

  function isBlacklisted(address playerAddress) external returns (bool);

  function isDeprecatedGame(address gameAddress) external returns (bool);
}