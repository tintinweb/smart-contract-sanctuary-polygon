contract PaidOff {
    Bill[] private bills;
    address public owner;
    enum Status {
        PENDING,
        VERIFIED
    }
    event BillVerified(Bill bill);
    event BillCreated(Bill bill);
    event TransactionCreated(Transaction transaction);
    event TransactionVerified(Transaction transaction);

    struct Transaction {
        address senderAddress;
        address receiverAddress;
        uint amount;
        Status status;
        uint transaction_index;
        uint createdAt;
        uint updatedAt;
    }
    struct Bill {
        uint bill_index;
        address debitorAddress;
        address collectorAddress;
        string service;
        uint startTime;
        uint endTime;
        Status status;
        uint total_debt;
        uint remaining;
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
        address debitorAddress,
        string memory service,
        uint startTime,
        uint endTime,
        uint total_debt
    ) public {
        require(
            startTime != 0 && endTime != 0 && total_debt != 0,
            "Invalid agruments"
        );
        require(
            msg.sender != debitorAddress,
            "debibtorAddress must not equal your address"
        );
        Bill memory newBill = Bill({
            debitorAddress: debitorAddress,
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
        address debitorAddress = bills[bill_index].debitorAddress;
        require(msg.sender == debitorAddress, "invalid sender address");
        require(bill_index < bills.length, "index out of bounds");
        bills[bill_index].status = Status.VERIFIED;
        bills[bill_index].updatedAt = block.timestamp;
        emit BillVerified(bills[bill_index]);
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
        Transaction memory tracsaction = transactions[bill_index][
            transaction_index
        ];
        return transactions[bill_index][transaction_index];
    }

    function createTransaction(uint amount, uint bill_index) public {
        require(amount != 0, "Invalid amount agruments");
        require(bill_index < bills.length, "Bill index out of bounds");
        require(
            msg.sender == bills[bill_index].debitorAddress,
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
        bills[bill_index].remaining =
            bills[bill_index].remaining -
            transactions[bill_index][transaction_index].amount;
        emit TransactionVerified(transactions[bill_index][transaction_index]);
    }

    function getListdetailsBillByDebitor(
        address debitorAddress
    ) public view returns (Bill[] memory billsByDebitor) {
        uint billsCount = 0;
        for (uint i = 0; i < bills.length; i++) {
            if (bills[i].debitorAddress == debitorAddress) {
                billsCount++;
            }
        }
        billsByDebitor = new Bill[](billsCount);
        uint index = 0;
        for (uint i = 0; i < bills.length; i++) {
            if (bills[i].debitorAddress == debitorAddress) {
                billsByDebitor[index] = bills[i];
                index++;
            }
        }
        return billsByDebitor;
    }

    function getListdetailsBillByCollector(
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

    function getListDetailTransactionByBill(
        uint bill_index
    ) public view returns (Transaction[] memory) {
        require(bill_index < bills.length, "bill index out of bounds");
        return transactions[bill_index];
    }
}