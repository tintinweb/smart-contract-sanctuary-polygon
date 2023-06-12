// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract MontyPyMultiSigWallet  {
    event Deposit(
        address indexed sender,
        uint indexed amount,
        uint indexed balance
    );
    event SubmitTransaction(
        address indexed owner,
        uint indexed txIndex,
        address indexed to,
        uint value
    );
    event ConfirmTransaction(
        address indexed owner,
        uint indexed txIndex,
        uint indexed numConfirmations
    );
    event RevokeConfirmation(
        address indexed owner,
        uint indexed txIndex,
        uint indexed numConfirmations
    );
    event ExecuteTransaction(
        address indexed owner,
        uint indexed txIndex,
        address indexed to,
        uint value,
        bool executed    
    );
    event AddOwner(address indexed addedBy, address indexed newOwner);
    event UpdateNumberOfConfirmationsRequired(address indexed updatedBy, uint indexed updatedNumberOfConfirmationsRequired);

    struct Transaction {
        address to;
        uint value;
        bool executed;
        uint numConfirmations;
    }

    uint private numberOfConfirmationsRequired;
    Transaction[] private transactions;
    address[] private owners;
    mapping(address => bool) private isOwner;
    mapping(uint => mapping(address => bool)) private isConfirmed;
    
    modifier onlyOwner() {
        require(isOwner[msg.sender], "not owner");
        _;
    }

    modifier txExists(uint _txIndex) {
        require(_txIndex < transactions.length, "transaction does not exist");
        _;
    }

    modifier notExecuted(uint _txIndex) {
        require(!transactions[_txIndex].executed, "transaction already executed");
        _;
    }

    modifier notConfirmed(uint _txIndex) {
        require(!isConfirmed[_txIndex][msg.sender], "transaction already confirmed");
        _;
    }

    constructor(address[] memory _owners, uint _numberOfConfirmationsRequired) {

        require(_owners.length > 0, "owners required");
        require(
            _numberOfConfirmationsRequired > 0 &&
                _numberOfConfirmationsRequired <= _owners.length,
            "invalid number of required confirmations"
        );
        for (uint i = 0; i < _owners.length; i++) {
            address owner = _owners[i];

            require(owner != address(0), "invalid owner");
            require(!isOwner[owner], "owner not unique");

            isOwner[owner] = true;
            owners.push(owner);
        }

        numberOfConfirmationsRequired = _numberOfConfirmationsRequired;
    }

    receive() external payable {
        emit Deposit(msg.sender, msg.value, address(this).balance);
    }

    function submitTransaction(
        address _to,
        uint _value
    ) public onlyOwner {
        uint txIndex = transactions.length;
        require(_value > 0, "Amount must be greater than 0");
        transactions.push(
            Transaction({
                to: _to,
                value: _value,
                executed: false,
                numConfirmations: 0
            })
        );

        emit SubmitTransaction(msg.sender, txIndex, _to, _value);

        transactions[txIndex].numConfirmations += 1;
        isConfirmed[txIndex][msg.sender] = true;

        emit ConfirmTransaction(msg.sender, txIndex, transactions[txIndex].numConfirmations);
    }

    function confirmTransaction(
        uint _txIndex
    ) public onlyOwner txExists(_txIndex) notExecuted(_txIndex) notConfirmed(_txIndex) {
        transactions[_txIndex].numConfirmations += 1;
        isConfirmed[_txIndex][msg.sender] = true;
        emit ConfirmTransaction(msg.sender, _txIndex, transactions[_txIndex].numConfirmations);
    }

    function executeTransaction(
        uint _txIndex,
        address paymentTokenAddress
    ) public onlyOwner txExists(_txIndex) notExecuted(_txIndex) {
        require(
            transactions[_txIndex].numConfirmations >= numberOfConfirmationsRequired,
            "cannot execute tx"
        );

        transactions[_txIndex].executed = true;

        require(transactions[_txIndex].value > 0, "Amount must be greater than 0");

        bool success = IERC20(paymentTokenAddress).transfer(transactions[_txIndex].to, transactions[_txIndex].value);

        require(success, "Token transfer failed");

        emit ExecuteTransaction(
            msg.sender,
            _txIndex,
            transactions[_txIndex].to,
            transactions[_txIndex].value,
            transactions[_txIndex].executed
        );
    }

    function revokeConfirmation(
        uint _txIndex
    ) public onlyOwner txExists(_txIndex) notExecuted(_txIndex) {
        require(isConfirmed[_txIndex][msg.sender], "transaction was not confirmed from your account!");

        transactions[_txIndex].numConfirmations -= 1;
        isConfirmed[_txIndex][msg.sender] = false;

        emit RevokeConfirmation(msg.sender, _txIndex, transactions[_txIndex].numConfirmations);
    }

    function getTransactionCount() public view returns (uint) {
        return transactions.length;
    }

    function getTransaction(
        uint _txIndex
    )
        public
        view
        txExists(_txIndex)
        returns (
            address to,
            uint value,
            bool executed,
            uint numConfirmations
        )
    {
        return (
            transactions[_txIndex].to,
            transactions[_txIndex].value,
            transactions[_txIndex].executed,
            transactions[_txIndex].numConfirmations
        );
    }

    function addOwner(address _newOwner) public onlyOwner {
        require(_newOwner != address(0), "invalid owner");
        require(!isOwner[_newOwner], "owner already exists");

        isOwner[_newOwner] = true;
        owners.push(_newOwner);

        emit AddOwner(msg.sender, _newOwner);
    }

    function getOwners() public view returns (address[] memory) {
        return owners;
    }

    function getTokenBalance(address _tokenAddress)
        public
        view
        returns(uint256 tokenBalance)
    {
        return IERC20(_tokenAddress).balanceOf(address(this));
    }

    function getNumberOfConfirmationsRequired() public view returns(uint256 _numberOfConfirmationsRequired){
        return numberOfConfirmationsRequired;
    }

    function updateNumberOfConfirmationsRequired(uint _numberOfConfirmationsRequired) public onlyOwner {
        require(_numberOfConfirmationsRequired > 0 && _numberOfConfirmationsRequired <= owners.length, "invalid number of required confirmations");
        numberOfConfirmationsRequired = _numberOfConfirmationsRequired;
        emit UpdateNumberOfConfirmationsRequired(msg.sender, _numberOfConfirmationsRequired);
    }
}