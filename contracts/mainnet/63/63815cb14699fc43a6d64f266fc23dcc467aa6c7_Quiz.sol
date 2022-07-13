/**
 *Submitted for verification at polygonscan.com on 2022-07-13
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }


    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }


    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }


    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }


    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }


    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }


    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }


    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}


interface ILottery {
    function getLotteryResults(uint256 _lotteryId, uint256 _index) external view returns (address[] memory);

    function addLotteryInductees(uint256 _lotteryId, address[] memory _inductees) external;

    function drawALottery(uint256 _lotteryId) external;
}

interface IQuizToken {
    function mint(address account, uint256 amount) external;
}


contract Quiz {
    using SafeMath for uint256;
    address  public owner;
    address payable public operator;
    ILottery public lottery;
    IQuizToken public quizToken;


    struct QuizDetail {
        uint256 id;
        string[] questions;
        uint256 amount;
        int256 group;
        uint botType;
        bool exist;
        bool over;
        uint256 startTime;
        uint256 activeTime;
        string title;
        string photo;
        uint256 participate;
    }


    mapping(uint256 => address[]) private inductees;
    mapping(uint256 => QuizDetail) private quizzes;
    mapping(string => address[]) public admins;
    mapping(uint256 => mapping(uint256 => address[])) private lotteryResults;
    mapping(string => uint256[]) public appQuizzes;


    uint256[] private quizIds;
    uint256[] private shouldAwardQuizIds;

    uint256 public correctRewardAmount;

    constructor(address payable _operator, ILottery _lottery, IQuizToken _quizToken, uint256 _rewardAmount) {
        owner = msg.sender;
        operator = _operator;
        lottery = _lottery;
        quizToken = _quizToken;
        correctRewardAmount = _rewardAmount;

    }


    modifier checkQuiz(uint256 _quizId){
        require(_quizId != 0, "invalid quizId 0");
        require(quizzes[_quizId].exist, "nonexistent quiz");
        _;
    }

    modifier onlyOwner(){
        require(msg.sender == owner, "Only Owner");
        _;
    }

    modifier onlyAdmin(string memory _appId) {
        require(checkAdmin(_appId, msg.sender) || operator == msg.sender, "Only admin");
        _;
    }

    function addAdmin(string memory _appId, address _admin) public onlyOwner {
        admins[_appId].push(_admin);
    }

    function delAdmin(string memory _appId, address _delAdmin) public onlyOwner {
        for (uint i = 0; i < admins[_appId].length; i++) {
            if (admins[_appId][i] == _delAdmin) {
                admins[_appId][i] = address(0);
                return;
            }
        }
    }

    function checkAdmin(string memory _appId, address _sender) public view returns (bool){
        for (uint i = 0; i < admins[_appId].length; i++) {
            if (admins[_appId][i] == _sender) {
                return true;
            }
        }
        return false;
    }


    function getAppAdmins(string memory _appId) public view returns (address[] memory){
        return admins[_appId];
    }


    event CreateQuiz(string _appId, uint256 _quizId, int256 _groupId, uint _botType, string[] questions, uint256 _rewardAmount,
        uint256 _startTime, uint256 _activeTime);
    event Awards(bytes32 _quizId);


    function changeOperator(address payable _newOperator) public onlyOwner {
        operator = _newOperator;
    }

    function changeLottery(ILottery _newLottery) public onlyOwner {
        lottery = _newLottery;
    }

    function changeQuizToken(IQuizToken _newQuizToken) public onlyOwner {
        quizToken = _newQuizToken;
    }

    function changeRewardAmount(uint256 _newAmount) public onlyOwner {
        correctRewardAmount = _newAmount;
    }

    function isQuizExist(uint256 _quizId) public view returns (bool){
        require(_quizId != 0, "invalid quizId 0");
        return quizzes[_quizId].exist;
    }

    function getQuizList() public view returns (uint256[] memory){
        return quizIds;
    }


    function quizQuantity() public view returns (uint256){
        return quizIds.length;
    }


    function createQuiz(string memory _appId, uint256 _quizId, int256 _groupId, uint _botType, string[] memory _questions,
        uint256 _rewardAmount, uint256 _startTime, uint256 _activeTime, string memory _title, string memory _photo) payable public onlyAdmin(_appId) {
        require(_quizId != 0, "invalid quizId 0");
        require(!isQuizExist(_quizId), "exist quiz");
        _rewardAmount = correctRewardAmount;
        if (address(msg.sender) != address(operator)) {
            require(msg.value > 0, "you should prepay for gas");
            operator.transfer(msg.value);
        }

        quizIds.push(_quizId);
        shouldAwardQuizIds.push(_quizId);
        quizzes[_quizId] = QuizDetail(_quizId, _questions, _rewardAmount, _groupId, _botType, true, false, _startTime, _activeTime, _title, _photo, 0);
        appQuizzes[_appId].push(_quizId);
        emit CreateQuiz(_appId, _quizId, _groupId, _botType, _questions, _rewardAmount, _startTime, _activeTime);
    }


    function getQuiz(uint256 _quizId) public view checkQuiz(_quizId) returns (QuizDetail memory) {
        return quizzes[_quizId];
    }

    function getQuizzes(uint256[] memory _ids) public view returns (QuizDetail[] memory){
        QuizDetail[] memory details = new QuizDetail[](_ids.length);
        for (uint i = 0; i < _ids.length; i++) {
            details[i] = quizzes[_ids[i]];
        }
        return details;
    }


    function getShouldAwardQuizIds() public view returns (uint256[] memory) {
        return shouldAwardQuizIds;
    }

    function getAppQuizIds(string memory _appId) public view returns (uint256[] memory){
        return appQuizzes[_appId];
    }

    function appQuizQuantity(string memory _appId) public view returns (uint256){
        return appQuizzes[_appId].length;
    }

    function questionQuantity(uint256 _quizId) public view checkQuiz(_quizId) returns (uint256){
        return quizzes[_quizId].questions.length;
    }

    function getQuestions(uint256 _quizId) public view checkQuiz(_quizId) returns (string[] memory) {
        return quizzes[_quizId].questions;
    }

    function getQuestionByIndex(uint256 _quizId, uint256 _questionIndex) public view checkQuiz(_quizId) returns (string memory){
        require(_questionIndex < quizzes[_quizId].questions.length, "question index out of bounds");
        return quizzes[_quizId].questions[_questionIndex];
    }

    function addQuestion(string memory _appId, uint256 _quizId, string memory _question) public checkQuiz(_quizId) onlyAdmin(_appId) {
        quizzes[_quizId].questions.push(_question);
    }

    function batchAddQuestion(string memory _appId, uint256 _quizId, string[] memory _questions) public checkQuiz(_quizId) onlyAdmin(_appId) {
        for (uint256 i = 0; i < _questions.length; i ++) {
            quizzes[_quizId].questions.push(_questions[i]);
        }

    }

    function editQuestionByIndex(string memory _appId, uint256 _quizId, uint256 _questionIndex, string memory _question) public checkQuiz(_quizId) onlyAdmin(_appId) {
        require(_questionIndex < quizzes[_quizId].questions.length, "question index out of bounds");
        quizzes[_quizId].questions[_questionIndex] = _question;
    }

    function deleteQuestionByIndex(string memory _appId, uint256 _quizId, uint256 _questionIndex) public checkQuiz(_quizId) onlyAdmin(_appId) {
        require(_questionIndex < quizzes[_quizId].questions.length, "question index out of bounds");
        uint256 lastShouldAwardQuizIdIndex = questionQuantity(_quizId) - 1;

        // When the question to delete is the last question, the swap operation is unnecessary
        if (lastShouldAwardQuizIdIndex != _questionIndex) {
            for (uint256 i = _questionIndex; i < lastShouldAwardQuizIdIndex; i++) {
                quizzes[_quizId].questions[i] = quizzes[_quizId].questions[i + 1];
            }
        }

        delete quizzes[_quizId].questions[lastShouldAwardQuizIdIndex];
    }

    function getInductees(uint256 _quizId) public view checkQuiz(_quizId) returns (address[] memory){
        return inductees[_quizId];
    }

    function addInductees(string memory _appId, uint256 _quizId, address[] memory _inductees, uint256 _participateNumber) public checkQuiz(_quizId) onlyAdmin(_appId) {
        require(!quizzes[_quizId].over, "QuizDetail is time out");
        lottery.addLotteryInductees(_quizId, _inductees);
        if (inductees[_quizId].length == 0) {
            inductees[_quizId] = _inductees;
        } else {
            for (uint256 i = 0; i < _inductees.length; i++) {
                inductees[_quizId].push(_inductees[i]);
            }
        }
        quizzes[_quizId].participate = _participateNumber;
    }

    function awards(string memory _appId, uint256 _quizId) public checkQuiz(_quizId) onlyAdmin(_appId) {
        require(!quizzes[_quizId].over, "QuizDetail is time out");

        address[] memory thisInductees = inductees[_quizId];
        uint256 i = 0;

        while (i < thisInductees.length) {
            quizToken.mint(thisInductees[i], quizzes[_quizId].amount);
            i += 1;
        }

        quizzes[_quizId].over = true;
        _popAwardQuiz(_quizId);
        lottery.drawALottery(_quizId);
    }


    function getLotteryResults(uint256 _quizId, uint256 _index) public view returns (address[] memory){
        return lottery.getLotteryResults(_quizId, _index);
    }

    function _popAwardQuiz(uint256 _quizId) internal {
        uint256 lastShouldAwardQuizIdIndex = shouldAwardQuizIds.length - 1;

        uint256 shouldAwardQuizIdIndex = 0;
        for (uint256 i = 0; i < lastShouldAwardQuizIdIndex; i ++) {
            if (shouldAwardQuizIds[i] == _quizId) {
                shouldAwardQuizIdIndex = i;
            }
        }

        // When the question to delete is the last question, the swap operation is unnecessary
        if (lastShouldAwardQuizIdIndex != shouldAwardQuizIdIndex) {
            shouldAwardQuizIds[shouldAwardQuizIdIndex] = shouldAwardQuizIds[lastShouldAwardQuizIdIndex];
        }
        shouldAwardQuizIds.pop();
    }
}