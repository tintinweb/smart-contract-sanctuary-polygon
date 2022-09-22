// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./ERC20.sol";
import "./IERC20.sol";
import "./IVerification.sol";
import "./safeTransfer.sol";
import "./AddressSet.sol";
using AddressSet for AddressSet.Set;

contract Loan is ERC20 {
  Lwned public factory;
  address public borrower;
  bytes32 public idHash;
  address public token;
  enum Status { PENDING, ACTIVE, REPAID, DEFAULTED, CANCELED }
  Status public status;
  uint public amountToGive;
  uint public amountToRepay;
  uint public deadlineIssue;
  uint public deadlineRepay;
  address[] public collateralTokens;
  uint[] public collateralAmounts;
  string public text;
  string public name;

  event InvestmentChanged(uint oldAmount, uint newAmount);
  event LoanIssued(uint timestamp);
  event LoanRepaid(uint timestamp);
  event LoanDefaulted(uint timestamp);
  event LoanCanceled(uint timestamp);

  string public symbol = "LWNED";
  uint8 public decimals;

  constructor(
    Lwned _factory,
    address _borrower,
    bytes32 _idHash,
    address _token,
    uint[4] memory _settings,
    address[] memory _collateralTokens,
    uint[] memory _collateralAmounts,
    string memory _text,
    string memory _name
  ) {
    factory = _factory;
    borrower = _borrower;
    idHash = _idHash;
    token = _token;
    decimals = IERC20(token).decimals();
    amountToGive = _settings[0];
    amountToRepay = _settings[1];
    deadlineIssue = _settings[2];
    deadlineRepay = _settings[3];
    collateralTokens = _collateralTokens;
    collateralAmounts = _collateralAmounts;
    text = _text;
    name = _name;
    require(deadlineIssue > block.timestamp);
    require(deadlineRepay > deadlineIssue);
    require(amountToGive > 0);
  }

  function invest(uint amount) external {
    require(block.timestamp < deadlineIssue);
    require(amount > 0);
    require(status == Status.PENDING);
    emit InvestmentChanged(totalSupply, totalSupply + amount);
    _mint(msg.sender, amount);
    // Don't allow collecting more investment than requested
    require(totalSupply <= amountToGive);
    factory.markAsLender(msg.sender);
    safeTransfer.invokeFrom(token, msg.sender, address(this), amount);
  }

  function divest(uint amount) external {
    require(balanceOf[msg.sender] >= amount);
    emit InvestmentChanged(totalSupply, totalSupply - amount);
    emit Transfer(msg.sender, address(0), amount);
    balanceOf[msg.sender] -= amount;
    totalSupply -= amount;
    if(status == Status.PENDING) {
      // Loan not yet approved
      safeTransfer.invoke(token, msg.sender, amount);
    } else if(status == Status.REPAID) {
      // Loan has been repaid, withdraw mature amount
      safeTransfer.invoke(token, msg.sender, (amount * amountToRepay) / amountToGive);
    } else if(status == Status.DEFAULTED || (status == Status.ACTIVE && deadlineRepay < block.timestamp)) {
      // Save users a transaction by allowing a loan to be divested and defaulted at once
      if(status == Status.ACTIVE) loanDefault();
      // Loan has defaulted, withdraw the collateral
      for(uint i = 0; i < collateralTokens.length; i++) {
        safeTransfer.invoke(collateralTokens[i], msg.sender, (amount * collateralAmounts[i]) / amountToGive);
      }
    } else if(status == Status.ACTIVE) {
      // Loan has been issued, cannot divest at the moment
      require(false);
    }
  }

  // Principal investment is met, issue the loan
  function loanIssue() external {
    require(status == Status.PENDING);
    require(msg.sender == borrower);
    require(totalSupply == amountToGive);
    status = Status.ACTIVE;
    emit LoanIssued(block.timestamp);
    factory.markAsActive();
    safeTransfer.invoke(token, borrower, amountToGive);
  }

  // Anyone can repay loan before deadline
  function loanRepay() external {
    require(status == Status.ACTIVE);
    require(deadlineRepay > block.timestamp);
    status = Status.REPAID;
    emit LoanRepaid(block.timestamp);
    safeTransfer.invokeFrom(token, msg.sender, address(this), amountToRepay);
    _refundCollateral();
  }

  // Borrower withdraws collateral of loan that never issued
  function loanCancel() external {
    require(status == Status.PENDING);
    require(msg.sender == borrower);
    status = Status.CANCELED;
    emit LoanCanceled(block.timestamp);
    factory.markAsCanceled();
    _refundCollateral();
  }

  // Transfer collateral back to borrower
  function _refundCollateral() internal {
    for(uint i = 0; i < collateralTokens.length; i++) {
      safeTransfer.invoke(collateralTokens[i], borrower, collateralAmounts[i]);
    }
  }

  // Borrower has not repaid before the deadline
  // Anybody can call this, it doesn't matter
  function loanDefault() public {
    require(status == Status.ACTIVE);
    require(deadlineRepay < block.timestamp);
    status = Status.DEFAULTED;
    emit LoanDefaulted(block.timestamp);
  }

  function allCollateralTokens() external view returns(address[] memory) {
    return collateralTokens;
  }

  function allCollateralAmounts() external view returns(uint[] memory) {
    return collateralAmounts;
  }
}

contract Lwned {
  IVerification public verifications;

  mapping(address => Loan[]) public loansByBorrower;
  mapping(bytes32 => Loan[]) public loansByBorrowerIdHash;
  mapping(address => Loan[]) public loansByLender;
  mapping(address => Loan[]) public loansByToken;
  mapping(address => mapping(address => bool)) public loansByLenderMap;
  AddressSet.Set pendingApplications;
  AddressSet.Set pendingApplicationsWithIdHash;
  AddressSet.Set activeLoans;

  event NewApplication(address indexed borrower, address loan);

  constructor(IVerification _verifications) {
    verifications = _verifications;
  }

  function newApplication(
    address _token,
    uint _toGive,
    uint _toRepay,
    uint _deadlineIssue,
    uint _deadlineRepay,
    address[] memory _collateralTokens,
    uint[] memory _collateralAmounts,
    string memory _text,
    string memory _name
  ) external {
    require(bytes(_name).length > 4 && bytes(_name).length < 161);
    bytes32 idHash = verifications.addressIdHash(msg.sender);

    Loan application = new Loan(
      this,
      msg.sender,
      idHash,
      _token,
      // Array defeats stack too deep error
      [_toGive,
      _toRepay,
      _deadlineIssue,
      _deadlineRepay],
      _collateralTokens,
      _collateralAmounts,
      _text,
      _name
    );

    // Transfer collateral to contract from borrower
    // User won't know loan contract instance address at this time
    // so they can't approve the spends to that address,
    // so perform the collateral transfer here
    require(_collateralAmounts.length == _collateralTokens.length);
    for(uint i = 0; i < _collateralTokens.length; i++) {
      safeTransfer.invokeFrom(_collateralTokens[i], msg.sender, address(application), _collateralAmounts[i]);
    }

    loansByBorrower[msg.sender].push(application);
    loansByToken[_token].push(application);
    pendingApplications.insert(address(application));
    emit NewApplication(msg.sender, address(application));

    if(uint256(idHash) > 0) {
      loansByBorrowerIdHash[idHash].push(application);
      pendingApplicationsWithIdHash.insert(address(application));
    }
  }

  // Invoked by the Loan contract internally
  function markAsLender(address lender) external {
    require(pendingApplications.exists(msg.sender));
    if(loansByLenderMap[lender][msg.sender] == false) {
      loansByLenderMap[lender][msg.sender] = true;
      loansByLender[lender].push(Loan(msg.sender));
    }
  }

  // Invoked by the Loan contract internally
  function markAsActive() external {
    require(pendingApplications.exists(msg.sender));
    pendingApplications.remove(msg.sender);
    if(pendingApplicationsWithIdHash.exists(msg.sender)) {
      pendingApplicationsWithIdHash.remove(msg.sender);
    }
    activeLoans.insert(msg.sender);
  }

  // Invoked by the Loan contract internally
  function markAsCanceled() external {
    require(pendingApplications.exists(msg.sender));
    pendingApplications.remove(msg.sender);
  }

  function countOf(address account) external view returns(uint) {
    return loansByBorrower[account].length;
  }

  function countOfIdHash(bytes32 idHash) external view returns(uint) {
    return loansByBorrowerIdHash[idHash].length;
  }

  function countOfLender(address account) external view returns(uint) {
    return loansByLender[account].length;
  }

  function countOfToken(address token) external view returns(uint) {
    return loansByToken[token].length;
  }

  function pendingCount() external view returns(uint) {
    return pendingApplications.count();
  }

  function pendingAt(uint index) external view returns(address) {
    return pendingApplications.keyList[index];
  }

  function pendingCountWithIdHash() external view returns(uint) {
    return pendingApplicationsWithIdHash.count();
  }

  function pendingAtWithIdHash(uint index) external view returns(address) {
    return pendingApplicationsWithIdHash.keyList[index];
  }

  function activeCount() external view returns(uint) {
    return activeLoans.count();
  }

  function activeAt(uint index) external view returns(address) {
    return activeLoans.keyList[index];
  }

}