/**
 *Submitted for verification at polygonscan.com on 2022-10-10
*/

pragma solidity ^0.8.12;

contract AtoB{
    struct Detail{
        string Title;
        string Content;
        string Description;
        string Ipfs_Hash;
    }
    event AddDetail(uint indexed  UserId,string  Title,string  Content,string   Description,string  indexed Ipfshash,bool Status );
    mapping (uint => Detail)UserDetails;
    address public  Owner;
    constructor(){
        Owner =msg.sender;
    }
    modifier OnlyOwner(){
        require(msg.sender == Owner);
        _;
    }
    function addDetail( uint _userId,string memory _title,string memory _content,string memory _description,string memory _ipfsHash)OnlyOwner external {
        require(bytes(_title).length !=0 && bytes(_content).length !=0 && bytes(_description).length!=0&&bytes(_ipfsHash).length !=0);
        UserDetails[_userId].Title=_title;
        UserDetails[_userId].Content=_content;
        UserDetails[_userId].Description=_description;
        UserDetails[_userId].Ipfs_Hash=_ipfsHash;
        emit  AddDetail(_userId,_title,_content,_description, _ipfsHash,true);
    }
    function getUserDetails(uint _userId)public view returns( Detail memory){
        return(UserDetails[_userId]);
    }

}