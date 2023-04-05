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
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Callback for IUniswapV3PoolActions#swap
/// @notice Any contract that calls IUniswapV3PoolActions#swap must implement this interface
interface IUniswapV3SwapCallback {
    /// @notice Called to `msg.sender` after executing a swap via IUniswapV3Pool#swap.
    /// @dev In the implementation you must pay the pool tokens owed for the swap.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
    /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
    /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#swap call
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

import '@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3SwapCallback.sol';

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface ISwapRouter is IUniswapV3SwapCallback {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);
}

// SPDX-License-Identifier: MIT
// pragma solidity ^0.8.16;
// import {RegistrarStorage} from "../storage.sol";
// import {RegistrarMessages} from "../message.sol";
// import {AngelCoreStruct} from "../../struct.sol";

// interface IRegistrar {
//     function queryConfig()
//         external
//         view
//         returns (RegistrarStorage.Config memory);

//     function queryNetworkConnection(
//         uint256 chainId
//     ) external view returns (AngelCoreStruct.NetworkInfo memory);

//     function queryVaultDetails(
//         address vaultAddr
//     ) external view returns (AngelCoreStruct.YieldVault memory);

//     function queryVaultList(
//         uint256 network,
//         AngelCoreStruct.EndowmentType endowmentType,
//         AngelCoreStruct.AccountType accountType,
//         AngelCoreStruct.VaultType vaultType,
//         AngelCoreStruct.BoolOptional approved,
//         uint256 startAfter,
//         uint256 limit
//     ) external view returns (AngelCoreStruct.YieldVault[] memory);

//     function updateConfig(
//         RegistrarMessages.UpdateConfigRequest memory curDetails
//     ) external returns (bool);

//     function updateNetworkConnections(
//         AngelCoreStruct.NetworkInfo memory networkInfo,
//         string memory action
//     ) external returns (bool);

//     function updateOwner(address newOwner) external returns (bool);

//     function vaultAdd(
//         RegistrarMessages.VaultAddRequest memory curDetails
//     ) external returns (bool);

//     function vaultRemove(address vaultAddr) external returns (bool);

//     function vaultUpdate(
//         address vaultAddr,
//         bool approved,
//         AngelCoreStruct.EndowmentType[] memory restrictedFrom
//     ) external returns (bool);

//     function queryFee(string memory name) external returns (uint256);

//     function testQuery() external view returns (address[] memory);

//     function testQueryStruct()
//         external
//         view
//         returns (AngelCoreStruct.YieldVault[] memory);

//     function queryVaultListBg(
//         uint256 network,
//         AngelCoreStruct.EndowmentType endowmentType,
//         AngelCoreStruct.AccountType accountType,
//         AngelCoreStruct.VaultType vaultType,
//         AngelCoreStruct.BoolOptional approved,
//         uint256 startAfter,
//         uint256 limit
//     ) external view returns (AngelCoreStruct.YieldVault[] memory);
// }

pragma solidity ^0.8.16;
import {RegistrarStorage} from "../storage.sol";
import {RegistrarMessages} from "../message.sol";
import {AngelCoreStruct} from "../../struct.sol";

interface IRegistrar {
    function updateConfig(
        RegistrarMessages.UpdateConfigRequest memory curDetails
    ) external;

    function updateOwner(address newOwner) external;

    function updateFees(
        RegistrarMessages.UpdateFeeRequest memory curDetails
    ) external;

    function vaultAdd(
        RegistrarMessages.VaultAddRequest memory curDetails
    ) external;

    function vaultRemove(string memory _stratagyName) external;

    function vaultUpdate(
        string memory _stratagyName,
        bool curApproved,
        AngelCoreStruct.EndowmentType[] memory curRestrictedfrom
    ) external;

    function updateNetworkConnections(
        AngelCoreStruct.NetworkInfo memory networkInfo,
        string memory action
    ) external;

    // Query functions for contract

    function queryConfig()
        external
        view
        returns (RegistrarStorage.Config memory);

    function testQuery() external view returns (string[] memory);

    function testQueryStruct()
        external
        view
        returns (AngelCoreStruct.YieldVault[] memory);

    function queryVaultListDep(
        uint256 network,
        AngelCoreStruct.EndowmentType endowmentType,
        AngelCoreStruct.AccountType accountType,
        AngelCoreStruct.VaultType vaultType,
        AngelCoreStruct.BoolOptional approved,
        uint256 startAfter,
        uint256 limit
    ) external view returns (AngelCoreStruct.YieldVault[] memory);

    function queryVaultList(
        uint256 network,
        AngelCoreStruct.EndowmentType endowmentType,
        AngelCoreStruct.AccountType accountType,
        AngelCoreStruct.VaultType vaultType,
        AngelCoreStruct.BoolOptional approved,
        uint256 startAfter,
        uint256 limit
    ) external view returns (AngelCoreStruct.YieldVault[] memory);

    function queryVaultDetails(
        string memory _stratagyName
    ) external view returns (AngelCoreStruct.YieldVault memory response);

    function queryNetworkConnection(
        uint256 chainId
    ) external view returns (AngelCoreStruct.NetworkInfo memory response);

    function queryFee(
        string memory name
    ) external view returns (uint256 response);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {AngelCoreStruct} from "../struct.sol";

library RegistrarMessages {
    struct InstantiateRequest {
        address treasury;
        uint256 taxRate;
        AngelCoreStruct.RebalanceDetails rebalance;
        AngelCoreStruct.SplitDetails splitToLiquid;
        AngelCoreStruct.AcceptedTokens acceptedTokens;
        address router;
        address axelerGateway;
    }

    struct UpdateConfigRequest {
        address accountsContract;
        uint256 taxRate;
        AngelCoreStruct.RebalanceDetails rebalance;
        string[] approved_charities;
        uint256 splitMax;
        uint256 splitMin;
        uint256 splitDefault;
        uint256 collectorShare;
        AngelCoreStruct.AcceptedTokens acceptedTokens;
        // WASM CODES -> EVM -> Solidity Implementation contract addresses
        address subdaoGovCode; // subdao gov wasm code
        address subdaoCw20TokenCode; // subdao gov token (basic CW20) wasm code
        address subdaoBondingTokenCode; // subdao gov token (w/ bonding-curve) wasm code
        address subdaoCw900Code; // subdao gov ve-CURVE contract for locked token voting
        address subdaoDistributorCode; // subdao gov fee distributor wasm code
        address subdaoEmitter;
        address donationMatchCode; // donation matching contract wasm code
        // CONTRACT ADSRESSES
        address indexFundContract;
        address govContract;
        address treasury;
        address donationMatchCharitesContract;
        address donationMatchEmitter;
        address haloToken;
        address haloTokenLpContract;
        address charitySharesContract;
        address fundraisingContract;
        address applicationsReview;
        address swapsRouter;
        address multisigFactory;
        address multisigEmitter;
        address charityProposal;
        address lockedWithdrawal;
        address proxyAdmin;
        address usdcAddress;
        address wethAddress;
        address cw900lvAddress;
    }

    struct VaultAddRequest {
        // chainid of network
        uint256 network;
        string stratagyName;
        address inputDenom;
        address yieldToken;
        AngelCoreStruct.EndowmentType[] restrictedFrom;
        AngelCoreStruct.AccountType acctType;
        AngelCoreStruct.VaultType vaultType;
    }

    struct UpdateFeeRequest {
        string[] keys;
        // TODO Change to decimal
        uint256[] values;
    }

    struct ConfigResponse {
        address owner;
        uint256 version;
        address accountsContract;
        address treasury;
        uint256 taxRate;
        AngelCoreStruct.RebalanceDetails rebalance;
        address indexFund;
        AngelCoreStruct.SplitDetails splitToLiquid;
        address haloToken;
        address govContract;
        address charitySharesContract;
        uint256 cw3Code;
        uint256 cw4Code;
        AngelCoreStruct.AcceptedTokens acceptedTokens;
        address applicationsReview;
        address swapsRouter;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {AngelCoreStruct} from "../struct.sol";

library RegistrarStorage {
    struct Config {
        address owner; // AP TEAM MULTISIG
        //Application review multisig
        address applicationsReview; // Endowment application review team's CW3 (set as owner to start). Owner can set and change/revoke.
        address indexFundContract;
        address accountsContract;
        address treasury;
        address subdaoGovCode; // subdao gov wasm code
        address subdaoCw20TokenCode; // subdao gov cw20 token wasm code
        address subdaoBondingTokenCode; // subdao gov bonding curve token wasm code
        address subdaoCw900Code; // subdao gov ve-CURVE contract for locked token voting
        address subdaoDistributorCode; // subdao gov fee distributor wasm code
        address subdaoEmitter;
        address donationMatchCode; // donation matching contract wasm code
        address donationMatchCharitesContract; // donation matching contract address for "Charities" endowments
        address donationMatchEmitter;
        AngelCoreStruct.SplitDetails splitToLiquid; // set of max, min, and default Split paramenters to check user defined split input against
        //TODO: pending check
        address haloToken; // TerraSwap HALO token addr
        address haloTokenLpContract;
        address govContract; // AP governance contract
        address collectorAddr; // Collector address for new fee
        uint256 collectorShare;
        address charitySharesContract;
        AngelCoreStruct.AcceptedTokens acceptedTokens; // list of approved native and CW20 coins can accept inward
        //PROTOCOL LEVEL
        address fundraisingContract;
        AngelCoreStruct.RebalanceDetails rebalance;
        address swapsRouter;
        address multisigFactory;
        address multisigEmitter;
        address charityProposal;
        address lockedWithdrawal;
        address proxyAdmin;
        address usdcAddress;
        address wethAddress;
        address cw900lvAddress;
    }

    struct State {
        Config config;
        mapping(string => AngelCoreStruct.YieldVault) VAULTS;
        string[] VAULT_POINTERS;
        mapping(uint256 => AngelCoreStruct.NetworkInfo) NETWORK_CONNECTIONS;
        mapping(string => uint256) FEES;
    }
}

contract Storage {
    RegistrarStorage.State state;
    bool initilized = false;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

library AngelCoreStruct {
    enum AccountType {
        Locked,
        Liquid,
        None
    }

    enum Tier {
        None,
        Level1,
        Level2,
        Level3
    }

    struct Pair {
        //This should be asset info
        string[] asset;
        address contractAddress;
    }

    struct Asset {
        address addr;
        string name;
    }

    enum AssetInfoBase {
        Cw20,
        Native,
        None
    }

    struct AssetBase {
        AssetInfoBase info;
        uint256 amount;
        address addr;
        string name;
    }

    //By default array are empty
    struct Categories {
        uint256[] sdgs;
        uint256[] general;
    }

    ///TODO: by default are not internal need to create a custom internal function for this refer :- https://ethereum.stackexchange.com/questions/21155/how-to-expose-enum-in-solidity-contract
    enum EndowmentType {
        Charity,
        Normal,
        None
    }

    enum EndowmentStatus {
        Inactive,
        Approved,
        Frozen,
        Closed
    }

    struct AccountStrategies {
        string[] locked_vault;
        uint256[] lockedPercentage;
        string[] liquid_vault;
        uint256[] liquidPercentage;
    }

    function accountStratagyLiquidCheck(
        AccountStrategies storage strategies,
        OneOffVaults storage oneoffVaults
    ) public {
        for (uint256 i = 0; i < strategies.liquid_vault.length; i++) {
            bool checkFlag = true;
            for (uint256 j = 0; j < oneoffVaults.liquid.length; j++) {
                if (
                    keccak256(abi.encodePacked(strategies.liquid_vault[i])) ==
                    keccak256(abi.encodePacked(oneoffVaults.liquid[j]))
                ) {
                    checkFlag = false;
                }
            }

            if (checkFlag) {
                oneoffVaults.liquid.push(strategies.liquid_vault[i]);
            }
        }
    }

    function accountStratagyLockedCheck(
        AccountStrategies storage strategies,
        OneOffVaults storage oneoffVaults
    ) public {
        for (uint256 i = 0; i < strategies.locked_vault.length; i++) {
            bool checkFlag = true;
            for (uint256 j = 0; j < oneoffVaults.locked.length; j++) {
                if (
                    keccak256(abi.encodePacked(strategies.locked_vault[i])) ==
                    keccak256(abi.encodePacked(oneoffVaults.locked[j]))
                ) {
                    checkFlag = false;
                }
            }

            if (checkFlag) {
                oneoffVaults.locked.push(strategies.locked_vault[i]);
            }
        }
    }

    function accountStrategiesDefaut()
        public
        pure
        returns (AccountStrategies memory)
    {
        AccountStrategies memory empty;
        return empty;
    }

    //TODO: handle the case when we invest into vault or redem from vault
    struct OneOffVaults {
        string[] locked;
        uint256[] lockedAmount;
        string[] liquid;
        uint256[] liquidAmount;
    }

    function removeLast(string[] storage vault, string memory remove) public {
        for (uint256 i = 0; i < vault.length - 1; i++) {
            if (
                keccak256(abi.encodePacked(vault[i])) ==
                keccak256(abi.encodePacked(remove))
            ) {
                vault[i] = vault[vault.length - 1];
                break;
            }
        }

        vault.pop();
    }

    function oneOffVaultsDefault() public pure returns (OneOffVaults memory) {
        OneOffVaults memory empty;
        return empty;
    }

    function checkTokenInOffVault(
        string[] storage curAvailible,
        uint256[] storage cerAvailibleAmount, 
        string memory curToken
    ) public {
        bool check = true;
        for (uint8 j = 0; j < curAvailible.length; j++) {
            if (
                keccak256(abi.encodePacked(curAvailible[j])) ==
                keccak256(abi.encodePacked(curToken))
            ) {
                check = false;
            }
        }
        if (check) {
            curAvailible.push(curToken);
            cerAvailibleAmount.push(0);
        }
    }

    struct RebalanceDetails {
        bool rebalanceLiquidInvestedProfits; // should invested portions of the liquid account be rebalanced?
        bool lockedInterestsToLiquid; // should Locked acct interest earned be distributed to the Liquid Acct?
        ///TODO: Should be decimal type insted of uint256
        uint256 interest_distribution; // % of Locked acct interest earned to be distributed to the Liquid Acct
        bool lockedPrincipleToLiquid; // should Locked acct principle be distributed to the Liquid Acct?
        ///TODO: Should be decimal type insted of uint256
        uint256 principle_distribution; // % of Locked acct principle to be distributed to the Liquid Acct
    }

    function rebalanceDetailsDefaut()
        public
        pure
        returns (RebalanceDetails memory)
    {
        RebalanceDetails memory _tempRebalanceDetails = RebalanceDetails({
            rebalanceLiquidInvestedProfits: false,
            lockedInterestsToLiquid: false,
            interest_distribution: 20,
            lockedPrincipleToLiquid: false,
            principle_distribution: 0
        });

        return _tempRebalanceDetails;
    }

    struct DonationsReceived {
        uint256 locked;
        uint256 liquid;
    }

    function donationsReceivedDefault()
        public
        pure
        returns (DonationsReceived memory)
    {
        DonationsReceived memory empty;
        return empty;
    }

    struct Coin {
        string denom;
        uint128 amount;
    }

    struct Cw20CoinVerified {
        uint128 amount;
        address addr;
    }

    struct GenericBalance {
        uint256 coinNativeAmount;
        // Coin[] native;
        uint256[] Cw20CoinVerified_amount;
        address[] Cw20CoinVerified_addr;
        // Cw20CoinVerified[] cw20;
    }

    function addToken(
        GenericBalance storage curTemp,
        address curTokenaddress,
        uint256 curAmount
    ) public {
        bool notFound = true;
        for (uint8 i = 0; i < curTemp.Cw20CoinVerified_addr.length; i++) {
            if (curTemp.Cw20CoinVerified_addr[i] == curTokenaddress) {
                notFound = false;
                curTemp.Cw20CoinVerified_amount[i] += curAmount;
            }
        }
        if (notFound) {
            curTemp.Cw20CoinVerified_addr.push(curTokenaddress);
            curTemp.Cw20CoinVerified_amount.push(curAmount);
        }
    }

    function addTokenMem(
        GenericBalance memory curTemp,
        address curTokenaddress,
        uint256 curAmount
    ) public pure returns (GenericBalance memory) {
        bool notFound = true;
        for (uint8 i = 0; i < curTemp.Cw20CoinVerified_addr.length; i++) {
            if (curTemp.Cw20CoinVerified_addr[i] == curTokenaddress) {
                notFound = false;
                curTemp.Cw20CoinVerified_amount[i] += curAmount;
            }
        }
        if (notFound) {
            GenericBalance memory new_temp = GenericBalance({
                coinNativeAmount: curTemp.coinNativeAmount,
                Cw20CoinVerified_amount: new uint256[](
                    curTemp.Cw20CoinVerified_amount.length + 1
                ),
                Cw20CoinVerified_addr: new address[](
                    curTemp.Cw20CoinVerified_addr.length + 1
                )
            });
            for (uint256 i = 0; i < curTemp.Cw20CoinVerified_addr.length; i++) {
                new_temp.Cw20CoinVerified_addr[i] = curTemp
                    .Cw20CoinVerified_addr[i];
                new_temp.Cw20CoinVerified_amount[i] = curTemp
                    .Cw20CoinVerified_amount[i];
            }
            new_temp.Cw20CoinVerified_addr[
                curTemp.Cw20CoinVerified_addr.length
            ] = curTokenaddress;
            new_temp.Cw20CoinVerified_amount[
                curTemp.Cw20CoinVerified_amount.length
            ] = curAmount;
            return new_temp;
        } else return curTemp;
    }

    function subToken(
        GenericBalance storage curTemp,
        address curTokenaddress,
        uint256 curAmount
    ) public {
        for (uint8 i = 0; i < curTemp.Cw20CoinVerified_addr.length; i++) {
            if (curTemp.Cw20CoinVerified_addr[i] == curTokenaddress) {
                curTemp.Cw20CoinVerified_amount[i] -= curAmount;
            }
        }
    }

    function subTokenMem(
        GenericBalance memory curTemp,
        address curTokenaddress,
        uint256 curAmount
    ) public pure returns (GenericBalance memory) {
        for (uint8 i = 0; i < curTemp.Cw20CoinVerified_addr.length; i++) {
            if (curTemp.Cw20CoinVerified_addr[i] == curTokenaddress) {
                curTemp.Cw20CoinVerified_amount[i] -= curAmount;
            }
        }
        return curTemp;
    }

    function splitBalance(
        uint256[] storage cw20Coin,
        uint256 splitFactor
    ) public view returns (uint256[] memory) {
        uint256[] memory curTemp = new uint256[](cw20Coin.length);
        for (uint8 i = 0; i < cw20Coin.length; i++) {
            uint256 result = SafeMath.div(cw20Coin[i], splitFactor);
            curTemp[i] = result;
        }

        return curTemp;
    }

    function receiveGenericBalance(
        address[] storage curReceiveaddr,
        uint256[] storage curReceiveamount,
        address[] storage curSenderaddr,
        uint256[] storage curSenderamount
    ) public {
        uint256 a = curSenderaddr.length;
        uint256 b = curReceiveaddr.length;

        for (uint8 i = 0; i < a; i++) {
            bool flag = true;
            for (uint8 j = 0; j < b; j++) {
                if (curSenderaddr[i] == curReceiveaddr[j]) {
                    flag = false;
                    curReceiveamount[j] += curSenderamount[i];
                }
            }

            if (flag) {
                curReceiveaddr.push(curSenderaddr[i]);
                curReceiveamount.push(curSenderamount[i]);
            }
        }
    }

    function receiveGenericBalanceModified(
        address[] storage curReceiveaddr,
        uint256[] storage curReceiveamount,
        address[] storage curSenderaddr,
        uint256[] memory curSenderamount
    ) public {
        uint256 a = curSenderaddr.length;
        uint256 b = curReceiveaddr.length;

        for (uint8 i = 0; i < a; i++) {
            bool flag = true;
            for (uint8 j = 0; j < b; j++) {
                if (curSenderaddr[i] == curReceiveaddr[j]) {
                    flag = false;
                    curReceiveamount[j] += curSenderamount[i];
                }
            }

            if (flag) {
                curReceiveaddr.push(curSenderaddr[i]);
                curReceiveamount.push(curSenderamount[i]);
            }
        }
    }

    function deductTokens(
        address[] memory curAddress,
        uint256[] memory curAmount,
        address curDeducttokenfor,
        uint256 curDeductamount
    ) public pure returns (uint256[] memory) {
        for (uint8 i = 0; i < curAddress.length; i++) {
            if (curAddress[i] == curDeducttokenfor) {
                require(curAmount[i] > curDeductamount, "Insufficient Funds");
                curAmount[i] -= curDeductamount;
            }
        }

        return curAmount;
    }

    function getTokenAmount(
        address[] memory curAddress,
        uint256[] memory curAmount,
        address curTokenaddress
    ) public pure returns (uint256) {
        uint256 amount = 0;
        for (uint8 i = 0; i < curAddress.length; i++) {
            if (curAddress[i] == curTokenaddress) {
                amount = curAmount[i];
            }
        }

        return amount;
    }

    struct AllianceMember {
        string name;
        string logo;
        string website;
    }

    function genericBalanceDefault()
        public
        pure
        returns (GenericBalance memory)
    {
        GenericBalance memory empty;
        return empty;
    }

    struct BalanceInfo {
        GenericBalance locked;
        GenericBalance liquid;
    }

    ///TODO: need to test this same names already declared in other libraries
    struct EndowmentId {
        uint256 id;
    }

    struct IndexFund {
        uint256 id;
        string name;
        string description;
        uint256[] members;
        bool rotatingFund; // set a fund as a rotating fund
        //Fund Specific: over-riding SC level setting to handle a fixed split value
        // Defines the % to split off into liquid account, and if defined overrides all other splits
        uint256 splitToLiquid;
        // Used for one-off funds that have an end date (ex. disaster recovery funds)
        uint256 expiryTime; // datetime int of index fund expiry
        uint256 expiryHeight; // block equiv of the expiry_datetime
    }

    struct Wallet {
        string addr;
    }

    struct BeneficiaryData {
        uint256 id;
        address addr;
    }

    enum BeneficiaryEnum {
        EndowmentId,
        IndexFund,
        Wallet,
        None
    }

    struct Beneficiary {
        BeneficiaryData data;
        BeneficiaryEnum enumData;
    }

    function beneficiaryDefault() public pure returns (Beneficiary memory) {
        Beneficiary memory curTemp = Beneficiary({
            enumData: BeneficiaryEnum.None,
            data: BeneficiaryData({id: 0, addr: address(0)})
        });

        return curTemp;
    }

    struct SocialMedialUrls {
        string facebook;
        string twitter;
        string linkedin;
    }

    struct Profile {
        string overview;
        string url;
        string registrationNumber;
        string countryOfOrigin;
        string streetAddress;
        string contactEmail;
        SocialMedialUrls socialMediaUrls;
        uint16 numberOfEmployees;
        string averageAnnualBudget;
        string annualRevenue;
        string charityNavigatorRating;
    }

    ///CHanges made for registrar contract

    struct SplitDetails {
        uint256 max;
        uint256 min;
        uint256 defaultSplit; // for when a split parameter is not provided
    }

    function checkSplits(
        SplitDetails memory registrarSplits,
        uint256 userLocked,
        uint256 userLiquid,
        bool userOverride
    ) public pure returns (uint256, uint256) {
        // check that the split provided by a non-TCA address meets the default
        // requirements for splits that is set in the Registrar contract
        if (
            userLiquid > registrarSplits.max ||
            userLiquid < registrarSplits.min ||
            userOverride == true
        ) {
            return (
                100 - registrarSplits.defaultSplit,
                registrarSplits.defaultSplit
            );
        } else {
            return (userLocked, userLiquid);
        }
    }

    struct AcceptedTokens {
        address[] cw20;
    }

    function cw20Valid(
        address[] memory cw20,
        address token
    ) public pure returns (bool) {
        bool check = false;
        for (uint8 i = 0; i < cw20.length; i++) {
            if (cw20[i] == token) {
                check = true;
            }
        }

        return check;
    }

    struct NetworkInfo {
        string name;
        uint256 chainId;
        address router;
        address axelerGateway;
        string ibcChannel; // Should be removed
        string transferChannel;
        address gasReceiver; // Should be removed
        uint256 gasLimit; // Should be used to set gas limit
    }

    struct Ibc {
        string ica;
    }

    ///TODO: need to check this and have a look at this
    enum VaultType {
        Native, // Juno native Vault contract
        Ibc, // the address of the Vault contract on it's Cosmos(non-Juno) chain
        Evm, // the address of the Vault contract on it's EVM chain
        None
    }

    enum BoolOptional {
        False,
        True,
        None
    }

    struct YieldVault {
        string addr; // vault's contract address on chain where the Registrar lives/??
        uint256 network; // Points to key in NetworkConnections storage map
        address inputDenom; //?
        address yieldToken; //?
        bool approved;
        EndowmentType[] restrictedFrom;
        AccountType acctType;
        VaultType vaultType;
    }

    struct Member {
        address addr;
        uint256 weight;
    }

    struct ThresholdData {
        uint256 weight;
        uint256 percentage;
        uint256 threshold;
        uint256 quorum;
    }
    enum ThresholdEnum {
        AbsoluteCount,
        AbsolutePercentage,
        ThresholdQuorum
    }

    struct DurationData {
        uint256 height;
        uint256 time;
    }

    enum DurationEnum {
        Height,
        Time
    }

    struct Duration {
        DurationEnum enumData;
        DurationData data;
    }

    //TODO: remove if not needed
    // function durationAfter(Duration memory data)
    //     public
    //     view
    //     returns (Expiration memory)
    // {
    //     if (data.enumData == DurationEnum.Height) {
    //         return
    //             Expiration({
    //                 enumData: ExpirationEnum.atHeight,
    //                 data: ExpirationData({
    //                     height: block.number + data.data.height,
    //                     time: 0
    //                 })
    //             });
    //     } else if (data.enumData == DurationEnum.Time) {
    //         return
    //             Expiration({
    //                 enumData: ExpirationEnum.atTime,
    //                 data: ExpirationData({
    //                     height: 0,
    //                     time: block.timestamp + data.data.time
    //                 })
    //             });
    //     } else {
    //         revert("Duration not configured");
    //     }
    // }

    enum ExpirationEnum {
        atHeight,
        atTime,
        Never
    }

    struct ExpirationData {
        uint256 height;
        uint256 time;
    }

    struct Expiration {
        ExpirationEnum enumData;
        ExpirationData data;
    }

    struct Threshold {
        ThresholdEnum enumData;
        ThresholdData data;
    }

    enum CurveTypeEnum {
        Constant,
        Linear,
        SquarRoot
    }

    //TODO: remove if unused
    // function getReserveRatio(CurveTypeEnum curCurveType)
    //     public
    //     pure
    //     returns (uint256)
    // {
    //     if (curCurveType == CurveTypeEnum.Linear) {
    //         return 500000;
    //     } else if (curCurveType == CurveTypeEnum.SquarRoot) {
    //         return 660000;
    //     } else {
    //         return 1000000;
    //     }
    // }

    struct CurveTypeData {
        uint128 value;
        uint256 scale;
        uint128 slope;
        uint128 power;
    }

    struct CurveType {
        CurveTypeEnum curve_type;
        CurveTypeData data;
    }

    enum TokenType {
        ExistingCw20,
        NewCw20,
        BondingCurve
    }

    struct DaoTokenData {
        address existingCw20Data;
        uint256 newCw20InitialSupply;
        string newCw20Name;
        string newCw20Symbol;
        CurveType bondingCurveCurveType;
        string bondingCurveName;
        string bondingCurveSymbol;
        uint256 bondingCurveDecimals;
        address bondingCurveReserveDenom;
        uint256 bondingCurveReserveDecimals;
        uint256 bondingCurveUnbondingPeriod;
    }

    struct DaoToken {
        TokenType token;
        DaoTokenData data;
    }

    struct DaoSetup {
        uint256 quorum; //: Decimal,
        uint256 threshold; //: Decimal,
        uint256 votingPeriod; //: u64,
        uint256 timelockPeriod; //: u64,
        uint256 expirationPeriod; //: u64,
        uint128 proposalDeposit; //: Uint128,
        uint256 snapshotPeriod; //: u64,
        DaoToken token; //: DaoToken,
    }

    struct Delegate {
        address Addr;
        uint256 expires; // datetime int of delegation expiry
    }

    function canTakeAction(
        Delegate storage self,
        address sender,
        uint256 envTime
    ) public view returns (bool) {
        if (
            sender == self.Addr &&
            (self.expires == 0 || envTime <= self.expires)
        ) {
            return true;
        } else {
            return false;
        }
    }

    struct EndowmentFee {
        address payoutAddress;
        uint256 feePercentage;
        bool active;
    }

    struct SettingsPermission {
        bool ownerControlled;
        bool govControlled;
        bool modifiableAfterInit;
        Delegate delegate;
    }

    function setDelegate(
        SettingsPermission storage self,
        address sender,
        address owner,
        address gov,
        address delegateAddr,
        uint256 delegateExpiry
    ) public {
        if (
            (sender == owner && self.ownerControlled) ||
            (gov != address(0) && self.govControlled && sender == gov)
        ) {
            self.delegate = Delegate({
                Addr: delegateAddr,
                expires: delegateExpiry
            });
        }
    }

    function revokeDelegate(
        SettingsPermission storage self,
        address sender,
        address owner,
        address gov,
        uint256 envTime
    ) public {
        if (
            (sender == owner && self.ownerControlled) ||
            (gov != address(0) && self.govControlled && sender == gov) ||
            (self.delegate.Addr != address(0) &&
                canTakeAction(self.delegate, sender, envTime))
        ) {
            self.delegate = Delegate({Addr: address(0), expires: 0});
        }
    }

    function canChange(
        SettingsPermission storage self,
        address sender,
        address owner,
        address gov,
        uint256 envTime
    ) public view returns (bool) {
        if (
            (sender == owner && self.ownerControlled) ||
            (gov != address(0) && self.govControlled && sender == gov) ||
            (self.delegate.Addr != address(0) &&
                canTakeAction(self.delegate, sender, envTime))
        ) {
            return self.modifiableAfterInit;
        }
        return false;
    }

    struct SettingsController {
        SettingsPermission endowmentController;
        SettingsPermission strategies;
        SettingsPermission whitelistedBeneficiaries;
        SettingsPermission whitelistedContributors;
        SettingsPermission maturityWhitelist;
        SettingsPermission maturityTime;
        SettingsPermission profile;
        SettingsPermission earningsFee;
        SettingsPermission withdrawFee;
        SettingsPermission depositFee;
        SettingsPermission aumFee;
        SettingsPermission kycDonorsOnly;
        SettingsPermission name;
        SettingsPermission image;
        SettingsPermission logo;
        SettingsPermission categories;
        SettingsPermission splitToLiquid;
        SettingsPermission ignoreUserSplits;
    }

    function getPermissions(
        SettingsController storage _tempObject,
        string memory name
    ) public view returns (SettingsPermission storage) {
        if (
            keccak256(abi.encodePacked(name)) ==
            keccak256(abi.encodePacked("endowmentController"))
        ) {
            return _tempObject.endowmentController;
        } else if (
            keccak256(abi.encodePacked(name)) ==
            keccak256(abi.encodePacked("maturityWhitelist"))
        ) {
            return _tempObject.maturityWhitelist;
        } else if (
            keccak256(abi.encodePacked(name)) ==
            keccak256(abi.encodePacked("splitToLiquid"))
        ) {
            return _tempObject.splitToLiquid;
        } else if (
            keccak256(abi.encodePacked(name)) ==
            keccak256(abi.encodePacked("ignoreUserSplits"))
        ) {
            return _tempObject.ignoreUserSplits;
        } else if (
            keccak256(abi.encodePacked(name)) ==
            keccak256(abi.encodePacked("strategies"))
        ) {
            return _tempObject.strategies;
        } else if (
            keccak256(abi.encodePacked(name)) ==
            keccak256(abi.encodePacked("whitelistedBeneficiaries"))
        ) {
            return _tempObject.whitelistedBeneficiaries;
        } else if (
            keccak256(abi.encodePacked(name)) ==
            keccak256(abi.encodePacked("whitelistedContributors"))
        ) {
            return _tempObject.whitelistedContributors;
        } else if (
            keccak256(abi.encodePacked(name)) ==
            keccak256(abi.encodePacked("maturityTime"))
        ) {
            return _tempObject.maturityTime;
        } else if (
            keccak256(abi.encodePacked(name)) ==
            keccak256(abi.encodePacked("profile"))
        ) {
            return _tempObject.profile;
        } else if (
            keccak256(abi.encodePacked(name)) ==
            keccak256(abi.encodePacked("earningsFee"))
        ) {
            return _tempObject.earningsFee;
        } else if (
            keccak256(abi.encodePacked(name)) ==
            keccak256(abi.encodePacked("withdrawFee"))
        ) {
            return _tempObject.withdrawFee;
        } else if (
            keccak256(abi.encodePacked(name)) ==
            keccak256(abi.encodePacked("depositFee"))
        ) {
            return _tempObject.depositFee;
        } else if (
            keccak256(abi.encodePacked(name)) ==
            keccak256(abi.encodePacked("aumFee"))
        ) {
            return _tempObject.aumFee;
        } else if (
            keccak256(abi.encodePacked(name)) ==
            keccak256(abi.encodePacked("kycDonorsOnly"))
        ) {
            return _tempObject.kycDonorsOnly;
        } else if (
            keccak256(abi.encodePacked(name)) ==
            keccak256(abi.encodePacked("name"))
        ) {
            return _tempObject.name;
        } else if (
            keccak256(abi.encodePacked(name)) ==
            keccak256(abi.encodePacked("image"))
        ) {
            return _tempObject.image;
        } else if (
            keccak256(abi.encodePacked(name)) ==
            keccak256(abi.encodePacked("logo"))
        ) {
            return _tempObject.logo;
        } else if (
            keccak256(abi.encodePacked(name)) ==
            keccak256(abi.encodePacked("categories"))
        ) {
            return _tempObject.categories;
        } else {
            revert("InvalidInputs");
        }
    }

    // None at the start as pending starts at 1 in ap rust contracts (in cw3 core)
    enum Status {
        None,
        Pending,
        Open,
        Rejected,
        Passed,
        Executed
    }
    enum Vote {
        Yes,
        No,
        Abstain,
        Veto
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

interface IPool {
    function getPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external view returns (address pool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

library SwapRouterMessages {
    struct InstantiateMsg {
        address registrarContract;
        address accountsContract;
        address swapFactory;
        address swapRouter;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

library SwapRouterStorage {
    struct Config {
        address registrarContract;
        address accountsContract;
    }
}

contract Storage {
    uint24[] swappingFees;
    SwapRouterStorage.Config config;
    address swapRouter;
    address swapFactory;
    bool initSwapRouterFlag;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

//Libraries
import {SwapRouterMessages} from "./message.sol";
import {AngelCoreStruct} from "../struct.sol";
import {IRegistrar} from "../registrar/interface/IRegistrar.sol";
import {RegistrarStorage} from "../registrar/storage.sol";
// import {IUniswapV2Router, IUniswapV2Pair, IUniswapV2Factory} from "./Interface/ISwapping.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";

import {IPool} from "./Interface/Ipool.sol";

// Interface
// import "./Interface/ISwapping.sol";

//Storage
import "./storage.sol";

/**
 *@title SwapRouter
 * @dev SwapRouter contract
 * The `SwapRouter` contract implements a swap router that facilitates the swapping of ERC20 tokens.
 */
contract SwapRouter is Storage {
    using SafeMath for uint256;

    /**
     * @dev Initialize contract
     * @param curDetails SwapRouterMessages.InstantiateMsg used to initialize contract
     */
    function intiSwapRouter(
        SwapRouterMessages.InstantiateMsg memory curDetails
    ) public {
        require(!initSwapRouterFlag, "Already Initilized");

        initSwapRouterFlag = true;
        config.registrarContract = curDetails.registrarContract;
        config.accountsContract = curDetails.accountsContract;
        swapRouter = curDetails.swapRouter;
        swapFactory = curDetails.swapFactory;

        swappingFees.push(500);
        swappingFees.push(3000);
        swappingFees.push(10000);
    }

    /**
     * @dev This function sorts two token addresses in ascending order and returns them.
     * @param tokenA address
     * @param tokenB address
     */
    function sortTokens(
        address tokenA,
        address tokenB
    ) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, "UniswapV2Library: IDENTICAL_ADDRESSES");
        (token0, token1) = tokenA < tokenB
            ? (tokenA, tokenB)
            : (tokenB, tokenA);
        require(token0 != address(0), "UniswapV2Library: ZERO_ADDRESS");
    }

    /**
     * @dev This function checks the pool and returns the fee for a swap between the two given tokens.
     * @param curTokena address
     * @param curTokenb address
     * @return fees Retruns the fee for swapping
     */
    function checkPoolAndReturFee(
        address curTokena,
        address curTokenb
    ) internal view returns (uint24) {
        require(curTokena != address(0), "Invalid Token A");
        require(curTokenb != address(0), "Invalid Token B");

        //sort Token
        (curTokena, curTokenb) = sortTokens(curTokena, curTokenb);

        uint24 fees = 0;
        address tempAddress = address(0);
        for (uint256 i = 0; i < 3; i++) {
            tempAddress = IPool(swapFactory).getPool(
                curTokena,
                curTokenb,
                swappingFees[i]
            );
            if (tempAddress != address(0)) {
                fees = swappingFees[i];
                break;
            }
        }
        // if(fees == 0) revert("No Pool Found");
        return fees;
    }

    /**
     * @dev This function swaps the given amount of tokenA for tokenB and transfers it to the specified recipient address.
     * @param curTokena address
     * @param curTokenb address
     * @param curAmount uint256
     * @param curTo address
     * @return amountOut Returns the amount of token received fom pool after swapping to specific address
     */
    function swap(
        address curTokena,
        address curTokenb,
        uint256 curAmount,
        address curTo
    ) internal returns (uint256) {
        //Get pool
        uint24 fees = checkPoolAndReturFee(curTokena, curTokenb);

        require(fees > 0, "Invalid Token Send to swap");

        require(
            IERC20(curTokena).transferFrom(
                msg.sender,
                address(this),
                curAmount
            ),
            "TransferFrom failed"
        );

        require(
            IERC20(curTokena).approve(swapRouter, curAmount),
            "Approve failed"
        );

        // Naively set amountOutMinimum to 0. In production, use an oracle or other data source to choose a safer value for amountOutMinimum.
        // We also set the sqrtPriceLimitx96 to be 0 to ensure we swap our exact input amount.
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
            .ExactInputSingleParams({
                tokenIn: curTokena,
                tokenOut: curTokenb,
                fee: fees,
                recipient: curTo,
                deadline: block.timestamp + 600,
                amountIn: curAmount,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });

        // The call to `exactInputSingle` executes the swap.
        uint256 amountOut = ISwapRouter(swapRouter).exactInputSingle(params);
        //Perform Swap
        return amountOut;
    }

    /**
     * @dev This function swaps multiple tokens for the specified output token and returns the amount obtained.
     * @param curTokenin address[]
     * @param curTokenout address[]
     * @param curAmountin uint256
     * @param curAmountout uint256[]
     * @return amountPossible Returns the amount of token obtained after swapping the tokens.
     */
    function executeSwapOperations(
        address[] memory curTokenin,
        address curTokenout,
        uint256[] memory curAmountin,
        uint256 curAmountout
    ) public returns (uint256) {
        uint256 callLength = curTokenin.length;

        require(callLength > 0, "Invalid callToken length");

        uint256 amountPossible = 0;

        for (uint8 i = 0; i < callLength; i++) {
            amountPossible += swap(
                curTokenin[i],
                curTokenout,
                curAmountin[i],
                address(this)
            );
        }

        require(
            amountPossible >= curAmountout,
            "Output funds less than the minimum funds"
        );

        require(
            IERC20(curTokenout).transfer(msg.sender, amountPossible),
            "Transfer failed"
        );

        return amountPossible;
    }

    /**
     * @dev This function swaps the given amount of the specified token for USDC. This function can only be called by the registrar contract or the accounts contract.
     * @param curTokena address
     * @param curAmountin uint256
     * @return account Returns the amount of token after swapping specified USDC token.
     */
    function swapTokenToUsdc(
        address curTokena,
        uint256 curAmountin
    ) public returns (uint256) {
        require(
            msg.sender == config.registrarContract ||
                msg.sender == config.accountsContract,
            "Unauthorized"
        );

        RegistrarStorage.Config memory registrar_config = IRegistrar(
            config.registrarContract
        ).queryConfig();

        uint256 account = swap(
            curTokena,
            registrar_config.usdcAddress,
            curAmountin,
            msg.sender
        );

        return account;
    }

    /**
     * @dev This function swaps the sent ETH for the specified token.
     * @return amountOut Returns the amount of token after swapping with ETH.
     */
    function swapEthToToken() public payable returns (uint256) {
        require(
            msg.sender == config.registrarContract ||
                msg.sender == config.accountsContract,
            "Unauthorized"
        );

        require(msg.value > 0, "Invalid Amount");

        RegistrarStorage.Config memory registrar_config = IRegistrar(
            config.registrarContract
        ).queryConfig();

        //Get pool
        uint24 fees = checkPoolAndReturFee(
            registrar_config.wethAddress,
            registrar_config.usdcAddress
        );

        // Naively set amountOutMinimum to 0. In production, use an oracle or other data source to choose a safer value for amountOutMinimum.
        // We also set the sqrtPriceLimitx96 to be 0 to ensure we swap our exact input amount.
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
            .ExactInputSingleParams({
                tokenIn: registrar_config.wethAddress,
                tokenOut: registrar_config.usdcAddress,
                fee: fees,
                recipient: msg.sender,
                deadline: block.timestamp + 600,
                amountIn: msg.value,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });

        // The call to `exactInputSingle` executes the swap.
        uint256 amountOut = ISwapRouter(swapRouter).exactInputSingle{
            value: msg.value
        }(params);

        //Perform Swap
        return amountOut;
    }

    /**
     * @dev This function swaps the sent ETH to any token.
     * @param token address
     * @return amountOut Returns the amount of token after swapping with ETH.
     */
    function swapEthToAnyToken(address token) public payable returns (uint256) {
        require(msg.value > 0, "Invalid Amount");

        RegistrarStorage.Config memory registrar_config = IRegistrar(
            config.registrarContract
        ).queryConfig();

        //Get pool
        uint24 fees = checkPoolAndReturFee(registrar_config.wethAddress, token);

        // Naively set amountOutMinimum to 0. In production, use an oracle or other data source to choose a safer value for amountOutMinimum.
        // We also set the sqrtPriceLimitx96 to be 0 to ensure we swap our exact input amount.
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
            .ExactInputSingleParams({
                tokenIn: registrar_config.wethAddress,
                tokenOut: token,
                fee: fees,
                recipient: msg.sender,
                deadline: block.timestamp + 600,
                amountIn: msg.value,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });

        // The call to `exactInputSingle` executes the swap.
        uint256 amountOut = ISwapRouter(swapRouter).exactInputSingle{
            value: msg.value
        }(params);

        //Perform Swap
        return amountOut;
    }
}