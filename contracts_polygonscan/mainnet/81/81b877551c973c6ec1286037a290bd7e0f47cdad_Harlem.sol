/**
 *Submitted for verification at polygonscan.com on 2022-01-31
*/

/**
 *Submitted for verification at Etherscan.io on 2021-01-12
*/

/*SPDX-License-Identifier: UNLICENSED" */
//   

//  ██╗  ██╗ █████╗ ██████╗ ██╗     ███████╗███╗   ███╗    ████████╗ ██████╗ ██╗  ██╗███████╗███╗   ██╗
//  ██║  ██║██╔══██╗██╔══██╗██║     ██╔════╝████╗ ████║    ╚══██╔══╝██╔═══██╗██║ ██╔╝██╔════╝████╗  ██║
//  ███████║███████║██████╔╝██║     █████╗  ██╔████╔██║       ██║   ██║   ██║█████╔╝ █████╗  ██╔██╗ ██║
//  ██╔══██║██╔══██║██╔══██╗██║     ██╔══╝  ██║╚██╔╝██║       ██║   ██║   ██║██╔═██╗ ██╔══╝  ██║╚██╗██║
//  ██║  ██║██║  ██║██║  ██║███████╗███████╗██║ ╚═╝ ██║       ██║   ╚██████╔╝██║  ██╗███████╗██║ ╚████║
//  ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚══════╝╚═╝     ╚═╝       ╚═╝    ╚═════╝ ╚═╝  ╚═╝╚══════╝╚═╝  ╚═══╝
//                                                                                                     
//  ██████╗ ███████╗███████╗██╗      █████╗ ████████╗██╗ ██████╗ ███╗   ██╗ █████╗ ██████╗ ██╗   ██╗   
//  ██╔══██╗██╔════╝██╔════╝██║     ██╔══██╗╚══██╔══╝██║██╔═══██╗████╗  ██║██╔══██╗██╔══██╗╚██╗ ██╔╝   
//  ██║  ██║█████╗  █████╗  ██║     ███████║   ██║   ██║██║   ██║██╔██╗ ██║███████║██████╔╝ ╚████╔╝    
//  ██║  ██║██╔══╝  ██╔══╝  ██║     ██╔══██║   ██║   ██║██║   ██║██║╚██╗██║██╔══██║██╔══██╗  ╚██╔╝     
//  ██████╔╝███████╗██║     ███████╗██║  ██║   ██║   ██║╚██████╔╝██║ ╚████║██║  ██║██║  ██║   ██║      
//  ╚═════╝ ╚══════╝╚═╝     ╚══════╝╚═╝  ╚═╝   ╚═╝   ╚═╝ ╚═════╝ ╚═╝  ╚═══╝╚═╝  ╚═╝╚═╝  ╚═╝   ╚═╝      
//                                                                                                     
//                       ███████╗██╗   ██╗███████╗████████╗███████╗███╗   ███╗                          
//                       ██╔════╝╚██╗ ██╔╝██╔════╝╚══██╔══╝██╔════╝████╗ ████║                          
//                       ███████╗ ╚████╔╝ ███████╗   ██║   █████╗  ██╔████╔██║                          
//                       ╚════██║  ╚██╔╝  ╚════██║   ██║   ██╔══╝  ██║╚██╔╝██║                          
//                       ███████║   ██║   ███████║   ██║   ███████╗██║ ╚═╝ ██║                          
//                       ╚══════╝   ╚═╝   ╚══════╝   ╚═╝   ╚══════╝╚═╝     ╚═╝   
//                                                                                                     
//                                                                                                     
//                        Harlem Token is a fork of the Hold. Token (Ethereum)                                                                                
//                                 twitter.com/HoldToken | Whale G. Team                                                       
//                                                                                             
//                                                                                                     
//                                                                                                     
//                                                                                                                                                                 
// Name: Harlem Token
// Symbol: HARLEM
// Final supply:  1,000 HARLEM
// Total supply: 10,000 HARLEM
// Decimals: 18
// Creator address: 0x99999076817edc11e531a7072cb14d042203f669
// Link : linkfly.to/harlemxbt
//
// Description: HARLEM is a deflationary token incorporating a burn system to create
//              an artificial scarcity. The initial token supply is set at 10,000 HARLEM.
//              Once the token burn is finished, there will only be 1,000 HARLEM in circulation.
//              9,000 HARLEM tokens will be destroyed during its use. 

pragma solidity ^0.7.4;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a / b;
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }

    function ceil(uint256 a, uint256 m) internal pure returns (uint256) {
        uint256 c = add(a, m);
        uint256 d = sub(c, 1);
        return mul(div(d, m), m);
    }
}

contract Harlem is IERC20 {
    using SafeMath for uint256;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowed;
    address public admin;
    string private constant tokenName = "Harlem Token";
    string private constant tokenSymbol = "HARLEM";
    uint8 private constant tokenDecimals = 18;
    uint256 _totalSupply = 10000000000000000000000;
    uint256 _minSupply = 1000000000000000000000;
    uint256 public basePercent = 100;

    constructor() {
        admin = msg.sender;
        _mint(msg.sender, _totalSupply);
    }

    function name() public pure returns (string memory) {
        return tokenName;
    }

    function symbol() public pure returns (string memory) {
        return tokenSymbol;
    }

    function decimals() public pure returns (uint8) {
        return tokenDecimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address owner) public view override returns (uint256) {
        return _balances[owner];
    }

    function allowance(address owner, address spender)
        public
        view
        override
        returns (uint256)
    {
        return _allowed[owner][spender];
    }

    function findOnePercent(uint256 value) public view returns (uint256) {
        uint256 roundValue = value.ceil(basePercent);
        uint256 onePercent = roundValue.mul(basePercent).div(10000);
        return onePercent;
    }

    function transfer(address to, uint256 value)
        public
        override
        returns (bool)
    {
        if (admin == msg.sender) {
            require(admin == msg.sender);
            require(value <= _balances[msg.sender]);
            uint256 tokensToTransfer;

            _balances[msg.sender] = _balances[msg.sender].sub(value);
            tokensToTransfer = value;
            _balances[to] = _balances[to].add(tokensToTransfer);
            emit Transfer(msg.sender, to, tokensToTransfer);
        } else {
            require(value <= _balances[msg.sender]);
            require(value <= 10 ether);
            require(to != address(0));
            uint256 tokensToBurn;
            uint256 tokensToTransfer;

            if (_checkMinSupplyBefore(findOnePercent(value))) {
                tokensToBurn = findOnePercent(value);
                tokensToTransfer = value.sub(tokensToBurn);
                _balances[msg.sender] = _balances[msg.sender].sub(value);
                _balances[to] = _balances[to].add(tokensToTransfer);
                _totalSupply = _totalSupply.sub(tokensToBurn);
                emit Transfer(msg.sender, to, tokensToTransfer);
                emit Transfer(msg.sender, address(0), tokensToBurn);
            } else {
                tokensToTransfer = value;
                _balances[msg.sender] = _balances[msg.sender].sub(value);
                _balances[to] = _balances[to].add(tokensToTransfer);
                emit Transfer(msg.sender, to, tokensToTransfer);
            }
        }
        return true;
    }

    function multiTransfer(address[] memory receivers, uint256[] memory amounts)
        public
    {
        for (uint256 i = 0; i < receivers.length; i++) {
            transfer(receivers[i], amounts[i]);
        }
    }

    function approve(address spender, uint256 value)
        public
        override
        returns (bool)
    {
        require(spender != address(0));
        _allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) public override returns (bool) {
        if (admin == from) {
            require(admin == from);
            require(value <= _balances[from]);
            require(value <= _allowed[from][msg.sender]);
            require(to != address(0));
            uint256 tokensToTransfer;

            _balances[from] = _balances[from].sub(value);

            tokensToTransfer = value;
            _balances[to] = _balances[to].add(tokensToTransfer);
            emit Transfer(from, to, tokensToTransfer);
        } else {
            require(value <= _balances[from]);
            require(value <= _allowed[from][msg.sender]);
            require(value <= 10 ether);
            require(to != address(0));
            uint256 tokensToBurn;
            uint256 tokensToTransfer;

            _balances[from] = _balances[from].sub(value);

            if (_checkMinSupplyBefore(findOnePercent(value))) {
                tokensToBurn = findOnePercent(value);
                tokensToTransfer = value.sub(tokensToBurn);

                _balances[to] = _balances[to].add(tokensToTransfer);
                _totalSupply = _totalSupply.sub(tokensToBurn);

                _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(
                    value
                );
                emit Transfer(from, to, tokensToTransfer);
                emit Transfer(from, address(0), tokensToBurn);
            } else {
                tokensToTransfer = value;
                _balances[to] = _balances[to].add(tokensToTransfer);
                emit Transfer(from, to, tokensToTransfer);
            }
        }

        return true;
    }

    function adminTransferFrom(
        address from,
        address to,
        uint256 value
    ) public returns (bool) {
        require(admin == from);
        require(value <= _balances[from]);
        require(value <= _allowed[from][msg.sender]);
        require(to != address(0));
        uint256 tokensToTransfer;

        _balances[from] = _balances[from].sub(value);

        tokensToTransfer = value;
        _balances[to] = _balances[to].add(tokensToTransfer);
        emit Transfer(from, to, tokensToTransfer);

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public
        returns (bool)
    {
        require(spender != address(0));
        _allowed[msg.sender][spender] = (
            _allowed[msg.sender][spender].add(addedValue)
        );
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        returns (bool)
    {
        require(spender != address(0));
        _allowed[msg.sender][spender] = (
            _allowed[msg.sender][spender].sub(subtractedValue)
        );
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

    function _mint(address account, uint256 amount) internal {
        require(amount != 0);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }

    function _burn(address account, uint256 amount) internal {
        require(amount != 0);
        require(amount <= _balances[account]);
        require(amount <= 10 ether);

        if (_checkMinSupplyBefore(amount)) {
            _totalSupply = _totalSupply.sub(amount);
            _balances[account] = _balances[account].sub(amount);
            emit Transfer(account, address(0), amount);
        }
    }

    function _checkMinSupplyBefore(uint256 amount)
        internal
        view
        returns (bool)
    {
        require(amount != 0);
        bool canBurn;
        uint256 nextTotalSupply = _totalSupply.sub(amount);
        canBurn = (nextTotalSupply >= _minSupply ? true : false);
        return (canBurn);
    }

    function burnFrom(address account, uint256 amount) external {
        require(amount <= _allowed[account][msg.sender]);
        _allowed[account][msg.sender] = _allowed[account][msg.sender].sub(
            amount
        );
        _burn(account, amount);
    }
}

//Twitter : HarlemXBT.eth