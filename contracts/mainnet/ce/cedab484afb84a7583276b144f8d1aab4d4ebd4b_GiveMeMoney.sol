// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

contract GiveMeMoney {
    address owner;
    uint256 public total;
    uint256 private ids;
    Donor[] private donations;

    //Definindo a estrututa do Donor (doador)
    struct Donor {
        uint256 id;
        address donor;
        uint256 value;
    }


    constructor () {
        //Defina o remetente da transação como o proprietário do contrato.
        owner = msg.sender;
    }

    //Modificador para verificar se o chamador é o proprietário do
    //contrato.
    modifier onlyOwner() {
        require(msg.sender == owner, "not owner");
        _;
    }

    function donate() external payable {
        require(msg.value > 0,"value not enough");
        ids++;
        Donor memory donation = Donor(ids, msg.sender, msg.value);
        donations.push(donation);
        total += msg.value;
    }

    function getDonations() external view returns (Donor[] memory) {
        return donations;
    }

    function withdraw() external payable onlyOwner() {
        uint256 balance = address(this).balance;
        require(balance > 0, "balance not enough");

        (bool sucess,) = (msg.sender).call{value: balance}("");
        require(sucess, "transfer failed");
        }

    }