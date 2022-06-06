// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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
pragma solidity 0.8.10;
pragma experimental ABIEncoderV2;

import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {ITaskExecutor} from "./interfaces/ITaskExecutor.sol";
import {IComptroller} from "./interfaces/IComptroller.sol";
import {IFund} from "./interfaces/IFund.sol";
import {Errors} from "./utils/Errors.sol";
import {DestructibleAction} from "./utils/DestructibleAction.sol";
import {DelegateCallAction} from "./utils/DelegateCallAction.sol";
import {AssetQuotaAction} from "./utils/AssetQuotaAction.sol";
import {DealingAssetAction} from "./utils/DealingAssetAction.sol";
import {LibParam} from "./libraries/LibParam.sol";

/// @title The fund action task executor
contract TaskExecutor is ITaskExecutor, DestructibleAction, DelegateCallAction, AssetQuotaAction, DealingAssetAction {
    using Address for address;
    using SafeERC20 for IERC20;
    using LibParam for bytes32;

    // prettier-ignore
    address public constant NATIVE_TOKEN = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    uint256 public constant PERCENTAGE_BASE = 1 ether;
    uint256 private constant _FEE_BASE = 1e4;
    IComptroller public immutable comptroller;

    event ExecFee(address indexed fund, address indexed token, uint256 fee);

    constructor(address payable owner_, address comptroller_) DestructibleAction(owner_) DelegateCallAction() {
        comptroller = IComptroller(comptroller_);
    }

    /// @notice Task execution function, will charge execution fee first.
    /// @param tokensIn_ The list of tokens used in execution.
    /// @param amountsIn_ The amount of tokens used in execution.
    /// @param tos_ The address of action.
    /// @param configs_ The configurations of executing actions.
    /// @param datas_ The action datas.
    /// @return The address of dealing asset list.
    /// inheritdoc ITaskExecutor, DelegateCallAction, AssetQuotaAction, DealingAssetAction.
    function batchExec(
        address[] calldata tokensIn_,
        uint256[] calldata amountsIn_,
        address[] calldata tos_,
        bytes32[] calldata configs_,
        bytes[] memory datas_
    ) external payable delegateCallOnly quotaCleanUp assetCleanUp returns (address[] memory) {
        _chargeExecutionFee(tokensIn_, amountsIn_);
        return _execs(tos_, configs_, datas_);
    }

    /// @notice The execution phase.
    /// @param tos_ The address of action.
    /// @param configs_ The configurations of executing actions.
    /// @param datas_ The action datas.
    /// @return The address of dealing asset list.
    function _execs(
        address[] memory tos_,
        bytes32[] memory configs_,
        bytes[] memory datas_
    ) internal returns (address[] memory) {
        bytes32[256] memory localStack;
        uint256 index = 0;

        Errors._require(tos_.length == datas_.length, Errors.Code.TASK_EXECUTOR_TOS_AND_DATAS_LENGTH_INCONSISTENT);
        Errors._require(tos_.length == configs_.length, Errors.Code.TASK_EXECUTOR_TOS_AND_CONFIGS_LENGTH_INCONSISTENT);

        uint256 level = IFund(msg.sender).level();

        for (uint256 i = 0; i < tos_.length; i++) {
            bytes32 config = configs_[i];

            if (config._isDelegateCall()) {
                // check comptroller delegate call
                Errors._require(
                    comptroller.canDelegateCall(level, tos_[i], bytes4(datas_[i])),
                    Errors.Code.TASK_EXECUTOR_INVALID_COMPTROLLER_DELEGATE_CALL
                );

                // Trim params from local stack depend on config
                _trimParams(datas_[i], config, localStack, index);

                // Execute action by delegate call
                bytes memory result = tos_[i].functionDelegateCall(
                    datas_[i],
                    "TaskExecutor: low-level delegate call failed"
                ); // use openzeppelin address delegate call, use error message directly

                // Store return data from action to local stack
                index = _parseReturn(result, config, localStack, index);
            } else {
                // Decode eth value from data
                (uint256 ethValue, bytes memory _data) = _decodeEthValue(datas_[i]);

                // check comptroller contract call
                Errors._require(
                    comptroller.canContractCall(level, tos_[i], bytes4(_data)),
                    Errors.Code.TASK_EXECUTOR_INVALID_COMPTROLLER_CONTRACT_CALL
                );

                // Trim params from local stack depend on config
                _trimParams(_data, config, localStack, index);

                // Execute action by call
                bytes memory result = tos_[i].functionCallWithValue(
                    _data,
                    ethValue,
                    "TaskExecutor: low-level call with value failed"
                ); // use openzeppelin address value call, use error message directly

                // Store return data from action to local stack depend on config
                index = _parseReturn(result, config, localStack, index);
            }
        }

        // verify dealing assets
        address[] memory dealingAssets = _getDealingAssets();
        Errors._require(
            comptroller.isValidDealingAssets(level, dealingAssets),
            Errors.Code.TASK_EXECUTOR_INVALID_DEALING_ASSET
        );
        return dealingAssets;
    }

    /// @notice Trimming the execution parameter if needed.
    /// @param data_ The execution data.
    /// @param config_ The configuration.
    /// @param localStack_ The stack the be referenced.
    /// @param index_ Current element count of localStack.
    function _trimParams(
        bytes memory data_,
        bytes32 config_,
        bytes32[256] memory localStack_,
        uint256 index_
    ) internal pure {
        if (config_._isStatic()) {
            // Don't need to trim parameters if static
            return;
        }

        // Trim the execution data base on the configuration and stack content if dynamic
        // Fetch the parameter configuration from config
        (uint256[] memory refs, uint256[] memory params) = config_._getParams();

        // Trim the data with the reference and parameters
        for (uint256 i = 0; i < refs.length; i++) {
            Errors._require(refs[i] < index_, Errors.Code.TASK_EXECUTOR_REFERENCE_TO_OUT_OF_LOCALSTACK);
            bytes32 ref = localStack_[refs[i]];
            uint256 offset = params[i];
            uint256 base = PERCENTAGE_BASE;
            assembly {
                let loc := add(add(data_, 0x20), offset)
                let m := mload(loc)
                // Adjust the value by multiplier if a dynamic parameter is not zero
                if iszero(iszero(m)) {
                    // Assert no overflow first
                    let p := mul(m, ref)
                    if iszero(eq(div(p, m), ref)) {
                        revert(0, 0)
                    } // require(p / m == ref)
                    ref := div(p, base)
                }
                mstore(loc, ref)
            }
        }
    }

    /// @notice Parse the execution return data into the local stack if needed.
    /// @param ret_ The return data.
    /// @param config_ The configuration.
    /// @param localStack_ The local stack to place the return values.
    /// @param index_ The current tail.
    /// @return The new index.
    function _parseReturn(
        bytes memory ret_,
        bytes32 config_,
        bytes32[256] memory localStack_,
        uint256 index_
    ) internal pure returns (uint256) {
        if (config_._isReferenced()) {
            // If so, parse the output and place it into local stack
            uint256 num = config_._getReturnNum();
            uint256 newIndex = _parse(localStack_, ret_, index_);
            Errors._require(
                newIndex == index_ + num,
                Errors.Code.TASK_EXECUTOR_RETURN_NUM_AND_PARSED_RETURN_NUM_NOT_MATCHED
            );
            index_ = newIndex;
        }
        return index_;
    }

    /// @notice Parse the return data into the local stack.
    /// @param localStack_ The local stack to place the return values.
    /// @param ret_ The return data.
    /// @param index_ The current tail.
    /// @return newIndex The new index.
    function _parse(
        bytes32[256] memory localStack_,
        bytes memory ret_,
        uint256 index_
    ) internal pure returns (uint256 newIndex) {
        uint256 len = ret_.length;
        // The return value should be multiple of 32-bytes to be parsed.
        Errors._require(len % 32 == 0, Errors.Code.TASK_EXECUTOR_ILLEGAL_LENGTH_FOR_PARSE);
        // Estimate the tail after the process.
        newIndex = index_ + len / 32;
        Errors._require(newIndex <= 256, Errors.Code.TASK_EXECUTOR_STACK_OVERFLOW);
        assembly {
            let offset := shl(5, index_)
            // Store the data into localStack
            for {
                let i := 0
            } lt(i, len) {
                i := add(i, 0x20)
            } {
                mstore(add(localStack_, add(i, offset)), mload(add(add(ret_, i), 0x20)))
            }
        }
    }

    /// @notice Decode eth value from the execution data.
    /// @param data_ The execution data.
    /// @return The first return uint256 value mean eth value,
    ///         the second return bytes value means execution data.
    function _decodeEthValue(bytes memory data_) internal pure returns (uint256, bytes memory) {
        return abi.decode(data_, (uint256, bytes));
    }

    /// @notice Charge execution fee from input tokens.
    /// @param tokensIn_ The input tokens.
    /// @param amountsIn_ The input token amounts.
    function _chargeExecutionFee(address[] calldata tokensIn_, uint256[] calldata amountsIn_) internal {
        // Check initial asset from white list
        uint256 level = IFund(msg.sender).level();
        Errors._require(
            comptroller.isValidInitialAssets(level, tokensIn_),
            Errors.Code.TASK_EXECUTOR_INVALID_INITIAL_ASSET
        );

        // collect execution fee to collector
        uint256 feePercentage = comptroller.execFeePercentage();
        address payable collector = payable(comptroller.execFeeCollector());

        for (uint256 i = 0; i < tokensIn_.length; i++) {
            // make sure all quota should be zero at the begin
            Errors._require(_isAssetQuotaZero(tokensIn_[i]), Errors.Code.TASK_EXECUTOR_NON_ZERO_QUOTA);

            // send fee to collector
            uint256 execFee = (amountsIn_[i] * feePercentage) / _FEE_BASE;
            IERC20(tokensIn_[i]).safeTransfer(collector, execFee);
            _setAssetQuota(tokensIn_[i], amountsIn_[i] - execFee);

            emit ExecFee(msg.sender, tokensIn_[i], execFee);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IAssetOracle {
    function calcConversionAmount(
        address base_,
        uint256 baseAmount_,
        address quote_
    ) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IAssetRegistry {
    function bannedResolvers(address) external view returns (bool);

    function register(address asset_, address resolver_) external;

    function unregister(address asset_) external;

    function banResolver(address resolver_) external;

    function unbanResolver(address resolver_) external;

    function resolvers(address asset_) external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IAssetRegistry} from "./IAssetRegistry.sol";
import {IAssetOracle} from "./IAssetOracle.sol";

interface IAssetRouter {
    function oracle() external view returns (IAssetOracle);

    function registry() external view returns (IAssetRegistry);

    function setOracle(address oracle_) external;

    function setRegistry(address registry_) external;

    function calcAssetsTotalValue(
        address[] calldata bases_,
        uint256[] calldata amounts_,
        address quote_
    ) external view returns (uint256);

    function calcAssetValue(
        address asset_,
        uint256 amount_,
        address quote_
    ) external view returns (int256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IAssetRouter} from "../assets/interfaces/IAssetRouter.sol";
import {IMortgageVault} from "./IMortgageVault.sol";
import {IDSProxyRegistry} from "./IDSProxy.sol";
import {ISetupAction} from "./ISetupAction.sol";

interface IComptroller {
    function owner() external view returns (address);

    function canDelegateCall(
        uint256 level_,
        address to_,
        bytes4 sig_
    ) external view returns (bool);

    function canContractCall(
        uint256 level_,
        address to_,
        bytes4 sig_
    ) external view returns (bool);

    function canHandlerCall(
        uint256 level_,
        address to_,
        bytes4 sig_
    ) external view returns (bool);

    function execFeePercentage() external view returns (uint256);

    function execFeeCollector() external view returns (address);

    function pendingLiquidator() external view returns (address);

    function pendingExpiration() external view returns (uint256);

    function execAssetValueToleranceRate() external view returns (uint256);

    function isValidDealingAsset(uint256 level_, address asset_) external view returns (bool);

    function isValidDealingAssets(uint256 level_, address[] calldata assets_) external view returns (bool);

    function isValidInitialAssets(uint256 level_, address[] calldata assets_) external view returns (bool);

    function assetCapacity() external view returns (uint256);

    function assetRouter() external view returns (IAssetRouter);

    function mortgageVault() external view returns (IMortgageVault);

    function pendingPenalty() external view returns (uint256);

    function execAction() external view returns (address);

    function mortgageTier(uint256 tier_) external view returns (bool, uint256);

    function isValidDenomination(address denomination_) external view returns (bool);

    function getDenominationDust(address denomination_) external view returns (uint256);

    function isValidCreator(address creator_) external view returns (bool);

    function dsProxyRegistry() external view returns (IDSProxyRegistry);

    function setupAction() external view returns (ISetupAction);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IDSProxy {
    function execute(address _target, bytes calldata _data) external payable returns (bytes memory response);

    function owner() external view returns (address);

    function setAuthority(address authority_) external;
}

interface IDSProxyFactory {
    function isProxy(address proxy) external view returns (bool);

    function build() external returns (address);

    function build(address owner) external returns (address);
}

interface IDSProxyRegistry {
    function proxies(address input) external view returns (address);

    function build() external returns (address);

    function build(address owner) external returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IFund {
    function level() external returns (uint256);

    function vault() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IMortgageVault {
    function mortgageToken() external view returns (IERC20);

    function totalAmount() external view returns (uint256);

    function fundAmounts(address fund_) external view returns (uint256);

    function mortgage(uint256 amount_) external;

    function claim(address receiver_) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ISetupAction {
    function maxApprove(IERC20 token_) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ITaskExecutor {
    function batchExec(
        address[] calldata tokensIn_,
        uint256[] calldata amountsIn_,
        address[] calldata tos_,
        bytes32[] calldata configs_,
        bytes[] memory datas_
    ) external payable returns (address[] calldata);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {StorageArray} from "./StorageArray.sol";
import {StorageMap} from "./StorageMap.sol";

library AssetQuota {
    using StorageArray for bytes32;
    using StorageMap for bytes32;

    // Data is stored in storage slot `uint256(keccak256('furucombo.funds.quota.map')) - 1`, so that it doesn't
    // conflict with the storage layout of the implementation behind the proxy.
    bytes32 private constant _QUOTA_MAP_SLOT = 0x1af59a3fd3f5a4bba6259b5a65dd4f4fbaab48545aeeabdfb60969120dbd5c35;

    // Data is stored in storage slot `uint256(keccak256('furucombo.funds.quota.array')) - 1`, so that it doesn't
    // conflict with the storage layout of the implementation behind the proxy.
    bytes32 private constant _QUOTA_ARR_SLOT = 0x041334f809138adff4aed76ee4e45b3671e485ee2dcac112682c24d3a0c21736;

    function _get(address key_) internal view returns (uint256) {
        bytes32 key = bytes32(bytes20(key_));
        return uint256(_QUOTA_MAP_SLOT._get(key));
    }

    function _set(address key_, uint256 val_) internal {
        bytes32 key = bytes32(bytes20(key_));
        uint256 oldVal = uint256(_QUOTA_MAP_SLOT._get(key));
        if (oldVal == 0) {
            _QUOTA_ARR_SLOT._push(key);
        }

        bytes32 val = bytes32(val_);
        _QUOTA_MAP_SLOT._set(key, val);
    }

    function _clean() internal {
        for (uint256 i = 0; i < _QUOTA_ARR_SLOT._getLength(); i++) {
            bytes32 key = _QUOTA_ARR_SLOT._get(i);
            _QUOTA_MAP_SLOT._set(key, 0);
        }
        _QUOTA_ARR_SLOT._delete();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {StorageArray} from "./StorageArray.sol";

library DealingAsset {
    using StorageArray for bytes32;

    // Data is stored in storage slot `uint256(keccak256('furucombo.funds.asset.array')) - 1`, so that it doesn't
    // conflict with the storage layout of the implementation behind the proxy.
    bytes32 private constant _ASSET_ARR_SLOT = 0x25241bfd865dc0cf716378d03594b4104571b985a2d5cf72950d41c4b7474874;

    function _add(address asset_) internal {
        if (!_exist(asset_)) {
            bytes32 asset = bytes32(bytes20(asset_));
            _ASSET_ARR_SLOT._push(asset);
        }
    }

    function _clean() internal {
        _ASSET_ARR_SLOT._delete();
    }

    function _assets() internal view returns (address[] memory) {
        uint256 length = _ASSET_ARR_SLOT._getLength();
        address[] memory assets = new address[](length);
        for (uint256 i = 0; i < length; i++) {
            assets[i] = address(bytes20(_ASSET_ARR_SLOT._get(i)));
        }
        return assets;
    }

    function _getLength() internal view returns (uint256) {
        return _ASSET_ARR_SLOT._getLength();
    }

    function _exist(address asset_) internal view returns (bool) {
        for (uint256 i = 0; i < _ASSET_ARR_SLOT._getLength(); i++) {
            if (asset_ == address(bytes20(_ASSET_ARR_SLOT._get(i)))) {
                return true;
            }
        }
        return false;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library LibParam {
    bytes32 private constant _STATIC_MASK = 0x0100000000000000000000000000000000000000000000000000000000000000;
    bytes32 private constant _CALLTYPE_MASK = 0x0200000000000000000000000000000000000000000000000000000000000000;
    bytes32 private constant _PARAMS_MASK = 0x0000000000000000000000000000000000000000000000000000000000000001;
    bytes32 private constant _REFS_MASK = 0x00000000000000000000000000000000000000000000000000000000000000FF;
    bytes32 private constant _RETURN_NUM_MASK = 0x00FF000000000000000000000000000000000000000000000000000000000000;

    uint256 private constant _REFS_LIMIT = 22;
    uint256 private constant _PARAMS_SIZE_LIMIT = 64;
    uint256 private constant _RETURN_NUM_OFFSET = 240;

    function _isStatic(bytes32 conf_) internal pure returns (bool) {
        return (conf_ & _STATIC_MASK == 0);
    }

    function _isReferenced(bytes32 conf_) internal pure returns (bool) {
        return !(_getReturnNum(conf_) == 0);
    }

    function _isDelegateCall(bytes32 conf_) internal pure returns (bool) {
        return (conf_ & _CALLTYPE_MASK == 0);
    }

    function _getReturnNum(bytes32 conf_) internal pure returns (uint256 num) {
        bytes32 temp = (conf_ & _RETURN_NUM_MASK) >> _RETURN_NUM_OFFSET;
        num = uint256(temp);
    }

    function _getParams(bytes32 conf_) internal pure returns (uint256[] memory refs, uint256[] memory params) {
        require(!_isStatic(conf_), "Static params");
        uint256 n = _REFS_LIMIT;
        while (conf_ & _REFS_MASK == _REFS_MASK && n > 0) {
            n--;
            conf_ = conf_ >> 8;
        }
        require(n > 0, "No dynamic param");
        refs = new uint256[](n);
        params = new uint256[](n);
        for (uint256 i = 0; i < n; i++) {
            refs[i] = uint256(conf_ & _REFS_MASK);
            conf_ = conf_ >> 8;
        }
        uint256 _i = 0;
        for (uint256 k = 0; k < _PARAMS_SIZE_LIMIT; k++) {
            if (conf_ & _PARAMS_MASK != 0) {
                require(_i < n, "Location count exceeds ref count");
                params[_i] = k * 32 + 4;
                _i++;
            }
            conf_ = conf_ >> 1;
        }
        require(_i == n, "Location count less than ref count");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library StorageArray {
    struct Slot {
        bytes32 value;
    }

    function _getSlot(bytes32 slot_) private pure returns (Slot storage ret) {
        assembly {
            ret.slot := slot_
        }
    }

    function _get(bytes32 slot_, uint256 index_) internal view returns (bytes32 val) {
        require(index_ < uint256(_getSlot(slot_).value), "StorageArray: _get invalid index");
        uint256 s = uint256(keccak256(abi.encodePacked(slot_))) + index_;
        val = _getSlot(bytes32(s)).value;
    }

    function _set(
        bytes32 slot_,
        uint256 index_,
        bytes32 val_
    ) internal {
        require(index_ < uint256(_getSlot(slot_).value), "StorageArray: _set invalid index");
        uint256 s = uint256(keccak256(abi.encodePacked(slot_))) + index_;
        _getSlot(bytes32(s)).value = val_;
    }

    function _push(bytes32 slot_, bytes32 val_) internal {
        uint256 length = uint256(_getSlot(slot_).value);
        _getSlot(slot_).value = bytes32(length + 1);
        _set(slot_, length, val_);
    }

    function _pop(bytes32 slot_) internal returns (bytes32 val) {
        uint256 length = uint256(_getSlot(slot_).value);
        length -= 1;
        uint256 s = uint256(keccak256(abi.encodePacked(slot_))) + length;
        val = _getSlot(bytes32(s)).value;
        _getSlot(slot_).value = bytes32(length);
    }

    function _getLength(bytes32 slot_) internal view returns (uint256) {
        return uint256(_getSlot(slot_).value);
    }

    function _delete(bytes32 slot_) internal {
        delete _getSlot(slot_).value;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library StorageMap {
    struct Slot {
        bytes32 value;
    }

    function _getSlot(bytes32 slot_) private pure returns (Slot storage ret) {
        assembly {
            ret.slot := slot_
        }
    }

    function _get(bytes32 slot_, bytes32 key_) internal view returns (bytes32 ret) {
        bytes32 b = keccak256(abi.encodePacked(key_, slot_));
        ret = _getSlot(b).value;
    }

    function _set(
        bytes32 slot_,
        bytes32 key_,
        bytes32 val_
    ) internal {
        bytes32 b = keccak256(abi.encodePacked(key_, slot_));
        _getSlot(b).value = val_;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {AssetQuota} from "../libraries/AssetQuota.sol";

/**
 * @dev Create immutable owner for action contract
 */
abstract contract AssetQuotaAction {
    modifier quotaCleanUp() {
        _cleanAssetQuota();
        _;
        _cleanAssetQuota();
    }

    function _getAssetQuota(address asset_) internal view returns (uint256) {
        return AssetQuota._get(asset_);
    }

    function _isAssetQuotaZero(address asset_) internal view returns (bool) {
        return _getAssetQuota(asset_) == 0;
    }

    function _setAssetQuota(address asset_, uint256 quota_) internal {
        AssetQuota._set(asset_, quota_);
    }

    function _increaseAssetQuota(address asset_, uint256 quota_) internal {
        uint256 oldQuota = AssetQuota._get(asset_);
        _setAssetQuota(asset_, oldQuota + quota_);
    }

    function _decreaseAssetQuota(address asset_, uint256 quota_) internal {
        uint256 oldQuota = AssetQuota._get(asset_);
        _setAssetQuota(asset_, oldQuota - quota_);
    }

    function _cleanAssetQuota() internal {
        AssetQuota._clean();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {DealingAsset} from "../libraries/DealingAsset.sol";

/**
 * @dev Create immutable owner for action contract
 */
abstract contract DealingAssetAction {
    modifier assetCleanUp() {
        _cleanAssets();
        _;
        _cleanAssets();
    }

    function _isDealingAssetExist(address asset_) internal view returns (bool) {
        return DealingAsset._exist(asset_);
    }

    function _getDealingAssets() internal view returns (address[] memory) {
        return DealingAsset._assets();
    }

    function _getDealingAssetLength() internal view returns (uint256) {
        return DealingAsset._getLength();
    }

    function _addDealingAsset(address asset_) internal {
        DealingAsset._add(asset_);
    }

    function _cleanAssets() internal {
        DealingAsset._clean();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev Can only be delegate call.
 */
abstract contract DelegateCallAction {
    address private immutable _self;

    modifier delegateCallOnly() {
        require(_self != address(this), "Delegate call only");
        _;
    }

    constructor() {
        _self = address(this);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {OwnableAction} from "./OwnableAction.sol";

/**
 * @dev Can only be destroyed by owner. All funds are sent to the owner.
 */
abstract contract DestructibleAction is OwnableAction {
    constructor(address payable owner_) OwnableAction(owner_) {}

    function destroy() external {
        require(msg.sender == actionOwner, "DestructibleAction: caller is not the owner");
        selfdestruct(actionOwner);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Errors {
    error RevertCode(Code errorCode);

    enum Code {
        COMPTROLLER_HALTED, // 0: "Halted"
        COMPTROLLER_BANNED, // 1: "Banned"
        COMPTROLLER_ZERO_ADDRESS, // 2: "Zero address"
        COMPTROLLER_TOS_AND_SIGS_LENGTH_INCONSISTENT, // 3: "tos and sigs length are inconsistent"
        COMPTROLLER_BEACON_IS_INITIALIZED, // 4: "Beacon is initialized"
        COMPTROLLER_DENOMINATIONS_AND_DUSTS_LENGTH_INCONSISTENT, // 5: "denominations and dusts length are inconsistent"
        IMPLEMENTATION_ASSET_LIST_NOT_EMPTY, // 6: "assetList is not empty"
        IMPLEMENTATION_INVALID_DENOMINATION, // 7: "Invalid denomination"
        IMPLEMENTATION_INVALID_MORTGAGE_TIER, // 8: "Mortgage tier not set in comptroller"
        IMPLEMENTATION_PENDING_SHARE_NOT_RESOLVABLE, // 9: "pending share is not resolvable"
        IMPLEMENTATION_PENDING_NOT_START, // 10: "Pending does not start"
        IMPLEMENTATION_PENDING_NOT_EXPIRE, // 11: "Pending does not expire"
        IMPLEMENTATION_INVALID_ASSET, // 12: "Invalid asset"
        IMPLEMENTATION_INSUFFICIENT_TOTAL_VALUE_FOR_EXECUTION, // 13: "Insufficient total value for execution"
        FUND_PROXY_FACTORY_INVALID_CREATOR, // 14: "Invalid creator"
        FUND_PROXY_FACTORY_INVALID_DENOMINATION, // 15: "Invalid denomination"
        FUND_PROXY_FACTORY_INVALID_MORTGAGE_TIER, // 16: "Mortgage tier not set in comptroller"
        FUND_PROXY_STORAGE_UTILS_INVALID_DENOMINATION, // 17: "Invalid denomination"
        FUND_PROXY_STORAGE_UTILS_UNKNOWN_OWNER, // 18: "Unknown owner"
        FUND_PROXY_STORAGE_UTILS_WRONG_ALLOWANCE, // 19: "Wrong allowance"
        FUND_PROXY_STORAGE_UTILS_IS_NOT_ZERO, // 20: "Is not zero value or address "
        FUND_PROXY_STORAGE_UTILS_IS_ZERO, // 21: "Is zero value or address"
        MORTGAGE_VAULT_FUND_MORTGAGED, // 22: "Fund mortgaged"
        SHARE_TOKEN_INVALID_FROM, // 23: "Invalid from"
        SHARE_TOKEN_INVALID_TO, // 24: "Invalid to"
        TASK_EXECUTOR_TOS_AND_DATAS_LENGTH_INCONSISTENT, // 25: "tos and datas length inconsistent"
        TASK_EXECUTOR_TOS_AND_CONFIGS_LENGTH_INCONSISTENT, // 26: "tos and configs length inconsistent"
        TASK_EXECUTOR_INVALID_COMPTROLLER_DELEGATE_CALL, // 27: "Invalid comptroller delegate call"
        TASK_EXECUTOR_INVALID_COMPTROLLER_CONTRACT_CALL, // 28: "Invalid comptroller contract call"
        TASK_EXECUTOR_INVALID_DEALING_ASSET, // 29: "Invalid dealing asset"
        TASK_EXECUTOR_REFERENCE_TO_OUT_OF_LOCALSTACK, // 30: "Reference to out of localStack"
        TASK_EXECUTOR_RETURN_NUM_AND_PARSED_RETURN_NUM_NOT_MATCHED, // 31: "Return num and parsed return num not matched"
        TASK_EXECUTOR_ILLEGAL_LENGTH_FOR_PARSE, // 32: "Illegal length for _parse"
        TASK_EXECUTOR_STACK_OVERFLOW, // 33: "Stack overflow"
        TASK_EXECUTOR_INVALID_INITIAL_ASSET, // 34: "Invalid initial asset"
        TASK_EXECUTOR_NON_ZERO_QUOTA, // 35: "Quota is not zero"
        AFURUCOMBO_DUPLICATED_TOKENSOUT, // 36: "Duplicated tokensOut"
        AFURUCOMBO_REMAINING_TOKENS, // 37: "Furucombo has remaining tokens"
        AFURUCOMBO_TOKENS_AND_AMOUNTS_LENGTH_INCONSISTENT, // 38: "Token length != amounts length"
        AFURUCOMBO_INVALID_COMPTROLLER_HANDLER_CALL, // 39: "Invalid comptroller handler call"
        CHAINLINK_ASSETS_AND_AGGREGATORS_INCONSISTENT, // 40: "assets.length == aggregators.length"
        CHAINLINK_ZERO_ADDRESS, // 41: "Zero address"
        CHAINLINK_EXISTING_ASSET, // 42: "Existing asset"
        CHAINLINK_NON_EXISTENT_ASSET, // 43: "Non-existent asset"
        CHAINLINK_INVALID_PRICE, // 44: "Invalid price"
        CHAINLINK_STALE_PRICE, // 45: "Stale price"
        ASSET_REGISTRY_UNREGISTERED, // 46: "Unregistered"
        ASSET_REGISTRY_BANNED_RESOLVER, // 47: "Resolver has been banned"
        ASSET_REGISTRY_ZERO_RESOLVER_ADDRESS, // 48: "Resolver zero address"
        ASSET_REGISTRY_ZERO_ASSET_ADDRESS, // 49: "Asset zero address"
        ASSET_REGISTRY_REGISTERED_RESOLVER, // 50: "Resolver is registered"
        ASSET_REGISTRY_NON_REGISTERED_RESOLVER, // 51: "Asset not registered"
        ASSET_REGISTRY_NON_BANNED_RESOLVER, // 52: "Resolver is not banned"
        ASSET_ROUTER_ASSETS_AND_AMOUNTS_LENGTH_INCONSISTENT, // 53: "assets length != amounts length"
        ASSET_ROUTER_NEGATIVE_VALUE, // 54: "Negative value"
        RESOLVER_ASSET_VALUE_NEGATIVE, // 55: "Resolver's asset value < 0"
        RESOLVER_ASSET_VALUE_POSITIVE, // 56: "Resolver's asset value > 0"
        RCURVE_STABLE_ZERO_ASSET_ADDRESS, // 57: "Zero asset address"
        RCURVE_STABLE_ZERO_POOL_ADDRESS, // 58: "Zero pool address"
        RCURVE_STABLE_ZERO_VALUED_ASSET_ADDRESS, // 59: "Zero valued asset address"
        RCURVE_STABLE_VALUED_ASSET_DECIMAL_NOT_MATCH_VALUED_ASSET, // 60: "Valued asset decimal not match valued asset"
        RCURVE_STABLE_POOL_INFO_IS_NOT_SET, // 61: "Pool info is not set"
        ASSET_MODULE_DIFFERENT_ASSET_REMAINING, // 62: "Different asset remaining"
        ASSET_MODULE_FULL_ASSET_CAPACITY, // 63: "Full Asset Capacity"
        MANAGEMENT_FEE_MODULE_FEE_RATE_SHOULD_BE_LESS_THAN_FUND_BASE, // 64: "Fee rate should be less than 100%"
        PERFORMANCE_FEE_MODULE_CAN_NOT_CRYSTALLIZED_YET, // 65: "Can not crystallized yet"
        PERFORMANCE_FEE_MODULE_TIME_BEFORE_START, // 66: "Time before start"
        PERFORMANCE_FEE_MODULE_FEE_RATE_SHOULD_BE_LESS_THAN_BASE, // 67: "Fee rate should be less than 100%"
        PERFORMANCE_FEE_MODULE_CRYSTALLIZATION_PERIOD_TOO_SHORT, // 68: "Crystallization period too short"
        SHARE_MODULE_SHARE_AMOUNT_TOO_LARGE, // 69: "The requesting share amount is greater than total share amount"
        SHARE_MODULE_PURCHASE_ZERO_BALANCE, // 70: "The purchased balance is zero"
        SHARE_MODULE_PURCHASE_ZERO_SHARE, // 71: "The share purchased need to greater than zero"
        SHARE_MODULE_REDEEM_ZERO_SHARE, // 72: "The redeem share is zero"
        SHARE_MODULE_INSUFFICIENT_SHARE, // 73: "Insufficient share amount"
        SHARE_MODULE_REDEEM_IN_PENDING_WITHOUT_PERMISSION, // 74: "Redeem in pending without permission"
        SHARE_MODULE_PENDING_ROUND_INCONSISTENT, // 75: "user pending round and current pending round are inconsistent"
        SHARE_MODULE_PENDING_REDEMPTION_NOT_CLAIMABLE // 76: "Pending redemption is not claimable"
    }

    function _require(bool condition_, Code errorCode_) internal pure {
        if (!condition_) revert RevertCode(errorCode_);
    }

    function _revertMsg(string memory functionName_, string memory reason_) internal pure {
        revert(string(abi.encodePacked(functionName_, ": ", reason_)));
    }

    function _revertMsg(string memory functionName_) internal pure {
        _revertMsg(functionName_, "Unspecified");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev Create immutable owner for action contract
 */
abstract contract OwnableAction {
    address payable public immutable actionOwner;

    constructor(address payable owner_) {
        actionOwner = owner_;
    }
}