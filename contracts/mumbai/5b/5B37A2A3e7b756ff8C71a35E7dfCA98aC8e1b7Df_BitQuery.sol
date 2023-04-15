// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract BitQuery {
    struct Question {
        address payable asker;
        string questionText;
        string domain;
        uint256 price;
        bool answered;
    }
    
    struct Answer {
        address payable responder;
        string answerText;
        bool accepted;
    }
    
    mapping(uint256 => Question) public questions;
    mapping(uint256 => Answer) public answers;
    uint256 public questionCount = 0;

    event NewAnswer(uint256 indexed questionId, address indexed responder, string answerText);
    event QuestionAccepted(uint256 indexed questionId);
    
    function askQuestion(address payable _asker, string memory _questionText, string memory _domain, uint256 _price) public payable returns (uint256) {

        Question storage question = questions[questionCount];

        question.asker = _asker;
        question.questionText = _questionText;
        question.domain = _domain;
        question.price = _price;
        question.answered = false; // initially false as the question not answered

        questionCount++;

        return questionCount - 1;
    }
    
    function answerQuestion(uint256 questionId, string memory answerText) public {
        Question storage question = questions[questionId];
        require(msg.sender != question.asker, "Asker cannot answer their own question");
        require(!question.answered, "Question has already been answered");
        answers[questionId] = Answer(payable(msg.sender), answerText, false);
        emit NewAnswer(questionId, msg.sender, answerText);
    }
    
    function acceptAnswer(uint256 questionId) public {
        Question storage question = questions[questionId];
        Answer storage answer = answers[questionId];
        require(msg.sender == question.asker, "Only asker can accept an answer");
        require(!question.answered, "Question has already been answered");
        answer.accepted = true;
        question.answered = true;
        uint256 payout = answer.responder.balance + question.price;
        answer.responder.transfer(payout);
        emit QuestionAccepted(questionId);
    }

    function getQuestions() public view returns (Question[] memory) {
        Question[] memory allQuestions = new Question[](questionCount);

        for(uint i = 0; i < questionCount; i++) {
            allQuestions[i] = questions[i];
        }
        return allQuestions;
    }
}