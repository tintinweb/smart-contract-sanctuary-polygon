/**
 *Submitted for verification at polygonscan.com on 2022-11-24
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

contract Messagebox {
    
    Message[] public messages;
    event NewMessage(address indexed author, string message); // Event
    mapping(address =>string) perfilUsuario;
    mapping(address =>bool) public walletRegistrado;
    
    struct Message{
        string mensaje;
        uint256 fecha;
        address autor;
    }
    

    constructor ()  {
        messages.push( Message("Hello World!",block.timestamp,msg.sender));
        emit NewMessage(msg.sender, "Hello World!");
    }
    
    function addMessage(string memory _new_message) public {
        messages.push(Message(_new_message,block.timestamp,msg.sender));
        emit NewMessage(msg.sender, _new_message);      
    }
    
    function getMessages() public view returns (string[] memory mensajes) {
        mensajes = new string[](messages.length);
        for(uint i=0; i<messages.length; i++) {
            mensajes[i] = messages[i].mensaje;
        }
        return mensajes;
    }

    function getMessagesAndDetailv1() public view returns(Message[] memory mesajesAndDetail) { 
        return messages;
    }

    struct MessageWithAlias{
        string mensaje;
        uint256 fecha;
        address autor;
        string aliasautor;
    }

    function getMessagesAndDetailv2() public view returns(MessageWithAlias[] memory mesajesAndDetail) {
        mesajesAndDetail = new MessageWithAlias[](messages.length);
        for(uint i=0; i<messages.length; i++) {
            mesajesAndDetail[i].mensaje = messages[i].mensaje;
            mesajesAndDetail[i].fecha = messages[i].fecha;
            mesajesAndDetail[i].autor = messages[i].autor;
            mesajesAndDetail[i].aliasautor = perfilUsuario[messages[i].autor];
        }
        return mesajesAndDetail;
    }
    function getMessageAndDetailByIndex(uint index) public view returns(string memory mensaje, uint fecha, address autor, string memory aliasautor) {
        mensaje = messages[index].mensaje;
        fecha = messages[index].fecha;
        autor = messages[index].autor;
        aliasautor = perfilUsuario[messages[index].autor];
    }


    function setAlias(string memory aliasName) public payable{
        if(walletRegistrado[msg.sender]) { //primera vez es falso - le dejamos gratis
            require(msg.value == 0.001 ether, "change alias requiere 0.001 ethers");
        }else {
            walletRegistrado[msg.sender] = true;  //registramos nuevo usuario
        }
        perfilUsuario[msg.sender] = aliasName;  //guardamos alias del wallet
    }

    function getAliasForAddress(address _wallet) public view returns(string memory userAlias) {
        return perfilUsuario[_wallet];
    }

    function getBalance() public view returns(uint) {
        return address(this).balance;
    }
}