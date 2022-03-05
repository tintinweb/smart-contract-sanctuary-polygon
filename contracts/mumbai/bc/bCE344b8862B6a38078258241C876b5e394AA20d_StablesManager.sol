// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./libraries/RebaseLib.sol";
import "./interfaces/stablecoin/ISharesRegistry.sol";
import "./interfaces/core/IManager.sol";
import "./interfaces/core/IHoldingManager.sol";
import "./interfaces/core/IStablesManager.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

//TODO: check what can be moved to Manager
contract StablesManager is IStablesManager, Ownable {
    using RebaseLib for RebaseLib.Rebase;

    /// @notice AlcBox project stablecoin address
    IERC20 public alcMoney;

    /// @notice manager's address
    IManager public manager;

    /// @notice represents the collateral rate precision
    /// @dev should be less than exchange rate precision due to optimization in math
    uint256 private constant COLLATERIZATION_RATE_PRECISION = 1e5;
    /// @notice exchange rate precision
    uint256 private constant EXCHANGE_RATE_PRECISION = 1e18;
    /// @notice used in liquidation operation
    uint256 private constant LIQUIDATION_MULTIPLIER_PRECISION = 1e5;
    /// @notice fee taken when a stablecoin borrow operation is done
    /// @dev can be 0
    uint256 private constant BORROW_OPENING_FEE_PRECISION = 1e5;
    /// @notice share balance for token
    /// @dev to prevent the ratio going off
    uint256 private constant MINIMUM_SHARE_BALANCE = 1000; 


    /// @notice total collateral share for a token
    /// @dev token > collateral share
    mapping(address => uint256) public totalCollateral;

    /// @notice total borrow per token
    mapping(address => RebaseLib.Rebase) public totalBorrowed;

    /// @notice borrowed amount for user, per token; holding > token > amount
    mapping(address => mapping(address => uint256)) public borrowed;
    /// @notice borrowed shares for user, per token; holding > token > shares
    mapping(address => mapping(address => uint256)) public borrowedShares;

    /// @notice share registry mapping per token; token > share registry address
    mapping(address => address) public shareRegistries;

    // Rebase from amount to share
    // TODO: check when this is updated
    mapping(IERC20 => RebaseLib.Rebase) public totals;

    // TODO: we might not need this!
    uint256 private constant DISTRIBUTION_PART = 10;
    // TODO: we might not need this!
    uint256 private constant DISTRIBUTION_PRECISION = 100;

    /// @notice creates a new StablesManager contract
    /// @param _manager the global manager's address
    /// @param _alcMoney the protocol's stablecoin address
    constructor(address _manager, address _alcMoney) {
        require(_manager != address(0), "ERR: INVALID MANAGER");
        require(_alcMoney != address(0), "ERR: INVALID TOKEN");
        manager = IManager(_manager);
        alcMoney = IERC20(_alcMoney);
    }

    // -- Owner specific methods --

    // -- View type methods --

    /// @notice Returns amount to share transformation
    /// @param _token token for which the exchange is done
    /// @param _amount token's amount
    /// @param _roundUp if the resulted shares are rounded up
    /// @return _share obtained shares
    function toShare(
        IERC20 _token,
        uint256 _amount,
        bool _roundUp
    ) public view override returns (uint256 _share) {
        _share = totals[_token].toBase(_amount, _roundUp);
    }

    /// @dev Returns share to amount transformation
    /// @param _token token for which the exchange is done
    /// @param _share amount of shares
    /// @param _roundUp if the resulted amount is rounded up
    /// @return _amount obtained amount
    function toAmount(
        IERC20 _token,
        uint256 _share,
        bool _roundUp
    ) public view override returns (uint256 _amount) {
        _amount = totals[_token].toElastic(_share, _roundUp);
    }

    /// @notice Returns true if user is solvent for the specified token
    /// @param _token the token for which the check is done
    /// @param _user the user address
    /// @param _collateral the amount of collateral the user has
    /// @param _collateralizationRate the collateralization rate for the specified token
    /// @return true/false
    function isUserSolvent(
        address _token,
        address _user,
        uint256 _collateral,
        uint256 _collateralizationRate
    ) public view override returns (bool) {
        if (borrowed[_user][_token] == 0) return true;
        if (_collateral == 0) return true;

        uint256 _solvencyRatio = _getSolvencyRatio(
            _token,
            _collateral,
            _collateralizationRate
        );

        return
            _solvencyRatio >=
            (borrowed[_user][_token] * totalBorrowed[_token].elastic) /
                totalBorrowed[_token].base;
    }

    // -- Write type methods --

    /// @notice registers new collateral
    /// @param _user the holding for which collateral is added
    /// @param _token collateral token
    /// @param _share amount of shares
    function addCollateral(
        address _user,
        address _token,
        uint256 _share
    ) external onlyHoldingManager {
        require(_share>0,"ERR: SHARE AMOUNT MIN");
        ISharesRegistry(shareRegistries[_token]).registerCollateral(
            _user,
            _share
        );

        totalCollateral[_token] += _share;
        RebaseLib.Rebase memory total = totals[IERC20(_token)];

        uint256 amount = total.toElastic(_share, true);
        total.base = total.base + uint128(_share);
        require(total.base >= MINIMUM_SHARE_BALANCE, "ERR: MIN SHARES");

        total.elastic = total.elastic + uint128(amount);
        totals[IERC20(_token)] = total;

        emit AddedCollateral(_user, _token, _share);

    }

    /// @notice unregisters collateral
    /// @param _user the holding for which collateral is added
    /// @param _token collateral token
    /// @param _share amount of shares
    function removeCollateral(
        address _user,
        address _token,
        uint256 _share
    ) external onlyHoldingManager {
        require(_share>0,"ERR: SHARE AMOUNT MIN");
        ISharesRegistry(shareRegistries[_token]).unregisterCollateral(
            _user,
            _share,
            totalBorrowed[_token].base,
            totalBorrowed[_token].elastic
        );

        totalCollateral[_token] -= _share;
        RebaseLib.Rebase memory total = totals[IERC20(_token)];

        uint256 amount = total.toElastic(_share, false);
        total.base = total.base - uint128(_share);
        total.elastic = total.elastic - uint128(amount);
        totals[IERC20(_token)] = total;

        // There have to be at least 1000 shares left to prevent reseting the share/amount ratio (unless it's fully emptied)
        require(total.base >= MINIMUM_SHARE_BALANCE || total.base == 0, "ERR: CANNOT EMPTY SHARES");

        emit RemovedCollateral(_user, _token, _share);
    }

    /// @notice mints stablecoin to the user
    /// @param _user the holding for which collateral is added
    /// @param _token collateral token
    /// @param _amount the borrowed amount
    function borrow(
        address _user,
        address _token,
        uint256 _amount
    ) external onlyHoldingManager returns (uint256 part, uint256 share) {
        ISharesRegistry registry = ISharesRegistry(shareRegistries[_token]);

        totalBorrowed[_token].elastic = registry.accrue(
            totalBorrowed[_token].base,
            totalBorrowed[_token].elastic
        );

        uint256 feeAmount = (_amount * registry.BORROW_OPENING_FEE()) /
            BORROW_OPENING_FEE_PRECISION;

        (totalBorrowed[_token], part) = totalBorrowed[_token].add(
            _amount + feeAmount,
            true
        );

        registry.accrueFees(feeAmount);
        borrowed[_user][_token] += part;

        share = toShare(alcMoney, _amount, false);
        borrowedShares[_user][_token] += share;

        require(
            isUserSolvent(
                _token,
                _user,
                registry.collateral(_user),
                registry.COLLATERIZATION_RATE()
            ),
            "ERR: USER INSOLVENT"
        );

        //TODO: mint `part` to `_user`; check if accurate?!

        emit Borrowed(_user, _amount, part);
    }

    /// @notice registers a repay operation
    /// @param _user the holding for which repay is performed
    /// @param _token collateral token
    /// @param _part the repayed amount
    function repay(
        address _user,
        address _token,
        uint256 _part
    ) external onlyHoldingManager returns (uint256 amount) {
        ISharesRegistry registry = ISharesRegistry(shareRegistries[_token]);

        totalBorrowed[_token].elastic = registry.accrue(
            totalBorrowed[_token].base,
            totalBorrowed[_token].elastic
        );

        (totalBorrowed[_token], amount) = totalBorrowed[_token].sub(
            _part,
            true
        );
        borrowed[_user][_token] -= _part;

        uint256 share = toShare(alcMoney, amount, true);
        borrowedShares[_user][_token] -= share;

        emit Repayed(_user, amount, _part);

        //TODO: do we need to check received funds here?! probably not as the user interacts with the HoldingManager first
    }

    /// @notice registers a liquidation event
    /// @dev if user is solvent, there's no need for liqudation;
    /// @param _user address of the holding which is being liquidated
    /// @param _token collateral token
    /// @param _to address of the holding which initiated the liquidation
    /// @return returns true if liquidation happened
    function liqudate(
        address _user,
        address _token,
        address _to
    ) external returns (bool) {
        require(_user != _to, "ERR: CANNOT LIQUIDATE YOURSELF");
        ISharesRegistry registry = ISharesRegistry(shareRegistries[_token]);

        //steps:
        //1-update exchange rate and accrue
        //2-check borrowed amount
        //3-check collateral share
        //4-update user's collateral share
        //5-declare user solvent

        //the oracle call can fail but we still need to allow liquidations
        (, uint256 _exchangeRate) = registry.updateExchangeRate();
        accrue(_token);

        RebaseLib.Rebase memory _totalBorrow = totalBorrowed[_token];
        RebaseLib.Rebase memory _totals = totals[IERC20(_token)];

        bool _isSolvent = isUserSolvent(
            _token,
            _user,
            registry.collateral(_user),
            registry.COLLATERIZATION_RATE()
        );

        //nothing to do if user is already solvent; skip liquidation
        if (_isSolvent) return false;

        uint256 borrowPart = borrowed[_user][_token];
        uint256 borrowAmount = _totalBorrow.toElastic(borrowPart, false);

        uint256 collateralShare = _totals.toBase(
            (borrowAmount * registry.LIQUIDATION_MULTIPLIER() * _exchangeRate) /
                (LIQUIDATION_MULTIPLIER_PRECISION * EXCHANGE_RATE_PRECISION),
            false
        );

        registry.updateLiquidatedCollateral(_user, _to, collateralShare);

        _totalBorrow.elastic = _totalBorrow.elastic - uint128(borrowAmount);
        _totalBorrow.base = _totalBorrow.base - uint128(borrowPart);
        totalBorrowed[_token] = _totalBorrow;

        totalCollateral[_token] -= collateralShare;

        borrowed[_user][_token] = 0;
        borrowedShares[_user][_token] = 0;

        //TODO: call HoldingMager to transfer collateral from _user to _to

        return true;
    }

    /// @notice accures interest for token
    /// @param _token token's address
    function accrue(address _token) public {
        totalBorrowed[_token].elastic = ISharesRegistry(shareRegistries[_token])
            .accrue(totalBorrowed[_token].base, totalBorrowed[_token].elastic);
    }

    // -- Private methods --
    function _getSolvencyRatio(
        address _token,
        uint256 _collateralShare,
        uint256 _collateralRatio
    ) private view returns (uint256) {
        uint256 _share = _collateralShare *
            (EXCHANGE_RATE_PRECISION / COLLATERIZATION_RATE_PRECISION) *
            _collateralRatio;
        return toAmount(IERC20(_token), _share, false);
    }

    modifier onlyHoldingManager() {
        require(
            msg.sender == manager.holdingManager(),
            "ERR: UNAUTHORIZED HOLDING MANAGER"
        );
        _;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library RebaseLib {
    struct Rebase {
        uint128 elastic;
        uint128 base;
    }

    /// @notice Calculates the base value in relationship to `elastic` and `total`.
    function toBase(
        Rebase memory total,
        uint256 elastic,
        bool roundUp
    ) internal pure returns (uint256 base) {
        if (total.elastic == 0) {
            base = elastic;
        } else {
            base = (elastic * total.base) / total.elastic;
            if (roundUp && ((base * total.elastic) / total.base) < elastic) {
                base = base + 1;
            }
        }
    }

    /// @notice Calculates the elastic value in relationship to `base` and `total`.
    function toElastic(
        Rebase memory total,
        uint256 base,
        bool roundUp
    ) internal pure returns (uint256 elastic) {
        if (total.base == 0) {
            elastic = base;
        } else {
            elastic = (base * total.elastic) / total.base;
            if (roundUp && ((elastic * total.base) / total.elastic) < base) {
                elastic = elastic + 1;
            }
        }
    }

    /// @notice Add `elastic` to `total` and doubles `total.base`.
    /// @return (Rebase) The new total.
    /// @return base in relationship to `elastic`.
    function add(
        Rebase memory total,
        uint256 elastic,
        bool roundUp
    ) internal pure returns (Rebase memory, uint256 base) {
        base = toBase(total, elastic, roundUp);
        total.elastic = uint128(total.elastic + elastic);
        total.base = uint128(total.base + base);
        return (total, base);
    }

    /// @notice Sub `base` from `total` and update `total.elastic`.
    /// @return (Rebase) The new total.
    /// @return elastic in relationship to `base`.
    function sub(
        Rebase memory total,
        uint256 base,
        bool roundUp
    ) internal pure returns (Rebase memory, uint256 elastic) {
        elastic = toElastic(total, base, roundUp);
        total.elastic = uint128(total.elastic - elastic);
        total.base = uint128(total.base - base);
        return (total, elastic);
    }

    /// @notice Add `elastic` and `base` to `total`.
    function add(
        Rebase memory total,
        uint256 elastic,
        uint256 base
    ) internal pure returns (Rebase memory) {
        total.elastic = uint128(total.elastic + elastic);
        total.base = uint128(total.base + base);
        return total;
    }

    /// @notice Subtract `elastic` and `base` to `total`.
    function sub(
        Rebase memory total,
        uint256 elastic,
        uint256 base
    ) internal pure returns (Rebase memory) {
        total.elastic = uint128(total.elastic - elastic);
        total.base = uint128(total.base - base);
        return total;
    }

    /// @notice Add `elastic` to `total` and update storage.
    /// @return newElastic Returns updated `elastic`.
    function addElastic(Rebase storage total, uint256 elastic)
        internal
        returns (uint256 newElastic)
    {
        newElastic = total.elastic = uint128(total.elastic + elastic);
    }

    /// @notice Subtract `elastic` from `total` and update storage.
    /// @return newElastic Returns updated `elastic`.
    function subElastic(Rebase storage total, uint256 elastic)
        internal
        returns (uint256 newElastic)
    {
        newElastic = total.elastic = uint128(total.elastic - elastic);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Interface for SharesRegistry contract
/// @author Cosmin Grigore (@gcosmintech)
/// @dev based on MIM CauldraonV2 contract
interface ISharesRegistry {
    /// @notice event emitted when contract new ownership is accepted
    event OwnershipAccepted(address indexed newOwner);
    /// @notice event emitted when contract ownership transferal was initated
    event OwnershipTransferred(
        address indexed oldOwner,
        address indexed newOwner
    );
    /// @notice event emitted when collateral was registered
    event CollateralAdded(address indexed user, uint256 share);
    /// @notice event emitted when collateral was unregistered
    event CollateralRemoved(address indexed user, uint256 share);
    /// @notice event emitted when exchange rate was updated
    event ExchangeRateUpdated(uint256 rate);

    /// @notice accure info data
    struct AccrueInfo {
        uint64 lastAccrued;
        uint128 feesEarned;
        uint64 INTEREST_PER_SECOND;
    }

    /// @notice returns the token address for which this registry was created
    function token() external view returns (address);

    /// @notice borrowing fee amount
    function BORROW_OPENING_FEE() external view returns (uint256);

    /// @notice collateralization rate for token
    function COLLATERIZATION_RATE() external view returns (uint256);

    //TODO: we might not need this ?!
    function LIQUIDATION_MULTIPLIER() external view returns (uint256);

    /// @notice returns the collateral shares for user
    /// @param _user the address for which the query is performed
    function collateral(address _user) external returns (uint256);

    /// @notice Gets the exchange rate. I.e how much collateral to buy 1e18 asset.
    /// @return updated True if `exchangeRate` was updated.
    /// @return rate The new exchange rate.
    function updateExchangeRate() external returns (bool updated, uint256 rate);

    /// @notice updates the AccrueInfo object
    /// @param _totalBorrowBase total borrow amount
    /// @param _totalBorrowElastic total borrow shares
    function accrue(uint256 _totalBorrowBase, uint256 _totalBorrowElastic)
        external
        returns (uint128);

    /// @notice removes collateral share from user
    /// @param _from the address for which the collateral is removed
    /// @param _to the address for which the collateral is added
    /// @param _share share amount
    function updateLiquidatedCollateral(
        address _from,
        address _to,
        uint256 _share
    ) external;

    /// @notice udates only the fees part of AccureInfo object
    function accrueFees(uint256 _amount) external;

    /// @notice registers collateral for token
    /// @param _user the user's address for which collateral is registered
    /// @param _share amount of shares
    function registerCollateral(address _user, uint256 _share) external;

    /// @notice unregisters collateral for token
    /// @param _user the user's address for which collateral is registered
    /// @param _share amount of shares
    /// @param _totalBorrowBase total borrow amount
    /// @param _totalBorrowElastic total borrow shares
    function unregisterCollateral(
        address _user,
        uint256 _share,
        uint256 _totalBorrowBase,
        uint256 _totalBorrowElastic
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Interface for a the manager contract
/// @author Cosmin Grigore (@gcosmintech)
interface IManager {
    /// @notice emitted when the dex manager is set
    event DexManagerUpdated(
        address indexed oldAddress,
        address indexed newAddress
    );

    /// @notice emitted when the strategy manager is set
    event StrategyManagerUpdated(
        address indexed oldAddress,
        address indexed newAddress
    );

    /// @notice emitted when the holding manager is set
    event HoldingManagerUpdated(
        address indexed oldAddress,
        address indexed newAddress
    );

    /// @notice emitted when the stablecoin manager is set
    event StablecoinManagerUpdated(
        address indexed oldAddress,
        address indexed newAddress
    );

    /// @notice emitted when the protocol token address is changed
    event ProtocolTokenUpdated(
        address indexed oldAddress,
        address indexed newAddress
    );

    /// @notice emitted when the protocol token reward for minting is updated
    event MintingTokenRewardUpdated(
        uint256 indexed oldFee,
        uint256 indexed newFee
    );

    /// @notice emitted when the max amount of available holdings is updated
    event MaxAvailableHoldingsUpdated(
        uint256 indexed oldFee,
        uint256 indexed newFee
    );

    /// @notice emitted when the fee address is changed
    event FeeAddressUpdated(
        address indexed oldAddress,
        address indexed newAddress
    );
    /// @notice emitted when the default fee is updated
    event PerformanceFeeUpdated(uint256 indexed oldFee, uint256 indexed newFee);

    /// @notice emitted when a new contract is whitelisted
    event ContractWhitelisted(address indexed contractAddress);

    /// @notice emitted when a contract is removed from the whitelist
    event ContractBlacklisted(address indexed contractAddress);

    /// @notice emitted when a new token is whitelisted
    event TokenWhitelisted(address indexed token);

    /// @notice emitted when a new token is removed from the whitelist
    event TokenRemoved(address indexed token);

    /// @notice returns true/false for contracts' whitelist status
    function isContractWhitelisted(address _contract)
        external
        view
        returns (bool);

    /// @notice returns true/false for token's whitelist status
    function isTokenWhitelisted(address _token) external view returns (bool);

    /// @notice returns holding manager address
    function holdingManager() external view returns (address);

    /// @notice returns stablecoin manager address
    function stablesManager() external view returns (address);

    /// @notice returns the available strategy manager
    function strategyManager() external view returns (address);

    /// @notice returns the available dex manager
    function dexManager() external view returns (address);

    /// @notice returns the protocol token address
    function protocolToken() external view returns (address);

    /// @notice returns the default performance fee
    function performanceFee() external view returns (uint256);

    /// @notice returns the amount of protocol tokens
    ///         rewarded for pre-minting a holding contract
    function mintingTokenReward() external view returns (uint256);

    /// @notice returns the max amount of available holdings
    function maxAvailableHoldings() external view returns (uint256);

    /// @notice returns the fee address
    function feeAddress() external view returns (address);

    /// @notice updates the fee address
    /// @param _fee the new address
    function setFeeAddress(address _fee) external;

    /// @notice updates the strategy manager address
    /// @param _strategy strategy manager's address
    function setStrategyManager(address _strategy) external;

    /// @notice updates the dex manager address
    /// @param _dex dex manager's address
    function setDexManager(address _dex) external;

    /// @notice sets the holding manager address
    /// @param _holding strategy's address
    function setHoldingManager(address _holding) external;

    /// @notice sets the protocol token address
    /// @param _protocolToken protocol token address
    function setProtocolToken(address _protocolToken) external;

    /// @notice sets the stablecoin manager address
    /// @param _stables strategy's address
    function setStablecoinManager(address _stables) external;

    /// @notice sets the performance fee
    /// @param _fee fee amount
    function setPerformanceFee(uint256 _fee) external;

    /// @notice sets the protocol token reward for pre-minting holdings
    /// @param _amount protocol token amount
    function setMintingTokenReward(uint256 _amount) external;

    /// @notice sets the max amount of available holdings
    /// @param _amount max amount of available holdings
    function setMaxAvailableHoldings(uint256 _amount) external;

    /// @notice whitelists a contract
    /// @param _contract contract's address
    function whitelistContract(address _contract) external;

    /// @notice removes a contract from the whitelisted list
    /// @param _contract contract's address
    function blacklistContract(address _contract) external;

    /// @notice whitelists a token
    /// @param _token token's address
    function whitelistToken(address _token) external;

    /// @notice removes a token from whitelist
    /// @param _token token's address
    function removeToken(address _token) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IMinHoldingManager.sol";

interface IHoldingManager is IMinHoldingManager {
    /// @notice emitted when a new holding is crated
    event HoldingCreated(address indexed user, address indexed holdingAddress);

    /// @notice emitted when a new user is assigned for the holding contract
    event HoldingAssigned(
        address indexed holding,
        address indexed minter,
        address indexed user
    );

    event HoldingUninitialized(address indexed holding);

    /// @notice emitted when rewards are sent to the holding contract
    event ReceivedRewards(
        address indexed holding,
        address indexed strategy,
        address indexed token,
        uint256 amount
    );

    /// @notice emitted when rewards were exchanged to another token
    event RewardsExchanged(
        address indexed holding,
        address indexed tokenIn,
        address indexed tokenOut,
        uint256 amountIn,
        uint256 amountOut
    );

    /// @notice emitted when rewards are withdrawn by the user
    event RewardsWithdrawn(
        address indexed holding,
        address indexed token,
        uint256 amount
    );

    /// @notice emitted when a deposit is created
    event Deposit(
        address indexed holding,
        address indexed user,
        address indexed token,
        uint256 amount
    );

    /// @notice emitted when an investment is created
    event Invested(
        address indexed holding,
        address indexed user,
        address indexed token,
        address strategy,
        uint256 amount,
        uint256 result
    );

    /// @notice emitted when an investment is withdrawn
    event StrategyClaim(
        address indexed holding,
        address indexed user,
        address indexed token,
        address strategy,
        uint256 shares,
        uint256 result
    );

    /// @notice emitted when an investment is withdrawn
    event InvestmentMoved(
        address indexed holding,
        address indexed user,
        address indexed token,
        address strategyFrom,
        address strategyTo,
        uint256 shares,
        uint256 result
    );

    /// @notice emitted when the Manager address is updated
    event ManagerUpdated(address indexed _old, address indexed _new);

    /// @notice returns holding for user
    function userHolding(address _user) external view returns (address);

    /// @notice returns true if holding was created
    function isHolding(address _holding) external view returns (bool);

    /// @notice address of the holding config contract
    function manager() external view returns (address);

    /// @notice mapping of minters of each holding (holding address => minter address)
    function holdingMinter(address) external view returns (address);

    /// @notice mapping of available holdings by position (position=>holding address)
    function availableHoldings(uint256) external view returns (address);

    /// @notice position of the first available holding
    function availableHoldingsHead() external view returns (uint256);

    /// @notice position of the last available holding
    function availableHoldingsTail() external view returns (uint256);

    /// @notice number of available holding contracts (tail - head)
    function numAvailableHoldings() external view returns (uint256);

    // -- User specific methods --

    /// @notice withdraws a token from the contract
    /// @param _holding holding's address
    /// @param _token token user wants to withdraw
    /// @param _amount withdrawal amount
    function withdraw(
        address _holding,
        address _token,
        uint256 _amount
    ) external;

    /// @notice deposits a whitelisted token into the holding
    /// @param _holding holding's address
    /// @param _token token's address
    /// @param _amount amount to deposit
    function deposit(
        address _holding,
        address _token,
        uint256 _amount
    ) external;

    /// @notice invests token into one of the whitelisted strategies
    /// @param _holding holding's address
    /// @param _token token's address
    /// @param _strategy strategy's address
    /// @param _amount token's amount
    /// @param _data extra data
    function invest(
        address _holding,
        address _token,
        address _strategy,
        uint256 _amount,
        bytes calldata _data
    ) external returns (uint256);

    /// @notice claims a strategy investment
    /// @param _holding holding's address
    /// @param _strategy strategy to invest into
    /// @param _shares shares amount
    /// @param _asset token address to be received
    /// @param _data extra data
    function claimInvestment(
        address _holding,
        address _strategy,
        uint256 _shares,
        address _asset,
        bytes calldata _data
    ) external returns (uint256);

    /// @notice exchanges an existing token with a whitelisted one
    /// @param _holding holding's address
    /// @param _ammId selected AMM id
    /// @param _tokenIn token available in the contract
    /// @param _tokenOut token resulting from the swap operation
    /// @param _amountIn exchange amount
    /// @param _minAmountOut min amount of tokenOut to receive when the swap is performed
    /// @param _data specific amm data
    /// @return the amount obtained
    function exchange(
        address _holding,
        uint256 _ammId,
        address _tokenIn,
        address _tokenOut,
        uint256 _amountIn,
        uint256 _minAmountOut,
        bytes calldata _data
    ) external returns (uint256);

    /// @notice claims investment from one strategy and invests it into another
    /// @param _holding holding's address
    /// @param _token token's address
    /// @param _strategyFrom strategy's address to claimInvestment from
    /// @param _strategyTo strategy's address to invest
    /// @param _shares shares amount
    /// @param _dataFrom extra data for claimInvestment
    /// @param _dataTo extra data for invest
    function moveInvestment(
        address _holding,
        address _token,
        address _strategyFrom,
        address _strategyTo,
        uint256 _shares,
        bytes calldata _dataFrom,
        bytes calldata _dataTo
    ) external returns (uint256);

    /// @notice creates holding and leaves it available to be assigned
    function createHolding() external returns (address);

    /// @notice creates holding at assigns it to the user
    function createHoldingForMyself() external returns (address);

    /// @notice assigns a new user to an existing holding
    /// @dev callable by owner only
    /// @param _user new user's address
    function assignHolding(address _user) external;

    /// @notice sets the manager address
    /// @param _manager contract's address
    function setManager(address _manager) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title Interface for stables manager
/// @author Cosmin Grigore (@gcosmintech)
/// @dev based on MIM implementation
interface IStablesManager {
    /// @notice event emitted when collateral was registered
    event AddedCollateral(
        address indexed user,
        address indexed token,
        uint256 amount
    );
    /// @notice event emitted when collateral was unregistered
    event RemovedCollateral(
        address indexed user,
        address indexed token,
        uint256 amount
    );
    /// @notice event emitted when a borrow action was performed
    event Borrowed(address indexed user, uint256 amount, uint256 part);
    /// @notice event emitted when a repay action was performed
    event Repayed(address indexed user, uint256 amount, uint256 part);

    /// @notice Returns amount to share transformation
    /// @param _token token for which the exchange is done
    /// @param _amount token's amount
    /// @param _roundUp if the resulted shares are rounded up
    /// @return _share obtained shares
    function toShare(
        IERC20 _token,
        uint256 _amount,
        bool _roundUp
    ) external view returns (uint256 _share);

    /// @dev Returns share to amount transformation
    /// @param _token token for which the exchange is done
    /// @param _share amount of shares
    /// @param _roundUp if the resulted amount is rounded up
    /// @return _amount obtained amount
    function toAmount(
        IERC20 _token,
        uint256 _share,
        bool _roundUp
    ) external view returns (uint256 _amount);

    /// @notice Returns true if user is solvent for the specified token
    /// @param _token the token for which the check is done
    /// @param _user the user address
    /// @param _collateral the amount of collateral the user has
    /// @param _collateralizationRate the collateralization rate for the specified token
    /// @return true/false
    function isUserSolvent(
        address _token,
        address _user,
        uint256 _collateral,
        uint256 _collateralizationRate
    ) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
pragma solidity ^0.8.0;

interface IMinHoldingManager {

    /// @notice returns user for holding
    function holdingUser(address _holding) external view returns (address);
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