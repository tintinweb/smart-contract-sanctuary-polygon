// SPDX-License-Identifier: GPL-3.0

//Deployed at 0x3DFEbE23BFB3D59c9Ff384D514740FC2F0c3bAb8

pragma solidity ^0.8.0;

// Import this file to use console.log
import "@openzeppelin/contracts/access/Ownable.sol";

contract DoliFlip is Ownable{
    mapping(address => uint) private lastPlayersData;

    address[20] usersAddresses;
    uint lastAddressIndex = 0; //used to check which user data to replace

    ////////////////////////////////////////
    uint public unlockTime;
    //address payable public owner;

    function play() public payable{
        //require(msg.value >= 0.1*10**18, "You bet less then the minimum amount of coins");

        uint8 randomNumber = getRandomNumber(1, 10);

        if (randomNumber < 50000){
            //won
            transferPrize(msg.value, msg.sender);
        } else {
            //lost
            //console.log("You got rugged!");
        }

        if (lastAddressIndex < 19){
            lastAddressIndex++;
        }
        else {
            lastAddressIndex = 0;
        }
        usersAddresses[lastAddressIndex] = msg.sender;
    }

    function transferPrize(uint _amountWon, address _address) public payable {
        address payable winningAddress = payable(_address);
        
        //check if contract address can pay the prize and pay him
        if (_amountWon < address(this).balance){
            winningAddress.transfer(_amountWon);
        } else {
            winningAddress.transfer(address(this).balance);
        }
    }

    function transferLiquidityToContract() public payable {
        address payable contractAddr = payable(address(this));
        contractAddr.transfer(msg.value);
    }

    function getRandomNumber(uint8 minNumber, uint16 maxNumber) private view returns(uint8) {
        uint256 getNum = uint256(blockhash(block.number-1));
        return uint8(getNum % (maxNumber - minNumber + 1) + minNumber);
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