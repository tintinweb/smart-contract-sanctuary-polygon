// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./FactoryBase.sol";
import "./ILoanDeskFactory.sol";
import "../LoanDesk.sol";


/**
 * @title LoanDesk Factory
 * @notice Facilitates on-chain deployment of new LoanDesk contracts.
 */
contract LoanDeskFactory is ILoanDeskFactory, FactoryBase {

    /// Event for when a new LoanDesk is deployed
    event LoanDeskCreated(address pool);

    /**
     * @notice Deploys a new instance of LoanDesk.
     * @dev Lending pool contract must implement ILoanDeskOwner.
     *      Caller must be the owner.
     * @param pool LendingPool address
     * @param governance Governance address
     * @param treasury Treasury wallet address
     * @param manager Manager address
     * @param decimals Decimals of the tokens used in the pool
     * @return Address of the deployed contract
     */
    function create(
        address pool,
        address governance,
        address treasury,
        address manager,
        uint8 decimals
    )
        external
        onlyOwner
        returns (address)
    {
        LoanDesk desk = new LoanDesk(pool, governance, treasury, manager, decimals);
        emit LoanDeskCreated(address(desk));
        return address(desk);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";


/**
 * @title Factory base
 * @dev Provides Ownable and shutdown/selfdestruct
 */
contract FactoryBase is Ownable {

    /**
     * @dev permanently shutdown this factory and the sub-factories it manages by self-destructing them.
     */
    function shutdown() external virtual onlyOwner {
        preShutdown();
        selfdestruct(payable(address(0)));
    }

    /**
     * Pre shutdown handler for extending contracts to override
     */
    function preShutdown() internal virtual onlyOwner {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

/**
 * @title Loan Desk Factory Interface
 * @dev Interface defining the inter-contract methods of a LoanDesk factory.
 */
interface ILoanDeskFactory {

    /**
     * @notice Deploys a new instance of LoanDesk.
     * @dev Lending pool contract must implement ILoanDeskOwner.
     *      Caller must be the owner.
     * @param pool LendingPool address
     * @param governance Governance address
     * @param protocol Protocol wallet address
     * @param manager Manager address
     * @param decimals Decimals of the tokens used in the pool
     * @return Address of the deployed contract
     */
    function create(
        address pool,
        address governance,
        address protocol,
        address manager,
        uint8 decimals
    )
        external
        returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "./context/SaplingManagerContext.sol";
import "./context/SaplingMathContext.sol";
import "./interfaces/ILoanDesk.sol";
import "./interfaces/ILoanDeskOwner.sol";

/**
 * @title Loan Desk
 * @notice Provides loan application and offer management.
 */

 //FIXME upgradable
contract LoanDesk is ILoanDesk, SaplingManagerContext, SaplingMathContext {

    using SafeMath for uint256;

    /// Loan application object template
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

        /// All time loan offer cancellation count
        uint256 countCancelled;

        /// Most recent application id
        uint256 recentApplicationId;

        /// Whether or not this borrower has a pending application
        bool hasOpenApplication;
    }

    /// Address of the lending pool contract
    address public pool;

    /// Math safe minimum loan amount including token decimals
    uint256 public immutable SAFE_MIN_AMOUNT;

    /// Minimum allowed loan amount
    uint256 public minLoanAmount;

    /// Math safe minimum loan duration in seconds
    uint256 public constant SAFE_MIN_DURATION = 1 days;

    /// Math safe maximum loan duration in seconds
    uint256 public constant SAFE_MAX_DURATION = 51 * 365 days;

    /// Minimum loan duration in seconds
    uint256 public minLoanDuration;

    /// Maximum loan duration in seconds
    uint256 public maxLoanDuration;

    /// Loan payment grace period after which a loan can be defaulted
    uint256 public templateLoanGracePeriod = 60 days;

    /// Minimum allowed loan payment grace period
    uint256 public constant MIN_LOAN_GRACE_PERIOD = 3 days;

    /// Maximum allowed loan payment grace period
    uint256 public constant MAX_LOAN_GRACE_PERIOD = 365 days;

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

    /// Total liquidity tokens allocated for loan offers and pending acceptance by the borrowers
    uint256 public offeredFunds;

    /// Event for when a new loan is requested, and an application is created
    event LoanRequested(uint256 applicationId, address indexed borrower);

    /// Event for when a loan request is denied
    event LoanRequestDenied(uint256 applicationId, address indexed borrower);

    /// Event for when a loan offer is made
    event LoanOffered(uint256 applicationId, address indexed borrower);

    /// Event for when a loan offer is updated
    event LoanOfferUpdated(uint256 applicationId, address indexed borrower);

    /// Event for when a loan offer is cancelled
    event LoanOfferCancelled(uint256 applicationId, address indexed borrower);

    /// A modifier to limit access only to the lending pool contract
    modifier onlyPool() {
        require(msg.sender == pool, "LoanDesk: caller is not the lending pool");
        _;
    }

    /// A modifier to limit access only to when the application exists and has the specified status
    modifier applicationInStatus(uint256 applicationId, LoanApplicationStatus status) {
        LoanApplication storage app = loanApplications[applicationId];
        require(app.id != 0, "LoanDesk: loan application is not found");
        require(app.status == status, "LoanDesk: invalid application status");
        _;
    }

    /**
     * @notice Create a new LoanDesk.
     * @dev Addresses must not be 0.
     * @param _pool Lending pool address
     * @param _governance Governance address
     * @param _treasury Treasury wallet address
     * @param _manager Manager address
     * @param _decimals Lending pool liquidity token decimals
     */
    constructor(address _pool, address _governance, address _treasury, address _manager, uint8 _decimals)
        SaplingManagerContext(_governance, _treasury, _manager) {

        require(_pool != address(0), "LoanDesk: invalid pool address");

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
     * @notice Set a minimum loan amount.
     * @dev minLoanAmount must be greater than or equal to SAFE_MIN_AMOUNT.
     *      Caller must be the manager.
     * @param _minLoanAmount Minimum loan amount to be enforced on new loan requests and offers
     */
    function setMinLoanAmount(uint256 _minLoanAmount) external onlyManager whenNotPaused {
        require(SAFE_MIN_AMOUNT <= _minLoanAmount, "LoanDesk: new min loan amount is less than the safe limit");
        minLoanAmount = _minLoanAmount;
    }

    /**
     * @notice Set the minimum loan duration
     * @dev Duration must be in seconds and inclusively between SAFE_MIN_DURATION and maxLoanDuration.
     *      Caller must be the manager.
     * @param duration Minimum loan duration to be enforced on new loan requests and offers
     */
    function setMinLoanDuration(uint256 duration) external onlyManager whenNotPaused {
        require(SAFE_MIN_DURATION <= duration && duration <= maxLoanDuration,
            "LoanDesk: new min duration is out of bounds");
        minLoanDuration = duration;
    }

    /**
     * @notice Set the maximum loan duration.
     * @dev Duration must be in seconds and inclusively between minLoanDuration and SAFE_MAX_DURATION.
     *      Caller must be the manager.
     * @param duration Maximum loan duration to be enforced on new loan requests and offers
     */
    function setMaxLoanDuration(uint256 duration) external onlyManager whenNotPaused {
        require(minLoanDuration <= duration && duration <= SAFE_MAX_DURATION,
            "LoanDesk: new max duration is out of bounds");
        maxLoanDuration = duration;
    }

    /**
     * @notice Set the template loan payment grace period.
     * @dev Grace period must be in seconds and inclusively between MIN_LOAN_GRACE_PERIOD and MAX_LOAN_GRACE_PERIOD.
     *      Caller must be the manager.
     * @param gracePeriod Loan payment grace period for new loan offers
     */
    function setTemplateLoanGracePeriod(uint256 gracePeriod) external onlyManager whenNotPaused {
        require(MIN_LOAN_GRACE_PERIOD <= gracePeriod && gracePeriod <= MAX_LOAN_GRACE_PERIOD,
            "LoanDesk: new grace period is out of bounds.");
        templateLoanGracePeriod = gracePeriod;
    }

    /**
     * @notice Set a template loan APR
     * @dev APR must be inclusively between SAFE_MIN_APR and SAFE_MAX_APR.
     *      Caller must be the manager.
     * @param apr Loan APR to be enforced on the new loan offers.
     */
    function setTemplateLoanAPR(uint16 apr) external onlyManager whenNotPaused {
        require(SAFE_MIN_APR <= apr && apr <= SAFE_MAX_APR, "LoanDesk: APR is out of bounds");
        templateLoanAPR = apr;
    }

    /**
     * @notice Request a new loan.
     * @dev Requested amount must be greater or equal to minLoanAmount().
     *      Loan duration must be between minLoanDuration() and maxLoanDuration().
     *      Multiple pending applications from the same address are not allowed -
     *      most recent loan/application of the caller must not have APPLIED status.
     * @param _amount Liquidity token amount to be borrowed
     * @param _duration Loan duration in seconds
     * @param _profileId Borrower metadata profile id obtained from the borrower service
     * @param _profileDigest Borrower metadata digest obtained from the borrower service
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
        require(borrowerStats[msg.sender].hasOpenApplication == false, "LoanDesk: another loan application is pending");
        require(_amount >= minLoanAmount, "LoanDesk: loan amount is less than the minimum allowed");
        require(minLoanDuration <= _duration, "LoanDesk: loan duration is less than minimum allowed");
        require(maxLoanDuration >= _duration, "LoanDesk: loan duration is greater than maximum allowed");

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
     *      Loan amount must not exceed available liquidity -
     *      canOffer(offeredFunds.add(_amount)) must be true on the lending pool.
     * @param appId Loan application id
     * @param _amount Loan amount in liquidity tokens
     * @param _duration Loan term in seconds
     * @param _gracePeriod Loan payment grace period in seconds
     * @param _installmentAmount Minimum payment amount on each instalment in liquidity tokens
     * @param _installments The number of payment installments
     * @param _apr Annual percentage rate of this loan
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
        validateLoanParams(_amount, _duration, _gracePeriod, _installmentAmount, _installments, _apr);

        LoanApplication storage app = loanApplications[appId];

        require(ILoanDeskOwner(pool).canOffer(offeredFunds.add(_amount)),
            "LoanDesk: lending pool cannot offer this loan at this time");
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
     * @notice Update an existing loan offer.
     * @dev Loan application must be in OFFER_MADE status.
     *      Caller must be the manager.
     *      Loan amount must not exceed available liquidity -
     *      canOffer(offeredFunds.add(offeredFunds.sub(offer.amount).add(_amount))) must be true on the lending pool.
     * @param appId Loan application id
     * @param _amount Loan amount in liquidity tokens
     * @param _duration Loan term in seconds
     * @param _gracePeriod Loan payment grace period in seconds
     * @param _installmentAmount Minimum payment amount on each instalment in liquidity tokens
     * @param _installments The number of payment installments
     * @param _apr Annual percentage rate of this loan
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
        validateLoanParams(_amount, _duration, _gracePeriod, _installmentAmount, _installments, _apr);

        LoanOffer storage offer = loanOffers[appId];

        if (offer.amount != _amount) {
            uint256 nextOfferedFunds = offeredFunds.sub(offer.amount).add(_amount);

            require(ILoanDeskOwner(pool).canOffer(nextOfferedFunds),
                "LoanDesk: lending pool cannot offer this loan at this time");
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
     * @dev Loan application must be in OFFER_MADE status.
     *      Caller must be the manager or approved party when the manager is inactive.
     */
    function cancelLoan(
        uint256 appId
    )
        external
        managerOrApprovedOnInactive
        applicationInStatus(appId, LoanApplicationStatus.OFFER_MADE)
    {
        LoanOffer storage offer = loanOffers[appId];

        // check if the call was made by an eligible non manager party, due to manager's inaction on the loan.
        if (msg.sender != manager) {
            // require inactivity grace period
            require(block.timestamp > offer.offeredTime + MANAGER_INACTIVITY_GRACE_PERIOD,
                "LoanDesk: too early to cancel this loan as a non-manager");
        }

        loanApplications[appId].status = LoanApplicationStatus.OFFER_CANCELLED;
        borrowerStats[offer.borrower].countCancelled++;
        borrowerStats[offer.borrower].hasOpenApplication = false;

        offeredFunds = offeredFunds.sub(offer.amount);
        ILoanDeskOwner(pool).onOfferUpdate(offer.amount, 0);

        emit LoanOfferCancelled(appId, offer.borrower);
    }

    /**
     * @notice Hook to be called when a loan offer is accepted. Updates the loan offer and liquidity state.
     * @dev Loan application must be in OFFER_MADE status.
     *      Caller must be the lending pool.
     * @param appId ID of the application the accepted offer was made for.
     */
    function onBorrow(
        uint256 appId
    )
        external
        override
        onlyPool
        applicationInStatus(appId, LoanApplicationStatus.OFFER_MADE)
    {
        LoanApplication storage app = loanApplications[appId];
        app.status = LoanApplicationStatus.OFFER_ACCEPTED;
        borrowerStats[app.borrower].hasOpenApplication = false;
        offeredFunds = offeredFunds.sub(loanOffers[appId].amount);
    }

    /**
     * @notice View indicating whether or not a given loan offer qualifies to be cancelled by a given caller.
     * @param appId Application ID of the loan offer in question
     * @param caller Address that intends to call cancel() on the loan offer
     * @return True if the given loan approval can be cancelled and can be cancelled by the specified caller,
     *         false otherwise.
     */
    function canCancel(uint256 appId, address caller) external view returns (bool) {
        if (caller != manager && !authorizedOnInactiveManager(caller)) {
            return false;
        }

        return loanApplications[appId].status == LoanApplicationStatus.OFFER_MADE && block.timestamp >= (
                loanOffers[appId].offeredTime + (caller == manager ? 0 : MANAGER_INACTIVITY_GRACE_PERIOD)
            );
    }

    /**
     * @notice Accessor for application status.
     * @dev NULL status is returned for nonexistent applications.
     * @param appId ID of the application in question.
     * @return Current status of the application with the specified ID.
     */
    function applicationStatus(uint256 appId) external view override returns (LoanApplicationStatus) {
        return loanApplications[appId].status;
    }

    /**
     * @notice Accessor for loan offer.
     * @dev Loan offer is valid when the loan application is present and has OFFER_MADE status.
     * @param appId ID of the application the offer was made for.
     * @return LoanOffer struct instance for the specified application ID.
     */
    function loanOfferById(uint256 appId) external view override returns (LoanOffer memory) {
        return loanOffers[appId];
    }

    /**
     * @notice Indicates whether or not the the caller is authorized to take applicable managing actions when the
     *         manager is inactive.
     * @dev Overrides a hook in SaplingManagerContext.
     * @param caller Caller's address.
     * @return True if the caller is authorized at this time, false otherwise.
     */
    function authorizedOnInactiveManager(address caller) override internal view returns (bool) {
        return caller == governance || caller == treasury;
    }

    /**
     * @notice Indicates whether or not the contract can be closed in it's current state.
     * @dev Overrides a hook in SaplingManagerContext.
     * @return True if the contract is closed, false otherwise.
     */
    function canClose() override internal pure returns (bool) {
        return true;
    }

    /**
     * @notice Validates loan offer parameters
     * @dev Throws a require-type exception on invalid loan parameter
     * @param _amount Loan amount in liquidity tokens
     * @param _duration Loan term in seconds
     * @param _gracePeriod Loan payment grace period in seconds
     * @param _installmentAmount Minimum payment amount on each instalment in liquidity tokens
     * @param _installments The number of payment installments
     * @param _apr Annual percentage rate of this loan
     */
    function validateLoanParams(
        uint256 _amount,
        uint256 _duration,
        uint256 _gracePeriod,
        uint256 _installmentAmount,
        uint16 _installments,
        uint16 _apr
    ) private view
    {
        require(_amount >= minLoanAmount, "LoanDesk: invalid amount");
        require(minLoanDuration <= _duration && _duration <= maxLoanDuration, "LoanDesk: invalid duration");
        require(MIN_LOAN_GRACE_PERIOD <= _gracePeriod && _gracePeriod <= MAX_LOAN_GRACE_PERIOD,
            "LoanDesk: invalid grace period");
        require(
            _installmentAmount == 0 || _installmentAmount >= SAFE_MIN_AMOUNT,
            "LoanDesk: invalid installment amount"
        );
        require(
            1 <= _installments && _installments <= _duration / (1 days),
            "LoanDesk: invalid number of installments"
        );
        require(SAFE_MIN_APR <= _apr && _apr <= SAFE_MAX_APR, "LoanDesk: invalid APR");
    }
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

pragma solidity ^0.8.15;

import "./SaplingContext.sol";

/**
 * @title Sapling Manager Context
 * @notice Provides manager access control, and a basic close functionality.
 */
abstract contract SaplingManagerContext is SaplingContext {

    /// Manager address
    address public manager;

    /// Flag indicating whether or not the pool is closed
    bool private _closed;

    /**
     * @notice Grace period for the manager to be inactive on a given loan /cancel/default decision.
     *         After this grace period of managers inaction on a given loan authorized parties
     *         can also call cancel() and default(). Other requirements for loan cancellation/default still apply.
     */
    uint256 public constant MANAGER_INACTIVITY_GRACE_PERIOD = 90 days;

    /// Event for when the contract is closed
    event Closed(address account);

    /// Event for when the contract is reopened
    event Opened(address account);

    /// Event for when a new manager is set
    event ManagerTransferred(address from, address to);

    /// A modifier to limit access only to the manager
    modifier onlyManager {
        require(msg.sender == manager, "SaplingManagerContext: caller is not the manager");
        _;
    }

    /// A modifier to limit access to the manager or to other applicable parties when the manager is considered inactive
    modifier managerOrApprovedOnInactive {
        require(msg.sender == manager || authorizedOnInactiveManager(msg.sender),
            "SaplingManagerContext: caller is neither the manager nor an approved party");
        _;
    }

    /// A modifier to limit access only to non-management users
    modifier onlyUser() {
        require(!isNonUserAddress(msg.sender), "SaplingManagerContext: caller is not a user");
        _;
    }

    /// Modifier to limit function access to when the contract is not closed
    modifier whenNotClosed {
        require(!_closed, "SaplingManagerContext: closed");
        _;
    }

    /// Modifier to limit function access to when the contract is closed
    modifier whenClosed {
        require(_closed, "SaplingManagerContext: not closed");
        _;
    }

    /**
     * @notice Create a new SaplingManagedContext.
     * @dev Addresses must not be 0.
     * @param _governance Governance address
     * @param _treasury Treasury wallet address
     * @param _manager Manager address
     */
    constructor(address _governance, address _treasury, address _manager) SaplingContext(_governance, _treasury) {
        require(_manager != address(0), "SaplingManagerContext: manager address is not set");
        manager = _manager;
        _closed = false;
    }

    /**
     * @notice Transfer the manager.
     * @dev Caller must be the governance.
     *      New manager address must not be 0, and must not be one of current non-user addresses.
     * @param _manager New manager address
     */
    function transferManager(address _manager) external onlyGovernance {
        require(
            _manager != address(0) && !isNonUserAddress(_manager),
            "SaplingManagerContext: invalid manager address"
        );
        address prevManager = manager;
        manager = _manager;
        emit ManagerTransferred(prevManager, manager);
    }

    /**
     * @notice Close the pool and stop borrowing, lender deposits, and staking.
     * @dev Caller must be the manager.
     *      Pool must be open.
     *      No loans or approvals must be outstanding (borrowedFunds must equal to 0).
     *      Emits 'PoolClosed' event.
     */
    function close() external onlyManager whenNotClosed {
        require(canClose(), "SaplingManagerContext: cannot close the pool with outstanding loans");
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

    /**
     * @notice Indicates whether or not the contract is closed.
     * @return True if the contract is closed, false otherwise.
     */
    function closed() public view returns (bool) {
        return _closed;
    }

    /**
     * @notice Verify if an address is currently in any non-user/management position.
     * @dev a hook in Sampling Context
     * @param party Address to verify
     */
    function isNonUserAddress(address party) internal view override returns (bool) {
        return party == manager || super.isNonUserAddress(party);
    }
    /**
     * @notice Indicates whether or not the contract can be closed in it's current state.
     * @dev A hook for the extending contract to implement.
     * @return True if the contract is closed, false otherwise.
     */
    function canClose() internal view virtual returns (bool);

    /**
     * @notice Indicates whether or not the the caller is authorized to take applicable managing actions when the
     *         manager is inactive.
     * @dev A hook for the extending contract to implement.
     * @param caller Caller's address.
     * @return True if the caller is authorized at this time, false otherwise.
     */
    function authorizedOnInactiveManager(address caller) internal view virtual returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../interfaces/IMath.sol";

/**
 * @title Sapling Math Context
 * @notice Provides common math constants and library imports.
 */
abstract contract SaplingMathContext is IMath {

    /// Number of decimal digits in integer percent values used across the contract
    uint16 public constant PERCENT_DECIMALS = 1;

    /// A constant representing 100%
    uint16 public immutable ONE_HUNDRED_PERCENT; //FIXME rename camelcase

    /**
     * @notice Create a new SaplingMathContext.
     */
    constructor() {
        ONE_HUNDRED_PERCENT = uint16(100 * 10 ** PERCENT_DECIMALS);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

/**
 * @title LoanDesk Interface
 * @dev LoanDesk interface defining common structures and hooks for the lending pools.
 */
interface ILoanDesk {

    /**
     * Loan application statuses. Initial value is defines as 'NULL' to differentiate the unintitialized state from
     * the logical initial state.
     */
    enum LoanApplicationStatus {
        NULL,
        APPLIED,
        DENIED,
        OFFER_MADE,
        OFFER_ACCEPTED,
        OFFER_CANCELLED
    }

    /// Loan offer object template
    struct LoanOffer {
        uint256 applicationId; // ID of the loan application this offer is made for
        address borrower; // applicant address
        uint256 amount; // offered loan principal amount in liquidity tokens
        uint256 duration; // requested loan term in seconds
        uint256 gracePeriod; // payment grace period in seconds
        uint256 installmentAmount; // minimum payment amount on each instalment in liquidity tokens
        uint16 installments; //number of payment installments
        uint16 apr; // annual percentage rate of this loan
        uint256 offeredTime; //the time this offer was created or last updated
    }

    /**
     * @dev Hook to be called when a loan offer is accepted.
     * @param appId ID of the application the accepted offer was made for.
     */
    function onBorrow(uint256 appId) external;

    /**
     * @notice Accessor for application status.
     * @dev NULL status is returned for nonexistent applications.
     * @param appId ID of the application in question.
     * @return Current status of the application with the specified ID.
     */
    function applicationStatus(uint256 appId) external view returns (LoanApplicationStatus);

    /**
     * @notice Accessor for loan offer.
     * @dev Loan offer is valid when the loan application is present and has OFFER_MADE status.
     * @param appId ID of the application the offer was made for.
     * @return LoanOffer struct instance for the specified application ID.
     */
    function loanOfferById(uint256 appId) external view returns (LoanOffer memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

/**
 * @title LoanDesk Owner Interface
 * @dev Interface defining functional hooks for LoanDesk, and setup hooks for SaplingFactory.
 */
interface ILoanDeskOwner {

    /**
     * @notice Links a new loan desk for the pool to use. Intended for use upon initial pool deployment.
     * @dev Caller must be the governance.
     * @param _loanDesk New LoanDesk address
     */
    function setLoanDesk(address _loanDesk) external;

    /**
     * @notice Handles liquidity state changes on a loan offer.
     * @dev Hook to be called when a new loan offer is made.
     *      Caller must be the LoanDesk.
     * @param amount Loan offer amount.
     */
    function onOffer(uint256 amount) external;

    /**
     * @dev Hook to be called when a loan offer amount is updated. Amount update can be due to offer update or
     *      cancellation. Caller must be the LoanDesk.
     * @param prevAmount The original, now previous, offer amount.
     * @param amount New offer amount. Cancelled offer must register an amount of 0 (zero).
     */
    function onOfferUpdate(uint256 prevAmount, uint256 amount) external;

    /**
     * @dev Hook for checking if the lending pool can provide liquidity for the total offered loans amount.
     * @param totalOfferedAmount Total sum of offered loan amount including outstanding offers
     * @return True if the pool has sufficient lending liquidity, false otherwise.
     */
    function canOffer(uint256 totalOfferedAmount) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "@openzeppelin/contracts/security/Pausable.sol";

/**
 * @title Sapling Context
 * @notice Provides governance access control, a common reverence to the treasury wallet address, and basic pause
 *         functionality by extending OpenZeppelin's Pausable contract.
 */
abstract contract SaplingContext is Pausable {

    /// Protocol governance
    address public governance;

    /// Protocol treasury wallet address
    address public treasury;

    /// Event for when a new governance is set
    event GovernanceTransferred(address from, address to);

    /// Event for when a new treasury wallet is set
    event TreasuryWalletTransferred(address from, address to);

    /// A modifier to limit access only to the governance
    modifier onlyGovernance {
        require(msg.sender == governance, "SaplingContext: caller is not the governance");
        _;
    }

    /**
     * @notice Creates a new SaplingContext.
     * @dev Addresses must not be 0.
     * @param _governance Governance address
     * @param _treasury Treasury wallet address
     */
    constructor(address _governance, address _treasury) {
        require(_governance != address(0), "SaplingContext: governance address is not set");
        require(_treasury != address(0), "SaplingContext: treasury wallet address is not set");
        governance = _governance;
        treasury = _treasury;
    }

    /**
     * @notice Pause the contract.
     * @dev Caller must be the governance.
     *      Only the functions using whenPaused and whenNotPaused modifiers will be affected by pause.
     */
    function pause() external onlyGovernance {
        _pause();
    }

    /**
     * @notice Resume the contract.
     * @dev Caller must be the governance.
     *      Only the functions using whenPaused and whenNotPaused modifiers will be affected by unpause.
     */
    function unpause() external onlyGovernance {
        _unpause();
    }

    /**
     * @notice Transfer the governance.
     * @dev Caller must be the governance.
     *      New governance address must not be 0, and must not be one of current non-user addresses.
     * @param _governance New governance address.
     */
    function transferGovernance(address _governance) external onlyGovernance {
        require(
            _governance != address(0) && !isNonUserAddress(_governance),
            "SaplingContext: invalid governance address"
        );
        address prevGovernance = governance;
        governance = _governance;
        emit GovernanceTransferred(prevGovernance, governance);
    }

    /**
     * @notice Transfer the treasury role.
     * @dev Caller must be the governance.
     *      New treasury address must not be 0, and must not be one of current non-user addresses.
     * @param _treasury New treasury wallet address
     */
    function transferTreasury(address _treasury) external onlyGovernance {
        require(
            _treasury != address(0) && !isNonUserAddress(_treasury),
            "SaplingContext: invalid treasury wallet address"
        );
        address prevTreasury = treasury;
        treasury = _treasury;
        emit TreasuryWalletTransferred(prevTreasury, treasury);
        afterTreasuryWalletTransfer(prevTreasury);
    }

    /**
     * @notice Hook that is called after a new treasury wallet address has been set.
     * @param from Address of the previous treasury wallet.
     */
    function afterTreasuryWalletTransfer(address from) internal virtual {}

    /**
     * @notice Hook that is called to verify if an address is currently in any non-user/management position.
     * @dev When overriding, return "contract local verification result" AND super.isNonUserAddress(party).
     * @param party Address to verify
     */
    function isNonUserAddress(address party) internal view virtual returns (bool) {
        return party == governance || party == treasury;
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

/**
 * @title Math Context Interface
 */
interface IMath {

    /**
     * @notice Accessor for percentage value decimals used in the current context.
     * @return Number of decimal digits in integer percent values used across the contract.
     */
    function PERCENT_DECIMALS() external view returns (uint16);
}