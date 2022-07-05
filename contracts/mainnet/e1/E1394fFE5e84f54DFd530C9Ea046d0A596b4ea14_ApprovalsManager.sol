// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./ApprovalsManagerStorage.sol";
import "../../interfaces/IApprovalsManager.sol";
import "../../interfaces/ICompanyManager.sol";

/// @notice Manager approvers and delegates
///         CompanyManager supports approvers by nature, i.e. head can approve requests of his workers.
///         This contract provides possibility to set approvers for workers manually.
///         Any wallet can be set as approver of the worker.
///         Assigned approver is able to delegate has approving permission to any other wallet - delegate.
///         The delegate is able to approve requests instead of original approver
///         until the approver doesn't revoke his permission back.
/// @author dvpublic
contract ApprovalsManager is ApprovalsManagerStorage {

  // *****************************************************
  // *********** Initialization **************************
  // *****************************************************
  function initialize(
    address controller_
  ) external initializer {
    Controllable.__Controllable_init(controller_);
  }

  // ****************************************************
  // *********** Add/remove approvers *******************
  // ****************************************************

  /// @notice Add some arbitrary account as approver for the worker
  ///         The account will be allowed to approve requests of the worker
  function addApprover(address approver_, WorkerUid worker_)
  external {
    ICompanyManager cm = ICompanyManager(IController(_controller()).companyManager());
    _onlyGovernanceOrDepartmentHead(worker_);

    ApproverPair aid = getApproverPair(approver_, worker_);

    if (approvers[aid].kind != ApprovePermissionKind.Unknown_0) {
      revert ErrorActionIsAlreadyDone();
    }
    if (!cm.isWorkerValid(worker_)) {
      revert ErrorWorkerNotFound(worker_);
    }
    if (_equals(cm.getWorkerByWallet(approver_), worker_)) {
      revert ErrorWorkerCannotBeApprover();
    }

    // add new ApproverEntry
    approvers[aid].kind = ApprovePermissionKind.Permanent_1;

    // add new approver to the list of worker approvers
    workersToPermanentApprovers[worker_].push(approver_);

    // add new worker to the list of approver's workers
    approverToWorkers[approver_].push(worker_);

    emit OnAddApprover(worker_, approver_);
  }

  /// @notice Remove the approver from the list of approvers of the worker
  function removeApprover(address approver_, WorkerUid worker_)
  external {
    _onlyGovernanceOrDepartmentHead(worker_);

    ApproverPair aid = getApproverPair(approver_, worker_);
    ApproverEntry storage ae = approvers[aid];

    if (ae.kind == ApprovePermissionKind.Unknown_0) {
      revert ErrorNotApprover(approver_, worker_);
    }
    if (ae.kind != ApprovePermissionKind.Permanent_1) {
      revert ErrorCannotRemoveNotPermanentApprover();
    }

    // delete the approver from listApprovers and put last added approver on the place of the removed item
    _deleteApproverFromListApprovers(worker_, approver_);

    // delete the worker from approverToWorkers and put last added worker on the place of the removed item
    _deleteWorkerFromApproversToWorkers(approver_, worker_);

    delete approvers[aid];
    emit OnRemoveApprover(worker_, approver_);
  }

  /// @notice delete the approver from listApprovers and put last added approver on the place of the removed item
  function _deleteApproverFromListApprovers(WorkerUid worker_, address approver_) internal {
    address[] storage listApprovers = workersToPermanentApprovers[worker_];

    uint len = listApprovers.length;
    for (uint i = 0; i < len; i = _uncheckedInc(i)) {
      if (listApprovers[i] == approver_) {
        if (i < len - 1) {
          listApprovers[i] = listApprovers[len - 1];
        }
        listApprovers.pop();
        break;
      }
    }
  }

  /// @notice delete the worker from approverToWorkers and put last added worker on the place of the removed item
  function _deleteWorkerFromApproversToWorkers(address approver_, WorkerUid worker_) internal {
    WorkerUid[] storage listWorkers = approverToWorkers[approver_];

    uint len = listWorkers.length;
    for (uint i = 0; i < len; i = _uncheckedInc(i)) {
      if (_equals(listWorkers[i], worker_)) {
        if (i < len - 1) {
          listWorkers[i] = listWorkers[len - 1];
        }
        listWorkers.pop();
        break;
      }
    }
  }

  // *****************************************************
  // ***************** Is approver ***********************
  // *****************************************************

  /// @notice Check if the approver has right to approve requests of the worker
  ///         Take into account all explicit and implicit cases:
  ///         permanent and delegated rights, approver WorkerRole and so on.
  function _getApproverKind(address approver_, WorkerUid worker_) internal view returns (ApproverKind) {
    ApproverEntry storage ae = approvers[getApproverPair(approver_, worker_)];

    if (ae.kind != ApprovePermissionKind.Unknown_0) {
      // there is permission (permanent or temporary) and it isn't delegated
      if (ae.delegatedTo == address(0)) {
        return ae.kind == ApprovePermissionKind.Permanent_1
          ? APPROVER_PERMANENT
          : APPROVER_DELEGATE;
      } else {
        return NOT_APPROVER_DELEGATED;
      }
    }

    ICompanyManager cm = ICompanyManager(IController(_controller()).companyManager());
    return cm.isNatureApprover(approver_, worker_);
 }

  /// @notice Check if the approver has right to approve requests of the worker
  ///         Take into account all explicit and implicit cases:
  ///         permanent and delegated rights, approver WorkerRole and so on.
  function getApproverKind(address approver_, WorkerUid worker_) external view override returns (ApproverKind) {
    return _getApproverKind(approver_, worker_);
  }

  function isApprover(address approver_, WorkerUid worker_) external view returns (bool) {
    return (
    ApproverKind.unwrap(_getApproverKind(approver_, worker_))
    & FLAG_IS_APPROVER // FLAG_IS_APPROVER indicates that this is a valid approver, see the comment to ApproverKind
    ) != 0;
  }

  /// @notice Check if the approver_ is registered approver for the worker_
  ///         it returns true even if the approver has temporary delegated his permission to some delegate
  function isRegisteredApprover(address approver_, WorkerUid worker_) external view returns (bool) {
    ApproverPair aid = getApproverPair(approver_, worker_);
    return approvers[aid].kind != ApprovePermissionKind.Unknown_0;
  }


  // *****************************************************
  // *********** Delegation of approving permissions *****
  // *****************************************************

  /// @notice Approver delegates permanent permission to approve worker requests to the delegate.
  ///         The delegate receives temporary permission to approve worker requests.
  ///         The approver temporary looses a permission to approve the requests of the worker
  ///         until he revokes his permission back from the delegate
  function addDelegation(address approver_, WorkerUid worker_, address delegate_)
  external {
    ICompanyManager cm = ICompanyManager(IController(_controller()).companyManager());
    _onlyPermanentApproverGovernanceOrDepartmentHead(approver_, worker_);

    ApproverPair approverAid = getApproverPair(approver_, worker_);
    ApproverEntry storage ae = approvers[approverAid];

    // this is valid approver
    if (ae.kind == ApprovePermissionKind.Unknown_0) {
      revert ErrorNotApprover(approver_, worker_);
    }
    // he hasn't delegated his permission yet
    if (ae.kind != ApprovePermissionKind.Permanent_1) {
      revert ErrorApprovingReDelegationIsNotAllowed();
    }
    // the delegate still hasn't that permission
    if (ae.delegatedTo != address(0)) {
      revert ErrorThePermissionIsAlreadyDelegated(); // the permission is already delegated
    }

    /// the delegate is not equal to worker or approver
    WorkerUid delegateUid = cm.getWorkerByWallet(delegate_);
    WorkerUid approverUid = cm.getWorkerByWallet(approver_);
    if (!_equalTo(delegateUid, 0)) {
      if (
        _equals(approverUid, delegateUid)  // the delegate is approver
        || _equals(delegateUid, worker_) // the delegate is worker
      ) {
        revert ErrorIncorrectDelegate();
      }
    }

    // the delegate hasn't such permission
    ApproverPair delegateAid = getApproverPair(delegate_, worker_);
    if (approvers[delegateAid].kind != ApprovePermissionKind.Unknown_0) {
      revert ErrorTheDelegateHasSamePermission();
    }

    // register new temporary permission for the delegate
    approvers[delegateAid].kind = ApprovePermissionKind.Delegated_2;

    // we don't need to add new item to _permanentApprovers, we add new temporary item to approvers instead
    // the approver temporary looses has permission to approve worker requests
    ae.delegatedTo = delegate_;

    approverToWorkers[delegate_].push(worker_);
    _deleteWorkerFromApproversToWorkers(approver_, worker_);

    emit OnAddDelegate(worker_, approver_, delegate_);
  }

  /// @notice Approver revokes his permanent permission to approve worker requests from the delegate.
  function revokeDelegation(address approver_, WorkerUid worker_, address delegate_)
  external {
    _onlyPermanentApproverGovernanceOrDepartmentHead(approver_, worker_);

    ApproverPair delegateAid = getApproverPair(delegate_, worker_);
    ApproverEntry storage ae = approvers[getApproverPair(approver_, worker_)];

    // this is valid approver
    if (ae.kind == ApprovePermissionKind.Unknown_0) {
      revert ErrorNotApprover(approver_, worker_);
    }

    // the approver has delegated his permission to the delegate
    if (
      ae.delegatedTo != delegate_
      || approvers[delegateAid].kind == ApprovePermissionKind.Unknown_0
    ) {
      revert ErrorNotDelegated(delegate_, worker_);
    }

    // unregister the temporary permission
    delete approvers[delegateAid];
    // restore back permissions of the approver
    ae.delegatedTo = address(0);

    approverToWorkers[approver_].push(worker_);
    _deleteWorkerFromApproversToWorkers(delegate_, worker_);

    emit OnRevokeDelegate(worker_, approver_, delegate_);
  }

  // *****************************************************
  // ********* Helper function for WorkerUid *************
  // *****************************************************

  function _equals(WorkerUid uid1, WorkerUid uid2) internal pure returns (bool) {
    return WorkerUid.unwrap(uid1) == WorkerUid.unwrap(uid2);
  }
  function _equalTo(WorkerUid uid1, uint64 uid2) internal pure returns (bool) {
    return WorkerUid.unwrap(uid1) == uid2;
  }

  // *****************************************************
  // ****************** Optimization - unchecked *********
  // *****************************************************

  function _uncheckedInc(uint i) internal pure returns (uint) {
  unchecked {
    return i + 1;
  }
  }

  // *****************************************************
  // ******* Helper function for ApproverPair/Kind *******
  // *****************************************************
  function getApproverPair(address approver, WorkerUid worker_) public pure returns (ApproverPair) {
    return ApproverPair.wrap(uint(keccak256(abi.encodePacked(approver, worker_))));
  }

  // *****************************************************
  // *********** Functions instead of modifiers **********
  // Hardhat sometime doesn't parse correctly custom errors,
  // generated inside modifiers.
  // To reproduce the problem see
  //      git: ac9e9769ea2263dfbb741df7c11b8b5e96b03a4b (31.05.2022)
  // So, modifiers are replaced by ordinal functions
  // *****************************************************
  function _onlyPermanentApproverGovernanceOrDepartmentHead(address approver_, WorkerUid workerUid) internal view {
    if (! _isGovernance(msg.sender)
        && !ICompanyManager(IController(_controller()).companyManager()).isDepartmentHead(msg.sender, workerUid)
    ) {
      if (approver_ != msg.sender) {
        revert ErrorAccessDenied(); // you cannot delegate other approver's rights
      }
      ApproverPair aid = getApproverPair(msg.sender, workerUid);
      if (approvers[aid].kind != ApprovePermissionKind.Permanent_1) {
        revert ErrorApproverOrHeadOrGovOnly();
      }
    }
  }

  function _onlyGovernanceOrDepartmentHead(WorkerUid workerUid) internal view {
    if (! _isGovernance(msg.sender)
        && !ICompanyManager(IController(_controller()).companyManager()).isDepartmentHead(msg.sender, workerUid)
    ) {
      revert ErrorGovernanceOrDepartmentHeadOnly();
    }
  }

}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;


import "../controller/Controllable.sol";
import "../../interfaces/IApprovalsManager.sol";

/// @notice Storage for any ApprovalsManager variables
/// @author dvpublic
abstract contract ApprovalsManagerStorage is Initializable
, Controllable
, IApprovalsManager {

  // don't change names or ordering!

  // *****************************************************
  // ******************** Constants **********************
  // *****************************************************

  /// @notice Version of the contract
  /// @dev Should be incremented when contract changed
  string constant public VERSION = "1.0.0";

  /// @notice All flags APPROVER_XXX contains this flag
  ///         to indicate that this approver kind is positive (this is approver)
  ///         Any flags NOT_APPROVER_XXX shouldn't contain 0x1
  uint constant public FLAG_IS_APPROVER = 0x1;
  /// @notice Approver is valid because he is a permanent approver
  ApproverKind constant public APPROVER_PERMANENT = ApproverKind.wrap(FLAG_IS_APPROVER | 0x200000);
  /// @notice Approver is valid because he has delegated permission
  ApproverKind constant public APPROVER_DELEGATE = ApproverKind.wrap(FLAG_IS_APPROVER | 0x400000);
  /// @notice Not approver, because he has delegated his approving permission to some delegate
  ApproverKind constant public NOT_APPROVER_DELEGATED = ApproverKind.wrap(0x800000);


  // *****************************************************
  // ********************* Members ***********************
  // *****************************************************

  /// @notice List of permanent (not temporary!) approvers for the worker
  /// @dev Removing items from the array is inefficient... but that lists should be very short.
  mapping(WorkerUid => address[]) public workersToPermanentApprovers;

  /// @notice All approving permissions: permanent and delegated
  ///         A wallet cannot have both kinds of permissions at the same time.
  ///         IF a permission is delegate, ApproverEntry has reference to the
  ///         approver to whom that permission was delegated.
  mapping(ApproverPair => ApproverEntry) public approvers;

  /// @notice List of all workers
  ///         for which the approver has got explicit permanent or temporary permission
  ///         to approve worker requests.
  mapping(address => WorkerUid[]) public approverToWorkers;


  // *****************************************************
  // ********************* Events ************************
  // *****************************************************

  event OnAddApprover(WorkerUid indexed worker, address approver_);
  event OnRemoveApprover(WorkerUid indexed worker, address approver_);
  event OnAddDelegate(WorkerUid indexed worker, address approver_, address delegate);
  event OnRevokeDelegate(WorkerUid indexed worker, address approver_, address delegate);


  // *****************************************************
  // ************* Lengths for reading mappings **********
  // *****************************************************
  function lengthWorkersToPermanentApprovers(WorkerUid workerUid) external view returns (uint) {
    return workersToPermanentApprovers[workerUid].length;
  }
  function lengthApproverToWorkers(address approver_) external view returns (uint) {
    return approverToWorkers[approver_].length;
  }

  //slither-disable-next-line unused-state
  uint[50] private ______gap;

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