// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract Movie {

    mapping(uint => movieDeatilsRequest) public moviesRequest;
    mapping(address => movieDeatilsRequest[]) public moviesFunded;
    mapping(address => movieDeatilsRequest[]) public moviesBought;
    uint256 numberMovieDetails;

    function saveMovieDetailsRequest(string memory movieName, string memory directorName,
                                    string memory description, uint256 fundNeeded) external {

        moviesRequest[numberMovieDetails].movieName = movieName;
        moviesRequest[numberMovieDetails].directorName = directorName;
        moviesRequest[numberMovieDetails].description = description;
        moviesRequest[numberMovieDetails].fundNeeded = fundNeeded;
        moviesRequest[numberMovieDetails].requester = msg.sender;

        numberMovieDetails = numberMovieDetails + 1;
    }

    function fundMovie(uint256 index, uint256 amountFunded) external {
        //update amount 
        moviesRequest[index].fundNeeded = moviesRequest[index].fundNeeded - amountFunded; 

        //add in users list all the movies funded
        movieDeatilsRequest memory temp = movieDeatilsRequest(moviesRequest[index].movieName,
        moviesRequest[index].directorName,moviesRequest[index].description,moviesRequest[index].fundNeeded,moviesRequest[index].requester);
        moviesFunded[msg.sender].push(temp);

        //TODO: mint NFT
    }

    function boughtMovie(uint256 index) external {
        //add the movie in users list
        movieDeatilsRequest memory temp = movieDeatilsRequest(moviesRequest[index].movieName,
        moviesRequest[index].directorName,moviesRequest[index].description,moviesRequest[index].fundNeeded,moviesRequest[index].requester);
        moviesBought[msg.sender].push(temp);
    }

    function getDetails(uint256 index) public view returns(movieDeatilsRequest memory) {
        return moviesFunded[msg.sender][index];
    }

    struct movieDeatilsRequest{
        string movieName;
        string directorName;
        string description;
        uint256 fundNeeded;
        address requester;
    }
}