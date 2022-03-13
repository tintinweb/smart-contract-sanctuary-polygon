/**
 *Submitted for verification at polygonscan.com on 2022-03-12
*/

//SPDX-License-Identifier: MIT"
pragma solidity >=0.4.4 <0.7.0;
pragma experimental ABIEncoderV2;

contract notes {

    // Dirección del profesor
    address public teacher_address;

    constructor() public {
        teacher_address = msg.sender;
    }

    // Mapping para relacionar el hash de l aidentidad del alumno con la nota.
    mapping(bytes32 => uint) Notas;
    
    // Array para los alumnos que pidan revisiones
    string[] revisiones;

    // Eventos
    event evento_evaluacion(bytes32);
    event evento_revision(string);

    // Función para evaluar a un alumno
    function evaluar(string memory _id, uint _nota) public SoloProfesor(msg.sender) {
        // Hash de la identificación del alumno
        bytes32 hash = keccak256(abi.encodePacked(_id));
        // Relación entre el hash y la nota
        Notas[hash] = _nota;
        // Se emite el evento de evaluaciónç
        emit evento_evaluacion(hash);
    }

    modifier SoloProfesor(address _direccion) {
        // La direccion introducida debe de ser igual a la del owner del contrato
        require(teacher_address == _direccion, "No tienes permisos para ejecutar esta función");
        _;
    }

    // Función para visualizar las notas de un alumno
    function visualizar(string memory _id) public view returns(uint) {
        // Hash de la identificación del alumno
        bytes32 hash = keccak256(abi.encodePacked(_id));
        // Se devuelve la nota del alumno
        return Notas[hash];
    }

    // Función para pedir una revisión del examen
    function solicitar_revision(string memory _id) public {
        revisiones.push(_id);
        emit evento_revision(_id);
    }

    // Función para hacer la revisión
    function revision() public view SoloProfesor(msg.sender) returns(string[] memory) {
        return revisiones;
    }
}