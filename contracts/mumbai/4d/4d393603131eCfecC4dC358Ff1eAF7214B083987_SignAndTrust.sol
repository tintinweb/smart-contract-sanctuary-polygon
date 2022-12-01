/**
 *Submitted for verification at polygonscan.com on 2022-11-30
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;

contract SignAndTrust {

    // BLOQUE PROPIETARIO DEL CONTRATO
    address owner;
    // Se define el propietario del contrato.
    constructor(){
        owner = msg.sender;
    }
    // Se crea el modificador que solamente permitirá al propietario realizar ciertas funciones.
    modifier onlyOwner(){
        require(msg.sender == owner, "[SMC] - Funcionalidad no permitida.");
        _;
    }
    // FIN BLOQUE PROPIETARIO DEL CONTRATO

    // BLOQUE ADMINISTRADOR
    // Se crea el modificador que solamente permitirá a los usuarios administradores realizar ciertas funciones.
    modifier onlyAdmin(){
        bool adminExists = false;
        for(uint i=0; i<adminaccounts.length; i++){
            if(adminaccounts[i] == msg.sender){
                adminExists = true;
            }
        }
        require(adminExists == true, "[SMC] - Funcionalidad no permitida.");
        _;
    }
    // FIN BLOQUE ADMINISTRADOR

    // BLOQUE USUARIO
    // Se crea el modificador que solamente permitirá a los usuarios administradores realizar ciertas funciones.
    modifier onlyUser(){
        bool userExists = false;
        for(uint i=0; i<useraccounts.length; i++){
            if(useraccounts[i] == msg.sender){
                userExists = true;
            }
        }
        require(userExists == true, "[SMC] - Funcionalidad no permitida.");
        _;
    }
    // FIN BLOQUE USUARIO

    // Array de direcciones de administración.
    address [] internal adminaccounts;

    // Array de direcciones de usuarios.
    address [] internal useraccounts;

    // Array de direcciones de firmantes (global a la aplicación).
    address [] internal signeraccounts;

    // Array de documentos (direcciones hash IPFS).
    string [] internal docs;

    // Mapping con datos de documentos y direcciones de firmantes
    mapping (uint256 => address) DocsAndSigners;
    
    // EVENTOS
        // Evento disparado al añadir direcciones de usuarios administradores.
        event newEventAddAdminAccount(
            address indexed adminaddress
        );

        // Evento disparado al añadir direcciones de usuarios de la aplicación.
        event newEventAddUserAccount(
            address indexed useraddress
        );

        // Evento disparado al añadir direcciones de posibles firmantes (para cualquier documento).
        event newEventAddSignerAccount(
            address indexed signeraddress
        );

        // Evento disparado al añadir documentos.
        event newEventAddDoc(
            string indexed docs
        );

        // Evento disparado al añadir firmantes a documentos.
        event newEventAddSignersToDocument(
            string indexed docaddress,
            address indexed signeraddress
        );
    // FIN EVENTOS

    // BLOQUE PROPIETARIO DEL CONTRATO
        // Función para añadir direcciones de usuarios administradores.
        function addAdminAccount(address _adminaddress) external onlyOwner{
            adminaccounts.push(_adminaddress);
            emit newEventAddAdminAccount(_adminaddress);
        }

        // Función para obtener todas las direcciones de firmantes (para cualquier documento) almacenadas en el contrato.
        function getDataAdmins() external view onlyOwner returns(address[] memory) {
            return adminaccounts;
        }

        // Función para obtener una única dirección de administrador almacenada en el contrato.
        function getDataAdmin(address _adminaddress) external view onlyOwner returns(bool){
            bool adminExists = false;
            for(uint i=0; i<adminaccounts.length; i++){
                if(adminaccounts[i] == _adminaddress){
                    adminExists = true;
                    return adminExists;
                } else {
                    adminExists = false;
                }
            }
            return adminExists;
        }

    // FIN BLOQUE PROPIETARIO DEL CONTRATO

    // BLOQUE ADMINISTRADOR
        // Función para añadir direcciones de posibles firmantes (para cualquier documento).
        function addSigner(address _signeraddress) external onlyAdmin{
            // Se comprueba que la dirección de firmante ya conste como usuario de la aplicación.
            bool existeusuario = getDataUser(_signeraddress);
            require(existeusuario == true, "[SMC] - El firmante debe estar dado de alta como usuario.");
            signeraccounts.push(_signeraddress);
            emit newEventAddSignerAccount(_signeraddress);
        }

        // Función para obtener todas las direcciones de firmantes (para cualquier documento) almacenadas en el contrato.
        function getDataSigners() external view onlyAdmin returns(address[] memory) {
            return signeraccounts;
        }

        // Función para obtener una única dirección de firmante almacenada en el contrato.
        function getDataSigner(address _signeraddress) external view onlyAdmin returns(bool) {
            bool signerExists = false;
            for(uint i=0; i<signeraccounts.length; i++){
                if(signeraccounts[i] == _signeraddress){
                    signerExists = true;
                    return signerExists;
                } else {
                    signerExists = false;
                }
            }
            return signerExists;
        }
    // FIN BLOQUE ADMINISTRADOR

    // BLOQUE USUARIOS APLICACIÓN
        // Función para añadir direcciones de posibles firmantes (para cualquier documento).
        function addUser(address _useraddress) external onlyAdmin{
            useraccounts.push(_useraddress);
            emit newEventAddUserAccount(_useraddress);
        }

        // Función para obtener todas las direcciones de usuarios almacenadas en el contrato.
        function getDataUsers() external view onlyAdmin returns(address[] memory) {
            return useraccounts;
        }

        // Función para obtener una única dirección de usuario almacenada en el contrato.
        function getDataUser(address _useraddress) public view onlyAdmin returns(bool) {
            bool userExists = false;
            for(uint i=0; i<useraccounts.length; i++){
                if(useraccounts[i] == _useraddress){
                    userExists = true;
                    return userExists;
                } else {
                    userExists = false;
                }
            }
            return userExists;
        }

    // FIN BLOQUE USUARIOS APLICACIÓN

    // BLOQUE GESTION DE DOCUMENTOS
        // Función para añadir documentos.
        function addDocument(string memory _docaddress) external onlyUser{
            docs.push(_docaddress);
            emit newEventAddDoc(_docaddress);
        }

        // Función para obtener todas las direcciones de documentos almacenados en el contrato.
        function getDataDocs() external view onlyUser returns(string[] memory) {
            return docs;
        }

        // Función que verifica si un hash de documento existe almacenado en el contrato
        function getDataDoc(string memory _docaddress) public view onlyUser returns(bool) {
            bool docExists = false;
            for(uint i=0; i<docs.length; i++){
                if(keccak256(bytes(docs[i])) == keccak256(bytes(_docaddress))){
                    docExists = true;
                    return docExists;
                } else {
                    docExists = false;
                }
            }
            return docExists;
        }

        // Función que obtiene el id de posicion dentro del array 
        // de documento para un determinado hash de documento.
        function getIdPosDataDoc(string memory _docaddress) internal view onlyUser returns(uint256) {
            uint256 docId;
            for(uint i=0; i<docs.length; i++){
                if(keccak256(bytes(docs[i])) == keccak256(bytes(_docaddress))){
                    docId = i;
                    return docId;
                } else {
                    docId;
                }
            }
            return docId;
        }

    // FIN BLOQUE GESTION DE DOCUMENTOS

    // BLOQUE DE DOCUMENTOS-FIRMANTES

        // Función para comprobar si el firmante ya está asociado al documento.

        // Función para añadir firmante a documento.
        function addSignerToDocument(string memory _docaddress, address _signeraddress) external onlyUser{
            uint256 docId = getIdPosDataDoc(_docaddress);
            require(docId >= 0, "[SMC] - El id de firmante indicado no consta dado de alta como tal.");
            DocsAndSigners[docId] = _signeraddress;
            emit newEventAddSignersToDocument(_docaddress, _signeraddress);
        }

        // Función para obtener todos los firmantes asociados a un documento

    // FIN BLOQUE DE DOCUMENTOS-FIRMANTES

}