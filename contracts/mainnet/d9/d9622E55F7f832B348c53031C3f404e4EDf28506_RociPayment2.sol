/// SPDX-License-Identifier: None
pragma solidity ^0.8.0;
import {SafeERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import {IERC20MetadataUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import {ScoreDBInterface} from "../interfaces/ScoreDBInterface.sol";
import {Errors} from "../libraries/Errors.sol";
import {ROLE_ADMIN, ROLE_LIQUIDATOR, ROLE_BONDS, ROLE_PAUSER, ROLE_NFCS, ROLE_ORACLE, ROLE_COLLATERAL_MANAGER, ONE_HUNDRED_PERCENT, CONTRACT_DECIMALS, ROLE_PRICE_FEED, DEAD} from "../Globals.sol";
import {AddressHandlerAbstract} from "../utilities/AddressHandlerAbstract.sol";
import {Loan} from "../libraries/Loan.sol";
import {ICollateralManager} from "../interfaces/newInterfaces/managers/ICollateralManager.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {Structs} from "../libraries/Structs.sol";
import {IPriceFeed} from "../interfaces/IPriceFeed.sol";
import {IpoolInvestor} from "../interfaces/newInterfaces/investor/IpoolInvestor.sol";
import {NFCSInterface} from "../NFCS/NFCSInterface.sol";
import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import {IAddressBook} from "../interfaces/IAddressBook.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import {IRoci} from "./IRoci.sol";

contract RociPayment2 is
    Initializable,
    AddressHandlerAbstract,
    PausableUpgradeable,
    UUPSUpgradeable
{
    using SafeERC20Upgradeable for IERC20MetadataUpgradeable;
    using Loan for Loan.loan;

    IAddressBook addressBook;
    mapping(uint256 => Loan.loan) internal _loanLookup;
    mapping(address => Loan.globalInfo) internal globalLoanLookup;
    mapping(uint256 => Loan.globalInfo) internal nfcsLoanLookup;
    mapping(address => uint256[]) public loanIDs;
    mapping(address => uint256[]) internal usersActiveLoans;
    mapping(address => bool) public allowedPoolInvestors;

    event LoanRepaid(
        uint256 timestamp,
        address indexed borrower,
        address indexed repayer,
        uint256 indexed loanId,
        uint256 principal,
        uint256 amountRepaid,
        Loan.Status status
    );
    event CollateralDeposited(
        uint256 timestamp,
        address indexed borrower,
        address indexed token,
        uint256 indexed amount
    );
    event CollateralWithdrawn(
        uint256 timestamp,
        address indexed borrower,
        address indexed token,
        uint256 indexed amount
    );
    event SetAllowedPoolInvestor(address pool, bool isSet);
    event Liquidated(uint256 timestamp, uint256 indexed loanId, address borrower, bool success);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address _addressBook) public initializer {
        addressBook = IAddressBook(_addressBook);
    }

    function setAllowedPoolInvestor(address _pool, bool _isSet) external onlyRole(ROLE_ADMIN) {
        allowedPoolInvestors[_pool] = _isSet;
        emit SetAllowedPoolInvestor(_pool, _isSet);
    }

    function getAddressBook() public view override returns (IAddressBook) {
        return addressBook;
    }

    function migration(address borrower) external {
        address roci = 0xeD7f6f693178c7F8972A558fCa3FE5A6E2F12Bc2;
        uint256 numberOfLoans = IRoci(roci).getNumberOfLoans(borrower);
        require(numberOfLoans > 0, "No loans to transfer");
        uint256[] memory currentState = loanIDs[borrower];
        require(currentState.length == 0, "Loans were already transferred");
        for (uint256 i = 0; i < numberOfLoans; i++) {
            uint256 loanId = IRoci(roci).loanIDs(borrower, i);
            loanIDs[borrower].push(loanId);
            Loan.loan memory loan = IRoci(roci).loanLookup(loanId);
            if (loan.status != Loan.Status.CLOSED) {
                usersActiveLoans[borrower].push(loanId);
            }
            _loanLookup[loanId] = loan;
        }
    }

    // function liquidateLoans(uint256[] memory _ids, string memory version)
    //     external
    //     whenNotPaused
    //     onlyRole(ROLE_LIQUIDATOR)
    // {
    //     uint8 numOfLiquidated = 0;
    //     for (uint256 i = 0; i < _ids.length; i++) {
    //         uint256 id = _ids[i];
    //         if (isDelinquent(id)) {
    //             liquidateLoan(_ids[i], msg.sender);
    //             numOfLiquidated++;
    //             updateUserActiveLoans(_loanLookup[id], id);
    //             emit Liquidated(block.timestamp, id, _loanLookup[id].borrower, true);
    //         }
    //     }
    //     require(numOfLiquidated != 0, Errors.PAYMENT_LOAN_NOT_DELINQUENT);
    // }

    function isScoreValidForBorrow(
        address user,
        uint256 nfcsId,
        uint16[] memory validScores
    ) external view returns (bool) {
        if (validScores.length == 0) {
            return false;
        }

        uint16 score = ScoreDBInterface(lookup(ROLE_ORACLE)).getScore(nfcsId).creditScore;

        bool isValidPool = false;
        for (uint8 i = 0; i < validScores.length; i++) {
            if (score == validScores[i]) {
                isValidPool = true;
            }
        }

        if (usersActiveLoans[user].length == 0) {
            return isValidPool;
        }

        return isValidPool && score == _loanLookup[usersActiveLoans[user][0]].score;
    }

    function getNFCSTotalOutstanding(uint256 _nfcsId) external view returns (uint256) {
        return (Loan.getOutstanding(nfcsLoanLookup[_nfcsId]));
    }

    function getUserTotalOutstanding(uint256 _nfcsId) external view returns (uint256) {
        address user = IERC721(lookup(ROLE_NFCS)).ownerOf(_nfcsId);
        return (Loan.getOutstanding(globalLoanLookup[user]));
    }

    function getTotalOutstanding() external view returns (uint256) {
        return (Loan.getOutstanding(globalLoanLookup[address(0)]));
    }

    function addCollateral(
        address _from,
        address _ERC20Contract,
        uint256 _amount
    ) external whenNotPaused {
        ICollateralManager(lookup(ROLE_COLLATERAL_MANAGER)).deposit(_from, _ERC20Contract, _amount);
        emit CollateralDeposited(block.timestamp, _from, _ERC20Contract, _amount);
    }

    function issueBonds(uint256 _id)
        public
        whenNotPaused
        onlyRole(ROLE_BONDS)
        returns (uint256, address)
    {
        Loan.loan storage ln = _loanLookup[_id];
        Loan.issue(
            ln,
            globalLoanLookup[ln.borrower],
            globalLoanLookup[address(0)],
            nfcsLoanLookup[ln.nfcsID]
        );

        NFCSInterface nfcs = NFCSInterface(lookup(ROLE_NFCS));
        (, uint128 globalLimit, , uint128 userGlobalLimit) = nfcs.getLimits();
        (, uint128 nfcsGlobalLimit) = nfcs.getNFCSLimits(ln.nfcsID);
        (uint256 gloablOutstanding, uint256 userOutstanding, uint256 nfcsOutstanding) = nfcs
            .getTotalOutstanding(ln.nfcsID);
        if (nfcsGlobalLimit != 0) {
            Loan.limitGlobalCheck(nfcsOutstanding, nfcsGlobalLimit, Errors.LOAN_TOTAL_LIMIT_NFCS);
        } else {
            Loan.limitGlobalCheck(userOutstanding, userGlobalLimit, Errors.LOAN_TOTAL_LIMIT_USER);
        }

        Loan.limitGlobalCheck(gloablOutstanding, globalLimit, Errors.LOAN_TOTAL_LIMIT);
        Structs.Score memory score = ScoreDBInterface(lookup(ROLE_ORACLE)).getScore(ln.nfcsID);
        require(
            block.timestamp >= score.timestamp &&
                block.timestamp - score.timestamp <= addressBook.scoreValidityPeriod(),
            Errors.PAYMENT_NFCS_OUTDATED
        );
        (uint256 collateral, uint256 collateralLTV) = getCollateralLTVandLTAbsoluteValues(
            ln.borrower,
            true
        );
        require(
            collateralLTV != 0 && collateral >= collateralLTV,
            Errors.PAYMENT_NOT_ENOUGH_COLLATERAL
        );
        return (ln.principal, ln.borrower);
    }

    function getCollateralData(address user)
        public
        view
        returns (
            uint256,
            uint8,
            uint256,
            uint8
        )
    {
        (address collateralContract, uint256 collateral) = ICollateralManager(
            lookup(ROLE_COLLATERAL_MANAGER)
        ).getCollateralLookup(address(this), user);

        (uint256 collateralPrice, uint8 feederDecimalsCollateral) = _safeGetPriceOf(
            collateralContract
        );

        return (
            collateral,
            IERC20MetadataUpgradeable(collateralContract).decimals(),
            collateralPrice,
            feederDecimalsCollateral
        );
    }

    function claimCollateral(
        address _token,
        uint256 _amount,
        string memory version
    ) external whenNotPaused {
        require(getBalanceOfCollateral(msg.sender) >= _amount, Errors.PAYMENT_CLAIM_COLLATERAL);
        ICollateralManager(lookup(ROLE_COLLATERAL_MANAGER)).withdrawal(
            msg.sender,
            _amount,
            msg.sender
        );
        for (uint256 i = 0; i < usersActiveLoans[msg.sender].length; i++) {
            require(
                !missedPayment(usersActiveLoans[msg.sender][i]),
                Errors.PAYMENT_CLAIM_COLLATERAL
            );
        }
        emit CollateralWithdrawn(block.timestamp, msg.sender, _token, _amount);
    }

    function getMaxWithdrawableCollateral() public view returns (uint256) {
        return getBalanceOfCollateral(msg.sender);
    }

    function getBalanceOfCollateral(address user) internal view returns (uint256) {
        (uint256 collateral, uint256 collateralLTV) = getCollateralLTVandLTAbsoluteValues(
            user,
            true
        );

        if (collateralLTV != 0) {
            return collateralLTV <= collateral ? collateral - collateralLTV : 0;
        }

        return collateral;
    }

    function calculateCollateralFromOutStanding(uint256 outstandingUSD, uint256 parameter)
        internal
        pure
        returns (uint256)
    {
        return parameter == 0 ? 0 : (outstandingUSD * ONE_HUNDRED_PERCENT) / parameter;
    }

    function getCollateralLTVandLTAbsoluteValues(address user, bool needLTV)
        internal
        view
        returns (uint256, uint256)
    {
        (uint256 outstandingUSD, uint256 ltvMean, uint256 ltMean) = aggregateActiveLoansData(user);

        (
            uint256 collateral,
            uint8 collateralDecimals,
            uint256 feedPrice,
            uint8 feedDecimals
        ) = getCollateralData(user);

        uint256 collateralLTVorLT = fromFeedPriceToToken(
            calculateCollateralFromOutStanding(outstandingUSD, needLTV ? ltvMean : ltMean),
            collateralDecimals,
            CONTRACT_DECIMALS,
            feedPrice,
            feedDecimals
        );

        return (collateral, collateralLTVorLT);
    }

    function isDelinquent(uint256 _id) public view returns (bool) {
        if (missedPayment(_id)) {
            return true;
        }

        if (_loanLookup[_id].lt < ONE_HUNDRED_PERCENT) {
            (uint256 collateral, uint256 collateralLT) = getCollateralLTVandLTAbsoluteValues(
                _loanLookup[_id].borrower,
                false
            );
            return collateralLT == 0 ? false : collateral <= collateralLT;
        }
        return false;
    }

    function aggregateActiveLoansData(address user)
        internal
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256[] memory activeLoans = usersActiveLoans[user];
        uint256 outstandingUSD;
        uint256 ltvAggregatedMean;
        uint256 ltAggregatedMean;

        if (activeLoans.length > 0) {
            address erc20Address = _loanLookup[activeLoans[0]].ERC20Address;

            for (uint256 i = 0; i < activeLoans.length; i++) {
                outstandingUSD += _loanLookup[activeLoans[i]].getOutstanding();
                ltvAggregatedMean += _loanLookup[activeLoans[i]].ltv;
                ltAggregatedMean += _loanLookup[activeLoans[i]].lt;
            }

            (uint256 priceLoan, uint8 feederDecimalsLoan) = _safeGetPriceOf(erc20Address);

            outstandingUSD = fromTokenToFeedPrice(
                outstandingUSD,
                IERC20MetadataUpgradeable(erc20Address).decimals(),
                CONTRACT_DECIMALS,
                priceLoan,
                feederDecimalsLoan
            );

            ltvAggregatedMean /= activeLoans.length;
            ltAggregatedMean /= activeLoans.length;
        }
        return (outstandingUSD, ltvAggregatedMean, ltAggregatedMean);
    }

    function fromTokenToFeedPrice(
        uint256 value,
        uint8 collDecimals,
        uint8 assetDecimals,
        uint256 price,
        uint8 feedDecimals
    ) internal pure returns (uint256) {
        uint256 converted = (price * value) / (10**feedDecimals);

        int8 decimalsDiff = int8(assetDecimals) - int8(collDecimals);

        if (decimalsDiff < 0) {
            converted /= 10**uint8(-decimalsDiff);
        } else if (decimalsDiff > 0) {
            converted = (price * value * 10**uint8(decimalsDiff)) / (10**feedDecimals);
        }

        return converted;
    }

    function fromFeedPriceToToken(
        uint256 value,
        uint8 collDecimals,
        uint8 assetDecimals,
        uint256 price,
        uint8 feedDecimals
    ) internal pure returns (uint256) {
        uint256 converted = (value * (10**feedDecimals)) / price;

        int8 decimalsDiff = int8(assetDecimals) - int8(collDecimals);

        if (decimalsDiff > 0) {
            converted /= 10**uint8(decimalsDiff);
        } else if (decimalsDiff < 0) {
            converted = (value * (10**feedDecimals) * 10**uint8(-decimalsDiff)) / price;
        }

        return converted;
    }

    function _safeGetPriceOf(address _tokenToGetPrice)
        internal
        view
        returns (uint256 tempPrice, uint8 decimals)
    {
        return IPriceFeed(lookup(ROLE_PRICE_FEED)).getLatestPriceUSD(_tokenToGetPrice);
    }

    function liquidateLoan(uint256 _id, address _receiver) internal {
        Loan.loan storage lInfo = _loanLookup[_id]; //loan info

        (address cAddress, uint256 cAvailable) = ICollateralManager(lookup(ROLE_COLLATERAL_MANAGER))
            .getCollateralLookup(address(this), lInfo.borrower);

        (uint256 cPrice, uint8 pDecimals) = _safeGetPriceOf(cAddress);

        //Normalization to collateral contract `format`
        uint256 cToLiquidate = fromFeedPriceToToken(
            lInfo.totalPaymentsValue - lInfo.paymentComplete,
            IERC20MetadataUpgradeable(cAddress).decimals(),
            IERC20MetadataUpgradeable(lInfo.ERC20Address).decimals(),
            cPrice,
            pDecimals
        );
        uint256 usdAmount = lInfo.totalPaymentsValue - lInfo.paymentComplete;

        //If there is not enough collateral then take it all
        if (cToLiquidate > cAvailable) {
            cToLiquidate = cAvailable;
            usdAmount = fromTokenToFeedPrice(
                cToLiquidate,
                IERC20MetadataUpgradeable(cAddress).decimals(),
                IERC20MetadataUpgradeable(lInfo.ERC20Address).decimals(),
                cPrice,
                pDecimals
            );
        }

        IpoolInvestor(lInfo.poolAddress).liquidate(_id);
        Loan.onLiquidate2(lInfo, usdAmount);

        if (cToLiquidate > 0) {
            ICollateralManager(lookup(ROLE_COLLATERAL_MANAGER)).withdrawal(
                lInfo.borrower,
                cToLiquidate,
                _receiver
            );
        }
    }

    function updateUserActiveLoans(Loan.loan memory _ln, uint256 _id) internal {
        if (_ln.status == Loan.Status.CLOSED) {
            for (uint256 i = 0; i < usersActiveLoans[_ln.borrower].length; i++) {
                if (usersActiveLoans[_ln.borrower][i] == _id) {
                    usersActiveLoans[_ln.borrower][i] = usersActiveLoans[_ln.borrower][
                        usersActiveLoans[_ln.borrower].length - 1
                    ];
                    usersActiveLoans[_ln.borrower].pop();
                    return;
                }
            }
        }
    }

    function getNumberOfLoans(address _who) external view returns (uint256) {
        return loanIDs[_who].length;
    }

    function addInterest(uint256 _am, uint256 _id)
        external
        whenNotPaused
        onlyRole(ROLE_BONDS)
        returns (bool)
    {
        if (!isComplete(_id)) {
            Loan.increaseTotalPaymentsValue(
                _loanLookup[_id],
                globalLoanLookup[_loanLookup[_id].borrower],
                globalLoanLookup[address(0)],
                nfcsLoanLookup[_loanLookup[_id].nfcsID],
                _am,
                addressBook.penaltyAPYMultiplier()
            );
        }
        return true;
    }

    function missedPayment(uint256 _id) public view returns (bool) {
        return ((Loan.isLate(_loanLookup[_id]) && !isComplete(_id)) &&
            block.timestamp >= _loanLookup[_id].maturityDate + addressBook.gracePeriod());
    }

    function getDataForLoan(address _erc20, uint256 _NFCSID)
        private
        view
        returns (
            uint16,
            uint256,
            uint256
        )
    {
        ScoreDBInterface oracle = ScoreDBInterface(lookup(ROLE_ORACLE));
        uint16 score = oracle.getScore(_NFCSID).creditScore;
        uint256 LTV = oracle.LTV(_erc20, score);
        uint256 LT = oracle.LT(_erc20, score);
        return (score, LTV, LT);
    }

    function getId(address _borrower, uint256 _index) public view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(address(this), _borrower, _index)));
    }

    function configureNew(
        address _erc20,
        address _borrower,
        uint256 _minPayment,
        uint256 _NFCSID,
        uint256 _maturityDate,
        uint256 _principal,
        uint256 _interestRate,
        uint256 _accrualPeriod
    ) external whenNotPaused returns (uint256) {
        require(allowedPoolInvestors[msg.sender], Errors.PAYMENT_POOL_INVESTOR_ACCESS);
        require(
            IERC721(lookup(ROLE_NFCS)).ownerOf(_NFCSID) == _borrower,
            Errors.PAYMENT_NFCS_OWNERSHIP
        );
        //Create new ID for the loan
        uint256 id = getId(_borrower, loanIDs[_borrower].length);
        loanIDs[_borrower].push(id);
        (uint16 score, uint256 ltv, uint256 lt) = getDataForLoan(_erc20, _NFCSID);
        //Add loan info to lookup
        _loanLookup[id] = Loan.loan({
            status: Loan.Status.NEW,
            ERC20Address: _erc20,
            borrower: _borrower,
            nfcsID: _NFCSID,
            maturityDate: _maturityDate,
            issueDate: 0,
            minPayment: _minPayment,
            interestRate: _interestRate,
            accrualPeriod: _accrualPeriod,
            principal: _principal,
            totalPaymentsValue: _principal, //For now. Will update with interest updates
            awaitingCollection: 0,
            awaitingInterest: 0,
            paymentComplete: 0,
            ltv: ltv,
            lt: lt,
            score: score,
            poolAddress: msg.sender
        });
        usersActiveLoans[_borrower].push(id);
        return id;
    }

    function withdrawl(
        uint256 _id,
        uint256 _am,
        address _receiver
    ) external whenNotPaused {
        require(allowedPoolInvestors[msg.sender], Errors.PAYMENT_POOL_INVESTOR_ACCESS);
        require(_loanLookup[_id].status != Loan.Status.UNISSUED, Errors.PAYMENT_NON_ISSUED_LOAN);
        Loan.loan storage ln = _loanLookup[_id];
        require(_am <= ln.awaitingCollection, Errors.PAYMENT_WITHDRAWAL_COLLECTION);
        Loan.onWithdrawal(ln, _am);
        IERC1155(lookup(ROLE_BONDS)).safeTransferFrom(_receiver, DEAD, _id, _am, "");
        IERC20MetadataUpgradeable(_loanLookup[_id].ERC20Address).safeTransfer(_receiver, _am);
    }

    function payment(
        uint256 _id,
        uint256 _erc20Amount,
        string memory version
    ) external whenNotPaused {
        require(!isComplete(_id), Errors.PAYMENT_FULFILLED);
        Loan.loan storage ln = _loanLookup[_id];

        require(_erc20Amount <= ln.totalPaymentsValue, Errors.PAYMENT_AMOUNT_TOO_LARGE);

        Loan.onPayment(
            ln,
            globalLoanLookup[_loanLookup[_id].borrower],
            globalLoanLookup[address(0)],
            nfcsLoanLookup[_loanLookup[_id].nfcsID],
            _erc20Amount
        );
        updateUserActiveLoans(ln, _id);

        IERC20MetadataUpgradeable(ln.ERC20Address).safeTransferFrom(
            msg.sender,
            address(this),
            _erc20Amount
        );

        emit LoanRepaid(
            block.timestamp,
            _loanLookup[_id].borrower,
            msg.sender,
            _id,
            _loanLookup[_id].principal,
            _erc20Amount,
            _loanLookup[_id].status
        );
    }

    function pause() public onlyRole(ROLE_PAUSER) {
        _pause();
    }

    function unpause() public onlyRole(ROLE_PAUSER) {
        _unpause();
    }

    function isComplete(uint256 _id) public view returns (bool) {
        return Loan.isComplete(_loanLookup[_id]);
    }

    function loanLookup(uint256 _id) external view returns (Loan.loan memory) {
        return _loanLookup[_id];
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyRole(ROLE_ADMIN) {}
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
pragma solidity ^0.8.0;
import "../libraries/Structs.sol";

/**
 * @title ScoreDBInterface
 * @author RociFI Labs
 * @notice Interface for the ScoreDB contract.
 **/

interface ScoreDBInterface {
    // Returns the current scores for the token from the on-chain storage.
    function getScore(uint256 tokenId) external view returns (Structs.Score memory);

    // Called by the lending contract, initiates logic to update score and fulfill loan.
    function pause() external;

    // UnPauses the contract [OWNER]
    function unpause() external;

    function LTV(address _token, uint16 _score) external view returns (uint256);

    function LT(address _token, uint16 _score) external view returns (uint256);
}

// SPDX-License-Identifier: None
pragma solidity ^0.8.0;

/**
 * @title Errors library
 * @author RociFi Labs
 * @notice Defines the error messages emitted by the different contracts of the RociFi protocol
 * @dev Error messages prefix glossary:
 *  - NFCS = NFCS
 *  - BONDS = Bonds
 *  - INVESTOR = Investor
 *  - POOL_INVESTOR = PoolInvestor
 *  - SCORE_DB = ScoreConfigs, ScoreDB
 *  - PAYMENT = ERC20CollateralPayment, ERC20PaymentStandard, RociPayment
 *  - PRICE_FEED = PriceFeed
 *  - REVENUE = PaymentSplitter, RevenueManager
 *  - LOAN = Loan
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

    string public constant BONDS_HASH_AND_ENCODING = "100"; //  Hash of data signed must be the paymentContractAddress and id encoded in that order
    string public constant BONDS_BORROWER_SIGNATURE = "101"; // Data provided must be signed by the borrower
    string public constant BONDS_NOT_STACKING = "102"; //  Not staking any NFTs
    string public constant BONDS_NOT_STACKING_INDEX = "103"; //  Not staking any tokens at this index
    string public constant BONDS_DELETE_HEAD = "104"; // Cannot delete the head

    string public constant INVESTOR_ISSUE_BONDS = "200"; //  Issue minting bonds
    string public constant INVESTOR_INSUFFICIENT_AMOUNT = "201"; //  Cannot borrow an amount of 0
    string public constant INVESTOR_BORROW_WITH_ANOTHER_SCORE = "202"; //  Cannot borrow if there is active loans with different score or pool does not support the score

    string public constant POOL_INVESTOR_INTEREST_RATE = "300"; // Interest rate has to be greater than zero
    string public constant POOL_INVESTOR_ZERO_POOL_VALUE = "301"; // Pool value is zero
    string public constant POOL_INVESTOR_ZERO_TOTAL_SUPPLY = "302"; // Total supply is zero
    string public constant POOL_INVESTOR_BONDS_LOST = "303"; // Bonds were lost in unstaking
    string public constant POOL_INVESTOR_NOT_ENOUGH_FUNDS = "304"; // Not enough funds to fulfill the loan
    string public constant POOL_INVESTOR_DAILY_LIMIT = "305"; // Exceeds daily deposits limit
    string public constant POOL_INVESTOR_GLOBAL_LIMIT = "306"; // Exceeds total deposits limit

    string public constant MANAGER_COLLATERAL_NOT_ACCEPTED = "400"; // Collateral is not accepted
    string public constant MANAGER_COLLATERAL_INCREASE = "401"; // When increasing collateral, the same ERC20 address should be used
    string public constant MANAGER_ZERO_WITHDRAW = "402"; // Cannot withdrawal zero
    string public constant MANAGER_EXCEEDING_WITHDRAW = "403"; // Requested withdrawal amount is too large
    string public constant MANAGER_COLLATERAL_TRANSFER = "404"; // The collateral struct was already transferred from old CollateralManager
    string public constant MANAGER_COLLATERAL_TRANSFER_BALANCE = "405"; // The balance of new CollateralManager is lower than old ones
    string public constant MANAGER_COLLATERAL_TRANSFER_EMPTY = "406"; // There is nothing to transfer from old CollateralManager

    string public constant SCORE_DB_EQUAL_LENGTH = "501"; // Arrays must be of equal length
    string public constant SCORE_DB_VERIFICATION = "502"; // Unverified score
    string public constant SCORE_DB_SCORE_NOT_GENERATED = "503"; // Score not yet generated.
    string public constant SCORE_DB_SCORE_GENERATING = "504"; // Error generating score.
    string public constant SCORE_DB_UNKNOW_FETCHING_SCORE = "505"; //  Unknown error fetching score.

    string public constant PAYMENT_NFCS_OUTDATED = "600"; // Outdated NFCS score outdated
    string public constant PAYMENT_ZERO_LTV = "601"; // LTV cannot be zero
    string public constant PAYMENT_NOT_ENOUGH_COLLATERAL = "602"; // Not enough collateral to issue a loan
    string public constant PAYMENT_NO_BONDS = "603"; // There is no bonds to liquidate a loan
    string public constant PAYMENT_FULFILLED = "604"; // Contract is paid off
    string public constant PAYMENT_NFCS_OWNERSHIP = "605"; // NFCS ID must belong to the borrower
    string public constant PAYMENT_NON_ISSUED_LOAN = "606"; // Loan has not been issued
    string public constant PAYMENT_WITHDRAWAL_COLLECTION = "607"; // There are not enough payments available for collection
    string public constant PAYMENT_LOAN_NOT_DELINQUENT = "608"; // Loan not delinquent
    string public constant PAYMENT_AMOUNT_TOO_LARGE = "609"; // Payment amount is too large
    string public constant PAYMENT_CLAIM_COLLATERAL = "610"; // Cannot claim collateral if this collateral is necessary for any non Closed/Liquidated loan's delinquency statu
    string public constant PAYMENT_POOL_INVESTOR_ACCESS = "611"; // Only PoolInvestors can call this method

    string public constant PRICE_FEED_TOKEN_NOT_SUPPORTED = "700"; // Token is not supported
    string public constant PRICE_FEED_TOKEN_BELOW_ZERO = "701"; // Token below zero price

    string public constant REVENUE_ADDRESS_TO_SHARE = "800"; // Non-equal length of addresses and shares
    string public constant REVENUE_UNIQUE_INDEXES = "801"; // Indexes in an array must not be duplicate
    string public constant REVENUE_FAILED_ETHER_TX = "802"; // Failed to send Ether
    string public constant REVENUE_UNVERIFIED_INVESTOR = "803"; // Only verified investors may request funds or make a payment
    string public constant REVENUE_NOT_ENOUGH_FUNDS = "804"; // Not enough funds to complete this request

    string public constant LOAN_MIN_PAYMENT = "900"; // Minimal payment should be made
    string public constant LOAN_DAILY_LIMIT = "901"; // Exceeds daily borrow limit
    string public constant LOAN_DAILY_LIMIT_USER = "902"; // Exceeds user daily borrow limit
    string public constant LOAN_TOTAL_LIMIT_USER = "903"; // Exceeds user total borrow limit
    string public constant LOAN_TOTAL_LIMIT = "904"; // Exceeds total borrow limit
    string public constant LOAN_CONFIGURATION = "905"; // Loan that is already issued, or not configured cannot be issued
    string public constant LOAN_TOTAL_LIMIT_NFCS = "906"; // Exceeds total nfcs borrow limit
    string public constant LOAN_DAILY_LIMIT_NFCS = "907"; // Exceeds daily nfcs borrow limit

    string public constant VERSION = "1000"; // Incorrect version of contract

    string public constant ADDRESS_BOOK_SET_MIN_SCORE = "1100"; // New min score must be less then maxScore
    string public constant ADDRESS_BOOK_SET_MAX_SCORE = "1101"; // New max score must be more then minScore

    string public constant ADDRESS_HANDLER_MISSING_ROLE_TOKEN = "1200"; // Lookup failed for role Token
    string public constant ADDRESS_HANDLER_MISSING_ROLE_BONDS = "1201"; // Lookup failed for role Bonds
    string public constant ADDRESS_HANDLER_MISSING_ROLE_INVESTOR = "1202"; // Lookup failed for role Investor
    string public constant ADDRESS_HANDLER_MISSING_ROLE_PAYMENT_CONTRACT = "1203"; // Lookup failed for role Payment Contract
    string public constant ADDRESS_HANDLER_MISSING_ROLE_REV_MANAGER = "1204"; // Lookup failed for role Revenue Manager
    string public constant ADDRESS_HANDLER_MISSING_ROLE_COLLATERAL_MANAGER = "1205"; // Lookup failed for role Collateral Manager
    string public constant ADDRESS_HANDLER_MISSING_ROLE_PRICE_FEED = "1206"; // Lookup failed for role Price Feed
    string public constant ADDRESS_HANDLER_MISSING_ROLE_ORACLE = "1207"; // Lookup failed for role Oracle
    string public constant ADDRESS_HANDLER_MISSING_ROLE_ADMIN = "1208"; // Lookup failed for role Admin
    string public constant ADDRESS_HANDLER_MISSING_ROLE_PAUSER = "1209"; // Lookup failed for role Pauser
    string public constant ADDRESS_HANDLER_MISSING_ROLE_LIQUIDATOR = "1210"; // Lookup failed for role Liquidator
    string public constant ADDRESS_HANDLER_MISSING_ROLE_COLLECTOR = "1211"; // Lookup failed for role Collector
}

// SPDX-License-Identifier: None
pragma solidity ^0.8.4;
uint256 constant ONE_HUNDRED_PERCENT = 100 ether; // NOTE This CAN NOT exceed 2^256/2 -1 as type casting to int occurs

uint256 constant ONE_YEAR = 31556926;
uint256 constant ONE_DAY = ONE_HOUR * 24;
uint256 constant ONE_HOUR = 60 * 60;

uint256 constant APY_CONST = 3000000000 gwei;

uint8 constant CONTRACT_DECIMALS = 18;

address constant DEAD = 0x000000000000000000000000000000000000dEaD;
address constant ZERO_ADDRESS = 0x0000000000000000000000000000000000000000;

uint256 constant ROLE_TOKEN = 0;
uint256 constant ROLE_BONDS = 1;
uint256 constant ROLE_PAYMENT_CONTRACT = 2;
uint256 constant ROLE_REV_MANAGER = 3;
uint256 constant ROLE_NFCS = 4;
uint256 constant ROLE_COLLATERAL_MANAGER = 5;
uint256 constant ROLE_PRICE_FEED = 6;
uint256 constant ROLE_ORACLE = 7;
uint256 constant ROLE_ADMIN = 8;
uint256 constant ROLE_PAUSER = 9;
uint256 constant ROLE_LIQUIDATOR = 10;
uint256 constant ROLE_COLLECTOR = 11;

/// SPDX-License-Identifier: None
pragma solidity ^0.8.0;

import {IAddressBook} from "../interfaces/IAddressBook.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

abstract contract AddressHandlerAbstract {
  function getAddressBook() public view virtual returns (IAddressBook);

  modifier onlyRole(uint256 _role) {
    require(msg.sender == lookup(_role), getAddressBook().roleLookupErrorMessage(_role));
    _;
  }

  function lookup(uint256 _role) internal view returns (address contractAddress) {
    contractAddress = getAddressBook().addressList(_role);
    require(contractAddress != address(0), getAddressBook().roleLookupErrorMessage(_role));
  }
}

/// SPDX-License-Identifier: None
pragma solidity ^0.8.0;

import {ONE_DAY, ONE_HUNDRED_PERCENT} from "../Globals.sol";
import {Errors} from "../libraries/Errors.sol";

/**
* @title Loan
* @author RociFI Labs
* @dev Library to abstract out edits to Loan object to help with global variable tracking
    NOTE
    In this library the function paramaters may seem confusing
    This is because there are special global/local instances of these loan objects

    _ln is an individual loan
    _user is a user's global amount in this payment contract
    _global is the payment contracts total sums
 */
library Loan {
    //Loan object. Stores lots of info about each loan
    enum Status {
        UNISSUED,
        NEW,
        APPROVED,
        PAIDPART,
        CLOSED,
        PAIDLATE,
        DEFAULT,
        LATE
    }
    struct loan {
        Status status;
        address ERC20Address;
        address poolAddress;
        address borrower;
        uint256 nfcsID;
        uint256 maturityDate;
        uint128 issueDate;
        uint256 minPayment;
        uint256 interestRate;
        uint256 accrualPeriod;
        uint256 principal;
        uint256 totalPaymentsValue;
        uint256 awaitingCollection;
        uint256 awaitingInterest;
        uint256 paymentComplete;
        uint256 ltv;
        uint256 lt;
        uint16 score;
    }

    struct globalInfo {
        uint256 principal;
        uint256 totalPaymentsValue;
        uint256 paymentComplete;
        uint128 borrowedToday;
        uint128 lastBorrowTimestamp;
    }

    /**
     * @dev onPayment function to check and handle updates to struct for payments
     * @param _ln individual loan
     * @param _user global loan for user
     * @param _global global loan for the whole contract
     */
    function onPayment(
        loan storage _ln,
        globalInfo storage _user,
        globalInfo storage _global,
        globalInfo storage _nfcs,
        uint256 _erc20Amount
    ) internal {
        require(
            _erc20Amount >= _ln.minPayment || //Payment must be more than min payment
                (getOutstanding(_ln) < _ln.minPayment && //Exception for the last payment (remainder)
                    _erc20Amount >= getOutstanding(_ln)), // Exception is only valid if user is paying the loan off in full on this transaction
            Errors.LOAN_MIN_PAYMENT
        );

        _ln.awaitingCollection += _erc20Amount;

        _ln.paymentComplete += _erc20Amount; //Increase paymentComplete
        _user.paymentComplete += _erc20Amount;
        _global.paymentComplete += _erc20Amount;
        _nfcs.paymentComplete += _erc20Amount;

        // do a status update for anything payment dependant
        if (isComplete(_ln) && _ln.status != Status.DEFAULT && _ln.status != Status.CLOSED) {
            _ln.status = Status.CLOSED;
        } else if (_erc20Amount > 0 && !isLate(_ln)) {
            _ln.status = Status.PAIDPART;
        } else if (isLate(_ln)) {
            _ln.status = Status.PAIDLATE;
        }

        _updateLoanDay(_user);
        _updateLoanDay(_global);
    }

    function onWithdrawal(loan storage _ln, uint256 _erc20Amount) internal {
        _ln.awaitingCollection -= _erc20Amount;
        _ln.awaitingInterest = 0;
    }

    function onLiquidate(loan storage _ln, bool def) internal {
        _ln.status = def ? Status.DEFAULT : Status.CLOSED;
    }

    function onLiquidate2(loan storage _ln, uint256 _amount) internal {
        if (_ln.totalPaymentsValue - _ln.paymentComplete > _amount) {
            _ln.status = Status.DEFAULT;
        } else {
            _ln.status = Status.CLOSED;
        }
        _ln.paymentComplete += _amount;
    }

    function limitGlobalCheck(
        uint256 _totalOutstanding,
        uint128 _limit,
        string memory exeption
    ) internal pure {
        if (_limit != 0) {
            require(_totalOutstanding <= _limit, exeption);
        }
    }

    function limitDailyCheck(
        loan storage _ln,
        globalInfo storage _limitInfo,
        uint128 _limit,
        string memory exeption
    ) internal {
        if (_limit != 0) {
            _updateLoanDay(_limitInfo);
            // Ensure that amount borrowed in last 24h + current borrow amount is less than the 24 limit for this user
            require(_limitInfo.borrowedToday + _ln.principal <= _limit, exeption);
            // Increase 24 limit by amount borrowed
            _limitInfo.borrowedToday += uint128(_ln.principal);
        }
    }

    /**
     * @dev function increases the total payment value on the loan for interest accrual
     * @param _ln individual loan
     * @param _user global loan for user
     * @param _global global loan for the whole contract
     */

    function increaseTotalPaymentsValue(
        loan storage _ln,
        globalInfo storage _user,
        globalInfo storage _global,
        globalInfo storage _nfcs,
        uint256 _am,
        uint256 penaltyAPYMultiplier
    ) internal {
        // if loan is late we give an APR multiplier
        if (
            isLate(_ln) &&
            _ln.status != Status.LATE &&
            _ln.status != Status.PAIDLATE &&
            _ln.status != Status.DEFAULT
        ) {
            _ln.status = Status.LATE;
            _ln.interestRate = _ln.interestRate * penaltyAPYMultiplier;
        }
        _ln.awaitingInterest += _am;
        _ln.totalPaymentsValue += _am;
        _user.totalPaymentsValue += _am;
        _global.totalPaymentsValue += _am;
        _nfcs.totalPaymentsValue += _am;
    }

    /// @dev function to issue a loan
    function issue(
        loan storage _ln,
        globalInfo storage _user,
        globalInfo storage _global,
        globalInfo storage _nfcs
    ) internal {
        require(_ln.status == Status.NEW, Errors.LOAN_CONFIGURATION);

        _ln.status = Status.APPROVED;
        _ln.issueDate = uint128(block.timestamp);

        _user.principal += _ln.principal;
        _user.totalPaymentsValue += _ln.totalPaymentsValue;
        _user.paymentComplete += _ln.paymentComplete;

        _global.principal += _ln.principal;
        _global.totalPaymentsValue += _ln.totalPaymentsValue;
        _global.paymentComplete += _ln.paymentComplete;

        _nfcs.principal += _ln.principal;
        _nfcs.totalPaymentsValue += _ln.totalPaymentsValue;
        _nfcs.paymentComplete += _ln.paymentComplete;
    }

    /// @dev helper function returns if loan is complete
    function isComplete(loan storage _ln) internal view returns (bool) {
        return _ln.paymentComplete >= _ln.totalPaymentsValue;
    }

    /// @dev function returns if loan is late
    function isLate(loan storage _ln) internal view returns (bool) {
        return (block.timestamp >= _ln.maturityDate);
    }

    function getOutstanding(loan memory _ln) internal pure returns (uint256) {
        if (_ln.paymentComplete > _ln.totalPaymentsValue) {
            return 0;
        }
        return (_ln.totalPaymentsValue - _ln.paymentComplete);
    }

    function getOutstanding(globalInfo memory _global) internal pure returns (uint256) {
        if (_global.paymentComplete > _global.totalPaymentsValue) {
            return 0;
        }
        return (_global.totalPaymentsValue - _global.paymentComplete);
    }

    function _updateLoanDay(globalInfo storage _user) private {
        // If current time - last borrow time = is greater than 24 hours
        if ((block.timestamp - _user.lastBorrowTimestamp) >= ONE_DAY) {
            // then reset daily limit
            _user.borrowedToday = 0;
        }
        // Set lastBorrowedTimestamp for this user to now
        _user.lastBorrowTimestamp = uint128(block.timestamp);
    }
}

/// SPDX-License-Identifier: None
pragma solidity ^0.8.0;

import "./IManager.sol";

/**
 * @title ICollateralManager
 * @author RociFI Labs
 * @notice A contract to manage the collateral of the Roci protocol
 * @dev the overrides of deposit/withdrawal will probably need to use data to store the loan ID
 */
interface ICollateralManager is IManager {
    /**
     * @dev function to return the ERC20 contract AND amount for a collateral deposit
     * @param _paymentContract address
     * @param _user of borrower
     * @return ERC20 contract address of collateral
     * @return Collateral amount deposited
     */
    function getCollateralLookup(address _paymentContract, address _user)
        external
        view
        returns (address, uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

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
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
pragma solidity ^0.8.0;

library Structs {
    struct Score {
        uint256 tokenId;
        uint256 timestamp;
        uint16 creditScore;
    }

    /**
        * @param _amount to borrow
        * @param _duration of loan in seconds
        * @param _NFCSID is the user's NFCS NFT ID from Roci's Credit scoring system
        * @param _collateralAmount is the amount of collateral to send in
        * @param _collateral is the ERC20 address of the collateral
        * @param _hash is the hash of this address and the loan ID. See Bonds.sol for more info on this @newLoan()
        * @param _signature is the signature of the data hashed for hash
    */
    struct BorrowArgs{
        uint256 _amount;
        uint256 _NFCSID;
        uint256 _collateralAmount;
        address _collateral;
        bytes32 _hash;
        bytes _signature;
    }

    /// @notice collateral info is stored in a struct/mapping pair
    struct collateral {
        uint256 creationTimestamp;
        address ERC20Contract;
        uint256 amount;
    }

    // Share struct that decides the share of each address
    struct Share{
        address payee;
        uint share;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IPriceFeed{
    function getLatestPriceUSD(address) external view returns (uint256, uint8);
}

// SPDX-License-Identifier: None
pragma solidity ^0.8.0;

import "./Iinvestor.sol";
import {IVersion} from "../../../Version/IVersion.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

/**
 * @title PoolInvestor
 * @author RociFI Labs
 * @dev TestToken will eventually be replaced with ERC-20
 */
interface IpoolInvestor is IVersion, Iinvestor, IERC20Metadata {
    enum addresses_PoolInvestor {
        token,
        bonds,
        paymentContract,
        revManager
    }

    // state variables

    function reserveRate() external returns (uint256);

    function stakeTimes(address) external returns (uint256);

    /**
     * @dev owner can set interestRateAnnual
     * @param _interestRateAnnual new interestRateAnnual
     */
    function setInterestRateAnnual(uint256 _interestRateAnnual) external;

    /// @dev setter for reserve rate
    function setReserveRate(uint256 _new) external;

    /**
     * @dev deposits stablecoins for some rate of rTokens
     * NOTE ideally should send stright to revManager, but user would need to approve it
     */
    function depositPool(uint256 _amount, string memory _version) external;

    /**
     * @dev function to exchange rToken back for stablecoins
     */
    function withdrawalPool(uint256 _amount, string memory _version) external;

    /**
     * @dev collects an array of loan id's payments to this
     * @param _ids to collect on
     */
    function collect(uint256[] memory _ids, string memory _version) external;

    /**
     * @dev pc contract call this function to change poolValue inside investor, also it can be used
     * to change loan relative params inside investor, emit events
     */
    function liquidate(uint256 _id) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import {IVersion} from "../Version/IVersion.sol";

interface NFCSInterface is IVersion {
    // Receives an address array, verifies ownership of addrs [WIP], mints a token, stores the bundle against token ID, sends token to msg.sender
    function mintToken(
        address[] memory bundle,
        bytes[] memory signatures,
        string memory _message,
        uint256 _nonce,
        string memory version
    ) external;

    // Receives a tokenId, returns corresponding address bundle
    function getBundle(uint256 tokenId)
        external
        view
        returns (address[] memory);

    // Receives an address, returns tokenOwned by it if any, otherwise reverts
    function getToken(address tokenOwner) external view returns (uint256);

    // Tells if an address owns a token or not
    function tokenExistence(address user) external view returns (bool);

    function getTotalOutstanding(uint _nfcsId) external view returns(uint,uint,uint);


    // function getUserAddressTotalOustanding(address _user) external view returns(uint);

    // function getGlobalTotalOustanding() external view returns(uint);

    function getLimits() external view returns(uint128, uint128,uint128, uint128);

    function getNFCSLimits(uint _nfcsId) external view returns(uint128, uint128);

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

/// SPDX-License-Identifier: None
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

interface IAddressBook {
    function addressList(uint256 role) external view returns (address);

    function setAddressToRole(uint256 role, address newAddress) external;

    function roleLookupErrorMessage(uint256 role) external view returns (string memory);

    function dailyLimit() external view returns (uint128);

    function globalLimit() external view returns (uint128);

    function setDailyLimit(uint128 newLimit) external;

    function setGlobalLimit(uint128 newLimit) external;

    function getMaturityDate() external view returns (uint256);

    function setLoanDuration(uint256 _newLoanDuration) external;

    function userDailyLimit() external view returns (uint128);

    function userGlobalLimit() external view returns (uint128);

    function setUserDailyLimit(uint128 newLimit) external;

    function setUserGlobalLimit(uint128 newLimit) external;

    function globalNFCSLimit(uint256 _nfcsId) external view returns (uint128);

    function setGlobalNFCSLimit(uint256 _nfcsId, uint128 newLimit) external;

    function scoreGlobalLimit(uint16 score) external view returns (uint128);

    function setScoreGlobalLimit(uint16 score, uint128) external;

    function latePenalty() external view returns (uint256);

    function scoreValidityPeriod() external view returns (uint256);

    function setLatePenalty(uint256 newPenalty) external;

    function setScoreValidityPeriod(uint256 newValidityPeriod) external;

    function minScore() external view returns (uint16);

    function maxScore() external view returns (uint16);

    function setMinScore(uint16 newScore) external;

    function setMaxScore(uint16 newScore) external;

    function notGenerated() external view returns (uint16);

    function generationError() external view returns (uint16);

    function setNotGenerated(uint16 newValue) external;

    function setGenerationError(uint16 newValue) external;

    function penaltyAPYMultiplier() external view returns (uint8);

    function gracePeriod() external view returns (uint128);

    function setPenaltyAPYMultiplier(uint8 newMultiplier) external;

    function setGracePeriod(uint128 newPeriod) external;

    function defaultPoolDailyLimit() external view returns (uint128);

    function defaultPoolGlobalLimit() external view returns (uint256);

    function setDefaultPoolDailyLimit(uint128 newLimit) external;

    function setDefaultPoolGlobalLimit(uint256 newLimit) external;

    function poolDailyLimit(address pool) external view returns (uint128);

    function poolGlobalLimit(address pool) external view returns (uint256);

    function setPoolDailyLimit(address pool, uint128 newLimit) external;

    function setPoolGlobalLimit(address pool, uint256 newLimit) external;

    function limitResetTimestamp() external view returns (uint128);

    function updateLimitResetTimestamp() external;

    function setLimitResetTimestamp(uint128 newTimestamp) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/utils/Initializable.sol)

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
        bool isTopLevelCall = _setInitializedVersion(1);
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
        bool isTopLevelCall = _setInitializedVersion(version);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(version);
        }
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
        _setInitializedVersion(type(uint8).max);
    }

    function _setInitializedVersion(uint8 version) private returns (bool) {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, and for the lowest level
        // of initializers, because in other contexts the contract may have been reentered.
        if (_initializing) {
            require(
                version == 1 && !AddressUpgradeable.isContract(address(this)),
                "Initializable: contract is already initialized"
            );
            return false;
        } else {
            require(_initialized < version, "Initializable: contract is already initialized");
            _initialized = version;
            return true;
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
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

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
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
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
        require(paused(), "Pausable: not paused");
        _;
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

/// SPDX-License-Identifier: None
pragma solidity ^0.8.0;

import "../libraries/Loan.sol";

// TEMPORARY INTERFACE FOR MIGRATION
interface IRoci {
    function loanLookup(uint256 _id) external view returns (Loan.loan memory);

    function loanIDs(address, uint256) external returns (uint256);

    function getNumberOfLoans(address _who) external view returns (uint256);
}

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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
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
pragma solidity ^0.8.0;

import {IAddressBook} from "../../IAddressBook.sol";

/**
 * @title IManager
 * @author RociFI Labs
 * @dev base contract for other managers. Contracts that hold funds for others, keep track of the owners,
 *   and also have accepted deposited fund types that can be updated.
 */
interface IManager {
    event AcceptedCollateralAdded(uint256 timestamp, address[] indexed ERC20Tokens);
    event AcceptedCollateralRemoved(uint256 timestamp, address[] indexed ERC20CTokens);

    // function deposit(uint _amount, bytes memory _data) external;
    function deposit(
        address _from,
        address _erc20,
        uint256 _amount
    ) external;

    // function withdrawal(uint _amount, address _receiver, bytes memory _data) external;
    function withdrawal(
        address user,
        uint256 _amount,
        address _receiver
    ) external;

    function addAcceptedDeposits(address[] memory) external;

    function removeAcceptedDeposits(address[] memory) external;
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
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
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

// SPDX-License-Identifier: None
pragma solidity ^0.8.0;

import {IAddressBook} from "../../IAddressBook.sol";
import {IVersion} from "../../../Version/IVersion.sol";
import "../../../libraries/Structs.sol";

/**
 * @title Investor
 * @author RociFI Labs
 * @dev is an ERC20
 */
interface Iinvestor is IVersion {
    /*
    State variables
     */
    function interestRateAnnual() external returns (uint256);

    // note addresses are replaced with address book
    // enum is the index in the array returned by addressBook's function
    enum addresses_Investor {
        token,
        bonds,
        paymentContract
    }

    function borrow(Structs.BorrowArgs calldata, string memory) external;
}

/// SPDX-License-Identifier: None
pragma solidity ^0.8.0;

/*
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