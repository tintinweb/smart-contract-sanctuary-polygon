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

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";

contract BGI_DAO is Ownable {   
    
    uint valCents; // DAO value measured in cents, //To be set on contract deployment = 71146650
    //benchmark1 = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48 "USD Coin"; 
    //benchmark2 = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2 "Wrapped Ether"
    //For further benchmarks in V1.0 simply enter the new benchmark choice when adding a member and keep an offline note of the linked address i.e. benchmark3 is link to XXXX ETH benchmark address.
    
    struct Payment {
        uint amount;
        uint timestamp;
    }

    struct Balance {
        uint totalBalance;
        uint numPayments;
        string userchoice;
        mapping(uint => Payment) payments;
    }

    mapping(address => Balance) balanceReceived;
    
    constructor() {
    }

    function valuateDAO(uint valNew) public {
        valCents = valNew;
    } // updates valuation of DAO assets

    function getDAOValue() public view onlyOwner returns (uint) {
        return valCents;
    } // returns the current valuation of the DAO assets
    
    function UserDeposit(address user, uint amount) public onlyOwner {
        balanceReceived[user].totalBalance += amount; 
        Payment memory payment = Payment(amount, block.timestamp);
        balanceReceived[user].payments[balanceReceived[user].numPayments] = payment; 
        balanceReceived[user].numPayments++;
    } // processes capital deposits to the DAO
    
    function UserwithdrawAllMoney(address user, uint amount) public onlyOwner {
        require(amount <= balanceReceived[user].totalBalance, "Not enough funds");
        require(amount == balanceReceived[user].totalBalance, "Input amount needs to match total balance"); //check
        balanceReceived[user].totalBalance = 0;
    } // processes capital withdrawals of all (single) user funds from the DAO
    
    function UserwithdrawMoney(address user, uint amount) public onlyOwner {
         require(amount <= balanceReceived[user].totalBalance, "Not enough funds");
         balanceReceived[user].totalBalance -= amount;
    }  // processes capital withdrawals of (single) user from the DAO

    function transfer(address to, address from , uint amount) public onlyOwner {
        require(amount <= balanceReceived[from].totalBalance, "Not enough funds");
        balanceReceived[from].totalBalance -= amount;
	    balanceReceived[to].totalBalance += amount;
    } // processes share transfers

    function addMember(address user, string memory _choice) public onlyOwner {
        balanceReceived[user].userchoice = _choice;
       } // adds new members to the DAO, states their chosen benchmark & countsup member count

    function getMemberChoice(address user) public view returns (string memory) {
        return balanceReceived[user].userchoice;
    } // returns the benchmark choice for a member

    function getCurrentMemberBalance(address user) public view returns (uint) {
        return balanceReceived[user].totalBalance;
    } // returns the current member balance

}