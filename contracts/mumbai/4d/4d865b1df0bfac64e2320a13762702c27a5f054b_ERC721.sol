/**
 *Submitted for verification at polygonscan.com on 2022-06-09
*/

/**
 *Submitted for verification at polygonscan.com on 2022-03-07
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

contract ERC721  {

        string public name;
        string public symbol;
        address ownerOfContract;

        mapping(address=>uint) public balanceOf;
        mapping(uint=>address) public tokenApprovals;
        mapping(uint=>address) public tokenIds;
        mapping(address=>mapping(address=>bool)) public operatorApprovals;
        event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
        event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);
        event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    // ***Constructor function, gets the token name and symbol. ***
        constructor(string memory _token_name,string memory _token_symbol) {
            ownerOfContract=msg.sender;
            name=_token_name;
            symbol=_token_symbol;
        }
    // ****Internal function to mint a new token. Reverts if the given token ID already exists.***
        function mint(address _to,uint _token_id) public{
            require(msg.sender != address(0),"not valid Address");
            require(msg.sender == _to,"Call must be same as address _to");
            require(tokenIds[_token_id]==address(0),"Token Id is already exists.");
            
            balanceOf[_to] +=1;
            tokenIds[_token_id]=_to;
        }
    // ***Safely transfers the ownership of a given token ID to another address If the target address is a contract***
        function safeTransferFrom(address _from, address _to, uint256 _tokenId) public
        {
            require(msg.sender==tokenIds[_tokenId] || msg.sender==tokenApprovals[_tokenId] || operatorApprovals[tokenIds[_tokenId]][msg.sender]==true ,"Only owner/approved can call this function");
            require(_from!=address(0),"Sender address is not valid");
            require(_to!=address(0),"Recipient address is not valid");
            require(_to!=_from,"Recipient address is same as Sender address");
            require(tokenIds[_tokenId] !=address(0),"Token Id is not valid");
            require(tokenIds[_tokenId]==_from,"Token id is not belong to owner");
            if(tokenApprovals[_tokenId] !=address(0))
            {
                tokenApprovals[_tokenId]=address(0);
            }
            balanceOf[_from] -=1;
            balanceOf[_to] +=1;
            tokenIds[_tokenId]=_to;

            emit Transfer(_from,_to,_tokenId);
        }

    // ***Gets the owner of the specified token ID.
            function ownerOf(uint _tokenId) public view returns (address)
            {
            require(tokenIds[_tokenId] !=address(0),"Token Id is not valid");
            address owner=tokenIds[_tokenId];
            return owner;
            }

    // *** Approves another address to transfer the given token ID The zero address indicates there is no approved address.***
            function approve(address _approved, uint256 _tokenId) public
            {  
            require(tokenIds[_tokenId] !=address(0),"TokenId is not valid");
            require(msg.sender==tokenIds[_tokenId],"It is just for Owner");
            require(_approved!=address(0),"approved address is not valid"); 
            tokenApprovals[_tokenId]=_approved;
            emit Approval(msg.sender,_approved,_tokenId);
            }

    // ***Gets the approved address for a token ID, or zero if no address set Reverts if the token ID does not exist.***
            function getApproved(uint _tokenId) public view returns (address){
            require(tokenIds[_tokenId] !=address(0),"TokenId is not valid");
            address approval_address=tokenApprovals[_tokenId];
            return approval_address;
            }

    // ***Sets or unsets the approval of a given operator An operator is allowed to transfer all tokens of the sender on their behalf.***
            function setApprovalForAll(address _operator, bool _approved) public
            {
            require(_operator!=address(0),"operator address is not valid");
            require(msg.sender != _operator, "opeartor address is not equal to owner");
            operatorApprovals[msg.sender][_operator]=_approved;
            emit ApprovalForAll(msg.sender,_operator,_approved);
            }

    // ***Tells whether an operator is approved by a given owner.***
            function isApprovedForAll(address _owner, address _operator) public view returns (bool){
            require(_owner!=address(0),"owner address is not valid");
            require(_operator!=address(0),"operator address is not valid");
            return operatorApprovals[_owner][_operator];
            }

}