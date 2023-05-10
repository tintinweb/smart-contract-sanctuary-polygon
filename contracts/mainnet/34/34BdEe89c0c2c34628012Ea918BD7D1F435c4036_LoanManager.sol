// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {IERC20MetadataUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import {SafeERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import {CountersUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";

import {IPool, IPriceFeed, ISettingsProvider, ICollateralManager, INFCS, IScoreDB, ILimitManager, ILoanManager} from "./interfaces/ILoanManager.sol";
import {IVersion} from "./interfaces/IVersion.sol";

import {Errors} from "./lib/Errors.sol";
import {Roles} from "./lib/Roles.sol";
import {LoanLib} from "./lib/LoanLib.sol";
import {Version} from "./lib/Version.sol";
import {SelectivePausable} from "./lib/SelectivePausable.sol";
import {LOAN_MANAGER_VERSION} from "./lib/ContractVersions.sol";
import {ONE_YEAR} from "./lib/Constants.sol";

contract LoanManager is
    Initializable,
    SelectivePausable,
    AccessControlUpgradeable,
    UUPSUpgradeable,
    ILoanManager,
    ReentrancyGuardUpgradeable,
    Version
{
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    using SafeERC20Upgradeable for IERC20MetadataUpgradeable;
    using CountersUpgradeable for CountersUpgradeable.Counter;
    using LoanLib for LoanLib.Loan;

    ICollateralManager public collateralManager;
    INFCS public nfcs;
    IPriceFeed public priceFeed;
    ISettingsProvider public settingsProvider;
    IScoreDB public scoreDB;
    ILimitManager public limitManager;

    // Loan id counter
    CountersUpgradeable.Counter public nextLoanId;

    // loanId => loan
    mapping(uint256 => LoanLib.Loan) internal _loans;

    mapping(address => uint256[]) public userLoanIds;

    //Statuses table
    LoanLib.StatusMatrix internal table;

    //Loans liquidation threshold
    uint256 public constant LIQUIDATION_THRESHOLD = 5 ether;

    function _authorizeUpgrade(
        address newImplementation
    ) internal override whenPaused onlyRole(Roles.UPDATER) {}

    function initialize(address _admin) public initializer {
        require(_admin != address(0), Errors.ZERO_ADDRESS);

        __Pausable_init();

        // start with 1
        nextLoanId.increment();

        _setRoleAdmin(Roles.PAUSER, Roles.ADMIN);
        _setRoleAdmin(Roles.UPDATER, Roles.ADMIN);
        _setRoleAdmin(Roles.ADMIN, Roles.ADMIN);
        _setRoleAdmin(Roles.LIQUIDATOR, Roles.ADMIN);

        _grantRole(Roles.ADMIN, _admin);

        _addPausableFunc("borrow", this.borrow.selector);
        _addPausableFunc("repay", this.repay.selector);
    }

    /**
     * @dev Returns full loan struct by loanId
     * @param loanId id of the loan
     * @return loan structure
     */
    function loans(uint256 loanId) external view returns (LoanLib.Loan memory) {
        return _loans[loanId];
    }

    function setCollateralManager(
        ICollateralManager _collateralManager
    ) external onlyRole(Roles.ADMIN) {
        emit CollateralManagerChanged(msg.sender, collateralManager, _collateralManager);
        collateralManager = _collateralManager;
    }

    function setNFCS(INFCS _nfcs) external onlyRole(Roles.ADMIN) {
        emit NFCSChanged(msg.sender, nfcs, _nfcs);
        nfcs = _nfcs;
    }

    function setPriceFeed(IPriceFeed _priceFeed) external onlyRole(Roles.ADMIN) {
        emit PriceFeedChanged(msg.sender, priceFeed, _priceFeed);
        priceFeed = _priceFeed;
    }

    function setSettingsProvider(
        ISettingsProvider _settingsProvider
    ) external onlyRole(Roles.ADMIN) {
        emit SettingsProviderChanged(msg.sender, settingsProvider, _settingsProvider);
        settingsProvider = _settingsProvider;
    }

    function setScoreDB(IScoreDB _scoreDB) external onlyRole(Roles.ADMIN) {
        emit ScoreDBChanged(msg.sender, scoreDB, _scoreDB);
        scoreDB = _scoreDB;
    }

    function setLimitManager(ILimitManager _limitManager) external onlyRole(Roles.ADMIN) {
        emit LimitManagerChanged(msg.sender, limitManager, _limitManager);
        limitManager = _limitManager;
    }

    function setStatus(
        LoanLib.Status from,
        LoanLib.Period period,
        LoanLib.Action action,
        LoanLib.Status to
    ) external onlyRole(Roles.ADMIN) {
        emit StatusChanged(msg.sender, from, period, action, table._m[from][period][action], to);
        table._m[from][period][action] = to;
    }

    function getStatus(
        LoanLib.Status from,
        LoanLib.Period period,
        LoanLib.Action action
    ) external view returns (LoanLib.Status) {
        return table._m[from][period][action];
    }

    /**
     * @dev Get all loan ids for user
     * @param user address of user account
     * @return array of user loan ids
     */
    function getUserLoanIds(address user) external view returns (uint256[] memory) {
        return userLoanIds[user];
    }

    /**
     * @dev Calculates interest for params
     * @param apr annual percentage rate
     * @param timeFrame time between last and next interest accruing in seconds
     * @param amount principal of loan
     * @return interest interest to accrue on next interest accruing
     */
    function calculateInterest(
        uint256 apr,
        uint256 timeFrame,
        uint256 amount
    ) internal pure returns (uint256) {
        return (amount * apr * timeFrame) / (100 ether * ONE_YEAR);
    }

    /**
     * @dev Calculates interest for loan
     * @notice Interest will be calculated from last loan repayment/liquidation time or from loan creation
     * @param loanId id of the loan
     * @param toTimestamp timestamp of the next interest accruing
     * @return interest interest to accrue on next interest accruing to loan
     */
    function getInterest(uint256 loanId, uint256 toTimestamp) public view returns (uint256) {
        LoanLib.Loan memory loan = _loans[loanId];

        uint256 interestDry = calculateInterest(
            loan.apr,
            toTimestamp - loan.lastRepay,
            loan.amount
        );

        if (toTimestamp <= loan.dueDate) {
            return interestDry;
        }

        if (loan.lastRepay <= loan.dueDate) {
            uint256 interest = calculateInterest(
                loan.apr,
                loan.dueDate - loan.lastRepay,
                loan.amount
            );

            uint256 lateInterest = calculateInterest(
                loan.apr,
                toTimestamp - loan.dueDate,
                loan.amount
            );

            return interest + (lateInterest * loan.lateFee) / 1 ether;
        }
        return (interestDry * loan.lateFee) / 1 ether;
    }

    function getScore(address user) internal view returns (uint16 score, bool exists) {
        try nfcs.getToken(user) returns (uint256 nfcsId) {
            score = scoreDB.getCreditScoreAndValidate(nfcsId);
            exists = true;
        } catch {
            score = scoreDB.scoreWithoutNfcsId();
            exists = false;
        }
    }

    /**
     * @dev Creates new loan of amount for msg.sender from pool with collateral and loan params
     * @notice method are payable means native token can be used as collateral
     * @notice this method will transfer value of collateral token required to cover loan from user
     * @notice and amount of loan to user
     * @param amount of pool underlying token to borrow
     * @param pool from which to borrow funds
     * @param collateral token that will be frozen to cover loan value
     * @param ltv loan to value factor
     * @param duration loan duration in seconds
     * @param version LoanManager version for external interactions
     */
    function borrow(
        uint256 amount,
        IPool pool,
        IERC20MetadataUpgradeable collateral,
        uint256 ltv,
        uint256 duration,
        string memory version
    ) public payable ifNotPaused nonReentrant checkVersion(version) {
        if (ltv == type(uint256).max) {
            collateral = IERC20MetadataUpgradeable(address(0));
        }

        BorrowVars memory vars = BorrowVars(
            _checkScoreToLtv(ltv),
            nextLoanId.current(),
            pool.underlyingToken()
        );

        nextLoanId.increment();

        limitManager.onBorrow(msg.sender, pool, vars.score, amount);

        ISettingsProvider.LoanSettings memory s = settingsProvider.getLoanSettings(
            pool,
            vars.score,
            ltv,
            duration,
            collateral
        );

        require(s.interestSettings.limit >= amount, Errors.LOAN_MANAGER_LOAN_PARAMS_LIMIT);

        uint256 collateralToFreeze = ltv == type(uint256).max
            ? 0
            : priceFeed.convert((amount * 100 ether) / ltv, vars.underlyingToken, collateral);

        _loans[vars.loanId] = LoanLib.Loan(
            msg.sender,
            amount,
            s.interestSettings.interest,
            ltv,
            s.lateFee,
            block.timestamp,
            block.timestamp + duration,
            block.timestamp + duration + s.gracePeriod,
            block.timestamp,
            collateralToFreeze,
            collateral,
            pool,
            LoanLib.Status.NEW
        );

        emit LoanCreated(
            msg.sender,
            address(pool),
            vars.loanId,
            s.interestSettings.interest,
            amount
        );

        userLoanIds[msg.sender].push(vars.loanId);

        uint256 userCollateralBalance = collateralManager.collateralToUserToAmount(
            collateral,
            msg.sender
        );

        uint256 collateralToAdd = userCollateralBalance >= collateralToFreeze
            ? 0
            : collateralToFreeze - userCollateralBalance;

        if (collateralToAdd > 0) {
            if (msg.value > 0) {
                collateralManager.addCollateral{value: collateralToAdd}(msg.sender, collateral, 0);
                if (msg.value > collateralToAdd) {
                    require(
                        payable(msg.sender).send(msg.value - collateralToAdd),
                        Errors.LOAN_MANAGER_NATIVE_RETURN
                    );
                }
            } else {
                collateralManager.addCollateral(msg.sender, collateral, collateralToAdd);
            }
        }

        if (ltv != type(uint256).max) {
            collateralManager.freeze(msg.sender, collateral, collateralToFreeze);
        }

        vars.underlyingToken.safeTransferFrom(address(pool), msg.sender, amount);
    }

    /**
     * @dev Repays existing loan with amount from msg.sender
     * @param loanId existing loan id
     * @param amount to repay, can be greater than loan principal + loan interest
     * @param version LoanManager version for external interactions
     */
    function repay(
        uint256 loanId,
        uint256 amount,
        string memory version
    ) external ifNotPaused nonReentrant checkVersion(version) {
        require(amount > 0, Errors.LOAN_MANAGER_ZERO_REPAY);

        LoanLib.Loan storage loan = _loans[loanId];

        require(loan.amount > 0, Errors.LOAN_MANAGER_LOAN_AMOUNT_ZERO);

        uint256 interestAccrued = getInterest(loanId, block.timestamp);

        require(interestAccrued > 0, Errors.ZERO_VALUE);

        //If user repays more that loan principal + loan interest accrued then it repays loan principal + loan interest accrued
        if (amount > loan.amount + interestAccrued) {
            amount = loan.amount + interestAccrued;
        }

        if (amount >= interestAccrued) {
            loan.amount -= amount - interestAccrued;
            limitManager.onRepayOrLiquidate(loan.borrower, loan.pool, amount - interestAccrued);
            loan.lastRepay = block.timestamp;
        } else {
            loan.lastRepay += (amount * 100 ether * ONE_YEAR) / (loan.amount * loan.apr);
            interestAccrued = amount;
        }

        loan.updateStatus(loanId, LoanLib.Action.REPAY_PARTIAL, table);

        emit LoanPayed(
            msg.sender,
            loan.borrower,
            address(loan.pool),
            loanId,
            interestAccrued,
            amount,
            loan.amount
        );

        IERC20MetadataUpgradeable underlyingToken = loan.pool.underlyingToken();

        uint256 treasuryShare = sendToTreasury(underlyingToken, msg.sender, interestAccrued);
        underlyingToken.safeTransferFrom(msg.sender, address(loan.pool), amount - treasuryShare);

        // Adjust pool value
        // if loan was partially liquidated it means that poolValue was previously decreased
        // therefore it should be increased not only by accrued interest but also by repaid principal
        // otherwise increase poolValue by accrued interest
        loan.pool.updatePoolValue(
            loan.status == LoanLib.Status.DEFAULT_PART
                ? int256(amount - treasuryShare)
                : int256(interestAccrued - treasuryShare)
        );

        //If loan are fully repaid
        if (loan.amount == 0) {
            if (loan.frozenCollateralAmount > 0) {
                collateralManager.unfreeze(
                    loan.borrower,
                    loan.frozenCollateralToken,
                    loan.frozenCollateralAmount
                );
            }

            limitManager.onLoanFulfillment(loan.borrower, loan.pool);

            loan.updateStatus(loanId, LoanLib.Action.REPAY_FULL, table);

            emit LoanClosed(loan.borrower, address(loan.pool), loanId);
        }
    }

    function liquidate(
        uint256 loanId,
        string memory version
    )
        external
        whenNotPaused
        nonReentrant
        checkVersion(version)
        onlyRole(Roles.LIQUIDATOR)
        returns (IERC20MetadataUpgradeable, IERC20MetadataUpgradeable, uint256, IPool)
    {
        LoanLib.DelinquencyInfo memory info = getDelinquencyInfo(loanId);

        LoanLib.Loan storage loan = _loans[loanId];

        IERC20MetadataUpgradeable underlyingToken = loan.pool.underlyingToken();

        uint256 treasuryShare = info.poolValueAdjust > 0
            ? sendToTreasury(underlyingToken, msg.sender, uint256(info.poolValueAdjust))
            : 0;

        int256 poolValueAdjustment = info.poolValueAdjust - int256(treasuryShare);

        loan.pool.updatePoolValue(poolValueAdjustment);

        underlyingToken.safeTransferFrom(
            msg.sender,
            address(loan.pool),
            info.notCovered > 0
                ? loan.amount < info.notCovered ? info.notCovered : loan.amount - info.notCovered
                : loan.amount + uint256(poolValueAdjustment)
        );

        limitManager.onRepayOrLiquidate(
            loan.borrower,
            loan.pool,
            loan.amount < info.notCovered ? 0 : loan.amount - info.notCovered
        );

        loan.amount = info.notCovered;

        if (loan.ltv != type(uint256).max) {
            collateralManager.seize(
                msg.sender,
                loan.frozenCollateralToken,
                loan.borrower,
                info.toLiquidate
            );
        }

        uint256 unfrozenCollateral;
        //If loan frozen collateral exceeds amount of collateral to liquidate we can unfreeze remaining amount
        if (loan.frozenCollateralAmount > info.toLiquidate) {
            unfrozenCollateral = loan.frozenCollateralAmount - info.toLiquidate;
            collateralManager.unfreeze(
                loan.borrower,
                loan.frozenCollateralToken,
                unfrozenCollateral
            );
            limitManager.onLoanFulfillment(loan.borrower, loan.pool);
        }

        loan.frozenCollateralAmount = 0;

        LoanLib.Action statusAction = LoanLib.Action.LIQUIDATION_COVERED;

        if (loan.amount > 0) {
            statusAction = LoanLib.Action.LIQUIDATION_NOT_COVERED;
            loan.lastRepay = block.timestamp;
        }

        loan.updateStatus(loanId, statusAction, table);

        emit LoanLiquidated(
            loan.borrower,
            loan.pool,
            loanId,
            poolValueAdjustment > 0 ? uint256(poolValueAdjustment) : 0,
            block.timestamp,
            loan.amount,
            info.toLiquidate,
            unfrozenCollateral,
            poolValueAdjustment
        );

        return (loan.frozenCollateralToken, underlyingToken, info.toLiquidate, loan.pool);
    }

    /**
     * @dev Sends part of accrued interest to treasury
     * @param token underlying token of loan
     * @param user that repays loan
     * @return amount sended to treasury
     */
    function sendToTreasury(
        IERC20MetadataUpgradeable token,
        address user,
        uint256 interestAccrued
    ) internal returns (uint256) {
        (address treasuryAddress, uint256 treasuryPercent) = settingsProvider.getTreasuryInfo();

        if (treasuryAddress == address(0)) {
            return 0;
        }

        uint256 treasuryAmount = (interestAccrued * treasuryPercent) / 100 ether;

        if (treasuryAmount > 0) {
            token.safeTransferFrom(user, treasuryAddress, treasuryAmount);
            emit SentToTreasury(user, treasuryAddress, treasuryAmount);
        }

        return treasuryAmount;
    }

    function getDelinquencyInfo(
        uint256 loanId
    ) public view returns (LoanLib.DelinquencyInfo memory) {
        LoanLib.Loan memory loan = _loans[loanId];

        IERC20MetadataUpgradeable loanToken = loan.pool.underlyingToken();

        require(_isDelinquent(loan, loanToken), Errors.LOAN_MANAGER_LOAN_IS_LIQUID);

        //Calculate accrued interest for now
        uint256 interestAccrued = getInterest(loanId, block.timestamp);

        if (loan.ltv == type(uint256).max) {
            return LoanLib.DelinquencyInfo(0, loan.amount + interestAccrued, -int256(loan.amount));
        }

        uint256 remainingAmountAsCollateral = priceFeed.convert(
            loan.amount,
            loanToken,
            loan.frozenCollateralToken
        );

        uint256 remainingInterestAsCollateral = priceFeed.convert(
            interestAccrued,
            loanToken,
            loan.frozenCollateralToken
        );

        uint256 remainingTotal = remainingAmountAsCollateral + remainingInterestAsCollateral;

        //Add liquidation fee to remaining total
        uint256 liquidationFee = (remainingAmountAsCollateral * LIQUIDATION_THRESHOLD) / 100 ether;

        //If frozen collateral amount of the loan covers loan principal + loan interest accrued
        if (loan.frozenCollateralAmount >= remainingTotal) {
            //if frozen collateral covers remain total and fee

            if (loan.frozenCollateralAmount > remainingTotal + liquidationFee) {
                return
                    LoanLib.DelinquencyInfo(
                        remainingTotal + liquidationFee,
                        0,
                        int256(interestAccrued)
                    );
            }
            //if frozen collateral covers liquidation fee partially
            return LoanLib.DelinquencyInfo(loan.frozenCollateralAmount, 0, int256(interestAccrued));
        }

        int256 poolValueAdjust;

        //If frozen collateral amount of the loan covers loan principal and part of loan interest accrued
        if (loan.frozenCollateralAmount > remainingAmountAsCollateral) {
            poolValueAdjust = int256(
                priceFeed.convert(
                    loan.frozenCollateralAmount - remainingAmountAsCollateral,
                    loan.frozenCollateralToken,
                    loanToken
                )
            );
        } else if (loan.frozenCollateralAmount < remainingAmountAsCollateral) {
            poolValueAdjust = -int256(
                priceFeed.convert(
                    remainingAmountAsCollateral - loan.frozenCollateralAmount,
                    loan.frozenCollateralToken,
                    loanToken
                )
            );
        }

        //This case will occur if frozen collateral amount of the loan covers exact loan principal
        uint256 notCovered = priceFeed.convert(
            remainingTotal - loan.frozenCollateralAmount,
            loan.frozenCollateralToken,
            loanToken
        );

        return LoanLib.DelinquencyInfo(loan.frozenCollateralAmount, notCovered, poolValueAdjust);
    }

    function isDelinquent(uint256 loanId) public view returns (bool) {
        LoanLib.Loan memory loan = _loans[loanId];
        IERC20MetadataUpgradeable underlyingToken = loan.pool.underlyingToken();
        return _isDelinquent(loan, underlyingToken);
    }

    function _checkScoreToLtv(uint256 ltv) internal view returns (uint16) {
        (uint16 score, bool exists) = getScore(msg.sender);

        require(
            ltv != type(uint256).max || (exists && score != scoreDB.scoreWithoutNfcsId()),
            Errors.NFCS_TOKEN_NOT_MINTED
        );

        return score;
    }

    function _isDelinquent(
        LoanLib.Loan memory loan,
        IERC20MetadataUpgradeable underlyingToken
    ) internal view returns (bool) {
        if (
            loan.status == LoanLib.Status.DEFAULT_PART ||
            loan.status == LoanLib.Status.DEFAULT_FULL_PAID ||
            loan.status == LoanLib.Status.DEFAULT_FULL_LIQUIDATED
        ) {
            return false;
        }
        // if loan is due to liquidate - it is delinquent
        if (block.timestamp > loan.liquidationDate) {
            return true;
        }
        // for over-collateralized loan delinquency should be checked on price as well
        if (loan.ltv < 100 ether) {
            return
                priceFeed.convert(
                    (loan.amount * 100 ether) / (loan.ltv + LIQUIDATION_THRESHOLD),
                    underlyingToken,
                    loan.frozenCollateralToken
                ) > loan.frozenCollateralAmount;
        }
        return false;
    }

    /**
     * @dev Pause all method with ifNotPaused modifier
     */
    function pause() external onlyRole(Roles.PAUSER) {
        _pause();
    }

    /**
     * @dev Unpause early paused all methods with ifNotPaused modifier
     */
    function unpause() external onlyRole(Roles.PAUSER) {
        _unpause();
    }

    function setFuncPaused(string memory name, bool paused) external onlyRole(Roles.PAUSER) {
        _setFuncPaused(name, paused);
    }

    function currentVersion() public pure override(ILoanManager, IVersion) returns (string memory) {
        return LOAN_MANAGER_VERSION;
    }
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../extensions/draft-IERC20PermitUpgradeable.sol";
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

    function safePermit(
        IERC20PermitUpgradeable token,
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

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
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
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
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
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
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;

import "../../interfaces/draft-IERC1822Upgradeable.sol";
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
abstract contract UUPSUpgradeable is Initializable, IERC1822ProxiableUpgradeable, ERC1967UpgradeUpgradeable {
    function __UUPSUpgradeable_init() internal onlyInitializing {
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
     * @dev Check that the execution is not being performed through a delegate call. This allows a function to be
     * callable on the implementing contract but not through proxies.
     */
    modifier notDelegated() {
        require(address(this) == __self, "UUPSUpgradeable: must not be called through delegatecall");
        _;
    }

    /**
     * @dev Implementation of the ERC1822 {proxiableUUID} function. This returns the storage slot used by the
     * implementation. It is used to validate that the this implementation remains valid after an upgrade.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy. This is guaranteed by the `notDelegated` modifier.
     */
    function proxiableUUID() external view virtual override notDelegated returns (bytes32) {
        return _IMPLEMENTATION_SLOT;
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
        _upgradeToAndCallUUPS(newImplementation, new bytes(0), false);
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
        _upgradeToAndCallUUPS(newImplementation, data, true);
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/AccessControl.sol)

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
        _checkRole(role);
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
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
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
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
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
     *
     * May emit a {RoleGranted} event.
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
     *
     * May emit a {RoleRevoked} event.
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
     *
     * May emit a {RoleRevoked} event.
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
     * May emit a {RoleGranted} event.
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
     *
     * May emit a {RoleGranted} event.
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
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

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
pragma solidity ^0.8.9;
import {LoanLib} from "../lib/LoanLib.sol";
import {IPool} from "./IPool.sol";
import {ICollateralManager} from "./ICollateralManager.sol";
import {INFCS} from "./INFCS.sol";
import {IPriceFeed} from "./IPriceFeed.sol";
import {ISettingsProvider} from "./ISettingsProvider.sol";
import {IScoreDB} from "./IScoreDB.sol";
import {ILimitManager} from "./ILimitManager.sol";

import {IERC20MetadataUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";

interface ILoanManager {
    event LoanCreated(
        address indexed borrower,
        address indexed pool,
        uint256 indexed loanId,
        uint256 apr,
        uint256 amount
    );

    event LoanPayed(
        address payer,
        address indexed borrower,
        address indexed pool,
        uint256 indexed loanId,
        uint256 interestAccrued,
        uint256 repayAmount,
        uint256 outstanding
    );

    event LoanClosed(address indexed borrower, address indexed pool, uint256 indexed loanId);

    event LoanLiquidated(
        address indexed borrower,
        IPool indexed pool,
        uint256 indexed loanId,
        uint256 interestAccrued,
        uint256 timestamp,
        uint256 remainingLoanAmount, // loan amount which was not covered by collateral => remains to be paid
        uint256 liquidatedCollateral, // amount of liquidated collateral
        uint256 unfrozenCollateral, // amount of collateral user received back
        int256 poolValueAdjustment // poolValue adjustment
    );

    event CollateralManagerChanged(
        address user,
        ICollateralManager old,
        ICollateralManager updated
    );
    event NFCSChanged(address user, INFCS old, INFCS updated);
    event PriceFeedChanged(address user, IPriceFeed old, IPriceFeed updated);
    event SettingsProviderChanged(address user, ISettingsProvider old, ISettingsProvider updated);
    event ScoreDBChanged(address user, IScoreDB old, IScoreDB updated);
    event LimitManagerChanged(address user, ILimitManager old, ILimitManager updated);
    event StatusChanged(
        address user,
        LoanLib.Status indexed from,
        LoanLib.Period indexed period,
        LoanLib.Action indexed action,
        LoanLib.Status old,
        LoanLib.Status updated
    );
    event SentToTreasury(address user, address treasuryAddress, uint256 treasuryAmount);

    struct BorrowVars {
        uint16 score;
        uint256 loanId;
        IERC20MetadataUpgradeable underlyingToken;
    }

    function loans(uint256) external view returns (LoanLib.Loan memory);

    function liquidate(uint256 loanId, string memory version)
        external
        returns (
            IERC20MetadataUpgradeable collateralToken,
            IERC20MetadataUpgradeable underlyingToken,
            uint256 collateralAmount,
            IPool pool
        );

    function getDelinquencyInfo(uint256 loanId)
        external
        view
        returns (LoanLib.DelinquencyInfo memory info);

    function currentVersion() external view returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/**
 * @title IVersion
 * @author RociFi Labs
 * @notice Interface for implementing versioning of contracts
 * @notice Used to mark backwards-incompatible changes to the contract logic.
 * @notice All interfaces of versioned contracts should inherit this interface
 */

interface IVersion {
    /**
     * @notice returns the current version of the contract
     */
    function currentVersion() external pure returns (string memory);

    /**
     * @notice converts string to bytes32
     */
    function getVersionAsBytes(string memory v) external pure returns (bytes32 result);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/**
 * @title Errors library
 * @author RociFi Labs
 * @notice Defines the error messages emitted by the different contracts of the RociFi protocol
 * @dev Error messages prefix glossary:
 *  - NFCS = NFCS
 *  - POOL = Pool
 *  - SettingsProvider = SettingsProvider
 *  - LOAN_MANAGER = LoanManager
 *  - COLLATERAL_MANAGER = CollateralManager
 *  - PRICE_FEED = PriceFeed
 *  - VERSION = Version
 */
library Errors {
    string public constant NFCS_TOKEN_MINTED = "0"; //  Token already minted
    string public constant NFCS_TOKEN_NOT_MINTED = "1"; //  No token minted for address
    string public constant NFCS_ADDRESS_BUNDLED = "2"; // Address already bundled
    string public constant NFCS_WALLET_VERIFICATION_FAILED = "3"; //  Wallet verification failed
    string public constant NFCS_NONEXISTENT_TOKEN = "4"; // Nonexistent NFCS token
    string public constant NFCS_TOKEN_HAS_BUNDLE = "5"; //  Token already has an associated bundle
    string public constant NFCS_TOKEN_HAS_NOT_BUNDLE = "6"; //  Token does not have an associated bundle
    string public constant NFCS_IMAGE_FEE = "7"; //  User didn't pay enough fee to set custom NFCS image
    string public constant NFCS_TREASURY_ADDRESS = "8"; //  Treasury address is not set

    string public constant POOL_TOTAL_SUPPLY_ZERO = "100"; // Zero totalSupply() pool
    string public constant POOL_VALUE_LT_ZERO = "101"; // pooValueUpdate leads to poolValue < 0
    string public constant POOL_LOCKUP = "102"; // withdraw before passing lockup period

    string public constant LOAN_MANAGER_ZERO_REPAY = "200"; //Loan repay zero
    string public constant LOAN_MANAGER_LOAN_AMOUNT_ZERO = "201"; //Loan amount is zero
    string public constant LOAN_MANAGER_LOAN_IS_LIQUID = "202"; //Loan is liquid
    string public constant LOAN_MANAGER_NATIVE_RETURN = "203"; //Can't return native token exceeds
    string public constant LOAN_MANAGER_LOAN_PARAMS_LIMIT = "204"; //Amount exceeds limit

    string public constant COLLATERAL_MANAGER_TOKEN_NOT_SUPPORTED = "300"; // CollateralManager does not support provided token
    string public constant COLLATERAL_MANAGER_FREEZER_OR_USER = "302"; // Provided contract / user address is not allowed to freeze/unfreeze collateral
    string public constant COLLATERAL_MANAGER_INSUFFICIENT_AMOUNT = "303"; // Not enough funds to perform transaction
    string public constant COLLATERAL_MANAGER_FROZEN_INSUFFICIENT_AMOUNT = "304"; // Not enough funds to perform transaction
    string public constant COLLATERAL_MANAGER_WRAPPER_ZERO = "305"; // Wrapper are not set
    string public constant COLLATERAL_MANAGER_NATIVE_TRANSFER = "306"; // Native token transfer error
    string public constant COLLATERAL_MANAGER_TOKEN_IS_NOT_WRAPPER = "307"; // Provided token is not equal to wrapper token

    string public constant SCORE_DB_VERIFICATION = "401"; // Unverified score
    string public constant SCORE_DB_UNKNOWN_FETCHING_SCORE = "402"; // Unknown error fetching score.
    string public constant SCORE_DB_OUTDATED_SIGNATURE = "403"; // Attempt to update score with outdated signature

    string public constant SETTINGS_PROVIDER_POOL_NOT_SET = "506"; //  Pool is not set
    string public constant SETTINGS_PROVIDER_SCORE_NOT_SET = "507"; //  Score is not set in pool
    string public constant SETTINGS_PROVIDER_LTV_NOT_SET = "508"; //  Ltv is not set in pool for score
    string public constant SETTINGS_PROVIDER_DURATION_NOT_SET = "509"; //  Duration is not set in pool for score
    string public constant SETTINGS_PROVIDER_INTEREST_NOT_SET = "510"; //  Interest is not set in pool for score-ltv-duration
    string public constant SETTINGS_PROVIDER_COLLATERAL_NOT_SET = "511"; //  Collateral is not set in pool
    string public constant SETTINGS_PROVIDER_SCORE_OUTDATED = "512"; //  Score should be updated

    string public constant LIMIT_MANAGER_MIN_LIMIT = "601"; //  Not reaching min required limit
    string public constant LIMIT_MANAGER_MAX_LIMIT = "602"; //  Exceeding max allowed limit
    string public constant LIMIT_MANAGER_MAX_LIMIT_SCORE = "603"; //  Exceeding max allowed limit for score
    string public constant LIMIT_MANAGER_LOAN_NUMBER = "604"; //  Loan number is exceeded
    string public constant LIMIT_MANAGER_REPAY_OR_LIQUIDATE = "605"; // Amount should be lesser or equal
    string public constant LIMIT_MANAGER_OPEN_LOANS = "606"; // User open loans value should be greater then zero

    string public constant PRICE_FEED_TOKEN_NOT_SUPPORTED = "700"; // Token is not supported
    string public constant PRICE_FEED_TOKEN_BELOW_ZERO = "701"; // Token below zero price

    string public constant LIQUIDATOR_MINIMUM_SWAP_FAILED = "801"; // Swap amount out are less than minimum amount out
    string public constant LIQUIDATOR_LOAN_MANAGER_APPROVE = "802"; //Liquidator approve failed
    string public constant LIQUIDATOR_INSUFFICIENT_FUNDS = "803"; //Liquidator insufficient funds
    string public constant LIQUIDATOR_NOTHING_TO_SWAP = "804"; //Liquidator insufficient funds

    string public constant VERSION = "1000"; // Incorrect version of contract
    string public constant ZERO_VALUE = "1001"; // Zero value
    string public constant ZERO_ADDRESS = "1003"; // Zero address
    string public constant NO_ELEMENT_IN_ARRAY = "1005"; //  there is no element in array
    string public constant ELEMENT_IN_ARRAY = "1006"; //  there is already element in array
    string public constant ARGUMENTS_LENGTH = "1007"; // Arguments length are different
    string public constant ROCI_ATTESTATION_SIGNATURE = "1008"; // AttestationProxy: Invalid signature

    string public constant NAMED_NFT_INCORRECT_LENGTH = "1100"; // Incorrect length on name
    string public constant NAMED_NFT_TOKEN_NOT_EXISTS = "1101"; // NFT token doesn't exists
    string public constant NAMED_NFT_OWNER = "1102"; // Owner of token are different
    string public constant NAMED_NFT_ONE_NAME = "1103"; // Nfcs consist only one name
    string public constant NAMED_NFT_NAME_NOT_FOUND = "1104"; // Name not found for NFCSid
    string public constant NAMED_NFT_NAME_EXISTS = "1105"; //Name already exists
    string public constant NAMED_NFT_BLOCKED = "1106"; //Name in blacklist
    string public constant NAMED_NFT_CHAR_NOT_ALLOWED = "1107"; //Char not allowed
    string public constant NAMED_NFT_NAMES_LIMIT = "1108"; // Names per nfcs limit
    string public constant NAMED_NFT_INSUFFICIENT_FEE_VALUE = "1109"; // Names per nfcs limit
    string public constant NAMED_NFT_TRANSFER = "1110"; // Names per nfcs limit
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

library Roles {
    bytes32 public constant ADMIN =
        bytes32(0xb055000000000000000000000000000000000000000000000000000000000000); // Admin can setup parameters and maintain protocol

    bytes32 public constant LOAN_MANAGER =
        bytes32(0xdeb7000000000000000000000000000000000000000000000000000000000000); // LoanManager can update pools params

    bytes32 public constant LIQUIDATOR =
        bytes32(0xc105e00000000000000000000000000000000000000000000000000000000000); // Liquidator contract

    bytes32 public constant UPDATER =
        bytes32(0xc105e10000000000000000000000000000000000000000000000000000000000); // Updater can update contracts

    bytes32 public constant PAUSER =
        bytes32(0xc105e12000000000000000000000000000000000000000000000000000000000); // Can pause contracts

    bytes32 public constant LIQUIDATION_BOT =
        bytes32(0xdeaf000000000000000000000000000000000000000000000000000000000000); // Liquidation bot account

    bytes32 public constant NAMED_NFT =
        bytes32(0x4a8e000000000000000000000000000000000000000000000000000000000000);

    bytes32 public constant POOL_FIXER =
        bytes32(0x4140000000000000000000000000000000000000000000000000000000000000);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {IPool} from "../interfaces/IPool.sol";
import {IERC20MetadataUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";

/*
 * @title Loan Library for RociFi Cydonia
 * @author RociFi Labs
 * @notice Manages loan structs, statuses.
 */

library LoanLib {
    event LoanStatusChanged(uint256 indexed loanId, LoanLib.Status from, LoanLib.Status to);

    // PERSIST -> Nothing to change
    // NEW -> Newly created, initial stage of any loan.
    // PAID_EARLY_PART -> Partially repaid before maturity date.
    // PAID_EARLY_FULL -> Final stage. Loan paid in full before or on maturity date time.
    // PAID_LATE_PART -> Partially repaid before grace period ends.
    // PAID_LATE_FULL -> Final stage. Loan paid in full after maturity date and before grace period ends.
    // DEFAULT_PART -> Loan is liquidated and collateral didn’t cover the amount due. Loan still has an outstanding balance.
    // DEFAULT_FULL_LIQUIDATED -> Final stage. Loan is liquidated and collateral covers the amount due on the loan. Loan will not accept further repayments.
    // DEFAULT_FULL_PAID -> Final stage. DEFAULT_PART loan which is paid in full. Loan will not accept further repayments.
    /**
     * @dev Status enum represents possible states of loan
     */
    enum Status {
        PERSIST,
        NEW,
        PAID_EARLY_PART,
        PAID_EARLY_FULL,
        PAID_LATE_PART,
        PAID_LATE_FULL,
        DEFAULT_PART,
        DEFAULT_FULL_LIQUIDATED,
        DEFAULT_FULL_PAID
    }

    // BEFORE_MATURITY -> Before maturity date
    // BEFORE_LIQUIDATION -> After maturity date but before liquidation
    // AFTER_LIQUIDATION -> After liquidation
    /**
     * @dev Period enum represents loan life cycles
     */
    enum Period {
        BEFORE_MATURITY,
        BEFORE_LIQUIDATION,
        AFTER_LIQUIDATION
    }

    // PARTIAL_REPAY -> Partial repayment
    // FULL_REPAY -> Full repayment
    // LIQUIDATION_COVERED -> Liquidation with outstanding = 0
    // LIQUIDATION_UNCOVERED -> Liquidation with outstanding > 0
    /**
     * @dev Action enum represents actions that can happen on loan
     */
    enum Action {
        REPAY_PARTIAL,
        REPAY_FULL,
        LIQUIDATION_COVERED,
        LIQUIDATION_NOT_COVERED
    }

    /**
     * @dev Loan instance structure
     * @param borrower of the loan
     * @param amount is loan principal
     * @param apr annual percentage rate to a moment of loan creation
     * @param ltv loan to value factor
     * @param lateFee fee that is applied to loan interest after maturity date will be passed
     * @param issueDate is a timestamp of loan creation
     * @param dueDate is a timestamp of maturity date of the loan
     * @param liquidationDate is a timestamp after that loan will be marked as ready for liquidation
     * @param lastRepay is a timestamp of last loan repayment or liquidation
     * @param frozenCollateralAmount amount of collateral frozen to cover loan
     * @param frozenCollateralToken collateral token address
     * @param pool pool address where loan has been taken
     * @param status current status of loan
     */
    struct Loan {
        address borrower;
        uint256 amount;
        uint256 apr;
        uint256 ltv;
        uint256 lateFee;
        uint256 issueDate;
        uint256 dueDate;
        uint256 liquidationDate;
        uint256 lastRepay;
        uint256 frozenCollateralAmount;
        IERC20MetadataUpgradeable frozenCollateralToken;
        IPool pool;
        Status status;
    }

    /**
     * @dev Loan liquidation info
     * @param toLiquidate amount of collateral that needs to be liquidated
     * @param notCovered amount of loan that will stay uncovered
     * @param poolValueAdjust amount by which pool value needs to be adjusted
     */
    struct DelinquencyInfo {
        uint256 toLiquidate;
        uint256 notCovered;
        int256 poolValueAdjust;
    }

    /**
     * @dev Status matrix is a 3 dimensional transition stable
     * @notice Current status is depends of last status, current period and action applied to loan
     */
    struct StatusMatrix {
        mapping(Status => mapping(Period => mapping(Action => Status))) _m;
    }

    /**
     * @dev Updates loan status
     * @param loan struct instance
     * @param loanId id of the loan
     * @param actionType action applied to loan
     * @param table transitions table
     * @notice loan period calculated from current block.timestamp and loan params
     */
    function updateStatus(
        Loan storage loan,
        uint256 loanId,
        Action actionType,
        StatusMatrix storage table
    ) internal {
        Period period = block.timestamp > loan.liquidationDate
            ? Period.AFTER_LIQUIDATION
            : block.timestamp > loan.dueDate
            ? Period.BEFORE_LIQUIDATION
            : Period.BEFORE_MATURITY;

        Status newStatus = table._m[loan.status][period][actionType];

        if (newStatus != Status.PERSIST) {
            emit LoanStatusChanged(loanId, loan.status, newStatus);
            loan.status = newStatus;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {IVersion} from "../interfaces/IVersion.sol";
import {Errors} from "./Errors.sol";

/*
 * @title Version
 * @author RociFi Labs
 * @notice  Abstract contract for implementing versioning functionality
 * @notice Used to mark backwards-incompatible changes to the contract logic.
 * @notice checkVersion modifier should be applied to all external mutating methods
 */

abstract contract Version is IVersion {
    /**
     * @notice converts string to bytes32
     */
    function getVersionAsBytes(string memory v) public pure override returns (bytes32 result) {
        if (bytes(v).length == 0) {
            return 0x0;
        }

        assembly {
            result := mload(add(v, 32))
        }
    }

    /**
     * @notice
     * Controls the call of mutating methods in versioned contract.
     * The following modifier reverts unless the value of the `versionToCheck` argument
     * matches the one provided in currentVersion method.
     */
    modifier checkVersion(string memory versionToCheck) {
        require(
            getVersionAsBytes(this.currentVersion()) == getVersionAsBytes(versionToCheck),
            Errors.VERSION
        );
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

/*
 * @title Selective Pausable Contract for RociFi Cydonia
 * @author RociFi Labs
 * @notice Allows to pause functions independently without effecting global pausable
 * @notice Inheritance from PausableUpgradable allows to add minimal functionality to support both global and selective pausability
 */

abstract contract SelectivePausable is PausableUpgradeable {
    //Function name to function selector mapping
    mapping(string => bytes4) internal funcNameSelector;
    //Function selector to function name mapping
    mapping(bytes4 => string) public selectorFuncName;

    //Function paused/unpaused mapping
    mapping(bytes4 => bool) public funcSelectorPaused;

    event PausableMethodAdded(string name, bytes4 selector, uint256 timestamp);
    event MethodPaused(string name, bool paused, uint256 timestamp);

    /**
     * @dev Adds selective pausability to function name using selector
     * @param name function name as string
     * @param selector function selector as bytes4; can be achieved using this.function.selector
     */
    function _addPausableFunc(string memory name, bytes4 selector) internal {
        funcNameSelector[name] = selector;
        selectorFuncName[selector] = name;
        emit PausableMethodAdded(name, selector, block.timestamp);
    }

    /**
     * @dev Pause/unpause function by name
     * @param name function name as string
     * @param paused true to pause
     */
    function _setFuncPaused(string memory name, bool paused) internal virtual {
        require(funcNameSelector[name] != bytes4(0), "Unknown function.");
        funcSelectorPaused[funcNameSelector[name]] = paused;
        emit MethodPaused(name, paused, block.timestamp);
    }

    /**
     * @dev whenNotPaused modifier can't be overridden, thus we added out modifier that implements both functionalities
     */
    modifier ifNotPaused() {
        _requireNotPaused();
        require(
            funcSelectorPaused[msg.sig] == false,
            string(bytes.concat(bytes(selectorFuncName[msg.sig]), bytes(" function is on pause.")))
        );
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

string constant COLLATERAL_MANAGER_VERSION = "2.0.0";
string constant LIMIT_MANAGER_VERSION = "2.0.0";
string constant LOAN_MANAGER_VERSION = "2.0.3";
string constant NFCS_VERSION = "2.0.1";
string constant POOL_VERSION = "2.0.1";
string constant PRICE_FEED_VERSION = "2.0.1";
string constant SCORE_DB_VERSION = "2.0.1";
string constant SETTINGS_PROVIDER_VERSION = "2.0.1";
string constant LIQUIDATOR_VERSION = "2.0.2";
string constant NAMED_NFT_VERSION = "1.0.0";
string constant NFCS_ATTESTATION_VERSION = "2.0.0";

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

// value for mapping USD
address constant USD_ADDRESS = 0x0000000000000000000000000000000000000001;

uint256 constant ONE_YEAR = 60 * 60 * 24 * 365;

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
interface IERC20PermitUpgradeable {
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822ProxiableUpgradeable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeaconUpgradeable.sol";
import "../../interfaces/draft-IERC1822Upgradeable.sol";
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
    function _upgradeToAndCallUUPS(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        // Upgrades from old implementations will perform a rollback test. This test requires the new
        // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // this special case will break upgrade paths from old UUPS implementation to new ones.
        if (StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822ProxiableUpgradeable(newImplementation).proxiableUUID() returns (bytes32 slot) {
                require(slot == _IMPLEMENTATION_SLOT, "ERC1967Upgrade: unsupported proxiableUUID");
            } catch {
                revert("ERC1967Upgrade: new implementation is not UUPS");
            }
            _upgradeToAndCall(newImplementation, data, forceCall);
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/StorageSlot.sol)

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
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
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
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

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

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
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
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
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
pragma solidity ^0.8.9;

import {IERC20MetadataUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";

interface IPool {
    event LiquidityDeposited(
        uint256 timestamp,
        address indexed user,
        uint256 amountUnderlyingToken,
        uint256 amountRToken
    );

    event LiquidityWithdrawn(
        uint256 timestamp,
        address indexed user,
        uint256 amountUnderlyingToken,
        uint256 amountRToken
    );

    event PoolValueUpdated(
        address indexed loanManager,
        uint256 old,
        uint256 updated,
        uint256 timestamp
    );

    event LoanManagerApproved(address loanManager, uint256 amount);

    event LockupPeriodChanged(address user, uint256 old, uint256 updated, uint256 timestamp);

    function underlyingToken() external view returns (IERC20MetadataUpgradeable);

    function decimals() external view returns (uint8);

    function updatePoolValue(int256) external;

    function deposit(uint256, string memory) external;

    function withdraw(uint256, string memory) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {IERC20MetadataUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import {IWrapper} from "./IWrapper.sol";

interface ICollateralManager {
    event AllowedTokenSet(
        uint256 timestamp,
        IERC20MetadataUpgradeable indexed token,
        bool indexed isSet
    );
    event CollateralAdded(address indexed user, IERC20MetadataUpgradeable token, uint256 amount);
    event CollateralClaimed(address indexed user, IERC20MetadataUpgradeable token, uint256 amount);
    event CollateralFrozen(
        address indexed user,
        address indexed freezer,
        IERC20MetadataUpgradeable token,
        uint256 amount
    );
    event CollateralUnfrozen(
        address indexed user,
        address indexed freezer,
        IERC20MetadataUpgradeable token,
        uint256 amount
    );
    event CollateralSeized(
        address indexed liquidator,
        address indexed user,
        address indexed freezer,
        IERC20MetadataUpgradeable token,
        uint256 amount
    );
    event WrapperChanged(address user, IWrapper old, IWrapper updated, uint256 timestamp);
    event CollateralsAdded(
        address user,
        IERC20MetadataUpgradeable[] collaterals,
        uint256 timestamp
    );
    event CollateralsRemoved(
        address user,
        IERC20MetadataUpgradeable[] collaterals,
        uint256 timestamp
    );

    function wrapper() external view returns (IWrapper);

    function collateralToUserToAmount(IERC20MetadataUpgradeable, address)
        external
        view
        returns (uint256);

    function freeze(
        address user,
        IERC20MetadataUpgradeable token,
        uint256 amount
    ) external;

    function unfreeze(
        address user,
        IERC20MetadataUpgradeable token,
        uint256 amount
    ) external;

    function addCollateral(
        address user,
        IERC20MetadataUpgradeable token,
        uint256 amount
    ) external payable;

    function claimCollateral(
        address user,
        IERC20MetadataUpgradeable token,
        uint256 amount
    ) external;

    function seize(
        address liquidator,
        IERC20MetadataUpgradeable token,
        address user,
        uint256 amount
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface INFCS {
    // Receives an address array, verifies ownership of address, mints a token, stores the bundle against token ID, sends token to msg.sender
    function mintToken(
        address[] calldata bundle,
        bytes[] calldata signatures,
        string calldata imageUrl,
        string calldata version
    ) external payable;

    // Receives a tokenId, returns corresponding address bundle
    function getBundle(uint256 tokenId) external view returns (address[] memory);

    // Receives an address, returns tokenOwned by it if any, otherwise reverts
    function getToken(address tokenOwner) external view returns (uint256);

    //Returns primary address for secondary address of bundle.
    function getPrimaryAddress(address user) external view returns (address);
}

// needed for compatibility of storage layout in NFCS contract
interface IAddressBook {

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {IERC20MetadataUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";

interface IPriceFeed {
    function convert(
        uint256 amount,
        IERC20MetadataUpgradeable token,
        IERC20MetadataUpgradeable targetToken
    ) external view returns (uint256);

    event PriceFeedSet(
        uint256 timestamp,
        address indexed priceFeed,
        IERC20MetadataUpgradeable indexed from,
        IERC20MetadataUpgradeable indexed to,
        uint8 fromDecimals
    );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import {IPool} from "./IPool.sol";

import {IPool} from "./IPool.sol";
import {IERC20MetadataUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";

interface ISettingsProvider {
    struct LoanSettings {
        InterestSettings interestSettings;
        uint256 gracePeriod;
        uint256 lateFee;
    }

    struct InterestSettings {
        uint256 interest;
        uint256 limit;
    }

    struct InterestSet {
        uint256 ltv;
        uint256 duration;
        InterestSettings interestSettings;
    }

    event TreasuryAddressChanged(address user, address old, address updated, uint256 timestamp);
    event TreasuryPercentChanged(address user, uint256 old, uint256 updated, uint256 timestamp);
    event PoolToLateFeeChanged(
        address user,
        IPool indexed pool,
        uint256 old,
        uint256 updated,
        uint256 timestamp
    );
    event PoolToGracePeriodChanged(
        address user,
        IPool indexed pool,
        uint256 old,
        uint256 updated,
        uint256 timestamp
    );
    event PoolsAdded(address user, IPool[] pools, uint256 timestamp);
    event PoolsRemoved(address user, IPool[] pools, uint256 timestamp);
    event PoolCollateralsAdded(
        address user,
        IPool indexed pool,
        IERC20MetadataUpgradeable[] collaterals,
        uint256 timestamp
    );
    event PoolCollateralsRemoved(
        address user,
        IPool indexed pool,
        IERC20MetadataUpgradeable[] collaterals,
        uint256 timestamp
    );
    event PoolScoresAdded(address user, IPool indexed pool, uint16[] scores, uint256 timestamp);
    event PoolScoresRemoved(address user, IPool indexed pool, uint16[] scores, uint256 timestamp);
    event PoolToScoreLtvsAdded(
        address user,
        IPool indexed pool,
        uint16 indexed score,
        uint256[] ltvs,
        uint256 timestamp
    );
    event PoolToScoreLtvsRemoved(
        address user,
        IPool indexed pool,
        uint16 indexed score,
        uint256[] ltvs,
        uint256 timestamp
    );
    event PoolToScoreDurationsAdded(
        address user,
        IPool indexed pool,
        uint16 indexed score,
        uint256[] durations,
        uint256 timestamp
    );
    event PoolToScoreDurationsRemoved(
        address user,
        IPool indexed pool,
        uint16 indexed score,
        uint256[] durations,
        uint256 timestamp
    );
    event PoolToScoreToLtvToDurationToInterestChanged(
        address user,
        IPool indexed pool,
        uint16 indexed score,
        uint256 indexed ltv,
        uint256 duration,
        InterestSettings old,
        InterestSettings updated,
        uint256 timestamp
    );

    function getLoanSettings(
        IPool pool,
        uint16 score,
        uint256 ltv,
        uint256 duration,
        IERC20MetadataUpgradeable collateral
    ) external view returns (LoanSettings memory);

    function getTreasuryInfo() external view returns (address, uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IScoreDB {
    event ScoreUpdated(uint256 timestamp, uint256 indexed tokenId, uint16 indexed score);
    event NFCSSignerAddressChanged(uint256 timestamp, address indexed nfcsSignerAddress);

    event MinScoreChanged(address user, uint256 old, uint256 updated, uint256 timestamp);
    event MaxScoreChanged(address user, uint256 old, uint256 updated, uint256 timestamp);
    event ScoreValidityPeriodChanged(address user, uint256 old, uint256 updated, uint256 timestamp);

    struct Score {
        uint256 timestamp;
        uint256 tokenId;
        uint16 creditScore;
    }

    function getScore(uint256 tokenId) external view returns (Score memory);

    function getCreditScoreAndValidate(uint256 tokenId) external view returns (uint16);

    function scoreWithoutNfcsId() external view returns (uint16);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {IPool} from "./IPool.sol";

interface ILimitManager {
    event PoolToMaxBorrowLimitChanged(
        address user,
        IPool indexed pool,
        uint256 old,
        uint256 updated,
        uint256 timestamp
    );
    event PoolToMinBorrowLimitChanged(
        address user,
        IPool indexed pool,
        uint256 old,
        uint256 updated,
        uint256 timestamp
    );
    event PoolToScoreToBorrowLimitChanged(
        address user,
        IPool indexed pool,
        uint16 indexed score,
        uint256 old,
        uint256 updated,
        uint256 timestamp
    );
    event PoolToMaxLoanNumberChanged(
        address user,
        IPool indexed pool,
        uint256 old,
        uint256 updated,
        uint256 timestamp
    );

    function onBorrow(
        address user,
        IPool pool,
        uint16 score,
        uint256 amount
    ) external;

    function onRepayOrLiquidate(
        address user,
        IPool pool,
        uint256 amount
    ) external;

    function onLoanFulfillment(address user, IPool pool) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IWrapper {
    function deposit() external payable;

    function withdraw(uint256 wad) external;

    function totalSupply() external view returns (uint256);

    function approve(address guy, uint256 wad) external returns (bool);

    function transfer(address dst, uint256 wad) external returns (bool);

    function transferFrom(
        address src,
        address dst,
        uint256 wad
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}