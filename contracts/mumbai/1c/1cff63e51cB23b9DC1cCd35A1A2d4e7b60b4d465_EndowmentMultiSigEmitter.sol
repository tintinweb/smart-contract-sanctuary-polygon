// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

// >> SHOULD INHERIT `IEndowmentMultiSigEmitter`? Has missing `requireExecutionChangeEndowment` implementation
// >> SHOULD INHERIT `Initializable`?
/**
 * @notice the endowment multisig emitter contract
 * @dev the endowment multisig emitter contract is a contract that emits events for all the endowment multisigs across AP
 */
contract EndowmentMultiSigEmitter {
  /*
   * Events
   */
  event Initialized();

  bool isInitialized;
  address multisigFactory;
  mapping(address => bool) isMultisig;

  function initEndowmentMultiSigEmitter(address _multisigFactory) public {
    require(_multisigFactory != address(0), "Invalid Address");
    require(!isInitialized, "Already initialized");
    isInitialized = true;
    multisigFactory = _multisigFactory;
    emit Initialized();
  }

  modifier isEmitter() {
    require(isMultisig[msg.sender], "Unauthorized");
    _;
  }
  modifier isOwner() {
    require(msg.sender == multisigFactory, "Not multisig factory");
    _;
  }
  event MultisigCreated(
    address multisigAddress,
    uint256 endowmentId,
    address emitter,
    address[] owners,
    uint256 required,
    bool requireExecution,
    uint256 transactionExpiry
  );
  event EndowmentConfirmed(uint256 endowmentId, address sender, uint256 transactionId);
  event ConfirmationRevoked(uint256 endowmentId, address sender, uint256 transactionId);
  event EndowmentSubmitted(uint256 endowmentId, uint256 transactionId);
  event TransactionExecuted(uint256 endowmentId, uint256 transactionId);
  event TransactionExecutionFailed(uint256 endowmentId, uint256 transactionId);
  event Deposit(uint256 endowmentId, address sender, uint256 amount);
  event OwnersAdded(uint256 endowmentId, address[] owners);
  event OwnersRemoved(uint256 endowmentId, address[] owners);
  event OwnerReplaced(uint256 endowmentId, address currOwner, address newOwner);
  event ApprovalRequirementsUpdated(uint256 endowmentId, uint256 approvalsRequired);
  event EndowmentTransactionExpiryChanged(uint256 endowmentId, uint256 transactionExpiry);

  /**
   * @notice emits MultisigCreated event
   * @param multisigAddress the multisig address
   * @param endowmentId the endowment id
   * @param emitter the emitter of the multisig
   * @param owners the owners of the multisig
   * @param required the required number of signatures
   * @param requireExecution the require execution flag
   * @param transactionExpiry duration of validity for newly created transactions
   */
  function createMultisig(
    address multisigAddress,
    uint256 endowmentId,
    address emitter,
    address[] memory owners,
    uint256 required,
    bool requireExecution,
    uint256 transactionExpiry
  ) public isOwner {
    isMultisig[multisigAddress] = true;
    emit MultisigCreated(
      multisigAddress,
      endowmentId,
      emitter,
      owners,
      required,
      requireExecution,
      transactionExpiry
    );
  }

  /**
   * @notice emits the EndowmentConfirmed event
   * @param endowmentId the endowment id
   * @param sender the sender of the transaction
   * @param transactionId the transaction id
   */
  function confirmEndowment(
    uint256 endowmentId,
    address sender,
    uint256 transactionId
  ) public isEmitter {
    emit EndowmentConfirmed(endowmentId, sender, transactionId);
  }

  /**
   * @notice emits the ConfirmationRevoked event
   * @param endowmentId the endowment id
   * @param sender the sender of the transaction
   * @param transactionId the transaction id
   */
  function revokeEndowment(
    uint256 endowmentId,
    address sender,
    uint256 transactionId
  ) public isEmitter {
    emit ConfirmationRevoked(endowmentId, sender, transactionId);
  }

  /**
   * @notice emits the EndowmentSubmitted event
   * @param endowmentId the endowment id
   * @param transactionId the transaction id
   */
  function submitEndowment(uint256 endowmentId, uint256 transactionId) public isEmitter {
    emit EndowmentSubmitted(endowmentId, transactionId);
  }

  /**
   * @notice emits the TransactionExecuted event
   * @param endowmentId the endowment id
   * @param transactionId the transaction id
   */
  function executeEndowment(uint256 endowmentId, uint256 transactionId) public isEmitter {
    emit TransactionExecuted(endowmentId, transactionId);
  }

  /**
   * @notice emits the TransactionExecutionFailed event
   * @param endowmentId the endowment id
   * @param transactionId the transaction id
   */
  function executeFailureEndowment(uint256 endowmentId, uint256 transactionId) public isEmitter {
    emit TransactionExecutionFailed(endowmentId, transactionId);
  }

  /**
   * @notice emits the Deposit event
   * @param endowmentId the endowment id
   * @param sender the sender of the transaction
   * @param value the value of the transaction
   */
  function depositEndowment(uint256 endowmentId, address sender, uint256 value) public isEmitter {
    emit Deposit(endowmentId, sender, value);
  }

  /**
   * @notice emits the OwnersAdded event
   * @param endowmentId the endowment id
   * @param owners the added owners of the endowment
   */
  function addOwnersEndowment(uint256 endowmentId, address[] memory owners) public isEmitter {
    emit OwnersAdded(endowmentId, owners);
  }

  /**
   * @notice emits the OwnersRemoved event
   * @param endowmentId the endowment id
   * @param owners the removed owners of the endowment
   */
  function removeOwnersEndowment(uint256 endowmentId, address[] memory owners) public isEmitter {
    emit OwnersRemoved(endowmentId, owners);
  }

  /**
   * @notice emits the OwnerReplaced event
   * @param endowmentId the endowment id
   * @param newOwner the added owner of the endowment
   */
  function replaceOwnerEndowment(
    uint256 endowmentId,
    address currOwner,
    address newOwner
  ) public isEmitter {
    emit OwnerReplaced(endowmentId, currOwner, newOwner);
  }

  /**
   * @notice emits the ApprovalRequirementsUpdated event
   * @param endowmentId the endowment id
   * @param approvalsRequired the required number of confirmations
   */
  function approvalsRequirementChangeEndowment(
    uint256 endowmentId,
    uint256 approvalsRequired
  ) public isEmitter {
    emit ApprovalRequirementsUpdated(endowmentId, approvalsRequired);
  }

  /**
   * @notice emits the EndowmentTransactionExpiryChange event
   * @param endowmentId the endowment id
   * @param transactionExpiry the duration a newly created transaction is valid for
   */
  function transactionExpiryChangeEndowment(
    uint256 endowmentId,
    uint256 transactionExpiry
  ) public isEmitter {
    emit EndowmentTransactionExpiryChanged(endowmentId, transactionExpiry);
  }
}