// SPDX-License-Identifier: MIT
/**
@title AmericanToken
@dev Implementación del estándar de token ERC20 para American Token (UST)
@author Cristhian Gamarra Arbaiza
*/

// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.18;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol

// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.18;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: ChestConfig.sol

pragma solidity ^0.8.18;

/// @title ChestConfig - Configuración basica para la creación de una cofre Hadamanty
/// @author Cristhian Gamarra Arbaiza

/// @title IChestConfig
/// @notice Interfaz para acceder a la configuración de los cofres
interface ICHESTCONFIG {
    /**
     * @dev Devuelve la configuración de un cofre a través de su ID
     * @param _id ID de la configuración del cofre que se va a devolver
     * @return addressTokenContract La dirección del contrato del token de pago
     * @return boxClass La clase del cofre (NORMAL, RARE, EPIC, LEGENDARY, ANCESTRAL o PRIMAL)
     * @return amountBase La cantidad de tokens que se incluirán en el cofre
     * @return priceBase El precio base de venta expresado en el tipo de token de pago
     * @return revenueBase La ganancia base para todos los actores involucrados en la venta del cofre
     */
    function getChestConfiguration(
        uint _id
    )
        external
        view
        returns (
            address addressTokenContract,
            string memory boxClass,
            uint amountBase,
            uint priceBase,
            uint256 revenueBase
        );

    /**
     * @dev Verifica si un token de pago es válido.
     * @param _addressTokenContract La dirección del token de pago a verificar.
     * @return status si el token de pago es válido retorna true, false en caso contrario.
     */
    function isValidPaymentToken(
        address _addressTokenContract
    ) external view returns (bool status);

    /**
     * @dev Retorna los decimales y el símbolo del token de pago válido correspondiente a la dirección del contrato del token.
     * @param _addressTokenContract La dirección del contrato del token.
     * @return decimals Cantidad de decimales del token.
     * @return symbol Símbolo del token.
     */
    function getValidPaymentData(
        address _addressTokenContract
    ) external view returns (uint decimals, string memory symbol);
}

/// * @title ChestConfig
/// * @dev Contrato que almacena y permite gestionar la configuración de los cofres

contract ChestConfig is Ownable, ICHESTCONFIG {
    constructor() {
        addAllowedAddress(msg.sender);
    }

    /**
     * @dev Estructura que almacena los parámetros de configuración de un cofre
     */
    struct ChestConfiguration {
        address addressTokenContract; // Dirección del contrato del token de pago
        string boxClass; // Clase del cofre: NORMAL, RARE, EPIC, LEGENDARY, ANCESTRAL o PRIMAL
        string nameToken; // Nombre del token de pago
        uint amountBase; // Cantidad de token de pago que se pone en el cofre
        uint priceBase; // Precio base de venta expresado en el token de pago
        uint revenueBase; // Ganancia base para todos los actores expresada en el token de pago
        bool status; // Estado de la cofiguracion donde true: available, false: deprecated
    }

    ChestConfiguration[] public chestConfigurations; // Array que almacena las configuraciones de los cofres
    mapping(address => bool) private allowedAddresses; // Mapa de direcciones permitidas para añadir o leer configuraciones de cofres

    struct Token {
        uint256 decimals;
        string symbol;
        bool status;
    }
    mapping(address => Token) public validPaymentTokens;

    /**
     * @dev Estructura que almacena la información de un token de pago válido
     */
    struct ListToken {
        address contractToken;
        uint256 decimals;
        string symbol;
        bool status;
    }
    address[] public validAddressPayments;

    /// @dev Modificador que permite solo a las direcciones permitidas llamar a una función
    modifier onlyAllowedAddresses() {
        require(
            allowedAddresses[msg.sender],
            "Only allowed addresses can call this function"
        );
        _;
    }

    /**
     * @dev Agrega un token de pago al contrato HadamantyAPP.
     * @param _tokenAddress La dirección del contrato del token de pago.
     * @param _decimals El número de decimales del token de pago.
     */
    function addPaymentToken(
        address _tokenAddress,
        string memory _symbol,
        uint _decimals
    ) internal onlyOwner {
        require(
            !validPaymentTokens[_tokenAddress].status,
            "El token de pago ya esta registrado"
        );
        validAddressPayments.push(_tokenAddress);
        validPaymentTokens[_tokenAddress] = Token(_decimals, _symbol, true);
    }

    /**
     * @dev Función para añadir una configuración de cofre al array
     * @param _addressTokenContract Dirección del token a utilizar como pago.
     * @param _boxClass Clase del cofre, puede ser NORMAL, RARE, EPIC, LEGENDARY, ANCESTRAL o PRIMAL.
     * @param _amountBase Cantidad de tokens que se incluirán en el cofre.
     * @param _priceBase Precio base de venta expresado en el tipo de token de pago.
     * @param _decimals Cantidad de decimales del token de pago.
     * @param _revenueBase Ganancia base para todos los actores involucrados en la venta del cofre.
     */
    function addChestConfiguration(
        address _addressTokenContract,
        string memory _boxClass,
        string memory _nameToken,
        uint _amountBase,
        uint _priceBase,
        uint _revenueBase,
        uint _decimals,
        bool _status
    ) public onlyAllowedAddresses {
        /// Comprobaciones de validez de los parámetros
        require(
            _addressTokenContract != address(0),
            "Invalid token contract address"
        );
        require(bytes(_boxClass).length > 0, "boxClass must not be empty");
        require(_amountBase > 0, "Amount must be greater than 0");
        require(_priceBase > 0, "Price must be greater than 0");
        require(_revenueBase > 0, "Revenue must be greater than 0");
        require(
            _revenueBase < _amountBase,
            "Revenue must be less than or equal to amountBase"
        );
        require(
            _amountBase < _priceBase,
            "amountBase must be less than or equal to priceBase"
        );

        /// Añadir la nueva configuración al array
        chestConfigurations.push(
            ChestConfiguration(
                _addressTokenContract,
                _boxClass,
                _nameToken,
                _amountBase,
                _priceBase,
                _revenueBase,
                _status
            )
        );

        if (
            bytes(validPaymentTokens[_addressTokenContract].symbol).length == 0
        ) {
            addPaymentToken(_addressTokenContract, _nameToken, _decimals);
        }
    }

    /**
     * @dev Función para obtener la configuración de un cofre según su ID en el array
     * @param _id ID de la configuración del cofre que se va a devolver.
     * @return addressTokenContract La dirección del contrato de token de pago.
     * @return boxClass La clase del cofre (normal, raro, épico, legendario, ancestral, primigenio).
     * @return amountBase La cantidad de hadamantys que se ponen en el cofre.
     * @return priceBase El precio base de venta, expresado en la moneda del token de pago.
     * @return revenueBase La ganancia base para todos los actores involucrados.
     */
    function getChestConfiguration(
        uint _id
    )
        public
        view
        override
        onlyAllowedAddresses
        returns (
            address addressTokenContract,
            string memory boxClass,
            uint amountBase,
            uint priceBase,
            uint256 revenueBase
        )
    {
        require(
            _id < chestConfigurations.length,
            "Invalid chestConfiguration ID"
        );

        ChestConfiguration memory myChestConfiguration = chestConfigurations[
            _id
        ];

        require(
            myChestConfiguration.status,
            "chestConfiguration ID is deprecated"
        );

        return (
            myChestConfiguration.addressTokenContract,
            myChestConfiguration.boxClass,
            myChestConfiguration.amountBase,
            myChestConfiguration.priceBase,
            myChestConfiguration.revenueBase
        );
    }

    /// * Función que agrega una dirección permitida para llamar a las funciones protegidas del contrato.
    /// * @param allowedAddress Dirección que se agregará a la lista de direcciones permitidas.
    function addAllowedAddress(address allowedAddress) public onlyOwner {
        allowedAddresses[allowedAddress] = true;
    }

    /**
     * @dev Función para verificar si la direccion ingresada tiene permisos para llamar a las funciones protegidas del contrato.
     * @param _address Dirección a verificar en la lista de direcciones permitidas.
     */
    function getAllowedAddresses(address _address) public view returns (bool) {
        return allowedAddresses[_address];
    }

    /// * Función que elimina una dirección permitida para llamar a las funciones protegidas del contrato.
    /// * @param allowedAddress Dirección que se eliminará de la lista de direcciones permitidas.
    function removeAllowedAddress(address allowedAddress) public onlyOwner {
        allowedAddresses[allowedAddress] = false;
    }

    /**
     * @notice Setea un token de pago válido del contrato.
     * @param _tokenAddress La dirección del token de pago que se va a remover.
     * @dev Esta función solo puede ser ejecutada por el propietario del contrato.
     * @dev Una vez estado sea false, el token de pago ya no será considerado válido para realizar transacciones.
     */

    function setPaymentToken(
        address _tokenAddress,
        string memory _symbol,
        uint _decimals,
        bool _status
    ) external onlyOwner {
        validPaymentTokens[_tokenAddress] = Token(_decimals, _symbol, _status);
    }

    /**
     * @dev Verifica si un token de pago es válido.
     * @param _addressTokenContract La dirección del token de pago a verificar.
     * @return status si el token de pago es válido retorna true, false en caso contrario.
     */
    function isValidPaymentToken(
        address _addressTokenContract
    ) public view returns (bool status) {
        status = validPaymentTokens[_addressTokenContract].status;
        return (status);
    }

    /**
     * @dev Retorna los decimales y el símbolo del token de pago válido correspondiente a la dirección del contrato del token.
     * @param _addressTokenContract La dirección del contrato del token.
     * @return decimals_ Cantidad de decimales del token.
     * @return symbol_ Símbolo del token.
     */
    function getValidPaymentData(
        address _addressTokenContract
    ) public view returns (uint decimals_, string memory symbol_) {
        Token storage token = validPaymentTokens[_addressTokenContract];
        require(token.status, "Token dont exist or has not permission");
        decimals_ = token.decimals;
        symbol_ = token.symbol;
        return (decimals_, symbol_);
    }

    /**
     * @notice Obtiene los tokens de pago válidos
     * @dev Esta función solo puede ser ejecutada por las direcciones permitidas
     * @return tokens Array de estructuras ListToken que contiene la información de los tokens de pago válidos
     */
    function getValidPaymentTokens()
        public
        view
        onlyAllowedAddresses
        returns (ListToken[] memory tokens)
    {
        uint count = 0;
        for (uint i = 0; i < validAddressPayments.length; i++) {
            if (validPaymentTokens[validAddressPayments[i]].status) {
                count++;
            }
        }

        tokens = new ListToken[](count);

        uint index = 0;
        for (uint i = 0; i < validAddressPayments.length; i++) {
            address tokenAddress = validAddressPayments[i];
            if (validPaymentTokens[tokenAddress].status) {
                tokens[index] = ListToken(
                    tokenAddress,
                    validPaymentTokens[tokenAddress].decimals,
                    validPaymentTokens[tokenAddress].symbol,
                    validPaymentTokens[tokenAddress].status
                );
                index++;
            }
        }

        return tokens;
    }
}