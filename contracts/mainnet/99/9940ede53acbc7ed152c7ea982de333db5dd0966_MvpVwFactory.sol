/**
 *Submitted for verification at polygonscan.com on 2022-05-26
*/

// SPDX-License-Identifier: BSL
// File: contracts/mvp_vw_contrato_locacion.sol


pragma solidity =0.8;

contract ContratoLocacion {


    address locatario;
    address locador;
    string public name;
    string fileUrl;
    string fileHash;

    uint256 status;
    uint256 timestamp;
    string description;

 
    constructor (address _locatario, address _locador, string memory _name, string memory _fileUrl, string memory _fileHash ) {

        locatario = _locatario;
        locador = _locador;
        name = _name;
        fileUrl = _fileUrl;
        fileHash = _fileHash;

        status = 1;
        timestamp = block.timestamp;
        description = "Contrato a la espera de ser aprobado por el locatario";

    }

    modifier locatarioOnly() {
        require(msg.sender == locatario, "Solo el locatario puede ejecutar esta funcion");
        _; 
    }

    modifier locadorOnly() {
        require(msg.sender == locador, "Solo el locador puede ejecutar esta funcion");
        _; 
    }


    function leerEstado () external view returns (uint256, string memory, uint256, string memory, string memory) {

        return (status, description , timestamp, fileUrl , fileHash  );
    }


    function aprobarContrato (string memory _fileHash) external locatarioOnly {

        require(status == 1, "Ya aprobado");
        require( keccak256(abi.encodePacked((fileHash))) == keccak256(abi.encodePacked((_fileHash))), "La firma del archivo no coincide");
        timestamp = block.timestamp;
        status = 2;
        description = "Contrato aprobado por el locatario, esperando la entrega por parte del locador";
    }


    function desaprobarContrato () external locatarioOnly {

        require(status == 1, "Ya aprobado");
        timestamp = block.timestamp;
        status = 0;
        description = "El contrato ha sido cancelado definitivamente por el locatario";
    }

    function marcarEnviado () external locadorOnly {

        require(status == 2, "El contrato todavia no ha sido aprobado");
        timestamp = block.timestamp;
        status = 3;
        description = "El envio ha sido realizado y el locatario tiene que confirmar haberlo recibido";
    }

    function cancelarContrato () external locadorOnly {

        require(status < 4 , "El contrato ya ha sido aprobado por ambas partes");
        timestamp = block.timestamp;
        status = 0;
        description = "El contrato ha sido cancelado definitivamente por el locador";
    }


    function aprobarRecibido () external locatarioOnly {

        require(status == 3, "Todavia no se ha realizado el envio");
        timestamp = block.timestamp;
        status = 4;
        description = "El locatario ya ha confirmado la recepcion del envio y lo ha aprobado";
    }

    function desaprobarRecibido () external locatarioOnly {

        require(status == 3, "Todavia no se ha realizado el envio");
        timestamp = block.timestamp;
        status = 2;
        description = "El locatario ha desaprobado el envio y sera reenviado nuevamente al locador";
    }



}
// File: contracts/mvp_vw_factory.sol


pragma solidity =0.8;


contract MvpVwFactory {

    address owner;

 
    constructor () {
        owner = msg.sender;
    }

    modifier ownerOnly() {
        require(msg.sender == owner);
        _; 
    }

    event ContractCreated(address);


    function deploy(address _locatario, address _locador, string memory _name, string memory _fileUrl, string memory _fileHash ) public ownerOnly returns (address){
        ContratoLocacion contrato = new ContratoLocacion(_locatario, _locador, _name, _fileUrl, _fileHash );
        emit ContractCreated(address(contrato));
        return address(contrato);
    }



}

//  0x6EfB0dF107c8354509c3D4e4DE3AF76938bD8739,0x308c62e06239E21f32422473af2704C8dF136C7c, "Brian", "https://endpoint.com/contratos/12345.pdf", "abcdefghi"