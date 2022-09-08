/**
 *Submitted for verification at polygonscan.com on 2022-09-07
*/

pragma solidity ^0.4.20;

contract Lottery {
    
    address owner = 0x04676381d98176ffF77b16Db0b6d13BdD163aA26;
    uint public pot;
    uint public winningsLimit;
    uint public participantLimit;
    address[] public participants;
    
    event Payout(address target, uint amount, uint nrOfParticipants);
    
    modifier onlyBy(address _account)
    {
        require(msg.sender == _account);
        _;
    }
    
    function Lottery(uint _winningsLimit, uint _participantLimit) public onlyBy(owner) {
        owner = msg.sender;
        winningsLimit = _winningsLimit;
        participantLimit = _participantLimit;
    }
    
    function () payable public {
        participants.push(msg.sender);
        pot += msg.value;
        
        if (this.balance > winningsLimit || participants.length > participantLimit) {
            terminate();
        }
    }
    
    function terminate() private {
        uint totalPayout = pot;
        pot = 0;
        
        // Take 5% for the owner (rounded down by int-division)
        uint ownerFee = totalPayout / 20;
        // Pay the rest to the winner
        uint payoutToWinner = totalPayout - ownerFee;
        
        uint winnerIndex = uint(block.blockhash(block.number-1)) % participants.length;
        address winner = participants[winnerIndex];
        
        winner.transfer(payoutToWinner);
        owner.transfer(ownerFee);
        
        Payout(winner, pot, participants.length);
        
        delete participants;
    }
    
    function murder() public onlyBy(owner) {
        if (msg.sender == owner) {
            terminate();
            
            selfdestruct(owner);
        }
    }
}