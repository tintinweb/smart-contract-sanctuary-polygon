// SPDX-License-Identifier: MIT

/**
▀█████████▄   ▄██████▄   ▄█          ▄████████    ▄████████  ▄██████▄  
  ███    ███ ███    ███ ███         ███    ███   ███    ███ ███    ███ 
  ███    ███ ███    ███ ███         ███    █▀    ███    ███ ███    ███ 
 ▄███▄▄▄██▀  ███    ███ ███        ▄███▄▄▄      ▄███▄▄▄▄██▀ ███    ███ 
▀▀███▀▀▀██▄  ███    ███ ███       ▀▀███▀▀▀     ▀▀███▀▀▀▀▀   ███    ███ 
  ███    ██▄ ███    ███ ███         ███    █▄  ▀███████████ ███    ███ 
  ███    ███ ███    ███ ███▌    ▄   ███    ███   ███    ███ ███    ███ 
▄█████████▀   ▀██████▀  █████▄▄██   ██████████   ███    ███  ▀██████▀  
                        ▀                        ███    ███   
*/

pragma solidity ^0.8.13;

contract MultiSigWallet {
    event Deposit(address indexed sender, uint256 amount, uint256 balance);
    event SubmitTransaction(
        address indexed owner,
        uint256 indexed txIndex,
        address indexed to,
        uint256 value,
        bytes data
    );
    event ConfirmTransaction(address indexed owner, uint256 indexed txIndex);
    event RejectTransaction(address indexed owner, uint256 indexed txIndex);
    event RevokeConfirmation(address indexed owner, uint256 indexed txIndex);
    event ExecuteTransaction(address indexed owner, uint256 indexed txIndex);

    address[] public owners;
    address paymentSplitter;

    mapping(address => bool) public isOwner;
    bool public initialized;
    uint256 public numConfirmationsRequired;

    struct Transaction {
        address to;
        uint256 value;
        bytes data;
        bool executed;
        uint256 numConfirmations;
        uint256 numRejections;
    }

    // mapping from tx index => owner => bool
    mapping(uint256 => mapping(address => bool)) public isConfirmed;
    mapping(uint256 => mapping(address => bool)) public isRejected;

    Transaction[] public transactions;

    modifier onlyOwner() {
        require(isOwner[msg.sender], "not owner");
        _;
    }

    modifier onlyAuthorized() {
        require(
            isOwner[msg.sender] || msg.sender == paymentSplitter,
            "!Authorized"
        );
        _;
    }

    modifier txExists(uint256 _txIndex) {
        require(_txIndex < transactions.length, "tx does not exist");
        _;
    }

    modifier notExecuted(uint256 _txIndex) {
        require(!transactions[_txIndex].executed, "tx already executed");
        _;
    }

    modifier notConfirmed(uint256 _txIndex) {
        require(!isConfirmed[_txIndex][msg.sender], "tx already confirmed");
        _;
    }

    modifier notRejected(uint256 _txIndex) {
        require(!isRejected[_txIndex][msg.sender], "tx already rejected");
        _;
    }

    /*******************************************************************************
     *	@notice Initialize a new contract from BoleroNFT contract.
     *  @param _owners an array of the addresses that will perform tx actions.
     *  @param _numConfirmationsRequired the number of confirmations required for each tx to pass.
     *  @param _paymentSplitter the address of the paymentSplitter to interract with.
     *******************************************************************************/
    function initialize(
        address[] memory _owners,
        uint256 _numConfirmationsRequired,
        address _paymentSplitter
    ) public {
        require(initialized == false, "already initialized");
        require(_owners.length > 0, "owners required");
        require(
            _numConfirmationsRequired > 0 &&
                _numConfirmationsRequired <= _owners.length,
            "invalid number of required confirmations"
        );

        for (uint256 i = 0; i < _owners.length; i++) {
            address owner = _owners[i];

            require(owner != address(0), "invalid owner");
            require(!isOwner[owner], "owner not unique");

            isOwner[owner] = true;
            owners.push(owner);
        }

        numConfirmationsRequired = _numConfirmationsRequired;
        paymentSplitter = _paymentSplitter;
        initialized = true;
    }

    receive() external payable {
        emit Deposit(msg.sender, msg.value, address(this).balance);
    }

    /*******************************************************************************
     *	@notice Submit a transaction as a proposal for others to validate.
     *  @param _to the address of the contract to submit a transaction to.
     *  @param _value the ammount of native token to passes on.
     *  @param _data the bytes of the tx to pass on to the target contract.
     *******************************************************************************/
    function submitTransaction(
        address _to,
        uint256 _value,
        bytes memory _data
    ) public onlyOwner {
        uint256 txIndex = transactions.length;

        transactions.push(
            Transaction({
                to: _to,
                value: _value,
                data: _data,
                executed: false,
                numConfirmations: 0,
                numRejections: 0
            })
        );

        emit SubmitTransaction(msg.sender, txIndex, _to, _value, _data);
    }

    /*******************************************************************************
     *	@notice Confirm a tx submited by another owner
     *  @param _txIndex the index of the tx that is stored of the array of submitted tx.
     *******************************************************************************/
    function confirmTransaction(uint256 _txIndex)
        public
        onlyOwner
        txExists(_txIndex)
        notExecuted(_txIndex)
        notConfirmed(_txIndex)
    {
        Transaction storage transaction = transactions[_txIndex];
        transaction.numConfirmations += 1;
        isConfirmed[_txIndex][msg.sender] = true;

        emit ConfirmTransaction(msg.sender, _txIndex);
    }

    /*******************************************************************************
     *	@notice Revoke a tx that was submitted by another owner
     *  @param _txIndex the index of the tx that is stored of the array of submitted tx.
     *******************************************************************************/
    function rejectTransaction(uint256 _txIndex)
        public
        onlyOwner
        txExists(_txIndex)
        notExecuted(_txIndex)
        notConfirmed(_txIndex)
    {
        Transaction storage transaction = transactions[_txIndex];
        transaction.numRejections += 1;
        isRejected[_txIndex][msg.sender] = true;

        emit RejectTransaction(msg.sender, _txIndex);
    }

    /*******************************************************************************
     *	@notice Confirm a tx submited by another owner
     *  @param _txIndex the index of the tx that is stored of the array of submitted tx.
     *******************************************************************************/
    function executeTransaction(uint256 _txIndex)
        public
        onlyOwner
        txExists(_txIndex)
        notExecuted(_txIndex)
    {
        Transaction storage transaction = transactions[_txIndex];

        require(
            transaction.numConfirmations >= numConfirmationsRequired,
            "cannot execute tx"
        );

        transaction.executed = true;

        (bool success, ) = transaction.to.call{value: transaction.value}(
            transaction.data
        );
        require(success, "tx failed");

        emit ExecuteTransaction(msg.sender, _txIndex);
    }

    /*******************************************************************************
     *	@notice Revoke a tx that was submitted by another owner
     *  @param _txIndex the index of the tx that is stored of the array of submitted tx.
     *******************************************************************************/
    function revokeConfirmation(uint256 _txIndex)
        public
        onlyOwner
        txExists(_txIndex)
        notExecuted(_txIndex)
    {
        Transaction storage transaction = transactions[_txIndex];

        require(isConfirmed[_txIndex][msg.sender], "tx not confirmed");

        transaction.numConfirmations -= 1;
        isConfirmed[_txIndex][msg.sender] = false;

        emit RevokeConfirmation(msg.sender, _txIndex);
    }

    /*******************************************************************************
     *	@notice Adding an additional owner via the paymentSplitter
     *  @param _owner the address of the new owner to add to the contract.
     *******************************************************************************/
    function addOwner(address _owner) public {
        require(
            msg.sender == paymentSplitter,
            "Only paymentSplitter is authorized!"
        );
        require(_owner != address(0), "invalid owner");
        require(!isOwner[_owner], "owner not unique");

        isOwner[_owner] = true;
        owners.push(_owner);
        numConfirmationsRequired += 1;
    }

    /*******************************************************************************
     *	@notice When it is decided to migrate a payee, the old payee is revoked as an owner
     *          and the new payee is being added as a new owner.
     *          only the paymentSplitter linked to the contract can perform this action.
     *  @param _oldOwner the address of the old owner.
     *  @param _newOwner the address of the new Onwer
     *******************************************************************************/
    function migrateOwner(address _oldOwner, address _newOwner) public {
        require(
            msg.sender == paymentSplitter,
            "Only paymentSplitter is authorized!"
        );
        isOwner[_oldOwner] = false;
        isOwner[_newOwner] = true;
        for (uint256 i = 0; i < owners.length; i++) {
            if (owners[i] == _oldOwner) {
                delete owners[i];
                owners.push(_newOwner);
            }
        }
    }

    function getOwners() public view returns (address[] memory) {
        return owners;
    }

    function getTransactionCount() public view returns (uint256) {
        return transactions.length;
    }

    function getTransaction(uint256 _txIndex)
        public
        view
        returns (
            address to,
            uint256 value,
            bytes memory data,
            bool executed,
            uint256 numConfirmations,
            uint256 numRejections
        )
    {
        Transaction storage transaction = transactions[_txIndex];

        return (
            transaction.to,
            transaction.value,
            transaction.data,
            transaction.executed,
            transaction.numConfirmations,
            transaction.numRejections
        );
    }
}