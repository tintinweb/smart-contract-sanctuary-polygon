/**
 *Submitted for verification at polygonscan.com on 2023-04-18
*/

pragma solidity ^0.8.0;

// Quiz in solidity giving a prize to the winner via a correct answer sended by polygon user
// 18/04/2023

contract Quiz {
    address payable public creator;
    address payable public winner;
    string public question;
    string public answer;
    uint256 public balance;

    constructor(address payable _creator) {
        creator = _creator;
    }

    function setQuestionAndAnswer(string memory _question, string memory _answer) public {
        //Set the duo "question", "answer"
        require(msg.sender == creator, "Only the creator can setup the quiz.");
        question = _question;
        answer = _answer;
    }

    function claim(string memory _answer) public payable {
        balance += uint256(msg.value / (1 ether));
        //Quiz entry 1 enter to win all ethers in the contract
        require(msg.value >= 1000 ether, "You must use at least 1000 Matic to win the quiz with the right answer.");

        //Verify the answer given
        require(keccak256(bytes(_answer)) == keccak256(bytes(answer)), "Incorrect answer.");

        uint256 amount = balance;

        //Transfer all the balance to the winner
        payable(msg.sender).transfer(amount);

        //No more ether in the contract
        balance = 0;
    }


    function deposit() public payable {
        // Deposit the loot into the contract
        balance += uint256(msg.value / (1 ether));
    }

    function withdraw(uint256 _amount) public {
        require(msg.sender == creator, "Only the creator can withdraw the balance.");
        creator.transfer(_amount);
    }

}