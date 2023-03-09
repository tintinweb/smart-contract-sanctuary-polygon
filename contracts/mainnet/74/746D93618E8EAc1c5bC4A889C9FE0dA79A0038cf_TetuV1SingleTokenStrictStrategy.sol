// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

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

pragma solidity 0.8.17;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
  /**
   * @dev Returns the amount of tokens in existence.
   */
  function totalSupply() external view returns (uint);

  /**
   * @dev Returns the amount of tokens owned by `account`.
   */
  function balanceOf(address account) external view returns (uint);

  /**
   * @dev Moves `amount` tokens from the caller's account to `recipient`.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transfer(address recipient, uint amount) external returns (bool);

  /**
   * @dev Returns the remaining number of tokens that `spender` will be
   * allowed to spend on behalf of `owner` through {transferFrom}. This is
   * zero by default.
   *
   * This value changes when {approve} or {transferFrom} are called.
   */
  function allowance(address owner, address spender) external view returns (uint);

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
  function approve(address spender, uint amount) external returns (bool);

  /**
   * @dev Moves `amount` tokens from `sender` to `recipient` using the
   * allowance mechanism. `amount` is then deducted from the caller's
   * allowance.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transferFrom(
    address sender,
    address recipient,
    uint amount
  ) external returns (bool);

  /**
   * @dev Emitted when `value` tokens are moved from one account (`from`) to
   * another (`to`).
   *
   * Note that `value` may be zero.
   */
  event Transfer(address indexed from, address indexed to, uint value);

  /**
   * @dev Emitted when the allowance of a `spender` for an `owner` is set by
   * a call to {approve}. `value` is the new allowance.
   */
  event Approval(address indexed owner, address indexed spender, uint value);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity 0.8.17;

import "./IERC20.sol";

/**
 * https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/release-v4.6/contracts/token/ERC20/extensions/IERC20MetadataUpgradeable.sol
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Permit.sol)

pragma solidity 0.8.17;

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
// OpenZeppelin Contracts (last updated v4.8.0) (interfaces/IERC4626.sol)

pragma solidity 0.8.17;

import "./IERC20.sol";
import "./IERC20Metadata.sol";

/**
 * @dev Interface of the ERC4626 "Tokenized Vault Standard", as defined in
 * https://eips.ethereum.org/EIPS/eip-4626[ERC-4626].
 *
 * _Available since v4.7._
 */
interface IERC4626 is IERC20, IERC20Metadata {
  event Deposit(address indexed sender, address indexed owner, uint256 assets, uint256 shares);

  event Withdraw(
    address indexed sender,
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

pragma solidity 0.8.17;

interface IForwarder {

  function tokenPerDestinationLength(address destination) external view returns (uint);

  function tokenPerDestinationAt(address destination, uint i) external view returns (address);

  function registerIncome(
    address[] memory tokens,
    uint[] memory amounts,
    address vault,
    bool isDistribute
  ) external;

  function distributeAll(address destination) external;

  function distribute(address token) external;

  function setInvestFundRatio(uint value) external;

  function setGaugesRatio(uint value) external;

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IStrategyStrict {

  function NAME() external view returns (string memory);

  function PLATFORM() external view returns (string memory);

  function STRATEGY_VERSION() external view returns (string memory);

  function asset() external view returns (address);

  function vault() external view returns (address);

  function compoundRatio() external view returns (uint);

  function totalAssets() external view returns (uint);

  /// @dev Usually, indicate that claimable rewards have reasonable amount.
  function isReadyToHardWork() external view returns (bool);

  function withdrawAllToVault() external;

  function withdrawToVault(uint amount) external;

  function investAll() external;

  function doHardWork() external returns (uint earned, uint lost);

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IStrategyV2 {

  function NAME() external view returns (string memory);

  function PLATFORM() external view returns (string memory);

  function STRATEGY_VERSION() external view returns (string memory);

  function asset() external view returns (address);

  function splitter() external view returns (address);

  function compoundRatio() external view returns (uint);

  function totalAssets() external view returns (uint);

  /// @dev Usually, indicate that claimable rewards have reasonable amount.
  function isReadyToHardWork() external view returns (bool);

  /// @return totalAssetsDelta The {strategy} can update its totalAssets amount internally before withdrawing
  ///                          Return [totalAssets-before-withdraw - totalAssets-before-call-of-withdrawAllToSplitter]
  function withdrawAllToSplitter() external returns (int totalAssetsDelta);

  /// @return totalAssetsDelta The {strategy} can update its totalAssets amount internally before withdrawing
  ///                          Return [totalAssets-before-withdraw - totalAssets-before-call-of-withdrawToSplitter]
  function withdrawToSplitter(uint amount) external returns (int totalAssetsDelta);

  /// @notice Stakes everything the strategy holds into the reward pool.
  /// @param amount_ Amount transferred to the strategy balance just before calling this function
  /// @param updateTotalAssetsBeforeInvest_ Recalculate total assets amount before depositing.
  ///                                       It can be false if we know exactly, that the amount is already actual.
  /// @return totalAssetsDelta The {strategy} can update its totalAssets amount internally before depositing {amount_}
  ///                          Return [totalAssets-before-deposit - totalAssets-before-call-of-investAll]
  function investAll(
    uint amount_,
    bool updateTotalAssetsBeforeInvest_
  ) external returns (
    int totalAssetsDelta
  );

  function doHardWork() external returns (uint earned, uint lost);

  function setCompoundRatio(uint value) external;

  /// @notice Max amount that can be deposited to the strategy (its internal capacity), see SCB-593.
  ///         0 means no deposit is allowed at this moment
  function capacity() external view returns (uint);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface ITetuLiquidator {

  struct PoolData {
    address pool;
    address swapper;
    address tokenIn;
    address tokenOut;
  }

  function addLargestPools(PoolData[] memory _pools, bool rewrite) external;

  function addBlueChipsPools(PoolData[] memory _pools, bool rewrite) external;

  function getPrice(address tokenIn, address tokenOut, uint amount) external view returns (uint);

  function getPriceForRoute(PoolData[] memory route, uint amount) external view returns (uint);

  function isRouteExist(address tokenIn, address tokenOut) external view returns (bool);

  function buildRoute(
    address tokenIn,
    address tokenOut
  ) external view returns (PoolData[] memory route, string memory errorMessage);

  function liquidate(
    address tokenIn,
    address tokenOut,
    uint amount,
    uint slippage
  ) external;

  function liquidateWithRoute(
    PoolData[] memory route,
    uint amount,
    uint slippage
  ) external;


}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

/// @title Library for interface IDs
/// @author bogdoslav
library InterfaceIds {

  /// @notice Version of the contract
  /// @dev Should be incremented when contract changed
  string public constant INTERFACE_IDS_LIB_VERSION = "1.0.0";

  /// default notation:
  /// bytes4 public constant I_VOTER = type(IVoter).interfaceId;

  /// As type({Interface}).interfaceId can be changed,
  /// when some functions changed at the interface,
  /// so used hardcoded interface identifiers

  bytes4 public constant I_VOTER = bytes4(keccak256("IVoter"));
  bytes4 public constant I_BRIBE = bytes4(keccak256("IBribe"));
  bytes4 public constant I_GAUGE = bytes4(keccak256("IGauge"));
  bytes4 public constant I_VE_TETU = bytes4(keccak256("IVeTetu"));
  bytes4 public constant I_SPLITTER = bytes4(keccak256("ISplitter"));
  bytes4 public constant I_FORWARDER = bytes4(keccak256("IForwarder"));
  bytes4 public constant I_MULTI_POOL = bytes4(keccak256("IMultiPool"));
  bytes4 public constant I_CONTROLLER = bytes4(keccak256("IController"));
  bytes4 public constant I_TETU_ERC165 = bytes4(keccak256("ITetuERC165"));
  bytes4 public constant I_STRATEGY_V2 = bytes4(keccak256("IStrategyV2"));
  bytes4 public constant I_CONTROLLABLE = bytes4(keccak256("IControllable"));
  bytes4 public constant I_TETU_VAULT_V2 = bytes4(keccak256("ITetuVaultV2"));
  bytes4 public constant I_PLATFORM_VOTER = bytes4(keccak256("IPlatformVoter"));
  bytes4 public constant I_VE_DISTRIBUTOR = bytes4(keccak256("IVeDistributor"));
  bytes4 public constant I_TETU_CONVERTER = bytes4(keccak256("ITetuConverter"));
  bytes4 public constant I_VAULT_INSURANCE = bytes4(keccak256("IVaultInsurance"));
  bytes4 public constant I_STRATEGY_STRICT = bytes4(keccak256("IStrategyStrict"));
  bytes4 public constant I_ERC4626 = bytes4(keccak256("IERC4626"));

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity 0.8.17;

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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity 0.8.17;

import "../interfaces/IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
  /**
   * @dev See {IERC165-supportsInterface}.
     */
  function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
    return interfaceId == type(IERC165).interfaceId;
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity 0.8.17;

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
    return a > b ? a : b;
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
    require(denominator > prod1, "Math: mulDiv overflow");

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
   * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
  function sqrt(uint256 a) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }

    // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
    //
    // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
    // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
    //
    // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
    // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
    // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
    //
    // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
    uint256 result = 1 << (log2(a) >> 1);

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
  unchecked {
    uint256 result = sqrt(a);
    return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
  }
  }

  /**
   * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
  function log2(uint256 value) internal pure returns (uint256) {
    uint256 result = 0;
  unchecked {
    if (value >> 128 > 0) {
      value >>= 128;
      result += 128;
    }
    if (value >> 64 > 0) {
      value >>= 64;
      result += 64;
    }
    if (value >> 32 > 0) {
      value >>= 32;
      result += 32;
    }
    if (value >> 16 > 0) {
      value >>= 16;
      result += 16;
    }
    if (value >> 8 > 0) {
      value >>= 8;
      result += 8;
    }
    if (value >> 4 > 0) {
      value >>= 4;
      result += 4;
    }
    if (value >> 2 > 0) {
      value >>= 2;
      result += 2;
    }
    if (value >> 1 > 0) {
      result += 1;
    }
  }
    return result;
  }

  /**
   * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
  function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
  unchecked {
    uint256 result = log2(value);
    return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
  }
  }

  /**
   * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
  function log10(uint256 value) internal pure returns (uint256) {
    uint256 result = 0;
  unchecked {
    if (value >= 10**64) {
      value /= 10**64;
      result += 64;
    }
    if (value >= 10**32) {
      value /= 10**32;
      result += 32;
    }
    if (value >= 10**16) {
      value /= 10**16;
      result += 16;
    }
    if (value >= 10**8) {
      value /= 10**8;
      result += 8;
    }
    if (value >= 10**4) {
      value /= 10**4;
      result += 4;
    }
    if (value >= 10**2) {
      value /= 10**2;
      result += 2;
    }
    if (value >= 10**1) {
      result += 1;
    }
  }
    return result;
  }

  /**
   * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
  function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
  unchecked {
    uint256 result = log10(value);
    return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
  }
  }

  /**
   * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
  function log256(uint256 value) internal pure returns (uint256) {
    uint256 result = 0;
  unchecked {
    if (value >> 128 > 0) {
      value >>= 128;
      result += 16;
    }
    if (value >> 64 > 0) {
      value >>= 64;
      result += 8;
    }
    if (value >> 32 > 0) {
      value >>= 32;
      result += 4;
    }
    if (value >> 16 > 0) {
      value >>= 16;
      result += 2;
    }
    if (value >> 8 > 0) {
      result += 1;
    }
  }
    return result;
  }

  /**
   * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
  function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
  unchecked {
    uint256 result = log256(value);
    return result + (rounding == Rounding.Up && 1 << (result << 3) < value ? 1 : 0);
  }
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity 0.8.17;

import "../interfaces/IERC20.sol";
import "../interfaces/IERC20Permit.sol";
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
pragma solidity 0.8.17;

import "../openzeppelin/SafeERC20.sol";
import "../openzeppelin/Math.sol";
import "../interfaces/IStrategyV2.sol";
import "../interfaces/IForwarder.sol";
import "../interfaces/IERC4626.sol";
import "../interfaces/IStrategyStrict.sol";
import "../tools/TetuERC165.sol";

/// @title Abstract contract for base strict strategy functionality
/// @author AlehNat
abstract contract StrategyStrictBase is IStrategyStrict, TetuERC165 {
  using SafeERC20 for IERC20;

  // *************************************************************
  //                        CONSTANTS
  // *************************************************************

  /// @dev Version of this contract. Adjust manually on each code modification.
  string public constant STRICT_STRATEGY_BASE_VERSION = "1.0.0";

  // *************************************************************
  //                        ERRORS
  // *************************************************************

  string internal constant WRONG_CONTROLLER = "SB: Wrong controller";
  string internal constant DENIED = "SB: Denied";
  string internal constant TOO_HIGH = "SB: Too high";
  string internal constant IMPACT_TOO_HIGH = "SB: Impact too high";
  string internal constant WRONG_AMOUNT = "SB: Wrong amount";
  string internal constant ALREADY_INITIALIZED = "SB: Already initialized";

  // *************************************************************
  //                        VARIABLES
  //                Keep names and ordering!
  //                 Add only in the bottom.
  // *************************************************************

  /// @dev Underlying asset
  address public override asset;
  /// @dev Linked vault
  address public override vault;
  /// @dev Percent of profit for autocompound inside this strategy.
  uint public override compoundRatio;

  // *************************************************************
  //                        EVENTS
  // *************************************************************

  event WithdrawAllToVault(uint amount);
  event WithdrawToVault(uint amount, uint sent, uint balance);
  event EmergencyExit(address sender, uint amount);
  event ManualClaim(address sender);
  event InvestAll(uint balance);
  event DepositToPool(uint amount);
  event WithdrawFromPool(uint amount);
  event WithdrawAllFromPool(uint amount);
  event Claimed(address token, uint amount);
  event CompoundRatioChanged(uint oldValue, uint newValue);

  // *************************************************************
  //                        INIT
  // *************************************************************

  /// @dev Initialize with the vault. Can be called only once.
  function init(address _vault) external {
    require(vault == address(0), ALREADY_INITIALIZED);
    _requireInterface(_vault, InterfaceIds.I_ERC4626);
    asset = IERC4626(_vault).asset();
    vault = _vault;
  }

  // *************************************************************
  //                        VIEWS
  // *************************************************************

  /// @dev Total amount of underlying assets under control of this strategy.
  function totalAssets() public view override returns (uint) {
    return IERC20(asset).balanceOf(address(this)) + investedAssets();
  }

  /// @dev See {IERC165-supportsInterface}.
  function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
    return interfaceId == InterfaceIds.I_STRATEGY_STRICT || super.supportsInterface(interfaceId);
  }

  // *************************************************************
  //                    DEPOSIT/WITHDRAW
  // *************************************************************

  /// @dev Stakes everything the strategy holds into the reward pool.
  function investAll() external override {
    require(msg.sender == vault, DENIED);
    address _asset = asset; // gas saving
    uint balance = IERC20(_asset).balanceOf(address(this));
    if (balance > 0) {
      _depositToPool(balance);
    }
    emit InvestAll(balance);
  }

  /// @dev Withdraws all underlying assets to the vault
  function withdrawAllToVault() external override {
    address _vault = vault;
    address _asset = asset; // gas saving
    require(msg.sender == _vault, DENIED);
    _withdrawAllFromPool();
    uint balance = IERC20(_asset).balanceOf(address(this));

    if (balance != 0) {
      IERC20(_asset).safeTransfer(_vault, balance);
    }
    emit WithdrawAllToVault(balance);
  }

  /// @dev Withdraws some assets to the vault
  function withdrawToVault(uint amount) external override {
    address _vault = vault;
    address _asset = asset; // gas saving
    require(msg.sender == _vault, DENIED);
    uint balance = IERC20(_asset).balanceOf(address(this));
    if (amount > balance) {
      _withdrawFromPool(amount - balance);
      balance = IERC20(_asset).balanceOf(address(this));
    }

    uint amountAdjusted = Math.min(amount, balance);
    if (amountAdjusted != 0) {
      IERC20(_asset).safeTransfer(_vault, amountAdjusted);
    }
    emit WithdrawToVault(amount, amountAdjusted, balance);
  }

  // *************************************************************
  //                       VIRTUAL
  // These functions must be implemented in the strategy contract
  // *************************************************************

  /// @dev Amount of underlying assets invested to the pool.
  function investedAssets() public view virtual returns (uint);

  /// @dev Deposit given amount to the pool.
  function _depositToPool(uint amount) internal virtual;

  /// @dev Withdraw given amount from the pool.
  /// @return investedAssetsUSD Sum of USD value of each asset in the pool that was withdrawn, decimals of {asset}.
  /// @return assetPrice Price of the strategy {asset}.
  function _withdrawFromPool(uint amount) internal virtual returns (uint investedAssetsUSD, uint assetPrice);

  /// @dev Withdraw all from the pool.
  /// @return investedAssetsUSD Sum of USD value of each asset in the pool that was withdrawn, decimals of {asset}.
  /// @return assetPrice Price of the strategy {asset}.
  function _withdrawAllFromPool() internal virtual returns (uint investedAssetsUSD, uint assetPrice);

  /// @dev If pool support emergency withdraw need to call it for emergencyExit()
  ///      Withdraw assets without impact checking.
  function _emergencyExitFromPool() internal virtual;

  /// @dev Claim all possible rewards.
  function _claim() internal virtual;

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../openzeppelin/ERC165.sol";
import "../interfaces/IERC20.sol";
import "../lib/InterfaceIds.sol";

/// @dev Tetu Implementation of the {IERC165} interface extended with helper functions.
/// @author bogdoslav
abstract contract TetuERC165 is ERC165 {

  function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
    return interfaceId == InterfaceIds.I_TETU_ERC165 || super.supportsInterface(interfaceId);
  }

  // *************************************************************
  //                        HELPER FUNCTIONS
  // *************************************************************
  /// @author bogdoslav

  /// @dev Checks what interface with id is supported by contract.
  /// @return bool. Do not throws
  function _isInterfaceSupported(address contractAddress, bytes4 interfaceId) internal view returns (bool) {
    require(contractAddress != address(0), "Zero address");
    // check what address is contract
    uint codeSize;
    assembly {
      codeSize := extcodesize(contractAddress)
    }
    if (codeSize == 0) return false;

    try IERC165(contractAddress).supportsInterface(interfaceId) returns (bool isSupported) {
      return isSupported;
    } catch {
    }
    return false;
  }

  /// @dev Checks what interface with id is supported by contract and reverts otherwise
  function _requireInterface(address contractAddress, bytes4 interfaceId) internal view {
    require(_isInterfaceSupported(contractAddress, interfaceId), "Interface is not supported");
  }

  /// @dev Checks what address is ERC20.
  /// @return bool. Do not throws
  function _isERC20(address contractAddress) internal view returns (bool) {
    require(contractAddress != address(0), "Zero address");
    // check what address is contract
    uint codeSize;
    assembly {
      codeSize := extcodesize(contractAddress)
    }
    if (codeSize == 0) return false;

    bool totalSupplySupported;
    try IERC20(contractAddress).totalSupply() returns (uint) {
      totalSupplySupported = true;
    } catch {
    }

    bool balanceSupported;
    try IERC20(contractAddress).balanceOf(address(this)) returns (uint) {
      balanceSupported = true;
    } catch {
    }

    return totalSupplySupported && balanceSupported;
  }


  /// @dev Checks what interface with id is supported by contract and reverts otherwise
  function _requireERC20(address contractAddress) internal view {
    require(_isERC20(contractAddress), "Not ERC20");
  }
}

// SPDX-License-Identifier: ISC
pragma solidity 0.8.17;

interface IRateProvider {
    /**
     * @dev Returns an 18 decimal fixed point number that is the exchange rate of the token to some other underlying
     * token. The meaning of this rate depends on the context.
     */
    function getRate() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface ISmartVault {
  function DEPOSIT_FEE_DENOMINATOR() external view returns (uint256);

  function LOCK_PENALTY_DENOMINATOR() external view returns (uint256);

  function TO_INVEST_DENOMINATOR() external view returns (uint256);

  function VERSION() external view returns (string memory);

  function active() external view returns (bool);

  function addRewardToken(address rt) external;

  function alwaysInvest() external view returns (bool);

  function availableToInvestOut() external view returns (uint256);

  function changeActivityStatus(bool _active) external;

  function changeAlwaysInvest(bool _active) external;

  function changeDoHardWorkOnInvest(bool _active) external;

  function changePpfsDecreaseAllowed(bool _value) external;

  function changeProtectionMode(bool _active) external;

  function deposit(uint256 amount) external;

  function depositAndInvest(uint256 amount) external;

  function depositFeeNumerator() external view returns (uint256);

  function depositFor(uint256 amount, address holder) external;

  function disableLock() external;

  function doHardWork() external;

  function doHardWorkOnInvest() external view returns (bool);

  function duration() external view returns (uint256);

  function earned(address rt, address account) external view returns (uint256);

  function earnedWithBoost(address rt, address account) external view returns (uint256);

  function exit() external;

  function getAllRewards() external;

  function getAllRewardsAndRedirect(address owner) external;

  function getPricePerFullShare() external view returns (uint256);

  function getReward(address rt) external;

  function getRewardTokenIndex(address rt) external view returns (uint256);

  function initializeSmartVault(
    string memory _name,
    string memory _symbol,
    address _controller,
    address __underlying,
    uint256 _duration,
    bool _lockAllowed,
    address _rewardToken,
    uint256 _depositFee
  ) external;

  function lastTimeRewardApplicable(address rt) external view returns (uint256);

  function lastUpdateTimeForToken(address) external view returns (uint256);

  function lockAllowed() external view returns (bool);

  function lockPenalty() external view returns (uint256);

  function notifyRewardWithoutPeriodChange(address _rewardToken, uint256 _amount) external;

  function notifyTargetRewardAmount(address _rewardToken, uint256 amount) external;

  function overrideName(string memory value) external;

  function overrideSymbol(string memory value) external;

  function periodFinishForToken(address) external view returns (uint256);

  function ppfsDecreaseAllowed() external view returns (bool);

  function protectionMode() external view returns (bool);

  function rebalance() external;

  function removeRewardToken(address rt) external;

  function rewardPerToken(address rt) external view returns (uint256);

  function rewardPerTokenStoredForToken(address) external view returns (uint256);

  function rewardRateForToken(address) external view returns (uint256);

  function rewardTokens() external view returns (address[] memory);

  function rewardTokensLength() external view returns (uint256);

  function rewardsForToken(address, address) external view returns (uint256);

  function setLockPenalty(uint256 _value) external;

  function setRewardsRedirect(address owner, address receiver) external;

  function setLockPeriod(uint256 _value) external;

  function setStrategy(address newStrategy) external;

  function setToInvest(uint256 _value) external;

  function stop() external;

  function strategy() external view returns (address);

  function toInvest() external view returns (uint256);

  function underlying() external view returns (address);

  function underlyingBalanceInVault() external view returns (uint256);

  function underlyingBalanceWithInvestment() external view returns (uint256);

  function underlyingBalanceWithInvestmentForHolder(address holder) external view returns (uint256);

  function underlyingUnit() external view returns (uint256);

  function userBoostTs(address) external view returns (uint256);

  function userLastDepositTs(address) external view returns (uint256);

  function userLastWithdrawTs(address) external view returns (uint256);

  function userLockTs(address) external view returns (uint256);

  function userRewardPerTokenPaidForToken(address, address) external view returns (uint256);

  function withdraw(uint256 numberOfShares) external;

  function withdrawAllToVault() external;

  function getAllRewardsFor(address rewardsReceiver) external;

  function lockPeriod() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@tetu_io/tetu-contracts-v2/contracts/strategy/StrategyStrictBase.sol";
import "@tetu_io/tetu-contracts-v2/contracts/interfaces/ITetuLiquidator.sol";
import "@tetu_io/tetu-contracts-v2/contracts/interfaces/IERC20Metadata.sol";
import "../../integrations/tetu-v1/ISmartVault.sol";
import "../../tools/AppLib.sol";
import "../../tools/ERC20Helpers.sol";
import "../../integrations/balancer/IRateProvider.sol";

/// @title Simple auto compounding strategy for TETU V1 vaults.
/// @author AlehNat
contract TetuV1SingleTokenStrictStrategy is StrategyStrictBase, IRateProvider, ERC20Helpers {
  using SafeERC20 for IERC20;

  string public constant override NAME = "TetuV1 Single Token Strict Strategy";
  string public constant override PLATFORM = "TETU";
  string public constant override STRATEGY_VERSION = "1.0.0";

  uint private constant _ASSET_LIQUIDATION_SLIPPAGE = 5000; // 5%

  // in this strategy TETU V1 vault is used as a pool
  ISmartVault public immutable pool;
  ITetuLiquidator public immutable liquidator;
  address public immutable xTetuAddress;

  bool public override isReadyToHardWork;

  constructor(address _pool, address _liquidator, address _xTetuAddress) {
    require(_pool != address(0) && _liquidator != address(0) && _xTetuAddress != address(0), '!address');
    pool = ISmartVault(_pool);
    liquidator = ITetuLiquidator(_liquidator);
    xTetuAddress = _xTetuAddress;
    isReadyToHardWork = true;
  }


  // uint earned, uint lost is it in USD?
  function doHardWork() external override returns (uint earned, uint lost) {
    // if we have some asset in the strategy we need to deposit it to the pool to not liquidate it.
    uint assetBalanceBeforeClaim = _balance(asset);
    if (assetBalanceBeforeClaim > 0) {
      _depositToPool(assetBalanceBeforeClaim);
    }

    uint strategyBalanceBefore = pool.underlyingBalanceWithInvestmentForHolder(address(this));

    _claim();
    _unwrapXTetu();
    _liquidateReward();
    uint assetBalance = _balance(asset);
    if (assetBalance > 0) {
      _depositToPool(assetBalance);
    }
    earned = 0;
    lost = 0;

    uint strategyBalanceAfter = pool.underlyingBalanceWithInvestmentForHolder(address(this));

    if (strategyBalanceAfter > strategyBalanceBefore) {
      earned = strategyBalanceAfter - strategyBalanceBefore;
    } else {
      lost = strategyBalanceBefore - strategyBalanceAfter;
    }
  }

  /// @dev Deposit given amount to the pool.
  function _depositToPool(uint amount) internal override {
    IERC20(asset).safeIncreaseAllowance(address(pool), amount);
    pool.depositAndInvest(amount);
  }

  /// @dev Withdraw given amount from the pool.
  /// @return investedAssetsUSD and assetPrice are not used in this strategy (0,0)
  function _withdrawFromPool(uint amount) internal override returns (uint investedAssetsUSD, uint assetPrice) {
    pool.withdraw(amount);
    return (0, 0);
  }

  /// @dev Withdraw all from the pool.
  /// @return investedAssetsUSD and assetPrice are not used in this strategy returns (0,0)
  function _withdrawAllFromPool() internal override returns (uint investedAssetsUSD, uint assetPrice) {
    uint totalBalance = _balance(address(pool));
    return _withdrawFromPool(totalBalance);
  }

  /// @dev If pool support emergency withdraw need to call it for emergencyExit()
  ///      Withdraw assets without impact checking.
  function _emergencyExitFromPool() internal override {
    _withdrawAllFromPool();
  }

  /// @dev Claim all possible rewards.
  function _claim() internal override {
    pool.getAllRewards();
  }

  function _unwrapXTetu() internal {
    uint xTetuBalance = _balance(xTetuAddress);
    if (xTetuBalance > 0) {
      ISmartVault(xTetuAddress).withdraw(xTetuBalance);
    }
  }

  function _liquidateReward() internal {
    address [] memory rewardTokens = pool.rewardTokens();
    for (uint i = 0; i < rewardTokens.length; i = AppLib.uncheckedInc(i)) {
      address rewardToken = rewardTokens[i];
      uint rewardBalance = _balance(rewardToken);
      if (rewardBalance > 0) {
        IERC20(rewardToken).safeIncreaseAllowance(address(liquidator), rewardBalance);
        liquidator.liquidate(rewardToken, asset, rewardBalance, _ASSET_LIQUIDATION_SLIPPAGE);
      }
    }
  }

  function getRate() external view override returns (uint256) {
    uint assetPrecision = 10 ** IERC20Metadata(asset).decimals();
    return IERC4626(vault).convertToAssets(assetPrecision) * 1e18 / assetPrecision;
  }

  function investedAssets() public view override returns (uint) {
    return pool.underlyingBalanceWithInvestmentForHolder(address(this));
  }

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@tetu_io/tetu-contracts-v2/contracts/interfaces/IERC20.sol";
import "@tetu_io/tetu-contracts-v2/contracts/interfaces/IERC20Metadata.sol";
import "@tetu_io/tetu-contracts-v2/contracts/openzeppelin/SafeERC20.sol";

/// @notice Common internal utils
library AppLib {
  using SafeERC20 for IERC20;

  /// @notice Unchecked increment for for-cycles
  function uncheckedInc(uint i) internal pure returns (uint) {
    unchecked {
      return i + 1;
    }
  }

  /// @notice Make infinite approve of {token} to {spender} if the approved amount is less than {amount}
  /// @dev Should NOT be used for third-party pools
  function approveIfNeeded(address token, uint amount, address spender) internal {
    if (IERC20(token).allowance(address(this), spender) < amount) {
      IERC20(token).safeApprove(spender, 0);
      // infinite approve, 2*255 is more gas efficient then type(uint).max
      IERC20(token).safeApprove(spender, 2**255);
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@tetu_io/tetu-contracts-v2/contracts/interfaces/IERC20.sol";
import "@tetu_io/tetu-contracts-v2/contracts/openzeppelin/SafeERC20.sol";

/// @title Contract with helper functions.
/// @author bogdoslav
contract ERC20Helpers {
  using SafeERC20 for IERC20;

  function _balance(address token) internal view returns (uint) {
    return IERC20(token).balanceOf(address(this));
  }

  /// @notice Should be used for third-party pools
  function _safeApprove(address token, uint amount, address spender) internal {
    IERC20(token).safeApprove(spender, 0);
    IERC20(token).safeApprove(spender, amount);
  }
}