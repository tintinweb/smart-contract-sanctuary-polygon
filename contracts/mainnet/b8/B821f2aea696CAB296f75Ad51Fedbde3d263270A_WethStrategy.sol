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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
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

//SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

interface IBalancerPool {
    function balanceOf(address) external view returns(uint256);
    function getRate() external view returns(uint256);
    function getPoolId() external view returns(bytes32);
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

interface IBalancerVault {

    enum SwapKind { GIVEN_IN, GIVEN_OUT }
    enum JoinKind { INIT, EXACT_TOKENS_IN_FOR_BPT_OUT, TOKEN_IN_FOR_EXACT_BPT_OUT }
    enum ExitKind { EXACT_BPT_IN_FOR_ONE_TOKEN_OUT, BPT_IN_FOR_EXACT_TOKENS_OUT }

    struct JoinPoolRequest {
        address[] assets;
        uint256[] maxAmountsIn;
        bytes userData;
        bool fromInternalBalance;
    }

    struct ExitPoolRequest {
        address[] assets;
        uint256[] minAmountsOut;
        bytes userData;
        bool toInternalBalance;
    }

    function joinPool(
        bytes32 poolId,
        address sender,
        address recipient,
        JoinPoolRequest memory request
    ) external;

    function exitPool(
        bytes32 poolId,
        address sender,
        address recipient,
        ExitPoolRequest memory request
    ) external;

    function getPool(bytes32 poolId)
    external
    view
    returns (address, uint8);

    function getPoolTokens(bytes32 poolId)
    external
    view
    returns (
        address[] memory tokens,
        uint256[] memory balances,
        uint256 lastChangeBlock
    );
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.9.0;

interface IBeefyVault {
    function deposit(uint256) external;
    function depositAll() external;
    function withdraw(uint256) external;
    function withdrawAll() external;
    function balance() external view returns (uint256);
    function balanceOf(address) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function getPricePerFullShare() external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;
 
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

interface IProduct is IERC20, IERC20Metadata {

    ///@notice Struct for product's information
    struct ProductInfo {
        string productName;
        string productSymbol;
        string dacName;
        address dacAddress;
        address underlyingAssetAddress;
        uint256 floatRatio;
        uint256 deviationThreshold;
    }

    ///@dev Struct for Product's asset information
    struct AssetParams {
        address assetAddress;
        uint256 targetWeight;
        uint256 currentPrice;
    }

    ///@dev MUST be emitted when tokens are deposited into the vault via the deposit methods
    event Deposit(
        address indexed sender,
        address indexed owner,
        uint256 assets,
        uint256 shares,
        uint256 sharePrice,
        uint256 time
    );

    ///@dev MUST be emitted when shares are withdrawn from the vault by a depositor in the withdraw methods.
    event Withdraw(
        address indexed sender,
        address indexed receiver,
        address indexed owner,
        uint256 assets,
        uint256 share,
        uint256 sharePrice,
        uint256 time
    );

    ///@dev Must be emitted when rebalancing occure via the rebalance methods
    event Rebalance(
        address indexed caller, 
        AssetParams[] currentAssets,
        uint256 time
    );

    function currentStrategies() external view returns(address[] memory);
    function currentAssets() external view returns(AssetParams[] memory);
    function dacName() external view returns(string memory);
    function dacAddress() external view returns(address);
    function sinceDate() external view returns(uint256);
    function currentFloatRatio() external view returns(uint256);
    function assetBalance(address assetAddress) external view returns(uint256);
    function portfolioValue() external view returns(uint256);
    function assetValue(address assetAddress) external view returns (uint256);
    function checkActivation() external view returns(bool);


    function deposit(
        address assetAddress, 
        uint256 assetAmount, 
        address receiver
    ) external  returns (uint256);

    function withdraw(
        address assetAddress, 
        uint256 shareAmount,
        address receiver, 
        address owner
    ) external returns (uint256);

    function rebalance() external;

    function maxDepositValue(address receiver) external view returns(uint256);
    function maxWithdrawValue(address owner) external view returns (uint256);

    function convertToShares(address assetAddress, uint256 assetAmount) external view returns(uint256 shareAmount);
    function convertToAssets(address assetAddress, uint256 shareAmount) external view returns(uint256 assetAmount);

    function sharePrice() external view returns(uint256);
    function shareValue(uint256 shareAmount) external view returns(uint256);

}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;
 
interface IStrategy {
    // for public variables
    function underlyingAsset() external view returns(address);
    function dac() external view returns(address);
    function product() external view returns(address);

    function delegate() external view returns(address); // interacting with delegate platform's deposit / withdraw 
    function yield() external view returns(address); // interfacting with yield platform's deposit / withdraw

    // view function
    function totalAssets() external view returns(uint256);

    // for interacting with product
    function withdraw(uint256 assetAmount) external returns(bool);
    function deposit() external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "./IStrategy.sol";
import "./IProduct.sol";
import "./interfaces/IBalancerVault.sol";
import "./interfaces/IBalancerPool.sol";
import "./interfaces/IBeefyVault.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract WethStrategy is IStrategy {
    using SafeERC20 for IERC20;

    // strategy state variables
    address public dac;
    address public product;
    address immutable public underlyingAsset;

    // for yield 
    address public delegate; // Beefy vault
    address public yield; // Balancer vault
    address public yieldPool; // Balancer wstETH StablePool

    modifier onlyProduct {
        require(msg.sender == product, "No permission: only product");
        _;
    }

    modifier onlyDac {
        require(msg.sender == dac, "No permission: only dac");
        _;
    }

    constructor(address dac_, address product_) {
        underlyingAsset = 0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619; // polygon weth (immutable)
        
        require(dac_ != address(0x0), "Invalid dac address");
        dac = dac_;
        require(product_ != address(0x0), "Invalid product address");
        product = product_;

        // balancer & beefy setting
        yield = 0xBA12222222228d8Ba445958a75a0704d566BF2C8; // Balancer vault
        yieldPool = 0x65Fe9314bE50890Fb01457be076fAFD05Ff32B9A; // Balancer wstETH StablePool
        delegate = 0x1d81c50d5aB5f095894c41B41BA49B9873033399; // Beefy vault
    }

    function totalAssets() public view override returns(uint256) {
        // return totalAmount;
        uint256 totalAmount = _availableUnderlyings();
        uint256 mooAmount = IBeefyVault(delegate).balanceOf(address(this));
        uint256 bptAmount = IBalancerPool(yieldPool).balanceOf(address(this));

        // 1. mooToken => balancer bpt token
        bptAmount += mooAmount * IBeefyVault(delegate).balance() / IBeefyVault(delegate).totalSupply();

        // 2. bpt token => weth token
        // Note: The pool.getRate() function returns the exchange rate of 
        // a BPT to the underlying base asset of the pool accounting for rate providers, if they exist. 
        totalAmount += bptAmount * IBalancerPool(yieldPool).getRate() / 1e18;

        return totalAmount;
    }

    function deposit() external override onlyDac {
        uint256 underlyingAmount = _availableUnderlyings();

        if(underlyingAmount > 0) { 
            IERC20(underlyingAsset).approve(yield, underlyingAmount);
            _joinPool(underlyingAmount);
        }

        uint256 bptAmount = IBalancerPool(yieldPool).balanceOf(address(this));
        
        if(bptAmount > 0){
            IERC20(yieldPool).approve(delegate, bptAmount);
            IBeefyVault(delegate).depositAll();
        }
        else {
            revert("thers no available token balances");
        }
    }

    function withdraw(uint256 assetAmount) external override onlyProduct returns(bool) {
        uint256 availableAmount = _availableUnderlyings(); 
        
        if (availableAmount < assetAmount) {
            uint256 neededAmount = assetAmount - availableAmount;
            uint256 neededMoo = _calcUnderlyingToMoo(neededAmount);
            uint256 availableMoo = IBeefyVault(delegate).balanceOf(address(this));

            if(neededMoo > availableMoo || assetAmount >= totalAssets()) {
                neededMoo = availableMoo;
            }

            // withdraw in beefy
            IBeefyVault(delegate).withdraw(neededMoo);

            // exit pool in balancer
            uint256 bptAmount = IBalancerPool(yieldPool).balanceOf(address(this));
            _exitPool(bptAmount);

            // Todo: return loss, usdc balance ... for reporting withdraw result
            uint256 diffAmount = _availableUnderlyings() - availableAmount;
            if(diffAmount < neededAmount) { 
                assetAmount = diffAmount + availableAmount;
            }
        }
        
        // usdc transfer
        if(assetAmount > 0) SafeERC20.safeTransfer(IERC20(underlyingAsset), product, assetAmount);

        return true;
    }

    function withdrawAll() external onlyProduct returns(bool) {
        require(!IProduct(product).checkActivation(), "Product is active now");
        // withdraw in beefy
        IBeefyVault(delegate).withdrawAll();

        // exit pool in balancer
        uint256 bptAmount = IBalancerPool(yieldPool).balanceOf(address(this));
        if(bptAmount > 0) _exitPool(bptAmount);

        // transfer all weth to product
        IERC20(underlyingAsset).safeTransfer(product, _availableUnderlyings()); 
        return true;
    }

    function _availableUnderlyings() internal view returns(uint256) {
        return IERC20(underlyingAsset).balanceOf(address(this));
    }

    function _calcUnderlyingToMoo(uint256 _underlying) internal view returns(uint256) {
        // usdc -> bpt -> moo
        uint256 neededBpt = _underlying * 1e18 / IBalancerPool(yieldPool).getRate();
        uint256 neededMoo = neededBpt * IBeefyVault(delegate).totalSupply() / IBeefyVault(delegate).balance();
        return neededMoo;
    }

    function _joinPool(uint256 underlyingAmount) internal {
        // get pool id
        bytes32 poolId = IBalancerPool(yieldPool).getPoolId();

        // get pool's sorted asset list
        (address[] memory assets,,) = IBalancerVault(yield).getPoolTokens(poolId);

        // make maxAmountsIn list for request
        uint256[] memory maxAmountsIn = new uint256[](assets.length);
        for (uint256 i=0; i < maxAmountsIn.length; i++) {
            maxAmountsIn[i] = assets[i] == underlyingAsset ? underlyingAmount : 0;
        }

        // make amountsIn list for request.userData
        uint256[] memory amountsIn = new uint256[](2);
        amountsIn[0] = 0;
        amountsIn[1] = underlyingAmount;
        bytes memory userData = abi.encode(1, amountsIn, 1);
        
        // make joinPoolRequest structure and call joinPool func
        IBalancerVault.JoinPoolRequest memory request = IBalancerVault.JoinPoolRequest(assets, maxAmountsIn, userData, false);
        IBalancerVault(yield).joinPool(poolId, address(this), address(this), request);
    }

    function _exitPool(uint256 bptAmount) internal {
        bytes32 poolId = IBalancerPool(yieldPool).getPoolId();
        
        (address[] memory assets,,) = IBalancerVault(yield).getPoolTokens(poolId);
        // Withdraw all available funds regardless of slippage
        uint256[] memory amountsOut = new uint256[](assets.length); 

        bytes memory userData = abi.encode(0, bptAmount, 1); // kind, bptIn, exitTokenIndex

        IBalancerVault.ExitPoolRequest memory request = IBalancerVault.ExitPoolRequest(assets, amountsOut, userData, false);

        IBalancerVault(yield).exitPool(poolId, address(this), address(this), request);
    }
}