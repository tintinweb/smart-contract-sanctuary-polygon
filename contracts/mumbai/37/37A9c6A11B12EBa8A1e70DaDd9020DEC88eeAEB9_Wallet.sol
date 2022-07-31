//SPDX-License-Identifier: MIT;

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Wallet{

    address owner;

    constructor(){
          owner = msg.sender;
    }
       
    enum Transection{
        Debit,
        Credit
        }
   

    struct Payment {
        uint amount;
        uint timestamp;
        Transection Transct;
    }

    struct Balance {
        uint totalBalance;
        uint numPayments;
        uint allowance;
        mapping(uint => Payment) payments;
    }

    mapping(address => Balance) public balanceReceived;

    event credit(address Account, uint Amount, uint time, Transection txn);
    event debit(address Account, uint Amount, uint time, Transection txn);

    modifier ownerOrAllowed(uint256 _amount){
        
         require(msg.sender == owner||balanceReceived[msg.sender].allowance >= _amount,"You are not allowed to perform this operation.");
        _;
    }

    modifier owneronly(){
        require(msg.sender == owner,"You are not owner");
        _;
    }

    function sendMoney() public payable {
        balanceReceived[msg.sender].totalBalance += msg.value;

        Payment memory payment = Payment(msg.value, block.timestamp,Transection.Credit);
        balanceReceived[msg.sender].payments[balanceReceived[msg.sender].numPayments] = payment;
        balanceReceived[msg.sender].numPayments++;
        emit credit(msg.sender,msg.value,payment.timestamp,payment.Transct);
    }

     function setAllowance(address _address, uint256 _allowance) public owneronly{
      balanceReceived[_address].allowance = _allowance;
    }

    function withdrawMoney(address payable _to,uint256 _amount) public ownerOrAllowed(_amount) {
        _to.transfer(_amount);
        balanceReceived[msg.sender].totalBalance -= _amount;
        Payment memory payment = Payment(_amount, block.timestamp,Transection.Debit);
        balanceReceived[msg.sender].payments[balanceReceived[msg.sender].numPayments] = payment;
        balanceReceived[msg.sender].numPayments++;
        emit debit(msg.sender,_amount,payment.timestamp,payment.Transct);
        
    }

    function transferOwnership(address _this) public owneronly{
        owner = _this;
    }

    function isOwner(address _this) public view returns(bool){
           return _this == owner;
    }

    function getBalance() public view returns(uint) {
        return address(this).balance;
    }

    function getAllowance(address _addrs) public view returns(uint) {
        require(msg.sender== _addrs||msg.sender == owner);
        return balanceReceived[_addrs].allowance;
    }

    function getaAccountBalance() public view returns(uint256){
        return (balanceReceived[msg.sender].totalBalance);
    }



    // Function to receive Ether. msg.data must be empty
      receive() external payable {}

      // Fallback function is called when msg.data is not empty
      fallback() external payable {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}