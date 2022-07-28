/**
 *Submitted for verification at polygonscan.com on 2022-07-27
*/

// SPDX-License-Identifier: NONE
pragma solidity 0.6.12;


/**
 *
 * @author Himanshu Singh
*/
contract AppFees {

    address public owner;
    uint public totalFeesCollected;

    event Transfer(
        address indexed from, 
        address indexed to, 
        uint256 value
    );
    event Received(
        address indexed from, 
        address indexed to, 
        uint256 value
    );
    event OwnerSet(
        address indexed oldOwner, 
        address indexed newOwner
    );

    modifier isOwner {
        require(msg.sender == owner, "Only owner allowed!");
        _;
    }
    
    /**
     *
     * @notice constructor initializes the owner with deployers Address
    */
    constructor() public {
        owner = msg.sender; 
        emit OwnerSet(address(0), owner);
    }

    /**
     *
     * @notice receive collects all the ether sent to this smart contract
    */
    receive() external payable {
        totalFeesCollected +=msg.value;
        emit Received(msg.sender,owner, msg.value);
    }

    /**
     *
       @notice changes the cuurentOwner to new owner
       @param newOwner address of the new owner
    */
    function changeOwner(
        address newOwner
    ) external  isOwner {
        require(newOwner != address(0),"Invalid Owner Address");
        owner = newOwner;
        emit OwnerSet(owner, newOwner);
    }

    /**
     *
     * @notice transfer function is used to send some amount of ether to beneficiary
       @param beneficiary address where we want to send ether balance
       @param amount value of balance that needs to be transferred
    */
    function transfer(
        address beneficiary,
        uint256 amount
    ) external isOwner {
        require(beneficiary != address(0),"INVALID_BENEFICIARY");
        require(amount>0,"INVALID_AMOUNT");
        require(address(this).balance>amount,"INSUCCIFIENT_BALANCE");
        (bool success,) = beneficiary.call{value:amount}(new bytes(0));
        require(success, 'ETH_TRANSFER_FAILED');
        emit Transfer(owner,beneficiary, amount );
    }

    /**
     *
     * @notice fetches the current Balance of the AppFees Smart Contract
       @return balance the new current available balance of the Smart Contract
    */
    function getBalance() public view returns (
        uint
    ){
        return address(this).balance;
    }

}