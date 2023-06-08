// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract Escrow {
    
    address public owner;
    uint public totalEscrows;
    uint public companyProfit;

    struct Escrows {
        uint id;
        address assignor;
        address assignee;
        uint amount;
        string details;
        string title;
        bool accepted;
        bool started;
        bool completed;
        bool approved;
        bool cancelled;
    }
    mapping(uint => Escrows) public escrows;

    constructor() {
        owner = msg.sender;
    }


    modifier onlyAssignor(uint _id){
        require(escrows[_id].assignor == msg.sender, "You are not creator of this contract");
        _;
    }
    modifier onlyOwner(){
        require(msg.sender == owner, "You are not owner of this contract");
        _;
    }
    modifier contractExist(uint _id){
        require(_id <= totalEscrows);
        _;
    }
    modifier onlyAssignee(uint _id){
        require(escrows[_id].assignee == msg.sender, "You are not creator of this contract");
        _;
    }

    event ContractCreated(uint indexed id, address indexed assignor, address indexed assignee);
    event ContractAccepted(uint indexed id, address indexed assignor, address indexed assignee);
    event ContractCompleted(uint indexed id, address indexed assignor, address indexed assignee);
    event ContractStarted(uint indexed id, address indexed assignor, address indexed assignee);
    event ContractEnded(uint indexed id, address indexed assignor, address indexed assignee);
    event ContractCancelled(uint indexed id, address indexed assignor, address indexed assignee);

    function createContract(address _assignee, uint _amount, string memory _details, string memory _title) public returns (bool){
        require(_assignee != address(0), "Invalid assignee address");
        require(_amount > 0, "Amount must be greater than zero");

        Escrows memory tmpEscrow = Escrows(
            totalEscrows,
            msg.sender,
            _assignee,
            _amount,
            _details,
            _title,
            false,
            false,
            false,
            false,
            false
        );
        escrows[totalEscrows] = tmpEscrow;
        emit ContractCreated(totalEscrows, msg.sender, _assignee);
        totalEscrows += 1;
        
        return true;
        
    }

    function acceptContract(uint _id) public onlyAssignee(_id) contractExist(_id) returns (bool){
        escrows[_id].accepted = true;
        emit ContractAccepted(_id, escrows[_id].assignor, escrows[_id].assignee);
        return true;
    }

    function startContract(uint _id) public payable onlyAssignor(_id) contractExist(_id) returns (bool){
        require(msg.value >= escrows[_id].amount, "Not enough funds");
        
        escrows[_id].started = true;
        emit ContractStarted(_id, escrows[_id].assignor, escrows[_id].assignee);
        return true;
    }
    
    function completeContract(uint _id) public onlyAssignee(_id) contractExist(_id) returns (bool){
        escrows[_id].completed = true;
        emit ContractCompleted(_id, escrows[_id].assignor, escrows[_id].assignee);
        return true;
    }
    
    function approveContract(uint _id) public onlyAssignor(_id) contractExist(_id) returns (bool){
        require(escrows[_id].completed, "Contract not completed");

        uint amount = escrows[_id].amount;
        uint commission = (amount * 2) / 100;
        uint assigneeAmount = amount - commission;

        companyProfit = companyProfit + commission;

        (bool success, ) = address(escrows[_id].assignee).call{value : assigneeAmount}("");
        require(success, "Amount not sent");

        escrows[_id].approved = true;
        emit ContractEnded(_id, escrows[_id].assignor, escrows[_id].assignee);
        return true;

    }

    function cancelContract(uint _id) public onlyAssignor(_id) contractExist(_id) returns (bool){
        
        escrows[_id].cancelled = true;

        emit ContractCancelled(_id, escrows[_id].assignor, escrows[_id].assignee);
        return true;

    }

    function getMyContractsAssignor() public view returns(Escrows[] memory ){
        Escrows[] memory contracts = new Escrows[](totalEscrows);
        uint counter = 0;
        for (uint i = 0; i < totalEscrows; i++){
            if (escrows[i].assignor == msg.sender){
                contracts[counter] = escrows[i];
            }
            counter += 1;
        }
        return contracts;
    }

    function getMyAssignedContractAssignor() public view returns(Escrows[] memory ){
        Escrows[] memory contracts = new Escrows[](totalEscrows);
        uint counter = 0;
        for (uint i = 0; i < totalEscrows; i++){
            if (escrows[i].assignor == msg.sender){
                if (escrows[i].started){
                    contracts[counter] = escrows[i];
                }
                
            }
            counter += 1;
        }
        return contracts;
    }

    function getMyContractsAssignee() public view returns(Escrows[] memory ){
        Escrows[] memory contracts = new Escrows[](totalEscrows);
        uint counter = 0;
        for (uint i = 0; i < totalEscrows; i++){
            if (escrows[i].assignee == msg.sender){
                contracts[counter] = escrows[i]; 
            }
            counter += 1;
        }
        return contracts;
    }

    function getMyAssignedContractsAssignee() public view returns(Escrows[] memory ){
        Escrows[] memory contracts = new Escrows[](totalEscrows);
        uint counter = 0;
        for (uint i = 0; i < totalEscrows; i++){
            if (escrows[i].assignee == msg.sender){
                if (escrows[i].started){
                    contracts[counter] = escrows[i];
                }
            }
            counter += 1;
        }
        return contracts;
    }

    
    
    function changeOwner(address _newOwner) public onlyOwner {
        owner = _newOwner;
    }

    function withdrawProfit(uint _amount) public onlyOwner{
        
        require(_amount <= companyProfit, "You cannot withdraw funds more than your commission");
        require(_amount <= address(this).balance, "Funds not available");

        (bool success, ) = owner.call{value:_amount}("");
        require(success, "Amount not sent");
    }

    function withdrawCompleteCommission() public onlyOwner{
        require(companyProfit <= address(this).balance, "Funds not available");
        
        (bool success, ) = owner.call{value:companyProfit}("");
        require(success, "Amount not sent");
    }

    


}