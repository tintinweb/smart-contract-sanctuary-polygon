/**
 *Submitted for verification at polygonscan.com on 2023-05-18
*/

//SPDX-License-Identifier:MIT

pragma solidity ^0.8.1;

//  string ["prop1","prop2",..., "prop5","prop6"]
//  bytes32 ["0x70726F706F73616C310000000000000000000000000000000000000000000000","0x70726F706F73616C320000000000000000000000000000000000000000000000","0x70726F706F73616C330000000000000000000000000000000000000000000000","0x70726F706F73616C340000000000000000000000000000000000000000000000","0x70726F706F73616C350000000000000000000000000000000000000000000000","0x70726F706F73616C360000000000000000000000000000000000000000000000"]
// deployed on polygon testnet  0x01e9e7dc13bd6ab7cbb74d0c4674a0e545cc8a37

contract VotingDapp {

    struct Voter {
        uint vote;
        bool anyvotes;
        uint value;
    }

    struct Proposal{
        bytes32 name;
        uint voteCount;
    }

    Proposal [] public proposals;

    mapping(address => Voter) public voters;

    address public authenticator;

    constructor (bytes32 [] memory proposalNames) {
        
        authenticator = msg.sender;

        voters[authenticator].value = 1;

        for (uint i=0; i <
            
            proposalNames.length; i++) {
                proposals.push(Proposal({
                    name:proposalNames[i],
                    voteCount: 0
                }));
            }
    }

    //Function to authenticate votes
    function giveRightToVote(address voter) public {
        require(msg.sender == authenticator,
        'Only the authenticator gives access to vote');

        //require that voter hasn't voted yet

        require(!voters[voter].anyvotes,
        
        'The voter has already voted');
        require(voters[voter].value == 0);
        voters[voter].value = 1;
    }

    // Function to delegate voting right
    function delegateRightToVote(address delegate) public { 
        Voter storage _delegate =
        voters[delegate];

        Voter storage _delegatee =
        voters[msg.sender];

        require(delegate != address(0), 'You can not delegate to null address');

        require(delegate != msg.sender, 'You can not delegate urself');

        require(_delegatee.value !=0, 'You have no voting right to delegate');

        require(!_delegatee.anyvotes, 'Already voted');
      
        require(!_delegate.anyvotes, 'You can not delegate voting rights to who has voted');
      
        _delegate.value += _delegatee.value;

        _delegatee.value = 0;

    }
  
    //Function for voting

    function vote (uint proposal) public{

        Voter storage sender =
        voters[msg.sender];

        require(sender.value !=0, 'Has no right to vote');

        require(!sender.anyvotes, 'Already voted');

        sender.anyvotes = true;
        sender.vote = proposal;

        proposals[proposal].voteCount = proposals[proposal].voteCount + sender.value;

        }

        //functions for showing results

        // 1. function that shows the winning proposal by integer

        function winningProposal() public
        view returns (uint
        winningProposal_) {
            uint winningVoteCount = 0;
            for(uint i=0; i <proposals.length; 
            
            i++)

            {
                if(proposals[i].voteCount >
                winningVoteCount) {
                    winningVoteCount =

                proposals[i].voteCount;
                winningProposal_=i;

                
            }
            
        }

    }

        //2. function that shows the winner by name

        function winningName() public view returns (bytes32 winningName_) {
            winningName_ =

            proposals[winningProposal()].name;
        }
}