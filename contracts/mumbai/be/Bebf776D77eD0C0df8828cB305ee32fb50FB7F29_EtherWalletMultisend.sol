/**
 *Submitted for verification at polygonscan.com on 2022-08-03
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract EtherWalletMultisend is Ownable {
    // VARIABLES
    struct BalanceDetails {
        uint256 balance;
        bool isLocked;
        bool isClient;
    }
    struct MultipleSendBody {
        uint256 amount;
        address receiverAddress;
    }

    uint256 saveFee;
    bool private isLocked = false;
    mapping(address => BalanceDetails) private balances;

    constructor(uint256 _saveFee) {
        saveFee = _saveFee;
    }

    // MODIFIERS
    modifier notLocked() {
        require(!balances[_msgSender()].isLocked, "Your account is locked");
        _;
    }

    modifier enoughFund(uint256 _amount) {
        require(
            balances[_msgSender()].balance >= _amount,
            "You have no enough fund in your balance"
        );
        _;
    }

    modifier enoughFundForTransaction(uint256 _amount) {
        require(
            balances[_msgSender()].balance >= _amount,
            "You have no enough fund in your balance for transferring money to other client"
        );
        _;
    }

    modifier enoughFundForMultiSend(uint256 totalAmount) {
        require(
            balances[_msgSender()].balance >= totalAmount,
            "You have no enough fund in your balance to fullfil multisend ether"
        );
        _;
    }

    modifier onlyClient() {
        require(balances[_msgSender()].isClient, "You have no wallet yet");
        _;
    }

    modifier notZeroAmount(uint256 amount) {
        require(
            amount > 0,
            "You have to use more than 0 ETH for any transaction"
        );
        _;
    }

    modifier notZeroAddress(address _address) {
        require(
            _address != address(0),
            "Given address should not be zero address"
        );
        _;
    }

    // EVENTS
    event WithdrawFund(uint256 _amount, address _address);
    event DepositSuccessful(uint256 _amount, address _address);
    event TransferSuccessful(address from, address to, uint256 amount);
    event MultiTransferSuccessful(
        address from,
        MultipleSendBody[] to,
        uint256 amount
    );
    event MultiTransferAnySuccessful(
        address from,
        MultipleSendBody[] to,
        MultipleSendBody[] unsendReceivers
    );

    // FUNCTIONS
    function addClient(address client) public onlyOwner notZeroAddress(client) {
        BalanceDetails memory newBalance = BalanceDetails({
            balance: 0,
            isLocked: false,
            isClient: true
        });
        balances[client] = newBalance;
    }

    function withdraw(uint256 _amount)
        external
        notLocked
        onlyClient
        enoughFund(_amount)
        notZeroAmount(_amount)
    {
        unchecked {
            balances[_msgSender()].balance -= _amount;
        }

        payable(_msgSender()).transfer(_amount);

        emit WithdrawFund(_amount, _msgSender());
    }

    function withdrawAll() external notLocked onlyClient {
        uint256 tempBalance = balances[_msgSender()].balance;

        unchecked {
            balances[_msgSender()].balance = 0;
        }
        payable(_msgSender()).transfer(tempBalance);

        emit WithdrawFund(tempBalance, _msgSender());
    }

    function deposit() external payable onlyClient {
        require(msg.value > 0, "You have to deposit more than 0 ETH");

        unchecked {
            balances[_msgSender()].balance += (msg.value -
                ((msg.value * saveFee) / 100));
        }

        emit DepositSuccessful(msg.value, _msgSender());
    }

    function transferToOtherClient(uint256 _amount, address receiver)
        external
        notLocked
        onlyClient
        notZeroAmount(_amount)
        notZeroAddress(receiver)
        enoughFundForTransaction(_amount)
    {
        unchecked {
            balances[_msgSender()].balance -= _amount;
            balances[receiver].balance += _amount;
        }

        emit TransferSuccessful(_msgSender(), receiver, _amount);
    }

    function multipleSend(MultipleSendBody[] memory addresses, uint256 totalAmount)
        external
        notLocked
        onlyClient
        enoughFundForMultiSend(totalAmount)
        returns (MultipleSendBody[] memory)
    {
        MultipleSendBody[] memory unsendAddresses;

        for (uint256 i = 0; i < addresses.length; i++) {
            uint256 currentBalance = balances[_msgSender()].balance;
            MultipleSendBody memory currentReceiver = addresses[i];

            if (currentBalance < currentReceiver.amount) {
                unsendAddresses[unsendAddresses.length] = currentReceiver;
                continue;
            }

            unchecked {
                balances[_msgSender()].balance -= currentReceiver.amount;
                balances[currentReceiver.receiverAddress]
                    .balance += currentReceiver.amount;
            }
        }

        emit MultiTransferAnySuccessful(
            _msgSender(),
            addresses,
            unsendAddresses
        );

        return unsendAddresses;
    }

    function getBalance() public view onlyClient returns (uint256) {
        return balances[_msgSender()].balance;
    }

    function getContractBalance() public view onlyOwner returns (uint256) {
        return address(this).balance;
    }

    function lockWithdraw() external onlyClient {
        require(
            !balances[_msgSender()].isLocked,
            "Your Balance is already locked"
        );
        balances[_msgSender()].isLocked = true;
    }

    function unlockWithdraw() external onlyClient {
        require(
            balances[_msgSender()].isLocked,
            "Your Balance is already unlocked"
        );
        balances[_msgSender()].isLocked = false;
    }
}