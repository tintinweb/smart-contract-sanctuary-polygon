/**
 *Submitted for verification at polygonscan.com on 2022-12-01
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;



contract Control{
    



     uint[] public firstArray = [1,2,3,4,5];
  function removeItem(uint i) public{
    delete firstArray[i];
  }
address[] addressArray;
 address public richest;
   uint public mostSent;

   mapping (address => uint) pendingWithdrawals;

 




 //function transfer2(address to, uint256 amount) external whenNotPaused {      
      // require(balances[msg.sender] >= amount, "Not enough tokens");
       //balances[msg.sender] -= amount;
       //balances[to] += amount;
   //}


    //modifier whenNotPaused() {
      // require(!_paused, "Pausable: paused");
       //_;
   //}













    
    string name;       
    bool active;     

    uint64 total_weight;  
    uint64 counter_votes; 
    int64 unclaimed_points; 
    uint256 unique_key;
    uint256 weight;



    struct LeaderVoter{
        uint256 id;
        string voter_name;
        string leader;
        uint256 pct;
          uint256 unique_key;

    }
    

    struct Proposal{
        string proposal__name;
        //GIVE A SYMBOL
        uint64 symbol;
        string permission;
        //std::vector<char> packed_transaction;  Proposed transaction



    }

    struct Approver{
        string approver;
        //give timestamp datastructure 


    }

    struct approvals_info {
    string proposal_name; //!< a name of proposed multi-signature transaction
    //std::vector<approval> provided_approvals; //!< the list of approvals received from certain leaders
   // uint64_t primary_key()const { return proposal_name.value; }
   uint256 id;

}
struct invalidation {
    string  account; //!< the account whose signature in transaction is to be invalidated
    //time_point last_invalidation_time; //!< the time when the previous signature of this account was invalidated

    //uint64_t primary_key() const { return account.value; }
}

 struct stat_struct {
        uint256 id;
        uint256 retained;
        //uint64_t primary_key() const { return id; }
    }

    struct init{

    uint256 unique_symbol;
    string leader_name;
     //url a website address from where information about the candidate can be obtained, including the reasons//for her/his desire to become a leader.

    }
    struct regleader{
        //REMOVE VOTES ACTION 
        uint256 unique_symbol;

           string leader_name;
           uint256 max_votes;


    }

    struct clearvotes{
        //REMOVE VOTES FUNCTION 

      


        uint256 unique_symbol;

           string leader_name;
           uint256 max_votes;
           //condition

    }


    struct unregLeader{
         uint256 unique_symbol;

           string leader_name;
           uint256 max_votes;
//LEADER ACTIVITY



    }

    struct stopleader{
         uint256 unique_symbol;

           string leader_name;
           uint256 max_votes;
    }

    struct startleader{
 uint256 unique_symbol;

           string leader_name;
           uint256 max_votes;
    }

    struct voteleader{
 uint256 unique_symbol;

           string leader_name;
           uint256 max_votes;
    }

    struct unvote{
         uint256 unique_symbol;

           string leader_name;
           uint256 max_votes;
    }


     struct claim{
          uint256 unique_symbol;

           string leader_name;
           uint256 max_votes;

     }
}