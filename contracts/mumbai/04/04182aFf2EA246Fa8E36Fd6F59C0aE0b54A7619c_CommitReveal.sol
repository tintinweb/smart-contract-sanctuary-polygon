//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/// @title Commit Reveal Scheme : A pattern used in games and puzzles to avoid cheating 
/// @author Srinivas Joshi<[email protected]>
contract CommitReveal{
    /*
     * Events
     */
    event PuzzleCreated(uint puzzleId,uint totalPrize,uint _guessDeadline,uint _revealDeadline);
    event PrizeClaimed(uint puzzleId,address winner,uint prize);
    event WinnerOfPuzzle(uint puzzleId,address winner);
    event GuessCommitted(uint puzzleId,address player);

    /*
     * Storage
     */
    struct Puzzle{
        address creator;
        uint totalPrize;
        uint guessDeadline;
        uint revealDeadline;
        uint winnerCount;
    }
    Puzzle[] public puzzles;
    uint public totalPuzzles;
    address public owner;

    mapping(uint => mapping(address => bytes32)) private committedAnswers;
    mapping(uint => mapping(address => bool)) public isPrizeClaimed;
    mapping(uint => mapping(address => bool)) public isPuzzleWinner;

    /*
     * Modifiers
     */
    modifier puzzleExist(uint _puzzleId){
        require(_puzzleId < totalPuzzles && _puzzleId >=0,"Puzzle does not exist");
        _;
    }

    modifier notCreator(uint _puzzleId){
        require(msg.sender != puzzles[_puzzleId].creator,"Creator of puzzle cannot use this");
        _;
    }

    /*
     * Public Functions
     */

    constructor(){
        owner=msg.sender;
    }
    
    /// @dev Allows a user to create a puzzle
    /// @param _hashedAnswer hash of the solution to the puzzle
    /// @param _guessDeadline deadline before solution to be guessed 
    /// @param _revealDeadline deadline to verify solution and to be claimed 
    function createPuzzle(bytes32 _hashedAnswer,uint _guessDeadline,uint _revealDeadline) public payable{
        uint _totalPrize = msg.value;
        require(_totalPrize > 0,"Prize cannot be empty");
        require(_guessDeadline > block.timestamp && _revealDeadline > block.timestamp,"Deadline cannot be before current time");
        require(_guessDeadline < _revealDeadline,"Cannot have guess after reveal");
        Puzzle memory _puzzle = Puzzle({
            creator : msg.sender,
            guessDeadline:_guessDeadline,
            revealDeadline:_revealDeadline,
            totalPrize:_totalPrize,
            winnerCount:0
        });
        committedAnswers[totalPuzzles][msg.sender] = _hashedAnswer;
        puzzles.push(_puzzle);
        emit PuzzleCreated(totalPuzzles,_totalPrize,_guessDeadline,_revealDeadline);
        totalPuzzles+=1;
    }

    /// @dev Allows player to submit guess to a puzzle
    /// @param _commitment Hash of player address + answer
    /// @param _puzzleId Puzzle ID
    function submitCommitment(bytes32 _commitment,uint _puzzleId) puzzleExist(_puzzleId) notCreator(_puzzleId) public{
        Puzzle memory _puzzle = puzzles[_puzzleId];
        require(block.timestamp < _puzzle.guessDeadline,"Late to submit solution to puzzle");
        committedAnswers[_puzzleId][msg.sender] = _commitment;
        emit GuessCommitted(_puzzleId,msg.sender);
    }

    /// @dev Allows player to verify if he is the winner of a puzzle
    /// @param _answer payload for verification
    /// @param _puzzleId puzzle ID
    function revealSolution(uint _answer,uint _puzzleId) puzzleExist(_puzzleId) notCreator(_puzzleId) public{
        Puzzle memory _puzzle = puzzles[_puzzleId];
        address _creator = _puzzle.creator;
        require(block.timestamp > _puzzle.guessDeadline,"Cannot reveal before deadline");
        require(block.timestamp < _puzzle.revealDeadline,"Reveal deadline crossed");
        // is answer same as comitted one
        require(createCommitment(msg.sender,_answer) == committedAnswers[_puzzleId][msg.sender],"Answer does not match committed answer");
        // is answer correct
        require(createCommitment(_creator,_answer) == committedAnswers[_puzzleId][_creator],"Answer is incorrect");
        require(!isPuzzleWinner[_puzzleId][msg.sender],"Already a winner of this puzzle");

        isPuzzleWinner[_puzzleId][msg.sender]=true;
        _puzzle.winnerCount+=1;
        puzzles[_puzzleId]=_puzzle;
        emit WinnerOfPuzzle(_puzzleId,msg.sender);
    }

    /// @dev Allows player to claim prize 
    /// @param _puzzleId puzzle ID
    function claimPrize(uint _puzzleId) puzzleExist(_puzzleId) notCreator(_puzzleId) public{
        Puzzle memory _puzzle = puzzles[_puzzleId];
        require(block.timestamp > _puzzle.revealDeadline,"Reveal deadline not complete");
        require(isPuzzleWinner[_puzzleId][msg.sender],"Not a winner");
        require(!isPrizeClaimed[_puzzleId][msg.sender],"Prize already claimed");

        uint prize = _puzzle.totalPrize/_puzzle.winnerCount;
        isPrizeClaimed[_puzzleId][msg.sender]=true;
        payable(msg.sender).transfer(prize);
        emit PrizeClaimed(_puzzleId,msg.sender,prize);
    }

    /// @dev Creates hash of your answer commit
    /// @param _user player address
    /// @param _answer player answer
    /// @return Returns hash of player address and answer 
    function createCommitment(address _user,uint _answer) public pure returns(bytes32){
        return keccak256(abi.encodePacked(_user,_answer));
    }

}