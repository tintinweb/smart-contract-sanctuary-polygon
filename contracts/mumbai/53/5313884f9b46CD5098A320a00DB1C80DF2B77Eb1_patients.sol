//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
import "./service.sol";

contract patients is service {
    /* 
    *  Mapa para almacenar los archivos de los pacientes
    *  El uint256 es el id del paciente(CIPA)
    *  El string es el hash del archivo
    */
    mapping(uint256 => string[]) private files;

    // Constructor que inicializa la variable owner con la direccion del creador del contrato
    constructor() {
        owner = payable(msg.sender);
    }

    /* 
    *  Función que añade un archivo a un paciente (CIPA) que se le pasa como parametro
    *  Además se comprueba que el doctor que añade el archivo es autorizado
    *  y que el CIPA no existe en el sistema
    */
    function addFile(uint256 _cipa, string memory _cid) public {
        require(
            getDoctor(msg.sender) == 1,
            "Only authorized doctor can add file"
        );
        for (uint256 i = 0; i < files[_cipa].length; i++) {
            if (
                keccak256(abi.encodePacked(files[_cipa][i])) ==
                keccak256(abi.encodePacked(_cid))
            ) {
                revert("File already exists");
            }
        }
        files[_cipa].push(_cid);
    }

    // Función que devuelve los archivos que tiene un paciente (CIPA )
    function getFile(uint256 _cipa) public view returns (string[] memory) {
        return files[_cipa];
    }
}