pragma solidity ^0.8.9;

interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);
    function balanceOf(address who) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
}

contract IdeaEscrow {
    struct Transaction {
        address buyer;
        address seller;
        uint256 amount;
        address token;
        bool paid;
        bool delivered;
        bool dispute;
        address disputeInitiator;
        string proofUrl;
    }

    mapping(bytes32 => Transaction) public transactions;
    uint256 public fee;
    address public admin;

    event TransactionCreated(bytes32 indexed transactionId, address buyer, address seller, uint256 amount, address token);
    event TransactionPaid(bytes32 indexed transactionId);
    event TransactionDelivered(bytes32 indexed transactionId);
    event DisputeInitiated(bytes32 indexed transactionId, address indexed seller, address indexed buyer, string reason, string proofUrl);
    event DisputeResolved(bytes32 indexed transactionId, address indexed disputeInitiator, address indexed recipient);

    constructor(uint256 _fee) {
        fee = _fee;
        admin = msg.sender;
    }

    function IdeaEscrowDiposit(bytes32 _transactionId, address _buyer, address _seller, uint256 _amount, address _token) public {
        require(transactions[_transactionId].buyer == address(0) && transactions[_transactionId].seller == address(0), "Transaction already exists");
        require(_buyer != _seller, "Invalid transaction");

        transactions[_transactionId] = Transaction(_buyer, _seller, _amount, _token, false, false, false, address(0), "");
        IERC20(_token).approve(address(this), _amount);
        uint256 allowance = IERC20(_token).allowance(_buyer, address(this));
        require(allowance >= _amount, "Dear Idea user :contract not authorized to spend tokens on behalf of the buyer");
        require(IERC20(_token).transferFrom(_buyer, address(this), _amount), "Transfer failed");

        emit TransactionCreated(_transactionId, _buyer, _seller, _amount, _token);
    }

    function IdeaPay(bytes32 _transactionId) public {
        Transaction storage transaction = transactions[_transactionId];
        require(!transaction.paid, "Transaction has already been paid");
        require(msg.sender == transaction.buyer, "Only the buyer can pay for the transaction");

        require(IERC20(transaction.token).transfer(transaction.seller, transaction.amount), "Transfer failed");

        transaction.paid = true;

        emit TransactionPaid(_transactionId);
    }

    function IdeaDeliver(bytes32 _transactionId) public {
        Transaction storage transaction = transactions[_transactionId];
        require(transaction.paid, "Transaction has not been paid yet");
        require(msg.sender == transaction.buyer, "Only the buyer can confirm delivery");

        transaction.delivered = true;

        emit TransactionDelivered(_transactionId);
    }

    function ideaInitiateDispute(bytes32 _transactionId, string memory _reason, string memory _proofUrl) public {
        Transaction storage transaction = transactions[_transactionId];
        require(msg.sender == transaction.buyer || msg.sender == transaction.seller, "Only the buyer or seller can initiate a dispute");
        require(!transaction.dispute, "Transaction is already in dispute");

        transaction.dispute = true;
        transaction.disputeInitiator = msg.sender;
        transaction.proofUrl = _proofUrl;

        emit DisputeInitiated(_transactionId, transaction.seller, transaction.buyer, _reason, _proofUrl);
    }
   function IdearesolveDispute(bytes32 _transactionId, bool _buyerWins) public {
        Transaction storage transaction = transactions[_transactionId];
        require(msg.sender == admin, "Only the admin can resolve disputes");
        require(transaction.dispute, "Transaction is not in dispute");

        address recipient = _buyerWins ? transaction.buyer : transaction.seller;
        uint256 amount = transaction.amount;

        require(IERC20(transaction.token).transfer(recipient, amount), "Transfer failed");

        transaction.dispute = false;

        emit DisputeResolved(_transactionId, transaction.disputeInitiator, recipient);
    }

    function setFee(uint256 _fee) public {
        require(msg.sender == admin, "Only the admin can set the fee");
        fee = _fee;
    }
    function setAdmin(address _newAdmin) public {
        require(msg.sender == admin, "Only the admin can set the fee");
        admin = _newAdmin;
    }

    function withdrawFee() public {
        require(msg.sender == admin, "Only the admin can withdraw the fee");
        uint256 balance = IERC20(transactions[bytes32(0)].token).balanceOf(address(this));
        require(balance >= fee, "Not enough balance to withdraw fee");

        require(IERC20(transactions[bytes32(0)].token).transfer(admin, fee), "Transfer failed");
    }
}