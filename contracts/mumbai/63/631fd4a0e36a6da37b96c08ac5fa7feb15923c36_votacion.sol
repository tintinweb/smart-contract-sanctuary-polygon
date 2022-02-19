/**
 *Submitted for verification at polygonscan.com on 2022-02-18
*/

// File: contracts/votacion.sol


pragma solidity ^0.8.12;
 
contract votacion{
    uint256 nombredavid;
    uint256 nombreluis;
    uint256  nombrealberto;

    address votantes;

    function votardavid( uint256 x) public {
        nombredavid = nombredavid + x;
    }
    function votarluis( uint256  y) public {
        nombreluis = nombreluis + y;
    }
    function votaralberto( uint256  z) public {
        nombrealberto = nombrealberto + z;
    }

        function misvotantes( address _votantes) private {
        votantes=_votantes;
    }
 


    function RecuperarDavid() public view returns (uint256) {
      
        return nombredavid;
                 
    }
     function RecuperarAlberto() public view returns (uint256) {
      
        return nombrealberto;
                 
    }
     function RecuperarLuis() public view returns (uint256) {
      
        return nombreluis;
                 
    }

   
}