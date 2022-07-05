// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./DebtsManagerStorage.sol";
import "../../interfaces/ICompanyManager.sol";
import "../../interfaces/IPaymentsManager.sol";
import "../../interfaces/IRequestsManager.sol";
import "../../interfaces/IApprovalsManager.sol";
import "../../interfaces/IPriceOracle.sol";

/// @notice Manage list of epochs and company-debts
///         Controller registers debts on the base of provided requests.
///         Debts are stored in the list of debts.
///         There is separate list of debts for each pair (department, role).
///         All debts from the list are paid one by one in order of registration. A debt can be paid in several pays.
///         To pay salary, controller grabs as many as possible debts for each (department, role)
///         Tne number of debts allowed to be paid is limited by max total sum for (department, role).
/// @author dvpublic
contract DebtsManager is DebtsManagerStorage {

  // *****************************************************
  // *********** Initialization **************************
  // *****************************************************

  function initialize(address controller_, EpochType firstEpoch_) external initializer {
    Controllable.__Controllable_init(controller_);
    firstEpoch = firstEpoch_;
    currentEpoch = firstEpoch_;
  }

  // *****************************************************
  // **************** Requests ***************************
  // *****************************************************

  /// @notice Register new request with status "Registered"
  function addRequest(
      RequestUid requestUid_
    , WorkerUid workerUid_
    , uint32 countHours_
    , string calldata descriptionUrl_
  ) external
  override // IDebtsManager
  {
    _onlyRequestsManager();
    (HourRate hourRate, RoleUid role, DepartmentUid departmentUid,, )
      = ICompanyManager(IController(_controller()).companyManager())
          .getWorkerInfo(workerUid_); // revert if the worker is not found

    if (_equalTo(requestUid_, 0)) {
      revert ErrorZeroValueNotAllowed(1);
    }

    if (countHours_ == 0) {
      revert ErrorZeroValueNotAllowed(2);
    }

    //it's not allowed to update request params if there is registered debt for the request
    if (!_equalTo(requestsToDebts[requestUid_], 0)) {
      revert ErrorDebtAlreadyRegistered(requestUid_);
    }

    requestsData[requestUid_] = RequestData({
      worker: workerUid_
      , role: role
      , department: departmentUid
      , hourRate: hourRate
      , countHours: countHours_
      , descriptionUrl: descriptionUrl_
      , epoch: currentEpoch
    });

    RoleUid maxRole = maxRoleValueInAllTimes;
    if (RoleUid.unwrap(maxRole) < RoleUid.unwrap(role)) {
      maxRoleValueInAllTimes = role;
    }
  }


  // *****************************************************
  // *************** Debts *******************************
  // *****************************************************

  /// @notice Convert salary-amount of accepted request to company-debt
  ///         Amount of the debt is auto calculated using requests properties: countHours * hourRate
  function addDebt(
    RequestUid requestUid_
  ) external
  override // IDebtsManager
  {
    _onlyRequestsManager();

    RequestData storage rd = requestsData[requestUid_];

    if (WorkerUid.unwrap(rd.worker) == 0) {
      revert ErrorUnknownRequest(requestUid_); // we can check existence of the request by not 0 worker
    }

    if (DebtUid.unwrap(requestsToDebts[requestUid_]) != 0) {
      revert ErrorDebtAlreadyRegistered(requestUid_);
    }

    // generate new debt-uid
    debtUidCounter = DebtUid.wrap(DebtUid.unwrap(debtUidCounter) + 1);
    DebtUid debtUid = debtUidCounter;

    // calculate salary amount in USD
    AmountUSD amountUSD = getAmountUSD(uint64(HourRate.unwrap(rd.hourRate) * rd.countHours));

    // register new department if necessary (add it to departments-array)
    if (NullableValue64.unwrap(registeredDepartments[rd.department]) == 0) {
      registeredDepartments[rd.department] = _wrapToNullableValue64(uint64(departments.length));
      departments.push(rd.department);
    }

    // add the debt to the list of department's debts
    RoleDebts storage roleDebts = roleDebts[rd.department][rd.role];
    uint64 indexNewDebt = roleDebts.totalCountDebts;
    roleDebts.totalCountDebts = indexNewDebt + 1;
    roleDebts.amountUnpaidTotalUSD = addUSD(roleDebts.amountUnpaidTotalUSD, amountUSD);

    roleDebtsList[rd.department][rd.role][_wrapToNullableValue64(indexNewDebt)] = debtUid;

    debtsToRequests[debtUid] = requestUid_;
    requestsToDebts[requestUid_] = debtUid;
    unpaidAmountsUSD[debtUid] = amountUSD;

    WorkerStat storage ws = statForWorkers[rd.worker];
    ws.workedHours = ws.workedHours + rd.countHours;
    ws.earnedDollars = addUSD(ws.earnedDollars, amountUSD);

    emit OnCreateDebt(debtUid, rd.worker);
  }

  /// @notice Revoke previously created debt
  ///         As result, we can have holes in the sequence of registered debts
  function revokeDebtForRequest(
    RequestUid requestUid_
  ) external {
    _onlyRequestsManager();

    DebtUid debtUid = requestsToDebts[requestUid_];

    if (_equalTo(debtUid, 0)) {
      revert ErrorRequestHasNoDebt();
    }

    RequestData storage rd = requestsData[requestUid_];

    AmountUSD amountUSD = unpaidAmountsUSD[debtUid];

    if (! _equals(requestUid_
      , IRequestsManager(IController(_controller()).requestsManager()).getRequestUid(currentEpoch, rd.worker)
    )) {
      revert ErrorDebtIsNotRevocable(debtUid);
    }

    requestsToDebts[requestUid_] = DebtUid.wrap(0);
    debtsToRequests[debtUid] = RequestUid.wrap(0);
    unpaidAmountsUSD[debtUid] = getAmountUSD(0);

    RoleDebts storage rds = roleDebts[rd.department][rd.role];
    rds.amountUnpaidTotalUSD = subUSD(rds.amountUnpaidTotalUSD, amountUSD);

    WorkerStat storage ws = statForWorkers[rd.worker];
    statForWorkers[rd.worker] = WorkerStat({
      workedHours: ws.workedHours - rd.countHours,
      earnedDollars: subUSD(ws.earnedDollars, amountUSD)
    });

    emit OnRevokeDebt(debtUid, rd.worker);

    // we don't modify roleDebtsList
    // it will still contain index of the revoked debt
    // it's not a problem - such debt will be just ignored during paying
    // because the debt is actually unregistered in debtsToRequests
  }

  // *****************************************************
  // ************ Internal pay functions *****************
  // *****************************************************
  // Example, partial payment:
  //         For a pair (department, role) we have following debts:
  //             d1, d2, d3, d4, d5, d6
  //                 ^ first unpaid payment
  //         After the finish of the payment we should have:
  //             d1, d2, d3, d4, d5, d6
  //                             ^ first unpaid (incompletely paid) payment
  //         where
  //             sum(d2, d3, d4, d5*) = maxSumAmountUSD
  //             d5* < d5 (partial pay)
  //         output
  //             outCountItems = 4
  //             outWallets = [wallet2, wallet3, wallet4, wallet5, 0]
  //             outAmountsST = [d2, d3, d4, d5*, 0]
  //         The arrays has length 5 (count of initially unpaid payments),
  //         but only outCountItems values are valid
  // *****************************************************
  // *****************************************************
  // *****************************************************

  /// @param indexDebt0 An index of the debt in the range [RoleDebts.firstUnpaidDebtIndex0...RoleDebts.totalCountDebts)
  function _payDebt(
    AmountST priceUSD
  , DepartmentUid departmentUid
  , RoleUid role
  , uint64 indexDebt0
  ) internal {
    DebtUid debtUid = roleDebtsList[departmentUid][role][_wrapToNullableValue64(indexDebt0)];
    RequestUid requestUid = debtsToRequests[debtUid];
    WorkerUid workerUid = requestsData[requestUid].worker;
    RoleDebts storage rd = roleDebts[departmentUid][role];

    // it the pay is incomplete, we cannot move forward RoleDebts.firstUnpaidDebtIndex0
    bool partialPay;
    IController c = IController(_controller());

    if (_equalTo(requestUid, 0)
      || _equals(requestUid
        , IRequestsManager(c.requestsManager()).getRequestUid(currentEpoch, workerUid)
      )
    ) {
      // revoked debt, ignore
      // or the debt belongs to the currentEpoch, we cannot pay it until the epoch is not changed
    } else {
      // debt value - how much we should pay in salary tokens?
      AmountUSD amountToPayUSD = unpaidAmountsUSD[debtUid];
      AmountST amountToPayST = usdToST(amountToPayUSD, priceUSD);

      // how much we can pay (available amount for the role + amounts for all lower roles)
      AmountST availableAmountToPayST = _getAvailableAmountST(departmentUid, role, amountToPayST);

      partialPay = !_equals(availableAmountToPayST, amountToPayST);
      if (!_equalTo(availableAmountToPayST, 0)) {
        IPaymentsManager(c.paymentsManager()).pay(
          ICompanyManager(c.companyManager()).getWallet(workerUid)
          , AmountST.unwrap(availableAmountToPayST), weekSalaryToken
        );
        emit OnPayDebt(debtUid, workerUid, partialPay);

        // update amounts available for the roles of the department
        _reduceAvailableAmountST(departmentUid, role, availableAmountToPayST);

        // update debt status
        AmountUSD amountPaidUSD = stToUSD(availableAmountToPayST, priceUSD);
        rd.amountUnpaidTotalUSD = subUSD(rd.amountUnpaidTotalUSD, amountPaidUSD);
        unpaidAmountsUSD[debtUid] = subUSD(amountToPayUSD, amountPaidUSD);
      }

      // move forward RoleDebts.firstUnpaidDebtIndex0
      if (! partialPay && rd.firstUnpaidDebtIndex0 == indexDebt0) {
        rd.firstUnpaidDebtIndex0 += 1;
      }
    }
  }

  function _payForRole(AmountST priceUSD, DepartmentUid departmentUid, RoleUid role) internal {
    RoleDebts storage rd = roleDebts[departmentUid][role];
    uint64 totalCountDebts = rd.totalCountDebts;
    uint64 startIndex = rd.firstUnpaidDebtIndex0;

    for (uint64 i = startIndex; i < totalCountDebts; i = _uncheckedInc64(i)) {
      _payDebt(priceUSD, departmentUid, role, i);

      if (rd.firstUnpaidDebtIndex0 == i) {
        // firstUnpaidDebtIndex0 wasn't incremented
        // there are no more money to pay other debts..
        break;
      }
    }
  }

  /// @dev Number of the roles can be reduces, but we should pay debts for out-dated roles anyway
  ///      So, we use maxRoleValueInAllTimes in the for-cycle here.
  function _payForDepartment(AmountST priceUSD, DepartmentUid departmentUid) internal {
    uint16 countRoles = RoleUid.unwrap(maxRoleValueInAllTimes);
    for (uint16 i = 0; i < countRoles; i = _uncheckedInc16(i)) {
      _payForRole(priceUSD, departmentUid, _roleIndexToRole(i));
    }
  }

  /// @notice Pay salary to all departments
  function _paySalary() internal {
    AmountST priceUSD = getPrice(weekSalaryToken, IController(_controller()).priceOracle());
    uint lenDepartments = departments.length;
    for (uint i = 0; i < lenDepartments; i = _uncheckedInc(i)) {
      _payForDepartment(priceUSD, departments[i]);
    }
  }

  // *****************************************************
  // ************ External pay functions *****************
  // *****************************************************

  function payDebt (
    DepartmentUid departmentUid
  , RoleUid role
  , uint64 indexDebt0
  ) external {
    onlyGovernance();

    AmountST priceUSD = getPrice(weekSalaryToken, IController(_controller()).priceOracle());
    _payDebt(priceUSD, departmentUid, role, indexDebt0);
  }

  function payForRole(DepartmentUid departmentUid, RoleUid role)
  external
  override {
    onlyGovernance();

    AmountST priceUSD = getPrice(weekSalaryToken, IController(_controller()).priceOracle());
    _payForRole(priceUSD, departmentUid, role);

    emit OnPayForRole(departmentUid, role);
  }

  function payForDepartment(DepartmentUid departmentUid)
  external
  override {
    onlyGovernance();

    AmountST priceUSD = getPrice(weekSalaryToken, IController(_controller()).priceOracle());
    _payForDepartment(priceUSD, departmentUid);

    emit OnPayForDepartment(departmentUid);
  }

  function pay()
  external
  override {
    onlyGovernance();

    _paySalary();
    emit OnPay();
  }

  // *****************************************************
  // ************ Amounts USD available for pay **********
  // *****************************************************

  /// @notice Check what amount is available to be paid to a worker with the given role
  /// @param role If the number of the roles was reduced, this value can exceed the actual number of the roles.
  ///             But it shouldn't exceed maxRoleValueInAllTimes
  /// @return availableAmountST
  ///         if total available amount >= amountToPayUSD then return amountToPayUSD
  ///         if total available amount < amountToPayUSD then return amount
  function _getAvailableAmountST(
    DepartmentUid departmentUid
  , RoleUid role
  , AmountST amountToPayST
  ) internal
  view
  returns (AmountST availableAmountST) {
    // we cannot pay more then current total week budget for the department
    // we cannot pay any debts for any deprecated department (for which no week-budget was provided in startEpoch)
    AmountST budgetForDepartmentST = _equals(weekDepartmentUidsToPay[departmentUid], currentEpoch)
      ? weekBudgetST[departmentUid]
      : AmountST.wrap(0);

    if (!greaterOrEqualST(budgetForDepartmentST, amountToPayST)) {
      amountToPayST = budgetForDepartmentST;
    }

    AmountST[] storage depAmountsST = weekBudgetLimitsForRolesST[departmentUid];
    uint lenRoles = depAmountsST.length;

    uint16 roleIndex0 = _roleToIndex0(role);
    if (roleIndex0 < RoleUid.unwrap(maxRoleValueInAllTimes)) {
      if (roleIndex0 >= lenRoles) {
        // the role is outdated
        // it means that there were N roles but now their number is reduced to M < N
        // We should allow to pay debts for the roles [M...N) anyway
        // Let's pay that debts using limits of the highest role
        // The same logic is implemented in _reduceAvailableAmountST
        roleIndex0 = uint16(lenRoles) - 1; // we assume that lenRoles > 0, it's not possible to set empty list of roles
      }
      for (uint16 i = roleIndex0 + 1; i > 0; i = _uncheckedDec16(i)) {
        if (i < roleIndex0 + 1
          &&  !_usdEqualTo(roleDebts[departmentUid][_roleIndexToRole(i - 1)].amountUnpaidTotalUSD, 0)) {
          // We can pay debts of higher role using the remaining amounts of lower roles
          // BUT only if the lower role (and more lower roles) have no unpaid debts
          // I.e.
          //   Debts  USD: Novice=0,    Educated=200, Blessed=0,   Nomarch=N
          //   Limits USD: Novice=1000, Educated=900, Blessed=800, Nomarch=700
          //   N = 2000: we can pay 700+800 only.
          // The restriction can be relaxed - we can allow to pay debts of higher-role by the amounts of lower roles
          // PARTLY (so that you can always be sure that the limits are enough to pay the debts of lower roles)
          // but it will complicated the code - probably we don't really need it.
          break;
        }

        availableAmountST = addST(availableAmountST, depAmountsST[i - 1]);
        if (greaterOrEqualST(availableAmountST, amountToPayST)) {
          return amountToPayST;
        }
      }
    }

    return availableAmountST;
  }

  /// @dev to be able to test _getAvailableAmountUSD
  function getAvailableAmountST (
    DepartmentUid departmentUid
  , RoleUid role
  , AmountST amountToPayST
  ) external
  view
  returns (AmountST availableAmountST) {
    return _getAvailableAmountST(departmentUid, role, amountToPayST);
  }

  /// @notice Fix values in limitAmountsUSD after successful paying of paidAmountUSD
  function _reduceAvailableAmountST(
    DepartmentUid departmentUid
  , RoleUid role
  , AmountST paidAmountST
  ) internal {
    AmountST budgetForDepartmentST = weekBudgetST[departmentUid];

    // ensure, that current total week budget >= paidAmountST
    if (_equalTo(paidAmountST, 0) ||  !greaterOrEqualST(budgetForDepartmentST, paidAmountST)) {
      revert ErrorIncorrectAmount();
    }

    // reduce total available budget for the department
    weekBudgetST[departmentUid] = subST(budgetForDepartmentST, paidAmountST);

    AmountST[] storage departmentAmountsST = weekBudgetLimitsForRolesST[departmentUid];
    uint lenRoles = departmentAmountsST.length;

    uint roleIndex0 = _roleToIndex0(role);

    if (roleIndex0 < RoleUid.unwrap(maxRoleValueInAllTimes)) {
      if (roleIndex0 >= lenRoles) {
        // the role is outdated
        // it means that there were N roles but now their number is reduced to M < N
        // We should allow to pay debts for the roles [M...N) anyway
        // Let's pay that debts using limits of the highest role
        // The same logic is implemented in _getAvailableAmountST
        roleIndex0 = uint16(lenRoles) - 1; // we assume that lenRoles > 0, it's not possible to set empty list of roles
      }
      for (uint i = roleIndex0 + 1; i > 0; i = _uncheckedDec(i)) {
        AmountST roleLimitST = departmentAmountsST[i - 1];
        if (! _equalTo(roleLimitST, 0)) {
          if (greaterOrEqualST(roleLimitST, paidAmountST)) {
            departmentAmountsST[i - 1] = subST(roleLimitST, paidAmountST);
            paidAmountST = AmountST.wrap(0);
            break;
          } else {
            departmentAmountsST[i - 1] = AmountST.wrap(0);
            paidAmountST = subST(paidAmountST, roleLimitST);
          }
        }
      }
    }

    if (AmountST.unwrap(paidAmountST) != 0) {
      revert ErrorTooBigAmount();
    }
  }

  /// @dev to be able to test reduceAvailableAmount
  function reduceAvailableAmountST(
    DepartmentUid departmentUid
  , RoleUid role
  , AmountST paidAmountST
  ) external {
    onlyGovernance();
    _reduceAvailableAmountST(departmentUid, role, paidAmountST);
  }

  /// @notice Get price of 1USD in [ST] from PriceOracle
  ///         Ensure, that price oracle uses same salary token as expected
  function getPrice(
    address salaryToken_
  , address priceOracle_
  ) public view returns (AmountST) {
    IPriceOracle p = IPriceOracle(priceOracle_);
    uint256 outPrice = p.getPrice(salaryToken_);
    return AmountST.wrap(outPrice);
  }

  // *****************************************************
  // ************ Start new epoch ************************
  // *****************************************************

  /// @notice Increment epoch counter.
  ///         Initialize week budget available for the payment of all exist debts.
  ///         After that it's possible to make payments for debts registered in the previous epochs
  /// @param paySalaryImmediately If true then call pay() immediately after starting new epoch
  function startEpoch(bool paySalaryImmediately)
  external {
    onlyGovernance();

    ICompanyManager cm = ICompanyManager(IController(_controller()).companyManager());

    // move epoch counter forward
    EpochType newEpoch = EpochType.wrap(EpochType.unwrap(currentEpoch) + 1);
    currentEpoch = newEpoch;

    // it's possible to pay all exist debts now
    // we need to fix week budget for each department
    // and max allowed sums for each pair (department, role)
    (DepartmentUid[] memory departmentUids
      , AmountST[] memory weekAmountsST
      , address salaryToken
    ) = cm.getWeekDepartmentBudgetsST(
      AmountST.wrap(0) // auto calculate week budget
    );

    // get salary token that will be used on this week (current epoch) to pay debts of the previous epochs
    // all amountsST are calculated in terms of this token
    weekSalaryToken = salaryToken;

    uint lenDepartments = departmentUids.length;
    for (uint i = 0; i < lenDepartments; i = _uncheckedInc(i)) {
      DepartmentUid departmentUid = departmentUids[i];

      weekDepartmentUidsToPay[departmentUid] = newEpoch;
      weekBudgetST[departmentUid] = weekAmountsST[i];
      weekBudgetLimitsForRolesST[departmentUid] = cm.getMaxWeekBudgetForRolesST(weekAmountsST[i], departmentUid);
    }

    // pay salary
    if (paySalaryImmediately) {
      _paySalary();
    }

    emit OnStartEpoch(newEpoch, paySalaryImmediately);
  }

  // *****************************************************
  // ****************** Migration ************************
  // *****************************************************
  /// @notice Migrate workers statistics from previously used PayrollClerk
  function migrateWorkStat(
    address predecessor_
    , WorkerUid[] calldata workerUids
    , uint[] calldata workedHours
    , uint[] calldata earnedAmountsUSD
  ) external {
    onlyGovernance();

    uint lenWorkers = workerUids.length;
    if (
      workedHours.length != lenWorkers
      || earnedAmountsUSD.length != lenWorkers
    ) {
      revert ErrorArraysHaveDifferentLengths();
    }

    // don't allow second migration
    if (predecessor_ == address(0)) {
      revert ErrorZeroAddress(0);
    }
    if (predecessor != address(0)) {
      revert ErrorAlreadyInitialized();
    }
    predecessor = predecessor_;

    // copy data from old contract
    for (uint i = 0; i < lenWorkers; i = _uncheckedInc(i)) {
      statForWorkers[workerUids[i]].workedHours = uint32(workedHours[i]);
      statForWorkers[workerUids[i]].earnedDollars = AmountUSD.wrap(uint64(earnedAmountsUSD[i]));
    }
  }

  // *****************************************************
  // ************ View functions for readers *************
  // *****************************************************
  /// @notice Allow to check if there is already exist for the request
  function getDebt(
    RequestUid requestUid_
  ) external
  view
  returns (DebtUid) {
    return requestsToDebts[requestUid_];
  }

  function getRequestWorkerAndRole(RequestUid requestUid_) external view returns (WorkerUid worker, RoleUid role) {
    RequestData storage rd = requestsData[requestUid_];
    return(rd.worker, rd.role);
  }

  // *****************************************************
  // ******** Helper function for DebtUid ****************
  // *****************************************************

  function _equalTo(DebtUid uid1, uint64 uid2) internal pure returns (bool) {
    return DebtUid.unwrap(uid1) == uid2;
  }

  // *****************************************************
  // ******* Helper function for RequestUid **************
  // *****************************************************

  function _equals(RequestUid uid1, RequestUid uid2) internal pure returns (bool) {
    return RequestUid.unwrap(uid1) == RequestUid.unwrap(uid2);
  }
  function _equalTo(RequestUid uid1, uint uid2) internal pure returns (bool) {
    return RequestUid.unwrap(uid1) == uid2;
  }

  // *****************************************************
  // ******* Helper function for roles *******************
  // *****************************************************

  /// @notice Convert 1-base role value to 0-base role index
  function _roleToIndex0(RoleUid role) internal pure returns (uint16) {
    return RoleUid.unwrap(role) - 1;
  }
  function _roleIndexToRole(uint16 roleIndex) internal pure returns (RoleUid) {
    return RoleUid.wrap(roleIndex + 1);
  }

  // *****************************************************
  // ******* Helper function for EpochType ***************
  // *****************************************************

  function _equals(EpochType uid1, EpochType uid2) internal pure returns (bool) {
    return EpochType.unwrap(uid1) == EpochType.unwrap(uid2);
  }

  // *****************************************************
  // ********* NullableIndexKey64 ************************
  // *****************************************************

  /// @notice Generate NullableIndexKey64 for uin64
  ///         It allows us to use 0 as a key/value in mapping
  function wrapToNullableValue64(uint64 value) external pure returns (NullableValue64) {
    return _wrapToNullableValue64(value);
  }
  function _wrapToNullableValue64(uint64 value) internal pure returns (NullableValue64) {
    return NullableValue64.wrap(value + 1);
  }

  // *****************************************************
  // ********* Amounts conversion ************************
  // *****************************************************
  function usdToST(AmountUSD amountUSD, AmountST price) public pure returns (AmountST amountST) {
    amountST = AmountST.wrap(
      AmountUSD.unwrap(amountUSD) * AmountST.unwrap(price)
    );
  }
  function stToUSD(AmountST amountST, AmountST price) public pure returns (AmountUSD amountUSD) {
    amountUSD = AmountUSD.wrap(
      uint64(AmountST.unwrap(amountST) / AmountST.unwrap(price))
    );
  }
  function getAmountUSD(uint64 amountUSD_) public pure returns (AmountUSD amountUSD) {
    amountUSD = AmountUSD.wrap(amountUSD_);
  }
  function addUSD(AmountUSD a1, AmountUSD a2) public pure returns (AmountUSD) {
    return AmountUSD.wrap(AmountUSD.unwrap(a1) + AmountUSD.unwrap(a2));
  }
  function subUSD(AmountUSD a1, AmountUSD a2) public pure returns (AmountUSD) {
    return AmountUSD.wrap(AmountUSD.unwrap(a1) - AmountUSD.unwrap(a2));
  }
  /// @dev 0.8.9 doesn't allow to use name _equalTo here, _equalTo(AmountST a1.. is not compiled
  function _usdEqualTo(AmountUSD a1, uint64 a2) public pure returns (bool) {
    return AmountUSD.unwrap(a1) == a2;
  }
  function addST(AmountST a1, AmountST a2) public pure returns (AmountST) {
    return AmountST.wrap(AmountST.unwrap(a1) + AmountST.unwrap(a2));
  }
  function subST(AmountST a1, AmountST a2) public pure returns (AmountST) {
    return AmountST.wrap(AmountST.unwrap(a1) - AmountST.unwrap(a2));
  }
  function greaterOrEqualST(AmountST a1, AmountST a2) public pure returns (bool) {
    return AmountST.unwrap(a1) >= AmountST.unwrap(a2);
  }
  function _equalTo(AmountST a1, uint a2) public pure returns (bool) {
    return AmountST.unwrap(a1) == a2;
  }
  function _equals(AmountST a1, AmountST a2) public pure returns (bool) {
    return AmountST.unwrap(a1) == AmountST.unwrap(a2);
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

  function _uncheckedDec(uint i) internal pure returns (uint) {
    unchecked {
      return i - 1;
    }
  }

  function _uncheckedDec16(uint16 i) internal pure returns (uint16) {
    unchecked {
      return i - 1;
    }
  }

  // *****************************************************
  // *********** Functions instead of modifiers **********
  // Hardhat sometime doesn't parse correctly custom errors,
  // generated inside modifiers.
  // To reproduce the problem see
  //      git: ac9e9769ea2263dfbb741df7c11b8b5e96b03a4b (31.05.2022)
  // So, modifiers are replaced by ordinal functions
  // *****************************************************
  function _onlyRequestsManager() internal view {
    if (msg.sender != address(IController(_controller()).requestsManager())) {
      revert ErrorOnlyRequestsManager();
    }
  }

}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;


import "../controller/Controllable.sol";
import "../../interfaces/IDebtsManager.sol";

/// @notice Storage for any DebtsManager variables
///         A debt = the company's debt to the worker
///         1 request - 1 debt - 1..N payments
/// @author dvpublic
abstract contract DebtsManagerStorage is Initializable, Controllable, IDebtsManager {

  // don't change names or ordering!

  // *****************************************************
  // ************* Constants *****************************
  // *****************************************************

  /// @notice Version of the contract
  /// @dev Should be incremented when contract changed
  string constant public VERSION = "1.0.0";


  // *****************************************************
  // ************ Members ********************************
  // *****************************************************
  /// @notice The initial value of current epoch at the contract deploy-solution
  EpochType public firstEpoch;

  /// @dev Greater then 0
  EpochType public currentEpoch;

  /// @notice A counter to generate DebtUid - unique uids for new debts
  DebtUid public debtUidCounter;

  /// @notice Max role-value used in roleDebts
  /// @dev List of roles can be changed in companyManager - number of the roles can increase or decrease
  ///      But we always need a way to enumerate all values inside DepartmentDebts.roleToDebts
  ///      so we need to know max role value
  RoleUid public maxRoleValueInAllTimes;


  /// @notice All departments for which we have any debts (paid or unpaid)
  ///         New departments are always added to the end of the array
  ///         The array allows us to enumerate all registered departments if necessary.
  ///         Each department must be registered here once and only once.
  /// @dev registeredDepartments allows to check if the department is already registered
  DepartmentUid[] public departments;

  /// @notice The value is an index of the corresponded department in departments-array
  /// @dev Allow to check if the department is already registered in departments-array
  mapping(DepartmentUid => NullableValue64) public registeredDepartments;

  /// @notice Info about debts registered for (department, role) - total count, index of last unpaid debt and so on
  mapping(DepartmentUid => mapping(RoleUid => RoleDebts)) public roleDebts;
  /// @notice List of debts registered for (department, role, firstUnpaidDebtIndex0 + 1)
  mapping(DepartmentUid => mapping(RoleUid => mapping(NullableValue64 => DebtUid))) public roleDebtsList;


  /// @notice All registered requests - approved and not approved
  mapping(RequestUid => RequestData) public requestsData;
  /// @notice All requests with registered debts
  mapping(RequestUid => DebtUid) public requestsToDebts;

  /// @notice All registered debts
  mapping(DebtUid => RequestUid) public debtsToRequests;
  /// @notice Currently unpaid amount [USD] for each debt
  mapping(DebtUid => AmountUSD) public unpaidAmountsUSD;


  /// @notice Statistic by workers
  ///         The statistics is updated when a debt is created/revoked
  mapping(WorkerUid => WorkerStat) public statForWorkers;

  /// @notice Address of previously used PayrollClerk (from tetu-contract project)
  ///         Initial workers stat is migrated from it
  address public predecessor;

  // *****************************************************
  // ***** Payment details for the current epoch *********
  // When new epoch is started, you get possibility to pay
  // all debts of the previous epochs. Following data
  // fixes the week budget details for such payments.
  // *****************************************************

  /// @notice The salary token used to make any payments during current epoch
  ///         The values weekBudgetST and weekBudgetLimitsForRolesST are calculated using this token.
  /// @dev This is a copy of the CompanyManager.salaryToken made at startEpoch call
  address public weekSalaryToken;

  /// @notice Permissions to pay to department in the current epoch
  ///         I.e. we have changed epoch 11 to 12
  ///         Current epoch is 12 now and we can pay debts for epoch 11 (and less)
  ///         We ask week cm.getWeekBudgetsST and get list of departments and related sums
  ///         For each department we store here a pair (department => 12)
  ///         At the same time we initialize weekBudgetST[department] by amount valid for the current epoch.
  ///         So, we can enumerate full list of departments
  ///         and make payments only for departments with stored [currentEpoch] here.
  mapping(DepartmentUid => EpochType) public weekDepartmentUidsToPay;

  /// @notice Week budget in salary tokens for each department
  ///         These values are fixed at the moment of startEpoch
  /// @dev Sum of all values is equal to total week budget [ST] passed to startEpoch
  mapping(DepartmentUid => AmountST) public weekBudgetST;

  /// @notice What amounts [salary tokens] are allowed to pay debts in the period up to the end of the current epoch.
  ///         Each array contains max allowed amounts for the roles.
  /// @dev The amounts are reduced after each pay.
  ///      The amounts are completely reinitialized on the start of a new epoch
  mapping(DepartmentUid => AmountST[]) public weekBudgetLimitsForRolesST;

  // *****************************************************
  // ************* Custom errors *************************
  // *****************************************************

  /// @notice Try to reduce the debts on the amount
  ///         that exceeds the total available budget for the pair (department, role)
  error ErrorTooBigAmount();

  /// @notice The debt was already created for the request
  error ErrorDebtAlreadyRegistered(RequestUid requestUid);

  /// @notice Attempt to revoke a debt of not-current epoch
  error ErrorDebtIsNotRevocable(DebtUid debtUid);

  /// @notice THere is no registered debt for the request
  error ErrorRequestHasNoDebt();

  /// @notice This function can be called by requests manager only
  error ErrorOnlyRequestsManager();


  // *****************************************************
  // ************* Events ********************************
  // *****************************************************

  event OnCreateDebt(DebtUid indexed debtUid, WorkerUid workerUid);
  event OnRevokeDebt(DebtUid indexed debtUid, WorkerUid workerUid);
  event OnStartEpoch(EpochType indexed newEpoch, bool paySalaryImmediatelly);
  event OnPayDebt(DebtUid indexed debtUid, WorkerUid workerUid, bool partialPay);

  event OnPayForDepartment(DepartmentUid indexed departmentUid);
  event OnPayForRole(DepartmentUid indexed departmentUid, RoleUid role);
  event OnPay();


  // *****************************************************
  // ************* Lengths and getters *******************
  // *****************************************************
  function lengthDepartments() external view returns (uint) {
    return departments.length;
  }

  function lengthWeekBudgetLimitsForRolesST(DepartmentUid departmentUid) external view returns (uint) {
    return weekBudgetLimitsForRolesST[departmentUid].length;
  }

  //slither-disable-next-line unused-state
  uint[50] private ______gap;
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

/// @notice Contract to pay salary to workers
interface IPaymentsManager is IClerkTypes {
  /// @notice Pay specified amount of salary tokens to the wallet
  /// @param amountST_ Amount of salary tokens, decimals 10^18
  function pay(address wallet_, uint amountST_, address salaryToken_) external;

  /// @notice Return available amount of salary token on balance of the payment manager
  function balance(address salaryToken_) external view returns (uint);
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

/// @notice Calculate price of 1 USD in the given tokens
interface IPriceOracle {

  /// @notice This PricesOracle is not able to calculate price of 1 USD in terms of the provided token
  error ErrorUnsupportedToken(address token);

  /// @notice Return a price of one dollar in required tokens
  /// @return Price of 1 USD in given token, decimals  = decimals of the required token
  function getPrice(address requiredToken) external view returns (uint);
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