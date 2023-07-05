/**
 *Submitted for verification at polygonscan.com on 2023-07-04
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
 
contract Storage
{   
    uint public userCount = 0;
    uint public fileCount = 0; 
    mapping(address => user) public usersList;
    mapping(uint256 => file) public fileList;
    struct user
    {
       string username;
       address userAddress;
    }

    struct file
    {
       string fileUrl;
       address userAddress;
    }
   // events
 
   event userCreated(
      string username,
      address userAddress
    );

    event fileCreated(
      string fileUrl,
      address userAddress
    );
 
  function createUser(string memory _username) public
  {   
      require(msg.sender!=address(0),"User address invalid");
      userCount++;
      usersList[msg.sender] = user(_username, msg.sender);
      emit userCreated(_username, msg.sender);
    }

    function addFiles(string memory _fileUrl) public
    {
      require(msg.sender!=address(0),"User address invalid");
      fileCount++;
      fileList[fileCount] = file(_fileUrl, msg.sender);
      emit fileCreated(_fileUrl, msg.sender);
    }

    function getAllFiles() public view returns(file[] memory)
    {
        file[] memory ret = new file[](fileCount);
        for(uint i=0;i<fileCount;i++)
        {
            ret[i]= fileList[i+1];
        }
        return ret;
    }
}