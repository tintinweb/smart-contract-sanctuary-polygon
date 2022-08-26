// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.15;

import "./context/SaplingManagerContext.sol";
import "./context/SaplingMathContext.sol";
import "./interfaces/ILoanDesk.sol";
import "./interfaces/ILoanDeskOwner.sol";

/**
 * @title SaplingPool Lender
 * @notice Extends ManagedLendingPool with lending functionality.
 * @dev This contract is abstract. Extend the contract to implement an intended pool functionality.
 */
contract LoanDesk is ILoanDesk, SaplingManagerContext, SaplingMathContext {

    using SafeMath for uint256;

    /// Loan application object
    struct LoanApplication {
        uint256 id;
        address borrower;
        uint256 amount;
        uint256 duration;
        uint256 requestedTime;
        LoanApplicationStatus status;

        string profileId;
        string profileDigest;
    }

    /// Individual borrower statistics
    struct BorrowerStats {

        /// Wallet address of the borrower
        address borrower; 

        /// All time loan request count
        uint256 countRequested;

        /// All time loan denial count
        uint256 countDenied;

        /// All time loan offer count
        uint256 countOffered;

        /// All time loan borrow count
        uint256 countBorrowed;

        /// All time loan cancellation count
        uint256 countCancelled;

        /// most recent applicationId
        uint256 recentApplicationId;

        bool hasOpenApplication;
    }

    event LoanRequested(uint256 applicationId, address indexed borrower);
    event LoanRequestDenied(uint256 applicationId, address indexed borrower);
    event LoanOffered(uint256 applicationId, address indexed borrower);
    event LoanOfferUpdated(uint256 applicationId, address indexed borrower);
    event LoanOfferCancelled(uint256 applicationId, address indexed borrower);

    address public pool;

    /// Contract math safe minimum loan amount including token decimals
    uint256 public immutable SAFE_MIN_AMOUNT;

    /// Minimum allowed loan amount 
    uint256 public minLoanAmount;

    /// Contract math safe minimum loan duration in seconds
    uint256 public constant SAFE_MIN_DURATION = 1 days;

    /// Contract math safe maximum loan duration in seconds
    uint256 public constant SAFE_MAX_DURATION = 51 * 365 days;

    /// Minimum loan duration in seconds
    uint256 public minLoanDuration;

    /// Maximum loan duration in seconds
    uint256 public maxLoanDuration;

    /// Loan payment grace period after which a loan can be defaulted
    uint256 public templateLoanGracePeriod = 60 days;

    /// Maximum allowed loan payment grace period
    uint256 public constant MIN_LOAN_GRACE_PERIOD = 3 days;

    uint256 public constant MAX_LOAN_GRACE_PERIOD = 365 days;

    // APR, to represent a percentage value as int, multiply by (10 ^ percentDecimals)

    /// Safe minimum for APR values
    uint16 public constant SAFE_MIN_APR = 0; // 0%

    /// Safe maximum for APR values
    uint16 public immutable SAFE_MAX_APR;

    /// Loan APR to be applied for the new loan requests
    uint16 public templateLoanAPR;

    /// Loan application id generator counter
    uint256 private nextApplicationId;

    /// Loan applications by applicationId
    mapping(uint256 => LoanApplication) public loanApplications;

    /// Loan offers by applicationId
    mapping(uint256 => LoanOffer) public loanOffers;

    /// Borrower statistics by address 
    mapping(address => BorrowerStats) public borrowerStats;

    uint256 public offeredFunds;

    modifier onlyPool() {
        require(msg.sender == pool, "Sapling: caller is not the lending pool");
        _;
    }

    modifier applicationInStatus(uint256 applicationId, LoanApplicationStatus status) {
        LoanApplication storage app = loanApplications[applicationId];
        require(app.id != 0, "Loan application is not found.");
        require(app.status == status, "Loan application does not have a valid status for this operation.");
        _;
    }

    /**
     * @notice Create a Lender that ManagedLendingPool.
     * @param _governance Address of the protocol governance.
     * @param _protocol Address of a wallet to accumulate protocol earnings.
     * @param _manager Address of the pool manager.
     */
    constructor(address _pool, address _governance, address _protocol, address _manager, uint8 _decimals) 
        SaplingManagerContext(_governance, _protocol, _manager) {
        require(_pool != address(0), "Sapling: Pool address is not set");

        pool = _pool;

        uint256 _oneToken = 10 ** uint256(_decimals);
        SAFE_MIN_AMOUNT = _oneToken;
        minLoanAmount = _oneToken.mul(100);

        minLoanDuration = SAFE_MIN_DURATION;
        maxLoanDuration = SAFE_MAX_DURATION;

        SAFE_MAX_APR = ONE_HUNDRED_PERCENT;
        templateLoanAPR = uint16(30 * 10 ** PERCENT_DECIMALS); // 30%

        offeredFunds = 0;
        nextApplicationId = 1;
    }

    /**
     * @notice Set a minimum loan amount for the future loans.
     * @dev minLoanAmount must be greater than or equal to SAFE_MIN_AMOUNT.
     *      Caller must be the manager.
     * @param _minLoanAmount minimum loan amount to be enforced for the new loan requests.
     */
    function setMinLoanAmount(uint256 _minLoanAmount) external onlyManager whenNotPaused {
        require(SAFE_MIN_AMOUNT <= _minLoanAmount, "New min loan amount is less than the safe limit");
        minLoanAmount = _minLoanAmount;
    }

    /**
     * @notice Set maximum loan duration for the future loans.
     * @dev Duration must be in seconds and inclusively between SAFE_MIN_DURATION and maxLoanDuration.
     *      Caller must be the manager.
     * @param duration Maximum loan duration to be enforced for the new loan requests.
     */
    function setMinLoanDuration(uint256 duration) external onlyManager whenNotPaused {
        require(SAFE_MIN_DURATION <= duration && duration <= maxLoanDuration, "New min duration is out of bounds");
        minLoanDuration = duration;
    }

    /**
     * @notice Set maximum loan duration for the future loans.
     * @dev Duration must be in seconds and inclusively between minLoanDuration and SAFE_MAX_DURATION.
     *      Caller must be the manager.
     * @param duration Maximum loan duration to be enforced for the new loan requests.
     */
    function setMaxLoanDuration(uint256 duration) external onlyManager whenNotPaused {
        require(minLoanDuration <= duration && duration <= SAFE_MAX_DURATION, "New max duration is out of bounds");
        maxLoanDuration = duration;
    }

    /**
     * @notice Set loan payment grace period for the future loans.
     * @dev Duration must be in seconds and inclusively between MIN_LOAN_GRACE_PERIOD and MAX_LOAN_GRACE_PERIOD.
     *      Caller must be the manager.
     * @param gracePeriod Loan payment grace period for new loan requests.
     */
    function setTemplateLoanGracePeriod(uint256 gracePeriod) external onlyManager whenNotPaused {
        require(MIN_LOAN_GRACE_PERIOD <= gracePeriod && gracePeriod <= MAX_LOAN_GRACE_PERIOD, "Lender: New grace period is out of bounds.");
        templateLoanGracePeriod = gracePeriod;
    }

    /**
     * @notice Set annual loan interest rate for the future loans.
     * @dev apr must be inclusively between SAFE_MIN_APR and SAFE_MAX_APR.
     *      Caller must be the manager.
     * @param apr Loan APR to be applied for the new loan requests.
     */
    function setTemplateLoanAPR(uint16 apr) external onlyManager whenNotPaused {
        require(SAFE_MIN_APR <= apr && apr <= SAFE_MAX_APR, "APR is out of bounds");
        templateLoanAPR = apr;
    }

    /**
     * @notice Request a new loan.
     * @dev Requested amount must be greater or equal to minLoanAmount().
     *      Loan duration must be between minLoanDuration() and maxLoanDuration().
     *      Caller must not be a lender, protocol, or the manager. 
     *      Multiple pending applications from the same address are not allowed,
     *      most recent loan/application of the caller must not have APPLIED status.
     * @param _amount Token amount to be borrowed.
     * @param _duration Loan duration in seconds. 
     */
    function requestLoan(
        uint256 _amount, 
        uint256 _duration, 
        string memory _profileId, 
        string memory _profileDigest
    ) 
        external 
        onlyUser
        whenNotClosed 
        whenNotPaused
    {

        require(borrowerStats[msg.sender].hasOpenApplication == false, "Sapling: another loan application is pending.");
        require(_amount >= minLoanAmount, "Sapling: loan amount is less than the minimum allowed");
        require(minLoanDuration <= _duration, "Sapling: loan duration is less than minimum allowed.");
        require(maxLoanDuration >= _duration, "Sapling: loan duration is more than maximum allowed.");

        uint256 appId = nextApplicationId;
        nextApplicationId++;

        loanApplications[appId] = LoanApplication({
            id: appId,
            borrower: msg.sender,
            amount: _amount,
            duration: _duration,
            requestedTime: block.timestamp,
            status: LoanApplicationStatus.APPLIED,
            profileId: _profileId,
            profileDigest: _profileDigest
        });

        if (borrowerStats[msg.sender].borrower == address(0)) {
            borrowerStats[msg.sender] = BorrowerStats({
                borrower: msg.sender,
                countRequested: 1, 
                countDenied: 0,
                countOffered: 0, 
                countBorrowed: 0,
                countCancelled: 0, 
                recentApplicationId: appId,
                hasOpenApplication: true
            });
        } else {
            borrowerStats[msg.sender].countRequested++;
            borrowerStats[msg.sender].recentApplicationId = appId;
            borrowerStats[msg.sender].hasOpenApplication = true;
        }

        emit LoanRequested(appId, msg.sender);
    }

    /**
     * @notice Deny a loan.
     * @dev Loan must be in APPLIED status.
     *      Caller must be the manager.
     */
    function denyLoan(uint256 appId) external onlyManager applicationInStatus(appId, LoanApplicationStatus.APPLIED) {
        LoanApplication storage app = loanApplications[appId];
        app.status = LoanApplicationStatus.DENIED;
        borrowerStats[app.borrower].countDenied++;
        borrowerStats[app.borrower].hasOpenApplication = false;
        
        emit LoanRequestDenied(appId, app.borrower);
    }

    /**
     * @notice Approve a loan application and offer a loan.
     * @dev Loan application must be in APPLIED status.
     *      Caller must be the manager.
     *      Loan amount must not exceed poolLiquidity();
     *      Stake to pool funds ratio must be good - poolCanLend() must be true.
     */
    function offerLoan(
        uint256 appId, 
        uint256 _amount, 
        uint256 _duration, 
        uint256 _gracePeriod, 
        uint256 _installmentAmount,
        uint16 _installments, 
        uint16 _apr
    ) 
        external 
        onlyManager 
        applicationInStatus(appId, LoanApplicationStatus.APPLIED) 
        whenNotClosed 
        whenNotPaused 
    {
        require(validLoanParams(_amount, _duration, _gracePeriod, _installmentAmount, _installments, _apr));

        LoanApplication storage app = loanApplications[appId];

        require(ILoanDeskOwner(pool).canOffer(offeredFunds.add(_amount)), "Sapling: lending pool cannot offer this loan at this time");
        ILoanDeskOwner(pool).onOffer(_amount);

        loanOffers[appId] = LoanOffer({
            applicationId: appId,
            borrower: app.borrower,
            amount: _amount,
            duration: _duration,
            gracePeriod: _gracePeriod,
            installmentAmount: _installmentAmount,
            installments: _installments,
            apr: _apr,
            offeredTime: block.timestamp
        });

        offeredFunds = offeredFunds.add(_amount);
        borrowerStats[app.borrower].countOffered++;
        loanApplications[appId].status = LoanApplicationStatus.OFFER_MADE;
        
        emit LoanOffered(appId, app.borrower);
    }

    /**
     * @notice Update an existing loan offer offer a loan.
     * @dev Loan application must be in OFFER_MADE status.
     *      Caller must be the manager.
     *      Loan amount must not exceed poolLiquidity();
     *      Stake to pool funds ratio must be good - poolCanLend() must be true.
     */
    function updateOffer(
        uint256 appId, 
        uint256 _amount, 
        uint256 _duration, 
        uint256 _gracePeriod, 
        uint256 _installmentAmount,
        uint16 _installments, 
        uint16 _apr
    ) 
        external 
        onlyManager 
        applicationInStatus(appId, LoanApplicationStatus.OFFER_MADE)
        whenNotClosed
        whenNotPaused 
    {
        require(validLoanParams(_amount, _duration, _gracePeriod, _installmentAmount, _installments, _apr));

        LoanOffer storage offer = loanOffers[appId];

        if (offer.amount != _amount) {
            uint256 nextOfferedFunds = offeredFunds.sub(offer.amount).add(_amount);
            
            require(ILoanDeskOwner(pool).canOffer(nextOfferedFunds), "Sapling: lending pool cannot offer this loan at this time");
            ILoanDeskOwner(pool).onOfferUpdate(offer.amount, _amount);

            offeredFunds = nextOfferedFunds;
        }

        offer.amount = _amount;
        offer.duration = _duration;
        offer.gracePeriod = _gracePeriod;
        offer.installmentAmount = _installmentAmount;
        offer.installments = _installments;
        offer.apr = _apr;
        offer.offeredTime = block.timestamp;

        emit LoanOfferUpdated(appId, offer.borrower);
    }

    
    /**
     * @notice Cancel a loan.
     * @dev Loan must be in APPROVED status.
     *      Caller must be the manager.
     */
    function cancelLoan(uint256 appId) external managerOrApprovedOnInactive applicationInStatus(appId, LoanApplicationStatus.OFFER_MADE) {
        LoanOffer storage offer = loanOffers[appId];

        // check if the call was made by an eligible non manager party, due to manager's inaction on the loan.
        if (msg.sender != manager) {
            // require inactivity grace period
            require(block.timestamp > offer.offeredTime + MANAGER_INACTIVITY_GRACE_PERIOD, 
                "It is too early to cancel this loan as a non-manager.");
        }

        loanApplications[appId].status = LoanApplicationStatus.OFFER_CANCELLED;
        borrowerStats[offer.borrower].countCancelled++;
        borrowerStats[offer.borrower].hasOpenApplication = false;
        
        offeredFunds = offeredFunds.sub(offer.amount);
        ILoanDeskOwner(pool).onOfferUpdate(offer.amount, 0);

        emit LoanOfferCancelled(appId, offer.borrower);
    }

    function onBorrow(uint256 appId) external override onlyPool applicationInStatus(appId, LoanApplicationStatus.OFFER_MADE) {
        LoanApplication storage app = loanApplications[appId];
        app.status = LoanApplicationStatus.OFFER_ACCEPTED;
        borrowerStats[app.borrower].hasOpenApplication = false;
        offeredFunds = offeredFunds.sub(loanOffers[appId].amount);
    }

    /**
     * @notice View indicating whether or not a given loan approval qualifies to be cancelled by a given caller.
     * @param appId application ID to check
     * @param caller address that intends to call cancel() on the loan
     * @return True if the given loan approval can be cancelled, false otherwise
     */
    function canCancel(uint256 appId, address caller) external view returns (bool) {
        if (caller != manager && !authorizedOnInactiveManager(caller)) {
            return false;
        }

        return loanApplications[appId].status == LoanApplicationStatus.OFFER_MADE 
            && block.timestamp >= (loanOffers[appId].offeredTime + (caller == manager ? 0 : MANAGER_INACTIVITY_GRACE_PERIOD));
    }

    function applicationStatus(uint256 appId) external view override returns (LoanApplicationStatus) {
        return loanApplications[appId].status;
    }

    function loanOfferById(uint256 appId) external view override returns (LoanOffer memory) {
        return loanOffers[appId];
    }

    function authorizedOnInactiveManager(address caller) override internal view returns (bool) {
        return caller == governance || caller == protocol;
    }

    function canClose() override internal pure returns (bool) {
        return true;
    }

    function validLoanParams(
        uint256 _amount, 
        uint256 _duration, 
        uint256 _gracePeriod, 
        uint256 _installmentAmount,
        uint16 _installments, 
        uint16 _apr
    ) private view returns (bool)
    {
        require(_amount >= minLoanAmount);
        require(minLoanDuration <= _duration && _duration <= maxLoanDuration);
        require(MIN_LOAN_GRACE_PERIOD <= _gracePeriod && _gracePeriod <= MAX_LOAN_GRACE_PERIOD);
        require(_installmentAmount == 0 || _installmentAmount >= SAFE_MIN_AMOUNT);
        require(1 <= _installments && _installments <= 4096); //FIXME set upper bound for installments
        require(SAFE_MIN_APR <= _apr && _apr <= SAFE_MAX_APR, "APR is out of bounds");
        return true;
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.15;

import "./SaplingContext.sol";

abstract contract SaplingManagerContext is SaplingContext {

    /// Pool manager address
    address public manager;

    /// Flag indicating whether or not the pool is closed
    bool private _closed;

    /**
     * @notice Grace period for the manager to be inactive on a given loan /cancel/default decision. 
     *         After this grace period of managers inaction on a given loan authorised parties
     *         can also call cancel() and default(). Other requirements for loan cancellation/default still apply.
     */
    uint256 public constant MANAGER_INACTIVITY_GRACE_PERIOD = 90 days;
    
    modifier onlyManager {
        // direct use of msg.sender is intentional
        require(msg.sender == manager, "Sapling: Caller is not the manager");
        _;
    }    

    modifier managerOrApprovedOnInactive {
        require(msg.sender == manager || authorizedOnInactiveManager(msg.sender),
            "Managed: caller is not the manager or an approved party.");
        _;
    }

    modifier onlyUser() {
        require(msg.sender != manager && msg.sender != governance && msg.sender != protocol, "SaplingPool: Caller is not a valid lender.");
        _;
    }

    event Closed(address account);
    event Opened(address account);

    modifier whenNotClosed {
        require(!_closed, "Sapling: closed");
        _;
    }

    modifier whenClosed {
        require(_closed, "Sapling: not closed");
        _;
    }

    /**
     * @notice Create a managed lending pool.
     * @dev msg.sender will be assigned as the manager of the created pool.
     * @param _manager Address of the pool manager
     * @param _governance Address of the protocol governance.
     * @param _protocol Address of a wallet to accumulate protocol earnings.
     */
    constructor(address _governance, address _protocol, address _manager) SaplingContext(_governance, _protocol) {
        require(_manager != address(0), "Sapling: Manager address is not set");
        manager = _manager;
        _closed = false;
    }

    /**
     * @notice Close the pool and stop borrowing, lender deposits, and staking. 
     * @dev Caller must be the manager. 
     *      Pool must be open.
     *      No loans or approvals must be outstanding (borrowedFunds must equal to 0).
     *      Emits 'PoolClosed' event.
     */
    function close() external onlyManager whenNotClosed {
        require(canClose(), "Cannot close pool with outstanding loans.");
        _closed = true;
        emit Closed(msg.sender);
    }

    /**
     * @notice Open the pool for normal operations. 
     * @dev Caller must be the manager. 
     *      Pool must be closed.
     *      Opening the pool will not unpause any pauses in effect.
     *      Emits 'PoolOpened' event.
     */
    function open() external onlyManager whenClosed {
        _closed = false;
        emit Opened(msg.sender);
    }

    function closed() public view returns (bool) {
        return _closed;
    }

    function canClose() virtual internal view returns (bool);

    function authorizedOnInactiveManager(address caller) virtual internal view returns (bool);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.15;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../interfaces/IMath.sol";

abstract contract SaplingMathContext is IMath {

    /// Number of decimal digits in integer percent values used across the contract
    uint16 public constant PERCENT_DECIMALS = 1;

    /// A constant representing 100%
    uint16 public immutable ONE_HUNDRED_PERCENT;

    constructor() {
        ONE_HUNDRED_PERCENT = uint16(100 * 10 ** PERCENT_DECIMALS);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

interface ILoanDesk {

    enum LoanApplicationStatus {
        NULL, 
        APPLIED,
        DENIED,
        OFFER_MADE,
        OFFER_ACCEPTED,
        OFFER_CANCELLED
    }

    struct LoanOffer {
        uint256 applicationId;
        address borrower;
        uint256 amount;
        uint256 duration;
        uint256 gracePeriod;
        uint256 installmentAmount;
        uint16 installments;
        uint16 apr;
        uint256 offeredTime;
    }

    function applicationStatus(uint256 appId) external view returns (LoanApplicationStatus);

    function loanOfferById(uint256 appId) external view returns (LoanOffer memory);

    function onBorrow(uint256 appId) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

interface ILoanDeskOwner {

    function setLoanDesk(address _loanDesk) external;
    
    function canOffer(uint256 totalLoansAmount) external view returns (bool);

    function onOffer(uint256 amount) external;

    function onOfferUpdate(uint256 prevAmount, uint256 amount) external;
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.15;

import "@openzeppelin/contracts/security/Pausable.sol";

abstract contract SaplingContext is Pausable {

    /// Protocol governance
    address public governance;

    /// Protocol wallet address
    address public protocol;

    /// Event emitted when a new governance is set
    event GovernanceTransferred(address from, address to);
    event ProtocolWalletSet(address from, address to);

    /// A modifier to limit access to the governance
    modifier onlyGovernance {
        // direct use of msg.sender is intentional
        require(msg.sender == governance, "Managed: Caller is not the governance");
        _;
    }

    /**
     * @notice Creates new SaplingContext instance.
     * @dev _governance must not be 0
     * @param _governance Address of the protocol governance.
     */
    constructor(address _governance, address _protocol) {
        require(_governance != address(0), "Sapling: Governance address is not set");
        require(_protocol != address(0), "Sapling: Protocol wallet address is not set");
        governance = _governance;
        protocol = _protocol;
    }

    /**
     * @notice Transfer the governance.
     * @dev Caller must be governance. 
     *      _governance must not be 0.
     * @param _governance Address of the new governance.
     */
    function transferGovernance(address _governance) external onlyGovernance {
        require(_governance != address(0) && _governance != governance, "Governed: New governance address is invalid.");
        address prevGovernance = governance;
        governance = _governance;
        emit GovernanceTransferred(prevGovernance, governance);
    }

    function setProtocolWallet(address _protocol) external onlyGovernance {
        require(_protocol != address(0) && _protocol != protocol, "Governed: New protocol wallet address is invalid.");
        address prevProtocol = protocol;
        protocol = _protocol;
        emit ProtocolWalletSet(prevProtocol, protocol);
    }

    function pause() external onlyGovernance {
        _pause();
    }

    function unpause() external onlyGovernance {
        _unpause();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
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
    constructor() {
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
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

interface IMath {

    function PERCENT_DECIMALS() external view returns (uint16);
}