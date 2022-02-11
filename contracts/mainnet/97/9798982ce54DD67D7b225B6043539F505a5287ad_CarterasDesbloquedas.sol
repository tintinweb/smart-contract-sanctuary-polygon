/**
 *Submitted for verification at polygonscan.com on 2022-02-04
*/

pragma solidity ^0.8.11;
contract CarterasDesbloquedas {
    mapping(address => uint) private usuario_ultima_cartera;
    mapping (address => bool) public permitedAddress;
    constructor() {
        permitedAddress[msg.sender]=true;
    }
    modifier whenPermited() {
        require(permitedAddress[msg.sender],"Not permited");
        _;
    }
    function setPermitedAddress(address ad, bool permited) public whenPermited {
        permitedAddress[ad]=permited;
    }
    function setCartera(address ad,uint cartera) public whenPermited {
        usuario_ultima_cartera[ad]=cartera;
    }
    function getCartera(address ad) public view returns(uint){
        return usuario_ultima_cartera[ad];
    }
}