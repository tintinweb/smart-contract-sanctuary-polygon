/**
 *Submitted for verification at polygonscan.com on 2022-03-04
*/

/**
 *Submitted for verification at Etherscan.io on 2022-03-03
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

contract ERC721  {

        string public name;
        string public symbol;
        address ownerOfContract;

        mapping(uint=>address) public tokenids;
        mapping(address=>uint) public balanceOf;
        mapping(uint=>address) public tokenApprovals;
        mapping(address=>mapping(address=>bool)) public operatorApprovals;
        event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
        event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);
        event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);


        constructor(string memory _token_name,string memory _token_symbol) {
            ownerOfContract=msg.sender;
            name=_token_name;
            symbol=_token_symbol;
        }

        function mint(address _to,uint _token_id) public{
            require(msg.sender != address(0),"Invalid Address");
            require(msg.sender == _to,"Call must be same as address _to");
            require(tokenids[_token_id]==address(0),"Token Id is already exists.");
            
            balanceOf[_to] +=1;
            tokenids[_token_id]=_to;
        }

        function safeTransferFrom(address _from, address _to, uint256 _tokenId) public
        {
            require(msg.sender==tokenids[_tokenId] || msg.sender==tokenApprovals[_tokenId] || operatorApprovals[tokenids[_tokenId]][msg.sender]==true ,"Only owner/approved can call this function");
            require(_from!=address(0),"Sender address is invalid");
            require(_to!=address(0),"Recipient address is invalid");
            require(_to!=_from,"Recipient address is same as Sender address");
            require(tokenids[_tokenId] !=address(0),"Token Id is invalid");
            require(tokenids[_tokenId]==_from,"Token id is not belong to owner");
            if(tokenApprovals[_tokenId] !=address(0))
            {
                tokenApprovals[_tokenId]=address(0);
            }
            balanceOf[_from] -=1;
            balanceOf[_to] +=1;
            tokenids[_tokenId]=_to;

            emit Transfer(_from,_to,_tokenId);
        }

            function ownerOf(uint _tokenId) public view returns (address)
            {
            require(tokenids[_tokenId] !=address(0),"Token Id is invalid");
            address ownerOfToken=tokenids[_tokenId];
            return ownerOfToken;
            }

            function approve(address _approved, uint256 _tokenId) public
            {  
            require(tokenids[_tokenId] !=address(0),"Token Id is invalid");
            require(msg.sender==tokenids[_tokenId],"Only owner can call this function");
            require(_approved!=address(0),"approved address is invalid"); 
            tokenApprovals[_tokenId]=_approved;
            emit Approval(msg.sender,_approved,_tokenId);
            }

            function getApproved(uint _tokenId) public view returns (address){
            require(tokenids[_tokenId] !=address(0),"Token Id is invalid");
            address approval_address=tokenApprovals[_tokenId];
            return approval_address;
            }

            function setApprovalForAll(address _operator, bool _approved) public
            {
            require(_operator!=address(0),"operator address is invalid");
            require(msg.sender != _operator, "opeartor address is not equal to owner");
            operatorApprovals[msg.sender][_operator]=_approved;
            emit ApprovalForAll(msg.sender,_operator,_approved);
            }

            function isApprovedForAll(address _owner, address _operator) public view returns (bool){
            require(_owner!=address(0),"owner address is invalid");
            require(_operator!=address(0),"operator address is invalid");
            return operatorApprovals[_owner][_operator];
            }

}