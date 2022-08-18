/**
 *Submitted for verification at polygonscan.com on 2022-08-17
*/

pragma solidity ^0.8.9;

contract ChainContract {

    string public constant VERSION = '1.0.0';
    address private owner;
    mapping(uint256 => string) public contracts;

    constructor(){
        owner = msg.sender;
    }

    modifier isOwner() {
        require(msg.sender == owner, "Caller is not owner");
        _;
    }

    function sign(uint256 _contractId, string memory _hashedContent) public isOwner
    {
        contracts[_contractId] = _hashedContent;
    }


}