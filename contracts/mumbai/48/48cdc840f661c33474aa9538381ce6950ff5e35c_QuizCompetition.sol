/**
 *Submitted for verification at polygonscan.com on 2023-02-09
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

contract QuizCompetition {

  struct Question {
    bytes32 question;
    bytes32 answer;
  }

  // Store the questions and answers
  Question[] public questions;

  // Store the number of participants
  uint public participantCount;

  // Store the results of the participants
  mapping(address => uint) public results;

  // Event to notify when a new participant joins
  event NewParticipant(address participant);

  // Event to notify when a participant submits their answer
  event AnswerSubmitted(address participant, uint score);

  // Add a new question to the quiz
  function addQuestion(string memory question, string memory answer) public {
    questions.push(Question(keccak256(abi.encodePacked(question)), keccak256(abi.encodePacked(answer))));
  }

  // Join the quiz competition
  function join() public {
    participantCount++;
    emit NewParticipant(msg.sender);
  }

  // Submit answers for the quiz competition
  function submitAnswers(string[] memory answers) public {
    require(answers.length == questions.length, "Incorrect number of answers.");
    uint score = 0;
    for (uint i = 0; i < answers.length; i++) {
      if (keccak256(abi.encodePacked(answers[i])) == questions[i].answer) {
        score++;
      }
    }
    results[msg.sender] = score;
    emit AnswerSubmitted(msg.sender, score);
  }

  // Get the results of a specific participant
  function getResult(address participant) public view returns (uint) {
    return results[participant];
  }
}