// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface IControllable {

  function isController(address _contract) external view returns (bool);

  function isGovernance(address _contract) external view returns (bool);

  function created() external view returns (uint256);

  function createdBlock() external view returns (uint256);

  function controller() external view returns (address);

  function increaseRevision(address oldLogic) external;

}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface IController {

  // --- DEPENDENCY ADDRESSES
  function governance() external view returns (address);

  function voter() external view returns (address);

  function liquidator() external view returns (address);

  function forwarder() external view returns (address);

  function investFund() external view returns (address);

  function veDistributor() external view returns (address);

  function platformVoter() external view returns (address);

  // --- VAULTS

  function vaults(uint id) external view returns (address);

  function vaultsList() external view returns (address[] memory);

  function vaultsListLength() external view returns (uint);

  function isValidVault(address _vault) external view returns (bool);

  // --- restrictions

  function isOperator(address _adr) external view returns (bool);


}

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

interface IGauge {

  function veIds(address stakingToken, address account) external view returns (uint);

  function getReward(
    address stakingToken,
    address account,
    address[] memory tokens
  ) external;

  function getAllRewards(
    address stakingToken,
    address account
  ) external;

  function getAllRewardsForTokens(
    address[] memory stakingTokens,
    address account
  ) external;

  function attachVe(address stakingToken, address account, uint veId) external;

  function detachVe(address stakingToken, address account, uint veId) external;

  function handleBalanceChange(address account) external;

  function notifyRewardAmount(address stakingToken, address token, uint amount) external;

  function addStakingToken(address token) external;

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface ISplitter {

  function init(address controller_, address _asset, address _vault) external;

  // *************** ACTIONS **************

  function withdrawAllToVault() external;

  function withdrawToVault(uint256 amount) external;

  function doHardWork() external;

  function investAll() external;

  // **************** VIEWS ***************

  function asset() external view returns (address);

  function vault() external view returns (address);

  function totalAssets() external view returns (uint256);

  function isHardWorking() external view returns (bool);

  function strategies(uint i) external view returns (address);

  function strategiesLength() external view returns (uint);

  function HARDWORK_DELAY() external view returns(uint);

  function lastHardWorks(address strategy) external view returns(uint);

  function pausedStrategies(address strategy) external view returns(bool);

  function pauseInvesting(address strategy) external;

  function continueInvesting(address strategy, uint apr) external;

}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "./IVaultInsurance.sol";
import "./IERC20.sol";
import "./ISplitter.sol";

interface ITetuVaultV2 {

  function splitter() external view returns (ISplitter);

  function insurance() external view returns (IVaultInsurance);

  function depositFee() external view returns (uint);

  function withdrawFee() external view returns (uint);

  function init(
    address controller_,
    IERC20 _asset,
    string memory _name,
    string memory _symbol,
    address _gauge,
    uint _buffer
  ) external;

  function setSplitter(address _splitter) external;

  function coverLoss(uint amount) external;

  function initInsurance(IVaultInsurance _insurance) external;

}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface IVaultInsurance {

  function init(address _vault, address _asset) external;

  function vault() external view returns (address);

  function asset() external view returns (address);

  function transferToVault(uint amount) external;

}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.17;

/// @notice Arithmetic library with operations for fixed-point numbers.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/FixedPointMathLib.sol)
/// @author Inspired by USM (https://github.com/usmfum/USM/blob/master/contracts/WadMath.sol)
library FixedPointMathLib {
  /*//////////////////////////////////////////////////////////////
  //SIMPLIFIED FIXED POINT OPERATIONS
  //////////////////////////////////////////////////////////////*/

  uint internal constant WAD = 1e18; // The scalar of ETH and most ERC20s.

  function mulWadDown(uint x, uint y) internal pure returns (uint) {
    return mulDivDown(x, y, WAD);
    // Equivalent to (x * y) / WAD rounded down.
  }

  function mulWadUp(uint x, uint y) internal pure returns (uint) {
    return mulDivUp(x, y, WAD);
    // Equivalent to (x * y) / WAD rounded up.
  }

  function divWadDown(uint x, uint y) internal pure returns (uint) {
    return mulDivDown(x, WAD, y);
    // Equivalent to (x * WAD) / y rounded down.
  }

  function divWadUp(uint x, uint y) internal pure returns (uint) {
    return mulDivUp(x, WAD, y);
    // Equivalent to (x * WAD) / y rounded up.
  }

  function positiveInt128(int128 value) internal pure returns (int128) {
    return value < 0 ? int128(0) : value;
  }

  /*//////////////////////////////////////////////////////////////
  //LOW LEVEL FIXED POINT OPERATIONS
  //////////////////////////////////////////////////////////////*/

  function mulDivDown(
    uint x,
    uint y,
    uint denominator
  ) internal pure returns (uint z) {
    assembly {
    // Store x * y in z for now.
      z := mul(x, y)

    // Equivalent to require(denominator != 0 && (x == 0 || (x * y) / x == y))
      if iszero(and(iszero(iszero(denominator)), or(iszero(x), eq(div(z, x), y)))) {
        revert(0, 0)
      }

    // Divide z by the denominator.
      z := div(z, denominator)
    }
  }

  function mulDivUp(
    uint x,
    uint y,
    uint denominator
  ) internal pure returns (uint z) {
    assembly {
    // Store x * y in z for now.
      z := mul(x, y)

    // Equivalent to require(denominator != 0 && (x == 0 || (x * y) / x == y))
      if iszero(and(iszero(iszero(denominator)), or(iszero(x), eq(div(z, x), y)))) {
        revert(0, 0)
      }

    // First, divide z - 1 by the denominator and add 1.
    // We allow z - 1 to underflow if z is 0, because we multiply the
    // end result by 0 if z is zero, ensuring we return 0 if z is zero.
      z := mul(iszero(iszero(z)), add(div(sub(z, 1), denominator), 1))
    }
  }

  function rpow(
    uint x,
    uint n,
    uint scalar
  ) internal pure returns (uint z) {
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
  // GENERAL NUMBER UTILITIES
  //////////////////////////////////////////////////////////////*/

  function sqrt(uint x) internal pure returns (uint z) {
    assembly {
    // Start off with z at 1.
      z := 1

    // Used below to help find a nearby power of 2.
      let y := x

    // Find the lowest power of 2 that is at least sqrt(x).
      if iszero(lt(y, 0x100000000000000000000000000000000)) {
        y := shr(128, y) // Like dividing by 2 ** 128.
        z := shl(64, z) // Like multiplying by 2 ** 64.
      }
      if iszero(lt(y, 0x10000000000000000)) {
        y := shr(64, y) // Like dividing by 2 ** 64.
        z := shl(32, z) // Like multiplying by 2 ** 32.
      }
      if iszero(lt(y, 0x100000000)) {
        y := shr(32, y) // Like dividing by 2 ** 32.
        z := shl(16, z) // Like multiplying by 2 ** 16.
      }
      if iszero(lt(y, 0x10000)) {
        y := shr(16, y) // Like dividing by 2 ** 16.
        z := shl(8, z) // Like multiplying by 2 ** 8.
      }
      if iszero(lt(y, 0x100)) {
        y := shr(8, y) // Like dividing by 2 ** 8.
        z := shl(4, z) // Like multiplying by 2 ** 4.
      }
      if iszero(lt(y, 0x10)) {
        y := shr(4, y) // Like dividing by 2 ** 4.
        z := shl(2, z) // Like multiplying by 2 ** 2.
      }
      if iszero(lt(y, 0x8)) {
      // Equivalent to 2 ** z.
        z := shl(1, z)
      }

    // Shifting right by 1 is like dividing by 2.
      z := shr(1, add(z, div(x, z)))
      z := shr(1, add(z, div(x, z)))
      z := shr(1, add(z, div(x, z)))
      z := shr(1, add(z, div(x, z)))
      z := shr(1, add(z, div(x, z)))
      z := shr(1, add(z, div(x, z)))
      z := shr(1, add(z, div(x, z)))

    // Compute a rounded down version of z.
      let zRoundDown := div(x, z)

    // If zRoundDown is smaller, use it.
      if lt(zRoundDown, z) {
        z := zRoundDown
      }
    }
  }
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

pragma solidity 0.8.17;

/// @title Library for setting / getting slot variables (used in upgradable proxy contracts)
/// @author bogdoslav
library SlotsLib {

  /// @notice Version of the contract
  /// @dev Should be incremented when contract changed
  string public constant SLOT_LIB_VERSION = "1.0.0";

  // ************* GETTERS *******************

  /// @dev Gets a slot as bytes32
  function getBytes32(bytes32 slot) internal view returns (bytes32 result) {
    assembly {
      result := sload(slot)
    }
  }

  /// @dev Gets a slot as an address
  function getAddress(bytes32 slot) internal view returns (address result) {
    assembly {
      result := sload(slot)
    }
  }

  /// @dev Gets a slot as uint256
  function getUint(bytes32 slot) internal view returns (uint result) {
    assembly {
      result := sload(slot)
    }
  }

  // ************* ARRAY GETTERS *******************

  /// @dev Gets an array length
  function arrayLength(bytes32 slot) internal view returns (uint result) {
    assembly {
      result := sload(slot)
    }
  }

  /// @dev Gets a slot array by index as address
  /// @notice First slot is array length, elements ordered backward in memory
  /// @notice This is unsafe, without checking array length.
  function addressAt(bytes32 slot, uint index) internal view returns (address result) {
    bytes32 pointer = bytes32(uint(slot) - 1 - index);
    assembly {
      result := sload(pointer)
    }
  }

  /// @dev Gets a slot array by index as uint
  /// @notice First slot is array length, elements ordered backward in memory
  /// @notice This is unsafe, without checking array length.
  function uintAt(bytes32 slot, uint index) internal view returns (uint result) {
    bytes32 pointer = bytes32(uint(slot) - 1 - index);
    assembly {
      result := sload(pointer)
    }
  }

  // ************* SETTERS *******************

  /// @dev Sets a slot with bytes32
  /// @notice Check address for 0 at the setter
  function set(bytes32 slot, bytes32 value) internal {
    assembly {
      sstore(slot, value)
    }
  }

  /// @dev Sets a slot with address
  /// @notice Check address for 0 at the setter
  function set(bytes32 slot, address value) internal {
    assembly {
      sstore(slot, value)
    }
  }

  /// @dev Sets a slot with uint
  function set(bytes32 slot, uint value) internal {
    assembly {
      sstore(slot, value)
    }
  }

  // ************* ARRAY SETTERS *******************

  /// @dev Sets a slot array at index with address
  /// @notice First slot is array length, elements ordered backward in memory
  /// @notice This is unsafe, without checking array length.
  function setAt(bytes32 slot, uint index, address value) internal {
    bytes32 pointer = bytes32(uint(slot) - 1 - index);
    assembly {
      sstore(pointer, value)
    }
  }

  /// @dev Sets a slot array at index with uint
  /// @notice First slot is array length, elements ordered backward in memory
  /// @notice This is unsafe, without checking array length.
  function setAt(bytes32 slot, uint index, uint value) internal {
    bytes32 pointer = bytes32(uint(slot) - 1 - index);
    assembly {
      sstore(pointer, value)
    }
  }

  /// @dev Sets an array length
  function setLength(bytes32 slot, uint length) internal {
    assembly {
      sstore(slot, length)
    }
  }

  /// @dev Pushes an address to the array
  function push(bytes32 slot, address value) internal {
    uint length = arrayLength(slot);
    setAt(slot, length, value);
    setLength(slot, length + 1);
  }

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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity 0.8.17;
import "./Initializable.sol";

/**
 * https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/release-v4.6/contracts/utils/ContextUpgradeable.sol
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
  function __Context_init() internal onlyInitializing {
  }

  function __Context_init_unchained() internal onlyInitializing {
  }
  function _msgSender() internal view virtual returns (address) {
    return msg.sender;
  }

  function _msgData() internal view virtual returns (bytes calldata) {
    return msg.data;
  }

  /**
   * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
  uint[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity 0.8.17;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library CountersUpgradeable {
  struct Counter {
    // This variable should never be directly accessed by users of the library: interactions must be restricted to
    // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
    // this feature: see https://github.com/ethereum/solidity/issues/4637
    uint256 _value; // default: 0
  }

  function current(Counter storage counter) internal view returns (uint256) {
    return counter._value;
  }

  function increment(Counter storage counter) internal {
  unchecked {
    counter._value += 1;
  }
  }

  function decrement(Counter storage counter) internal {
    uint256 value = counter._value;
    require(value > 0, "Counter: decrement overflow");
  unchecked {
    counter._value = value - 1;
  }
  }

  function reset(Counter storage counter) internal {
    counter._value = 0;
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/cryptography/ECDSA.sol)

pragma solidity 0.8.17;

import "./Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSAUpgradeable {
  enum RecoverError {
    NoError,
    InvalidSignature,
    InvalidSignatureLength,
    InvalidSignatureS,
    InvalidSignatureV // Deprecated in v4.8
  }

  function _throwError(RecoverError error) private pure {
    if (error == RecoverError.NoError) {
      return; // no error: do nothing
    } else if (error == RecoverError.InvalidSignature) {
      revert("ECDSA: invalid signature");
    } else if (error == RecoverError.InvalidSignatureLength) {
      revert("ECDSA: invalid signature length");
    } else if (error == RecoverError.InvalidSignatureS) {
      revert("ECDSA: invalid signature 's' value");
    }
  }

  /**
   * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
  function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
    if (signature.length == 65) {
      bytes32 r;
      bytes32 s;
      uint8 v;
      // ecrecover takes the signature parameters, and the only way to get them
      // currently is to use assembly.
      /// @solidity memory-safe-assembly
      assembly {
        r := mload(add(signature, 0x20))
        s := mload(add(signature, 0x40))
        v := byte(0, mload(add(signature, 0x60)))
      }
      return tryRecover(hash, v, r, s);
    } else {
      return (address(0), RecoverError.InvalidSignatureLength);
    }
  }

  /**
   * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
  function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
    (address recovered, RecoverError error) = tryRecover(hash, signature);
    _throwError(error);
    return recovered;
  }

  /**
   * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
  function tryRecover(
    bytes32 hash,
    bytes32 r,
    bytes32 vs
  ) internal pure returns (address, RecoverError) {
    bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
    uint8 v = uint8((uint256(vs) >> 255) + 27);
    return tryRecover(hash, v, r, s);
  }

  /**
   * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
  function recover(
    bytes32 hash,
    bytes32 r,
    bytes32 vs
  ) internal pure returns (address) {
    (address recovered, RecoverError error) = tryRecover(hash, r, vs);
    _throwError(error);
    return recovered;
  }

  /**
   * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
  function tryRecover(
    bytes32 hash,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) internal pure returns (address, RecoverError) {
    // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
    // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
    // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
    // signatures from current libraries generate a unique signature with an s-value in the lower half order.
    //
    // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
    // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
    // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
    // these malleable signatures as well.
    if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
      return (address(0), RecoverError.InvalidSignatureS);
    }

    // If the signature is valid (and not malleable), return the signer address
    address signer = ecrecover(hash, v, r, s);
    if (signer == address(0)) {
      return (address(0), RecoverError.InvalidSignature);
    }

    return (signer, RecoverError.NoError);
  }

  /**
   * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
  function recover(
    bytes32 hash,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) internal pure returns (address) {
    (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
    _throwError(error);
    return recovered;
  }

  /**
   * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
  function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
    // 32 is the length in bytes of hash,
    // enforced by the type signature above
    return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
  }

  /**
   * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
  function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
  }

  /**
   * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
  function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "./ECDSAUpgradeable.sol";
import "./Initializable.sol";

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 *
 * @custom:storage-size 52
 */
abstract contract EIP712Upgradeable is Initializable {
  /* solhint-disable var-name-mixedcase */
  bytes32 private _HASHED_NAME;
  bytes32 private _HASHED_VERSION;
  bytes32 private constant _TYPE_HASH = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

  /* solhint-enable var-name-mixedcase */

  /**
   * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
  function __EIP712_init(string memory name, string memory version) internal onlyInitializing {
    __EIP712_init_unchained(name, version);
  }

  function __EIP712_init_unchained(string memory name, string memory version) internal onlyInitializing {
    bytes32 hashedName = keccak256(bytes(name));
    bytes32 hashedVersion = keccak256(bytes(version));
    _HASHED_NAME = hashedName;
    _HASHED_VERSION = hashedVersion;
  }

  /**
   * @dev Returns the domain separator for the current chain.
     */
  function _domainSeparatorV4() internal view returns (bytes32) {
    return _buildDomainSeparator(_TYPE_HASH, _EIP712NameHash(), _EIP712VersionHash());
  }

  function _buildDomainSeparator(
    bytes32 typeHash,
    bytes32 nameHash,
    bytes32 versionHash
  ) private view returns (bytes32) {
    return keccak256(abi.encode(typeHash, nameHash, versionHash, block.chainid, address(this)));
  }

  /**
   * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
  function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
    return ECDSAUpgradeable.toTypedDataHash(_domainSeparatorV4(), structHash);
  }

  /**
   * @dev The hash of the name parameter for the EIP712 domain.
     *
     * NOTE: This function reads from storage by default, but can be redefined to return a constant value if gas costs
     * are a concern.
     */
  function _EIP712NameHash() internal virtual view returns (bytes32) {
    return _HASHED_NAME;
  }

  /**
   * @dev The hash of the version parameter for the EIP712 domain.
     *
     * NOTE: This function reads from storage by default, but can be redefined to return a constant value if gas costs
     * are a concern.
     */
  function _EIP712VersionHash() internal virtual view returns (bytes32) {
    return _HASHED_VERSION;
  }

  /**
   * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
  uint256[50] private __gap;
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/extensions/draft-ERC20Permit.sol)

pragma solidity 0.8.17;

import "./ERC20Upgradeable.sol";
import "./ECDSAUpgradeable.sol";
import "./EIP712Upgradeable.sol";
import "./CountersUpgradeable.sol";
import "./Initializable.sol";
import "../interfaces/IERC20Permit.sol";

/**
 * @dev Implementation of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on `{IERC20-approve}`, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 *
 * _Available since v3.4._
 *
 * @custom:storage-size 51
 */
abstract contract ERC20PermitUpgradeable is Initializable, ERC20Upgradeable, IERC20Permit, EIP712Upgradeable {
  using CountersUpgradeable for CountersUpgradeable.Counter;

  mapping(address => CountersUpgradeable.Counter) private _nonces;

  // solhint-disable-next-line var-name-mixedcase
  bytes32 private constant _PERMIT_TYPEHASH =
  keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
  /**
   * @dev In previous versions `_PERMIT_TYPEHASH` was declared as `immutable`.
     * However, to ensure consistency with the upgradeable transpiler, we will continue
     * to reserve a slot.
     * @custom:oz-renamed-from _PERMIT_TYPEHASH
     */
  // solhint-disable-next-line var-name-mixedcase
  bytes32 private _PERMIT_TYPEHASH_DEPRECATED_SLOT;

  /**
   * @dev Initializes the {EIP712} domain separator using the `name` parameter, and setting `version` to `"1"`.
     *
     * It's a good idea to use the same `name` that is defined as the ERC20 token name.
     */
  function __ERC20Permit_init(string memory name) internal onlyInitializing {
    __EIP712_init_unchained(name, "1");
  }

  function __ERC20Permit_init_unchained(string memory) internal onlyInitializing {}

  /**
   * @dev See {IERC20Permit-permit}.
     */
  function permit(
    address owner,
    address spender,
    uint256 value,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) public virtual override {
    require(block.timestamp <= deadline, "ERC20Permit: expired deadline");

    bytes32 structHash = keccak256(abi.encode(_PERMIT_TYPEHASH, owner, spender, value, _useNonce(owner), deadline));

    bytes32 hash = _hashTypedDataV4(structHash);

    address signer = ECDSAUpgradeable.recover(hash, v, r, s);
    require(signer == owner, "ERC20Permit: invalid signature");

    _approve(owner, spender, value);
  }

  /**
   * @dev See {IERC20Permit-nonces}.
     */
  function nonces(address owner) public view virtual override returns (uint256) {
    return _nonces[owner].current();
  }

  /**
   * @dev See {IERC20Permit-DOMAIN_SEPARATOR}.
     */
  // solhint-disable-next-line func-name-mixedcase
  function DOMAIN_SEPARATOR() external view override returns (bytes32) {
    return _domainSeparatorV4();
  }

  /**
   * @dev "Consume a nonce": return the current value and increment.
     *
     * _Available since v4.1._
     */
  function _useNonce(address owner) internal virtual returns (uint256 current) {
    CountersUpgradeable.Counter storage nonce = _nonces[owner];
    current = nonce.current();
    nonce.increment();
  }

  /**
   * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
  uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

pragma solidity 0.8.17;

import "../interfaces/IERC20.sol";
import "../interfaces/IERC20Metadata.sol";
import "./ContextUpgradeable.sol";
import "./Initializable.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20, IERC20Metadata {
  mapping(address => uint256) private _balances;

  mapping(address => mapping(address => uint256)) internal _allowances;

  uint256 private _totalSupply;

  string private _name;
  string private _symbol;

  /**
   * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
  function __ERC20_init(string memory name_, string memory symbol_) internal onlyInitializing {
    __ERC20_init_unchained(name_, symbol_);
  }

  function __ERC20_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
    _name = name_;
    _symbol = symbol_;
  }

  /**
   * @dev Returns the name of the token.
     */
  function name() public view virtual override returns (string memory) {
    return _name;
  }

  /**
   * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
  function symbol() public view virtual override returns (string memory) {
    return _symbol;
  }

  /**
   * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
  function decimals() public view virtual override returns (uint8) {
    return 18;
  }

  /**
   * @dev See {IERC20-totalSupply}.
     */
  function totalSupply() public view virtual override returns (uint256) {
    return _totalSupply;
  }

  /**
   * @dev See {IERC20-balanceOf}.
     */
  function balanceOf(address account) public view virtual override returns (uint256) {
    return _balances[account];
  }

  /**
   * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
  function transfer(address to, uint256 amount) public virtual override returns (bool) {
    address owner = _msgSender();
    _transfer(owner, to, amount);
    return true;
  }

  /**
   * @dev See {IERC20-allowance}.
     */
  function allowance(address owner, address spender) public view virtual override returns (uint256) {
    return _allowances[owner][spender];
  }

  /**
   * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
  function approve(address spender, uint256 amount) public virtual override returns (bool) {
    address owner = _msgSender();
    _approve(owner, spender, amount);
    return true;
  }

  /**
   * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
  function transferFrom(
    address from,
    address to,
    uint256 amount
  ) public virtual override returns (bool) {
    address spender = _msgSender();
    _spendAllowance(from, spender, amount);
    _transfer(from, to, amount);
    return true;
  }

  /**
   * @dev Atomically increases the allowance granted to `spender` by the caller.
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
  function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
    address owner = _msgSender();
    _approve(owner, spender, allowance(owner, spender) + addedValue);
    return true;
  }

  /**
   * @dev Atomically decreases the allowance granted to `spender` by the caller.
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
  function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
    address owner = _msgSender();
    uint256 currentAllowance = allowance(owner, spender);
    require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
  unchecked {
    _approve(owner, spender, currentAllowance - subtractedValue);
  }

    return true;
  }

  /**
   * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
  function _transfer(
    address from,
    address to,
    uint256 amount
  ) internal virtual {
    require(from != address(0), "ERC20: transfer from the zero address");
    require(to != address(0), "ERC20: transfer to the zero address");

    _beforeTokenTransfer(from, to, amount);

    uint256 fromBalance = _balances[from];
    require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
  unchecked {
    _balances[from] = fromBalance - amount;
    // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
    // decrementing then incrementing.
    _balances[to] += amount;
  }

    emit Transfer(from, to, amount);

    _afterTokenTransfer(from, to, amount);
  }

  /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
  function _mint(address account, uint256 amount) internal virtual {
    require(account != address(0), "ERC20: mint to the zero address");

    _beforeTokenTransfer(address(0), account, amount);

    _totalSupply += amount;
  unchecked {
    // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
    _balances[account] += amount;
  }
    emit Transfer(address(0), account, amount);

    _afterTokenTransfer(address(0), account, amount);
  }

  /**
   * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
  function _burn(address account, uint256 amount) internal virtual {
    require(account != address(0), "ERC20: burn from the zero address");

    _beforeTokenTransfer(account, address(0), amount);

    uint256 accountBalance = _balances[account];
    require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
  unchecked {
    _balances[account] = accountBalance - amount;
    // Overflow not possible: amount <= accountBalance <= totalSupply.
    _totalSupply -= amount;
  }

    emit Transfer(account, address(0), amount);

    _afterTokenTransfer(account, address(0), amount);
  }

  /**
   * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
  function _approve(
    address owner,
    address spender,
    uint256 amount
  ) internal virtual {
    require(owner != address(0), "ERC20: approve from the zero address");
    require(spender != address(0), "ERC20: approve to the zero address");

    _allowances[owner][spender] = amount;
    emit Approval(owner, spender, amount);
  }

  /**
   * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
  function _spendAllowance(
    address owner,
    address spender,
    uint256 amount
  ) internal virtual {
    uint256 currentAllowance = allowance(owner, spender);
    if (currentAllowance != type(uint256).max) {
      require(currentAllowance >= amount, "ERC20: insufficient allowance");
    unchecked {
      _approve(owner, spender, currentAllowance - amount);
    }
    }
  }

  /**
   * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal virtual {}

  /**
   * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
  function _afterTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal virtual {}

  /**
   * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
  uint256[45] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/utils/Initializable.sol)

pragma solidity 0.8.17;

import "./Address.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
  /**
   * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
  uint8 private _initialized;

  /**
   * @dev Indicates that the contract is in the process of being initialized.
     */
  bool private _initializing;

  /**
   * @dev Triggered when the contract has been initialized or reinitialized.
     */
  event Initialized(uint8 version);

  /**
   * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
  modifier initializer() {
    bool isTopLevelCall = !_initializing;
    require(
      (isTopLevelCall && _initialized < 1) || (!Address.isContract(address(this)) && _initialized == 1),
      "Initializable: contract is already initialized"
    );
    _initialized = 1;
    if (isTopLevelCall) {
      _initializing = true;
    }
    _;
    if (isTopLevelCall) {
      _initializing = false;
      emit Initialized(1);
    }
  }

  /**
   * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
  modifier reinitializer(uint8 version) {
    require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
    _initialized = version;
    _initializing = true;
    _;
    _initializing = false;
    emit Initialized(version);
  }

  /**
   * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
  modifier onlyInitializing() {
    require(_initializing, "Initializable: contract is not initializing");
    _;
  }

  /**
   * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
  function _disableInitializers() internal virtual {
    require(!_initializing, "Initializable: contract is initializing");
    if (_initialized != type(uint8).max) {
      _initialized = type(uint8).max;
      emit Initialized(type(uint8).max);
    }
  }

  /**
   * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
  function _getInitializedVersion() internal view returns (uint8) {
    return _initialized;
  }

  /**
   * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
  function _isInitializing() internal view returns (bool) {
    return _initializing;
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
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity 0.8.17;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
  // Booleans are more expensive than uint256 or any type that takes up a full
  // word because each write operation emits an extra SLOAD to first read the
  // slot's contents, replace the bits taken up by the boolean, and then write
  // back. This is the compiler's defense against contract upgrades and
  // pointer aliasing, and it cannot be disabled.

  // The values being non-zero value makes deployment a bit more expensive,
  // but in exchange the refund on every call to nonReentrant will be lower in
  // amount. Since refunds are capped to a percentage of the total
  // transaction's gas, it is best to keep them low in cases like this one, to
  // increase the likelihood of the full refund coming into effect.
  uint256 private constant _NOT_ENTERED = 1;
  uint256 private constant _ENTERED = 2;

  uint256 private _status;

  constructor() {
    _status = _NOT_ENTERED;
  }

  /**
   * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
  modifier nonReentrant() {
    _nonReentrantBefore();
    _;
    _nonReentrantAfter();
  }

  function _nonReentrantBefore() private {
    // On the first call to nonReentrant, _status will be _NOT_ENTERED
    require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

    // Any calls to nonReentrant after this point will fail
    _status = _ENTERED;
  }

  function _nonReentrantAfter() private {
    // By storing the original value once again, a refund is triggered (see
    // https://eips.ethereum.org/EIPS/eip-2200)
    _status = _NOT_ENTERED;
  }

  /**
   * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
  function _reentrancyGuardEntered() internal view returns (bool) {
    return _status == _ENTERED;
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./Math.sol";

/**
 * @dev String operations.
 */
library Strings {
  bytes16 private constant _SYMBOLS = "0123456789abcdef";
  uint8 private constant _ADDRESS_LENGTH = 20;

  /**
   * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
  function toString(uint256 value) internal pure returns (string memory) {
  unchecked {
    uint256 length = Math.log10(value) + 1;
    string memory buffer = new string(length);
    uint256 ptr;
    /// @solidity memory-safe-assembly
    assembly {
      ptr := add(buffer, add(32, length))
    }
    while (true) {
      ptr--;
      /// @solidity memory-safe-assembly
      assembly {
        mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
      }
      value /= 10;
      if (value == 0) break;
    }
    return buffer;
  }
  }

  /**
   * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
  function toHexString(uint256 value) internal pure returns (string memory) {
  unchecked {
    return toHexString(value, Math.log256(value) + 1);
  }
  }

  /**
   * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
  function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
    bytes memory buffer = new bytes(2 * length + 2);
    buffer[0] = "0";
    buffer[1] = "x";
    for (uint256 i = 2 * length + 1; i > 1; --i) {
      buffer[i] = _SYMBOLS[value & 0xf];
      value >>= 4;
    }
    require(value == 0, "Strings: hex length insufficient");
    return string(buffer);
  }

  /**
   * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
  function toHexString(address addr) internal pure returns (string memory) {
    return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "../openzeppelin/Initializable.sol";
import "../tools/TetuERC165.sol";
import "../interfaces/IControllable.sol";
import "../interfaces/IController.sol";
import "../lib/SlotsLib.sol";
import "../lib/InterfaceIds.sol";

/// @title Implement basic functionality for any contract that require strict control
/// @dev Can be used with upgradeable pattern.
///      Require call __Controllable_init() in any case.
/// @author belbix
abstract contract ControllableV3 is Initializable, TetuERC165, IControllable {
  using SlotsLib for bytes32;

  /// @notice Version of the contract
  /// @dev Should be incremented when contract changed
  string public constant CONTROLLABLE_VERSION = "3.0.0";

  bytes32 internal constant _CONTROLLER_SLOT = bytes32(uint256(keccak256("eip1967.controllable.controller")) - 1);
  bytes32 internal constant _CREATED_SLOT = bytes32(uint256(keccak256("eip1967.controllable.created")) - 1);
  bytes32 internal constant _CREATED_BLOCK_SLOT = bytes32(uint256(keccak256("eip1967.controllable.created_block")) - 1);
  bytes32 internal constant _REVISION_SLOT = bytes32(uint256(keccak256("eip1967.controllable.revision")) - 1);
  bytes32 internal constant _PREVIOUS_LOGIC_SLOT = bytes32(uint256(keccak256("eip1967.controllable.prev_logic")) - 1);

  event ContractInitialized(address controller, uint ts, uint block);
  event RevisionIncreased(uint value, address oldLogic);

  /// @dev Prevent implementation init
  constructor() {
    _disableInitializers();
  }

  /// @notice Initialize contract after setup it as proxy implementation
  ///         Save block.timestamp in the "created" variable
  /// @dev Use it only once after first logic setup
  /// @param controller_ Controller address
  function __Controllable_init(address controller_) internal onlyInitializing {
    require(controller_ != address(0), "Zero controller");
    _requireInterface(controller_, InterfaceIds.I_CONTROLLER);
    require(IController(controller_).governance() != address(0), "Zero governance");
    _CONTROLLER_SLOT.set(controller_);
    _CREATED_SLOT.set(block.timestamp);
    _CREATED_BLOCK_SLOT.set(block.number);
    emit ContractInitialized(controller_, block.timestamp, block.number);
  }

  /// @dev Return true if given address is controller
  function isController(address _value) public override view returns (bool) {
    return _value == controller();
  }

  /// @notice Return true if given address is setup as governance in Controller
  function isGovernance(address _value) public override view returns (bool) {
    return IController(controller()).governance() == _value;
  }

  /// @dev Contract upgrade counter
  function revision() external view returns (uint){
    return _REVISION_SLOT.getUint();
  }

  /// @dev Previous logic implementation
  function previousImplementation() external view returns (address){
    return _PREVIOUS_LOGIC_SLOT.getAddress();
  }

  /// @dev See {IERC165-supportsInterface}.
  function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
    return interfaceId == InterfaceIds.I_CONTROLLABLE || super.supportsInterface(interfaceId);
  }

  // ************* SETTERS/GETTERS *******************

  /// @notice Return controller address saved in the contract slot
  function controller() public view override returns (address) {
    return _CONTROLLER_SLOT.getAddress();
  }

  /// @notice Return creation timestamp
  /// @return Creation timestamp
  function created() external view override returns (uint256) {
    return _CREATED_SLOT.getUint();
  }

  /// @notice Return creation block number
  /// @return Creation block number
  function createdBlock() external override view returns (uint256) {
    return _CREATED_BLOCK_SLOT.getUint();
  }

  /// @dev Revision should be increased on each contract upgrade
  function increaseRevision(address oldLogic) external override {
    require(msg.sender == address(this), "Increase revision forbidden");
    uint r = _REVISION_SLOT.getUint() + 1;
    _REVISION_SLOT.set(r);
    _PREVIOUS_LOGIC_SLOT.set(oldLogic);
    emit RevisionIncreased(r, oldLogic);
  }

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

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "../openzeppelin/ERC20PermitUpgradeable.sol";
import "../openzeppelin/SafeERC20.sol";
import "../openzeppelin/ReentrancyGuard.sol";
import "../interfaces/IERC4626.sol";
import "../lib/FixedPointMathLib.sol";

/// @notice Minimal ERC4626 tokenized Vault implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/mixins/ERC4626.sol)
/// @author belbix - adopted to proxy pattern + added ReentrancyGuard
abstract contract ERC4626Upgradeable is ERC20PermitUpgradeable, ReentrancyGuard, IERC4626 {
  using SafeERC20 for IERC20;
  using FixedPointMathLib for uint;

  uint internal constant INITIAL_SHARES = 1000;
  address internal constant DEAD_ADDRESS = 0xdEad000000000000000000000000000000000000;

  /// @dev The address of the underlying token used for the Vault uses for accounting,
  ///      depositing, and withdrawing
  IERC20 internal _asset;

  function __ERC4626_init(
    IERC20 asset_,
    string memory _name,
    string memory _symbol
  ) internal onlyInitializing {
    __ERC20_init(_name, _symbol);
    _asset = asset_;
  }

  function decimals() public view override(IERC20Metadata, ERC20Upgradeable) returns (uint8) {
    return IERC20Metadata(address(_asset)).decimals();
  }

  function asset() external view override returns (address) {
    return address(_asset);
  }

  /*//////////////////////////////////////////////////////////////
  //             DEPOSIT/WITHDRAWAL LOGIC
  //////////////////////////////////////////////////////////////*/

  /// @dev Mints vault shares to receiver by depositing exactly amount of assets.
  function deposit(
    uint assets,
    address receiver
  ) public nonReentrant virtual override returns (uint shares) {
    require(assets <= maxDeposit(receiver), "MAX");

    shares = previewDeposit(assets);
    // Check for rounding error since we round down in previewDeposit.
    require(shares != 0, "ZERO_SHARES");

    // Need to transfer before minting or ERC777s could reenter.
    _asset.safeTransferFrom(msg.sender, address(this), assets);

    if(totalSupply() == 0) {
      _mint(receiver, shares - INITIAL_SHARES);
      _mint(DEAD_ADDRESS, INITIAL_SHARES);
    } else {
      _mint(receiver, shares);
    }

    emit Deposit(msg.sender, receiver, assets, shares);

    afterDeposit(assets, shares, receiver);
  }

  function mint(
    uint shares,
    address receiver
  ) public nonReentrant virtual override returns (uint assets) {
    require(shares <= maxMint(receiver), "MAX");

    assets = previewMint(shares);
    // No need to check for rounding error, previewMint rounds up.

    // Need to transfer before minting or ERC777s could reenter.
    _asset.safeTransferFrom(msg.sender, address(this), assets);

    if(totalSupply() == 0) {
      _mint(receiver, shares - INITIAL_SHARES);
      _mint(DEAD_ADDRESS, INITIAL_SHARES);
    } else {
      _mint(receiver, shares);
    }

    emit Deposit(msg.sender, receiver, assets, shares);

    afterDeposit(assets, shares, receiver);
  }

  function withdraw(
    uint assets,
    address receiver,
    address owner
  ) public nonReentrant virtual override returns (uint shares) {
    require(assets <= maxWithdraw(owner), "MAX");

    shares = previewWithdraw(assets);
    // No need to check for rounding error, previewWithdraw rounds up.

    if (msg.sender != owner) {
      uint allowed = _allowances[owner][msg.sender];
      // Saves gas for limited approvals.
      if (allowed != type(uint).max) _allowances[owner][msg.sender] = allowed - shares;
    }

    beforeWithdraw(assets, shares, receiver);

    _burn(owner, shares);

    emit Withdraw(msg.sender, receiver, owner, assets, shares);

    _asset.safeTransfer(receiver, assets);
  }

  /// @dev Redeems shares from owner and sends assets to receiver.
  function redeem(
    uint shares,
    address receiver,
    address owner
  ) public nonReentrant virtual override returns (uint assets) {
    require(shares <= maxRedeem(owner), "MAX");

    if (msg.sender != owner) {
      uint allowed = _allowances[owner][msg.sender];
      // Saves gas for limited approvals.
      if (allowed != type(uint).max) _allowances[owner][msg.sender] = allowed - shares;
    }

    assets = previewRedeem(shares);
    // Check for rounding error since we round down in previewRedeem.
    require(assets != 0, "ZERO_ASSETS");

    beforeWithdraw(assets, shares, receiver);

    _burn(owner, shares);

    emit Withdraw(msg.sender, receiver, owner, assets, shares);

    _asset.safeTransfer(receiver, assets);
  }

  /*//////////////////////////////////////////////////////////////
  //                  ACCOUNTING LOGIC
  //////////////////////////////////////////////////////////////*/

  /// @dev Total amount of the underlying asset that is “managed” by Vault
  function totalAssets() public view virtual override returns (uint);

  function convertToShares(uint assets) public view virtual override returns (uint) {
    uint supply = totalSupply();
    // Saves an extra SLOAD if totalSupply is non-zero.
    return supply == 0 ? assets : assets.mulDivDown(supply, totalAssets());
  }

  function convertToAssets(uint shares) public view virtual override returns (uint) {
    uint supply = totalSupply();
    // Saves an extra SLOAD if totalSupply is non-zero.
    return supply == 0 ? shares : shares.mulDivDown(totalAssets(), supply);
  }

  function previewDeposit(uint assets) public view virtual override returns (uint) {
    return convertToShares(assets);
  }

  function previewMint(uint shares) public view virtual override returns (uint) {
    uint supply = totalSupply();
    // Saves an extra SLOAD if totalSupply is non-zero.
    return supply == 0 ? shares : shares.mulDivUp(totalAssets(), supply);
  }

  function previewWithdraw(uint assets) public view virtual override returns (uint) {
    uint supply = totalSupply();
    // Saves an extra SLOAD if totalSupply is non-zero.
    return supply == 0 ? assets : assets.mulDivUp(supply, totalAssets());
  }

  function previewRedeem(uint shares) public view virtual override returns (uint) {
    return convertToAssets(shares);
  }

  ///////////////////////////////////////////////////////////////
  //           DEPOSIT/WITHDRAWAL LIMIT LOGIC
  ///////////////////////////////////////////////////////////////

  function maxDeposit(address) public view virtual override returns (uint) {
    return type(uint).max - 1;
  }

  function maxMint(address) public view virtual override returns (uint) {
    return type(uint).max - 1;
  }

  function maxWithdraw(address owner) public view virtual override returns (uint) {
    return convertToAssets(balanceOf(owner));
  }

  function maxRedeem(address owner) public view virtual override returns (uint) {
    return balanceOf(owner);
  }

  ///////////////////////////////////////////////////////////////
  //                INTERNAL HOOKS LOGIC
  ///////////////////////////////////////////////////////////////

  function beforeWithdraw(uint assets, uint shares, address receiver) internal virtual {}

  function afterDeposit(uint assets, uint shares, address receiver) internal virtual {}

  /**
 * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
  uint[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "../openzeppelin/Math.sol";
import "../interfaces/ISplitter.sol";
import "../interfaces/ITetuVaultV2.sol";
import "../interfaces/IGauge.sol";
import "../proxy/ControllableV3.sol";
import "./ERC4626Upgradeable.sol";

/// @title Vault for storing underlying tokens and managing them with strategy splitter.
/// @author belbix
contract TetuVaultV2 is ERC4626Upgradeable, ControllableV3, ITetuVaultV2 {
  using SafeERC20 for IERC20;
  using FixedPointMathLib for uint;

  // *************************************************************
  //                        CONSTANTS
  // *************************************************************

  /// @dev Version of this contract. Adjust manually on each code modification.
  string public constant VAULT_VERSION = "2.1.4";
  /// @dev Denominator for buffer calculation. 100% of the buffer amount.
  uint constant public BUFFER_DENOMINATOR = 100_000;
  /// @dev Denominator for fee calculation.
  uint constant public FEE_DENOMINATOR = 100_000;
  /// @dev Max 1% fee.
  uint constant public MAX_FEE = FEE_DENOMINATOR / 100;

  // *************************************************************
  //                        VARIABLES
  //                Keep names and ordering!
  //                 Add only in the bottom.
  // *************************************************************

  /// @dev Strategy splitter. Should be setup after deploy.
  ISplitter public splitter;
  /// @dev Connected gauge for stakeless rewards
  IGauge public gauge;
  /// @dev Dedicated contract for holding insurance for covering share price loss.
  IVaultInsurance public override insurance;
  /// @dev Percent of assets that will always stay in this vault.
  uint public buffer;

  /// @dev Maximum amount for withdraw. Max UINT256 by default.
  uint public maxWithdrawAssets;
  /// @dev Maximum amount for redeem. Max UINT256 by default.
  uint public maxRedeemShares;
  /// @dev Maximum amount for deposit. Max UINT256 by default.
  uint public maxDepositAssets;
  /// @dev Maximum amount for mint. Max UINT256 by default.
  uint public maxMintShares;
  /// @dev Fee for deposit/mint actions. Zero by default.
  uint public override depositFee;
  /// @dev Fee for withdraw/redeem actions. Zero by default.
  uint public override withdrawFee;

  /// @dev Trigger doHardwork on invest action. Enabled by default.
  bool public doHardWorkOnInvest;
  /// @dev msg.sender => block when request sent. Should be cleared on deposit/withdraw action
  ///      For simplification we are setup new withdraw request on each deposit/transfer
  mapping(address => uint) public withdrawRequests;
  /// @dev A user should wait this block amounts before able to withdraw.
  uint public withdrawRequestBlocks;

  // *************************************************************
  //                        EVENTS
  // *************************************************************

  event Init(
    address controller,
    address asset,
    string name,
    string symbol,
    address gauge,
    uint buffer
  );
  event SplitterSetup(address splitter);
  event BufferChanged(uint oldValue, uint newValue);
  event Invest(address splitter, uint amount);
  event MaxWithdrawChanged(uint maxAssets, uint maxShares);
  event MaxDepositChanged(uint maxAssets, uint maxShares);
  event FeeChanged(uint depositFee, uint withdrawFee);
  event DoHardWorkOnInvestChanged(bool oldValue, bool newValue);
  event FeeTransfer(uint amount);
  event LossCovered(uint amount);
  event WithdrawRequested(address sender, uint startBlock);
  event WithdrawRequestBlocks(uint blocks);

  // *************************************************************
  //                        INIT
  // *************************************************************

  /// @dev Proxy initialization. Call it after contract deploy.
  function init(
    address controller_,
    IERC20 asset_,
    string memory _name,
    string memory _symbol,
    address _gauge,
    uint _buffer
  ) external initializer override {
    require(_buffer <= BUFFER_DENOMINATOR, "!BUFFER");
    require(_gauge != address(0), "!GAUGE");
    require(IControllable(_gauge).isController(controller_), "!GAUGE_CONTROLLER");

    _requireERC20(address(asset_));
    __ERC4626_init(asset_, _name, _symbol);
    __Controllable_init(controller_);

    _requireInterface(_gauge, InterfaceIds.I_GAUGE);
    gauge = IGauge(_gauge);
    buffer = _buffer;

    // set defaults
    maxWithdrawAssets = type(uint).max;
    maxRedeemShares = type(uint).max;
    maxDepositAssets = type(uint).max - 1;
    maxMintShares = type(uint).max - 1;
    doHardWorkOnInvest = true;
    withdrawRequestBlocks = 5;
    emit WithdrawRequestBlocks(5);

    emit Init(
      controller_,
      address(asset_),
      _name,
      _symbol,
      _gauge,
      _buffer
    );
  }

  function initInsurance(IVaultInsurance _insurance) external override {
    require(address(insurance) == address(0), "INITED");
    _requireInterface(address(_insurance), InterfaceIds.I_VAULT_INSURANCE);

    require(_insurance.vault() == address(this), "!VAULT");
    require(_insurance.asset() == address(_asset), "!ASSET");
    insurance = _insurance;
  }

  // *************************************************************
  //                      GOV ACTIONS
  // *************************************************************

  /// @dev Set block amount before user will able to withdraw after a request.
  function setWithdrawRequestBlocks(uint blocks) external {
    require(isGovernance(msg.sender), "DENIED");
    withdrawRequestBlocks = blocks;
    emit WithdrawRequestBlocks(blocks);
  }

  /// @dev Set new buffer value. Should be lower than denominator.
  function setBuffer(uint _buffer) external {
    require(isGovernance(msg.sender), "DENIED");
    require(_buffer <= BUFFER_DENOMINATOR, "BUFFER");

    emit BufferChanged(buffer, _buffer);
    buffer = _buffer;
  }

  /// @dev Set maximum available to deposit amounts.
  ///      Could be zero values in emergency case when need to pause malicious actions.
  function setMaxDeposit(uint maxAssets, uint maxShares) external {
    require(isGovernance(msg.sender), "DENIED");

    maxDepositAssets = maxAssets;
    maxMintShares = maxShares;
    emit MaxDepositChanged(maxAssets, maxShares);
  }

  /// @dev Set maximum available to withdraw amounts.
  ///      Could be zero values in emergency case when need to pause malicious actions.
  function setMaxWithdraw(uint maxAssets, uint maxShares) external {
    require(isGovernance(msg.sender), "DENIED");

    maxWithdrawAssets = maxAssets;
    maxRedeemShares = maxShares;
    emit MaxWithdrawChanged(maxAssets, maxShares);
  }

  /// @dev Set deposit/withdraw fees
  function setFees(uint _depositFee, uint _withdrawFee) external {
    require(isGovernance(msg.sender), "DENIED");
    require(_depositFee <= MAX_FEE && _withdrawFee <= MAX_FEE, "TOO_HIGH");

    depositFee = _depositFee;
    withdrawFee = _withdrawFee;
    emit FeeChanged(_depositFee, _withdrawFee);
  }

  /// @dev If activated will call doHardWork on splitter on each invest action.
  function setDoHardWorkOnInvest(bool value) external {
    require(isGovernance(msg.sender), "DENIED");
    emit DoHardWorkOnInvestChanged(doHardWorkOnInvest, value);
    doHardWorkOnInvest = value;
  }

  /// @dev Set splitter address. Can not change exist splitter.
  function setSplitter(address _splitter) external override {
    IERC20 asset_ = _asset;
    require(address(splitter) == address(0), "DENIED");
    _requireInterface(_splitter, InterfaceIds.I_SPLITTER);
    require(ISplitter(_splitter).asset() == address(asset_), "WRONG_UNDERLYING");
    require(ISplitter(_splitter).vault() == address(this), "WRONG_VAULT");
    require(IControllable(_splitter).isController(controller()), "WRONG_CONTROLLER");
    asset_.approve(_splitter, type(uint).max);
    splitter = ISplitter(_splitter);
    emit SplitterSetup(_splitter);
  }

  // *************************************************************
  //                        VIEWS
  // *************************************************************

  /// @dev Total amount of the underlying asset that is “managed” by Vault
  function totalAssets() public view override returns (uint) {
    return _asset.balanceOf(address(this)) + splitter.totalAssets();
  }

  /// @dev Amount of assets under control of strategy splitter.
  function splitterAssets() external view returns (uint) {
    return splitter.totalAssets();
  }

  /// @dev Price of 1 full share
  function sharePrice() external view returns (uint) {
    uint units = 10 ** uint256(decimals());
    uint totalSupply_ = totalSupply();
    return totalSupply_ == 0
      ? units
      : units * totalAssets() / totalSupply_;
  }

  /// @dev See {IERC165-supportsInterface}.
  function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
    return interfaceId == InterfaceIds.I_TETU_VAULT_V2 || super.supportsInterface(interfaceId);
  }

  // *************************************************************
  //                 DEPOSIT LOGIC
  // *************************************************************

  function previewDeposit(uint assets) public view virtual override returns (uint) {
    uint shares = convertToShares(assets);
    return shares - (shares * depositFee / FEE_DENOMINATOR);
  }

  function previewMint(uint shares) public view virtual override returns (uint) {
    uint supply = totalSupply();
    if (supply != 0) {
      uint assets = shares.mulDivUp(totalAssets(), supply);
      return assets * FEE_DENOMINATOR / (FEE_DENOMINATOR - depositFee);
    } else {
      return shares * FEE_DENOMINATOR / (FEE_DENOMINATOR - depositFee);
    }
  }

  /// @dev Calculate available to invest amount and send this amount to splitter
  function afterDeposit(uint assets, uint /*shares*/, address receiver) internal override {
    // reset withdraw request if necessary
    if (withdrawRequestBlocks != 0) {
      withdrawRequests[receiver] = block.number;
    }

    address _splitter = address(splitter);
    IERC20 asset_ = _asset;
    uint _depositFee = depositFee;
    // send fee to insurance contract
    if (_depositFee != 0) {
      uint toFees = assets * _depositFee / FEE_DENOMINATOR;
      asset_.safeTransfer(address(insurance), toFees);
      emit FeeTransfer(toFees);
    }
    uint256 toInvest = _availableToInvest(_splitter, asset_);
    // invest only when buffer is filled
    if (toInvest > 0) {

      // need to check recursive hardworks
      if (doHardWorkOnInvest && !ISplitter(_splitter).isHardWorking()) {
        ISplitter(_splitter).doHardWork();
      }

      asset_.safeTransfer(_splitter, toInvest);
      ISplitter(_splitter).investAll();
      emit Invest(_splitter, toInvest);
    }
  }

  /// @notice Returns amount of assets ready to invest to the splitter
  function _availableToInvest(address _splitter, IERC20 asset_) internal view returns (uint) {
    uint _buffer = buffer;
    if (_splitter == address(0) || _buffer == BUFFER_DENOMINATOR) {
      return 0;
    }
    uint assetsInVault = asset_.balanceOf(address(this));
    uint assetsInSplitter = ISplitter(_splitter).totalAssets();
    uint wantInvestTotal = (assetsInVault + assetsInSplitter)
    * (BUFFER_DENOMINATOR - _buffer) / BUFFER_DENOMINATOR;
    if (assetsInSplitter >= wantInvestTotal) {
      return 0;
    } else {
      uint remainingToInvest = wantInvestTotal - assetsInSplitter;
      return remainingToInvest <= assetsInVault ? remainingToInvest : assetsInVault;
    }
  }

  // *************************************************************
  //                 WITHDRAW LOGIC
  // *************************************************************

  function requestWithdraw() external {
    withdrawRequests[msg.sender] = block.number;
    emit WithdrawRequested(msg.sender, block.number);
  }

  /// @dev Withdraw all available shares for tx sender.
  ///      The revert is expected if the balance is higher than `maxRedeem`
  function withdrawAll() external {
    redeem(balanceOf(msg.sender), msg.sender, msg.sender);
  }

  function previewWithdraw(uint assets) public view virtual override returns (uint) {
    uint supply = totalSupply();
    uint _totalAssets = totalAssets();
    if (_totalAssets == 0) {
      return assets;
    }
    uint shares = assets.mulDivUp(supply, _totalAssets);
    shares = shares * FEE_DENOMINATOR / (FEE_DENOMINATOR - withdrawFee);
    return supply == 0 ? assets : shares;
  }

  function previewRedeem(uint shares) public view virtual override returns (uint) {
    shares = shares - (shares * withdrawFee / FEE_DENOMINATOR);
    return convertToAssets(shares);
  }

  function maxDeposit(address) public view override returns (uint) {
    return maxDepositAssets;
  }

  function maxMint(address) public view override returns (uint) {
    return maxMintShares;
  }

  function maxWithdraw(address owner) public view override returns (uint) {
    uint assets = convertToAssets(balanceOf(owner));
    assets -= assets.mulDivUp(withdrawFee, FEE_DENOMINATOR);
    return Math.min(maxWithdrawAssets, assets);
  }

  function maxRedeem(address owner) public view override returns (uint) {
    return Math.min(maxRedeemShares, balanceOf(owner));
  }

  /// @dev Internal hook for getting necessary assets from splitter.
  function beforeWithdraw(
    uint assets,
    uint shares,
    address receiver
  ) internal override {
    // check withdraw request if necessary
    uint _withdrawRequestBlocks = withdrawRequestBlocks;
    if (_withdrawRequestBlocks != 0) {
      uint wr = withdrawRequests[receiver];
      require(wr != 0 && wr + _withdrawRequestBlocks < block.number, "NOT_REQUESTED");
      withdrawRequests[receiver] = block.number;
    }

    uint _withdrawFee = withdrawFee;
    uint fromSplitter;
    if (_withdrawFee != 0) {
      // add fee amount
      fromSplitter = assets * FEE_DENOMINATOR / (FEE_DENOMINATOR - _withdrawFee);
    } else {
      fromSplitter = assets;
    }

    IERC20 asset_ = _asset;
    uint balance = asset_.balanceOf(address(this));
    // if not enough balance in the vault withdraw from strategies
    if (balance < fromSplitter) {
      _processWithdrawFromSplitter(
        fromSplitter,
        shares,
        totalSupply(),
        buffer,
        splitter,
        balance
      );
    }
    balance = asset_.balanceOf(address(this));
    require(assets <= balance, "SLIPPAGE");

    // send fee amount to insurance for keep correct calculations
    // in case of compensation it will lead to double transfer
    // but we assume that it will be rare case
    if (_withdrawFee != 0) {
      // we should compensate possible slippage from user fee too
      uint toFees = Math.min(fromSplitter - assets, balance - assets);
      if (toFees != 0) {
        asset_.safeTransfer(address(insurance), toFees);
        emit FeeTransfer(toFees);
      }
    }
  }

  /// @dev Do necessary calculation for withdrawing from splitter and move assets to vault.
  ///      If splitter not defined must not be called.
  function _processWithdrawFromSplitter(
    uint assetsNeed,
    uint shares,
    uint totalSupply_,
    uint _buffer,
    ISplitter _splitter,
    uint assetsInVault
  ) internal {
    // withdraw everything from the splitter to accurately check the share value
    if (shares == totalSupply_) {
      _splitter.withdrawAllToVault();
    } else {
      uint assetsInSplitter = _splitter.totalAssets();

      // we should always have buffer amount inside the vault
      // assume `assetsNeed` can not be higher than entire balance
      uint expectedBuffer = (assetsInSplitter + assetsInVault - assetsNeed) * _buffer / BUFFER_DENOMINATOR;

      // this code should not be called if `assetsInVault` higher than `assetsNeed`
      uint missing = Math.min(expectedBuffer + assetsNeed - assetsInVault, assetsInSplitter);
      // if zero should be resolved on splitter side
      _splitter.withdrawToVault(missing);
    }
  }

  // *************************************************************
  //                 INSURANCE LOGIC
  // *************************************************************

  function coverLoss(uint amount) external override {
    require(msg.sender == address(splitter), "!SPLITTER");
    IVaultInsurance _insurance = insurance;
    uint balance = _asset.balanceOf(address(_insurance));
    uint toRecover = Math.min(amount, balance);
    _insurance.transferToVault(toRecover);
    emit LossCovered(toRecover);
  }

  // *************************************************************
  //                 GAUGE HOOK
  // *************************************************************

  /// @dev Connect this vault to the gauge for non-contract addresses.
  function _afterTokenTransfer(
    address from,
    address to,
    uint
  ) internal override {
    // refresh withdraw request if necessary
    if (withdrawRequestBlocks != 0) {
      withdrawRequests[from] = block.number;
      withdrawRequests[to] = block.number;
    }
    gauge.handleBalanceChange(from);
    gauge.handleBalanceChange(to);
  }

}