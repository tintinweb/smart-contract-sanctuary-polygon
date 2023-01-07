// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Permit.sol)

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
import "../extensions/IERC20Permit.sol";
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

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
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
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
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
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.14;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./Types.sol";

/**
 * @dev Inherit this contract to allow your smart contract to
 * - Make synchronous fee payments.
 * - Have call restrictions for functions to be automated.
 */
// solhint-disable private-vars-leading-underscore
abstract contract OpsReady {
    IOps public immutable ops;
    address public immutable dedicatedMsgSender;
    address private immutable _gelato;
    address internal constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address private constant OPS_PROXY_FACTORY =
        0xC815dB16D4be6ddf2685C201937905aBf338F5D7;

    /**
     * @dev
     * Only tasks created by _taskCreator defined in constructor can call
     * the functions with this modifier.
     */
    modifier onlyDedicatedMsgSender() {
        require(msg.sender == dedicatedMsgSender, "Only dedicated msg.sender");
        _;
    }

    /**
     * @dev
     * _taskCreator is the address which will create tasks for this contract.
     */
    constructor(address _ops, address _taskCreator) {
        ops = IOps(_ops);
        _gelato = IOps(_ops).gelato();
        (dedicatedMsgSender, ) = IOpsProxyFactory(OPS_PROXY_FACTORY).getProxyOf(
            _taskCreator
        );
    }

    /**
     * @dev
     * Transfers fee to gelato for synchronous fee payments.
     *
     * _fee & _feeToken should be queried from IOps.getFeeDetails()
     */
    function _transfer(uint256 _fee, address _feeToken) internal {
        if (_feeToken == ETH) {
            (bool success, ) = _gelato.call{value: _fee}("");
            require(success, "_transfer: ETH transfer failed");
        } else {
            SafeERC20.safeTransfer(IERC20(_feeToken), _gelato, _fee);
        }
    }

    function _getFeeDetails()
        internal
        view
        returns (uint256 fee, address feeToken)
    {
        (fee, feeToken) = ops.getFeeDetails();
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;

enum Module {
    RESOLVER,
    TIME,
    PROXY,
    SINGLE_EXEC
}

struct ModuleData {
    Module[] modules;
    bytes[] args;
}

interface IOps {
    function createTask(
        address execAddress,
        bytes calldata execDataOrSelector,
        ModuleData calldata moduleData,
        address feeToken
    ) external returns (bytes32 taskId);

    function cancelTask(bytes32 taskId) external;

    function getFeeDetails() external view returns (uint256, address);

    function gelato() external view returns (address payable);

    function taskTreasury() external view returns (ITaskTreasuryUpgradable);
}

interface ITaskTreasuryUpgradable {
    function depositFunds(
        address receiver,
        address token,
        uint256 amount
    ) external payable;

    function withdrawFunds(
        address payable receiver,
        address token,
        uint256 amount
    ) external;
}

interface IOpsProxyFactory {
    function getProxyOf(address account) external view returns (address, bool);
}

// SPDX-License-Identifier: MIT


pragma solidity ^0.8.13;

import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "../lib/ops/contracts/integrations/OpsReady.sol";

interface veTetu {
  function increaseUnlockTime(uint _tokenId, uint _lockDuration) external returns (uint power, uint unlockDate);
  function isApprovedOrOwner(address _spender, uint _tokenId) external view returns (bool);
  function ownerOf(uint _tokenId) external view returns (address);
  function lockedEnd(uint _tokenId) external view returns (uint);
  function setApprovalForAll(address _operator, bool _approved) external;
  function tokenOfOwnerByIndex(address _owner, uint _tokenIndex) external view returns (uint);
}


// simple proxy contract that users can defer relocking capabilities to.
// this is just safety measure to ensure that the operator authority
// can't be abused
contract veTetuRelockerProxy {
  address public constant VETETU = 0x6FB29DD17fa6E27BD112Bc3A2D0b8dae597AeDA4;
  address public immutable operator;

  constructor(address _operator) { 
    operator = _operator;
  }

  function relock(uint veNFT, uint duration) external returns (bool) {
    require(msg.sender == operator);
    veTetu(VETETU).increaseUnlockTime(veNFT, duration);
    return true;
  }

}


contract veTetuRelocker is OpsReady {
    address public constant VETETU = 0x6FB29DD17fa6E27BD112Bc3A2D0b8dae597AeDA4;
    address public constant OPS = 0x527a819db1eb0e34426297b03bae11F2f8B3A19E;

    uint internal constant MAX_TIME = 16 weeks;
    uint internal constant WEEK = 1 weeks;
    // minimum balance needed to be queued
    uint public constant MIN_ALLOWANCE = 100000000000000000;
    address public immutable relocker;

    address public operator;
    uint[] public veNFTs;
    mapping(uint => uint) internal _veNFTtoIdx;
    bool public paused = false;
    mapping(uint => uint) public balances;
    mapping(uint => uint) public lockTime;

    constructor(address ops, address _taskCreator) OpsReady(ops, _taskCreator) {
      operator = _taskCreator;
      relocker = address(new veTetuRelockerProxy(address(this)));
    }

    receive() external payable {
      _registerAll(msg.value);
    }

    function registerAll() external payable {
      _registerAll(msg.value);
    }

    // returns all veNFTs owned by the given user that can be registered
    function userTokensToBeRegistered(address user) public view returns (uint[] memory) {
      uint i = 0;
      uint veNFT;
      uint j = 0;
      do { 
        veNFT = veTetu(VETETU).tokenOfOwnerByIndex(user, i++);
        if (_registerCondition(veNFT)) {
          j++;
        }
      } while (veNFT > 0);
      uint[] memory toks = new uint[](j);
      i = 0;
      j = 0;
      do {
        veNFT = veTetu(VETETU).tokenOfOwnerByIndex(user, i++);
        if (_registerCondition(veNFT)) {
          toks[j++] = veNFT;
        }
      } while (veNFT > 0);
      return toks;
    }

    function _registerAll(uint value) internal {
      uint[] memory toks = userTokensToBeRegistered(msg.sender);
      if (toks.length == 0) { return; }
      uint perToken = value / toks.length;
      uint i;
      for(i = 0; i < toks.length; i++){
         _register(toks[i], perToken, MAX_TIME);
      }
    }

    function setOperator(address newOperator) external returns (bool) {
      require(msg.sender == operator);
      operator = newOperator;
      return true;
    }

    function setPaused(bool _paused) external returns (bool) {
      require(msg.sender == operator);
      paused = _paused;
      return true;
    }

    function rescueToken(address tok, uint amount) external returns (bool){
      require(msg.sender == operator);
      require(tok != VETETU);
      IERC20(tok).transfer(operator, amount);
      return true;
    }

    function _deposit(uint veNFT, uint amount) internal{
      balances[veNFT] = amount + balances[veNFT];
    }

    function _withdraw(uint veNFT, uint amount) internal{
      balances[veNFT] = balances[veNFT] - amount;
    }

    function register(uint veNFT) external payable returns (uint idx) {
      require(_registerCondition(veNFT));
      return _register(veNFT, msg.value, MAX_TIME);
    }

    function register(uint veNFT, uint _weeks) external payable returns (uint idx) {
      require(_registerCondition(veNFT));
      require (_weeks <= 16);
      return _register(veNFT, msg.value, _weeks * WEEK);
    }

    function _registerCondition(uint veNFT) internal view returns (bool) {
      return veNFT > 0
             && veTetu(VETETU).isApprovedOrOwner(msg.sender, veNFT) 
             && veTetu(VETETU).isApprovedOrOwner(relocker, veNFT)
             && !isRegistered(veNFT);
    }

    function _register(uint veNFT, uint value, uint duration) internal returns (uint idx) {
      _deposit(veNFT, value);

      idx = veNFTs.length;
      veNFTs.push(veNFT);
      refreshIdx(idx);
      lockTime[veNFT] = duration;
      return idx;
    }

    function addToBalance(uint veNFT) external payable returns (bool) {
       _addToBalanceFor(veNFT, msg.sender, msg.value);
       return true;
    }

    function addToBalanceFor(uint veNFT, address to) external payable returns (bool) {
      _addToBalanceFor(veNFT, to, msg.value);
      return true;
    }

    function _addToBalanceFor(uint veNFT, address to, uint value) internal {
      // doesn't actually enforce anything, just a sanity check
      require(veTetu(VETETU).isApprovedOrOwner(to, veNFT));
      _deposit(veNFT, value);
      
    }

    function withdrawFromBalance(uint veNFT, uint amount) external returns (bool) {
      require(veTetu(VETETU).isApprovedOrOwner(msg.sender, veNFT));
      _withdraw(veNFT, amount);
      payable(msg.sender).transfer(amount);
      return true;
    }

    function setLockTIme(uint veNFT, uint _weeks) external returns (bool) {
      require(veTetu(VETETU).isApprovedOrOwner(msg.sender, veNFT));
      require (_weeks <= 16);
      lockTime[veNFT] = _weeks * WEEK;
      return true;
    }

    function isRegistered(uint veNFT) public view returns (bool) {
      uint idx = _veNFTtoIdx[veNFT];
      return (idx > 0);
    }

    function veNFTtoIdx(uint veNFT) public view returns (uint) {
      uint idx = _veNFTtoIdx[veNFT];
      require(idx > 0);
      return (idx-1);
    }

    function refreshIdx(uint idx) internal{
      _veNFTtoIdx[veNFTs[idx]] = (idx + 1);
    }


    function unregister(uint veNFT, address fee_return) public  returns (bool) { 
      require(veTetu(VETETU).isApprovedOrOwner(msg.sender, veNFT));
      _unregister(veNFT, fee_return);
      return true;
    }

    function _unregister(uint veNFT, address fee_return) internal {
      uint idx = veNFTtoIdx(veNFT);
      veNFTs[idx] = veNFTs[veNFTs.length - 1];
      refreshIdx(idx);
      _veNFTtoIdx[veNFT] = 0;
      veNFTs.pop();

      uint bal = balances[veNFT];
      _withdraw(veNFT, bal);
      payable(fee_return).transfer(bal);
    }

    function unregister(uint veNFT) external returns (bool) {
      return unregister(veNFT, msg.sender);
    }

    function unregisterAll() external returns (bool) {
      return unregisterAll(msg.sender);
    }

    function unregisterAll(address fee_return) public returns (bool) {
      uint i = 0;
      uint veNFT;
      
      do {
        veNFT = veTetu(VETETU).tokenOfOwnerByIndex(msg.sender, i++);
        if(isRegistered(veNFT)){
          _unregister(veNFT, fee_return);
        }
      }
      while (veNFT > 0);
      return true;
    }

    function floor(uint a, uint m) pure internal returns (uint ) {
      return (a / m) * m;
    }

    function getReadyNFT() public view returns (bool success, uint veNFT) {
      if (paused || veNFTs.length == 0) {
        return (false, 0);
      }
      uint lockEnd;
      uint balance;

      // start at an arbitrary point in the list
      // so we can't get stuck
      uint startidx = block.timestamp % veNFTs.length;
      uint i = startidx;

      do {
        veNFT = veNFTs[i];
        lockEnd = veTetu(VETETU).lockedEnd(veNFT);
        balance = balances[veNFT];

        if (   floor(block.timestamp + lockTime[veNFT], WEEK) > lockEnd
            && lockEnd > block.timestamp
            && balance >= MIN_ALLOWANCE 
            && veTetu(VETETU).isApprovedOrOwner(relocker, veNFT)) 
          { return (true, veNFT); }
        i = (i + 1) % veNFTs.length;
        } while(i != startidx);
      return (false, 0);
    }
    
    // for gelato resolver
    function checker()
        external
        view
        returns (bool canExec, bytes memory execPayload)
    {
        (bool success, uint veNFT) = getReadyNFT();
        if (!success) {
          return (false, bytes("No veNFTs ready"));
        }

        execPayload = abi.encodeCall(veTetuRelocker.processLock, (veNFT));
        return (true, execPayload);
    }

    function processLock(uint veNFT) external onlyDedicatedMsgSender returns (bool) {
      require(!paused);
      require(isRegistered(veNFT));

      veTetuRelockerProxy(relocker).relock(veNFT, lockTime[veNFT]);

      (uint256 fee,address feeToken) = _getFeeDetails();
      require(feeToken == ETH);
      _withdraw(veNFT, fee);
      _transfer(fee,feeToken);
      return true;
    }

}