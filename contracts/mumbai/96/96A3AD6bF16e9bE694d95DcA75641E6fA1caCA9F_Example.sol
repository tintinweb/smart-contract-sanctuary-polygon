// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
    EXAMPLE CONTRACT
    It shows how to develop, test and deply contracts
 */
 contract Example{
    // All fields should be public unless there is a reason for settin it private
    // Fields must be grouped by types(all addresses, all bool all uint256 and so on) so they would be stored more efficiently
    address public owner; //All contract fields must be documented.  
    uint256 public counter; // use 'uint256' instead of 'uint'

    // Events are necessary and must be defined with care. Index only relevant fields
    event ChangeOwnerEvent(address indexed oldOwner, address indexed newOWner, uint256 timestamp);

    modifier onlyOwner(){
        require(msg.sender == owner,"Restrict this msg to 32 chars");
        _;
    }

    /**
        Constructor
        @param _owner Params are always preceded with a '_'
     */
    constructor(address _owner){
        owner=_owner;
    }

    /**
        @notice Increments counter 
        @notice It is better to use 'external' modifier than 'public' as require less gas to execute
        @param _increment Amount to increment 
     */
    function incrementIn(uint256 _increment) external {
        counter += _increment; //Overflow validation not needed in solidity version >= 0.8.0
    }

    /**
        @notice Change contract ownership
        @notice Restricted to owner
        @notice emit ChangeOwnerEvent
        @param _newOwner new owner address
     */
    function changeOwner(address _newOwner) external onlyOwner{
        address oldOwner = owner;
        owner = _newOwner;
        emit ChangeOwnerEvent(oldOwner,owner,block.timestamp);
    }    

    /**
        @notice get Counter Value
        @notice it can be 'public' as it is a view function
        @return counterValue Current counter value 
     */
    function getCounterValue() public view returns(uint256 counterValue){
        return counter;
    }
     
 }