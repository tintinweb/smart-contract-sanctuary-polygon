// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
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
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
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
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
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
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
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
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/math/SignedMath.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard signed math utilities missing in the Solidity language.
 */
library SignedMath {
    /**
     * @dev Returns the largest of two signed numbers.
     */
    function max(int256 a, int256 b) internal pure returns (int256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two signed numbers.
     */
    function min(int256 a, int256 b) internal pure returns (int256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two signed numbers without overflow.
     * The result is rounded towards zero.
     */
    function average(int256 a, int256 b) internal pure returns (int256) {
        // Formula from the book "Hacker's Delight"
        int256 x = (a & b) + ((a ^ b) >> 1);
        return x + (int256(uint256(x) >> 255) & (a ^ b));
    }

    /**
     * @dev Returns the absolute unsigned value of a signed value.
     */
    function abs(int256 n) internal pure returns (uint256) {
        unchecked {
            // must be unchecked in order to support `n = type(int256).min`
            return uint256(n >= 0 ? n : -n);
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

/**
 * @title Library for address related errors.
 */
library AddressError {
    /**
     * @dev Thrown when a zero address was passed as a function parameter (0x0000000000000000000000000000000000000000).
     */
    error ZeroAddress();

    /**
     * @dev Thrown when an address representing a contract is expected, but no code is found at the address.
     * @param contr The address that was expected to be a contract.
     */
    error NotAContract(address contr);
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title Library for change related errors.
 */
library ChangeError {
    /**
     * @dev Thrown when a change is expected but none is detected.
     */
    error NoChange();
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title Library for initialization related errors.
 */
library InitError {
    /**
     * @dev Thrown when attempting to initialize a contract that is already initialized.
     */
    error AlreadyInitialized();

    /**
     * @dev Thrown when attempting to interact with a contract that has not been initialized yet.
     */
    error NotInitialized();
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title Library for errors related with expected function parameters.
 */
library ParameterError {
    /**
     * @dev Thrown when an invalid parameter is used in a function.
     * @param parameter The name of the parameter.
     * @param reason The reason why the received parameter is invalid.
     */
    error InvalidParameter(string parameter, string reason);
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import "../errors/InitError.sol";

/**
 * @title Mixin for contracts that require initialization.
 */
abstract contract InitializableMixin {
    /**
     * @dev Reverts if contract is not initialized.
     */
    modifier onlyIfInitialized() {
        if (!_isInitialized()) {
            revert InitError.NotInitialized();
        }

        _;
    }

    /**
     * @dev Reverts if contract is already initialized.
     */
    modifier onlyIfNotInitialized() {
        if (_isInitialized()) {
            revert InitError.AlreadyInitialized();
        }

        _;
    }

    /**
     * @dev Override this function to determine if the contract is initialized.
     * @return True if initialized, false otherwise.
     */
    function _isInitialized() internal view virtual returns (bool);
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title ERC165 interface for determining if a contract supports a given interface.
 */
interface IERC165 {
    /**
     * @notice Determines if the contract in question supports the specified interface.
     * @param interfaceID XOR of all selectors in the contract.
     * @return True if the contract supports the specified interface.
     */
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
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
     * - `owner` must be a valid address
     */
    function balanceOf(address owner) external view returns (uint256 balance);

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

import "./IERC165.sol";

/**
 * @title Additional metadata for IERC721 tokens.
 */
interface IERC721Metadata is IERC165 {
    /**
     * @notice Retrieves the name of the token, e.g. "Synthetix Account Token".
     * @return A string with the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @notice Retrieves the symbol of the token, e.g. "SNX-ACC".
     * @return A string with the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @notice Retrieves the off-chain URI where the specified token id may contain associated data, such as images, audio, etc.
     * @param tokenId The numeric id of the token in question.
     * @return The URI of the token in question.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title ERC721 extension that allows contracts to receive tokens with `safeTransferFrom`.
 */
interface IERC721Receiver {
    /**
     * @notice Function that will be called by ERC721 tokens implementing the `safeTransferFrom` function.
     * @dev The contract transferring the token will revert if the receiving contract does not implement this function.
     * @param operator The address that is executing the transfer.
     * @param from The address whose token is being transferred.
     * @param tokenId The numeric id of the token being transferred.
     * @param data Optional additional data that may be passed by the operator, and could be used by the implementing contract.
     * @return The selector of this function (IERC721Receiver.onERC721Received.selector). Caller will revert if not returned.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes memory data
    ) external returns (bytes4);
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title Contract for facilitating ownership by a single address.
 */
interface IOwnable {
    /**
     * @notice Thrown when an address tries to accept ownership but has not been nominated.
     * @param addr The address that is trying to accept ownership.
     */
    error NotNominated(address addr);

    /**
     * @notice Emitted when an address has been nominated.
     * @param newOwner The address that has been nominated.
     */
    event OwnerNominated(address newOwner);

    /**
     * @notice Emitted when the owner of the contract has changed.
     * @param oldOwner The previous owner of the contract.
     * @param newOwner The new owner of the contract.
     */
    event OwnerChanged(address oldOwner, address newOwner);

    /**
     * @notice Allows a nominated address to accept ownership of the contract.
     * @dev Reverts if the caller is not nominated.
     */
    function acceptOwnership() external;

    /**
     * @notice Allows the current owner to nominate a new owner.
     * @dev The nominated owner will have to call `acceptOwnership` in a separate transaction in order to finalize the action and become the new contract owner.
     * @param newNominatedOwner The address that is to become nominated.
     */
    function nominateNewOwner(address newNominatedOwner) external;

    /**
     * @notice Allows a nominated owner to reject the nomination.
     */
    function renounceNomination() external;

    /**
     * @notice Returns the current owner of the contract.
     */
    function owner() external view returns (address);

    /**
     * @notice Returns the current nominated owner of the contract.
     * @dev Only one address can be nominated at a time.
     */
    function nominatedOwner() external view returns (address);
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title Contract to be used as the implementation of a Universal Upgradeable Proxy Standard (UUPS) proxy.
 *
 * Important: A UUPS proxy requires its upgradeability functions to be in the implementation as opposed to the proxy. This means that if the proxy is upgraded to an implementation that does not support this interface, it will no longer be upgradeable.
 */
interface IUUPSImplementation {
    /**
     * @notice Thrown when an incoming implementation will not be able to receive future upgrades.
     */
    error ImplementationIsSterile(address implementation);

    /**
     * @notice Thrown intentionally when testing future upgradeability of an implementation.
     */
    error UpgradeSimulationFailed();

    /**
     * @notice Emitted when the implementation of the proxy has been upgraded.
     * @param self The address of the proxy whose implementation was upgraded.
     * @param implementation The address of the proxy's new implementation.
     */
    event Upgraded(address indexed self, address implementation);

    /**
     * @notice Allows the proxy to be upgraded to a new implementation.
     * @param newImplementation The address of the proxy's new implementation.
     * @dev Will revert if `newImplementation` is not upgradeable.
     * @dev The implementation of this function needs to be protected by some sort of access control such as `onlyOwner`.
     */
    function upgradeTo(address newImplementation) external;

    /**
     * @notice Function used to determine if a new implementation will be able to receive future upgrades in `upgradeTo`.
     * @param newImplementation The address of the new implementation being tested for future upgradeability.
     * @dev This function will always revert, but will revert with different error messages. The function `upgradeTo` uses this error to determine the future upgradeability of the implementation in question.
     */
    function simulateUpgradeTo(address newImplementation) external;

    /**
     * @notice Retrieves the current implementation of the proxy.
     * @return The address of the current implementation.
     */
    function getImplementation() external view returns (address);
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import "./OwnableStorage.sol";
import "../interfaces/IOwnable.sol";
import "../errors/AddressError.sol";
import "../errors/ChangeError.sol";

/**
 * @title Contract for facilitating ownership by a single address.
 * See IOwnable.
 */
contract Ownable is IOwnable {
    constructor(address initialOwner) {
        OwnableStorage.load().owner = initialOwner;
    }

    /**
     * @inheritdoc IOwnable
     */
    function acceptOwnership() public override {
        OwnableStorage.Data storage store = OwnableStorage.load();

        address currentNominatedOwner = store.nominatedOwner;
        if (msg.sender != currentNominatedOwner) {
            revert NotNominated(msg.sender);
        }

        emit OwnerChanged(store.owner, currentNominatedOwner);
        store.owner = currentNominatedOwner;

        store.nominatedOwner = address(0);
    }

    /**
     * @inheritdoc IOwnable
     */
    function nominateNewOwner(address newNominatedOwner) public override onlyOwner {
        OwnableStorage.Data storage store = OwnableStorage.load();

        if (newNominatedOwner == address(0)) {
            revert AddressError.ZeroAddress();
        }

        if (newNominatedOwner == store.nominatedOwner) {
            revert ChangeError.NoChange();
        }

        store.nominatedOwner = newNominatedOwner;
        emit OwnerNominated(newNominatedOwner);
    }

    /**
     * @inheritdoc IOwnable
     */
    function renounceNomination() external override {
        OwnableStorage.Data storage store = OwnableStorage.load();

        if (store.nominatedOwner != msg.sender) {
            revert NotNominated(msg.sender);
        }

        store.nominatedOwner = address(0);
    }

    /**
     * @inheritdoc IOwnable
     */
    function owner() external view override returns (address) {
        return OwnableStorage.load().owner;
    }

    /**
     * @inheritdoc IOwnable
     */
    function nominatedOwner() external view override returns (address) {
        return OwnableStorage.load().nominatedOwner;
    }

    /**
     * @dev Reverts if the caller is not the owner.
     */
    modifier onlyOwner() {
        OwnableStorage.onlyOwner();

        _;
    }
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

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

abstract contract AbstractProxy {
    fallback() external payable {
        _forward();
    }

    receive() external payable {
        _forward();
    }

    function _forward() internal {
        address implementation = _getImplementation();

        // solhint-disable-next-line no-inline-assembly
        assembly {
            calldatacopy(0, 0, calldatasize())

            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            returndatacopy(0, 0, returndatasize())

            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    function _getImplementation() internal view virtual returns (address);
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

contract ProxyStorage {
    bytes32 private constant _SLOT_PROXY_STORAGE =
        keccak256(abi.encode("io.synthetix.core-contracts.Proxy"));

    struct ProxyStore {
        address implementation;
        bool simulatingUpgrade;
    }

    function _proxyStore() internal pure returns (ProxyStore storage store) {
        bytes32 s = _SLOT_PROXY_STORAGE;
        assembly {
            store.slot := s
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import "../interfaces/IUUPSImplementation.sol";
import "../errors/AddressError.sol";
import "../errors/ChangeError.sol";
import "../utils/AddressUtil.sol";
import "./ProxyStorage.sol";

abstract contract UUPSImplementation is IUUPSImplementation, ProxyStorage {
    /**
     * @inheritdoc IUUPSImplementation
     */
    function simulateUpgradeTo(address newImplementation) public override {
        ProxyStore storage store = _proxyStore();

        store.simulatingUpgrade = true;

        address currentImplementation = store.implementation;
        store.implementation = newImplementation;

        (bool rollbackSuccessful, ) = newImplementation.delegatecall(
            abi.encodeCall(this.upgradeTo, (currentImplementation))
        );

        if (!rollbackSuccessful || _proxyStore().implementation != currentImplementation) {
            revert UpgradeSimulationFailed();
        }

        store.simulatingUpgrade = false;

        // solhint-disable-next-line reason-string
        revert();
    }

    /**
     * @inheritdoc IUUPSImplementation
     */
    function getImplementation() external view override returns (address) {
        return _proxyStore().implementation;
    }

    function _upgradeTo(address newImplementation) internal virtual {
        if (newImplementation == address(0)) {
            revert AddressError.ZeroAddress();
        }

        if (!AddressUtil.isContract(newImplementation)) {
            revert AddressError.NotAContract(newImplementation);
        }

        ProxyStore storage store = _proxyStore();

        if (newImplementation == store.implementation) {
            revert ChangeError.NoChange();
        }

        if (!store.simulatingUpgrade && _implementationIsSterile(newImplementation)) {
            revert ImplementationIsSterile(newImplementation);
        }

        store.implementation = newImplementation;

        emit Upgraded(address(this), newImplementation);
    }

    function _implementationIsSterile(
        address candidateImplementation
    ) internal virtual returns (bool) {
        (bool simulationReverted, bytes memory simulationResponse) = address(this).delegatecall(
            abi.encodeCall(this.simulateUpgradeTo, (candidateImplementation))
        );

        return
            !simulationReverted &&
            keccak256(abi.encodePacked(simulationResponse)) ==
            keccak256(abi.encodePacked(UpgradeSimulationFailed.selector));
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import "./AbstractProxy.sol";
import "./ProxyStorage.sol";
import "../errors/AddressError.sol";
import "../utils/AddressUtil.sol";

contract UUPSProxy is AbstractProxy, ProxyStorage {
    constructor(address firstImplementation) {
        if (firstImplementation == address(0)) {
            revert AddressError.ZeroAddress();
        }

        if (!AddressUtil.isContract(firstImplementation)) {
            revert AddressError.NotAContract(firstImplementation);
        }

        _proxyStore().implementation = firstImplementation;
    }

    function _getImplementation() internal view virtual override returns (address) {
        return _proxyStore().implementation;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import {UUPSProxy} from "./UUPSProxy.sol";
import {OwnableStorage} from "../ownership/OwnableStorage.sol";

contract UUPSProxyWithOwner is UUPSProxy {
    // solhint-disable-next-line no-empty-blocks
    constructor(address firstImplementation, address initialOwner) UUPSProxy(firstImplementation) {
        OwnableStorage.load().owner = initialOwner;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import "../interfaces/IERC721.sol";
import "../interfaces/IERC721Metadata.sol";
import "../interfaces/IERC721Receiver.sol";
import "../errors/AddressError.sol";
import "../errors/AccessError.sol";
import "../errors/InitError.sol";
import "../errors/ParameterError.sol";
import "./ERC721Storage.sol";
import "../utils/AddressUtil.sol";
import "../utils/StringUtil.sol";

/*
 * @title ERC721 non-fungible token (NFT) contract.
 * See IERC721.
 *
 * Reference implementations:
 * - OpenZeppelin - https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/ERC721.sol
 */
contract ERC721 is IERC721, IERC721Metadata {
    /**
     * @inheritdoc IERC165
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return
            interfaceId == this.supportsInterface.selector || // ERC165
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId;
    }

    /**
     * @inheritdoc IERC721
     */
    function balanceOf(address holder) public view virtual override returns (uint) {
        if (holder == address(0)) {
            revert InvalidOwner(holder);
        }

        return ERC721Storage.load().balanceOf[holder];
    }

    /**
     * @inheritdoc IERC721
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        if (!_exists(tokenId)) {
            revert TokenDoesNotExist(tokenId);
        }

        return ERC721Storage.load().ownerOf[tokenId];
    }

    /**
     * @inheritdoc IERC721Metadata
     */
    function name() external view virtual override returns (string memory) {
        return ERC721Storage.load().name;
    }

    /**
     * @inheritdoc IERC721Metadata
     */
    function symbol() external view virtual override returns (string memory) {
        return ERC721Storage.load().symbol;
    }

    /**
     * @inheritdoc IERC721Metadata
     */
    function tokenURI(uint256 tokenId) external view virtual override returns (string memory) {
        if (!_exists(tokenId)) {
            revert TokenDoesNotExist(tokenId);
        }

        string memory baseURI = ERC721Storage.load().baseTokenURI;

        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, StringUtil.uintToString(tokenId)))
                : "";
    }

    /**
     * @inheritdoc IERC721
     */
    function approve(address to, uint256 tokenId) public virtual override {
        ERC721Storage.Data storage store = ERC721Storage.load();
        address holder = store.ownerOf[tokenId];

        if (to == holder) {
            revert CannotSelfApprove(to);
        }

        if (msg.sender != holder && !isApprovedForAll(holder, msg.sender)) {
            revert AccessError.Unauthorized(msg.sender);
        }

        _approve(to, tokenId);
    }

    /**
     * @inheritdoc IERC721
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        if (!_exists(tokenId)) {
            revert TokenDoesNotExist(tokenId);
        }

        return ERC721Storage.load().tokenApprovals[tokenId];
    }

    /**
     * @inheritdoc IERC721
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        if (msg.sender == operator) {
            revert CannotSelfApprove(operator);
        }

        ERC721Storage.load().operatorApprovals[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    /**
     * @inheritdoc IERC721
     */
    function isApprovedForAll(
        address holder,
        address operator
    ) public view virtual override returns (bool) {
        return ERC721Storage.load().operatorApprovals[holder][operator];
    }

    /**
     * @inheritdoc IERC721
     */
    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        if (!_isApprovedOrOwner(msg.sender, tokenId)) {
            revert AccessError.Unauthorized(msg.sender);
        }

        _transfer(from, to, tokenId);
    }

    /**
     * @inheritdoc IERC721
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @inheritdoc IERC721
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override {
        if (!_isApprovedOrOwner(msg.sender, tokenId)) {
            revert AccessError.Unauthorized(msg.sender);
        }

        _transfer(from, to, tokenId);
        if (!_checkOnERC721Received(from, to, tokenId, data)) {
            revert InvalidTransferRecipient(to);
        }
    }

    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return ERC721Storage.load().ownerOf[tokenId] != address(0);
    }

    function _isApprovedOrOwner(
        address spender,
        uint256 tokenId
    ) internal view virtual returns (bool) {
        address holder = ownerOf(tokenId);

        // Not checking tokenId existence since it is checked in ownerOf() and getApproved()

        return (spender == holder ||
            getApproved(tokenId) == spender ||
            isApprovedForAll(holder, spender));
    }

    function _mint(address to, uint256 tokenId) internal virtual {
        ERC721Storage.Data storage store = ERC721Storage.load();
        if (to == address(0)) {
            revert AddressError.ZeroAddress();
        }

        if (tokenId == 0) {
            revert ParameterError.InvalidParameter("tokenId", "cannot be zero");
        }

        if (_exists(tokenId)) {
            revert TokenAlreadyMinted(tokenId);
        }

        _beforeTransfer(address(0), to, tokenId);

        store.balanceOf[to] += 1;
        store.ownerOf[tokenId] = to;

        _postTransfer(address(0), to, tokenId);

        emit Transfer(address(0), to, tokenId);
    }

    function _burn(uint256 tokenId) internal virtual {
        ERC721Storage.Data storage store = ERC721Storage.load();
        address holder = store.ownerOf[tokenId];

        _approve(address(0), tokenId);

        _beforeTransfer(holder, address(0), tokenId);

        store.balanceOf[holder] -= 1;
        delete store.ownerOf[tokenId];

        _postTransfer(holder, address(0), tokenId);

        emit Transfer(holder, address(0), tokenId);
    }

    function _transfer(address from, address to, uint256 tokenId) internal virtual {
        ERC721Storage.Data storage store = ERC721Storage.load();

        if (ownerOf(tokenId) != from) {
            revert AccessError.Unauthorized(from);
        }

        if (to == address(0)) {
            revert AddressError.ZeroAddress();
        }

        _beforeTransfer(from, to, tokenId);

        // Clear approvals from the previous holder
        _approve(address(0), tokenId);

        store.balanceOf[from] -= 1;
        store.balanceOf[to] += 1;
        store.ownerOf[tokenId] = to;

        _postTransfer(from, to, tokenId);

        emit Transfer(from, to, tokenId);
    }

    function _approve(address to, uint256 tokenId) internal virtual {
        ERC721Storage.load().tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal returns (bool) {
        if (AddressUtil.isContract(to)) {
            try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, data) returns (
                bytes4 retval
            ) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch {
                return false;
            }
        } else {
            return true;
        }
    }

    function _beforeTransfer(
        address from,
        address to,
        uint256 tokenId // solhint-disable-next-line no-empty-blocks
    ) internal virtual {}

    function _postTransfer(
        address from,
        address to,
        uint256 tokenId // solhint-disable-next-line no-empty-blocks
    ) internal virtual {}

    function _initialize(
        string memory tokenName,
        string memory tokenSymbol,
        string memory baseTokenURI
    ) internal virtual {
        ERC721Storage.Data storage store = ERC721Storage.load();
        if (
            bytes(store.name).length > 0 ||
            bytes(store.symbol).length > 0 ||
            bytes(store.baseTokenURI).length > 0
        ) {
            revert InitError.AlreadyInitialized();
        }

        if (bytes(tokenName).length == 0 || bytes(tokenSymbol).length == 0) {
            revert ParameterError.InvalidParameter("name/symbol", "must not be empty");
        }

        store.name = tokenName;
        store.symbol = tokenSymbol;
        store.baseTokenURI = baseTokenURI;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import "./ERC721.sol";
import "./ERC721EnumerableStorage.sol";
import "../interfaces/IERC721Enumerable.sol";

/*
 * @title ERC721 extension with helper functions that allow the enumeration of NFT tokens.
 * See IERC721Enumerable
 *
 * Reference implementations:
 * - OpenZeppelin - https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/extensions/ERC721EnumerableStorage.sol
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    /**
     * @inheritdoc IERC165
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return
            super.supportsInterface(interfaceId) ||
            interfaceId == type(IERC721Enumerable).interfaceId;
    }

    /**
     * @inheritdoc IERC721Enumerable
     */
    function tokenOfOwnerByIndex(
        address owner,
        uint256 index
    ) public view virtual override returns (uint256) {
        if (ERC721.balanceOf(owner) <= index) {
            revert IndexOverrun(index, ERC721.balanceOf(owner));
        }
        return ERC721EnumerableStorage.load().ownedTokens[owner][index];
    }

    /**
     * @inheritdoc IERC721Enumerable
     */
    function totalSupply() public view virtual override returns (uint256) {
        return ERC721EnumerableStorage.load().allTokens.length;
    }

    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        if (index >= ERC721Enumerable.totalSupply()) {
            revert IndexOverrun(index, ERC721Enumerable.totalSupply());
        }
        return ERC721EnumerableStorage.load().allTokens[index];
    }

    function _beforeTransfer(address from, address to, uint256 tokenId) internal virtual override {
        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        ERC721EnumerableStorage.load().ownedTokens[to][length] = tokenId;
        ERC721EnumerableStorage.load().ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        ERC721EnumerableStorage.load().allTokensIndex[tokenId] = ERC721EnumerableStorage
            .load()
            .allTokens
            .length;
        ERC721EnumerableStorage.load().allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = ERC721EnumerableStorage.load().ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = ERC721EnumerableStorage.load().ownedTokens[from][lastTokenIndex];

            ERC721EnumerableStorage.load().ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            ERC721EnumerableStorage.load().ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete ERC721EnumerableStorage.load().ownedTokensIndex[tokenId];
        delete ERC721EnumerableStorage.load().ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721EnumerableStorage.load().allTokens.length - 1;
        uint256 tokenIndex = ERC721EnumerableStorage.load().allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = ERC721EnumerableStorage.load().allTokens[lastTokenIndex];

        ERC721EnumerableStorage.load().allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        ERC721EnumerableStorage.load().allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete ERC721EnumerableStorage.load().allTokensIndex[tokenId];
        ERC721EnumerableStorage.load().allTokens.pop();
    }

    function _initialize(
        string memory tokenName,
        string memory tokenSymbol,
        string memory baseTokenURI
    ) internal virtual override {
        super._initialize(tokenName, tokenSymbol, baseTokenURI);
        if (ERC721EnumerableStorage.load().allTokens.length > 0) {
            revert InitError.AlreadyInitialized();
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

library ERC721EnumerableStorage {
    bytes32 private constant _SLOT_ERC721_ENUMERABLE_STORAGE =
        keccak256(abi.encode("io.synthetix.core-contracts.ERC721Enumerable"));

    struct Data {
        mapping(uint256 => uint256) ownedTokensIndex;
        mapping(uint256 => uint256) allTokensIndex;
        mapping(address => mapping(uint256 => uint256)) ownedTokens;
        uint256[] allTokens;
    }

    function load() internal pure returns (Data storage store) {
        bytes32 s = _SLOT_ERC721_ENUMERABLE_STORAGE;
        assembly {
            store.slot := s
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

library ERC721Storage {
    bytes32 private constant _SLOT_ERC721_STORAGE =
        keccak256(abi.encode("io.synthetix.core-contracts.ERC721"));

    struct Data {
        string name;
        string symbol;
        string baseTokenURI;
        mapping(uint256 => address) ownerOf;
        mapping(address => uint256) balanceOf;
        mapping(uint256 => address) tokenApprovals;
        mapping(address => mapping(address => bool)) operatorApprovals;
    }

    function load() internal pure returns (Data storage store) {
        bytes32 s = _SLOT_ERC721_STORAGE;
        assembly {
            store.slot := s
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

library AddressUtil {
    function isContract(address account) internal view returns (bool) {
        uint256 size;

        assembly {
            size := extcodesize(account)
        }

        return size > 0;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/*
    Reference implementations:
    * OpenZeppelin - https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Strings.sol
*/

library StringUtil {
    function uintToString(uint value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }

        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }

        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            // solhint-disable-next-line numcast/safe-cast
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }

        return string(buffer);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title Module for connecting a system with other associated systems.

 * Associated systems become available to all system modules for communication and interaction, but as opposed to inter-modular communications, interactions with associated systems will require the use of `CALL`.
 *
 * Associated systems can be managed or unmanaged.
 * - Managed systems are connected via a proxy, which means that their implementation can be updated, and the system controls the execution context of the associated system. Example, an snxUSD token connected to the system, and controlled by the system.
 * - Unmanaged systems are just addresses tracked by the system, for which it has no control whatsoever. Example, Uniswap v3, Curve, etc.
 *
 * Furthermore, associated systems are typed in the AssociatedSystem utility library (See AssociatedSystem.sol):
 * - KIND_ERC20: A managed associated system specifically wrapping an ERC20 implementation.
 * - KIND_ERC721: A managed associated system specifically wrapping an ERC721 implementation.
 * - KIND_UNMANAGED: Any unmanaged associated system.
 */
interface IAssociatedSystemsModule {
    /**
     * @notice Emitted when an associated system is set.
     * @param kind The type of associated system (managed ERC20, managed ERC721, unmanaged, etc - See the AssociatedSystem util).
     * @param id The bytes32 identifier of the associated system.
     * @param proxy The main external contract address of the associated system.
     * @param impl The address of the implementation of the associated system (if not behind a proxy, will equal `proxy`).
     */
    event AssociatedSystemSet(
        bytes32 indexed kind,
        bytes32 indexed id,
        address proxy,
        address impl
    );

    /**
     * @notice Emitted when the function you are calling requires an associated system, but it
     * has not been registered
     */
    error MissingAssociatedSystem(bytes32 id);

    /**
     * @notice Creates or initializes a managed associated ERC20 token.
     * @param id The bytes32 identifier of the associated system. If the id is new to the system, it will create a new proxy for the associated system.
     * @param name The token name that will be used to initialize the proxy.
     * @param symbol The token symbol that will be used to initialize the proxy.
     * @param decimals The token decimals that will be used to initialize the proxy.
     * @param impl The ERC20 implementation of the proxy.
     */
    function initOrUpgradeToken(
        bytes32 id,
        string memory name,
        string memory symbol,
        uint8 decimals,
        address impl
    ) external;

    /**
     * @notice Creates or initializes a managed associated ERC721 token.
     * @param id The bytes32 identifier of the associated system. If the id is new to the system, it will create a new proxy for the associated system.
     * @param name The token name that will be used to initialize the proxy.
     * @param symbol The token symbol that will be used to initialize the proxy.
     * @param uri The token uri that will be used to initialize the proxy.
     * @param impl The ERC721 implementation of the proxy.
     */
    function initOrUpgradeNft(
        bytes32 id,
        string memory name,
        string memory symbol,
        string memory uri,
        address impl
    ) external;

    /**
     * @notice Registers an unmanaged external contract in the system.
     * @param id The bytes32 identifier to use to reference the associated system.
     * @param endpoint The address of the associated system.
     *
     * Note: The system will not be able to control or upgrade the associated system, only communicate with it.
     */
    function registerUnmanagedSystem(bytes32 id, address endpoint) external;

    /**
     * @notice Retrieves an associated system.
     * @param id The bytes32 identifier used to reference the associated system.
     * @return addr The external contract address of the associated system.
     * @return kind The type of associated system (managed ERC20, managed ERC721, unmanaged, etc - See the AssociatedSystem util).
     */
    function getAssociatedSystem(bytes32 id) external view returns (address addr, bytes32 kind);
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import "@synthetixio/core-contracts/contracts/interfaces/IERC721Enumerable.sol";

/**
 * @title Module wrapping an ERC721 token implementation.
 */
interface INftModule is IERC721Enumerable {
    /**
     * @notice Returns wether the token has been initialized.
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
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title Module for giving a system owner based access control.
 */
// solhint-disable-next-line no-empty-blocks
interface IOwnerModule {

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
     * @param to The address whose tokens will be burnt.
     * @param amount The amount of tokens to burn.
     */
    function burn(address to, uint amount) external;

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

import "@synthetixio/core-contracts/contracts/errors/InitError.sol";
import "@synthetixio/core-contracts/contracts/ownership/OwnableStorage.sol";
import "@synthetixio/core-contracts/contracts/proxy/UUPSProxyWithOwner.sol";
import "../interfaces/IAssociatedSystemsModule.sol";

import "@synthetixio/core-contracts/contracts/interfaces/IUUPSImplementation.sol";
import "../interfaces/IOwnerModule.sol";
import "../interfaces/ITokenModule.sol";
import "../interfaces/INftModule.sol";

import "../storage/AssociatedSystem.sol";

/**
 * @title Module for connecting a system with other associated systems.
 * @dev See IAssociatedSystemsModule.
 */
contract AssociatedSystemsModule is IAssociatedSystemsModule {
    using AssociatedSystem for AssociatedSystem.Data;

    /**
     * @inheritdoc IAssociatedSystemsModule
     */
    function initOrUpgradeToken(
        bytes32 id,
        string memory name,
        string memory symbol,
        uint8 decimals,
        address impl
    ) external override {
        OwnableStorage.onlyOwner();
        _initOrUpgradeToken(id, name, symbol, decimals, impl);
    }

    /**
     * @inheritdoc IAssociatedSystemsModule
     */
    function initOrUpgradeNft(
        bytes32 id,
        string memory name,
        string memory symbol,
        string memory uri,
        address impl
    ) external override {
        OwnableStorage.onlyOwner();
        _initOrUpgradeNft(id, name, symbol, uri, impl);
    }

    /**
     * @inheritdoc IAssociatedSystemsModule
     */
    function registerUnmanagedSystem(bytes32 id, address endpoint) external override {
        OwnableStorage.onlyOwner();
        // empty string require kind will make sure the system is either unregistered or already unmanaged
        AssociatedSystem.load(id).expectKind("");

        _setAssociatedSystem(id, AssociatedSystem.KIND_UNMANAGED, endpoint, endpoint);
    }

    /**
     * @inheritdoc IAssociatedSystemsModule
     */
    function getAssociatedSystem(
        bytes32 id
    ) external view override returns (address addr, bytes32 kind) {
        addr = AssociatedSystem.load(id).proxy;
        kind = AssociatedSystem.load(id).kind;
    }

    modifier onlyIfAssociated(bytes32 id) {
        if (address(AssociatedSystem.load(id).proxy) == address(0)) {
            revert MissingAssociatedSystem(id);
        }

        _;
    }

    function _setAssociatedSystem(bytes32 id, bytes32 kind, address proxy, address impl) internal {
        AssociatedSystem.load(id).set(proxy, impl, kind);
        emit AssociatedSystemSet(kind, id, proxy, impl);
    }

    function _upgradeToken(bytes32 id, address impl) internal {
        AssociatedSystem.Data storage store = AssociatedSystem.load(id);
        store.expectKind(AssociatedSystem.KIND_ERC20);

        store.impl = impl;

        address proxy = store.proxy;

        // tell the associated proxy to upgrade to the new implementation
        IUUPSImplementation(proxy).upgradeTo(impl);

        _setAssociatedSystem(id, AssociatedSystem.KIND_ERC20, proxy, impl);
    }

    function _upgradeNft(bytes32 id, address impl) internal {
        AssociatedSystem.Data storage store = AssociatedSystem.load(id);
        store.expectKind(AssociatedSystem.KIND_ERC721);

        store.impl = impl;

        address proxy = store.proxy;

        // tell the associated proxy to upgrade to the new implementation
        IUUPSImplementation(proxy).upgradeTo(impl);

        _setAssociatedSystem(id, AssociatedSystem.KIND_ERC721, proxy, impl);
    }

    function _initOrUpgradeToken(
        bytes32 id,
        string memory name,
        string memory symbol,
        uint8 decimals,
        address impl
    ) internal {
        AssociatedSystem.Data storage store = AssociatedSystem.load(id);

        if (store.proxy != address(0)) {
            _upgradeToken(id, impl);
        } else {
            // create a new proxy and own it
            address proxy = address(new UUPSProxyWithOwner(impl, address(this)));

            ITokenModule(proxy).initialize(name, symbol, decimals);

            _setAssociatedSystem(id, AssociatedSystem.KIND_ERC20, proxy, impl);
        }
    }

    function _initOrUpgradeNft(
        bytes32 id,
        string memory name,
        string memory symbol,
        string memory uri,
        address impl
    ) internal {
        OwnableStorage.onlyOwner();
        AssociatedSystem.Data storage store = AssociatedSystem.load(id);

        if (store.proxy != address(0)) {
            _upgradeNft(id, impl);
        } else {
            // create a new proxy and own it
            address proxy = address(new UUPSProxyWithOwner(impl, address(this)));

            INftModule(proxy).initialize(name, symbol, uri);

            _setAssociatedSystem(id, AssociatedSystem.KIND_ERC721, proxy, impl);
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import {OwnerModule} from "./OwnerModule.sol";
import {UpgradeModule} from "./UpgradeModule.sol";

// solhint-disable-next-line no-empty-blocks
contract CoreModule is OwnerModule, UpgradeModule {

}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import "@synthetixio/core-contracts/contracts/token/ERC721Enumerable.sol";
import "@synthetixio/core-contracts/contracts/utils/AddressUtil.sol";
import "@synthetixio/core-contracts/contracts/initializable/InitializableMixin.sol";
import "@synthetixio/core-contracts/contracts/ownership/OwnableStorage.sol";
import "@synthetixio/core-contracts/contracts/errors/AddressError.sol";

import "../storage/Initialized.sol";

import "../interfaces/INftModule.sol";

/**
 * @title Module wrapping an ERC721 token implementation.
 * See INftModule.
 */
contract NftModule is INftModule, ERC721Enumerable, InitializableMixin {
    bytes32 internal constant _INITIALIZED_NAME = "NftModule";

    /**
     * @inheritdoc INftModule
     */
    function isInitialized() external view returns (bool) {
        return _isInitialized();
    }

    /**
     * @inheritdoc INftModule
     */
    function initialize(
        string memory tokenName,
        string memory tokenSymbol,
        string memory uri
    ) public {
        OwnableStorage.onlyOwner();

        _initialize(tokenName, tokenSymbol, uri);
        Initialized.load(_INITIALIZED_NAME).initialized = true;
    }

    /**
     * @inheritdoc INftModule
     */
    function burn(uint256 tokenId) external override {
        OwnableStorage.onlyOwner();
        _burn(tokenId);
    }

    /**
     * @inheritdoc INftModule
     */
    function mint(address to, uint256 tokenId) external override {
        OwnableStorage.onlyOwner();
        _mint(to, tokenId);
    }

    /**
     * @inheritdoc INftModule
     */
    function safeMint(address to, uint256 tokenId, bytes memory data) external override {
        OwnableStorage.onlyOwner();
        _mint(to, tokenId);

        if (!_checkOnERC721Received(address(0), to, tokenId, data)) {
            revert InvalidTransferRecipient(to);
        }
    }

    /**
     * @inheritdoc INftModule
     */
    function setAllowance(uint tokenId, address spender) external override {
        OwnableStorage.onlyOwner();
        ERC721Storage.load().tokenApprovals[tokenId] = spender;
    }

    function _isInitialized() internal view override returns (bool) {
        return Initialized.load(_INITIALIZED_NAME).initialized;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import "@synthetixio/core-contracts/contracts/ownership/Ownable.sol";
import "@synthetixio/core-contracts/contracts/initializable/InitializableMixin.sol";
import "../interfaces/IOwnerModule.sol";

/**
 * @title Module for giving a system owner based access control.
 * See IOwnerModule.
 */
contract OwnerModule is Ownable, IOwnerModule {
    // solhint-disable-next-line no-empty-blocks
    constructor() Ownable(address(0)) {
        // empty intentionally
    }

    // no impl intentionally
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import "@synthetixio/core-contracts/contracts/proxy/UUPSImplementation.sol";
import "@synthetixio/core-contracts/contracts/ownership/OwnableStorage.sol";

contract UpgradeModule is UUPSImplementation {
    function upgradeTo(address newImplementation) public override {
        OwnableStorage.onlyOwner();
        _upgradeTo(newImplementation);
    }
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

    function load(bytes32 id) internal pure returns (Data storage store) {
        bytes32 s = keccak256(abi.encode("io.synthetix.core-modules.AssociatedSystem", id));
        assembly {
            store.slot := s
        }
    }

    bytes32 public constant KIND_ERC20 = "erc20";
    bytes32 public constant KIND_ERC721 = "erc721";
    bytes32 public constant KIND_UNMANAGED = "unmanaged";

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

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

library Initialized {
    struct Data {
        bool initialized;
    }

    function load(bytes32 id) internal pure returns (Data storage store) {
        bytes32 s = keccak256(abi.encode("io.synthetix.code-modules.Initialized", id));
        assembly {
            store.slot := s
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

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

library InputErrors {
    error ZeroAmount();
    error ZeroAddress();
    error ZeroId();
    error ZeroTime();
    error AlreadyInitialized();
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

library ProfileErrors {
    error InvalidProfile();
    error NonExistentProfile();
    error UnauthorizedProfile();
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

library SubscriptionErrors {
    error InvalidCreator();
    error InvalidRate();
    error AlreadySubscribed();
    error NotSubscribed();
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

library VaultErrors {
    error VaultAlreadyInitialized();
    error VaultNotInitialized();
    error InvalidVault();
    error InsufficientAllowance();
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IBalancesModule {
    /**
     * @notice Return the current profile balance from a vault
     * @param profileId The profile to return the balance
     * @param vaultId The vault from where return the balance
     * @return The current balance
     */
    function balanceOf(
        bytes32 profileId,
        bytes32 vaultId
    ) external view returns (int256);

    /**
     * @notice Return the current profile flow from a vault
     * @param profileId The profile to return the flow
     * @param vaultId The vault from where return the flow
     * @return The current flow
     */
    function getFlow(
        bytes32 profileId,
        bytes32 vaultId
    ) external view returns (int256);

    /**
     * @notice Check if a profile can be liquidated from a vault
     * @param profileId The profile to check the liquidation
     * @param vaultId The vault from where to check the liquidation
     * @return If profile/vault is liquidable
     */
    function canBeLiquidated(
        bytes32 profileId,
        bytes32 vaultId
    ) external view returns (bool);

    /**
     * @notice Return the profile remaining time to zero balance from a vault
     * @param profileId The profile to return the remaining time
     * @param vaultId The vault from where return the remaining time
     * @return Time left
     */
    function getRemainingTimeToZero(
        bytes32 profileId,
        bytes32 vaultId
    ) external view returns (uint256);

    /**
     * @notice Return the current profile balance data from a vault
     * @dev It bundle all balance data in one function
     * @param profileId The profile to return the current data
     * @param vaultId The vault from where return the current data
     * @return balance Current balance
     * @return flow Current flow
     * @return liquidable If profile/vault is liquidable
     * @return timeLeft Time left to zero balance
     */
    function getBalanceCurrentData(
        bytes32 profileId,
        bytes32 vaultId
    )
        external
        view
        returns (
            int256 balance,
            int256 flow,
            bool liquidable,
            uint256 timeLeft
        );
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IConfigModule {
    /**************************************************************************
     * Governance functions
     *************************************************************************/

    /**
     * @notice Initialize the grateful system configuration
     * @dev Only owner / Emits `ConfigInitialized` event
     * @param solvencyTimeRequired The time required to remain solvent (allow to start new susbscriptions or withdrawals)
     * @param liquidationTimeRequired The time required to avoid liquidation
     */
    function initializeConfigModule(
        uint256 solvencyTimeRequired,
        uint256 liquidationTimeRequired
    ) external;

    /**
     * @notice Change the time required to remain solvent
     * @dev Only owner / Emits `SolvencyTimeChanged` event
     * @param newSolvencyTime The new time required to remain solvent
     */
    function setSolvencyTimeRequired(uint256 newSolvencyTime) external;

    /**
     * @notice Change the time required to avoid liquidation
     * @dev Only owner / Emits `LiquidationTimeChanged` event
     * @param newLiquidationTime The new time required to avoid liquidation
     */
    function setLiquidationTimeRequired(uint256 newLiquidationTime) external;

    /**************************************************************************
     * View functions
     *************************************************************************/

    /**
     * @notice Return the current solvency time required
     * @return Solvency time
     */
    function getSolvencyTimeRequired() external returns (uint256);

    /**
     * @notice Return the current liquidation time required
     * @return Liquidation time
     */
    function getLiquidationTimeRequired() external returns (uint256);

    /**************************************************************************
     * Events
     *************************************************************************/

    /**
     * @notice Emits the initial configuration
     * @param solvencyTimeRequired The time required to remain solvent
     * @param liquidationTimeRequired The time required to avoid liquidation
     */
    event ConfigInitialized(
        uint256 solvencyTimeRequired,
        uint256 liquidationTimeRequired
    );

    /**
     * @notice Emits the solvency time change
     * @param oldSolvencyTime The old time required to remain solvent
     * @param newSolvencyTime The new time required to remain solvent
     */
    event SolvencyTimeChanged(uint256 oldSolvencyTime, uint256 newSolvencyTime);

    /**
     * @notice Emits the liquidation time change
     * @param oldLiquidationTime The old time required to avoid liquidation
     * @param newLiquidationTime The new time required to avoid liquidation
     */
    event LiquidationTimeChanged(
        uint256 oldLiquidationTime,
        uint256 newLiquidationTime
    );
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IFeesModule {
    /**************************************************************************
     * Governance functions
     *************************************************************************/

    /**
     * @notice Initialize the grateful system fees
     * @dev Only owner / Emits `FeesInitialized` event
     * @param gratefulFeeTreasury The Grateful treasury profile ID
     * @param feePercentage The fee percentage to take from giver subscriptions
     */
    function initializeFeesModule(
        bytes32 gratefulFeeTreasury,
        uint256 feePercentage
    ) external;

    /**
     * @notice Change the grateful fee treasury
     * @dev Only owner / Emits `GratefulFeeTreasuryChanged` event
     * @param newTreasury The new grateful fee treasury
     */
    function setGratefulFeeTreasury(bytes32 newTreasury) external;

    /**
     * @notice Change the fee percentage
     * @dev Only owner / Emits `FeePercentageChanged` event
     * @param newFeePercentage The new fee percentage
     */
    function setFeePercentage(uint256 newFeePercentage) external;

    /**************************************************************************
     * View functions
     *************************************************************************/

    /**
     * @notice Return the current Grateful treasury profile ID
     * @return Treasury profile ID
     */
    function getFeeTreasuryId() external view returns (bytes32);

    /**
     * @notice Return the current fee percentage
     * @return Fee percentage
     */
    function getFeePercentage() external view returns (uint256);

    /**
     * @notice Return the current fee rate from a subscription rate
     * @param rate The subscription rate to take fee from
     * @return Fee rate
     */
    function getFeeRate(uint256 rate) external view returns (uint256);

    /**************************************************************************
     * Events
     *************************************************************************/

    /**
     * @notice Emits the initial fees configuration
     * @param gratefulFeeTreasury The Grateful treasury profile ID
     * @param feePercentage The fee percentage to take from giver subscriptions
     */
    event FeesInitialized(bytes32 gratefulFeeTreasury, uint256 feePercentage);

    /**
     * @notice Emits the grateful fee treasury change
     * @param oldTreasury The old grateful fee treasury
     * @param newTreasury The new grateful fee treasury
     */
    event GratefulFeeTreasuryChanged(bytes32 oldTreasury, bytes32 newTreasury);

    /**
     * @notice Emits the fee percentage change
     * @param oldFeePercentage The old fee percentage
     * @param newFeePercentage The new fee percentage
     */
    event FeePercentageChanged(
        uint256 oldFeePercentage,
        uint256 newFeePercentage
    );
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IFundsModule {
    /**
     * @notice Deposit funds into Grateful.
     *
     * Requirements:
     *
     * - Only profiles NFTs allowed on the system
     * - Only existing profile token ID
     * - Only vaults initialized into the system
     * - Emits `FundsDeposited` event
     *
     * @param profile The profile NFT address
     * @param tokenId The token ID from the profile NFT
     * @param vaultId The vault ID to deposit into
     * @param amount The amount of the vault asset to deposit
     */
    function depositFunds(
        address profile,
        uint256 tokenId,
        bytes32 vaultId,
        uint256 amount
    ) external;

    /**
     * @notice Withdraw funds from Grateful.
     *
     * Requirements:
     *
     * - Only profiles NFTs allowed on the system
     * - Only profile token ID owner or approved
     * - Only vaults initialized into the system
     * - Profile ID must have enough vault balance to withdraw
     * - Profile ID must have enough vault balance to remain solvent for `solvencyTimeRequired`
     * - Emits `FundsWithdrawn` event
     *
     * @param profile The profile NFT address
     * @param tokenId The token ID from the profile NFT
     * @param vaultId The vault ID to withdraw from
     * @param shares The amount of vault shares to withdraw
     */
    function withdrawFunds(
        address profile,
        uint256 tokenId,
        bytes32 vaultId,
        uint256 shares
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IGratefulSubscription {
    function safeMint(address to) external;

    function getCurrentTokenId() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface ILiquidationsModule {
    /**
     * @notice Liquidate subscription from giver to creator.
     *
     * Requirements:
     *
     * - Giver and creator cannot be the same
     * - Creator cannot be Grateful treasury
     * - Giver must be subscribed to creator
     * - Only vaults initialized into the system
     * - Giver vault balance must be liquidable (the balance to remain solvent is less then `liquidationTimeRequired`)
     * - Emits a `SubscriptionFinished` and `SubscriptionLiquidated` events
     *
     * @param giverId The giver ID from the subscription to liquidate
     * @param creatorId The creator ID from the subscription to liquidate
     * @param liquidatorId The liquidator ID to send the liquidation rewards
     *
     */
    function liquidate(
        bytes32 giverId,
        bytes32 creatorId,
        bytes32 liquidatorId
    ) external;

    /**************************************************************************
     * Events
     *************************************************************************/

    /**
     * @notice Emits the data from the liquidated subscription
     * @param giverId The ID from the profile that was subscribed
     * @param creatorId The ID from the profile that was receiving the subscription
     * @param liquidatorId The ID from the profile that liquidated the subscription
     * @param vaultId The vault being used in the subscription
     * @param subscriptionId The subscription ID from the Grateful Subscription NFT
     * @param reward The reward that the liquidator receive
     * @param surplus The surplus from the balance that was compensated (if any)
     */
    event SubscriptionLiquidated(
        bytes32 indexed giverId,
        bytes32 indexed creatorId,
        bytes32 indexed liquidatorId,
        bytes32 vaultId,
        uint256 subscriptionId,
        uint256 reward,
        uint256 surplus
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

interface IProfilesModule {
    /**************************************************************************
     * User functions
     *************************************************************************/

    /**
     * @notice Create a new profile
     * @dev Mint a Grateful Profile NFT / Emits `ProfileCreated` event
     * @param to The address to mint the profile NFT
     */
    function createProfile(address to) external;

    /**************************************************************************
     * Governance functions
     *************************************************************************/

    /**
     * @notice Allow profile NFT to be used on Grateful
     * @dev Only owner / Emits `ProfileAllowed` event
     * @param profile The profile NFT address to allow
     */
    function allowProfile(address profile) external;

    /**
     * @notice Disallow profile NFT to be used on Grateful
     * @dev Only owner / Emits `ProfileDisallowed` event
     * @param profile The profile NFT address to disallow
     */
    function disallowProfile(address profile) external;

    /**************************************************************************
     * View functions
     *************************************************************************/

    /**
     * @notice Return if a profile is allowed
     * @return Allowed flag
     */
    function isProfileAllowed(address profile) external view returns (bool);

    /**
     * @notice Return a profile ID
     * @dev The profile ID is a hash from the profile address and the token ID
     * @param profile The profile NFT address
     * @param tokenId The token ID from the profile NFT
     * @return The profile ID
     */
    function getProfileId(
        address profile,
        uint256 tokenId
    ) external pure returns (bytes32);

    /**
     * @notice Return if the sender is approved or owner to the profile token ID, and also return the profile ID
     * @param profile The profile NFT address
     * @param tokenId The token ID from the profile NFT
     * @param sender The address to check wether if it is approved or owner
     * @return isApproved If it is approved or owner
     * @return profileId The profile ID
     */
    function getApprovedAndProfileId(
        address profile,
        uint256 tokenId,
        address sender
    ) external view returns (bool isApproved, bytes32 profileId);

    /**************************************************************************
     * Events
     *************************************************************************/

    /**
     * @notice Emits the new profile created
     * @param owner The new profile owner address
     * @param tokenId The Grateful Profile NFT token ID minted
     */
    event ProfileCreated(address indexed owner, uint256 tokenId);

    /**
     * @notice Emits the profile allowed
     * @param profile The profile address that was allowed
     */
    event ProfileAllowed(address indexed profile);

    /**
     * @notice Emits the profile disallowed
     * @param profile The profile address that was disallowed
     */
    event ProfileDisallowed(address indexed profile);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Subscription} from "../storage/Subscription.sol";

interface ISubscriptionsModule {
    /**
     * @notice Start subscription from giver to creator.
     *
     * Requirements:
     *
     * - Only profiles NFTs allowed on the system
     * - Only giver profile token ID owner or approved
     * - Only existing creator profile token ID
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
     * @param giverProfile The giver profile NFT address
     * @param giverTokenId The giver token ID from the giver profile NFT
     * @param creatorProfile The creator profile NFT address
     * @param creatorTokenId The creator token ID from the creator profile NFT
     * @param vaultId The vault ID from where start the subscription
     * @param subscriptionRate The subscription rate from giver balance to creator balance (1e-20/second)
     *
     */
    function subscribe(
        address giverProfile,
        uint256 giverTokenId,
        address creatorProfile,
        uint256 creatorTokenId,
        bytes32 vaultId,
        uint256 subscriptionRate
    ) external;

    /**
     * @notice End subscription from giver to creator.
     *
     * Requirements:
     *
     * - Only profiles NFTs allowed on the system
     * - Only giver profile token ID owner or approved
     * - Only existing creator profile token ID
     * - Giver and creator cannot be the same
     * - Creator cannot be Grateful treasury
     * - Giver must be subscribed to creator
     * - Emits `SubscriptionFinished` event
     *
     * @param giverProfile The giver profile NFT address
     * @param giverTokenId The giver token ID from the giver profile NFT
     * @param creatorProfile The creator profile NFT address
     * @param creatorTokenId The creator token ID from the creator profile NFT
     */
    function unsubscribe(
        address giverProfile,
        uint256 giverTokenId,
        address creatorProfile,
        uint256 creatorTokenId
    ) external;

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
     * @param id The vault ID (any bytes32 defined by the owner)
     * @param impl The vault implementation address
     * @param minRate Minimum subscription rate allowed for this vault
     * @param maxRate Maximum subscription rate allowed for this vault
     */
    function addVault(
        bytes32 id,
        address impl,
        uint256 minRate,
        uint256 maxRate
    ) external;

    /**
     * @notice Change the vault minimum rate
     * @dev Only owner / Emits `MinRateChanged` event / Vault must be initialized
     * @param id The vault ID to change the minimum rate
     * @param newMinRate The new minimum rate
     */
    function setMinRate(bytes32 id, uint256 newMinRate) external;

    /**
     * @notice Change the vault maximum rate
     * @dev Only owner / Emits `MaxRateChanged` event / Vault must be initialized
     * @param id The vault ID to change the maximum rate
     * @param newMaxRate The new maximum rate
     */
    function setMaxRate(bytes32 id, uint256 newMaxRate) external;

    /**
     * @notice Pause a vault to avoid deposits, withdrawals or subscriptions
     * @dev Only owner / Emits `VaultPaused` event / Vault must be initialized
     * @param id The vault ID to pause
     */
    function pauseVault(bytes32 id) external;

    /**
     * @notice Pause a vault to allow deposits, withdrawals or subscriptions
     * @dev Only owner / Emits `VaultUnpaused` event / Vault must be initialized
     * @param id The vault ID to unpause
     */
    function unpauseVault(bytes32 id) external;

    /**************************************************************************
     * View functions
     *************************************************************************/

    /**
     * @notice Return a vault address
     * @param id The vault ID from where to return the address
     * @return The vault address
     */
    function getVault(bytes32 id) external view returns (address);

    /**************************************************************************
     * Events
     *************************************************************************/

    /**
     * @notice Emits the vault added data
     * @param id The vault ID (any bytes32 defined by the owner)
     * @param impl The vault implementation address
     * @param minRate The vault minimum rate
     * @param maxRate The vault maximum rate
     */
    event VaultAdded(
        bytes32 indexed id,
        address impl,
        uint256 minRate,
        uint256 maxRate
    );

    /**
     * @notice Emits the vault minimum rate change
     * @param id The vault ID
     * @param oldMinRate The old minimum rate
     * @param newMinRate The new minimum rate
     */
    event MinRateChanged(
        bytes32 indexed id,
        uint256 oldMinRate,
        uint256 newMinRate
    );

    /**
     * @notice Emits the vault maximum rate change
     * @param id The vault ID
     * @param oldMaxRate The old maximum rate
     * @param newMaxRate The new maximum rate
     */
    event MaxRateChanged(
        bytes32 indexed id,
        uint256 oldMaxRate,
        uint256 newMaxRate
    );

    /**
     * @notice Emits when a vault is paused
     * @param id The vault ID
     */
    event VaultPaused(bytes32 indexed id);

    /**
     * @notice Emits when a vault is unpaused
     * @param id The vault ID
     */
    event VaultUnpaused(bytes32 indexed id);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {AssociatedSystemsModule as BaseAssociatedSystemsModule} from "@synthetixio/core-modules/contracts/modules/AssociatedSystemsModule.sol";

// solhint-disable-next-line no-empty-blocks
contract GratefulAssociatedSystemsModule is BaseAssociatedSystemsModule {

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {NftModule} from "@synthetixio/core-modules/contracts/modules/NftModule.sol";

// solhint-disable-next-line no-empty-blocks
contract GratefulProfile is NftModule {

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {NftModule} from "@synthetixio/core-modules/contracts/modules/NftModule.sol";
import {ERC721} from "@synthetixio/core-contracts/contracts/token/ERC721.sol";
import {OwnableStorage} from "@synthetixio/core-contracts/contracts/ownership/OwnableStorage.sol";
import {SubscriptionNft} from "../../storage/SubscriptionNft.sol";

contract GratefulSubscription is ERC721 {
    using SubscriptionNft for SubscriptionNft.Data;

    function initialize(
        string memory tokenName,
        string memory tokenSymbol,
        string memory uri
    ) public {
        OwnableStorage.onlyOwner();

        SubscriptionNft.load().incrementCounter();

        _initialize(tokenName, tokenSymbol, uri);
    }

    function mint(address to) external {
        OwnableStorage.onlyOwner();

        SubscriptionNft.Data storage store = SubscriptionNft.load();

        uint256 tokenId = store.tokenIdCounter;
        store.incrementCounter();

        _mint(to, tokenId);
    }

    function getCurrentTokenId() external view returns (uint256) {
        return SubscriptionNft.load().tokenIdCounter;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IBalancesModule} from "../interfaces/IBalancesModule.sol";
import {Balance} from "../storage/Balance.sol";

contract BalancesModule is IBalancesModule {
    using Balance for Balance.Data;

    /// @inheritdoc	IBalancesModule
    function balanceOf(
        bytes32 profileId,
        bytes32 vaultId
    ) external view override returns (int256) {
        return Balance.load(profileId, vaultId).balanceOf();
    }

    /// @inheritdoc	IBalancesModule
    function getFlow(
        bytes32 profileId,
        bytes32 vaultId
    ) external view override returns (int256) {
        return Balance.load(profileId, vaultId).flow;
    }

    /// @inheritdoc	IBalancesModule
    function canBeLiquidated(
        bytes32 profileId,
        bytes32 vaultId
    ) external view override returns (bool) {
        return Balance.load(profileId, vaultId).canBeLiquidated();
    }

    /// @inheritdoc	IBalancesModule
    function getRemainingTimeToZero(
        bytes32 profileId,
        bytes32 vaultId
    ) external view override returns (uint256) {
        return Balance.load(profileId, vaultId).remainingTimeToZero();
    }

    /// @inheritdoc	IBalancesModule
    function getBalanceCurrentData(
        bytes32 profileId,
        bytes32 vaultId
    )
        external
        view
        override
        returns (int256 balance, int256 flow, bool liquidable, uint256 timeLeft)
    {
        Balance.Data storage store = Balance.load(profileId, vaultId);

        balance = store.balanceOf();
        flow = store.flow;
        liquidable = store.canBeLiquidated();
        timeLeft = store.remainingTimeToZero();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Config} from "../storage/Config.sol";
import {IConfigModule} from "../interfaces/IConfigModule.sol";
import {OwnableStorage} from "@synthetixio/core-contracts/contracts/ownership/OwnableStorage.sol";
import {InputErrors} from "../errors/InputErrors.sol";

contract ConfigModule is IConfigModule {
    using Config for Config.Data;

    /// @inheritdoc	IConfigModule
    function initializeConfigModule(
        uint256 solvencyTimeRequired,
        uint256 liquidationTimeRequired
    ) external override {
        OwnableStorage.onlyOwner();

        if (solvencyTimeRequired == 0) revert InputErrors.ZeroTime();
        if (liquidationTimeRequired == 0) revert InputErrors.ZeroTime();

        Config.Data storage store = Config.load();

        if (store.isInitialized()) revert InputErrors.AlreadyInitialized();

        store.setSolvencyTimeRequired(solvencyTimeRequired);
        store.setLiquidationTimeRequired(liquidationTimeRequired);

        emit ConfigInitialized(solvencyTimeRequired, liquidationTimeRequired);
    }

    /// @inheritdoc	IConfigModule
    function setSolvencyTimeRequired(
        uint256 newSolvencyTime
    ) external override {
        OwnableStorage.onlyOwner();
        if (newSolvencyTime == 0) revert InputErrors.ZeroTime();

        Config.Data storage config = Config.load();

        uint256 oldSolvencyTime = config.solvencyTimeRequired;
        config.setSolvencyTimeRequired(newSolvencyTime);

        emit SolvencyTimeChanged(oldSolvencyTime, newSolvencyTime);
    }

    /// @inheritdoc	IConfigModule
    function setLiquidationTimeRequired(
        uint256 newLiquidationTime
    ) external override {
        OwnableStorage.onlyOwner();
        if (newLiquidationTime == 0) revert InputErrors.ZeroTime();

        Config.Data storage config = Config.load();

        uint256 oldLiquidationTime = config.liquidationTimeRequired;
        config.setLiquidationTimeRequired(newLiquidationTime);

        emit LiquidationTimeChanged(oldLiquidationTime, newLiquidationTime);
    }

    /// @inheritdoc	IConfigModule
    function getSolvencyTimeRequired()
        external
        view
        override
        returns (uint256)
    {
        return Config.load().solvencyTimeRequired;
    }

    /// @inheritdoc	IConfigModule
    function getLiquidationTimeRequired()
        external
        view
        override
        returns (uint256)
    {
        return Config.load().liquidationTimeRequired;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {CoreModule} from "@synthetixio/core-modules/contracts/modules/CoreModule.sol";

// solhint-disable-next-line no-empty-blocks
contract MainCoreModule is CoreModule {

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Fee} from "../storage/Fee.sol";
import {IFeesModule} from "../interfaces/IFeesModule.sol";
import {OwnableStorage} from "@synthetixio/core-contracts/contracts/ownership/OwnableStorage.sol";
import {InputErrors} from "../errors/InputErrors.sol";

contract FeesModule is IFeesModule {
    using Fee for Fee.Data;

    /// @inheritdoc	IFeesModule
    function initializeFeesModule(
        bytes32 gratefulFeeTreasury,
        uint256 feePercentage
    ) external override {
        OwnableStorage.onlyOwner();

        if (gratefulFeeTreasury == bytes32(0)) revert InputErrors.ZeroId();
        if (feePercentage == 0) revert InputErrors.ZeroAmount();

        Fee.Data storage store = Fee.load();

        if (store.isInitialized()) revert InputErrors.AlreadyInitialized();

        store.setGratefulFeeTreasury(gratefulFeeTreasury);
        store.setFeePercentage(feePercentage);

        emit FeesInitialized(gratefulFeeTreasury, feePercentage);
    }

    /// @inheritdoc	IFeesModule
    function setGratefulFeeTreasury(bytes32 newTreasury) external override {
        OwnableStorage.onlyOwner();
        if (newTreasury == 0) revert InputErrors.ZeroId();

        Fee.Data storage store = Fee.load();

        bytes32 oldTreasury = store.gratefulFeeTreasury;
        store.setGratefulFeeTreasury(newTreasury);

        emit GratefulFeeTreasuryChanged(oldTreasury, newTreasury);
    }

    /// @inheritdoc	IFeesModule
    function setFeePercentage(uint256 newFeePercentage) external override {
        OwnableStorage.onlyOwner();

        Fee.Data storage store = Fee.load();

        uint256 oldFeePercentage = store.feePercentage;
        store.setFeePercentage(newFeePercentage);

        emit FeePercentageChanged(oldFeePercentage, newFeePercentage);
    }

    /// @inheritdoc	IFeesModule
    function getFeeTreasuryId() external view override returns (bytes32) {
        return Fee.load().gratefulFeeTreasury;
    }

    /// @inheritdoc	IFeesModule
    function getFeePercentage() external view override returns (uint256) {
        return Fee.load().feePercentage;
    }

    /// @inheritdoc	IFeesModule
    function getFeeRate(uint256 rate) external view override returns (uint256) {
        return Fee.load().getFeeRate(rate);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IFundsModule} from "../interfaces/IFundsModule.sol";
import {ProfileUtil} from "../utils/ProfileUtil.sol";
import {VaultUtil} from "../utils/VaultUtil.sol";
import {InputErrors} from "../errors/InputErrors.sol";
import {VaultErrors} from "../errors/VaultErrors.sol";
import {BalanceErrors} from "../errors/BalanceErrors.sol";
import {Balance} from "../storage/Balance.sol";

contract FundsModule is IFundsModule {
    using Balance for Balance.Data;

    /**
     * @notice Emits the funds deposited from a profile into a vault
     * @param profileId The profile ID that made the deposit
     * @param vaultId The vault that the deposit where made into
     * @param amount The vault asset amount that was deposited
     * @param shares The shares minted from the vault (normalized to 20 decimals)
     */
    event FundsDeposited(
        bytes32 indexed profileId,
        bytes32 indexed vaultId,
        uint256 amount,
        uint256 shares
    );

    /**
     * @notice Emits the funds withdrawn from a profile from a vault
     * @param profileId The profile ID that made the withdrawal
     * @param vaultId The vault that received the withdrawal
     * @param shares The vault shares amount that were withdrawn
     * @param amountWithdrawn The vault asset amount that was withdrawn
     */
    event FundsWithdrawn(
        bytes32 indexed profileId,
        bytes32 indexed vaultId,
        uint256 shares,
        uint256 amountWithdrawn
    );

    /// @inheritdoc	IFundsModule
    function depositFunds(
        address profile,
        uint256 tokenId,
        bytes32 vaultId,
        uint256 amount
    ) external override {
        if (amount == 0) revert InputErrors.ZeroAmount();

        if (!VaultUtil.isVaultActive(vaultId))
            revert VaultErrors.InvalidVault();

        (bytes32 profileId, ) = ProfileUtil.validateExistenceAndGetProfile(
            profile,
            tokenId
        );

        uint256 shares = VaultUtil.deposit(vaultId, amount);

        Balance.load(profileId, vaultId).increase(shares);

        emit FundsDeposited(profileId, vaultId, amount, shares);
    }

    /// @inheritdoc	IFundsModule
    function withdrawFunds(
        address profile,
        uint256 tokenId,
        bytes32 vaultId,
        uint256 shares
    ) external override {
        if (shares == 0) revert InputErrors.ZeroAmount();

        if (!VaultUtil.isVaultActive(vaultId))
            revert VaultErrors.InvalidVault();

        (, bytes32 profileId, ) = ProfileUtil.validateAllowanceAndGetProfile(
            profile,
            tokenId
        );

        Balance.Data storage store = Balance.load(profileId, vaultId);

        int256 balance = store.settle();
        if (balance < 0 || uint256(balance) < shares)
            revert BalanceErrors.InsufficientBalance();

        store.decrease(shares);

        if (!store.canWithdraw()) revert BalanceErrors.InsolventUser();

        uint256 amountWithdrawn = VaultUtil.withdraw(vaultId, shares);

        emit FundsWithdrawn(profileId, vaultId, shares, amountWithdrawn);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {ILiquidationsModule} from "../interfaces/ILiquidationsModule.sol";
import {SubscriptionUtil} from "../utils/SubscriptionUtil.sol";
import {SubscriptionErrors} from "../errors/SubscriptionErrors.sol";
import {BalanceErrors} from "../errors/BalanceErrors.sol";
import {Balance} from "../storage/Balance.sol";
import {SubscriptionId} from "../storage/SubscriptionId.sol";
import {Subscription} from "../storage/Subscription.sol";
import {Fee} from "../storage/Fee.sol";
import {SignedMath} from "@openzeppelin/contracts/utils/math/SignedMath.sol";

contract LiquidationsModule is ILiquidationsModule {
    using SignedMath for int256;
    using Balance for Balance.Data;
    using SubscriptionId for SubscriptionId.Data;
    using Subscription for Subscription.Data;
    using Fee for Fee.Data;

    /// @inheritdoc	ILiquidationsModule
    function liquidate(
        bytes32 giverId,
        bytes32 creatorId,
        bytes32 liquidatorId
    ) external override {
        bytes32 treasury = Fee.load().gratefulFeeTreasury;
        if (giverId == creatorId || creatorId == treasury)
            revert SubscriptionErrors.InvalidCreator();

        if (!SubscriptionId.load(giverId, creatorId).isSubscribed())
            revert SubscriptionErrors.NotSubscribed();

        bytes32 vaultId = SubscriptionId
            .load(giverId, creatorId)
            .getSubscriptionData()
            .vaultId;

        if (!Balance.load(giverId, vaultId).canBeLiquidated())
            revert BalanceErrors.SolventUser();

        (uint256 subscriptionId, , , uint256 surplus) = _liquidateSubscription(
            giverId,
            creatorId,
            vaultId
        );

        emit SubscriptionLiquidated(
            giverId,
            creatorId,
            liquidatorId,
            vaultId,
            subscriptionId,
            0,
            surplus
        );
    }

    function _liquidateSubscription(
        bytes32 giverId,
        bytes32 creatorId,
        bytes32 vaultId
    )
        private
        returns (
            uint256 subscriptionId,
            uint256 subscriptionRate,
            uint256 feeRate,
            uint256 surplus
        )
    {
        // Get current flow
        int256 flow = Balance.load(giverId, vaultId).flow;

        // Finish subscription
        (subscriptionId, subscriptionRate, feeRate, ) = SubscriptionUtil
            .finishSubscription(giverId, creatorId);

        // Check if balance is negative and compensate if necessary
        if (Balance.load(giverId, vaultId).isNegative()) {
            surplus = _settleLostBalance(
                giverId,
                creatorId,
                vaultId,
                subscriptionRate,
                feeRate,
                flow
            );
        }
    }

    function _settleLostBalance(
        bytes32 giverId,
        bytes32 creatorId,
        bytes32 vaultId,
        uint256 rate,
        uint256 feeRate,
        int256 flow
    ) private returns (uint256 surplus) {
        // Get absolute values
        uint256 absoluteBalance = Balance
            .load(giverId, vaultId)
            .balanceOf()
            .abs();

        uint256 totalFlow = flow.abs();

        // Decrease creator balance surplus
        uint256 subscriptionRateSurplus = (rate * absoluteBalance) / totalFlow;
        Balance.load(creatorId, vaultId).decrease(subscriptionRateSurplus);

        // Decrease treasury balance surplus
        uint256 feeRateSurplus = (feeRate * absoluteBalance) / totalFlow;
        bytes32 treasury = Fee.load().gratefulFeeTreasury;
        Balance.load(treasury, vaultId).decrease(feeRateSurplus);

        // Increase giver balance total surplus
        surplus = ((rate + feeRate) * absoluteBalance) / totalFlow;
        Balance.load(giverId, vaultId).increase(surplus);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IProfilesModule} from "../interfaces/IProfilesModule.sol";
import {Profile} from "../storage/Profile.sol";
import {ProfileUtil} from "../utils/ProfileUtil.sol";
import {GratefulProfile} from "./associated-systems/GratefulProfile.sol";
import {OwnableStorage} from "@synthetixio/core-contracts/contracts/ownership/OwnableStorage.sol";
import {AssociatedSystem} from "@synthetixio/core-modules/contracts/storage/AssociatedSystem.sol";
import {InputErrors} from "../errors/InputErrors.sol";

contract ProfilesModule is IProfilesModule {
    using Profile for Profile.Data;
    using AssociatedSystem for AssociatedSystem.Data;

    bytes32 private constant _GRATEFUL_PROFILE_NFT = "gratefulProfileNft";

    /// @inheritdoc	IProfilesModule
    function createProfile(address to) external override {
        GratefulProfile profile = GratefulProfile(
            AssociatedSystem.load(_GRATEFUL_PROFILE_NFT).proxy
        );

        uint256 tokenId = profile.totalSupply() + 1;

        profile.mint(to, tokenId);

        emit ProfileCreated(to, tokenId);
    }

    /// @inheritdoc	IProfilesModule
    function allowProfile(address profile) external override {
        OwnableStorage.onlyOwner();

        if (profile == address(0)) revert InputErrors.ZeroAddress();

        Profile.load(profile).allow();

        emit ProfileAllowed(profile);
    }

    /// @inheritdoc	IProfilesModule
    function disallowProfile(address profile) external override {
        OwnableStorage.onlyOwner();

        if (profile == address(0)) revert InputErrors.ZeroAddress();

        Profile.load(profile).disallow();

        emit ProfileDisallowed(profile);
    }

    /// @inheritdoc	IProfilesModule
    function isProfileAllowed(address profile) external view returns (bool) {
        return Profile.load(profile).allowed;
    }

    /// @inheritdoc	IProfilesModule
    function getProfileId(
        address profile,
        uint256 tokenId
    ) external pure returns (bytes32) {
        return Profile.getProfileId(profile, tokenId);
    }

    /// @inheritdoc	IProfilesModule
    function getApprovedAndProfileId(
        address profile,
        uint256 tokenId,
        address sender
    ) external view returns (bool isApproved, bytes32 profileId) {
        (isApproved, profileId, ) = ProfileUtil.getApprovedAndProfileId(
            profile,
            tokenId,
            sender
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {ISubscriptionsModule} from "../interfaces/ISubscriptionsModule.sol";
import {SubscriptionUtil} from "../utils/SubscriptionUtil.sol";
import {ProfileUtil} from "../utils/ProfileUtil.sol";
import {VaultUtil} from "../utils/VaultUtil.sol";
import {SubscriptionErrors} from "../errors/SubscriptionErrors.sol";
import {VaultErrors} from "../errors/VaultErrors.sol";
import {BalanceErrors} from "../errors/BalanceErrors.sol";
import {Balance} from "../storage/Balance.sol";
import {Subscription} from "../storage/Subscription.sol";
import {SubscriptionId} from "../storage/SubscriptionId.sol";
import {Fee} from "../storage/Fee.sol";
import {GratefulSubscription} from "./associated-systems/GratefulSubscription.sol";
import {AssociatedSystem} from "@synthetixio/core-modules/contracts/storage/AssociatedSystem.sol";

contract SubscriptionsModule is ISubscriptionsModule {
    using Balance for Balance.Data;
    using Subscription for Subscription.Data;
    using SubscriptionId for SubscriptionId.Data;
    using Fee for Fee.Data;
    using AssociatedSystem for AssociatedSystem.Data;

    bytes32 private constant _GRATEFUL_SUBSCRIPTION_NFT =
        "gratefulSubscriptionNft";

    /// @inheritdoc ISubscriptionsModule
    function subscribe(
        address giverProfile,
        uint256 giverTokenId,
        address creatorProfile,
        uint256 creatorTokenId,
        bytes32 vaultId,
        uint256 subscriptionRate
    ) external override {
        if (!VaultUtil.isVaultActive(vaultId))
            revert VaultErrors.InvalidVault();

        (, bytes32 giverId, address profileOwner) = ProfileUtil
            .validateAllowanceAndGetProfile(giverProfile, giverTokenId);

        (bytes32 creatorId, ) = ProfileUtil.validateExistenceAndGetProfile(
            creatorProfile,
            creatorTokenId
        );

        bytes32 treasury = Fee.load().gratefulFeeTreasury;
        if (giverId == creatorId || creatorId == treasury)
            revert SubscriptionErrors.InvalidCreator();

        if (SubscriptionId.load(giverId, creatorId).isSubscribed())
            revert SubscriptionErrors.AlreadySubscribed();

        if (!VaultUtil.isRateValid(vaultId, subscriptionRate))
            revert SubscriptionErrors.InvalidRate();

        uint256 rate = VaultUtil.getCurrentRate(vaultId, subscriptionRate);

        (
            uint256 subscriptionId,
            uint256 feeRate,
            uint256 totalRate
        ) = _startSubscription(giverId, creatorId, vaultId, rate, profileOwner);

        if (!Balance.load(giverId, vaultId).canStartSubscription(totalRate))
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

    function _startSubscription(
        bytes32 giverId,
        bytes32 creatorId,
        bytes32 vaultId,
        uint256 subscriptionRate,
        address profileOwner
    )
        private
        returns (uint256 subscriptionId, uint256 feeRate, uint256 totalRate)
    {
        // Calculate fee rate
        feeRate = Fee.load().getFeeRate(subscriptionRate);

        // Decrease giver flow
        totalRate = subscriptionRate + feeRate;
        Balance.load(giverId, vaultId).decreaseFlow(totalRate);

        // Increase creator flow
        Balance.load(creatorId, vaultId).increaseFlow(subscriptionRate);

        // Increase treasury flow with feeRate
        bytes32 treasury = Fee.load().gratefulFeeTreasury;
        Balance.load(treasury, vaultId).increaseFlow(feeRate);

        if (SubscriptionId.load(giverId, creatorId).exists()) {
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

    function _createSubscription(
        bytes32 giverId,
        bytes32 creatorId,
        bytes32 vaultId,
        uint256 subscriptionRate,
        uint256 feeRate,
        address profileOwner
    ) private returns (uint256 subscriptionId) {
        // Get subscription ID from subscription NFT
        GratefulSubscription gs = GratefulSubscription(
            AssociatedSystem.load(_GRATEFUL_SUBSCRIPTION_NFT).proxy
        );
        subscriptionId = gs.getCurrentTokenId();

        // Start subscription
        Subscription.Data storage subscription = Subscription.load(
            subscriptionId
        );
        subscription.start(subscriptionRate, feeRate, creatorId, vaultId);

        // Link subscription ID with subscription data
        SubscriptionId.load(giverId, creatorId).set(subscriptionId);

        // Mint subscription NFT to giver profile owner
        gs.mint(profileOwner);
    }

    function _updateSubscription(
        bytes32 giverId,
        bytes32 creatorId,
        bytes32 vaultId,
        uint256 subscriptionRate,
        uint256 feeRate
    ) private returns (uint256 subscriptionId) {
        // Get subscription data
        subscriptionId = SubscriptionId.load(giverId, creatorId).subscriptionId;

        Subscription.Data storage subscription = Subscription.load(
            subscriptionId
        );

        // Update subscription
        subscription.update(subscriptionRate, feeRate, vaultId);
    }

    /// @inheritdoc ISubscriptionsModule
    function unsubscribe(
        address giverProfile,
        uint256 giverTokenId,
        address creatorProfile,
        uint256 creatorTokenId
    ) external override {
        (, bytes32 giverId, ) = ProfileUtil.validateAllowanceAndGetProfile(
            giverProfile,
            giverTokenId
        );

        (bytes32 creatorId, ) = ProfileUtil.validateExistenceAndGetProfile(
            creatorProfile,
            creatorTokenId
        );

        bytes32 treasury = Fee.load().gratefulFeeTreasury;
        if (giverId == creatorId || creatorId == treasury)
            revert SubscriptionErrors.InvalidCreator();

        if (!SubscriptionId.load(giverId, creatorId).isSubscribed())
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
        return SubscriptionId.load(giverId, creatorId).getSubscriptionData();
    }

    /// @inheritdoc ISubscriptionsModule
    function getSubscriptionId(
        bytes32 giverId,
        bytes32 creatorId
    ) external view override returns (uint256) {
        return SubscriptionId.load(giverId, creatorId).subscriptionId;
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
        return SubscriptionId.load(giverId, creatorId).isSubscribed();
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

import {Vault} from "../storage/Vault.sol";
import {IVaultsModule} from "../interfaces/IVaultsModule.sol";
import {OwnableStorage} from "@synthetixio/core-contracts/contracts/ownership/OwnableStorage.sol";
import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";
import {VaultErrors} from "../errors/VaultErrors.sol";
import {InputErrors} from "../errors/InputErrors.sol";

contract VaultsModule is IVaultsModule {
    using Vault for Vault.Data;

    /// @inheritdoc IVaultsModule
    function addVault(
        bytes32 id,
        address impl,
        uint256 minRate,
        uint256 maxRate
    ) external override {
        OwnableStorage.onlyOwner();

        if (id == bytes32(0)) revert InputErrors.ZeroId();
        if (impl == address(0)) revert InputErrors.ZeroAddress();

        Vault.Data storage store = Vault.load(id);

        if (store.isInitialized()) revert VaultErrors.VaultAlreadyInitialized();

        uint256 decimalsNormalizer = 10 ** (20 - IERC4626(impl).decimals());

        store.set(impl, decimalsNormalizer, minRate, maxRate);

        emit VaultAdded(id, impl, minRate, maxRate);
    }

    function _validateVaultPermissions(bytes32 id) private view {
        OwnableStorage.onlyOwner();

        if (!Vault.load(id).isInitialized())
            revert VaultErrors.VaultNotInitialized();
    }

    /// @inheritdoc IVaultsModule
    function setMinRate(bytes32 id, uint256 newMinRate) external override {
        _validateVaultPermissions(id);

        Vault.Data storage vault = Vault.load(id);
        uint256 oldMinRate = vault.minRate;
        vault.setMinRate(newMinRate);

        emit MinRateChanged(id, oldMinRate, newMinRate);
    }

    /// @inheritdoc IVaultsModule
    function setMaxRate(bytes32 id, uint256 newMaxRate) external override {
        _validateVaultPermissions(id);

        Vault.Data storage vault = Vault.load(id);
        uint256 oldMaxRate = vault.maxRate;
        vault.setMaxRate(newMaxRate);

        emit MaxRateChanged(id, oldMaxRate, newMaxRate);
    }

    /// @inheritdoc IVaultsModule
    function pauseVault(bytes32 id) external override {
        _validateVaultPermissions(id);

        Vault.load(id).pause();

        emit VaultPaused(id);
    }

    /// @inheritdoc IVaultsModule
    function unpauseVault(bytes32 id) external override {
        _validateVaultPermissions(id);

        Vault.load(id).unpause();

        emit VaultUnpaused(id);
    }

    /// @inheritdoc IVaultsModule
    function getVault(bytes32 id) external view override returns (address) {
        return Vault.load(id).impl;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {UUPSProxyWithOwner} from "@synthetixio/core-contracts/contracts/proxy/UUPSProxyWithOwner.sol";

contract Proxy is UUPSProxyWithOwner {
    constructor(
        address firstImplementation,
        address initialOwner
    ) UUPSProxyWithOwner(firstImplementation, initialOwner) {}
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

// --------------------------------------------------------------------------------
// --------------------------------------------------------------------------------
// GENERATED CODE - do not edit manually!!
// --------------------------------------------------------------------------------
// --------------------------------------------------------------------------------

contract Router {
    error UnknownSelector(bytes4 sel);

    address private constant _MAIN_CORE_MODULE = 0xAD795078484243f5759aB55D98cD5Cf1A249b5b2;
    address private constant _BALANCES_MODULE = 0xAF2D5f6C6C67C9e7A0Fc1fF7Cd3288B920fA4ac8;
    address private constant _CONFIG_MODULE = 0xC594a796895839aa60A86C8DF58935376B7B2bc4;
    address private constant _FEES_MODULE = 0x85C03697Fe4297Ec41B4666e68eAeDEB22E2A3F4;
    address private constant _FUNDS_MODULE = 0x908748C1a93B551022fEC3b5820686F5E87fA1df;
    address private constant _LIQUIDATIONS_MODULE = 0x2c9C503EB328e83F8e9Fea3A23eB3155eeCF3236;
    address private constant _PROFILES_MODULE = 0x72C191074BA502956cCDF8ffc3FEe48181861296;
    address private constant _SUBSCRIPTIONS_MODULE = 0xc8cdE5347e5611EAb2AB461Ab70c3549FBEa5A84;
    address private constant _VAULTS_MODULE = 0x9Bf3e4E24F7a763419cBBB250A8D6C04B74Be2C0;

    fallback() external payable {
        _forward();
    }

    receive() external payable {
        _forward();
    }

    function _forward() internal {
        // Lookup table: Function selector => implementation contract
        bytes4 sig4 = msg.sig;
        address implementation;

        assembly {
            let sig32 := shr(224, sig4)

            function findImplementation(sig) -> result {
                if lt(sig,0x73ee1bf6) {
                    if lt(sig,0x39976ed7) {
                        if lt(sig,0x2e1120a1) {
                            switch sig
                            case 0x0e09db34 { result := _BALANCES_MODULE } // BalancesModule.getRemainingTimeToZero()
                            case 0x0e2a6a58 { result := _VAULTS_MODULE } // VaultsModule.pauseVault()
                            case 0x11d7a49d { result := _FEES_MODULE } // FeesModule.setGratefulFeeTreasury()
                            case 0x11efbf61 { result := _FEES_MODULE } // FeesModule.getFeePercentage()
                            case 0x1627540c { result := _MAIN_CORE_MODULE } // MainCoreModule.nominateNewOwner()
                            case 0x269c9ab6 { result := _CONFIG_MODULE } // ConfigModule.setLiquidationTimeRequired()
                            case 0x2d3e461f { result := _VAULTS_MODULE } // VaultsModule.setMaxRate()
                            leave
                        }
                        switch sig
                        case 0x2e1120a1 { result := _FUNDS_MODULE } // FundsModule.depositFunds()
                        case 0x3068e2f6 { result := _VAULTS_MODULE } // VaultsModule.setMinRate()
                        case 0x352e2760 { result := _FUNDS_MODULE } // FundsModule.withdrawFunds()
                        case 0x35eb2824 { result := _MAIN_CORE_MODULE } // MainCoreModule.isOwnerModuleInitialized()
                        case 0x3659cfe6 { result := _MAIN_CORE_MODULE } // MainCoreModule.upgradeTo()
                        case 0x38ed2de7 { result := _PROFILES_MODULE } // ProfilesModule.allowProfile()
                        leave
                    }
                    if lt(sig,0x624bd96d) {
                        switch sig
                        case 0x39976ed7 { result := _SUBSCRIPTIONS_MODULE } // SubscriptionsModule.getSubscriptionRates()
                        case 0x45fe26a2 { result := _CONFIG_MODULE } // ConfigModule.setSolvencyTimeRequired()
                        case 0x53a47bb7 { result := _MAIN_CORE_MODULE } // MainCoreModule.nominatedOwner()
                        case 0x564ab52d { result := _SUBSCRIPTIONS_MODULE } // SubscriptionsModule.getSubscriptionDuration()
                        case 0x5a0be8d0 { result := _PROFILES_MODULE } // ProfilesModule.isProfileAllowed()
                        case 0x610aabdc { result := _SUBSCRIPTIONS_MODULE } // SubscriptionsModule.subscribe()
                        leave
                    }
                    switch sig
                    case 0x624bd96d { result := _MAIN_CORE_MODULE } // MainCoreModule.initializeOwnerModule()
                    case 0x641f9561 { result := _PROFILES_MODULE } // ProfilesModule.getProfileId()
                    case 0x6aa2025b { result := _VAULTS_MODULE } // VaultsModule.addVault()
                    case 0x6ddc6588 { result := _SUBSCRIPTIONS_MODULE } // SubscriptionsModule.getSubscriptionFrom()
                    case 0x718fe928 { result := _MAIN_CORE_MODULE } // MainCoreModule.renounceNomination()
                    case 0x72777622 { result := _CONFIG_MODULE } // ConfigModule.initializeConfigModule()
                    leave
                }
                if lt(sig,0xc2f610e4) {
                    if lt(sig,0xaaf10f42) {
                        switch sig
                        case 0x73ee1bf6 { result := _CONFIG_MODULE } // ConfigModule.getLiquidationTimeRequired()
                        case 0x774e7eae { result := _PROFILES_MODULE } // ProfilesModule.getApprovedAndProfileId()
                        case 0x79ba5097 { result := _MAIN_CORE_MODULE } // MainCoreModule.acceptOwnership()
                        case 0x7f7f51a6 { result := _SUBSCRIPTIONS_MODULE } // SubscriptionsModule.getSubscriptionId()
                        case 0x8da5cb5b { result := _MAIN_CORE_MODULE } // MainCoreModule.owner()
                        case 0x9fdc9f4e { result := _PROFILES_MODULE } // ProfilesModule.disallowProfile()
                        leave
                    }
                    switch sig
                    case 0xaaf10f42 { result := _MAIN_CORE_MODULE } // MainCoreModule.getImplementation()
                    case 0xae06c1b7 { result := _FEES_MODULE } // FeesModule.setFeePercentage()
                    case 0xb1ffc03e { result := _BALANCES_MODULE } // BalancesModule.balanceOf()
                    case 0xb776ff6b { result := _SUBSCRIPTIONS_MODULE } // SubscriptionsModule.isSubscribed()
                    case 0xb7c61f06 { result := _VAULTS_MODULE } // VaultsModule.getVault()
                    case 0xc2637d01 { result := _FEES_MODULE } // FeesModule.initializeFeesModule()
                    leave
                }
                if lt(sig,0xdc311dd3) {
                    switch sig
                    case 0xc2f610e4 { result := _SUBSCRIPTIONS_MODULE } // SubscriptionsModule.unsubscribe()
                    case 0xc6fd3fcb { result := _BALANCES_MODULE } // BalancesModule.canBeLiquidated()
                    case 0xc7f62cda { result := _MAIN_CORE_MODULE } // MainCoreModule.simulateUpgradeTo()
                    case 0xd2aaef4e { result := _FEES_MODULE } // FeesModule.getFeeRate()
                    case 0xd3d77f79 { result := _CONFIG_MODULE } // ConfigModule.getGratefulSubscription()
                    case 0xd5b3e4d9 { result := _LIQUIDATIONS_MODULE } // LiquidationsModule.liquidate()
                    leave
                }
                switch sig
                case 0xdc311dd3 { result := _SUBSCRIPTIONS_MODULE } // SubscriptionsModule.getSubscription()
                case 0xe6701923 { result := _BALANCES_MODULE } // BalancesModule.getFlow()
                case 0xfae82647 { result := _VAULTS_MODULE } // VaultsModule.unpauseVault()
                case 0xfc725969 { result := _FEES_MODULE } // FeesModule.getFeeTreasuryId()
                case 0xfcacdcdf { result := _CONFIG_MODULE } // ConfigModule.getSolvencyTimeRequired()
                case 0xffdd4ce8 { result := _BALANCES_MODULE } // BalancesModule.getBalanceCurrentData()
                leave
            }

            implementation := findImplementation(sig32)
        }

        if (implementation == address(0)) {
            revert UnknownSelector(sig4);
        }

        // Delegatecall to the implementation contract
        assembly {
            calldatacopy(0, 0, calldatasize())

            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())

            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

// --------------------------------------------------------------------------------
// --------------------------------------------------------------------------------
// GENERATED CODE - do not edit manually!!
// --------------------------------------------------------------------------------
// --------------------------------------------------------------------------------

contract Router {
    error UnknownSelector(bytes4 sel);

    address private constant _MAIN_CORE_MODULE = 0x457cA3F194eA0133d7fD93dDf8e685A630d65582;
    address private constant _BALANCES_MODULE = 0x3009b75Eb035b915374686D67BBB4c992dc90338;
    address private constant _CONFIG_MODULE = 0x5cB333E8f6251F15a21503CDDD6016FfB82b112d;
    address private constant _FEES_MODULE = 0xeB6E7A0349ce9ca80cE582e56520f2Ec9096Ca3d;
    address private constant _FUNDS_MODULE = 0x07f60756D25958bA135d02880E1f1505C3F474b5;
    address private constant _LIQUIDATIONS_MODULE = 0xb1F09D4522238cEB99064A58E99A0163CBe1a9eE;
    address private constant _PROFILES_MODULE = 0xFA392fBf516a5aFD04bdfD85659fd75a2D6071f5;
    address private constant _SUBSCRIPTIONS_MODULE = 0x9400EDb5869Fa29804567E484363e19706EA656e;
    address private constant _VAULTS_MODULE = 0xAc3C27c94E276E156470bAF35e4dE549728aB799;

    fallback() external payable {
        _forward();
    }

    receive() external payable {
        _forward();
    }

    function _forward() internal {
        // Lookup table: Function selector => implementation contract
        bytes4 sig4 = msg.sig;
        address implementation;

        assembly {
            let sig32 := shr(224, sig4)

            function findImplementation(sig) -> result {
                if lt(sig,0x73ee1bf6) {
                    if lt(sig,0x39976ed7) {
                        if lt(sig,0x2e1120a1) {
                            switch sig
                            case 0x0e09db34 { result := _BALANCES_MODULE } // BalancesModule.getRemainingTimeToZero()
                            case 0x0e2a6a58 { result := _VAULTS_MODULE } // VaultsModule.pauseVault()
                            case 0x11d7a49d { result := _FEES_MODULE } // FeesModule.setGratefulFeeTreasury()
                            case 0x11efbf61 { result := _FEES_MODULE } // FeesModule.getFeePercentage()
                            case 0x1627540c { result := _MAIN_CORE_MODULE } // MainCoreModule.nominateNewOwner()
                            case 0x269c9ab6 { result := _CONFIG_MODULE } // ConfigModule.setLiquidationTimeRequired()
                            case 0x2d3e461f { result := _VAULTS_MODULE } // VaultsModule.setMaxRate()
                            leave
                        }
                        switch sig
                        case 0x2e1120a1 { result := _FUNDS_MODULE } // FundsModule.depositFunds()
                        case 0x3068e2f6 { result := _VAULTS_MODULE } // VaultsModule.setMinRate()
                        case 0x352e2760 { result := _FUNDS_MODULE } // FundsModule.withdrawFunds()
                        case 0x35eb2824 { result := _MAIN_CORE_MODULE } // MainCoreModule.isOwnerModuleInitialized()
                        case 0x3659cfe6 { result := _MAIN_CORE_MODULE } // MainCoreModule.upgradeTo()
                        case 0x38ed2de7 { result := _PROFILES_MODULE } // ProfilesModule.allowProfile()
                        leave
                    }
                    if lt(sig,0x624bd96d) {
                        switch sig
                        case 0x39976ed7 { result := _SUBSCRIPTIONS_MODULE } // SubscriptionsModule.getSubscriptionRates()
                        case 0x45fe26a2 { result := _CONFIG_MODULE } // ConfigModule.setSolvencyTimeRequired()
                        case 0x53a47bb7 { result := _MAIN_CORE_MODULE } // MainCoreModule.nominatedOwner()
                        case 0x564ab52d { result := _SUBSCRIPTIONS_MODULE } // SubscriptionsModule.getSubscriptionDuration()
                        case 0x5a0be8d0 { result := _PROFILES_MODULE } // ProfilesModule.isProfileAllowed()
                        case 0x610aabdc { result := _SUBSCRIPTIONS_MODULE } // SubscriptionsModule.subscribe()
                        leave
                    }
                    switch sig
                    case 0x624bd96d { result := _MAIN_CORE_MODULE } // MainCoreModule.initializeOwnerModule()
                    case 0x641f9561 { result := _PROFILES_MODULE } // ProfilesModule.getProfileId()
                    case 0x6aa2025b { result := _VAULTS_MODULE } // VaultsModule.addVault()
                    case 0x6ddc6588 { result := _SUBSCRIPTIONS_MODULE } // SubscriptionsModule.getSubscriptionFrom()
                    case 0x718fe928 { result := _MAIN_CORE_MODULE } // MainCoreModule.renounceNomination()
                    case 0x72777622 { result := _CONFIG_MODULE } // ConfigModule.initializeConfigModule()
                    leave
                }
                if lt(sig,0xc2f610e4) {
                    if lt(sig,0xaaf10f42) {
                        switch sig
                        case 0x73ee1bf6 { result := _CONFIG_MODULE } // ConfigModule.getLiquidationTimeRequired()
                        case 0x774e7eae { result := _PROFILES_MODULE } // ProfilesModule.getApprovedAndProfileId()
                        case 0x79ba5097 { result := _MAIN_CORE_MODULE } // MainCoreModule.acceptOwnership()
                        case 0x7f7f51a6 { result := _SUBSCRIPTIONS_MODULE } // SubscriptionsModule.getSubscriptionId()
                        case 0x8da5cb5b { result := _MAIN_CORE_MODULE } // MainCoreModule.owner()
                        case 0x9fdc9f4e { result := _PROFILES_MODULE } // ProfilesModule.disallowProfile()
                        leave
                    }
                    switch sig
                    case 0xaaf10f42 { result := _MAIN_CORE_MODULE } // MainCoreModule.getImplementation()
                    case 0xae06c1b7 { result := _FEES_MODULE } // FeesModule.setFeePercentage()
                    case 0xb1ffc03e { result := _BALANCES_MODULE } // BalancesModule.balanceOf()
                    case 0xb776ff6b { result := _SUBSCRIPTIONS_MODULE } // SubscriptionsModule.isSubscribed()
                    case 0xb7c61f06 { result := _VAULTS_MODULE } // VaultsModule.getVault()
                    case 0xc2637d01 { result := _FEES_MODULE } // FeesModule.initializeFeesModule()
                    leave
                }
                if lt(sig,0xdc311dd3) {
                    switch sig
                    case 0xc2f610e4 { result := _SUBSCRIPTIONS_MODULE } // SubscriptionsModule.unsubscribe()
                    case 0xc6fd3fcb { result := _BALANCES_MODULE } // BalancesModule.canBeLiquidated()
                    case 0xc7f62cda { result := _MAIN_CORE_MODULE } // MainCoreModule.simulateUpgradeTo()
                    case 0xd2aaef4e { result := _FEES_MODULE } // FeesModule.getFeeRate()
                    case 0xd3d77f79 { result := _CONFIG_MODULE } // ConfigModule.getGratefulSubscription()
                    case 0xd5b3e4d9 { result := _LIQUIDATIONS_MODULE } // LiquidationsModule.liquidate()
                    leave
                }
                switch sig
                case 0xdc311dd3 { result := _SUBSCRIPTIONS_MODULE } // SubscriptionsModule.getSubscription()
                case 0xe6701923 { result := _BALANCES_MODULE } // BalancesModule.getFlow()
                case 0xfae82647 { result := _VAULTS_MODULE } // VaultsModule.unpauseVault()
                case 0xfc725969 { result := _FEES_MODULE } // FeesModule.getFeeTreasuryId()
                case 0xfcacdcdf { result := _CONFIG_MODULE } // ConfigModule.getSolvencyTimeRequired()
                case 0xffdd4ce8 { result := _BALANCES_MODULE } // BalancesModule.getBalanceCurrentData()
                leave
            }

            implementation := findImplementation(sig32)
        }

        if (implementation == address(0)) {
            revert UnknownSelector(sig4);
        }

        // Delegatecall to the implementation contract
        assembly {
            calldatacopy(0, 0, calldatasize())

            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())

            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

// --------------------------------------------------------------------------------
// --------------------------------------------------------------------------------
// GENERATED CODE - do not edit manually!!
// --------------------------------------------------------------------------------
// --------------------------------------------------------------------------------

contract Router {
    error UnknownSelector(bytes4 sel);

    address private constant _MAIN_CORE_MODULE = 0xA8492cf12026AA5989de54928a292f543d25B7b4;
    address private constant _BALANCES_MODULE = 0xEc3A13e1a71F948dE4F167E172769E38b0B4C01F;
    address private constant _CONFIG_MODULE = 0x40464f4b914CE09E2BaD985aB9f496da5bA8E87f;
    address private constant _FEES_MODULE = 0xB069633756f4ED2E090D2A4aFcE95F928A50F0eF;
    address private constant _FUNDS_MODULE = 0x4BD210812719b50F18393ed9A6A820c283286fAf;
    address private constant _LIQUIDATIONS_MODULE = 0x463cB1D390Fed763b0944aab2c7A9FA12B4c07b8;
    address private constant _PROFILES_MODULE = 0x304dc2cda27d7902C36601f20046286118296828;
    address private constant _SUBSCRIPTIONS_MODULE = 0x803cD4f7a9B0e63D36aF82567233EFEf542C00f2;
    address private constant _VAULTS_MODULE = 0x06E3a0fC1F34fb9D9Cc9f277775A30Dda9094a11;

    fallback() external payable {
        _forward();
    }

    receive() external payable {
        _forward();
    }

    function _forward() internal {
        // Lookup table: Function selector => implementation contract
        bytes4 sig4 = msg.sig;
        address implementation;

        assembly {
            let sig32 := shr(224, sig4)

            function findImplementation(sig) -> result {
                if lt(sig,0x79ba5097) {
                    if lt(sig,0x564ab52d) {
                        if lt(sig,0x35eb2824) {
                            switch sig
                            case 0x0e09db34 { result := _BALANCES_MODULE } // BalancesModule.getRemainingTimeToZero()
                            case 0x11efbf61 { result := _FEES_MODULE } // FeesModule.getFeePercentage()
                            case 0x1627540c { result := _MAIN_CORE_MODULE } // MainCoreModule.nominateNewOwner()
                            case 0x2e1120a1 { result := _FUNDS_MODULE } // FundsModule.depositFunds()
                            case 0x352e2760 { result := _FUNDS_MODULE } // FundsModule.withdrawFunds()
                            leave
                        }
                        switch sig
                        case 0x35eb2824 { result := _MAIN_CORE_MODULE } // MainCoreModule.isOwnerModuleInitialized()
                        case 0x3659cfe6 { result := _MAIN_CORE_MODULE } // MainCoreModule.upgradeTo()
                        case 0x38ed2de7 { result := _PROFILES_MODULE } // ProfilesModule.allowProfile()
                        case 0x39976ed7 { result := _SUBSCRIPTIONS_MODULE } // SubscriptionsModule.getSubscriptionRates()
                        case 0x53a47bb7 { result := _MAIN_CORE_MODULE } // MainCoreModule.nominatedOwner()
                        leave
                    }
                    if lt(sig,0x6aa2025b) {
                        switch sig
                        case 0x564ab52d { result := _SUBSCRIPTIONS_MODULE } // SubscriptionsModule.getSubscriptionDuration()
                        case 0x5a0be8d0 { result := _PROFILES_MODULE } // ProfilesModule.isProfileAllowed()
                        case 0x610aabdc { result := _SUBSCRIPTIONS_MODULE } // SubscriptionsModule.subscribe()
                        case 0x624bd96d { result := _MAIN_CORE_MODULE } // MainCoreModule.initializeOwnerModule()
                        case 0x641f9561 { result := _PROFILES_MODULE } // ProfilesModule.getProfileId()
                        leave
                    }
                    switch sig
                    case 0x6aa2025b { result := _VAULTS_MODULE } // VaultsModule.addVault()
                    case 0x6ddc6588 { result := _SUBSCRIPTIONS_MODULE } // SubscriptionsModule.getSubscriptionFrom()
                    case 0x718fe928 { result := _MAIN_CORE_MODULE } // MainCoreModule.renounceNomination()
                    case 0x72777622 { result := _CONFIG_MODULE } // ConfigModule.initializeConfigModule()
                    case 0x73ee1bf6 { result := _CONFIG_MODULE } // ConfigModule.getLiquidationTimeRequired()
                    leave
                }
                if lt(sig,0xc6fd3fcb) {
                    if lt(sig,0xb1ffc03e) {
                        switch sig
                        case 0x79ba5097 { result := _MAIN_CORE_MODULE } // MainCoreModule.acceptOwnership()
                        case 0x7f7f51a6 { result := _SUBSCRIPTIONS_MODULE } // SubscriptionsModule.getSubscriptionId()
                        case 0x8da5cb5b { result := _MAIN_CORE_MODULE } // MainCoreModule.owner()
                        case 0x9fdc9f4e { result := _PROFILES_MODULE } // ProfilesModule.disallowProfile()
                        case 0xaaf10f42 { result := _MAIN_CORE_MODULE } // MainCoreModule.getImplementation()
                        leave
                    }
                    switch sig
                    case 0xb1ffc03e { result := _BALANCES_MODULE } // BalancesModule.balanceOf()
                    case 0xb776ff6b { result := _SUBSCRIPTIONS_MODULE } // SubscriptionsModule.isSubscribed()
                    case 0xb7c61f06 { result := _VAULTS_MODULE } // VaultsModule.getVault()
                    case 0xc2637d01 { result := _FEES_MODULE } // FeesModule.initializeFeesModule()
                    case 0xc2f610e4 { result := _SUBSCRIPTIONS_MODULE } // SubscriptionsModule.unsubscribe()
                    leave
                }
                switch sig
                case 0xc6fd3fcb { result := _BALANCES_MODULE } // BalancesModule.canBeLiquidated()
                case 0xc7f62cda { result := _MAIN_CORE_MODULE } // MainCoreModule.simulateUpgradeTo()
                case 0xd2aaef4e { result := _FEES_MODULE } // FeesModule.getFeeRate()
                case 0xd3d77f79 { result := _CONFIG_MODULE } // ConfigModule.getGratefulSubscription()
                case 0xd5b3e4d9 { result := _LIQUIDATIONS_MODULE } // LiquidationsModule.liquidate()
                case 0xdc311dd3 { result := _SUBSCRIPTIONS_MODULE } // SubscriptionsModule.getSubscription()
                case 0xe6701923 { result := _BALANCES_MODULE } // BalancesModule.getFlow()
                case 0xfc725969 { result := _FEES_MODULE } // FeesModule.getFeeTreasuryId()
                case 0xfcacdcdf { result := _CONFIG_MODULE } // ConfigModule.getSolvencyTimeRequired()
                leave
            }

            implementation := findImplementation(sig32)
        }

        if (implementation == address(0)) {
            revert UnknownSelector(sig4);
        }

        // Delegatecall to the implementation contract
        assembly {
            calldatacopy(0, 0, calldatasize())

            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())

            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {SignedMath} from "@openzeppelin/contracts/utils/math/SignedMath.sol";
import {Config} from "../storage/Config.sol";

library Balance {
    using SafeCast for uint256;
    using SafeCast for int256;
    using SignedMath for int256;
    using Config for Config.Data;

    struct Data {
        int256 balance; // Total balance
        int216 flow; // Total flow (1e-20 per second)
        uint40 lastUpdate; // Last time profile balance was updated
    }

    function load(
        bytes32 profileId,
        bytes32 vaultId
    ) internal pure returns (Data storage store) {
        bytes32 s = keccak256(abi.encode("Balance", profileId, vaultId));
        assembly {
            store.slot := s
        }
    }

    function increase(Data storage self, uint256 amount) internal {
        self.balance += amount.toInt256();
    }

    function decrease(Data storage self, uint256 amount) internal {
        self.balance -= amount.toInt256();
    }

    function settle(Data storage self) internal returns (int256 newBalance) {
        newBalance = balanceOf(self);

        self.balance = newBalance;
        self.lastUpdate = (block.timestamp).toUint40();
    }

    function increaseFlow(Data storage self, uint256 amount) internal {
        settle(self);

        self.flow += (amount.toInt256()).toInt216();
    }

    function decreaseFlow(Data storage self, uint256 amount) internal {
        settle(self);

        self.flow -= (amount.toInt256()).toInt216();
    }

    function balanceOf(
        Data storage self
    ) internal view returns (int256 balance) {
        uint256 elapsedTime = _getElapsedTime(self.lastUpdate);

        balance = _calculateBalance(self.balance, self.flow, elapsedTime);
    }

    function _getElapsedTime(
        uint256 lastUpdate
    ) private view returns (uint256 elapsedTime) {
        if (lastUpdate == 0) return 0;
        if (block.timestamp <= lastUpdate) return 0;
        elapsedTime = block.timestamp - lastUpdate;
    }

    function _calculateBalance(
        int256 balance,
        int256 flow,
        uint256 time
    ) private pure returns (int256 currentBalance) {
        int256 totalFlow = flow * time.toInt256();

        currentBalance = balance + totalFlow;
    }

    function _isSolvent(
        Data storage self,
        uint256 time
    ) private view returns (bool) {
        uint256 futureElapsedTime = _getElapsedTime(self.lastUpdate) + time;

        return
            _calculateBalance(self.balance, self.flow, futureElapsedTime) > 0;
    }

    function canWithdraw(Data storage self) internal view returns (bool) {
        uint256 time = Config.load().solvencyTimeRequired;
        return _isSolvent(self, time);
    }

    function canStartSubscription(
        Data storage self,
        uint256 rate
    ) internal view returns (bool) {
        uint256 time = Config.load().solvencyTimeRequired;

        int256 balance = balanceOf(self);
        int256 requiredBalance = (rate * time).toInt256();
        bool hasEnoughBalance = balance > requiredBalance;

        return hasEnoughBalance && _isSolvent(self, time);
    }

    function canBeLiquidated(Data storage self) internal view returns (bool) {
        uint256 time = Config.load().liquidationTimeRequired;
        bool hasNegativeFlow = self.flow < 0;
        return hasNegativeFlow && !_isSolvent(self, time);
    }

    function isNegative(Data storage self) internal view returns (bool) {
        int256 balance = balanceOf(self);
        return balance < 0;
    }

    function remainingTimeToZero(
        Data storage self
    ) internal view returns (uint256) {
        int256 balance = balanceOf(self);
        int256 flow = self.flow;

        if (flow >= 0 || balance <= 0) {
            return 0;
        } else {
            return uint256(balance) / flow.abs();
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

library Config {
    bytes32 private constant CONFIG_STORAGE_SLOT =
        keccak256(abi.encode("Config"));

    struct Data {
        uint256 solvencyTimeRequired;
        uint256 liquidationTimeRequired;
    }

    function load() internal pure returns (Data storage store) {
        bytes32 s = CONFIG_STORAGE_SLOT;
        assembly {
            store.slot := s
        }
    }

    function setSolvencyTimeRequired(
        Data storage self,
        uint256 solvencyTime
    ) internal {
        self.solvencyTimeRequired = solvencyTime;
    }

    function setLiquidationTimeRequired(
        Data storage self,
        uint256 liquidationTime
    ) internal {
        self.liquidationTimeRequired = liquidationTime;
    }

    function isInitialized(Data storage self) internal view returns (bool) {
        return self.liquidationTimeRequired != 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

library Fee {
    using Math for uint256;

    bytes32 private constant FEE_STORAGE_SLOT = keccak256(abi.encode("Fee"));

    struct Data {
        bytes32 gratefulFeeTreasury;
        uint256 feePercentage;
    }

    function load() internal pure returns (Data storage store) {
        bytes32 s = FEE_STORAGE_SLOT;
        assembly {
            store.slot := s
        }
    }

    function setGratefulFeeTreasury(
        Data storage self,
        bytes32 gratefulFeeTreasury
    ) internal {
        self.gratefulFeeTreasury = gratefulFeeTreasury;
    }

    function setFeePercentage(
        Data storage self,
        uint256 feePercentage
    ) internal {
        self.feePercentage = feePercentage;
    }

    function isInitialized(Data storage self) internal view returns (bool) {
        return self.gratefulFeeTreasury != bytes32(0);
    }

    function getFeeRate(
        Data storage self,
        uint256 subscriptionRate
    ) internal view returns (uint256) {
        return subscriptionRate.mulDiv(self.feePercentage, 100);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

library Profile {
    struct Data {
        bool allowed;
    }

    function load(address profile) internal pure returns (Data storage store) {
        bytes32 s = keccak256(abi.encode("Profile", profile));
        assembly {
            store.slot := s
        }
    }

    function allow(Data storage self) internal {
        self.allowed = true;
    }

    function disallow(Data storage self) internal {
        self.allowed = false;
    }

    function isAllowed(Data storage self) internal view returns (bool) {
        return self.allowed;
    }

    function getProfileId(
        address profile,
        uint256 tokenId
    ) internal pure returns (bytes32 profileId) {
        profileId = keccak256(abi.encode(profile, tokenId));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";

library Subscription {
    using SafeCast for uint256;

    struct Data {
        uint256 rate;
        uint176 feeRate;
        uint40 lastUpdate;
        uint40 duration;
        bytes32 creatorId;
        bytes32 vaultId;
    }

    function load(
        uint256 subscriptionId
    ) internal pure returns (Data storage store) {
        bytes32 s = keccak256(abi.encode("Subscription", subscriptionId));
        assembly {
            store.slot := s
        }
    }

    function start(
        Data storage self,
        uint256 rate,
        uint256 feeRate,
        bytes32 creatorId,
        bytes32 vaultId
    ) internal {
        self.rate = rate;
        self.feeRate = feeRate.toUint176();
        self.lastUpdate = (block.timestamp).toUint40();
        self.creatorId = creatorId;
        self.vaultId = vaultId;
    }

    function update(
        Data storage self,
        uint256 rate,
        uint256 feeRate,
        bytes32 vaultId
    ) internal {
        self.rate = rate;
        self.feeRate = feeRate.toUint176();
        self.lastUpdate = (block.timestamp).toUint40();
        self.vaultId = vaultId;
    }

    function finish(Data storage self) internal {
        uint256 elapsedTime = block.timestamp - self.lastUpdate;

        self.rate = 0;
        self.feeRate = 0;
        self.lastUpdate = (block.timestamp).toUint40();
        self.duration += (elapsedTime).toUint40();
    }

    function isSubscribed(Data storage self) internal view returns (bool) {
        return self.rate != 0;
    }

    function getDuration(
        Data storage self
    ) internal view returns (uint256 duration) {
        uint256 elapsedTime = block.timestamp - self.lastUpdate;

        duration = self.duration + (elapsedTime).toUint128();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Subscription} from "./Subscription.sol";

library SubscriptionId {
    using Subscription for Subscription.Data;

    struct Data {
        uint256 subscriptionId;
    }

    function load(
        bytes32 giverId,
        bytes32 creatorId
    ) internal pure returns (Data storage store) {
        bytes32 s = keccak256(abi.encode("SubscriptionId", giverId, creatorId));
        assembly {
            store.slot := s
        }
    }

    function set(Data storage self, uint256 subscriptionId) internal {
        self.subscriptionId = subscriptionId;
    }

    function getSubscriptionData(
        Data storage self
    ) internal view returns (Subscription.Data storage subscriptionData) {
        return Subscription.load(self.subscriptionId);
    }

    function isSubscribed(Data storage self) internal view returns (bool) {
        return Subscription.load(self.subscriptionId).isSubscribed();
    }

    function exists(Data storage self) internal view returns (bool) {
        return self.subscriptionId != 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

library SubscriptionNft {
    struct Data {
        uint256 tokenIdCounter;
    }

    function load() internal pure returns (Data storage store) {
        bytes32 s = keccak256(abi.encode("SubscriptionNft"));
        assembly {
            store.slot := s
        }
    }

    function incrementCounter(Data storage self) internal {
        self.tokenIdCounter++;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

library Vault {
    struct Data {
        // address proxy;
        address impl;
        uint256 decimalsNormalizer;
        uint256 minRate;
        uint256 maxRate;
        bool paused;
    }

    function load(bytes32 id) internal pure returns (Data storage store) {
        bytes32 s = keccak256(abi.encode("Vault", id));
        assembly {
            store.slot := s
        }
    }

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

    function setMinRate(Data storage self, uint256 minRate) internal {
        self.minRate = minRate;
    }

    function setMaxRate(Data storage self, uint256 maxRate) internal {
        self.maxRate = maxRate;
    }

    function pause(Data storage self) internal {
        self.paused = true;
    }

    function unpause(Data storage self) internal {
        self.paused = false;
    }

    function getVault(Data storage self) internal view returns (address) {
        return self.impl;
    }

    function isInitialized(Data storage self) internal view returns (bool) {
        return self.impl != address(0);
    }

    function isActive(Data storage self) internal view returns (bool) {
        return self.impl != address(0) && !self.paused;
    }

    function isRateValid(
        Data storage self,
        uint256 rate
    ) internal view returns (bool) {
        return (rate >= self.minRate) && (rate <= self.maxRate);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Profile} from "../storage/Profile.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {ProfileErrors} from "../errors/ProfileErrors.sol";

library ProfileUtil {
    using Profile for Profile.Data;

    function _isApprovedOrOwner(
        address profile,
        address spender,
        uint256 tokenId,
        address owner
    ) private view returns (bool) {
        return (spender == owner ||
            IERC721(profile).isApprovedForAll(owner, spender) ||
            IERC721(profile).getApproved(tokenId) == spender);
    }

    function _getOwnerOf(
        address profile,
        uint256 tokenId
    ) private view returns (address) {
        return IERC721(profile).ownerOf(tokenId);
    }

    function validateExistenceAndGetProfile(
        address profile,
        uint256 tokenId
    ) internal view returns (bytes32 profileId, address owner) {
        Profile.Data storage store = Profile.load(profile);

        if (!store.isAllowed()) revert ProfileErrors.InvalidProfile();

        owner = _getOwnerOf(profile, tokenId);

        if (owner == address(0)) revert ProfileErrors.NonExistentProfile();

        profileId = Profile.getProfileId(profile, tokenId);
    }

    function getApprovedAndProfileId(
        address profile,
        uint256 tokenId,
        address sender
    )
        internal
        view
        returns (bool isApproved, bytes32 profileId, address owner)
    {
        (profileId, owner) = validateExistenceAndGetProfile(profile, tokenId);

        isApproved = _isApprovedOrOwner(profile, sender, tokenId, owner);
    }

    function validateAllowanceAndGetProfile(
        address profile,
        uint256 tokenId
    )
        internal
        view
        returns (bool isApproved, bytes32 profileId, address owner)
    {
        (isApproved, profileId, owner) = getApprovedAndProfileId(
            profile,
            tokenId,
            msg.sender
        );

        if (!isApproved) revert ProfileErrors.UnauthorizedProfile();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Balance} from "../storage/Balance.sol";
import {Subscription} from "../storage/Subscription.sol";
import {SubscriptionId} from "../storage/SubscriptionId.sol";
import {Fee} from "../storage/Fee.sol";

library SubscriptionUtil {
    using Balance for Balance.Data;
    using Subscription for Subscription.Data;

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
        subscriptionId = SubscriptionId.load(giverId, creatorId).subscriptionId;

        Subscription.Data storage subscription = Subscription.load(
            subscriptionId
        );

        subscriptionRate = subscription.rate;
        feeRate = subscription.feeRate;
        vaultId = subscription.vaultId;

        // Increase giver flow
        uint256 totalRate = subscriptionRate + feeRate;
        Balance.load(giverId, vaultId).increaseFlow(totalRate);

        // Decrease creator flow
        Balance.load(creatorId, vaultId).decreaseFlow(subscriptionRate);

        // Decrease treasury flow with feeRate
        bytes32 treasury = Fee.load().gratefulFeeTreasury;
        Balance.load(treasury, vaultId).decreaseFlow(feeRate);

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
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Vault} from "../storage/Vault.sol";
import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {VaultErrors} from "../errors/VaultErrors.sol";

library VaultUtil {
    using SafeERC20 for IERC20;
    using Vault for Vault.Data;

    /**************************************************************************
     * Vault interaction functions
     *************************************************************************/

    function deposit(
        bytes32 vaultId,
        uint256 amount
    ) internal returns (uint256 shares) {
        Vault.Data storage store = Vault.load(vaultId);
        IERC4626 vault = IERC4626(store.impl);

        _checkUserAllowance(vault, amount);

        IERC20(vault.asset()).safeTransferFrom(
            msg.sender,
            address(this),
            amount
        );

        IERC20(vault.asset()).approve(address(vault), amount);

        shares =
            vault.deposit({assets: amount, receiver: address(this)}) *
            store.decimalsNormalizer;
    }

    function withdraw(
        bytes32 vaultId,
        uint256 shares
    ) internal returns (uint256 amountWithdrawn) {
        Vault.Data storage store = Vault.load(vaultId);
        IERC4626 vault = IERC4626(store.impl);

        uint256 normalizedShares = shares / store.decimalsNormalizer;

        amountWithdrawn = vault.redeem({
            shares: normalizedShares,
            receiver: msg.sender,
            owner: address(this)
        });
    }

    /**************************************************************************
     * View functions
     *************************************************************************/
    function _checkUserAllowance(IERC4626 vault, uint256 amount) private view {
        uint256 allowance = IERC20(vault.asset()).allowance(
            msg.sender,
            address(this)
        );

        if (allowance < amount) revert VaultErrors.InsufficientAllowance();
    }

    function isVaultActive(bytes32 id) internal view returns (bool) {
        return Vault.load(id).isActive();
    }

    function isRateValid(
        bytes32 id,
        uint256 rate
    ) internal view returns (bool) {
        return Vault.load(id).isRateValid(rate);
    }

    function getCurrentRate(
        bytes32 id,
        uint256 subscriptionRate
    ) internal view returns (uint256) {
        Vault.Data storage store = Vault.load(id);
        IERC4626 vault = IERC4626(store.impl);

        return vault.convertToShares(subscriptionRate);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {AaveV2ERC4626, ERC20, IAaveMining, ILendingPool} from "lib/yield-daddy/src/aave-v2/AaveV2ERC4626.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

// @audit Migrate to router proxy
contract AaveV2Vault is AaveV2ERC4626, Ownable {
    constructor(
        ERC20 asset_,
        ERC20 aToken_,
        IAaveMining aaveMining_,
        address rewardRecipient_,
        ILendingPool lendingPool_,
        address newOwner
    )
        AaveV2ERC4626(
            asset_,
            aToken_,
            aaveMining_,
            rewardRecipient_,
            lendingPool_
        )
    {
        transferOwnership(newOwner);
    }

    function deposit(
        uint256 assets,
        address receiver
    ) public override onlyOwner returns (uint256 shares) {
        return super.deposit(assets, receiver);
    }

    function mint(
        uint256 shares,
        address receiver
    ) public override onlyOwner returns (uint256 assets) {
        return super.mint(shares, receiver);
    }

    function withdraw(
        uint256 assets,
        address receiver,
        address owner_
    ) public override onlyOwner returns (uint256 shares) {
        return super.withdraw(assets, receiver, owner_);
    }

    function redeem(
        uint256 shares,
        address receiver,
        address owner_
    ) public override onlyOwner returns (uint256 assets) {
        return super.redeem(shares, receiver, owner_);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {ERC20} from "../tokens/ERC20.sol";
import {SafeTransferLib} from "../utils/SafeTransferLib.sol";
import {FixedPointMathLib} from "../utils/FixedPointMathLib.sol";

/// @notice Minimal ERC4626 tokenized Vault implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/mixins/ERC4626.sol)
abstract contract ERC4626 is ERC20 {
    using SafeTransferLib for ERC20;
    using FixedPointMathLib for uint256;

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Deposit(address indexed caller, address indexed owner, uint256 assets, uint256 shares);

    event Withdraw(
        address indexed caller,
        address indexed receiver,
        address indexed owner,
        uint256 assets,
        uint256 shares
    );

    /*//////////////////////////////////////////////////////////////
                               IMMUTABLES
    //////////////////////////////////////////////////////////////*/

    ERC20 public immutable asset;

    constructor(
        ERC20 _asset,
        string memory _name,
        string memory _symbol
    ) ERC20(_name, _symbol, _asset.decimals()) {
        asset = _asset;
    }

    /*//////////////////////////////////////////////////////////////
                        DEPOSIT/WITHDRAWAL LOGIC
    //////////////////////////////////////////////////////////////*/

    function deposit(uint256 assets, address receiver) public virtual returns (uint256 shares) {
        // Check for rounding error since we round down in previewDeposit.
        require((shares = previewDeposit(assets)) != 0, "ZERO_SHARES");

        // Need to transfer before minting or ERC777s could reenter.
        asset.safeTransferFrom(msg.sender, address(this), assets);

        _mint(receiver, shares);

        emit Deposit(msg.sender, receiver, assets, shares);

        afterDeposit(assets, shares);
    }

    function mint(uint256 shares, address receiver) public virtual returns (uint256 assets) {
        assets = previewMint(shares); // No need to check for rounding error, previewMint rounds up.

        // Need to transfer before minting or ERC777s could reenter.
        asset.safeTransferFrom(msg.sender, address(this), assets);

        _mint(receiver, shares);

        emit Deposit(msg.sender, receiver, assets, shares);

        afterDeposit(assets, shares);
    }

    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) public virtual returns (uint256 shares) {
        shares = previewWithdraw(assets); // No need to check for rounding error, previewWithdraw rounds up.

        if (msg.sender != owner) {
            uint256 allowed = allowance[owner][msg.sender]; // Saves gas for limited approvals.

            if (allowed != type(uint256).max) allowance[owner][msg.sender] = allowed - shares;
        }

        beforeWithdraw(assets, shares);

        _burn(owner, shares);

        emit Withdraw(msg.sender, receiver, owner, assets, shares);

        asset.safeTransfer(receiver, assets);
    }

    function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) public virtual returns (uint256 assets) {
        if (msg.sender != owner) {
            uint256 allowed = allowance[owner][msg.sender]; // Saves gas for limited approvals.

            if (allowed != type(uint256).max) allowance[owner][msg.sender] = allowed - shares;
        }

        // Check for rounding error since we round down in previewRedeem.
        require((assets = previewRedeem(shares)) != 0, "ZERO_ASSETS");

        beforeWithdraw(assets, shares);

        _burn(owner, shares);

        emit Withdraw(msg.sender, receiver, owner, assets, shares);

        asset.safeTransfer(receiver, assets);
    }

    /*//////////////////////////////////////////////////////////////
                            ACCOUNTING LOGIC
    //////////////////////////////////////////////////////////////*/

    function totalAssets() public view virtual returns (uint256);

    function convertToShares(uint256 assets) public view virtual returns (uint256) {
        uint256 supply = totalSupply; // Saves an extra SLOAD if totalSupply is non-zero.

        return supply == 0 ? assets : assets.mulDivDown(supply, totalAssets());
    }

    function convertToAssets(uint256 shares) public view virtual returns (uint256) {
        uint256 supply = totalSupply; // Saves an extra SLOAD if totalSupply is non-zero.

        return supply == 0 ? shares : shares.mulDivDown(totalAssets(), supply);
    }

    function previewDeposit(uint256 assets) public view virtual returns (uint256) {
        return convertToShares(assets);
    }

    function previewMint(uint256 shares) public view virtual returns (uint256) {
        uint256 supply = totalSupply; // Saves an extra SLOAD if totalSupply is non-zero.

        return supply == 0 ? shares : shares.mulDivUp(totalAssets(), supply);
    }

    function previewWithdraw(uint256 assets) public view virtual returns (uint256) {
        uint256 supply = totalSupply; // Saves an extra SLOAD if totalSupply is non-zero.

        return supply == 0 ? assets : assets.mulDivUp(supply, totalAssets());
    }

    function previewRedeem(uint256 shares) public view virtual returns (uint256) {
        return convertToAssets(shares);
    }

    /*//////////////////////////////////////////////////////////////
                     DEPOSIT/WITHDRAWAL LIMIT LOGIC
    //////////////////////////////////////////////////////////////*/

    function maxDeposit(address) public view virtual returns (uint256) {
        return type(uint256).max;
    }

    function maxMint(address) public view virtual returns (uint256) {
        return type(uint256).max;
    }

    function maxWithdraw(address owner) public view virtual returns (uint256) {
        return convertToAssets(balanceOf[owner]);
    }

    function maxRedeem(address owner) public view virtual returns (uint256) {
        return balanceOf[owner];
    }

    /*//////////////////////////////////////////////////////////////
                          INTERNAL HOOKS LOGIC
    //////////////////////////////////////////////////////////////*/

    function beforeWithdraw(uint256 assets, uint256 shares) internal virtual {}

    function afterDeposit(uint256 assets, uint256 shares) internal virtual {}
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                            METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*//////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*//////////////////////////////////////////////////////////////
                            EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*//////////////////////////////////////////////////////////////
                               ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*//////////////////////////////////////////////////////////////
                             EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            address recoveredAddress = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                keccak256(
                                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                                ),
                                owner,
                                spender,
                                value,
                                nonces[owner]++,
                                deadline
                            )
                        )
                    )
                ),
                v,
                r,
                s
            );

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Arithmetic library with operations for fixed-point numbers.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/FixedPointMathLib.sol)
/// @author Inspired by USM (https://github.com/usmfum/USM/blob/master/contracts/WadMath.sol)
library FixedPointMathLib {
    /*//////////////////////////////////////////////////////////////
                    SIMPLIFIED FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    uint256 internal constant MAX_UINT256 = 2**256 - 1;

    uint256 internal constant WAD = 1e18; // The scalar of ETH and most ERC20s.

    function mulWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, y, WAD); // Equivalent to (x * y) / WAD rounded down.
    }

    function mulWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, y, WAD); // Equivalent to (x * y) / WAD rounded up.
    }

    function divWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, WAD, y); // Equivalent to (x * WAD) / y rounded down.
    }

    function divWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, WAD, y); // Equivalent to (x * WAD) / y rounded up.
    }

    /*//////////////////////////////////////////////////////////////
                    LOW LEVEL FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function mulDivDown(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        assembly {
            // Equivalent to require(denominator != 0 && (y == 0 || x <= type(uint256).max / y))
            if iszero(mul(denominator, iszero(mul(y, gt(x, div(MAX_UINT256, y)))))) {
                revert(0, 0)
            }

            // Divide x * y by the denominator.
            z := div(mul(x, y), denominator)
        }
    }

    function mulDivUp(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        assembly {
            // Equivalent to require(denominator != 0 && (y == 0 || x <= type(uint256).max / y))
            if iszero(mul(denominator, iszero(mul(y, gt(x, div(MAX_UINT256, y)))))) {
                revert(0, 0)
            }

            // If x * y modulo the denominator is strictly greater than 0,
            // 1 is added to round up the division of x * y by the denominator.
            z := add(gt(mod(mul(x, y), denominator), 0), div(mul(x, y), denominator))
        }
    }

    function rpow(
        uint256 x,
        uint256 n,
        uint256 scalar
    ) internal pure returns (uint256 z) {
        assembly {
            switch x
            case 0 {
                switch n
                case 0 {
                    // 0 ** 0 = 1
                    z := scalar
                }
                default {
                    // 0 ** n = 0
                    z := 0
                }
            }
            default {
                switch mod(n, 2)
                case 0 {
                    // If n is even, store scalar in z for now.
                    z := scalar
                }
                default {
                    // If n is odd, store x in z for now.
                    z := x
                }

                // Shifting right by 1 is like dividing by 2.
                let half := shr(1, scalar)

                for {
                    // Shift n right by 1 before looping to halve it.
                    n := shr(1, n)
                } n {
                    // Shift n right by 1 each iteration to halve it.
                    n := shr(1, n)
                } {
                    // Revert immediately if x ** 2 would overflow.
                    // Equivalent to iszero(eq(div(xx, x), x)) here.
                    if shr(128, x) {
                        revert(0, 0)
                    }

                    // Store x squared.
                    let xx := mul(x, x)

                    // Round to the nearest number.
                    let xxRound := add(xx, half)

                    // Revert if xx + half overflowed.
                    if lt(xxRound, xx) {
                        revert(0, 0)
                    }

                    // Set x to scaled xxRound.
                    x := div(xxRound, scalar)

                    // If n is even:
                    if mod(n, 2) {
                        // Compute z * x.
                        let zx := mul(z, x)

                        // If z * x overflowed:
                        if iszero(eq(div(zx, x), z)) {
                            // Revert if x is non-zero.
                            if iszero(iszero(x)) {
                                revert(0, 0)
                            }
                        }

                        // Round to the nearest number.
                        let zxRound := add(zx, half)

                        // Revert if zx + half overflowed.
                        if lt(zxRound, zx) {
                            revert(0, 0)
                        }

                        // Return properly scaled zxRound.
                        z := div(zxRound, scalar)
                    }
                }
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                        GENERAL NUMBER UTILITIES
    //////////////////////////////////////////////////////////////*/

    function sqrt(uint256 x) internal pure returns (uint256 z) {
        assembly {
            let y := x // We start y at x, which will help us make our initial estimate.

            z := 181 // The "correct" value is 1, but this saves a multiplication later.

            // This segment is to get a reasonable initial estimate for the Babylonian method. With a bad
            // start, the correct # of bits increases ~linearly each iteration instead of ~quadratically.

            // We check y >= 2^(k + 8) but shift right by k bits
            // each branch to ensure that if x >= 256, then y >= 256.
            if iszero(lt(y, 0x10000000000000000000000000000000000)) {
                y := shr(128, y)
                z := shl(64, z)
            }
            if iszero(lt(y, 0x1000000000000000000)) {
                y := shr(64, y)
                z := shl(32, z)
            }
            if iszero(lt(y, 0x10000000000)) {
                y := shr(32, y)
                z := shl(16, z)
            }
            if iszero(lt(y, 0x1000000)) {
                y := shr(16, y)
                z := shl(8, z)
            }

            // Goal was to get z*z*y within a small factor of x. More iterations could
            // get y in a tighter range. Currently, we will have y in [256, 256*2^16).
            // We ensured y >= 256 so that the relative difference between y and y+1 is small.
            // That's not possible if x < 256 but we can just verify those cases exhaustively.

            // Now, z*z*y <= x < z*z*(y+1), and y <= 2^(16+8), and either y >= 256, or x < 256.
            // Correctness can be checked exhaustively for x < 256, so we assume y >= 256.
            // Then z*sqrt(y) is within sqrt(257)/sqrt(256) of sqrt(x), or about 20bps.

            // For s in the range [1/256, 256], the estimate f(s) = (181/1024) * (s+1) is in the range
            // (1/2.84 * sqrt(s), 2.84 * sqrt(s)), with largest error when s = 1 and when s = 256 or 1/256.

            // Since y is in [256, 256*2^16), let a = y/65536, so that a is in [1/256, 256). Then we can estimate
            // sqrt(y) using sqrt(65536) * 181/1024 * (a + 1) = 181/4 * (y + 65536)/65536 = 181 * (y + 65536)/2^18.

            // There is no overflow risk here since y < 2^136 after the first branch above.
            z := shr(18, mul(z, add(y, 65536))) // A mul() is saved from starting z at 181.

            // Given the worst case multiplicative error of 2.84 above, 7 iterations should be enough.
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))

            // If x+1 is a perfect square, the Babylonian method cycles between
            // floor(sqrt(x)) and ceil(sqrt(x)). This statement ensures we return floor.
            // See: https://en.wikipedia.org/wiki/Integer_square_root#Using_only_integer_division
            // Since the ceil is rare, we save gas on the assignment and repeat division in the rare case.
            // If you don't care whether the floor or ceil square root is returned, you can remove this statement.
            z := sub(z, lt(div(x, z), z))
        }
    }

    function unsafeMod(uint256 x, uint256 y) internal pure returns (uint256 z) {
        assembly {
            // Mod x by y. Note this will return
            // 0 instead of reverting if y is zero.
            z := mod(x, y)
        }
    }

    function unsafeDiv(uint256 x, uint256 y) internal pure returns (uint256 r) {
        assembly {
            // Divide x by y. Note this will return
            // 0 instead of reverting if y is zero.
            r := div(x, y)
        }
    }

    function unsafeDivUp(uint256 x, uint256 y) internal pure returns (uint256 z) {
        assembly {
            // Add 1 to x * y if x % y > 0. Note this will
            // return 0 instead of reverting if y is zero.
            z := add(gt(mod(x, y), 0), div(x, y))
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {ERC20} from "../tokens/ERC20.sol";

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/SafeTransferLib.sol)
/// @dev Use with caution! Some functions in this library knowingly create dirty bits at the destination of the free memory pointer.
/// @dev Note that none of the functions in this library check that a token has code at all! That responsibility is delegated to the caller.
library SafeTransferLib {
    /*//////////////////////////////////////////////////////////////
                             ETH OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferETH(address to, uint256 amount) internal {
        bool success;

        assembly {
            // Transfer the ETH and store if it succeeded or not.
            success := call(gas(), to, amount, 0, 0, 0, 0)
        }

        require(success, "ETH_TRANSFER_FAILED");
    }

    /*//////////////////////////////////////////////////////////////
                            ERC20 OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferFrom(
        ERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x23b872dd00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), from) // Append the "from" argument.
            mstore(add(freeMemoryPointer, 36), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 68), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 100 because the length of our calldata totals up like so: 4 + 32 * 3.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 100, 0, 32)
            )
        }

        require(success, "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0xa9059cbb00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "TRANSFER_FAILED");
    }

    function safeApprove(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x095ea7b300000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "APPROVE_FAILED");
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.13;

import {ERC20} from "lib/solmate/src/tokens/ERC20.sol";
import {ERC4626} from "lib/solmate/src/mixins/ERC4626.sol";
import {SafeTransferLib} from "lib/solmate/src/utils/SafeTransferLib.sol";

import {IAaveMining} from "./external/IAaveMining.sol";
import {ILendingPool} from "./external/ILendingPool.sol";

/// @title AaveV2ERC4626
/// @author zefram.eth
/// @notice ERC4626 wrapper for Aave V2
/// @dev Important security note: due to Aave using a rebasing model for aTokens,
/// this contract cannot independently keep track of the deposited funds, so it is possible
/// for an attacker to directly transfer aTokens to this contract, increase the vault share
/// price atomically, and then exploit an external lending market that uses this contract
/// as collateral.
contract AaveV2ERC4626 is ERC4626 {
    /// -----------------------------------------------------------------------
    /// Libraries usage
    /// -----------------------------------------------------------------------

    using SafeTransferLib for ERC20;

    /// -----------------------------------------------------------------------
    /// Events
    /// -----------------------------------------------------------------------

    event ClaimRewards(uint256 amount);

    /// -----------------------------------------------------------------------
    /// Constants
    /// -----------------------------------------------------------------------

    uint256 internal constant ACTIVE_MASK = 1 << 56;
    uint256 internal constant FROZEN_MASK = 1 << 57;

    /// -----------------------------------------------------------------------
    /// Immutable params
    /// -----------------------------------------------------------------------

    /// @notice The Aave aToken contract
    ERC20 public immutable aToken;

    /// @notice The Aave liquidity mining contract
    IAaveMining public immutable aaveMining;

    /// @notice The address that will receive the liquidity mining rewards (if any)
    address public immutable rewardRecipient;

    /// @notice The Aave LendingPool contract
    ILendingPool public immutable lendingPool;

    /// -----------------------------------------------------------------------
    /// Constructor
    /// -----------------------------------------------------------------------

    constructor(
        ERC20 asset_,
        ERC20 aToken_,
        IAaveMining aaveMining_,
        address rewardRecipient_,
        ILendingPool lendingPool_
    ) ERC4626(asset_, _vaultName(asset_), _vaultSymbol(asset_)) {
        aToken = aToken_;
        aaveMining = aaveMining_;
        lendingPool = lendingPool_;
        rewardRecipient = rewardRecipient_;
    }

    /// -----------------------------------------------------------------------
    /// Aave liquidity mining
    /// -----------------------------------------------------------------------

    /// @notice Claims liquidity mining rewards from Aave and sends it to rewardRecipient
    function claimRewards() external {
        address[] memory assets = new address[](1);
        assets[0] = address(aToken);
        uint256 amount = aaveMining.claimRewards(assets, type(uint256).max, rewardRecipient);
        emit ClaimRewards(amount);
    }

    /// -----------------------------------------------------------------------
    /// ERC4626 overrides
    /// -----------------------------------------------------------------------

    function withdraw(uint256 assets, address receiver, address owner)
        public
        virtual
        override
        returns (uint256 shares)
    {
        shares = previewWithdraw(assets); // No need to check for rounding error, previewWithdraw rounds up.

        if (msg.sender != owner) {
            uint256 allowed = allowance[owner][msg.sender]; // Saves gas for limited approvals.

            if (allowed != type(uint256).max) {
                allowance[owner][msg.sender] = allowed - shares;
            }
        }

        beforeWithdraw(assets, shares);

        _burn(owner, shares);

        emit Withdraw(msg.sender, receiver, owner, assets, shares);

        // withdraw assets directly from Aave
        lendingPool.withdraw(address(asset), assets, receiver);
    }

    function redeem(uint256 shares, address receiver, address owner) public virtual override returns (uint256 assets) {
        if (msg.sender != owner) {
            uint256 allowed = allowance[owner][msg.sender]; // Saves gas for limited approvals.

            if (allowed != type(uint256).max) {
                allowance[owner][msg.sender] = allowed - shares;
            }
        }

        // Check for rounding error since we round down in previewRedeem.
        require((assets = previewRedeem(shares)) != 0, "ZERO_ASSETS");

        beforeWithdraw(assets, shares);

        _burn(owner, shares);

        emit Withdraw(msg.sender, receiver, owner, assets, shares);

        // withdraw assets directly from Aave
        lendingPool.withdraw(address(asset), assets, receiver);
    }

    function totalAssets() public view virtual override returns (uint256) {
        // aTokens use rebasing to accrue interest, so the total assets is just the aToken balance
        return aToken.balanceOf(address(this));
    }

    function afterDeposit(uint256 assets, uint256 /*shares*/ ) internal virtual override {
        /// -----------------------------------------------------------------------
        /// Deposit assets into Aave
        /// -----------------------------------------------------------------------

        // approve to lendingPool
        asset.safeApprove(address(lendingPool), assets);

        // deposit into lendingPool
        lendingPool.deposit(address(asset), assets, address(this), 0);
    }

    function maxDeposit(address) public view virtual override returns (uint256) {
        // check if pool is paused
        if (lendingPool.paused()) {
            return 0;
        }

        // check if asset is paused
        uint256 configData = lendingPool.getReserveData(address(asset)).configuration.data;
        if (!(_getActive(configData) && !_getFrozen(configData))) {
            return 0;
        }

        return type(uint256).max;
    }

    function maxMint(address) public view virtual override returns (uint256) {
        // check if pool is paused
        if (lendingPool.paused()) {
            return 0;
        }

        // check if asset is paused
        uint256 configData = lendingPool.getReserveData(address(asset)).configuration.data;
        if (!(_getActive(configData) && !_getFrozen(configData))) {
            return 0;
        }

        return type(uint256).max;
    }

    function maxWithdraw(address owner) public view virtual override returns (uint256) {
        // check if pool is paused
        if (lendingPool.paused()) {
            return 0;
        }

        // check if asset is paused
        uint256 configData = lendingPool.getReserveData(address(asset)).configuration.data;
        if (!_getActive(configData)) {
            return 0;
        }

        uint256 cash = asset.balanceOf(address(aToken));
        uint256 assetsBalance = convertToAssets(balanceOf[owner]);
        return cash < assetsBalance ? cash : assetsBalance;
    }

    function maxRedeem(address owner) public view virtual override returns (uint256) {
        // check if pool is paused
        if (lendingPool.paused()) {
            return 0;
        }

        // check if asset is paused
        uint256 configData = lendingPool.getReserveData(address(asset)).configuration.data;
        if (!_getActive(configData)) {
            return 0;
        }

        uint256 cash = asset.balanceOf(address(aToken));
        uint256 cashInShares = convertToShares(cash);
        uint256 shareBalance = balanceOf[owner];
        return cashInShares < shareBalance ? cashInShares : shareBalance;
    }

    /// -----------------------------------------------------------------------
    /// ERC20 metadata generation
    /// -----------------------------------------------------------------------

    function _vaultName(ERC20 asset_) internal view virtual returns (string memory vaultName) {
        vaultName = string.concat("ERC4626-Wrapped Aave v2 ", asset_.symbol());
    }

    function _vaultSymbol(ERC20 asset_) internal view virtual returns (string memory vaultSymbol) {
        vaultSymbol = string.concat("wa2", asset_.symbol());
    }

    /// -----------------------------------------------------------------------
    /// Internal functions
    /// -----------------------------------------------------------------------

    function _getActive(uint256 configData) internal pure returns (bool) {
        return (configData & ACTIVE_MASK) != 0;
    }

    function _getFrozen(uint256 configData) internal pure returns (bool) {
        return (configData & FROZEN_MASK) != 0;
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.4;

interface IAaveMining {
    function claimRewards(address[] calldata assets, uint256 amount, address to) external returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.4;

// Aave lending pool interface
// Documentation: https://docs.aave.com/developers/the-core-protocol/lendingpool/ilendingpool
// refer to the whitepaper, section 1.1 basic concepts for a formal description of these properties.
interface ILendingPool {
    struct ReserveConfigurationMap {
        //bit 0-15: LTV
        //bit 16-31: Liq. threshold
        //bit 32-47: Liq. bonus
        //bit 48-55: Decimals
        //bit 56: Reserve is active
        //bit 57: reserve is frozen
        //bit 58: borrowing is enabled
        //bit 59: stable rate borrowing enabled
        //bit 60-63: reserved
        //bit 64-79: reserve factor
        uint256 data;
    }

    struct ReserveData {
        ReserveConfigurationMap configuration;
        //the liquidity index. Expressed in ray
        uint128 liquidityIndex;
        //variable borrow index. Expressed in ray
        uint128 variableBorrowIndex;
        //the current supply rate. Expressed in ray
        uint128 currentLiquidityRate;
        //the current variable borrow rate. Expressed in ray
        uint128 currentVariableBorrowRate;
        //the current stable borrow rate. Expressed in ray
        uint128 currentStableBorrowRate;
        uint40 lastUpdateTimestamp;
        //tokens addresses
        address aTokenAddress;
        address stableDebtTokenAddress;
        address variableDebtTokenAddress;
        //address of the interest rate strategy
        address interestRateStrategyAddress;
        //the id of the reserve. Represents the position in the list of the active reserves
        uint8 id;
    }

    /**
     * @dev Deposits an `amount` of underlying asset into the reserve, receiving in return overlying aTokens.
     * - E.g. User deposits 100 USDC and gets in return 100 aUSDC
     * @param asset The address of the underlying asset to deposit
     * @param amount The amount to be deposited
     * @param onBehalfOf The address that will receive the aTokens, same as msg.sender if the user
     * wants to receive them on his own wallet, or a different address if the beneficiary of aTokens
     * is a different wallet
     * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
     * 0 if the action is executed directly by the user, without any middle-man
     *
     */
    function deposit(address asset, uint256 amount, address onBehalfOf, uint16 referralCode) external;

    /**
     * @dev Withdraws an `amount` of underlying asset from the reserve, burning the equivalent aTokens owned
     * E.g. User has 100 aUSDC, calls withdraw() and receives 100 USDC, burning the 100 aUSDC
     * @param asset The address of the underlying asset to withdraw
     * @param amount The underlying amount to be withdrawn
     * - Send the value type(uint256).max in order to withdraw the whole aToken balance
     * @param to Address that will receive the underlying, same as msg.sender if the user
     * wants to receive it on his own wallet, or a different address if the beneficiary is a
     * different wallet
     * @return The final amount withdrawn
     *
     */
    function withdraw(address asset, uint256 amount, address to) external returns (uint256);

    /**
     * @dev Returns the state and configuration of the reserve
     * @param asset The address of the underlying asset of the reserve
     * @return The state of the reserve
     *
     */
    function getReserveData(address asset) external view returns (ReserveData memory);

    function paused() external view returns (bool);
}