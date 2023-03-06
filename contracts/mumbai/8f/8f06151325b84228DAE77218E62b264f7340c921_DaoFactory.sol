/**
 *Submitted for verification at polygonscan.com on 2023-03-05
*/

// SPDX-License-Identifier: MIT 
pragma solidity ^0.8.17;


library SignedMath {
    function max(int256 a, int256 b) internal pure returns (int256) {
        return a > b ? a : b;
    }

    function min(int256 a, int256 b) internal pure returns (int256) {
        return a < b ? a : b;
    }

    function average(int256 a, int256 b) internal pure returns (int256) {
        int256 x = (a & b) + ((a ^ b) >> 1);
        return x + (int256(uint256(x) >> 255) & (a ^ b));
    }

    function abs(int256 n) internal pure returns (uint256) {
        unchecked {
            return uint256(n >= 0 ? n : -n);
        }
    }
}

library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
        unchecked {
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            if (prod1 == 0) {
                return prod0 / denominator;
            }

            require(denominator > prod1, "Math: mulDiv overflow");

            uint256 remainder;
            assembly {
                remainder := mulmod(x, y, denominator)

                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            uint256 twos = denominator & (~denominator + 1);
            assembly {
                denominator := div(denominator, twos)

                prod0 := div(prod0, twos)

                twos := add(div(sub(0, twos), twos), 1)
            }

            prod0 |= prod1 * twos;

            uint256 inverse = (3 * denominator) ^ 2;

            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            result = prod0 * inverse;
            return result;
        }
    }

    function mulDiv(uint256 x, uint256 y, uint256 denominator, Rounding rounding) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 result = 1 << (log2(a) >> 1);

        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10 ** 64) {
                value /= 10 ** 64;
                result += 64;
            }
            if (value >= 10 ** 32) {
                value /= 10 ** 32;
                result += 32;
            }
            if (value >= 10 ** 16) {
                value /= 10 ** 16;
                result += 16;
            }
            if (value >= 10 ** 8) {
                value /= 10 ** 8;
                result += 8;
            }
            if (value >= 10 ** 4) {
                value /= 10 ** 4;
                result += 4;
            }
            if (value >= 10 ** 2) {
                value /= 10 ** 2;
                result += 2;
            }
            if (value >= 10 ** 1) {
                result += 1;
            }
        }
        return result;
    }

    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10 ** result < value ? 1 : 0);
        }
    }

    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result << 3) < value ? 1 : 0);
        }
    }
}

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

abstract contract ERC165 is IERC165 {

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    function toString(int256 value) internal pure returns (string memory) {
        return string(abi.encodePacked(value < 0 ? "-" : "", toString(SignedMath.abs(value))));
    }

    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }

    function equal(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(bytes(a)) == keccak256(bytes(b));
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

interface IAccessControl {
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    function hasRole(bytes32 role, address account) external view returns (bool);

    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    function grantRole(bytes32 role, address account) external;

    function revokeRole(bytes32 role, address account) external;

    function renounceRole(bytes32 role, address account) external;
}

abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(account),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

contract DaoTransactions is AccessControl  {
    bytes32 public constant ROLE_ADMIN = keccak256("ROLE_ADMIN");
    bytes32 public constant ROLE_SUBADMIN = keccak256("ROLE_SUBADMIN");
    bytes32 public constant ROLE_MEMBER = keccak256("ROLE_MEMBER");
    mapping (uint256 => TransactionDetails) inTransactions;
    mapping (uint256 => TransactionDetails) outTransactions;
    address public treasuryAddress;

    constructor(address walletAddress) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(ROLE_ADMIN, msg.sender);
        treasuryAddress = walletAddress;
    }

    struct TransactionDetails {
        string name;
        string description;
        string label;
    }

    function updateTransactionsMapping(
        string[] memory names, 
        string[] memory descriptions,
        string[] memory labels,
        uint256[] memory txnsHashes, 
        bool isIn
    ) public onlyRole(ROLE_ADMIN) {
        require(hasRole(ROLE_ADMIN, msg.sender), "Caller must have user role");
        require(names.length == descriptions.length, "Name and Description Length not equal");
        require(labels.length == descriptions.length, "Name and Description Length not equal");
        if (isIn) {
            for (uint8 i = 0; i < txnsHashes.length; i ++) {
                TransactionDetails memory data = TransactionDetails({
                    name: names[i],
                    description: descriptions[i],
                    label:  labels[i]
                });
                inTransactions[txnsHashes[i]] = data;
            }
        } else {
            for (uint8 i = 0; i < txnsHashes.length; i ++) {
                TransactionDetails memory data = TransactionDetails({
                    name: names[i],
                    description: descriptions[i],
                    label:  labels[i]
                });
                inTransactions[txnsHashes[i]] = data;
            }
        }
    }

    function getInTransactions(bool isIn, uint256 txnHash) view public returns (string memory, string memory, string memory) {
        if (isIn) {
            return (inTransactions[txnHash].name, inTransactions[txnHash].description, inTransactions[txnHash].label);
        } else {
            return (outTransactions[txnHash].name, outTransactions[txnHash].description, outTransactions[txnHash].label);
        }
    }

    function grantUserAdminRole(address user) public {
        grantRole(ROLE_ADMIN, user);
    }

    function revokeUserAdminRole(address user) public {
        revokeRole(ROLE_ADMIN, user);
    }
}

contract Dao is AccessControl {
  string public logo_URL;
  string public name;
  string public introduction;
  address public treasuryAddress;
  address public ownerAddress;
  address[] public tokenLists;

  bytes32 public constant ROLE_ADMIN = keccak256("ROLE_ADMIN");
  bytes32 public constant ROLE_SUBADMIN = keccak256("ROLE_SUBADMIN");
  bytes32 public constant ROLE_MEMBER = keccak256("ROLE_MEMBER");

  constructor(
    string memory _logo_URL, 
    string memory _name, 
    string memory _introduction,
    address _treasuryAddress
  ) {
    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _setupRole(ROLE_ADMIN, msg.sender);
    logo_URL = _logo_URL;
    name = _name;
    introduction = _introduction;
    treasuryAddress = _treasuryAddress;
    ownerAddress = msg.sender;
  }

  function getDAOInfo() external view returns (string memory, string memory, string memory, address) {
    return (logo_URL, name, introduction, treasuryAddress);
  }

  function updateDAOLogo(
    string memory _logo_URL
  ) public onlyRole(ROLE_ADMIN) {
    logo_URL = _logo_URL;
  }

  function updateDAOName(
    string memory _name
  ) public onlyRole(ROLE_ADMIN)  {
    name = _name;
  }

  function updateDAOIntroduction(
    string memory _introduction
  ) public onlyRole(ROLE_ADMIN)  {
    introduction = _introduction;
  }

  // function getAdminMembers() public view onlyRole(ROLE_ADMIN) returns (address[] memory){
  //   return getRoleMembers(ROLE_ADMIN);
  // }

  // function getSubAdminMembers() public view onlyRole(ROLE_ADMIN) returns (address[] memory){
  //   return getRoleMembers(ROLE_SUBADMIN);
  // }

  // function getMembers() public view onlyRole(ROLE_ADMIN) returns (address[] memory){
  //   return getRoleMembers(ROLE_MEMBER);
  // }

  function deleteMembers(address userAddress) public onlyRole(ROLE_ADMIN) {
    revokeRole(ROLE_MEMBER, userAddress);
  }

  function deleteSubAdmin(address userAddress) public onlyRole(ROLE_ADMIN) {
    revokeRole(ROLE_SUBADMIN, userAddress);
  }

  function addTokenList(address tokenAddress) public onlyRole(ROLE_ADMIN) {
    bool flag = false;
    for (uint8 i = 0; i < tokenLists.length; i ++) {
      if (tokenLists[i] == tokenAddress) {
        flag = true;
      }
    }
    if (!flag) {
      tokenLists.push(tokenAddress);
    }
  }

  function removeTokenFromList(address tokenAddress) public onlyRole(ROLE_ADMIN) {
    for (uint8 i = 0; i < tokenLists.length; i ++) {
      if (tokenLists[i] == tokenAddress) {
        delete tokenLists[i];
      }
    }
  }
}

contract DaoFactory {
  address public daoOwner;
  mapping(address => address[]) userToDAO;
  mapping(address => address[]) userToDaoTransactions;

  constructor (address _daoOwner) {
    daoOwner = _daoOwner;
  }

  modifier isAdmin(address treasuryAddress) {
    Dao dao = Dao(treasuryAddress);
    require(dao.ownerAddress() == msg.sender); // check the condition before executing the function
    _; // execute remaining code in the fuctions
  }

  function createDAO(
    string memory _logo_URL, 
    string memory _name, 
    string memory _introduction,
    address treasuryAddress
  ) external isAdmin(treasuryAddress) returns (address) {
    Dao newDao = new Dao(_logo_URL, _name, _introduction, treasuryAddress);
    DaoTransactions daoTransactions = new DaoTransactions(treasuryAddress);
    userToDAO[msg.sender].push(address(newDao));
    userToDaoTransactions[msg.sender].push(address(daoTransactions));
    return address(newDao);
  }

  function deleteDAO(
    address treasuryAddress
  ) external isAdmin(treasuryAddress) {
    for (uint i = 0; i < userToDAO[msg.sender].length; i ++) {
      if (userToDAO[msg.sender][i] == treasuryAddress) {
        delete userToDAO[msg.sender][i];
        delete userToDaoTransactions[msg.sender][i];
        break;
      }
    }
  }

  function getUsersDAO() external view returns(address[] memory) {
    return userToDAO[msg.sender];
  }
}