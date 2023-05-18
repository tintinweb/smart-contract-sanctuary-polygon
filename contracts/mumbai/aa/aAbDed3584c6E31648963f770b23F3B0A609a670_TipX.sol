/**
 *Submitted for verification at polygonscan.com on 2023-05-18
*/

// SPDX-License-Identifier: MIXED

// Sources flattened with hardhat v2.9.0 https://hardhat.org

// File contracts/TipX.sol

// License-Identifier: MIT
//Author: Nnamdi Umeh - https://nnamdiumeh.dev

pragma solidity ^0.8.9;

contract TipX  {
    //global counter
    uint private counter;

    struct Tip{
        uint id;
        address owner;
        string title;
        string description;
        uint maxAmount;
        bool isActive;
    }

    struct Payment{
        uint tipId;
        address owner;
        address customer;
        uint amount;
    }

    //for storing all tips created by a user
    mapping(address => Tip[]) public allUserTips;   

    //for storing all payments received from a Tip
    mapping( uint => Payment[]) public tipPayments;

    //to get a tip
    mapping(uint => Tip) allTips;

    event NewTipCreated(uint id, address indexed owner, string title, string description, uint maxAmount, bool isActive);
    event NewPaymentReceived(uint tipId, address indexed owner, address indexed customer, uint amount);
    event MakeWithdrawal(uint tipId, uint amount);

    function increment () private{
        counter = counter + 1;
    }

    //create a new tip
    function createNewTip(
        string memory _title, 
        string memory _description,
        uint _maxAmount) 
        external {
            //require(!_title && !_description && _maxAmount && _status, "All fields are required!");

            increment();
            
            //save new tip template to caller   
            allUserTips[msg.sender].push(Tip(
                counter,
                msg.sender,
                _title,
                _description,
                _maxAmount,
                true
            )); 

            allTips[counter] = Tip(
                counter,
                msg.sender,
                _title,
                _description,
                _maxAmount,
                true
            );

            //broadcast event
            emit NewTipCreated(counter, msg.sender, _title, _description, _maxAmount, true);
    }

    //get all tips created by a user
    function getUserTips() external view returns (  Tip[] memory ) {
        
        Tip[] memory userTips = new Tip[](allUserTips[msg.sender].length);
        for(uint i = 0; i < allUserTips[msg.sender].length; i++){
            userTips[i] = allUserTips[msg.sender][i];
        }
        
        return userTips;
    } 

    //get a single tip
    function getTip(uint _id) public view returns (Tip memory){
        //check if Tip exists
        Tip memory tip = allTips[_id];
        require(tip.id > 0 ,"Yikes! Not found on our blockchain.");
        return allTips[_id];
    }

    //to get all payments 
    function getTipPayments(uint _tipId) external view returns (Payment[] memory){
        require(getTip(_tipId).owner == msg.sender, "Cannot view another payments");

        Payment[] memory payments = new Payment[](tipPayments[_tipId].length);
        for(uint i = 0; i < tipPayments[_tipId].length; i++){
            payments[i] = tipPayments[_tipId][i];
        }
        
        return (payments);
    }

    //for giving tips
    function giveTip(uint _tipId) external payable {
        Tip memory tip = getTip(_tipId);
        require(msg.value > 0, "Haba! you didn't send any tip.");
        require(msg.value <= tip.maxAmount, "Too Kind! Please send a lower amount.");

        tipPayments[_tipId].push(Payment(
                _tipId,
                tip.owner,
                msg.sender,
                msg.value
            ));

        emit NewPaymentReceived(_tipId, tip.owner, msg.sender, 5);
    }

    //get total amount raised on a Tip
    function getTipTotal(uint _tipId) public view returns (uint){
        uint total = 0;
        for(uint i = 0; i < tipPayments[_tipId].length; i++){
            total += tipPayments[_tipId][i].amount;
        }
        return total;
    }

    //withdraw funds and deactivate Tip
     function withdrawMoney(uint _tipId) external payable {
        Tip memory tip = getTip(_tipId);
        uint amount = getTipTotal(_tipId);
        //checks if tip is active
        require(tip.isActive == true, "Tips is already withdrawn");
        //checks if caller is owner
        require(tip.owner == msg.sender, "No games please");
        
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Transfer failed.");

        //deactivate Tip
        allUserTips[tip.owner][_tipId - 1].isActive = false;
        allTips[_tipId].isActive = false;

        emit MakeWithdrawal(_tipId, amount);
    }
}