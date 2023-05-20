// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MovieVoting {
    struct Movie {
        uint256 id;
        string title;
        uint256 goodVotes;
        uint256 badVotes;
        bool isVotingOpen;
    }

    mapping(uint256 => Movie) public movies;
    uint256 public totalMovies;
    address public owner;

    event MovieAdded(uint256 movieId, string title);
    event VoteCasted(uint256 movieId, bool isGoodVote, uint256 totalGoodVotes, uint256 totalBadVotes);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only contract owner can perform this action");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function addMovie(string memory _title) public onlyOwner {
        uint256 movieId = totalMovies + 1;
        movies[movieId] = Movie(movieId, _title, 0, 0, true);
        totalMovies++;
        emit MovieAdded(movieId, _title);
    }

    mapping(address=> mapping(uint256=>bool)) public hasVoted;

    function castVote(uint256 _movieId, bool _isGoodVote) public {
        require(_movieId <= totalMovies, "Invalid movie ID");
        require(movies[_movieId].isVotingOpen, "Voting for this movie is closed");

        require(!hasVoted[msg.sender][_movieId], "You have already voted for this movie");

        if (_isGoodVote) {
            movies[_movieId].goodVotes++;
        } else {
            movies[_movieId].badVotes++;
        }

        hasVoted[msg.sender][_movieId] = true;

        emit VoteCasted(
            _movieId,
            _isGoodVote,
            movies[_movieId].goodVotes,
            movies[_movieId].badVotes
        );
    }

    function closeVoting(uint256 _movieId) public onlyOwner {
        require(_movieId <= totalMovies, "Invalid movie ID");
        movies[_movieId].isVotingOpen = false;
    }

    // function displayVote(uint256 _movieId) public view returns (uint256, uint256){
    //     require(_movieId <= totalMovies, "Enter Correct Movie ID");
    //     return (movies[_movieId].goodVotes, movies[_movieId].badVotes);
    // }
}