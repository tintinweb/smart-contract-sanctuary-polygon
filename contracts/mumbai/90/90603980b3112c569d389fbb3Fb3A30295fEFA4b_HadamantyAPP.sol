// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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

pragma solidity ^0.8.0;

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

// File: @openzeppelin/contracts/utils/math/SafeMath.sol

// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// File: HadamantyApp.sol

pragma solidity ^0.8.18;

/// @title Contrato HadamantyUSDS
/// @author Cristhian Gamarra Arbaiza

/**
 * @title Interface IHADAMANTYTOKEN
 * @dev Interfaz para el contrato del token HADAMANTY.
 */
interface IHADAMANTYTOKEN {
    /**
     * @dev Función utilizada para crear nuevos tokens HADAMANTY.
     * @param amount El número de tokens a crear.
     * @return bool Indica si la operación fue exitosa o no.
     */
    function mint(address account, uint256 amount) external returns (bool);
}

/**
 * @title Interface IChestConfig
 * @notice Interfaz para acceder a la configuración de los cofres
 */
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

    function isValidPaymentToken(
        address _tokenAddress
    ) external view returns (bool status);

    function getValidPaymentData(
        address _addressTokenContract
    ) external view returns (uint decimals, string memory symbol);
}

/**
 * @title HadamantyAPP
 * @dev Contrato inteligente para la aplicación Hadamanty.
 * @dev Permite la compra y adición de cofres.
 */

contract HadamantyAPP is Ownable {
    IERC20 private RFT;
    IERC20 private TokenPayment;
    IHADAMANTYTOKEN private IhadamantyToken;
    ICHESTCONFIG private IChestConfig;
    address private addressHadamanty;
    address private addressKuantiq;
    address private noOne = address(0);

    /**
     * @dev Evento que se emite cuando se compra un cofre.
     * @param cofreId ID del cofre comprado.
     * @param status Estado del cofre.
     * @param orderType Tipo de orden de compra.
     */
    event CofrePurchased(
        bytes32 indexed cofreId,
        string status,
        bool orderType
    );

    /**
     * @dev Evento que se emite cuando se agrega un nuevo cofre.
     * @param newcofreId Nuevo ID del cofre agregado.
     * @param status Estado del cofre.
     * @param orderType Tipo de orden de compra.
     */
    event CofreAdded(bytes32 indexed newcofreId, string status, bool orderType);

    /**
     * @notice Constructor del contrato.
     * @param _addressHadamantyToken Dirección del token Hadamanty(RFT).
     * @param _addressChestConfig Dirección de la interfaz IChestConfig.
     * @param _addressKuantiq Dirección de la empresa Kuantiq en la red desplegada.
     */
    constructor(
        address _addressHadamantyToken,
        address _addressChestConfig,
        address _addressKuantiq
    ) {
        addressHadamanty = _addressHadamantyToken;
        addressKuantiq = _addressKuantiq;
        RFT = IERC20(addressHadamanty);
        IhadamantyToken = IHADAMANTYTOKEN(_addressHadamantyToken);
        IChestConfig = ICHESTCONFIG(_addressChestConfig);
    }

    struct Cofre {
        uint chestConfigId; //  ID DE LA DESCRIPTION DEL COFRE
        uint timeStamp; //  FECHA Y HORA DE CREACION
        address addressSeller; //  DIRECCION DEL CREADOR DEL PRODUCTO
        address addressBuyer; //  DIRECCION DEL CREADOR DEL PRODUCTO
        address addressTokenPayment; //  DIRECCION DEL TOKEN EN EL QUE SE HARÁ EL PAGO
        uint price; //  PRECIO DE VENTA
        uint revenue; //  CANTIDAD DE GANANCIA PARA CADA PARTE
        uint amountPackage; //  MONTO DE HAMANTYS ENPAQUETADOS
        bool orderType; //  TIPO DE ORDEN: FALSE: SELL , TRUE: BUY
        string status; //  ESTADO DE LA ORDEN: CREATED - PENDING - COMPLETED
    }
    // Almacena la información de cada cofre
    mapping(bytes32 => Cofre) public cofres;
    // Almacena los saldos de los tokens para cada dirección
    mapping(address => mapping(address => uint256)) private balances;
    // Almacena los saldos bloqueados de los tokens para cada dirección
    mapping(address => mapping(address => uint256)) private blockedBalance;

    /**
     * @dev Convierte una cadena de texto en bytes32.
     * @param inputString Cadena de texto de entrada.
     * @return El valor de la cadena de texto convertida en bytes32.
     */
    function convertToBytes32(
        string memory inputString
    ) public pure returns (bytes32) {
        require(
            bytes(inputString).length > 0,
            "Input string must not be empty."
        );
        bytes32 outputBytes32 = bytes32(0);
        assembly {
            outputBytes32 := mload(add(inputString, 32))
        }
        return outputBytes32;
    }

    /**
     * @dev Convierte un valor a la cantidad de decimales adecuada para un token específico.
     * @param _value Valor a convertir.
     * @param _tokenAddress Dirección del token.
     * @return El valor convertido con la cantidad de decimales correcta.
     */

    function _toDecimals(
        uint _value,
        address _tokenAddress
    ) private view returns (uint) {
        bool isValid = IChestConfig.isValidPaymentToken(_tokenAddress);
        require(isValid, "El token de pago no es valido");
        uint _decimals;
        (_decimals, ) = IChestConfig.getValidPaymentData(_tokenAddress);

        return _value * (10 ** _decimals);
    }

    /**
     * @dev Función para depositar tokens RFT en el contrato.
     * @param _amount Cantidad de tokens RFT a depositar.
     * @return bool Indica si la operación de depósito fue exitosa.
     */
    function depositRFT(uint _amount) external returns (bool) {
        bool isValid = IChestConfig.isValidPaymentToken(addressHadamanty);
        require(isValid, "El token de pago no es valido");

        require(
            _amount <= RFT.balanceOf(msg.sender),
            "Insuficient tokens to make transfer"
        );
        require(
            RFT.allowance(msg.sender, address(this)) >= _amount,
            "Insuficient allowance to make transfer"
        );
        bool sent = RFT.transferFrom(msg.sender, address(this), _amount);
        require(sent, "Not sent");
        balances[msg.sender][addressHadamanty] += _amount;
        return (true);
    }

    /**
     * @dev Función para depositar tokens personalizados en el contrato.
     * @param _amount Cantidad de tokens personalizados a depositar.
     * @param _tokenAddress Dirección del token personalizado a depositar.
     * @return bool Indica si la operación de depósito fue exitosa.
     */

    function depositToken(
        uint _amount,
        address _tokenAddress
    ) external returns (bool) {
        bool isValid = IChestConfig.isValidPaymentToken(_tokenAddress);
        require(isValid, "El token de pago no es valido");

        TokenPayment = IERC20(_tokenAddress);
        require(
            _amount <= TokenPayment.balanceOf(msg.sender),
            "Insuficient tokens to make transfer"
        );
        require(
            TokenPayment.allowance(msg.sender, address(this)) >= _amount,
            "Insuficient allowance to make transfer"
        );
        bool sent = TokenPayment.transferFrom(
            msg.sender,
            address(this),
            _amount
        );
        require(sent, "Not sent");
        balances[msg.sender][_tokenAddress] += _amount;
        return (true);
    }

    /**
     * @dev Función interna que realiza el empaquetado de un cofre.
     * @param _newcofreId ID del nuevo cofre generado.
     * @param _chestConfigId ID de la configuración del cofre.
     * @param _orderType Tipo de orden: true para compra, false para venta.
     * @param _addressSeller Dirección del vendedor.
     * @param _addressBuyer Dirección del comprador.
     * @param _status Estado del cofre.
     * @return bool Retorna true si el empaquetado fue exitoso.
     */
    function packing(
        bytes32 _newcofreId,
        uint _chestConfigId,
        bool _orderType,
        address _addressSeller,
        address _addressBuyer,
        string memory _status
    ) private returns (bool) {
        address addressTokenContract;
        uint priceBase;
        uint amountBase;
        uint revenueBase;
        (
            addressTokenContract,
            ,
            amountBase,
            priceBase,
            revenueBase
        ) = IChestConfig.getChestConfiguration(_chestConfigId);
        uint amountPackage = _toDecimals(amountBase, addressTokenContract);
        uint price = _toDecimals(priceBase, addressTokenContract);

        if (_orderType == false) {
            address tokenAddress = addressHadamanty;
            require(
                balances[msg.sender][tokenAddress] >= amountPackage,
                "Balance Insuficiente"
            );
            balances[msg.sender][tokenAddress] -= amountPackage;
            blockedBalance[msg.sender][tokenAddress] += amountPackage;
        } else {
            /// @param = true: buy
            address tokenAddress = addressTokenContract;
            require(
                balances[msg.sender][tokenAddress] >= price,
                "Balance Insuficiente"
            );
            balances[msg.sender][tokenAddress] -= price;
            blockedBalance[msg.sender][tokenAddress] += price;
        }

        Cofre storage myCofre = cofres[_newcofreId];

        myCofre.chestConfigId = _chestConfigId;
        myCofre.timeStamp = block.timestamp;
        myCofre.addressSeller = _addressSeller;
        myCofre.addressBuyer = _addressBuyer;
        myCofre.addressTokenPayment = addressTokenContract;
        myCofre.price = price;
        myCofre.revenue = _toDecimals(revenueBase, addressTokenContract);
        myCofre.amountPackage = _toDecimals(amountBase, addressTokenContract);
        myCofre.orderType = _orderType;
        myCofre.status = _status;

        return true;
    }

    /**
     * @dev Función externa para agregar una orden de cofre.
     * @param _orderType Tipo de orden: true para compra, false para venta.
     * @param newcofreId_ ID del nuevo cofre en formato string.
     * @param _chestConfigId ID de la configuración del cofre.
     * @return bool Retorna true si se agrega la orden de cofre correctamente.
     */

    function addCofreOrder(
        bool _orderType,
        string memory newcofreId_,
        uint _chestConfigId
    ) external returns (bool) {
        bytes32 _newcofreId = convertToBytes32(newcofreId_);
        require(
            _orderType == true || _orderType == false,
            "The @param _orderType must not be empty"
        );
        require(
            _chestConfigId >= 0,
            "The @param ChestConfigurationId must not be empty"
        );
        string memory _status = "created";

        if (_orderType == false) {
            /// @param = false: sell

            address _addressBuyer = noOne;
            address _addressSeller = msg.sender;
            bool send = packing(
                _newcofreId,
                _chestConfigId,
                _orderType,
                _addressSeller,
                _addressBuyer,
                _status
            );
            emit CofreAdded(_newcofreId, _status, _orderType);
            return send;
        } else {
            /// @param = true: buy

            address _addressBuyer = msg.sender;
            address _addressSeller = noOne;
            bool send = packing(
                _newcofreId,
                _chestConfigId,
                _orderType,
                _addressSeller,
                _addressBuyer,
                _status
            );
            emit CofreAdded(_newcofreId, _status, _orderType);
            return send;
        }
    }

    /**
     * @dev Función interna para crear tokens de ingresos y asignarlos a una cuenta.
     * @param account Cuenta a la que se asignarán los tokens de ingresos.
     * @param totalRevenue Cantidad total de tokens de ingresos a crear.
     * @return bool Retorna true si la creación y asignación de tokens de ingresos fue exitosa.
     */
    function mintRevenue(
        address account,
        uint totalRevenue
    ) private returns (bool) {
        bool statusMint = IhadamantyToken.mint(account, totalRevenue);
        require(statusMint, "No se pudo mintear el revenue");
        return true;
    }

    /**
     * @dev Función payload
     * @param tokenAddress Dirección del token
     * @param price Precio del producto
     * @param amount Cantidad del producto
     * @param revenue Ganancia generada
     * @param addressSeller Dirección del vendedor
     * @param addressBuyer Dirección del comprador
     * @return bool Resultado de la operación
     */

    function payload(
        address tokenAddress,
        uint price,
        uint amount,
        uint revenue,
        address addressSeller,
        address addressBuyer
    ) private returns (bool) {
        require(
            addressSeller != noOne,
            "@param addressSeller no puede ser noOne"
        );
        require(
            addressBuyer != noOne,
            "@param addressBuyer no puede ser noOne"
        );
        require(
            blockedBalance[addressBuyer][tokenAddress] >= price,
            "BalanceBlocked buyer Insuficiente"
        );
        require(
            blockedBalance[addressSeller][addressHadamanty] >= amount,
            "BalanceBlocked seller Insuficiente"
        );

        bool result = false;
        uint totalRevenue = revenue * 3;
        //mint a contrato
        result = mintRevenue(address(this), totalRevenue);
        //transferimos a seller
        blockedBalance[addressBuyer][tokenAddress] -= price - revenue;
        balances[addressSeller][tokenAddress] += price - revenue;

        //transferimos a buyer
        blockedBalance[addressSeller][addressHadamanty] -= amount;
        balances[addressBuyer][addressHadamanty] += amount + totalRevenue;

        //transferimos a kuantiq
        balances[addressKuantiq][tokenAddress] += revenue;

        return result;
    }

    /**
     * @dev Realiza el pago de una orden del cofre
     * @param cofreId_ ID del cofre
     * @return bool Resultado de la operación
     */
    function payCofreOrder(string memory cofreId_) external returns (bool) {
        bytes32 _cofreId = convertToBytes32(cofreId_);
        require(cofres[_cofreId].timeStamp > 0, "El cofre no existe.");
        Cofre storage myCofre = cofres[_cofreId];
        address tokenAddress = myCofre.addressTokenPayment;

        if (myCofre.orderType == false && myCofre.addressBuyer == noOne) {
            /// @param = false: sell

            require(
                balances[msg.sender][tokenAddress] >= myCofre.price,
                "Balance sender Insuficiente"
            );
            balances[msg.sender][tokenAddress] -= myCofre.price;
            blockedBalance[msg.sender][tokenAddress] += myCofre.price;
            myCofre.status = "pending";
            myCofre.addressBuyer = msg.sender;
            bool send = payload(
                tokenAddress,
                myCofre.price,
                myCofre.amountPackage,
                myCofre.revenue,
                myCofre.addressSeller,
                myCofre.addressBuyer
            );
            require(send, "Payload internal not procesed");
            myCofre.status = "completed";
            emit CofrePurchased(_cofreId, myCofre.status, myCofre.orderType);
        } else {
            /// @param = true: buy

            require(
                balances[msg.sender][addressHadamanty] >= myCofre.amountPackage,
                "Balance sender Insuficiente"
            );
            balances[msg.sender][addressHadamanty] -= myCofre.amountPackage;
            blockedBalance[msg.sender][addressHadamanty] += myCofre
                .amountPackage;
            myCofre.status = "pending";
            myCofre.addressSeller = msg.sender;
            bool send = payload(
                tokenAddress,
                myCofre.price,
                myCofre.amountPackage,
                myCofre.revenue,
                myCofre.addressSeller,
                myCofre.addressBuyer
            );
            require(send, "Payload internal not procesed");
            myCofre.status = "completed";
            emit CofrePurchased(_cofreId, myCofre.status, myCofre.orderType);
        }

        return true;
    }

    /**
     * @dev Permite a un usuario retirar tokens de tipo Hadamanty de su saldo.
     * @param _amount La cantidad de tokens Hadamanty a retirar.
     * @return flag Indica si la transferencia de tokens fue exitosa.
     */
    function withdrawHadamanty(uint _amount) external returns (bool) {
        require(
            RFT.balanceOf(address(this)) >= _amount,
            "Insuficient tokens to make transfer"
        );
        require(
            balances[msg.sender][addressHadamanty] >= _amount,
            "Balance Insuficiente"
        );
        bool flag = false;
        balances[msg.sender][addressHadamanty] -= _amount;
        RFT.transfer(msg.sender, _amount);
        return flag;
    }

    /**
     * @dev Permite a un usuario retirar tokens de un contrato inteligente utilizando una dirección de token específica.
     * @param _amount La cantidad de tokens a retirar.
     * @param _addressToken La dirección del contrato del token a retirar.
     * @return flag Indica si la transferencia de tokens fue exitosa.
     */
    function withdrawToken(
        uint _amount,
        address _addressToken
    ) external returns (bool) {
        TokenPayment = IERC20(_addressToken);
        require(
            TokenPayment.balanceOf(address(this)) >= _amount,
            "Insuficient tokens to make transfer"
        );
        require(
            balances[msg.sender][_addressToken] >= _amount,
            "Balance Insuficiente"
        );
        bool flag = false;
        balances[msg.sender][_addressToken] -= _amount;
        TokenPayment.transfer(msg.sender, _amount);
        return flag;
    }

    // Función para obtener el saldo de un token específico para una dirección
    function getBalance(address account) public view returns (uint256) {
        return balances[msg.sender][account];
    }

    // Función para obtener el saldo bloqueado de un token específico para una dirección
    function getBlockedBalance(address account) public view returns (uint256) {
        return blockedBalance[msg.sender][account];
    }
}