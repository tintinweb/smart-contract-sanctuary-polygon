/**
 *Submitted for verification at polygonscan.com on 2022-06-06
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;
pragma experimental ABIEncoderV2;

contract ProyectoBIM {

    address private owner;

    struct Proyecto {
        uint id; 
        string nombre;   
        uint256 creado;
    }
    struct Elemento {
        uint id;
        uint id_proyecto;   
        string nombre;
        uint256 creado; 
        uint256 certificado;
     }

    struct Archivo {
        uint id;
        uint id_elemento;   
        string hash;
        uint256 creado; 
     }

    uint256 public cantidadProyectos = 0;
    uint256 public cantidadElementos = 0;
    uint256 public cantidadArchivos = 0;

    mapping(uint256 => Proyecto) private proyectos;
    mapping(uint256 => Elemento) private elementos;
    mapping(uint256 => Archivo) private archivos;


    event OwnerSet(address indexed oldOwner, address indexed newOwner);
    event NewProyecto(uint256 indexed idblockchain, uint indexed id);
    event NewElemento(uint256 indexed idblockchain, uint indexed id);
    event NewArchivo(uint256 indexed idblockchain, uint indexed id);
    event CerfificarElemento(uint indexed id);


    modifier isOwner() {
        require(msg.sender == owner, "Caller is not owner");
        _;
    }
    
    constructor ()  {
        owner = msg.sender; 
        emit OwnerSet(address(0), owner);
    }

    function changeOwner(address newOwner) public isOwner {
        emit OwnerSet(owner, newOwner);
        owner = newOwner;
    }

    function getOwner() external view returns (address) {
        return owner;
    }

    function addProyecto(uint  _id, string  memory _nombre) public isOwner {
        require(_id>0,"id debe ser mayor a 0");
        require(bytes(_nombre).length>0,"nombre no puede ser nulo");
        bool found=false;
        for ( uint256 i = 0; i <= cantidadProyectos ; i++) {
            if ( _id == proyectos[i].id) { 
                found=true;
            }
        }
        require(found==false, "Proyecto ya cargado");
        Proyecto storage proyecto = proyectos[cantidadProyectos];
        proyecto.id = _id;
        proyecto.nombre =  _nombre;
        proyecto.creado = block.timestamp;
        cantidadProyectos++;
    }

    function addElemento(uint  _id, string  memory _nombre,uint _id_proyecto) public isOwner {
        require(_id>0,"id debe ser mayor a 0");
        require(bytes(_nombre).length>0,"nombre no puede ser nulo");
        require(_id_proyecto < cantidadProyectos, "id_proyecto inexistente");
        bool found=false;
        for ( uint256 i = 0; i <= cantidadElementos ; i++) {
            if ( _id == elementos[i].id) { 
                found=true;
            }
        }
        require(found==false, "Elemento ya cargado");
        Elemento storage elemento = elementos[cantidadElementos];
        elemento.id = _id;
        elemento.nombre =  _nombre;
        elemento.id_proyecto =  _id_proyecto;
        elemento.creado = block.timestamp;
        emit NewElemento(cantidadProyectos, _id);
        cantidadElementos++;
    }

    function addArchivo(uint  _id, string  memory _hash,uint _id_elemento) public isOwner {
        require(_id>0,"id debe ser mayor a 0");
        require(bytes(_hash).length>0,"hash no puede ser nulo");
        require(_id_elemento < cantidadElementos, "_id_elemento inexistente");
        bool found=false;
        for ( uint256 i = 0; i <= cantidadArchivos ; i++) {
            if ( _id == archivos[i].id) { 
                found=true;
            }
        }
        require(found==false, "Archivo ya cargado");
        Archivo storage archivo = archivos[cantidadArchivos];
        archivo.id = _id;
        archivo.hash =  _hash;
        archivo.id_elemento =  _id_elemento;
        archivo.creado = block.timestamp;
        emit NewArchivo(cantidadProyectos, _id);
        cantidadArchivos++;
    }

    function getProyecto(uint _id) public view returns (uint,
                                                        string memory,uint256)  {
        return (proyectos[_id].id,
                proyectos[_id].nombre,
                proyectos[_id].creado);
    }

    function getElemento(uint _id) public view returns (uint,
                                                        uint,
                                                        string memory,
                                                        uint256,
                                                        uint256)  {
        return (elementos[_id].id,
                elementos[_id].id_proyecto,
                elementos[_id].nombre,
                elementos[_id].creado,
                elementos[_id].certificado);
    }

    function getArchivo(uint _id) public view returns (uint,
                                                        uint,
                                                        string memory,
                                                        uint256)  {
        return (archivos[_id].id,
                archivos[_id].id_elemento,
                archivos[_id].hash,
                archivos[_id].creado);
    }

    function certificarElemento(uint _id) public isOwner  {
        require(_id < cantidadElementos, "_id_elemento inexistente");
        elementos[_id].certificado=block.timestamp;
        emit CerfificarElemento(_id);
        return;
    }

    function getProyectoById(uint _id) public view returns (uint256)  {
        bool found=false;
        for ( uint256 i = 0; i <= cantidadProyectos ; i++) {
            if ( _id == proyectos[i].id) {  
                found=true;  
                return i;
            }
        }
        require(found, "No encontrado");
        return 0; 
    }

    function getElementoById(uint _id) public view returns (uint256)  {
        bool found=false;
        for ( uint256 i = 0; i <= cantidadElementos ; i++) {
            if ( _id == elementos[i].id) {
                return i;
            }
        }
        require(found, "No encontrado");
        return 0;
    }

    function getArchivoById(uint _id) public view returns (uint256)  {
        bool found=false;
        for ( uint256 i = 0; i <= cantidadArchivos ; i++) {
            if ( _id == archivos[i].id) { 
                return i;
            }
        }
        require(found, "No encontrado");
        return 0;
           
    }    
}