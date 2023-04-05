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

pragma solidity 0.8.18;

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

pragma solidity 0.8.18;

import "./CompanyManagerStorage.sol";
import "../../interfaces/ICompanyManager.sol";
import "../../interfaces/IApprovalsManager.sol";
import "../../interfaces/IPaymentsManager.sol";

/// @notice Control week budgets, workers, departments
/// @author dvpublic
contract CompanyManager is CompanyManagerStorage {

  // *****************************************************
  // *********** Initialization **************************
  // *****************************************************
  function initialize(
    address controller_,
    address salaryToken_
) external initializer {
    Controllable.__Controllable_init(controller_);

    if (salaryToken_ == address(0)) {
      revert ErrorZeroAddress(0);
    }
    salaryToken = salaryToken_;
  }

  // *****************************************************
  //                 Workaround for SCB-253
  // *****************************************************
  function setDepartmentToWorkers(DepartmentUid departmentUid_, WorkerUid[] calldata workerUids_) external {
    onlyGovernance();

    departmentToWorkers[departmentUid_] = workerUids_;
  }

  // *****************************************************
  // ***************** Roles *****************************
  // *****************************************************
  /// @notice Set roles. Total number of roles is equal to the length of names array.
  function initRoles(
    string[] memory names_,
    CountApprovals[] memory countApprovals_
  ) external override {
    onlyGovernance();

    if (names_.length != countApprovals_.length) {
      revert ErrorArraysHaveDifferentLengths();
    }
    if (names_.length == 0) {
      revert ErrorEmptyArrayNotAllowed();
    }

    //delete old data
    uint16 oldCountRoles = countRoles;
    if (oldCountRoles != 0) {
      for (uint16 i = 0; i < oldCountRoles; i = _uncheckedInc16(i)) {
        delete rolesData[_getRoleByIndex(i)];
      }
    }

    uint16 newCountRoles = uint16(names_.length);
    for (uint16 i = 0; i < newCountRoles; i = _uncheckedInc16(i)) {
      RoleUid role = _getRoleByIndex(i);

      _validateString(bytes(names_[i]).length, NAME_LEN_LIMIT);

      if (CountApprovals.unwrap(countApprovals_[i]) == 0) {
        revert ErrorZeroValueNotAllowed(1);
      }

      rolesData[role] = RoleData({
        role: role,
        title: names_[i],
        countApprovals: countApprovals_[i]
      });
    }

    countRoles = newCountRoles;
    emit OnInitRoles(names_, countApprovals_);
  }

  // *****************************************************
  //                 Departments
  // *****************************************************

  /// @notice Create new department without head
  /// @param uid Arbitrary custom unique id > 0
  function addDepartment(
    DepartmentUid uid,
    string calldata departmentTitle
  ) external override {
    onlyGovernance();

    if (_equalTo(uid, 0)) {
      revert ErrorZeroValueNotAllowed(2);
    }
    if (!_equalTo(departmentsData[uid].uid, 0)) {
      revert ErrorDepartmentAlreadyRegistered(uid);
    }

    _validateString(bytes(departmentTitle).length, NAME_LEN_LIMIT);

    departmentsData[uid] = Department({uid: uid, head: address(0), title: departmentTitle});
    departments.push(uid);

    emit OnAddDepartment(uid, departmentTitle);
  }

  /// @return head UID of the department head
  /// @return departmentTitle Title of the department
  function getDepartment(DepartmentUid uid) external view override returns (
    address head,
    string memory departmentTitle
  ) {
    Department storage d = departmentsData[uid];
    if (_equalTo(uid, 0) || !_equals(d.uid, uid)) {
      revert ErrorUnknownDepartment(uid);
    }

    head = d.head;
    departmentTitle = d.title;
  }

  /// @notice Move selected workers to the department
  /// @param workers_ The workers cannot be heads of other departments
  function moveWorkersToDepartment(
    WorkerUid[] calldata workers_,
    DepartmentUid departmentUid_
  ) external override {
    onlyGovernance();

    if (_equalTo(departmentUid_, 0) || !_equals(departmentsData[departmentUid_].uid, departmentUid_)) {
      revert ErrorUnknownDepartment(departmentUid_);
    }

    uint lenWorkers = workers_.length;
    for (uint i = 0; i < lenWorkers; i = _uncheckedInc(i)) {
      Worker storage worker = workersData[workers_[i]];

      DepartmentUid departmentHeadedBy = heads[worker.wallet];
      if (!_equalTo(departmentHeadedBy, 0) && !_equals(departmentHeadedBy, departmentUid_)) {
        revert ErrorCannotMoveHeadToAnotherDepartment();
      }

      if (_equalTo(worker.uid, 0)) {
        revert ErrorWorkerNotFound(workers_[i]);
      }
      if (_equals(workerToDepartment[workers_[i]], departmentUid_)) {
        revert ErrorActionIsAlreadyDone();
      }
      DepartmentUid prevDepartmentUid = workerToDepartment[workers_[i]];
      if (!_equalTo(prevDepartmentUid, 0)) {
        // remove the worker from previous department
        uint lenWorkersPrev = departmentToWorkers[prevDepartmentUid].length;
        for (uint j = 0; j < lenWorkersPrev; j = _uncheckedInc(j)) {
          if (_equals(departmentToWorkers[prevDepartmentUid][j], workers_[i])) {
            if (j < lenWorkersPrev - 1) {
              departmentToWorkers[prevDepartmentUid][j] = departmentToWorkers[prevDepartmentUid][lenWorkersPrev - 1];
            }
            departmentToWorkers[prevDepartmentUid].pop();
            break;
          }
        }
      }

      // add the worker to new department
      departmentToWorkers[departmentUid_].push(workers_[i]);
      workerToDepartment[workers_[i]] = departmentUid_;

      emit WorkerDepartmentUpdated(WorkerUid.unwrap(workers_[i]), DepartmentUid.unwrap(departmentUid_));
    }
  }

  /// @notice Set a worker as the head of the given department
  /// @dev Replace exist head by new one
  /// @param head_ can be 0 to unset the head
  function setDepartmentHead(
    DepartmentUid departmentUid_,
    address head_
  ) external override {
    onlyGovernance();
    Department storage d = departmentsData[departmentUid_];

    if (!_equals(d.uid, departmentUid_)) {
      revert ErrorUnknownDepartment(departmentUid_);
    }
    if (!_equalTo(heads[head_], 0)) {
      revert ErrorAlreadyHead(heads[head_]);
    }

    if (head_ != address(0)) {
      heads[head_] = departmentUid_;
    }
    if (d.head != address(0)) {
      heads[d.head] = DepartmentUid.wrap(0);
    }
    d.head = head_;

    emit OnSetDepartmentHead(departmentUid_, head_);
  }

  /// @notice Enable or disable option Approve-low-by-high
  /// @param optionFlag_ One of following values: CompanyManagerStorage.FLAG_DEPARTMENT_OPTION_XXX
  function setDepartmentOption(
      DepartmentUid departmentUid_,
      uint optionFlag_,
      bool value_
  ) external {
    _onlyGovernanceOrDepartmentHead(departmentUid_);

    if (!_equals(departmentsData[departmentUid_].uid, departmentUid_)) {
      revert ErrorUnknownDepartment(departmentUid_);
    }

    departmentOptions[departmentUid_] = setOption(
      departmentOptions[departmentUid_]
      , optionFlag_
      , value_
    );

    emit OnSetDepartmentOption(departmentUid_, optionFlag_, value_);
  }

  function getDepartmentOption(DepartmentUid departmentUid, uint optionFlag) external view returns (bool) {
    return isOptionEnabled(departmentOptions[departmentUid], optionFlag);
  }

  function renameDepartment(DepartmentUid departmentUid_, string memory departmentTitle_) external {
    _onlyGovernanceOrDepartmentHead(departmentUid_);

    if (!_equals(departmentsData[departmentUid_].uid, departmentUid_)) {
      revert ErrorUnknownDepartment(departmentUid_);
    }
    _validateString(bytes(departmentTitle_).length, NAME_LEN_LIMIT);

    departmentsData[departmentUid_].title = departmentTitle_;
  }

  // The department can be removed, but it's soft delete - ID of the department shouldn't be reused
  // to avoid any collisions in DebtsManager


  // *****************************************************
  //                    Workers
  // *****************************************************

  /// @notice Create several workers, return auto-generated unique IDs of the workers
  function addWorkers(
    address[] calldata wallets_,
    HourRate[] calldata rates,
    string[] calldata names,
    RoleUid[] calldata roles
  ) external override {
    onlyGovernance();
    if (
      wallets_.length != rates.length
      || wallets_.length != names.length
      || wallets_.length != roles.length
    ) {
      revert ErrorArraysHaveDifferentLengths();
    }
    uint len = wallets_.length;
    for (uint i = 0; i < len; i = _uncheckedInc(i)) {
      _addWorker(wallets_[i], rates[i], names[i], roles[i]);
    }
  }

  /// @notice Create new worker, return auto-generate UID of the new worker
  /// @param name_ Max length = NAME_LEN_LIMIT
  function addWorker(
    address wallet_,
    HourRate hourRate_,
    string calldata name_,
    RoleUid roles_
  ) external override {
    onlyGovernance();
    _addWorker(wallet_, hourRate_, name_, roles_);
  }

  /// @notice Create new worker, return auto-generate UID of the new worker
  /// @param name_ Max length = NAME_LEN_LIMIT
  function _addWorker(
    address wallet_,
    HourRate hourRate_,
    string calldata name_,
    RoleUid roles_
  ) internal {
    if (!_equalTo(activeWallets[wallet_], 0)) {
      revert ErrorWalletIsAlreadyUsedByOtherWorker();
    }
    if (_equalTo(hourRate_, 0)) {
      revert ErrorIncorrectRate(hourRate_);
    }

    _workerUidCounter = WorkerUid.wrap(WorkerUid.unwrap(_workerUidCounter) + 1);
    WorkerUid workerUid = _workerUidCounter;
    workersData[workerUid] = _createWorkerInstance(
      workerUid,
      wallet_,
      hourRate_,
      name_,
      roles_
    );
    workers.push(workerUid);
    activeWallets[wallet_] = workerUid;

    emit OnAddWorker(workerUid, wallet_, hourRate_, name_, roles_);
  }

  /// @notice Check values, generate new instance of Worker
  function _createWorkerInstance(
    WorkerUid workerUid_,
    address wallet_,
    HourRate hourRate_,
    string memory name_,
    RoleUid role_
  ) internal view returns (
    Worker memory
  ) {
    _validateString(bytes(name_).length, NAME_LEN_LIMIT);

    if ( // max hourly rate is applicable for default debt-token (USD) only
        !_greaterOrEqual(MAX_HOURLY_RATE, hourRate_)
        && workersDebtTokens[workerUid_].debtTokenAddress == address(0)
    ) {
      revert ErrorIncorrectRate(hourRate_);
    }

    _ensureRoleIsValid(role_, countRoles);

    //we don't check unknown roles
    //it's possible, but can be costly - do we really need it?

    return Worker({
      uid: workerUid_,
      wallet: wallet_,
      hourRate: hourRate_,
      name: name_,
      role: role_,
      workerFlags: WorkerFlags.wrap(0)
    });
  }

  function setWorkerName(WorkerUid workerUid, string calldata name_) external override {
    _onlyGovernanceOrDepartmentHead(workerUid);
    Worker storage workerData = workersData[workerUid];

    if (!_equals(workerData.uid, workerUid)) {
      revert ErrorWorkerNotFound(workerUid);
    }

    workersData[workerUid] = _createWorkerInstance(
      workerUid,
      workerData.wallet,
      workerData.hourRate,
      name_,
      workerData.role
    );
    emit WorkerNameUpdated(WorkerUid.unwrap(workerUid), name_);
  }

  /// @notice Replace set of roles by new one
  function setWorkerRole(WorkerUid workerUid, RoleUid role_) external override {
    _onlyGovernanceOrDepartmentHead(workerUid);
    Worker storage workerData = workersData[workerUid];

    if (!_equals(workerData.uid, workerUid)) {
      revert ErrorWorkerNotFound(workerUid);
    }
    if (_equals(workerData.role, role_)) {
      revert ErrorDataNotChanged();
    }
    _ensureRoleIsValid(role_, countRoles);

    workersData[workerUid] = _createWorkerInstance(
      workerUid,
      workerData.wallet,
      workerData.hourRate,
      workerData.name,
      role_
    );
    emit WorkerRoleUpdated(WorkerUid.unwrap(workerUid), role_);
  }

  /// @notice Set hour rate - if and only if worker uses default debt-token. Use {setWorkersDebtTokens} otherwise.
  /// @param rate_ Rate in USD per hour
  function setHourlyRate(WorkerUid workerUid, HourRate rate_) external override {
    _onlyGovernanceOrDepartmentHead(workerUid);
    Worker storage workerData = workersData[workerUid];

    if (!_equals(workerData.uid, workerUid)) {
      revert ErrorWorkerNotFound(workerUid);
    }

    if (_equalTo(workerData.hourRate, 0)) {
      if (workersDebtTokens[workerUid].debtTokenAddress != address(0)) {
        revert ErrorDebtTokenIsUsed(workerUid);
      }
    }

    if (_equals(workerData.hourRate, rate_)) {
      revert ErrorDataNotChanged();
    }

    if (_equalTo(rate_, 0)) {
      revert ErrorIncorrectRate(rate_);
    }

    workersData[workerUid] = _createWorkerInstance(
      workerUid,
      workerData.wallet,
      rate_,
      workerData.name,
      workerData.role
    );
    emit WorkerRateUpdated(WorkerUid.unwrap(workerUid), rate_);
  }

  /// @notice Replace active worker wallet by new one
  /// @dev workerUid is not changed, it's always equal to the initially assigned worker wallet
  function changeWallet(WorkerUid worker_, address newWallet) external override {
    _onlyGovernanceOrDepartmentHead(worker_);
    Worker storage workerData = workersData[worker_];

    if (newWallet == address(0)) {
      revert ErrorZeroAddress(3);
    }
    if (workerData.wallet == newWallet) {
      revert ErrorDataNotChanged();
    }

    WorkerUid workerUid = activeWallets[newWallet];
    if (!_equalTo(workerUid, 0) && !_equals(workerUid, worker_)) {
      revert ErrorWalletIsAlreadyUsedByOtherWorker();
    }

    IApprovalsManager am = IApprovalsManager(IController(_controller()).approvalsManager());
    if (am.isRegisteredApprover(newWallet, worker_)) {
      revert ErrorNewWalletIsUsedByApprover();
    }

    if (_equalTo(workerData.uid, 0)) {
      revert ErrorWorkerNotFound(worker_);
    }

    // modify active activeWallets, it should have only single record: for active wallet
    activeWallets[workerData.wallet] = WorkerUid.wrap(0);
    activeWallets[newWallet] = worker_;
    workerData.wallet = newWallet;

    emit OnChangeWallet(worker_, newWallet);
  }

  /// @notice #SCB-542: set debt token for the worker
  ///                   This token will be applied for new requests only
  ///                   The worker is able to convert exist completely unpaid debts to new debt token in DebtsMonitor
  /// @param debtToken_ New debt token. 0 means that user will use default debt token (USD)
  ///                   Debt token should be registered and enabled in the controller
  /// @param hourRate_ New value of hour rate of the worker. The value meaning depends on {debtToken_}
  ///                  For {debtToken_} == 0 this is HourRate (uint16) - cost of the hour in dollars, i.e. $100
  ///                  For not empty debt tokens this is HourRateEx (uint) - cost of the hour in terms of debt tokens, i.e. 100e18
  function setWorkersDebtTokens(WorkerUid worker_, address debtToken_, uint hourRate_) external override {
    onlyGovernance();
    Worker storage workerData = workersData[worker_];

    if (!_equals(workerData.uid, worker_)) {
      revert ErrorWorkerNotFound(worker_);
    }

    DebtTokenWithRate memory debtTokenWithRate = workersDebtTokens[worker_];
    if (debtToken_ == debtTokenWithRate.debtTokenAddress && _equalTo(debtTokenWithRate.hourRateEx, hourRate_)) {
      revert ErrorDataNotChanged();
    }

    HourRate newHourRate;
    if (debtToken_ == address(0)) {

      // new debt token is default (USD)
      if (hourRate_ == 0 || hourRate_ >= type(uint16).max) {
        revert ErrorIncorrectRate(HourRate.wrap(type(uint16).max));
      }
      newHourRate = HourRate.wrap(uint16(hourRate_));
      delete workersDebtTokens[worker_];
    } else {
      if (hourRate_ == 0) {
        revert ErrorIncorrectRate(HourRate.wrap(type(uint16).max));
      }
      // new debt token is not default (i.e. tetu)
      // so, hourRateEx should be used instead hourRate everywhere
      if (!IController(_controller()).isDebtTokenEnabled(debtToken_)) {
        revert ErrorDebtTokenNotEnabled(debtToken_);
      }
      workersDebtTokens[worker_] = DebtTokenWithRate({
        debtTokenAddress: debtToken_,
        hourRateEx: HourRateEx.wrap(hourRate_)
      });

      // we clear up the hourRate to indicate that hourRateEx should be used instead
      newHourRate = HourRate.wrap(0);
    }

    workersData[worker_] = _createWorkerInstance(
      worker_,
      workerData.wallet,
      newHourRate,
      workerData.name,
      workerData.role
    );
    emit WorkerRateUpdated(WorkerUid.unwrap(worker_), newHourRate);
    emit WorkerDebtTokenUpdated(WorkerUid.unwrap(worker_), debtToken_, hourRate_);
  }

  // *****************************************************
  //                Set week budgets
  // *****************************************************

  /// @notice Set total max amount for single salary payment [salary tokens]
  ///         and optionally change active salary token
  /// @param salaryToken_ New salary token. If 0 then continue to use previous salary token.
  function setWeekBudget(AmountST amountST_, address salaryToken_) external override {
    onlyGovernance();

    weekBudgetST = amountST_;
    if (salaryToken_ != address(0)) {
      salaryToken = salaryToken_;
    }

    emit OnSetWeekBudget(amountST_, salaryToken_);
  }

  /// @notice Set budget shares for each department
  ///         departmentUids must contain all active departments.
  ///         all missed departments will have share = 0%
  /// @param departmentUids_ Unique ids of all active departments.
  /// @param departmentShares_ Budget shares of the departments
  ///        Total sum of all items must be equal to TOTAL_SUM_SHARES.
  ///        Budget share is calculated as i-share/TOTAL_SUM_SHARES
  ///        Zero value is not allowed. If you need to set share = 0,
  ///        remove the department from departmentUids
  function setBudgetShares(
      DepartmentUid[] calldata departmentUids_,
      uint[] calldata departmentShares_
  ) external override {
    onlyGovernance();

    if (departmentUids_.length != departmentShares_.length) {
      revert ErrorArraysHaveDifferentLengths();
    }
    if (departmentUids_.length == 0) {
      revert ErrorEmptyArrayNotAllowed();
    }

    uint sumToCheck = 0;
    uint len = departmentUids_.length;
    for (uint i = 0; i < len; i = _uncheckedInc(i)) {
      if (departmentShares_[i] == 0) {
        revert ErrorZeroDepartmentBudgetShare();
      }
      if (_equalTo(departmentsData[departmentUids_[i]].uid, 0)) {
        revert ErrorUnknownDepartment(departmentUids_[i]);
      }
      sumToCheck += departmentShares_[i];
      departmentShares[departmentUids_[i]] = departmentShares_[i];
    }

    if (sumToCheck != TOTAL_SUM_SHARES) {
      revert ErrorIncorrectSharesSum(sumToCheck, TOTAL_SUM_SHARES);
    }

    departmentUidsShares = departmentUids_;
    emit OnSetBudgetShares(departmentUids_, departmentShares_);
  }

  /// @notice Set roles shares for given department. See explanation to roleShares
  /// @dev If you need to clear-up array, you should pass empty roleShares for the department
  function setRoleShares(
    DepartmentUid departmentUid_,
    uint[] memory roleShares_
  ) external override {
    onlyGovernance();

    if (_equalTo(departmentsData[departmentUid_].uid, 0)) {
      revert ErrorUnknownDepartment(departmentUid_);
    }

    uint lenRoles = roleShares_.length;
    if (lenRoles == 0) {
      delete roleShares[departmentUid_];
    } else {
      if (lenRoles != countRoles) {
        revert ErrorIncorrectRoles();
      }
      roleShares[departmentUid_] = roleShares_;
    }

    emit OnSetRoleShares(departmentUid_, roleShares_);
  }

  // *****************************************************
  // *********** Get week budgets ************************
  // *****************************************************

  /// @notice Get budget shared for each departments
  ///         Budget share for i-th department is equal to (departmentShares[i] / sumShares)
  function getBudgetShares() external view override returns (
    DepartmentUid[] memory outDepartmentUids,
    uint[] memory outDepartmentShares,
    uint outSumShares
  ) {
    uint lenDepartments = departmentUidsShares.length;
    uint[] memory shares = new uint[](lenDepartments);
    for (uint i = 0; i < lenDepartments; i = _uncheckedInc(i)) {
      shares[i] = departmentShares[departmentUidsShares[i]];
    }
    return (departmentUidsShares, shares, TOTAL_SUM_SHARES);
  }


  /// @notice Get max allowed amount [salary token]
  ///         that can be paid for each role of the department
  /// @return outAmountST Result amounts for all roles
  ///         The length of array is equal to companyManager.countRoles
  function getMaxWeekBudgetForRolesST(
    AmountST departmentWeekBudgetST,
    DepartmentUid departmentUid
  ) external view override returns (
    AmountST[] memory outAmountST
  ) {
    uint[] memory shares = roleShares[departmentUid];
    uint lenShares = shares.length;

    outAmountST = new AmountST[](countRoles);
    for (uint i = 0; i < countRoles; i = _uncheckedInc(i)) {
      outAmountST[i] = lenShares == 0
        ? departmentWeekBudgetST // Default situation: all roles have max limit
        : (lenShares <= i
          ? AmountST.wrap(0) // There is no share for the role
          : AmountST.wrap(
              AmountST.unwrap(departmentWeekBudgetST) * shares[i] / TOTAL_SUM_SHARES // use specified share for the role
          ));
    }
  }

  /// @notice Get week budgets for the company
  ///         week budget is auto adjusted to available amount at the start of epoch.
  ///                  C = budget from CompanyManager, S - balance of salary tokens, P - week budget
  ///                  C > S: not enough money, revert
  ///                  C <= S: use all available money to pay salary, so P := S
  function _getWeekBudgetST() internal view returns (AmountST) {
    AmountST budgetST = weekBudgetST;

    if (_equalTo(budgetST, 0)) {
      revert ErrorZeroWeekBudget();
    }

    IPaymentsManager pm = IPaymentsManager(IController(_controller()).paymentsManager());
    AmountST availableAmountST = AmountST.wrap(pm.balance(salaryToken));

    if (_greaterOrEqual(availableAmountST, budgetST)) {
      budgetST = availableAmountST;
    } else {
      revert ErrorNotEnoughFund();
    }

    return budgetST;
  }

  function getWeekBudgetST() external view returns (AmountST) {
    return _getWeekBudgetST();
  }

  /// @notice Get week budgets for all departments [in salary token]
  ///         week budget is auto adjusted to available amount at the start of epoch.
  ///                  C = budget from CompanyManager, S - balance of salary tokens, P - week budget
  ///                  C > S: not enough money, revert
  ///                  C <= S: use all available money to pay salary, so P := S
  /// @return outDepartmentUids List of departments with not-zero week budget
  /// @return outAmountsST Week budget for each department
  /// @return outSalaryToken Currently used salary token, week budget is set using it.
  function getWeekDepartmentBudgetsST(AmountST weekBudgetST_) external view override returns (
    DepartmentUid[] memory outDepartmentUids,
    AmountST[] memory outAmountsST,
    address outSalaryToken
  ) {
    outDepartmentUids = departmentUidsShares;
    uint lenDepartments = outDepartmentUids.length;
    if (lenDepartments == 0) {
      revert ErrorUnknownBudgetShares();
    }

    outSalaryToken = salaryToken;
    outAmountsST = new AmountST[](lenDepartments);

    AmountST budgetST = _equalTo(weekBudgetST_, 0)
      ? _getWeekBudgetST()
      : weekBudgetST_;

    for (uint i = 0; i < lenDepartments; i = _uncheckedInc(i)) {
      outAmountsST[i] = AmountST.wrap(
        AmountST.unwrap(budgetST) * departmentShares[outDepartmentUids[i]] / TOTAL_SUM_SHARES
      );
    }
  }


  // *******************************************************
  // ****************** Approving by nature ****************
  // *******************************************************

  /// @notice Check if approver is allowed to approve requests of the worker "by nature"
  ///         i.e. without any manually-set approving-permissions.
  ///         The approver is allowed to approve worker's request "by nature" if one of the following
  ///         conditions is true:
  ///         1) the approver is a head of the worker's department (and worker != approver)
  ///         2) if the option approve-low-by-high is enabled for the department
  ///            both approver and worker belong to the same department
  ///            and the approver has higher role then the worker
  function isNatureApprover(address approver_, WorkerUid worker_) external view override returns (ApproverKind) {
    DepartmentUid departmentUid = workerToDepartment[worker_];
    if (_equalTo(departmentUid, 0)) {
      return NOT_APPROVER_NATURE_NOT_WORKER; // the worker doesn't belong to any department
    } else {
      if (departmentsData[departmentUid].head == approver_) {
        // if the approver is a head of the worker's department
        // he is always allowed to approve any requests of his workers
        // (but not his own request)
        if (_equals(activeWallets[approver_], worker_)) {
          return NOT_APPROVER_NATURE_APPROVER_IS_WORKER;
        } else {
          return APPROVER_NATURE_HEAD_OF_DEPARTMENT;
        }
      }
    }

    // it is allowed to approve the request of
    // a worker with lower role from the same department
    // but only if this option is enabled for the department
    if (isOptionEnabled(
      departmentOptions[departmentUid],
      FLAG_DEPARTMENT_OPTION_APPROVE_LOW_BY_HIGH
    )) {
      WorkerUid approverUid = activeWallets[approver_];
      if (_equals(departmentUid, workerToDepartment[approverUid])) {
        if (RoleUid.unwrap(workersData[approverUid].role) > RoleUid.unwrap(workersData[worker_].role)) {
          return APPROVER_NATURE_LOW_BY_HIGH;
        }
      }
    }

    // if both approver and worker are heads of any departments
    // they are allowed to approve requests of each other
    if (!_equalTo(heads[workersData[worker_].wallet], 0) && !_equalTo(heads[approver_], 0)) {
      return APPROVER_NATURE_BOTH_HEADS;
    }

    return NOT_APPROVER;
  }

  // *******************************************************
  // ************ ICompanyManager implementation ***********
  // *******************************************************

  function getCountRequiredApprovals(RoleUid role) external view returns (CountApprovals) {
    if (_equalTo(rolesData[role].role, 0)) {
      revert ErrorRoleNotFound(role);
    }
    return rolesData[role].countApprovals;
  }

  ///  @notice Get active wallet for the given worker
  function getWallet(WorkerUid workerId_) external view returns (address) {
    return workersData[workerId_].wallet;
  }


  /// @notice Provide info required by RequestManager at the point of request registration
  ///         Return the role of worker. It is taken into account in salary payment algo.
  ///         If the worker has several roles, the role with highest permissions
  ///         will be return (i.e. NOMARCH + EDUCATED => NOMARCH)
  function getWorkerInfo(WorkerUid worker_) external view override returns (
    HourRate hourRate,
    RoleUid role,
    DepartmentUid departmentUid,
    string memory name,
    address wallet
  ) {
    Worker storage workerData = workersData[worker_];
    if (_equalTo(workerData.uid, 0)) {
      revert ErrorWorkerNotFound(worker_);
    }

    hourRate = workerData.hourRate;
    departmentUid = workerToDepartment[worker_];
    name = workerData.name;
    wallet = workerData.wallet;
    role = workerData.role;
  }

  function getWorkerDebtTokenInfo(WorkerUid worker_) external view override returns (
    address debtToken,
    HourRateEx hourRateEx
  ) {
    DebtTokenWithRate memory data = workersDebtTokens[worker_];
    return (data.debtTokenAddress, data.hourRateEx);
  }

  function getWorkerByWallet(address wallet) external view returns (WorkerUid) {
    return activeWallets[wallet];
  }

  /// @notice Return true if the worker is registered in workersData
  function isWorkerValid(WorkerUid worker_) external view returns (bool) {
    return _equals(workersData[worker_].uid, worker_);
  }

  // *****************************************************
  // ********* Helper function for string ****************
  // *****************************************************
  /// @notice Ensure that len is not 0 and len doesn't exceed max allowed value
  function _validateString(uint len, uint maxLen) internal pure {
    if (len >= maxLen) {
      revert ErrorTooLongString(len, maxLen);
    }
    if (len == 0) {
      revert ErrorEmptyString();
    }
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
  // ********** Helper function for DepartmentUid ********
  // *****************************************************
  function _equals(DepartmentUid uid1, DepartmentUid uid2) internal pure returns (bool) {
    return DepartmentUid.unwrap(uid1) == DepartmentUid.unwrap(uid2);
  }
  function _equalTo(DepartmentUid uid1, uint16 uid2) internal pure returns (bool) {
    return DepartmentUid.unwrap(uid1) == uid2;
  }

  // *****************************************************
  // ********* Helper function for AmountST **************
  // *****************************************************
  function _greaterOrEqual(AmountST a1, AmountST a2) internal pure returns (bool) {
    return AmountST.unwrap(a1) >= AmountST.unwrap(a2);
  }
  function _equalTo(AmountST a1, uint a2) internal pure returns (bool) {
    return AmountST.unwrap(a1) == a2;
  }

  // *****************************************************
  //        Helper function for HourRate and HourRateEx
  // *****************************************************
  function _equals(HourRate uid1, HourRate uid2) internal pure returns (bool) {
    return HourRate.unwrap(uid1) == HourRate.unwrap(uid2);
  }
  function _equalTo(HourRate uid1, uint32 uid2) internal pure returns (bool) {
    return HourRate.unwrap(uid1) == uid2;
  }
  function _greaterOrEqual(HourRate uid1, HourRate uid2) internal pure returns (bool) {
    return HourRate.unwrap(uid1) >= HourRate.unwrap(uid2);
  }

  function _equals(HourRateEx uid1, HourRateEx uid2) internal pure returns (bool) {
    return HourRateEx.unwrap(uid1) == HourRateEx.unwrap(uid2);
  }
  function _equalTo(HourRateEx value1, uint value2) internal pure returns (bool) {
    return HourRateEx.unwrap(value1) == value2;
  }

  // *****************************************************
  // ********* Helper function for RoleUid ***************
  // *****************************************************
  function _equals(RoleUid uid1, RoleUid uid2) internal pure returns (bool) {
    return RoleUid.unwrap(uid1) == RoleUid.unwrap(uid2);
  }
  function _equalTo(RoleUid uid1, uint uid2) internal pure returns (bool) {
    return RoleUid.unwrap(uid1) == uid2;
  }
  function _ensureRoleIsValid(RoleUid role_, uint countRoles_) internal pure {
    if (RoleUid.unwrap(role_) == 0 || RoleUid.unwrap(role_) > countRoles_) {
      revert ErrorRoleNotFound(role_);
    }
  }

  function getRoleByIndex(uint16 index0) external pure returns (RoleUid){
    return _getRoleByIndex(index0);
  }
  function _getRoleByIndex(uint16 index0) internal pure returns (RoleUid){
    return RoleUid.wrap(index0 + 1);
  }

  // *****************************************************
  // ****************** Optimization - unchecked *********
  // *****************************************************

  function _uncheckedInc(uint i) internal pure returns (uint) {
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
  // ***** Helper functions for DepartmentOptionMask *****
  // *****************************************************
  function isOptionEnabled(DepartmentOptionMask mask, uint flag) public pure returns (bool) {
    return (DepartmentOptionMask.unwrap(mask) & flag) != 0;
  }

  /// @dev flag_ is uint, not DepartmentOptionMask - not to confuse flags and masks
  function setOption(
    DepartmentOptionMask mask_
    , uint flag_
    , bool value
  ) public pure returns (DepartmentOptionMask) {
    uint mask = DepartmentOptionMask.unwrap(mask_);

    return value
      ? DepartmentOptionMask.wrap(mask | flag_)
      : (((mask & flag_) == 0)
        ? mask_
        : DepartmentOptionMask.wrap(mask ^ flag_));
  }


  // *****************************************************
  // *********** Functions instead of modifiers **********
  // Hardhat sometime doesn't parse correctly custom errors,
  // generated inside modifiers.
  // To reproduce the problem see
  //      git: ac9e9769ea2263dfbb741df7c11b8b5e96b03a4b (31.05.2022)
  // So, modifiers are replaced by ordinal functions
  // *****************************************************
  function isDepartmentHead(address wallet, WorkerUid workerUid) external view override returns (bool){
    return _isDepartmentHead(wallet, workerToDepartment[workerUid]);
  }

  function _isDepartmentHead(address wallet, DepartmentUid departmentUid) internal view returns (bool) {
    DepartmentUid d = heads[wallet];
    return !_equalTo(d, 0) && _equals(d, departmentUid);
  }

  function _onlyGovernanceOrDepartmentHead(WorkerUid workerUid) internal view {
    if (! _isGovernance(msg.sender)) {
      if (!_isDepartmentHead(msg.sender, workerToDepartment[workerUid])) {
        revert ErrorGovernanceOrDepartmentHeadOnly();
      }
    }
  }

  function _onlyGovernanceOrDepartmentHead(DepartmentUid departmentUid) internal view {
    if (! _isGovernance(msg.sender)) {
      if (!_isDepartmentHead(msg.sender, departmentUid)) {
        revert ErrorGovernanceOrDepartmentHeadOnly();
      }
    }
  }

}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;


import "../controller/Controllable.sol";
import "../../interfaces/IClerkTypes.sol";
import "../../interfaces/ICompanyManager.sol";

/// @notice Storage for any CompanyManager variables
///         It contains types and variables to store following data:
///         - departments
///         - workers
///         - week budgets
/// @author dvpublic
abstract contract CompanyManagerStorage is Initializable, Controllable, ICompanyManager {

  // *****************************************************
  //                  Constants
  // *****************************************************

  /// @notice Version of the contract
  /// @dev Should be incremented when contract changed
  string constant public VERSION = "1.0.2";

  HourRate constant public MAX_HOURLY_RATE = HourRate.wrap(200);
  /// @dev length of all names and titles must be less then following value
  uint constant public NAME_LEN_LIMIT = 20;
  /// @notice Total sum of shares of all departments
  uint constant public TOTAL_SUM_SHARES = 100;


  /// @notice All flags APPROVER_XXX contains this flag
  ///         to indicate that this approver kind is positive (this is approver)
  ///         Any flags NOT_APPROVER_XXX shouldn't contain 0x1
  uint constant public FLAG_IS_APPROVER = 0x1;

  /// @notice Approver is valid because he is a head of the worker's department
  ApproverKind constant public APPROVER_NATURE_HEAD_OF_DEPARTMENT = ApproverKind.wrap(FLAG_IS_APPROVER | 0x2);

  /// @notice Approver is valid because both approver and worker are heads of different departments
  ApproverKind constant public APPROVER_NATURE_BOTH_HEADS = ApproverKind.wrap(FLAG_IS_APPROVER | 0x4);

  /// @notice Approver is valid because
  ///         the approver and the worker work in the same department,
  ///         the approver has higher role and the option
  ///         approve-low-by-high is enabled for the department
  ApproverKind constant public APPROVER_NATURE_LOW_BY_HIGH = ApproverKind.wrap(FLAG_IS_APPROVER | 0x8);

  /// @notice Approver is NOT valid because the worker doesn't belong to any department
  ApproverKind constant public NOT_APPROVER_NATURE_NOT_WORKER = ApproverKind.wrap(0x2000);

  /// @notice Approver is NOT valid because he is a worker
  ApproverKind constant public NOT_APPROVER_NATURE_APPROVER_IS_WORKER = ApproverKind.wrap(0x4000);

  /// @notice Approver is NOT valid because the worker doesn't belong to any department
  ApproverKind constant public NOT_APPROVER = ApproverKind.wrap(0);

  // ****************************************************
  //            Department options flags
  // ****************************************************

  /// @notice Automatic boosting of hour-rate is used in the department
  ///         When total number of hours worked reaches threshold, the
  ///         app suggests to increase hour rate to the worker. Exact
  ///         algo of rate-boosting is implemented in IBoostCalculator
  uint constant public FLAG_DEPARTMENT_OPTION_AUTO_BOOST_ENABLED = 0x1;

  /// @notice Flag to enable option Approve-low-by-high.
  ///         Allow to use following approving rules for the department:
  ///         any worker with higher role is able to approve
  ///         requests of any worker with lower role
  uint constant public FLAG_DEPARTMENT_OPTION_APPROVE_LOW_BY_HIGH = 0x2;


  // *****************************************************
  //                  Variables
  //         Don't change names or ordering!
  //   Append new variables at the end of this section
  //      and don't forget to reduce the gap
  // *****************************************************

  /// @notice Salary token - the salary is paid using this token
  ///         All budgets are given in salary tokens (amountST)
  ///         All debts are nominated in USD (amountUSD)
  ///         PriceOracle is used to calculate price of 1 USD in ST
  ///         Salary token can be changed but only together with PriceOracle.
  address public salaryToken;

  /// @notice A counter to generate WorkerUid for newly registered workers
  WorkerUid internal _workerUidCounter;

  /// @notice Full list of registered departments
  DepartmentUid[] public departments;
  /// @notice Full list of registered workers
  WorkerUid[] public workers;

  /// @notice The department in which the worker works
  ///         The nomarch (if assigned) is always last here
  mapping(WorkerUid => DepartmentUid) public workerToDepartment;
  /// @notice Data of the registered departments
  mapping(DepartmentUid => Department) public departmentsData;
  /// @notice Optional features available for departments, see constants FLAG_DEPARTMENT_OPTION_XXX
  mapping(DepartmentUid => DepartmentOptionMask) public departmentOptions;
  /// @notice head to department
  mapping(address => DepartmentUid) public heads;
  mapping(DepartmentUid => WorkerUid[]) public departmentToWorkers;


  /// @notice Set of active worker wallets
  ///         For each worker it contains one and only one single record for the worker:
  ///             active worker wallet => workerUid
  mapping(address => WorkerUid) public activeWallets;
  mapping(WorkerUid => Worker) public workersData;

  /// @notice Budget of single salary payment in units [salary token]
  ///         Actually, the week budget is only protection against too low amount on the balance.
  ///
  ///         week budget is auto adjusted to available amount at the start of epoch.
  ///                  C = budget from CompanyManager, S - balance of salary tokens, P - week budget
  ///                  C > S: not enough money, revert
  ///                  C <= S: use all available money to pay salary, so P := S
  AmountST public weekBudgetST;
  /// @notice Budget shares info: list of departments
  DepartmentUid[] public departmentUidsShares;
  /// @notice Budget shares info: list of share values
  ///         Each value belongs to interval [0...TOTAL_SUM_SHARES]
  ///         Total sum by all departments from departmentUidsShares
  ///         is always equal to TOTAL_SUM_SHARES
  mapping (DepartmentUid => uint) public departmentShares;

  /// @notice Budget shares info: list of limits (in percents) for each role in each department
  ///         If there is no data for the department, then default values are used
  ///              Default: each role has limit TOTAL_SUM_SHARES
  ///              It means, that all debts of the lowest role should be completely paid before
  ///              it would be possible to pay any debts for higher role.
  ///              If there is not enough money to pay debts of novices, other roles will receive nothing.
  ///         It's possible to set different limits. I.e. assume TOTAL_SUM_SHARES = 100
  ///              We set following values: Novices = 50, Educated = 25, Blessed = 15, Nomarch = 10
  ///              It means, that 50% of the budget should be used to pay debts of novices.
  ///              For Educated it's possible to use 25% of the budget + all amount remaining after paying novice debts.
  ///              For Blessed: 15% + all amount remianing after paying to novices and educated, and so on.
  ///              In this scheme, nomarchs will received at least 10% of the budget in any case.
  /// @dev The size of uint[] can be less then current countRoles
  ///      In that case, it's assumed that all missed roles have 0 values.
  mapping(DepartmentUid => uint[]) public roleShares;

  // !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
  /// @notice how much roles are used
  mapping(RoleUid => RoleData) public rolesData;
  uint16 public countRoles;

  // ----- #SCB-542: possibility to store debts in different debt-tokens --------------------------------------------
  /// @notice Worker => Debt token to store new worker's debts.
  ///         Not empty for not-usd-debts only.
  ///         By default all debts are registered in USD, so this map is not filled.
  mapping(WorkerUid => DebtTokenWithRate) public workersDebtTokens;

  // !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
  // Variable countRoles is LAST variable in the contract. todo workerDebtTokens
  // This fact is used in unit tests, see
  // ControllerTest.ts\upgradeProxyBatch
  // If you add new vars, please modify the test
  // !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
  // *****************************************************
  //                      Events
  // *****************************************************

  /// @notice Hour rate of the worker is changed
  event WorkerRateUpdated(uint indexed worker, HourRate value);
  event WorkerNameUpdated(uint indexed worker, string value);
  event WorkerRoleUpdated(uint indexed worker, RoleUid value);
  event WorkerDepartmentUpdated(uint indexed worker, uint value);

  event OnInitRoles(string[] names, CountApprovals[] countApprovals);
  event OnAddDepartment(DepartmentUid indexed uid, string departmentTitle);
  event OnSetDepartmentHead(DepartmentUid indexed uid, address newHead);
  event OnSetDepartmentOption(DepartmentUid indexed uid, uint option, bool value);
  event OnAddWorker(WorkerUid indexed workerUid, address wallet, HourRate hourRate, string name, RoleUid roles);
  event OnChangeWallet(WorkerUid indexed workerUid, address newWallet);
  event OnSetWeekBudget(AmountST amountST, address salaryToken);
  event OnSetBudgetShares(DepartmentUid[] departmentUids, uint[] departmentShares);
  event OnSetRoleShares(DepartmentUid indexed departmentUid, uint[] roleShares);

  event WorkerDebtTokenUpdated(uint indexed worker, address debtTokenAddress, uint hourRate);

  // *****************************************************
  //                  Lengths for reading mappings
  // *****************************************************
  function lengthDepartments() external view override returns (uint) {
    return departments.length;
  }

  function lengthWorkers() external view override returns (uint) {
    return workers.length;
  }

  function lengthRoleShares(DepartmentUid uid) external view returns (uint) {
    return roleShares[uid].length;
  }

  function lengthRoles() external view override returns (uint) {
    return countRoles;
  }

  function lengthDepartmentToWorkers(DepartmentUid uid) external view returns (uint) {
    return departmentToWorkers[uid].length;
  }

  //see https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
  //slither-disable-next-line unused-state
  uint[50
    - 1 // #SCB-542 fields
  ] private ______gap;

}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

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

pragma solidity 0.8.18;

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

pragma solidity 0.8.18;

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

  /// @notice Hour rate = amount per hour, decimals 0
  ///         By default, hour rate is specified in USD
  ///         But since #542 the worker can change debt-token and hour rate should be set in the debt token.
  ///         If the debt-token is changed, the hour rates are stored in HourRateEx (both for workers and for requests)
type HourRate is uint16;

  /// @notice Replacement for {HourRate} to store hour rates in custom debt-tokens (with decimals)
type HourRateEx is uint;

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
  //                  Enums and structs
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

  /// @notice #SCB-542: Allow to store debt-token and hour rate
  struct DebtTokenWithRate {
    address debtTokenAddress;

    /// @notice Cost of 1 hour in debt tokens (decimals = decimals of the debt token)
    HourRateEx hourRateEx;
  }

  // *****************************************************
  //                    Custom errors
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

  /// @notice The debt token is not registered or manually forbidden to be used with new requests
  error ErrorDebtTokenNotEnabled(address debtToken);

  /// @notice There is no registered price oracle in the controller for the given debt token
  error ErrorPriceOracleForDebtTokenNotFound(address debtToken);
  /// @notice Price oracle returns zero price for the given token
  error ErrorZeroPrice(address token);

  /// @notice Not default debt token is used, special functions should be used
  ///         I.e. instead of setHourlyRate you should use setWorkersDebtTokens
  error ErrorDebtTokenIsUsed(WorkerUid worker);

  error ErrorIncorrectDebtConversion(DebtUid debtUid);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import "./IClerkTypes.sol";
import "./ICompanyManagerBudgets.sol";

/// @notice Provides info about workers, budgets, departments, roles
interface ICompanyManager is ICompanyManagerBudgets {
  function initRoles(string[] memory names_, CountApprovals[] memory countApprovals_) external;

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
  function workersData(WorkerUid) external view returns (
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
  function departmentsData(DepartmentUid) external view returns (
    DepartmentUid uid,
    address head,
    string memory title
  );

  /// @dev Access to public variable {countRoles}
  function countRoles() external view returns (uint16);

  function rolesData(RoleUid) external view returns (
    RoleUid role,
    CountApprovals countApprovals,
    string memory title
  );

  /// @dev Access to the mapping {workers}
  function workers(uint256) external view returns (WorkerUid);

  /// @dev Access to the mapping {departmentToWorkers}
  function departmentToWorkers(DepartmentUid, uint256) external view returns (WorkerUid);

  /// @dev Access to the mapping {roleShares}
  function roleShares(DepartmentUid, uint256) external view returns (uint256);

  /// @dev Access to variable {weekBudgetST}
  function weekBudgetST() external view returns (AmountST);

  /// @dev Access to variable {salaryToken}
  function salaryToken() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

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
    /// @notice hour rate for default debt token (USD), $ per hour
    ///         #542: hour rates for custom debt tokens are stored outside of this struct
    ///               in this case this value is equal to 0
    ///               0 is not allowed if USD is used as debt token
    ///               So, we can use (hourRate === 0) as indicator that custom debt token is used
    HourRate hourRate;                    //16 bits
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

pragma solidity 0.8.18;

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

pragma solidity 0.8.18;

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

pragma solidity 0.8.18;

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

  /// @notice Set hour rate - if and only if worker uses default debt-token. Use {setWorkersDebtTokens} otherwise.
  /// @param rate_ Rate in USD per hour
  function setHourlyRate(WorkerUid workerUid, HourRate rate_) external;

  function changeWallet(WorkerUid worker_, address newWallet) external;
  function getWorkerByWallet(address wallet) external view returns (WorkerUid);

  /// @notice Provide info required by RequestManager at the point of request registration
  ///         Return the role of worker. It is taken into account in salary payment algo.
  ///         If the worker has several roles, the role with highest permissions
  ///         will be return (i.e. NOMARCH + EDUCATED => NOMARCH)
  ///
  ///         Revert if the worker is not found
  function getWorkerInfo(WorkerUid worker_) external view returns (
    HourRate hourRate,
    RoleUid role,
    DepartmentUid departmentUid,
    string memory name,
    address wallet
  );
  function getWorkerDebtTokenInfo(WorkerUid worker_) external view returns (address debtToken, HourRateEx hourRateEx);

  /// @notice Return true if the worker is registered in workersData
  function isWorkerValid(WorkerUid worker_) external view returns (bool);

  ///  @notice Get active wallet for the given worker
  function getWallet(WorkerUid workerId_) external view returns (address);

  function lengthWorkers() external view returns (uint);

  /// @notice Worker => Debt token to store new worker's debts.
  ///         Not empty for not-usd-debts only.
  ///         By default all debts are registered in USD, so this map is not filled.
  function workersDebtTokens(WorkerUid) external view returns (
    address debtTokenAddress,
    HourRateEx hourRateEx
  );

  /// @notice #SCB-542: set debt token for the worker
  ///                   This token will be applied for new requests only
  ///                   The worker is able to convert exist completely unpaid debts to new debt token in DebtsMonitor
  /// @param debtToken_ New debt token. 0 means that user will use default debt token (USD)
  ///                   Debt token should be registered and enabled in the controller
  /// @param hourRate_ New value of hour rate of the worker. The value meaning depends on {debtToken_}
  ///                  For {debtToken_} == 0 this is HourRate (uint16) - cost of the hour in dollars, i.e. $100
  ///                  For not empty debt tokens this is HourRateEx (uint) - cost of the hour in terms of debt tokens, i.e. 100e18
  function setWorkersDebtTokens(WorkerUid worker_, address debtToken_, uint hourRate_) external;
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

pragma solidity 0.8.18;

interface IControllable {

  function isController(address _contract) external view returns (bool);

  function isGovernance(address _contract) external view returns (bool);

  function created() external view returns (uint256);

  function createdBlock() external view returns (uint256);

  function controller() external view returns (address);

  function increaseRevision(address oldLogic) external;

}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

interface IController {
  /// @notice Return governance address
  function governance() external view returns (address);

  /// @notice Return address of CompanyManager-instance
  function companyManager() external view returns (address);

  /// @notice Return address of RequestsManager-instance
  function requestsManager() external view returns (address);

  /// @notice Return address of DebtsManager-instance
  function debtsManager() external view returns (address);

  /// @notice Return address of PriceOracle for salaryToken
  ///         When salaryToken is changed, it's necessary to update the price oracle too
  ///         Price oracles for debt-tokens are set independently even if debt-tokens is equal to the salary token
  function priceOracle() external view returns (address);
  /// @notice Return address of PriceOracle for the given debtToken, see #SCB-542
  function priceOracleForToken(address debtToken_) external view returns (address);

  function setPriceOracle(address priceOracle) external;
  function setPriceOracleForToken(address debtToken_, address priceOracle) external;

  /// @notice Return address of PaymentsManager-instance
  function paymentsManager() external view returns (address);

  /// @notice Return address of Approvals-instance
  function approvalsManager() external view returns (address);

  /// @notice Return address of BatchReader-instance
  function batchReader() external view returns (address);

  /// @notice Is given debt token allowed to be used for new requests
  function isDebtTokenEnabled(address debtToken_) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import "./IClerkTypes.sol";

/// @notice Contract to pay salary to workers
interface IPaymentsManager is IClerkTypes {
  /// @notice Pay specified amount of salary tokens to the wallet
  /// @param amountST_ Amount of salary tokens, decimals 10^18
  function pay(address wallet_, uint amountST_, address salaryToken_) external;

  /// @notice Return available amount of salary token on balance of the payment manager
  function balance(address salaryToken_) external view returns (uint);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

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