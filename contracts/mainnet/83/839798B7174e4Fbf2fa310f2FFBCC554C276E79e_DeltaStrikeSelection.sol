// SPDX-License-Identifier: MIT
pragma solidity =0.8.14;

import {IPriceOracle} from "../interfaces/IPriceOracle.sol";
import {IOptionsPremiumPricer} from "../interfaces/ITrufin.sol";
import {IManualVolatilityOracle} from "../interfaces/IManualVolatilityOracle.sol";
import {IStrikeSelection} from "../interfaces/ITrufin.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import {Vault} from "../libraries/Vault.sol";

/**
 * @title DeltaStrikeSelection
 * @dev Calculates the desired option strike price
 * When provided with volatility oracle, spot price oracle, target delta, step and expiry
 */
contract DeltaStrikeSelection is Ownable, IStrikeSelection {
    /**
     * Immutables
     */
    IOptionsPremiumPricer public immutable optionsPremiumPricer;

    IManualVolatilityOracle public immutable volatilityOracle;

    /**
     * @dev delta for options strike price selection. 1 is 10000 (10**4)
     */
    uint256 public delta;

    // Step indicates the user chosen grid granularity ( grid precision )
    // We use two strike prices, with gap of step, and we shift them until there is a strike price, with delta between target delta
    // The target delta is chosen at start
    // corresponding to that delta is a strike price
    // The algorithm, tries to choose a strike price which is rounded to the nearest step that is as close as possible to the strike price of the target delta
    // step in absolute terms at which we will increment
    // (ex: 100 * 10 ** assetOracleDecimals means we will move at increments of 100 points)
    uint256 public step;

    /**
     * @dev multiplier to shift asset prices
     */
    uint256 private immutable assetOracleMultiplier;

    /**
     * @dev Delta are in 4 decimal places. 1 * 10**4 = 1 delta.
     */
    uint256 private constant DELTA_MULTIPLIER = 10**4;

    /**
     * @dev ChainLink's USD Price oracles return results in 8 decimal places
     */
    uint256 private constant ORACLE_PRICE_MULTIPLIER = 10**8;

    /**
     * @dev Emitted when new delta value is set
     * @param oldDelta is the old delta value
     * @param newDelta is the new delta value
     * @param owner is address which set the delta
     */
    event DeltaSet(uint256 oldDelta, uint256 newDelta, address indexed owner);

    /**
     * @dev Emitted when new step value is set
     * @param oldStep is the old step value
     * @param newStep is the new step value
     * @param owner is address which set the step
     */
    event StepSet(uint256 oldStep, uint256 newStep, address indexed owner);

    /**
     * Contract constructor.
     * @param _optionsPremiumPricer address of the options premium pricer.
     * @param _delta is the initial delta to be set.
     * @param _step is the initial step to be set
     */
    constructor(
        address _optionsPremiumPricer,
        uint256 _delta,
        uint256 _step
    ) {
        require(
            _optionsPremiumPricer != address(0),
            "Should not be a zero address"
        );
        require(_delta > 0, "_delta should be greater than zero");
        require(_delta <= DELTA_MULTIPLIER, "newDelta cannot be more than 1");
        require(_step > 0, "_step should be greater than zero");
        optionsPremiumPricer = IOptionsPremiumPricer(_optionsPremiumPricer);
        volatilityOracle = IManualVolatilityOracle(
            IOptionsPremiumPricer(_optionsPremiumPricer).volatilityOracle()
        );
        // ex: delta = 7500 (.75)
        delta = _delta;
        uint256 _assetOracleMultiplier = 10 **
            IPriceOracle(
                IOptionsPremiumPricer(_optionsPremiumPricer).priceOracle()
            ).decimals();

        // ex: step = 1000
        step = _step;

        assetOracleMultiplier = _assetOracleMultiplier;
    }

    /**
     * @notice Gets the strike price satisfying the delta value
     * given the expiry timestamp and whether option is call or put
     * @param expiryTimestamp is the unix timestamp of expiration
     * @param isPut is whether option is put or call
     * @return newStrikePrice is the strike price of the option (ex: for BTC might be 45000 * 10 ** 8)
     * @return newDelta is the delta of the option given its parameters
     */
    function getStrikePrice(uint256 expiryTimestamp, bool isPut)
        external
        view
        returns (uint256 newStrikePrice, uint256 newDelta)
    {
        // asset's annualized volatility : To annualize a number means to convert a short-term calculation or rate into an annual rate.
        uint256 annualizedVol = volatilityOracle.annualizedVol(
            optionsPremiumPricer.optionId()
        ) * 10**10;

        return _getStrikePrice(expiryTimestamp, isPut, annualizedVol);
    }

    /**
     * @notice Gets the strike price satisfying the delta value
     * given the expiry timestamp and whether option is call or put
     * @param expiryTimestamp is the unix timestamp of expiration
     * @param isPut is whether option is put or call
     * @param annualizedVol implied volatility of the underlying asset
     * @return newStrikePrice is the strike price of the option (ex: for BTC might be 45000 * 10 ** 8)
     * @return newDelta is the delta of the option given its parameters
     */
    function getStrikePriceWithVol(
        uint256 expiryTimestamp,
        bool isPut,
        uint256 annualizedVol
    ) external view returns (uint256 newStrikePrice, uint256 newDelta) {
        return _getStrikePrice(expiryTimestamp, isPut, annualizedVol * 10**10);
    }

    /**
     * @notice Gets the strike price satisfying the delta value
     * given the expiry timestamp and whether option is call or put
     * @dev
     * 1) Get the asset spot price using the `optionsPremiumPricer.getUnderlyingPrice()`
     * 2) Pick a starting strike price k0 close to the current asset price
     * 3) Calculate the delta for the starting strike price k0
     *    Delta is calculated using `optionsPremiumPricer.getOptionDelta` which uses Black Scholes equation for delta
     * 4) Calculate the next possible strike price ki+1 = ki + step
     * 5) Calculate the delta and check if deltaKi >= targetDelta >= deltaKi+1 if not go back to step 4
     * 6) Currently the strikePrice lies somewhere in the [ki, ki+1].
          Select the one which has the closest delta to the targetDelta and return it + it's delta
     * @param expiryTimestamp is the unix timestamp of expiration
     * @param isPut is whether option is put or call
     * @param annualizedVol volatility of the underlying asset
     * @return newStrikePrice is the strike price of the option (ex: for BTC might be 45000 * 10 ** 8)
     * @return newDelta is the delta of the option given its parameters
     */

    function _getStrikePrice(
        uint256 expiryTimestamp,
        bool isPut,
        uint256 annualizedVol
    ) internal view returns (uint256 newStrikePrice, uint256 newDelta) {
        require(
            expiryTimestamp > block.timestamp,
            "Expiry must be in the future!"
        );

        // asset price
        uint256 assetPrice = optionsPremiumPricer.getUnderlyingPrice();

        // For each asset prices with step of 'step' (down if put, up if call)
        //   if asset's getOptionDelta(currStrikePrice, spotPrice, annualizedVol, t) == (isPut ? 1 - delta:delta)
        //   with certain margin of error
        //        return strike price

        uint256 strike = isPut
            ? assetPrice - (assetPrice % step) - step
            : assetPrice + (step - (assetPrice % step)) + step;
        uint256 targetDelta = isPut ? DELTA_MULTIPLIER - delta : delta;
        uint256 prevDelta = isPut ? 0 : DELTA_MULTIPLIER;

        while (true) {
            uint256 currDelta = optionsPremiumPricer.getOptionDelta(
                (assetPrice * ORACLE_PRICE_MULTIPLIER) / assetOracleMultiplier,
                strike,
                annualizedVol,
                expiryTimestamp
            );

            //  If the current delta is between the previous
            //  strike price delta and current strike price delta
            //  then we are done
            bool foundTargetStrikePrice = isPut
                ? targetDelta >= prevDelta && targetDelta <= currDelta
                : targetDelta <= prevDelta && targetDelta >= currDelta;

            if (foundTargetStrikePrice) {
                uint256 finalDelta = _getBestDelta(
                    prevDelta,
                    currDelta,
                    targetDelta,
                    isPut
                );
                uint256 finalStrike = _getBestStrike(
                    finalDelta,
                    prevDelta,
                    strike,
                    isPut
                );
                require(
                    isPut
                        ? finalStrike <= assetPrice
                        : finalStrike >= assetPrice,
                    "Invalid strike price"
                );
                // make decimals consistent with oToken strike price decimals (10 ** 8)
                return (
                    (finalStrike * ORACLE_PRICE_MULTIPLIER) /
                        assetOracleMultiplier,
                    finalDelta
                );
            }
            //If reverts, decrease step size
            require(
                isPut ? targetDelta >= prevDelta : targetDelta <= prevDelta,
                "Delta out of bounds"
            );

            strike = isPut ? strike - step : strike + step;

            prevDelta = currDelta;
        }
    }

    /**
     * @notice Rounds to best delta value: picks the strike in the grid with delta closer to target
     * @param prevDelta is the delta of the previous strike price
     * @param currDelta is delta of the current strike price
     * @param targetDelta is the delta we are targeting
     * @param isPut is whether its a put
     * @return the best delta value
     */
    function _getBestDelta(
        uint256 prevDelta,
        uint256 currDelta,
        uint256 targetDelta,
        bool isPut
    ) private pure returns (uint256) {
        uint256 finalDelta;

        // for tie breaks (ex: 0.05 <= 0.1 <= 0.15) round to higher strike price
        // for calls and lower strike price for puts for deltas
        if (isPut) {
            uint256 upperBoundDiff = currDelta - targetDelta;
            uint256 lowerBoundDiff = targetDelta - prevDelta;
            finalDelta = lowerBoundDiff <= upperBoundDiff
                ? prevDelta
                : currDelta;
        } else {
            uint256 upperBoundDiff = prevDelta - targetDelta;
            uint256 lowerBoundDiff = targetDelta - currDelta;

            finalDelta = lowerBoundDiff <= upperBoundDiff
                ? currDelta
                : prevDelta;
        }

        return finalDelta;
    }

    /**
     * @notice Rounds to best delta value
     * @param finalDelta is the best delta value we found
     * @param prevDelta is delta of the previous strike price
     * @param strike is the strike of the previous iteration
     * @param isPut is whether its a put
     * @return the best strike
     */
    function _getBestStrike(
        uint256 finalDelta,
        uint256 prevDelta,
        uint256 strike,
        bool isPut
    ) private view returns (uint256) {
        if (finalDelta != prevDelta) {
            return strike;
        }
        return isPut ? strike + step : strike - step;
    }

    /**
     * @notice Sets new delta value
     * @param newDelta is the new delta value
     */
    function setDelta(uint256 newDelta) external onlyOwner {
        require(newDelta > 0, "newDelta should be greater than zero");
        require(newDelta <= DELTA_MULTIPLIER, "newDelta cannot be more than 1");
        uint256 oldDelta = delta;
        delta = newDelta;
        emit DeltaSet(oldDelta, newDelta, msg.sender);
    }

    /**
     * @notice Sets new step value
     * @param newStep is the new step value
     */
    function setStep(uint256 newStep) external onlyOwner {
        require(newStep > 0, "newStep should be greater than zero");
        uint256 oldStep = step;
        step = newStep;
        emit StepSet(oldStep, newStep, msg.sender);
    }
}

//SPDX-License-Identifier: GPL-3.0
pragma solidity =0.8.14;

interface IPriceOracle {
    function decimals() external view returns (uint256 _decimals);

    function latestAnswer() external view returns (uint256 price);
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.14;
import {Vault} from "../libraries/Vault.sol";

interface IStrikeSelection {
    /**
     * @notice Gets the strike price satisfying the delta value
     * given the expiry timestamp and whether option is call or put
     * @param expiryTimestamp is the unix timestamp of expiration
     * @param isPut is whether option is put or call
     * @return newStrikePrice is the strike price of the option (ex: for BTC might be 45000 * 10 ** 8)
     * @return newDelta is the delta of the option given its parameters
     */
    function getStrikePrice(uint256 expiryTimestamp, bool isPut)
        external
        view
        returns (uint256 newStrikePrice, uint256 newDelta);

    /**
     * @notice Getter function for delta
     * @dev delta for options strike price selection. 1 is 10000 (10**4)
     */
    function delta() external view returns (uint256);
}

interface IOptionsPremiumPricer {
    function getPremium(
        uint256 strikePrice,
        uint256 timeToExpiry,
        bool isPut
    ) external view returns (uint256);

    function getPremiumInStables(
        uint256 strikePrice,
        uint256 timeToExpiry,
        bool isPut
    ) external view returns (uint256);

    function getOptionDelta(
        uint256 spotPrice,
        uint256 strikePrice,
        uint256 volatility,
        uint256 expiryTimestamp
    ) external view returns (uint256 delta);

    function getUnderlyingPrice() external view returns (uint256);

    function priceOracle() external view returns (address);

    function volatilityOracle() external view returns (address);

    function optionId() external view returns (bytes32);
}

//SPDX-License-Identifier: GPL-3.0
pragma solidity =0.8.14;

interface IManualVolatilityOracle {
    function vol(bytes32 optionId)
        external
        view
        returns (uint256 standardDeviation);

    function annualizedVol(bytes32 optionId)
        external
        view
        returns (uint256 annualStdev);

    function setAnnualizedVol(
        bytes32[] calldata optionIds,
        uint256[] calldata newAnnualizedVols
    ) external;
}

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
pragma solidity =0.8.14;

library Vault {
    /************************************************
     *  IMMUTABLES & CONSTANTS
     ***********************************************/

    /// @dev Fees are 6-decimal places. For example: 20 * 10**6 = 20%
    uint256 internal constant FEE_MULTIPLIER = 10**6;

    /// @dev Premium discount has 1-decimal place. For example: 80 * 10**1 = 80%. Which represents a 20% discount.
    uint256 internal constant PREMIUM_DISCOUNT_MULTIPLIER = 10;

    /// @dev Otokens have 8 decimal places.
    uint256 internal constant OTOKEN_DECIMALS = 8;

    /// @dev Percentage of funds allocated to options is 2 decimal places. 10 * 10**2 = 10%
    uint256 internal constant OPTION_ALLOCATION_MULTIPLIER = 10**2;

    /// @dev Placeholder uint value to prevent cold writes
    uint256 internal constant PLACEHOLDER_UINT = 1;

    /// @dev struct for vault general data
    struct VaultParams {
        /// @dev Option type the vault is selling
        bool isPut;
        /// @dev Token decimals for vault shares
        uint8 decimals;
        /// @dev Asset used in Theta Vault
        address asset;
        /// @dev Underlying asset of the options sold by vault
        address underlying;
        /// @dev Minimum supply of the vault shares issued, for ETH it's 10**10
        uint56 minimumSupply;
        /// @dev Vault cap
        uint104 cap;
    }

    /// @dev struct for vault state of the options sold and the timelocked option
    struct OptionState {
        /// @dev Option that the vault is shorting / longing in the next cycle
        address nextOption;
        /// @dev Option that the vault is currently shorting / longing
        address currentOption;
        /// @dev The timestamp when the `nextOption` can be used by the vault
        uint32 nextOptionReadyAt;
        /// @dev The timestamp when the `nextOption` will expire
        uint256 currentOptionExpirationAt;
    }

    /// @dev struct for vault accounting state
    struct VaultState {
        /**
         * @dev 32 byte slot 1
         * Current round number. `round` represents the number of `period`s elapsed.
         */
        uint16 round;
        /// @dev Amount that is currently locked for selling options
        uint104 lockedAmount;
        /**
         * @dev Amount that was locked for selling options in the previous round
         * used for calculating performance fee deduction
         */
        uint104 lastLockedAmount;
        /**
         * @dev 32 byte slot 2
         * Stores the total tally of how much of `asset` there is
         * to be used to mint rTHETA tokens
         */
        uint128 totalPending;
        /// @dev Amount locked for scheduled withdrawals;
        uint128 queuedWithdrawShares;
    }

    /// @dev struct for fee rebate for whitelisted vaults depositings
    struct VaultFee {
        /// @dev Amount for whitelisted vaults
        mapping(uint16 => uint256) whitelistedVaultAmount;
        /// @dev Fees not to recipient fee recipient: Will be sent to the vault at complete
        mapping(uint16 => uint256) feesNotSentToRecipient;
    }

    /// @dev struct for pending deposit for the round
    struct DepositReceipt {
        /// @dev Maximum of 65535 rounds. Assuming 1 round is 7 days, maximum is 1256 years.
        uint16 round;
        /// @dev Deposit amount, max 20,282,409,603,651 or 20 trillion ETH deposit
        uint104 amount;
        /// @dev Unredeemed shares balance
        uint128 unredeemedShares;
    }

    /// @dev struct for pending withdrawals
    struct Withdrawal {
        /// @dev Maximum of 65535 rounds. Assuming 1 round is 7 days, maximum is 1256 years.
        uint16 round;
        /// @dev Number of shares withdrawn
        uint128 shares;
    }

    /// @dev struct for auction sell order
    struct AuctionSellOrder {
        /// @dev Amount of `asset` token offered in auction
        uint96 sellAmount;
        /// @dev Amount of oToken requested in auction
        uint96 buyAmount;
        /// @dev User Id of delta vault in latest gnosis auction
        uint64 userId;
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