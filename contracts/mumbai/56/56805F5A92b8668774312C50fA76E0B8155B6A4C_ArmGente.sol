// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "@openzeppelin/contracts/access/AccessControl.sol";

struct Gente {
  address addr;
  string ipfs;
  string nomalias;
  uint256 plata;
}

struct Comunidad {
  bool activa; 
  string gremio;
  string nomalias;
  string mecenasalias;
  string[] maestros;
  string[] oficiales;
  string[] aprendices;
}

struct Gremio {
  bool activo; 
  string nomalias;
  string mecenasalias;
  string[] maestros;
 }



contract ArmGente is AccessControl {
  using SafeMath for uint256;

  address payable mio;
  
  bytes32 public constant GENESIS_ROLE = keccak256("GENESIS_ROLE");
  bytes32 public constant PAYABLE_ROLE = keccak256("PAYABLE_ROLE");

  string[] public genesis ;

  mapping (address => Gente) public genteByAddr;
  mapping (string  => Gente) public genteByAlias;

  mapping (string => Comunidad ) public comunidades;
  mapping (string => Gremio ) public gremios;
    
  event RegisterEvent( string message , address  sender );
  event CoinsEvent( address indexed  sender , int ammount );
  event ComunidadEvent( string nomalias, string gremioalias, string mecenasalias);
  event GremioEvent( string nomalias , string mecenasalias );

  event PayEvent( address sender , uint256 ammount );
  
  constructor () {
    mio = payable(msg.sender);
    
    address addr = 0x2E1af14F00461830050c31DdAcc180c4E0340427;
                   
    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    grantRole(GENESIS_ROLE, msg.sender);
    addAdmin( addr );
  }

  receive () payable external  {
    emit PayEvent(msg.sender,msg.value);
  }

    function close() public { 
      selfdestruct(mio); 
    }
  // fallback() external payable{}

  modifier onlyAdmins() {
    require(isAdmin(msg.sender), "Restringido a los administradores.");
    _;
  }

  modifier onlyPayables() {
    require(isPayable(msg.sender), "Restringido a los pagables.");
    _;
  }

  modifier onlyGenesis() {
    require(isGenesis(msg.sender), "Restringido a Genesis.");
    _;
  }

  function isAdmin(address account) public virtual view returns (bool){
    return hasRole(DEFAULT_ADMIN_ROLE, account);
  }

  function isPayable(address account) public virtual view returns (bool){
    return hasRole(PAYABLE_ROLE, account);
  }

  function isGenesis(address account) public virtual view returns (bool){
    return  hasRole(GENESIS_ROLE,account);
  }

  function isUser(string memory _nomalias) public virtual view returns (bool){
    return  genteByAlias[_nomalias].addr != address(0);
  }

  function addGenesis(address account) public virtual onlyGenesis {
    grantRole(GENESIS_ROLE, account);
  }
  
  function addAdmin(address account) public virtual onlyAdmins {
    grantRole(DEFAULT_ADMIN_ROLE, account);
  }

  function leaveAdmin() public virtual {
    renounceRole(DEFAULT_ADMIN_ROLE, msg.sender);
  }


  function Gremio_Add( string memory _nomalias, string memory _mecenasalias  ) public onlyAdmins {
    require ( gremios[_nomalias].activo == false  , string(abi.encodePacked("ya existe el gremio" ,_nomalias )) );
    require( isUser(_mecenasalias),  string(abi.encodePacked('GA:Mecenas: ', _mecenasalias ," no es un usuario.")) );

    gremios[_nomalias].activo  = true ;
    gremios[_nomalias].nomalias = _nomalias;
    gremios[_nomalias].mecenasalias = _mecenasalias;

    emit GremioEvent( _nomalias  , _mecenasalias );

    // INFO: Al mecenas se le incorpora como maestro;
    GremioMaestro_Add(_nomalias,_mecenasalias);
  }

  function GremioMaestro_Add( string memory _nomalias, string memory _master  ) public onlyAdmins {
    require( isUser(_master),  string(abi.encodePacked('GMA:Maestro: ', _master ," no es un usuario.")) );
    gremios[_nomalias].maestros.push(_master);
  }


  function Comunidad_Add( string memory _nomalias,  string memory _gremioalias , string memory _mecenasalias  ) public onlyAdmins {
    require ( comunidades[_nomalias].activa == false  , string(abi.encodePacked("ya existe la comunidad" ,_nomalias )) );
    require( isUser(_mecenasalias),  string(abi.encodePacked('CA:Mecenas: ', _mecenasalias ," no es un usuario.")) );

    comunidades[_nomalias].activa  = true ;
    comunidades[_nomalias].nomalias = _nomalias;
    comunidades[_nomalias].mecenasalias = _mecenasalias;

    emit ComunidadEvent( _nomalias , _gremioalias , _mecenasalias);

    // INFO: Al mecenas se le incorpora como maestro;
    ComunidadMaestro_Add(_nomalias,_mecenasalias);
  }

  function ComunidadMaestro_Add( string memory _nomalias, string memory _master  ) public onlyAdmins {
    require( isUser(_master),  string(abi.encodePacked('CMA: Maestro: ' , _master ," no es un usuario.")) );
    comunidades[_nomalias].maestros.push(_master);
  }

  function ComunidadOficial_Add( string memory _nomalias, string memory _oficial  ) public onlyAdmins {
    require( isUser(_oficial),  string(abi.encodePacked('COA: Oficial ',_oficial ," no es un usuario.")) );
    require ( comunidades[_nomalias].activa == true   , string(abi.encodePacked("NO  existe la comunidad" ,_nomalias )) );
    require( indexOf(comunidades[_nomalias].maestros,  genteByAddr[msg.sender].nomalias  ) != -1 , "No eres Maestro para crear");
    comunidades[_nomalias].oficiales.push(_oficial);
  }

  function ComunidadAprendiz_Add( string memory _nomalias, string memory _aprendiz  ) public onlyAdmins {
    require( isUser(_aprendiz),  string(abi.encodePacked('CAA: Aprendiz: ',_aprendiz ," no es un usuario.")) );
    require ( comunidades[_nomalias].activa == true   , string(abi.encodePacked("NO  existe la comunidad" ,_nomalias )) );
    require( indexOf(comunidades[_nomalias].oficiales, genteByAddr[msg.sender].nomalias  ) != -1 , "No eres Oficial para crear");
    comunidades[_nomalias].aprendices.push(_aprendiz);
  }


  function CoinAddByAddr( address  _addr , uint256 _amount  ) public onlyAdmins {
    require(isPayable(_addr), "Restringido a los pagables.");
   //   Gente storage auxGente  = genteAddr[_addr];
    Gente storage auxGente = genteByAddr[_addr];
    auxGente.plata = auxGente.plata.add(_amount);
    emit CoinsEvent(_addr, int256(_amount) );
  }

  function CoinAddByAlias( string memory _nomalias , uint256 _amount   ) public onlyAdmins {
    CoinAddByAddr ( genteByAlias[_nomalias].addr , _amount ); 
  }

  function CoinDelByAddr(  address  _addr  , uint256 _amount ) public onlyAdmins {
    require(isPayable(_addr), "Restringido a los pagables.");
    Gente storage auxGente = genteByAddr[_addr];
    auxGente.plata = auxGente.plata.sub(_amount);
    emit CoinsEvent(_addr, int256(_amount)  * -1 );
  }

  function CoinDelByAlias(string memory _nomalias  , uint256 _amount  ) public onlyAdmins {
    CoinDelByAddr( genteByAlias[_nomalias].addr ,_amount); 
  }


  function register(string memory _nomalias ) public {
    require( genteByAlias[_nomalias].addr == address(0) , 'Alias Duplicado');
    require( genteByAddr[msg.sender].addr == address(0) , 'Pasaporte ya creado');
    Gente memory oGente = Gente( msg.sender , '' , _nomalias , 0  );  
    genteByAddr[msg.sender] = oGente;
    genteByAlias[_nomalias] = oGente;
    genteByAlias[_nomalias].addr = msg.sender;
    _setupRole(PAYABLE_ROLE, msg.sender);
    emit RegisterEvent( _nomalias, msg.sender);
  }

  // INFO: Quitar en produccion 
  function registerByAdmin(string memory _nomalias , address payable _addr , string memory ipfs ) public onlyAdmins {
    require( genteByAlias[_nomalias].addr == address(0) , 'Alias Duplicado');
    require( genteByAddr[_addr].addr == address(0) , 'Pasaporte ya creado');
    Gente memory oGente = Gente( _addr , ipfs , _nomalias , 0  );  
    genteByAddr[_addr] = oGente;
    genteByAlias[_nomalias].addr = _addr;
    _setupRole(PAYABLE_ROLE, _addr);
    _addr.transfer(1000000);
    emit RegisterEvent( _nomalias, _addr );

  }
  



   function ComunidadByAlias(string memory _nomalias) public view returns(Comunidad memory) {
    return comunidades[_nomalias];
  }

  function ComCountByAlias(string memory _nomalias, string memory _ent) public view returns(uint256) {
   uint256 nRet = 0 ;
   if( keccak256(bytes(_ent)) == keccak256(bytes('maestros')) ){
     nRet = comunidades[_nomalias].maestros.length; 
   }
   if( keccak256(bytes(_ent)) == keccak256(bytes('oficiales')) ){
     nRet = comunidades[_nomalias].oficiales.length; 
   }
   if( keccak256(bytes(_ent)) == keccak256(bytes('aprendices')) ){
    nRet = comunidades[_nomalias].aprendices.length; 
   }
   return nRet;
  }


  function indexOf(string[] memory arr, string memory searchFor) private pure returns (int256) {
    for (uint256 i = 0; i < arr.length; i++) {
      if( keccak256(abi.encodePacked(arr[i])) == keccak256(abi.encodePacked(searchFor))){
        return int256(i);
      }
    }
    return -1; // not found
  }


}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

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
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
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
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
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
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
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
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

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
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}