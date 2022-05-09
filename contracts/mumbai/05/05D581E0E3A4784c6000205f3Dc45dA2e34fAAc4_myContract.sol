/**
 *Submitted for verification at polygonscan.com on 2022-05-08
*/

// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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
        require(newOwner != address(0), "Ownable: new owner is the zero address");
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

// File: contracts/myContract.sol



pragma solidity ^0.8.6;


contract myContract is Ownable{

    // VARIABLES GLOBALES 

    // Lista
    uint increment;
    struct Box {
        uint id;
        address wallet;
        string description;
    }
    Box[] lists;

    // Calculadora
    uint operation;
    int number1;
    int number2;

    // FUNCIONES INTERNAS

    // Buscar objetos en el array por id
    function findById (uint _id) internal view returns (uint) {
        for (uint i = 0; i < lists.length; i++) {
            if (lists[i].id == _id) {
                return i;
            }
        }
        return 0;
    }

    // Buscar objetos en el array por wallet
    function findByWallet (address _wallet) internal view returns (uint) {
        for (uint i = 0; i < lists.length; i++) {
            if (lists[i].wallet == _wallet) {
                 return i;
            }  
        }
        return 0;
    }

    // Comprobar objetos en el array por wallet
    function checkByWallet (address _wallet) internal view returns (bool) {
        for (uint i = 0; i < lists.length; i++) {
            if (lists[i].wallet == _wallet) {
                 return true;
            }  
        }
        return false;
    }

    // FUNCIONES DE LECTURA (READ)

    // Mostrar un objeto por id
    function showObjectById (uint _id) public view returns (uint, address, string memory) {
        uint index = findById(_id);
        return (lists[index].id, lists[index].wallet, lists[index].description);
    }

    // Mostrar un objeto por wallet
    function showObjectByWallet (address _wallet) public view returns (uint, address, string memory) {
        uint index = findByWallet(_wallet);
        return (lists[index].id, lists[index].wallet, lists[index].description);
    }

    // Comprobar si una wallet esta en el array
    function isWalletInArray (address _wallet) public view returns (bool) {
        bool result = checkByWallet(_wallet);
        return result;
    }

    // Mostrar índice actual del array 
    function indexArray () public view returns (uint) {
        if (increment > 0) {
            uint result = increment - 1;
            return result;
        }
        return 0;
    }

    // Calculadora de numeros negativos y positivos [sumar, restar, multiplicar, dividir]
    function calculator (uint _operation, int _number1, int _number2) public pure returns (int, string memory, int, string memory, int) {
        string memory equal = '=';
        if (_operation == 0) {
            return (_number1, '+', _number2, equal, _number1 + _number2);
        }
        if (_operation == 1) {
           return (_number1, '-', _number2, equal, _number1 - _number2);
        }
        if (_operation == 2) {
            return (_number1, '*', _number2, equal, _number1 * _number2);
        }
        if (_operation == 3) {
            return (_number1, '/', _number2, equal, _number1 / _number2);
        }
        return (0,"",0,"",0);
    }

    // FUNCIONES DE ESCRITURA (WRITE)
  
    // Guardar objetos en el array si no existe wallet
    function createMessage (string memory _description) public {
        bool result = checkByWallet(msg.sender);
        if (result == false) {
            lists.push(Box(increment, msg.sender, _description));
            increment++;
        } else {
            revert("Wallet is already in list");
        }
    }

    // Leer objeto del array si existe wallet y actualizar descripción
    function updateMessage (string memory _description) public {
        bool result = checkByWallet(msg.sender);
        if (result == true) {
            uint index = findByWallet(msg.sender);
            require(msg.sender == lists[index].wallet, "You do not have permissions to perform this action");
            lists[index].description = _description;
        } else {
            revert("Wallet not found in list");
        }
    }

    // Eliminar todos los objetos del array (solo puede ser ejecutado por el dueño del contrato)
    function deleteAllMessages () public onlyOwner {
        for (uint i = 0; i < lists.length; i++) {
            lists.pop();
        }
        increment = 0;
    }

}