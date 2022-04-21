// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./libraries/RebaseLib.sol";
import "./libraries/OperationsLib.sol";

import "./interfaces/core/IManager.sol";
import "./interfaces/core/IHoldingManager.sol";
import "./interfaces/core/IStablesManager.sol";
import "./interfaces/stablecoin/IPandoraUSD.sol";
import "./interfaces/stablecoin/ISharesRegistry.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

/// @title StablesManager contract
/// @author Cosmin Grigore (@gcosmintech)
contract StablesManager is IStablesManager, Ownable {
    using RebaseLib for RebaseLib.Rebase;

    /// @notice AlcBox project stablecoin address
    IPandoraUSD public override pandoraUSD;

    /// @notice contract that contains the address of the manager contract
    IManagerContainer public immutable override managerContainer;

    /// @notice returns the pause state of the contract
    bool public override paused;

    /// @notice total borrow per token
    mapping(address => RebaseLib.Rebase) public override totalBorrowed;

    /// @notice returns config info for each share
    mapping(address => ShareRegistryInfo) public override shareRegistryInfo;

    // Rebase from amount to share
    mapping(IERC20 => RebaseLib.Rebase) public override totals;

    /// @notice creates a new StablesManager contract
    /// @param _managerContainer contract that contains the address of the manager contract
    /// @param _pandoraUSD the protocol's stablecoin address
    constructor(address _managerContainer, address _pandoraUSD) {
        require(_managerContainer != address(0), "3065");
        require(_pandoraUSD != address(0), "3001");
        managerContainer = IManagerContainer(_managerContainer);
        pandoraUSD = IPandoraUSD(_pandoraUSD);
    }

    // -- Owner specific methods --
    /// @notice sets a new value for pause state
    /// @param _val the new value
    function setPaused(bool _val) external override onlyOwner {
        emit PauseUpdated(paused, _val);
        paused = _val;
    }

    /// @notice sets the pUSD address
    /// @param _newAddr contract's address
    function setPandoraUSD(address _newAddr) external override onlyOwner {
        require(_newAddr != address(0), "3000");
        emit StableAddressUpdated(address(pandoraUSD), _newAddr);
        pandoraUSD = IPandoraUSD(_newAddr);
    }

    /// @notice registers a share registry contract for a token
    /// @param _registry registry contract address
    /// @param _token token address
    function registerShareRegistry(address _registry, address _token)
        external
        onlyOwner
    {
        require(_token != address(0), "3007");
        require(shareRegistryInfo[_token].deployedAt == address(0), "3017");

        _setShareRegistry(_registry, _token, true);
        emit RegistryAdded(_token, _registry);
    }

    /// @notice updates an already registered share registry contract for a token
    /// @param _registry registry contract address
    /// @param _token token address
    /// @param _active set it as active or inactive
    function updateShareRegistry(
        address _registry,
        address _token,
        bool _active
    ) external onlyOwner {
        require(_token != address(0), "3007");
        require(shareRegistryInfo[_token].deployedAt != address(0), "3060");

        _setShareRegistry(_registry, _token, _active);
        emit RegistryUpdated(_token, _registry);
    }

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
    /// @param _holding the user address
    /// @return true/false
    function isSolvent(address _token, address _holding)
        public
        view
        override
        returns (bool)
    {
        require(_holding != address(0), "3031");
        ISharesRegistry registry = ISharesRegistry(
            shareRegistryInfo[_token].deployedAt
        );
        require(address(registry) != address(0), "3008");

        if (registry.borrowed(_holding) == 0) return true;

        uint256 _solvencyRatio = _getSolvencyRatio(_holding, registry);

        uint256 _borrowRatio = (registry.borrowed(_holding) *
            totalBorrowed[_token].elastic) / totalBorrowed[_token].base;

        return _solvencyRatio >= _borrowRatio;
    }

    /// @notice get liquidation info for holding and token
    /// @dev returns borrowed amount, collateral amount, collateral's value ratio, current borrow ratio, solvency status; colRatio needs to be >= borrowRaio
    /// @param _holding address of the holding to check for
    /// @param _token address of the token to check for
    function getLiquidationInfo(address _holding, address _token)
        external
        view
        override
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            bool
        )
    {
        ISharesRegistry registry = ISharesRegistry(
            shareRegistryInfo[_token].deployedAt
        );

        uint256 colRatio = _getSolvencyRatio(_holding, registry);
        uint256 borrowRatio = registry.borrowed(_holding) == 0
            ? 0
            : (registry.borrowed(_holding) * totalBorrowed[_token].elastic) /
                totalBorrowed[_token].base;

        return (
            registry.borrowed(_holding),
            registry.collateral(_holding),
            colRatio,
            borrowRatio,
            colRatio >= borrowRatio
        );
    }

    /// @notice returns collateral amount
    /// @param _token collateral token
    /// @param _amount stablecoin amount
    function computeNeededCollateral(address _token, uint256 _amount)
        external
        view
        override
        returns (uint256 result)
    {
        result =
            (_amount * _getManager().EXCHANGE_RATE_PRECISION()) /
            ISharesRegistry(shareRegistryInfo[_token].deployedAt)
                .exchangeRate();
    }

    // -- Write type methods --

    /// @notice accrues collateral for holding
    /// @dev callable by the owner
    /// @param _holding the holding for which collateral is added
    /// @param _token collateral token
    /// @param _amount amount of collateral
    function forceAddCollateral(
        address _holding,
        address _token,
        uint256 _amount
    ) external override onlyOwner {
        uint256 _share = _addCollateral(_holding, _token, _amount);
        emit ForceAddedCollateral(_holding, _token, _share);
    }

    /// @notice registers new collateral
    /// @dev the amount will be transformed to shares
    /// @param _holding the holding for which collateral is added
    /// @param _token collateral token
    /// @param _amount amount of tokens to be added as collateral
    function addCollateral(
        address _holding,
        address _token,
        uint256 _amount
    ) external override notPaused onlyHoldingOrStrategyManager {
        require(shareRegistryInfo[_token].active, "1201");
        uint256 _share = _addCollateral(_holding, _token, _amount);

        emit AddedCollateral(_holding, _token, _share);
    }

    /// @notice removes collateral for holding
    /// @dev callable by the owner
    /// @param _holding the holding for which collateral is removed
    /// @param _token collateral token
    /// @param _amount amount of collateral
    function forceRemoveCollateral(
        address _holding,
        address _token,
        uint256 _amount
    ) external override onlyOwner {
        uint256 _share = _removeCollateral(_holding, _token, _amount);
        emit ForceRemovedCollateral(_holding, _token, _share);
    }

    /// @notice unregisters collateral
    /// @param _holding the holding for which collateral is added
    /// @param _token collateral token
    /// @param _amount amount of collateral
    function removeCollateral(
        address _holding,
        address _token,
        uint256 _amount
    ) external override onlyHoldingOrStrategyManager notPaused {
        require(shareRegistryInfo[_token].active, "1201");
        uint256 _share = _removeCollateral(_holding, _token, _amount);

        require(isSolvent(_token, _holding), "3009");
        emit RemovedCollateral(_holding, _token, _share);
    }

    /// @notice migrates collateral and share to a new registry
    /// @param _holding the holding for which collateral is added
    /// @param _tokenFrom collateral token source
    /// @param _tokenTo collateral token destination
    /// @param _collateralFrom collateral amount to be removed from source
    /// @param _collateralTo collateral amount to be added to destination
    function migrateDataToRegistry(
        address _holding,
        address _tokenFrom,
        address _tokenTo,
        uint256 _collateralFrom,
        uint256 _collateralTo
    ) external override onlyHoldingOrStrategyManager notPaused {
        ISharesRegistry registryFrom = ISharesRegistry(
            shareRegistryInfo[_tokenFrom].deployedAt
        );

        uint256 _migratedRatio = OperationsLib.getRatio(
            _collateralFrom,
            registryFrom.collateral(_holding),
            18
        );

        if (shareRegistryInfo[_tokenTo].deployedAt != address(0)) {
            _addCollateral(_holding, _tokenTo, _collateralTo);
        }
        _removeCollateral(_holding, _tokenFrom, _collateralFrom);

        uint256 _borrowedFrom = 0;
        uint256 _borrowedSharesFrom = 0;
        if (
            registryFrom.borrowed(_holding) > 0 &&
            shareRegistryInfo[_tokenTo].deployedAt != address(0)
        ) {
            ISharesRegistry registryTo = ISharesRegistry(
                shareRegistryInfo[_tokenTo].deployedAt
            );

            uint256 _borrowedTo = 0;
            uint256 _borrowedSharesTo = 0;

            (
                _borrowedFrom,
                _borrowedSharesFrom,
                _borrowedTo,
                _borrowedSharesTo
            ) = _getMigrationData(
                _holding,
                registryFrom,
                _tokenTo,
                _migratedRatio
            );

            //add to destination
            _updateDestinationOnMigration(
                _holding,
                registryTo,
                _borrowedTo,
                _borrowedSharesTo
            );

            //remove from source
            _updateSourceOnMigration(
                _holding,
                registryFrom,
                _borrowedFrom,
                _borrowedSharesFrom
            );

            //do not check solvency to save gas
        }

        emit CollateralMigrated(
            _holding,
            _tokenFrom,
            _tokenTo,
            _borrowedFrom,
            _borrowedSharesFrom,
            _collateralTo
        );
    }

    /// @notice mints stablecoin to the user
    /// @param _holding the holding for which collateral is added
    /// @param _token collateral token
    /// @param _amount the borrowed amount
    /// @param _mintDirectlyToUser if true mints to user instead of holding
    function borrow(
        address _holding,
        address _token,
        uint256 _amount,
        bool _mintDirectlyToUser
    )
        external
        override
        onlyHoldingOrStrategyManager
        notPaused
        returns (
            uint256 part,
            uint256 share,
            uint256 feeAmount
        )
    {
        require(_amount > 0, "3010");
        require(shareRegistryInfo[_token].active, "1201");

        ISharesRegistry registry = ISharesRegistry(
            shareRegistryInfo[_token].deployedAt
        );

        totalBorrowed[_token].elastic = registry.accrue(
            totalBorrowed[_token].base,
            totalBorrowed[_token].elastic
        );

        feeAmount =
            (_amount * registry.borrowOpeningFee()) /
            _getManager().BORROW_FEE_PRECISION();
        _amount -= feeAmount;

        (totalBorrowed[_token], part) = totalBorrowed[_token].add(
            _amount,
            true
        );

        registry.setBorrowed(_holding, registry.borrowed(_holding) + part);

        share = toShare(IERC20(address(pandoraUSD)), part, false);
        registry.setBorrowedShares(
            _holding,
            registry.borrowedShares(_holding) + share
        );

        registry.updateExchangeRate();
        require(isSolvent(_token, _holding), "3009");

        if (!_mintDirectlyToUser) {
            pandoraUSD.mint(
                _holding,
                _amount,
                IERC20Metadata(_token).decimals()
            );
        } else {
            pandoraUSD.mint(
                _getHoldingManager().holdingUser(_holding),
                _amount,
                IERC20Metadata(_token).decimals()
            );
        }

        if (feeAmount > 0) {
            address feeAddr = IManager(managerContainer.manager()).feeAddress();
            require(feeAddr != address(0), "3060");
            pandoraUSD.mint(feeAddr, feeAmount, 18);
        }

        emit Borrowed(_holding, _amount, part, _mintDirectlyToUser);
    }

    /// @notice registers a repay operation
    /// @param _holding the holding for which repay is performed
    /// @param _token collateral token
    /// @param _part the repayed amount
    /// @param _repayFromUser if true it will burn from user's wallet, otherwise from user's holding
    /// @param _selfLiquidation if true, nothing is burned
    function repay(
        address _holding,
        address _token,
        uint256 _part,
        bool _repayFromUser,
        bool _selfLiquidation
    )
        external
        override
        onlyHoldingOrStrategyManager
        notPaused
        returns (uint256 amount)
    {
        require(shareRegistryInfo[_token].active, "1201");

        ISharesRegistry registry = ISharesRegistry(
            shareRegistryInfo[_token].deployedAt
        );
        require(registry.borrowed(_holding) > 0, "3011");
        require(_part > 0, "3012");

        totalBorrowed[_token].elastic = registry.accrue(
            totalBorrowed[_token].base,
            totalBorrowed[_token].elastic
        );

        (totalBorrowed[_token], amount) = totalBorrowed[_token].sub(
            _part,
            true
        );
        registry.setBorrowed(_holding, registry.borrowed(_holding) - _part);

        uint256 share = toShare(IERC20(address(pandoraUSD)), amount, true);
        registry.setBorrowedShares(
            _holding,
            registry.borrowedShares(_holding) - share
        );

        if (!_selfLiquidation) {
            if (!_repayFromUser) {
                pandoraUSD.burnFrom(
                    _holding,
                    _part,
                    IERC20Metadata(_token).decimals()
                );
            } else {
                pandoraUSD.burnFrom(
                    _getHoldingManager().holdingUser(_holding),
                    _part,
                    IERC20Metadata(_token).decimals()
                );
            }
        }

        emit Repayed(_holding, amount, _part, _repayFromUser, _selfLiquidation);
    }

    struct LiqTempData {
        RebaseLib.Rebase _totalBorrow;
        RebaseLib.Rebase _totals;
        uint256 _exchangeRate;
        uint256 borrowPart;
        uint256 borrowAmount;
        uint256 liquidationCollateralShare;
        uint256 protocolShare;
    }

    /// @notice registers a liquidation event
    /// @dev if user is solvent, there's no need for liqudation;
    /// @param _liquidatedHolding address of the holding which is being liquidated
    /// @param _token collateral token
    /// @param _holdingTo address of the holding which initiated the liquidation
    /// @param _burnFromUser if true, burns stablecoin from the liquidating user, not from the holding
    /// @return result true if liquidation happened
    /// @return collateralAmount the amount of collateral to move
    /// @return protocolFeeAmount the protocol fee amount
    function liquidate(
        address _liquidatedHolding,
        address _token,
        address _holdingTo,
        bool _burnFromUser
    )
        external
        override
        onlyHoldingOrStrategyManager
        notPaused
        returns (
            bool,
            uint256,
            uint256
        )
    {
        require(_liquidatedHolding != _holdingTo, "3013");
        ISharesRegistry registry = ISharesRegistry(
            shareRegistryInfo[_token].deployedAt
        );
        LiqTempData memory tempData;

        //steps:
        //1-update exchange rate and accrue
        //2-check borrowed amount
        //3-check collateral share
        //4-update user's collateral share
        //5-declare user solvent

        //the oracle call can fail but we still need to allow liquidations
        (, tempData._exchangeRate) = registry.updateExchangeRate();
        accrue(_token);

        tempData._totalBorrow = totalBorrowed[_token];
        tempData._totals = totals[IERC20(_token)];

        //nothing to do if user is already solvent; skip liquidation
        if (isSolvent(_token, _liquidatedHolding)) return (false, 0, 0);

        tempData.borrowPart = registry.borrowed(_liquidatedHolding);
        tempData.borrowAmount = tempData._totalBorrow.toElastic(
            tempData.borrowPart,
            false
        );

        tempData.protocolShare = tempData._totals.toBase(
            (tempData.borrowAmount *
                registry.liquidationMultiplier() *
                tempData._exchangeRate) /
                (_getManager().LIQUIDATION_MULTIPLIER_PRECISION() *
                    _getManager().EXCHANGE_RATE_PRECISION()),
            false
        );

        tempData.liquidationCollateralShare =
            registry.collateral(_liquidatedHolding) -
            tempData.protocolShare;

        //we move everything here as this gets fixed in HoldingManager after taking the `_maxLoss` parameter into account
        registry.updateLiquidatedCollateral(
            _liquidatedHolding,
            _holdingTo,
            tempData.liquidationCollateralShare + tempData.protocolShare
        );

        tempData._totalBorrow.elastic =
            tempData._totalBorrow.elastic -
            uint128(tempData.borrowAmount);
        tempData._totalBorrow.base =
            tempData._totalBorrow.base -
            uint128(tempData.borrowPart);
        totalBorrowed[_token] = tempData._totalBorrow;

        registry.setBorrowed(_liquidatedHolding, 0);
        registry.setBorrowedShares(_liquidatedHolding, 0);

        pandoraUSD.burnFrom(
            _burnFromUser
                ? IHoldingManager(_getManager().holdingManager()).holdingUser(
                    _holdingTo
                )
                : _holdingTo,
            tempData.borrowAmount,
            IERC20Metadata(_token).decimals()
        );

        emit Liquidated(
            _liquidatedHolding,
            _holdingTo,
            _token,
            tempData.liquidationCollateralShare,
            tempData.protocolShare,
            tempData.borrowAmount
        );

        return (
            true,
            totals[IERC20(_token)].toElastic(
                tempData.liquidationCollateralShare,
                false
            ),
            totals[IERC20(_token)].toElastic(tempData.protocolShare, false)
        );
    }

    /// @notice accures interest for token
    /// @param _token token's address
    function accrue(address _token) public notPaused {
        require(shareRegistryInfo[_token].active, "1201");
        totalBorrowed[_token].elastic = ISharesRegistry(
            shareRegistryInfo[_token].deployedAt
        ).accrue(totalBorrowed[_token].base, totalBorrowed[_token].elastic);
    }

    // -- Private methods --
    /// @notice sets registry and registry info
    function _setShareRegistry(
        address _registry,
        address _token,
        bool _active
    ) private {
        ShareRegistryInfo memory info;
        info.deployedAt = _registry;
        info.active = _active;
        shareRegistryInfo[_token] = info;
    }

    /// @notice used to update destination borrowed values when migrating collateral
    function _updateDestinationOnMigration(
        address _holding,
        ISharesRegistry registryTo,
        uint256 _borrowedTo,
        uint256 _borrowedSharesTo
    ) private {
        registryTo.setBorrowed(
            _holding,
            _borrowedTo + registryTo.borrowed(_holding)
        );
        registryTo.setBorrowedShares(
            _holding,
            _borrowedSharesTo + registryTo.borrowedShares(_holding)
        );

        (totalBorrowed[registryTo.token()], ) = totalBorrowed[
            registryTo.token()
        ].add(_borrowedTo, true);
    }

    /// @notice used to update source borrowed values when migrating collateral
    function _updateSourceOnMigration(
        address _holding,
        ISharesRegistry registryFrom,
        uint256 _borrowedFrom,
        uint256 _borrowedSharesFrom
    ) private {
        registryFrom.setBorrowed(
            _holding,
            registryFrom.borrowed(_holding) - _borrowedFrom
        );
        registryFrom.setBorrowedShares(
            _holding,
            registryFrom.borrowedShares(_holding) - _borrowedSharesFrom
        );
        (totalBorrowed[registryFrom.token()], ) = totalBorrowed[
            registryFrom.token()
        ].sub(_borrowedFrom, true);
    }

    /// @notice used to get migration values for borrowed amounts
    function _getMigrationData(
        address _holding,
        ISharesRegistry _from,
        address _to,
        uint256 _ratio
    )
        private
        view
        returns (
            uint256 _borrowedFrom,
            uint256 _borrowedSharesFrom,
            uint256 _borrowedTo,
            uint256 _borrowedSharesTo
        )
    {
        uint256 _tokenFromDecimals = IERC20Metadata(_from.token()).decimals();
        uint256 _tokenToDecimals = IERC20Metadata(_to).decimals();

        _borrowedFrom = (_from.borrowed(_holding) * _ratio) / 1e18;
        _borrowedSharesFrom = (_from.borrowedShares(_holding) * _ratio) / 1e18;

        if (_tokenFromDecimals > _tokenToDecimals) {
            _borrowedTo =
                _borrowedFrom /
                10**(_tokenFromDecimals - _tokenToDecimals);

            _borrowedSharesTo =
                _borrowedSharesFrom /
                10**(_tokenFromDecimals - _tokenToDecimals);
        } else {
            _borrowedTo =
                _borrowedFrom *
                10**(_tokenToDecimals - _tokenFromDecimals);

            _borrowedSharesTo =
                _borrowedSharesFrom *
                10**(_tokenToDecimals - _tokenFromDecimals);
        }
    }

    /// @notice used to remove collateral from holding
    function _removeCollateral(
        address _holding,
        address _token,
        uint256 _amount
    ) private returns (uint256 _share) {
        require(_amount > 0, "2004");

        //if share > collateral[user] we consider share = collateral[user]
        _share = totals[IERC20(_token)].toBase(_amount, false);

        ISharesRegistry(shareRegistryInfo[_token].deployedAt)
            .unregisterCollateral(
                _holding,
                _share,
                totalBorrowed[_token].base,
                totalBorrowed[_token].elastic
            );

        RebaseLib.Rebase memory total = totals[IERC20(_token)];

        uint256 amount = total.toElastic(_share, false);
        total.base = uint128(_share) > total.base
            ? 0
            : total.base - uint128(_share);
        total.elastic = uint128(amount) > total.elastic
            ? 0
            : total.elastic - uint128(amount);
        totals[IERC20(_token)] = total;
    }

    /// @notice used to accrue collateral
    function _addCollateral(
        address _holding,
        address _token,
        uint256 _amount
    ) private returns (uint256 _share) {
        require(_amount > 0, "2001");

        _share = totals[IERC20(_token)].toBase(_amount, false);

        ISharesRegistry(shareRegistryInfo[_token].deployedAt)
            .registerCollateral(_holding, _share);

        RebaseLib.Rebase memory total = totals[IERC20(_token)];

        total.base = total.base + uint128(_share);
        require(total.base >= _getManager().MINIMUM_SHARE_BALANCE(), "3028");

        total.elastic = total.elastic + uint128(_amount);
        totals[IERC20(_token)] = total;
    }

    function _getSolvencyRatio(address _holding, ISharesRegistry registry)
        private
        view
        returns (uint256)
    {
        uint256 _colRate = registry.collateralizationRate();
        uint256 _exchangeRate = registry.exchangeRate();

        uint256 _share = ((1e18 *
            registry.collateral(_holding) *
            _exchangeRate *
            _colRate) /
            (_getManager().EXCHANGE_RATE_PRECISION() *
                _getManager().COLLATERALIZATION_PRECISION())) / 1e18;

        return toAmount(IERC20(registry.token()), _share, false);
    }

    function _getManager() private view returns (IManager) {
        return IManager(managerContainer.manager());
    }

    function _getHoldingManager() private view returns (IHoldingManager) {
        return IHoldingManager(_getManager().holdingManager());
    }

    // -- modifiers --
    modifier onlyHoldingOrStrategyManager() {
        require(
            msg.sender == _getManager().holdingManager() ||
                msg.sender == _getManager().strategyManager(),
            "1000"
        );
        _;
    }

    modifier notPaused() {
        require(!paused, "1200");
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

library OperationsLib {
    uint256 internal constant FEE_FACTOR = 10000;

    function getFeeAbsolute(uint256 amount, uint256 fee)
        internal
        pure
        returns (uint256)
    {
        return (amount * fee) / FEE_FACTOR;
    }

    function getRatio(
        uint256 numerator,
        uint256 denominator,
        uint256 precision
    ) internal pure returns (uint256) {
        if (numerator == 0 || denominator == 0) {
            return 0;
        }
        uint256 _numerator = numerator * 10**(precision + 1);
        uint256 _quotient = ((_numerator / denominator) + 5) / 10;
        return (_quotient);
    }

    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x095ea7b3, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "OperationsLib::safeApprove: approve failed"
        );
    }

    function getRevertMsg(bytes memory _returnData)
        internal
        pure
        returns (string memory)
    {
        // If the _res length is less than 68, then the transaction failed silently (without a revert message)
        if (_returnData.length < 68) return "Transaction reverted silently";
        // solhint-disable-next-line no-inline-assembly
        assembly {
            // Slice the sighash.
            _returnData := add(_returnData, 0x04)
        }
        return abi.decode(_returnData, (string)); // All that remains is the revert string
    }
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

    /// @notice emitted when the USDC address is changed
    event USDCAddressUpdated(
        address indexed oldAddress,
        address indexed newAddress
    );

    /// @notice emitted when the first deposit amount
    event FirstDepositAmountUpdated(
        uint256 indexed oldAmount,
        uint256 indexed newAmount
    );

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

    /// @notice USDC address
    // solhint-disable-next-line func-name-mixedcase
    function USDC() external view returns (address);

    /// @notice Amount necessary to deposit for a user to grab a holding
    function firstDepositAmount() external view returns (uint256);

    /// @dev should be less than exchange rate precision due to optimization in math
    // solhint-disable-next-line func-name-mixedcase
    function COLLATERALIZATION_PRECISION() external view returns (uint256);

    /// @notice exchange rate precision
    // solhint-disable-next-line func-name-mixedcase
    function EXCHANGE_RATE_PRECISION() external view returns (uint256);

    /// @notice used in liquidation operation
    // solhint-disable-next-line func-name-mixedcase
    function LIQUIDATION_MULTIPLIER_PRECISION() external view returns (uint256);

    /// @notice precision used to calculate max accepted loss in case of liquidation
    // solhint-disable-next-line func-name-mixedcase
    function LIQUIDATION_MAX_LOSS_PRECISION() external view returns (uint256);

    /// @notice fee taken when a stablecoin borrow operation is done
    /// @dev can be 0
    // solhint-disable-next-line func-name-mixedcase
    function BORROW_FEE_PRECISION() external view returns (uint256);

    /// @notice share balance for token
    /// @dev to prevent the ratio going off
    // solhint-disable-next-line func-name-mixedcase
    function MINIMUM_SHARE_BALANCE() external view returns (uint256);

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

    /// @notice sets the amount necessary to deposit for a user to grab a holding
    /// @param _amount amount of USDC that will be deposited
    function setFirstDepositAmount(uint256 _amount) external;

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

import "./IManagerContainer.sol";

interface IHoldingManager {
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
        address indexed token,
        uint256 amount
    );

    /// @notice event emitted when a borrow action was performed
    event Borrowed(
        address indexed holding,
        address indexed token,
        uint256 amount,
        uint256 fee,
        bool mintToUser
    );
    /// @notice event emitted when a repay action was performed
    event Repayed(
        address indexed holding,
        address indexed token,
        uint256 amount,
        bool repayFromUser
    );

    /// @notice event emitted when collateral is retrieved from a strategy in case of liquidation
    event CollateralRetrieved(
        address indexed token,
        address indexed holding,
        address indexed strategy,
        uint256 collateral
    );
    /// @notice event emitted when collateral is moved from liquidated holding to liquidating holding
    event CollateralMoved(
        address indexed token,
        address indexed holdingFrom,
        address indexed holdingTo,
        uint256 amount
    );

    /// @notice event emitted when fee is moved from liquidated holding to fee addres
    event CollateralFeeTaken(
        address token,
        address holdingFrom,
        address to,
        uint256 amount
    );

    /// @notice event emitted when self liquidation happened
    event SelfLiquidated(
        address indexed holding,
        address indexed token,
        uint256 amount,
        uint256 collateralUsed
    );

    /// @notice event emitted when borrow event happened for multiple users
    event BorrowedMultiple(
        address indexed holding,
        uint256 length,
        bool mintedToUser
    );
    /// @notice event emitted when a multiple repay operation happened
    event RepayedMultiple(
        address indexed holding,
        uint256 length,
        bool repayedFromUser
    );
    /// @notice event emitted when pause state is changed
    event PauseUpdated(bool oldVal, bool newVal);

    /// @notice data used for multiple borrow
    struct BorrowOrRepayData {
        address token;
        uint256 amount;
    }
    /// @notice properties used for self liquidation
    /// @dev self liquidation is when a user swaps collateral with the stablecoin
    struct SelfLiquidateData {
        address[] _strategies;
        bytes[] _strategiesData;
    }

    /// @notice properties used for holding liquidation
    struct LiquidateData {
        address[] _strategies;
        bytes[] _strategiesData;
        uint256 _maxLoss;
        bool _burnFromUser;
    }

    /// @notice returns the pause state of the contract
    function paused() external view returns (bool);

    /// @notice sets a new value for pause state
    /// @param _val the new value
    function setPaused(bool _val) external;

    /// @notice returns user for holding
    function holdingUser(address holding) external view returns (address);

    /// @notice returns holding for user
    function userHolding(address _user) external view returns (address);

    /// @notice returns true if holding was created
    function isHolding(address _holding) external view returns (bool);

    /// @notice interface of the manager container contract
    function managerContainer() external view returns (IManagerContainer);

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

    /// @notice deposits a whitelisted token into the holding
    /// @param _token token's address
    /// @param _amount amount to deposit
    function deposit(address _token, uint256 _amount) external;

    /// @notice withdraws a token from the contract
    /// @param _token token user wants to withdraw
    /// @param _amount withdrawal amount
    function withdraw(address _token, uint256 _amount) external;

    /// @notice exchanges an existing token with a whitelisted one
    /// @param _ammId selected AMM id
    /// @param _tokenIn token available in the contract
    /// @param _tokenOut token resulting from the swap operation
    /// @param _amountIn exchange amount
    /// @param _minAmountOut min amount of tokenOut to receive when the swap is performed
    /// @param _data specific amm data
    /// @return the amount obtained
    function exchange(
        uint256 _ammId,
        address _tokenIn,
        address _tokenOut,
        uint256 _amountIn,
        uint256 _minAmountOut,
        bytes calldata _data
    ) external returns (uint256);

    /// @notice mints stablecoin to the user or to the holding contract
    /// @param _token collateral token
    /// @param _amount the borrowed amount
    function borrow(
        address _token,
        uint256 _amount,
        bool _mintDirectlyToUser
    )
        external
        returns (
            uint256 part,
            uint256 share,
            uint256 fee
        );

    /// @notice borrows from multiple assets
    /// @param _data struct containing data for each collateral type
    /// @param _mintDirectlyToUser if true mints to user instead of holding
    function borrowMultiple(
        BorrowOrRepayData[] calldata _data,
        bool _mintDirectlyToUser
    ) external;

    /// @notice registers a repay operation
    /// @param _token collateral token
    /// @param _amount the repayed amount
    /// @param _repayFromUser if true it will burn from user's wallet, otherwise from user's holding
    function repay(
        address _token,
        uint256 _amount,
        bool _repayFromUser
    ) external returns (uint256 amount);

    /// @notice repays multiple assets
    /// @param _data struct containing data for each collateral type
    /// @param _repayFromUser if true it will burn from user's wallet, otherwise from user's holding
    function repayMultiple(
        BorrowOrRepayData[] calldata _data,
        bool _repayFromUser
    ) external;

    /// @notice method used to pay stablecoin debt by using own collateral
    /// @param _token token to be used as collateral
    /// @param _amount the amount of stablecoin to repay
    function selfLiquidate(
        address _token,
        uint256 _amount,
        SelfLiquidateData calldata _data
    ) external returns (uint256);

    /// @notice liquidate user
    /// @dev if user is solvent liquidation won't work
    /// @param _liquidatedHolding address of the holding which is being liquidated
    /// @param _token collateral token
    /// @param _data liquidation data
    /// @return result true if liquidation happened
    /// @return collateralAmount the amount of collateral to move
    /// @return protocolFeeAmount the protocol fee amount
    function liquidate(
        address _liquidatedHolding,
        address _token,
        LiquidateData calldata _data
    )
        external
        returns (
            bool result,
            uint256 collateralAmount,
            uint256 protocolFeeAmount
        );

    /// @notice creates holding and leaves it available to be assigned
    function createHolding() external returns (address);

    /// @notice creates holding at assigns it to the user
    function createHoldingForMyself() external returns (address);

    /// @notice assigns a new user to an existing holding
    /// @dev callable by owner only
    /// @param _user new user's address
    function assignHolding(address _user) external;

    /// @notice user grabs an existing holding, with a deposit
    function assignHoldingToMyself() external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../libraries/RebaseLib.sol";

import "./IManagerContainer.sol";
import "../stablecoin/IPandoraUSD.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title Interface for stables manager
/// @author Cosmin Grigore (@gcosmintech)
interface IStablesManager {
    /// @notice event emitted when collateral was registered
    event AddedCollateral(
        address indexed user,
        address indexed token,
        uint256 amount
    );
    /// @notice event emitted when collateral was registered by the owner
    event ForceAddedCollateral(
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

    /// @notice event emitted when collateral was unregistered by the owner
    event ForceRemovedCollateral(
        address indexed user,
        address indexed token,
        uint256 amount
    );
    /// @notice event emitted when a borrow action was performed
    event Borrowed(
        address indexed user,
        uint256 amount,
        uint256 part,
        bool mintToUser
    );
    /// @notice event emitted when a repay action was performed
    event Repayed(
        address indexed user,
        uint256 amount,
        uint256 part,
        bool repayFromUser,
        bool selfLiquidation
    );

    /// @notice event emitted when a registry is added
    event RegistryAdded(address indexed token, address indexed registry);

    /// @notice event emitted when a registry is updated
    event RegistryUpdated(address indexed token, address indexed registry);

    /// @notice event emmitted when a liquidation operation happened
    event Liquidated(
        address indexed liquidatedUser,
        address indexed liquidatingUser,
        address indexed token,
        uint256 obtainedCollateral,
        uint256 protocolCollateral,
        uint256 liquidatedAmount
    );

    /// @notice event emitted when data is migrated to another collateral token
    event CollateralMigrated(
        address indexed holding,
        address indexed tokenFrom,
        address indexed tokenTo,
        uint256 borrowedAmount,
        uint256 borrowedShares,
        uint256 collateralTo
    );

    /// @notice emitted when an existing strategy info is updated
    event RegistryConfigUpdated(address indexed registry, bool active);

    struct ShareRegistryInfo {
        bool active;
        address deployedAt;
    }

    /// @notice event emitted when pause state is changed
    event PauseUpdated(bool oldVal, bool newVal);

    /// @notice emitted when the PandoraUSD address is updated
    event StableAddressUpdated(address indexed _old, address indexed _new);

    /// @notice returns the pause state of the contract
    function paused() external view returns (bool);

    /// @notice sets a new value for pause state
    /// @param _val the new value
    function setPaused(bool _val) external;

    /// @notice returns collateral amount
    /// @param _token collateral token
    /// @param _amount stablecoin amount
    function computeNeededCollateral(address _token, uint256 _amount)
        external
        view
        returns (uint256 result);

    /// @notice sets the PandoraUSD address
    /// @param _newAddr contract's address
    function setPandoraUSD(address _newAddr) external;

    /// @notice share -> info
    function shareRegistryInfo(address _registry)
        external
        view
        returns (bool, address);

    /// @notice total borrow per token
    function totalBorrowed(address _token)
        external
        view
        returns (uint128 elastic, uint128 base);

    /// @notice returns totals, base and elastic
    function totals(IERC20 token) external view returns (uint128, uint128);

    /// @notice interface of the manager container contract
    function managerContainer() external view returns (IManagerContainer);

    /// @notice Pandora project stablecoin address
    function pandoraUSD() external view returns (IPandoraUSD);

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
    /// @param _holding the user address
    /// @return true/false
    function isSolvent(address _token, address _holding)
        external
        view
        returns (bool);

    /// @notice get liquidation info for holding and token
    /// @dev returns borrowed amount, collateral amount, collateral's value ratio, current borrow ratio, solvency status; colRatio needs to be >= borrowRaio
    /// @param _holding address of the holding to check for
    /// @param _token address of the token to check for
    function getLiquidationInfo(address _holding, address _token)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            bool
        );

    /// @notice migrates collateral and share to a new registry
    /// @param _holding the holding for which collateral is added
    /// @param _tokenFrom collateral token source
    /// @param _tokenTo collateral token destination
    /// @param _collateralFrom collateral amount to be removed from source
    /// @param _collateralTo collateral amount to be added to destination
    function migrateDataToRegistry(
        address _holding,
        address _tokenFrom,
        address _tokenTo,
        uint256 _collateralFrom,
        uint256 _collateralTo
    ) external;

    /// @notice accrues collateral for holding
    /// @dev callable by the owner
    /// @param _holding the holding for which collateral is added
    /// @param _token collateral token
    /// @param _amount amount of collateral
    function forceAddCollateral(
        address _holding,
        address _token,
        uint256 _amount
    ) external;

    /// @notice registers new collateral
    /// @param _holding the holding for which collateral is added
    /// @param _token collateral token
    /// @param _amount amount of collateral
    function addCollateral(
        address _holding,
        address _token,
        uint256 _amount
    ) external;

    /// @notice removes collateral for holding
    /// @dev callable by the owner
    /// @param _holding the holding for which collateral is removed
    /// @param _token collateral token
    /// @param _amount amount of collateral
    function forceRemoveCollateral(
        address _holding,
        address _token,
        uint256 _amount
    ) external;

    /// @notice unregisters collateral
    /// @param _holding the holding for which collateral is added
    /// @param _token collateral token
    /// @param _amount amount of collateral
    function removeCollateral(
        address _holding,
        address _token,
        uint256 _amount
    ) external;

    /// @notice mints stablecoin to the user
    /// @param _holding the holding for which collateral is added
    /// @param _token collateral token
    /// @param _amount the borrowed amount
    function borrow(
        address _holding,
        address _token,
        uint256 _amount,
        bool _mintDirectlyToUser
    )
        external
        returns (
            uint256 part,
            uint256 share,
            uint256 feeAmount
        );

    /// @notice registers a repay operation
    /// @param _holding the holding for which repay is performed
    /// @param _token collateral token
    /// @param _part the repayed amount
    /// @param _repayFromUser if true it will burn from user's wallet, otherwise from user's holding
    /// @param _selfLiquidation if true, nothing is burned
    function repay(
        address _holding,
        address _token,
        uint256 _part,
        bool _repayFromUser,
        bool _selfLiquidation
    ) external returns (uint256 amount);

    /// @notice registers a liquidation event
    /// @dev if user is solvent, there's no need for liqudation;
    /// @param _liquidatedHolding address of the holding which is being liquidated
    /// @param _token collateral token
    /// @param _holdingTo address of the holding which initiated the liquidation
    /// @param _burnFromUser if true, burns stablecoin from the liquidating user, not from the holding
    /// @return result true if liquidation happened
    /// @return collateralAmount the amount of collateral to move
    /// @return protocolFeeAmount the protocol fee amount
    function liquidate(
        address _liquidatedHolding,
        address _token,
        address _holdingTo,
        bool _burnFromUser
    )
        external
        returns (
            bool,
            uint256,
            uint256
        );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../core/IManagerContainer.sol";

interface IPandoraUSD {
    /// @notice event emitted when the mint limit is updated
    event MintLimitUpdated(uint256 oldLimit, uint256 newLimit);

    /// @notice sets the manager address
    /// @param _limit the new mint limit
    function updateMintLimit(uint256 _limit) external;

    /// @notice interface of the manager container contract
    function managerContainer() external view returns (IManagerContainer);

    /// @notice returns the max mint limitF
    function mintLimit() external view returns (uint256);

    /// @notice returns total minted so far
    function totalMinted() external view returns (uint256);

    /// @notice mint tokens
    /// @dev no need to check if '_to' is a valid address if the '_mint' method is used
    /// @param _to address of the user receiving minted tokens
    /// @param _amount the amount to be minted
    /// @param _decimals amount's decimals
    function mint(
        address _to,
        uint256 _amount,
        uint8 _decimals
    ) external;

    /// @notice burns token from sender
    /// @param _amount the amount of tokens to be burnt
    /// @param _decimals amount's decimals
    function burn(uint256 _amount, uint8 _decimals) external;

    /// @notice burns token from an address
    /// @param _user the user to burn it from
    /// @param _amount the amount of tokens to be burnt
    /// @param _decimals amount's decimals
    function burnFrom(
        address _user,
        uint256 _amount,
        uint8 _decimals
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../oracle/IOracle.sol";
import "../core/IManagerContainer.sol";

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
    /// @notice event emitted when the borrowing opening fee is updated
    event BorrowingOpeningFeeUpdated(uint256 oldVal, uint256 newVal);
    /// @notice event emitted when the liquidation mutiplier is updated
    event LiquidationMultiplierUpdated(uint256 oldVal, uint256 newVal);
    /// @notice event emitted when the collateralization rate is updated
    event CollateralizationRateUpdated(uint256 oldVal, uint256 newVal);
    /// @notice event emitted when fees are accrued
    event FeesAccrued(uint256 amount);
    /// @notice event emitted when accrue was called
    event Accrued(uint256 updatedTotalBorrow, uint256 extraAmount);
    /// @notice oracle data updated
    event OracleDataUpdated();
    /// @notice event emitted when borrowed amount is set
    event BorrowedSet(address _holding, uint256 oldVal, uint256 newVal);
    /// @notice event emitted when borrowed shares amount is set
    event BorrowedSharesSet(address _holding, uint256 oldVal, uint256 newVal);

    /// @notice accure info data
    struct AccrueInfo {
        uint64 lastAccrued;
        uint128 feesEarned;
        // solhint-disable-next-line var-name-mixedcase
        uint64 INTEREST_PER_SECOND;
    }

    /// @notice exchange and interest rate tracking
    /// this is 'cached' here because calls to oracles can be very expensive
    function exchangeRate() external view returns (uint256);

    /// @notice borrowed amount for holding; holding > amount
    function borrowed(address _holding) external view returns (uint256);

    /// @notice borrowed shares for holding; holding > amount
    function borrowedShares(address _holding) external view returns (uint256);

    /// @notice info about the accrued data
    function accrueInfo()
        external
        view
        returns (
            uint64,
            uint128,
            uint64
        );

    /// @notice current owner
    function owner() external view returns (address);

    /// @notice possible new owner
    /// @dev if different than `owner` an ownership transfer is in  progress and has to be accepted by the new owner
    function temporaryOwner() external view returns (address);

    /// @notice interface of the manager container contract
    function managerContainer() external view returns (IManagerContainer);

    /// @notice returns the token address for which this registry was created
    function token() external view returns (address);

    /// @notice oracle contract associated with this share registry
    function oracle() external view returns (IOracle);

    /// @notice borrowing fee amount
    // solhint-disable-next-line func-name-mixedcase
    function borrowOpeningFee() external view returns (uint256);

    /// @notice collateralization rate for token
    // solhint-disable-next-line func-name-mixedcase
    function collateralizationRate() external view returns (uint256);

    // solhint-disable-next-line func-name-mixedcase
    function liquidationMultiplier() external view returns (uint256);

    /// @notice returns the collateral shares for user
    /// @param _user the address for which the query is performed
    function collateral(address _user) external view returns (uint256);

    /// @notice sets a new value for borrowed
    /// @param _holding the address of the user
    /// @param _newVal the new amount
    function setBorrowed(address _holding, uint256 _newVal) external;

    /// @notice sets a new value for borrowedShares
    /// @param _holding the address of the user
    /// @param _newVal the new amount
    function setBorrowedShares(address _holding, uint256 _newVal) external;

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
    /// @param _holding the user's address for which collateral is registered
    /// @param _share amount of shares
    function registerCollateral(address _holding, uint256 _share) external;

    /// @notice unregisters collateral for token
    /// @param _holding the user's address for which collateral is registered
    /// @param _share amount of shares
    /// @param _totalBorrowBase total borrow amount
    /// @param _totalBorrowElastic total borrow shares
    function unregisterCollateral(
        address _holding,
        uint256 _share,
        uint256 _totalBorrowBase,
        uint256 _totalBorrowElastic
    ) external;

    /// @notice initiates the ownership transferal
    /// @param _newOwner the address of the new owner
    function transferOwnership(address _newOwner) external;

    /// @notice finalizes the ownership transferal process
    /// @dev must be called after `transferOwnership` was executed successfully, by the new temporary onwer
    function acceptOwnership() external;
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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
pragma solidity ^0.8.0;

interface IManagerContainer {
    /// @notice emitted when the strategy manager is set
    event ManagerUpdated(
        address indexed oldAddress,
        address indexed newAddress
    );

    /// @notice returns manager address
    function manager() external view returns (address);

    /// @notice Updates the manager address
    /// @param _address The address of the manager
    function updateManager(address _address) external;

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IOracle {
    /// @notice Get the latest exchange rate.
    /// @dev MAKE SURE THIS HAS 10^18 decimals
    /// @param data Usually abi encoded, implementation specific data that contains information and arguments to & about the oracle.
    /// For example:
    /// (string memory collateralSymbol, string memory assetSymbol, uint256 division) = abi.decode(data, (string, string, uint256));
    /// @return success if no valid (recent) rate is available, return false else true.
    /// @return rate The rate of the requested asset / pair / pool.
    function get(bytes calldata data)
        external
        returns (bool success, uint256 rate);

    /// @notice Check the last exchange rate without any state changes.
    /// @param data Usually abi encoded, implementation specific data that contains information and arguments to & about the oracle.
    /// For example:
    /// (string memory collateralSymbol, string memory assetSymbol, uint256 division) = abi.decode(data, (string, string, uint256));
    /// @return success if no valid (recent) rate is available, return false else true.
    /// @return rate The rate of the requested asset / pair / pool.
    function peek(bytes calldata data)
        external
        view
        returns (bool success, uint256 rate);

    /// @notice Check the current spot exchange rate without any state changes. For oracles like TWAP this will be different from peek().
    /// @param data Usually abi encoded, implementation specific data that contains information and arguments to & about the oracle.
    /// For example:
    /// (string memory collateralSymbol, string memory assetSymbol, uint256 division) = abi.decode(data, (string, string, uint256));
    /// @return rate The rate of the requested asset / pair / pool.
    function peekSpot(bytes calldata data) external view returns (uint256 rate);

    /// @notice Returns a human readable (short) name about this oracle.
    /// @param data Usually abi encoded, implementation specific data that contains information and arguments to & about the oracle.
    /// For example:
    /// (string memory collateralSymbol, string memory assetSymbol, uint256 division) = abi.decode(data, (string, string, uint256));
    /// @return (string) A human readable symbol name about this oracle.
    function symbol(bytes calldata data) external view returns (string memory);

    /// @notice Returns a human readable name about this oracle.
    /// @param data Usually abi encoded, implementation specific data that contains information and arguments to & about the oracle.
    /// For example:
    /// (string memory collateralSymbol, string memory assetSymbol, uint256 division) = abi.decode(data, (string, string, uint256));
    /// @return (string) A human readable name about this oracle.
    function name(bytes calldata data) external view returns (string memory);
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