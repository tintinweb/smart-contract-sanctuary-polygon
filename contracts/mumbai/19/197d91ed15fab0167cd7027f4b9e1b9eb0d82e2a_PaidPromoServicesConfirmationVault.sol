/**
 *Submitted for verification at polygonscan.com on 2022-09-21
*/

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v4.6/contracts/utils/Context.sol


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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v4.6/contracts/access/Ownable.sol


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

// File: contracts-launchpad/PaidPromoServicesConfirmationVault.sol

//SPDX-License-Identifier: Unlicense


pragma solidity ^0.8.4;

contract PaidPromoServicesConfirmationVault is Ownable
{ 
    struct OrderData 
    {
        string orderId;
        string status;
        uint256 value;
        bool isCompleted;
        address promoter;
        address payer;
    }

    address nf3launchpad;
    mapping(address => bool) controllers;
    mapping (string => OrderData) private orderPools;



    function addController(address controller) external onlyOwner 
    {
        controllers[controller] = true;
    }


    function removeController(address controller) external onlyOwner 
    {
        controllers[controller] = false;
    }


    function setNF3Addr(address nf3addr) external onlyOwner 
    {
        nf3launchpad = nf3addr;
    }




    function addOrderPool( string memory _orderId, uint256 _value, address _promoter ) external payable
    {
        require(msg.value > 0, "Value can't be 0");
        require(msg.value == _value, "Values don't match");
        require(!(orderPools[_orderId].value>0), "Order already exists" );

        orderPools[_orderId] = OrderData( 
            _orderId,
            "in-progress",
            _value,
            false,
            _promoter,
            msg.sender
        );
    }

    function completeOrderPool(string memory _orderId) external payable{
        
        require(orderPools[_orderId].value>0, "Order Not Found" );
        require(!orderPools[_orderId].isCompleted, "Order already completed" );
        require(msg.sender == orderPools[_orderId].payer || msg.sender == nf3launchpad || controllers[msg.sender], "TRX not by payer / NF3");

        payable(orderPools[_orderId].promoter).transfer(orderPools[_orderId].value);

        orderPools[_orderId].status = "completed"; 
        orderPools[_orderId].isCompleted = true; 
    }

    function cancelOrderPool(string memory _orderId) external payable{
        
        require(orderPools[_orderId].value>0, "Order Not Found" );
        require(!orderPools[_orderId].isCompleted, "Order already completed" );
        require( msg.sender == nf3launchpad || controllers[msg.sender], "TRX not by NF3");

        payable(orderPools[_orderId].payer).transfer(orderPools[_orderId].value);

        orderPools[_orderId].status = "cancelled"; 
        orderPools[_orderId].isCompleted = true; 
  }

    function getOrderPool(string memory _orderId) external view  returns (OrderData memory){
        
        require(orderPools[_orderId].value>0, "Order Not Found" );
        
        return orderPools[_orderId];
    }

}