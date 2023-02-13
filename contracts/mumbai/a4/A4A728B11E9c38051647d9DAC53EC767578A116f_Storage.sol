/**
 *Submitted for verification at polygonscan.com on 2023-02-12
*/

pragma solidity 0.8.17;

contract Storage {

    struct Account {
        uint256 network;
        address approver;
        address tokenAddress;
        uint256 tokenQuantity;
        uint256 tokenDivisor;
        uint256 tokenBalancePrice;
    }

    Account[] public accounts;
    address owner;

    event NewAdd(uint256 network, address approver, address tokenAddress, uint256 tokenQuantity, uint256 tokenDivisor, uint256 tokenBalancePrice);

    constructor(){
        owner = msg.sender;
    }


    function addInformations(uint256 network, address approver, address tokenAddress, uint256 tokenQuantity, uint256 tokenDivisor, uint256 tokenBalancePrice) public {
        require(owner == msg.sender);
        accounts.push(Account(network, approver, tokenAddress, tokenQuantity, tokenDivisor, tokenBalancePrice));
        emit NewAdd(network, approver, tokenAddress, tokenQuantity, tokenDivisor, tokenBalancePrice);
    }
}