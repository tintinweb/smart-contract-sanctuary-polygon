// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.9;

import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "./interface/IGeltVault.sol";
import "./interface/strategy/mstable/ISaveWrapper.sol";
import "./interface/strategy/mstable/IMasset.sol";
import "./interface/strategy/mstable/IInterestBearingMasset.sol";
import "./interface/strategy/mstable/IVaultedInterestBearingMasset.sol";
import "./lib/FixedPointMath.sol";
import "./lib/PercentageMath.sol";
import "./TemporarilyPausable.sol";
import "./Migratable.sol";
import "./Authorizable.sol";

/// @title Gelt Vault implementation with mStable as the underlying strategy.
contract MstableGeltVault is
    Initializable,
    ContextUpgradeable,
    UUPSUpgradeable,
    ReentrancyGuardUpgradeable,
    AccessControlUpgradeable,
    ERC20Upgradeable,
    TemporarilyPausable,
    Migratable,
    Authorizable,
    IGeltVault
{
    using FixedPointMath for UFixed256x18;
    using PercentageMath for uint256;
    using SafeCast for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeERC20Upgradeable for IERC20MetadataUpgradeable;

    bytes32 public constant MINT_WITH_AUTHORIZATION_TYPEHASH = keccak256("MintWithAuthorization(address minter,uint256 mintAmount,uint256 validAfter,uint256 validBefore,bytes32 nonce)");
    bytes32 public constant REDEEM_WITH_AUTHORIZATION_TYPEHASH = keccak256("RedeemWithAuthorization(address redeemer,address withdrawTo,uint256 redeemTokens,uint256 validAfter,uint256 validBefore,bytes32 nonce)");

    /// @notice Owner of the vault, it can update the vault and assign roles to accounts.
    bytes32 public constant OWNER_ROLE = keccak256("OWNER_ROLE");
    /// @notice Administrator of the vault, can configure the vault and trigger emergency operations.
    bytes32 public constant ADMINISTRATOR_ROLE = keccak256("ADMINISTRATOR_ROLE");
    /// @notice Operator of the vault, it can interact with the strategy and submit meta-transactions.
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    /// @notice Address of the governance token collector.
    address public collector;

    /// @notice Underlying basket asset (e.g. USDC).
    IERC20MetadataUpgradeable public bAsset;
    /// @notice mStable meta asset (mUSD).
    IMasset public mAsset;
    /// @notice mStable interest bearing meta asset (imUSD).
    IInterestBearingMasset public imAsset;
    /// @notice mStable vaulted interest bearing meta asset (v-imUSD).
    IVaultedInterestBearingMasset public vimAsset;
    /// @notice mStable save wrapper.
    ISaveWrapper public saveWrapper;

    /// @notice Initial exchange rate between the underlying and the vault's token.
    UFixed256x18 public initialExchangeRate;
    /// @notice Precision multiplier between basket asset and mStable's meta asset.
    uint256 public precisionMultiplier;
    /// @notice Tolerances for strategy operations (e.g. slippage).
    StrategyTolerances public strategyTolerances;

    /// @notice Initializes the Gelt Vault.
    function initialize(
        IERC20MetadataUpgradeable bAsset_,
        IMasset mAsset_,
        IInterestBearingMasset imAsset_,
        IVaultedInterestBearingMasset vimAsset_,
        ISaveWrapper saveWrapper_,
        string memory name,
        string memory symbol
    )
        public
        initializer
    {
        require(address(bAsset_) != address(0), "bAsset addr must not be 0");
        require(address(mAsset_) != address(0), "mAsset addr must not be 0");
        require(address(imAsset_) != address(0), "imAsset addr must not be 0");
        require(address(vimAsset_) != address(0), "vimAsset addr must not be 0");
        require(address(saveWrapper_) != address(0), "saveWrapper addr must not be 0");

        __Context_init();
        __UUPSUpgradeable_init();
        __ReentrancyGuard_init();
        __AccessControl_init();
        __ERC20_init(name, symbol);
        __TemporarilyPausable_init(2 weeks);
        __Migratable_init();
        __Authorizable_init(name, "1");

        _grantRole(OWNER_ROLE, _msgSender());
        _setRoleAdmin(ADMINISTRATOR_ROLE, OWNER_ROLE);
        _setRoleAdmin(OPERATOR_ROLE, OWNER_ROLE);

        bAsset = bAsset_;
        vimAsset = vimAsset_;
        saveWrapper = saveWrapper_;
        imAsset = imAsset_;
        mAsset = mAsset_;

        require(decimals() >= bAsset.decimals(), "invalid decimals on bAsset");

        initialExchangeRate = FixedPointMath.toUFixed256x18(1, 100); // 1:100 initial mint.
        precisionMultiplier = 10**decimals() / 10**bAsset.decimals(); // 10^18 / 10^6 = 10^12
        strategyTolerances = StrategyTolerances({
            slippage: 4 * PercentageMath.SCALE, // 0.04%
            redemptionFee: 10 * PercentageMath.SCALE // 0.10%
        });

        collector = address(0);
    }

    // =========================================================================
    // UUPSUpgradeable
    // =========================================================================

    /// @dev This function should revert when `msg.sender` is not authorized to upgrade the contract.
    function _authorizeUpgrade(address) internal override onlyRole(OWNER_ROLE) {}

    // =========================================================================
    // ERC20Upgradeable
    // =========================================================================

    /// @inheritdoc ERC20Upgradeable
    function decimals() public pure override returns (uint8) {
        return 18;
    }

    // =========================================================================
    // GeltVault
    // =========================================================================

    /// @inheritdoc IGeltVaultV1
    function mintWithAuthorization(
        address minter,
        uint256 mintAmount,
        uint256 validAfter,
        uint256 validBefore,
        bytes32 nonce,
        uint8 v,
        bytes32 r,
        bytes32 s
    )
        external
        override
        onlyRole(OPERATOR_ROLE)
        whenNotTemporarilyPaused
        returns (uint256 mintTokens)
    {
        require(minter != address(0), "minter addr must not be 0");
        require(mintAmount > 0, "mintAmount must be > 0");

        // Verify authorization.
        _requireValidAuthorization(minter, validAfter, validBefore, nonce);

        // Verify signature.
        bytes memory data = abi.encode(
            MINT_WITH_AUTHORIZATION_TYPEHASH,
            minter,
            mintAmount,
            validAfter,
            validBefore,
            nonce
        );
        _requireValidSignature(minter, data, v, r, s);
        _markAuthorizationAsUsed(minter, nonce);

        // User gets mintTokens gUSDC such that the present USDC value of mintTokens
        // reflects the relative share of the vault.
        mintTokens = _calcMintTokens(mintAmount);

        // Transfer the underlying to the vault.
        bAsset.safeTransferFrom(minter, address(this), mintAmount);

        // Update the total supply and the balance of the minter.
        _mint(minter, mintTokens);

        emit MintedWithAuthorization(minter, mintAmount, mintTokens, _msgSender());
    }

    /// @inheritdoc IGeltVaultV1
    function redeemWithAuthorization(
        address redeemer,
        address withdrawTo,
        uint256 redeemTokens,
        uint256 validAfter,
        uint256 validBefore,
        bytes32 nonce,
        uint8 v,
        bytes32 r,
        bytes32 s
    )
        external
        override
        onlyRole(OPERATOR_ROLE)
        whenNotTemporarilyPaused
        returns (uint256 redeemAmount)
    {
        require(redeemer != address(0), "redeemer addr must not be 0");
        require(withdrawTo != address(0), "withdrawTo addr must not be 0");
        require(redeemTokens > 0, "redeemTokens must be > 0");

        // Verify authorization.
        _requireValidAuthorization(redeemer, validAfter, validBefore, nonce);

        // Verify signature.
        bytes memory data = abi.encode(
            REDEEM_WITH_AUTHORIZATION_TYPEHASH,
            redeemer,
            withdrawTo,
            redeemTokens,
            validAfter,
            validBefore,
            nonce
        );
        _requireValidSignature(redeemer, data, v, r, s);
        _markAuthorizationAsUsed(redeemer, nonce);

        redeemAmount = _calcRedeemAmount(redeemTokens);

        // Update the total supply and the balance of the redeemer.
        _burn(redeemer, redeemTokens);

        bAsset.safeTransfer(withdrawTo, redeemAmount);

        emit RedeemedWithAuthorization(redeemer, redeemTokens, redeemAmount, withdrawTo, _msgSender());
    }

    /// @notice Calculates the exchange rate from the underlying to the vault's token.
    /// @return exchangeRate_ The calculated exchange rate scaled by 10^18.
    function exchangeRate() public view returns (UFixed256x18 exchangeRate_) {
        uint256 _totalSupply = totalSupply();

        if (_totalSupply == 0) {
            exchangeRate_ = initialExchangeRate;
        } else {
            // Total assets = free funds held by the vault + funds lent out to the strategy
            uint256 totalAssets = _underlyingBalance() + _getStrategyValue();
            uint256 totalAssetsScaled = totalAssets * precisionMultiplier;

            // Exchange rate = total assets / total vault token supply
            exchangeRate_ = FixedPointMath.toUFixed256x18(totalAssetsScaled, _totalSupply);
        }
    }

    /// @inheritdoc IGeltVaultV1
    function voluntaryExit(address withdrawTo, uint256 minOutputQuantity)
        external
        override
        whenNotTemporarilyPaused
        nonReentrant
    {
        require(withdrawTo != address(0), "withdrawTo addr must not be 0");

        uint256 redeemTokens = balanceOf(_msgSender());

        uint256 redeemAmount = _calcRedeemAmount(redeemTokens);

        // In case of a voluntary exit, the user pays for the redemption fees.
        redeemAmount -= redeemAmount.percentage(_getStrategyRedemptionFee());

        require(redeemAmount >= minOutputQuantity, "requested minimum output quantity is not satisfied");

        // Check if the vault has enough free funds to satisfy the exit request.
        uint256 underlyingBalance = _underlyingBalance();
        if (underlyingBalance < redeemAmount) {
            // Not enough free funds, execute strategy.
            uint256 diff = redeemAmount - underlyingBalance;
            _executeStrategyRedeem(diff, false);
        }

        // Assert that the vault has enough free funds.
        assert(_underlyingBalance() >= redeemAmount);

        // Update the total supply and the balance of the redeemer.
        _burn(_msgSender(), redeemTokens);

        bAsset.safeTransfer(withdrawTo, redeemAmount);

        emit VoluntarilyExited(_msgSender(), redeemTokens, redeemAmount, withdrawTo);
    }

    /// @inheritdoc IGeltVaultV1
    function executeStrategyNetDeposit(uint256 amount)
        external
        override
        whenNotTemporarilyPaused
        onlyRole(OPERATOR_ROLE)
    {
        _executeStrategyMint(amount);

        emit DepositedToStrategy(amount, _msgSender());
    }

    /// @inheritdoc IGeltVaultV1
    function executeStrategyNetWithdraw(uint256 amount)
        external
        override
        whenNotTemporarilyPaused
        onlyRole(OPERATOR_ROLE)
    {
        _executeStrategyRedeem(amount, true);

        emit WithdrewFromStrategy(amount, _msgSender());
    }


    /// @inheritdoc IGeltVaultV1
    function claimGovernanceTokens() external override whenNotTemporarilyPaused onlyRole(OPERATOR_ROLE) {
        vimAsset.claimReward();
    }

    /// @inheritdoc IGeltVaultV1
    function collectGovernanceTokens() external override whenNotTemporarilyPaused onlyRole(OPERATOR_ROLE) {
        require(collector != address(0), "collector addr must not be 0");

        IERC20Upgradeable rewardToken = vimAsset.getRewardToken(); // MTA
        IERC20Upgradeable platformToken = vimAsset.getPlatformToken(); // WMATIC
        uint256 rewardTokenBalance = rewardToken.balanceOf(address(this));
        uint256 platformTokenBalance = platformToken.balanceOf(address(this));

        if (rewardTokenBalance > 0) {
            rewardToken.safeTransfer(collector, rewardTokenBalance);
        }

        if (platformTokenBalance > 0) {
            platformToken.safeTransfer(collector, platformTokenBalance);
        }

        emit GovernanceTokensCollected(
            rewardToken,
            platformToken,
            rewardTokenBalance,
            platformTokenBalance,
            _msgSender()
        );
    }

    /// @inheritdoc IGeltVaultV1
    function setCollector(address collector_)
        external
        override
        whenNotTemporarilyPaused
        onlyRole(ADMINISTRATOR_ROLE)
    {
        require(collector_ != address(0), "collector addr must not be 0");

        emit CollectorChanged(collector, collector_, _msgSender());

        collector = collector_;
    }

    /// @inheritdoc IGeltVaultV1
    function setStrategyTolerances(StrategyTolerances calldata strategyTolerances_)
        external
        override
        whenNotTemporarilyPaused
        onlyRole(ADMINISTRATOR_ROLE)
    {
        require(strategyTolerances_.slippage <= PercentageMath.MAX_BPS, "slippage out of bounds");
        require(strategyTolerances_.redemptionFee <= PercentageMath.MAX_BPS, "redemptionFee out of bounds");

        emit StrategyTolerancesChanged(strategyTolerances, strategyTolerances_, _msgSender());

        strategyTolerances = strategyTolerances_;
    }

    /// @inheritdoc IGeltVaultV1
    function emergencyExitStrategy(uint256 minOutputQuantity) external override onlyRole(ADMINISTRATOR_ROLE) {
        require(minOutputQuantity != 0, "minOutputQuantity must not be 0");

        if (vimAsset.balanceOf(address(this)) > 0) {
            // Unstake and collect rewards.
            vimAsset.exit();
        }

        uint256 creditBalance = imAsset.balanceOf(address(this));
        if (creditBalance > 0) {
            // Redeem credits to mAssets.
            imAsset.redeemCredits(creditBalance);
        }

        uint256 mAssetBalance = mAsset.balanceOf(address(this));
        uint256 outputAmount = 0;
        if (mAssetBalance > 0) {
            // Redeem mAssets to bAssets.
            outputAmount = mAsset.redeem(
                address(bAsset), // address _output
                mAssetBalance, // uint256 _mAssetQuantity
                minOutputQuantity, // uint256 _minOutputQuantity
                address(this) // address _recipient
            );
        }

        emit EmergencyExited(creditBalance, outputAmount, _msgSender());
    }

    /// @inheritdoc IGeltVaultV1
    function emergencyPause() external override whenNotTemporarilyPaused onlyRole(ADMINISTRATOR_ROLE) {
        _temporarilyPause();
    }

    /// @inheritdoc IGeltVaultV1
    function emergencyUnpause() external override whenTemporarilyPaused onlyRole(ADMINISTRATOR_ROLE) {
        _unpause();
    }

    /// @inheritdoc IGeltVaultV1
    function sweep(IERC20Upgradeable token, uint256 amount)
        external
        override
        whenNotTemporarilyPaused
        onlyRole(ADMINISTRATOR_ROLE)
    {
        require(amount > 0, "amount must not be 0");
        require(
            token != bAsset &&
                token != mAsset &&
                token != imAsset &&
                token != vimAsset &&
                token != vimAsset.getRewardToken() &&
                token != vimAsset.getPlatformToken(),
           "token must not be protected"
        );

        uint256 balance = token.balanceOf(address(this));
        require(balance >= amount, "amount must not exceed balance");

        token.safeTransfer(_msgSender(), amount);

        emit TokenSwept(token, amount, _msgSender());
    }

    /// @inheritdoc IGeltVaultV1
    function transferOwnership(address newOwner) external onlyRole(OWNER_ROLE) {
        require(newOwner != address(0), "owner addr must not be 0");

        // Revoke role from previous owner and grant role to new owner.
        _revokeRole(OWNER_ROLE, _msgSender());
        _grantRole(OWNER_ROLE, newOwner);

        emit OwnershipTransferred(_msgSender(), newOwner);
    }

    /// @dev Deposits to the strategy.
    /// @param amount Amount of underlying to supply to the strategy.
    /// @return inputAmount Amount of underlying that was supplied.
    function _executeStrategyMint(uint256 amount) internal returns (uint256 inputAmount) {
        require(amount > 0, "amount must not be 0");

        // Check if the mint output quantity is within the allowed bounds.
        uint256 maxSlippage = amount.percentage(strategyTolerances.slippage);
        uint256 minOutputQuantity = (amount - maxSlippage) * precisionMultiplier;

        uint256 mintOutput = mAsset.getMintOutput(address(bAsset), amount);
        require(mintOutput >= minOutputQuantity, "slippage outside of tolerance");

        bAsset.safeIncreaseAllowance(address(saveWrapper), amount);

        // USDC (amount) -> mUSD (amount - ∆mint)
        // mUSD (amount - ∆mint) -> imUSD (X)
        // imUSD (X) -> v-imUSD (X)
        saveWrapper.saveViaMint(
            address(mAsset), // address _mAsset
            address(imAsset), // address _save
            address(vimAsset), // address _vault
            address(bAsset), // address _bAsset
            amount, // uint256 _amount
            minOutputQuantity, // uint256 _minOut
            true // bool _stake
        );

        inputAmount = amount;
    }

    /// @dev Redeems from the strategy.
    /// @param amount Amount of underlying to redeem from the strategy.
    /// @param checkRedemptionFee True to enable redemption fee tolerance checks, false otherwise.
    /// @return outputAmount Amount of underlying that was redeemed.
    function _executeStrategyRedeem(uint256 amount, bool checkRedemptionFee) internal returns (uint256 outputAmount) {
        require(amount > 0, "amount must not be 0");

        uint64 redemptionFee = _getStrategyRedemptionFee();

        if (checkRedemptionFee) {
            // Check if the mStable redemption fee is within the tolerance bounds.
            require(
                redemptionFee <= strategyTolerances.redemptionFee,
                "redemptionFee out of tolerance"
            );
        }

        // Calculate how much mAssets would need to be redeemed to satisfy the strategy execution request.
        uint256 withdrawAmount = _calcStrategyRedeemAmount(amount);

        // Scale bAsset amount to mAsset precision.
        uint256 maxRedeemOutput = amount * precisionMultiplier;
        // Calculate maximum tolerated redeem amount (includes slippage and redeem fee).
        maxRedeemOutput += maxRedeemOutput.percentage(redemptionFee); // Redemption fee tolerance already checked.
        maxRedeemOutput += maxRedeemOutput.percentage(strategyTolerances.slippage);
        require(maxRedeemOutput >= withdrawAmount, "redeem delta out of tolerance");

        // Get value in imAssets.
        uint256 credits = imAsset.underlyingToCredits(withdrawAmount);

        // Check that we have enough v-imAsset.
        require(vimAsset.balanceOf(address(this)) >= credits, "insufficient credits to redeem");

        // Unstake v-imAsset.
        vimAsset.withdraw(credits);

        // Redeem imAsset to underlying mAsset.
        imAsset.redeemCredits(credits);

        // Redeem mAsset to backing asset (bAsset).
        outputAmount = mAsset.redeem(
            address(bAsset), // address _output
            withdrawAmount, // uint256 _mAssetQuantity
            amount, // uint256 _minOutputQuantity
            address(this) // address _recipient
        );

        assert(outputAmount >= amount);
    }

    /// @dev Returns the vault's free-floating balance of the underlying basket asset.
    /// @return Balance of the vault.
    function _underlyingBalance() internal view returns (uint256) {
        return bAsset.balanceOf(address(this));
    }

    /// @dev Calculates the amount of tokens to issue in exchange for some underlying.
    /// @param mintAmount Underlying amount to supply.
    /// @return mintTokens Amount of tokens to mint.
    function _calcMintTokens(uint256 mintAmount) internal view returns (uint256 mintTokens) {
        uint256 scaledMintAmount = mintAmount * precisionMultiplier;

        mintTokens = FixedPointMath.toUFixed256x18(scaledMintAmount).div(exchangeRate()).floor();
    }

    /// @dev Calculates the amount of underlying to redeem in exchange for the vault's tokens.
    /// @param redeemTokens Token amount to supply.
    /// @return redeemAmount Amount of underlying to redeem, in exchange for the given tokens.
    function _calcRedeemAmount(uint256 redeemTokens) internal view returns (uint256 redeemAmount) {
        uint256 redeemAmountScaled = exchangeRate().mul(redeemTokens).floor();

        redeemAmount = redeemAmountScaled / precisionMultiplier;
    }

    /// @dev Returns the total value stored in the strategy in the underlying basket asset.
    /// @return strategyValue Value of the strategy.
    function _getStrategyValue() internal view virtual returns (uint256 strategyValue) {
        // Get the balance of both staked and unstaked credits.
        uint256 credits = vimAsset.balanceOf(address(this)) + imAsset.balanceOf(address(this));

        uint256 mAssetBalance = mAsset.balanceOf(address(this));

        if (credits > 0) {
            // Get the value of the credits in mAssets.
            mAssetBalance += imAsset.creditsToUnderlying(credits);
        }

        if (mAssetBalance > 0) {
            // Get bAsset (e.g. USDC) value of mAsset (mUSD) when redeemed.
            strategyValue = mAsset.getRedeemOutput(address(bAsset), mAssetBalance);
        } else {
            strategyValue = 0;
        }
    }

    /// @dev Returns the current redemption fee of the underlying strategy.
    /// @return redemptionFee Redemption fee in scaled basis points (bps * 1e14).
    function _getStrategyRedemptionFee() internal view returns (uint64 redemptionFee) {
        redemptionFee = mAsset.data().redemptionFee.toUint64();
    }

    /// @dev Calculates the amount of meta asset to redeem to receive the given amount of underlying basket asset.
    /// @param bAssetQuantity Target amount of underlying.
    /// @return mAssetAmount Amount of meta asset to redeem.
    function _calcStrategyRedeemAmount(uint256 bAssetQuantity) internal view returns (uint256 mAssetAmount) {
        uint256[] memory bAssetQuantities = new uint256[](1);
        address[] memory bAssets = new address[](1);
        bAssetQuantities[0] = bAssetQuantity;
        bAssets[0] = address(bAsset);

        mAssetAmount = mAsset.getRedeemExactBassetsOutput(bAssets, bAssetQuantities) + 1; // Compensate for rounding errors.
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeCast.sol)

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
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
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
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
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
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
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
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
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
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
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
     * - input must fit into 8 bits.
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
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
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
     * - input must fit into 8 bits.
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
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../utils/StringsUpgradeable.sol";
import "../utils/introspection/ERC165Upgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    function __AccessControl_init() internal onlyInitializing {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __AccessControl_init_unchained();
    }

    function __AccessControl_init_unchained() internal onlyInitializing {
    }
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        StringsUpgradeable.toHexString(uint160(account), 20),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
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
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;

import "../ERC1967/ERC1967UpgradeUpgradeable.sol";
import "./Initializable.sol";

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is Initializable, ERC1967UpgradeUpgradeable {
    function __UUPSUpgradeable_init() internal onlyInitializing {
        __ERC1967Upgrade_init_unchained();
        __UUPSUpgradeable_init_unchained();
    }

    function __UUPSUpgradeable_init_unchained() internal onlyInitializing {
    }
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallSecure(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallSecure(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
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
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20Upgradeable.sol";
import "./extensions/IERC20MetadataUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
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
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable, IERC20MetadataUpgradeable {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

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
        __Context_init_unchained();
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
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
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
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
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
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
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
        _balances[account] += amount;
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
        }
        _totalSupply -= amount;

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
    uint256[45] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
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
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
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

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

/// @notice Strategy tolerance configuration.
struct StrategyTolerances {
    /// @notice Slippage tolerance in scaled basis points.
    uint64 slippage;
    /// @notice Strategy redemption fee tolerance in scaled basis points.
    uint64 redemptionFee;
}

/// @title The interface to the V1 Gelt Vault.
interface IGeltVaultV1 {
    // =========================================================================
    // Events
    // =========================================================================

    /// @notice Emitted after a mint with signed authorization.
    /// @param minter Minter's address (authorizer).
    /// @param mintAmount Amount of underlying supplied.
    /// @param mintTokens Amount of vault tokens minted.
    /// @param sender Sender of the transaction (Gelt operator).
    event MintedWithAuthorization(
        address indexed minter,
        uint256 mintAmount,
        uint256 mintTokens,
        address sender
    );

    /// @notice Emitted after a redeem with signed authorization.
    /// @param redeemer Redeemer's address (authorizer).
    /// @param redeemTokens Amount of vault tokens redeemed.
    /// @param redeemAmount Amount of underlying received for the tokens.
    /// @param withdrawTo Address the underlying was withdrawn to.
    /// @param sender Sender of the transaction (Gelt operator).
    event RedeemedWithAuthorization(
        address indexed redeemer,
        uint256 redeemTokens,
        uint256 redeemAmount,
        address withdrawTo,
        address sender
    );

    /// @notice Emitted after a voluntary exit from the vault.
    /// @param sender Sender of the transaction (Gelt user).
    /// @param redeemTokens Amount of vault tokens redeemed.
    /// @param redeemAmount Amount of underlying received for the tokens.
    /// @param withdrawTo Address the underlying was withdrawn to.
    event VoluntarilyExited(
        address indexed sender,
        uint256 redeemTokens,
        uint256 redeemAmount,
        address withdrawTo
    );

    /// @notice Emitted after depositing to the strategy.
    /// @param amount Amount of underlying deposited.
    /// @param sender Sender of the transaction (Gelt operator).
    event DepositedToStrategy(uint256 amount, address sender);

    /// @notice Emitted after withdrawing from the strategy.
    /// @param amount Amount of underlying withdrawn.
    /// @param sender Sender of the transaction (Gelt operator).
    event WithdrewFromStrategy(uint256 amount, address sender);

    /// @notice Emitted after the governance tokens were collected from the vault.
    /// @param rewardToken Address of the reward token.
    /// @param platformToken Address of the platform token.
    /// @param rewardTokenBalance Amount of reward tokens collected.
    /// @param platformTokenBalance Amount of platform tokens collected.
    /// @param sender Sender of the transaction (Gelt operator).
    event GovernanceTokensCollected(
        IERC20Upgradeable indexed rewardToken,
        IERC20Upgradeable indexed platformToken,
        uint256 rewardTokenBalance,
        uint256 platformTokenBalance,
        address sender
    );

    /// @notice Emitted after a change to the collector address.
    /// @param oldCollector Previous address.
    /// @param newCollector New address.
    /// @param sender Sender of the transaction (Gelt administrator).
    event CollectorChanged(address oldCollector, address newCollector, address sender);

    /// @notice Emitted after a change to the strategy tolerances.
    /// @param oldTolerances Previous strategy tolerances.
    /// @param newTolerances New strategy tolerances.
    /// @param sender Sender of the transaction (Gelt administrator).
    event StrategyTolerancesChanged(StrategyTolerances oldTolerances, StrategyTolerances newTolerances, address sender);

    /// @notice Emitted after an emergency exit from the strategy.
    /// @param redeemCredits Amount of credits redeemed.
    /// @param redeemAmount Amount of underlying redeemed.
    /// @param sender Sender of the transaction (Gelt administrator).
    event EmergencyExited(uint256 redeemCredits, uint256 redeemAmount, address sender);

    /// @notice Emitted after a token was swept from the vault.
    /// @param token Address of the ERC20 token.
    /// @param amount Amount of tokens swept.
    /// @param sender Sender of the transaction (Gelt administrator).
    event TokenSwept(IERC20Upgradeable indexed token, uint256 amount, address sender);

    /// @notice Emitted after the contract's ownership is transferred.
    /// @param previousOwner Address of the previous owner.
    /// @param newOwner Address of the new owner.
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    // =========================================================================
    // Functions
    // =========================================================================

    /// @notice Executes a mint with a signed authorization.
    /// @param minter Minter's address (authorizer).
    /// @param mintAmount Amount of underlying to supply.
    /// @param validAfter The time after which the meta-transaction is valid (UNIX timestamp).
    /// @param validBefore The time before which the meta-transaction is valid (UNIX timestamp).
    /// @param nonce Unique nonce.
    /// @param v Meta-transaction signature's `v` component.
    /// @param r Meta-transaction signature's `r` component.
    /// @param s Meta-transaction signature's `s` component.
    /// @return mintTokens Amount of tokens minted.
    /// @custom:gelt-access-control Operator
    function mintWithAuthorization(
        address minter,
        uint256 mintAmount,
        uint256 validAfter,
        uint256 validBefore,
        bytes32 nonce,
        uint8 v,
        bytes32 r,
        bytes32 s
    )
        external
        returns (uint256 mintTokens);

    /// @notice Executes a redeem with a signed authorization.
    /// @param redeemer Redeemer's address (authorizer).
    /// @param withdrawTo Address to withdraw the underlying to.
    /// @param redeemTokens Amount of tokens to redeem.
    /// @param validAfter The time after which the meta-transaction is valid (UNIX timestamp).
    /// @param validBefore The time before which the meta-transaction is valid (UNIX timestamp).
    /// @param nonce Unique nonce.
    /// @param v Meta-transaction signature's `v` component.
    /// @param r Meta-transaction signature's `r` component.
    /// @param s Meta-transaction signature's `s` component.
    /// @return redeemAmount Amount of underlying redeemed.
    /// @custom:gelt-access-control Operator
    function redeemWithAuthorization(
        address redeemer,
        address withdrawTo,
        uint256 redeemTokens,
        uint256 validAfter,
        uint256 validBefore,
        bytes32 nonce,
        uint8 v,
        bytes32 r,
        bytes32 s
    )
        external
        returns (uint256 redeemAmount);

    /// @notice Allows an end-user to voluntarily exit the vault.
    /// @param withdrawTo Address to withdraw the underlying to.
    /// @param minOutputQuantity Minimum amount of underlying to be withdrawn.
    ///                          This protects against slippage.
    function voluntaryExit(address withdrawTo, uint256 minOutputQuantity) external;

    /// @notice Deposits to the strategy.
    /// @param amount Amount of underlying to supply to the strategy.
    /// @custom:gelt-access-control Operator
    function executeStrategyNetDeposit(uint256 amount) external;

    /// @notice Redeems from the strategy.
    /// @param amount Amount of underlying to redeem from the strategy.
    /// @custom:gelt-access-control Operator
    function executeStrategyNetWithdraw(uint256 amount) external;

    /// @notice Claims governance tokens from the strategy.
    /// @custom:gelt-access-control Operator
    function claimGovernanceTokens() external;

    /// @notice Collects claimed governance tokens to the collector address.
    /// @custom:gelt-access-control Operator
    function collectGovernanceTokens() external;

    /// @notice Sets the governance token collector address.
    /// @param collector_ New collector address.
    /// @custom:gelt-access-control Administrator
    function setCollector(address collector_) external;

    /// @notice Sets the strategy tolerances, e.g. slippage or redemption fee tolerances.
    /// @param strategyTolerances_ New strategy tolerances.
    /// @custom:gelt-access-control Administrator
    function setStrategyTolerances(StrategyTolerances calldata strategyTolerances_) external;

    /// @notice Exits all funds and collects rewards from the strategy.
    /// @dev This should only be used in emergency scenarios.
    /// @param minOutputQuantity Minimum amount of underlying to be withdrawn.
    /// @custom:gelt-access-control Administrator
    function emergencyExitStrategy(uint256 minOutputQuantity) external;

    /// @notice Pauses the vault preventing mints, redeems, strategy execution and voluntary exits.
    /// @dev This should only be used in emergency scenarios.
    /// @custom:gelt-access-control Administrator
    function emergencyPause() external;

    /// @notice Unpauses the vault enabling mints, redeems, strategy execution and voluntary exits.
    /// @dev This should only be used in emergency scenarios.
    /// @custom:gelt-access-control Administrator
    function emergencyUnpause() external;

    /// @notice Withdraws a token that isn't protected by the vault.
    ///         This allows for recovering tokens that were sent to the vault by accident.
    /// @param token Address of the ERC20 token to withdraw.
    /// @param amount Amount to withdraw.
    /// @custom:gelt-access-control Administrator
    function sweep(IERC20Upgradeable token, uint256 amount) external;

    /// @notice Transfers the ownership of the contract.
    /// @param newOwner Address of the new contract owner.
    /// @custom:gelt-access-control Owner
    function transferOwnership(address newOwner) external;
}

/// @title The interface to the Gelt Vault.
interface IGeltVault is IGeltVaultV1 {}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.9;

/// @dev Interface based on https://github.com/mstable/mStable-contracts/blob/69fc5b2d3e4461b4a7b1071e976c316e8b9f370f/contracts/savings/peripheral/SaveWrapper.sol
interface ISaveWrapper {
    /// @dev Mints mAssets and then deposits to Save/Savings Vault.
    function saveViaMint(
        address _mAsset,
        address _save,
        address _vault,
        address _bAsset,
        uint256 _amount,
        uint256 _minOut,
        bool _stake
    ) external;
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

struct MassetData {
    uint256 redemptionFee;
}

/// @title An incentivised constant sum market maker with hard limits at max region.
/// @notice The AMM produces stablecoin (mAsset) and redirects lending market interest
///         and swap fees to the savings contract, producing a second yield bearing asset.
/// @dev Interface based on https://github.com/mstable/mStable-contracts/blob/69fc5b2d3e4461b4a7b1071e976c316e8b9f370f/contracts/interfaces/IMasset.sol
interface IMasset is IERC20Upgradeable {
    /// @dev Configuration.
    function data() external view returns (MassetData calldata);

    /// @dev Gets the projected output of a given mint.
    function getMintOutput(
        address _input,
        uint256 _inputQuantity
    ) external view returns (uint256 mintOutput);

    /// @dev Redeems a specified quantity of mAsset in return for a bAsset specified by bAsset address.
    function redeem(
        address _output,
        uint256 _mAssetQuantity,
        uint256 _minOutputQuantity,
        address _recipient
    ) external returns (uint256 outputQuantity);

    /// @dev Gets the estimated bAsset output from a given redeem.
    function getRedeemOutput(
        address _output,
        uint256 _mAssetQuantity
    ) external view returns (uint256 bAssetOutput);

    /// @dev Gets the estimated mAsset output from a given redeem.
    function getRedeemExactBassetsOutput(
        address[] calldata _outputs,
        uint256[] calldata _outputQuantities
    ) external view returns (uint256 mAssetQuantity);
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

/// @notice Uses the ever increasing "exchangeRate" to increase the value of the "credits" (ERC20)
///         relative to the amount of additional underlying collateral that has been deposited into
///         this contract ("interest").
/// @dev Interface based on https://github.com/mstable/mStable-contracts/blob/69fc5b2d3e4461b4a7b1071e976c316e8b9f370f/contracts/interfaces/ISavingsContract.sol
interface IInterestBearingMasset is IERC20Upgradeable {
    /// @dev Rate between 'savings credits' and underlying.
    function exchangeRate() external view returns (uint256);

    /// @dev The underlying balance of a given user.
    function balanceOfUnderlying(address _user) external view returns (uint256 _underlying);

    /// @dev Converts a given underlying amount into credits.
    function underlyingToCredits(uint256 _underlying) external view returns (uint256 credits);

    /// @dev Converts a given credit amount into underlying.
    function creditsToUnderlying(uint256 _credits) external view returns (uint256 amount);

    /// @dev Redeem specific number of the senders "credits" in exchange for underlying.
    function redeemCredits(uint256 _credits) external returns (uint256 massetReturned);

    /// @dev Redeem credits into a specific amount of underlying.
    function redeemUnderlying(uint256 _underlying) external returns (uint256 creditsBurned);

    /// @dev Deposit interest (add to savings) and update exchange rate of contract.
    function depositInterest(uint256 _amount) external;
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

/// @notice Rewards stakers of a given LP token (a.k.a StakingToken) with RewardsToken, on a pro-rata basis
///         additionally, distributes the Platform token airdropped by the platform.
/// @dev Interface based on https://github.com/mstable/mStable-contracts/blob/69fc5b2d3e4461b4a7b1071e976c316e8b9f370f/contracts/rewards/staking/StakingRewardsWithPlatformToken.sol
interface IVaultedInterestBearingMasset is IERC20Upgradeable {
    /// @dev Withdraws given stake amount from the pool.
    /// @param _amount Units of the staked token to withdraw.
    function withdraw(uint256 _amount) external;

    /// @dev Withdraws stake from pool and claims any rewards.
    function exit() external;

    /// @dev Claims outstanding rewards (both platform and native) for the sender.
    function claimReward() external;

    /// @dev Gets the RewardsToken.
    function getRewardToken() external view returns (IERC20Upgradeable);

    /// @dev Gets the PlatformToken.
    function getPlatformToken() external view returns (IERC20Upgradeable);
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.9;

/// @dev Represents a 18 decimal, 256 bit wide fixed point number.
type UFixed256x18 is uint256;

/// @title A minimal library to do fixed point operations on UFixed256x18.
library FixedPointMath {
    uint256 internal constant MULTIPLIER = 1e18;

    /// Adds two UFixed256x18 numbers.
    /// @dev Reverts on overflow, relying on checked arithmetic on uint256.
    function add(UFixed256x18 a, UFixed256x18 b) internal pure returns (UFixed256x18) {
        return UFixed256x18.wrap(UFixed256x18.unwrap(a) + UFixed256x18.unwrap(b));
    }

    /// Subtracts two UFixed256x18 numbers.
    /// @dev Reverts on underflow, relying on checked arithmetic on uint256.
    function sub(UFixed256x18 a, UFixed256x18 b) internal pure returns (UFixed256x18) {
        return UFixed256x18.wrap(UFixed256x18.unwrap(a) - UFixed256x18.unwrap(b));
    }

    /// Multiplies UFixed256x18 and uint256.
    /// @dev Reverts on overflow, relying on checked arithmetic on uint256.
    function mul(UFixed256x18 a, uint256 b) internal pure returns (UFixed256x18) {
        return UFixed256x18.wrap(UFixed256x18.unwrap(a) * b);
    }

    /// Multiplies two UFixed256x18 numbers.
    /// @dev Reverts on overflow, relying on checked arithmetic on uint256.
    function mul(UFixed256x18 a, UFixed256x18 b) internal pure returns (UFixed256x18) {
        return UFixed256x18.wrap((UFixed256x18.unwrap(a) * UFixed256x18.unwrap(b)) / MULTIPLIER);
    }

    /// Divides UFixed256x18 and uint256.
    function div(UFixed256x18 a, uint256 b) internal pure returns (UFixed256x18) {
        return UFixed256x18.wrap(UFixed256x18.unwrap(a) / b);
    }

    /// Divides two UFixed256x18 numbers.
    /// @dev Reverts on overflow, relying on checked arithmetic on uint256.
    function div(UFixed256x18 a, UFixed256x18 b) internal pure returns (UFixed256x18) {
        return UFixed256x18.wrap((UFixed256x18.unwrap(a) * MULTIPLIER) / UFixed256x18.unwrap(b));
    }

    /// Takes the floor of a UFixed256x18 number.
    function floor(UFixed256x18 a) internal pure returns (uint256) {
        return UFixed256x18.unwrap(a) / MULTIPLIER;
    }

    /// Turns a uint256 into a UFixed256x18 of the same value.
    /// @dev Reverts if the integer is too large.
    function toUFixed256x18(uint256 a) internal pure returns (UFixed256x18) {
        return UFixed256x18.wrap(a * MULTIPLIER);
    }

    /// Turns a numerator and a denominator into a fixed precision number.
    /// @dev Reverts if either numbers are too large.
    function toUFixed256x18(uint256 numerator, uint256 denominator) internal pure returns (UFixed256x18) {
        return UFixed256x18.wrap((numerator * MULTIPLIER) / denominator);
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.9;

/// @title A library providing utilities to work with percentages.
library PercentageMath {
    uint64 internal constant SCALE = 1e14;

    /// @dev 10k bps = 100%
    uint64 internal constant MAX_BPS = 10_000 * SCALE;

    /// @dev Calculates the percentage (given in scaled basis points) of the given number.
    /// @param amount The amount to calculate the percentage of.
    /// @param scaledBps Percentage in scaled basis points.
    /// @return Percentage of amount.
    function percentage(uint256 amount, uint64 scaledBps) internal pure returns (uint256) {
        require(amount > 0, "amount must not be 0");
        require(scaledBps > 0, "bps must not be 0");
        require(scaledBps <= MAX_BPS, "bps out of bounds");

        return (amount * scaledBps) / MAX_BPS;
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";

/// @title Abstract contract to allow for temporarily pausing a contract preventing
///        execution of the designated functions.
abstract contract TemporarilyPausable is Initializable, ContextUpgradeable {
    /// @dev Emitted when the pause is triggered by `account`.
    event TemporarilyPaused(address account);

    /// @dev Emitted when the pause is lifted by `account`.
    event Unpaused(address account);

    uint256 private _pauseDuration;
    uint256 private _pausedAt;
    bool private _paused;

    /// @dev Initializes the contract in unpaused state.
    function __TemporarilyPausable_init(uint256 pauseDuration_) internal onlyInitializing {
        __Context_init_unchained();
        __TemporarilyPausable_init_unchained(pauseDuration_);
    }

    function __TemporarilyPausable_init_unchained(uint256 pauseDuration_) internal onlyInitializing {
        _setPauseDuration(pauseDuration_);
        _paused = false;
    }

    /// @dev Returns the pause duration after which the a paused contract will automatically unpause.
    function pauseDuration() public view virtual returns (uint256) {
        return _pauseDuration;
    }

    /// @dev Returns true if the contract is temporarily paused, and false otherwise.
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /// @dev Modifier to make a function callable only when the contract is temporarily paused.
    modifier whenTemporarilyPaused() {
        _checkPaused();
        _;
    }

    /// @dev Modifier to make a function callable only when the contract is not temporarily paused.
    ///      Automatically unpauses the contract if the pause duration expired.
    modifier whenNotTemporarilyPaused() {
        _checkNotPaused();
        _;
    }

    /// @dev Temporarily pauses the contract.
    function _temporarilyPause() internal {
        _pausedAt = block.timestamp;
        _paused = true;
        emit TemporarilyPaused(_msgSender());
    }

    /// @dev Unpauses the contract.
    function _unpause() internal {
        _paused = false;
        emit Unpaused(_msgSender());
    }

    /// @dev Sets the pause duration. Reverts if the given duration is less than a week.
    /// @param pauseDuration_ Duration in seconds.
    function _setPauseDuration(uint256 pauseDuration_) internal {
        // Make sure pause duration is long enough so that miners can't manipulate the behaviour.
        require(pauseDuration_ >= 1 days, "pauseDuration must be >= 1 day");

        _pauseDuration = pauseDuration_;
    }

    function _checkPaused() private view {
        require(paused(), "TemporarilyPausable: not temporarily paused");
    }

    function _checkNotPaused() private {
        // Unpause if the pause duration expired.
        if (paused() && block.timestamp > (_pausedAt + _pauseDuration)) {
            _unpause();
        }

        require(!paused(), "TemporarilyPausable: temporarily paused");
    }

    uint256[47] private __gap;
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/// @title Abstract contract to allow for designating migrator functions that can be used to
///        define migration logic triggered during contract upgrades.
abstract contract Migratable is Initializable {
    mapping(uint256 => bool) private _migrations;

    function __Migratable_init() internal onlyInitializing {
        __Migratable_init_unchained();
    }

    function __Migratable_init_unchained() internal onlyInitializing {
    }

    modifier migrator(uint256 version) {
        _migrateVersion(version);
        _;
    }

    function _migrateVersion(uint256 version) private {
        require(!_migrations[version], "Migratable: contract already migrated");
        _migrations[version] = true;
    }

    uint256[50] private __gap;
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./lib/EIP712Domain.sol";
import "./lib/EIP712.sol";

/// @title Abstract contract to allow for executing operations using signed authorizations.
/// @dev Implements meta-transactions as specified in https://eips.ethereum.org/EIPS/eip-3009.
abstract contract Authorizable is Initializable, EIP712Domain {
    bytes32 public constant CANCEL_AUTHORIZATION_TYPEHASH = keccak256("CancelAuthorization(address authorizer,bytes32 nonce)");

    /// @dev Authorizer address => nonce => bool (true if nonce is used)
    mapping(address => mapping(bytes32 => bool)) private _authorizationStates;

    event AuthorizationUsed(address indexed authorizer, bytes32 indexed nonce);
    event AuthorizationCanceled(
        address indexed authorizer,
        bytes32 indexed nonce
    );

    function __Authorizable_init(string memory name, string memory version) internal onlyInitializing {
        __Authorizable_init_unchained(name, version);
    }

    function __Authorizable_init_unchained(string memory name, string memory version) internal onlyInitializing {
        DOMAIN_SEPARATOR = EIP712.makeDomainSeparator(name, version);
    }

    /// @notice Returns the state of an authorization.
    /// @param authorizer Authorizer's address.
    /// @param nonce Unique nonce of the authorization.
    /// @return True if the nonce is used, false otherwise.
    function authorizationState(address authorizer, bytes32 nonce)
        external
        view
        returns (bool)
    {
        return _authorizationStates[authorizer][nonce];
    }

    /// @notice Attempts to cancel an authorization.
    /// @param authorizer Authorizer's address.
    /// @param nonce Unique nonce of the authorization.
    /// @param v Meta-transaction signature's `v` component.
    /// @param r Meta-transaction signature's `r` component.
    /// @param s Meta-transaction signature's `s` component.
    function cancelAuthorization(
        address authorizer,
        bytes32 nonce,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        _requireUnusedAuthorization(authorizer, nonce);

        bytes memory data = abi.encode(
            CANCEL_AUTHORIZATION_TYPEHASH,
            authorizer,
            nonce
        );
        require(
            EIP712.recover(DOMAIN_SEPARATOR, v, r, s, data) == authorizer,
            "Authorizable: invalid signature"
        );

        _authorizationStates[authorizer][nonce] = true;
        emit AuthorizationCanceled(authorizer, nonce);
    }

    /// @dev Checks that the authorization is valid.
    function _requireValidAuthorization(
        address authorizer,
        uint256 validAfter,
        uint256 validBefore,
        bytes32 nonce
    )
        internal
        view
    {
        // Require timestamps to be valid.
        require(
            block.timestamp > validAfter,
            "Authorizable: authorization is not yet valid"
        );
        require(
            block.timestamp < validBefore,
            "Authorizable: authorization is expired"
        );

        _requireUnusedAuthorization(authorizer, nonce);
    }

    /// @dev Checks that the signature is valid.
    function _requireValidSignature(
        address authorizer,
        bytes memory data,
        uint8 v,
        bytes32 r,
        bytes32 s
    )
        internal
        view
    {
        require(
            EIP712.recover(DOMAIN_SEPARATOR, v, r, s, data) == authorizer,
            "Authorizable: invalid signature"
        );
    }

    /// @dev Marks an authorization as used.
    function _markAuthorizationAsUsed(address authorizer, bytes32 nonce)
        internal
    {
        _authorizationStates[authorizer][nonce] = true;
        emit AuthorizationUsed(authorizer, nonce);
    }

    /// @dev Checks if an authorization has already been unused.
    function _requireUnusedAuthorization(address authorizer, bytes32 nonce)
        private
        view
    {
        require(
            !_authorizationStates[authorizer][nonce],
            "Authorizable: authorization is used or canceled"
        );
    }

    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

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
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
        __ERC165_init_unchained();
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }
    uint256[50] private __gap;
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
interface IERC165Upgradeable {
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
// OpenZeppelin Contracts v4.4.1 (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeaconUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/StorageSlotUpgradeable.sol";
import "../utils/Initializable.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967UpgradeUpgradeable is Initializable {
    function __ERC1967Upgrade_init() internal onlyInitializing {
        __ERC1967Upgrade_init_unchained();
    }

    function __ERC1967Upgrade_init_unchained() internal onlyInitializing {
    }
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(AddressUpgradeable.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallSecure(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        address oldImplementation = _getImplementation();

        // Initial upgrade and setup call
        _setImplementation(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }

        // Perform rollback test if not already in progress
        StorageSlotUpgradeable.BooleanSlot storage rollbackTesting = StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT);
        if (!rollbackTesting.value) {
            // Trigger rollback using upgradeTo from the new implementation
            rollbackTesting.value = true;
            _functionDelegateCall(
                newImplementation,
                abi.encodeWithSignature("upgradeTo(address)", oldImplementation)
            );
            rollbackTesting.value = false;
            // Check rollback was effective
            require(oldImplementation == _getImplementation(), "ERC1967Upgrade: upgrade breaks further upgrades");
            // Finally reset to the new implementation and log the upgrade
            _upgradeTo(newImplementation);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(AddressUpgradeable.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            AddressUpgradeable.isContract(IBeaconUpgradeable(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
        }
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function _functionDelegateCall(address target, bytes memory data) private returns (bytes memory) {
        require(AddressUpgradeable.isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return AddressUpgradeable.verifyCallResult(success, returndata, "Address: low-level delegate call failed");
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeaconUpgradeable {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlotUpgradeable {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        assembly {
            r.slot := slot
        }
    }
}

/**
 * SPDX-License-Identifier: MIT
 *
 * Copyright (c) 2018-2020 CENTRE SECZ
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

pragma solidity 0.8.9;

/**
 * @title EIP712 Domain
 */
contract EIP712Domain {
    /**
     * @dev EIP712 Domain Separator
     */
    bytes32 public DOMAIN_SEPARATOR;
}

/**
 * SPDX-License-Identifier: MIT
 *
 * Copyright (c) 2018-2020 CENTRE SECZ
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

pragma solidity 0.8.9;

import { ECRecover } from "./ECRecover.sol";

/**
 * @title EIP712
 * @notice A library that provides EIP712 helper functions
 */
library EIP712 {
    /**
     * @notice Make EIP712 domain separator
     * @param name      Contract name
     * @param version   Contract version
     * @return Domain separator
     */
    function makeDomainSeparator(string memory name, string memory version)
        internal
        view
        returns (bytes32)
    {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        return
            keccak256(
                abi.encode(
                    // keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)")
                    0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f,
                    keccak256(bytes(name)),
                    keccak256(bytes(version)),
                    chainId,
                    address(this)
                )
            );
    }

    /**
     * @notice Recover signer's address from a EIP712 signature
     * @param domainSeparator   Domain separator
     * @param v                 v of the signature
     * @param r                 r of the signature
     * @param s                 s of the signature
     * @param typeHashAndData   Type hash concatenated with data
     * @return Signer's address
     */
    function recover(
        bytes32 domainSeparator,
        uint8 v,
        bytes32 r,
        bytes32 s,
        bytes memory typeHashAndData
    ) internal pure returns (address) {
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                domainSeparator,
                keccak256(typeHashAndData)
            )
        );
        return ECRecover.recover(digest, v, r, s);
    }
}

/**
 * SPDX-License-Identifier: MIT
 *
 * Copyright (c) 2016-2019 zOS Global Limited
 * Copyright (c) 2018-2020 CENTRE SECZ
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

pragma solidity 0.8.9;

/**
 * @title ECRecover
 * @notice A library that provides a safe ECDSA recovery function
 */
library ECRecover {
    /**
     * @notice Recover signer's address from a signed message
     * @dev Adapted from: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/65e4ffde586ec89af3b7e9140bdc9235d1254853/contracts/cryptography/ECDSA.sol
     * Modifications: Accept v, r, and s as separate arguments
     * @param digest    Keccak-256 hash digest of the signed message
     * @param v         v of the signature
     * @param r         r of the signature
     * @param s         s of the signature
     * @return Signer address
     */
    function recover(
        bytes32 digest,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (
            uint256(s) >
            0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0
        ) {
            revert("ECRecover: invalid signature 's' value");
        }

        if (v != 27 && v != 28) {
            revert("ECRecover: invalid signature 'v' value");
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(digest, v, r, s);
        require(signer != address(0), "ECRecover: invalid signature");

        return signer;
    }
}