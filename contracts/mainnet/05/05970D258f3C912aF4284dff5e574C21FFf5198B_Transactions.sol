//SPDX-License-Identifier: Unlicensed 

// look into artifacts and folder there for actual abi, deployed from hardhat
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Transactions is Ownable {
    uint256 public transactionCount; 

    TransferStruct[] public transactions;
    uint256 public usersNum = 0;
    mapping(address => bool) public addressPaid; 
    uint256 public subCost = 0.0005 ether;
    address[] public users;


    event TransferFee(address _from, address _receiver, uint amount, string _message, uint256 _timestamp, string _keyword);

    struct Paid {
        address sender; 
        uint amount; 
        uint256 timestamp;
    }

    struct TransferStruct {
        address sender; 
        address receiver; 
        uint amount; 
        string message; 
        uint256 timestamp; 
        string keyword;
    }


    function addToBlockchain(address _payableReceiver, uint _amount, string memory _message, string memory _keyword) public payable  {
        transactionCount++;
        transactions.push(TransferStruct(msg.sender, _payableReceiver, _amount, _message, block.timestamp, _keyword));
        emit TransferFee(msg.sender, _payableReceiver, _amount, _message, block.timestamp, _keyword);
    }
    
    function getAllTransactions() public view returns(TransferStruct[] memory) {
        return transactions;
    }
    
    function getTransactionCount() public view returns (uint256) {
        return transactionCount;
    }

    function hasPaid(address _from) public payable returns (bool) {
        // require that the ether sent to the contract is enough for user to be added to list
        require(msg.value >= subCost, "Please Send Correct Amount");
        usersNum ++;
        // will be added to the mapping and their address will contain true, otherwise false initially
        addressPaid[_from] = true;
        return true;
    }

    function getPaidList(address _user) public returns (bool) {
        // have to get the id's from mapping, then 
        // then return that list to the user, from there the user will search
        // if they are eligible for the information that is later shown. 
        if(addressPaid[_user] == true) {
             return  addressPaid[_user];
        } 
        // return false;
    }

    // need functions for terms and subscriptions, this will initialize the address into the mapping
    // in the initialization the address will be false. when they are initially added. 

      function withdraw() public payable onlyOwner {
        
    // This will payout the owner 100% of the contract balance.
    // Do not remove this otherwise you will not be able to withdraw the funds.
    // =============================================================================
    (bool os, ) = payable(owner()).call{value: address(this).balance}("Heres Your Payout");
    require(os);
    // =============================================================================
  }

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