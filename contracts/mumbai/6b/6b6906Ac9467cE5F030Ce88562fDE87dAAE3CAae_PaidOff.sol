/**
 *Submitted for verification at polygonscan.com on 2023-06-04
*/

pragma solidity ^0.8.9;

contract PaidOff {
    Bill[] private bills;
    address public owner;
    enum Status {
        PENDING,
        VERIFIED,
        SUCCESSFUL,
        FAILED,
        EXTENDED
    }
    event BillVerified(Bill bill);
    event BillCreated(Bill bill);
    event BillSuccessful(Bill bill);
    event BillFailed(Bill bill);
    event BillExtended(Bill bill);
    event TransactionCreated(Transaction transaction);
    event TransactionVerified(Transaction transaction);

    struct Transaction {
        address senderAddress;
        address receiverAddress;
        int amount;
        Status status;
        uint transaction_index;
        uint createdAt;
        uint updatedAt;
        uint bill_index;
    }
    struct Bill {
        uint bill_index;
        address debtorAddress;
        address collectorAddress;
        string service;
        uint startTime;
        uint endTime;
        Status status;
        int total_debt;
        int remaining;
        uint createdAt;
        uint updatedAt;
    }

    constructor() {
        owner = 0xB0a93EB50f27042d49faB971cd7bA416D7A2146f;
    }

    mapping(uint => Transaction[]) transactions;

    function getBillsLength() public view returns (uint) {
        return bills.length;
    }

    function getTransactionsLength(uint bill_index) public view returns (uint) {
        require(bill_index < bills.length, "bill index out of bounds");
        return transactions[bill_index].length;
    }

    function createBill(
        address debtorAddress,
        string memory service,
        uint startTime,
        uint endTime,
        int total_debt
    ) public {
        require(
            startTime != 0 && endTime != 0 && total_debt > 0,
            "Invalid agruments"
        );
        require(
            msg.sender != debtorAddress,
            "debibtorAddress must not match your address"
        );
        Bill memory newBill = Bill({
            debtorAddress: debtorAddress,
            collectorAddress: msg.sender,
            service: service,
            startTime: startTime,
            endTime: endTime,
            status: Status.PENDING,
            total_debt: total_debt,
            remaining: total_debt,
            createdAt: block.timestamp,
            bill_index: bills.length,
            updatedAt: 0
        });
        bills.push(newBill);
        emit BillCreated(newBill);
    }

    function verifyBill(uint bill_index) public {
        address debtorAddress = bills[bill_index].debtorAddress;
        require(msg.sender == debtorAddress, "invalid debtorAddress");
        require(bill_index < bills.length, "index out of bounds");
        bills[bill_index].status = Status.VERIFIED;
        bills[bill_index].updatedAt = block.timestamp;
        emit BillVerified(bills[bill_index]);
    }

    function checkSuccessfulBill(uint bill_index) public {
        address collectorAddress = bills[bill_index].collectorAddress;
        require(msg.sender == collectorAddress, "invalid collectorAddress");
        require(bill_index < bills.length, "index out of bounds");
        require(bills[bill_index].remaining == 0, "remmaining must be 0");
        bills[bill_index].status = Status.SUCCESSFUL;
        bills[bill_index].updatedAt = block.timestamp;
        emit BillSuccessful(bills[bill_index]);
    }

    function checkFailedBill(uint bill_index) public {
        address collectorAddress = bills[bill_index].collectorAddress;
        require(msg.sender == collectorAddress, "invalid collectorAddress");
        require(bill_index < bills.length, "index out of bounds");
        require(block.timestamp > bills[bill_index].endTime, "Invalid time");
        bills[bill_index].status = Status.FAILED;
        bills[bill_index].updatedAt = block.timestamp;
        emit BillFailed(bills[bill_index]);
    }

    function extendExpiration(uint bill_index, uint endTime) public {
        address collectorAddress = bills[bill_index].collectorAddress;
        require(msg.sender == collectorAddress, "invalid collectorAddress");
        require(bill_index < bills.length, "index out of bounds");
        require(block.timestamp < endTime, "Invalid endTime");
        bills[bill_index].status = Status.EXTENDED;
        bills[bill_index].endTime = endTime;
        bills[bill_index].updatedAt = block.timestamp;
        emit BillExtended(bills[bill_index]);
    }

    function getDetailsBill(
        uint bill_index
    ) public view returns (Bill memory bill) {
        require(bill_index < bills.length, "index out of bounds");
        return bills[bill_index];
    }

    function getDetailsTransaction(
        uint bill_index,
        uint transaction_index
    ) public view returns (Transaction memory transaction) {
        require(bill_index < bills.length, "bill index out of bounds");
        require(
            transaction_index < transactions[bill_index].length,
            "Transaction index out of bounds"
        );
        return transactions[bill_index][transaction_index];
    }

    function createTransaction(int amount, uint bill_index) public {
        require(amount != 0, "Invalid amount agruments");
        require(bill_index < bills.length, "Bill index out of bounds");
        require(
            msg.sender == bills[bill_index].debtorAddress,
            "Not authorize access"
        );
        uint trans_index = transactions[bill_index].length;
        Transaction memory transaction = Transaction({
            senderAddress: msg.sender,
            receiverAddress: bills[bill_index].collectorAddress,
            amount: amount,
            status: Status.PENDING,
            transaction_index: trans_index,
            createdAt: block.timestamp,
            bill_index: bill_index,
            updatedAt: 0
        });
        transactions[bill_index].push(transaction);
        emit TransactionCreated(transaction);
    }

    function verifyTransaction(uint bill_index, uint transaction_index) public {
        require(bill_index < bills.length, "bill index out of bounds");
        require(
            transaction_index < transactions[bill_index].length,
            "transaction index out of bounds"
        );
        require(
            msg.sender == bills[bill_index].collectorAddress,
            "Not authorize access"
        );
        transactions[bill_index][transaction_index].status = Status.VERIFIED;
        transactions[bill_index][transaction_index].updatedAt = block.timestamp;
        if (
            bills[bill_index].remaining -
                transactions[bill_index][transaction_index].amount <
            0
        ) {
            bills[bill_index].remaining = 0;
        } else {
            bills[bill_index].remaining =
                bills[bill_index].remaining -
                transactions[bill_index][transaction_index].amount;
        }

        emit TransactionVerified(transactions[bill_index][transaction_index]);
    }

    function getListDetailsBillByDebtor(
        address debtorAddress
    ) public view returns (Bill[] memory billsBydebtor) {
        uint billsCount = 0;
        for (uint i = 0; i < bills.length; i++) {
            if (bills[i].debtorAddress == debtorAddress) {
                billsCount++;
            }
        }
        billsBydebtor = new Bill[](billsCount);
        uint index = 0;
        for (uint i = 0; i < bills.length; i++) {
            if (bills[i].debtorAddress == debtorAddress) {
                billsBydebtor[index] = bills[i];
                index++;
            }
        }
        return billsBydebtor;
    }

    function getListDetailsBillByCollector(
        address collectorAddress
    ) public view returns (Bill[] memory billsByCollector) {
        uint billsCount = 0;
        for (uint i = 0; i < bills.length; i++) {
            if (bills[i].collectorAddress == collectorAddress) {
                billsCount++;
            }
        }
        billsByCollector = new Bill[](billsCount);
        uint index = 0;
        for (uint i = 0; i < bills.length; i++) {
            if (bills[i].collectorAddress == collectorAddress) {
                billsByCollector[index] = bills[i];
                index++;
            }
        }
        return billsByCollector;
    }

    function getTransactionsBySender(
        address senderAddress
    ) public view returns (Transaction[] memory transactionsBySender) {
        uint transCount = 0;
        for (uint i = 0; i < bills.length; i++) {
            for (uint j = 0; j < transactions[i].length; j++) {
                if (transactions[i][j].senderAddress == senderAddress) {
                    transCount++;
                }
            }
        }
        transactionsBySender = new Transaction[](transCount);
        uint index = 0;
        for (uint i = 0; i < bills.length; i++) {
            for (uint j = 0; j < transactions[i].length; j++) {
                if (transactions[i][j].senderAddress == senderAddress) {
                    transactionsBySender[index] = transactions[i][j];
                    index++;
                }
            }
        }
        return transactionsBySender;
    }

    function getTransactionsByReceiver(
        address receiverAddress
    ) public view returns (Transaction[] memory transactionsByReceiver) {
        uint transCount = 0;
        for (uint i = 0; i < bills.length; i++) {
            for (uint j = 0; j < transactions[i].length; j++) {
                if (transactions[i][j].receiverAddress == receiverAddress) {
                    transCount++;
                }
            }
        }
        transactionsByReceiver = new Transaction[](transCount);
        uint index = 0;
        for (uint i = 0; i < bills.length; i++) {
            for (uint j = 0; j < transactions[i].length; j++) {
                if (transactions[i][j].receiverAddress == receiverAddress) {
                    transactionsByReceiver[index] = transactions[i][j];
                    index++;
                }
            }
        }
        return transactionsByReceiver;
    }

    function getListDetailTransactionByBill(
        uint bill_index
    ) public view returns (Transaction[] memory) {
        require(bill_index < bills.length, "bill index out of bounds");
        return transactions[bill_index];
    }
}