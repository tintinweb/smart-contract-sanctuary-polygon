//SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

contract HolaMundo {
    /*
        Emitir eventos es necesario para comunicarse con nuestro subgrafo (Subgraph).
        Cuando nuestro contrato inteligente emite eventos durante una transacción,
        nuestro subgrafo reacciona para manejar esos eventos y mapearlos a nuestros entidades (Entity / Entities) definidas en nuestro Esquema (Schema).
    */
    event NuevoSaludoCreado( // El evento: NuevoSaludoCreado se emite cada vez que se llama a la función crearNuevoSaludo()
        bytes32 saludoId, // Identificador de saludo
        string saludoDatosCID, // CID que apunta a nuestros datos almacenados en IPFS
        address saludador, // Dirección de la persona que creó este saludo específico
        uint256 marcaDeTiempo // Marca de tiempo de cuando se creó el saludo; Para que podamos ordenar los saludos por fecha
    );

    event SaludoRecibido(bytes32 saludoId, address de); // El evento se emite cada vez que se llama a nuestra función enviarSaludo()

    /*
        Una estructura (struct) para representar un Saludo.
        Una estructura es como crear un nuevo data tipo (datatype) que contiene información relacionada entre sí.
    */
    struct Saludo {
        bytes32 saludoId; 
        string saludoDatosCID; 
        address saludador;
        uint256 marcaDeTiempo; 
        uint256 saludosRecibidos; // Aquí almacenamos y realizamos un seguimiento de los saludos recibidos por otros usuarios
    }

    /*
        Los mapeos (mapping) son lo que creamos cuando queremos almacenar datos en el blockchain.
        Almacenan valores en forma de pares clave-valor.
        A continuación, definimos una asignación entre el saludoId (clave) y la estructura Saludo (valor).
        Es nuestro almacenamiento para nuestros Saludos.
    */
    mapping(bytes32 => Saludo) public todosSaludos;

    function crearNuevoSaludo( // Cree un nuevo saludo proporcionando el CID a nuestros datos almacenados en ipfs para asociarlo con nuestro saludo
        string calldata saludoDatosCID
    ) external {

        // Obtener marca de tiempo (en segundos)
        uint256 marcaDeTiempo = block.timestamp;

        // Creando un identificador único para cada nuevo saludo creado para poder recuperarlo más tarde
        bytes32 saludoId = keccak256(
            abi.encodePacked(
                msg.sender, // dirección de la persona que llama a la función
                address(this), // dirección de la instancia del contrato
                marcaDeTiempo,
                saludoDatosCID
            )
        );

        // Agregando a nuestro almacenamiento de Saludos
        todosSaludos[saludoId] = Saludo(
            saludoId,
            saludoDatosCID,
            msg.sender,
            marcaDeTiempo,
            0
        );
        // Emitir evento que anuncia la creación de un nuevo Saludo
        emit NuevoSaludoCreado(
            saludoId,
            saludoDatosCID,
            msg.sender,
            marcaDeTiempo 
        );
    }

    // Enviar un Saludo de vuelta a un Saludo existente proporcionando el greetingId
    function enviarSaludo(bytes32 saludoId) external {
        // Recuperar el saludo existente de nuestro almacenamiento con el greetingId
        Saludo storage saludo = todosSaludos[saludoId];        require(msg.sender != saludo.saludador, "No puedes saludarte a ti mismo.");
        // Requerir que la persona que llama a la función (msg.sender) no se saludan a si mismos
        require(msg.sender != saludo.saludador);
        // Actualizar saludo
        saludo.saludosRecibidos += 1;
        // Emitir evento que anuncia el saludo asociado con greetingId recibió un nuevo saludo de msg.sender
        emit SaludoRecibido(saludoId, msg.sender);
    }

}