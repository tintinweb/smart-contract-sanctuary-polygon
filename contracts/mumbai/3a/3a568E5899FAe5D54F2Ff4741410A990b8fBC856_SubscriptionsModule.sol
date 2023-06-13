// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (interfaces/IERC4626.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";
import "../token/ERC20/extensions/IERC20Metadata.sol";

/**
 * @dev Interface of the ERC4626 "Tokenized Vault Standard", as defined in
 * https://eips.ethereum.org/EIPS/eip-4626[ERC-4626].
 *
 * _Available since v4.7._
 */
interface IERC4626 is IERC20, IERC20Metadata {
    event Deposit(address indexed caller, address indexed owner, uint256 assets, uint256 shares);

    event Withdraw(
        address indexed caller,
        address indexed receiver,
        address indexed owner,
        uint256 assets,
        uint256 shares
    );

    /**
     * @dev Returns the address of the underlying token used for the Vault for accounting, depositing, and withdrawing.
     *
     * - MUST be an ERC-20 token contract.
     * - MUST NOT revert.
     */
    function asset() external view returns (address assetTokenAddress);

    /**
     * @dev Returns the total amount of the underlying asset that is “managed” by Vault.
     *
     * - SHOULD include any compounding that occurs from yield.
     * - MUST be inclusive of any fees that are charged against assets in the Vault.
     * - MUST NOT revert.
     */
    function totalAssets() external view returns (uint256 totalManagedAssets);

    /**
     * @dev Returns the amount of shares that the Vault would exchange for the amount of assets provided, in an ideal
     * scenario where all the conditions are met.
     *
     * - MUST NOT be inclusive of any fees that are charged against assets in the Vault.
     * - MUST NOT show any variations depending on the caller.
     * - MUST NOT reflect slippage or other on-chain conditions, when performing the actual exchange.
     * - MUST NOT revert.
     *
     * NOTE: This calculation MAY NOT reflect the “per-user” price-per-share, and instead should reflect the
     * “average-user’s” price-per-share, meaning what the average user should expect to see when exchanging to and
     * from.
     */
    function convertToShares(uint256 assets) external view returns (uint256 shares);

    /**
     * @dev Returns the amount of assets that the Vault would exchange for the amount of shares provided, in an ideal
     * scenario where all the conditions are met.
     *
     * - MUST NOT be inclusive of any fees that are charged against assets in the Vault.
     * - MUST NOT show any variations depending on the caller.
     * - MUST NOT reflect slippage or other on-chain conditions, when performing the actual exchange.
     * - MUST NOT revert.
     *
     * NOTE: This calculation MAY NOT reflect the “per-user” price-per-share, and instead should reflect the
     * “average-user’s” price-per-share, meaning what the average user should expect to see when exchanging to and
     * from.
     */
    function convertToAssets(uint256 shares) external view returns (uint256 assets);

    /**
     * @dev Returns the maximum amount of the underlying asset that can be deposited into the Vault for the receiver,
     * through a deposit call.
     *
     * - MUST return a limited value if receiver is subject to some deposit limit.
     * - MUST return 2 ** 256 - 1 if there is no limit on the maximum amount of assets that may be deposited.
     * - MUST NOT revert.
     */
    function maxDeposit(address receiver) external view returns (uint256 maxAssets);

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their deposit at the current block, given
     * current on-chain conditions.
     *
     * - MUST return as close to and no more than the exact amount of Vault shares that would be minted in a deposit
     *   call in the same transaction. I.e. deposit should return the same or more shares as previewDeposit if called
     *   in the same transaction.
     * - MUST NOT account for deposit limits like those returned from maxDeposit and should always act as though the
     *   deposit would be accepted, regardless if the user has enough tokens approved, etc.
     * - MUST be inclusive of deposit fees. Integrators should be aware of the existence of deposit fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToShares and previewDeposit SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by depositing.
     */
    function previewDeposit(uint256 assets) external view returns (uint256 shares);

    /**
     * @dev Mints shares Vault shares to receiver by depositing exactly amount of underlying tokens.
     *
     * - MUST emit the Deposit event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the
     *   deposit execution, and are accounted for during deposit.
     * - MUST revert if all of assets cannot be deposited (due to deposit limit being reached, slippage, the user not
     *   approving enough underlying tokens to the Vault contract, etc).
     *
     * NOTE: most implementations will require pre-approval of the Vault with the Vault’s underlying asset token.
     */
    function deposit(uint256 assets, address receiver) external returns (uint256 shares);

    /**
     * @dev Returns the maximum amount of the Vault shares that can be minted for the receiver, through a mint call.
     * - MUST return a limited value if receiver is subject to some mint limit.
     * - MUST return 2 ** 256 - 1 if there is no limit on the maximum amount of shares that may be minted.
     * - MUST NOT revert.
     */
    function maxMint(address receiver) external view returns (uint256 maxShares);

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their mint at the current block, given
     * current on-chain conditions.
     *
     * - MUST return as close to and no fewer than the exact amount of assets that would be deposited in a mint call
     *   in the same transaction. I.e. mint should return the same or fewer assets as previewMint if called in the
     *   same transaction.
     * - MUST NOT account for mint limits like those returned from maxMint and should always act as though the mint
     *   would be accepted, regardless if the user has enough tokens approved, etc.
     * - MUST be inclusive of deposit fees. Integrators should be aware of the existence of deposit fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToAssets and previewMint SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by minting.
     */
    function previewMint(uint256 shares) external view returns (uint256 assets);

    /**
     * @dev Mints exactly shares Vault shares to receiver by depositing amount of underlying tokens.
     *
     * - MUST emit the Deposit event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the mint
     *   execution, and are accounted for during mint.
     * - MUST revert if all of shares cannot be minted (due to deposit limit being reached, slippage, the user not
     *   approving enough underlying tokens to the Vault contract, etc).
     *
     * NOTE: most implementations will require pre-approval of the Vault with the Vault’s underlying asset token.
     */
    function mint(uint256 shares, address receiver) external returns (uint256 assets);

    /**
     * @dev Returns the maximum amount of the underlying asset that can be withdrawn from the owner balance in the
     * Vault, through a withdraw call.
     *
     * - MUST return a limited value if owner is subject to some withdrawal limit or timelock.
     * - MUST NOT revert.
     */
    function maxWithdraw(address owner) external view returns (uint256 maxAssets);

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their withdrawal at the current block,
     * given current on-chain conditions.
     *
     * - MUST return as close to and no fewer than the exact amount of Vault shares that would be burned in a withdraw
     *   call in the same transaction. I.e. withdraw should return the same or fewer shares as previewWithdraw if
     *   called
     *   in the same transaction.
     * - MUST NOT account for withdrawal limits like those returned from maxWithdraw and should always act as though
     *   the withdrawal would be accepted, regardless if the user has enough shares, etc.
     * - MUST be inclusive of withdrawal fees. Integrators should be aware of the existence of withdrawal fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToShares and previewWithdraw SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by depositing.
     */
    function previewWithdraw(uint256 assets) external view returns (uint256 shares);

    /**
     * @dev Burns shares from owner and sends exactly assets of underlying tokens to receiver.
     *
     * - MUST emit the Withdraw event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the
     *   withdraw execution, and are accounted for during withdraw.
     * - MUST revert if all of assets cannot be withdrawn (due to withdrawal limit being reached, slippage, the owner
     *   not having enough shares, etc).
     *
     * Note that some implementations will require pre-requesting to the Vault before a withdrawal may be performed.
     * Those methods should be performed separately.
     */
    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) external returns (uint256 shares);

    /**
     * @dev Returns the maximum amount of Vault shares that can be redeemed from the owner balance in the Vault,
     * through a redeem call.
     *
     * - MUST return a limited value if owner is subject to some withdrawal limit or timelock.
     * - MUST return balanceOf(owner) if owner is not subject to any withdrawal limit or timelock.
     * - MUST NOT revert.
     */
    function maxRedeem(address owner) external view returns (uint256 maxShares);

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their redeemption at the current block,
     * given current on-chain conditions.
     *
     * - MUST return as close to and no more than the exact amount of assets that would be withdrawn in a redeem call
     *   in the same transaction. I.e. redeem should return the same or more assets as previewRedeem if called in the
     *   same transaction.
     * - MUST NOT account for redemption limits like those returned from maxRedeem and should always act as though the
     *   redemption would be accepted, regardless if the user has enough shares, etc.
     * - MUST be inclusive of withdrawal fees. Integrators should be aware of the existence of withdrawal fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToAssets and previewRedeem SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by redeeming.
     */
    function previewRedeem(uint256 shares) external view returns (uint256 assets);

    /**
     * @dev Burns exactly shares from owner and sends assets of underlying tokens to receiver.
     *
     * - MUST emit the Withdraw event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the
     *   redeem execution, and are accounted for during redeem.
     * - MUST revert if all of shares cannot be redeemed (due to withdrawal limit being reached, slippage, the owner
     *   not having enough shares, etc).
     *
     * NOTE: some implementations will require pre-requesting to the Vault before a withdrawal may be performed.
     * Those methods should be performed separately.
     */
    function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) external returns (uint256 assets);
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. It the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`.
        // We also know that `k`, the position of the most significant bit, is such that `msb(a) = 2**k`.
        // This gives `2**k < a <= 2**(k+1)` → `2**(k/2) <= sqrt(a) < 2 ** (k/2+1)`.
        // Using an algorithm similar to the msb conmputation, we are able to compute `result = 2**(k/2)` which is a
        // good first aproximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1;
        uint256 x = a;
        if (x >> 128 > 0) {
            x >>= 128;
            result <<= 64;
        }
        if (x >> 64 > 0) {
            x >>= 64;
            result <<= 32;
        }
        if (x >> 32 > 0) {
            x >>= 32;
            result <<= 16;
        }
        if (x >> 16 > 0) {
            x >>= 16;
            result <<= 8;
        }
        if (x >> 8 > 0) {
            x >>= 8;
            result <<= 4;
        }
        if (x >> 4 > 0) {
            x >>= 4;
            result <<= 2;
        }
        if (x >> 2 > 0) {
            result <<= 1;
        }

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        uint256 result = sqrt(a);
        if (rounding == Rounding.Up && result * result < a) {
            result += 1;
        }
        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/math/SafeCast.sol)

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint248 from uint256, reverting on
     * overflow (when the input is greater than largest uint248).
     *
     * Counterpart to Solidity's `uint248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toUint248(uint256 value) internal pure returns (uint248) {
        require(value <= type(uint248).max, "SafeCast: value doesn't fit in 248 bits");
        return uint248(value);
    }

    /**
     * @dev Returns the downcasted uint240 from uint256, reverting on
     * overflow (when the input is greater than largest uint240).
     *
     * Counterpart to Solidity's `uint240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toUint240(uint256 value) internal pure returns (uint240) {
        require(value <= type(uint240).max, "SafeCast: value doesn't fit in 240 bits");
        return uint240(value);
    }

    /**
     * @dev Returns the downcasted uint232 from uint256, reverting on
     * overflow (when the input is greater than largest uint232).
     *
     * Counterpart to Solidity's `uint232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toUint232(uint256 value) internal pure returns (uint232) {
        require(value <= type(uint232).max, "SafeCast: value doesn't fit in 232 bits");
        return uint232(value);
    }

    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.2._
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint216 from uint256, reverting on
     * overflow (when the input is greater than largest uint216).
     *
     * Counterpart to Solidity's `uint216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toUint216(uint256 value) internal pure returns (uint216) {
        require(value <= type(uint216).max, "SafeCast: value doesn't fit in 216 bits");
        return uint216(value);
    }

    /**
     * @dev Returns the downcasted uint208 from uint256, reverting on
     * overflow (when the input is greater than largest uint208).
     *
     * Counterpart to Solidity's `uint208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toUint208(uint256 value) internal pure returns (uint208) {
        require(value <= type(uint208).max, "SafeCast: value doesn't fit in 208 bits");
        return uint208(value);
    }

    /**
     * @dev Returns the downcasted uint200 from uint256, reverting on
     * overflow (when the input is greater than largest uint200).
     *
     * Counterpart to Solidity's `uint200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toUint200(uint256 value) internal pure returns (uint200) {
        require(value <= type(uint200).max, "SafeCast: value doesn't fit in 200 bits");
        return uint200(value);
    }

    /**
     * @dev Returns the downcasted uint192 from uint256, reverting on
     * overflow (when the input is greater than largest uint192).
     *
     * Counterpart to Solidity's `uint192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toUint192(uint256 value) internal pure returns (uint192) {
        require(value <= type(uint192).max, "SafeCast: value doesn't fit in 192 bits");
        return uint192(value);
    }

    /**
     * @dev Returns the downcasted uint184 from uint256, reverting on
     * overflow (when the input is greater than largest uint184).
     *
     * Counterpart to Solidity's `uint184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toUint184(uint256 value) internal pure returns (uint184) {
        require(value <= type(uint184).max, "SafeCast: value doesn't fit in 184 bits");
        return uint184(value);
    }

    /**
     * @dev Returns the downcasted uint176 from uint256, reverting on
     * overflow (when the input is greater than largest uint176).
     *
     * Counterpart to Solidity's `uint176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toUint176(uint256 value) internal pure returns (uint176) {
        require(value <= type(uint176).max, "SafeCast: value doesn't fit in 176 bits");
        return uint176(value);
    }

    /**
     * @dev Returns the downcasted uint168 from uint256, reverting on
     * overflow (when the input is greater than largest uint168).
     *
     * Counterpart to Solidity's `uint168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toUint168(uint256 value) internal pure returns (uint168) {
        require(value <= type(uint168).max, "SafeCast: value doesn't fit in 168 bits");
        return uint168(value);
    }

    /**
     * @dev Returns the downcasted uint160 from uint256, reverting on
     * overflow (when the input is greater than largest uint160).
     *
     * Counterpart to Solidity's `uint160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toUint160(uint256 value) internal pure returns (uint160) {
        require(value <= type(uint160).max, "SafeCast: value doesn't fit in 160 bits");
        return uint160(value);
    }

    /**
     * @dev Returns the downcasted uint152 from uint256, reverting on
     * overflow (when the input is greater than largest uint152).
     *
     * Counterpart to Solidity's `uint152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toUint152(uint256 value) internal pure returns (uint152) {
        require(value <= type(uint152).max, "SafeCast: value doesn't fit in 152 bits");
        return uint152(value);
    }

    /**
     * @dev Returns the downcasted uint144 from uint256, reverting on
     * overflow (when the input is greater than largest uint144).
     *
     * Counterpart to Solidity's `uint144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toUint144(uint256 value) internal pure returns (uint144) {
        require(value <= type(uint144).max, "SafeCast: value doesn't fit in 144 bits");
        return uint144(value);
    }

    /**
     * @dev Returns the downcasted uint136 from uint256, reverting on
     * overflow (when the input is greater than largest uint136).
     *
     * Counterpart to Solidity's `uint136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toUint136(uint256 value) internal pure returns (uint136) {
        require(value <= type(uint136).max, "SafeCast: value doesn't fit in 136 bits");
        return uint136(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v2.5._
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint120 from uint256, reverting on
     * overflow (when the input is greater than largest uint120).
     *
     * Counterpart to Solidity's `uint120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toUint120(uint256 value) internal pure returns (uint120) {
        require(value <= type(uint120).max, "SafeCast: value doesn't fit in 120 bits");
        return uint120(value);
    }

    /**
     * @dev Returns the downcasted uint112 from uint256, reverting on
     * overflow (when the input is greater than largest uint112).
     *
     * Counterpart to Solidity's `uint112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toUint112(uint256 value) internal pure returns (uint112) {
        require(value <= type(uint112).max, "SafeCast: value doesn't fit in 112 bits");
        return uint112(value);
    }

    /**
     * @dev Returns the downcasted uint104 from uint256, reverting on
     * overflow (when the input is greater than largest uint104).
     *
     * Counterpart to Solidity's `uint104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toUint104(uint256 value) internal pure returns (uint104) {
        require(value <= type(uint104).max, "SafeCast: value doesn't fit in 104 bits");
        return uint104(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     *
     * _Available since v4.2._
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint88 from uint256, reverting on
     * overflow (when the input is greater than largest uint88).
     *
     * Counterpart to Solidity's `uint88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toUint88(uint256 value) internal pure returns (uint88) {
        require(value <= type(uint88).max, "SafeCast: value doesn't fit in 88 bits");
        return uint88(value);
    }

    /**
     * @dev Returns the downcasted uint80 from uint256, reverting on
     * overflow (when the input is greater than largest uint80).
     *
     * Counterpart to Solidity's `uint80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toUint80(uint256 value) internal pure returns (uint80) {
        require(value <= type(uint80).max, "SafeCast: value doesn't fit in 80 bits");
        return uint80(value);
    }

    /**
     * @dev Returns the downcasted uint72 from uint256, reverting on
     * overflow (when the input is greater than largest uint72).
     *
     * Counterpart to Solidity's `uint72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toUint72(uint256 value) internal pure returns (uint72) {
        require(value <= type(uint72).max, "SafeCast: value doesn't fit in 72 bits");
        return uint72(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v2.5._
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint56 from uint256, reverting on
     * overflow (when the input is greater than largest uint56).
     *
     * Counterpart to Solidity's `uint56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toUint56(uint256 value) internal pure returns (uint56) {
        require(value <= type(uint56).max, "SafeCast: value doesn't fit in 56 bits");
        return uint56(value);
    }

    /**
     * @dev Returns the downcasted uint48 from uint256, reverting on
     * overflow (when the input is greater than largest uint48).
     *
     * Counterpart to Solidity's `uint48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toUint48(uint256 value) internal pure returns (uint48) {
        require(value <= type(uint48).max, "SafeCast: value doesn't fit in 48 bits");
        return uint48(value);
    }

    /**
     * @dev Returns the downcasted uint40 from uint256, reverting on
     * overflow (when the input is greater than largest uint40).
     *
     * Counterpart to Solidity's `uint40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toUint40(uint256 value) internal pure returns (uint40) {
        require(value <= type(uint40).max, "SafeCast: value doesn't fit in 40 bits");
        return uint40(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v2.5._
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint24 from uint256, reverting on
     * overflow (when the input is greater than largest uint24).
     *
     * Counterpart to Solidity's `uint24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toUint24(uint256 value) internal pure returns (uint24) {
        require(value <= type(uint24).max, "SafeCast: value doesn't fit in 24 bits");
        return uint24(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v2.5._
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits
     *
     * _Available since v2.5._
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     *
     * _Available since v3.0._
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int248 from int256, reverting on
     * overflow (when the input is less than smallest int248 or
     * greater than largest int248).
     *
     * Counterpart to Solidity's `int248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toInt248(int256 value) internal pure returns (int248) {
        require(value >= type(int248).min && value <= type(int248).max, "SafeCast: value doesn't fit in 248 bits");
        return int248(value);
    }

    /**
     * @dev Returns the downcasted int240 from int256, reverting on
     * overflow (when the input is less than smallest int240 or
     * greater than largest int240).
     *
     * Counterpart to Solidity's `int240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toInt240(int256 value) internal pure returns (int240) {
        require(value >= type(int240).min && value <= type(int240).max, "SafeCast: value doesn't fit in 240 bits");
        return int240(value);
    }

    /**
     * @dev Returns the downcasted int232 from int256, reverting on
     * overflow (when the input is less than smallest int232 or
     * greater than largest int232).
     *
     * Counterpart to Solidity's `int232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toInt232(int256 value) internal pure returns (int232) {
        require(value >= type(int232).min && value <= type(int232).max, "SafeCast: value doesn't fit in 232 bits");
        return int232(value);
    }

    /**
     * @dev Returns the downcasted int224 from int256, reverting on
     * overflow (when the input is less than smallest int224 or
     * greater than largest int224).
     *
     * Counterpart to Solidity's `int224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.7._
     */
    function toInt224(int256 value) internal pure returns (int224) {
        require(value >= type(int224).min && value <= type(int224).max, "SafeCast: value doesn't fit in 224 bits");
        return int224(value);
    }

    /**
     * @dev Returns the downcasted int216 from int256, reverting on
     * overflow (when the input is less than smallest int216 or
     * greater than largest int216).
     *
     * Counterpart to Solidity's `int216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toInt216(int256 value) internal pure returns (int216) {
        require(value >= type(int216).min && value <= type(int216).max, "SafeCast: value doesn't fit in 216 bits");
        return int216(value);
    }

    /**
     * @dev Returns the downcasted int208 from int256, reverting on
     * overflow (when the input is less than smallest int208 or
     * greater than largest int208).
     *
     * Counterpart to Solidity's `int208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toInt208(int256 value) internal pure returns (int208) {
        require(value >= type(int208).min && value <= type(int208).max, "SafeCast: value doesn't fit in 208 bits");
        return int208(value);
    }

    /**
     * @dev Returns the downcasted int200 from int256, reverting on
     * overflow (when the input is less than smallest int200 or
     * greater than largest int200).
     *
     * Counterpart to Solidity's `int200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toInt200(int256 value) internal pure returns (int200) {
        require(value >= type(int200).min && value <= type(int200).max, "SafeCast: value doesn't fit in 200 bits");
        return int200(value);
    }

    /**
     * @dev Returns the downcasted int192 from int256, reverting on
     * overflow (when the input is less than smallest int192 or
     * greater than largest int192).
     *
     * Counterpart to Solidity's `int192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toInt192(int256 value) internal pure returns (int192) {
        require(value >= type(int192).min && value <= type(int192).max, "SafeCast: value doesn't fit in 192 bits");
        return int192(value);
    }

    /**
     * @dev Returns the downcasted int184 from int256, reverting on
     * overflow (when the input is less than smallest int184 or
     * greater than largest int184).
     *
     * Counterpart to Solidity's `int184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toInt184(int256 value) internal pure returns (int184) {
        require(value >= type(int184).min && value <= type(int184).max, "SafeCast: value doesn't fit in 184 bits");
        return int184(value);
    }

    /**
     * @dev Returns the downcasted int176 from int256, reverting on
     * overflow (when the input is less than smallest int176 or
     * greater than largest int176).
     *
     * Counterpart to Solidity's `int176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toInt176(int256 value) internal pure returns (int176) {
        require(value >= type(int176).min && value <= type(int176).max, "SafeCast: value doesn't fit in 176 bits");
        return int176(value);
    }

    /**
     * @dev Returns the downcasted int168 from int256, reverting on
     * overflow (when the input is less than smallest int168 or
     * greater than largest int168).
     *
     * Counterpart to Solidity's `int168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toInt168(int256 value) internal pure returns (int168) {
        require(value >= type(int168).min && value <= type(int168).max, "SafeCast: value doesn't fit in 168 bits");
        return int168(value);
    }

    /**
     * @dev Returns the downcasted int160 from int256, reverting on
     * overflow (when the input is less than smallest int160 or
     * greater than largest int160).
     *
     * Counterpart to Solidity's `int160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toInt160(int256 value) internal pure returns (int160) {
        require(value >= type(int160).min && value <= type(int160).max, "SafeCast: value doesn't fit in 160 bits");
        return int160(value);
    }

    /**
     * @dev Returns the downcasted int152 from int256, reverting on
     * overflow (when the input is less than smallest int152 or
     * greater than largest int152).
     *
     * Counterpart to Solidity's `int152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toInt152(int256 value) internal pure returns (int152) {
        require(value >= type(int152).min && value <= type(int152).max, "SafeCast: value doesn't fit in 152 bits");
        return int152(value);
    }

    /**
     * @dev Returns the downcasted int144 from int256, reverting on
     * overflow (when the input is less than smallest int144 or
     * greater than largest int144).
     *
     * Counterpart to Solidity's `int144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toInt144(int256 value) internal pure returns (int144) {
        require(value >= type(int144).min && value <= type(int144).max, "SafeCast: value doesn't fit in 144 bits");
        return int144(value);
    }

    /**
     * @dev Returns the downcasted int136 from int256, reverting on
     * overflow (when the input is less than smallest int136 or
     * greater than largest int136).
     *
     * Counterpart to Solidity's `int136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toInt136(int256 value) internal pure returns (int136) {
        require(value >= type(int136).min && value <= type(int136).max, "SafeCast: value doesn't fit in 136 bits");
        return int136(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= type(int128).min && value <= type(int128).max, "SafeCast: value doesn't fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int120 from int256, reverting on
     * overflow (when the input is less than smallest int120 or
     * greater than largest int120).
     *
     * Counterpart to Solidity's `int120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toInt120(int256 value) internal pure returns (int120) {
        require(value >= type(int120).min && value <= type(int120).max, "SafeCast: value doesn't fit in 120 bits");
        return int120(value);
    }

    /**
     * @dev Returns the downcasted int112 from int256, reverting on
     * overflow (when the input is less than smallest int112 or
     * greater than largest int112).
     *
     * Counterpart to Solidity's `int112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toInt112(int256 value) internal pure returns (int112) {
        require(value >= type(int112).min && value <= type(int112).max, "SafeCast: value doesn't fit in 112 bits");
        return int112(value);
    }

    /**
     * @dev Returns the downcasted int104 from int256, reverting on
     * overflow (when the input is less than smallest int104 or
     * greater than largest int104).
     *
     * Counterpart to Solidity's `int104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toInt104(int256 value) internal pure returns (int104) {
        require(value >= type(int104).min && value <= type(int104).max, "SafeCast: value doesn't fit in 104 bits");
        return int104(value);
    }

    /**
     * @dev Returns the downcasted int96 from int256, reverting on
     * overflow (when the input is less than smallest int96 or
     * greater than largest int96).
     *
     * Counterpart to Solidity's `int96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     *
     * _Available since v4.7._
     */
    function toInt96(int256 value) internal pure returns (int96) {
        require(value >= type(int96).min && value <= type(int96).max, "SafeCast: value doesn't fit in 96 bits");
        return int96(value);
    }

    /**
     * @dev Returns the downcasted int88 from int256, reverting on
     * overflow (when the input is less than smallest int88 or
     * greater than largest int88).
     *
     * Counterpart to Solidity's `int88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toInt88(int256 value) internal pure returns (int88) {
        require(value >= type(int88).min && value <= type(int88).max, "SafeCast: value doesn't fit in 88 bits");
        return int88(value);
    }

    /**
     * @dev Returns the downcasted int80 from int256, reverting on
     * overflow (when the input is less than smallest int80 or
     * greater than largest int80).
     *
     * Counterpart to Solidity's `int80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toInt80(int256 value) internal pure returns (int80) {
        require(value >= type(int80).min && value <= type(int80).max, "SafeCast: value doesn't fit in 80 bits");
        return int80(value);
    }

    /**
     * @dev Returns the downcasted int72 from int256, reverting on
     * overflow (when the input is less than smallest int72 or
     * greater than largest int72).
     *
     * Counterpart to Solidity's `int72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toInt72(int256 value) internal pure returns (int72) {
        require(value >= type(int72).min && value <= type(int72).max, "SafeCast: value doesn't fit in 72 bits");
        return int72(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= type(int64).min && value <= type(int64).max, "SafeCast: value doesn't fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int56 from int256, reverting on
     * overflow (when the input is less than smallest int56 or
     * greater than largest int56).
     *
     * Counterpart to Solidity's `int56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toInt56(int256 value) internal pure returns (int56) {
        require(value >= type(int56).min && value <= type(int56).max, "SafeCast: value doesn't fit in 56 bits");
        return int56(value);
    }

    /**
     * @dev Returns the downcasted int48 from int256, reverting on
     * overflow (when the input is less than smallest int48 or
     * greater than largest int48).
     *
     * Counterpart to Solidity's `int48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toInt48(int256 value) internal pure returns (int48) {
        require(value >= type(int48).min && value <= type(int48).max, "SafeCast: value doesn't fit in 48 bits");
        return int48(value);
    }

    /**
     * @dev Returns the downcasted int40 from int256, reverting on
     * overflow (when the input is less than smallest int40 or
     * greater than largest int40).
     *
     * Counterpart to Solidity's `int40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toInt40(int256 value) internal pure returns (int40) {
        require(value >= type(int40).min && value <= type(int40).max, "SafeCast: value doesn't fit in 40 bits");
        return int40(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= type(int32).min && value <= type(int32).max, "SafeCast: value doesn't fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int24 from int256, reverting on
     * overflow (when the input is less than smallest int24 or
     * greater than largest int24).
     *
     * Counterpart to Solidity's `int24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toInt24(int256 value) internal pure returns (int24) {
        require(value >= type(int24).min && value <= type(int24).max, "SafeCast: value doesn't fit in 24 bits");
        return int24(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= type(int16).min && value <= type(int16).max, "SafeCast: value doesn't fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= type(int8).min && value <= type(int8).max, "SafeCast: value doesn't fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     *
     * _Available since v3.0._
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title ERC20 token implementation.
 */
interface IERC20 {
    /**
     * @notice Emitted when tokens have been transferred.
     * @param from The address that originally owned the tokens.
     * @param to The address that received the tokens.
     * @param amount The number of tokens that were transferred.
     */
    event Transfer(address indexed from, address indexed to, uint amount);

    /**
     * @notice Emitted when a user has provided allowance to another user for transferring tokens on its behalf.
     * @param owner The address that is providing the allowance.
     * @param spender The address that received the allowance.
     * @param amount The number of tokens that were added to `spender`'s allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint amount);

    /**
     * @notice Thrown when the address interacting with the contract does not have sufficient allowance to transfer tokens from another contract.
     * @param required The necessary allowance.
     * @param existing The current allowance.
     */
    error InsufficientAllowance(uint required, uint existing);

    /**
     * @notice Thrown when the address interacting with the contract does not have sufficient tokens.
     * @param required The necessary balance.
     * @param existing The current balance.
     */
    error InsufficientBalance(uint required, uint existing);

    /**
     * @notice Retrieves the name of the token, e.g. "Synthetix Network Token".
     * @return A string with the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @notice Retrieves the symbol of the token, e.g. "SNX".
     * @return A string with the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @notice Retrieves the number of decimals used by the token. The default is 18.
     * @return The number of decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @notice Returns the total number of tokens in circulation (minted - burnt).
     * @return The total number of tokens.
     */
    function totalSupply() external view returns (uint);

    /**
     * @notice Returns the balance of a user.
     * @param owner The address whose balance is being retrieved.
     * @return The number of tokens owned by the user.
     */
    function balanceOf(address owner) external view returns (uint);

    /**
     * @notice Returns how many tokens a user has allowed another user to transfer on its behalf.
     * @param owner The user who has given the allowance.
     * @param spender The user who was given the allowance.
     * @return The amount of tokens `spender` can transfer on `owner`'s behalf.
     */
    function allowance(address owner, address spender) external view returns (uint);

    /**
     * @notice Transfer tokens from one address to another.
     * @param to The address that will receive the tokens.
     * @param amount The amount of tokens to be transferred.
     * @return A boolean which is true if the operation succeeded.
     */
    function transfer(address to, uint amount) external returns (bool);

    /**
     * @notice Allows users to provide allowance to other users so that they can transfer tokens on their behalf.
     * @param spender The address that is receiving the allowance.
     * @param amount The amount of tokens that are being added to the allowance.
     * @return A boolean which is true if the operation succeeded.
     */
    function approve(address spender, uint amount) external returns (bool);

    /**
     * @notice Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);

    /**
     * @notice Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);

    /**
     * @notice Allows a user who has been given allowance to transfer tokens on another user's behalf.
     * @param from The address that owns the tokens that are being transferred.
     * @param to The address that will receive the tokens.
     * @param amount The number of tokens to transfer.
     * @return A boolean which is true if the operation succeeded.
     */
    function transferFrom(address from, address to, uint amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title ERC721 non-fungible token (NFT) contract.
 */
interface IERC721 {
    /**
     * @notice Thrown when an address attempts to provide allowance to itself.
     * @param addr The address attempting to provide allowance.
     */
    error CannotSelfApprove(address addr);

    /**
     * @notice Thrown when attempting to transfer a token to an address that does not satisfy IERC721Receiver requirements.
     * @param addr The address that cannot receive the tokens.
     */
    error InvalidTransferRecipient(address addr);

    /**
     * @notice Thrown when attempting to specify an owner which is not valid (ex. the 0x00000... address)
     */
    error InvalidOwner(address addr);

    /**
     * @notice Thrown when attempting to operate on a token id that does not exist.
     * @param id The token id that does not exist.
     */
    error TokenDoesNotExist(uint256 id);

    /**
     * @notice Thrown when attempting to mint a token that already exists.
     * @param id The token id that already exists.
     */
    error TokenAlreadyMinted(uint256 id);

    /**
     * @notice Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @notice Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @notice Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @notice Returns the number of tokens in ``owner``'s account.
     *
     * Requirements:
     *
     * - `holder` must be a valid address
     */
    function balanceOf(address holder) external view returns (uint256 balance);

    /**
     * @notice Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @notice Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @notice Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @notice Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @notice Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @notice Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @notice Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @notice Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import "./IERC721.sol";

/**
 * @title ERC721 extension with helper functions that allow the enumeration of NFT tokens.
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @notice Thrown calling *ByIndex function with an index greater than the number of tokens existing
     * @param requestedIndex The index requested by the caller
     * @param length The length of the list that is being iterated, making the max index queryable length - 1
     */
    error IndexOverrun(uint requestedIndex, uint length);

    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     *
     * Requirements:
     * - `owner` must be a valid address
     * - `index` must be less than the balance of the tokens for the owner
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     *
     * Requirements:
     * - `index` must be less than the total supply of the tokens
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * Utilities that convert numeric types avoiding silent overflows.
 */
import "./SafeCast/SafeCastU32.sol";
import "./SafeCast/SafeCastI32.sol";
import "./SafeCast/SafeCastI24.sol";
import "./SafeCast/SafeCastU56.sol";
import "./SafeCast/SafeCastI56.sol";
import "./SafeCast/SafeCastU64.sol";
import "./SafeCast/SafeCastI128.sol";
import "./SafeCast/SafeCastI256.sol";
import "./SafeCast/SafeCastU128.sol";
import "./SafeCast/SafeCastU160.sol";
import "./SafeCast/SafeCastU256.sol";
import "./SafeCast/SafeCastAddress.sol";
import "./SafeCast/SafeCastBytes32.sol";

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title See SafeCast.sol.
 */
library SafeCastAddress {
    function toBytes32(address x) internal pure returns (bytes32) {
        return bytes32(uint256(uint160(x)));
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title See SafeCast.sol.
 */
library SafeCastBytes32 {
    function toAddress(bytes32 x) internal pure returns (address) {
        return address(uint160(uint256(x)));
    }

    function toUint(bytes32 x) internal pure returns (uint) {
        return uint(x);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title See SafeCast.sol.
 */
library SafeCastI128 {
    error OverflowInt128ToUint128();
    error OverflowInt128ToInt32();

    function toUint(int128 x) internal pure returns (uint128) {
        // ----------------<==============o==============>-----------------
        // ----------------xxxxxxxxxxxxxxxo===============>----------------
        if (x < 0) {
            revert OverflowInt128ToUint128();
        }

        return uint128(x);
    }

    function to256(int128 x) internal pure returns (int256) {
        return int256(x);
    }

    function to32(int128 x) internal pure returns (int32) {
        // ----------------<==============o==============>-----------------
        // ----------------xxxxxxxxxxxx<==o==>xxxxxxxxxxxx-----------------
        if (x < int(type(int32).min) || x > int(type(int32).max)) {
            revert OverflowInt128ToInt32();
        }

        return int32(x);
    }

    function zero() internal pure returns (int128) {
        return int128(0);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title See SafeCast.sol.
 */
library SafeCastI24 {
    function to256(int24 x) internal pure returns (int256) {
        return int256(x);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title See SafeCast.sol.
 */
library SafeCastI256 {
    error OverflowInt256ToUint256();
    error OverflowInt256ToInt128();
    error OverflowInt256ToInt24();

    function to128(int256 x) internal pure returns (int128) {
        // ----<==========================o===========================>----
        // ----xxxxxxxxxxxx<==============o==============>xxxxxxxxxxxxx----
        if (x < int256(type(int128).min) || x > int256(type(int128).max)) {
            revert OverflowInt256ToInt128();
        }

        return int128(x);
    }

    function to24(int256 x) internal pure returns (int24) {
        // ----<==========================o===========================>----
        // ----xxxxxxxxxxxxxxxxxxxx<======o=======>xxxxxxxxxxxxxxxxxxxx----
        if (x < int256(type(int24).min) || x > int256(type(int24).max)) {
            revert OverflowInt256ToInt24();
        }

        return int24(x);
    }

    function toUint(int256 x) internal pure returns (uint256) {
        // ----<==========================o===========================>----
        // ----xxxxxxxxxxxxxxxxxxxxxxxxxxxo===============================>
        if (x < 0) {
            revert OverflowInt256ToUint256();
        }

        return uint256(x);
    }

    function zero() internal pure returns (int256) {
        return int256(0);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title See SafeCast.sol.
 */
library SafeCastI32 {
    error OverflowInt32ToUint32();

    function toUint(int32 x) internal pure returns (uint32) {
        // ----------------------<========o========>----------------------
        // ----------------------xxxxxxxxxo=========>----------------------
        if (x < 0) {
            revert OverflowInt32ToUint32();
        }

        return uint32(x);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title See SafeCast.sol.
 */
library SafeCastI56 {
    error OverflowInt56ToInt24();

    function to24(int56 x) internal pure returns (int24) {
        // ----------------------<========o========>-----------------------
        // ----------------------xxx<=====o=====>xxx-----------------------
        if (x < int(type(int24).min) || x > int(type(int24).max)) {
            revert OverflowInt56ToInt24();
        }

        return int24(x);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title See SafeCast.sol.
 */
library SafeCastU128 {
    error OverflowUint128ToInt128();

    function to256(uint128 x) internal pure returns (uint256) {
        return uint256(x);
    }

    function toInt(uint128 x) internal pure returns (int128) {
        // -------------------------------o===============>----------------
        // ----------------<==============o==============>x----------------
        if (x > uint128(type(int128).max)) {
            revert OverflowUint128ToInt128();
        }

        return int128(x);
    }

    function toBytes32(uint128 x) internal pure returns (bytes32) {
        return bytes32(uint256(x));
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title See SafeCast.sol.
 */
library SafeCastU160 {
    function to256(uint160 x) internal pure returns (uint256) {
        return uint256(x);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title See SafeCast.sol.
 */
library SafeCastU256 {
    error OverflowUint256ToUint128();
    error OverflowUint256ToInt256();
    error OverflowUint256ToUint64();
    error OverflowUint256ToUint32();
    error OverflowUint256ToUint160();

    function to128(uint256 x) internal pure returns (uint128) {
        // -------------------------------o===============================>
        // -------------------------------o===============>xxxxxxxxxxxxxxxx
        if (x > type(uint128).max) {
            revert OverflowUint256ToUint128();
        }

        return uint128(x);
    }

    function to64(uint256 x) internal pure returns (uint64) {
        // -------------------------------o===============================>
        // -------------------------------o======>xxxxxxxxxxxxxxxxxxxxxxxxx
        if (x > type(uint64).max) {
            revert OverflowUint256ToUint64();
        }

        return uint64(x);
    }

    function to32(uint256 x) internal pure returns (uint32) {
        // -------------------------------o===============================>
        // -------------------------------o===>xxxxxxxxxxxxxxxxxxxxxxxxxxxx
        if (x > type(uint32).max) {
            revert OverflowUint256ToUint32();
        }

        return uint32(x);
    }

    function to160(uint256 x) internal pure returns (uint160) {
        // -------------------------------o===============================>
        // -------------------------------o==================>xxxxxxxxxxxxx
        if (x > type(uint160).max) {
            revert OverflowUint256ToUint160();
        }

        return uint160(x);
    }

    function toBytes32(uint256 x) internal pure returns (bytes32) {
        return bytes32(x);
    }

    function toInt(uint256 x) internal pure returns (int256) {
        // -------------------------------o===============================>
        // ----<==========================o===========================>xxxx
        if (x > uint256(type(int256).max)) {
            revert OverflowUint256ToInt256();
        }

        return int256(x);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title See SafeCast.sol.
 */
library SafeCastU32 {
    error OverflowUint32ToInt32();

    function toInt(uint32 x) internal pure returns (int32) {
        // -------------------------------o=========>----------------------
        // ----------------------<========o========>x----------------------
        if (x > uint32(type(int32).max)) {
            revert OverflowUint32ToInt32();
        }

        return int32(x);
    }

    function to256(uint32 x) internal pure returns (uint256) {
        return uint256(x);
    }

    function to56(uint32 x) internal pure returns (uint56) {
        return uint56(x);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title See SafeCast.sol.
 */
library SafeCastU56 {
    error OverflowUint56ToInt56();

    function toInt(uint56 x) internal pure returns (int56) {
        // -------------------------------o=========>----------------------
        // ----------------------<========o========>x----------------------
        if (x > uint56(type(int56).max)) {
            revert OverflowUint56ToInt56();
        }

        return int56(x);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title See SafeCast.sol.
 */
library SafeCastU64 {
    error OverflowUint64ToInt64();

    function toInt(uint64 x) internal pure returns (int64) {
        // -------------------------------o=========>----------------------
        // ----------------------<========o========>x----------------------
        if (x > uint64(type(int64).max)) {
            revert OverflowUint64ToInt64();
        }

        return int64(x);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import "./SafeCast.sol";

library SetUtil {
    using SafeCastAddress for address;
    using SafeCastBytes32 for bytes32;
    using SafeCastU256 for uint256;

    // ----------------------------------------
    // Uint support
    // ----------------------------------------

    struct UintSet {
        Bytes32Set raw;
    }

    function add(UintSet storage set, uint value) internal {
        add(set.raw, value.toBytes32());
    }

    function remove(UintSet storage set, uint value) internal {
        remove(set.raw, value.toBytes32());
    }

    function replace(UintSet storage set, uint value, uint newValue) internal {
        replace(set.raw, value.toBytes32(), newValue.toBytes32());
    }

    function contains(UintSet storage set, uint value) internal view returns (bool) {
        return contains(set.raw, value.toBytes32());
    }

    function length(UintSet storage set) internal view returns (uint) {
        return length(set.raw);
    }

    function valueAt(UintSet storage set, uint position) internal view returns (uint) {
        return valueAt(set.raw, position).toUint();
    }

    function positionOf(UintSet storage set, uint value) internal view returns (uint) {
        return positionOf(set.raw, value.toBytes32());
    }

    function values(UintSet storage set) internal view returns (uint[] memory) {
        bytes32[] memory store = values(set.raw);
        uint[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // ----------------------------------------
    // Address support
    // ----------------------------------------

    struct AddressSet {
        Bytes32Set raw;
    }

    function add(AddressSet storage set, address value) internal {
        add(set.raw, value.toBytes32());
    }

    function remove(AddressSet storage set, address value) internal {
        remove(set.raw, value.toBytes32());
    }

    function replace(AddressSet storage set, address value, address newValue) internal {
        replace(set.raw, value.toBytes32(), newValue.toBytes32());
    }

    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return contains(set.raw, value.toBytes32());
    }

    function length(AddressSet storage set) internal view returns (uint) {
        return length(set.raw);
    }

    function valueAt(AddressSet storage set, uint position) internal view returns (address) {
        return valueAt(set.raw, position).toAddress();
    }

    function positionOf(AddressSet storage set, address value) internal view returns (uint) {
        return positionOf(set.raw, value.toBytes32());
    }

    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = values(set.raw);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // ----------------------------------------
    // Core bytes32 support
    // ----------------------------------------

    error PositionOutOfBounds();
    error ValueNotInSet();
    error ValueAlreadyInSet();

    struct Bytes32Set {
        bytes32[] _values;
        mapping(bytes32 => uint) _positions; // Position zero is never used.
    }

    function add(Bytes32Set storage set, bytes32 value) internal {
        if (contains(set, value)) {
            revert ValueAlreadyInSet();
        }

        set._values.push(value);
        set._positions[value] = set._values.length;
    }

    function remove(Bytes32Set storage set, bytes32 value) internal {
        uint position = set._positions[value];
        if (position == 0) {
            revert ValueNotInSet();
        }

        uint index = position - 1;
        uint lastIndex = set._values.length - 1;

        // If the element being deleted is not the last in the values,
        // move the last element to its position.
        if (index != lastIndex) {
            bytes32 lastValue = set._values[lastIndex];

            set._values[index] = lastValue;
            set._positions[lastValue] = position;
        }

        // Remove the last element in the values.
        set._values.pop();
        delete set._positions[value];
    }

    function replace(Bytes32Set storage set, bytes32 value, bytes32 newValue) internal {
        if (!contains(set, value)) {
            revert ValueNotInSet();
        }

        if (contains(set, newValue)) {
            revert ValueAlreadyInSet();
        }

        uint position = set._positions[value];
        delete set._positions[value];

        uint index = position - 1;

        set._values[index] = newValue;
        set._positions[newValue] = position;
    }

    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return set._positions[value] != 0;
    }

    function length(Bytes32Set storage set) internal view returns (uint) {
        return set._values.length;
    }

    function valueAt(Bytes32Set storage set, uint position) internal view returns (bytes32) {
        if (position == 0 || position > set._values.length) {
            revert PositionOutOfBounds();
        }

        uint index = position - 1;

        return set._values[index];
    }

    function positionOf(Bytes32Set storage set, bytes32 value) internal view returns (uint) {
        if (!contains(set, value)) {
            revert ValueNotInSet();
        }

        return set._positions[value];
    }

    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return set._values;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import "@synthetixio/core-contracts/contracts/interfaces/IERC721Enumerable.sol";

/**
 * @title Module wrapping an ERC721 token implementation.
 */
interface INftModule is IERC721Enumerable {
    /**
     * @notice Returns whether the token has been initialized.
     * @return A boolean with the result of the query.
     */
    function isInitialized() external returns (bool);

    /**
     * @notice Initializes the token with name, symbol, and uri.
     */
    function initialize(
        string memory tokenName,
        string memory tokenSymbol,
        string memory uri
    ) external;

    /**
     * @notice Allows the owner to mint tokens.
     * @param to The address to receive the newly minted tokens.
     * @param tokenId The ID of the newly minted token
     */
    function mint(address to, uint tokenId) external;

    /**
     * @notice Allows the owner to mint tokens. Verifies that the receiver can receive the token
     * @param to The address to receive the newly minted token.
     * @param tokenId The ID of the newly minted token
     * @param data any data which should be sent to the receiver
     */
    function safeMint(address to, uint256 tokenId, bytes memory data) external;

    /**
     * @notice Allows the owner to burn tokens.
     * @param tokenId The token to burn
     */
    function burn(uint tokenId) external;

    /**
     * @notice Allows an address that holds tokens to provide allowance to another.
     * @param tokenId The token which should be allowed to spender
     * @param spender The address that is given allowance.
     */
    function setAllowance(uint tokenId, address spender) external;

    /**
     * @notice Allows the owner to update the base token URI.
     * @param uri The new base token uri
     */
    function setBaseTokenURI(string memory uri) external;
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import "@synthetixio/core-contracts/contracts/interfaces/IERC20.sol";

/**
 * @title Module wrapping an ERC20 token implementation.
 */
interface ITokenModule is IERC20 {
    /**
     * @notice Returns wether the token has been initialized.
     * @return A boolean with the result of the query.
     */
    function isInitialized() external returns (bool);

    /**
     * @notice Initializes the token with name, symbol, and decimals.
     */
    function initialize(
        string memory tokenName,
        string memory tokenSymbol,
        uint8 tokenDecimals
    ) external;

    /**
     * @notice Allows the owner to mint tokens.
     * @param to The address to receive the newly minted tokens.
     * @param amount The amount of tokens to mint.
     */
    function mint(address to, uint amount) external;

    /**
     * @notice Allows the owner to burn tokens.
     * @param from The address whose tokens will be burnt.
     * @param amount The amount of tokens to burn.
     */
    function burn(address from, uint amount) external;

    /**
     * @notice Allows an address that holds tokens to provide allowance to another.
     * @param from The address that is providing allowance.
     * @param spender The address that is given allowance.
     * @param amount The amount of allowance being given.
     */
    function setAllowance(address from, address spender, uint amount) external;
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import "../interfaces/ITokenModule.sol";
import "../interfaces/INftModule.sol";

library AssociatedSystem {
    struct Data {
        address proxy;
        address impl;
        bytes32 kind;
    }

    error MismatchAssociatedSystemKind(bytes32 expected, bytes32 actual);

    bytes32 public constant KIND_ERC20 = "erc20";
    bytes32 public constant KIND_ERC721 = "erc721";
    bytes32 public constant KIND_UNMANAGED = "unmanaged";

    function load(bytes32 id) internal pure returns (Data storage store) {
        bytes32 s = keccak256(abi.encode("io.synthetix.core-modules.AssociatedSystem", id));
        assembly {
            store.slot := s
        }
    }

    function getAddress(Data storage self) internal view returns (address) {
        return self.proxy;
    }

    function asToken(Data storage self) internal view returns (ITokenModule) {
        expectKind(self, KIND_ERC20);
        return ITokenModule(self.proxy);
    }

    function asNft(Data storage self) internal view returns (INftModule) {
        expectKind(self, KIND_ERC721);
        return INftModule(self.proxy);
    }

    function set(Data storage self, address proxy, address impl, bytes32 kind) internal {
        self.proxy = proxy;
        self.impl = impl;
        self.kind = kind;
    }

    function expectKind(Data storage self, bytes32 kind) internal view {
        bytes32 actualKind = self.kind;

        if (actualKind != kind && actualKind != KIND_UNMANAGED) {
            revert MismatchAssociatedSystemKind(kind, actualKind);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**
 * @title Balances related errors.
 */
library BalanceErrors {
    /**
     * @notice Error when a profile doesn't have enough balance to withdraw.
     *
     * Cases:
     * - `FundsModule.withdrawFunds()`
     *
     */
    error InsufficientBalance();

    /**
     * @notice Error when a profile want to subscribe or withdraw but will get insolvent.
     *
     * Cases:
     * - `FundsModule.withdrawFunds()`
     * - `SubscriptionsModule.subscribe()`
     *
     */
    error InsolventUser();

    /**
     * @notice Error when wanting to liquidate a profile subscription but is not liquidable.
     *
     * Cases:
     * - `LiquidationsModule.liquidate()`
     *
     */
    error SolventUser();
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**
 * @title Input related errors.
 */
library InputErrors {
    /**
     * @notice Error when an input has unexpected zero uint256.
     *
     * Cases:
     * - `FundsModule.depositunds()`
     * - `FundsModule.withdrawFunds()`
     *
     */
    error ZeroAmount();

    /**
     * @notice Error when an input has unexpected zero address.
     *
     * Cases:
     * - `ProfilesModule.allowProfile()`
     * - `ProfilesModule.disallowProfile()`
     * - `VaultsModule.addVault()`
     *
     */
    error ZeroAddress();

    /**
     * @notice Error when an input has unexpected zero bytes32 ID.
     *
     * Cases:
     * - `FeesModule.initializeFeesModule()`
     * - `FeesModule.setGratefulFeeTreasury()`
     * - `VaultsModule.addVault()`
     *
     */
    error ZeroId();

    /**
     * @notice Error when an input has unexpected zero uint for time.
     *
     * Cases:
     * - `ConfigModule.initializeConfigModule()`
     * - `ConfigModule.setSolvencyTimeRequired()`
     * - `ConfigModule.setLiquidationTimeRequired()`
     *
     */
    error ZeroTime();

    /**
     * @notice Error when trying to initialize a module that has already been.
     *
     * Cases:
     * - `ConfigModule.initializeConfigModule()`
     * - `FeesModule.initializeFeesModule()`
     * - `VaultModule.addVault()`
     *
     */
    error AlreadyInitialized();
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**
 * @title Profile related errors.
 */
library ProfileErrors {
    /**
     * @notice Thrown when a profile attempts to renounce a permission that it didn't have.
     *
     * Cases:
     * - `ProfilesModules.renouncePermission()`
     *
     */
    error PermissionNotGranted();

    /**
     * @dev Thrown when the given target address does not have the given permission with the given profile.
     *
     * Thrown in:
     * - `Profile.loadProfileAndValidatePermission()`
     *
     * Cases:
     * - `FundsModule.withdrawFunds()`
     * - `SubscriptionsModule.subscribe()`
     * - `SubscriptionsModule.unsubscribe()`
     *
     */
    error PermissionDenied();

    /**
     * @dev Thrown when a profile cannot be found.
     *
     * Thrown in:
     * - `Profile.exists()`
     *
     * Cases:
     * - `FundsModule.depositFunds()`
     * - `SubscriptionsModule.subscribe()`
     * - `SubscriptionsModule.unsubscribe()`
     *
     */
    error ProfileNotFound();

    /**
     * @dev Thrown when a permission specified by a user does not exist or is invalid.
     *
     * Cases:
     *  - `ProfilesModules.grantPermission()`
     *
     */
    error InvalidPermission();

    /**
     * @notice Thrown when the profile interacting with the system is expected to be the associated profile token, but is not.
     *
     * Cases:
     * - `ProfilesModules.notifyProfileTransfer()`
     *
     */
    error OnlyGratefulProfileProxy();

    /**
     * @notice Thrown when trying to create a profile with a salt that was already used.
     *
     * Cases:
     * - `ProfilesModules.createProfile()`
     *
     */
    error ProfileAlreadyCreated();
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**
 * @title Subscriptions related errors.
 */
library SubscriptionErrors {
    /**
     * @notice Error when providing a creator that is similar to the giver or the treasury ID.
     *
     * Cases:
     * - `LiquidationsModule.liquidate()`
     * - `SubscriptionsModule.subscribe()`
     * - `SubscriptionsModule.unsubscribe()`
     *
     */
    error InvalidCreator();

    /**
     * @notice Error when providing a subscription rate that is not valid for the selected vault.
     *
     * Cases:
     * - `SubscriptionsModule.subscribe()`
     *
     */
    error InvalidRate();

    /**
     * @notice Error when trying to subscribe to a creator that already has an open subscription from the giver.
     *
     * Cases:
     * - `SubscriptionsModule.subscribe()`
     *
     */
    error AlreadySubscribed();

    /**
     * @notice Error when trying to unsubscribe from a creator that not has an open subscription from the giver.
     *
     * Cases:
     * - `LiquidationsModule.liquidate()`
     * - `SubscriptionsModule.unsubscribe()`
     *
     */
    error NotSubscribed();
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**
 * @title Vault related errors.
 */
library VaultErrors {
    /**
     * @notice Error when trying to change a vault that has not been initialized.
     *
     * Cases:
     * - `VaultsModule._validateVaultPermissions()`
     *
     */
    error VaultNotInitialized();

    /**
     * @notice Error when trying to use a vault that is not active (not initialized or paused).
     *
     * Cases:
     * - `FundsModule.depositFunds()`
     * - `FundsModule.withdrawFunds()`
     * - `SubscriptionModule.subscribe()`
     *
     */
    error InvalidVault();

    /**
     * @notice Error when trying to deposit into a vault but the user has not allow the token to the system.
     *
     * Cases:
     * - `FundsModule.depositFunds()`
     *
     */
    error InsufficientAllowance();
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**
 * @title Module with ERC721 logic for the grateful subscription.
 */
interface IGratefulSubscription {
    /**************************************************************************
     * Governance functions
     *************************************************************************/

    /**
     * @notice Initialize the NFT
     * @dev Only owner / Token must not be initialized
     * @param tokenName The NFT token name
     * @param tokenSymbol The NFT token symbol
     * @param uri The NFT uri
     */
    function initialize(
        string memory tokenName,
        string memory tokenSymbol,
        string memory uri
    ) external;

    /**
     * @notice Mint token to user and increment counter
     * @dev Only owner / Token must be initialized
     * @param to Address to mint the NFT
     */
    function mint(address to) external;

    /**************************************************************************
     * View functions
     *************************************************************************/

    /**
     * @notice Get the current subscriptions token ID
     * @return The current token ID
     */
    function getCurrentTokenId() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Subscription} from "../storage/Subscription.sol";

/**
 * @title Module for starting and finishing subscription.
 */
interface ISubscriptionsModule {
    /**************************************************************************
     * User functions
     *************************************************************************/

    /**
     * @notice Start subscription from giver to creator.
     *
     * Requirements:
     *
     * - Only profiles NFTs allowed on the system
     * - Sender must have subscribe role authorized
     * - Only existing creator profile ID
     * - Giver and creator cannot be the same
     * - Creator cannot be Grateful treasury
     * - Giver cannot be already subscribed to creator
     * - Only vaults initialized into the system
     * - Rate must be valid (between min and max vault rate)
     * - Subscription NFT will be minted to current giver profile owner
     * - Giver profile ID must have enough vault balance to start a subscription
     * - Giver profile ID must have enough vault balance to remain solvent for `solvencyTimeRequired` after subscription starts
     * - Emits a `SubscriptionStarted` event
     *
     * @param giverId The giver profile ID
     * @param creatorId The creator profile ID
     * @param vaultId The vault ID from where start the subscription
     * @param subscriptionRate The subscription rate from giver balance to creator balance (1e-20/second)
     *
     */
    function subscribe(
        bytes32 giverId,
        bytes32 creatorId,
        bytes32 vaultId,
        uint256 subscriptionRate
    ) external;

    /**
     * @notice End subscription from giver to creator.
     *
     * Requirements:
     *
     * - Only profiles NFTs allowed on the system
     * - Sender must have unsubscribe role authorized
     * - Only existing creator profile ID
     * - Giver and creator cannot be the same
     * - Creator cannot be Grateful treasury
     * - Giver must be subscribed to creator
     * - Emits `SubscriptionFinished` event
     *
     * @param giverId The giver profile ID
     * @param creatorId The creator profile ID
     */
    function unsubscribe(bytes32 giverId, bytes32 creatorId) external;

    /**************************************************************************
     * View functions
     *************************************************************************/

    /**
     * @notice Return subscription data from a subscription ID
     * @dev The subscription ID is a token ID from the Grateful Subcription NFT
     * @param subscriptionId The ID from where return the subscription data
     * @return subscription The subscription struct data
     */
    function getSubscription(
        uint256 subscriptionId
    ) external pure returns (Subscription.Data memory subscription);

    /**
     * @notice Return subscription data from giver and creator IDs
     * @param giverId The ID from where the subscription was created
     * @param creatorId The ID from whom is receiving the subscription
     * @return subscription The subscription struct data
     */
    function getSubscriptionFrom(
        bytes32 giverId,
        bytes32 creatorId
    ) external view returns (Subscription.Data memory subscription);

    /**
     * @notice Return the subscription ID from giver and creator IDs
     * @param giverId The ID from where the subscription was created
     * @param creatorId The ID from whom is receiving the subscription
     * @return The subscription ID
     */
    function getSubscriptionId(
        bytes32 giverId,
        bytes32 creatorId
    ) external view returns (uint256);

    /**
     * @notice Return the subscription and fee rates from a subscription ID
     * @param subscriptionId The ID from where return the subscription data
     * @return Subscription rate and fee rate
     */
    function getSubscriptionRates(
        uint256 subscriptionId
    ) external view returns (uint256, uint256);

    /**
     * @notice Return if a subscription is active from giver to creator
     * @param giverId The ID from where the subscription was created
     * @param creatorId The ID from whom is receiving the subscription
     * @return Subscribed flag
     */
    function isSubscribed(
        bytes32 giverId,
        bytes32 creatorId
    ) external view returns (bool);

    /**
     * @notice Return the total subscription duration since it was created
     * @param subscriptionId The ID from where return the subscription data
     * @return The current duration
     */
    function getSubscriptionDuration(
        uint256 subscriptionId
    ) external view returns (uint256);

    /**************************************************************************
     * Events
     *************************************************************************/

    /**
     * @notice Emits the data from the started subscription
     * @param giverId The ID from the profile starting the subscription
     * @param creatorId The ID from the profile receiving the subscription
     * @param vaultId The vault using in the subscription
     * @param subscriptionId The subscription ID from the Grateful Subscription NFT
     * @param rate The subscription rate going to the creator (1e-20/second)
     * @param feeRate The fee rate going to the treasury (1e-20/second)
     */
    event SubscriptionStarted(
        bytes32 indexed giverId,
        bytes32 indexed creatorId,
        bytes32 indexed vaultId,
        uint256 subscriptionId,
        uint256 rate,
        uint256 feeRate
    );

    // Note: Duplicated event until library events are exportable (https://github.com/ethereum/solidity/pull/10996)
    /**
     * @notice Emits the data from the finished subscription
     * @param giverId The ID from the profile that was subscribed
     * @param creatorId The ID from the profile that was receiving the subscription
     * @param vaultId The vault being used in the subscription
     * @param subscriptionId The subscription ID from the Grateful Subscription NFT
     * @param rate The subscription rate that was going to the creator (1e-20/second)
     * @param feeRate The fee rate that was going to the treasury (1e-20/second)
     */
    event SubscriptionFinished(
        bytes32 indexed giverId,
        bytes32 indexed creatorId,
        bytes32 indexed vaultId,
        uint256 subscriptionId,
        uint256 rate,
        uint256 feeRate
    );
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {ISubscriptionsModule} from "../interfaces/ISubscriptionsModule.sol";
import {SubscriptionUtil} from "../utils/SubscriptionUtil.sol";
import {VaultUtil} from "../utils/VaultUtil.sol";
import {SubscriptionErrors} from "../errors/SubscriptionErrors.sol";
import {VaultErrors} from "../errors/VaultErrors.sol";
import {BalanceErrors} from "../errors/BalanceErrors.sol";
import {Balance} from "../storage/Balance.sol";
import {Subscription} from "../storage/Subscription.sol";
import {SubscriptionRegistry} from "../storage/SubscriptionRegistry.sol";
import {Profile} from "../storage/Profile.sol";
import {ProfileRBAC} from "../storage/ProfileRBAC.sol";

/**
 * @title Module for starting and finishing subscriptions.
 * @dev See ISubscriptionsModule.
 */
contract SubscriptionsModule is ISubscriptionsModule {
    using Balance for Balance.Data;
    using Subscription for Subscription.Data;
    using SubscriptionRegistry for SubscriptionRegistry.Data;
    using Profile for Profile.Data;

    /// @inheritdoc ISubscriptionsModule
    function subscribe(
        bytes32 giverId,
        bytes32 creatorId,
        bytes32 vaultId,
        uint256 subscriptionRate
    ) external {
        if (!VaultUtil.isVaultActive(vaultId))
            revert VaultErrors.InvalidVault();

        Profile.Data storage profile = Profile.loadProfileAndValidatePermission(
            giverId,
            ProfileRBAC._SUBSCRIBE_PERMISSION
        );

        address owner = profile.rbac.owner;

        Profile.exists(creatorId);

        SubscriptionUtil.validateCreator(giverId, creatorId);

        if (SubscriptionRegistry.load(giverId, creatorId).isSubscribed())
            revert SubscriptionErrors.AlreadySubscribed();

        if (!VaultUtil.isRateValid(vaultId, subscriptionRate))
            revert SubscriptionErrors.InvalidRate();

        uint256 rate = VaultUtil.getCurrentRate(vaultId, subscriptionRate);

        (uint256 subscriptionId, uint256 feeRate, ) = SubscriptionUtil
            .startSubscription(giverId, creatorId, vaultId, rate, owner);

        if (!Balance.load(giverId, vaultId).canStartSubscription())
            revert BalanceErrors.InsolventUser();

        emit SubscriptionStarted(
            giverId,
            creatorId,
            vaultId,
            subscriptionId,
            rate,
            feeRate
        );
    }

    /// @inheritdoc ISubscriptionsModule
    function unsubscribe(bytes32 giverId, bytes32 creatorId) external {
        Profile.loadProfileAndValidatePermission(
            giverId,
            ProfileRBAC._UNSUBSCRIBE_PERMISSION
        );

        Profile.exists(creatorId);

        SubscriptionUtil.validateCreator(giverId, creatorId);

        if (!SubscriptionRegistry.load(giverId, creatorId).isSubscribed())
            revert SubscriptionErrors.NotSubscribed();

        SubscriptionUtil.finishSubscription(giverId, creatorId);
    }

    /// @inheritdoc ISubscriptionsModule
    function getSubscription(
        uint256 subscriptionId
    ) external pure override returns (Subscription.Data memory subscription) {
        return Subscription.load(subscriptionId);
    }

    /// @inheritdoc ISubscriptionsModule
    function getSubscriptionFrom(
        bytes32 giverId,
        bytes32 creatorId
    ) external view override returns (Subscription.Data memory subscription) {
        return
            SubscriptionRegistry.load(giverId, creatorId).getSubscriptionData();
    }

    /// @inheritdoc ISubscriptionsModule
    function getSubscriptionId(
        bytes32 giverId,
        bytes32 creatorId
    ) external view override returns (uint256) {
        return SubscriptionRegistry.load(giverId, creatorId).subscriptionId;
    }

    /// @inheritdoc ISubscriptionsModule
    function getSubscriptionRates(
        uint256 subscriptionId
    ) external view override returns (uint256, uint256) {
        return (
            Subscription.load(subscriptionId).rate,
            Subscription.load(subscriptionId).feeRate
        );
    }

    /// @inheritdoc ISubscriptionsModule
    function isSubscribed(
        bytes32 giverId,
        bytes32 creatorId
    ) external view override returns (bool) {
        return SubscriptionRegistry.load(giverId, creatorId).isSubscribed();
    }

    /// @inheritdoc ISubscriptionsModule
    function getSubscriptionDuration(
        uint256 subscriptionId
    ) external view override returns (uint256) {
        return Subscription.load(subscriptionId).getDuration();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {Config} from "../storage/Config.sol";

/**
 * @title Stores the balance and flow for a profile ID and vault ID tuple.
 *
 * Each profile has a different balance for each vault.
 */
library Balance {
    using SafeCast for uint256;
    using Config for Config.Data;

    struct Data {
        /**
         * @dev Amount of settled balance.
         *
         * Vault balance is normalized to 20 decimals.
         *
         * This can be increase or decrease during depositing or withdrawing funds,
         * or also after settling the elapsed time due to a flow change.
         *
         * The system accepts negative balances if the subscriptions were not liquidated at time.
         */
        int256 balance;
        /**
         * @dev Current balance incoming flow.
         *
         * Flow unit is 1e-20 per second.
         *
         * This reperesents the amount of balance that is increasing each second.
         */
        uint104 inflow;
        /**
         * @dev Current balance outgoing flow.
         *
         * Flow unit is 1e-20 per second.
         *
         * This reperesents the amount of balance that is decreasing each second.
         */
        uint104 outflow;
        /**
         * @dev Last time balance was updated.
         *
         * This is used to calculate the current balance.
         */
        uint48 lastUpdate;
    }

    /**
     * @dev Loads the balance for the profile/vault tuple.
     */
    function load(
        bytes32 profileId,
        bytes32 vaultId
    ) internal pure returns (Data storage store) {
        bytes32 s = keccak256(abi.encode("Balance", profileId, vaultId));
        assembly {
            store.slot := s
        }
    }

    /**
     * @dev Increases the settled balance by `amount`.
     */
    function increase(Data storage self, uint256 amount) internal {
        self.balance += amount.toInt256();
    }

    /**
     * @dev Decreases the settled balance by `amount`.
     */
    function decrease(Data storage self, uint256 amount) internal {
        self.balance -= amount.toInt256();
    }

    /**
     * @dev Calculates the current balance, stores it and returns it.
     */
    function settle(Data storage self) internal returns (int256 newBalance) {
        newBalance = balanceOf(self);

        self.balance = newBalance;
        self.lastUpdate = (block.timestamp).toUint48();
    }

    /**
     * @dev Increases the current inflow by `amount`.
     */
    function increaseInflow(Data storage self, uint256 amount) internal {
        settle(self);

        self.inflow += amount.toUint104();
    }

    /**
     * @dev Increases the current outflow by `amount`.
     */
    function increaseOutflow(Data storage self, uint256 amount) internal {
        settle(self);

        self.outflow += amount.toUint104();
    }

    /**
     * @dev Decreases the current inflow by `amount`.
     */
    function decreaseInflow(Data storage self, uint256 amount) internal {
        settle(self);

        self.inflow -= amount.toUint104();
    }

    /**
     * @dev Decreases the current outflow by `amount`.
     */
    function decreaseOutflow(Data storage self, uint256 amount) internal {
        settle(self);

        self.outflow -= amount.toUint104();
    }

    /**
     * @dev Calculate the current total flow.
     *
     * This means the inflow minus the outflow. It could be negative.
     */
    function getFlow(Data storage self) internal view returns (int256) {
        int256 totalInflow = (uint256(self.inflow)).toInt256();
        int256 totalOutflow = (uint256(self.outflow)).toInt256();
        return totalInflow - totalOutflow;
    }

    /**
     * @dev Returns the current balance since last update.
     */
    function balanceOf(
        Data storage self
    ) internal view returns (int256 balance) {
        uint256 elapsedTime = _getElapsedTime(self.lastUpdate);

        balance = _calculateBalance(
            self.balance,
            self.inflow,
            self.outflow,
            elapsedTime
        );
    }

    /**
     * @dev Returns the elapsed time since `lastUpdate`.
     */
    function _getElapsedTime(
        uint256 lastUpdate
    ) private view returns (uint256 elapsedTime) {
        if (lastUpdate == 0) return 0;
        if (block.timestamp <= lastUpdate) return 0;
        elapsedTime = block.timestamp - lastUpdate;
    }

    /**
     * @dev Calculates the current balance: `balance` + (`inflow` * `time`) - (`outflow` * `time`)
     */
    function _calculateBalance(
        int256 balance,
        uint256 inflow,
        uint256 outflow,
        uint256 time
    ) private pure returns (int256 currentBalance) {
        int256 totalInflow = (inflow * time).toInt256();
        int256 totalOutflow = (outflow * time).toInt256();
        int256 totalFlow = totalInflow - totalOutflow;

        currentBalance = balance + totalFlow;
    }

    /**
     * @dev Returns if the balance is solvent for a given `time`.
     *
     * It adds the input time to the current elapsed time to calculate if the balance is positive in a future time.
     */
    function _isSolvent(
        Data storage self,
        uint256 time
    ) private view returns (bool) {
        uint256 futureElapsedTime = _getElapsedTime(self.lastUpdate) + time;

        return
            _calculateBalance(
                self.balance,
                self.inflow,
                self.outflow,
                futureElapsedTime
            ) > 0;
    }

    /**
     * @dev Returns if the balance is greater or equal to the required balance.
     *
     * The required balance is the balance needed to cover the `time` of outflow.
     */
    function _hasEnoughBalance(
        Data storage self,
        uint256 time
    ) private view returns (bool) {
        int256 balance = balanceOf(self);
        int256 requiredBalance = (self.outflow * time).toInt256();
        return balance >= requiredBalance;
    }

    /**
     * @dev Returns if the profile with the current balance can make a withdrawal.
     *
     * To make a withdrawal the current balance must cover the required time of flow
     * and also must be solvent for that lapse.
     *
     * Uses the solvency time required from the system to evaluate the solvency.
     */
    function canWithdraw(Data storage self) internal view returns (bool) {
        uint256 time = Config.load().solvencyTimeRequired;
        return _hasEnoughBalance(self, time) && _isSolvent(self, time);
    }

    /**
     * @dev Returns if the profile with the current balance can make a new subscription.
     *
     * To make a new subscription the current balance must cover the required time of flow
     * and also must be solvent for that lapse.
     *
     * Uses the solvency time required from the system to evaluate the solvency.
     */
    function canStartSubscription(
        Data storage self
    ) internal view returns (bool) {
        uint256 time = Config.load().solvencyTimeRequired;
        return _hasEnoughBalance(self, time) && _isSolvent(self, time);
    }

    /**
     * @dev Returns if the profile with the current balance can be liquidated.
     *
     * To be liquidated the balance must have negative flow and also not be solvent
     * for the required time.
     *
     * Uses the liquidation time required from the system to evaluate the solvency.
     */
    function canBeLiquidated(Data storage self) internal view returns (bool) {
        uint256 time = Config.load().liquidationTimeRequired;
        bool hasNegativeFlow = self.outflow > self.inflow;
        return hasNegativeFlow && !_isSolvent(self, time);
    }

    /**
     * @dev Returns if the balance is negative
     */
    function isNegative(Data storage self) internal view returns (bool) {
        int256 balance = balanceOf(self);
        return balance < 0;
    }

    /**
     * @dev Returns the remaining time to zero balance.
     *
     * If the flow is positive (or zero) or the balance is already negative (or zero), the time is zero.
     *
     * remainingTime = currentBalance / flow
     */
    function remainingTimeToZero(
        Data storage self
    ) internal view returns (uint256) {
        int256 balance = balanceOf(self);
        uint256 inflow = self.inflow;
        uint256 outflow = self.outflow;

        if (inflow >= outflow || balance <= 0) {
            return 0;
        } else {
            return uint256(balance) / (outflow - inflow);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**
 * @title Stores the system configuration.
 */
library Config {
    bytes32 private constant _CONFIG_STORAGE_SLOT =
        keccak256(abi.encode("Config"));

    struct Data {
        /**
         * @dev Time required to remain solvent.
         *
         * This is used to know if a profile is allow to open new subscriptions or making withdrawals.
         *
         * If the profile balance does not cover this future time, it is insolvent.
         */
        uint256 solvencyTimeRequired;
        /**
         * @dev Time required to allow making liquidations.
         *
         * This is used to know if a profile is in a liquidation period.
         *
         * If the profile balance does not cover this future time, it can be liquidated.
         */
        uint256 liquidationTimeRequired;
    }

    /**
     * @dev Loads the singleton storage info about the system.
     */
    function load() internal pure returns (Data storage store) {
        bytes32 s = _CONFIG_STORAGE_SLOT;
        assembly {
            store.slot := s
        }
    }

    /**
     * @dev Sets the system solvency time.
     */
    function setSolvencyTimeRequired(
        Data storage self,
        uint256 solvencyTime
    ) internal {
        self.solvencyTimeRequired = solvencyTime;
    }

    /**
     * @dev Sets the system liquidation time.
     */
    function setLiquidationTimeRequired(
        Data storage self,
        uint256 liquidationTime
    ) internal {
        self.liquidationTimeRequired = liquidationTime;
    }

    /**
     * @dev Returns if the config storage is initialized.
     */
    function isInitialized(Data storage self) internal view returns (bool) {
        return self.liquidationTimeRequired != 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

/**
 * @title Stores the system fees configuration.
 *
 * There can only be one fee treasury.
 */
library Fee {
    using Math for uint256;

    bytes32 private constant _FEE_STORAGE_SLOT = keccak256(abi.encode("Fee"));

    struct Data {
        /**
         * @dev Treasury ID where to receive the fees.
         *
         * The treasury must be a grateful profile because the fees are treated like a subscription.
         */
        bytes32 gratefulFeeTreasury;
        /**
         * @dev Fee percentage to be taken from a subscription rate.
         *
         * Can be zero if wanted.
         */
        uint256 feePercentage;
    }

    /**
     * @dev Loads the singleton storage info about the fees.
     */
    function load() internal pure returns (Data storage store) {
        bytes32 s = _FEE_STORAGE_SLOT;
        assembly {
            store.slot := s
        }
    }

    /**
     * @dev Sets the grateful fee treasury where fees are collected.
     */
    function setGratefulFeeTreasury(
        Data storage self,
        bytes32 gratefulFeeTreasury
    ) internal {
        self.gratefulFeeTreasury = gratefulFeeTreasury;
    }

    /**
     * @dev Sets the fee percentage taken from the rate subscription.
     */
    function setFeePercentage(
        Data storage self,
        uint256 feePercentage
    ) internal {
        self.feePercentage = feePercentage;
    }

    /**
     * @dev Returns if the fee storage is initialized.
     */
    function isInitialized(Data storage self) internal view returns (bool) {
        return self.gratefulFeeTreasury != bytes32(0);
    }

    /**
     * @dev Returns the fee rate from a subscription rate.
     *
     * The fee rate is calculated as a percentage from the `subscriptionRate`.
     *
     * feeRate = (subscriptionRate * feePercentage) / 100
     */
    function getFeeRate(
        Data storage self,
        uint256 subscriptionRate
    ) internal view returns (uint256) {
        return subscriptionRate.mulDiv(self.feePercentage, 100);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {ProfileRBAC} from "./ProfileRBAC.sol";
import {ProfileErrors} from "../errors/ProfileErrors.sol";

/**
 * @title Object for tracking profiles with access control.
 */
library Profile {
    using ProfileRBAC for ProfileRBAC.Data;

    struct Data {
        /**
         * @dev Role based access control data for the profile.
         */
        ProfileRBAC.Data rbac;
    }

    /**
     * @dev Returns the profile stored at the specified profile ID.
     */
    function load(
        bytes32 profileId
    ) internal pure returns (Data storage store) {
        bytes32 s = keccak256(abi.encode("Profile", profileId));
        assembly {
            store.slot := s
        }
    }

    /**
     * @dev Creates a profile for the given profileId, and associates it to the given owner.
     *
     * Note: Will not fail if the profile already exists, and if so, will overwrite the existing owner.
     * Whatever calls this internal function must first check that the profile doesn't exist before re-creating it.
     */
    function create(
        bytes32 profileId,
        address owner
    ) internal returns (Data storage profile) {
        profile = load(profileId);

        profile.rbac.owner = owner;
    }

    /**
     * @dev Reverts if the profile does not exist with appropriate error.
     */
    function exists(bytes32 profileId) internal view {
        if (load(profileId).rbac.owner == address(0)) {
            revert ProfileErrors.ProfileNotFound();
        }
    }

    /**
     * @dev Reverts if the profile exists with appropriate error.
     */
    function notExists(bytes32 profileId) internal view {
        if (load(profileId).rbac.owner != address(0)) {
            revert ProfileErrors.ProfileAlreadyCreated();
        }
    }

    /**
     * @dev Loads the Profile object for the specified profileId,
     * and validates that sender has the specified permission. These
     * are different actions but they are merged in a single function
     * because loading a profile and checking for a permission is a very
     * common use case in other parts of the code.
     */
    function loadProfileAndValidatePermission(
        bytes32 profileId,
        bytes32 permission
    ) internal view returns (Data storage profile) {
        profile = load(profileId);

        if (!profile.rbac.authorized(permission, msg.sender)) {
            revert ProfileErrors.PermissionDenied();
        }
    }

    /**
     * @dev Returns a profile ID.
     *
     * It is the hash from the profile NFT owner address and a salt.
     *
     * It must be unique for the system.
     */
    function getProfileId(
        address owner,
        bytes32 salt
    ) internal pure returns (bytes32 profileId) {
        profileId = keccak256(abi.encode(owner, salt));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {SetUtil} from "@synthetixio/core-contracts/contracts/utils/SetUtil.sol";
import {ProfileErrors} from "../errors/ProfileErrors.sol";
import {InputErrors} from "../errors/InputErrors.sol";

/**
 * @title Object for tracking an profiles permissions (role based access control).
 */
library ProfileRBAC {
    using SetUtil for SetUtil.Bytes32Set;
    using SetUtil for SetUtil.AddressSet;

    /**
     * @dev All permissions used by the system
     * need to be hardcoded here.
     */
    bytes32 internal constant _ADMIN_PERMISSION = "ADMIN";
    bytes32 internal constant _WITHDRAW_PERMISSION = "WITHDRAW";
    bytes32 internal constant _SUBSCRIBE_PERMISSION = "SUBSCRIBE";
    bytes32 internal constant _UNSUBSCRIBE_PERMISSION = "UNSUBSCRIBE";
    bytes32 internal constant _EDIT_PERMISSION = "EDIT";

    struct Data {
        /**
         * @dev The owner of the profile and admin of all permissions.
         */
        address owner;
        /**
         * @dev Set of permissions for each address enabled by the profile.
         */
        mapping(address => SetUtil.Bytes32Set) permissions;
        /**
         * @dev Array of addresses that this profile has given permissions to.
         */
        SetUtil.AddressSet permissionAddresses;
    }

    /**
     * @dev Reverts if the specified permission is unknown to the profile RBAC system.
     */
    function isPermissionValid(bytes32 permission) internal pure {
        if (
            permission != _ADMIN_PERMISSION &&
            permission != _WITHDRAW_PERMISSION &&
            permission != _SUBSCRIBE_PERMISSION &&
            permission != _UNSUBSCRIBE_PERMISSION &&
            permission != _EDIT_PERMISSION
        ) {
            revert ProfileErrors.InvalidPermission();
        }
    }

    /**
     * @dev Sets the owner of the profile.
     */
    function setOwner(Data storage self, address owner) internal {
        self.owner = owner;
    }

    /**
     * @dev Grants a particular permission to the specified target address.
     */
    function grantPermission(
        Data storage self,
        bytes32 permission,
        address target
    ) internal {
        if (target == address(0)) {
            revert InputErrors.ZeroAddress();
        }

        if (!self.permissionAddresses.contains(target)) {
            self.permissionAddresses.add(target);
        }

        self.permissions[target].add(permission);
    }

    /**
     * @dev Revokes a particular permission from the specified target address.
     */
    function revokePermission(
        Data storage self,
        bytes32 permission,
        address target
    ) internal {
        self.permissions[target].remove(permission);

        if (self.permissions[target].length() == 0) {
            self.permissionAddresses.remove(target);
        }
    }

    /**
     * @dev Revokes all permissions for the specified target address.
     * @notice only removes permissions for the given address, not for the entire profile
     */
    function revokeAllPermissions(Data storage self, address target) internal {
        bytes32[] memory permissions = self.permissions[target].values();

        for (uint256 i = 0; i < permissions.length; i++) {
            self.permissions[target].remove(permissions[i]);
        }

        self.permissionAddresses.remove(target);
    }

    /**
     * @dev Returns wether the specified address has the given permission.
     */
    function hasPermission(
        Data storage self,
        bytes32 permission,
        address target
    ) internal view returns (bool) {
        return
            target != address(0) &&
            self.permissions[target].contains(permission);
    }

    /**
     * @dev Returns wether the specified target address has the given permission, or has the high level admin permission.
     */
    function authorized(
        Data storage self,
        bytes32 permission,
        address target
    ) internal view returns (bool) {
        return ((target == self.owner) ||
            hasPermission(self, _ADMIN_PERMISSION, target) ||
            hasPermission(self, permission, target));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";

/**
 * @title Stores the subscription data for each subscription.
 *
 * A subscription ID is a token ID minted in the Grateful subscription NFT.
 *
 * A subscription between a giver and a creator is unique.
 */
library Subscription {
    using SafeCast for uint256;

    struct Data {
        /**
         * @dev The subscription rate being streamed from giver to creator.
         *
         * Rate unit is 1e-20 per second.
         */
        uint96 rate;
        /**
         * @dev The fee rate being streamed from giver to treasury.
         *
         * Fee rate unit is 1e-20 per second.
         */
        uint80 feeRate;
        /**
         * @dev The last time the subscription was updated.
         *
         * This is stored when starting, updating or finishing it.
         */
        uint40 lastUpdate;
        /**
         * @dev The subscription total duration since creation.
         */
        uint40 duration;
        /**
         * @dev The creator ID who is receiving the subscription.
         */
        bytes32 creatorId;
        /**
         * @dev The vault balance that is being used in the subscription.
         */
        bytes32 vaultId;
    }

    /**
     * @dev Loads the subscription data from a subscription ID.
     */
    function load(
        uint256 subscriptionId
    ) internal pure returns (Data storage store) {
        bytes32 s = keccak256(abi.encode("Subscription", subscriptionId));
        assembly {
            store.slot := s
        }
    }

    /**
     * @dev Starts a subscription.
     *
     * This is used the first time a subscription is created.
     */
    function start(
        Data storage self,
        uint256 rate,
        uint256 feeRate,
        bytes32 creatorId,
        bytes32 vaultId
    ) internal {
        self.rate = rate.toUint96();
        self.feeRate = feeRate.toUint80();
        self.lastUpdate = (block.timestamp).toUint40();
        self.creatorId = creatorId;
        self.vaultId = vaultId;
    }

    /**
     * @dev Updates a subscription.
     *
     * This is used if the giver wants to update the rate or the vault being used.
     *
     * Also is called if restarting an already created subscription.
     */
    function update(
        Data storage self,
        uint256 rate,
        uint256 feeRate,
        bytes32 vaultId
    ) internal {
        self.rate = rate.toUint96();
        self.feeRate = feeRate.toUint80();
        self.lastUpdate = (block.timestamp).toUint40();
        self.vaultId = vaultId;
    }

    /**
     * @dev Finishes a subscription.
     *
     * This is used when the giver wants to unsubscribe.
     */
    function finish(Data storage self) internal {
        uint256 elapsedTime = block.timestamp - self.lastUpdate;

        self.rate = 0;
        self.feeRate = 0;
        self.lastUpdate = (block.timestamp).toUint40();
        self.duration += (elapsedTime).toUint40();
    }

    /**
     * @dev Returns if the subscription is active.
     */
    function isSubscribed(Data storage self) internal view returns (bool) {
        return self.rate != 0;
    }

    /**
     * @dev Returns the current subscription duration.
     *
     * It is the stored duration plus the elapsed time since last update.
     */
    function getDuration(
        Data storage self
    ) internal view returns (uint256 duration) {
        uint256 lastUpdate = self.lastUpdate;
        if (lastUpdate == 0) return 0;

        if (isSubscribed(self)) {
            uint256 elapsedTime = block.timestamp - lastUpdate;
            duration = self.duration + (elapsedTime).toUint128();
        } else {
            duration = self.duration;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Subscription} from "./Subscription.sol";

/**
 * @title Stores the relation from a giver/creator to a subscription ID.
 */
library SubscriptionRegistry {
    using Subscription for Subscription.Data;

    struct Data {
        /**
         * @dev The subscription ID that represents the subscription from giver to creator.
         *
         * A subscription ID is a token ID minted in the Grateful subscription NFT.
         *
         * A subscription ID between a giver and a creator is unique.
         */
        uint256 subscriptionId;
    }

    /**
     * @dev Loads the subscription ID from the giver/creator tuple.
     */
    function load(
        bytes32 giverId,
        bytes32 creatorId
    ) internal pure returns (Data storage store) {
        bytes32 s = keccak256(
            abi.encode("SubscriptionRegistry", giverId, creatorId)
        );
        assembly {
            store.slot := s
        }
    }

    /**
     * @dev Sets the subscription ID.
     */
    function set(Data storage self, uint256 subscriptionId) internal {
        self.subscriptionId = subscriptionId;
    }

    /**
     * @dev Gets the subscription data stored in the subscription storage.
     */
    function getSubscriptionData(
        Data storage self
    ) internal view returns (Subscription.Data storage subscriptionData) {
        return Subscription.load(self.subscriptionId);
    }

    /**
     * @dev Returns if the subscription is active.
     */
    function isSubscribed(Data storage self) internal view returns (bool) {
        return Subscription.load(self.subscriptionId).isSubscribed();
    }

    /**
     * @dev Returns if the subscription already exists.
     */
    function exists(Data storage self) internal view returns (bool) {
        return self.subscriptionId != 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**
 * @title Stores the vaults data used by the system.
 */
library Vault {
    struct Data {
        /**
         * @dev The vault address.
         *
         * Must be an ERC4626.
         */
        address impl;
        /**
         * @dev The extra decimals to be used to normalize all vaults.
         *
         * Normalized vaults have 20 decimals.
         *
         * This is used to minimize precision errors.
         */
        uint256 decimalsNormalizer;
        /**
         * @dev The minimum rate accepted by the vault.
         *
         * It is verified when a subcription is starting.
         */
        uint256 minRate;
        /**
         * @dev The maximum rate accepted by the vault.
         *
         * It is verified when a subcription is starting.
         */
        uint256 maxRate;
        /**
         * @dev Flag to pause the vault.
         */
        bool paused;
        /**
         * @dev Flag to deactivate the vault.
         */
        bool deactivated;
    }

    /**
     * @dev Loads the configuration for a vault.
     *
     * Vault ID is setup when initializing a vault.
     */
    function load(bytes32 vaultId) internal pure returns (Data storage store) {
        bytes32 s = keccak256(abi.encode("Vault", vaultId));
        assembly {
            store.slot := s
        }
    }

    /**
     * @dev Sets the data for a vault.
     */
    function set(
        Data storage self,
        address impl,
        uint256 decimalsNormalizer,
        uint256 minRate,
        uint256 maxRate
    ) internal {
        self.impl = impl;
        self.decimalsNormalizer = decimalsNormalizer;
        self.minRate = minRate;
        self.maxRate = maxRate;
    }

    /**
     * @dev Sets the minimum rate for a vault.
     */
    function setMinRate(Data storage self, uint256 minRate) internal {
        self.minRate = minRate;
    }

    /**
     * @dev Sets the maximum rate for a vault.
     */
    function setMaxRate(Data storage self, uint256 maxRate) internal {
        self.maxRate = maxRate;
    }

    /**
     * @dev Pauses a vault.
     */
    function pause(Data storage self) internal {
        self.paused = true;
    }

    /**
     * @dev Unpauses a vault.
     */
    function unpause(Data storage self) internal {
        self.paused = false;
    }

    /**
     * @dev Deactivates a vault.
     */
    function deactivate(Data storage self) internal {
        self.deactivated = true;
    }

    /**
     * @dev Activates a vault.
     */
    function activate(Data storage self) internal {
        self.deactivated = false;
    }

    /**
     * @dev Returns if a vault has been initialized.
     */
    function isInitialized(Data storage self) internal view returns (bool) {
        return self.impl != address(0);
    }

    /**
     * @dev Returns if a vault is active to be used.
     */
    function isActive(Data storage self) internal view returns (bool) {
        return self.impl != address(0) && !self.paused && !self.deactivated;
    }

    /**
     * @dev Returns if a vault is paused.
     */
    function isPaused(Data storage self) internal view returns (bool) {
        return self.impl != address(0) && !self.paused;
    }

    /**
     * @dev Returns if a subscription rate is valid for the current vault.
     */
    function isRateValid(
        Data storage self,
        uint256 rate
    ) internal view returns (bool) {
        return (rate >= self.minRate) && (rate <= self.maxRate);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Balance} from "../storage/Balance.sol";
import {Subscription} from "../storage/Subscription.sol";
import {SubscriptionRegistry} from "../storage/SubscriptionRegistry.sol";
import {Fee} from "../storage/Fee.sol";
import {IGratefulSubscription} from "../interfaces/IGratefulSubscription.sol";
import {AssociatedSystem} from "@synthetixio/core-modules/contracts/storage/AssociatedSystem.sol";
import {Fee} from "../storage/Fee.sol";
import {SubscriptionRegistry} from "../storage/SubscriptionRegistry.sol";
import {SubscriptionErrors} from "../errors/SubscriptionErrors.sol";

/**
 * @title Utils for reusing subscriptions interactions.
 *
 * Use case: reusing finishing subscription logic for Subscriptions and Liquidations modules
 */
library SubscriptionUtil {
    using Balance for Balance.Data;
    using Subscription for Subscription.Data;
    using AssociatedSystem for AssociatedSystem.Data;
    using Fee for Fee.Data;
    using SubscriptionRegistry for SubscriptionRegistry.Data;

    bytes32 private constant _GRATEFUL_SUBSCRIPTION_NFT =
        "gratefulSubscriptionNft";

    /**
     * @notice Emits the data from the finished subscription
     * @param giverId The ID from the profile that was subscribed
     * @param creatorId The ID from the profile that was receiving the subscription
     * @param vaultId The vault being used in the subscription
     * @param subscriptionId The subscription ID from the Grateful Subscription NFT
     * @param rate The subscription rate that was going to the creator (1e-20/second)
     * @param feeRate The fee rate that was going to the treasury (1e-20/second)
     */
    event SubscriptionFinished(
        bytes32 indexed giverId,
        bytes32 indexed creatorId,
        bytes32 indexed vaultId,
        uint256 subscriptionId,
        uint256 rate,
        uint256 feeRate
    );

    /**
     * @dev Starts a subscription.
     *
     * This function is used from a user.
     *
     * Updates the balances flows (giver, creator and treasury).
     *
     * If the subscription between giver and creator already exist, then the subscription is
     * updated to the new rate, else the subscription is created for the first time.
     *
     * To create a new subscription means to mint a new token ID from the Grateful subscription NFT.
     */
    function startSubscription(
        bytes32 giverId,
        bytes32 creatorId,
        bytes32 vaultId,
        uint256 subscriptionRate,
        address profileOwner
    )
        internal
        returns (uint256 subscriptionId, uint256 feeRate, uint256 totalRate)
    {
        // Calculate fee rate
        feeRate = Fee.load().getFeeRate(subscriptionRate);

        // Decrease giver flow
        totalRate = subscriptionRate + feeRate;
        Balance.load(giverId, vaultId).increaseOutflow(totalRate);

        // Increase creator flow
        Balance.load(creatorId, vaultId).increaseInflow(subscriptionRate);

        // Increase treasury flow with feeRate
        bytes32 treasuryId = Fee.load().gratefulFeeTreasury;
        Balance.load(treasuryId, vaultId).increaseInflow(feeRate);

        if (SubscriptionRegistry.load(giverId, creatorId).exists()) {
            subscriptionId = _updateSubscription(
                giverId,
                creatorId,
                vaultId,
                subscriptionRate,
                feeRate
            );
        } else {
            subscriptionId = _createSubscription(
                giverId,
                creatorId,
                vaultId,
                subscriptionRate,
                feeRate,
                profileOwner
            );
        }
    }

    /**
     * @dev Creates a subscription.
     *
     * This function is used from a user.
     *
     * Gets the next token ID from the subscription NFT.
     *
     * Saves the subscription data from this ID, and links it with the giver and creator.
     *
     * A new token ID is minted to the giver profile owner.
     */
    function _createSubscription(
        bytes32 giverId,
        bytes32 creatorId,
        bytes32 vaultId,
        uint256 subscriptionRate,
        uint256 feeRate,
        address profileOwner
    ) private returns (uint256 subscriptionId) {
        // Get subscription ID from subscription NFT
        IGratefulSubscription gs = IGratefulSubscription(
            AssociatedSystem.load(_GRATEFUL_SUBSCRIPTION_NFT).proxy
        );
        subscriptionId = gs.getCurrentTokenId();

        // Start subscription
        Subscription.Data storage subscription = Subscription.load(
            subscriptionId
        );
        subscription.start(subscriptionRate, feeRate, creatorId, vaultId);

        // Link subscription ID with subscription data
        SubscriptionRegistry.load(giverId, creatorId).set(subscriptionId);

        // Mint subscription NFT to giver profile owner
        gs.mint(profileOwner);
    }

    /**
     * @dev Updates a subscription.
     *
     * This function is used from a user.
     *
     * Loads the subscription data from the giver and creator.
     *
     * Updates the subscription data with the new rates and vault.
     *
     * No new subscription token is minted, the already created token is reused.
     */
    function _updateSubscription(
        bytes32 giverId,
        bytes32 creatorId,
        bytes32 vaultId,
        uint256 subscriptionRate,
        uint256 feeRate
    ) private returns (uint256 subscriptionId) {
        // Get subscription data
        subscriptionId = SubscriptionRegistry
            .load(giverId, creatorId)
            .subscriptionId;

        Subscription.Data storage subscription = Subscription.load(
            subscriptionId
        );

        // Update subscription
        subscription.update(subscriptionRate, feeRate, vaultId);
    }

    /**
     * @dev Finishes a subscription.
     *
     * This function is used from user or liquidator.
     *
     * Updates the balances flows (giver, creator and treasury).
     *
     * Updates the subscription state to be finished.
     *
     * Emit a event with the subscription data.
     */
    function finishSubscription(
        bytes32 giverId,
        bytes32 creatorId
    )
        internal
        returns (
            uint256 subscriptionId,
            uint256 subscriptionRate,
            uint256 feeRate,
            bytes32 vaultId
        )
    {
        // Get subscription data
        subscriptionId = SubscriptionRegistry
            .load(giverId, creatorId)
            .subscriptionId;

        Subscription.Data storage subscription = Subscription.load(
            subscriptionId
        );

        subscriptionRate = subscription.rate;
        feeRate = subscription.feeRate;
        vaultId = subscription.vaultId;

        // Increase giver flow
        uint256 totalRate = subscriptionRate + feeRate;
        Balance.load(giverId, vaultId).decreaseOutflow(totalRate);

        // Decrease creator flow
        Balance.load(creatorId, vaultId).decreaseInflow(subscriptionRate);

        // Decrease treasury flow with feeRate
        bytes32 treasuryId = Fee.load().gratefulFeeTreasury;
        Balance.load(treasuryId, vaultId).decreaseInflow(feeRate);

        // Finish subscription
        subscription.finish();

        // Emit event
        emit SubscriptionFinished(
            giverId,
            creatorId,
            vaultId,
            subscriptionId,
            subscriptionRate,
            feeRate
        );
    }

    /**
     * @dev Validates if the creator is correct.
     *
     * - Only existing creator profile ID
     * - Giver and creator cannot be the same
     * - Creator cannot be Grateful treasury
     */
    function validateCreator(bytes32 giverId, bytes32 creatorId) internal view {
        bytes32 treasuryId = Fee.load().gratefulFeeTreasury;
        if (giverId == creatorId || creatorId == treasuryId)
            revert SubscriptionErrors.InvalidCreator();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Vault} from "../storage/Vault.sol";
import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {VaultErrors} from "../errors/VaultErrors.sol";

/**
 * @title Utils for interacting with ERC4626 vaults.
 */
library VaultUtil {
    using SafeERC20 for IERC20;
    using Vault for Vault.Data;

    /**************************************************************************
     * Vault interaction functions
     *************************************************************************/

    /**
     * @dev Makes a user deposit into a vault.
     *
     * The vault must be a ERC4626.
     *
     * The `amount` corresponds to vault assets. The `shares` to vault shares.
     *
     * The user must have allowed the amount of the vault asset to the system.
     *
     * The assets are first transfer to the system and the system makes the deposit.
     *
     * The vault shares are normalized to 20 decimals after the deposit is made.
     */
    function deposit(
        bytes32 vaultId,
        uint256 amount
    ) internal returns (uint256 shares) {
        Vault.Data storage vaultData = Vault.load(vaultId);
        IERC4626 vault = IERC4626(vaultData.impl);

        _checkUserAllowance(vault, amount);

        IERC20(vault.asset()).safeTransferFrom(
            msg.sender,
            address(this),
            amount
        );

        shares =
            vault.deposit({assets: amount, receiver: address(this)}) *
            vaultData.decimalsNormalizer;
    }

    /**
     * @dev Makes a user withdrawal from a vault.
     *
     * The vault must be a ERC4626.
     *
     * The `shares` corresponds to vault shares. The `amountWithdrawn` to vault assets.
     *
     * The assets are directly transferred to the user.
     *
     * The user shares are normalized to original decimals before the redeem is made.
     */
    function redeem(
        bytes32 vaultId,
        uint256 shares
    ) internal returns (uint256 amountWithdrawn) {
        Vault.Data storage vaultData = Vault.load(vaultId);
        IERC4626 vault = IERC4626(vaultData.impl);

        uint256 normalizedShares = shares / vaultData.decimalsNormalizer;

        amountWithdrawn = vault.redeem({
            shares: normalizedShares,
            receiver: msg.sender,
            owner: address(this)
        });
    }

    function approve(bytes32 vaultId) internal {
        Vault.Data storage vaultData = Vault.load(vaultId);
        IERC4626 vault = IERC4626(vaultData.impl);

        IERC20(vault.asset()).approve(address(vault), type(uint256).max);
    }

    /**************************************************************************
     * View functions
     *************************************************************************/
    /**
     * @dev Checks user allowande to the system.
     *
     * The allowance check is made with the vault asset.
     */
    function _checkUserAllowance(IERC4626 vault, uint256 amount) private view {
        uint256 allowance = IERC20(vault.asset()).allowance(
            msg.sender,
            address(this)
        );

        if (allowance < amount) revert VaultErrors.InsufficientAllowance();
    }

    /**
     * @dev Returns if a vault is active.
     */
    function isVaultActive(bytes32 vaultId) internal view returns (bool) {
        return Vault.load(vaultId).isActive();
    }

    /**
     * @dev Returns if a vault is paused.
     */
    function isVaultPaused(bytes32 vaultId) internal view returns (bool) {
        return Vault.load(vaultId).isPaused();
    }

    /**
     * @dev Returns if a subscription rate is valid.
     */
    function isRateValid(
        bytes32 vaultId,
        uint256 rate
    ) internal view returns (bool) {
        return Vault.load(vaultId).isRateValid(rate);
    }

    /**
     * @dev Converts the rate from assets to shares.
     *
     * Receives a subscription rate denominated in assets.
     *
     * Returns a subscription rate denominated in shares.
     *
     * This is used because the relation between asset/share in a vault is changing.
     */
    function getCurrentRate(
        bytes32 vaultId,
        uint256 subscriptionRate
    ) internal view returns (uint256) {
        Vault.Data storage vaultData = Vault.load(vaultId);
        IERC4626 vault = IERC4626(vaultData.impl);

        return vault.convertToShares(subscriptionRate);
    }
}