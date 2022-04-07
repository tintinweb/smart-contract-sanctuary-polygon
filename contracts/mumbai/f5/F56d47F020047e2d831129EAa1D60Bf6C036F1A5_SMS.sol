/**
 *Submitted for verification at polygonscan.com on 2022-04-06
*/

pragma solidity >= 0.8.1;

contract SMS {

  address desde;
  address recibe;

  struct Coreo {
    string Assunto;
    string Texto;
  }

  Coreo coreo;

  constructor(string memory Assunto, string memory Texto, address _recibe) {
    desde = msg.sender;
    coreo = Coreo(Assunto, Texto);
    require(msg.sender == desde);
    recibe = _recibe;
  }

  function LeerSMS() public view returns(string memory, string memory){
    require(msg.sender == recibe, "No tienes premiso");
    return (coreo.Assunto, coreo.Texto);
  }

}