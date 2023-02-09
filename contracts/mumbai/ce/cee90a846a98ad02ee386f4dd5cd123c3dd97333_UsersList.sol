/**
 *Submitted for verification at polygonscan.com on 2023-02-08
*/

pragma solidity >=0.5.8 <0.6.0;

contract UsersList
{
    address    Owner ;

    struct IpfsLink
    {
      bytes32  used ;
       string  link ;
    }

    mapping (bytes32 => IpfsLink)  UsersIpfsLinks ;

    bytes32[]  Users ;

//
   constructor() public
   {
              Owner     = tx.origin ;
   }
// 
   function PutUser(bytes32  user_, string memory ipfs_link_) public
   {
       if(msg.sender!=Owner)  return ;

       if(UsersIpfsLinks[user_].used!="Y")
       {
             UsersIpfsLinks[user_]=IpfsLink({ used: "Y", link: ipfs_link_ }) ;

                    Users.push(user_) ;
       }
       else
       {
             UsersIpfsLinks[user_].link=ipfs_link_ ;
       }
   }
//
    function GetUser(bytes32  user_) public view returns (string memory retVal)
    {
       return(UsersIpfsLinks[user_].link) ;
    }
//
    function GetUsersList() public view returns (bytes32[] memory retVal)
    {
       return(Users) ;
    }

}