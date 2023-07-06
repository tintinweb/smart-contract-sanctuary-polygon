// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IERC20Interface {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
}


contract SurveyContract {
    address public owner;
    IERC20Interface public token;
    uint private surveyCounter;

    struct Question {
        string questionText;
        uint8 questionType; // Types = 1: Short text input, 2: Long text input, 3: Number input, 4: True/False, 5: Rating as 1-5
    }

    struct Response {
        address participant;
        string[] answers; // Arrays of answers received from user answers.length == Question.length
    }

    struct Survey {
        bool isActive;
        uint tokenBalance;
        uint tokenReward;
        string[] tags;
        mapping(uint => Question) questions;
        uint questionSize;
        mapping(uint => address) participants;
        uint participantSize;
        mapping(uint => Response) responses;
        uint responseSize;
        address surveyCreator;
    }

    struct Transaction {
        uint surveyId;
        address sender;
        address receiver;
        uint256 amount;
    }

    mapping(uint => Survey) public surveys;
    uint public surveySize;

    event SurveyCreated(uint surveyId);
    event QuestionsAdded(
        uint surveyId,
        string[] questionTexts
    );
    event SurveyResponseSubmitted(
        uint surveyId,
        address participant
    );
    event TransferCompleted(
        uint surveyId,
        address indexed sender,
        address indexed recipient,
        uint256 amount
    ); 

    constructor(address _tokenAddress) {
        owner = msg.sender;
        token = IERC20Interface(_tokenAddress);
    }

    modifier onlySurveyCreator(uint _surveyId) {
        require(msg.sender == surveys[_surveyId].surveyCreator, "Only survey creator can create a survey");
        _;
    }

    function createSurvey(uint _tokenBalance, uint _tokenReward, string[] memory _tags) public {
        require(token.balanceOf(msg.sender) >= _tokenBalance, "Insufficient balance");
        require(_tokenBalance > 0, "Token balance must be greater than 0");
        require(_tokenReward > 0, "Token reward must be greater than 0");
        require(_tokenBalance > _tokenReward, "Token Balance should be greater than the token Reward");

        uint surveyId = surveyCounter;

        // Set the allowance for the smart contract
        bool success = token.approve(address(this), _tokenBalance);
        require(success, "Failed to set allowance");

        Survey storage newSurvey = surveys[surveyId];
        newSurvey.isActive = false;
        newSurvey.tokenBalance = _tokenBalance;
        newSurvey.tokenReward = _tokenReward;
        newSurvey.tags = _tags;
        newSurvey.questionSize = 0;
        newSurvey.participantSize = 0;
        newSurvey.responseSize = 0;
        newSurvey.surveyCreator = msg.sender;

        surveyCounter++;
        surveySize++;

        emit SurveyCreated(surveyId);
    }

    function addQuestionToSurvey(uint _surveyId, string[] memory _questionTexts, uint8[] memory _questionTypes) public onlySurveyCreator(_surveyId) {
        require(_surveyId < surveySize, "Survey does not exist, Invalid survey ID");
        require(_questionTexts.length == _questionTypes.length, "Number of questions does not match the Number of question types");

        Survey storage survey = surveys[_surveyId];
        uint questionIndex = survey.questionSize;

        for(uint i = 0; i < _questionTexts.length; i++) {
            Question storage newQuestion = survey.questions[questionIndex];
            newQuestion.questionText = _questionTexts[i];
            newQuestion.questionType = _questionTypes[i];
            questionIndex++;
        }

        survey.questionSize += _questionTexts.length;


        if(survey.questionSize > 0 && surveys[_surveyId].tokenBalance > 0) {
            surveys[_surveyId].isActive  = true;
        }

        emit QuestionsAdded(_surveyId, _questionTexts);
    }

    function submitSurveyResponse(uint _surveyId, string[] memory _answers) public {
        require(_surveyId < surveySize, "Survey does not exist, Invalid survey ID");
        require(surveys[_surveyId].isActive, "Survey is not active");

        Survey storage survey = surveys[_surveyId];

        // Submit survey response
        if(survey.tokenBalance <= survey.tokenReward) {
            surveys[_surveyId].isActive = false; // Mark survey as completed
        }

        uint participantIndex = survey.participantSize;

        survey.participants[participantIndex] = msg.sender;
        survey.participantSize++;


        Response storage newResponse = survey.responses[survey.responseSize];
        newResponse.participant = msg.sender;
        newResponse.answers = _answers;
        survey.responseSize++;

        transferSurveyTokens(_surveyId);

        emit SurveyResponseSubmitted(_surveyId, msg.sender);
    }

    function transferSurveyTokens(uint _surveyId) private {
        require(surveys[_surveyId].tokenBalance >= surveys[_surveyId].tokenReward, "Insufficient tokens in survey balance");
        require(surveys[_surveyId].surveyCreator != msg.sender, "Owner of the survey can't participate in the survey");

        uint256 senderBalance = token.balanceOf(surveys[_surveyId].surveyCreator);
        require(senderBalance >= surveys[_surveyId].tokenReward, "Insufficent Survey Owner Balance");

        surveys[_surveyId].tokenBalance -= surveys[_surveyId].tokenReward;

        bool success = token.transferFrom(surveys[_surveyId].surveyCreator, msg.sender, surveys[_surveyId].tokenReward);
        require(success, "Transfer of tokens has failed");

        Transaction memory transaction = Transaction({
            surveyId: _surveyId,
            sender: surveys[_surveyId].surveyCreator,
            receiver: msg.sender,
            amount: surveys[_surveyId].tokenReward
        });

        emit TransferCompleted(_surveyId, transaction.sender, msg.sender, transaction.amount);
    }

    function transferTokens(address _recipient, uint256 _amount) public payable {
    require(_amount > 0, "Amount must be greater than 0");

    address sender = msg.sender;
    require(token.balanceOf(sender) >= _amount, "Insufficient balance");

    token.transferFrom(sender, _recipient, _amount);

    emit TransferCompleted(0, sender, _recipient, _amount);
    }

    function deleteSurvey(uint _surveyId) public onlySurveyCreator(_surveyId) {
        require(_surveyId < surveySize, "Survey does not exist, Invalid survey ID");

        delete surveys[_surveyId];

        surveySize--;
    }

    // Getter functions

    function getSurvey(uint _surveyId) external view returns (Question[] memory) {
        require(_surveyId < surveySize, "Survey does not exist, Invalid survey ID");

        uint questionSize = surveys[_surveyId].questionSize;
        Question[] memory surveyQuestions = new Question[](questionSize);

        for (uint i = 0; i < questionSize; i++) {
            surveyQuestions[i] = surveys[_surveyId].questions[i];
        }

        return surveyQuestions;

    }

    function getSurveyResponses(uint _surveyId) public view returns (Response[] memory) {
        require(_surveyId < surveySize, "Survey does not exist, Invalid survey ID");

        uint responseSize = surveys[_surveyId].responseSize;
        Response[] memory surveyResponses = new Response[](responseSize);

        for (uint i = 0; i < responseSize; i++) {
            surveyResponses[i] = surveys[_surveyId].responses[i];
        }

        return surveyResponses;

    }

    function getSurveyTags(uint _surveyId) public view returns (string[] memory) {
        require(_surveyId < surveySize, "Survey does not exist, Invalid survey ID");
        return surveys[_surveyId].tags;
    }

    function getOwnerBalance() public view returns (uint256) {
    return token.balanceOf(owner);
    }

    function getSurveyCreatorBalance(uint _surveyId) public view returns (uint256) {
    require(_surveyId < surveySize, "Survey does not exist, Invalid survey ID");

    address creator = surveys[_surveyId].surveyCreator;

    return token.balanceOf(creator);
    }

    function getParticipantBalance(address participant) public view returns (uint256) {
        return token.balanceOf(participant);
    }

}