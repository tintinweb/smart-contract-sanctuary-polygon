/**
 *Submitted for verification at polygonscan.com on 2023-02-15
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract Expenser {

    // Defining all the variables
    address owner;
    uint256 count=0;
    mapping (uint256=>Expense) public expenseList;
    struct Expense {
        string title;
        string category;
        uint256 amount;
        uint256 timestamp;
    }

    // events
    event ExpenseAdded(uint256,string,string,uint256);
    event ExpenseModified(uint256,string,string,uint256);
    event ExpenseDeleted(uint256);

    constructor() {
        owner = msg.sender;
    }

    // Defining all the view functions
    function viewExpenseById(uint256 _id) public view returns (Expense memory) {
         return expenseList[_id];
    }

    function getAllExpenses() public view returns (Expense[] memory){
      Expense[] memory allExpenses = new Expense[](count);
      for (uint i = 0; i <count; i++) {
          Expense storage expense = expenseList[i];
          allExpenses[i] = expense;
          
      }
         return allExpenses;
    }


    // Defining all the write functions
    function addExpense(string memory _title,string memory _category, uint256 _amount) public {
        expenseList[count] = Expense({
            title: _title,
            category: _category,
            amount: _amount,
            timestamp:block.timestamp
        });
        count+=1;
        emit ExpenseAdded(count,_title,_category,_amount);
    }

  function modifyExpense(uint256 _id,string memory _title,string memory _category, uint256 _amount) public {
        require(_id<=count,"Expense does not exist in the list");
        expenseList[_id] = Expense({
            title: _title,
            category: _category,
            amount: _amount,
            timestamp:block.timestamp
        });
        emit ExpenseModified(_id,_title,_category,_amount);
        
    }

    function deleteExpense(uint256 _id) public {
        require(_id<count,"Expense does not exist in the list");
        delete expenseList[_id];
        emit ExpenseDeleted(_id);
     
    }
  



}