// SPDX-License-Identifier: MIT
pragma solidity =0.8.14;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title Management of Funder.
 * @author Freeverse.io, www.freeverse.io
 * @dev The ...
 */

contract Funder is Ownable {
    /**
     * @dev Event emitted on change of default operator
     * @param operator The address of the new default operator
     * @param prevOperator The previous value of operator
     */
    event DefaultOperator(address indexed operator, address indexed prevOperator);

    uint256 constant MAX_INT = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

    address[] private _addr;

    constructor(address[] memory initialAddresses) {
        for (uint16 i = 0; i < initialAddresses.length; i++) {
            _addr.push(initialAddresses[i]);
        }
    }

    function addAddress(address newAddress) onlyOwner public {
        for (uint16 i = 0; i < _addr.length; i++) {
            require(_addr[i] != newAddress, 'addAddress: address already exists');
        }
        _addr.push(newAddress);
    } 
    

    function removeAddr(address addr) onlyOwner public {
        removeAddrAtIdx(idxOfAddress(addr));
    }

    function removeAddrAtIdx(uint16 idx) onlyOwner public {
        for (uint16 i = idx; i < _addr.length - 1; i++) {
            _addr[i] = _addr[i+1];
        }
        _addr.pop();        
    }

    function fund() public payable {
        // the target is the new average
        uint256 target = (sumBalances() + msg.value)/_addr.length;

        uint256 remainder = msg.value;

        for (uint16 i = 0; i < _addr.length; i++) {
            if (remainder == 0) return;

            uint256 prevBalance = _addr[i].balance;
            // only fund if below new average
            if (target > prevBalance) {
                uint256 fundsForThisAddr = target - prevBalance;
                if (fundsForThisAddr > remainder) fundsForThisAddr = remainder;
                remainder -= fundsForThisAddr;
                (bool success, ) = _addr[i].call{value: fundsForThisAddr}("");
                require(success, "fund: unable to send value, recipient may have reverted");
            }
        }
    }

    // View functions

    function sumBalances() public view returns(uint256) {
        uint256 sum;
        for (uint16 i = 0; i < _addr.length; i++) {
            sum += _addr[i].balance;
        }
        return sum;        
    }

    function lowestBalance() public view returns(uint256) {
        uint256 lowest = MAX_INT;
        for (uint16 i = 0; i < _addr.length; i++) {
            uint256 thisBalance = _addr[i].balance;
            if (thisBalance < lowest) lowest = thisBalance;
        }
        return lowest;        
    }

    function idxOfAddress(address addr) public view returns (uint16 idx) {
        for (uint16 i = 0; i < _addr.length; i++) {
            if (_addr[i] == addr) return i;
        }
        revert('idxOfAddress: address not in list');
    }

    function balance(address addr) public view returns(uint256) {
        return addr.balance;
    }    

    function balances() public view returns(uint256[] memory allBalances) {
        uint256 nAddr = _addr.length;
        allBalances = new uint256[](nAddr);
        for (uint16 i = 0; i < nAddr; i++) {
            allBalances[i] = _addr[i].balance;
        }
        return allBalances;
    }    

    function balanceOfAddrAtIndex(uint256 idx) public view returns(uint256) {
        return _addr[idx].balance;
    }    

    function addresses() public view returns(address[] memory) {
        return _addr;
    }    

    function nAddresses() public view returns(uint256 n) {
        return _addr.length;
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