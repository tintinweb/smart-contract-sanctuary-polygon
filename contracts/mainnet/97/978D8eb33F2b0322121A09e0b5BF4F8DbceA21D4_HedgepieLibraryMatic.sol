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
pragma solidity ^0.8.4;

import "../interfaces/IYBNFT.sol";
import "../interfaces/IPathFinder.sol";
import "../interfaces/IHedgepieInvestor.sol";
import "../interfaces/IHedgepieAuthority.sol";

import "./HedgepieAccessControlled.sol";

abstract contract BaseAdapter is HedgepieAccessControlled {
    struct UserAdapterInfo {
        uint256 amount; // Staking token amount
        uint256 userShare1; // First rewardTokens' share
        uint256 userShare2; // Second rewardTokens' share
        uint256 rewardDebt1; // Reward Debt for first reward token
        uint256 rewardDebt2; // Reward Debt for second reward token
        uint256 invested; // invested lp token amount
    }

    struct AdapterInfo {
        uint256 accTokenPerShare1; // Accumulated per share for first reward token
        uint256 accTokenPerShare2; // Accumulated per share for second reward token
        uint256 totalStaked; // Total staked staking token
    }

    // LP pool id - should be 0 when stakingToken is not LP
    uint256 public pid;

    // staking token
    address public stakingToken;

    // first reward token
    address public rewardToken1;

    // second reward token - optional
    address public rewardToken2;

    // repay token which we will receive after deposit - optional
    address public repayToken;

    // strategy where we deposit staking token
    address public strategy;

    // router address for LP token
    address public router;

    // swap router address for ERC20 token swap
    address public swapRouter;

    // wbnb address
    address public wbnb;

    // adapter name
    string public name;

    // adapter info having totalStaked and 1st, 2nd share info
    AdapterInfo public mAdapter;

    // adapter info for each nft
    // nft id => UserAdapterInfo
    mapping(uint256 => UserAdapterInfo) public userAdapterInfos;

    /** @notice Constructor
     * @param _hedgepieAuthority  address of authority
     */
    constructor(address _hedgepieAuthority) HedgepieAccessControlled(IHedgepieAuthority(_hedgepieAuthority)) {}

    /** @notice get user staked amount */
    function getUserAmount(uint256 _tokenId) external view returns (uint256 amount) {
        return userAdapterInfos[_tokenId].amount;
    }

    /**
     * @notice deposit to strategy
     * @param _tokenId YBNFT token id
     */
    function deposit(uint256 _tokenId) external payable virtual returns (uint256 amountOut) {}

    /**
     * @notice withdraw from strategy
     * @param _tokenId YBNFT token id
     * @param _amount amount of staking tokens to withdraw
     */
    function withdraw(uint256 _tokenId, uint256 _amount) external payable virtual returns (uint256 amountOut) {}

    /**
     * @notice claim reward from strategy
     * @param _tokenId YBNFT token id
     */
    function claim(uint256 _tokenId) external payable virtual returns (uint256 amountOut) {}

    /**
     * @notice Remove funds
     * @param _tokenId YBNFT token id
     */
    function removeFunds(uint256 _tokenId) external payable virtual returns (uint256 amountOut) {}

    /**
     * @notice Update funds
     * @param _tokenId YBNFT token id
     */
    function updateFunds(uint256 _tokenId) external payable virtual returns (uint256 amountOut) {}

    /**
     * @notice Get pending token reward
     * @param _tokenId YBNFT token id
     */
    function pendingReward(uint256 _tokenId) external view virtual returns (uint256 reward, uint256 withdrawable) {}

    /**
     * @notice Charge Fee and send BNB to investor
     * @param _tokenId YBNFT token id
     */
    function _chargeFeeAndSendToInvestor(uint256 _tokenId, uint256 _amount, uint256 _reward) internal {
        bool success;
        if (_reward != 0) {
            _reward = (_reward * IYBNFT(authority.hYBNFT()).performanceFee(_tokenId)) / 1e4;

            // 20% to treasury
            (success, ) = payable(IHedgepieInvestor(authority.hInvestor()).treasury()).call{value: _reward / 5}("");
            require(success, "Failed to send bnb to Treasury");

            // 80% to fund manager
            (success, ) = payable(IYBNFT(authority.hYBNFT()).ownerOf(_tokenId)).call{value: _reward - _reward / 5}("");
            require(success, "Failed to send bnb to Treasury");
        }

        (success, ) = payable(msg.sender).call{value: _amount - _reward}("");
        require(success, "Failed to send bnb");
    }

    receive() external payable {}
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.4;

import "../interfaces/IHedgepieAuthority.sol";

abstract contract HedgepieAccessControlled {
    /* ========== EVENTS ========== */

    event AuthorityUpdated(IHedgepieAuthority indexed authority);

    // unauthorized error message
    string private _unauthorized = "UNAUTHORIZED"; // save gas

    // paused error message
    string private _paused = "PAUSED"; // save gas

    /* ========== STATE VARIABLES ========== */

    IHedgepieAuthority public authority;

    /* ========== Constructor ========== */
    /**
     * @notice Constructor
     * @param _authority address of authority
     */
    constructor(IHedgepieAuthority _authority) {
        authority = _authority;
        emit AuthorityUpdated(_authority);
    }

    /* ========== MODIFIERS ========== */

    modifier whenNotPaused() {
        require(!authority.paused(), _paused);
        _;
    }

    modifier onlyGovernor() {
        require(msg.sender == authority.governor(), _unauthorized);
        _;
    }

    modifier onlyPathManager() {
        require(msg.sender == authority.pathManager(), _unauthorized);
        _;
    }

    modifier onlyAdapterManager() {
        require(msg.sender == authority.adapterManager(), _unauthorized);
        _;
    }

    modifier onlyInvestor() {
        require(msg.sender == authority.hInvestor(), _unauthorized);
        _;
    }

    /* ========== GOV ONLY ========== */
    /**
     * @notice Set new authority
     * @param _newAuthority address of new authority
     */
    /// #if_succeeds {:msg "setAuthority failed"}  authority == _newAuthority;
    function setAuthority(IHedgepieAuthority _newAuthority) external onlyGovernor {
        require(address(_newAuthority) != address(0), "Invalid adddress");
        authority = _newAuthority;
        emit AuthorityUpdated(_newAuthority);
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.4;

import "./IWrap.sol";
import "../base/BaseAdapter.sol";

interface IAdapter {
    function stakingToken() external view returns (address);

    function repayToken() external view returns (address);

    function strategy() external view returns (address);

    function name() external view returns (string memory);

    function rewardToken1() external view returns (address);

    function rewardToken2() external view returns (address);

    function router() external view returns (address);

    function swapRouter() external view returns (address);

    function authority() external view returns (address);

    function userAdapterInfos(uint256 _tokenId) external view returns (BaseAdapter.UserAdapterInfo memory);

    function mAdapter() external view returns (BaseAdapter.AdapterInfo memory);

    /**
     * @notice deposit to strategy
     * @param _tokenId YBNFT token id
     */
    function deposit(uint256 _tokenId) external payable returns (uint256 amountOut);

    /**
     * @notice withdraw from strategy
     * @param _tokenId YBNFT token id
     * @param _amount amount of staking tokens to withdraw
     */
    function withdraw(uint256 _tokenId, uint256 _amount) external payable returns (uint256 amountOut);

    /**
     * @notice claim reward from strategy
     * @param _tokenId YBNFT token id
     */
    function claim(uint256 _tokenId) external payable returns (uint256 amountOut);

    /**
     * @notice Get pending token reward
     * @param _tokenId YBNFT token id
     */
    function pendingReward(uint256 _tokenId) external view returns (uint256 amountOut, uint256 withdrawable);

    /**
     * @notice Remove funds
     * @param _tokenId YBNFT token id
     */
    function removeFunds(uint256 _tokenId) external payable returns (uint256 amount);

    /**
     * @notice Update funds
     * @param _tokenId YBNFT token id
     */
    function updateFunds(uint256 _tokenId) external payable returns (uint256 amount);

    /**
     * @notice get user staked amount
     */
    function getUserAmount(uint256 _tokenId) external view returns (uint256 amount);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.4;

interface IHedgepieAuthority {
    /* ========== EVENTS ========== */

    event GovernorPushed(address indexed from, address indexed to, bool _effectiveImmediately);
    event PathManagerPushed(address indexed from, address indexed to, bool _effectiveImmediately);
    event AdapterManagerPushed(address indexed from, address indexed to, bool _effectiveImmediately);

    event GovernorPulled(address indexed from, address indexed to);
    event PathManagerPulled(address indexed from, address indexed to);
    event AdapterManagerPulled(address indexed from, address indexed to);

    event HInvestorUpdated(address indexed from, address indexed to);
    event HYBNFTUpdated(address indexed from, address indexed to);
    event HAdapterListUpdated(address indexed from, address indexed to);
    event PathFinderUpdated(address indexed from, address indexed to);

    /* ========== VIEW ========== */

    function governor() external view returns (address);

    function pathManager() external view returns (address);

    function adapterManager() external view returns (address);

    function hInvestor() external view returns (address);

    function hYBNFT() external view returns (address);

    function hAdapterList() external view returns (address);

    function pathFinder() external view returns (address);

    function paused() external view returns (bool);
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.4;

interface IHedgepieInvestor {
    function treasury() external view returns (address);

    /**
     * @notice Update funds for token id
     * @param _tokenId YBNFT token id
     */
    function updateFunds(uint256 _tokenId) external;

    /**
     * @notice Deposit with BNB
     * @param _tokenId  YBNft token id
     */
    function deposit(uint256 _tokenId) external;

    /**
     * @notice Withdraw by BNB
     * @param _tokenId  YBNft token id
     */
    function withdraw(uint256 _tokenId) external;

    /**
     * @notice Claim
     * @param _tokenId  YBNft token id
     */
    function claim(uint256 _tokenId) external;

    /**
     * @notice pendingReward
     * @param _tokenId  YBNft token id
     * @param _account  user address
     */
    function pendingReward(
        uint256 _tokenId,
        address _account
    ) external returns (uint256 amountOut, uint256 withdrawable);
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.4;

interface IOffchainOracle {
    function getRate(address srcToken, address dstToken, bool) external view returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.4;

interface IPancakePair {
    function token0() external view returns (address);

    function token1() external view returns (address);

    function totalSupply() external view returns (uint256);

    function fee() external view returns (uint24);

    function getReserves() external view returns (uint112, uint112, uint32);
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.4;

interface IPancakeRouter {
    function getAmountsIn(uint256 amountOut, address[] memory path) external view returns (uint256[] memory amounts);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

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

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB, uint256 liquidity);

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external payable returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);

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

    function getAmountsOut(uint256 amountIn, address[] memory path) external view returns (uint256[] memory amounts);

    function factory() external view returns (address);
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.4;

interface IPathFinder {
    /**
     * @notice Get Path
     * @param _router swap router address
     * @param _inToken input token address
     * @param _outToken output token address
     */
    function getPaths(address _router, address _inToken, address _outToken) external view returns (address[] memory);
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.4;

interface IWrap {
    // get wrapper token
    function deposit(uint256 amount) external;

    // get native token
    function withdraw(uint256 share) external;

    function deposit() external payable;
}

// SPDX-License-Identifier: None
pragma solidity ^0.8.4;

interface IYBNFT {
    struct AdapterParam {
        uint256 allocation;
        address addr;
        bool isCross;
    }

    struct UpdateInfo {
        uint256 tokenId; // YBNFT tokenID
        uint256 value; // traded amount
        address account; // user address
        bool isDeposit; // deposit or withdraw
    }

    function exists(uint256) external view returns (bool);

    function getCurrentTokenId() external view returns (uint256);

    function ownerOf(uint256) external view returns (address);

    function performanceFee(uint256 tokenId) external view returns (uint256);

    /**
     * @notice Get adapter parameters
     * @param tokenId  YBNft token id
     */
    function getTokenAdapterParams(uint256 tokenId) external view returns (AdapterParam[] memory);

    /**
     * @notice Mint nft
     * @param _adapterParams  parameters of adapters
     * @param _performanceFee  performance fee
     * @param _tokenURI  token URI
     */
    function mint(AdapterParam[] memory _adapterParams, uint256 _performanceFee, string memory _tokenURI) external;

    /**
     * @notice Update profit info
     * @param _tokenId  YBNFT tokenID
     * @param _value  amount of profit
     */
    function updateProfitInfo(uint256 _tokenId, uint256 _value) external;

    /**
     * @notice Update TVL, Profit, Participants info
     * @param param  update info param
     */
    function updateInfo(UpdateInfo memory param) external;
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../interfaces/IAdapter.sol";
import "../interfaces/IPancakePair.sol";
import "../interfaces/IPancakeRouter.sol";
import "../interfaces/IOffchainOracle.sol";

import "../base/BaseAdapter.sol";

library HedgepieLibraryMatic {
    using SafeERC20 for IERC20;

    // WBNB address
    address public constant WBNB = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;

    // USDT address
    address public constant USDT = 0xc2132D05D31c914a87C6611C10748AEb04B58e8F;

    // 1inch oracle address
    address public constant ORACLE = 0xf023D71EfB08339EA28F0C186AE130c74D44C58c;

    /**
     * @notice Wrap BNB to WBNB
     * @param _amountIn  amount of BNB
     */
    function wrapBNB(uint256 _amountIn) external returns (uint256) {
        IWrap(WBNB).deposit{value: _amountIn}();
        return _amountIn;
    }

    /**
     * @notice Swap tokens
     * @param _amountIn  amount of inputToken
     * @param _adapter  address of adapter
     * @param _outToken  address of targetToken
     * @param _router  address of swap router
     */
    function swapOnRouter(
        uint256 _amountIn,
        address _adapter,
        address _outToken,
        address _router
    ) public returns (uint256 amountOut) {
        address[] memory path = IPathFinder(IHedgepieAuthority(IAdapter(_adapter).authority()).pathFinder()).getPaths(
            _router,
            WBNB,
            _outToken
        );
        uint256 beforeBalance = IERC20(_outToken).balanceOf(address(this));

        IPancakeRouter(_router).swapExactETHForTokensSupportingFeeOnTransferTokens{value: _amountIn}(
            0,
            path,
            address(this),
            block.timestamp + 2 hours
        );

        uint256 afterBalance = IERC20(_outToken).balanceOf(address(this));
        amountOut = afterBalance - beforeBalance;
    }

    /**
     * @notice Swap tokens to bnb
     * @param _amountIn  amount of swap token
     * @param _adapter  address of adapter
     * @param _inToken  address of swap token
     * @param _router  address of swap router
     */
    function swapForBnb(
        uint256 _amountIn,
        address _adapter,
        address _inToken,
        address _router
    ) public returns (uint256 amountOut) {
        if (_inToken == WBNB) {
            IWrap(WBNB).withdraw(_amountIn);
            amountOut = _amountIn;
        } else {
            address[] memory path = IPathFinder(IHedgepieAuthority(IAdapter(_adapter).authority()).pathFinder())
                .getPaths(_router, _inToken, WBNB);
            uint256 beforeBalance = address(this).balance;

            IERC20(_inToken).safeApprove(_router, 0);
            IERC20(_inToken).safeApprove(_router, _amountIn);

            IPancakeRouter(_router).swapExactTokensForETHSupportingFeeOnTransferTokens(
                _amountIn,
                0,
                path,
                address(this),
                block.timestamp + 2 hours
            );

            uint256 afterBalance = address(this).balance;
            amountOut = afterBalance - beforeBalance;
        }
    }

    /**
     * @notice Get the reward amount of user from adapter
     * @param _tokenId  tokenID
     * @param _adapterAddr  address of adapter
     */
    function getMRewards(uint256 _tokenId, address _adapterAddr) public view returns (uint256 reward, uint256 reward1) {
        BaseAdapter.AdapterInfo memory adapterInfo = IAdapter(_adapterAddr).mAdapter();
        BaseAdapter.UserAdapterInfo memory userInfo = IAdapter(_adapterAddr).userAdapterInfos(_tokenId);

        if (
            IAdapter(_adapterAddr).rewardToken1() != address(0) &&
            adapterInfo.totalStaked != 0 &&
            adapterInfo.accTokenPerShare1 != 0
        ) {
            reward =
                (userInfo.amount * (adapterInfo.accTokenPerShare1 - userInfo.userShare1)) /
                1e12 +
                userInfo.rewardDebt1;
        }

        if (
            IAdapter(_adapterAddr).rewardToken2() != address(0) &&
            adapterInfo.totalStaked != 0 &&
            adapterInfo.accTokenPerShare2 != 0
        ) {
            reward1 =
                (userInfo.amount * (adapterInfo.accTokenPerShare2 - userInfo.userShare2)) /
                1e12 +
                userInfo.rewardDebt2;
        }
    }

    /**
     * @notice Get LP token
     * @param _adapter  AdapterInfo
     * @param _stakingToken  address of staking token
     * @param _amountIn  amount of BNB
     */
    function getLP(
        IYBNFT.AdapterParam memory _adapter,
        address _stakingToken,
        uint256 _amountIn
    ) public returns (uint256 amountOut) {
        address[2] memory tokens;
        tokens[0] = IPancakePair(_stakingToken).token0();
        tokens[1] = IPancakePair(_stakingToken).token1();
        address _router = IAdapter(_adapter.addr).router();

        uint256[2] memory tokenAmount;
        unchecked {
            tokenAmount[0] = _amountIn / 2;
            tokenAmount[1] = _amountIn - tokenAmount[0];
        }

        if (tokens[0] != WBNB) {
            tokenAmount[0] = swapOnRouter(tokenAmount[0], _adapter.addr, tokens[0], _router);
            IERC20(tokens[0]).safeApprove(_router, 0);
            IERC20(tokens[0]).safeApprove(_router, tokenAmount[0]);
        }

        if (tokens[1] != WBNB) {
            tokenAmount[1] = swapOnRouter(tokenAmount[1], _adapter.addr, tokens[1], _router);
            IERC20(tokens[1]).safeApprove(_router, 0);
            IERC20(tokens[1]).safeApprove(_router, tokenAmount[1]);
        }

        if (tokenAmount[0] != 0 && tokenAmount[1] != 0) {
            if (tokens[0] == WBNB || tokens[1] == WBNB) {
                (, , amountOut) = IPancakeRouter(_router).addLiquidityETH{
                    value: tokens[0] == WBNB ? tokenAmount[0] : tokenAmount[1]
                }(
                    tokens[0] == WBNB ? tokens[1] : tokens[0],
                    tokens[0] == WBNB ? tokenAmount[1] : tokenAmount[0],
                    0,
                    0,
                    address(this),
                    block.timestamp + 2 hours
                );
            } else {
                (, , amountOut) = IPancakeRouter(_router).addLiquidity(
                    tokens[0],
                    tokens[1],
                    tokenAmount[0],
                    tokenAmount[1],
                    0,
                    0,
                    address(this),
                    block.timestamp + 2 hours
                );
            }
        }
    }

    /**
     * @notice Withdraw LP token
     * @param _adapter  AdapterInfo
     * @param _stakingToken  address of staking token
     * @param _amountIn  amount of LP
     */
    function withdrawLP(
        IYBNFT.AdapterParam memory _adapter,
        address _stakingToken,
        uint256 _amountIn
    ) public returns (uint256 amountOut) {
        address[2] memory tokens;
        tokens[0] = IPancakePair(_stakingToken).token0();
        tokens[1] = IPancakePair(_stakingToken).token1();

        address _router = IAdapter(_adapter.addr).router();
        address swapRouter = IAdapter(_adapter.addr).swapRouter();

        IERC20(_stakingToken).safeApprove(_router, 0);
        IERC20(_stakingToken).safeApprove(_router, _amountIn);

        if (tokens[0] == WBNB || tokens[1] == WBNB) {
            address tokenAddr = tokens[0] == WBNB ? tokens[1] : tokens[0];
            (uint256 amountToken, uint256 amountETH) = IPancakeRouter(_router).removeLiquidityETH(
                tokenAddr,
                _amountIn,
                0,
                0,
                address(this),
                block.timestamp + 2 hours
            );

            amountOut = amountETH;
            amountOut += swapForBnb(amountToken, _adapter.addr, tokenAddr, swapRouter);
        } else {
            (uint256 amountA, uint256 amountB) = IPancakeRouter(_router).removeLiquidity(
                tokens[0],
                tokens[1],
                _amountIn,
                0,
                0,
                address(this),
                block.timestamp + 2 hours
            );

            amountOut += swapForBnb(amountA, _adapter.addr, tokens[0], swapRouter);
            amountOut += swapForBnb(amountB, _adapter.addr, tokens[1], swapRouter);
        }
    }

    /**
     * @notice Get BNB Price from 1inch oracle
     */
    function getBNBPrice() public view returns (uint256) {
        return IOffchainOracle(ORACLE).getRate(WBNB, USDT, false);
    }
}