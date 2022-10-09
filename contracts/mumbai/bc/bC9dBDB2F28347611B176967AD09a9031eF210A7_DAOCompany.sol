/**
 *Submitted for verification at polygonscan.com on 2022-10-08
*/

// File: @openzeppelin/contracts/utils/Strings.sol


// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// File: demo/data.sol

//SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.12; 
//No es necesario especificar el encoder, en versiones  > 0.8.0 se usa por defecto ABIEncoderV2



contract DAOCompany {
    address public Administrador;
    // uint256 public SaldoTotalRetiradoAdministrador;
    
    // Constructor del contrato 
    constructor () {
        Administrador = msg.sender;
    }
    

    // Estatico 
    struct Empresa {
        string nombreEmpresa;
        uint numeroTrabajadores;
        string nif;
    }

    struct Saldos {
        address saldoInicialEmpresa;
        address saldoVentas;
        address saldoRetenidoPagos;
    }

    struct PuestosDeTrabajo {
        string nombrePuesto;
        uint nominaInicial;
        uint maxNomina;
        uint cantidadAumentoNomina; // Asumo que es un % 
        uint tiempoAumentoNomina;
        uint horasMesLaborable;
        uint posicionesLibres; 
    }


    // Dinamico    
    struct Trabajadores {
        string puestoDeTrabajo;
        string nombre;
        string apellidos;
        uint fechaNacimiento;
        string dni;
        string email;
        address wallet;
        uint fechaDeAlta;
        uint fechaDeBaja;
        uint dineroRetirado;
        bool activo;
    }

    struct EmpresaProveedor {
        string nombreEmpresa;
        uint nif;
        string direecionEmpresa;
        mapping(bytes32 => ProductoEmpresa) productosOfrecidos;
        bool activo;
    }

    struct ProductoEmpresa {
        string material;
        uint costeMaterialIndividual;
        bool activo;
    }

    struct Dni_trabajadores {
        string dni;
        bool activo;
    }

    struct Saldo_retirado_Administrador {
        uint256 id;
        uint fecharetiro;
        uint256 cantidadretiro;
        uint256 totalRetirado;
    }
    // mapping (string => bool) public EstaOcupadoPuesto; //No es necesario en este caso 
    mapping (address => Trabajadores) public ViewTrabajador; 
    mapping (bytes32 => PuestosDeTrabajo) public Puestos_De_Trabajo; 
    mapping (uint => EmpresaProveedor) public Empresas_Pr; 
    mapping (string => ProductoEmpresa) public Empresas_Produc; 
    mapping (string => Dni_trabajadores) public Dni_portrabajadores; 
    mapping (uint256 => Saldo_retirado_Administrador) public SaldoRetiradoAdministrador; 
    

    uint []  empresas_registradas;
    uint256 contarretiradassaldoadministrador = 0;
    string [] lista_trabajadores;
    address [] lista_trabajadores_tipo_address;

    // Evento para generar latransferencia, se entiende que es en euros
    event Transfer(address indexed from, address indexed to, uint256 tokens);
    

    // Creamos la empresa Base
    Empresa public Nom_Empresa = Empresa("Aerodomic", 5, "00000000X"); 
    
    // Set wallet para saldos
    Saldos public walletStart = Saldos(0xa9eE4FF3765901f1147Daa739eEe6D5ed4c8a3FE, 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2, 0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db);
    // Agregacion temporal de cantidad de  saldo en la cuenta
    uint public TOTALDINEROCUENTA = 10000;

    // Decorador para que solo el administrador pueda realizar la funcion
    modifier UnicamenteAdmin() {
        require(msg.sender == Administrador, "No tienes permisos para realizar esta funcion.");
        _;
    }
    
    

    function AddTrabajador(string memory _puestoDeTrabajo, string memory _nombre, string memory _apellidos, uint256 _fechaNacimiento, string memory _dni, string memory _email, address _wallet) external UnicamenteAdmin(){
        
        //El puesto de trabajo puede ocuparse por más de un trabajador. 
        //Por ejemplo, tenemos 3 programadores y 2 comerciales.
        //Se comprueba si quedan vacantes libres para dicho puesto de trabajo lo cual resuelve el problema de tener un CEO o varios programadores

        //Comprobamos si el puesto de trabajo existe, sino habrá que crearlo
        bytes32 codigo_puestoDeTrabajo = keccak256(abi.encodePacked(_puestoDeTrabajo));
        require(Puestos_De_Trabajo[codigo_puestoDeTrabajo].posicionesLibres > 0, "El puesto de trabajo esta ocupado o no existe");
        require(ViewTrabajador[_wallet].activo == false, "Este trabajador ya esta dado de alta con esta wallet");           
        require(Dni_portrabajadores[_dni].activo == false, "Este trabajador ya esta dado de alta con este dni");

        //Registrar trabajador
        ViewTrabajador[_wallet].puestoDeTrabajo = _puestoDeTrabajo;
        ViewTrabajador[_wallet].nombre = _nombre;
        ViewTrabajador[_wallet].apellidos = _apellidos;
        ViewTrabajador[_wallet].fechaNacimiento = _fechaNacimiento;
        ViewTrabajador[_wallet].dni = _dni;
        ViewTrabajador[_wallet].email = _email;
        ViewTrabajador[_wallet].dineroRetirado = 0;
        ViewTrabajador[_wallet].wallet = _wallet;
        ViewTrabajador[_wallet].fechaDeAlta = block.timestamp;
        ViewTrabajador[_wallet].fechaDeBaja = 0;
        ViewTrabajador[_wallet].activo = true;
        lista_trabajadores.push(Strings.toHexString(_wallet));
        lista_trabajadores_tipo_address.push(_wallet);
        Dni_portrabajadores[_dni].activo = true;
        Puestos_De_Trabajo[codigo_puestoDeTrabajo].posicionesLibres -= 1;
    }

    //Función para dar trabajadores de baja
    function bajaTrabajador(address _address) external UnicamenteAdmin() {
        
        //Comprobar que el trabajador existe y está activo
        require(ViewTrabajador[_address].activo = true, "El trabajador ya esta dado de baja o no existe");

        //Actualizar variables del trabajador
        ViewTrabajador[_address].fechaDeBaja = block.timestamp;
        ViewTrabajador[_address].activo = false;
        Dni_portrabajadores[ViewTrabajador[_address].dni].activo = false;
        //Añadir una plaza libre al puesto de trabajo que ocupaba el trabajador
        string memory puestoDeTrabajo = ViewTrabajador[_address].puestoDeTrabajo;
        bytes32 codigo_puestoDeTrabajo = keccak256(abi.encodePacked(puestoDeTrabajo));
        Puestos_De_Trabajo[codigo_puestoDeTrabajo].posicionesLibres += 1;

    }

    //Función para registrar un nuevo puesto de trabajo
    function registrarPuestoDeTrabajo(string memory _nombrePuesto, uint256 _nominaInicial, uint256 _maxNomina, uint256 _cantidadAumentoNomina, uint256 _tiempoAumentoNomina, uint256 _horasMesLaborable, uint256 _posicionesLibres) external UnicamenteAdmin(){
        
        //Comprobar si existe o no el puesto de trabajo
        bytes32 codigo_puestoDeTrabajo = keccak256(abi.encodePacked(_nombrePuesto));
        require(Puestos_De_Trabajo[codigo_puestoDeTrabajo].nominaInicial <= 0, "El puesto de trabajo ya existe");
        
        //Antes de poder registrar el puesto de trabajo debemos comprobar que nominaInicial > SMI
        require(_nominaInicial >= 700, "La nomina inicial debe superar el SMI");
        require(_maxNomina > _nominaInicial+100, "La nomina maxima debe superar la nomina inicial en mas de 100" );
        
        //Registramos la informaicón del nuevo puesto de trabajo
        Puestos_De_Trabajo[codigo_puestoDeTrabajo].nombrePuesto = _nombrePuesto;
        Puestos_De_Trabajo[codigo_puestoDeTrabajo].nominaInicial = _nominaInicial;
        Puestos_De_Trabajo[codigo_puestoDeTrabajo].maxNomina = _maxNomina;
        Puestos_De_Trabajo[codigo_puestoDeTrabajo].cantidadAumentoNomina = _cantidadAumentoNomina;
        Puestos_De_Trabajo[codigo_puestoDeTrabajo].tiempoAumentoNomina = _tiempoAumentoNomina;
        Puestos_De_Trabajo[codigo_puestoDeTrabajo].horasMesLaborable = _horasMesLaborable;
        Puestos_De_Trabajo[codigo_puestoDeTrabajo].posicionesLibres = _posicionesLibres;
    }



    //Función para consultar el saldo disponible de un trabajador
    function ConsulSaldo(address _address) public view returns(uint256, uint256){
       
       address address_pedidor = _address;

        //Si el admin es quien está consultando el saldo, no comprobamos quien está lanzando la transacción, ya que el admin puede ver todos los datos
        if(msg.sender != Administrador){
            //Limitamos la consulta del saldo solo para el trabajador, o el propio contrato
            require(ViewTrabajador[address_pedidor].wallet == msg.sender || msg.sender == address(this), 'Usted no trabaja en la empresa');
        }
        

        // Creamos una variable con el puesto de trabajo del trabajador que se a solicitado tal informacion
        string memory trabaj = ViewTrabajador[address_pedidor].puestoDeTrabajo;
        
        //Crear variable con el puesto de trabajo del trabajador actual
        bytes32 codigo_puestoDeTrabajo = keccak256(abi.encodePacked(trabaj));
        PuestosDeTrabajo memory puestoActual = Puestos_De_Trabajo[codigo_puestoDeTrabajo];

        // Calculamos el tiempo que lleva en la empresa el trabajador
        // Comprobar si el trabajador está activo
        uint tiempo_total;
        if(ViewTrabajador[address_pedidor].activo){
            tiempo_total = (block.timestamp - ViewTrabajador[address_pedidor].fechaDeAlta) / 60;
        } else {
            tiempo_total = (ViewTrabajador[address_pedidor].fechaDeBaja - ViewTrabajador[address_pedidor].fechaDeAlta) / 60;
        }

        // ( fecha actual - fecha de alta / 60 segundos ) Esto se hace por que nos lo devuelve en segundos y con 
        //                                                      esto lo convertimos en minutos el tiempo en la empresa
        //Creamos una variable para saber el tiempo cada cuánto aumenta la nómina
        uint tiempo_aumento_nomina = puestoActual.tiempoAumentoNomina;
        
        // Creamos variable para calcular la cantidad de aumentos necesarios
        uint cantidad_aumentos = 0;

        // Creamos variable para contar el dinero acumulado en el for de mas adelante
        uint dinero_Acumulado = 0;

        // Creamos variable para saber cuanto gana el trabajador por minuto, se calcula en el for de mas adelante
        uint dinero_X_Minuto;
        
        // Creamos una variable para marcar el maximo que un trabajado puede cobrar, se calcula en el for de mas adelante
        uint max_dinero_X_minuto;

        // Creamos una variable para saber cuanto ha de aumentar la nomina en porcentaje, se calcula en el for de mas adelante
        uint aumento_nomina;

       
        //Calculamos los valores de las variables anteriores con los datos relacionados con el puesto de trabajo del trabajador seleccionado
        //No es necesario crear una estructura if, else if, else para acceder a la información de cualquier puesto de trabajo
        dinero_X_Minuto = puestoActual.nominaInicial * 1000 / 165 / 60; //Resultado en euros/minuto
        max_dinero_X_minuto = puestoActual.maxNomina * 1000 /165 / 60; //Resultado en euros/minuto
        aumento_nomina = puestoActual.cantidadAumentoNomina; //Porcentaje de aumento de la nómina
        tiempo_aumento_nomina = puestoActual.tiempoAumentoNomina; 

        //Calculamos el dinero que le corresponde al trabajador
        cantidad_aumentos = tiempo_total / puestoActual.tiempoAumentoNomina; // El número de aumentos totales = tiempo_total_en_la_empresa / tiempo_cada_cuando_se_aumenta_la_nomina
                                                                             //Ejemplo: Si el trabajador X lleva 15 minutos en la empresa y cada 5 minutos debe recibir un aumento, en total se reciben 15/5 = 3 aumentos
        
        
        //El bucle se repetirá una vez por aumento, no por minuto/mes trabajado. Probablemente de esta forma se necesiten menos iteraciones
        for(uint256 i = 0; i < cantidad_aumentos; i++){
            
            //Calculamos el acumulado hasta el momento =  dinero por minuto por la cantidad de tiempo que debe pasar para que haya un aumento.
            dinero_Acumulado += dinero_X_Minuto*tiempo_aumento_nomina;
            
            //Actualizamos el porcentaje del dinero por minuto que debe cobrar este trabajador
            if(dinero_X_Minuto*aumento_nomina/100 > max_dinero_X_minuto){
                dinero_X_Minuto = max_dinero_X_minuto;
            } else {
                dinero_X_Minuto += dinero_X_Minuto*aumento_nomina/100;
            }
        }

        //Ya hemos calculado el total que debe cobrar un trabajador hasta el último aumento, pero podrían quedar minutos restantes
        //Ejemplo Si el trabajador X lleva 17 minutos restantes, arriba abríamos calculado desde el minuto 1 al 15, faltan 2 minutos
        //Usando el operador % (módulo) podemos saber si quedan o no quedan meses por cobrar
        uint256 meses_no_cobrados = tiempo_total % puestoActual.tiempoAumentoNomina;
                
        while(meses_no_cobrados > 0){  //Mientras el módulo no sea 0 sabemos que quedan meses por cobrar
            dinero_Acumulado += dinero_X_Minuto; //Añadimos al acumulado el dinero por minuto que debemos cobrar
            tiempo_total -= 1; //Hay que restar el minuto cobrados
            meses_no_cobrados = tiempo_total % puestoActual.tiempoAumentoNomina; //Actualizamos los meses sin cobrar
        }

        

        //Calcular el dinero total que puede retirar el trabajador
        uint256 dineroDisponibleParaRetirar = dinero_Acumulado - ViewTrabajador[address_pedidor].dineroRetirado;

        return (dinero_Acumulado, dineroDisponibleParaRetirar);
       
    }

    function RetirarSaldo(address _address, uint numTokens) external returns(bool){
         // Requiere para asegurarse que la wallet es igual a la de la solicitud
        //require(msg.sender == ViewTrabajador[_address].wallet, "Solo puede retirar dinero suyo y no el de otro...");

        //Consultamos el saldo del trabajador actual
        (, uint256 dineroDisponibleParaRetirar) = ConsulSaldo(_address);

        //Verificamos que el saldo que quiere retirar el trabajador está disponible
        require(numTokens <= dineroDisponibleParaRetirar, "No tiene suficiente saldo acumulado");

        // Se agrega el dinero que solicitado retirar a la variable de dineroRetirado
        ViewTrabajador[_address].dineroRetirado += numTokens;
        TOTALDINEROCUENTA = TOTALDINEROCUENTA - numTokens;
        // Se emite un evento con la transferencia del dinero que solicito retirar
        // IMPORTANTE, el dinero solicitado sera en formato EURO, falta la funcion para que realice el cambio de euro a token
        emit Transfer(address(this), ViewTrabajador[_address].wallet, numTokens);
        return true;
    }


    // Funcion de retirar saldo solo por el Administrador del contrato
    // ## FALTA AGREGAR UN CONTADOR DE DINERO RETIRADO POR EL ADMINISTRADOR ## -- HECHO 
    function AdminRetirarSaldo(uint256 numTokens) external UnicamenteAdmin(){
        //emit Transfer(address(this), Administrador, numTokens);
        uint256 total_retenido = 0;
        for(uint256 i = 0; i < lista_trabajadores_tipo_address.length; i++){
            (, uint256 dis) = ConsulSaldo(lista_trabajadores_tipo_address[i]);
            total_retenido = total_retenido + dis;
        }

        //Verificamos que el saldo que quiere retirar el trabajador está disponible
        require(numTokens + total_retenido < TOTALDINEROCUENTA, "No tiene suficiente saldo la cuenta");

        TOTALDINEROCUENTA = TOTALDINEROCUENTA - numTokens;
        
        contarretiradassaldoadministrador += 1;
        SaldoRetiradoAdministrador[contarretiradassaldoadministrador].id = contarretiradassaldoadministrador;
        SaldoRetiradoAdministrador[contarretiradassaldoadministrador].fecharetiro = block.timestamp;
        SaldoRetiradoAdministrador[contarretiradassaldoadministrador].cantidadretiro = numTokens;
        SaldoRetiradoAdministrador[contarretiradassaldoadministrador].totalRetirado = SaldoRetiradoAdministrador[contarretiradassaldoadministrador-1].totalRetirado + numTokens;

        // Se agrega el dinero que solicitado retirar a la variable de dineroRetirado
        //ViewTrabajador[_address].dineroRetirado += numTokens;

        // Se emite un evento con la transferencia del dinero que solicito retirar
        // IMPORTANTE, el dinero solicitado sera en formato EURO, falta la funcion para que realice el cambio de euro a token
        emit Transfer(address(this), Administrador, numTokens);
    }

    //función para consultar el saldo retirado por el administrador
    function SaldoAdmin_show() external view returns(uint256){
        return SaldoRetiradoAdministrador[contarretiradassaldoadministrador].totalRetirado;
    }


    //Función para consultar todos los trabajadores en un array por wallet
    function AllTrabajadores_show() public view returns(string memory){
        bytes memory output;
        for (uint256 i = 0; i < lista_trabajadores.length; i++) {
            output = abi.encodePacked(output, " - ", lista_trabajadores[i]);
        }
        return string(output);
    }








    /* NUEVA ZONA, TAL VEZ EN OTRO CONTRATO? */
     // Funcion para gregar una nueva empresa proveedora
    function AgregarEmpresaProveedora(string memory _nombreEmpresa, uint _nif, string memory _direecionEmpresa) public returns (bool) {
        
        require(!Empresas_Pr[_nif].activo, "La empresa ya existe");
        
        // Se agrega al mapping los campos de la nueva empresa
        Empresas_Pr[_nif].nombreEmpresa = _nombreEmpresa;
        Empresas_Pr[_nif].nif = _nif;
        Empresas_Pr[_nif].direecionEmpresa = _direecionEmpresa;
        Empresas_Pr[_nif].activo = true;
        empresas_registradas.push(_nif);
        return true;
    }


    // Funcion para agregar un producto a la empresa proveedora
    function AgregaProductoEmpresaProveedora(uint _nif, string memory _material, uint _costeMaterialIndividual) external {     

        require(Empresas_Pr[_nif].activo, "La empresa no existe");
        
        //Calculamos el id del material
        bytes32 codigoMaterial = keccak256(abi.encodePacked(_material));
        require(!Empresas_Pr[_nif].productosOfrecidos[codigoMaterial].activo, "Material ya registrado" ); //No podríamos modificar el precio con esta función

        Empresas_Pr[_nif].productosOfrecidos[codigoMaterial].material = _material;
        Empresas_Pr[_nif].productosOfrecidos[codigoMaterial].costeMaterialIndividual = _costeMaterialIndividual;
        Empresas_Pr[_nif].productosOfrecidos[codigoMaterial].activo = true;
    }


    
    // Funcion que busca dentro de las Empresas registradas como proveedoras
    // Buscara el material solicitado y devolvera un array con las empresas que lo ofrecen con este formato
    // · Nif de la empresa
    // · Nombre del material
    // · Precio del material

    function BuscarMaterial(string memory _material) public view returns(string [] memory) {
        
        bytes32 codigoMaterial = keccak256(abi.encodePacked(_material));

        // Se crean los string dentro de la funcion para que se mezclen si hay mas peticiones        
        string[] memory productos_total_empresas = new string[](empresas_registradas.length) ;
        string memory dato0;
        string memory dato1;
        // string memory dato2;
        string memory dato3;

        // Contamos las empresas que estan registradas y hacemos un for
        for(uint i = 0; i < empresas_registradas.length; i++){

            // Comprobamos si en la empresa actual existe el material que buscamos
            if (Empresas_Pr[empresas_registradas[i]].productosOfrecidos[codigoMaterial].activo){
                
                // Guardamos el nif de la empresa que dispone de ese material
                // Tambien cambiamos el formato de uint a string
                dato1 = Strings.toString(empresas_registradas[i]);

                // Guardamos el nombre del material soliciado
                // dato2 = Empresas_Pr[empresas_registradas[i]].productosOfrecidos[empresas_registradas[i]].material;

                // Guardamos el precio del material solicitado y que ofrece la empresa proveedora
                // Tambien cambiamos el formato de uint a string
                dato3 = Strings.toString(Empresas_Pr[empresas_registradas[i]].productosOfrecidos[codigoMaterial].costeMaterialIndividual);

                // Concatenamos los 3 valores en 1 string
                dato0 = string(abi.encodePacked("Empresa:",dato1," Material:",_material," Precio:",dato3));

                // Agregado la concateneacion en el array
                productos_total_empresas[i] = dato0;
            }
        }
        
        // Devolvemos el resultado del array
        return productos_total_empresas;
    }


}