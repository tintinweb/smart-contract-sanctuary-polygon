// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

library UserTransactionType {
    enum Status {
        Open,
        Processing,
        Complete,
        Cancelled
    }

    struct UserTransaction {
        bytes32 transactionNumber;
        uint256 amount;
        Status status;
        address recipient;
    }
}

contract EmpiyaP2P {
    Escrow escrowContract;
    address admin;

    using UserTransactionType for UserTransactionType.UserTransaction;

    constructor () {
        escrowContract = new Escrow(payable(address(this)));
        admin = msg.sender;
    }

    modifier nonZeroAmount() {
        require(msg.value > 0, "Amount should be greater than zero.");
        _;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only an Admin can execute this transaction.");
        _;
    }

    function setAdmin(address _admin) external onlyAdmin {
        require(_admin != address(0), "Invalid address input.");
        admin = _admin;
    }

    function getCaller() external view onlyAdmin returns (address caller) {
        caller = escrowContract.getCaller();
    }

    function getOwner() external view onlyAdmin returns (address owner) {
        owner = escrowContract.getOwner();
    }

    function getUserBalance() external view returns (uint balance) {
        balance = msg.sender.balance;
    }

    function getEscrowAddress() external view onlyAdmin returns (address owner) {
        owner = escrowContract.getAddress();
    }

    function setEscrowContract(Escrow escrowContractAccount) external onlyAdmin returns (address) {
        escrowContract = Escrow(escrowContractAccount);
        return address(escrowContract);
    }

    function getTotalBalance() external view onlyAdmin returns (uint256 balance) {
        balance = escrowContract.getTotalBalance();
    }

    function getUserTransaction(uint256 transactionKey) external view returns (UserTransactionType.UserTransaction memory transaction) {
        transaction = escrowContract.getTransaction(msg.sender, transactionKey);
    }

    function getUserTransactionByUser(address userAddress, uint256 transactionKey) external view returns (UserTransactionType.UserTransaction memory transaction) {
        transaction = escrowContract.getTransaction(userAddress, transactionKey);
    }

    function getUserTransactions() external view returns (UserTransactionType.UserTransaction[] memory transactions) {
        transactions = escrowContract.getTransactionsByUser(msg.sender);
    }

    function getTransactionsByUser(address userAddress) external view onlyAdmin returns (UserTransactionType.UserTransaction[] memory transactions) {
        transactions = escrowContract.getTransactionsByUser(userAddress);
    }

    function deposit() external payable returns (uint256, UserTransactionType.UserTransaction memory) {
        (uint256 transactionKey, UserTransactionType.UserTransaction memory userTransaction) = escrowContract.deposit{value: msg.value}(msg.sender);
        return (transactionKey, userTransaction);
    }

    function withdraw(uint256 transactionKey, bytes32 transactionNumber) external payable returns (uint256 _transactionKey, UserTransactionType.UserTransaction memory userTransaction) {
        (_transactionKey, userTransaction) = escrowContract.withdraw(payable(msg.sender), transactionKey, transactionNumber);
    }

    function transfer(uint256 transactionKey, bytes32 transactionNumber, address payable recipient) external returns (uint256 _transactionKey, UserTransactionType.UserTransaction memory userTransaction) {
        (_transactionKey, userTransaction) = escrowContract.transfer(msg.sender, transactionKey, transactionNumber, recipient);
    }

    function transferByDepositor(address depositor, uint256 transactionKey, bytes32 transactionNumber, address payable recipient) external onlyAdmin returns (uint256 _transactionKey, UserTransactionType.UserTransaction memory userTransaction) {
        (_transactionKey, userTransaction) = escrowContract.transfer(depositor, transactionKey, transactionNumber, recipient);
    }
}

contract Escrow {
    address private arbitrator;

    using UserTransactionType for UserTransactionType.UserTransaction;

    using UserTransactionType for UserTransactionType.Status;

    event Transaction(address indexed sender, address indexed receiver, bytes data);

    mapping(address => UserTransactionType.UserTransaction[]) public userTransactions;

    receive() external payable{}

    modifier nonZeroAmount() {
        require(msg.value > 0, "Amount should be greater than zero.");
        _;
    }

    modifier onlyArbitrator() {
        require(msg.sender == address(arbitrator), "Only Arbitrator can execute this transaction.");
        _;
    }

    modifier transactionNumberMatch(address userAddress, uint256 transactionKey, bytes32 transactionNumber) {
        require(userTransactions[userAddress][transactionKey].transactionNumber == transactionNumber, "Wrong Transaction Number provided.");
        _;
    }

    constructor (address _arbitrator) {
        arbitrator = _arbitrator;
    }

    function deposit(address depositorAddress) public onlyArbitrator nonZeroAmount payable returns (uint256, UserTransactionType.UserTransaction memory) {
        uint256 amount = msg.value;
        bytes32 transactionNumber = this.hash(depositorAddress, amount);
        userTransactions[depositorAddress].push(UserTransactionType.UserTransaction(transactionNumber, amount, UserTransactionType.Status.Open, address(0)));
        uint256 transactionKey = userTransactions[depositorAddress].length - 1;
        return (transactionKey, userTransactions[depositorAddress][transactionKey]);
    }

    function withdraw(address payable depositorAddress, uint256 transactionKey, bytes32 transactionNumber) public onlyArbitrator transactionNumberMatch(depositorAddress, transactionKey, transactionNumber) payable returns (uint256, UserTransactionType.UserTransaction memory) {
        require(userTransactions[depositorAddress][transactionKey].status != UserTransactionType.Status.Cancelled, "This deposit transaction has been cancelled.");
        require(userTransactions[depositorAddress][transactionKey].status != UserTransactionType.Status.Complete, "This deposit transaction has already been completed.");
        uint256 amount = userTransactions[depositorAddress][transactionKey].amount;
        (bool sent, bytes memory data) = depositorAddress.call{value: amount}("");
        emit Transaction(depositorAddress, depositorAddress, data);
        require(sent, "Failed to send Ether back to depositor.");

        userTransactions[depositorAddress][transactionKey].status = UserTransactionType.Status.Cancelled;

        return (transactionKey, userTransactions[depositorAddress][transactionKey]);
    }

    function transfer(address sender, uint256 transactionKey, bytes32 transactionNumber, address payable receiver) public onlyArbitrator transactionNumberMatch(sender, transactionKey, transactionNumber) payable returns (uint256, UserTransactionType.UserTransaction memory) {
        require(userTransactions[sender][transactionKey].status != UserTransactionType.Status.Cancelled, "This deposit transaction has been cancelled.");
        require(userTransactions[sender][transactionKey].status != UserTransactionType.Status.Complete, "This deposit transaction has already been completed.");
        uint256 amount = userTransactions[sender][transactionKey].amount;
        (bool sent, bytes memory data) = receiver.call{value: amount}("");
        emit Transaction(sender, receiver, data);
        require(sent, "Failed to send Ether to recipient.");

        userTransactions[sender][transactionKey].recipient = receiver;
        userTransactions[sender][transactionKey].status = UserTransactionType.Status.Complete;

        return (transactionKey, userTransactions[sender][transactionKey]);
    }

    function getTotalBalance() external view onlyArbitrator returns (uint256 balance) {
        balance = address(this).balance;
    }

    function getTransaction(address userAddress, uint256 transactionKey) external view onlyArbitrator returns (UserTransactionType.UserTransaction memory transaction) {
        transaction = userTransactions[userAddress][transactionKey];
    }

    function getTransactionsByUser(address userAddress) external view onlyArbitrator returns (UserTransactionType.UserTransaction[] memory transactions) {
        transactions = userTransactions[userAddress];
    }

    function getCaller() external view onlyArbitrator returns (address caller) {
        caller = msg.sender;
    }

    function getOwner() external view onlyArbitrator returns (address owner) {
        owner = arbitrator;
    }

    function getAddress() external view onlyArbitrator returns (address contractAddress) {
        contractAddress = address(this);
    }

    function hash(address userAddress, uint256 ampount) external view returns (bytes32) {
        return keccak256(abi.encodePacked(userAddress, block.timestamp, ampount));
    }
}