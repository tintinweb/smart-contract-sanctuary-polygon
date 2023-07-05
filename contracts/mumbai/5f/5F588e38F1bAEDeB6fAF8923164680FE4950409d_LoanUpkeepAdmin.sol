// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @notice OnchainConfig of the registry
 * @dev only used in params and return values
 * @member paymentPremiumPPB payment premium rate oracles receive on top of
 * being reimbursed for gas, measured in parts per billion
 * @member flatFeeMicroLink flat fee paid to oracles for performing upkeeps,
 * priced in MicroLink; can be used in conjunction with or independently of
 * paymentPremiumPPB
 * @member checkGasLimit gas limit when checking for upkeep
 * @member stalenessSeconds number of seconds that is allowed for feed data to
 * be stale before switching to the fallback pricing
 * @member gasCeilingMultiplier multiplier to apply to the fast gas feed price
 * when calculating the payment ceiling for keepers
 * @member minUpkeepSpend minimum LINK that an upkeep must spend before cancelling
 * @member maxPerformGas max executeGas allowed for an upkeep on this registry
 * @member fallbackGasPrice gas price used if the gas price feed is stale
 * @member fallbackLinkPrice LINK price used if the LINK price feed is stale
 * @member transcoder address of the transcoder contract
 * @member registrar address of the registrar contract
 */
struct OnchainConfig {
  uint32 paymentPremiumPPB;
  uint32 flatFeeMicroLink; // min 0.000001 LINK, max 4294 LINK
  uint32 checkGasLimit;
  uint24 stalenessSeconds;
  uint16 gasCeilingMultiplier;
  uint96 minUpkeepSpend;
  uint32 maxPerformGas;
  uint32 maxCheckDataSize;
  uint32 maxPerformDataSize;
  uint256 fallbackGasPrice;
  uint256 fallbackLinkPrice;
  address transcoder;
  address registrar;
}

/**
 * @notice state of the registry
 * @dev only used in params and return values
 * @member nonce used for ID generation
 * @member ownerLinkBalance withdrawable balance of LINK by contract owner
 * @member expectedLinkBalance the expected balance of LINK of the registry
 * @member totalPremium the total premium collected on registry so far
 * @member numUpkeeps total number of upkeeps on the registry
 * @member configCount ordinal number of current config, out of all configs applied to this contract so far
 * @member latestConfigBlockNumber last block at which this config was set
 * @member latestConfigDigest domain-separation tag for current config
 * @member latestEpoch for which a report was transmitted
 * @member paused freeze on execution scoped to the entire registry
 */
struct State {
  uint32 nonce;
  uint96 ownerLinkBalance;
  uint256 expectedLinkBalance;
  uint96 totalPremium;
  uint256 numUpkeeps;
  uint32 configCount;
  uint32 latestConfigBlockNumber;
  bytes32 latestConfigDigest;
  uint32 latestEpoch;
  bool paused;
}

/**
 * @notice all information about an upkeep
 * @dev only used in return values
 * @member target the contract which needs to be serviced
 * @member executeGas the gas limit of upkeep execution
 * @member checkData the checkData bytes for this upkeep
 * @member balance the balance of this upkeep
 * @member admin for this upkeep
 * @member maxValidBlocknumber until which block this upkeep is valid
 * @member lastPerformBlockNumber the last block number when this upkeep was performed
 * @member amountSpent the amount this upkeep has spent
 * @member paused if this upkeep has been paused
 * @member skipSigVerification skip signature verification in transmit for a low security low cost model
 */
struct UpkeepInfo {
  address target;
  uint32 executeGas;
  bytes checkData;
  uint96 balance;
  address admin;
  uint64 maxValidBlocknumber;
  uint32 lastPerformBlockNumber;
  uint96 amountSpent;
  bool paused;
  bytes offchainConfig;
}

enum UpkeepFailureReason {
  NONE,
  UPKEEP_CANCELLED,
  UPKEEP_PAUSED,
  TARGET_CHECK_REVERTED,
  UPKEEP_NOT_NEEDED,
  PERFORM_DATA_EXCEEDS_LIMIT,
  INSUFFICIENT_BALANCE
}

interface AutomationRegistryBaseInterface {
  function registerUpkeep(
    address target,
    uint32 gasLimit,
    address admin,
    bytes calldata checkData,
    bytes calldata offchainConfig
  ) external returns (uint256 id);

  function cancelUpkeep(uint256 id) external;

  function pauseUpkeep(uint256 id) external;

  function unpauseUpkeep(uint256 id) external;

  function transferUpkeepAdmin(uint256 id, address proposed) external;

  function acceptUpkeepAdmin(uint256 id) external;

  function updateCheckData(uint256 id, bytes calldata newCheckData) external;

  function addFunds(uint256 id, uint96 amount) external;

  function setUpkeepGasLimit(uint256 id, uint32 gasLimit) external;

  function setUpkeepOffchainConfig(uint256 id, bytes calldata config) external;

  function getUpkeep(uint256 id) external view returns (UpkeepInfo memory upkeepInfo);

  function getActiveUpkeepIDs(uint256 startIndex, uint256 maxCount) external view returns (uint256[] memory);

  function getTransmitterInfo(address query)
    external
    view
    returns (
      bool active,
      uint8 index,
      uint96 balance,
      uint96 lastCollected,
      address payee
    );

  function getState()
    external
    view
    returns (
      State memory state,
      OnchainConfig memory config,
      address[] memory signers,
      address[] memory transmitters,
      uint8 f
    );
}

/**
 * @dev The view methods are not actually marked as view in the implementation
 * but we want them to be easily queried off-chain. Solidity will not compile
 * if we actually inherit from this interface, so we document it here.
 */
interface AutomationRegistryInterface is AutomationRegistryBaseInterface {
  function checkUpkeep(uint256 upkeepId)
    external
    view
    returns (
      bool upkeepNeeded,
      bytes memory performData,
      UpkeepFailureReason upkeepFailureReason,
      uint256 gasUsed,
      uint256 fastGasWei,
      uint256 linkNative
    );
}

interface AutomationRegistryExecutableInterface is AutomationRegistryBaseInterface {
  function checkUpkeep(uint256 upkeepId)
    external
    returns (
      bool upkeepNeeded,
      bytes memory performData,
      UpkeepFailureReason upkeepFailureReason,
      uint256 gasUsed,
      uint256 fastGasWei,
      uint256 linkNative
    );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface LinkTokenInterface {
  function allowance(address owner, address spender) external view returns (uint256 remaining);

  function approve(address spender, uint256 value) external returns (bool success);

  function balanceOf(address owner) external view returns (uint256 balance);

  function decimals() external view returns (uint8 decimalPlaces);

  function decreaseApproval(address spender, uint256 addedValue) external returns (bool success);

  function increaseApproval(address spender, uint256 subtractedValue) external;

  function name() external view returns (string memory tokenName);

  function symbol() external view returns (string memory tokenSymbol);

  function totalSupply() external view returns (uint256 totalTokensIssued);

  function transfer(address to, uint256 value) external returns (bool success);

  function transferAndCall(
    address to,
    uint256 value,
    bytes calldata data
  ) external returns (bool success);

  function transferFrom(
    address from,
    address to,
    uint256 value
  ) external returns (bool success);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

// import "hardhat/console.sol";

import "./LoanLibrary.sol";

import "../interfaces/IDepositToken.sol";
import "../interfaces/ILoanMultiSig.sol";
import "../interfaces/ILoanUpkeepAdmin.sol";

contract LoanContract {
    // ------------------ CUSTOM ERRORS --------------------

    error Unauthorized();
    error InvalidRepaymentSchedule();
    error OnlyLoanMultiSig();
    error InsufficientLoan();
    error LoanNotConfirmed();
    error NotPermittedTransferee();
    error InvalidInputError();

    // ----------------- CONSTANTS ----------------

    uint constant RAY = 10 ** 27;
    uint MINIMUM_REPAYMENTAMOUNT_DIVISOR = 1000;

    // address constant ADDRESS_UPKEEP_REGISTRAR_MUMBAI =
    //     0x57A4a13b35d25EE78e084168aBaC5ad360252467;
    // address constant ADDRESS_UPKEEP_REGISTRY_MUMBAI =
    //     0xE16Df59B887e3Caa439E0b29B42bA2e7976FD8b2;
    // address constant ADDRESS_UPKEEP_REGISTRAR_SEPOLIA =
    //     0x9a811502d843E5a03913d5A2cfb646c11463467A;
    // address constant ADDRESS_UPKEEP_REGISTRY_SEPOLIA =
    //     0xE16Df59B887e3Caa439E0b29B42bA2e7976FD8b2;

    // ----------------- CUSTOM TYPES ------------

    enum FloatingRateMaturityType {
        EuriborOneWeek,
        EuriborOneMonth,
        EuriborThreeMonths,
        EuriborSixMonths,
        EuriborOneYear
    }

    struct AncillaryContractAddresses {
        address loanMultiSig;
        address loanSale;
        address loanPercentage;
        address timelock;
        address chainlinkFunctions;
    }

    // ----------------- Chainlink variables --------------------
    // string public euribor_url;
    // bytes32 public euribor_jobId;
    // uint256 public euribor_fee;
    // uint256 public euriborInterestRate;
    // event RequestEuriborFulfilled(
    //     bytes32 indexed requestId,
    //     uint256 indexed euribor
    // );

    // ----------------- STATE VARIABLES ----------

    uint public creationTime;
    address public arranger;
    address public borrower;
    uint public loanAmount;
    uint public fixedInterestRate;
    LoanLibrary.TimeAndAmount[] public repaymentSchedule;
    uint[] public interestPaymentTimes;
    LoanLibrary.TimeRateAmount[] public rateAndOutstandingAmountHistory;
    uint public totalInterestPaid;
    uint public defaultInterestRateInRay;
    LoanLibrary.DefaultInterestTracker public defaultInterestTracker;
    LoanLibrary.LoanStatus public loanStatus;
    address public addressDepositToken;
    address public addressLoanMultiSig;
    address public addressLoanSale;
    address public addressLoanPercentage;
    address public addressTimelock;
    address public addressLoanUpkeepAdmin;
    address public addressChainlinkFunctions;
    uint public chainlinkUpkeepId;

    address[] public lenders;

    // ------------------ ACCESS CONTROL ---------------------------------

    function onlyLoanMultiSig() private view {
        if (msg.sender != addressLoanMultiSig) revert OnlyLoanMultiSig();
    }

    // ------------------ PUBLIC AND EXTERNAL FUNCTIONS ------------------------

    constructor(
        address _arranger,
        LoanLibrary.AddressAndAmount[] memory _originalLenders,
        address _borrower,
        uint _loanAmount,
        LoanLibrary.TimeAndAmount[] memory _repaymentSchedule,
        uint _fixedInterestRateInRay,
        uint[] memory _interestPaymentTimes,
        uint _defaultInterestRateInRay,
        address _addressDepositTokenArranger,
        AncillaryContractAddresses memory _ancillaryAddresses,
        address _addressLoanUpkeepAdmin
    ) {
        if (
            !LoanLibrary.checkRepaymentscheduleValid(
                _repaymentSchedule,
                _loanAmount
            )
        ) revert InvalidRepaymentSchedule();
        if (
            !LoanLibrary.checkInterestPaymentTimesValid(
                _interestPaymentTimes,
                _repaymentSchedule[_repaymentSchedule.length - 1].time
            )
        ) revert InvalidInputError();
        arranger = _arranger;
        borrower = _borrower;
        loanAmount = _loanAmount;
        fixedInterestRate = _fixedInterestRateInRay;
        interestPaymentTimes = _interestPaymentTimes;
        defaultInterestRateInRay = _defaultInterestRateInRay;
        loanStatus = LoanLibrary.LoanStatus.Proposed;
        addressDepositToken = _addressDepositTokenArranger;
        addressLoanPercentage = _ancillaryAddresses.loanPercentage;
        addressTimelock = _ancillaryAddresses.timelock;
        addressChainlinkFunctions = _ancillaryAddresses.chainlinkFunctions;
        addressLoanUpkeepAdmin = _addressLoanUpkeepAdmin;
        uint i;
        uint percentageInRay;
        for (i = 0; i < _repaymentSchedule.length; i++) {
            repaymentSchedule.push(_repaymentSchedule[i]);
        }

        for (i = 0; i < _originalLenders.length; i++) {
            percentageInRay = (_originalLenders[i].amount * RAY) / loanAmount;
            ILoanPercentage(addressLoanPercentage).transferByLoanContract(
                address(this),
                _originalLenders[i].inputAddress,
                percentageInRay
            );
            lenders.push(_originalLenders[i].inputAddress);
        }

        bool isOriginalLenderInputValid = LoanLibrary
            .checkIsOriginalLenderInputValid(_originalLenders, loanAmount);
        if (!isOriginalLenderInputValid) {
            revert InvalidInputError();
        }
        addressLoanSale = _ancillaryAddresses.loanSale;
        addressLoanMultiSig = _ancillaryAddresses.loanMultiSig;
    }

    function confirmLoan(
        uint _arrangementFeePercentageInRay,
        uint _initialFloatingRateInRay
    ) external {
        onlyLoanMultiSig();
        LoanLibrary.checkConfirmationRequirements(
            msg.sender,
            addressLoanMultiSig,
            loanStatus,
            repaymentSchedule[0].time,
            interestPaymentTimes[0]
        );

        LoanLibrary.makeFundsAvailableToBorrower(
            ILoanPercentage(addressLoanPercentage),
            lenders,
            loanAmount,
            _arrangementFeePercentageInRay,
            borrower,
            addressDepositToken
        );

        uint initialTotalInterestRate = LoanLibrary.getTotalInterestRate(
            fixedInterestRate,
            _initialFloatingRateInRay
        );
        LoanLibrary.updateRateAndOutstandingAmountHistory(
            rateAndOutstandingAmountHistory,
            initialTotalInterestRate,
            loanAmount
        );
        creationTime = block.timestamp;
        chainlinkUpkeepId = ILoanUpkeepAdmin(addressLoanUpkeepAdmin)
            .registerAndPredictID(addressChainlinkFunctions);
        loanStatus = LoanLibrary.LoanStatus.Performing;
    }

    // this function should ultimately be capable of being called only by Chainlink oracle
    // the floating rate will typically be EURIBOR
    // for fixed rate loan the floating rate will be zero

    function setFloatingRate(uint _newFloatingRateInRay) external {
        if (msg.sender != arranger) revert Unauthorized();
        uint newTotalInterestRate = LoanLibrary.getTotalInterestRate(
            fixedInterestRate,
            _newFloatingRateInRay
        );
        LoanLibrary.updateRateAndOutstandingAmountHistory(
            rateAndOutstandingAmountHistory,
            newTotalInterestRate,
            getCurrentOutstandingPrincipal()
        );
    }

    // chainlink should call this 24hrs after each interest payment date
    // and principal repayment date; any of the lenders or borrower can
    // call this function too
    // borrower determines what is paid by control over the allowance
    // does this function need to check first whether there is sufficient
    // balanceBackedAllowance?

    function payInCorrectOrder() public {
        payDefaultInterest();
        if (getDueAndUnpaidDefaultInterest() == 0) {
            payInterest();
            if (getDueAndUnpaidInterest() == 0) repayPrincipal();
        }
    }

    // this is now an internal function, called through payInCorrectOrder

    event RepayPrincipalCalled(
        address indexed _addressRegistry,
        uint indexed _upkeepID
    );

    function repayPrincipal() internal {
        uint dueAndUnpaidPrincipal = getDueAndUnpaidPrincipal();
        if (dueAndUnpaidPrincipal == 0) return;

        uint allowance = LoanLibrary.checkBalanceBackedAllowance(
            addressDepositToken,
            borrower,
            address(this)
        );
        if (allowance > (loanAmount / MINIMUM_REPAYMENTAMOUNT_DIVISOR)) {
            uint outstandingBalanceBeforeRepayment = getCurrentOutstandingPrincipal();
            LoanLibrary.updateDefaultInterestTracker(
                defaultInterestRateInRay,
                outstandingBalanceBeforeRepayment,
                defaultInterestTracker
            );
            uint usedAmount = (allowance < dueAndUnpaidPrincipal)
                ? allowance
                : dueAndUnpaidPrincipal;
            LoanLibrary.distributePaymentToLenders(
                ILoanPercentage(addressLoanPercentage),
                lenders,
                borrower,
                addressDepositToken,
                usedAmount
            );
            uint newOutstandingAmount = outstandingBalanceBeforeRepayment -
                usedAmount;
            LoanLibrary.updateRateAndOutstandingAmountHistory(
                rateAndOutstandingAmountHistory,
                getCurrentInterestRate(),
                newOutstandingAmount
            );
            checkAndUpdateDefault();
            if (newOutstandingAmount == 0) {
                loanStatus = LoanLibrary.LoanStatus.Repaid;
            }
        }
    }

    function payInterest() internal {
        totalInterestPaid += LoanLibrary.payInterest(
            getDueAndUnpaidInterest(),
            addressDepositToken,
            borrower,
            address(this),
            ILoanPercentage(addressLoanPercentage),
            lenders
        );
        checkAndUpdateDefault();
    }

    function payDefaultInterest() public {
        defaultInterestTracker.paidDefaultInterest += LoanLibrary
            .payDefaultInterest(
                getDueAndUnpaidDefaultInterest(),
                addressDepositToken,
                borrower,
                address(this),
                ILoanPercentage(addressLoanPercentage),
                lenders
            );
    }

    function getDueAndUnpaidPrincipal() public view returns (uint) {
        return
            LoanLibrary.getDueAndUnpaidPrincipal(
                loanStatus,
                repaymentSchedule,
                loanAmount,
                getCurrentOutstandingPrincipal()
            );
    }

    function getDueAndUnpaidInterest() public view returns (uint) {
        return
            LoanLibrary.getDueAndUnpaidInterest(
                loanStatus,
                interestPaymentTimes,
                rateAndOutstandingAmountHistory,
                creationTime,
                totalInterestPaid
            );
    }

    function getDueAndUnpaidDefaultInterest() public view returns (uint) {
        return
            LoanLibrary.getDueAndUnpaidDefaultInterest(
                defaultInterestTracker,
                defaultInterestRateInRay,
                getCurrentOutstandingPrincipal()
            );
    }

    // checkAndUpdateDefault to be called by Chainlink 24 hours after expiry payment date

    function checkAndUpdateDefault() public {
        loanStatus = LoanLibrary.checkAndUpdateDefault(
            loanStatus,
            getDueAndUnpaidInterest(),
            getDueAndUnpaidPrincipal(),
            getDueAndUnpaidDefaultInterest(),
            defaultInterestTracker
        );
    }

    function terminateLoan() external {
        if (msg.sender != addressTimelock) revert Unauthorized();
        if (loanStatus != LoanLibrary.LoanStatus.Defaulted)
            revert Unauthorized();
        delete repaymentSchedule;
        LoanLibrary.TimeAndAmount memory repayFullAmount = LoanLibrary
            .TimeAndAmount(block.timestamp, loanAmount);
        repaymentSchedule.push(repayFullAmount);
        loanStatus = LoanLibrary.LoanStatus.Terminated;
    }

    // ------------- LOAN ASSIGNMENT --------------

    function assignLoan(
        address _seller,
        address _buyer,
        uint _assignedLoanAmount
    ) external {
        ILoanPercentage loanPercentage = ILoanPercentage(addressLoanPercentage);
        if (msg.sender != addressLoanSale) revert Unauthorized();
        if (_assignedLoanAmount == 0) revert InvalidInputError();
        uint initialPercentageBuyer = loanPercentage.balanceOf(_buyer);
        uint initialPercentageSeller = loanPercentage.balanceOf(_seller);
        uint percentageAssignedInRay = (_assignedLoanAmount * RAY) /
            getCurrentOutstandingPrincipal();
        if (initialPercentageSeller < percentageAssignedInRay)
            revert InsufficientLoan();
        loanPercentage.transferByLoanContract(
            _seller,
            _buyer,
            percentageAssignedInRay
        );
        uint newPercentageSeller = loanPercentage.balanceOf(_seller);
        if (newPercentageSeller == 0) {
            LoanLibrary.removeItemFromAddressArray(lenders, _seller);
            ILoanMultiSig(addressLoanMultiSig).removeOwner(_seller);
        }

        if (initialPercentageBuyer == 0) {
            require(
                !LoanLibrary.isLender(lenders, _buyer),
                "Invalid lenders array"
            );
            lenders.push(_buyer);
            ILoanMultiSig(addressLoanMultiSig).addOwner(_buyer);
            ILoanMultiSig(addressLoanMultiSig).changeRequirement(
                lenders.length + 1
            );
        }
    }

    // ------------- GETTERS ----------------------

    function getAccruedInterestBetween(
        uint _startDate,
        uint _endDate
    ) public view returns (uint) {
        return
            LoanLibrary.getAccruedInterestBetween(
                rateAndOutstandingAmountHistory,
                _startDate,
                _endDate
            );
    }

    function getRepaymentSchedule()
        external
        view
        returns (LoanLibrary.TimeAndAmount[] memory)
    {
        return repaymentSchedule;
    }

    function getInterestPaymentTimes() external view returns (uint[] memory) {
        return interestPaymentTimes;
    }

    function getCurrentOutstandingPrincipal() public view returns (uint) {
        return
            rateAndOutstandingAmountHistory.length == 0
                ? 0
                : rateAndOutstandingAmountHistory[
                    rateAndOutstandingAmountHistory.length - 1
                ].outstandingAmount;
    }

    function getCurrentInterestRate() public view returns (uint) {
        return
            rateAndOutstandingAmountHistory.length == 0
                ? 0
                : rateAndOutstandingAmountHistory[
                    rateAndOutstandingAmountHistory.length - 1
                ].interestRate;
    }

    function getCurrentFloatingRate() public view returns (uint) {
        return getCurrentInterestRate() - fixedInterestRate;
    }

    function getRateAndOutstandingAmountHistory()
        public
        view
        returns (LoanLibrary.TimeRateAmount[] memory)
    {
        return rateAndOutstandingAmountHistory;
    }

    function getLenders() public view returns (address[] memory) {
        return lenders;
    }

    function getDefaultInterestTracker()
        public
        view
        returns (LoanLibrary.DefaultInterestTracker memory)
    {
        return defaultInterestTracker;
    }

    // --------------------- AMENDMENT FUNCTIONS ----------------------

    function amendFixedInterestRate(uint _newFixedRateInRay) external {
        onlyLoanMultiSig();
        uint currentFloatingRate = getCurrentFloatingRate();
        fixedInterestRate = _newFixedRateInRay;
        uint newTotalInterestRate = LoanLibrary.getTotalInterestRate(
            fixedInterestRate,
            currentFloatingRate
        );
        LoanLibrary.updateRateAndOutstandingAmountHistory(
            rateAndOutstandingAmountHistory,
            newTotalInterestRate,
            getCurrentOutstandingPrincipal()
        );
    }

    function amendRepaymentSchedule(
        LoanLibrary.TimeAndAmount[] memory _newRepaymentSchedule
    ) external {
        onlyLoanMultiSig();
        delete repaymentSchedule;
        LoanLibrary.changeRepaymentSchedule(
            repaymentSchedule,
            _newRepaymentSchedule,
            loanAmount
        );
        if (getDueAndUnpaidPrincipal() != 0) revert InvalidInputError();
        checkAndUpdateDefault();
    }

    function amendInterestPaymentTimes(
        uint[] calldata _newInterestPaymentTimes
    ) external {
        onlyLoanMultiSig();
        delete interestPaymentTimes;
        interestPaymentTimes = _newInterestPaymentTimes;
        if (
            !LoanLibrary.checkInterestPaymentTimesValid(
                interestPaymentTimes,
                repaymentSchedule[repaymentSchedule.length - 1].time
            )
        ) revert InvalidInputError();

        if (getDueAndUnpaidInterest() != 0) revert InvalidInputError();
        checkAndUpdateDefault();
    }

    function addDefaultInterestToPrincipal(uint _amountToAdd) external {
        onlyLoanMultiSig();
        LoanLibrary.capitalizeDefaultInterest(
            _amountToAdd,
            defaultInterestTracker,
            rateAndOutstandingAmountHistory,
            getDueAndUnpaidDefaultInterest(),
            getCurrentOutstandingPrincipal(),
            defaultInterestRateInRay,
            getCurrentInterestRate()
        );
        loanAmount += _amountToAdd;
        checkAndUpdateDefault();
    }

    function addInterestToPrincipal(uint _amountToAdd) external {
        onlyLoanMultiSig();
        LoanLibrary.capitalizeInterest(
            _amountToAdd,
            rateAndOutstandingAmountHistory,
            getDueAndUnpaidInterest(),
            getCurrentOutstandingPrincipal(),
            getCurrentInterestRate()
        );
        loanAmount += _amountToAdd;
        totalInterestPaid += _amountToAdd;
        checkAndUpdateDefault();
    }

    function waiveDefaultInterest(uint _amountToWaive) external {
        onlyLoanMultiSig();
        uint dueAndUnpaidDefaultInterest = getDueAndUnpaidDefaultInterest();
        if (dueAndUnpaidDefaultInterest == 0) return;
        if (_amountToWaive > dueAndUnpaidDefaultInterest)
            _amountToWaive = dueAndUnpaidDefaultInterest;
        defaultInterestTracker.paidDefaultInterest += _amountToWaive;
        checkAndUpdateDefault();
    }

    function waiveInterest(uint _amountToWaive) external {
        onlyLoanMultiSig();
        uint dueAndUnpaidInterest = getDueAndUnpaidInterest();
        if (dueAndUnpaidInterest == 0) return;
        if (_amountToWaive > dueAndUnpaidInterest) revert InvalidInputError();
        totalInterestPaid += _amountToWaive;
        checkAndUpdateDefault();
    }

    // need to check whether repayment schedule still works. might lead to negative outstanding amount
    // think it is also necessary to change repayment schedule; todo
    function waivePrincipal(uint _amountToWaive) external {
        onlyLoanMultiSig();
        uint outstandingPrincipal = getCurrentOutstandingPrincipal();
        if (outstandingPrincipal == 0) return;
        if (_amountToWaive > outstandingPrincipal) revert InvalidInputError();
        uint newOutstandingPrincipal = outstandingPrincipal - _amountToWaive;
        LoanLibrary.updateRateAndOutstandingAmountHistory(
            rateAndOutstandingAmountHistory,
            getCurrentInterestRate(),
            newOutstandingPrincipal
        );
        // loanAmount -= _amountToWaive; query whether this is correct. perhaps delete?
        checkAndUpdateDefault();
        if (newOutstandingPrincipal == 0)
            loanStatus = LoanLibrary.LoanStatus.Repaid;
    }
}

// TODO:
// 1. events
// 2. check whether loanStatus is tracked properly and adjusted where needed
// 3. binary searches instead of brute force searches through arrays
// 4. perhaps change checkAndUpdateDefault function to only update default
// given that check already happens in upkeep and perfromUpkeep functions
// 5. use ERC-677 standard for loanPercentage tokens? https://github.com/ethereum/EIPs/issues/677
// 6. do we need automation on top of API calls
// functions instead of Any API?
// in functions that amend principal (add and waive) the repayment schedule also needs to be adjusted. still todo
// add change deposit token function
// in amend functions, if amount to add/waive reater than relevant outstanding amount then equate amount to add/waive to relevant outstanding amount
// how to register new loanContracts with Chainlink programmatically? Yes - this can be done dynamically, see here:
// https://docs.chain.link/chainlink-automation/register-upkeep (with code example)
// change ChainlinkFunctions to LoanUpkeep
// change chainlinkUpkeepRegistrar to loanUpkeepRegistrar
// withdraw link after cancelling upkeep with call to withdraw function on registry
// make chainlinkUpkeepRegistrar (after renaming) chainlink admin so that funds are returned to this address
// cancelUpkeep should then run via this contract. perhaps call loanUpkeepManager?

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

// import "hardhat/console.sol";

import "../lib/DSMath.sol";
import "../lib/EnumerableMapExtended.sol";
import "../interfaces/IDepositToken.sol";
import "../interfaces/ILoanPercentage.sol";

library LoanLibrary {
    using EnumerableMapExtended for EnumerableMapExtended.AddressToUintMap;
    using DSMath for uint;

    //  ----------------- CUSTOM ERRORS -------------------------

    error DistributionFailed();
    error InvalidInput();
    error OnlyLoanMultiSig();
    error AlreadyConfirmed();
    error LoanNotConfirmed();

    // ----------------- CONSTANTS ------------------------------

    uint constant ONE_YEAR_IN_SEC = 60 * 60 * 24 * 365;
    uint constant RAY = 10 ** 27;
    uint constant BILLION = 10 ** 9;

    // ---------------- CUSTOM TYPES ---------------------------
    enum LoanStatus {
        Proposed,
        Performing,
        Defaulted,
        Terminated,
        Repaid
    }

    struct TimeAndAmount {
        uint time;
        uint amount;
    }

    struct AddressAndAmount {
        address inputAddress;
        uint amount;
    }

    struct TimeRateAmount {
        uint time;
        uint interestRate;
        uint outstandingAmount;
    }

    // paidDefaultInterest does not track total paid default interest
    // but is reset to zero each time outstandining default interst is fully repaid
    // do we also want tot track total default interest paid for APY purposes?
    struct DefaultInterestTracker {
        uint accruedDefaultInterest;
        uint paidDefaultInterest;
        uint defaultInterestUpdateTime;
    }

    // --------------- EXTERNAL OR PUBLIC LIBRARY FUNCTIONS ---------------

    function checkRepaymentscheduleValid(
        TimeAndAmount[] memory _repaymentSchedule,
        uint _initialLoanAmount
    ) public pure returns (bool) {
        uint totalRepayments;
        for (uint i = 0; i < _repaymentSchedule.length; i++) {
            totalRepayments += _repaymentSchedule[i].amount;
            if (_repaymentSchedule[i].amount == 0) return false;
            if (i == _repaymentSchedule.length - 1) continue;
            if (_repaymentSchedule[i].time >= _repaymentSchedule[i + 1].time)
                return false;
        }
        if (
            _repaymentSchedule.length == 0 ||
            totalRepayments != _initialLoanAmount
        ) return false;
        return true;
    }

    function checkInterestPaymentTimesValid(
        uint[] calldata _interestPaymentTimes,
        uint timeLastRepayment
    ) public pure returns (bool) {
        if (
            _interestPaymentTimes.length == 0 ||
            _interestPaymentTimes[_interestPaymentTimes.length - 1] !=
            timeLastRepayment
        ) return false;
        for (uint i = 0; i < _interestPaymentTimes.length; i++) {
            if (_interestPaymentTimes[i] == 0) return false;
            if (i == _interestPaymentTimes.length - 1) continue;
            if (_interestPaymentTimes[i] >= _interestPaymentTimes[i + 1])
                return false;
        }
        return true;
    }

    function checkIsOriginalLenderInputValid(
        AddressAndAmount[] memory _originalLenders,
        uint _initialLoanAmount
    ) external pure returns (bool) {
        uint sum;
        for (uint i = 0; i < _originalLenders.length; i++) {
            if (
                _originalLenders[i].amount == 0 ||
                _originalLenders[i].inputAddress == address(0)
            ) return false;
            sum += _originalLenders[i].amount;
        }
        if (sum != _initialLoanAmount) return false;
        return true;
    }

    function isLender(
        address[] storage _lenders,
        address _entityAddress
    ) external view returns (bool) {
        for (uint i = 0; i < _lenders.length; i++) {
            if (_lenders[i] == _entityAddress) return true;
        }
        return false;
    }

    function checkConfirmationRequirements(
        address _functionCaller,
        address _addressMultiSig,
        LoanStatus _loanStatus,
        uint _timeFirstRepayment,
        uint _timeFirstInterestPayment
    ) external view {
        if (_functionCaller != _addressMultiSig) revert OnlyLoanMultiSig();
        if (_loanStatus != LoanStatus.Proposed) revert AlreadyConfirmed();
        if (
            _timeFirstRepayment <= block.timestamp ||
            _timeFirstInterestPayment <= block.timestamp
        ) revert InvalidInput();
    }

    function makeFundsAvailableToBorrower(
        ILoanPercentage _loanPercentage,
        address[] storage _lenders,
        uint _initialLoanAmount,
        uint _arrangementFeePercentageInRay,
        address _borrower,
        address _addressDepositToken
    ) external {
        uint cashLoanAmount = ((RAY - _arrangementFeePercentageInRay) *
            _initialLoanAmount) / RAY;

        for (uint i = 0; i < _lenders.length; i++) {
            uint loanFraction = _loanPercentage.balanceOf(_lenders[i]);
            uint cashPortion = (loanFraction * cashLoanAmount) / RAY;
            IDepositToken(_addressDepositToken).transferFrom(
                _lenders[i],
                _borrower,
                cashPortion
            );
        }
    }

    function payInterest(
        uint _dueInterest,
        address _addressDepositToken,
        address _borrower,
        address _loanContract,
        ILoanPercentage _loanPercentage,
        address[] storage _lenders
    ) external returns (uint) {
        if (_dueInterest == 0) return 0;
        uint allowance = checkBalanceBackedAllowance(
            _addressDepositToken,
            _borrower,
            _loanContract
        );

        if (allowance > 0) {
            uint usedAmount = (allowance < _dueInterest)
                ? allowance
                : _dueInterest;
            distributePaymentToLenders(
                _loanPercentage,
                _lenders,
                _borrower,
                _addressDepositToken,
                usedAmount
            );
            return usedAmount;
        }
        return 0;
    }

    function payDefaultInterest(
        uint _dueDefaultInterest,
        address _addressDepositToken,
        address _borrower,
        address _loanContract,
        ILoanPercentage _loanPercentage,
        address[] storage _lenders
    ) public returns (uint) {
        if (_dueDefaultInterest == 0) return 0;
        uint allowance = checkBalanceBackedAllowance(
            _addressDepositToken,
            _borrower,
            _loanContract
        );
        if (allowance > 0) {
            uint usedAmount = (allowance < _dueDefaultInterest)
                ? allowance
                : _dueDefaultInterest;
            distributePaymentToLenders(
                _loanPercentage,
                _lenders,
                _borrower,
                _addressDepositToken,
                usedAmount
            );
            return usedAmount;
        }
        return 0;
    }

    function getDueAndUnpaidPrincipal(
        LoanStatus _loanStatus,
        TimeAndAmount[] storage _repaymentSchedule,
        uint _initialLoanAmount,
        uint _outstandingPrincipal
    ) external view returns (uint) {
        if (_loanStatus == LoanStatus.Proposed) return 0;
        uint totalPrincipalPaid = _initialLoanAmount - _outstandingPrincipal;
        uint duePrincipal = getTotalPrincipalFallenDue(_repaymentSchedule);
        uint dueAndUnpaidPrincipal = duePrincipal - totalPrincipalPaid;
        return dueAndUnpaidPrincipal;
    }

    function getTotalPrincipalFallenDue(
        TimeAndAmount[] storage _repaymentSchedule
    ) public view returns (uint) {
        if (block.timestamp <= _repaymentSchedule[0].time) return 0;
        uint totalDue;
        for (uint i = 0; i < _repaymentSchedule.length; i++) {
            if (_repaymentSchedule[i].time <= block.timestamp)
                totalDue += _repaymentSchedule[i].amount;
        }
        return totalDue;
    }

    function getDueAndUnpaidInterest(
        LoanStatus _loanStatus,
        uint[] storage _interestPaymentTimes,
        TimeRateAmount[] storage _rateAndOutstandingAmountHistory,
        uint _creationTime,
        uint _totalInterestPaid
    ) public view returns (uint) {
        if (
            _loanStatus == LoanStatus.Proposed ||
            block.timestamp <= _interestPaymentTimes[0]
        ) return 0;
        uint lastLapsedInterestPaymentTime = getTimeLastScheduledInterestPaymentBefore(
                _interestPaymentTimes,
                block.timestamp
            );

        uint lastScheduledInterestPayment = _interestPaymentTimes[
            _interestPaymentTimes.length - 1
        ];
        uint duePaymentTime = block.timestamp >= lastScheduledInterestPayment
            ? block.timestamp
            : lastLapsedInterestPaymentTime;

        uint totalInterestFallenDue = lastLapsedInterestPaymentTime == 0
            ? 0
            : getAccruedInterestBetween(
                _rateAndOutstandingAmountHistory,
                _creationTime,
                duePaymentTime
            );
        // totalInterestFallenDue can be less than totalInterestPaid when interestPaymentTimes are changed
        return
            totalInterestFallenDue < _totalInterestPaid
                ? 0
                : totalInterestFallenDue - _totalInterestPaid;
    }

    function getDueAndUnpaidDefaultInterest(
        DefaultInterestTracker storage _defaultInterestTracker,
        uint _defaultInterestRateInRay,
        uint _currentOutstandingPrincipal
    ) public view returns (uint) {
        uint totalAccruedDefaultInterest = _defaultInterestTracker
            .accruedDefaultInterest +
            calculateAccruedInterest(
                _defaultInterestRateInRay,
                _currentOutstandingPrincipal,
                _defaultInterestTracker.defaultInterestUpdateTime,
                block.timestamp
            );
        return
            totalAccruedDefaultInterest -
            _defaultInterestTracker.paidDefaultInterest;
    }

    function getTotalInterestRate(
        uint fixedRateInRay,
        uint floatingRateInRay
    ) external pure returns (uint) {
        return fixedRateInRay.add(floatingRateInRay);
    }

    function getAccruedInterestBetween(
        TimeRateAmount[] storage _rateAndOutstandingAmountHistory,
        uint _interestStartDate,
        uint _interestEndDate
    ) public view returns (uint) {
        if (_rateAndOutstandingAmountHistory.length == 0) return 0;
        if (_interestEndDate <= _rateAndOutstandingAmountHistory[0].time)
            return 0;
        if (_interestStartDate < _rateAndOutstandingAmountHistory[0].time)
            _interestStartDate = _rateAndOutstandingAmountHistory[0].time;
        if (_interestStartDate > _interestEndDate) revert InvalidInput();
        uint intervalStart = _interestStartDate;
        uint intervalEnd;
        uint intervalInterest;
        uint interestSum;
        uint indexBeforeStart = getIndexHistoryItemBefore(
            _rateAndOutstandingAmountHistory,
            _interestStartDate
        );
        uint indexBeforeEnd = getIndexHistoryItemBefore(
            _rateAndOutstandingAmountHistory,
            _interestEndDate
        );
        uint intervalRate = _rateAndOutstandingAmountHistory[indexBeforeStart]
            .interestRate;
        uint intervalPrincipal = _rateAndOutstandingAmountHistory[
            indexBeforeStart
        ].outstandingAmount;

        for (uint i = indexBeforeStart + 1; i <= indexBeforeEnd + 1; i++) {
            if (i == indexBeforeEnd + 1) {
                intervalEnd = _interestEndDate;
                intervalInterest = calculateAccruedInterest(
                    intervalRate,
                    intervalPrincipal,
                    intervalStart,
                    intervalEnd
                );
                interestSum += intervalInterest;
                break;
            }
            intervalEnd = _rateAndOutstandingAmountHistory[i].time;
            intervalInterest = calculateAccruedInterest(
                intervalRate,
                intervalPrincipal,
                intervalStart,
                intervalEnd
            );
            intervalRate = _rateAndOutstandingAmountHistory[i].interestRate;
            intervalPrincipal = _rateAndOutstandingAmountHistory[i]
                .outstandingAmount;
            intervalStart = intervalEnd;
            interestSum += intervalInterest;
        }
        return interestSum;
    }

    function calculateAccruedInterest(
        uint _interestRateInRay,
        uint _outstandingPrincipal,
        uint _interestStartTime,
        uint _interestEndTime
    ) public pure returns (uint) {
        if (_interestStartTime == 0) return 0;
        uint outstandingPrincipalInRay = _outstandingPrincipal * BILLION;
        uint accruedAnnualInterestInRay = outstandingPrincipalInRay.rmul(
            _interestRateInRay
        );
        uint timeLapsed = (_interestEndTime - _interestStartTime);
        uint accruedInterestInRay = (timeLapsed * accruedAnnualInterestInRay) /
            ONE_YEAR_IN_SEC;

        uint accruedInterestInWei = accruedInterestInRay / BILLION;

        return accruedInterestInWei;
    }

    function checkAndUpdateDefault(
        LoanStatus _loanStatus,
        uint _dueAndUnpaidInterest,
        uint _dueAndUnpaidPrincipal,
        uint _dueAndUnpaidDefaultInterest,
        DefaultInterestTracker storage _defaultInterestTracker
    ) public returns (LoanStatus) {
        LoanStatus status = _loanStatus;
        if (_defaultInterestTracker.defaultInterestUpdateTime == 0) {
            if ((_dueAndUnpaidInterest > 0) || (_dueAndUnpaidPrincipal > 0)) {
                _defaultInterestTracker.defaultInterestUpdateTime = block
                    .timestamp;
                status = LoanStatus.Defaulted;
            }
        } else if (
            _dueAndUnpaidInterest == 0 &&
            _dueAndUnpaidPrincipal == 0 &&
            _dueAndUnpaidDefaultInterest == 0
        ) {
            _defaultInterestTracker.defaultInterestUpdateTime = 0;
            _defaultInterestTracker.accruedDefaultInterest = 0;
            _defaultInterestTracker.paidDefaultInterest = 0; // do we also want to keep track of total paid default interest, e.g. for APY purposes?
            status = LoanStatus.Performing;
        }
        return status;
    }

    function getIndexHistoryItemBefore(
        TimeRateAmount[] storage _historyArray,
        uint specifiedTime
    ) public view returns (uint) {
        if (specifiedTime < _historyArray[0].time) revert InvalidInput();
        if (_historyArray.length == 1) return 0;
        for (uint i = 1; i < _historyArray.length; i++) {
            if (specifiedTime <= _historyArray[i].time) return i - 1;
        }
        return _historyArray.length - 1;
    }

    function getIndexScheduledRepaymentBefore(
        TimeAndAmount[] memory _repaymentSchedule,
        uint specifiedTime
    ) public pure returns (uint) {
        if (specifiedTime < _repaymentSchedule[0].time) revert InvalidInput();
        if (_repaymentSchedule.length == 1) return 0;
        for (uint i = 1; i < _repaymentSchedule.length; i++) {
            if (specifiedTime <= _repaymentSchedule[i].time) return i - 1;
        }
        return _repaymentSchedule.length - 1;
    }

    function getTimeLastScheduledInterestPaymentBefore(
        uint[] memory _interestPaymentTimes,
        uint _specifiedTime
    ) public pure returns (uint) {
        if (_specifiedTime < _interestPaymentTimes[0]) revert InvalidInput();
        uint latestInterestPaymentTime = _interestPaymentTimes[0];
        for (uint i = 0; i < _interestPaymentTimes.length; i++) {
            if (_interestPaymentTimes[i] > _specifiedTime) break;
            if (_interestPaymentTimes[i] > latestInterestPaymentTime) {
                latestInterestPaymentTime = _interestPaymentTimes[i];
            }
        }
        return latestInterestPaymentTime;
    }

    function updateDefaultInterestTracker(
        uint _defaultInterestRateInRay,
        uint _outstandingPrincipal,
        DefaultInterestTracker storage _defaultInterestTracker
    ) public {
        if (_defaultInterestTracker.defaultInterestUpdateTime == 0) return;
        uint defaultInterestSinceLastUpdate = calculateAccruedInterest(
            _defaultInterestRateInRay,
            _outstandingPrincipal,
            _defaultInterestTracker.defaultInterestUpdateTime,
            block.timestamp
        );
        _defaultInterestTracker
            .accruedDefaultInterest += defaultInterestSinceLastUpdate;
        _defaultInterestTracker.defaultInterestUpdateTime = block.timestamp;
    }

    function checkBalanceBackedAllowance(
        address _addressToken,
        address _owner,
        address _spender
    ) public view returns (uint) {
        uint balanceOwner = IDepositToken(_addressToken).balanceOf(_owner);
        uint allowance = IDepositToken(_addressToken).allowance(
            _owner,
            _spender
        );
        uint spendableAmount = allowance <= balanceOwner
            ? allowance
            : balanceOwner;
        return spendableAmount;
    }

    // function distributePaymentToLenders(
    //     EnumerableMapExtended.AddressToUintMap storage _lenderToFractionInRay,
    //     address _borrower,
    //     address _addressDepositToken,
    //     uint _receivedPayment
    // ) public returns (bool) {
    //     uint shareOfPayment;
    //     uint fraction;
    //     address lender;
    //     for (uint i = 0; i < _lenderToFractionInRay.length(); i++) {
    //         (lender, fraction) = _lenderToFractionInRay.at(i);
    //         shareOfPayment =
    //             fraction.rmul(_receivedPayment * BILLION) /
    //             BILLION;
    //         (bool success, ) = _addressDepositToken.call(
    //             abi.encodeWithSignature(
    //                 "transferFrom(address,address,uint256)",
    //                 _borrower,
    //                 lender,
    //                 shareOfPayment
    //             )
    //         );
    //         if (!success) revert DistributionFailed();
    //     }
    //     return true;
    // }

    function distributePaymentToLenders(
        ILoanPercentage _loanPercentage,
        address[] storage _lenders,
        address _borrower,
        address _addressDepositToken,
        uint _receivedPayment
    ) public returns (bool) {
        uint shareOfPayment;
        uint fraction;
        for (uint i = 0; i < _lenders.length; i++) {
            fraction = _loanPercentage.balanceOf(_lenders[i]);
            shareOfPayment =
                fraction.rmul(_receivedPayment * BILLION) /
                BILLION;
            (bool success, ) = _addressDepositToken.call(
                abi.encodeWithSignature(
                    "transferFrom(address,address,uint256)",
                    _borrower,
                    _lenders[i],
                    shareOfPayment
                )
            );
            if (!success) revert DistributionFailed();
        }
        return true;
    }

    function updateRateAndOutstandingAmountHistory(
        TimeRateAmount[] storage _rateAndOutstandingAmountHistory,
        uint _updatedInterestRateInRay,
        uint _updatedOutstandingPrincipal
    ) public {
        TimeRateAmount memory updatedValues = TimeRateAmount(
            block.timestamp,
            _updatedInterestRateInRay,
            _updatedOutstandingPrincipal
        );
        _rateAndOutstandingAmountHistory.push(updatedValues);
    }

    // ------------------------- AMENDMENT FUNCTIONS ---------------------------

    function changeRepaymentSchedule(
        TimeAndAmount[] storage _repaymentSchedule,
        TimeAndAmount[] memory _newRepaymentSchedule,
        uint _initialLoanAmount
    ) external {
        for (uint i = 0; i < _newRepaymentSchedule.length; i++) {
            _repaymentSchedule.push(_newRepaymentSchedule[i]);
        }
        if (
            !checkRepaymentscheduleValid(_repaymentSchedule, _initialLoanAmount)
        ) revert InvalidInput();
    }

    function capitalizeDefaultInterest(
        uint _amountToAdd,
        DefaultInterestTracker storage _defaultInterestTracker,
        TimeRateAmount[] storage _rateAndOutstandingAmountHistory,
        uint _dueAndUnpaidDefaultInterest,
        uint _outstandingPrincipalBefore,
        uint _defaultInterestRateInRay,
        uint _currentInterestRate
    ) external {
        if (_dueAndUnpaidDefaultInterest == 0) return;
        if (_amountToAdd > _dueAndUnpaidDefaultInterest) revert InvalidInput();
        updateDefaultInterestTracker(
            _defaultInterestRateInRay,
            _outstandingPrincipalBefore,
            _defaultInterestTracker
        );
        uint newOutstandingAmount = _outstandingPrincipalBefore + _amountToAdd;
        updateRateAndOutstandingAmountHistory(
            _rateAndOutstandingAmountHistory,
            _currentInterestRate,
            newOutstandingAmount
        );
        _defaultInterestTracker.paidDefaultInterest += _amountToAdd;
    }

    function capitalizeInterest(
        uint _amountToAdd,
        TimeRateAmount[] storage _rateAndOutstandingAmountHistory,
        uint _dueAndUnpaidInterest,
        uint _outstandingPrincipalBefore,
        uint _currentInterestRate
    ) external {
        if (_dueAndUnpaidInterest == 0) return;
        if (_amountToAdd > _dueAndUnpaidInterest) revert InvalidInput();
        uint newOutstandingAmount = _outstandingPrincipalBefore + _amountToAdd;
        updateRateAndOutstandingAmountHistory(
            _rateAndOutstandingAmountHistory,
            _currentInterestRate,
            newOutstandingAmount
        );
    }

    function predictAddress(
        address _addressDeployer,
        uint _nonceDeployer
    ) public pure returns (address) {
        bytes memory data;
        if (_nonceDeployer == 0x00)
            data = abi.encodePacked(
                bytes1(0xd6),
                bytes1(0x94),
                _addressDeployer,
                bytes1(0x80)
            );
        else if (_nonceDeployer <= 0x7f)
            data = abi.encodePacked(
                bytes1(0xd6),
                bytes1(0x94),
                _addressDeployer,
                uint8(_nonceDeployer)
            );
        else if (_nonceDeployer <= 0xff)
            data = abi.encodePacked(
                bytes1(0xd7),
                bytes1(0x94),
                _addressDeployer,
                bytes1(0x81),
                uint8(_nonceDeployer)
            );
        else if (_nonceDeployer <= 0xffff)
            data = abi.encodePacked(
                bytes1(0xd8),
                bytes1(0x94),
                _addressDeployer,
                bytes1(0x82),
                uint16(_nonceDeployer)
            );
        else if (_nonceDeployer <= 0xffffff)
            data = abi.encodePacked(
                bytes1(0xd9),
                bytes1(0x94),
                _addressDeployer,
                bytes1(0x83),
                uint24(_nonceDeployer)
            );
        else
            data = abi.encodePacked(
                bytes1(0xda),
                bytes1(0x94),
                _addressDeployer,
                bytes1(0x84),
                uint32(_nonceDeployer)
            );
        return address(uint160(uint256(keccak256(data))));
    }

    function removeItemFromAddressArray(
        address[] storage _addressArray,
        address _addressToRemove
    ) external {
        for (uint i = 0; i < _addressArray.length; i++) {
            if (_addressArray[i] == _addressToRemove) {
                _addressArray[i] = _addressArray[_addressArray.length - 1];
                _addressArray.pop();
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

// UpkeepIDConsumerExample.sol imports functions from both ./AutomationRegistryInterface2_0.sol and
// ./interfaces/LinkTokenInterface.sol

import "./LoanContract.sol";
import {IChainlinkRegistrar, RegistrationParams} from "../interfaces/IChainlinkRegistrar.sol";
import "../interfaces/IChainlinkRegistry.sol";

import {AutomationRegistryBaseInterface} from "@chainlink/contracts/src/v0.8/interfaces/AutomationRegistryInterface2_0.sol";

import {LinkTokenInterface} from "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";

contract LoanUpkeepAdmin {
    // ---- CUSTOM ERRORS --------

    error Unauthorized();
    error LoanNotRepaid();
    error BalanceLessThanWithdrawal();
    error WithdrawalNotAllowed();

    // ---- CONSTANTS -----

    uint public constant MINIMUM_LINK_BALANCE = 10 * 10 ** 18; // 10 LINK
    address constant ADDRESS_UPKEEP_REGISTRY_MUMBAI =
        0xE16Df59B887e3Caa439E0b29B42bA2e7976FD8b2;
    address constant ADDRESS_UPKEEP_REGISTRY_SEPOLIA =
        0xE16Df59B887e3Caa439E0b29B42bA2e7976FD8b2;
    address constant ADDRESS_LINK_TOKEN_MUMBAI =
        0x326C977E6efc84E512bB9C30f76E30c160eD06FB;
    address constant ADDRESS_UPKEEP_REGISTRAR_MUMBAI =
        0x57A4a13b35d25EE78e084168aBaC5ad360252467;
    address constant ADDRESS_LINK_TOKEN_SEPOLIA =
        0x779877A7B0D9E8603169DdbD7836e478b4624789;
    address constant ADDRESS_UPKEEP_REGISTRAR_SEPOLIA =
        0x9a811502d843E5a03913d5A2cfb646c11463467A;
    uint32 public constant CHAINLINK_PERFORM_GASLIMIT_MUMBAI = 5000000; // 5 million
    uint32 public constant CHAINLINK_PERFORM_GASLIMIT_SEPOLIA = 5000000; // 5 million
    uint96 public constant LINK_INITIAL_FUNDING_AMOUNT = 5000000000000000000; // 5 LINK

    // ------- VARIABLES --------------

    LinkTokenInterface public immutable linkToken;
    IChainlinkRegistrar public immutable chainlinkRegistrar;
    IChainlinkRegistry public immutable chainlinkRegistry;
    RegistrationParams public params;
    address addressLoanContract;
    address public admin;
    uint public activeUpkeeps;

    constructor() {
        admin = msg.sender;
        params = RegistrationParams({
            name: "loan-app",
            encryptedEmail: "0x",
            upkeepContract: address(0),
            gasLimit: getChainlinkPerformGasLimit(),
            adminAddress: msg.sender,
            checkData: "0x",
            offchainConfig: "0x",
            amount: LINK_INITIAL_FUNDING_AMOUNT
        });
        (
            address addressLinkToken,
            address addressRegistrar,
            address addressRegistry
        ) = getChainlinkAddresses();
        linkToken = LinkTokenInterface(addressLinkToken);
        chainlinkRegistrar = IChainlinkRegistrar(addressRegistrar);
        chainlinkRegistry = IChainlinkRegistry(addressRegistry);
    }

    function registerAndPredictID(
        address _addressUpKeepContract
    ) public returns (uint256) {
        // LINK must be approved for transfer - this can be done every time or once
        // with an infinite approval
        params.name = string.concat(params.name, "extension-still-to-follow");
        params.upkeepContract = _addressUpKeepContract;
        params.adminAddress = admin; // i.e. deployer
        linkToken.approve(address(chainlinkRegistrar), params.amount);
        uint256 upkeepID = chainlinkRegistrar.registerUpkeep(params);
        if (upkeepID != 0) {
            // DEV - Use the upkeepID however you see fit
            activeUpkeeps++;
            return upkeepID;
        } else {
            revert("auto-approve disabled");
        }
    }

    function addFundsToChainlinkUpkeep(uint _upkeepId, uint96 _amount) public {
        if (msg.sender != address(this) && msg.sender != admin)
            revert Unauthorized();
        chainlinkRegistry.addFunds(_upkeepId, _amount);
    }

    // amend to that upkeeps are somehow cancelled automatically or, if manually, in batches
    function cancelUpKeep(uint _upkeepId) external {
        if (msg.sender != admin) revert Unauthorized();
        if (
            LoanContract(addressLoanContract).loanStatus() !=
            LoanLibrary.LoanStatus.Repaid
        ) revert LoanNotRepaid();
        chainlinkRegistry.cancelUpkeep(_upkeepId);
        activeUpkeeps--;
    }

    // can be called only after 20 or more confirmations after cancellation (see chainlink app)
    // amend to that upkeeps are somehow cancelled automatically or, if manually, in batches
    function withdrawFundsFromChainlink(uint _upkeepId) external {
        if (msg.sender != admin) revert Unauthorized();
        if (
            LoanContract(addressLoanContract).loanStatus() !=
            LoanLibrary.LoanStatus.Repaid
        ) revert LoanNotRepaid();
        chainlinkRegistry.withdrawFunds(_upkeepId, address(this));
    }

    function getChainlinkPerformGasLimit() public view returns (uint32) {
        if (block.chainid == 80001) {
            return (CHAINLINK_PERFORM_GASLIMIT_MUMBAI);
        } else if (block.chainid == 11155111) {
            return (CHAINLINK_PERFORM_GASLIMIT_SEPOLIA);
        } else {
            return (0);
        }
    }

    // withdraw funds from this contract
    function withdrawFundsFromUpkeepAdminContract(uint _amount) external {
        if (msg.sender != admin) revert Unauthorized();
        uint currentBalance = linkToken.balanceOf(address(this));
        uint balanceAfterWithdrawal = currentBalance - _amount;
        if (activeUpkeeps > 0 && balanceAfterWithdrawal < MINIMUM_LINK_BALANCE)
            revert WithdrawalNotAllowed();
        if (currentBalance < _amount) revert BalanceLessThanWithdrawal();
        linkToken.transfer(admin, _amount);
    }

    function getChainlinkAddresses()
        private
        view
        returns (address, address, address)
    {
        if (block.chainid == 80001) {
            return (
                ADDRESS_LINK_TOKEN_MUMBAI,
                ADDRESS_UPKEEP_REGISTRAR_MUMBAI,
                ADDRESS_UPKEEP_REGISTRY_MUMBAI
            );
        } else if (block.chainid == 11155111) {
            return (
                ADDRESS_LINK_TOKEN_SEPOLIA,
                ADDRESS_UPKEEP_REGISTRAR_SEPOLIA,
                ADDRESS_UPKEEP_REGISTRY_SEPOLIA
            );
        } else {
            return (address(0), address(0), address(0));
        }
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

struct RegistrationParams {
    string name;
    bytes encryptedEmail;
    address upkeepContract;
    uint32 gasLimit;
    address adminAddress;
    bytes checkData;
    bytes offchainConfig;
    uint96 amount;
}

interface IChainlinkRegistrar {
    function registerUpkeep(
        RegistrationParams calldata requestParams
    ) external returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

// this interface has been taken from the verified source code
//  available at the registry address on the blockexplorer
// https://vscode.blockscan.com/polygon/0x02777053d6764996e594c3E88AF1D58D5363a2e6

interface IChainlinkRegistry {
    function cancelUpkeep(uint256 id) external;

    function addFunds(uint256 id, uint96 amount) external;

    function withdrawFunds(uint256 id, address to) external;
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

interface IDepositToken {
    function balanceOf(address owner) external view returns (uint256);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

interface ILoanMultiSig {
    function addOwner(address owner) external;

    function removeOwner(address owner) external;

    function changeRequirement(uint _required) external;
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

interface ILoanPercentage {
    function balanceOf(address owner) external view returns (uint256);

    function transferByLoanContract(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

interface ILoanUpkeepAdmin {
    function registerAndPredictID(
        address _addressUpKeepContract
    ) external returns (uint256);

    function cancelUpKeep(uint _upkeepId) external;

    function retrieveFundsFromChainlink(uint _upkeepId) external;
}

//SPDX-License-Identifier: Unlicense

/// math.sol -- mixin for inline numerical wizardry

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity >0.4.13;

library DSMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, "ds-math-add-overflow");
    }
    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, "ds-math-sub-underflow");
    }
    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, "ds-math-mul-overflow");
    }

    function min(uint x, uint y) internal pure returns (uint z) {
        return x <= y ? x : y;
    }
    function max(uint x, uint y) internal pure returns (uint z) {
        return x >= y ? x : y;
    }
    function imin(int x, int y) internal pure returns (int z) {
        return x <= y ? x : y;
    }
    function imax(int x, int y) internal pure returns (int z) {
        return x >= y ? x : y;
    }

    uint constant WAD = 10 ** 18;
    uint constant RAY = 10 ** 27;

    //rounds to zero if x*y < WAD / 2
    function wmul(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, y), WAD / 2) / WAD;
    }
    //rounds to zero if x*y < WAD / 2
    function rmul(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, y), RAY / 2) / RAY;
    }
    //rounds to zero if x*y < WAD / 2
    function wdiv(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, WAD), y / 2) / y;
    }
    //rounds to zero if x*y < RAY / 2
    function rdiv(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, RAY), y / 2) / y;
    }

    // This famous algorithm is called "exponentiation by squaring"
    // and calculates x^n with x as fixed-point and n as regular unsigned.
    //
    // It's O(log n), instead of O(n) for naive repeated multiplication.
    //
    // These facts are why it works:
    //
    //  If n is even, then x^n = (x^2)^(n/2).
    //  If n is odd,  then x^n = x * x^(n-1),
    //   and applying the equation for even x gives
    //    x^n = x * (x^2)^((n-1) / 2).
    //
    //  Also, EVM division is flooring and
    //    floor[(n-1) / 2] = floor[n / 2].
    //
    function rpow(uint x, uint n) internal pure returns (uint z) {
        z = n % 2 != 0 ? x : RAY;

        for (n /= 2; n != 0; n /= 2) {
            x = rmul(x, x);

            if (n % 2 != 0) {
                z = rmul(z, x);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/structs/EnumerableMap.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableMap.js.

// NT: extended this file with keys functions copied from openzeppeling repo on github

pragma solidity ^0.8.0;

// import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./EnumerableSet.sol";

/**
 * @dev Library for managing an enumerable variant of Solidity's
 * https://solidity.readthedocs.io/en/latest/types.html#mapping-types[`mapping`]
 * type.
 *
 * Maps have the following properties:
 *
 * - Entries are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Entries are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableMap for EnumerableMap.UintToAddressMap;
 *
 *     // Declare a set state variable
 *     EnumerableMap.UintToAddressMap private myMap;
 * }
 * ```
 *
 * The following map types are supported:
 *
 * - `uint256 -> address` (`UintToAddressMap`) since v3.0.0
 * - `address -> uint256` (`AddressToUintMap`) since v4.6.0
 * - `bytes32 -> bytes32` (`Bytes32ToBytes32Map`) since v4.6.0
 * - `uint256 -> uint256` (`UintToUintMap`) since v4.7.0
 * - `bytes32 -> uint256` (`Bytes32ToUintMap`) since v4.7.0
 *
 * [WARNING]
 * ====
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableMap, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableMap.
 * ====
 */
library EnumerableMapExtended {
    using EnumerableSet for EnumerableSet.Bytes32Set;

    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Map type with
    // bytes32 keys and values.
    // The Map implementation uses private functions, and user-facing
    // implementations (such as Uint256ToAddressMap) are just wrappers around
    // the underlying Map.
    // This means that we can only create new EnumerableMaps for types that fit
    // in bytes32.

    struct Bytes32ToBytes32Map {
        // Storage of keys
        EnumerableSet.Bytes32Set _keys;
        mapping(bytes32 => bytes32) _values;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(
        Bytes32ToBytes32Map storage map,
        bytes32 key,
        bytes32 value
    ) internal returns (bool) {
        map._values[key] = value;
        return map._keys.add(key);
    }

    /**
     * @dev Removes a key-value pair from a map. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(
        Bytes32ToBytes32Map storage map,
        bytes32 key
    ) internal returns (bool) {
        delete map._values[key];
        return map._keys.remove(key);
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(
        Bytes32ToBytes32Map storage map,
        bytes32 key
    ) internal view returns (bool) {
        return map._keys.contains(key);
    }

    /**
     * @dev Returns the number of key-value pairs in the map. O(1).
     */
    function length(
        Bytes32ToBytes32Map storage map
    ) internal view returns (uint256) {
        return map._keys.length();
    }

    /**
     * @dev Returns the key-value pair stored at position `index` in the map. O(1).
     *
     * Note that there are no guarantees on the ordering of entries inside the
     * array, and it may change when more entries are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(
        Bytes32ToBytes32Map storage map,
        uint256 index
    ) internal view returns (bytes32, bytes32) {
        bytes32 key = map._keys.at(index);
        return (key, map._values[key]);
    }

    /**
     * @dev Tries to returns the value associated with `key`. O(1).
     * Does not revert if `key` is not in the map.
     */
    function tryGet(
        Bytes32ToBytes32Map storage map,
        bytes32 key
    ) internal view returns (bool, bytes32) {
        bytes32 value = map._values[key];
        if (value == bytes32(0)) {
            return (contains(map, key), bytes32(0));
        } else {
            return (true, value);
        }
    }

    /**
     * @dev Returns the value associated with `key`. O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(
        Bytes32ToBytes32Map storage map,
        bytes32 key
    ) internal view returns (bytes32) {
        bytes32 value = map._values[key];
        require(
            value != 0 || contains(map, key),
            "EnumerableMap: nonexistent key"
        );
        return value;
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(
        Bytes32ToBytes32Map storage map,
        bytes32 key,
        string memory errorMessage
    ) internal view returns (bytes32) {
        bytes32 value = map._values[key];
        require(value != 0 || contains(map, key), errorMessage);
        return value;
    }

    /**
     * @dev Return the an array containing all the keys
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the map grows to a point where copying to memory consumes too much gas to fit in a block.
     */

    function keys(
        Bytes32ToBytes32Map storage map
    ) internal view returns (bytes32[] memory) {
        return map._keys.values();
    }

    // UintToUintMap

    struct UintToUintMap {
        Bytes32ToBytes32Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(
        UintToUintMap storage map,
        uint256 key,
        uint256 value
    ) internal returns (bool) {
        return set(map._inner, bytes32(key), bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(
        UintToUintMap storage map,
        uint256 key
    ) internal returns (bool) {
        return remove(map._inner, bytes32(key));
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(
        UintToUintMap storage map,
        uint256 key
    ) internal view returns (bool) {
        return contains(map._inner, bytes32(key));
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(UintToUintMap storage map) internal view returns (uint256) {
        return length(map._inner);
    }

    /**
     * @dev Returns the element stored at position `index` in the set. O(1).
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(
        UintToUintMap storage map,
        uint256 index
    ) internal view returns (uint256, uint256) {
        (bytes32 key, bytes32 value) = at(map._inner, index);
        return (uint256(key), uint256(value));
    }

    /**
     * @dev Tries to returns the value associated with `key`. O(1).
     * Does not revert if `key` is not in the map.
     */
    function tryGet(
        UintToUintMap storage map,
        uint256 key
    ) internal view returns (bool, uint256) {
        (bool success, bytes32 value) = tryGet(map._inner, bytes32(key));
        return (success, uint256(value));
    }

    /**
     * @dev Returns the value associated with `key`. O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(
        UintToUintMap storage map,
        uint256 key
    ) internal view returns (uint256) {
        return uint256(get(map._inner, bytes32(key)));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(
        UintToUintMap storage map,
        uint256 key,
        string memory errorMessage
    ) internal view returns (uint256) {
        return uint256(get(map._inner, bytes32(key), errorMessage));
    }

    // UintToAddressMap

    struct UintToAddressMap {
        Bytes32ToBytes32Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(
        UintToAddressMap storage map,
        uint256 key,
        address value
    ) internal returns (bool) {
        return set(map._inner, bytes32(key), bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(
        UintToAddressMap storage map,
        uint256 key
    ) internal returns (bool) {
        return remove(map._inner, bytes32(key));
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(
        UintToAddressMap storage map,
        uint256 key
    ) internal view returns (bool) {
        return contains(map._inner, bytes32(key));
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(
        UintToAddressMap storage map
    ) internal view returns (uint256) {
        return length(map._inner);
    }

    /**
     * @dev Returns the element stored at position `index` in the set. O(1).
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(
        UintToAddressMap storage map,
        uint256 index
    ) internal view returns (uint256, address) {
        (bytes32 key, bytes32 value) = at(map._inner, index);
        return (uint256(key), address(uint160(uint256(value))));
    }

    /**
     * @dev Tries to returns the value associated with `key`. O(1).
     * Does not revert if `key` is not in the map.
     */
    function tryGet(
        UintToAddressMap storage map,
        uint256 key
    ) internal view returns (bool, address) {
        (bool success, bytes32 value) = tryGet(map._inner, bytes32(key));
        return (success, address(uint160(uint256(value))));
    }

    /**
     * @dev Returns the value associated with `key`. O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(
        UintToAddressMap storage map,
        uint256 key
    ) internal view returns (address) {
        return address(uint160(uint256(get(map._inner, bytes32(key)))));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(
        UintToAddressMap storage map,
        uint256 key,
        string memory errorMessage
    ) internal view returns (address) {
        return
            address(
                uint160(uint256(get(map._inner, bytes32(key), errorMessage)))
            );
    }

    // AddressToUintMap

    struct AddressToUintMap {
        Bytes32ToBytes32Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(
        AddressToUintMap storage map,
        address key,
        uint256 value
    ) internal returns (bool) {
        return set(map._inner, bytes32(uint256(uint160(key))), bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(
        AddressToUintMap storage map,
        address key
    ) internal returns (bool) {
        return remove(map._inner, bytes32(uint256(uint160(key))));
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(
        AddressToUintMap storage map,
        address key
    ) internal view returns (bool) {
        return contains(map._inner, bytes32(uint256(uint160(key))));
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(
        AddressToUintMap storage map
    ) internal view returns (uint256) {
        return length(map._inner);
    }

    /**
     * @dev Returns the element stored at position `index` in the set. O(1).
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(
        AddressToUintMap storage map,
        uint256 index
    ) internal view returns (address, uint256) {
        (bytes32 key, bytes32 value) = at(map._inner, index);
        return (address(uint160(uint256(key))), uint256(value));
    }

    /**
     * @dev Tries to returns the value associated with `key`. O(1).
     * Does not revert if `key` is not in the map.
     */
    function tryGet(
        AddressToUintMap storage map,
        address key
    ) internal view returns (bool, uint256) {
        (bool success, bytes32 value) = tryGet(
            map._inner,
            bytes32(uint256(uint160(key)))
        );
        return (success, uint256(value));
    }

    /**
     * @dev Returns the value associated with `key`. O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(
        AddressToUintMap storage map,
        address key
    ) internal view returns (uint256) {
        return uint256(get(map._inner, bytes32(uint256(uint160(key)))));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(
        AddressToUintMap storage map,
        address key,
        string memory errorMessage
    ) internal view returns (uint256) {
        return
            uint256(
                get(map._inner, bytes32(uint256(uint160(key))), errorMessage)
            );
    }

    /**
     * @dev Return the an array containing all the keys
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the map grows to a point where copying to memory consumes too much gas to fit in a block.
     */

    function keys(
        AddressToUintMap storage map
    ) internal view returns (address[] memory) {
        bytes32[] memory store = keys(map._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // Bytes32ToUintMap

    struct Bytes32ToUintMap {
        Bytes32ToBytes32Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(
        Bytes32ToUintMap storage map,
        bytes32 key,
        uint256 value
    ) internal returns (bool) {
        return set(map._inner, key, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(
        Bytes32ToUintMap storage map,
        bytes32 key
    ) internal returns (bool) {
        return remove(map._inner, key);
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(
        Bytes32ToUintMap storage map,
        bytes32 key
    ) internal view returns (bool) {
        return contains(map._inner, key);
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(
        Bytes32ToUintMap storage map
    ) internal view returns (uint256) {
        return length(map._inner);
    }

    /**
     * @dev Returns the element stored at position `index` in the set. O(1).
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(
        Bytes32ToUintMap storage map,
        uint256 index
    ) internal view returns (bytes32, uint256) {
        (bytes32 key, bytes32 value) = at(map._inner, index);
        return (key, uint256(value));
    }

    /**
     * @dev Tries to returns the value associated with `key`. O(1).
     * Does not revert if `key` is not in the map.
     */
    function tryGet(
        Bytes32ToUintMap storage map,
        bytes32 key
    ) internal view returns (bool, uint256) {
        (bool success, bytes32 value) = tryGet(map._inner, key);
        return (success, uint256(value));
    }

    /**
     * @dev Returns the value associated with `key`. O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(
        Bytes32ToUintMap storage map,
        bytes32 key
    ) internal view returns (uint256) {
        return uint256(get(map._inner, key));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(
        Bytes32ToUintMap storage map,
        bytes32 key,
        string memory errorMessage
    ) internal view returns (uint256) {
        return uint256(get(map._inner, key, errorMessage));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/structs/EnumerableSet.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableSet.js.

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableSet.
 * ====
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        bytes32[] memory store = _values(set._inner);
        bytes32[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}