/**
 *Submitted for verification at polygonscan.com on 2022-03-17
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.8.2;


contract Voting {
    struct Question {
        uint256 questionId;
        string poll;
     //   Option[] options;
    }

    struct Option {
        uint256 optionId;
        string optionValue;
        uint counter;
    }
       Question[] public questions;
        uint public _id = 1;

    // map(questionId => Question)
    mapping(uint => Option[]) public mapOptions;
  

        event emitProposal(uint id, string pollDesc);
        event emitOptions(Option r);

   function addQuestion(string[] calldata _option1, string calldata  _question) public {

          
       for (uint i = 0; i < _option1.length; i++) {
        Option memory r = Option({
            optionId: i,
            optionValue: _option1[i],
            counter: 0
        });
        
        mapOptions[_id].push(r);
        emit emitOptions(r);

       }

           Question memory d = Question({
            questionId: _id,
            poll: _question
        });
        questions.push(d);
       _id+=1;

        emit emitProposal(_id, _question);


       /* Question storage quest = mapQuestions[_id];
        quest.questionId = _id;
        quest.poll = _question;
        quest.options.push(Option(_id, _option1));*/
    }

   /*function insert(address key, string memory id, uint requestTime, uint releaseTime, bool foo, uint bar) public {

        Direction memory d = Direction({
            foo: foo,
            bar: bar
        });
        
        Record memory r = Record({
            id: id,
            requestTime: requestTime,
            releaseTime: releaseTime,
            dir: d
        });
        
        records[key].push(r);
    }
    
    function inspect(address key) public view returns(Record[] memory) {
        return records[key];
    }
    
    function inspectLength(address key) public view returns(uint) {
        return records[key].length;
    }
    
    function inspectRecord(address key, uint record) public view returns(Record memory) {
        return records[key][record];
    }*/

   function getOptions(uint256 record) public view returns(Option[] memory) {
        return mapOptions[record];
    }

      function getPollDetails(uint pollId) public view returns(Question memory) {
       
       Question memory ques;
              for (uint i=0; i < questions.length; i++) {
                   Question memory e = questions[i];
        if (questions[i].questionId == pollId) {
            // corresponding item found - update quantity and early return
            
             return (e);
        }
    }
     return (ques);
    }

 


    /// Give your vote (including votes delegated to you)
    /// to proposal `proposals[proposal].name`.
    function vote(uint pollId, uint optionId) public  {
      //  Voter storage sender = voters[msg.sender];
        // require(sender.weight != 0, "Has no right to vote");
       // require(!sender.voted, "Already voted.");
       // sender.voted = true;
      //  sender.vote = proposal;

        Option memory t = mapOptions[pollId][optionId];

    Option memory r = Option({
            optionId: optionId,
            optionValue: t.optionValue,
            counter: 1
        });

        mapOptions[pollId][optionId] = r;

        // If `proposal` is out of the range of the array,
        // this will throw automatically and revert all
        // changes.
       // proposals[proposal].voteCount += 1;
        emit emitOptions(r);


    }

}