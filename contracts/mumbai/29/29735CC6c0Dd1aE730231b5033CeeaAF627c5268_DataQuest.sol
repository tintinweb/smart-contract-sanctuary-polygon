pragma solidity 0.8.17;

contract DataQuest {
    struct Question {
        address questioner;
        string title;
        string description;
        string imageUrl;
        address token;
        uint256 totalWinningAmount;
        uint256 startTimestamp;
        uint256 endTimestamp;
        uint256[] winnersAmount;
    }
    struct Answer {
        bytes32 questionHash;
        string linkToAnswer;
        string description;
        string imageUrl;
        address answerer;
    }
    struct QuestionWinners {
        bytes32 questionHash;
        address[] winners;    // Array of address order by win position
    }

    mapping (address => bool) public allowedTokens;
    mapping (bytes32 => Question) public questionMap;
    mapping (bytes32 => Answer) public answerMap;
    mapping (bytes32 => Answer[]) public questionAnswersMap;
    mapping (bytes32 => QuestionWinners[]) public questionWinnersMap;
    uint256 questionCounter = 0;
    uint256 answerCounter = 0;
    uint256 questionWinnersCounter = 0;

    event QuestionCreated(address questioner, bytes32 questionHash, string title, address token, uint256 startTimedtsmp, uint256 endTimestamp,
                          uint totalWinningAmount, uint[] winnerAmount);
    event AnswerSubmitted(address answerer, bytes32 answerHash, bytes32 questionHash, string answerLink, string answerDescription, string answerImage);
    event WinnersDeclared(address questioner, bytes32 questionHash);
    event lockedFund(address questionerAddress, address token, uint amount);
    event fundTransferredToWinners(address questioner, address token, uint amount, address[] winnersAddress);


    function createQuestion(string memory title, address token, uint256 startTimestamp, uint256 endTimestamp,
                            uint totalWinningAmount, uint[] memory winnersAmount, string memory description,
                            string memory imageUrl) public {
        // Creation question
        Question memory quest;
        quest.questioner = msg.sender;
        quest.title = title;
        quest.token = token;
        quest.description = description;
        quest.imageUrl = imageUrl;
        quest.startTimestamp = startTimestamp;
        quest.endTimestamp = endTimestamp;
        quest.totalWinningAmount = totalWinningAmount;
        quest.winnersAmount = winnersAmount;

        bytes32 questionHash = bytes32(keccak256(abi.encodePacked(msg.sender, blockhash(questionCounter + 1))));
        questionMap[questionHash] = quest;
        questionCounter += 1;

        emit QuestionCreated(msg.sender, bytes32(questionCounter), title, token, startTimestamp,
            endTimestamp, totalWinningAmount, winnersAmount);
    }

    function lockFund(address _token, uint amount, address questionerAddress) private{
        // Check balance of questioner
    }

    function submitAnswer(bytes32 questionHash, string memory answerLink, string memory answerDescription,
                          string memory answerImage) public {
        // Submit answer
        Answer memory ans;
        ans.answerer = msg.sender;
        ans.questionHash = questionHash;
        ans.imageUrl = answerImage;
        ans.description = answerDescription;
        ans.linkToAnswer = answerLink;

        // Create unique id for answer
        bytes32 answerHash = bytes32(keccak256(abi.encodePacked(msg.sender, blockhash(answerCounter + 1))));
        answerMap[answerHash] = ans;
        answerCounter += 1;

        // Push answer to questionAnswersMap
        questionAnswersMap[questionHash].push(ans);

        emit AnswerSubmitted(msg.sender, answerHash, questionHash, answerLink, answerDescription, answerImage);
    }

    function declareWinners(bytes32 questionHash, address[] memory answererAddresses) public {
        QuestionWinners memory questionWinnersObj;
        questionWinnersObj.questionHash = questionHash;
        questionWinnersObj.winners = answererAddresses;

        // Create unique id for answer
        bytes32 questionWinnersHash = bytes32(keccak256(abi.encodePacked(msg.sender,
            blockhash(questionWinnersCounter + 1))));
        questionWinnersMap[questionWinnersHash].push(questionWinnersObj);
        questionWinnersCounter += 1;

        // Push answer to questionAnswersMap
        questionWinnersMap[questionHash].push(questionWinnersObj);
        emit WinnersDeclared(msg.sender, questionHash);
    }

    function getQuestionDetails(bytes32 questionHash) public returns(Question memory){
        // Submit answer
        Question memory questDetail = questionMap[questionHash];
        return questDetail;
    }

    function getAllAnswers(bytes32 questID) external view returns(Answer[] memory){
        // Return details answer
        Answer[] memory answers = questionAnswersMap[questID];
        return answers;
    }

    function transferFundsToWinners(address token, uint amount, address[] memory winnersAddress) public {
        // Check balance of questioner
        emit fundTransferredToWinners(msg.sender, token, amount, winnersAddress);
    }
}