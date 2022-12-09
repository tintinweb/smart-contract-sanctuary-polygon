/**
 *Submitted for verification at polygonscan.com on 2022-12-08
*/

// SPDX-License-Identifier: GPL-3.0
// File: https://github.com/pkdcryptos/OpenZeppelin-openzeppelin-solidity/blob/master/contracts/ownership/Ownable.sol

pragma solidity ^0.5.2;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @return the address of the owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner());
        _;
    }

    /**
     * @return true if `msg.sender` is the owner of the contract.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Allows the current owner to relinquish control of the contract.
     * It will not be possible to call the functions with the `onlyOwner`
     * modifier anymore.
     * @notice Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: contracts/sharedwallet.sol



   pragma solidity ^0.5.17;


  contract Allowance is Ownable{
    event allowancechange(address indexed _forwho,address indexed _fromwhom,uint _oldamount , uint _newamount);

    mapping(address => uint) public allowance;
    
    function addallowance(address _who,uint _amount) public {
        emit allowancechange(_who,msg.sender,allowance[_who],_amount);
        allowance[_who]= _amount;
    }

        modifier ownerorallowed(uint _amount){
        require(isOwner() || allowance[msg.sender] >= _amount,"you are not allowed");
        _;
    }

    function reduceallowance(address _who,uint _amount) internal {
        emit allowancechange(_who,msg.sender,allowance[_who],_amount);
        allowance[_who]-=_amount;
    }
}
 pragma solidity ^0.5.17;
   // import "./Allowance.sol";

    contract Simplewallet is Allowance{

    //   address public owner;

    //  constructor() public {
    //      owner=msg.sender;
    //  }
    event moneysend(address indexed _beneficiary,uint _amount);
    event moneyreceived(address indexed _from,uint _amount);
    
     function withdrawMoney(address payable _to,uint _amount) public ownerorallowed(_amount){
         require(_amount <= address(this).balance,"not enough funds in smart contract");
        //  require(owner == msg.sender ,"you are not allowed");
        if(!isOwner()){
            reduceallowance(msg.sender,_amount);
        }
        emit moneysend(_to,_amount);
         _to.transfer(_amount);
     }

     function renounceOwnership() public onlyOwner {
         revert("can't renounce ownership");
     }


     function () external payable {
        emit moneyreceived(msg.sender,msg.value);
     }

 }