// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract SubmissionContract {

    enum Result {PENDING,PASSED,FAILED}
    
    struct Submission {
        string cidSubmission;
        address account;
        address test;
        uint256 date;
        Result result;
    }

    mapping(address => string[]) public listOfAllSubmissionsOfATest; // Test -> Array uid Submissions
    mapping(string => Submission) public listOfSubmissions; // uid Submissions -> Submission

    address owner;   

    event NewSubmission(address indexed from, address indexed test, string indexed uid);
    event CorrectedSubmission(address indexed reviser, string indexed uid);

    modifier onlyOwner() {
        require(msg.sender == owner, "You're not the owner of this smart contract");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function newSubmission(string calldata _cidSubmission, address _test, string calldata _uid) public onlyOwner {
        Submission memory submission = Submission(
            _cidSubmission,
            tx.origin,
            _test,
            block.timestamp,
            Result.PENDING
        );
        listOfAllSubmissionsOfATest[_test].push(_uid);
        listOfSubmissions[_uid] = submission;
        emit NewSubmission(tx.origin,_test,_uid);
    }

    function setResultSubmission(string calldata _uid, Result _result) public onlyOwner {
        require(listOfSubmissions[_uid].result == Result.PENDING,"This submission has already been corrected");
        require(_result == Result.PASSED || _result == Result.FAILED);
        listOfSubmissions[_uid].result = _result;
        emit CorrectedSubmission(tx.origin,_uid);

    }

    function getResultSubmission(string calldata _uid) public view returns (Result){
        return listOfSubmissions[_uid].result;
    }

    function getAllSubmissionsOfATest(address _test) public view returns(string[] memory){
        return listOfAllSubmissionsOfATest[_test];
    }

    function getSubmission(string calldata _uid) public view returns (Submission memory) {
        return listOfSubmissions[_uid];
    }

}