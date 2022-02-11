/**
 *Submitted for verification at polygonscan.com on 2022-02-05
*/

pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

// import "@openzeppelin/contracts/access/Ownable.sol"; 
// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol

contract UserPostLike {
  // Events
  event SetLikeToPost(address user, address post);

  // Fields
  address public constant OWNER = 0x53eaCf386176e165eA897bE327f4d7BB9fC7bEC3;
  // from address post => user like 
  mapping(address => mapping(address => bool)) public postUserLiked;

  // from user => all post of user add like
  //                 PostStorage
  mapping(address => address[]) public userPostLike;

  // from post get all liked posts;
  mapping(address => address[]) public postAllUserLiked;

  // Modifiers
  modifier onlyOwner(){
    require(msg.sender == OWNER, "Not Onwer");
    _;
  }

  // Methods
  constructor() onlyOwner {}

  function setLike(address post) public {
    if(postUserLiked[post][msg.sender] == false){
      postUserLiked[post][msg.sender] = true;
      postAllUserLiked[post].push(msg.sender);
      userPostLike[msg.sender].push(post);
      emit SetLikeToPost(msg.sender, post);
    }
  }
  function removeLike(address post) public {
    if(postUserLiked[post][msg.sender] == true){
      postUserLiked[post][msg.sender] = false;
      uint256 count = userPostLike[msg.sender].length;
      if(userPostLike[msg.sender].length != 1){
        // find the index position of Post in user Like post 
        for (uint256 index = 0; index < count; index++) {
          // if post in index position is equal to search post
          if(userPostLike[msg.sender][index] == post){
            // i will move the last index post in current index to pop it
            userPostLike[msg.sender][index] = userPostLike[msg.sender][count -1 ];
            break;
          }
        }
      }
      if (postAllUserLiked[post].length != 1) {
        for (uint256 index = 0; index < postAllUserLiked[post].length; index++) {
          if (postAllUserLiked[post][index] == msg.sender) {
            postAllUserLiked[post][index] = postAllUserLiked[post][postAllUserLiked[post].length -1];
            break;
          }
        }
      }
      userPostLike[msg.sender].pop();
      postAllUserLiked[post].pop();
    }
  }

  function getAllPosts(address user) public view returns (address[] memory) {
    uint256 postId = userPostLike[user].length;
    address[] memory _posts = new address[](postId);
    for (uint256 index = 0; index < postId; index++) {
        _posts[index] = userPostLike[user][index];
    }
    return _posts;
  }
  
  function getAllLiked(address post) public view returns (address[] memory) {
    uint256 countUsers = postAllUserLiked[post].length;
    address[] memory _users = new address[](countUsers);
    for (uint256 index = 0; index < countUsers; index++) {
        _users[index] = postAllUserLiked[post][index];
    }
    return _users;
  }

  function countUserLikedPost(address user) public view returns (uint256) {
    return  userPostLike[user].length;
  }
}