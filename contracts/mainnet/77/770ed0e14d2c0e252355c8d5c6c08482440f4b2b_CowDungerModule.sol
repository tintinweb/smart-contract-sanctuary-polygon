// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {AutomateReady} from "./gelato/AutomateReady.sol";
import {ISafe} from "./interfaces/safe/ISafe.sol";

import {IMilkMan} from "./interfaces/milkman/IMilkMan.sol";

import {IERC20} from "./interfaces/vendored/IERC20.sol";

contract CowDungerModule is AutomateReady {
    ////////////////////////////////////////////////////////////////////////////
    // STATE VARIABLES
    ////////////////////////////////////////////////////////////////////////////

    ISafe public immutable safe;
    address[] public whitelist;

    ////////////////////////////////////////////////////////////////////////////
    // CONSTANTS
    ////////////////////////////////////////////////////////////////////////////
    address internal constant MILK_MAN = 0x11C76AD590ABDFFCD980afEC9ad951B160F02797;
    address internal constant META_PRICE_CHECKER = 0xf447Bf3CF8582E4DaB9c34C5b261A7b6AD4D6bDD;
    address internal constant SUSHI_PRICE_CHECKER = 0x5A5633909060c75e5B7cB4952eFad918c711F587;

    address internal constant WETH_MAINNET = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address internal constant WETH_GOERLI = 0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6;

    uint256 internal constant MAINNET_CHAIN_ID = 1;
    uint256 internal constant GOERLI_CHAIN_ID = 5;

    ////////////////////////////////////////////////////////////////////////////
    // ERRORS
    ////////////////////////////////////////////////////////////////////////////

    error NotSigner(address safe, address executor);
    error ExecutionFailure(address to, bytes data, uint256 timestamp);

    ////////////////////////////////////////////////////////////////////////////
    // EVENTS
    ////////////////////////////////////////////////////////////////////////////

    event TokenWhitelisted(address token);
    event CowDungMilked(address tokenSell, uint256 soldAmount, uint256 timestamp);

    //////////////////////////////////////////////////////////////////////////
    // MODIFIERS
    //////////////////////////////////////////////////////////////////////////

    modifier isSigner(ISafe _safe) {
        address[] memory signers = _safe.getOwners();
        bool isOwner;
        for (uint256 i; i < signers.length; i++) {
            if (signers[i] == msg.sender) {
                isOwner = true;
                break;
            }
        }
        if (!isOwner) revert NotSigner(address(_safe), msg.sender);
        _;
    }

    constructor(address _safe, address _automate, address _taskCreator) AutomateReady(_automate, _taskCreator) {
        safe = ISafe(payable(_safe));
    }

    ////////////////////////////////////////////////////////////////////////////
    // PUBLIC
    ////////////////////////////////////////////////////////////////////////////

    function whitelistLength() public view returns (uint256) {
        return whitelist.length;
    }

    receive() external payable {}

    function addTokensWhitelist(address[] calldata _tokens) external isSigner(safe) {
        for (uint256 i; i < _tokens.length; i++) {
            address token = _tokens[i];
            whitelist.push(token);
            emit TokenWhitelisted(token);
        }
    }

    function _isWhitelisted(address _token) external view returns (bool) {
        for (uint256 i; i < whitelist.length; i++) {
            if (whitelist[i] == _token) {
                return true;
            }
        }
        return false;
    }

    function dung(uint256[] calldata _toSell) external onlyDedicatedMsgSender {
        uint256 chainId = block.chainid;
        address checker;
        // NOTE: naive check data to be zero
        bytes memory priceCheckerData;

        for (uint256 i; i < _toSell.length; i++) {
            if (_toSell[i] > 0) {
                address sellToken = whitelist[i];
                // 1. Approve milkman
                _checkTransactionAndExecute(safe, sellToken, abi.encodeCall(IERC20.approve, (MILK_MAN, _toSell[i])));
                // 2. Place swap trade in milkman
                if (chainId == MAINNET_CHAIN_ID) {
                    checker = META_PRICE_CHECKER;
                } else if (chainId == GOERLI_CHAIN_ID) {
                    checker = SUSHI_PRICE_CHECKER;
                }
                _checkTransactionAndExecute(
                    safe,
                    MILK_MAN,
                    abi.encodeCall(
                        IMilkMan.requestSwapExactTokensForTokens,
                        (
                            _toSell[i],
                            sellToken,
                            checker == META_PRICE_CHECKER ? WETH_MAINNET : WETH_GOERLI,
                            address(safe),
                            checker,
                            priceCheckerData
                        )
                    )
                );
                emit CowDungMilked(sellToken, _toSell[i], block.timestamp);
            }
        }

        // Pay the Gelato automator
        (uint256 fee, address feeToken) = _getFeeDetails();
        _transfer(fee, feeToken);
    }

    ////////////////////////////////////////////////////////////////////////////
    // INTERNAL
    ////////////////////////////////////////////////////////////////////////////

    /// @notice Allows executing specific calldata into an address thru a gnosis-safe, which have enable this contract as module.
    /// @param to Contract address where we will execute the calldata.
    /// @param data Calldata to be executed within the boundaries of the `allowedFunctions`.
    function _checkTransactionAndExecute(ISafe _safe, address to, bytes memory data) internal {
        if (data.length >= 4) {
            bool success = _safe.execTransactionFromModule(to, 0, data, ISafe.Operation.Call);
            if (!success) revert ExecutionFailure(to, data, block.timestamp);
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.14;

import "../oz/SafeERC20.sol";
import "./Types.sol";

/**
 * @dev Inherit this contract to allow your smart contract to
 * - Make synchronous fee payments.
 * - Have call restrictions for functions to be automated.
 * - https://docs.gelato.network/developer-services/automate/paying-for-your-transactions#transaction-pays-for-itself
 */
// solhint-disable private-vars-leading-underscore
abstract contract AutomateReady {
    mapping(address => bool) public whitelistedAgents;
    IAutomate public immutable automate;
    address public immutable dedicatedMsgSender;
    address private immutable _gelato;
    address internal constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address private constant OPS_PROXY_FACTORY = 0xC815dB16D4be6ddf2685C201937905aBf338F5D7;

    /**
     * @dev
     * Only tasks created by _taskCreator defined in constructor can call
     * the functions with this modifier.
     */
    modifier onlyDedicatedMsgSender() {
        require(msg.sender == dedicatedMsgSender || whitelistedAgents[msg.sender], "Only dedicated msg.sender");
        _;
    }

    /**
     * @dev
     * _taskCreator is the address which will create tasks for this contract.
     */
    constructor(address _automate, address _taskCreator) {
        automate = IAutomate(_automate);
        _gelato = IAutomate(_automate).gelato();
        (dedicatedMsgSender,) = IOpsProxyFactory(OPS_PROXY_FACTORY).getProxyOf(_taskCreator);
    }

    function allowAgent(address _addr) external {
        whitelistedAgents[_addr] = true;
    }

    function disallowAgent(address _addr) external {
        whitelistedAgents[_addr] = false;
    }

    /**
     * @dev
     * Transfers fee to gelato for synchronous fee payments.
     *
     * _fee & _feeToken should be queried from IAutomate.getFeeDetails()
     */
    function _transfer(uint256 _fee, address _feeToken) internal {
        if (_feeToken == ETH) {
            (bool success,) = _gelato.call{value: _fee}("");
            require(success, "_transfer: ETH transfer failed");
        } else {
            SafeERC20.safeTransfer(IERC20(_feeToken), _gelato, _fee);
        }
    }

    function _getFeeDetails() internal view returns (uint256 fee, address feeToken) {
        (fee, feeToken) = automate.getFeeDetails();
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

interface IAutomate {
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
    function depositFunds(address receiver, address token, uint256 amount) external payable;

    function withdrawFunds(address payable receiver, address token, uint256 amount) external;
}

interface IOpsProxyFactory {
    function getProxyOf(address account) external view returns (address, bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IMilkMan {
    event SwapRequested(
        address orderContract,
        address orderCreator,
        uint256 amountIn,
        address fromToken,
        address toToken,
        address to,
        address priceChecker,
        bytes priceCheckerData
    );

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function cancelSwap(
        uint256 amountIn,
        address fromToken,
        address toToken,
        address to,
        address priceChecker,
        bytes memory priceCheckerData
    ) external;

    function initialize(address fromToken, bytes32 _swapHash) external;

    function isValidSignature(bytes32 orderDigest, bytes memory encodedOrder) external view returns (bytes4);

    function requestSwapExactTokensForTokens(
        uint256 amountIn,
        address fromToken,
        address toToken,
        address to,
        address priceChecker,
        bytes memory priceCheckerData
    ) external;

    function swapHash() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.19;

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
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/extensions/IERC20Permit.sol)

pragma solidity ^0.8.19;

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
    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s)
        external;

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
pragma solidity ^0.8.17;

interface ISafe {
    enum Operation {
        Call,
        DelegateCall
    }

    event AddedOwner(address indexed owner);
    event ApproveHash(bytes32 indexed approvedHash, address indexed owner);
    event ChangedFallbackHandler(address indexed handler);
    event ChangedGuard(address indexed guard);
    event ChangedThreshold(uint256 threshold);
    event DisabledModule(address indexed module);
    event EnabledModule(address indexed module);
    event ExecutionFailure(bytes32 indexed txHash, uint256 payment);
    event ExecutionFromModuleFailure(address indexed module);
    event ExecutionFromModuleSuccess(address indexed module);
    event ExecutionSuccess(bytes32 indexed txHash, uint256 payment);
    event RemovedOwner(address indexed owner);
    event SafeReceived(address indexed sender, uint256 value);
    event SafeSetup(
        address indexed initiator, address[] owners, uint256 threshold, address initializer, address fallbackHandler
    );
    event SignMsg(bytes32 indexed msgHash);

    fallback() external;

    function VERSION() external view returns (string memory);

    function addOwnerWithThreshold(address owner, uint256 _threshold) external;

    function approveHash(bytes32 hashToApprove) external;

    function approvedHashes(address, bytes32) external view returns (uint256);

    function changeThreshold(uint256 _threshold) external;

    function checkNSignatures(bytes32 dataHash, bytes memory data, bytes memory signatures, uint256 requiredSignatures)
        external
        view;

    function checkSignatures(bytes32 dataHash, bytes memory data, bytes memory signatures) external view;

    function disableModule(address prevModule, address module) external;

    function domainSeparator() external view returns (bytes32);

    function enableModule(address module) external;

    function encodeTransactionData(
        address to,
        uint256 value,
        bytes memory data,
        uint8 operation,
        uint256 safeTxGas,
        uint256 baseGas,
        uint256 gasPrice,
        address gasToken,
        address refundReceiver,
        uint256 _nonce
    ) external view returns (bytes memory);

    function execTransaction(
        address to,
        uint256 value,
        bytes memory data,
        uint8 operation,
        uint256 safeTxGas,
        uint256 baseGas,
        uint256 gasPrice,
        address gasToken,
        address refundReceiver,
        bytes memory signatures
    ) external payable returns (bool success);

    function execTransactionFromModule(address to, uint256 value, bytes memory data, Operation operation)
        external
        returns (bool success);

    function execTransactionFromModuleReturnData(address to, uint256 value, bytes memory data, Operation operation)
        external
        returns (bool success, bytes memory returnData);

    function getChainId() external view returns (uint256);

    function getModulesPaginated(address start, uint256 pageSize)
        external
        view
        returns (address[] memory array, address next);

    function getOwners() external view returns (address[] memory);

    function getStorageAt(uint256 offset, uint256 length) external view returns (bytes memory);

    function getThreshold() external view returns (uint256);

    function getTransactionHash(
        address to,
        uint256 value,
        bytes memory data,
        uint8 operation,
        uint256 safeTxGas,
        uint256 baseGas,
        uint256 gasPrice,
        address gasToken,
        address refundReceiver,
        uint256 _nonce
    ) external view returns (bytes32);

    function isModuleEnabled(address module) external view returns (bool);

    function isOwner(address owner) external view returns (bool);

    function nonce() external view returns (uint256);

    function removeOwner(address prevOwner, address owner, uint256 _threshold) external;

    function setFallbackHandler(address handler) external;

    function setGuard(address guard) external;

    function setup(
        address[] memory _owners,
        uint256 _threshold,
        address to,
        bytes memory data,
        address fallbackHandler,
        address paymentToken,
        uint256 payment,
        address paymentReceiver
    ) external;

    function signedMessages(bytes32) external view returns (uint256);

    function simulateAndRevert(address targetContract, bytes memory calldataPayload) external;

    function swapOwner(address prevOwner, address oldOwner, address newOwner) external;

    receive() external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Address.sol)

pragma solidity ^0.8.19;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev The ETH balance of the account is not enough to perform the operation.
     */
    error AddressInsufficientBalance(address account);

    /**
     * @dev There's no code at `target` (it is not a contract).
     */
    error AddressEmptyCode(address target);

    /**
     * @dev A call to an address target failed. The target may have reverted.
     */
    error FailedInnerCall();

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
     * https://solidity.readthedocs.io/en/v0.8.0/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        if (address(this).balance < amount) {
            revert AddressInsufficientBalance(address(this));
        }

        (bool success,) = recipient.call{value: amount}("");
        if (!success) {
            revert FailedInnerCall();
        }
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
        return functionCallWithValue(target, data, 0, defaultRevert);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with a
     * `customRevert` function as a fallback when `target` reverts.
     *
     * Requirements:
     *
     * - `customRevert` must be a reverting function.
     *
     * _Available since v5.0._
     */
    function functionCall(address target, bytes memory data, function() internal view customRevert)
        internal
        returns (bytes memory)
    {
        return functionCallWithValue(target, data, 0, customRevert);
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
        return functionCallWithValue(target, data, value, defaultRevert);
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with a `customRevert` function as a fallback revert reason when `target` reverts.
     *
     * Requirements:
     *
     * - `customRevert` must be a reverting function.
     *
     * _Available since v5.0._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        function() internal view customRevert
    ) internal returns (bytes memory) {
        if (address(this).balance < value) {
            revert AddressInsufficientBalance(address(this));
        }
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, customRevert);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, defaultRevert);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, function() internal view customRevert)
        internal
        view
        returns (bytes memory)
    {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, customRevert);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, defaultRevert);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, function() internal view customRevert)
        internal
        returns (bytes memory)
    {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, customRevert);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided `customRevert`) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v5.0._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        function() internal view customRevert
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check if target is a contract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                if (target.code.length == 0) {
                    revert AddressEmptyCode(target);
                }
            }
            return returndata;
        } else {
            _revert(returndata, customRevert);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or with a default revert error.
     *
     * _Available since v5.0._
     */
    function verifyCallResult(bool success, bytes memory returndata) internal view returns (bytes memory) {
        return verifyCallResult(success, returndata, defaultRevert);
    }

    /**
     * @dev Same as {xref-Address-verifyCallResult-bool-bytes-}[`verifyCallResult`], but with a
     * `customRevert` function as a fallback when `success` is `false`.
     *
     * Requirements:
     *
     * - `customRevert` must be a reverting function.
     *
     * _Available since v5.0._
     */
    function verifyCallResult(bool success, bytes memory returndata, function() internal view customRevert)
        internal
        view
        returns (bytes memory)
    {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, customRevert);
        }
    }

    /**
     * @dev Default reverting function when no `customRevert` is provided in a function call.
     */
    function defaultRevert() internal pure {
        revert FailedInnerCall();
    }

    function _revert(bytes memory returndata, function() internal view customRevert) private view {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            customRevert();
            revert FailedInnerCall();
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.19;

import "../interfaces/oz/IERC20.sol";
import "../interfaces/oz/extensions/IERC20Permit.sol";
import "./Address.sol";

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

    /**
     * @dev An operation with an ERC20 token failed.
     */
    error SafeERC20FailedOperation(address token);

    /**
     * @dev Indicates a failed `decreaseAllowance` request.
     */
    error SafeERC20FailedDecreaseAllowance(address spender, uint256 currentAllowance, uint256 requestedDecrease);

    /**
     * @dev Transfer `value` amount of `token` from the calling contract to `to`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeCall(token.transfer, (to, value)));
    }

    /**
     * @dev Transfer `value` amount of `token` from `from` to `to`, spending the approval given by `from` to the
     * calling contract. If `token` returns no value, non-reverting calls are assumed to be successful.
     */
    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeCall(token.transferFrom, (from, to, value)));
    }

    /**
     * @dev Increase the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 oldAllowance = token.allowance(address(this), spender);
        forceApprove(token, spender, oldAllowance + value);
    }

    /**
     * @dev Decrease the calling contract's allowance toward `spender` by `requestedDecrease`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeDecreaseAllowance(IERC20 token, address spender, uint256 requestedDecrease) internal {
        unchecked {
            uint256 currentAllowance = token.allowance(address(this), spender);
            if (currentAllowance < requestedDecrease) {
                revert SafeERC20FailedDecreaseAllowance(spender, currentAllowance, requestedDecrease);
            }
            forceApprove(token, spender, currentAllowance - requestedDecrease);
        }
    }

    /**
     * @dev Set the calling contract's allowance toward `spender` to `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful. Compatible with tokens that require the approval to be set to
     * 0 before setting it to a non-zero value.
     */
    function forceApprove(IERC20 token, address spender, uint256 value) internal {
        bytes memory approvalCall = abi.encodeCall(token.approve, (spender, value));

        if (!_callOptionalReturnBool(token, approvalCall)) {
            _callOptionalReturn(token, abi.encodeCall(token.approve, (spender, 0)));
            _callOptionalReturn(token, approvalCall);
        }
    }

    /**
     * @dev Use a ERC-2612 signature to set the `owner` approval toward `spender` on `token`.
     * Revert on invalid signature.
     */
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
        if (nonceAfter != nonceBefore + 1) {
            revert SafeERC20FailedOperation(address(token));
        }
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

        bytes memory returndata = address(token).functionCall(data);
        if (returndata.length != 0 && !abi.decode(returndata, (bool))) {
            revert SafeERC20FailedOperation(address(token));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     *
     * This is a variant of {_callOptionalReturn} that silents catches all reverts and returns a bool instead.
     */
    function _callOptionalReturnBool(IERC20 token, bytes memory data) private returns (bool) {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We cannot use {Address-functionCall} here since this should return false
        // and not revert is the subcall reverts.

        (bool success, bytes memory returndata) = address(token).call(data);
        return success && (returndata.length == 0 || abi.decode(returndata, (bool))) && address(token).code.length > 0;
    }
}