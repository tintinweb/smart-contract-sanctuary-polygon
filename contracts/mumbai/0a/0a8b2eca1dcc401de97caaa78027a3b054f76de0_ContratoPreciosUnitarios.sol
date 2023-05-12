/**
 *Submitted for verification at polygonscan.com on 2023-05-12
*/

pragma solidity ^0.5.17;

contract ContratoPreciosUnitarios {

    address public contratista;
    address public cliente;
    address public director;
    address public interventor;
    uint public valorContrato;
    uint public valorEjecutado;
    uint public valorPago;

    enum Estado {
        EnProgreso,
        EsperandoVerificacionInterventor,
        EsperandoVerificacionDirector,
        EsperandoAprobacionFinal,
        PendientePago,
        Completado
    }
    Estado public estado;

    struct Factura {
        address contratista;
        uint ejecutado;
        string documentos;
        bool verificadoPorInterventor;
        bool verificadoPorDirector;
        bool verificadoPorCliente;
        string motivoRechazo;
    }

    Factura[] public facturas;

    event FacturaRechazada(uint indexed indice, string motivo);

    constructor(address _contratista, address _cliente, address _interventor, address _director, uint _valorContrato) public {
        contratista = _contratista;
        cliente = _cliente;
        interventor = _interventor;
        director = _director;
        valorContrato = _valorContrato;
        estado = Estado.EnProgreso;
    }

    function subirFactura(uint _ejecutado, string memory _documentos) public {
        require(msg.sender == contratista, "Solo el contratista puede subir facturas");
        require(estado == Estado.EnProgreso, "El contrato no está en progreso");

        facturas.push(Factura({
            contratista: msg.sender,
            ejecutado: _ejecutado,
            documentos: _documentos,
            verificadoPorInterventor: false,
            verificadoPorDirector: false,
            verificadoPorCliente: false,
            motivoRechazo: ""
        }));

        estado = Estado.EsperandoVerificacionInterventor;
    }

    function verificarPorInterventor(uint _indice, string memory _motivoRechazo) public {
        require(msg.sender == interventor, "Solo el interventor puede verificar facturas");
        require(estado == Estado.EsperandoVerificacionInterventor, "La factura no está esperando verificación del interventor");

        Factura storage factura = facturas[_indice];

        if (bytes(_motivoRechazo).length > 0) {
            // Si el motivo de rechazo está presente, se rechaza la factura
            estado = Estado.EnProgreso;
            emit FacturaRechazada(_indice, _motivoRechazo);
        } else {
            factura.verificadoPorInterventor = true;
            estado = Estado.EsperandoVerificacionDirector;
        }

    }

    function verificarPorDirector(uint _indice, string memory _motivoRechazo) public {
        require(msg.sender == interventor, "Solo el interventor puede verificar facturas");
        require(estado == Estado.EsperandoVerificacionDirector, "La factura no está esperando verificación del director");

        Factura storage factura = facturas[_indice];

        if (bytes(_motivoRechazo).length > 0) {
            // Si el motivo de rechazo está presente, se rechaza la factura
            estado = Estado.EnProgreso;
            emit FacturaRechazada(_indice, _motivoRechazo);
        } else {
            factura.verificadoPorDirector = true;
            estado = Estado.EsperandoAprobacionFinal;
        }

    }

    function verificarPorCliente(uint _indice, string memory _motivoRechazo) public {
        require(msg.sender == cliente, "Solo el cliente puede aprobar facturas");
        require(estado == Estado.EsperandoAprobacionFinal, "La factura no está esperando verificación del cliente");

        Factura storage factura = facturas[_indice];

        if (bytes(_motivoRechazo).length > 0) {
            // Si el motivo de rechazo está presente, se rechaza la factura
            estado = Estado.EnProgreso;
            emit FacturaRechazada(_indice, _motivoRechazo);
        } else {
            factura.verificadoPorCliente = true;
            estado = Estado.PendientePago;
            valorPago = factura.ejecutado;
        }

    }
    

    function realizarPago() public payable {
        require(msg.sender == cliente, "Solo el cliente puede realizar el pago");
        require(estado == Estado.PendientePago, "El contrato no está completado");

        address payable _contratista = address(uint160(contratista));
        _contratista.transfer(valorPago);
        //payable(contratista).transfer(valorPago);
        valorEjecutado += valorPago;
        valorPago = 0;

        if (valorEjecutado >= valorContrato) {
            estado = Estado.Completado;
        } else {
            estado = Estado.EnProgreso;
        }

    }

    function facturasLength() public view returns (uint) {
        return facturas.length;
    }

}