/**
 *Submitted for verification at polygonscan.com on 2022-09-05
*/

//SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

contract Faucet {  
    address public owner; // requerimiento 1
    event OwnerSet(address oldOwner, address newOwner);

    constructor () payable{
        owner==msg.sender;}
    
    function request () external { //requerimiento 3

        require(address(this).balance>=1 ether); //requerimiento 4    
        
        address payable user =payable (msg.sender);}

    function send() external payable {

        require(msg.sender== owner, "Solo el propietario del contrato puede ejecutar esta funcion");}//requerimiento 5
    
    function withdraw() external {// requerimiento 6

        require(msg.sender== owner, "Solo el propietario del contrato puede extraer todos los fondos");

        address payable user = payable (msg.sender);

        uint balance = address(this).balance;

        user.transfer(balance);}   

    modifier isOwner() { //bonus numero 1

        require(msg.sender == owner, "Solo el propietario puede ceder la propiedad del contrato");
        _;}
    function changeOwner(address newOwner) public isOwner {
        
        emit OwnerSet(owner, newOwner);
        owner = newOwner; 
    }
}