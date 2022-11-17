import "../interfaces/IMintTeams.sol";
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract QuizGame {
    address public owner;
    address public mintAddress;
    bool public startedQuizOne;
    bool public startedQuizTwo;
    bool pause;
    event currentGame(address caller, uint256 currentGameId);
    event winner(address winner, uint256 gameId);

    struct Quiz {
        string question;
        string optionOne;
        string optionTwo;
        string optionThree;
        string optionFour;
        string correctAnswer;
    }

    mapping(uint => mapping(address => bool)) alreadyJoinedGame;
    mapping(uint => mapping(address => bool)) claimedPrize;
    mapping(uint => mapping(address => uint)) score;
    mapping(uint => mapping(address => bool)) guessed;
    mapping (uint256 => Quiz) quizOne;
    mapping (uint256 => Quiz) quizTwo;
    uint256 quizIdOne;
    uint256 quizIdTwo;
    uint256 public currentGameId = 1;
    uint256 public timeLimit;
    uint public nextRound;


    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier onlyWhenNotPaused {
     require(pause == false, "CONTRACT_IS_PAUSED");
     _;
   }

    function AddQuizOne(
        string memory _question,
        string memory _optionOne,
        string memory _optionTwo,
        string memory _optionThree,
        string memory _optionFour,
        string memory answer
    ) 
    external onlyOwner
    {
        require(quizIdOne != 3, "Can't add more than 3 questions");
        quizOne[quizIdOne] = Quiz(
            _question,
            _optionOne,
            _optionTwo,
            _optionThree,
            _optionFour,
            answer
        );
        quizIdOne++;
    }

    function AddQuizTwo(
        string memory _question,
        string memory _optionOne,
        string memory _optionTwo,
        string memory _optionThree,
        string memory _optionFour,
        string memory answer
    ) 
    external onlyOwner
    {
        require(quizIdTwo != 3, "Can't add more than 3 questions");
        quizTwo[quizIdTwo] = Quiz(
            _question,
            _optionOne,
            _optionTwo,
            _optionThree,
            _optionFour,
            answer
        );
        quizIdTwo++;
    }

    function setMintTeamOneAddress(address _mintTeamOneAddress) external onlyOwner {
        mintAddress = _mintTeamOneAddress;
    }

     function startGameOne() external onlyOwner {
        require(quizIdOne == 3, "Make three questions first");
        require(startedQuizOne == false, "Game already started!");
        startedQuizOne = true;
        timeLimit = block.timestamp + 15 minutes;
        nextRound = block.timestamp + 5 days;
    }

    function startGameTwo() external onlyOwner {
        require(quizIdTwo == 3, "Make three questions first");
        require(block.timestamp > nextRound, "CANT_START_GAME_YET");
        require(startedQuizTwo == false, "Game is already started!");
        startedQuizTwo = true;
        timeLimit = block.timestamp + 15 minutes;
        currentGameId++;
    }

    function joinGameOne() external onlyWhenNotPaused {
        require(block.timestamp < timeLimit, "TIMES_UP");
        require(startedQuizOne == true, "CANT_JOIN_GAME_YET");
        require(!alreadyJoinedGame[0][msg.sender], "You have already joined the game!");
        alreadyJoinedGame[0][msg.sender] = true;
        emit currentGame(msg.sender, currentGameId);
    }
    
    function joinGameTwo() external onlyWhenNotPaused {
        require(block.timestamp < timeLimit, "TIMES_UP");
        require(startedQuizTwo == true, "CANT_JOIN_GAME_YET");
        require(!alreadyJoinedGame[1][msg.sender], "You have already joined the game!");
        alreadyJoinedGame[1][msg.sender] = true;
        emit currentGame(msg.sender, currentGameId);
    }
  

    function guessQuestionsOne(string memory guess, string memory guessTwo, string memory guessThree) external onlyWhenNotPaused {
        require(startedQuizOne == true, "QUIZ_NEVER_STARTED");
        require(guessed[0][msg.sender] == false,"CANT_GUESS_TWICE");
        require(block.timestamp < timeLimit, "TIMES_UP");
        if(keccak256(abi.encode(guess)) == keccak256(abi.encode(quizOne[0].correctAnswer))) {
          score[0][msg.sender]++;
        }
         if(keccak256(abi.encode(guessTwo)) == keccak256(abi.encode(quizOne[1].correctAnswer))) {
          score[0][msg.sender]++;
        }
         if(keccak256(abi.encode(guessThree)) == keccak256(abi.encode(quizOne[2].correctAnswer))) {
          score[0][msg.sender]++;
        }
        guessed[0][msg.sender] = true;
    }

     function guessQuestionsTwo(string memory guess, string memory guessTwo, string memory guessThree) external onlyWhenNotPaused {
        require(startedQuizTwo == true, "QUIZ_NEVER_STARTED");
        require(guessed[1][msg.sender] == false,"CANT_GUESS_TWICE");
        require(block.timestamp < timeLimit, "TIMES_UP");
        if(keccak256(abi.encode(guess)) == keccak256(abi.encode(quizTwo[0].correctAnswer))) {
          score[1][msg.sender]++;
        }
         if(keccak256(abi.encode(guessTwo)) == keccak256(abi.encode(quizTwo[1].correctAnswer))) {
          score[1][msg.sender]++;
        }
         if(keccak256(abi.encode(guessThree)) == keccak256(abi.encode(quizTwo[2].correctAnswer))) {
          score[1][msg.sender]++;
        }
        guessed[1][msg.sender] = true;
    }

    function claimPrizeOne() external onlyWhenNotPaused {
       require(claimedPrize[0][msg.sender] == false, "Already claimed prize");
       require(score[0][msg.sender] == 3, "You didn't score high enough");
       IMintTeams(mintAddress).mint(msg.sender, 2, 1, "");
       claimedPrize[0][msg.sender] = true;
    }

     function claimPrizeTwo() external onlyWhenNotPaused {
       require(claimedPrize[1][msg.sender] == false, "Alread claimed prize");
       require(score[1][msg.sender] == 3, "You didn't score high enough");
       IMintTeams(mintAddress).mint(msg.sender, 6, 1, "");
       claimedPrize[1][msg.sender] = true;
    }

    function returnQuizOne(uint _quizId) external view returns(string memory question, string memory optionOne, string memory optionTwo, string memory optionThree, string memory optionFour) {
        return (quizOne[_quizId].question, quizOne[_quizId].optionOne, quizOne[_quizId].optionTwo, quizOne[_quizId].optionThree, quizOne[_quizId].optionFour);
    }

    function returnQuizTwo(uint _quizId) external view returns(string memory question, string memory optionOne, string memory optionTwo, string memory optionThree, string memory optionFour) {
        require(msg.sender == owner, "You are not the owner");
        return (quizTwo[_quizId].question, quizTwo[_quizId].optionOne, quizTwo[_quizId].optionTwo, quizTwo[_quizId].optionThree, quizTwo[_quizId].optionFour);
    }

    function setPause(bool _setPause) external onlyOwner {
       pause = _setPause;
     }

     function joinedGame(uint quizId) external view returns(bool) {
        return alreadyJoinedGame[quizId][msg.sender];
     }

      function haveYouClaimedPrize(uint quizId) external view returns(bool) {
        return claimedPrize[quizId][msg.sender];
     }

     function haveYouGuessed(uint quizId) external view returns(bool) {
        return guessed[quizId][msg.sender];
     }

     function getScore(uint quizId) external view returns(uint) {
        return score[quizId][msg.sender];
     }

    }

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IMintTeams {
    function claimLevel1Nft(address _predictor, string calldata _teamName, bool firstFourMinted) external;
    function claimLevel2Nft(address _predictor, string calldata _teamName) external;
    function claimLevel3Nft(address _predictor, string calldata _teamName) external;
    function claimLevel4Nft(address _predictor, string calldata _teamName) external;
    function mint(address to, uint256 id, uint256 amount, bytes memory data) external;
    function burn(address from, uint id, uint amount) external;
}