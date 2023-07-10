/**
 *Submitted for verification at polygonscan.com on 2023-07-09
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
 
contract Storage
{   
    uint public userCount = 0;
    uint public fileCount = 0; 
    mapping(uint256 => user) public usersList;
    mapping(uint256 => file) public fileList;
    struct user
    {
       string username;
       address userAddress;
    }

    struct file
    {
       string fileUrl;
       address[] userAddress;
    }
   // events
 
   event userCreated(
      string username,
      address userAddress
    );

    event fileCreated(
      string fileUrl,
      address[] userAddress
    );

    event fileShared(
      string fileUrl,
      address[] userAddress
    );
 
  function createUser(string memory _username) public
  {   
      require(msg.sender!=address(0),"User address invalid");
      for(uint i=0;i<userCount;i++)
      {
        // if(usersList[i+1].userAddress==msg.sender)
        // {
          require(usersList[i+1].userAddress!=msg.sender,"User address already created");
        //}
      }

      userCount++;
      usersList[userCount] = user(_username, msg.sender);
      emit userCreated(_username, msg.sender);
    }

    function addFiles(string memory _fileUrl) public
    {
      require(msg.sender!=address(0),"User address invalid");
      fileCount++;
      fileList[fileCount] = file(_fileUrl, new address[](0));
      fileList[fileCount].userAddress.push(msg.sender);
      emit fileCreated(_fileUrl, fileList[fileCount].userAddress);
    }

    function getAllFiles() public view returns(string[] memory)
    {
        string[] memory ret = new string[](fileCount);
        uint256 fileUsers;
        for(uint i=0;i<fileCount;i++)
        {
          fileUsers=fileList[i+1].userAddress.length;
          for(uint j=0;j<fileUsers;j++)
          {
            if(fileList[i+1].userAddress[j]==msg.sender)
            {
              ret[i]= fileList[i+1].fileUrl;
            }
          }
        }
        return ret;
    }

    function fetchUsers() public view returns(string[] memory)
    {
        string[] memory ret = new string[](userCount);
        for(uint i=0;i<userCount;i++)
        {
          if(usersList[i+1].userAddress!=msg.sender)
          {
            ret[i]= usersList[i+1].username;
          }
        }
        return ret;
    }

    function shareFilePermission(string memory _fileUrl, address _userAddress) public
    {
        require(_userAddress!=address(0),"User address invalid");
        uint256 record;
        for(uint i=1;i<=fileCount;i++)
        {
          if(keccak256(abi.encodePacked(fileList[i].fileUrl)) == keccak256(abi.encodePacked(_fileUrl)))
          {
            record=i;
          }
        }

        fileList[record].userAddress.push( _userAddress);
        emit fileShared(_fileUrl, fileList[record].userAddress);
    }
}