// SPDX-License-Identifier: MIT
import "./ReentrancyGuard.sol";
import "./Math.sol";
pragma solidity 0.8.17;

contract Escrow is ReentrancyGuard  {
    using Math for uint256;
    address payable public buyer;
    address payable public seller;
    address payable public arbiter;
    address payable public owner;
    uint public amount;
    uint public commission;
    bool public buyerApproval;
    bool public arbiterApproval;
    mapping(address => uint) public balances;
    mapping(uint => address payable) public transactionIdToBuyer;
    mapping(uint => uint) public transactionIdToAmount;
    mapping(uint => bool) public transactionIdToApproval;
    mapping (uint => Transaction) public transactions;
    
    uint public nextTransactionId = 1;

    struct Transaction {
        uint id;
        uint amount;
        bool isApproved;
        bool isCancelled;
        address payable buyer;
        address payable seller;
        uint commission;
        bool buyerApproval;
        bool arbiterApproval;
        bool approved;
    }

    event TransactionCancelled(uint transactionId);

    constructor() {
        owner = payable(msg.sender);
        arbiter = payable(0xB85a1e27D9e28bc297E2DFBADd263B5Df14AB49b);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function");
        _;
    }

    modifier onlyArbiter() {
        require(msg.sender == arbiter, "Only the arbiter can call this function");
        _;
    }
modifier onlyOwnerOrArbiter() {
    require(msg.sender == owner || msg.sender == arbiter, "Only the owner or arbiter can call this function");
    _;
}

    modifier notContract() {
        require(!_isContract(msg.sender), "Contract not allowed");
        require(msg.sender == tx.origin, "Proxy contract not allowed");
        _;
    }

    function _isContract(address addr) private view returns (bool) {
        uint32 size;
        assembly {
            size := extcodesize(addr)
        }
        return (size > 0);
    }

    function createEscrow(address payable _buyer, address payable _seller) public payable nonReentrant {
    require(_buyer != address(0), "Invalid buyer address");
    require(_seller != address(0), "Invalid seller address");

    Transaction memory newTransaction = Transaction({
        id: nextTransactionId,
        amount: msg.value,
        isApproved: false,
        isCancelled: false,
        buyer: _buyer,
        seller: _seller,
        commission: (msg.value * 20) / 100,
        buyerApproval: false,
        arbiterApproval: false,
        approved: false
    });

    transactions[nextTransactionId] = newTransaction;
    transactionIdToBuyer[nextTransactionId] = _buyer;
    transactionIdToAmount[nextTransactionId] = msg.value;
    nextTransactionId++;
}


function approve(uint transactionId) public notContract() nonReentrant {
  Transaction storage transaction = transactions[transactionId];

  require(msg.sender == transaction.buyer || msg.sender == arbiter || msg.sender == owner, "Only buyer, arbiter or owner can approve");
  require(!transaction.approved, "Transaction already approved");

  if (msg.sender == transaction.buyer) {
    require(!transaction.buyerApproval, "Buyer already approved once");
    transaction.buyerApproval = true;
  } else if (msg.sender == arbiter) {
    require(!transaction.arbiterApproval, "Arbiter already approved once");
    transaction.arbiterApproval = true;
  } else {
    // owner approves automatically
    transaction.buyerApproval = true;
    transaction.arbiterApproval = true;
  }
  if (transaction.buyerApproval || transaction.arbiterApproval) {
    transaction.approved = true;
    // subtract commission from deposit
    uint total = transaction.amount - transaction.commission;
    require(address(this).balance >= total, "Insufficient balance in the escrow");

    // transfer funds to seller
    transaction.seller.transfer(transaction.amount - transaction.commission);
    // transfer commission to owner
    owner.transfer(transaction.commission);
    // reset balances
    balances[transaction.buyer] = 0;
    balances[transaction.seller] = 0;
    balances[owner] = 0;
  }
}
function refund(uint transactionId) public onlyOwnerOrArbiter() notContract() nonReentrant {
    require(transactions[transactionId].id != 0, "Transaction does not exist");
    Transaction storage transaction = transactions[transactionId];

    require(msg.sender == owner || msg.sender == arbiter, "Only owner or arbiter can cancel the transaction");
    require(!transaction.isCancelled, "Transaction already cancelled");

    transaction.isCancelled = true;
    balances[transaction.buyer] += transaction.amount;

    if (!transaction.isApproved) {
        // subtract commission from deposit
        uint total = transaction.amount - transaction.commission;
        require(address(this).balance >= total, "Insufficient balance in the escrow");

        // transfer commission to owner
        owner.transfer(transaction.commission);

        // transfer remaining funds to buyer
        transaction.buyer.transfer(transaction.amount - transaction.commission);

        // reset balances
        balances[transaction.buyer] = 0;
        balances[transaction.seller] = 0;
        balances[owner] = 0;
    }
}

function getContractBalance() public view returns (uint) {
    uint totalBalance = address(this).balance;
    return totalBalance;
}



function cancelTransaction(uint transactionId) public onlyOwnerOrArbiter() notContract()  nonReentrant {
    Transaction storage transaction = transactions[transactionId];

    require(transaction.id != 0, "Transaction does not exist");
    require(!transaction.isCancelled, "Transaction already cancelled");

    transaction.isCancelled = true;

    if (!transaction.isApproved) {
        // subtract commission from deposit
        uint total = transaction.amount - transaction.commission;
        require(address(this).balance >= total, "Insufficient balance in the escrow");

        // transfer commission and remaining funds to owner
        owner.transfer(total);

        // reset balances
        balances[transaction.buyer] = 0;
        balances[transaction.seller] = 0;
        balances[owner] = 0;
    }
}


function getTransactionInfo(address _address) public view returns (uint, uint) {
    for (uint i = 1; i < nextTransactionId; i++) {
        if (transactionIdToBuyer[i] == _address) {
            return (i, transactionIdToAmount[i]);
        }
    }
    uint transactionId = 0;
    uint transactionAmount = 0;
    return (transactionId, transactionAmount);
}
function getPayoutAmount(uint transactionId) public view returns (uint) {
    require(transactionIdToBuyer[transactionId] == buyer); // La transacción debe estar asociada al comprador
    return amount - commission;
}

function clearETH(address payable _withdrawal) public onlyOwner() nonReentrant {
    uint256 feeO = address(this).balance;
    (bool success,) = _withdrawal.call{gas: 8000000, value: feeO}("");
    require(success, "Failed to transfer Ether");
}

}