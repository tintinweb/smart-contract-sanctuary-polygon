/**
 *Submitted for verification at polygonscan.com on 2022-10-17
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

/**
 * Proof of concept transfer mechanism where you can send tokens
 * to an unknown address without having to reveal the unknown address
 * till the receiver claims it.
 * Warning: It is not a mixer, do not use it like a mixer.
 */
contract CommitTransfer {
  uint256 private unlocked = 1;
  modifier lock() {
    require(unlocked == 1, "CommitTransfer: LOCKED");
    unlocked = 0;
    _;
    unlocked = 1;
  }
  struct CommitTransaction {
    bytes32 commitHash;
    uint256 value;
    uint256 timestamp;
  }

  mapping(bytes32 => uint256) private balances;
  mapping(bytes32 => CommitTransaction[]) private pendingTransactions;

  uint256 private immutable PENDING_TRANSACTION_LIMIT;
  uint256 private immutable MINIMUM_DEPOSIT_AMOUNT;
  uint256 private immutable MINIMUM_REFUND_WAIT_TIME;
  uint256 private immutable secret;

  function getHash(uint256 _secret, address addr) public pure returns (bytes32) {
    return keccak256(abi.encodePacked(_secret, addr));
  }

  constructor(uint256 _secret) {
    require(_secret > 0, "CommitTransfer: INVALID SECRET");
    PENDING_TRANSACTION_LIMIT = 256; // it is there to ensure the receiver doesn't have to pay a lot to delete the array
    MINIMUM_DEPOSIT_AMOUNT = 1000000000000;
    MINIMUM_REFUND_WAIT_TIME = 0; // wait for 1 hour
    secret = _secret;
  }

  function getMyBalance() public view returns (uint256) {
    return balances[getHash(secret, msg.sender)];
  }

  /**
   * Deposit money into the contract for the receiving party to withdraw it
   * Arguments:
   * _receiverCommitHash: keccak256 hash of (secret, receiver address), getHash function can be used to compute it beforehand
   * Function Logic:
   * - LOCK
   * - Assert PENDING_TRANSACTION_LIMIT
   * - Assert MINIMUM_DEPOSIT_AMOUNT
   * - Add transaction to corresponding transaction list
   * - UNLOCK
   */
  function deposit(bytes32 _receiverCommitHash) external payable lock {
    require(pendingTransactions[_receiverCommitHash].length < PENDING_TRANSACTION_LIMIT, "CommitTransfer: PENDING_TRANSACTION_LIMIT REACHED");
    require(msg.value >= MINIMUM_DEPOSIT_AMOUNT, "CommitTransfer: MINIMUM_DEPOSIT_AMOUNT REQUIRED");
    pendingTransactions[_receiverCommitHash].push(CommitTransaction(getHash(secret, msg.sender), msg.value, block.timestamp));
    balances[_receiverCommitHash] += msg.value;
  }

  /**
   * Get your money refunded if the receiver has not claimed the amount
   * Function logic:
   * - LOCK
   * - Loop through the pending transactions for valid transactions
   * - Assert refund amount less than contract's balance
   * - delete specific transaction
   * - subtract refund amount from balance
   * - UNLOCK
   */
  function refund(bytes32 _receiverCommitHash) external lock {
    bytes32 _senderCommitHash = getHash(secret, msg.sender);
    uint256 minRefundableTimestamp = block.timestamp - MINIMUM_REFUND_WAIT_TIME;
    uint256 refundAmount = 0;
    uint256 i = 0;
    uint256 j = 0;
    uint256 len = pendingTransactions[_receiverCommitHash].length;
    while (i < len) {
      CommitTransaction memory commitTransaction = pendingTransactions[_receiverCommitHash][i];
      if (commitTransaction.commitHash == _senderCommitHash && commitTransaction.timestamp <= minRefundableTimestamp) {
        refundAmount += commitTransaction.value;
        j = i;
        while (j < len - 1) {
          pendingTransactions[_receiverCommitHash][j] = pendingTransactions[_receiverCommitHash][j + 1];
          j++;
        }
        pendingTransactions[_receiverCommitHash].pop();
        len--;
      } else {
        i++;
      }
    }

    uint256 balance = balances[_receiverCommitHash];
    require(refundAmount > 0, "CommitTransfer: NO REFUND");
    require(balance >= refundAmount, "CommitTransfer: BALANCE < REFUND");
    require(address(this).balance >= refundAmount, "CommitTransfer: CONTRACT BALANCE < REFUND");

    balances[_receiverCommitHash] -= refundAmount;

    (bool sent, bytes memory data) = payable(msg.sender).call{value: refundAmount}("");
    require(sent, "Failed to send Ether");
  }

  /**
   * Claim the deposited money in your account
   * Function Logic:
   * - LOCK
   * - Assert balance exists
   * - Assert balance less than contract's balance
   * - delete pending transactions
   * - subtract remaining balance
   * - transfer balance
   * - UNLOCK
   */
  function claim() external lock {
    bytes32 _commitHash = getHash(secret, msg.sender);
    uint256 balance = balances[_commitHash];

    require(balance > 0);
    require(balance <= address(this).balance);

    delete pendingTransactions[_commitHash];
    delete balances[_commitHash];

    (bool sent, bytes memory data) = payable(msg.sender).call{value: balance}("");
    require(sent, "Failed to send Ether");
  }
}