/**
 *Submitted for verification at polygonscan.com on 2023-04-11
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}
interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);


    function transfer(address recipient, uint256 amount) external returns (bool);


    function allowance(address owner, address spender) external view returns (uint256);


    function approve(address spender, uint256 amount) external returns (bool);


    function transferFrom(
    address sender,
    address recipient,
    uint256 amount
    ) external returns (bool);


    event Transfer(address indexed from, address indexed to, uint256 value);


    event Approval(address indexed owner, address indexed spender, uint256 value);
}
interface IERC20Metadata is IERC20 {

    function name() external view returns (string memory);


    function symbol() external view returns (string memory);


    function decimals() external view returns (uint8);
}

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


    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }


    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }


    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }


    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }


    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

 
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }


    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
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
        }
        _totalSupply -= amount;

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}



abstract contract ERC20Burnable is Context, ERC20 {
  
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

 
    function burnFrom(address account, uint256 amount) public virtual {
        uint256 currentAllowance = allowance(account, _msgSender());
        require(currentAllowance >= amount, "ERC20: burn amount exceeds allowance");
        unchecked {
            _approve(account, _msgSender(), currentAllowance - amount);
        }
        _burn(account, amount);
    }
}
   



abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by 'account'.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by 'account'.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

abstract contract ERC20Pausable is ERC20, Pausable {
    /**
     * @dev See {ERC20-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - the contract must not be paused.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);

        require(!paused(), "ERC20Pausable: token transfer while paused");
    }
}


    

library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

 
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


   

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
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
        _checkRole(role, _msgSender());
        _;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

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


    /**
     * @dev {ERC20} token, including:
     *
     *  - ability for holders to burn (destroy) their tokens
     *  - a minter role that allows for token minting (creation)
     *  - a pauser role that allows to stop all token transfers
     *
     * This contract uses {AccessControl} to lock permissioned functions using the
     * different roles - head to its documentation for details.
     *
     * The account that deploys the contract will be granted the minter and pauser
     * roles, as well as the default admin role, which will let it grant both minter
     * and pauser roles to other accounts.
     *
     * _Deprecated in favor of https://wizard.openzeppelin.com/[Contracts Wizard]._
     */
    contract ERC20PresetMinterPauser is Context, AccessControl, ERC20Burnable, ERC20Pausable {
        bytes32 public constant WITHDRAWER_ROLE = keccak256("WITHDRAWER_ROLE");
        bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
        bytes32 public constant UNPAUSER_ROLE = keccak256("UNPAUSER_ROLE");
        bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
        bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
        bytes32 public constant MINCAPPER_ROLE = keccak256("MINCAPPER_ROLE");
        bytes32 public constant LOSSSETTER_ROLE = keccak256("LOSSSETTER_ROLE");
        bytes32 public constant SUPPLYCAPPER_ROLE = keccak256("SUPPLYCAPPER_ROLE");

        /**
         * @dev Grants 'DEFAULT_ADMIN_ROLE', 'MINTER_ROLE' and 'PAUSER_ROLE' to the
         * account that deploys the contract.
         *
         * See {ERC20-constructor}.
         */
        constructor(string memory name, string memory symbol) ERC20(name, symbol) {
            _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
            _setupRole(MINTER_ROLE, _msgSender());
            _setupRole(PAUSER_ROLE, _msgSender());
            _setupRole(UNPAUSER_ROLE, _msgSender());
            _setupRole(BURNER_ROLE, _msgSender());
            _setupRole(MINCAPPER_ROLE, _msgSender());
            _setupRole(LOSSSETTER_ROLE, _msgSender());
            _setupRole(SUPPLYCAPPER_ROLE, _msgSender());
            _setupRole(WITHDRAWER_ROLE, _msgSender());
        }

        /**
         * @dev Creates 'amount' new tokens for 'to'.
         *
         * See {ERC20-_mint}.
         *
         * Requirements:
         *
         * - the caller must have the 'MINTER_ROLE'.
         */
        function mint(address to, uint256 amount) public virtual {
            require(hasRole(MINTER_ROLE, _msgSender()), "ERC20PresetMinterPauser: must have minter role to mint");
            _mint(to, amount);
        }

        /**
         * @dev Pauses all token transfers.
         *
         * See {ERC20Pausable} and {Pausable-_pause}.
         *
         * Requirements:
         *
         * - the caller must have the 'PAUSER_ROLE'.
         */
        function pause() public virtual {
            require(hasRole(PAUSER_ROLE, _msgSender()), "ERC20PresetMinterPauser: must have pauser role to pause");
            _pause();
        }

        function burn(uint256 amount) public virtual override {
            require(hasRole(BURNER_ROLE, _msgSender()), "ERC20PresetMinterPauser: must have burner role to burn");
            _burn(_msgSender(), amount);
        }
    
     
        function burnFrom(address account, uint256 amount) public virtual override {
            require(hasRole(BURNER_ROLE, _msgSender()), "ERC20PresetMinterPauser: must have burner role to burn");
            uint256 currentAllowance = allowance(account, _msgSender());
            require(currentAllowance >= amount, "ERC20: burn amount exceeds allowance");
            unchecked {
                _approve(account, _msgSender(), currentAllowance - amount);
            }
            _burn(account, amount);
        }

        /**
         * @dev Unpauses all token transfers.
         *
         * See {ERC20Pausable} and {Pausable-_unpause}.
         *
         * Requirements:
         *
         * - the caller must have the 'PAUSER_ROLE'.
         */
        function unpause() public virtual {
            require(hasRole(UNPAUSER_ROLE, _msgSender()), "ERC20PresetMinterPauser: must have unpauser role to unpause");
            _unpause();
        }

        function _beforeTokenTransfer(
            address from,
            address to,
            uint256 amount
        ) internal virtual override(ERC20, ERC20Pausable) {
            super._beforeTokenTransfer(from, to, amount);
        }
    }


contract Token is ERC20PresetMinterPauser, Ownable, ReentrancyGuard {
    uint256 private _tax;

    uint256 private immutable _slope;

    uint256 private _loss_fee_percentage = 1000;

    uint256 private mintCap = 100;
    uint256 private supplyCap = 1000000000;

    event tokensBought(address indexed buyer, uint amount, uint total_supply, uint newPrice);
    event tokensSold(address indexed seller, uint amount, uint total_supply, uint newPrice);
    event withdrawn(address from, address to, uint amount, uint time);

    constructor () ERC20PresetMinterPauser("Purple", "PRP") {
        _slope = 1;
        supplyCap = 100000000000;
    }

    function buy(uint256 _amount) external nonReentrant payable {
        require(totalSupply() + _amount <= supplyCap, "Exceeds supply cap");
        uint price = _calculatePriceForBuy(_amount);
        require(msg.value>=price,"Send Price is low");
        require(_amount <= mintCap , "Value Exceed MintCap");
        _mint(msg.sender, _amount);
        
        (bool sent,) = payable(msg.sender).call{value: msg.value - price}("");
        require(sent, "Failed to send Ether");

        emit tokensBought(msg.sender, _amount, totalSupply(), getCurrentPrice());
    }

    function sell(uint256 _amount) external nonReentrant {
        require(balanceOf(msg.sender) >= _amount,"Not enough tokens");
        uint256 _price = _calculatePriceForSell(_amount);
        uint tax = _calculateLoss(_price);
        _burn(msg.sender, _amount);
        _tax += tax;

        (bool sent,) = payable(msg.sender).call{value: _price - tax}("");
        require(sent, "Failed to send Ether");

        emit tokensSold(msg.sender, _amount, totalSupply(), getCurrentPrice());
    }

    function withdraw() external  nonReentrant {
        require(hasRole(WITHDRAWER_ROLE, _msgSender()), "ERC20PresetMinterPauser: must have withdrawer role to withdraw");
        require(_tax > 0,"Low On Ether");
        uint amount = _tax;
        _tax = 0;
        
        (bool sent,) = payable(msg.sender).call{value: amount}("");
        require(sent, "Failed to send Ether");

        emit withdrawn (address(this), msg.sender, amount, block.timestamp);
    }

    function getCurrentPrice() public view returns (uint) {
        return _calculatePriceForBuy(1);
    }

    function calculatePriceForBuy(
        uint256 _tokensToBuy
    ) external view returns (uint256) {
        return _calculatePriceForBuy(_tokensToBuy);
    }

    function calculatePriceForSell(
        uint256 _tokensToSell
    ) external view returns (uint256) {
        return _calculatePriceForSell(_tokensToSell);
    }

    function _calculatePriceForBuy(
        uint256 _tokensToBuy
    ) private view returns (uint256) {
        uint ts = totalSupply();
        uint tsa = ts + _tokensToBuy;
        return area_under_the_curve(tsa) - area_under_the_curve(ts);
    }

    function _calculatePriceForSell(
        uint256 _tokensToSell
    ) private view returns (uint256) {
        uint ts = totalSupply();
        uint tsa = ts - _tokensToSell;
        return area_under_the_curve(ts) - area_under_the_curve(tsa);
    }

    function area_under_the_curve(uint x) internal view returns (uint256) {
        return (_slope * (x ** 2)) / 2 ;
    }

    function _calculateLoss(uint256 amount) private view returns (uint256) {
        return (amount * _loss_fee_percentage) / (1E4);
    }

    function viewTax() external view  returns (uint256) {
        require(hasRole(WITHDRAWER_ROLE, _msgSender()), "ERC20PresetMinterPauser: must have withdrawer role to view");
        return _tax;
    }

    function setLoss(uint _loss) external  returns (uint256) {
        require(hasRole(LOSSSETTER_ROLE, _msgSender()), "ERC20PresetMinterPauser: must have loss setter role to set loss");
        require(_loss_fee_percentage < 5000, "require loss to be >= 1000 & < 5000");
        _loss_fee_percentage = _loss;
        return _loss_fee_percentage;
    }

    function setMintCap(uint _mintCap) external  returns (uint256) {
        require(hasRole(MINCAPPER_ROLE, _msgSender()), "ERC20PresetMinterPauser: must have mint capper role to set mint cap");
        require(mintCap >= 10, "value should be greater than 10");
        mintCap = _mintCap;
        return mintCap;
    }

    function setSupplyCap(uint _cap) external  returns (uint256) {
        require(hasRole(SUPPLYCAPPER_ROLE, _msgSender()), "ERC20PresetMinterPauser: must have supply capper role to set supply cap");
        require(_cap >= totalSupply(), "value cannot be less than total supply");
        supplyCap = _cap;
        return supplyCap;
    }

    

    function builtwith() external pure returns(string memory){
        return "BuildMyToken_v2.0";
    }
}