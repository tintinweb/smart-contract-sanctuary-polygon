/**
 *Submitted for verification at polygonscan.com on 2023-01-13
*/

// Sources flattened with hardhat v2.12.5 https://hardhat.org

// File @openzeppelin/contracts/token/ERC20/[email protected]

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


// File contracts/MultiSig.sol

pragma solidity ^0.8.0;

/// @title Multisig
/// @author Zartaj
/// @notice this contract serves you as a joint wallet where you and your partners can store your funds
/// safely and can only withdraw if everyone agrees on the withdrawl
/// @dev This is the base contract. Users will create wallet from the factory contract.

contract MultiSig {
    //events
    event DepositedEther(address depositor, uint amount, uint timestamp);
    event DepositedErc20(
        address depositor,
        uint amount,
        address TokenAddress,
        uint timestamp
    );
    event SubmittedErc20(
        address SubmittedBy,
        address to,
        address TokenAddress,
        uint amount,
        uint timestamp
    );
    event SubmittedEther(
        address SubmittedBy,
        address to,
        uint amount,
        uint timestamp
    );
    event Approved(address approvedBy, Transaction transaction, uint timestamp);
    event Executed(address to, Transaction transaction, uint timestamp);

    //state Variables
    uint256 requiredApproval;
    address[] owners;
    Transaction[] transactions;
    //mapppings
    mapping(address => bool) private isOwner;
    mapping(uint256 => mapping(address => bool)) private confirmed;
    mapping(uint => address) internal TokenAddress;

    //enum
    enum Type {
        ERC20,
        Ether
    }

    //structs
    struct Transaction {
        address submittedBy;
        address to;
        uint256 amount;
        bytes data;
        uint256 txIndex;
        bool executed;
        uint256 confirmCount;
        Type _type;
    }

    //modifiers
    modifier onlyOwner() {
        require(isOwner[msg.sender], "you are not an owner");
        _;
    }

    modifier txExist(uint256 _txIndex) {
        require(_txIndex < transactions.length, " transaction doesn't exist");
        _;
    }
    modifier notExecuted(uint256 _txIndex) {
        require(!transactions[_txIndex].executed, "Already executed");
        _;
    }
    modifier notConfirmed(uint256 _txIndex) {
        require(!confirmed[_txIndex][msg.sender], "Already confirmed");
        _;
    }

    //constructor
    constructor(address[] memory _owners, uint256 _required) {
        require(_owners.length > 1, "must be mmore than 1 owner");
        require(
            _owners.length >= _required && _required > 0,
            "Invalid require input"
        );
        for (uint256 i = 0; i < _owners.length; i++) {
            address owner = _owners[i];

            require(owner != address(0), "invalid address");
            require(!isOwner[owner], "Owner is already added");

            isOwner[owner] = true;
            owners.push(owner);
        }

        requiredApproval = _required;
    }

    function allTxs() external view returns (Transaction[] memory) {
        return transactions;
    }

    //view functions
    function singleTx(uint _index) external view returns (Transaction memory) {
        return transactions[_index];
    }

    function balanceErc20(address ERC20) public view returns (uint) {
        return IERC20(ERC20).balanceOf(address(this));
    }

    //write functions
    function submitERC20Tx(
        address _to,
        address ERC20,
        uint _amount,
        bytes memory _data
    ) external {
        uint balance = balanceErc20(ERC20);

        require(_amount <= balance, "Not enough balance");
        uint256 _txIndex = transactions.length;

        confirmed[_txIndex][msg.sender] = true;

        transactions.push(
            Transaction({
                submittedBy: msg.sender,
                to: _to,
                amount: _amount,
                data: _data,
                txIndex: _txIndex,
                executed: false,
                confirmCount: 1,
                _type: Type.ERC20
            })
        );

        TokenAddress[_txIndex] = ERC20;

        emit SubmittedErc20(msg.sender, _to, ERC20, _amount, block.timestamp);
    }

    function submitEtherTx(
        address _to,
        uint256 _amount,
        bytes calldata _data
    ) external onlyOwner {
        uint256 _txIndex = transactions.length;

        confirmed[_txIndex][msg.sender] = true;

        transactions.push(
            Transaction({
                submittedBy: msg.sender,
                to: _to,
                amount: _amount,
                data: _data,
                txIndex: _txIndex,
                executed: false,
                confirmCount: 1,
                _type: Type.Ether
            })
        );

        emit SubmittedEther(msg.sender, _to, _amount, block.timestamp);
    }

    function approveTx(
        uint256 _txIndex
    )
        external
        onlyOwner
        txExist(_txIndex)
        notExecuted(_txIndex)
        notConfirmed(_txIndex)
    {
        confirmed[_txIndex][msg.sender] = true;
        transactions[_txIndex].confirmCount += 1;
        if (transactions[_txIndex].confirmCount == requiredApproval) {
            executeTx(_txIndex);
        }
        emit Approved(msg.sender, transactions[_txIndex], block.timestamp);
    }

    function executeTx(uint256 _txIndex) internal notExecuted(_txIndex) {
        Transaction storage transaction = transactions[_txIndex];

        if (transaction._type == Type.Ether) {
            transaction.executed = true;
            (bool result, ) = transaction.to.call{value: transaction.amount}(
                ""
            );

            require(result, " tx failed ");
        } else {
            address token = TokenAddress[_txIndex];

            IERC20(token).transfer(transaction.to, transaction.amount);
        }
        emit Executed(transaction.to, transaction, block.timestamp);
    }

    receive() external payable {
        emit DepositedEther(msg.sender, msg.value, block.timestamp);
    }
}