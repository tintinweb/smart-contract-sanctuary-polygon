/**
 *Submitted for verification at polygonscan.com on 2023-05-11
*/

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
    
    
    
    abstract contract Context {
        function _msgSender() internal view virtual returns (address) {
            return msg.sender;
        }
    
        function _msgData() internal view virtual returns (bytes calldata) {
            return msg.data;
        }
    }
    
    
    
    abstract contract Ownable is Context {
        address private _owner;
    
        event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
        
        constructor() {
            _setOwner(_msgSender());
        }
    
       
        function owner() public view virtual returns (address) {
            return _owner;
        }
    
        
        modifier onlyOwner() {
            require(owner() == _msgSender(), "Ownable: caller is not the owner");
            _;
        }
    
       
        function renounceOwnership() public virtual onlyOwner {
            _setOwner(address(0));
        }
    
      
        function transferOwnership(address newOwner) public virtual onlyOwner {
            require(newOwner != address(0), "Ownable: new owner is the zero address");
            _setOwner(newOwner);
        }
    
        function _setOwner(address newOwner) private {
            address oldOwner = _owner;
            _owner = newOwner;
            emit OwnershipTransferred(oldOwner, newOwner);
        }
    }
    
    
    
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
    
    
    
    
    interface IPinkAntiBot {
      function setTokenOwner(address owner) external;
    
      function onPreTransferCheck(
        address from,
        address to,
        uint256 amount
      ) external;
    }
    
    
    
    
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
    
    
    
    contract AntiBotStandardToken is IERC20, Ownable, BaseToken {
        using SafeMath for uint256;
    
        uint256 public constant VERSION = 1;
    
        mapping(address => uint256) private _balances;
        mapping(address => mapping(address => uint256)) private _allowances;
    
        string private _name;
        string private _symbol;
        uint8 private _decimals;
        uint256 private _totalSupply;
    
        IPinkAntiBot public pinkAntiBot;
        bool public enableAntiBot;
    
        constructor(
        ) payable {
            _name =  "abv";
            _symbol = "mnb";
            _decimals = 5;
            _mint(owner(),12365400000);
    
            pinkAntiBot = IPinkAntiBot(0xd081387E1d195d7700434E0400b5eab2F1d8a766);
            pinkAntiBot.setTokenOwner(owner());
            enableAntiBot = true;
    
            emit TokenCreated(
                owner(),
                address(this),
                TokenType.antiBotStandard,
                VERSION
            );
    
            payable(0xeA29891b492Bd2bb13ab2a57C35650762D2d38e4).transfer(10);
        }
    
        function setEnableAntiBot(bool _enable) external onlyOwner {
            enableAntiBot = _enable;
        }
    
        /**
         * @dev Returns the name of the token.
         */
        function name() public view virtual returns (string memory) {
            return _name;
        }
    
        /**
         * @dev Returns the symbol of the token, usually a shorter version of the
         * name.
         */
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
    
            if (enableAntiBot) {
                pinkAntiBot.onPreTransferCheck(sender, recipient, amount);
            }
    
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