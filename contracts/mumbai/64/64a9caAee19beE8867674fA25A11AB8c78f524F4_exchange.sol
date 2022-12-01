/**
 *Submitted for verification at polygonscan.com on 2022-12-01
*/

/**
 *Submitted for verification at Etherscan.io on 2022-02-21
 */

// File: contracts/lib/SafeMath.sol

/*

    Copyright 2020 DODO ZOO.
    SPDX-License-Identifier: Apache-2.0

*
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
/**
 * @title SafeMath
 * @author DODO Breeder
 *
 * @notice Math operations with safety checks that revert on error
 */
//代码通用于5点几到6点几版本

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "MUL_ERROR");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "DIVIDING_ERROR");
        return a / b;
    }

    function divCeil(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 quotient = div(a, b);
        uint256 remainder = a - quotient * b;
        if (remainder > 0) {
            return quotient + 1;
        } else {
            return quotient;
        }
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SUB_ERROR");
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "ADD_ERROR");
        return c;
    }

    function sqrt(uint256 x) internal pure returns (uint256 y) {
        uint256 z = x / 2 + 1;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }
}


// File: contracts/lib/InitializableOwnable.sol

/**
 * @title Ownable
 * @author DODO Breeder
 *
 * @notice Ownership related functions
 */
contract InitializableOwnable {
    address public _OWNER_;
    address public _NEW_OWNER_;
    bool internal _INITIALIZED_;

    // ============ Events ============

    event OwnershipTransferPrepared(
        address indexed previousOwner,
        address indexed newOwner
    );

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    // ============ Modifiers ============

    modifier notInitialized() {
        require(!_INITIALIZED_, "DODO_INITIALIZED");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == _OWNER_, "NOT_OWNER");
        _;
    }

    // ============ Functions ============

    function initOwner(address newOwner) internal notInitialized {
        _INITIALIZED_ = true;
        _OWNER_ = newOwner;
    }
}

contract exchange is InitializableOwnable {
    using SafeMath for uint256;

    string public name; //代币名称
    uint8 public decimals; //代币精度
    string public symbol; //代币付号
    uint256 public totalSupply; //代币总量

    uint256 public tradeBurnRatio; //交易销毁比例
    uint256 public tradeFeeRatio; //交易手续费比例
    address public team; //手续费收取地址

    uint256 public tokenPrice; //换币价格

    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) internal allowed;

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 amount
    );
    event Mint(address indexed user, uint256 value);
    event Burn(address indexed user, uint256 value);

    event ChangeTeam(address oldTeam, address newTeam);

    function init(
        address _creator, //创建地址
        uint256 _initSupply, //初始总量
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint256 _tradeBurnRatio,
        uint256 _tradeFeeRatio,
        address _team
    ) public {
        initOwner(_creator);
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply = _initSupply;
        balances[_creator] = _initSupply;
        require(
            _tradeBurnRatio >= 0 && _tradeBurnRatio <= 5000,
            "TRADE_BURN_RATIO_INVALID"
        );
        require(
            _tradeFeeRatio >= 0 && _tradeFeeRatio <= 5000,
            "TRADE_FEE_RATIO_INVALID"
        );
        tradeBurnRatio = _tradeBurnRatio;
        tradeFeeRatio = _tradeFeeRatio;
        team = _team;
        emit Transfer(address(0), _creator, _initSupply);
    }

    function transfer(address to, uint256 amount) public returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }

    function balanceOf(address owner) public view returns (uint256 balance) {
        return balances[owner];
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public returns (bool) {
        require(amount <= allowed[from][msg.sender], "ALLOWANCE_NOT_ENOUGH");
        _transfer(from, to, amount);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(amount);
        return true;
    }

    //spender合约地址 amount授权金额
    function approve(address spender, uint256 amount) public returns (bool) {
        allowed[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    //spender合约地址
    function allowance(address owner, address spender)
        public
        view
        returns (uint256)
    {
        return allowed[owner][spender];
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(
            balances[sender] >= amount,
            "ERC20: transfer amount exceeds balance"
        );

        balances[sender] = balances[sender].sub(amount);

        uint256 burnAmount;
        uint256 feeAmount;
        if (tradeBurnRatio > 0) {
            burnAmount = amount.mul(tradeBurnRatio).div(10000);
            balances[address(0)] = balances[address(0)].add(burnAmount);
            emit Transfer(sender, address(0), burnAmount);
        }

        if (tradeFeeRatio > 0) {
            feeAmount = amount.mul(tradeFeeRatio).div(10000);
            balances[team] = balances[team].add(feeAmount);
            emit Transfer(sender, team, feeAmount);
        }

        uint256 receiveAmount = amount.sub(burnAmount).sub(feeAmount);
        balances[recipient] = balances[recipient].add(receiveAmount);

        emit Transfer(sender, recipient, receiveAmount);
    }

    //销毁
    function burn(uint256 value) external {
        require(balances[msg.sender] >= value, "VALUE_NOT_ENOUGH");
        balances[msg.sender] = balances[msg.sender].sub(value);
        totalSupply = totalSupply.sub(value);
        emit Burn(msg.sender, value);
        emit Transfer(msg.sender, address(0), value);
    }

    //=================== Ownable ======================
    //增发
    function mint(address user, uint256 value) external onlyOwner {
        require(user == _OWNER_, "NOT_OWNER");
        balances[user] = balances[user].add(value);
        totalSupply = totalSupply.add(value);
        emit Mint(user, value);
        emit Transfer(address(0), user, value);
    }

    // // 向合约账户转账
    // function transderToContract() public payable {
    //     payable(address(this)).transfer(msg.value);
    // }

    // 获取合约账户余额
    function getBalanceOfContract() public view returns (uint256) {
        return address(this).balance;
    }

    fallback() external payable {}

    receive() external payable {}

    function setPrices(uint256 newtoknePrice) external onlyOwner {
        require(msg.sender == _OWNER_, "NOT_OWNER");
        tokenPrice = newtoknePrice;
    }

    address private _usdtAddr =
        address(0xfE366e89F2ae34fA3003D9E942436D62105bDF7f);


    function safeApprove(
        address to,
        uint256 value
    ) public {
        bytes4(keccak256(bytes("approve(address,uint256)")));
        (bool success, bytes memory data) = _usdtAddr.call(
            abi.encodeWithSelector(0x095ea7b3, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper: APPROVE_FAILED"
        );
    }

    function buyFund(uint256 amount) public returns (bool) {
        balances[msg.sender] = balances[msg.sender].add(amount);
        totalSupply = totalSupply.add(amount);
        bytes4(keccak256(bytes("transferFrom(address,address,uint256)")));
        (bool success, bytes memory data) = _usdtAddr.call(
            abi.encodeWithSelector(
                0x23b872dd,
                msg.sender,
                address(this),
                amount
            )
        );
        bytes4(keccak256(bytes("transfer(address,uint256)")));
        (bool success1, bytes memory data1) = _usdtAddr.call(
            abi.encodeWithSelector(0xa9059cbb, team, amount)
        );
        require(
            success1 && (data1.length == 0 || abi.decode(data1, (bool))),
            "TransferHelper: TRANSFER_FAILED"
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper: TRANSFER_FROM_FAILED"
        );
        emit Mint(msg.sender, amount);
        emit Transfer(address(0), msg.sender, amount);
        return true;
    }
}