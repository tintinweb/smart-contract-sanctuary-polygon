/**
 *Submitted for verification at polygonscan.com on 2023-06-08
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)
// pragma solidity ^0.8.0;
 
abstract contract ReentrancyGuard { 
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }
 
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private { 
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
 
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private { 
        _status = _NOT_ENTERED;
    }
}

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)
// pragma solidity ^0.8.0;
 
interface IERC165 { 
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// File: @openzeppelin/contracts/utils/introspection/ERC165.sol
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)
// pragma solidity ^0.8.0;
 
abstract contract ERC165 is IERC165 { 
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// File: @openzeppelin/contracts/utils/math/SignedMath.sol
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/SignedMath.sol)
// pragma solidity ^0.8.0;
 
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

// File: @openzeppelin/contracts/utils/math/Math.sol
// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/Math.sol)
// pragma solidity ^0.8.0;
 
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
        return (a & b) + (a ^ b) / 2;
    }
 
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) { 
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

// File: @openzeppelin/contracts/utils/Strings.sol
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Strings.sol)
// pragma solidity ^0.8.0;
 
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;
 
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
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

// File: @openzeppelin/contracts/access/IAccessControl.sol
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)
// pragma solidity ^0.8.0;
 
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

// File: @openzeppelin/contracts/utils/Context.sol
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)
// pragma solidity ^0.8.0;
 
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/AccessControl.sol
// OpenZeppelin Contracts (last updated v4.9.0) (access/AccessControl.sol)
// pragma solidity ^0.8.0;
 
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

// File: @openzeppelin/contracts/security/Pausable.sol
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)
// pragma solidity ^0.8.0;

abstract contract Pausable is Context { 
    event Paused(address account);
 
    event Unpaused(address account);

    bool private _paused;
 
    constructor() {
        _paused = false;
    }
 
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }
 
    modifier whenPaused() {
        _requirePaused();
        _;
    }
 
    function paused() public view virtual returns (bool) {
        return _paused;
    }
 
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }
 
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }
 
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }
 
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)
// pragma solidity ^0.8.0;

interface IERC20 { 
    event Transfer(address indexed from, address indexed to, uint256 value);
 
    event Approval(address indexed owner, address indexed spender, uint256 value);
 
    function totalSupply() external view returns (uint256);
 
    function balanceOf(address account) external view returns (uint256);
 
    function transfer(address to, uint256 amount) external returns (bool);
 
    function allowance(address owner, address spender) external view returns (uint256);
 
    function approve(address spender, uint256 amount) external returns (bool);
 
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// File: @openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)
// pragma solidity ^0.8.0;

interface IERC20Metadata is IERC20 { 
    function name() external view returns (string memory);
 
    function symbol() external view returns (string memory);
 
    function decimals() external view returns (uint8);
}

// File: @openzeppelin/contracts/token/ERC20/ERC20.sol
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)
// pragma solidity ^0.8.0;
 
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }
 
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }
 
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }
 
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }
 
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }
  
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }
 
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }
 
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }
 
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }
 
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }
 
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }
 
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount; 
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }
 
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked { 
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }
 
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount; 
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }
 
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
 
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }
 
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
 
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// File: contracts/erc20-tax-addlp.sol
// pragma solidity ^0.8.9;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}
 
interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}
 
interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}
 
contract MyToken is ERC20, Pausable, AccessControl {
    IUniswapV2Router02 public zUniswapV2Router;
    address public zUniswapV2Pair;
    
    bytes32 private constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 private constant SETTER_ROLE = keccak256("SETTER_ROLE");

    uint256 private constant yMaxSupply = 10_000_000 * 10**18;
    uint256 public constant yMaxTokenWallet = yMaxSupply * 5 / 1000;
    uint256 private constant ySupLiquidity = yMaxSupply * 93 / 100;
    uint256 private constant ySupListings = yMaxSupply - ySupLiquidity; 
    uint256 public zStaStage;

    uint256 public zForLiquidity;
    uint256 public zForLiquidityTreshold = 1000 * 10**18;
    uint256 public zTotalBurnAmount;
    uint256 public zTotalLiquidityAmount;

    bool public yFlaTaxLiquidity;
    bool public yFlaTaxBurn;
    bool public yFlaSwap;
    bool public yFlaMaxTokenWallet;

    uint256 public yBuyTaxAutoBurn = 1; 
    uint256 public yBuyTaxToLiquidityWallet = 2; 
    uint256 public ySellTaxAutoBurn = 2; 
    uint256 public ySellTaxToLiquidityWallet = 3;  

    address public yWalLiquidity;
    address public yWalListing;

    mapping(address => bool) public yWhitelistedAddresses;
    mapping(address => bool) public yBlocklistedAddresses;
    mapping(address => bool) public yTaxExemptedAddresses;

    mapping(address => uint256) private _lastTransfer;
    uint256 public constant cooldownTime = 30 minutes;
    
    string public xLogMe;
    string public xLogA;
    string public xLogB;
    string public xLogC;
    string public xLogD;
    string public xLogE;
 
    bool private zIsLiquidity;
    modifier mLockTheSwap {
        zIsLiquidity = true;
        _;
        zIsLiquidity = false;
    }

    constructor() ERC20("DDDD", "DD") { 
        IUniswapV2Router02 _router = IUniswapV2Router02(0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506);
        zUniswapV2Router = _router;
        zUniswapV2Pair = IUniswapV2Factory(_router.factory()).createPair(address(this), _router.WETH());

        yWalLiquidity = 0x1Ceba3405D0e453A38F37a0a830ada3Cb6702909; 
        yWalListing = 0xeC0637b1D865cd4723aFA613e77F444D7281cae6;

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(SETTER_ROLE, msg.sender);
        
        yTaxExemptedAddresses[msg.sender] = true;
        yTaxExemptedAddresses[address(this)] = true;
        yTaxExemptedAddresses[address(zUniswapV2Router)] = true;
        yTaxExemptedAddresses[zUniswapV2Pair] = true;
        yTaxExemptedAddresses[yWalLiquidity] = true;
        yTaxExemptedAddresses[yWalListing] = true;

        yWhitelistedAddresses[msg.sender] = true;
        yWhitelistedAddresses[address(this)] = true;
        yWhitelistedAddresses[address(zUniswapV2Router)] = true;
        yWhitelistedAddresses[zUniswapV2Pair] = true; 
        
        _grantRole(PAUSER_ROLE, yWalLiquidity);
        _grantRole(SETTER_ROLE, yWalLiquidity);

        _mint(msg.sender, ySupLiquidity);
        _mint(yWalListing, ySupListings);

        yFlaTaxLiquidity = false;
        yFlaTaxBurn = false;
        yFlaSwap = false;
        yFlaMaxTokenWallet = true;
        yBuyTaxAutoBurn = 2;
        yBuyTaxToLiquidityWallet = 8;
        ySellTaxAutoBurn = 2;
        ySellTaxToLiquidityWallet = 8;
        zStaStage = 0; 
    }

    function _transfer(address sender, address recipient, uint256 amount) internal override whenNotPaused {
        require(!yBlocklistedAddresses[sender], "Sender is blocklisted");
        require(!yBlocklistedAddresses[recipient], "Recipient is blocklisted");

        uint256 taxAutoBurn = 0;
        uint256 TaxToLiquidityWallet = 0;
        uint256 forTransfer = 0;

        bool isSwap = yFlaSwap;
        bool isBuy = false;
        bool isSell = false; 

        if (zStaStage <= 1) {
            xLogE = "zStaStage <= 1";
            isSwap = false;
            xLogD= "yWhitelistedAddresses false";
            if (yWhitelistedAddresses[sender] && yWhitelistedAddresses[recipient]) {
                isSwap = true;
                xLogD = "yWhitelistedAddresses true";
            } 
        } else {
            xLogE = "zStaStage > 1";
        }
        xLogMe = concatenate(sender,recipient,"Normal","",amount,0);
        if (sender == zUniswapV2Pair) { 
            isBuy = true;
            require(isSwap, "Swap is off");
            // require(
            //     block.timestamp >= _lastTransfer[recipient] + cooldownTime || _lastTransfer[recipient] == 0, "Transfer not allowed before cooldown"
            // );
            // _lastTransfer[recipient] = block.timestamp;
            taxAutoBurn = amount * yBuyTaxAutoBurn / 100;
            TaxToLiquidityWallet = amount * yBuyTaxToLiquidityWallet / 100;
            xLogMe = concatenate(sender,recipient,"Buy","",amount,1);
        } else if (recipient == zUniswapV2Pair) { 
            isSell = true;
            require(isSwap, "Swap is off"); 
            taxAutoBurn = amount * ySellTaxAutoBurn / 100;
            TaxToLiquidityWallet = amount * ySellTaxToLiquidityWallet / 100;
            xLogMe = concatenate(sender,recipient,"Sell","",amount,2); 
        } 
        // if (isBuy) { 
        //     taxAutoBurn = amount * yBuyTaxAutoBurn / 100;
        //     TaxToLiquidityWallet = amount * yBuyTaxToLiquidityWallet / 100;
        //     xLogMe = concatenate(sender,recipient,"Buy","",amount,1);
        // } else if (isSell) { 
        //     taxAutoBurn = amount * ySellTaxAutoBurn / 100;
        //     TaxToLiquidityWallet = amount * ySellTaxToLiquidityWallet / 100;
        //     xLogMe = concatenate(sender,recipient,"Sell","",amount,2);
        // }
        if (yTaxExemptedAddresses[sender] && yTaxExemptedAddresses[recipient]) {
            taxAutoBurn = 0;
            TaxToLiquidityWallet = 0;
            xLogMe = concatenate(sender,recipient,"yTaxExemptedAddresses","",amount,0);
        }
        if (taxAutoBurn > 0) {
            _burn(sender, taxAutoBurn);
            zTotalBurnAmount += taxAutoBurn;
            xLogA = "taxAutoBurn";
        }
        if (TaxToLiquidityWallet > 0) {
            super._transfer(sender, address(this), TaxToLiquidityWallet); 
            xLogB = "TaxToLiquidityWallet";
            zTotalLiquidityAmount += TaxToLiquidityWallet;
            zForLiquidity += TaxToLiquidityWallet;
        }
        forTransfer = amount - taxAutoBurn - TaxToLiquidityWallet;
        xLogC = "recipient";
        super._transfer(sender, recipient, forTransfer);
    }


  




    
    /* addLiquidityManually */
    function addLiquidity() external onlyRole(SETTER_ROLE) mLockTheSwap { 
        if (zForLiquidity >= zForLiquidityTreshold) { 
            uint256 half = zForLiquidity / 2;
            uint256 otherHalf = zForLiquidity - half;

            uint256 initialBalance = address(this).balance; 
    
            swapTokensForEth2(otherHalf);

            uint256 newBalance = address(this).balance - initialBalance; 
    
            addLiquidity2(half, newBalance);            
            zForLiquidity -= (half + otherHalf);

            // emit SwapAndLiquify2(otherHalf, newBalance);
        } 
    } 
    function swapTokensForEth2(uint256 tokenAmount) private { 
        address[] memory path = new address[](2);
        path[0] = address(this); 
        path[1] = zUniswapV2Router.WETH(); 
        _approve(address(this), address(zUniswapV2Router), tokenAmount);  
        zUniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, 
            path,
            address(this), 
            block.timestamp
        ); 
    } 
    function addLiquidity2(uint256 tokenAmount, uint256 ethAmount) private { 
        _approve(address(this), address(zUniswapV2Router), tokenAmount);   
        zUniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this), 
            tokenAmount,
            0, 
            0,  
            address(0),
            block.timestamp
        ); 
    }




    function zGetTokenBalance(address account) public view returns (uint256) {
        return balanceOf(account);
    }

    function zGetEthBalance(address account) public view returns (uint256) {
        return account.balance;
    } 

    // this is the only option to set tax deductions
    function zSetIndex(uint256 _index) external onlyRole(SETTER_ROLE) {
        if (_index == 1) {
            yFlaTaxLiquidity = false;
            yFlaTaxBurn = false;
            yFlaSwap = false;
            yFlaMaxTokenWallet = true;
            yBuyTaxAutoBurn = 2;
            yBuyTaxToLiquidityWallet = 8;
            ySellTaxAutoBurn = 2;
            ySellTaxToLiquidityWallet = 8;
            zStaStage = 1;
        } else if (_index == 2) {
            yFlaTaxLiquidity = true;
            yFlaTaxBurn = true;
            yFlaSwap = true;
            yFlaMaxTokenWallet = true;
            yBuyTaxAutoBurn = 2;
            yBuyTaxToLiquidityWallet = 8;
            ySellTaxAutoBurn = 2;
            ySellTaxToLiquidityWallet = 8;
            zStaStage = 2;
        } else if (_index == 3) {
            yFlaTaxLiquidity = true;
            yFlaTaxBurn = true;
            yFlaSwap = true;
            yFlaMaxTokenWallet = false;
            yBuyTaxAutoBurn = 2;
            yBuyTaxToLiquidityWallet = 8;
            ySellTaxAutoBurn = 2;
            ySellTaxToLiquidityWallet = 8;
            zStaStage = 3;
        }
    }

    function zSetWhitelistedAddress(address _address, bool _whitelisted) external onlyRole(SETTER_ROLE) {
        yWhitelistedAddresses[_address] = _whitelisted;
    }
    function zSetBlocklistedAddress(address _address, bool _blocklisted) external onlyRole(SETTER_ROLE) { 
        yBlocklistedAddresses[_address] = _blocklisted; 
    }
    function zSetyWalLiquidity(address _yWalLiquidity) external onlyRole(SETTER_ROLE) {
        yWalLiquidity = _yWalLiquidity;
    }
 
    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }
    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }
 
    function concatenate(
        address addr1,
        address addr2,
        string memory str1,
        string memory str2,
        uint256 num1,
        uint256 num2
    ) public pure returns (string memory) {
        return
        string(
            abi.encodePacked(
                "Address 1: ",
                toString(addr1),
                ", Address 2: ",
                toString(addr2),
                ", String 1: ",
                str1,
                ", String 2: ",
                str2,
                ", Number 1: ",
                toString(num1),
                ", Number 2: ",
                toString(num2)
            )
        );
    }

    function toString(address _addr) internal pure returns (string memory) {
        bytes32 value = bytes32(uint256(uint160(_addr)));
        bytes memory alphabet = "0123456789abcdef";
        bytes memory str = new bytes(42);
        str[0] = "0";
        str[1] = "x";
        for (uint256 i = 0; i < 20; i++) {
            str[2 + i * 2] = alphabet[uint8(value[i + 12] >> 4)];
            str[3 + i * 2] = alphabet[uint8(value[i + 12] & 0x0f)];
        }
        return string(str);
    }

    function toString(uint256 value) internal pure returns (string memory) {
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

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        whenNotPaused
        override
    {
        super._beforeTokenTransfer(from, to, amount);
    }

    receive() external payable {}
    
}