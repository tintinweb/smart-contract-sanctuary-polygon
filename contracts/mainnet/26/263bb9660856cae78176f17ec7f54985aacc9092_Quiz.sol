/**
 *Submitted for verification at polygonscan.com on 2022-07-06
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
        bool exist;
        bool over;
        uint256 startTime;
        uint256 activeTime;
        string title;
        string photo;
    }


    mapping(uint256 => address[]) private inductees;
    mapping(uint256 => QuizDetail) private quizzes;
    mapping(address => bool) public admins;
    mapping(uint256 => mapping(uint256 => address[])) private lotteryResults;
    mapping(string => uint256[]) public appQuizzes;
    mapping(uint256 => int256) public quizGroup;


    uint256[] private quizIds;
    uint256[] private shouldAwardQuizIds;

    uint256 public correctRewardAmount;

    constructor(address payable _operator, ILottery _lottery, IQuizToken _quizToken, uint256 _rewardAmount) {
        owner = msg.sender;
        admins[msg.sender] = true;
        operator = _operator;
        admins[_operator] = true;
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

    modifier onlyAdmin() {
        require(admins[msg.sender] == true, "Ownable: caller is not the admin");
        _;
    }

    event CreateQuiz(string _appId, uint256 _quizId, int256 _groupId, string[] questions, uint256 _rewardAmount,
        uint256 _startTime, uint256 _activeTime);
    event Awards(bytes32 _quizId);


    function changeOperator(address payable _newOperator) public onlyOwner {
        operator = _newOperator;
        admins[_newOperator] = true;
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


    function isAdmin(address _sender) public view returns (bool){
        return admins[_sender];
    }

    function addAdmin(address _newAdmin) public onlyOwner {
        admins[_newAdmin] = true;
    }

    function delAdmin(address _newAdmin) public onlyOwner {
        admins[_newAdmin] = false;
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


    function createQuiz(string memory _appId, uint256 _quizId, int256 _groupId, string[] memory _questions,
        uint256 _rewardAmount, uint256 _startTime, uint256 _activeTime, string memory _title, string memory _photo) payable public onlyAdmin {
        require(_quizId != 0, "invalid quizId 0");
        require(!isQuizExist(_quizId), "exist quiz");
        _rewardAmount = correctRewardAmount;
        if (address(msg.sender) != address(operator)) {
            require(msg.value > 0, "you should prepay for gas");
            operator.transfer(msg.value);
        }

        quizIds.push(_quizId);
        shouldAwardQuizIds.push(_quizId);
        quizzes[_quizId] = QuizDetail(_quizId, _questions, _rewardAmount, true, false, _startTime, _activeTime, _title, _photo);
        appQuizzes[_appId].push(_quizId);
        quizGroup[_quizId] = _groupId;

        emit CreateQuiz(_appId, _quizId, _groupId, _questions, _rewardAmount, _startTime, _activeTime);
    }


    function getQuiz(uint256 _quizId) public view checkQuiz(_quizId) returns (QuizDetail memory) {
        return quizzes[_quizId];
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

    function addQuestion(uint256 _quizId, string memory _question) public checkQuiz(_quizId) onlyAdmin {
        quizzes[_quizId].questions.push(_question);
    }

    function batchAddQuestion(uint256 _quizId, string[] memory _questions) public checkQuiz(_quizId) onlyAdmin {
        for (uint256 i = 0; i < _questions.length; i ++) {
            quizzes[_quizId].questions.push(_questions[i]);
        }

    }

    function editQuestionByIndex(uint256 _quizId, uint256 _questionIndex, string memory _question) public checkQuiz(_quizId) onlyAdmin {
        require(_questionIndex < quizzes[_quizId].questions.length, "question index out of bounds");
        quizzes[_quizId].questions[_questionIndex] = _question;
    }

    function deleteQuestionByIndex(uint256 _quizId, uint256 _questionIndex) public checkQuiz(_quizId) onlyAdmin {
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

    function getQuizGroup(uint256 _quizId) public view checkQuiz(_quizId) returns (int256){
        return quizGroup[_quizId];
    }


    function addInductees(uint256 _quizId, address[] memory _inductees) public checkQuiz(_quizId) onlyAdmin {
        require(!quizzes[_quizId].over, "QuizDetail is time out");
        lottery.addLotteryInductees(_quizId, _inductees);
        if (inductees[_quizId].length == 0) {
            inductees[_quizId] = _inductees;
        } else {
            for (uint256 i = 0; i < _inductees.length; i++) {
                inductees[_quizId].push(_inductees[i]);
            }
        }
    }

    function awards(uint256 _quizId) public checkQuiz(_quizId) onlyAdmin {
        require(!quizzes[_quizId].over, "QuizDetail is time out");

        address[] memory thisInductees = inductees[_quizId];
        uint256 i = 0;

        while (i < thisInductees.length) {
            //            (bool _success, bytes memory _data) = quizToken.call(abi.encodeWithSignature("mint(address,uint256)", thisInductees[i], quizzes[_quizId].amount));
            //            require(_success && (_data.length == 0 || abi.decode(_data, (bool))), 'QuizToken: MINT_FAILED');
            quizToken.mint(thisInductees[i], quizzes[_quizId].amount);
            i += 1;
        }

        quizzes[_quizId].over = true;
        _popAwardQuiz(_quizId);
        //        (bool success, bytes memory data) = lottery.call(abi.encodeWithSignature("drawALottery(uint256)", _quizId));
        //        require(success && (data.length == 0 || abi.decode(data, (bool))), 'Lottery: draw lottery failed');
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