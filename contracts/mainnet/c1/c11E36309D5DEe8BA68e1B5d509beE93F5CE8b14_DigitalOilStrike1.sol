pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

import "./Ownable.sol";
import "./IERC20.sol";

contract DigitalOilStrike1 is Ownable {

    mapping (address => bool) public whitelist; // make sure no multi-address abuse
    Joke[] private jokes;
    uint8 private jokeCount = 0;
    address[] private jokeTellers;
    mapping (address => uint8) private jokersJokeNumber;
    bool private votingOpen = false;
    bool private raffleOpen = false;
    mapping (uint8 => uint8) private voteCount;
    mapping (address => bool) private voted;
    string public bestJoke;
    address public bestJokeTeller;
    address[] private raffleParticipants;
    mapping (address => bool) private inRaffle;
    address public raffleWinner;
    address private USDC_ADDRESS = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;

    struct Joke {
        uint8 jokeNumber;
        string joke;
        uint8 votes;
    }  

    function addToWhitelist(address participant) public onlyOwner {
        whitelist[participant] = true;
    }

    function submitJoke(string memory joke) public {
        require(whitelist[msg.sender] == true, "You aren't authorized to participate");
        require(checkJokeUnique(joke), "This joke has already been told");
        require(jokersJokeNumber[msg.sender] == 0, "You can't submit more than one joke");
        jokeTellers.push(msg.sender);
        jokes.push(Joke(jokeCount+1, joke, 0));
        jokersJokeNumber[msg.sender] = jokeCount + 1;
        jokeCount++;        
    }  

    function voteForJoke(uint8 jokeNumber) public {
        require(votingOpen, "Voting hasn't been opened yet");
        require(jokersJokeNumber[msg.sender] > 0, "You can't vote if you haven't submitted your own joke");
        require(jokeNumber > 0, "Joke numbers start at 1");
        require(jokeNumber <= jokeCount, "That joke doesn't exist");
        require(voted[msg.sender] == false, "You have already voted");
        require(jokersJokeNumber[msg.sender] != jokeNumber, "You can't vote for your own Joke");
        voted[msg.sender] = true;
        jokes[jokeNumber-1].votes = jokes[jokeNumber-1].votes + 1;
    }

    function enterRaffle() public {
        require(raffleOpen, "Raffle hasn't been opened yet");
        require(voted[msg.sender] == true, "To enter raffle you must have first voted for a joke");
        require(inRaffle[msg.sender] == false, "You can only enter the raffle once");
        raffleParticipants.push(msg.sender);
        inRaffle[msg.sender] = true;
    }

    function checkJokeUnique(string memory _joke) internal view returns (bool) {
        for (uint8 i = 0; i < jokes.length; i++) {
            if (sha256(bytes(_joke)) == sha256(bytes(jokes[i].joke))) {
                return false;
            }
        }

        return true;
    }

    function getJokes() public view returns (Joke[] memory) {
        return jokes;
    }

    function openVoting() public onlyOwner {
        votingOpen = true;
    }

    function openRaffle() public onlyOwner {
        raffleOpen = true;
        // Also determine joke telling winner. In case of a tie, the first joke that was entered wins and breaks the tie
        uint8 maxVotes = 0;
        for (uint8 i = 0; i < jokeCount; i++) {
            if (jokes[i].votes > maxVotes) {
                bestJoke = jokes[i].joke;
                bestJokeTeller = jokeTellers[i];
            }
        }
    }      

    function getRaffleParticipants() public view returns (address[] memory) {
        return raffleParticipants;
    } 

    function drawRaffle() public onlyOwner {
        require(raffleOpen == true, "Raffle hasn't been opened yet");
        uint256 numParticipants = raffleParticipants.length;
        // Draw Winner
        raffleWinner = raffleParticipants[block.number % numParticipants];
        // Send 500 USDC to winner
        uint256 withdrawableUSDC = IERC20(USDC_ADDRESS).balanceOf(address(this));        
        IERC20(USDC_ADDRESS).transferFrom(address(this), raffleWinner, withdrawableUSDC);
    }

    function withdrawUSDC() public onlyOwner {
        uint256 withdrawableUSDC = IERC20(USDC_ADDRESS).balanceOf(address(this));
        require(withdrawableUSDC != 0, "There is no USDC to withdraw");
        IERC20(USDC_ADDRESS).transfer(_msgSender(), withdrawableUSDC);
    }

}