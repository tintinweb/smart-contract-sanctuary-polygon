pragma solidity 0.8.17;

contract DataQuestV4 {
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

    mapping (bytes32 => Question) public questionMap;
    mapping (bytes32 => Answer) public answerMap;
    mapping (bytes32 => Answer[]) public questionAnswersMap; // questionHash => array of answers
    mapping (bytes32 => address[]) public questionWinnersMap; // questionHash => array of winners
    uint256 public questionCounter;
    uint256 public answerCounter;

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

    constructor(){
        questionCounter = 0;
        answerCounter = 0;
    }

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

        bytes32 questionHash = bytes32(keccak256(abi.encodePacked(msg.sender, questionCounter)));
        questionMap[questionHash] = quest;
        questionCounter += 1;

        emit QuestionCreated(
            questionHash, msg.sender, title,
            description, imageUrl, token, startTimestamp,
            endTimestamp, totalWinningAmount, winnersAmount);
    }

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

    // function transferFundsToWinners(address token, uint256 amount, address[] memory winnersAddress) public {
    //      // Check balance of questioner
    //      emit fundTransferredToWinners(msg.sender, token, amount, winnersAddress);
    // }

    // function lockFund(address _token, uint256 amount, address questionerAddress) private{
    //      // Check balance of questioner
    // }
}