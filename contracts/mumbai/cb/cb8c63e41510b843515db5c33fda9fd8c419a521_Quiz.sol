/**
 *Submitted for verification at polygonscan.com on 2022-03-16
*/

// SPDX-License-Identifier: MIT
 pragma solidity ^0.8.0;

    contract Quiz {

    struct Answer
    {
        bytes32 text; 
        uint voteCount; // number of accumulated votes
        // add more non-key fields as needed
    }

    struct Question
    {
        bytes32 text;
        bytes32[] answerList; // list of answer keys so we can look them up
        mapping(bytes32 => Answer) answerStructs; // random access by question key and answer key
        // add more non-key fields as needed
    }

    mapping(bytes32 => Question) questionStructs; // random access by question key
    bytes32[] questionList; // list of question keys so we can enumerate them
  
    function newQuestion(bytes32 questionKey, bytes32 text) public
        // onlyOwner
        returns(bool success)
    {
        // not checking for duplicates
        questionStructs[questionKey].text = text;
        questionList.push(questionKey);
        return true;
    }

    /*function getQuestion(bytes32 questionKey)
        public
        constant
        returns(bytes32 wording, uint answerCount)
    {
        return(questionStructs[questionKey].text, questionStructs[questionKey].answerList.length);
    }*/

    function addAnswer(bytes32 questionKey, bytes32 answerKey, bytes32 answerText) public
        // onlyOwner
        returns(bool success)
    {
        questionStructs[questionKey].answerList.push(answerKey);
        questionStructs[questionKey].answerStructs[answerKey].text = answerText;
        // answer vote will init to 0 without our help
        return true;
    }



}