/**
 *Submitted for verification at polygonscan.com on 2022-02-01
*/

pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

// import "hardhat/console.sol";
// import "@openzeppelin/contracts/access/Ownable.sol"; 
// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol

contract UserPostLike {
  // Events
  event SetLikeToPost(address user, address post);

  // Fields
  address public owner = 0x53eaCf386176e165eA897bE327f4d7BB9fC7bEC3;
  // from address post => user like 
  mapping(address => mapping(address => bool)) public postUserLiked;

  // from user => all post of user add like
  //                 PostStorage
  mapping(address => address[]) public userPostLike;
  mapping (address => uint256) public countUserLikedPost;

  // Modifiers
  modifier onlyOwner(){
    require(msg.sender == owner, "Not Onwer");
    _;
  }

  // Methods
  constructor() onlyOwner {}

  function setLike(address post) public {
    if(postUserLiked[post][msg.sender] == false){
      postUserLiked[post][msg.sender] = true;
      countUserLikedPost[msg.sender] += 1;
      userPostLike[msg.sender].push(post);
      emit SetLikeToPost(msg.sender, post);
    }
  }
  function removeLike(address post) public {
    if(postUserLiked[post][msg.sender] == true){
      postUserLiked[post][msg.sender] = false;
      countUserLikedPost[msg.sender] -= 1;
      if(userPostLike[msg.sender].length != 1){
        // find the index position of Post in user Like post 
        for (uint256 index = 0; index < countUserLikedPost[msg.sender]; index++) {
          // if post in index position is equal to search post
          if(userPostLike[msg.sender][index] == post){
            // i will move the last index post in current index to pop it
            userPostLike[msg.sender][index] = userPostLike[msg.sender][countUserLikedPost[msg.sender]];
            break;
          }
        }
      }
      userPostLike[msg.sender].pop();
    }
  }

  function getAllPosts(/*address user*/) public view returns (address[] memory) {
    address user = msg.sender;
    uint256 postId = countUserLikedPost[user];
    // console.log(postId);
    address[] memory _posts = new address[](postId);
    for (uint256 index = 0; index < postId; index++) {
        _posts[index] = userPostLike[user][index];
    }
    return _posts;
  }
}