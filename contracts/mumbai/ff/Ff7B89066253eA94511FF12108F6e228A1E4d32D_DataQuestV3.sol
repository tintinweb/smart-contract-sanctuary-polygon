pragma solidity 0.8.17;

contract DataQuestV3 {
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

    mapping (address => bool) private allowedTokens;
    mapping (bytes32 => Question) public questionMap;
    mapping (bytes32 => Answer) private answerMap;
    mapping (bytes32 => Answer[]) private questionAnswersMap; // questionHash => array of answers
    mapping (bytes32 => address[]) private questionWinnersMap; // questionHash => array of winners
    uint256 questionCounter = 0;
    uint256 answerCounter = 0;

    event QuestionCreated(
        bytes32 questionHash,
        address questioner,
        string title,
        string description,
        string imageUrl,
        address token,
        uint256 startTimedtsmp,
        uint256 endTimestamp,
        uint256 totalWinningAmount,
        uint256[] winnerAmount
    );

    event AnswerSubmitted(
        bytes32 answerHash,
        bytes32 questionHash,
        address answerer,
        string answerLink,
        string answerDescription,
        string answerImageUrl
    );

    event WinnersDeclared(
        bytes32 questionHash,
        address[] winners
    );
    // event lockedFund(address questionerAddress, address token, uint256 amount);
    // event fundTransferredToWinners(address questioner, address token, uint256 amount, address[] winnersAddress);

    function createQuestion(
        string memory title,
        string memory description,
        address token,
        uint256 startTimestamp,
        uint256 endTimestamp,
        uint256 totalWinningAmount,
        uint256[] memory winnersAmount,
        string memory imageUrl) external {
        // Creation question
        Question memory quest;
        quest.questioner = msg.sender;
        quest.title = title;
        quest.description = description;
        quest.imageUrl = imageUrl;
        quest.token = token;
        quest.startTimestamp = startTimestamp;
        quest.endTimestamp = endTimestamp;
        quest.totalWinningAmount = totalWinningAmount;
        quest.winnersAmount = winnersAmount;

        bytes32 questionHash = bytes32(keccak256(abi.encodePacked(msg.sender, blockhash(questionCounter + 1))));
        questionMap[questionHash] = quest;
        questionCounter += 1;

        emit QuestionCreated(
            questionHash, msg.sender, title,
            description, imageUrl, token, startTimestamp,
            endTimestamp, totalWinningAmount, winnersAmount);
    }

//    function lockFund(address _token, uint256 amount, address questionerAddress) private{
//        // Check balance of questioner
//    }

    function submitAnswer(
        bytes32 questionHash,
        string memory answerLink,
        string memory answerDescription,
        string memory answerImageUrl) external {
        // Submit answer
        Answer memory ans;
        ans.answerer = msg.sender;
        ans.questionHash = questionHash;
        ans.imageUrl = answerImageUrl;
        ans.description = answerDescription;
        ans.linkToAnswer = answerLink;

        // Create unique id for answer
        bytes32 answerHash = bytes32(keccak256(abi.encodePacked(msg.sender, blockhash(answerCounter + 1))));
        answerMap[answerHash] = ans;
        answerCounter += 1;

        // Push answer to questionAnswersMap
        questionAnswersMap[questionHash].push(ans);

        emit AnswerSubmitted(answerHash, questionHash, msg.sender, answerLink, answerDescription, answerImageUrl);
    }

    function declareWinners(bytes32 questionHash, address[] memory winners) external {
        questionWinnersMap[questionHash] = winners;
        emit WinnersDeclared(questionHash, winners);
    }

    function getQuestionDetails(bytes32 questionHash) public view returns(Question memory){
        // Submit answer
        Question memory questDetail = questionMap[questionHash];
        return questDetail;
    }

    function getAllAnswers(bytes32 questionHash) external view returns(Answer[] memory){
        // Return details answer
        Answer[] memory answers = questionAnswersMap[questionHash];
        return answers;
    }

//    function getQuestionMap(bytes32 questionHash) public view returns (Question memory) {
//        return questionMap[questionHash];
//    }

    function getQuestionAnswersMap(bytes32 questionHash) public view returns (Answer[] memory) {
        return questionAnswersMap[questionHash];
    }

    function getQuestionWinnersMap(bytes32 questionHash) public view returns (address[] memory) {
        return questionWinnersMap[questionHash];
    }

//    function transferFundsToWinners(address token, uint256 amount, address[] memory winnersAddress) public {
//        // Check balance of questioner
//        emit fundTransferredToWinners(msg.sender, token, amount, winnersAddress);
//    }
}