/**
 *Submitted for verification at polygonscan.com on 2022-11-10
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

/// @author SOMYADITYA DEOPURIA
/// @title  A Simple value storage smart contract

contract UniTest {
    /* 
    Struct Record that stores input record address and value
     */
    struct Record {
        address inputBy;
        uint256 value;
    }

    // total number of unique wallets that have done the input
    uint256 private totalWallet;

    //total number of enteries done so far
    uint256 private totalEntries;

    // total sum of values that hae been entered by users so far 
    uint256 private totalSum;


    // array of all records of enteries made 
    Record[] private valuesRecord;

    // mapping of address to bool to check whether a user has done their first entry or not
    mapping(address=>bool) private debut;

    // event to keep a track and log of records 
    event RecordUpdated(address inputBy, uint256 value);

    /* 
    @returns total number of unique wallets that have done the entry
     */
    function getTotalUniqueWallets() public view returns(uint256){
        return totalWallet;
    }

    /* 
    @returns total number of enteries given
     */
    function getTotalEntereis() public view returns(uint256){
        return totalEntries;
    }
    /* 
    @returns total sum of the input values till now
     */
    function getTotalSum() public view returns(uint256){
        return totalSum;
    }

    /* 
    @param index of the record the that required
    @returns record stored at the given index
     */
    function getValuesRecord(uint256 index) public view returns(Record memory){
        return valuesRecord[index];
    }

    /* 
    @returns complete record of value input
     */
    function getAllRecord() public view returns(Record[] memory){
        return valuesRecord;
    }


     /* 
     @param value is the number/integer that user wants to store
     @dev stores the number in the record
     @dev increase the total wallets and total enteries count
     @dev increases the total sum 
     */
    function addNumber(uint256 value) public {
        totalEntries++;
        increaseWallet();
        totalSum += value;
        Record memory record = Record(msg.sender, value);
        valuesRecord.push(record);
        emit RecordUpdated(msg.sender, value);
    }
    /* 
    @dev increases the unique wallet counts
     */
    function increaseWallet() private { 
        if(!debut[msg.sender]){
            debut[msg.sender] = true;
            totalWallet++;
        }
    }



}