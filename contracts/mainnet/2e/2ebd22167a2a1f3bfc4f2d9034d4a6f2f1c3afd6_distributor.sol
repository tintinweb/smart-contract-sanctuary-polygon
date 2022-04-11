/**
 *Submitted for verification at polygonscan.com on 2022-04-11
*/

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;


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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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

// File: distributor.sol

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;


contract distributor is Ownable {
    address[] public receivers;
    uint256[] public amounts;

    function setHolders(address[] calldata _addresses) public onlyOwner {
        receivers = _addresses;
    }

    receive() external payable {
        
    }

    function setAmountForEach(uint256[] calldata _amounts) public onlyOwner {
        amounts = _amounts;
    }

    function updateBoth(uint256[] calldata _amounts,address[] calldata _addresses) public onlyOwner {
        require(_addresses.length == _amounts.length,'invalid lengths');
        receivers = _addresses;
        amounts = _amounts;
    }

    function distributeToHolders() public onlyOwner {
        require(receivers.length > 0,'receivers not set');
        require(receivers.length == amounts.length,'invalid lengths');
        uint256 totalReceivers = receivers.length;
        
        for (uint256 i=0;i< totalReceivers;i++) {
            address receiver = receivers[i];
            uint256 toTransfer = amounts[i];
            payable(receiver).transfer(toTransfer);
        }
    }

    function distributeEqually() public onlyOwner {
        require(receivers.length > 0,'receivers not set');
        
        uint256 totalReceivers = receivers.length;
        uint256 toTransfer = address(this).balance/totalReceivers;
        for (uint256 i=0;i< totalReceivers;i++) {
            address receiver = receivers[i];
            
            payable(receiver).transfer(toTransfer);
        }
    }

    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }


}