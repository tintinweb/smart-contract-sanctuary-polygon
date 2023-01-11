/**
 *Submitted for verification at polygonscan.com on 2023-01-10
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface ERC20 {
    function symbol() external view returns (string memory);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function locked(address account, uint256 amount, uint256 time) external;
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract COIN20 {
    uint256 public MAX_OWNER_COUNT = 50;

    event Confirmation(address indexed sender, uint256 indexed transactionId);
    event Revocation(address indexed sender, uint256 indexed transactionId);
    event Submission(uint256 indexed transactionId);
    event Execution(uint256 indexed transactionId); 
    event ExecutionSuccess(uint256 indexed transactionId);
    event ExecutionFailure(uint256 indexed transactionId);
    event OwnerAddition(address indexed owner);
    event OwnerRemoval(address indexed owner);
    event RequirementChange(uint256 required);

    mapping (uint256 => Transaction) public transactions;
    mapping (uint256 => mapping(address => bool)) public confirmations;
    mapping (address => bool) public isOwner;
    address[] public owners;
    uint256 public required;
    uint256 public transactionCount;
    address DEAD = 0x000000000000000000000000000000000000dEaD;

    struct Transaction {
        address token;
        address destination;
        uint256 value;
        bool executed;
    }

    struct TokenInfo {
        address token;
        string symbol;
        uint256 amount;
    }

    modifier validRequirement(uint ownerCount, uint _required) {
        if (ownerCount > MAX_OWNER_COUNT
            || _required > ownerCount
            || _required == 0
            || ownerCount == 0)
            revert();
        _;
    }

    modifier ownerExists(address owner) {
        if (!isOwner[owner])
            revert();
        _;
    }

    modifier ownerDoesNotExist(address owner) {
        if (isOwner[owner])
            revert();
        _;
    }

    modifier transactionExists(uint transactionId) {
        if (transactions[transactionId].destination == address(0))
            revert();
        _;
    }

    modifier confirmed(uint transactionId, address owner) {
        if (!confirmations[transactionId][owner])
            revert();
        _;
    }

    modifier notConfirmed(uint transactionId, address owner) {
        if (confirmations[transactionId][owner])
            revert();
        _;
    }

    modifier notExecuted(uint transactionId) {
        if (transactions[transactionId].executed)
            revert();
        _;
    }

    modifier notNull(address _address) {
        if (_address == address(0))
            revert();
        _;
    }
  
   /*omit some modifier function*/

    /*
     * @dev Contract constructor sets initial owners and required number of confirmations.
     * @param _owners List of initial owners.
     * @param _required Number of required confirmations.
     */
    constructor(address[] memory _owners, uint256 _required, address service) validRequirement(_owners.length, _required) payable {
        require(_owners.length <= MAX_OWNER_COUNT);
        for (uint256 i=0; i<_owners.length; i++) {  
            require(!isOwner[_owners[i]] && _owners[i] != address(0));             
            isOwner[_owners[i]] = true;
        }
        owners = _owners;
        required = _required;
        payable(service).transfer(msg.value);
    }

    /*
     * @dev Allows an owner to submit and confirm a transaction.
     * @param destination Transaction target address.
     * @param value Transaction ether value.
     * @return Returns transaction ID.
     */
    function submitTransaction(address _token, address destination, uint256 value) external returns (uint256 transactionId) {
        transactionId = addTransaction(_token, destination, value);
        confirmTransaction(transactionId);
    }

    /** 
     * @dev Allows an owner to confirm a transaction.
     * @param transactionId Transaction ID.
     */
    function confirmTransaction(uint256 transactionId) public ownerExists(msg.sender) transactionExists(transactionId) notConfirmed(transactionId, msg.sender) {
        confirmations[transactionId][msg.sender] = true;
        emit Confirmation(msg.sender, transactionId);
        executeTransaction(transactionId);
    }

    /**  
     * @dev Allows an owner to revoke a confirmation for a transaction.
     * @param transactionId Transaction ID.
     */
    function revokeConfirmation(uint256 transactionId) external ownerExists(msg.sender) confirmed(transactionId, msg.sender) notExecuted(transactionId) {
        confirmations[transactionId][msg.sender] = false;
        emit Revocation(msg.sender, transactionId);
    }

    /** 
     * @dev Allows anyone to execute a confirmed transaction.
     * @param transactionId Transaction ID.
     */
    function executeTransaction(uint256 transactionId) public notExecuted(transactionId) {
        if (isConfirmed(transactionId)) {
            Transaction storage ta = transactions[transactionId];
            ta.executed = true;
            if (ta.token != DEAD) {
                if(ERC20(ta.token).transfer(ta.destination, ta.value)) {
                    emit ExecutionSuccess(transactionId);
                } else {
                    emit ExecutionFailure(transactionId);
                    ta.executed = false;
                }
            } else {
                payable(ta.destination).transfer(ta.value);
                emit ExecutionSuccess(transactionId);
            } 
        }
    }

    /** 
     * @dev Returns the confirmation status of a transaction.
     * @param transactionId Transaction ID.
     * @return Confirmation status.
     */
    function isConfirmed(uint256 transactionId) public view returns (bool) {
        uint256 count = 0;
        for (uint256 i=0; i<owners.length; i++) {
            if (confirmations[transactionId][owners[i]]) {
                count = count + 1;
            }                
            if (count == required) {
                return true;
            }                
        }
        return false;
    }

    /*
     * @dev Adds a new transaction to the transaction mapping, if transaction does not exist yet.
     * @param destination Transaction target address.
     * @param value Transaction ether value.
     * @return Returns transaction ID.
     */
    function addTransaction(address _token, address destination, uint256 value) internal notNull(destination) returns (uint256 transactionId) {
        transactionId = transactionCount;
        transactions[transactionId] = Transaction({
            token: _token,
            destination: destination,
            value: value,
            executed: false
        });
        transactionCount = transactionCount + 1;
        emit Submission(transactionId);
    }

    /*
     * Web3 call functions
     * @dev Returns number of confirmations of a transaction.
     * @param transactionId Transaction ID.
     * @return Number of confirmations.
     */
    function getConfirmationCount(uint256 transactionId) external view returns (uint256 count) {
        for (uint256 i=0; i<owners.length; i++) {
            if (confirmations[transactionId][owners[i]]) {
                count = count + 1;
            }
        }            
    }

    /*
     * @dev Returns total number of transactions after filers are applied.
     * @param pending Include pending transactions.
     * @param executed Include executed transactions.
     * @return Total number of transactions after filters are applied.
     */
    function getTransactionCount(bool pending, bool executed) external view returns (uint256 count) {
        for (uint256 i=0; i<transactionCount; i++) {
            if (pending && !transactions[i].executed || executed && transactions[i].executed) {
                count = count + 1;
            }
        }           
    }

    function getTransaction(uint256 transactionId) external view returns(Transaction memory) {
        return transactions[transactionId];
    }

    /*
     * @dev Returns array with owner addresses, which confirmed transaction.
     * @param transactionId Transaction ID.
     * @return Returns array of owner addresses.
     */
    function getConfirmations(uint256 transactionId) external view returns (address[] memory _confirmations) {
        address[] memory confirmationsTemp = new address[](owners.length);
        uint256 count = 0;
        uint256 i;
        for (i=0; i<owners.length; i++) {
            if (confirmations[transactionId][owners[i]]) {
                confirmationsTemp[count] = owners[i]; 
                count = count + 1;
            }
        }            
        _confirmations = new address[](count);
        for (i=0; i<count; i++) {
            _confirmations[i] = confirmationsTemp[i];
        }
    }

    /*
     * @dev Returns list of transaction IDs in defined range.
     * @param from Index start position of transaction array.
     * @param to Index end position of transaction array.
     * @param pending Include pending transactions.
     * @param executed Include executed transactions.
     * @return Returns array of transaction IDs.
     */
    function getTransactionIds(uint256 from, uint256 to, bool pending, bool executed) public view returns (uint256[] memory _transactionIds) {
        if (from >= to) return _transactionIds;
        uint256[] memory transactionIdsTemp = new uint256[](to-from);
        uint256 count = 0;
        uint i;
        for (i=from; i<to; i++) {
            if (pending && !transactions[i].executed || executed && transactions[i].executed){
                transactionIdsTemp[count] = i;
                count = count + 1;
            }
        }   
        if (count == 0) return _transactionIds;         
        _transactionIds = new uint256[](count);
        for (i=0; i<count; i++) {
            _transactionIds[i] = transactionIdsTemp[i];
        }
    }

    function getBaseInfos() external view returns (uint256, uint256, address[] memory, uint256[] memory _pendingIds, uint256[] memory _executedIds) {
        _pendingIds = getTransactionIds(0, transactionCount, true, false);
        _executedIds = getTransactionIds(0, transactionCount, false, true);
        return (transactionCount, required, owners, _pendingIds, _executedIds);
    }

    receive() external payable {}

}