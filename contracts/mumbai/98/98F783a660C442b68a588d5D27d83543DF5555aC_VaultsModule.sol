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

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title Library for access related errors.
 */
library AccessError {
    /**
     * @dev Thrown when an address tries to perform an unauthorized action.
     * @param addr The address that attempts the action.
     */
    error Unauthorized(address addr);
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import "../errors/AccessError.sol";

library OwnableStorage {
    bytes32 private constant _SLOT_OWNABLE_STORAGE =
        keccak256(abi.encode("io.synthetix.core-contracts.Ownable"));

    struct Data {
        address owner;
        address nominatedOwner;
    }

    function load() internal pure returns (Data storage store) {
        bytes32 s = _SLOT_OWNABLE_STORAGE;
        assembly {
            store.slot := s
        }
    }

    function onlyOwner() internal view {
        if (msg.sender != getOwner()) {
            revert AccessError.Unauthorized(msg.sender);
        }
    }

    function getOwner() internal view returns (address) {
        return OwnableStorage.load().owner;
    }
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
 * @title Module for managing vaults.
 */
interface IVaultsModule {
    /**************************************************************************
     * Governance functions
     *************************************************************************/

    /**
     * @notice Add vault to Grateful system.
     *
     * Requirements:
     *
     * - Only owner
     * - ERC4626 compliant vault
     * - Emits `VaultAdded` event
     *
     * @param vaultId The vault ID (any bytes32 defined by the owner)
     * @param impl The vault implementation address
     * @param minRate Minimum subscription rate allowed for this vault
     * @param maxRate Maximum subscription rate allowed for this vault
     */
    function addVault(
        bytes32 vaultId,
        address impl,
        uint256 minRate,
        uint256 maxRate
    ) external;

    /**
     * @notice Change the vault minimum rate
     * @dev Only owner / Emits `MinRateChanged` event / Vault must be initialized
     * @param vaultId The vault ID to change the minimum rate
     * @param newMinRate The new minimum rate
     */
    function setMinRate(bytes32 vaultId, uint256 newMinRate) external;

    /**
     * @notice Change the vault maximum rate
     * @dev Only owner / Emits `MaxRateChanged` event / Vault must be initialized
     * @param vaultId The vault ID to change the maximum rate
     * @param newMaxRate The new maximum rate
     */
    function setMaxRate(bytes32 vaultId, uint256 newMaxRate) external;

    /**
     * @notice Pause a vault to avoid deposits, withdrawals or subscriptions
     * @dev Only owner / Emits `VaultPaused` event / Vault must be initialized
     * @param vaultId The vault ID to pause
     */
    function pauseVault(bytes32 vaultId) external;

    /**
     * @notice Unpause a vault to allow deposits, withdrawals or subscriptions
     * @dev Only owner / Emits `VaultUnpaused` event / Vault must be initialized
     * @param vaultId The vault ID to unpause
     */
    function unpauseVault(bytes32 vaultId) external;

    /**
     * @notice Deactivate a vault to avoid new deposits or subscriptions
     * @dev Only owner / Emits `VaultDeactivated` event / Vault must be initialized
     * @param vaultId The vault ID to pause
     */
    function deactivateVault(bytes32 vaultId) external;

    /**
     * @notice Activate a vault to allow new deposits or subscriptions
     * @dev Only owner / Emits `VaultActivated` event / Vault must be initialized
     * @param vaultId The vault ID to unpause
     */
    function activateVault(bytes32 vaultId) external;

    /**************************************************************************
     * View functions
     *************************************************************************/

    /**
     * @notice Return a vault address
     * @param vaultId The vault ID from where to return the address
     * @return The vault address
     */
    function getVault(bytes32 vaultId) external view returns (address);

    /**************************************************************************
     * Events
     *************************************************************************/

    /**
     * @notice Emits the vault added data
     * @param vaultId The vault ID (any bytes32 defined by the owner)
     * @param impl The vault implementation address
     * @param minRate The vault minimum rate
     * @param maxRate The vault maximum rate
     */
    event VaultAdded(
        bytes32 indexed vaultId,
        address impl,
        uint256 minRate,
        uint256 maxRate
    );

    /**
     * @notice Emits the vault minimum rate change
     * @param vaultId The vault ID
     * @param oldMinRate The old minimum rate
     * @param newMinRate The new minimum rate
     */
    event MinRateChanged(
        bytes32 indexed vaultId,
        uint256 oldMinRate,
        uint256 newMinRate
    );

    /**
     * @notice Emits the vault maximum rate change
     * @param vaultId The vault ID
     * @param oldMaxRate The old maximum rate
     * @param newMaxRate The new maximum rate
     */
    event MaxRateChanged(
        bytes32 indexed vaultId,
        uint256 oldMaxRate,
        uint256 newMaxRate
    );

    /**
     * @notice Emits when a vault is paused
     * @param vaultId The vault ID
     */
    event VaultPaused(bytes32 indexed vaultId);

    /**
     * @notice Emits when a vault is unpaused
     * @param vaultId The vault ID
     */
    event VaultUnpaused(bytes32 indexed vaultId);

    /**
     * @notice Emits when a vault is deactivated
     * @param vaultId The vault ID
     */
    event VaultDeactivated(bytes32 indexed vaultId);

    /**
     * @notice Emits when a vault is activated
     * @param vaultId The vault ID
     */
    event VaultActivated(bytes32 indexed vaultId);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Vault} from "../storage/Vault.sol";
import {IVaultsModule} from "../interfaces/IVaultsModule.sol";
import {OwnableStorage} from "@synthetixio/core-contracts/contracts/ownership/OwnableStorage.sol";
import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";
import {VaultErrors} from "../errors/VaultErrors.sol";
import {InputErrors} from "../errors/InputErrors.sol";
import {VaultUtil} from "../utils/VaultUtil.sol";

/**
 * @title Module for managing vaults.
 * @dev See IVaultsModule.
 */
contract VaultsModule is IVaultsModule {
    using Vault for Vault.Data;

    /// @inheritdoc IVaultsModule
    function addVault(
        bytes32 vaultId,
        address impl,
        uint256 minRate,
        uint256 maxRate
    ) external override {
        OwnableStorage.onlyOwner();

        if (vaultId == bytes32(0)) revert InputErrors.ZeroId();
        if (impl == address(0)) revert InputErrors.ZeroAddress();

        Vault.Data storage vault = Vault.load(vaultId);

        if (vault.isInitialized()) revert InputErrors.AlreadyInitialized();

        uint256 decimalsNormalizer = 10 ** (20 - IERC4626(impl).decimals());

        vault.set(impl, decimalsNormalizer, minRate, maxRate);

        VaultUtil.approve(vaultId);

        emit VaultAdded(vaultId, impl, minRate, maxRate);
    }

    function _validateVaultPermissions(bytes32 vaultId) private view {
        OwnableStorage.onlyOwner();

        if (!Vault.load(vaultId).isInitialized())
            revert VaultErrors.VaultNotInitialized();
    }

    /// @inheritdoc IVaultsModule
    function setMinRate(bytes32 vaultId, uint256 newMinRate) external override {
        _validateVaultPermissions(vaultId);

        Vault.Data storage vault = Vault.load(vaultId);
        uint256 oldMinRate = vault.minRate;
        vault.setMinRate(newMinRate);

        emit MinRateChanged(vaultId, oldMinRate, newMinRate);
    }

    /// @inheritdoc IVaultsModule
    function setMaxRate(bytes32 vaultId, uint256 newMaxRate) external override {
        _validateVaultPermissions(vaultId);

        Vault.Data storage vault = Vault.load(vaultId);
        uint256 oldMaxRate = vault.maxRate;
        vault.setMaxRate(newMaxRate);

        emit MaxRateChanged(vaultId, oldMaxRate, newMaxRate);
    }

    /// @inheritdoc IVaultsModule
    function deactivateVault(bytes32 vaultId) external override {
        _validateVaultPermissions(vaultId);

        Vault.load(vaultId).deactivate();

        emit VaultDeactivated(vaultId);
    }

    /// @inheritdoc IVaultsModule
    function activateVault(bytes32 vaultId) external override {
        _validateVaultPermissions(vaultId);

        Vault.load(vaultId).activate();

        emit VaultActivated(vaultId);
    }

    /// @inheritdoc IVaultsModule
    function pauseVault(bytes32 vaultId) external override {
        _validateVaultPermissions(vaultId);

        Vault.load(vaultId).pause();

        emit VaultPaused(vaultId);
    }

    /// @inheritdoc IVaultsModule
    function unpauseVault(bytes32 vaultId) external override {
        _validateVaultPermissions(vaultId);

        Vault.load(vaultId).unpause();

        emit VaultUnpaused(vaultId);
    }

    /// @inheritdoc IVaultsModule
    function getVault(
        bytes32 vaultId
    ) external view override returns (address) {
        return Vault.load(vaultId).impl;
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