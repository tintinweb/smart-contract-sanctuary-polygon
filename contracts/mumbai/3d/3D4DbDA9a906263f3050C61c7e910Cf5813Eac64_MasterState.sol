//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./interfaces/IMaster.sol";
import "./interfaces/IMasterState.sol";
import "./MasterEvents.sol";
import "./MasterAdmin.sol";
import "./MasterMessageHandler.sol";
import "./MasterInternals.sol";

contract MasterState is
    IMaster,
    IMasterState,
    MasterEvents,
    MasterAdmin,
    MasterMessageHandler,
    MasterInternals
{

    function initialize(address _middleLayer, address _ecc) external onlyOwner() {
        middleLayer = IMiddleLayer(_middleLayer);
        ecc = IECC(_ecc);
        borrowIndex = 1e18;
        accrualBlockNumber = block.number;
    }

    function borrowBalanceStored(
        address account
    ) external override view returns (uint256, uint256) {
        return _borrowBalanceStored(account);
    }

    function accrueInterest() external override {
        _accrueInterest();
    }

    function enterMarkets(address[] calldata tokens, uint256[] calldata chainIds)
        external
        override
        returns (bool[] memory r)
    {
        uint256 tokensLen = tokens.length;
        uint256 chainIdLen = chainIds.length;

        require(tokensLen == chainIdLen, "ARRAY_LENGTH");

        r = new bool[](tokensLen);
        for (uint256 i = 0; i < tokensLen; i++) {
            address token = tokens[i];
            uint256 chainId = chainIds[i];

            r[i] = _addToMarket(token, chainId, msg.sender);
        }
    }

    function getAccountAssets(address accountAddress)
        external
        view
        override
        returns (CollateralMarket[] memory)
    {
        return accountAssets[accountAddress];
    }

    function exchangeRateStored() external view override returns (uint256) {
        return _exchangeRateStored();
    }

    function getAccountLiquidity(address account)
        external
        override
        view
        returns (uint256, uint256)
    {

        return _getHypotheticalAccountLiquidityRedeem(account, address(0), 0);
    }

    function liquidateCalculateSeizeTokens(
        address pTokenCollateral,
        uint256 chainId,
        uint256 actualRepayAmount
    ) external view override returns (uint256) {
        return
            _liquidateCalculateSeizeTokens(
                pTokenCollateral,
                chainId,
                actualRepayAmount
            );
    }

    function liquidateBorrowAllowed(
        address pTokenCollateral,
        address borrower,
        uint256 chainId,
        uint256 repayAmount
    ) external view override returns (bool) {
        return
            _liquidateBorrowAllowed(
                pTokenCollateral,
                borrower,
                chainId,
                repayAmount
            );
    }

    function liquidateBorrow(
        address pTokenCollateral,
        address borrower,
        uint256 chainId,
        uint256 repayAmount
    ) external override payable returns (bool) {
        _accrueInterest();

        return _liquidateBorrow(pTokenCollateral, borrower, chainId, repayAmount);
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "../MasterStorage.sol";

abstract contract IMaster is MasterStorage {
    /**
     * @notice Return the borrow balance of account based on stored data
     * @param account The address whose balance should be calculated
     * @return (error code, the calculated balance or 0 if error code is non-zero)
     */
    function _borrowBalanceStored(address account)
        internal
        view
        virtual
        returns (uint256, uint256);

    function _accrueInterest() internal virtual;

    /**
     * @notice Add the market to the borrower's "assets in" for liquidity calculations
     * @param token The market to enter
     * @param chainId The chainId
     * @param borrower The address of the account to modify
     */
    function _addToMarket(
        address token,
        uint256 chainId,
        address borrower
    ) internal virtual returns (bool);

    /**
     * @notice Get a snapshot of the account's balance, and the cached exchange rate
     * @dev This is used by risk engine to more efficiently perform liquidity checks.
     * @param user Address of the account to snapshot
     * @param chainId metadata of the ptoken
     * @param token metadata of the ptoken
     * @return (possible error, token balance, exchange rate)
     */
    function _getAccountSnapshot(
        address user,
        uint256 chainId,
        address token
    ) internal view virtual returns (uint256, uint256);

    /**
     * @notice Calculates the exchange rate from the underlying to the PToken
     * @dev This function does not accrue interest before calculating the exchange rate
     * @return (calculated exchange rate scaled by 1e18)
     */
    function _exchangeRateStored() internal view virtual returns (uint256);

    function _getHypotheticalAccountLiquidity(
        address account,
        address pTokenModify,
        uint256 redeemTokens,
        uint256 borrowAmount
    ) internal view virtual returns (uint256, uint256);

    /**
     * @notice The liquidator liquidates the borrowers collateral.
     *  The collateral seized is transferred to the liquidator.
     * @param borrower The borrower of this pToken to be liquidated
     * @param pTokenCollateral The market in which to seize collateral from the borrower
     * @param repayAmount The amount of the underlying borrowed asset to repay
     * @return (uint, uint) An error code (0=success, otherwise a failure, see ErrorReporter.sol), and the actual repayment amount.
     */
    function _liquidateBorrow(
        address pTokenCollateral,
        address borrower,
        uint256 chainId,
        uint256 repayAmount
    ) internal virtual returns (bool);

    function _liquidateCalculateSeizeTokens(
        address pTokenCollateral,
        uint256 chainId,
        uint256 actualRepayAmount
    ) internal view virtual returns (uint256);

    function _liquidateBorrowAllowed(
        address pTokenCollateral,
        address borrower,
        uint256 chainId,
        uint256 repayAmount
    ) internal view virtual returns (bool);

    function satelliteLiquidateBorrow(
        uint256 chainId,
        address borrower,
        address liquidator,
        uint256 seizeTokens,
        address pTokenCollateral
    ) internal virtual;
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "../MasterStorage.sol";

abstract contract IMasterState is MasterStorage {

    function borrowBalanceStored(
        address account
    ) external virtual returns (uint256, uint256);

    function accrueInterest() external virtual;

    function enterMarkets(
        address[] calldata tokens,
        uint256[] calldata chainIds
    ) external virtual returns (bool[] memory r);

    function getAccountAssets(
        address accountAddress
    ) external virtual returns (CollateralMarket[] memory);

    function exchangeRateStored() external virtual returns (uint256);

    function getAccountLiquidity(
        address account
    ) external virtual returns (uint256, uint256);

    function liquidateCalculateSeizeTokens(
        address pTokenCollateral,
        uint256 chainId,
        uint256 actualRepayAmount
    ) external virtual returns (uint256);

    function liquidateBorrowAllowed(
        address pTokenCollateral,
        address borrower,
        uint256 chainId,
        uint256 repayAmount
    ) external virtual returns (bool);

    function liquidateBorrow(
        address pTokenCollateral,
        address borrower,
        uint256 chainId,
        uint256 repayAmount
    ) external virtual payable returns (bool);

    function addChain(uint256 chainId) external virtual;

    function changeOwner(address newOwner) external virtual;

    function changeMiddleLayer(
        IMiddleLayer oldMid,
        IMiddleLayer newMid
    ) external virtual;

    /**
     * @notice Add the market to the markets mapping and set it as listed
     * @dev Admin function to set isListed and add support for the market
     * @param token The address of the market (token) to list
     * @param chainId corresponding chain of the market
     */
    function supportMarket(
        address token,
        uint256 chainId,
        uint256 initialExchangeRate_,
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        address underlying_
    ) external virtual;

    function changeLiqIncentive(uint256 newLiqIncentive) external virtual;

    function changeCloseFactor(uint256 newCloseFactor) external virtual;

    function changeCollateralFactor(uint256 newCollateralFactor) external virtual;

    function changeProtocolSeizeShare(uint256 newProtocolSeizeShare) external virtual;

    function setPUSD(address newPUSD) external virtual;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

abstract contract MasterEvents {
    event CollateralBalanceAdded(
        address indexed user,
        uint256 chainId,
        uint256 prevAmount,
        uint256 newAmount
    );

    event CollateralChanged(
        address indexed user,
        uint256 indexed chainId,
        uint256 prevAmount,
        uint256 newAmount
    );

    event LoanAdded(
        address indexed user,
        uint256 indexed chainId,
        uint256 prevAmount,
        uint256 newAmount
    );

    event LoanChanged(
        address indexed user,
        uint256 indexed chainId,
        uint256 prevAmount,
        uint256 newAmount
    );

    event LoanRepaid(
        address indexed user,
        uint256 indexed chainId,
        uint256 prevAmount,
        uint256 newAmount
    );

    /// @notice Emitted when an account enters a deposit market
    event MarketEntered(uint256 chainId, address token, address borrower);

    event ReceiveFromChain(uint256 _srcChainId, address _fromAddress);

    /// @notice Event emitted when a borrow is liquidated
    event LiquidateBorrow(
        address liquidator,
        address borrower,
        uint256 repayAmount,
        address cTokenCollateral,
        uint256 seizeTokens
    );
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./MasterModifiers.sol";
import "./interfaces/IMaster.sol";
import "./interfaces/IMasterState.sol";

abstract contract MasterAdmin is IMaster, IMasterState, MasterModifiers {
    function addChain(uint256 chainId) external override onlyOwner {
        chains.push(chainId);
    }

    function changeOwner(address newOwner) external override onlyOwner {
        admin = newOwner;
    }

    function changeMiddleLayer(
        IMiddleLayer oldMid,
        IMiddleLayer newMid
    ) external override onlyOwner {
        require(middleLayer == oldMid, "INVALID_MIDDLE_LAYER");
        middleLayer = newMid;
    }

    /**
     * @notice Add the market to the markets mapping and set it as listed
     * @dev Admin function to set isListed and add support for the market
     * @param token The address of the market (token) to list
     * @param chainId corresponding chain of the market
     */
    function supportMarket(
        address token,
        uint256 chainId,
        uint256 initialExchangeRate_,
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        address underlying_
    ) external override onlyOwner {
        require(!markets[chainId][token].isListed, "SUPPORT_MARKET_EXISTS");

        markets[chainId][token].isListed = true;
        markets[chainId][token].collateralFactor = 80e6;
        markets[chainId][token].initialExchangeRate = initialExchangeRate_;
        markets[chainId][token].name = name_;
        markets[chainId][token].symbol = symbol_;
        markets[chainId][token].decimals = decimals_;
        markets[chainId][token].underlying = underlying_;

        for (uint256 i; i < allMarkets.length; i++) {
            require(
                allMarkets[i].token != token &&
                    allMarkets[i].chainId != chainId,
                "MARKET_EXISTS"
            );
        }
        CollateralMarket memory market;

        market.token = token;
        market.chainId = chainId;

        allMarkets.push(market);

        // emit MarketListed(token);
    }

    function changeLiqIncentive(uint256 newLiqIncentive) external override onlyOwner {
        liquidityIncentive = newLiqIncentive;
    }

    function changeCloseFactor(uint256 newCloseFactor) external override onlyOwner {
        closeFactor = newCloseFactor;
    }

    function changeCollateralFactor(uint256 newCollateralFactor)
        external
        override
        onlyOwner
    {
        collateralFactor = newCollateralFactor;
    }

    function changeProtocolSeizeShare(uint256 newProtocolSeizeShare)
        external
        override
        onlyOwner
    {
        protocolSeizeShare = newProtocolSeizeShare;
    }

    function setPUSD(address newPUSD) external override onlyOwner() {
        pusd = newPUSD;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "../interfaces/IHelper.sol";

import "./interfaces/IMaster.sol";
import "./MasterModifiers.sol";
import "./MasterEvents.sol";

abstract contract MasterMessageHandler is IMaster, MasterModifiers, MasterEvents {
    function satelliteLiquidateBorrow(
        uint256 chainId,
        address borrower,
        address liquidator,
        uint256 seizeTokens,
        address pTokenCollateral
    ) internal virtual override {
        bytes memory payload = abi.encode(
            uint256(0),
            IHelper.SLiquidateBorrow(
                IHelper.Selector.SATELLITE_LIQUIDATE_BORROW,
                borrower,
                liquidator,
                seizeTokens,
                pTokenCollateral
            )
        );

        bytes32 metadata = ecc.preRegMsg(payload, msg.sender);
        assembly {
            mstore(add(payload, 0x20), metadata)
        }

        middleLayer.msend{value: msg.value}(
            chainId,
            payload, // bytes payload
            payable(msg.sender), // refund address
            address(0)
        );
    }

    // pass in the erc20 prevBalance, newBalance
    /// @dev Update the collateral balance for the given arguments
    /// @notice This will come from the satellite chain- the approve models
    function masterDeposit(
        IHelper.MDeposit memory params,
        bytes32 metadata,
        uint256 chainId
    ) external payable onlyMid() {
        if (!ecc.preProcessingValidation(abi.encode(params), metadata)) return;

        if (collateralBalances[chainId][params.user][params.pToken] != params.previousAmount) {
            // fallback to satellite to report failure
        }

        collateralBalances[chainId][params.user][params.pToken] += params.amountIncreased;
        markets[chainId][params.pToken].totalSupply += params.amountIncreased;

        emit CollateralBalanceAdded(
            params.user,
            chainId,
            collateralBalances[chainId][params.user][params.pToken],
            collateralBalances[chainId][params.user][params.pToken]
        );

        ecc.flagMsgValidated(abi.encode(params), metadata);

        // fallback to satellite to report receipt
    }

    function borrowAllowed(
        IHelper.MBorrowAllowed memory params,
        bytes32 metadata,
        uint256 chainId,
        address _route
    ) external payable onlyMid() {
        if (!ecc.preProcessingValidation(abi.encode(params), metadata)) return;

        // TODO: liquidity calculation
        _accrueInterest();

        (, uint256 shortfall) = _getHypotheticalAccountLiquidity(
            params.user,
            address(0),
            0,
            params.borrowAmount
        );

        //if approved, update the balance and fire off a return message
        if (shortfall == 0) {
            (uint256 _accountBorrows, ) = _borrowBalanceStored(params.user);

            /////////////////////////
            // EFFECTS & INTERACTIONS
            // (No safe failures beyond this point)

            accountBorrows[params.user].principal = _accountBorrows + params.borrowAmount;
            accountBorrows[params.user].interestIndex = borrowIndex;

            loansOutstanding[params.user][chainId] += params.borrowAmount;
            totalBorrows += params.borrowAmount;

            bytes memory payload = abi.encode(
                uint256(0),
                IHelper.FBBorrow(
                    IHelper.Selector.FB_BORROW,
                    params.user,
                    params.borrowAmount
                )
            );

            bytes32 _metadata = ecc.preRegMsg(payload, params.user);
            assembly {
                mstore(add(payload, 0x20), _metadata)
            }

            middleLayer.msend{ value: msg.value }(
                chainId,
                payload, // bytes payload
                payable(msg.sender), // refund address
                _route
            );

            ecc.flagMsgValidated(abi.encode(params), metadata);
        } else {
            // middleLayer.msend{ value: msg.value }(
            //   chainId,
            //   dstContractLookup[chainId], // send to this address on the destination
            //   payload, // bytes payload
            //   payable(msg.sender), // refund address
            //   address(0x0), // future parameter
            //   bytes("") // adapterParams (see "Advanced Features")
            // );
        }
    }

    function masterRepay(
        IHelper.MRepay memory params,
        bytes32 metadata,
        uint256 chainId
    ) external payable onlyMid() {
        if (!ecc.preProcessingValidation(abi.encode(params), metadata)) return;

        if (loansOutstanding[params.borrower][chainId] < params.amountRepaid
        ) {
            // TODO: fallback to satellite to report failure
        }
        (uint256 _accountBorrows,) = _borrowBalanceStored(params.borrower);

        loansOutstanding[params.borrower][chainId] -= params.amountRepaid;
        totalBorrows -= params.amountRepaid;
        accountBorrows[params.borrower].principal = _accountBorrows - params.amountRepaid;

        _accrueInterest();

        ecc.flagMsgValidated(abi.encode(params), metadata);

        // TODO: fallback to satellite to report receipt
    }

    function redeemAllowed(
        IHelper.MRedeemAllowed memory params,
        bytes32 metadata,
        uint256 chainId,
        address _route
    ) external payable onlyMid() {
        if (!ecc.preProcessingValidation(abi.encode(params), metadata)) return;

        _accrueInterest();

        //calculate hypothetical liquidity for the user
        //make sure we also check that the redeem isn't more than what's deposited
        // bool approved = true;

        (, uint256 shortfall) = _getHypotheticalAccountLiquidity(
            params.user,
            params.pToken,
            params.amount,
            0
        );

        bytes memory payload = abi.encode(
            uint256(0),
            IHelper.FBRedeem(
                IHelper.Selector.FB_REDEEM,
                params.pToken,
                params.user,
                params.amount
            )
        );

        bytes32 _metadata = ecc.preRegMsg(payload, params.user);
        assembly {
            mstore(add(payload, 0x20), _metadata)
        }

        //if approved, update the balance and fire off a return message
        if (shortfall == 0) {
            collateralBalances[chainId][params.user][params.pToken] -= params.amount;
            markets[chainId][params.pToken].totalSupply -= params.amount;

            ecc.flagMsgValidated(abi.encode(params), metadata);

            middleLayer.msend{value: msg.value}(
                chainId,
                payload, // bytes payload
                payable(msg.sender), // refund address
                _route
            );
        } else {
            middleLayer.msend{value: msg.value}(
                chainId,
                payload, // bytes payload
                payable(msg.sender), // refund address
                _route
            );
        }
    }

    function transferAllowed(
        IHelper.MTransferAllowed memory params,
        bytes32 metadata,
        uint256 chainId,
        address _route
    ) public payable onlyMid() {
        if (!ecc.preProcessingValidation(abi.encode(params), metadata)) return;

        _accrueInterest();

        (, uint256 shortfall) = _getHypotheticalAccountLiquidity(
            params.user,
            params.pToken,
            0,
            0
        );

        bytes memory payload = abi.encode(
            uint256(0),
            IHelper.FBCompleteTransfer(
                uint8(IHelper.Selector.FB_COMPLETE_TRANSFER),
                params.pToken,
                params.spender,
                params.user, // src
                params.dst,
                params.amount // tokens
            )
        );

        bytes32 _metadata = ecc.preRegMsg(payload, params.user);
        assembly {
            mstore(add(payload, 0x20), _metadata)
        }

        if (shortfall == 0) {
            collateralBalances[chainId][params.user][params.pToken] -= params.amount;
            collateralBalances[chainId][params.dst][params.pToken] += params.amount;

            ecc.flagMsgValidated(abi.encode(params), metadata);

            middleLayer.msend{value: msg.value}(
                chainId,
                payload, // bytes payload
                payable(msg.sender), // refund address
                _route
            );
        } else {
            // TODO: shortfall > 0
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./interfaces/IMaster.sol";
import "./MasterEvents.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

abstract contract MasterInternals is IMaster, MasterEvents {
    /**
     * @notice Return the borrow balance of account based on stored data
     * @param account The address whose balance should be calculated
     * @return (error code, the calculated balance or 0 if error code is non-zero)
     */
    function _borrowBalanceStored(
        address account
    ) internal view virtual override returns (uint256, uint256) {
        /* Note: we do not assert that the market is up to date */

        BorrowSnapshot storage borrowSnapshot = accountBorrows[account];

        /* If borrowBalance = 0 then borrowIndex is likely also 0.
        * Rather than failing the calculation with a division by 0, we immediately return 0 in this case.
        */
        if (borrowSnapshot.principal == 0) {
            return (0, 0);
        }

        /* Calculate new borrow balance using the interest index:
        *  recentBorrowBalance = borrower.borrowBalance * market.borrowIndex / borrower.borrowIndex
        */
        uint256 principalTimesIndex = borrowSnapshot.principal * borrowIndex;
        uint256 result = principalTimesIndex / borrowSnapshot.interestIndex;

        return (result, borrowSnapshot.principal);
    }

    function _accrueInterest() internal virtual override {
        uint256 accrualBlockNumberPrior = accrualBlockNumber;

        if (accrualBlockNumberPrior == block.number) return;

        // uint cashPrior = getCashPrior();
        uint256 borrowsPrior = totalBorrows;
        // TODO Deal with Reserves
        uint256 reservesPrior = totalReserves;
        uint256 borrowIndexPrior = borrowIndex;

        // TODO interest rate model - set to 0.0002% per block for now
        uint256 borrowRate = 2e6; // TODO: interestRateModel.setBorrowRate();
        require(borrowRate <= borrowRateMax, "borrow rate is absurdly high");

        require(block.number >= accrualBlockNumberPrior, "Cannot calculate data");
        uint256 blockDelta = block.number - accrualBlockNumberPrior;

        uint256 simpleInterestFactor = borrowRate * blockDelta;

        uint256 multiplier = 10**8; // TODO: PUSDAddress.decimals();

        uint256 interestAccumulated = (simpleInterestFactor * borrowsPrior) /
            multiplier;

        uint256 totalBorrowsNew = interestAccumulated + borrowsPrior;

        uint256 totalReservesNew = (reserveFactor * interestAccumulated) /
            multiplier + reservesPrior;

        uint256 borrowIndexNew = (simpleInterestFactor * borrowIndexPrior) /
            multiplier + borrowIndexPrior;

        /////////////////////////
        // EFFECTS & INTERACTIONS
        // (No safe failures beyond this point)

        accrualBlockNumber = block.number;
        borrowIndex = borrowIndexNew;
        totalBorrows = totalBorrowsNew;
        totalReserves = totalReservesNew;

        // emit AccrueInterest(interestAccumulated, borrowIndexNew, totalBorrowsNew);
    }

    /**
     * @notice Add the market to the borrower's "assets in" for liquidity calculations
     * @param token The market to enter
     * @param chainId The chainId
     * @param borrower The address of the account to modify
     */
    function _addToMarket(
        address token,
        uint256 chainId,
        address borrower
    ) internal virtual override returns (bool) {
        Market storage marketToJoin = markets[chainId][token];

        if (!marketToJoin.isListed) {
            return false;
        }

        if (marketToJoin.accountMembership[borrower] == true) {
            return true;
        }

        // survived the gauntlet, add to list
        // NOTE: we store these somewhat redundantly as a significant optimization
        //  this avoids having to iterate through the list for the most common use cases
        //  that is, only when we need to perform liquidity checks
        //  and not whenever we want to check if an account is in a particular market
        marketToJoin.accountMembership[borrower] = true;

        CollateralMarket memory market;
        market.token = token;
        market.chainId = chainId;

        accountAssets[borrower].push(market);

        emit MarketEntered(market.chainId, market.token, borrower);

        return true;
    }

    /**
     * @notice Get a snapshot of the account's balance, and the cached exchange rate
     * @dev This is used by risk engine to more efficiently perform liquidity checks.
     * @param user Address of the account to snapshot
     * @param chainId metadata of the ptoken
     * @param token metadata of the ptoken
     * @return (possible error, token balance, exchange rate)
     */
    function _getAccountSnapshot(
        address user,
        uint256 chainId,
        address token
    ) internal view virtual override returns (uint256, uint256) {
        uint256 pTokenBalance = collateralBalances[chainId][user][token];
        uint256 exchangeRate = _exchangeRateStored();

        return (pTokenBalance, exchangeRate);
    }

    /**
     * @dev Local vars for avoiding stack-depth limits in calculating account liquidity.
     *  Note that `pTokenBalance` is the number of pTokens the account owns in the market,
     *  whereas `borrowBalance` is the amount of underlying that the account has borrowed.
     */
    struct AccountLiquidityLocalVars {
        uint256 sumCollateral;
        uint256 sumBorrowPlusEffects;
        uint256 pTokenBalance;
        uint256 borrowBalance;
        uint256 collateralFactor;
        uint256 exchangeRate;
        uint256 oraclePrice;
        uint256 tokensToDenom;
    }

    function _getHypotheticalAccountLiquidity(
        address account,
        address pTokenModify,
        uint256 redeemTokens,
        uint256 borrowAmount
    ) internal view virtual override returns (uint256, uint256) {
        AccountLiquidityLocalVars memory vars; // Holds all our calculation results

        //add in the existing borrow
        (vars.sumBorrowPlusEffects, ) = _borrowBalanceStored(account);

        // For each asset the account is in
        CollateralMarket[] memory assets = accountAssets[account];
        for (uint256 i; i < assets.length; i++) {
            CollateralMarket memory asset = assets[i];

            // Read the balances and exchange rate from the pToken
            (vars.pTokenBalance, vars.exchangeRate) = _getAccountSnapshot(
                account,
                asset.chainId,
                asset.token
            );

            // Unlike prime protocol, getUnderlyingPrice is relatively expensive because we use ChainLink as our primary price feed.
            // If user has no supply / borrow balance on this asset, and user is not redeeming / borrowing this asset, skip it.
            if (vars.pTokenBalance == 0) {
                continue;
            }

            uint256 precision = markets[asset.chainId][asset.token].decimals;
            uint256 multiplier = 10**precision;

            // hardcoded for test
            vars.collateralFactor = markets[asset.chainId][asset.token]
                .collateralFactor;

            // TODO: using hard coded price of 1, FIX THIS
            vars.oraclePrice = multiplier; //oracle.getUnderlyingPrice(asset);

            require(vars.oraclePrice != 0, "PRICE_ERROR");

            // Pre-compute a conversion factor from tokens -> ether (normalized price value)
            vars.tokensToDenom = ((((vars.collateralFactor *
                vars.exchangeRate) / multiplier) * vars.oraclePrice) /
                multiplier);

            // sumCollateral += tokensToDenom * pTokenBalance
            vars.sumCollateral =
                (vars.tokensToDenom * vars.pTokenBalance) /
                multiplier +
                vars.sumCollateral;

            if (asset.token == pTokenModify) {
                // redeem effect
                // sumBorrowPlusEffects += tokensToDenom * redeemTokens
                vars.sumBorrowPlusEffects += (vars.tokensToDenom * redeemTokens) /
                    multiplier; /* normalize */
            }
        }

        // //get the multiplier and the oracle price from the loanAgent
        // // Read the balances and exchange rate from the pToken
        // (vars.pTokenBalance, vars.exchangeRate) = asset.getAccountSnapshot(
        //   account
        // );
        // // sumBorrowPlusEffects += oraclePrice * borrowBalance

        // borrow effect
        // sumBorrowPlusEffects += oraclePrice * borrowAmount
        vars.sumBorrowPlusEffects += borrowAmount;

        // These are safe, as the underflow condition is checked first
        if (vars.sumCollateral > vars.sumBorrowPlusEffects) {
            return (vars.sumCollateral - vars.sumBorrowPlusEffects, 0);
        } else {
            return (0, vars.sumBorrowPlusEffects - vars.sumCollateral);
        }
    }

    /**
        * FIXME: Refactor this method: https://primeprotocol.atlassian.net/browse/PC-211
        *
        * @notice Determine what the account liquidity would be if the given amounts were redeemed/borrowed
        * @param pTokenModify The market to hypothetically redeem/borrow in
        * @param account The account to determine liquidity for
        * @param redeemTokens The number of tokens to hypothetically redeem
        * @dev Note that we calculate the exchangeRateStored for each collateral pToken using stored data,
        *  without calculating accumulated interest.
        * @return (possible error code,
                    hypothetical account liquidity in excess of collateral requirements,
        *          hypothetical account shortfall below collateral requirements)
        */
    function _getHypotheticalAccountLiquidityRedeem(
        address account,
        address pTokenModify,
        uint256 redeemTokens
    ) internal view returns (uint256, uint256) {
        // For each asset the account is in
        CollateralMarket[] memory assets = accountAssets[account];

        require(assets.length > 0, "no account assets");

        /// @notice if we exit the loop early for one  PToken, we need to reset these values.
        ///   i could see an exploit where they use an old multiplier value for a specific PToken
        uint256 precision;
        uint256 multiplier;

        AccountLiquidityLocalVars memory vars;

        for (uint256 i; i < assets.length; i++) {
            CollateralMarket memory asset = assets[i];

            // Read the balances and exchange rate from the pToken
            vars.pTokenBalance = collateralBalances[asset.chainId][account][
                asset.token
            ];

            // Unlike prime protocol, getUnderlyingPrice is relatively expensive because we use ChainLink as our primary price feed.
            // If user has no supply / borrow balance on this asset, and user is not redeeming / borrowing this asset, skip it.
            if (vars.pTokenBalance == 0 && asset.token != pTokenModify) {
                continue;
            }

            precision = asset.decimals;
            multiplier = 10**precision;

            // Get the normalized price of the asset
            // TODO: using hard coded price of 1, FIX THIS
            vars.oraclePrice = multiplier; //oracle.getUnderlyingPrice(asset);

            require(vars.oraclePrice != 0, "PRICE_ERROR");

            // 1e8
            // vars.collateralFactor = markets[asset.chainId][asset.token].collateralFactor;
            vars.collateralFactor = collateralFactor;
            vars.exchangeRate = _exchangeRateStored();

            // Pre-compute a conversion factor from tokens -> ether (normalized price value)
            // exchangeRate is getAccountSnapshot (pToken => underlying); if we deposited ETH, how much pETH are you getting
            // if someone deposited 10 ETH a month ago, they could get like 1k pTokens. if someone does the same this month, they would get the new exchangeRate, which would theoretically be lower. like 200 pTokens
            // should be 1, actual is (1 * 100000000 * 100000000)
            vars.tokensToDenom =
                (vars.collateralFactor * vars.exchangeRate * vars.oraclePrice) /
                multiplier /
                multiplier; /* normalize */

            // sumCollateral += tokensToDenom * pTokenBalance
            vars.sumCollateral +=
                (vars.tokensToDenom * vars.pTokenBalance) /
                multiplier; /* normalize */

            // Calculate effects of interacting with pTokenModify
            if (asset.token == pTokenModify) {
                // redeem effect
                // sumBorrowPlusEffects += tokensToDenom * redeemTokens
                vars.sumBorrowPlusEffects +=
                    (vars.tokensToDenom * redeemTokens) /
                    multiplier; /* normalize */
            }
        }

        // //get the multiplier and the oracle price from the loanAgent
        // // Read the balances and exchange rate from the pToken
        // (vars.pTokenBalance, vars.exchangeRate) = asset.getAccountSnapshot(
        //   account
        // );
        // // sumBorrowPlusEffects += oraclePrice * borrowBalance

        // FIXME: using hard coded price of 1
        uint256 borrowOraclePrice = multiplier; //oracle.getUnderlyingPriceBorrow(borrowMarket);
        (uint256 borrowBalance, ) = _borrowBalanceStored(account);

        vars.sumBorrowPlusEffects +=
            (borrowOraclePrice * borrowBalance) /
            multiplier; /* normalize */

        // These are safe, as the underflow condition is checked first
        if (vars.sumCollateral > vars.sumBorrowPlusEffects) {
            return (vars.sumCollateral - vars.sumBorrowPlusEffects, 0);
        } else {
            return (0, vars.sumBorrowPlusEffects - vars.sumCollateral);
        }
    }

    function _liquidateCalculateSeizeTokens(
        address pTokenCollateral,
        uint256 chainId,
        uint256 actualRepayAmount
    ) internal view virtual override returns (uint256) {
        /* TODO: Read oracle prices for borrowed and collateral markets */
        // PUSD Price
        uint256 priceBorrowed = 1e8; //oracle.getUnderlyingPriceBorrow(pTokenCollateral);
        uint256 priceCollateral = 1e8; //oracle.getUnderlyingPrice(pTokenCollateral);
        require(priceCollateral > 0 && priceBorrowed > 0, "PRICE_FETCH");

        uint256 multiplier = 10**markets[chainId][pTokenCollateral].decimals;

        /*
         * Get the exchange rate and calculate the number of collateral tokens to seize:
         *  seizeAmount = actualRepayAmount * liquidationIncentive * priceBorrowed / priceCollateral
         *  seizeTokens = seizeAmount / exchangeRate
         *   = actualRepayAmount * (liquidationIncentive * priceBorrowed) / (priceCollateral * exchangeRate)
         */
        uint256 numerator = (actualRepayAmount *
            (multiplier + liquidityIncentive) *
            priceBorrowed) / multiplier;
        uint256 denominator = (priceCollateral * _exchangeRateStored()) /
            multiplier;
        uint256 seizeTokens = numerator / denominator;

        return seizeTokens;
    }

    function _liquidateBorrowAllowed(
        address pTokenCollateral,
        address borrower,
        uint256 chainId,
        uint256 repayAmount
    ) internal view virtual override returns (bool) {
        if (!markets[chainId][pTokenCollateral].isListed) {
            return false;
        }

        /* The borrower must have shortfall in order to be liquidatable */
        (, uint256 shortfall) = _getHypotheticalAccountLiquidityRedeem(
            borrower,
            address(0),
            0
        );

        if (shortfall == 0) {
            return false;
        }

        uint256 multiplier = 10**markets[chainId][pTokenCollateral].decimals;

        /* The liquidator may not repay more than what is allowed by the closeFactor */
        (uint256 borrowBalance, ) = _borrowBalanceStored(borrower);

        uint256 maxClose = (closeFactor * borrowBalance) / multiplier;

        if (repayAmount > maxClose) {
            return false;
        }

        return true;
    }

    struct RepayBorrowLocalVars {
        uint256 repayAmount;
        uint256 borrowerIndex;
        uint256 accountBorrows;
        uint256 accountBorrowsNew;
        uint256 totalBorrowsNew;
        uint256 actualRepayAmount;
    }

    function _repayBorrowFresh(
        address borrower,
        uint256 repayAmount /*override*/
    ) internal virtual returns (uint256) {
        /* Verify market's block number equals current block number */
        require(
            accrualBlockNumber == block.number,
            "REPAY_BORROW_FRESHNESS_CHECK"
        );

        RepayBorrowLocalVars memory vars;

        /* We remember the original borrowerIndex for verification purposes */
        vars.borrowerIndex = accountBorrows[borrower].interestIndex;

        /* We fetch the amount the borrower owes, with accumulated interest */
        (vars.accountBorrows, ) = _borrowBalanceStored(borrower);

        /* If repayAmount == -1, repayAmount = accountBorrows */
        // As of Solidity v0.8 Explicit conversions between literals and an integer type T are only allowed if the literal lies between type(T).min and type(T).max. In particular, replace usages of uint(-1) with type(uint).max.
        // type(uint).max
        vars.actualRepayAmount = repayAmount == type(uint256).max
            ? vars.accountBorrows
            : repayAmount;

        /////////////////////////
        // EFFECTS & INTERACTIONS
        // (No safe failures beyond this point)

        /*
         * We call doTransferIn for the payer and the repayAmount
         *  Note: The pToken must handle variations between ERC-20 and ETH underlying.
         *  On success, the pToken holds an additional repayAmount of cash.
         *  doTransferIn reverts if anything goes wrong, since we can't be sure if side effects occurred.
         *   it returns the amount actually transferred, in case of a fee.
         */
        // vars.actualRepayAmount = doTransferIn(payer, vars.repayAmount);
        // TODO: Handle this in lz call
        // PUSDAddress.burnFrom(/*msg.sender*/ -> payer, vars.repayAmount); // burn the pusd

        // vars.actualRepayAmount = vars.repayAmount;

        /*
         * We calculate the new borrower and total borrow balances, failing on underflow:
         *  accountBorrowsNew = accountBorrows - actualRepayAmount
         *  totalBorrowsNew = totalBorrows - actualRepayAmount
         */
        require(
            vars.accountBorrows >= vars.actualRepayAmount,
            "REPAY_GT_BORROWS"
        );
        // ! This case should be impossible if the above check passes
        require(totalBorrows >= vars.actualRepayAmount, "REPAY_GT_TBORROWS");

        vars.accountBorrowsNew = vars.accountBorrows - vars.actualRepayAmount;
        vars.totalBorrowsNew = totalBorrows - vars.actualRepayAmount;

        accountBorrows[borrower].principal = vars.accountBorrowsNew;
        accountBorrows[borrower].interestIndex = borrowIndex;
        totalBorrows = vars.totalBorrowsNew;

        /* We emit a RepayBorrow event */
        // emit RepayBorrow(
        //     payer,
        //     borrower,
        //     vars.actualRepayAmount,
        //     vars.accountBorrowsNew,
        //     vars.totalBorrowsNew
        // );

        return vars.actualRepayAmount;
    }

    function _seizeAllowed() internal virtual returns (bool) {
        // return seizeGuardianPaused;
    }

    function _liquidateBorrow(
        address pTokenCollateral,
        address borrower,
        uint256 chainId,
        uint256 repayAmount
    ) internal virtual override returns (bool) {
        /* Fail if liquidate not allowed */
        require(
            _liquidateBorrowAllowed(
                pTokenCollateral,
                borrower,
                chainId,
                repayAmount
            ),
            "LIQUIDATE_RISKENGINE_REJECTION"
        );

        /* Verify market's block number equals current block number */
        require(
            accrualBlockNumber == block.number,
            "LIQUIDATE_FRESHNESS_CHECK"
        );

        /* Fail if borrower = liquidator */
        // ? Using msg.sender here is more optimal than using a local var
        // ? that is in every case assigned to msg.sender
        require(borrower != msg.sender, "LIQUIDATE_LIQUIDATOR_IS_BORROWER");

        /* Fail if repayAmount = 0 */
        require(repayAmount > 0, "LIQUIDATE_CLOSE_AMOUNT_IS_ZERO");

        /* Fail if repayAmount = -1 */
        // NOTE: What case is this check covering?
        // require(repayAmount != type(uint128).max, "INVALID_CLOSE_AMOUNT_REQUESTED | LIQUIDATE_CLOSE_AMOUNT_IS_UINT_MAX");

        // Fail if repayBorrow fails
        uint256 actualRepayAmount = _repayBorrowFresh(
            // msg.sender, // ! payer value unused in function call
            borrower,
            repayAmount
        );

        uint256 protocolSeizeShareAmount = (actualRepayAmount * protocolSeizeShare)/1e8;

        // We calculate the number of collateral tokens that will be seized
        uint256 seizeTokens = _liquidateCalculateSeizeTokens(
            pTokenCollateral,
            chainId,
            actualRepayAmount - protocolSeizeShareAmount
        );

        uint256 collateralBalance = collateralBalances[chainId][borrower][pTokenCollateral];

        // Revert if borrower collateral token balance < seizeTokens
        require(
            collateralBalance >= seizeTokens,
            "LIQUIDATE_SEIZE_TOO_MUCH"
        );

        accountBorrows[borrower].principal += protocolSeizeShareAmount;
        collateralBalances[chainId][borrower][pTokenCollateral] = collateralBalance - seizeTokens;
        collateralBalances[chainId][msg.sender][pTokenCollateral] += seizeTokens;
        totalReserves += protocolSeizeShareAmount;

        ERC20Burnable(pusd).burnFrom(msg.sender, actualRepayAmount);

        // ! If this call fails on satellite we accept a fallback call
        // ! to revert above state changes
        satelliteLiquidateBorrow(
            chainId,
            borrower,
            msg.sender,
            seizeTokens,
            pTokenCollateral
        );

        /* We emit a LiquidateBorrow event */
        // emit LiquidateBorrow(
        //     msg.sender,
        //     borrower,
        //     actualRepayAmount,
        //     address(pTokenCollateral),
        //     seizeTokens
        // );

        return true;
    }

    function _exchangeRateStored()
        internal
        view
        virtual
        override
        returns (uint256)
    {
        // this is where the tests are failing
        // uint256 _totalSupply = totalSupply;
        // if (_totalSupply == 0) {
        //   /*
        //    * If there are no tokens minted:
        //    *  exchangeRate = initialExchangeRate
        //    */
        //   return initialExchangeRate;
        // } else {
        //   /*
        //    * Otherwise:
        //    *  exchangeRate = (totalCash + totalBorrows - totalReserves) / totalSupply
        //    */
        //   uint256 totalCash = getCashPrior();
        //   uint256 cashPlusBorrowsMinusReserves;
        //   uint256 exchangeRate;

        //   cashPlusBorrowsMinusReserves = totalCash - totalReserves;

        //   exchangeRate = (totalCash * 10**decimals) / _totalSupply;
        //   return exchangeRate;
        // }
        return 1e8;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

// TODO: Change this import to somewhere else probably
import "../master/oracle/interfaces/IPTokenOracle.sol";
import "../middleLayer/interfaces/IMiddleLayer.sol";
import "../ecc/interfaces/IECC.sol";

abstract contract MasterStorage {
    /**
    * @notice Administrator for this contract
    */
    address public admin;

    IMiddleLayer internal middleLayer;

    IECC internal ecc;

    address internal pusd;

    /**
     * @notice Block number that interest was last accrued at
     */
    uint256 public accrualBlockNumber;

    /**
     * @notice Total amount of outstanding borrows of the underlying in this market
     */
    uint256 public totalBorrows;

    /**
    * @notice Total amount of reserves of the underlying held in this market
    */
    uint256 public totalReserves;

    /**
     * @notice Accumulator of the total earned interest rate since the opening of the market
     */
    uint256 public borrowIndex; // TODO - needs initialized

    uint256 public liquidityIncentive = 5e6; // 5%
    uint256 public closeFactor = 50e6; // 50%
    uint256 public collateralFactor = 80e6; // 80%
    uint256 public protocolSeizeShare = 5e6; // 5%
    uint256 public reserveFactor = 80e6; // 80%

    /**
     * @notice Maximum borrow rate that can ever be applied (.0005% / block)
     */
    uint256 internal constant borrowRateMax = 0.0005e16;

    // chainid => user => token => token balance
    mapping(uint256 => mapping(address => mapping(address => uint256)))
        public collateralBalances;

    // user => chainId => token balance
    mapping(address => mapping(uint256 => uint256)) public loansOutstanding;

    struct Market {
        uint256 collateralFactor;
        uint256 initialExchangeRate;
        uint256 totalSupply;
        string name; // 256
        string symbol; // 256
        address underlying; // 20
        bool isListed; // 8
        uint8 decimals;
        mapping(address => bool) accountMembership;
    }

    /**
     * @notice Official mapping of pTokens -> Market metadata
     * @dev Used e.g. to determine if a market is supported
     */
    // chain => ptoken address => market
    mapping(uint256 => mapping(address => Market)) public markets;

    struct InterestSnapshot {
        uint256 interestAccrued;
        uint256 interestIndex;
    }

    /**
     * @notice Container for borrow balance information
     * @member principal Total balance (with accrued interest), after applying the most recent balance-changing action
     * @member interestIndex Global borrowIndex as of the most recent balance-changing action
     */
    struct BorrowSnapshot {
        uint256 principal;
        uint256 interestIndex;
    }

    /**
     * @notice Mapping of account addresses to outstanding borrow balances
     */
    mapping(address => BorrowSnapshot) public accountBorrows;

    /// @notice A list of all deposit markets
    CollateralMarket[] public allMarkets;

    struct CollateralMarket {
        address token;
        uint256 chainId;
        uint8 decimals;
    }
    // user => interest index
    mapping(address => CollateralMarket[]) public accountAssets;

    uint256[] public chains;
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "../../../satellite/pToken/interfaces/IPToken.sol";
import "../../../satellite/loanAgent/interfaces/ILoanAgent.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

interface IPTokenOracle {
    /**
     * @notice Get the underlying price of a cToken asset
     * @param pToken The pToken to get the underlying price of
     * @return The underlying asset price.
     *  Zero means the price is unavailable.
     */
    function getUnderlyingPrice(IERC20 pToken) external view returns (uint256);

    /**
     * @notice Get the underlying borrow price of a pToken asset
     * @param loanAgent The loanAgent associated with the pToken
     * @return The underlying borrow price
     *  Zero means the price is unavailable.
     */
    function getUnderlyingPriceBorrow(ILoanAgent loanAgent) external view returns (uint256);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

abstract contract IMiddleLayer {
    /**
     * @notice routes and encodes messages for you
     * @param params - abi.encode() of the struct related to the selector, used to generate _payload
     * all params starting with '_' are directly sent to the lz 'send()' function
     */
    function msend(
        uint256 _dstChainId,
        bytes memory params,
        address payable _refundAddress,
        address _route
    ) external payable virtual;

    function mreceive(
        uint256 _srcChainId,
        bytes memory payload
    ) external virtual;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IECC {
    struct Metadata {
        bytes5 soph; // start of payload hash
        uint40 creation;
        uint16 nonce; // in case the same exact message is sent multiple times the same block, we increase the nonce in metadata
        address sender;
    }

    function preRegMsg(
        bytes memory payload,
        address instigator
    ) external returns (bytes32 metadata);

    function preProcessingValidation(
        bytes memory payload,
        bytes32 metadata
    ) external view returns (bool allowed);

    function flagMsgValidated(
        bytes memory payload,
        bytes32 metadata
    ) external returns (bool);

    // function rsm(uint256 messagePtr) external returns (bool);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

abstract contract IPToken {

    function mint(uint256 amount) external virtual payable;

    function redeemUnderlying(uint256 redeemAmount) external virtual payable;


    function setMidLayer(address _middleLayer) external virtual;

    function setMasterCID(uint256 _cid) external virtual;

    function changeOwner(address payable _newOwner) external virtual;
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "../LoanAgentStorage.sol";
import "../../../interfaces/IHelper.sol";

abstract contract ILoanAgent is LoanAgentStorage {
    function initialize(address _ecc) external virtual;

    function borrow(uint256 borrowAmount) external payable virtual;

    // function completeBorrow(
    //     address borrower,
    //     uint borrowAmount
    // ) external virtual;

    function repayBorrow(uint256 repayAmount) external payable virtual returns (bool);

    function repayBorrowBehalf(
        address borrower,
        uint256 repayAmount
    ) external payable virtual returns (bool);

    function borrowApproved(
        IHelper.FBBorrow memory params,
        bytes32 metadata
    ) external payable virtual;

    function setPUSD(address newPUSD) external virtual;

    function setMidLayer(address _middleLayer) external virtual;

    function setMasterCID(uint256 _cid) external virtual;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

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
contract ERC20 is Context, IERC20, IERC20Metadata {
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
    constructor(string memory name_, string memory symbol_) {
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
        _approve(owner, spender, _allowances[owner][spender] + addedValue);
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
        uint256 currentAllowance = _allowances[owner][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
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
        }
        _balances[to] += amount;

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
     * @dev Spend `amount` form the allowance of `owner` toward `spender`.
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
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "../../middleLayer/interfaces/IMiddleLayer.sol";
import "../../ecc/interfaces/IECC.sol";

abstract contract LoanAgentStorage {
    /**
    * @notice Administrator for this contract
    */
    address payable public admin;

    address internal PUSD;

    IMiddleLayer internal middleLayer;

    IECC internal ecc;

    uint256 internal masterCID;

    uint256 public borrowIndex;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

interface IHelper {
    enum Selector {
        MASTER_DEPOSIT,
        MASTER_REDEEM_ALLOWED,
        FB_REDEEM,
        MASTER_REPAY,
        MASTER_BORROW_ALLOWED,
        FB_BORROW,
        SATELLITE_LIQUIDATE_BORROW,
        MASTER_TRANSFER_ALLOWED,
        FB_COMPLETE_TRANSFER,
        PUSD_BRIDGE
    }

    // !!!!
    // @dev
    // an artificial uint256 param for metadata should be added
    // after packing the payload
    // metadata can be generated via call to ecc.preRegMsg()

    struct MDeposit {
        Selector selector; // = Selector.MASTER_DEPOSIT
        address user;
        address pToken;
        uint256 previousAmount;
        uint256 amountIncreased;
    }

    struct MRedeemAllowed {
        Selector selector; // = Selector.MASTER_REDEEM_ALLOWED
        address pToken;
        address user;
        uint256 amount;
    }

    struct FBRedeem {
        Selector selector; // = Selector.FB_REDEEM
        address pToken;
        address user;
        uint256 redeemAmount;
    }

    struct MRepay {
        Selector selector; // = Selector.MASTER_REPAY
        address borrower;
        uint256 amountRepaid;
    }

    struct MBorrowAllowed {
        Selector selector; // = Selector.MASTER_BORROW_ALLOWED
        address user;
        uint256 borrowAmount;
    }

    struct FBBorrow {
        Selector selector; // = Selector.FB_BORROW
        address user;
        uint256 borrowAmount;
    }

    struct SLiquidateBorrow {
        Selector selector; // = Selector.SATELLITE_LIQUIDATE_BORROW
        address borrower;
        address liquidator;
        uint256 seizeTokens;
        address pTokenCollateral;
    }

    struct MTransferAllowed {
        uint8 selector; // = Selector.MASTER_TRANSFER_ALLOWED
        address pToken;
        address spender;
        address user;
        address dst;
        uint256 amount;
    }

    struct FBCompleteTransfer {
        uint8 selector; // = Selector.FB_COMPLETE_TRANSFER
        address pToken;
        address spender;
        address src;
        address dst;
        uint256 tokens;
    }

    struct PUSDBridge {
        uint8 selector; // = Selector.PUSD_BRIDGE
        address minter;
        uint256 amount;
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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./MasterStorage.sol";

abstract contract MasterModifiers is MasterStorage {
    modifier onlyOwner() {
        require(msg.sender == admin, "ONLY_OWNER");
        _;
    }

    modifier onlyMid() {
        require(
            IMiddleLayer(msg.sender) == middleLayer,
            "ONLY_MIDDLE_LAYER"
        );
        _;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/extensions/ERC20Burnable.sol)

pragma solidity ^0.8.0;

import "../ERC20.sol";
import "../../../utils/Context.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20 {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
    }
}