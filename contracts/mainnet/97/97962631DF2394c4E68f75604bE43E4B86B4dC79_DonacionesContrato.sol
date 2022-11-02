// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.9.0;

contract DonacionesContrato {

    struct ProductoDonado {
        string descripcionProducto;
        uint cantidad;
    }

    enum EstadoDonacion {
        PROCESADO,
        RESERVADO,
        TRASLADO,
        ENTREGADO
    }
    
    struct DonacionRequest {
        uint idDonacion;
        uint idOrganizacion;
        string organizacion;
        uint idCampania;
        string campania;
        uint idDonador;
        ProductoDonado[] productosDonados;
    }

    struct Donacion {
        uint idDonacion;
        uint idOrganizacion;
        string organizacion;
        uint idCampania;
        string campania;
        uint idDonador;
        ProductoDonado[] productosDonados;
        uint timestamp;
        EstadoDonacion estado;
    }

    struct DonacionResponse {
        uint idDonacion;
        string organizacion;
        string campania;
        ProductoDonado[] productosDonados;
        uint timestamp;
        EstadoDonacion estado;
    }

    Donacion[] private donaciones;
    address private owner;

    constructor(){
        owner = msg.sender;
    }

    event datosDonacion (
        DonacionResponse response
    );

    modifier chequearModificador() {
        require(owner == msg.sender, "No esta autorizado a modificar los datos dentro del contrato");
        _;
    }

    function crearResponse(Donacion memory donacion) private pure returns (DonacionResponse memory response) {
        response = DonacionResponse(donacion.idDonacion, donacion.organizacion, donacion.campania, donacion.productosDonados, donacion.timestamp, donacion.estado);
    }

    function chequearExistencia(DonacionRequest memory donacion) private view {
        for (uint256 i = 0; i < donaciones.length; i++) {
            if(donaciones[i].idDonacion == donacion.idDonacion){
                revert("Ya existe una donacion con el id asignado");
            }
        }
    }

    function crearDonacion(DonacionRequest memory request) public chequearModificador {
        chequearExistencia(request);
        uint timestamp = block.timestamp;
        Donacion storage nuevaDonacion = donaciones.push();

        nuevaDonacion.idDonacion = request.idDonacion;
        nuevaDonacion.idOrganizacion = request.idOrganizacion;
        nuevaDonacion.organizacion = request.organizacion;
        nuevaDonacion.idCampania = request.idCampania;
        nuevaDonacion.campania = request.campania;
        nuevaDonacion.idDonador = request.idDonador;
        nuevaDonacion.timestamp = timestamp;
        nuevaDonacion.estado = EstadoDonacion.PROCESADO;

        for (uint256 i = 0; i < request.productosDonados.length; i++) {
            nuevaDonacion.productosDonados.push(request.productosDonados[i]);
        }

        DonacionResponse memory response = crearResponse(nuevaDonacion);
        emit datosDonacion(response);
    }

    function consultarTodasLasDonaciones() public view returns (DonacionResponse[] memory){
        DonacionResponse[] memory lista = new DonacionResponse[](donaciones.length);
        for (uint256 i = 0; i < donaciones.length; i++) {
            lista[i] = crearResponse(donaciones[i]);
        }
        return lista;
    }

    function consultarDonacionesPorId(uint idDonacion) public view returns (DonacionResponse memory){
        for (uint256 i = 0; i < donaciones.length; i++) {
            if(donaciones[i].idDonacion == idDonacion){
                return crearResponse(donaciones[i]);
            }
        }

        revert("No se encontro la donacion con el id ingresado");
    }


    function consultarDonacionesPorOrganizacion(uint idOrganizacion) public view returns (DonacionResponse[] memory) {
        Donacion[] memory listaFiltrada = new Donacion[](donaciones.length);
        uint contador = 0;
        for (uint256 i = 0; i < donaciones.length; i++) {
            Donacion memory request = donaciones[i];
            if(request.idOrganizacion == idOrganizacion){
                listaFiltrada[contador] = donaciones[i];
                contador++;
            }
        }

        DonacionResponse[] memory lista = new DonacionResponse[](contador);

        for (uint256 i = 0; i < contador; i++) {
            lista[i] = crearResponse(listaFiltrada[i]);
        }

        return lista;
    }
}