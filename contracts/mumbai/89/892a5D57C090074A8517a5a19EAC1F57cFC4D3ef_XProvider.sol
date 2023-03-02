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
pragma solidity ^0.8.11;

interface IConnext {
  function xcall(
    uint32 _destination,
    address _to,
    address _asset,
    address _delegate,
    uint256 _amount,
    uint256 _slippage,
    bytes calldata _callData
  ) external payable returns (bytes32);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

interface IXReceiver {
  function xReceive(
    bytes32 _transferId,
    uint256 _amount,
    address _asset,
    address _originSender,
    uint32 _origin,
    bytes memory _callData
  ) external returns (bytes memory);
}

// SPDX-License-Identifier: MIT
// Derby Finance - 2022
pragma solidity ^0.8.11;

interface IGame {
  function Vaults(uint256 _ETFnumber) external view returns (address);

  function basketUnredeemedRewardsViaVault(uint256 _basketId, address _ownerAddr)
    external
    view
    returns (int256);

  function basketRedeemedRewards(uint256 _basketId) external view returns (int256);

  function setUnredeemedToRedeemed(uint256 _basketId, address _ownerAddr) external;

  function settleRewards(
    uint256 _vaultNumber,
    uint32 _chainId,
    int256[] memory rewards
  ) external;
}

// SPDX-License-Identifier: MIT
// Derby Finance - 2022
pragma solidity ^0.8.11;

interface IVault {
  function swapTokens(uint256 _amountIn, address _tokenIn) external returns (uint256);

  function rebalancingPeriod() external view returns (uint256);

  function price(uint256) external view returns (uint256);

  function setDeltaAllocations(uint256 _protocolNum, int256 _allocation) external;

  function historicalPrices(
    uint256 _rebalancingPeriod,
    uint256 _protocolNum
  ) external view returns (uint256);

  function rewardPerLockedToken(
    uint256 _rebalancingPeriod,
    uint256 _protocolNum
  ) external view returns (int256);

  function performanceFee() external view returns (uint256);

  function getTotalUnderlying() external view returns (uint256);

  function getTotalUnderlyingIncBalance() external view returns (uint256);

  function vaultCurrencyAddress() external view returns (address);

  function setXChainAllocation(
    uint256 _amountToSend,
    uint256 _exchangeRate,
    bool _receivingFunds
  ) external;

  function setVaultState(uint256 _state) external;

  function receiveFunds() external;

  function receiveProtocolAllocations(int256[] memory _deltas) external;

  function toggleVaultOnOff(bool _state) external;

  function decimals() external view returns (uint256);

  function redeemRewardsGame(uint256 _amount, address _user) external;
}

// SPDX-License-Identifier: MIT
// Derby Finance - 2022
pragma solidity ^0.8.11;

interface IXChainController {
  function addTotalChainUnderlying(uint256 _vaultNumber, uint256 _amount) external;

  function upFundsReceived(uint256 _vaultNumber) external;

  function receiveAllocationsFromGame(uint256 _vaultNumber, int256[] memory _deltas) external;

  function setTotalUnderlying(
    uint256 _vaultNumber,
    uint32 _chainId,
    uint256 _underlying,
    uint256 _totalSupply,
    uint256 _withdrawalRequests
  ) external;
}

// SPDX-License-Identifier: MIT
// Derby Finance - 2022
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./Interfaces/IVault.sol";
import "./Interfaces/IXChainController.sol";
import "./Interfaces/IGame.sol";
import "./Interfaces/ExternalInterfaces/IConnext.sol";
import "./Interfaces/ExternalInterfaces/IXReceiver.sol";

contract XProvider is IXReceiver {
  using SafeERC20 for IERC20;

  address public immutable connext;

  address private dao;
  address private guardian;
  address public xController;
  address public xControllerProvider;
  address public game;

  uint32 public homeChain;
  uint32 public xControllerChain;
  uint32 public gameChain;

  // (domainID => contract address) mapping domainIDs to trusted remote xProvider on that specific domain
  mapping(uint32 => address) public trustedRemoteConnext;
  // (vaultAddress => bool): used for whitelisting vaults
  mapping(address => bool) public vaultWhitelist;
  // (vaultNumber => vaultAddress): used for guardian when xCall fails
  mapping(uint256 => address) public vaults;

  event SetTrustedRemote(uint32 _srcChainId, bytes _srcAddress);
  event SetTrustedRemoteConnext(uint32 _srcChainId, address _srcAddress);

  modifier onlyDao() {
    require(msg.sender == dao, "xProvider: only DAO");
    _;
  }

  modifier onlyGuardian() {
    require(msg.sender == guardian, "only Guardian");
    _;
  }

  modifier onlyController() {
    require(msg.sender == xController, "xProvider: only Controller");
    _;
  }

  modifier onlyVaults() {
    require(vaultWhitelist[msg.sender], "xProvider: only vault");
    _;
  }

  modifier onlyGame() {
    require(msg.sender == game, "xProvider: only Game");
    _;
  }

  /// @notice Solution for the low-level call in xReceive that is seen as an external call
  modifier onlySelf() {
    require(msg.sender == address(this), "xProvider: only Self");
    _;
  }

  modifier onlySelfOrVault() {
    require(
      msg.sender == address(this) || vaultWhitelist[msg.sender],
      "xProvider: only Self or Vault"
    );
    _;
  }

  /** @notice A modifier for authenticated calls.
   * This is an important security consideration. If the target contract
   * function should be authenticated, it must check three things:
   *    1) The originating call comes from the expected origin domain.
   *    2) The originating call comes from the expected source contract.
   *    3) The call to this contract comes from Connext.
   */
  modifier onlySource(address _originSender, uint32 _origin) {
    require(_originSender == trustedRemoteConnext[_origin] && msg.sender == connext, "Not trusted");
    _;
  }

  constructor(
    address _connext,
    address _dao,
    address _guardian,
    address _game,
    address _xController,
    uint32 _homeChain
  ) {
    connext = _connext;
    dao = _dao;
    guardian = _guardian;
    game = _game;
    xController = _xController;
    homeChain = _homeChain;
  }

  /// @notice Function to send function selectors crossChain
  /// @param _destinationDomain chain Id of destination chain
  /// @param _callData Function selector to call on receiving chain with params
  /// @param _relayerFee The fee offered to the relayers, if 0 use the complete msg.value
  function xSend(uint32 _destinationDomain, bytes memory _callData, uint256 _relayerFee) internal {
    address target = trustedRemoteConnext[_destinationDomain];
    require(target != address(0), "XProvider: destination chain not trusted");
    uint256 relayerFee = _relayerFee != 0 ? _relayerFee : msg.value;

    IConnext(connext).xcall{value: relayerFee}(
      _destinationDomain, // _destination: Domain ID of the destination chain
      target, // _to: address of the target contract
      address(0), // _asset: use address zero for 0-value transfers
      msg.sender, // _delegate: address that can revert or forceLocal on destination
      0, // _amount: 0 because no funds are being transferred
      0, // _slippage: can be anything between 0-10000 because no funds are being transferred
      _callData // _callData: the encoded calldata to send
    );
  }

  /// @notice Transfers funds from one chain to another.
  /// @param _token Address of the token on this domain.
  /// @param _amount The amount to transfer.
  /// @param _recipient The destination address (e.g. a wallet).
  /// @param _destinationDomain The destination domain ID.
  /// @param _slippage Slippage tollerance for xChain swap, in BPS (i.e. 30 = 0.3%)
  /// @param _relayerFee The fee offered to the relayers for confirmation message, msg.value - _relayerFee is what goes to the routers
  function xTransfer(
    address _token,
    uint256 _amount,
    address _recipient,
    uint32 _destinationDomain,
    uint256 _slippage,
    uint256 _relayerFee
  ) internal {
    require(
      IERC20(_token).allowance(msg.sender, address(this)) >= _amount,
      "User must approve amount"
    );

    // User sends funds to this contract
    IERC20(_token).transferFrom(msg.sender, address(this), _amount);

    // This contract approves transfer to Connext
    IERC20(_token).approve(address(connext), _amount);

    IConnext(connext).xcall{value: (msg.value - _relayerFee)}(
      _destinationDomain, // _destination: Domain ID of the destination chain
      _recipient, // _to: address receiving the funds on the destination
      _token, // _asset: address of the token contract
      msg.sender, // _delegate: address that can revert or forceLocal on destination
      _amount, // _amount: amount of tokens to transfer
      _slippage, // _slippage: the maximum amount of slippage the user will accept in BPS (e.g. 30 = 0.3%)
      bytes("") // _callData: empty bytes because we're only sending funds
    );
  }

  /// @notice function implemented from IXReceive from connext, standard way to receive messages with connext.
  /// @param _transferId not used here because only relevant in case of a value transfer. Still in the signature to comply with IXReceive.
  /// @param _amount not used here because only relevant in case of a value transfer. Still in the signature to comply with IXReceive.
  /// @param _asset not used here because only relevant in case of a value transfer. Still in the signature to comply with IXReceive.
  /// @param _originSender sender contract.
  /// @param _origin sender domain id.
  /// @param _callData calldata, contains function signature which has to be called in this contract as well as the values, hashed and encoded.
  function xReceive(
    bytes32 _transferId,
    uint256 _amount,
    address _asset,
    address _originSender,
    uint32 _origin,
    bytes memory _callData
  ) external onlySource(_originSender, _origin) returns (bytes memory) {
    (bool success, ) = address(this).call(_callData);
    require(success, "xReceive: No success");
  }

  /// @notice Step 1 push; Game pushes totalDeltaAllocations to xChainController
  /// @notice Pushes the delta allocations from the game to the xChainController
  /// @param _vaultNumber number of the vault
  /// @param _deltas Array with delta Allocations for all chainIds
  function pushAllocations(
    uint256 _vaultNumber,
    int256[] memory _deltas
  ) external payable onlyGame {
    if (homeChain == xControllerChain) {
      return IXChainController(xController).receiveAllocationsFromGame(_vaultNumber, _deltas);
    }
    bytes4 selector = bytes4(keccak256("receiveAllocations(uint256,int256[])"));
    bytes memory callData = abi.encodeWithSelector(selector, _vaultNumber, _deltas);

    xSend(xControllerChain, callData, 0);
  }

  /// @notice Step 1 receive; Game pushes totalDeltaAllocations to xChainController
  /// @notice Receives the delta allocations from the game and routes to xChainController
  /// @param _vaultNumber number of the vault
  /// @param _deltas Array with delta Allocations for all chainIds
  function receiveAllocations(uint256 _vaultNumber, int256[] memory _deltas) external onlySelf {
    return IXChainController(xController).receiveAllocationsFromGame(_vaultNumber, _deltas);
  }

  /// @notice Step 2 push; Vaults push totalUnderlying, totalSupply and totalWithdrawalRequests to xChainController
  /// @notice Pushes cross chain requests for the totalUnderlying for a vaultNumber on a chainId
  /// @param _vaultNumber Number of the vault
  /// @param _chainId Number of chain used
  /// @param _underlying TotalUnderling plus vault balance in vaultcurrency e.g USDC
  /// @param _totalSupply Supply of the LP token of the vault on given chainId
  /// @param _withdrawalRequests Total amount of withdrawal requests from the vault in LP Tokens
  function pushTotalUnderlying(
    uint256 _vaultNumber,
    uint32 _chainId,
    uint256 _underlying,
    uint256 _totalSupply,
    uint256 _withdrawalRequests
  ) external payable onlyVaults {
    if (_chainId == xControllerChain) {
      return
        IXChainController(xController).setTotalUnderlying(
          _vaultNumber,
          _chainId,
          _underlying,
          _totalSupply,
          _withdrawalRequests
        );
    } else {
      bytes4 selector = bytes4(
        keccak256("receiveTotalUnderlying(uint256,uint32,uint256,uint256,uint256)")
      );
      bytes memory callData = abi.encodeWithSelector(
        selector,
        _vaultNumber,
        _chainId,
        _underlying,
        _totalSupply,
        _withdrawalRequests
      );

      xSend(xControllerChain, callData, 0);
    }
  }

  /// @notice Step 2 receive; Vaults push totalUnderlying, totalSupply and totalWithdrawalRequests to xChainController
  /// @notice Receive and set totalUnderlyings from the vaults for every chainId
  /// @param _vaultNumber Number of the vault
  /// @param _chainId Number of chain used
  /// @param _underlying TotalUnderling plus vault balance in vaultcurrency e.g USDC
  /// @param _totalSupply Supply of the LP token of the vault on given chainId
  /// @param _withdrawalRequests Total amount of withdrawal requests from the vault in LP Tokens
  function receiveTotalUnderlying(
    uint256 _vaultNumber,
    uint32 _chainId,
    uint256 _underlying,
    uint256 _totalSupply,
    uint256 _withdrawalRequests
  ) external onlySelf {
    return
      IXChainController(xController).setTotalUnderlying(
        _vaultNumber,
        _chainId,
        _underlying,
        _totalSupply,
        _withdrawalRequests
      );
  }

  /// @notice Step 3 push; xChainController pushes exchangeRate and amount the vaults have to send back to all vaults
  /// @param _vault Address of the Derby Vault on given chainId
  /// @param _chainId Number of chain used
  /// @param _amountToSendBack Amount the vault has to send back
  /// @param _exchangeRate New exchangerate for vaults
  function pushSetXChainAllocation(
    address _vault,
    uint32 _chainId,
    uint256 _amountToSendBack,
    uint256 _exchangeRate,
    bool _receivingFunds
  ) external payable onlyController {
    if (_chainId == homeChain) {
      return IVault(_vault).setXChainAllocation(_amountToSendBack, _exchangeRate, _receivingFunds);
    } else {
      bytes4 selector = bytes4(
        keccak256("receiveSetXChainAllocation(address,uint256,uint256,bool)")
      );
      bytes memory callData = abi.encodeWithSelector(
        selector,
        _vault,
        _amountToSendBack,
        _exchangeRate,
        _receivingFunds
      );

      xSend(_chainId, callData, 0);
    }
  }

  /// @notice Step 3 receive; xChainController pushes exchangeRate and amount the vaults have to send back to all vaults
  /// @param _vault Address of the Derby Vault on given chainId
  /// @param _amountToSendBack Amount the vault has to send back
  /// @param _exchangeRate New exchangerate for vaults
  function receiveSetXChainAllocation(
    address _vault,
    uint256 _amountToSendBack,
    uint256 _exchangeRate,
    bool _receivingFunds
  ) external onlySelf {
    return IVault(_vault).setXChainAllocation(_amountToSendBack, _exchangeRate, _receivingFunds);
  }

  /// @notice Step 4 push; Push funds from vaults to xChainController
  /// @notice Transfers funds from vault to xController for crosschain rebalance
  /// @param _vaultNumber Address of the Derby Vault on given chainId
  /// @param _amount Number of the vault
  /// @param _asset Address of the token to send e.g USDC
  /// @param _slippage Slippage tollerance for xChain swap, in BPS (i.e. 30 = 0.3%)
  /// @param _relayerFee The fee offered to the relayers
  function xTransferToController(
    uint256 _vaultNumber,
    uint256 _amount,
    address _asset,
    uint256 _slippage,
    uint256 _relayerFee
  ) external payable onlyVaults {
    if (homeChain == xControllerChain) {
      IERC20(_asset).transferFrom(msg.sender, xController, _amount);
      IXChainController(xController).upFundsReceived(_vaultNumber);
    } else {
      xTransfer(_asset, _amount, xController, xControllerChain, _slippage, _relayerFee);
      pushFeedbackToXController(_vaultNumber, _relayerFee);
    }
  }

  /// @notice Step 4 push; Push funds from vaults to xChainController
  /// @notice Push crosschain feedback to xController to know when the vaultNumber has sent funds
  /// @param _vaultNumber Number of the vault
  /// @param _relayerFee The fee offered to the relayers
  function pushFeedbackToXController(uint256 _vaultNumber, uint256 _relayerFee) internal {
    bytes4 selector = bytes4(keccak256("receiveFeedbackToXController(uint256)"));
    bytes memory callData = abi.encodeWithSelector(selector, _vaultNumber);

    xSend(xControllerChain, callData, _relayerFee);
  }

  /// @notice Step 4 receive; Push funds from vaults to xChainController
  /// @notice Receive crosschain feedback to xController to know when the vaultNumber has sent funds
  /// @param _vaultNumber Number of the vault
  function receiveFeedbackToXController(uint256 _vaultNumber) external onlySelf {
    return IXChainController(xController).upFundsReceived(_vaultNumber);
  }

  /// @notice Step 5 push; Push funds from xChainController to vaults
  /// @notice Transfers funds from xController to vault for crosschain rebalance
  /// @param _chainId Number of chainId
  /// @param _amount Amount to send to vault in vaultcurrency
  /// @param _asset Addres of underlying e.g USDC
  /// @param _slippage Slippage tollerance for xChain swap, in BPS (i.e. 30 = 0.3%)
  /// @param _relayerFee The fee offered to the relayers
  function xTransferToVaults(
    address _vault,
    uint32 _chainId,
    uint256 _amount,
    address _asset,
    uint256 _slippage,
    uint256 _relayerFee
  ) external payable onlyController {
    if (_chainId == homeChain) {
      IVault(_vault).receiveFunds();
      IERC20(_asset).transferFrom(msg.sender, _vault, _amount);
    } else {
      pushFeedbackToVault(_chainId, _vault, _relayerFee);
      xTransfer(_asset, _amount, _vault, _chainId, _slippage, _relayerFee);
    }
  }

  /// @notice Step 5 push; Push funds from xChainController to vaults
  /// @notice Push feedback message so the vault knows it has received funds and is ready to rebalance
  /// @param _chainId Number of chainId
  /// @param _vault Address of the vault on given chainId
  /// @param _relayerFee The fee offered to the relayers
  function pushFeedbackToVault(uint32 _chainId, address _vault, uint256 _relayerFee) internal {
    bytes4 selector = bytes4(keccak256("receiveFeedbackToVault(address)"));
    bytes memory callData = abi.encodeWithSelector(selector, _vault);

    xSend(_chainId, callData, _relayerFee);
  }

  /// @notice Step 5 receive; Push funds from xChainController to vaults
  /// @notice Receive feedback message so the vault knows it has received funds and is ready to rebalance
  /// @param _vault Address of the vault on given chainId
  function receiveFeedbackToVault(address _vault) external onlySelfOrVault {
    return IVault(_vault).receiveFunds();
  }

  /// @notice Step 6 push; Game pushes deltaAllocations to vaults
  /// @notice Push protocol allocation array from the game to all vaults/chains
  /// @param _vault Address of the vault on given chainId
  /// @param _deltas Array with delta allocations where the index matches the protocolId
  function pushProtocolAllocationsToVault(
    uint32 _chainId,
    address _vault,
    int256[] memory _deltas
  ) external payable onlyGame {
    if (_chainId == homeChain) return IVault(_vault).receiveProtocolAllocations(_deltas);
    else {
      bytes4 selector = bytes4(keccak256("receiveProtocolAllocationsToVault(address,int256[])"));
      bytes memory callData = abi.encodeWithSelector(selector, _vault, _deltas);

      xSend(_chainId, callData, 0);
    }
  }

  /// @notice Step 6 receive; Game pushes deltaAllocations to vaults
  /// @notice Receives protocol allocation array from the game to all vaults/chains
  /// @param _vault Address of the vault on given chainId
  /// @param _deltas Array with delta allocations where the index matches the protocolId
  function receiveProtocolAllocationsToVault(
    address _vault,
    int256[] memory _deltas
  ) external onlySelf {
    return IVault(_vault).receiveProtocolAllocations(_deltas);
  }

  /// @notice Step 8 push; Vaults push rewardsPerLockedToken to game
  /// @notice Push price and rewards array from vaults to the game
  /// @param _vaultNumber Number of the vault
  /// @param _chainId Number of chain used
  /// @param _rewards Array with rewardsPerLockedToken of all protocols in vault => index matches protocolId
  function pushRewardsToGame(
    uint256 _vaultNumber,
    uint32 _chainId,
    int256[] memory _rewards
  ) external payable onlyVaults {
    if (_chainId == gameChain) {
      return IGame(game).settleRewards(_vaultNumber, _chainId, _rewards);
    } else {
      bytes4 selector = bytes4(keccak256("receiveRewardsToGame(uint256,uint32,int256[])"));
      bytes memory callData = abi.encodeWithSelector(selector, _vaultNumber, _chainId, _rewards);

      xSend(gameChain, callData, 0);
    }
  }

  /// @notice Step 8 receive; Vaults push rewardsPerLockedToken to game
  /// @notice Receives price and rewards array from vaults to the game
  /// @param _vaultNumber Number of the vault
  /// @param _chainId Number of chain used
  /// @param _rewards Array with rewardsPerLockedToken of all protocols in vault => index matches protocolId
  function receiveRewardsToGame(
    uint256 _vaultNumber,
    uint32 _chainId,
    int256[] memory _rewards
  ) external onlySelf {
    return IGame(game).settleRewards(_vaultNumber, _chainId, _rewards);
  }

  /// @notice Push feedback to the vault if the vault is set to on or off
  /// @param _vault Address of the Derby Vault on given chainId
  /// @param _chainId Number of chain used
  /// @param _state bool for chainId on or off
  function pushStateFeedbackToVault(
    address _vault,
    uint32 _chainId,
    bool _state
  ) external payable onlyController {
    if (_chainId == homeChain) {
      return IVault(_vault).toggleVaultOnOff(_state);
    } else {
      bytes4 selector = bytes4(keccak256("receiveStateFeedbackToVault(address,bool)"));
      bytes memory callData = abi.encodeWithSelector(selector, _vault, _state);

      xSend(_chainId, callData, 0);
    }
  }

  /// @notice Receive feedback for the vault if the vault is set to on or off
  /// @param _vault Address of the Derby Vault on given chainId
  /// @param _state bool for chainId on or off
  function receiveStateFeedbackToVault(address _vault, bool _state) external onlySelf {
    return IVault(_vault).toggleVaultOnOff(_state);
  }

  /// @notice returns number of decimals for the vault
  function getDecimals(address _vault) external view returns (uint256) {
    return IVault(_vault).decimals();
  }

  /// @notice Getter for dao address
  function getDao() public view returns (address) {
    return dao;
  }

  /*
  Only Dao functions
  */
  /// @notice set trusted provider on remote chains, allow owner to set it multiple times.
  /// @param _srcChainId Chain is for remote xprovider, some as the remote receiving contract chain id (xReceive)
  /// @param _srcAddress Address of remote xprovider
  function setTrustedRemoteConnext(uint32 _srcChainId, address _srcAddress) external onlyDao {
    trustedRemoteConnext[_srcChainId] = _srcAddress;
    emit SetTrustedRemoteConnext(_srcChainId, _srcAddress);
  }

  /// @notice Setter for xControlleraddress
  /// @param _xController New address of _xController
  function setXController(address _xController) external onlyDao {
    xController = _xController;
  }

  /// @notice Setter for xControllerProvider address
  /// @param _xControllerProvider New address of xProvider for xController chain
  function setXControllerProvider(address _xControllerProvider) external onlyDao {
    xControllerProvider = _xControllerProvider;
  }

  /// @notice Setter for xController chain id
  /// @param _xControllerChain new xController chainId
  function setXControllerChainId(uint32 _xControllerChain) external onlyDao {
    xControllerChain = _xControllerChain;
  }

  /// @notice Setter for homeChain Id
  /// @param _homeChain New home chainId
  function setHomeChain(uint32 _homeChain) external onlyDao {
    homeChain = _homeChain;
  }

  /// @notice Setter for gameChain Id
  /// @param _gameChain New chainId for game contract
  function setGameChainId(uint32 _gameChain) external onlyDao {
    gameChain = _gameChain;
  }

  /// @notice Whitelists vault address for onlyVault modifier
  function toggleVaultWhitelist(address _vault) external onlyDao {
    vaultWhitelist[_vault] = !vaultWhitelist[_vault];
  }

  /// @notice Setter for dao address
  function setDao(address _dao) external onlyDao {
    dao = _dao;
  }

  /// @notice Setter for guardian address
  /// @param _guardian new address of the guardian
  function setGuardian(address _guardian) external onlyDao {
    guardian = _guardian;
  }

  /// @notice Setter for new game address
  /// @param _game New address of the game
  function setGame(address _game) external onlyDao {
    game = _game;
  }

  /// @notice Setter for vault address to vaultNumber for guardian
  function setVaultAddress(uint256 _vaultNumber, address _vault) external onlyDao {
    vaults[_vaultNumber] = _vault;
  }

  /*
  Only Guardian functions
  */

  /// @notice Guardian function to send funds back to xController when xCall fails
  function sendFundsToXController(address _token) external onlyGuardian {
    require(xControllerChain == homeChain, "No xController on this chain");
    require(xController != address(0), "Zero address");

    uint256 balance = IERC20(_token).balanceOf(address(this));
    IERC20(_token).transfer(xController, balance);
  }

  /// @notice Guardian function to send funds back to vault when xCall fails
  function sendFundsToVault(uint256 _vaultNumber, address _token) external onlyGuardian {
    address vault = vaults[_vaultNumber];
    require(vault != address(0), "Zero address");

    uint256 balance = IERC20(_token).balanceOf(address(this));
    IERC20(_token).transfer(vault, balance);
  }
}