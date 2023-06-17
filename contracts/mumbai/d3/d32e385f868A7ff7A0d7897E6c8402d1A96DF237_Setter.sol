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

/// @title Interface for handler contracts that support deposits and deposit executions.
/// @author Router Protocol.
interface IDepositExecute {
    struct NonReserveSwapInfo {
        uint256 srcTokenAmount;
        uint256 srcStableTokenAmount;
        bytes32 destChainIdBytes;
        address depositor;
        address srcTokenAddress;
        address srcStableTokenAddress;
        bytes[] dataTx;
        address[] path;
        uint256[] flags;
    }

    struct ReserveOrLPSwapInfo {
        uint256 srcStableTokenAmount;
        address srcStableTokenAddress;
        address depositor;
        address srcTokenAddress;
        bytes32 destChainIdBytes;
    }

    struct ExecuteSwapInfo {
        uint256 destStableTokenAmount;
        bytes destStableTokenAddress;
        uint64 depositNonce;
        bool isDestNative;
        bytes destTokenAddress;
        bytes recipient;
        bytes[] dataTx;
        bytes[] path;
        uint256[] flags;
        uint256 destTokenAmount;
        uint256 widgetID;
    }

    struct DepositData {
        address sender;
        address srcStableTokenAddress;
        uint256 srcStableTokenAmount;
    }

    struct ArbitraryInstruction {
        bytes destContractAddress;
        bytes data;
        uint256 gasLimit;
        uint256 gasPrice;
    }

    // dest details for usdc deposits
    struct DestDetails {
        string chainId;
        uint32 usdcDomainId;
        address reserveHandlerAddress;
        address destCallerAddress;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IHandlerReserve {
    function fundERC20(
        address tokenAddress,
        address owner,
        uint256 amount
    ) external;

    function lockERC20(
        address tokenAddress,
        address owner,
        address recipient,
        uint256 amount
    ) external;

    function releaseERC20(
        address tokenAddress,
        address recipient,
        uint256 amount
    ) external;

    function mintERC20(
        address tokenAddress,
        address recipient,
        uint256 amount
    ) external;

    function burnERC20(
        address tokenAddress,
        address owner,
        uint256 amount
    ) external;

    function safeTransferETH(address to, uint256 value) external;

    // function deductFee(
    //     address feeTokenAddress,
    //     address depositor,
    //     uint256 providedFee,
    //     // uint256 requiredFee,
    //     // address _ETH,
    //     // bool _isFeeEnabled,
    //     address _feeManager
    // ) external;

    function mintWrappedERC20(
        address tokenAddress,
        address recipient,
        uint256 amount
    ) external;

    function stake(
        address depositor,
        address tokenAddress,
        uint256 amount
    ) external;

    function stakeETH(
        address depositor,
        address tokenAddress,
        uint256 amount
    ) external;

    function unstake(
        address unstaker,
        address tokenAddress,
        uint256 amount
    ) external;

    function unstakeETH(
        address unstaker,
        address tokenAddress,
        uint256 amount,
        address WETH
    ) external;

    function giveAllowance(
        address token,
        address spender,
        uint256 amount
    ) external;

    function getStakedRecord(address account, address tokenAddress) external view returns (uint256);

    function withdrawWETH(address WETH, uint256 amount) external;

    function _setLiquidityPoolOwner(
        address oldOwner,
        address newOwner,
        address tokenAddress,
        address lpAddress
    ) external;

    function _setLiquidityPool(address contractAddress, address lpAddress) external;

    // function _setLiquidityPool(
    //     string memory name,
    //     string memory symbol,
    //     uint8 decimals,
    //     address contractAddress,
    //     address lpAddress
    // ) external returns (address);

    function swapMulti(
        address oneSplitAddress,
        address[] memory tokens,
        uint256 amount,
        uint256 minReturn,
        uint256[] memory flags,
        bytes[] memory dataTx
    ) external returns (uint256 returnAmount);

    function swap(
        address oneSplitAddress,
        address fromToken,
        address destToken,
        uint256 amount,
        uint256 minReturn,
        uint256 flags,
        bytes memory dataTx
    ) external returns (uint256 returnAmount);

    // function feeManager() external returns (address);

    function _lpToContract(address token) external returns (address);

    function _contractToLP(address token) external returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ITokenMessenger {
    function depositForBurnWithCaller(
        uint256 _amount,
        uint32 _destinationDomain,
        bytes32 _mintRecipient,
        address _burnToken,
        bytes32 _destinationCaller
    ) external returns (uint64);

    function replaceDepositForBurn(
        bytes memory originalMessage,
        bytes calldata originalAttestation,
        bytes32 _destCaller,
        bytes32 _mintRecipient
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "../interfaces/IDepositExecute.sol";
import "../interfaces/IHandlerReserve.sol";
import "../interfaces/ITokenMessenger.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

library Setter {
    using SafeERC20 for IERC20;

    // codeId:
    // 1 -> Only Gateway contract
    // 2 -> array length mismatch
    // 3 -> contract address cannot be zero address
    // 4 -> provided contract is not whitelisted
    // 5 -> Either reserve handler or dest caller address is zero address
    // 6 -> Insufficient native assets sent
    // 7 -> token not whitelisted
    // 8 -> min amount lower than required
    // 9 -> invalid data
    // 10 -> invalid token addresses
    // 11 -> data for reserve transfer
    // 12 -> data for LP transfer
    // 13 -> only Voyager middleware
    // 14 -> already reverted
    // 15 -> no deposit found
    // 16 -> dest chain not configured
    error VoyagerError(uint8 codeId);

    event DepositReverted(
        bytes32 indexed destChainIdBytes,
        uint64 indexed depositNonce,
        address indexed sender,
        address srcStableTokenAddress,
        uint256 srcStableTokenAmount
    );

    /// @notice Function to get chain ID bytes
    /// @param  chainId chain Id of the chain
    function getChainIdBytes(string memory chainId) public pure returns (bytes32) {
        return keccak256(abi.encode(chainId));
    }

    function setChainIdToDestDetails(
        mapping(bytes32 => IDepositExecute.DestDetails) storage chainIdToDestDetails,
        IDepositExecute.DestDetails[] memory destDetails
    ) public {
        for (uint256 i = 0; i < destDetails.length; i++) {
            bytes32 chainIdBytes = getChainIdBytes(destDetails[i].chainId);

            // require(destDetails[i].reserveHandlerAddress != address(0), "Reserve handler != address(0)");
            // require(destDetails[i].destCallerAddress != address(0), "Dest caller != address(0)");
            if (destDetails[i].reserveHandlerAddress == address(0) || destDetails[i].destCallerAddress == address(0)) {
                // Either reserve handler or dest caller address is zero address
                revert VoyagerError(5);
            }

            chainIdToDestDetails[chainIdBytes] = IDepositExecute.DestDetails(
                destDetails[i].chainId,
                destDetails[i].usdcDomainId,
                destDetails[i].reserveHandlerAddress,
                destDetails[i].destCallerAddress
            );
        }
    }

    function setResource(
        mapping(address => bool) storage _contractWhitelist,
        address contractAddress,
        bool isResource
    ) public {
        // require(contractAddress != address(0), "contract address can't be zero");
        if (contractAddress == address(0)) {
            // contract address can't be zero
            revert VoyagerError(3);
        }
        _contractWhitelist[contractAddress] = isResource;
    }

    /// @notice First verifies {contractAddress} is whitelisted, then sets {_burnList}[{contractAddress}]
    /// to true.
    /// @dev Can only be called by the bridge
    /// @param contractAddress Address of contract to be used when making or executing deposits.
    /// @param status Boolean flag to change burnable status.
    function setBurnable(
        mapping(address => bool) storage _burnList,
        bool isWhitelisted,
        address contractAddress,
        bool status
    ) public {
        // require(isWhitelisted, "provided contract is not whitelisted");
        if (!isWhitelisted) {
            // provided contract is not whitelisted
            revert VoyagerError(4);
        }
        _burnList[contractAddress] = status;
    }

    /// @notice Function to set min amount to transfer to another chain.
    /// @param  _tokens addresses of src stable token
    /// @param  _amounts min amounts to be transferred
    function setMinAmountToSwap(
        mapping(address => uint256) storage _minAmountToSwap,
        address[] memory _tokens,
        uint256[] memory _amounts
    ) public {
        // require(_tokens.length == _amounts.length, "array length mismatch");
        if (_tokens.length != _amounts.length) {
            // array length mismatch
            revert VoyagerError(2);
        }
        uint8 length = uint8(_tokens.length);
        for (uint8 i = 0; i < length; i++) {
            _minAmountToSwap[_tokens[i]] = _amounts[i];
        }
    }

    function setLiquidityPool(
        IHandlerReserve _reserve,
        mapping(address => bool) storage _contractWhitelist,
        mapping(address => bool) storage _burnList,
        address contractAddress,
        address lpAddress
    ) public {
        _reserve._setLiquidityPool(contractAddress, lpAddress);
        _contractWhitelist[lpAddress] = true;
        _burnList[lpAddress] = true;
    }

    /// @notice Set if USDC is burnable and mintable for a chain pair
    /// @notice Only RESOURCE_SETTER can call this function
    /// @param _destChainID array of dest chain ids
    /// @param _setTrue array of boolean suggesting whether it is burnable and mintable
    function setUsdcBurnableAndMintable(
        mapping(bytes32 => bool) storage _isUsdcBurnableMintable,
        string[] memory _destChainID,
        bool[] memory _setTrue
    ) public {
        // Array length mismatch
        if (_destChainID.length != _setTrue.length) {
            revert VoyagerError(2);
        }

        for (uint8 i = 0; i < _destChainID.length; i++) {
            bytes32 destChainIdBytes = getChainIdBytes(_destChainID[i]);
            // require(isChainWhitelisted[destChainIdBytes], "Chain Id != 0");
            _isUsdcBurnableMintable[destChainIdBytes] = _setTrue[i];
        }
    }

    /// @notice Function to handle the request for execution received from Router Chain
    /// @param requestSender Address of the sender of the transaction on the source chain.
    /// @param packet Payload coming from the router chain.
    function iReceive(
        mapping(bytes32 => mapping(uint64 => bool)) storage _executionRevertCompleted,
        mapping(address => bool) storage _burnList,
        IHandlerReserve _reserve,
        string memory routerBridge,
        string memory requestSender,
        bytes memory packet
    ) public {
        // require(
        //     keccak256(abi.encodePacked(sender)) == keccak256(abi.encodePacked(routerBridge)),
        //     "only Voyager middleware"
        // );

        if (keccak256(bytes(requestSender)) != keccak256(bytes(routerBridge))) {
            // only Voyager middleware
            revert VoyagerError(13);
        }

        uint8 txType = abi.decode(packet, (uint8));

        /// Refunding user money in case of some issues on dest chain
        if (txType == 2) {
            (, bytes32 destChainIdBytes, uint64 _depositNonce, IDepositExecute.DepositData memory depositData) = abi
                .decode(packet, (uint8, bytes32, uint64, IDepositExecute.DepositData));

            // require(!_executionRevertCompleted[destChainIdBytes][_depositNonce], "already reverted");

            if (_executionRevertCompleted[destChainIdBytes][_depositNonce]) {
                // already reverted
                revert VoyagerError(14);
            }

            // IDepositExecute.DepositData memory depositData = _depositData[destChainIdBytes][_depositNonce];
            // require(depositData.srcStableTokenAddress != address(0), "no deposit found");

            if (depositData.srcStableTokenAddress == address(0)) {
                // no deposit found
                revert VoyagerError(15);
            }

            _executionRevertCompleted[destChainIdBytes][_depositNonce] = true;

            if (_burnList[depositData.srcStableTokenAddress]) {
                _reserve.mintERC20(
                    depositData.srcStableTokenAddress,
                    depositData.sender,
                    depositData.srcStableTokenAmount
                );
            } else {
                IERC20(depositData.srcStableTokenAddress).safeTransfer(
                    depositData.sender,
                    depositData.srcStableTokenAmount
                );
            }

            emit DepositReverted(
                destChainIdBytes,
                _depositNonce,
                depositData.sender,
                depositData.srcStableTokenAddress,
                depositData.srcStableTokenAmount
            );
        }
    }

    /// @notice Function to change the destCaller and mintRecipient for a USDC burn tx.
    /// @notice Only DEFAULT_ADMIN can call this function.
    /// @param  originalMessage Original message received when the USDC was burnt.
    /// @param  originalAttestation Original attestation received from the API.
    /// @param  newDestCaller Address of the new destination caller.
    /// @param  newMintRecipient Address of the new mint recipient.
    function changeDestCallerOrMintRecipient(
        ITokenMessenger tokenMessenger,
        bytes memory originalMessage,
        bytes calldata originalAttestation,
        address newDestCaller,
        address newMintRecipient
    ) public {
        bytes32 _destCaller = bytes32(uint256(uint160(newDestCaller)));
        bytes32 _mintRecipient = bytes32(uint256(uint160(newMintRecipient)));

        tokenMessenger.replaceDepositForBurn(originalMessage, originalAttestation, _destCaller, _mintRecipient);
    }

    // function decodeArbitraryData(
    //     bytes calldata arbitraryData
    // ) internal pure returns (IDepositExecute.ArbitraryInstruction memory arbitraryInstruction) {
    //     (
    //         arbitraryInstruction.destContractAddress,
    //         arbitraryInstruction.data,
    //         arbitraryInstruction.gasLimit,
    //         arbitraryInstruction.gasPrice
    //     ) = abi.decode(arbitraryData, (bytes, bytes, uint256, uint256));
    // }

    // function decodeReserveOrLpSwapData(
    //     bytes calldata swapData
    // ) internal pure returns (IDepositExecute.ReserveOrLPSwapInfo memory swapDetails) {
    //     (
    //         swapDetails.destChainIdBytes,
    //         swapDetails.srcStableTokenAmount,
    //         swapDetails.srcStableTokenAddress,
    //         swapDetails.srcTokenAddress
    //     ) = abi.decode(swapData, (bytes32, uint256, address, address));
    // }

    // function decodeExecuteData(
    //     bytes calldata executeData
    // ) internal pure returns (IDepositExecute.ExecuteSwapInfo memory executeDetails) {
    //     (executeDetails.destTokenAmount) = abi.decode(executeData, (uint256));

    //     (
    //         ,
    //         executeDetails.destTokenAddress,
    //         executeDetails.isDestNative,
    //         executeDetails.destStableTokenAddress,
    //         executeDetails.recipient,
    //         executeDetails.dataTx,
    //         executeDetails.path,
    //         executeDetails.flags,
    //         executeDetails.widgetID
    //     ) = abi.decode(executeData, (uint256, bytes, bool, bytes, bytes, bytes[], bytes[], uint256[], uint256));
    // }

    // function checks(
    //     address token,
    //     uint256 amount,
    //     mapping(address => uint256) storage _minAmountToSwap,
    //     mapping(address => bool) storage _contractWhitelist
    // ) internal view {
    //     if (amount < _minAmountToSwap[token]) {
    //         // min amount lower than required
    //         revert VoyagerError(8);
    //     }

    //     if (!_contractWhitelist[token]) {
    //         // token not whitelisted
    //         revert VoyagerError(7);
    //     }
    // }

    // /// @notice Function to transfer LP tokens from source chain to get any other token on dest chain.
    // /// @param swapData Swap data for LP token deposit
    // /// @param executeData Execute data for the execution of transaction on the destination chain.
    // function depositLPToken(
    //     bytes calldata swapData,
    //     bytes calldata executeData,
    //     mapping(address => uint256) storage _minAmountToSwap,
    //     mapping(address => bool) storage _contractWhitelist,
    //     mapping(bytes32 => uint64) storage depositNonce,
    //     IHandlerReserve reserve,
    //     address msgSender
    // ) external returns (bytes memory, address srcToken, uint256 amount) {
    //     IDepositExecute.ReserveOrLPSwapInfo memory swapDetails = decodeReserveOrLpSwapData(swapData);
    //     IDepositExecute.ExecuteSwapInfo memory executeDetails = decodeExecuteData(executeData);
    //     swapDetails.depositor = msgSender;

    //     executeDetails.depositNonce = _depositLPToken(
    //         swapDetails,
    //         _minAmountToSwap,
    //         _contractWhitelist,
    //         depositNonce,
    //         reserve
    //     );

    //     bytes memory packet = abi.encode(0, swapDetails, executeDetails);
    //     return (packet, swapDetails.srcTokenAddress, swapDetails.srcStableTokenAmount);
    // }

    // /// @notice Function to transfer LP tokens from source chain to get any other token on dest chain
    // /// and execute an arbitrary instruction on the destination chain after the fund transfer is completed.
    // /// @param swapData Swap data for LP token deposit
    // /// @param executeData Execute data for the execution of token transfer on the destination chain.
    // /// @param arbitraryData Arbitrary data for the execution of arbitrary instruction execution on the
    // /// destination chain.
    // function depositLPTokenAndExecute(
    //     bytes calldata swapData,
    //     bytes calldata executeData,
    //     bytes calldata arbitraryData,
    //     mapping(address => uint256) storage _minAmountToSwap,
    //     mapping(address => bool) storage _contractWhitelist,
    //     mapping(bytes32 => uint64) storage depositNonce,
    //     IHandlerReserve reserve,
    //     address depositor
    // ) external returns (bytes memory, address, uint256) {
    //     IDepositExecute.ReserveOrLPSwapInfo memory swapDetails = decodeReserveOrLpSwapData(swapData);
    //     IDepositExecute.ExecuteSwapInfo memory executeDetails = decodeExecuteData(executeData);
    //     swapDetails.depositor = depositor;

    //     IDepositExecute.ArbitraryInstruction memory arbitraryInstruction = decodeArbitraryData(arbitraryData);
    //     executeDetails.depositNonce = _depositLPToken(
    //         swapDetails,
    //         _minAmountToSwap,
    //         _contractWhitelist,
    //         depositNonce,
    //         reserve
    //     );

    //     bytes memory packet = abi.encode(2, msg.sender, swapDetails, executeDetails, arbitraryInstruction);
    //     return (packet, swapDetails.srcTokenAddress, swapDetails.srcStableTokenAmount);
    // }

    // function _depositLPToken(
    //     IDepositExecute.ReserveOrLPSwapInfo memory swapDetails,
    //     mapping(address => uint256) storage _minAmountToSwap,
    //     mapping(address => bool) storage _contractWhitelist,
    //     mapping(bytes32 => uint64) storage depositNonce,
    //     IHandlerReserve reserve
    // ) internal returns (uint64 nonce) {
    //     // require(_contractWhitelist[swapDetails.srcStableTokenAddress], "token not whitelisted");
    //     // if(!_contractWhitelist[swapDetails.srcStableTokenAddress]) {
    //     //     // token not whitelisted
    //     //     revert VoyagerError(7);
    //     // }

    //     // require(
    //     //     swapDetails.srcStableTokenAmount >= _minAmountToSwap[swapDetails.srcStableTokenAddress],
    //     //     "min amount lower than required"
    //     // );
    //     // if (swapDetails.srcStableTokenAmount < _minAmountToSwap[swapDetails.srcStableTokenAddress]) {
    //     //     // min amount lower than required
    //     //     revert VoyagerError(8);
    //     // }

    //     checks(
    //         swapDetails.srcStableTokenAddress,
    //         swapDetails.srcStableTokenAmount,
    //         _minAmountToSwap,
    //         _contractWhitelist
    //     );

    //     // require(
    //     //     _reserve._contractToLP(swapDetails.srcStableTokenAddress) == swapDetails.srcTokenAddress,
    //     //     "invalid token addresses"
    //     // );
    //     if (reserve._contractToLP(swapDetails.srcStableTokenAddress) != swapDetails.srcTokenAddress) {
    //         // invalid token addresses
    //         revert VoyagerError(10);
    //     }

    //     // require(isChainWhitelisted[swapDetails.destChainIdBytes], "dest chain not whitelisted");

    //     // depositNonce[swapDetails.destChainIdBytes] += 1;
    //     // _reserve.burnERC20(swapDetails.srcTokenAddress, swapDetails.depositor, swapDetails.srcStableTokenAmount);

    //     unchecked {
    //         nonce = ++depositNonce[swapDetails.destChainIdBytes];
    //     }
    // }
}