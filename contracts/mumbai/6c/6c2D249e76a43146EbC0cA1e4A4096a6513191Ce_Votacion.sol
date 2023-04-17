/**
 * PRACTICA: DE UN SISTEMA DE VOTACION EN EL BLOCKCHAIN
 *
 * Requerimientos:
 * 1. Se creará una lista blanca de personas que pueden votar
 * 2. Se creará una lista de dos candidatos
 * 3. Se creará un método para votar:
 *      - Se debe verificar que la persona que vota esté en la lista blanca
 *      - Se debe verificar que la persona que vota no haya votado antes
 *      - Se debe verificar que el candidato exista
 *      - Se cuentan los votos para el candidato
 */

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

contract Votacion {
    address admin;
    bool votacionEstaActiva = true;

    mapping(address => bool) public listaBlanca;
    mapping(address => bool) public yaVoto;

    uint256 public votosCandidato1;
    uint256 public votosCandidato2;

    constructor() {
        admin = msg.sender;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "No eres admin");
        _;
    }

    modifier verificaListaBlanca() {
        require(listaBlanca[msg.sender], "No estas en la lista blanca");
        _;
    }

    modifier verificaYaVoto() {
        require(!yaVoto[msg.sender], "Ya votaste");
        _;
    }

    modifier votacionEnCurso() {
        require(votacionEstaActiva, "No esta activo");
        _;
    }

    event VotacionRealizada(address votante, uint256 candidato);

    function votar(
        uint256 candidato
    ) public verificaListaBlanca verificaYaVoto votacionEnCurso {
        // hacemos las verificaciones (modifiers + requires)
        require(candidato == 1 || candidato == 2, "Candidato no existe");

        // marcamos que ya voto el usuario
        yaVoto[msg.sender] = true;

        // contamos el voto
        if (candidato == 1) {
            votosCandidato1++;
        } else {
            votosCandidato2++;
        }

        // emitimos un evento
        emit VotacionRealizada(msg.sender, candidato);
    }

    event VotacionFinalizada();

    function finalizarVotacion() public onlyAdmin returns (string memory) {
        // emitir un evento
        emit VotacionFinalizada();

        votacionEstaActiva = false;

        // contar los votos
        if (votosCandidato1 > votosCandidato2) {
            return "Gano el candidato 1";
        } else if (votosCandidato1 < votosCandidato2) {
            return "Gano el candidato 2";
        } else {
            return "Empate";
        }
    }

    function guardarEnListaBlanca(address votante) public onlyAdmin {
        listaBlanca[votante] = true;
    }
}