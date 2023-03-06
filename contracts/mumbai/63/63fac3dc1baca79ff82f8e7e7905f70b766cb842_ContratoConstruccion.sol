/**
 *Submitted for verification at polygonscan.com on 2023-03-05
*/

pragma solidity ^0.5.17;
// Declaración del contrato inteligente

contract ContratoConstruccion {

    // Declaración de las direcciones de billetera para cada rol
    address public interventor;
    address public contratista;
    address public cliente;
    address public directorObra;
    uint public montoEjecutado;
    uint public montoContrato;
    
    // Declaración de los estados del contrato
    enum Estado { 
        Iniciado, 
        VerificacionInterventor, 
        VerificacionClienteDirectorObra, 
        PendientePago, 
        Finalizado }

    Estado public estadoContrato;
    
    // Declaración de los precios unitarios para cada componente del proyecto
    mapping (string => uint) public preciosUnitarios;
    mapping (string => uint) public cantidadEjecutada;
    string[] public componentes;

    //Declaración de mensajes (eventos)
    event FacturaSubida(address indexed contratista, string componente, uint cantidad, uint monto);
    event FacturaVerificada(address indexed interventor);
    event FacturaAprobada(address indexed clienteDirector);
    
    // Declaración del constructor para inicializar las direcciones y los precios unitarios
    constructor(address _interventor, address _contratista, address _cliente, address _directorObra, uint _montoContrato) public {
        interventor = _interventor;
        contratista = _contratista;
        cliente = _cliente;
        directorObra = _directorObra;
        estadoContrato = Estado.Iniciado;
        montoContrato = _montoContrato;
    }
    
    // Función para agregar precios unitarios
    function agregarPrecioUnitario(string memory componente, uint precio) public {
        require(msg.sender == interventor, "Solo el interventor puede agregar precios unitarios.");
        preciosUnitarios[componente] = precio;
        componentes.push(componente);
    }
    
    // Función para subir factura por parte del contratista
    function subirFactura(string memory componente, uint cantidad) public {
        require(msg.sender == contratista, "Solo el contratista puede subir facturas.");
        require(preciosUnitarios[componente] > 0, "Debe establecerse un precio unitario para el componente.");
        // Calcular el monto total de la factura
        uint montoTotal = preciosUnitarios[componente] * cantidad;
        // Se actualiza la cantidad ejecutada
        cantidadEjecutada[componente] = cantidad;
        // Emitir un evento para informar que se ha subido una factura
        emit FacturaSubida(contratista, componente, cantidad, montoTotal);
        estadoContrato = Estado.VerificacionInterventor;
    }
    
    // Función para que el interventor verifique y firme la factura
    function verificarFactura() public {
        require(msg.sender == interventor, "Solo el interventor puede verificar las facturas.");
        emit FacturaVerificada(interventor);
        estadoContrato = Estado.VerificacionClienteDirectorObra;
    }
    
    // Función para que el cliente y el director de obra verifiquen la factura y aprueben el pago
    function aprobarFactura() public {
        require(msg.sender == cliente || msg.sender == directorObra, "Solo el cliente y el director de obra pueden aprobar las facturas.");
        emit FacturaAprobada(msg.sender);
        // Si tanto el cliente como el director de obra han aprobado la factura, el contrato se finaliza
        if (msg.sender == cliente) {
            estadoContrato = Estado.PendientePago;
        }
    }
    
    // Función para realizar el pago correspondiente a las cantidades ejecutadas
    function realizarPago() payable public {
        require(msg.sender == cliente, "Solo el cliente puede realizar el pago.");
        require(estadoContrato == Estado.PendientePago, "El director de obra y el cliente deben verificar la factura primero.");
        // Calcular el monto total a pagar
        uint montoTotal = 0;
        for (uint i = 0; i < componentes.length; i++) {
            montoTotal += preciosUnitarios[componentes[i]] * cantidadEjecutada[componentes[i]];
            cantidadEjecutada[componentes[i]] = 0;
        }

        address payable _contratista = address(uint160(contratista));
        _contratista.transfer(montoTotal);
        montoEjecutado += montoTotal;

        if (montoEjecutado >= montoContrato) {
            estadoContrato = Estado.Finalizado;
        } else {
            estadoContrato = Estado.Iniciado;
        }

    }
}