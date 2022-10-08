/**
 *Submitted for verification at polygonscan.com on 2022-10-08
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ReceiveEther{

    //contracto alcancia
    //receive () 
    receive() external payable{}
    //fallback () solo se llama si msg.data esta vacio checar el 
    fallback() external payable {

    }
    //getBalance()

    function getBalance() public view returns(uint){
        return address(this).balance;
    }
}

contract SendEther{
    //transfer 23000 gas emite un error en caso de fallo
    function sendEtherTransfer(address payable _to) public payable{

        _to.transfer(msg.value);

    }
    //send 2300 gas, devuelve bool
    function sendEtherSend(address payable _to) public payable returns(bool){
        bool sent = _to.send(msg.value);
        require(sent,"error");
        return sent;
    }
    //call 
   /* function sendEtherCall(address payable _to) public payable returns(bool,bytes) {
        _//to.call{value:msg.value}("");

        (bool sent, bytes memory data) = _to.call{value: msg.value}("");
        require(sent,"failed");
        return (sent, data);
    
    }*/
    // call
    function sendEtherCall(address payable _to)  public payable returns(bool, bytes memory) {
        (bool sent, bytes memory data) = _to.call{value: msg.value}("");
        require(sent, "Fallo la transaccion");
        return(sent, data);
    }

}