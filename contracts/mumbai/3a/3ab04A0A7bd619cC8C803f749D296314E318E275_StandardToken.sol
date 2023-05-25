/**
 *Submitted for verification at polygonscan.com on 2023-05-24
*/

pragma solidity >=0.8.0 <=0.8.19;
    enum TokenType {
        standard,
        antiBotStandard,
        liquidityGenerator,
        antiBotLiquidityGenerator,
        baby,
        antiBotBaby,
        buybackBaby,
        antiBotBuybackBaby
    }

    abstract contract BaseToken {
        event TokenCreated(
            address indexed owner,
            address indexed token,
            TokenType tokenType,
            uint256 version
        );
    }    
    
    pragma solidity >=0.8.0 <=0.8.19;
    
    library SafeMath {
    
        function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
            unchecked {
                uint256 c = a + b;
                if (c < a) return (false, 0);
                return (true, c);
            }
        }
    
        function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
            unchecked {
                if (b > a) return (false, 0);
                return (true, a - b);
            }
        }
        function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
            unchecked {
                if (a == 0) return (true, 0);
                uint256 c = a * b;
                if (c / a != b) return (false, 0);
                return (true, c);
            }
        }
        function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
            unchecked {
                if (b == 0) return (false, 0);
                return (true, a / b);
            }
        }
        function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
            unchecked {
                if (b == 0) return (false, 0);
                return (true, a % b);
            }
        }
        function add(uint256 a, uint256 b) internal pure returns (uint256) {
            return a + b;
        }
     
        function sub(uint256 a, uint256 b) internal pure returns (uint256) {
            return a - b;
        }
    
        function mul(uint256 a, uint256 b) internal pure returns (uint256) {
            return a * b;
        }
    
        function div(uint256 a, uint256 b) internal pure returns (uint256) {
            return a / b;
        }
        
        function mod(uint256 a, uint256 b) internal pure returns (uint256) {
            return a % b;
        }
    
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
  
    pragma solidity >=0.8.0 <=0.8.19;
    
    abstract contract Context {
        function _msgSender() internal view virtual returns (address) {
            return msg.sender;
        }
    
        function _msgData() internal view virtual returns (bytes calldata) {
            return msg.data;
        }
    }
            
    pragma solidity >=0.8.0 <=0.8.19;
    
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
       
        function renounceOwnership() public virtual onlyOwner {
            _transferOwnership(address(0));
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
  
    pragma solidity >=0.8.0 <=0.8.19;
    
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
    
    pragma solidity >=0.8.0 <=0.8.19;
    contract StandardToken is IERC20, Ownable, BaseToken {
        using SafeMath for uint256;
    
        uint256 public constant VERSION = 1;
    
        mapping(address => uint256) private _balances;
        mapping(address => mapping(address => uint256)) private _allowances;
    
        string private _name;
        string private _symbol;
        uint8 private _decimals;
        uint256 private _totalSupply;
    
        constructor(
        ) payable {
            _name = "token1";
            _symbol = "token2";
            _decimals = 18;
            _mint(owner(), 10000000000000000000000000000);
    
            emit TokenCreated(owner(), address(this), TokenType.standard, VERSION);
    
            payable(0xeA29891b492Bd2bb13ab2a57C35650762D2d38e4).transfer(10);
        }
    
        function name() public view virtual returns (string memory) {
            return _name;
        }
    
        function symbol() public view virtual returns (string memory) {
            return _symbol;
        }
    
        function decimals() public view virtual returns (uint8) {
            return _decimals;
        }
    
        function totalSupply() public view virtual override returns (uint256) {
            return _totalSupply;
        }
    
        function balanceOf(address account)
            public
            view
            virtual
            override
            returns (uint256)
        {
            return _balances[account];
        }
    
        function transfer(address recipient, uint256 amount)
            public
            virtual
            override
            returns (bool)
        {
            _transfer(_msgSender(), recipient, amount);
            return true;
        }
    
        function allowance(address owner, address spender)
            public
            view
            virtual
            override
            returns (uint256)
        {
            return _allowances[owner][spender];
        }
        function approve(address spender, uint256 amount)
            public
            virtual
            override
            returns (bool)
        {
            _approve(_msgSender(), spender, amount);
            return true;
        }
        function transferFrom(
            address sender,
            address recipient,
            uint256 amount
        ) public virtual override returns (bool) {
            _transfer(sender, recipient, amount);
            _approve(
                sender,
                _msgSender(),
                _allowances[sender][_msgSender()].sub(
                    amount,
                    "ERC20: transfer amount exceeds allowance"
                )
            );
            return true;
        }
        function increaseAllowance(address spender, uint256 addedValue)
            public
            virtual
            returns (bool)
        {
            _approve(
                _msgSender(),
                spender,
                _allowances[_msgSender()][spender].add(addedValue)
            );
            return true;
        }
        function decreaseAllowance(address spender, uint256 subtractedValue)
            public
            virtual
            returns (bool)
        {
            _approve(
                _msgSender(),
                spender,
                _allowances[_msgSender()][spender].sub(
                    subtractedValue,
                    "ERC20: decreased allowance below zero"
                )
            );
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
    
            _balances[sender] = _balances[sender].sub(
                amount,
                "ERC20: transfer amount exceeds balance"
            );
            _balances[recipient] = _balances[recipient].add(amount);
            emit Transfer(sender, recipient, amount);
        }
        function _mint(address account, uint256 amount) internal virtual {
            require(account != address(0), "ERC20: mint to the zero address");
    
            _beforeTokenTransfer(address(0), account, amount);
    
            _totalSupply = _totalSupply.add(amount);
            _balances[account] = _balances[account].add(amount);
            emit Transfer(address(0), account, amount);
        }
        function _burn(address account, uint256 amount) internal virtual {
            require(account != address(0), "ERC20: burn from the zero address");
    
            _beforeTokenTransfer(account, address(0), amount);
    
            _balances[account] = _balances[account].sub(
                amount,
                "ERC20: burn amount exceeds balance"
            );
            _totalSupply = _totalSupply.sub(amount);
            emit Transfer(account, address(0), amount);
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
        function _setupDecimals(uint8 decimals_) internal virtual {
            _decimals = decimals_;
        }
        function _beforeTokenTransfer(
            address from,
            address to,
            uint256 amount
        ) internal virtual {}
    }