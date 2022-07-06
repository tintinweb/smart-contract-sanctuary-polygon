// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "../controller/Controllable.sol";
import "../../interfaces/IBatchReader.sol";
import "../../interfaces/ICompanyManager.sol";
import "../../interfaces/IApprovalsManager.sol";
import "../../interfaces/IRequestsManager.sol";
import "../../interfaces/IDebtsManager.sol";

/// @notice Provide set of read-only functions
///         to read multiple data from chain using single call.
///
///         This is (mostly) state-less contract.
/// @author dvpublic
contract BatchReader is IBatchReader, Initializable, Controllable {

  string constant public VERSION = "1.0.0";

  // *****************************************************
  // *********** Initialization **************************
  // *****************************************************
  function initialize(
    address controller_
  ) external initializer {
    Controllable.__Controllable_init(controller_);
  }

  // *****************************************************
  // *********** Read data of Company manager ************
  // *****************************************************
  function getWorkerInfoBatch(WorkerUid[] calldata workers_)
  external
  view
  override
  returns (
    HourRate[] memory outHourRates,
    RoleUid[] memory outRoles,
    DepartmentUid[] memory outDepartmentUids,
    string[] memory outNames,
    address[] memory outWallets
  ) {
    uint lenWorkers = workers_.length;

    outHourRates = new HourRate[](lenWorkers);
    outRoles = new RoleUid[](lenWorkers);
    outDepartmentUids = new DepartmentUid[](lenWorkers);
    outNames = new string[](lenWorkers);
    outWallets = new address[](lenWorkers);

    for (uint i = 0; i < lenWorkers; i = _uncheckedInc(i)) {
      WorkerUid uid;
      WorkerFlags workerFlags;
      (uid
        , outHourRates[i]
        , outRoles[i]
        , workerFlags
        , outWallets[i]
        , outNames[i]
      ) = ICompanyManager(IController(_controller()).companyManager()).workersData(workers_[i]);

      if (_equalTo(uid, 0)) {
        revert ErrorWorkerNotFound(workers_[i]);
      }
      outDepartmentUids[i] = ICompanyManager(IController(_controller()).companyManager()).workerToDepartment(workers_[i]);
    }
  }

  function getDepartments(uint startFromIndex0_, uint count_) external view override returns (
    uint outCount
  , DepartmentUid[] memory outUids
  , address[] memory outHeads
  , string[] memory outTitles
  ) {
    ICompanyManager cm = ICompanyManager(IController(_controller()).companyManager());
    uint lenDepartments = cm.lengthDepartments();

    uint len = lenDepartments >= startFromIndex0_ + count_
      ? startFromIndex0_ + count_
      : lenDepartments;
    outCount = len - startFromIndex0_;

    outUids = new DepartmentUid[](outCount);
    outHeads = new address[](outCount);
    outTitles = new string[](outCount);

    for (uint i = 0; i < outCount; i = _uncheckedInc(i)) {
      DepartmentUid departmentUid = cm.departments(i + startFromIndex0_);
      (outUids[i], outHeads[i], outTitles[i]) = cm.departmentsData(departmentUid);
    }
  }

  function getRoles(uint16 startFromIndex0_, uint16 count_) external view override returns (
    uint16 outCount
    , RoleUid[] memory outUids
    , string[] memory outTitles
    , CountApprovals[] memory outCountApprovals
  ) {
    ICompanyManager cm = ICompanyManager(IController(_controller()).companyManager());
    uint16 lenRoles = cm.countRoles();

    uint16 len = lenRoles >= startFromIndex0_ + count_
      ? startFromIndex0_ + count_
      : lenRoles;
    outCount = len - startFromIndex0_;

    outUids = new RoleUid[](outCount);
    outCountApprovals = new CountApprovals[](outCount);
    outTitles = new string[](outCount);

    for (uint16 i = 0; i < outCount; i = _uncheckedInc16(i)) {
      RoleUid roleUid = cm.getRoleByIndex(i + startFromIndex0_);
      (outUids[i], outCountApprovals[i], outTitles[i]) = cm.rolesData(roleUid);
    }
  }

  function workersOfDepartment(DepartmentUid departmentId) external view returns (WorkerUid[] memory outWorkerUids) {
    ICompanyManager cm = ICompanyManager(IController(_controller()).companyManager());
    uint lenWorkers = cm.lengthDepartmentToWorkers(departmentId);

    outWorkerUids = new WorkerUid[](lenWorkers);

    for (uint i = 0; i < lenWorkers; i = _uncheckedInc(i)) {
      outWorkerUids[i] = cm.departmentToWorkers(departmentId, i);
    }
  }

  // *****************************************************
  // *********** Read data of Approvals manager **********
  // *****************************************************
  function isApproverBatch(address approver_, WorkerUid[] calldata workers_)
  external
  view
  override
  returns (bool[] memory) {
    IApprovalsManager am = IApprovalsManager(IController(_controller()).approvalsManager());

    uint lenWorkers = workers_.length;
    bool[] memory dest = new bool[](lenWorkers);
    for (uint i = 0; i < lenWorkers; i = _uncheckedInc(i)) {
      dest[i] = am.isApprover(approver_, workers_[i]);
    }
    return dest;
  }

  function approverToWorkersBatch(address approver_) external view returns (WorkerUid[] memory outWorkerUids) {
    IApprovalsManager am = IApprovalsManager(IController(_controller()).approvalsManager());
    uint len = am.lengthApproverToWorkers(approver_);

    outWorkerUids = new WorkerUid[](len);
    for (uint i = 0; i < len; i = _uncheckedInc(i)) {
      outWorkerUids[i] = am.approverToWorkers(approver_, i);
    }
  }

  // *****************************************************
  // *********** Read data of Requests manager ***********
  // *****************************************************

  function getRequestUidBatch(EpochType epoch_, WorkerUid[] calldata workers_)
  external
  view
  returns (RequestUid[] memory dest) {
    IRequestsManager rm = IRequestsManager(IController(_controller()).requestsManager());

    uint lenWorkers = workers_.length;
    dest = new RequestUid[](lenWorkers);
    for (uint i = 0; i < lenWorkers; i = _uncheckedInc(i)) {
      dest[i] = rm.getRequestUid(epoch_, workers_[i]);
    }
  }

  /// @notice Get info about specified approvals
  function getRequestStatuses(EpochType epoch_, WorkerUid[] memory workers_)
  external
  view
  override
  returns (RequestStatus[] memory outStatuses) {
    IRequestsManager rm = IRequestsManager(IController(_controller()).requestsManager());

    uint lenWorkers = workers_.length;
    outStatuses = new RequestStatus[](lenWorkers);
    for (uint i = 0; i < lenWorkers; i = _uncheckedInc(i)) {
      RequestUid requestUid = rm.getRequestUid(epoch_, workers_[i]);
      outStatuses[i] = rm.extractRequestStatus(rm.requestsStatusValues(requestUid));
    }
  }

  function getRejectionReasons(EpochType epoch_, WorkerUid[] memory workers_)
  external
  view
  returns (string[] memory outReasons) {
    IRequestsManager rm = IRequestsManager(IController(_controller()).requestsManager());

    uint lenWorkers = workers_.length;
    outReasons = new string[](lenWorkers);
    for (uint i = 0; i < lenWorkers; i = _uncheckedInc(i)) {
      RequestUid requestUid = rm.getRequestUid(epoch_, workers_[i]);
      ApprovalUid approvalUid = rm.getApprovalUid(msg.sender, requestUid);
      outReasons[i] = rm.approvalExplanations(approvalUid);
    }
  }

  function getApprovals(ApprovalUid[] calldata approvalUids)
  external
  view
  override
  returns (
    address[] memory approvers
  , uint[] memory approvedValues
  , string[] memory explanations
  ) {
    IRequestsManager rm = IRequestsManager(IController(_controller()).requestsManager());
    uint lenApprovals = approvalUids.length;

    approvers = new address[](lenApprovals);
    approvedValues = new uint[](lenApprovals);
    explanations = new string[](lenApprovals);

    for (uint i = 0; i < lenApprovals; i = _uncheckedInc(i)) {
      (approvers[i], approvedValues[i]) = rm.approverRequests(approvalUids[i]);
      explanations[i] = rm.approvalExplanations(approvalUids[i]);
    }
  }

  /// @notice Get an approvals provided by the signer to the requests of the given workers in the given epoch
  /// @return outApprovedValues Values of flags APPROVAL_XXX
  function getApprovalsMadeBySigner(EpochType epoch_, WorkerUid[] memory workerUids)
  external
  view
  returns (uint64[] memory outApprovedValues) {
    IRequestsManager rm = IRequestsManager(IController(_controller()).requestsManager());

    uint lenWorkers = workerUids.length;
    outApprovedValues = new uint64[](lenWorkers);
    for (uint i = 0; i < lenWorkers; i = _uncheckedInc(i)) {
      RequestUid requestUid = rm.getRequestUid(epoch_, workerUids[i]);
      (, outApprovedValues[i]) = rm.approverRequests(rm.getApprovalUid(msg.sender, requestUid));
    }
  }

  /// @notice Get info about all approvals created for the request
  function getApprovalsMadeForRequest(RequestUid requestUid)
  external
  view
  returns (
    address[] memory outApprovers
  , uint[] memory outApprovedValues
  , string[] memory outExplanations
  ) {
    IRequestsManager rm = IRequestsManager(IController(_controller()).requestsManager());

    uint lenApprovals = rm.lengthRequestApprovals(requestUid);

    outApprovers = new address[](lenApprovals);
    outApprovedValues = new uint[](lenApprovals);
    outExplanations = new string[](lenApprovals);

    for (uint i = 0; i < lenApprovals; i = _uncheckedInc(i)) {
      address approver = rm.requestApprovals(requestUid, i);
      ApprovalUid approvalUid = rm.getApprovalUid(approver, requestUid);
      (outApprovers[i], outApprovedValues[i]) = rm.approverRequests(approvalUid);
      if ( (outApprovedValues[i] & 0x2) != 0 ) { //0x2 is APPROVAL_NEGATIVE
        outExplanations[i] = rm.approvalExplanations(approvalUid);
      }
    }
  }

  // *****************************************************
  // *********** Read data of Debts manager **************
  // *****************************************************
  function getRequests(RequestUid[] calldata requestUids_) external view returns (
    WorkerUid[] memory outWorkerUids
  , DepartmentUid[] memory outDepartmentUids
  , RoleUid[] memory outWorkerRoles
  , uint32[] memory outCountHours
  , string[] memory outDescriptionUrls
  , HourRate[] memory outHourRates
  , EpochType[] memory outEpochTypes
  ) {
    {
      uint lenRequests = requestUids_.length;

      outWorkerUids = new WorkerUid[](lenRequests);
      outDepartmentUids = new DepartmentUid[](lenRequests);
      outWorkerRoles = new RoleUid[](lenRequests);
      outCountHours = new uint32[](lenRequests);
      outDescriptionUrls = new string[](lenRequests);
      outHourRates = new HourRate[](lenRequests);
      outEpochTypes = new EpochType[](lenRequests);
    }

    for (uint i = 0; i < requestUids_.length; i = _uncheckedInc(i)) {
      // There are two calls below
      // to workaround "Stack too deep, try removing local variables"
      {
        (outWorkerUids[i]
          , outWorkerRoles[i]
          , outDepartmentUids[i]
          , outHourRates[i]
          , outCountHours[i]
          , outEpochTypes[i]
          ,
        ) = IDebtsManager(IController(_controller()).debtsManager()).requestsData(requestUids_[i]);
      }
      {
        (
          ,
          ,
          ,
          ,
          ,
          , outDescriptionUrls[i]
        ) = IDebtsManager(IController(_controller()).debtsManager()).requestsData(requestUids_[i]);
      }
    }
  }

  /// @notice Get all fully or partly unpaid requests
  ///         You can get limited number of requests at once
  ///         To get all items, call this function multiple times,
  ///         increasing startIndex0 += countItemsInArrays on each step
  ///         until countItemsInArrays != 0
  /// @param bufferSize Max allowed length of requestIds and amountsUSD
  /// @param startIndex0 How many items should be skipped before starting to write found items to result arrays
  /// @return countItemsInArrays How many items were saved to requestIds and amountsUSD
  /// @dev If a request is not found (canceled), outWorkers and outAmountsUSD will contain 0 for the request
  function getUnpaidDebts(DepartmentUid departmentUid, RoleUid roleUid, uint bufferSize, uint startIndex0)
  external
  view
  override
  returns (uint countItemsInArrays
    , RequestUid[] memory outRequestIds
    , WorkerUid[] memory outWorkers
    , AmountUSD[] memory outAmountsUSD
    , DebtUid[] memory outDebtUids
  ) {
    outRequestIds = new RequestUid[](bufferSize);
    outWorkers = new WorkerUid[](bufferSize);
    outAmountsUSD = new AmountUSD[](bufferSize);
    outDebtUids = new DebtUid[](bufferSize);

    uint totalSkippedItems = 0;
    IDebtsManager dm = IDebtsManager(IController(_controller()).debtsManager());

    (uint64 totalCountDebts, uint64 firstUnpaidDebtIndex0,) = dm.roleDebts(departmentUid, roleUid);
    for (uint64 j = firstUnpaidDebtIndex0; j < totalCountDebts; j = _uncheckedInc64(j)) {
      if (totalSkippedItems == startIndex0) {
        outDebtUids[countItemsInArrays] = dm.roleDebtsList(departmentUid, roleUid, dm.wrapToNullableValue64(j));
        outRequestIds[countItemsInArrays] = dm.debtsToRequests(outDebtUids[countItemsInArrays]);
        (WorkerUid workerUid,,,,,,) = dm.requestsData(outRequestIds[countItemsInArrays]);
        outWorkers[countItemsInArrays] = workerUid; // 0 is allowed
        outAmountsUSD[countItemsInArrays] = dm.unpaidAmountsUSD(outDebtUids[countItemsInArrays]);

        countItemsInArrays = _uncheckedInc(countItemsInArrays);
        if (countItemsInArrays == bufferSize) break;
      } else {
        ++totalSkippedItems;
      }
    }

    return (countItemsInArrays, outRequestIds, outWorkers, outAmountsUSD, outDebtUids);
  }

  function getEpochAndStatusBatch(RequestUid[] calldata requests_)
  external
  view
  returns (RequestStatus[] memory outStatuses, EpochType[] memory outEpochs) {
    IDebtsManager dm = IDebtsManager(IController(_controller()).debtsManager());
    IRequestsManager rm = IRequestsManager(IController(_controller()).requestsManager());

    uint lenRequests = requests_.length;
    outStatuses = new RequestStatus[](lenRequests);
    outEpochs = new EpochType[](lenRequests);

    for (uint i = 0; i < lenRequests; i = _uncheckedInc(i)) {
      (,,,,, outEpochs[i],) = dm.requestsData(requests_[i]);
      outStatuses[i] = rm.extractRequestStatus(rm.requestsStatusValues(requests_[i]));
    }
  }

  function getDebtDepartmentsInfo()
  external
  view
  returns (
    DepartmentUid[] memory outDepartmentUids
    , AmountST[] memory outBudgetAmountST
  ) {
    IDebtsManager dm = IDebtsManager(IController(_controller()).debtsManager());
    uint lenDepartments = dm.lengthDepartments();
    EpochType currentEpoch = dm.currentEpoch();

    outDepartmentUids = new DepartmentUid[](lenDepartments);
    outBudgetAmountST = new AmountST[](lenDepartments);

    for (uint i = 0; i < lenDepartments; i = _uncheckedInc(i)) {
      DepartmentUid departmentUid = dm.departments(i);
      outDepartmentUids[i] = departmentUid;
      if (_equals(currentEpoch, dm.weekDepartmentUidsToPay(departmentUid))) {
        outBudgetAmountST[i] = dm.weekBudgetST(departmentUid);
      }
    }
  }

  function getWeekBudgetLimitsForRolesST(DepartmentUid departmentUid)
  external
  view
  returns (AmountST[] memory outAmounts) {
    IDebtsManager dm = IDebtsManager(IController(_controller()).debtsManager());
    uint lenRoles = dm.lengthWeekBudgetLimitsForRolesST(departmentUid);

    outAmounts = new AmountST[](lenRoles);

    for (uint i = 0; i < lenRoles; i = _uncheckedInc(i)) {
      outAmounts[i] = dm.weekBudgetLimitsForRolesST(departmentUid, i);
    }
  }

  function getUnpaidAmountsForDepartment(DepartmentUid departmentUid)
  external
  view
  returns (
    AmountUSD[] memory outUnpaidAmountUSD
  ) {
    IDebtsManager dm = IDebtsManager(IController(_controller()).debtsManager());

    uint16 countRoles = RoleUid.unwrap(dm.maxRoleValueInAllTimes());
    outUnpaidAmountUSD = new AmountUSD[](countRoles);

    for (uint16 i = 0; i < countRoles; i = _uncheckedInc16(i)) {
      (,, outUnpaidAmountUSD[i]) = dm.roleDebts(departmentUid, _getRoleByIndex(i) );
    }
  }


  // *****************************************************
  // ********** Optimization - unchecked *****************
  // *****************************************************

  function _uncheckedInc(uint i) internal pure returns (uint) {
    unchecked {
      return i + 1;
    }
  }

  function _uncheckedInc64(uint64 i) internal pure returns (uint64) {
    unchecked {
      return i + 1;
    }
  }

  function _uncheckedInc16(uint16 i) internal pure returns (uint16) {
    unchecked {
      return i + 1;
    }
  }

  // *****************************************************
  // *********  Helper function for WorkerUid ************
  // *****************************************************

  function _equalTo(WorkerUid uid1, uint64 uid2) internal pure returns (bool) {
    return WorkerUid.unwrap(uid1) == uid2;
  }

  // *****************************************************
  // ******* Helper function for EpochType ***************
  // *****************************************************

  function _equals(EpochType uid1, EpochType uid2) internal pure returns (bool) {
    return EpochType.unwrap(uid1) == EpochType.unwrap(uid2);
  }

  function _getRoleByIndex(uint16 index0) internal pure returns (RoleUid){
    return RoleUid.wrap(index0 + 1);
  }


  //slither-disable-next-line unused-state
  uint[50] private ______gap;
}

// SPDX-License-Identifier: ISC
/**
* By using this software, you understand, acknowledge and accept that Tetu
* and/or the underlying software are provided “as is” and “as available”
* basis and without warranties or representations of any kind either expressed
* or implied. Any use of this open source software released under the ISC
* Internet Systems Consortium license is done at your own risk to the fullest
* extent permissible pursuant to applicable law any and all liability as well
* as all warranties, including any fitness for a particular purpose with respect
* to Tetu and/or the underlying software and the use thereof are disclaimed.
*/

pragma solidity 0.8.9;

import "../../openzeppelin/Initializable.sol";
import "../../lib/SlotsLib.sol";
import "../../interfaces/IControllable.sol";
import "../../interfaces/IController.sol";

/// @title Implement basic functionality for any contract that require strict control
/// @dev Can be used with upgradeable pattern.
///      Require call __Controllable_init() in any case.
/// @author belbix
abstract contract Controllable is Initializable, IControllable {
  using SlotsLib for bytes32;

  /// @notice Version of the contract
  /// @dev Should be incremented when contract changed
  string public constant CONTROLLABLE_VERSION = "1.0.0";

  bytes32 internal constant _CONTROLLER_SLOT = bytes32(uint(keccak256("eip1967.controllable.controller")) - 1);
  bytes32 internal constant _CREATED_SLOT = bytes32(uint(keccak256("eip1967.controllable.created")) - 1);
  bytes32 internal constant _CREATED_BLOCK_SLOT = bytes32(uint(keccak256("eip1967.controllable.created_block")) - 1);
  bytes32 internal constant _REVISION_SLOT = bytes32(uint(keccak256("eip1967.controllable.revision")) - 1);
  bytes32 internal constant _PREVIOUS_LOGIC_SLOT = bytes32(uint(keccak256("eip1967.controllable.prev_logic")) - 1);

  event ContractInitialized(address controller, uint ts, uint block);
  event RevisionIncreased(uint value, address oldLogic);

  error ErrorGovernanceOnly();
  error ErrorIncreaseRevisionForbidden();

  /// @notice Initialize contract after setup it as proxy implementation
  ///         Save block.timestamp in the "created" variable
  /// @dev Use it only once after first logic setup
  /// @param controller_ Controller address
  function __Controllable_init(address controller_) public initializer {
    require(controller_ != address(0), "Zero controller");
    _CONTROLLER_SLOT.set(controller_);
    _CREATED_SLOT.set(block.timestamp);
    _CREATED_BLOCK_SLOT.set(block.number);
    emit ContractInitialized(controller_, block.timestamp, block.number);
  }

  /// @dev Return true if given address is controller
  function isController(address _value) external override view returns (bool) {
    return _isController(_value);
  }

  function _isController(address _value) internal view returns (bool) {
    return _value == _controller();
  }

  /// @notice Return true if given address is setup as governance in Controller
  function isGovernance(address _value) external override view returns (bool) {
    return _isGovernance(_value);
  }

  function _isGovernance(address _value) internal view returns (bool) {
    return IController(_controller()).governance() == _value;
  }

  /// @dev Contract upgrade counter
  function revision() external view returns (uint){
    return _REVISION_SLOT.getUint();
  }

  /// @dev Previous logic implementation
  function previousImplementation() external view returns (address){
    return _PREVIOUS_LOGIC_SLOT.getAddress();
  }

  // ************* SETTERS/GETTERS *******************

  /// @notice Return controller address saved in the contract slot
  function controller() external view override returns (address) {
    return _controller();
  }

  function _controller() internal view returns (address result) {
    return _CONTROLLER_SLOT.getAddress();
  }

  /// @notice Return creation timestamp
  /// @return Creation timestamp
  function created() external view override returns (uint) {
    return _CREATED_SLOT.getUint();
  }

  /// @notice Return creation block number
  /// @return Creation block number
  function createdBlock() external override view returns (uint) {
    return _CREATED_BLOCK_SLOT.getUint();
  }

  /// @dev Revision should be increased on each contract upgrade
  function increaseRevision(address oldLogic) external override {
    if (msg.sender != address(this)) {
      revert ErrorIncreaseRevisionForbidden();
    }
    uint r = _REVISION_SLOT.getUint() + 1;
    _REVISION_SLOT.set(r);
    _PREVIOUS_LOGIC_SLOT.set(oldLogic);
    emit RevisionIncreased(r, oldLogic);
  }

  // *****************************************************
  // *********** Functions instead of modifiers **********
  // Hardhat sometime doesn't parse correctly custom errors,
  // generated inside modifiers.
  // To reproduce the problem see
  //      git: ac9e9769ea2263dfbb741df7c11b8b5e96b03a4b (31.05.2022)
  // So, modifiers are replaced by ordinal functions
  // *****************************************************

  /// @dev Operations allowed only for Governance address
  function onlyGovernance() internal view {
    if (! _isGovernance(msg.sender)) {
      revert ErrorGovernanceOnly();
    }
  }

}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./ICompanyManagerBase.sol";
import "./IApprovalsManagerBase.sol";
import "./IDebtsManagerBase.sol";
import "./IRequestsManagerBase.sol";

/// @notice Provide set of read-only functions
///         to read multiple data from chain using single call.
interface IBatchReader is
IClerkTypes
, ICompanyManagerBase
, IApprovalsManagerBase
, IRequestsManagerBase
, IDebtsManagerBase
{
  function getWorkerInfoBatch(WorkerUid[] calldata workers_)
  external
  view
  returns (
    HourRate[] memory outHourRates,
    RoleUid[] memory outRoles,
    DepartmentUid[] memory outDepartmentUids,
    string[] memory outNames,
    address[] memory outWallets
  );

  function getDepartments(uint startFromIndex0_, uint count_) external view returns (
    uint outCount
    , DepartmentUid[] memory outUids
    , address[] memory outHeads
    , string[] memory outTitles
  );

  function getRoles(uint16 startFromIndex0_, uint16 count_) external view returns (
    uint16 outCount
    , RoleUid[] memory outUids
    , string[] memory outTitles
    , CountApprovals[] memory outCountApprovals
  );

  function workersOfDepartment(DepartmentUid departmentId) external view returns (WorkerUid[] memory);

  function isApproverBatch(address approver_, WorkerUid[] calldata workers_) external view returns (bool[] memory);

  function getRequestUidBatch(EpochType epoch_, WorkerUid[] calldata ids_) external view returns (RequestUid[] memory);

  /// @notice Get statuses of specified requests
  function getRequestStatuses(EpochType epoch_, WorkerUid[] memory workers_)
  external
  view
  returns (RequestStatus[] memory statuses);

  function getRejectionReasons(EpochType epoch_, WorkerUid[] memory workers_)
  external
  view
  returns (string[] memory outReasons);

  /// @notice Get info about specified approvals
  function getApprovals(ApprovalUid[] calldata approvalUids)
  external
  view
  returns (
      address[] memory approvers
    , uint[] memory approvedValues
    , string[] memory explanations
  );

  /// @notice Get info about all approvals created for the request
  function getApprovalsMadeForRequest(RequestUid requestUid)
  external
  view
  returns (
    address[] memory approvers
  , uint[] memory approvedValues
  , string[] memory explanations
  );

  /// @notice Get an approvals provided by the signer to the requests of the given workers in the given epoch
  /// @return outApprovedValues Values of flags APPROVAL_XXX
  function getApprovalsMadeBySigner(EpochType epoch_, WorkerUid[] memory workerUids)
  external
  view
  returns (uint64[] memory outApprovedValues);

  function getRequests(RequestUid[] calldata requestUids_) external view returns (
      WorkerUid[] memory outWorkerUids
    , DepartmentUid[] memory outDepartmentUids
    , RoleUid[] memory outWorkerRoles
    , uint32[] memory outCountHours
    , string[] memory outDescriptionUrls
    , HourRate[] memory outHourRates
    , EpochType[] memory outEpochTypes
  );

  function approverToWorkersBatch(address approver_) external view returns (WorkerUid[] memory);

  /// @notice Get all fully or partly unpaid requests
  ///         You can get limited number of requests at once
  ///         To get all items, call this function multiple times,
  ///         increasing startIndex0 += countItemsInArrays on each step
  ///         until countItemsInArrays != 0
  /// @param bufferSize Max allowed length of requestIds and amountsUSD
  /// @param startIndex0 How many items should be skipped before starting to write found items to result arrays
  /// @return countItemsInArrays How many items were saved to requestIds and amountsUSD
  function getUnpaidDebts(DepartmentUid departmentUid, RoleUid roleUid, uint bufferSize, uint startIndex0)
  external
  view
  returns (uint countItemsInArrays
    , RequestUid[] memory outRequestIds
    , WorkerUid[] memory outWorkers
    , AmountUSD[] memory outAmountsUSD
    , DebtUid[] memory outDebtUids
  );

  function getEpochAndStatusBatch(RequestUid[] calldata requests_)
  external
  view
  returns (RequestStatus[] memory outStatuses, EpochType[] memory outEpochs);

  /// @notice Get a list of departments for which debts have ever been registered + info about debts
  ///         All unused departments will have zero budgets
  /// @return outDepartmentUids This array has a length of DebtsManager.departments
  /// @return outBudgetAmountST Remain week budgets for the current epoch
  function getDebtDepartmentsInfo()
  external
  view
  returns (
    DepartmentUid[] memory outDepartmentUids
    , AmountST[] memory outBudgetAmountST
  );

  function getWeekBudgetLimitsForRolesST(DepartmentUid departmentUid)
  external
  view
  returns (AmountST[] memory outAmounts);

  /// @return outUnpaidAmountUSD Size of array is DebtsManager.maxRoleValueInAllTimes
  function getUnpaidAmountsForDepartment(DepartmentUid departmentUid)
  external
  view
  returns (
    AmountUSD[] memory outUnpaidAmountUSD
  );
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./IClerkTypes.sol";
import "./ICompanyManagerBudgets.sol";

/// @notice Provides info about workers, budgets, departments, roles
interface ICompanyManager is ICompanyManagerBudgets {
    function initRoles(
        string[] memory names_
    , CountApprovals[] memory countApprovals_
    ) external;

    /// @notice Check if approver is alloed to approve requests of the worker "by nature"
    ///         i.e. without any manually-set approving-permissions.
    ///         The approver is allowed to approve worker's request "by nature" if one of the following
    ///         conditions is true:
    ///         1) the approver is a head of the worker's department (and worker != approver)
    ///         2) if the option approve-low-by-high is enabled for the department
    ///            both approver and worker belong to the same department
    ///            and the approver has higher role then the worker
    function isNatureApprover(address approver_, WorkerUid worker_) external view returns (ApproverKind);
    function getCountRequiredApprovals(RoleUid role) external view returns (CountApprovals);
    function getRoleByIndex(uint16 index0) external pure returns (RoleUid);
    function lengthRoles() external view returns (uint);
    function lengthDepartmentToWorkers(DepartmentUid uid) external view returns (uint);
    function lengthRoleShares(DepartmentUid uid) external view returns (uint);

    /// ************************************************************
    /// * Direct access to public mapping for BatchReader-purposes *
    /// * All functions below were generated from artifact jsons   *
    /// * using https://gnidan.github.io/abi-to-sol/               *
    /// ************************************************************

    /// @dev Access to the mapping {workersData}
    function workersData(WorkerUid)
    external
    view
    returns (
        WorkerUid uid,
        HourRate hourRate,
        RoleUid role,
        WorkerFlags workerFlags,
        address wallet,
        string memory name
    );

    /// @dev Access to the mapping {workerToDepartment}
    function workerToDepartment(WorkerUid) external view returns (DepartmentUid);

    /// @dev Access to the mapping {departments}
    function departments(uint256) external view returns (DepartmentUid);

    /// @dev Access to the mapping {departmentsData}
    function departmentsData(DepartmentUid)
    external
    view
    returns (
        DepartmentUid uid,
        address head,
        string memory title
    );

    /// @dev Access to public variable {countRoles}
    function countRoles() external view returns (uint16);

    function rolesData(RoleUid)
    external
    view
    returns (
        RoleUid role,
        CountApprovals countApprovals,
        string memory title
    );

    /// @dev Access to the mapping {workers}
    function workers(uint256) external view returns (WorkerUid);

    /// @dev Access to the mapping {departmentToWorkers}
    function departmentToWorkers(DepartmentUid, uint256)
    external
    view
    returns (WorkerUid);

    /// @dev Access to the mapping {roleShares}
    function roleShares(DepartmentUid, uint256)
    external
    view
    returns (uint256);

    /// @dev Access to variable {weekBudgetST}
    function weekBudgetST()
    external
    view
    returns (AmountST);

    /// @dev Access to variable {salaryToken}
    function salaryToken()
    external
    view
    returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./IClerkTypes.sol";
import "./IApprovalsManagerBase.sol";

/// @notice Provides info about approvers and delegates
interface IApprovalsManager is IApprovalsManagerBase {

  /// @notice Check if the approver_ is valid approver for the worker_
  ///         and return the reason why the approver is/isn't valid
  function getApproverKind(address approver_, WorkerUid worker_) external view returns (ApproverKind);

  /// @notice Check if the approver_ is valid approver for the worker_
  ///         and return true if the approver is valid
  function isApprover(address approver_, WorkerUid worker_) external view returns (bool);

  /// @notice Check if the approver_ is registered approver for the worker_
  ///         it returns true even if the approver has temporary delegated his permission to some delegate
  function isRegisteredApprover(address approver_, WorkerUid worker_) external view returns (bool);

  function lengthWorkersToPermanentApprovers(WorkerUid workerUid) external view returns (uint);
  function lengthApproverToWorkers(address approver_) external view returns (uint);

  /// ************************************************************
  /// * Direct access to public mapping for BatchReader-purposes *
  /// * All functions below were generated from artifact jsons   *
  /// * using https://gnidan.github.io/abi-to-sol/               *
  /// ************************************************************

  /// @notice access to the mapping {approvers}
  function approvers(ApproverPair)
  external
  view
  returns (ApprovePermissionKind kind, address delegatedTo);

  /// @notice access to the mapping {workersToPermanentApprovers}
  function workersToPermanentApprovers(WorkerUid, uint256)
  external
  view
  returns (address);

  /// @notice access to the mapping {approverToWorkers}
  function approverToWorkers(address, uint256)
  external
  view
  returns (WorkerUid);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./IRequestsManagerBase.sol";

/// @notice Manage the list of requests.
///         Collect approvals and update approve-statuses of the requests on the fly
interface IRequestsManager is IRequestsManagerBase {

  /// @notice Cancel last request for the current epoch, created by the signer;
  ///        revoke related debt if it was already created
  function cancelRequest() external;

  /// @notice Register new request for the current epoch with initial status "registered"
  /// @param countHours_ Count of requested hours, max value should be less then MAX_ALLOWED_HOURS
  /// @param descriptionUrl_ Obligatory URL of the document with description of the hours.
  ///                        Max allowed length is MAX_URL_LENGTH chars.
  function createRequest(
    uint32 countHours_
    , string calldata descriptionUrl_
  ) external;

  function approve(
    RequestUid requestUid
    , bool approveValue_
    , string calldata explanation_
  ) external;

  /// @notice Make batch disapproving (with providing explanations)
  function disapproveBatch(
    RequestUid[] calldata requestUids
    , string[] calldata explanations
  ) external;

  /// @notice Make batch approving
  function approveBatch(RequestUid[] calldata requestUids) external;

  /// @notice Generate unique id of a request for the worker in the given epoch
  ///         keccak256(epoch_, worker_)
  function getRequestUid(EpochType epoch_, WorkerUid worker_) external pure returns (RequestUid);

  function extractRequestStatus(RequestStatusValue status)
  external
  pure
  returns (RequestStatus requestStatus);

  function lengthRequestsForEpoch(EpochType epoch) external view returns (uint256);
  function lengthRequestApprovals(RequestUid requestUid) external view returns (uint256);

  function getApprovalUid(address approver_, RequestUid requestUid_) external pure returns (ApprovalUid);

  /// ************************************************************
  /// * Direct access to public mapping for BatchReader-purposes *
  /// * All functions below were generated from artifact jsons   *
  /// * using https://gnidan.github.io/abi-to-sol/               *
  /// ************************************************************
  /// @dev Access to the mapping {approverRequests}
  function approverRequests(ApprovalUid)
  external
  view
  returns (address approver, uint64 approvedValue);

  /// @dev Access to the mapping {approvalExplanations}
  function approvalExplanations(ApprovalUid)
  external
  view
  returns (string memory);

  /// @dev Access to the mapping {requestsStatusValues}
  function requestsStatusValues(RequestUid)
  external
  view
  returns (RequestStatusValue);

  /// @dev Access to the array {requestsStatusValues}
  function requestsForEpoch(EpochType, uint256) external view returns (WorkerUid);

  /// @dev Access to the mapping {requestApprovals}
  function requestApprovals(RequestUid, uint256) external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./IClerkTypes.sol";
import "./IDebtsManagerBase.sol";

/// @notice Manage list of epochs and company-debts
interface IDebtsManager is IDebtsManagerBase {

    /// @notice Register new request with status "Registered"
    ///         It's allowed to register same request several times
    ///         (user makes several attempts to send request)
    ///         but only most recent version is stored.
    function addRequest(
        RequestUid requestUid_
        , WorkerUid workerUid_
        , uint32 countHours
        , string calldata descriptionUrl
    ) external;

    /// @notice Convert salary-amount of accepted request to company-debt
    ///         Amount of the debt is auto calculated using requests properties: countHours * hourRate
    function addDebt(
        RequestUid requestUid_
    ) external;

    /// @notice Revoke previously created debt
    ///         As result, we can have holes in the sequence of registered debts
    function revokeDebtForRequest(RequestUid requestUid_) external;

    /// @notice Increment epoch counter.
    ///         Initialize week budget available for the payment of all exist debts.
    ///         After that it's possible to make payments for debts registered in the previous epochs
    /// @param paySalaryImmediately If true then call pay() immediately after starting new epoch
    function startEpoch(bool paySalaryImmediately) external;

    function payForRole(DepartmentUid departmentUid, RoleUid role) external;
    function payForDepartment(DepartmentUid departmentUid) external;
    function pay() external;
    function payDebt(DepartmentUid departmentUid, RoleUid role, uint64 indexDebt0) external;

// Functions for Readers
    function lengthDepartments() external view returns (uint);
    function lengthWeekBudgetLimitsForRolesST(DepartmentUid departmentUid) external view returns (uint);
    function wrapToNullableValue64(uint64 value) external pure returns (NullableValue64);

    /// @notice get worker and role for request, don't make any checks (return zeros if the request is not known)
    /// @dev we need this function to make approve-call more gas-efficient
    function getRequestWorkerAndRole(RequestUid requestUid_) external view returns (WorkerUid worker, RoleUid role);

    /// ************************************************************
    /// * Direct access to public mapping for BatchReader-purposes *
    /// * All functions below were generated from artifact jsons   *
    /// * using https://gnidan.github.io/abi-to-sol/               *
    /// ************************************************************

    /// @dev Access to the mapping {requestsData}
    function requestsData(RequestUid)
    external
    view
    returns (
        WorkerUid worker,
        RoleUid role,
        DepartmentUid department,
        HourRate hourRate,
        uint32 countHours,
        EpochType epoch,
        string memory descriptionUrl
    );

    /// @dev Access to the mapping {requestsToDebts}
    function requestsToDebts(RequestUid) external view returns (DebtUid);

    /// @dev Access to the mapping {statForWorkers}
    function statForWorkers(WorkerUid)
    external
    view
    returns (uint32 workedHours, AmountUSD earnedDollars);

    /// @dev Access to the mapping {weekBudgetST}
    function weekBudgetST(DepartmentUid) external view returns (AmountST);

    /// @dev Access to the mapping {weekBudgetLimitsForRolesST}
    function weekBudgetLimitsForRolesST(DepartmentUid, uint256)
    external
    view
    returns (AmountST);

    /// @dev Access to the public variable {weekSalaryToken}
    function weekSalaryToken() external view returns (address);

    /// @dev Access to the mapping {roleDebts}
    function roleDebts(DepartmentUid, RoleUid)
    external
    view
    returns (
        uint64 totalCountDebts,
        uint64 firstUnpaidDebtIndex0,
        AmountUSD amountUnpaidTotalUSD
    );

    /// @dev Access to the mapping {roleDebtsList}
    function roleDebtsList(
        DepartmentUid,
        RoleUid,
        NullableValue64
    ) external view returns (DebtUid);

    /// @dev Access to the public variable {maxRoleValueInAllTimes}
    function maxRoleValueInAllTimes() external view returns (RoleUid);

    /// @dev Access to the public variable {currentEpoch}
    function currentEpoch() external view returns (EpochType);

    /// @dev Access to the public variable {firstEpoch}
    function firstEpoch() external view returns (EpochType);

    function debtsToRequests(DebtUid) external view returns (RequestUid);
    function unpaidAmountsUSD(DebtUid) external view returns (AmountUSD);
    function departments(uint) external view returns (DepartmentUid);

    function weekDepartmentUidsToPay(DepartmentUid) external view returns (EpochType);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
 */
abstract contract Initializable {
  /// @notice Initializable: contract is already initialized
  error ErrorAlreadyInitialized();

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
    if (!_initializing && _initialized) {
      revert ErrorAlreadyInitialized();
    }

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
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

/// @title Library for setting / getting slot variables (used in upgradable proxy contracts)
/// @author bogdoslav
library SlotsLib {

  /// @notice Version of the contract
  /// @dev Should be incremented when contract changed
  string public constant SLOT_LIB_VERSION = "1.0.0";

  // ************* GETTERS *******************

  /// @dev Gets a slot as bytes32
  function getBytes32(bytes32 slot) internal view returns (bytes32 result) {
    assembly {
      result := sload(slot)
    }
  }

  /// @dev Gets a slot as an address
  function getAddress(bytes32 slot) internal view returns (address result) {
    assembly {
      result := sload(slot)
    }
  }

  /// @dev Gets a slot as uint
  function getUint(bytes32 slot) internal view returns (uint result) {
    assembly {
      result := sload(slot)
    }
  }

  // ************* ARRAY GETTERS *******************

  /// @dev Gets an array length
  function arrayLength(bytes32 slot) internal view returns (uint result) {
    assembly {
      result := sload(slot)
    }
  }

  /// @dev Gets a slot array by index as address
  /// @notice First slot is array length, elements ordered backward in memory
  /// @notice This is unsafe, without checking array length.
  function addressAt(bytes32 slot, uint index) internal view returns (address result) {
    bytes32 pointer = bytes32(uint(slot) - 1 - index);
    assembly {
      result := sload(pointer)
    }
  }

  // ************* SETTERS *******************

  /// @dev Sets a slot with bytes32
  /// @notice Check address for 0 at the setter
  function set(bytes32 slot, bytes32 value) internal {
    assembly {
      sstore(slot, value)
    }
  }

  /// @dev Sets a slot with address
  /// @notice Check address for 0 at the setter
  function set(bytes32 slot, address value) internal {
    assembly {
      sstore(slot, value)
    }
  }

  /// @dev Sets a slot with uint
  function set(bytes32 slot, uint value) internal {
    assembly {
      sstore(slot, value)
    }
  }

}

// SPDX-License-Identifier: ISC
/**
* By using this software, you understand, acknowledge and accept that Tetu
* and/or the underlying software are provided “as is” and “as available”
* basis and without warranties or representations of any kind either expressed
* or implied. Any use of this open source software released under the ISC
* Internet Systems Consortium license is done at your own risk to the fullest
* extent permissible pursuant to applicable law any and all liability as well
* as all warranties, including any fitness for a particular purpose with respect
* to Tetu and/or the underlying software and the use thereof are disclaimed.
*/

pragma solidity 0.8.9;

interface IControllable {

  function isController(address _contract) external view returns (bool);

  function isGovernance(address _contract) external view returns (bool);

  function created() external view returns (uint256);

  function createdBlock() external view returns (uint256);

  function controller() external view returns (address);

  function increaseRevision(address oldLogic) external;

}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface IController {
  /// @notice Return governance address
  function governance() external view returns (address);

  /// @notice Return address of CompanyManager-instance
  function companyManager() external view returns (address);

  /// @notice Return address of RequestsManager-instance
  function requestsManager() external view returns (address);

  /// @notice Return address of DebtsManager-instance
  function debtsManager() external view returns (address);

  /// @notice Return address of PriceOracle-instance
  function priceOracle() external view returns (address);
  function setPriceOracle(address priceOracle) external;

  /// @notice Return address of PaymentsManager-instance
  function paymentsManager() external view returns (address);

  /// @notice Return address of Approvals-instance
  function approvalsManager() external view returns (address);

  /// @notice Return address of BatchReader-instance
  function batchReader() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./IClerkTypes.sol";

/// @notice All common user defined types, enums and structs
///         used by CompanyManager and its readers
interface ICompanyManagerBase is IClerkTypes {
  struct RoleData {
    RoleUid role;
    /// @notice how many approvals are required to approve an worker's request with this role
    CountApprovals countApprovals;

    string title;
  }

  struct Department {
    /// @dev Arbitrary custom unique id > 0
    DepartmentUid uid;
    /// @notice A head of the department. Can be unassigned (0)
    address head;
    string title;
  }

  /// @notice Current worker settings
  struct Worker {
    /// @notice Unique permanent identifier of the worker
    /// @dev it's generated using _workerUidCounter. Started from 1
    WorkerUid uid;                        //64 bits
    /// @notice hour rate, $ per hour
    HourRate hourRate;                    //32 bits
    RoleUid role;                         //64 bits
    ///  @notice Various boolean-attributes of the worker, i.e. "boost-calculator is used"
    WorkerFlags workerFlags;              //96 bits
    //                                    //256 bits in total

    /// @notice current wallet of the worker
    /// @dev it can be changed, so it can be different from uid
    address wallet;
    string name;
  }

  // *****************************************************
  // ************* Custom errors *************************
  // *****************************************************

  error ErrorCannotMoveHeadToAnotherDepartment();

  /// @notice You try to register new worker with a wallet
  ///         that is already registered for some other worker
  error ErrorWalletIsAlreadyUsedByOtherWorker();

  /// @notice Provided list of roles is incorrect (i.e. incomplete or it contains unregistered role)
  error ErrorIncorrectRoles();

  /// @notice Total sum of shared of all departments must be equal to TOTAL_SUM_SHARES
  error ErrorIncorrectSharesSum(uint currentSum, uint requiredSum);

  /// @notice Share must be greater then zero.
  ///         If you need assign share = 0 to a department, just exclude the department from the list
  ///         of the departments passed to setBudgetShares
  error ErrorZeroDepartmentBudgetShare();

  /// @notice The department is already registered, try to use another uid for new department
  error ErrorDepartmentAlreadyRegistered(DepartmentUid uid);

  /// @notice It's not possible to set new wallet for a worker
  ///         if the wallet is used as approver for the worker
  error ErrorNewWalletIsUsedByApprover();

  /// @notice setBudgetShares is not called
  error ErrorUnknownBudgetShares();

  /// @notice companyManager.setWeekBudget was not called
  error ErrorZeroWeekBudget();

  /// @notice The role is not registered
  error ErrorRoleNotFound(RoleUid uid);

}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./IClerkTypes.sol";

/// @notice All common user defined types, enums and structs
///         used by ApprovalsManager and its readers
interface IApprovalsManagerBase is IClerkTypes {

  struct ApproverEntry {
    ApprovePermissionKind kind;
    /// @notice to whom the approving permission is delegated
    address delegatedTo;
  }

  // *****************************************************
  // ************* Custom errors *************************
  // *****************************************************

  /// @notice You cannot delegate your approving permission to a registered approver of the worker
  error ErrorTheDelegateHasSamePermission();

  /// @notice The delegate cannot be equal to worker or the approver
  error ErrorIncorrectDelegate();

  /// @notice Currently the permission is delegated to another delegate.
  error ErrorThePermissionIsAlreadyDelegated();

  /// @notice You try to delegate temporary approving permission, received from the other [email protected]
  ///         You can delegate approving permission only if you are approver, not a delegate
  error ErrorApprovingReDelegationIsNotAllowed();

  /// @notice Permanent approver, head of the worker's department or governance only
  error ErrorApproverOrHeadOrGovOnly();

  /// @notice If approving permission was delegated by some approver,
  ///         it's not allowed to delete it using removeApprover
  ///         Use removeDelegation instead.
  error ErrorCannotRemoveNotPermanentApprover();

  /// @notice It's not allowed to a worker to be approver of his own requests
  error ErrorWorkerCannotBeApprover();

  /// @notice Provided address is not registered as a delegate of the worker
  error ErrorNotDelegated(address providedAddress, WorkerUid worker);

}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./IClerkTypes.sol";
import "./IRequestsTypes.sol";

/// @notice All common user defined types, enums and structs
///         used by DebtsManager and its readers
interface IDebtsManagerBase is IRequestsTypes {

  /// @notice All registered company-debts for the workers of the specified role
  ///         Unique order number of the debt registered for the specified pair (department, role)
  ///         All debts in the pair are numerated as 1, 2, 3 ...
  ///         and are payed exactly in the same order.
  struct RoleDebts {
    /// @notice Total count debts registered in debts-mapping.
    uint64 totalCountDebts;

    /// @notice 0-based index of first unpaid debt
    ///         Valid values [0...totalCountDebts)
    ///         The range [0...totalCountDebts) can contain revoked debts with unpaid amount = 0
    uint64 firstUnpaidDebtIndex0;

    /// @notice total unpaid amount by all debts in the role
    /// @dev This value can be used to know if there are any really unpaid debts for the (department, role)
    ///      firstUnpaidDebtIndex0 is not reliable for this purpose because of revoke debts
    AmountUSD amountUnpaidTotalUSD;
  }

  // *****************************************************
  // ************* Custom errors *************************
  // *****************************************************
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./IRequestsTypes.sol";

/// @notice All common user defined types, enums and structs
///         used by RequestsManager and its readers
interface IRequestsManagerBase is IRequestsTypes {
  /// @notice approval or disapproval of the request
  struct Approval {
    address approver;
    /// @notice Approval value: positive or negative
    ///         If the worker has canceled his request,
    ///         this value is changed to (positive or negative) | canceled
    /// @dev see APPROVAL_XXX flags
    uint64 approvedValue;
  }

  // *****************************************************
  // ************* Custom errors *************************
  // *****************************************************

  /// @notice It's not allowed to approve canceled request. It's not allowed to cancel it second time
  error ErrorRequestIsCanceled();

  /// @notice Number of provided hours cannot exceed specified threshold
  error ErrorTooManyHours(uint countHours, uint maxAllowedValue);

}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

/// @notice All common user defined types, enums and custom errors
///         used by Payroll-clerk application contracts
interface IClerkTypes {

  // *****************************************************
  // ************* User defined types ********************
  // *****************************************************

  /// @notice Unique id of the worker, auto-generated using a counter
type WorkerUid is uint64;

  /// @notice Unique id of the departments (manually assigned by the governance)
type DepartmentUid is uint16;

  /// @notice Unique ID of a request
  ///         uint(keccak256(currentEpoch, worker))
type RequestUid is uint;

  /// @notice Unique global id of the registered debt.
  /// @dev This is order number of registered debt: 1,2,3... See _debtUidCounter
type DebtUid is uint64;

  /// @notice Unique id of the epoch.
  ///         Epoch is a period for which salary is paid. Usually it's 1 week.
  ///         Initially the epoch is initialized by some initial value, i.e. 34
  ///         and then it's incremented by one with each week
type EpochType is uint16;

  ///  @notice 1-based unique ID of worker role
  ///          lowest is novice, highest is nomarch
type RoleUid is uint16;

  /// @notice Amount in salary tokens
  ///         The salary token = the token used as a salary token in the current epoch
  ///                            to pay debts of the previous epochs.
type AmountST is uint256;

  /// @notice Amount in USD == countHours * hourRate (no decimals here)
type AmountUSD is uint64;

  /// @notice Hour rate = USD per hour
type HourRate is uint16;

  /// @notice Bitmask with optional features for departments
type DepartmentOptionMask is uint256;

  /// @notice Result of isApprover function
  ///         It can return any code, that explain the reason why
  ///         the particular address is considered as approver or not approver for the worker's requests
  ///         If the bit 0x1 is ON, this is approver
  ///         if the big 0x1 is OFF, this is NOT approver
  ///         CompanyManager and ApprovalsManager have various codes
type ApproverKind is uint256;

  /// @notice Encoded values: (RequestStatus, countPositiveApprovals, countNegativeApprovals)
type RequestStatusValue is uint;

  /// @notice how many approvals are required to approve a request created by the worker with the specified role
type CountApprovals is uint16;

  /// @notice Unique ID of an approval
  ///         uint(keccak256(approver, requestUid))
  ///         The uid is generated in a way that don't allow
  ///         an approver to create several approves for a single request
type ApprovalUid is uint;

  /// @notice uint64 with following characteristics:
  ///         - value 0 is used
  ///         - we need to use this type as a key or value in the mapping
  ///         So, all values are stored in the mapping as (value+1).
  ///         There is special function to wrap/unwrap value to this type.
type NullableValue64 is uint64;

  ///  @notice A hash of following unique data: uint(keccak256(approver-wallet, workerUid))
type ApproverPair is uint;

  ///  @notice Various boolean-attributes of the worker, i.e. "boost-calculator is used"
type WorkerFlags is uint96;

  // *****************************************************
  // ************* Enums and structs *********************
  // *****************************************************
  enum RequestStatus {
    Unknown_0,    //0
    /// @notice Worker has added the request, but the request is not still approved / rejected
    New_1,        //1
    /// @notice The request has got enough approvals to be accepted to payment
    Approved_2,   //2
    /// @notice The request has got at least one disapproval, so it cannot be accepted to payment
    Rejected_3,   //3
    /// @notice Worker has canceled the request
    Canceled_4    //4
  }

  enum ApprovePermissionKind {
    Unknown_0,
    /// @notice Permission to make an approval is given permanently
    Permanent_1,
    /// @notice Permission to make an approval is given temporary
    Delegated_2
  }

  // *****************************************************
  // ************* Custom errors *************************
  // *****************************************************
  /// @notice Worker not found, the worker ID is not registered
  error ErrorWorkerNotFound(WorkerUid uid);

  /// @notice The department is not registered
  error ErrorUnknownDepartment(DepartmentUid uid);

  /// @notice The address cannot be zero
  /// @param errorCode Some error code to help to identify exact place of the error in the source codes
  error ErrorZeroAddress(uint errorCode);

  /// @notice The amount cannot be zero or cannot exceed some limits
  error ErrorIncorrectAmount();

  /// @notice  A function to change data was called,
  ///          but new data is exactly the same as the stored data
  error ErrorDataNotChanged();

  /// @notice Provided string is empty
  error ErrorEmptyString();

  /// @notice Too long string
  error ErrorTooLongString(uint currentLength, uint maxAllowedLength);

  /// @notice You don't have permissions for such operation
  error ErrorAccessDenied();

  /// @notice Two or more arrays were passed to the function.
  ///         The arrays should have same length, but they haven't
  error ErrorArraysHaveDifferentLengths();

  /// @notice It's not allowed to send empty array to the called function
  error ErrorEmptyArrayNotAllowed();

  /// @notice Provided address is not registered as an approver of the worker
  error ErrorNotApprover(address providedAddress, WorkerUid worker);

  /// @notice You try to make action that is already performed
  ///         i.e. try to move a worker to a department whereas the worker is already a member of the department
  error ErrorActionIsAlreadyDone();

  error ErrorGovernanceOrDepartmentHeadOnly();

  /// @notice Some param has value = 0
  /// @param errorCode allows to identify exact problem place in the code
  error ErrorZeroValueNotAllowed(uint errorCode);

  /// @notice Hour rate must be greater then zero and less or equal then the given threshold (MAX_HOURLY_RATE)
  error ErrorIncorrectRate(HourRate rate);

  /// @notice You try to set new head of a department
  ///         But the account is alreayd the head of the this or other department
  error ErrorAlreadyHead(DepartmentUid);

  /// @notice The request is not registered
  error ErrorUnknownRequest(RequestUid uid);

  error ErrorNotEnoughFund();
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./IClerkTypes.sol";

/// @notice All common user defined types, enums and structs
///         used by both RequestsManager and DebtsManager
interface IRequestsTypes is IClerkTypes {

  /// @notice Request to pay a salary to a worker
  ///         RequestData is stored in DebtsManaget
  ///         because request-data is used both in Debts and in Requests manager.
  struct RequestData {
    WorkerUid worker;           // 64 bit
    RoleUid role;               // 16 bit
    DepartmentUid department;   // 16 bit
    HourRate hourRate;          // 16 bit
    uint32 countHours;          // 32 bit
    EpochType epoch;            // 16 bit
    //                             160 bit in total


    /// @notice URL to the report with description how the hours were spent
    string descriptionUrl;
  }

  struct WorkerStat {
    /// @notice The number of hours an worker has worked during the entire period of work
    uint32 workedHours;

    /// @notice The dollar amount that the worker has earned over the entire period of working,
    ///         including paid salary and the company's current debt to the worker
    AmountUSD earnedDollars;
  }

}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./IClerkTypes.sol";
import "./ICompanyManagerDepartments.sol";

/// @notice CompanyManager-functions to work with budgets and role limits
interface ICompanyManagerBudgets is ICompanyManagerDepartments {
    function setWeekBudget(AmountST amountST, address salaryToken_) external;

    function setBudgetShares(
        DepartmentUid[] calldata departmentUids_
    , uint[] calldata departmentShares_
    ) external;

    function setRoleShares(
        DepartmentUid departmentUid_,
        uint[] memory roleShares_
    ) external;



    function getBudgetShares()
    external
    view
    returns (
        DepartmentUid[] memory outDepartmentUids
        , uint[] memory outDepartmentShares
        , uint outSumShares
    );

    /// @notice Get week budgets for the company
    ///         week budget is auto adjusted to available amount at the start of epoch.
    ///                  C = budget from CompanyManager, S - balance of salary tokens, P - week budget
    ///                  C > S: not enough money, revert
    ///                  C <= S: use all available money to pay salary, so P := S
    function getWeekBudgetST() external view returns (AmountST);

    /// @notice Get week budgets for all departments [in salary token]
    /// @param weekBudgetST_ If 0 then week budget should be auto-calculated
    /// @return outDepartmentUids List of departments with not-zero week budget
    /// @return outAmountsST Week budget for each department
    /// @return outSalaryToken Currently used salary token, week budget is set using it.
    function getWeekDepartmentBudgetsST(AmountST weekBudgetST_)
    external
    view
    returns (
        DepartmentUid[] memory outDepartmentUids
        , AmountST[] memory outAmountsST
        , address outSalaryToken
    );

    /// @notice Get max allowed amount [salary token]
    ///         that can be paid for each role of the department
    /// @param  departmentWeekBudgetST Week budget of the department
    /// @return outAmountST Result amounts for all roles
    ///         The length of array is equal to companyManager.countRoles
    function getMaxWeekBudgetForRolesST(AmountST departmentWeekBudgetST, DepartmentUid departmentUid)
    external
    view
    returns (
        AmountST[] memory outAmountST
    );
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./IClerkTypes.sol";
import "./ICompanyManagerWorkers.sol";

/// @notice CompanyManager-functions to work with departments + workers
interface ICompanyManagerDepartments is ICompanyManagerWorkers {
    function addDepartment(
        DepartmentUid uid
    , string calldata departmentTitle
    ) external;

    function getDepartment(DepartmentUid uid)
    external
    view
    returns (address head, string memory departmentTitle);

    function setDepartmentHead(
        DepartmentUid departmentUid_
    , address head_
    ) external;

    function renameDepartment(DepartmentUid uid, string memory departmentTitle) external;

    /// @param optionFlag One of following values: CompanyManagerStorage.FLAG_DEPARTMENT_OPTION_XXX
    function setDepartmentOption(DepartmentUid departmentUid, uint optionFlag, bool value) external;
    function getDepartmentOption(DepartmentUid departmentUid, uint optionFlag) external view returns (bool);

    /// @notice Check if the wallet is a head of the worker's department
    function isDepartmentHead(address wallet, WorkerUid workerUid) external view returns (bool);

    function lengthDepartments() external view returns (uint);

    function moveWorkersToDepartment(
        WorkerUid[] calldata workers_
    , DepartmentUid departmentUid_
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./IClerkTypes.sol";
import "./ICompanyManagerBase.sol";

/// @notice CompanyManager-functions to work with workers
interface ICompanyManagerWorkers is ICompanyManagerBase {
  function addWorker(
    address wallet_,
    HourRate hourRate_,
    string calldata name_,
    RoleUid roles_
  ) external;

  function addWorkers(
    address[] calldata wallets_,
    HourRate[] calldata rates,
    string[] calldata names,
    RoleUid[] calldata roles
  ) external;

  function setWorkerName(WorkerUid workerUid, string calldata name_) external;
  function setWorkerRole(WorkerUid workerUid, RoleUid role_) external;
  function setHourlyRate(WorkerUid workerUid, HourRate rate_) external;

  function changeWallet(WorkerUid worker_, address newWallet) external;
  function getWorkerByWallet(address wallet) external view returns (WorkerUid);

  /// @notice Provide info required by RequestManager at the point of request registration
  ///         Return the role of worker. It is taken into account in salary payment algo.
  ///         If the worker has several roles, the role with highest permissions
  ///         will be return (i.e. NOMARCH + EDUCATED => NOMARCH)
  ///
  ///         Revert if the worker is not found
  function getWorkerInfo(WorkerUid worker_)
  external
  view
  returns (
    HourRate hourRate,
    RoleUid role,
    DepartmentUid departmentUid,
    string memory name,
    address wallet
  );

  /// @notice Return true if the worker is registered in workersData
  function isWorkerValid(WorkerUid worker_) external view returns (bool);

  ///  @notice Get active wallet for the given worker
  function getWallet(WorkerUid workerId_) external view returns (address);

  function lengthWorkers() external view returns (uint);
}