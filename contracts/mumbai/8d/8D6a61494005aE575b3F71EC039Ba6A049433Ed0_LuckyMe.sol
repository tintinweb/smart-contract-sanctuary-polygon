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
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface IRandomNumberGenerator {
    function randomNumberGenerator(uint8 number) external view returns (uint8);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./IRandomNumberGenerator.sol";

contract LuckyMe is Ownable {
  using Counters for Counters.Counter;
  using SafeERC20 for IERC20;
  IRandomNumberGenerator public Number;
  IERC20 public DAI;

  /**
      User Data
   */
  struct userGame {
    uint8 Game;
    uint8 Prize;
    uint256 GameId;
    uint8 LuckyNumber;
  }
  struct pick {
    uint8 Game;
    uint256 GameId;
    uint8 Number;
  }
  struct user {
    uint8 Plan;
    uint256 Id;
    uint256 Ref;
    address Address;
    /**

     */
    uint256[] AllRef;
    /**

     */
    uint256 registerAt;
    uint256 TimeToRenew;
    /**

     */
    uint256 TotalPrizesAmount;
    uint256 TotalPicksRewards;
    uint256 TotalReferralRewards;
    /**
     * @notice
     */
    pick[] Picks;
    userGame[] AllWinLuckyDraw;
  }
  uint32 public Year = 365 days;
  Counters.Counter public UsersIds;
  mapping(uint256 => user) public User;
  mapping(address => uint256) public UserId;
  mapping(address => bool) public isUserExists;
  mapping(uint8 => mapping(uint256 => uint256)) public MembersRefByLevel;
  mapping(uint8 => mapping(uint256 => uint256)) public PartnersRefByLevel;

  /**
      Membership plans
   */
  struct totalRewardsPaid {
    uint256 Prize;
    uint256 PicksRef;
    uint256 MemberRef;
  }
  totalRewardsPaid public TotalRewardsPaid;

  /**
      Membership plans
   */
  uint8 public Plans;
  uint256 public Members;
  uint256 public Partners;
  mapping(uint8 => uint256) public MembershipPlan;

  /**
      lucky draws ( Game )
   */
  uint8 public TotalGames;
  uint8 public TotalParticipates;
  mapping(uint8 => uint256) public GameEntryFee;

  /**
      lucky draws ( Game ) user data
   */
  struct game {
    uint256 StartedAt;
    uint256 EndedAt;
    bool GameOver;
    /**
     *
     */
    bool Withdraw;
    uint8[] Winners;
    uint256[] WinnersId;
    /**
     * @notice
     */
    uint8[] AllNumbers;
    uint256[100] AllParticipates;
    /**
     * @notice
     */
    uint256 TotalPrizeAmount;
    /**
     * @notice
     */
    mapping(uint8 => bool) Sold;
    mapping(uint8 => uint256) UserId;
  }
  struct compGame {
    uint8 Game;
    uint256 GameId;
  }
  compGame[] compGames;
  uint256 public TotalPicksAmount;
  Counters.Counter public TotalPicks;
  mapping(uint8 => Counters.Counter) public GameIds;
  mapping(uint8 => mapping(uint256 => game)) internal Game;
  mapping(uint8 => mapping(uint256 => mapping(uint256 => bool)))
    internal UserInGame;

  /**
      Membership Referrals
   */
  uint8 public TotalPrizes;
  mapping(uint8 => uint8) public Prizes;

  /**
      Membership Referrals
   */
  uint8 public RefLevels;
  mapping(uint8 => uint8) public MembershipRefLevels;

  /**
      Purchase Referrals
   */
  uint8 public PurLevels;
  mapping(uint8 => uint8) public PurchaseRefLevels;

  /********************************************************
                        Constructor
  ********************************************************/

  constructor(address _DAI, address _RandomNumberGenerator) {
    DAI = IERC20(_DAI);
    Number = IRandomNumberGenerator(_RandomNumberGenerator);

    /**
      Registering user
    */
    uint256 _id = UsersIds.current();
    User[_id].Id = _id;
    User[_id].Ref = _id;
    User[_id].Plan = 1;
    User[_id].Address = owner();
    UserId[owner()] = _id;
    isUserExists[owner()] = true;
    User[_id].registerAt = block.timestamp;

    /**
        Membership plans
     */
    Plans = 1;
    MembershipPlan[0] = 1 ether;
    MembershipPlan[1] = 20 ether;

    /**
        Lucky draws ( Game )
     */
    TotalGames = 9;
    TotalParticipates = 100;
    GameEntryFee[0] = 1 ether;
    GameEntryFee[1] = 2 ether;
    GameEntryFee[2] = 5 ether;
    GameEntryFee[3] = 10 ether;
    GameEntryFee[4] = 25 ether;
    GameEntryFee[5] = 50 ether;
    GameEntryFee[6] = 100 ether;
    GameEntryFee[7] = 250 ether;
    GameEntryFee[8] = 500 ether;

    /**
     * game start time
     */
    Game[0][0].StartedAt = block.timestamp;
    Game[1][0].StartedAt = block.timestamp;
    Game[2][0].StartedAt = block.timestamp;
    Game[3][0].StartedAt = block.timestamp;
    Game[4][0].StartedAt = block.timestamp;
    Game[5][0].StartedAt = block.timestamp;
    Game[6][0].StartedAt = block.timestamp;
    Game[7][0].StartedAt = block.timestamp;
    Game[8][0].StartedAt = block.timestamp;

    /**
        Membership Referrals
     */
    RefLevels = 5;
    MembershipRefLevels[0] = 25;
    MembershipRefLevels[1] = 10;
    MembershipRefLevels[2] = 5;
    MembershipRefLevels[3] = 5;
    MembershipRefLevels[4] = 5;
    //               Total = 50%

    /**
        Purchase Referrals
     */
    PurLevels = 5;
    PurchaseRefLevels[0] = 15;
    PurchaseRefLevels[1] = 4;
    PurchaseRefLevels[2] = 3;
    PurchaseRefLevels[3] = 2;
    PurchaseRefLevels[4] = 1;
    //             Total = 25%
    // and 5% goes to admin it total 30%

    /**
        Prizes
     */
    TotalPrizes = 3;
    Prizes[0] = 40;
    Prizes[1] = 20;
    Prizes[2] = 10;
    //  Total = 70%
  }

  /********************************************************
                        Modifier
  ********************************************************/

  bool internal Locked;
  modifier noReentrant() {
    require(!Locked, "No re-entrancy");
    Locked = true;
    _;
    Locked = false;
  }

  /********************************************************
                        Public Functions
  ********************************************************/

  function register(
    uint256 _ref,
    uint8 _plan,
    address _user
  ) public noReentrant {
    require(Plans >= _plan, "Please choose correct plan");
    require(!isUserExists[_user], "User exists");
    require(isUserExists[User[_ref].Address], "Ref not exists");

    uint256 _amount = MembershipPlan[_plan];
    DAI.safeTransferFrom(msg.sender, address(this), _amount);

    UsersIds.increment();
    uint256 _id = UsersIds.current();

    User[_id].Id = _id;
    User[_id].Ref = _ref;
    User[_id].Plan = _plan;
    User[_id].Address = _user;
    User[_id].TimeToRenew = block.timestamp + Year;
    User[_id].registerAt = block.timestamp;
    UserId[_user] = _id;
    isUserExists[_user] = true;

    User[_ref].AllRef.push(_id);

    if (_plan == 0) Members++;
    if (_plan == 1) Partners++;

    registerRefByLevel(_plan, _ref);
    registerUplineMemberRef(_id, _ref, _amount);

    emit _registered(_id, _ref, _plan, _user, block.timestamp);
  }

  function renew(uint256 _id) public noReentrant {
    user memory _user = User[_id];
    require(isUserExists[_user.Address], "User not exists");

    uint256 _amount = MembershipPlan[_user.Plan];
    DAI.safeTransferFrom(msg.sender, address(this), _amount);

    User[_id].TimeToRenew = block.timestamp + Year;
    renewUplineMemberRef(_id, _user.Ref, _amount);

    emit _renewed(_id, _user.Ref, _user.Plan, _user.Address, block.timestamp);
  }

  function upgradePlan(uint256 _id) public noReentrant {
    user memory _user = User[_id];

    require(isUserExists[_user.Address], "User not exists");
    require(_user.Plan == 0, "Already upgraded");

    uint256 _amount = MembershipPlan[1];
    DAI.safeTransferFrom(msg.sender, address(this), _amount);

    Members--;
    Partners++;
    User[_id].Plan = 1;
    User[_id].TimeToRenew = block.timestamp + Year;

    upgradeRefByLevel(_user.Ref);
    upgradePlanUplineMemberRef(_id, _user.Ref, _amount);

    emit _upgraded(_id, _user.Ref, _user.Plan, _user.Address, block.timestamp);
  }

  function enterGame(
    uint8 _game,
    uint8 _number,
    uint256 _id
  ) public noReentrant {
    require(TotalGames > _game, "Please choose correct game");
    require(TotalParticipates > _number, "Number is not correct");

    user memory _user = User[_id];
    require(isUserExists[_user.Address], "User not exists");
    require(
      _user.TimeToRenew > block.timestamp || _id == 0,
      "It's Time To Renew"
    );

    uint256 _gameId = GameIds[_game].current();
    require(!Game[_game][_gameId].Sold[_number], "This number is already sell");

    uint256 _amount = GameEntryFee[_game];
    DAI.safeTransferFrom(msg.sender, address(this), _amount);

    game storage _Game = Game[_game][_gameId];
    require(!_Game.GameOver, "Game Over");

    _Game.Sold[_number] = true;
    _Game.UserId[_number] = _id;
    _Game.AllParticipates[_number] = _id;
    _Game.AllNumbers.push(_number);

    if (_Game.StartedAt == 0) _Game.StartedAt = block.timestamp;

    TotalPicks.increment();
    TotalPicksAmount += _amount;
    UserInGame[_game][_gameId][_id] = true;
    User[_id].Picks.push(pick(_game, _gameId, _number));

    uplinePicksRef(_id, _game, _user.Ref, _amount);
    _Game.TotalPrizeAmount += Percentage(_amount, 85);

    emit _picked(
      _id,
      _user.Ref,
      _user.Plan,
      _game,
      _gameId,
      _amount,
      block.timestamp
    );

    if (_Game.AllNumbers.length == TotalParticipates) {
      for (uint8 i = 0; i < TotalPrizes; i++) {
        uint8 _luckyNumber = Number.randomNumberGenerator(i) % 99;

        _Game.Winners.push(_luckyNumber);
        _Game.WinnersId.push(_Game.AllParticipates[_luckyNumber]);

        User[_Game.AllParticipates[_luckyNumber]].AllWinLuckyDraw.push(
          userGame(_game, i, _gameId, _luckyNumber)
        );
      }

      emit _winnersAnnounced(_game, _gameId, _Game.Winners, block.timestamp);

      _Game.GameOver = true;
      _Game.EndedAt = block.timestamp;

      compGames.push(compGame(_game, _gameId));
      GameIds[_game].increment();
    }
  }

  function withdrawPrizes(uint8 _game, uint256 _gameId) public noReentrant {
    require(Game[_game][_gameId].GameOver, "Game hasn't ended yet");
    require(!Game[_game][_gameId].Withdraw, "Prizes already withdrawn");

    uint256 _amount = GameEntryFee[_game] * 100;
    game storage _Game = Game[_game][_gameId];

    for (uint8 i = 0; i < 3; i++) {
      user memory _User = User[_Game.WinnersId[i]];
      uint256 _Percentage = Percentage(_amount, Prizes[i]);

      DAI.safeTransferFrom(address(this), _User.Address, _Percentage);

      User[_Game.WinnersId[i]].TotalPrizesAmount += _Percentage;
      TotalRewardsPaid.Prize += _Percentage;

      emit _prizesWinner(
        _User.Id,
        _User.Ref,
        _User.Plan,
        _User.Address,
        _game,
        _gameId,
        i,
        _Percentage,
        block.timestamp
      );
    }

    _Game.Withdraw = true;
    emit _prizesWithdraw(_game, _gameId, _amount, block.timestamp);
  }

  /********************************************************
                        private Functions
  ********************************************************/

  function registerRefByLevel(uint8 _plan, uint256 _ref) private {
    for (uint8 j = 0; j < RefLevels; j++) {
      if (_plan == 0) MembersRefByLevel[j][_ref] += 1;
      if (_plan == 1) PartnersRefByLevel[j][_ref] += 1;

      _ref = User[_ref].Ref;
    }
  }

  function registerUplineMemberRef(
    uint256 _id,
    uint256 _ref,
    uint256 _amount
  ) private {
    uint8 j;
    uint256 _Percentage;

    while (j < RefLevels) {
      user memory _user = User[_ref];

      if (
        (_user.Plan == 1 && _user.TimeToRenew > block.timestamp) || _ref == 0
      ) {
        _Percentage = Percentage(_amount, MembershipRefLevels[j]);
        DAI.safeTransfer(_user.Address, _Percentage);

        TotalRewardsPaid.MemberRef += _Percentage;
        User[_ref].TotalReferralRewards += _Percentage;

        emit _uplineMemberRef(
          _id,
          _user.Id,
          User[_id].Plan,
          User[_id].Address,
          _Percentage,
          block.timestamp
        );

        j++;
      }

      _ref = _user.Ref;
    }

    _Percentage = Percentage(_amount, 50);
    DAI.safeTransfer(owner(), _Percentage);

    TotalRewardsPaid.MemberRef += _Percentage;
    User[0].TotalReferralRewards = _Percentage;
  }

  function upgradeRefByLevel(uint256 _ref) private {
    for (uint8 j = 0; j < RefLevels; j++) {
      MembersRefByLevel[j][_ref] -= 1;
      PartnersRefByLevel[j][_ref] += 1;

      _ref = User[_ref].Ref;
    }
  }

  function upgradePlanUplineMemberRef(
    uint256 _id,
    uint256 _ref,
    uint256 _amount
  ) private {
    uint8 j;
    uint256 _Percentage;

    while (j < RefLevels) {
      user memory _user = User[_ref];
      if (
        (_user.Plan == 1 && _user.TimeToRenew > block.timestamp) || _ref == 0
      ) {
        _Percentage = Percentage(_amount, MembershipRefLevels[j]);
        DAI.safeTransfer(_user.Address, _Percentage);

        TotalRewardsPaid.MemberRef += _Percentage;
        User[_ref].TotalReferralRewards += _Percentage;

        emit _uplineMemberRef(
          _id,
          _user.Id,
          User[_id].Plan,
          User[_id].Address,
          _Percentage,
          block.timestamp
        );

        j++;
      }

      _ref = _user.Ref;
    }

    _Percentage = Percentage(_amount, 50);
    DAI.safeTransfer(owner(), _Percentage);

    TotalRewardsPaid.MemberRef += _Percentage;
    User[0].TotalReferralRewards = _Percentage;
  }

  function renewUplineMemberRef(
    uint256 _id,
    uint256 _ref,
    uint256 _amount
  ) private {
    uint8 j;
    uint256 _Percentage;

    while (j < RefLevels) {
      user memory _user = User[_ref];
      if (
        (_user.Plan == 1 && _user.TimeToRenew > block.timestamp) || _ref == 0
      ) {
        _Percentage = Percentage(_amount, MembershipRefLevels[j]);
        DAI.safeTransfer(_user.Address, _Percentage);

        TotalRewardsPaid.MemberRef += _Percentage;
        User[_ref].TotalReferralRewards += _Percentage;

        emit _uplineMemberRef(
          _id,
          _user.Id,
          User[_id].Plan,
          User[_id].Address,
          _Percentage,
          block.timestamp
        );

        j++;
      }
      _ref = _user.Ref;
    }

    _Percentage = Percentage(_amount, 50);
    DAI.safeTransfer(owner(), _Percentage);

    TotalRewardsPaid.MemberRef += _Percentage;
    User[0].TotalReferralRewards = _Percentage;
  }

  function uplinePicksRef(
    uint256 _id,
    uint8 _game,
    uint256 _ref,
    uint256 _amount
  ) private {
    uint8 j;
    uint256 _Percentage;

    while (j < PurLevels) {
      user memory _user = User[_ref];

      if (
        (_user.Plan == 1 && _user.TimeToRenew > block.timestamp) || _ref == 0
      ) {
        _Percentage = Percentage(_amount, PurchaseRefLevels[j]);
        DAI.safeTransfer(_user.Address, _Percentage);

        TotalRewardsPaid.PicksRef += _Percentage;
        User[_ref].TotalPicksRewards += _Percentage;

        emit _uplinePicksRef(
          _id,
          _user.Id,
          User[_id].Plan,
          User[_id].Address,
          _game,
          _Percentage,
          block.timestamp
        );

        j++;
      }
      _ref = _user.Ref;
    }

    _Percentage = Percentage(_amount, 5);
    DAI.safeTransfer(owner(), _Percentage);

    TotalRewardsPaid.PicksRef += _Percentage;
    User[0].TotalPicksRewards = _Percentage;
  }

  /********************************************************
                        Reusable Functions
  ********************************************************/

  function Percentage(uint256 a, uint8 n) internal pure returns (uint256) {
    // a = amount , n = number, p = percentage

    uint256 p = a * 1e18;
    p = (p * n) / 100;
    p = p / 1e18;

    return p;
  }

  /********************************************************
                        View Functions
  ********************************************************/

  struct gameDetail {
    uint256 Id;
    uint256 StartedAt;
    uint256 EndedAt;
    bool GameOver;
    bool Withdraw;
    uint256 EntryFee;
    uint8[] Winners;
    uint256[] WinnersId;
    uint8[] AllNumbers;
    uint256[100] AllParticipates;
    uint256 TotalPrizeAmount;
  }

  function singleGameDetail(
    uint8 _game,
    uint8 _gameId
  ) public view returns (gameDetail memory) {
    game storage _Game = Game[_game][_gameId];

    return
      gameDetail(
        _gameId,
        _Game.StartedAt,
        _Game.EndedAt,
        _Game.GameOver,
        _Game.Withdraw,
        GameEntryFee[_game],
        _Game.Winners,
        _Game.WinnersId,
        _Game.AllNumbers,
        _Game.AllParticipates,
        _Game.TotalPrizeAmount
      );
  }

  function currentGameDetail(
    uint8 _game
  ) public view returns (gameDetail memory) {
    uint256 _GameId = GameIds[_game].current();
    game storage _Game = Game[_game][_GameId];

    return
      gameDetail(
        _GameId,
        _Game.StartedAt,
        _Game.EndedAt,
        _Game.GameOver,
        _Game.Withdraw,
        GameEntryFee[_game],
        _Game.Winners,
        _Game.WinnersId,
        _Game.AllNumbers,
        _Game.AllParticipates,
        _Game.TotalPrizeAmount
      );
  }

  function currentUserInGame(
    uint8 _game,
    uint256 _id
  ) public view returns (bool) {
    return UserInGame[_game][GameIds[_game].current()][_id];
  }

  function userDetail(uint256 _userId) public view returns (user memory) {
    require(isUserExists[User[_userId].Address], "User not exists");
    return User[_userId];
  }

  function userTotalRefrerrs(
    uint256 _id
  )
    public
    view
    returns (uint256[] memory memberLevels, uint256[] memory partnersLevels)
  {
    uint256[] memory _memberLevels = new uint256[](5);
    uint256[] memory _partnersLevels = new uint256[](5);

    for (uint8 i = 0; i < 5; i++) {
      _memberLevels[i] = MembersRefByLevel[i][_id];
      _partnersLevels[i] = PartnersRefByLevel[i][_id];
    }

    return (_memberLevels, _partnersLevels);
  }

  function CompGames() public view returns (compGame[] memory) {
    return compGames;
  }

  /********************************************************
                        View Functions
  ********************************************************/

  event _registered(
    uint256 indexed _id,
    uint256 _ref,
    uint8 _plan,
    address _address,
    uint256 timestamp
  );

  event _upgraded(
    uint256 indexed _id,
    uint256 _ref,
    uint8 _plan,
    address _address,
    uint256 timestamp
  );

  event _renewed(
    uint256 indexed _id,
    uint256 _ref,
    uint8 _plan,
    address _address,
    uint256 timestamp
  );

  event _uplineMemberRef(
    uint256 indexed _id,
    uint256 _ref,
    uint8 _plan,
    address _address,
    uint256 _amount,
    uint256 timestamp
  );

  // >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

  event _picked(
    uint256 indexed _id,
    uint256 _ref,
    uint8 _plan,
    uint8 _game,
    uint256 _gameId,
    uint256 _amount,
    uint256 _timestamp
  );

  event _uplinePicksRef(
    uint256 indexed _id,
    uint256 _ref,
    uint8 _plan,
    address _address,
    uint8 _game,
    uint256 _amount,
    uint256 timestamp
  );

  // >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

  event _winnersAnnounced(
    uint8 _game,
    uint256 _gameId,
    uint8[] _winners,
    uint256 _timestamp
  );

  event _prizesWithdraw(
    uint8 _game,
    uint256 _gameId,
    uint256 _amount,
    uint256 _timestamp
  );

  event _prizesWinner(
    uint256 indexed _id,
    uint256 _ref,
    uint8 _plan,
    address _address,
    uint8 _game,
    uint256 _gameId,
    uint8 _prize,
    uint256 _amount,
    uint256 _timestamp
  );
}