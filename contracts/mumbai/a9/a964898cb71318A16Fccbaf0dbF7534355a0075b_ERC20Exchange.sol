// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

// INFO: 只实现主要逻辑，不实现小费，权限，订单状态校验，创建订单和完成订单时要检查余额。。。
// 用户先存币 -> 创建订单 -> 完成订单（换币）-> 不玩了退钱（提币）
import {MoonToken} from "./MoonToken.sol";

contract ERC20Exchange {
    // 引入其它合约
    address public MOTAddress;
    MoonToken MOT;

    // tokens struct
    // {
    //     "ETH": {
    //         EOA1: 10,
    //         EOA2: 20,
    //     },
    //     "MOT": {
    //         EOA1: 23,
    //         EOA4: 4,
    //     }
    // }
    mapping(address => mapping(address => uint256)) public tokens;

    struct _Order {
        uint256 id;
        address user;
        address tokenGive;
        uint256 valueGive;
        address tokenGet;
        uint256 valueGet;
        uint256 timestamp;
        uint256 orderStatus; // 订单状态1：创建 200: 成功 404: 软删除
    }

    uint256 orderCount = 0;

    mapping(uint256 => _Order) public orders;

    event Order(
        uint256 indexed id,
        address user,
        address tokenGive,
        uint256 valueGive,
        address tokenGet,
        uint256 valueGet,
        uint256 timestamp,
        uint256 orderStatus
    );

    event EcancelOrder(
        uint256 indexed id,
        address user,
        address tokenGive,
        uint256 valueGive,
        address tokenGet,
        uint256 valueGet,
        uint256 timestamp,
        uint256 orderStatus
    );

    event EfinishOrder(
        uint256 indexed id,
        address user,
        address tokenGive,
        uint256 valueGive,
        address tokenGet,
        uint256 valueGet,
        uint256 timestamp,
        uint256 orderStatus
    );

    event Depolit(
        address indexed token,
        address user,
        uint256 amount,
        uint256 balance
    );

    event WithDraw(
        address indexed token,
        address user,
        uint256 amount,
        uint256 balance
    );

    constructor(address _MOTAddress) {
        // 初始化代币实例
        // https://mumbai.polygonscan.com/address/0x99c98b530217bF831126e949ce6A871b5F36bb38#code
        MOTAddress = _MOTAddress;
        MOT = MoonToken(MOTAddress);
    }

    function depolitETH() public payable {
        // 存入平台币，不是 ERC20 代币
        // 在 polygon 就是 Matic
        tokens[address(0)][msg.sender] =
            tokens[address(0)][msg.sender] +
            msg.value;

        emit Depolit(
            address(0),
            msg.sender,
            msg.value,
            tokens[address(0)][msg.sender]
        );
    }

    function depolitToken(uint256 _value) public {
        // 存入ERC20代币
        // 检查是否已经授权了额度
        // MOT.allowance[msg.sender, address(this)]
        require(MOT.allowance(msg.sender, address(this)) >= _value);

        MOT.transferFrom(msg.sender, address(this), _value);

        tokens[MOTAddress][msg.sender] =
            tokens[MOTAddress][msg.sender] +
            _value;
    }

    function withdrawEther(uint256 _value) public {
        // 提取平台token
        require(tokens[address(0)][msg.sender] >= _value);
        tokens[address(0)][msg.sender] =
            tokens[address(0)][msg.sender] -
            _value;

        payable(msg.sender).transfer(_value);
        emit WithDraw(
            address(0),
            msg.sender,
            _value,
            tokens[address(0)][msg.sender]
        );
    }

    function withdrawToken(uint256 _value) public {
        // 提取代币
        require(tokens[MOTAddress][msg.sender] >= _value);

        tokens[MOTAddress][msg.sender] =
            tokens[MOTAddress][msg.sender] -
            _value;

        MOT.transfer(msg.sender, _value);

        emit WithDraw(
            MOTAddress,
            msg.sender,
            _value,
            tokens[MOTAddress][msg.sender]
        );
    }

    function createOrder(
        address _tokenGive,
        uint256 _valueGive,
        address _tokenGet,
        uint256 _valueGet
    ) public {
        orderCount = orderCount + 1;
        orders[orderCount] = _Order(
            orderCount,
            msg.sender,
            _tokenGive,
            _valueGive,
            _tokenGet,
            _valueGet,
            block.timestamp,
            1
        );

        emit Order(
            orderCount,
            msg.sender,
            _tokenGive,
            _valueGive,
            _tokenGet,
            _valueGet,
            block.timestamp,
            1
        );
    }

    function cancelOrder(uint256 _orderId) public {
        // TODO: 订单状态检查
        require(orders[_orderId].user == msg.sender);
        orders[_orderId].orderStatus = 404;

        _Order memory order = orders[_orderId];

        emit EcancelOrder(
            order.id,
            order.user,
            order.tokenGive,
            order.valueGive,
            order.tokenGet,
            order.valueGet,
            block.timestamp,
            order.orderStatus
        );
    }

    function finishOrder(uint256 _orderId) public {
        // TODO: 订单状态检查，钱包token余额检查
        _Order memory order = orders[_orderId];

        // 本系统更新账户余额互换
        tokens[order.tokenGet][msg.sender] -= order.valueGet;
        tokens[order.tokenGet][order.user] += order.valueGet;

        tokens[order.tokenGive][msg.sender] += order.valueGive;
        tokens[order.tokenGive][order.user] -= order.valueGive;

        // 更新订单状态
        orders[_orderId].orderStatus = 200;

        emit EfinishOrder(
            order.id,
            order.user,
            order.tokenGive,
            order.valueGive,
            order.tokenGet,
            order.valueGet,
            block.timestamp,
            200
        );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

// TODO: 异常/错误处理 检查转账的账户是否有足够的代币

contract MoonToken {
    // function name() public view returns (string)
    string public name = "MoonToken";
    // function symbol() public view returns (string)
    string public symbol = "MOT";
    // function decimals() public view returns (uint8)
    uint8 public decimals = 18; // 每个代币面值 0.0000,,,1MOT
    // function totalSupply() public view returns (uint256)
    uint256 public totalSupply = 100 * 10**decimals; // 这里代币的个数是和decimals相关的 100MOT
    // function balanceOf(address _owner) public view returns (uint256 balance)
    // {
    //     address1: 20,
    //     address2: 30,
    //     address3: 10,
    // }
    mapping(address => uint256) public balanceOf;
    // function allowance(address _owner, address _spender) public view returns (uint256 remaining)
    // {
    //     _owner1: {
    //         _spender1: 10,
    //         _spender2: 2,
    //     },
    //     _owner2: {
    //         _spender1: 3,
    //         _spender4: 34,
    //     }
    // }
    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );

    // 规范中没有代币初始分配的规范
    constructor() {
        // 把所有币交给合约部署者
        balanceOf[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }

    // function transfer(address _to, uint256 _value) public returns (bool success)
    function transfer(address _to, uint256 _value)
        public
        returns (bool success)
    {
        // 用户转账
        // 代币发行方可能会在此函数里添加额外的逻辑如抽成，手续费

        balanceOf[msg.sender] = balanceOf[msg.sender] - _value;
        balanceOf[_to] = balanceOf[_to] + _value;

        emit Transfer(msg.sender, _to, _value);

        return true;
    }

    // function transferFrom(address _from, address _to, uint256 _value) public returns (bool success)
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public returns (bool success) {
        allowance[_from][_to] = allowance[_from][_to] - _value;

        balanceOf[_from] = balanceOf[_from] - _value;
        balanceOf[_to] = balanceOf[_to] + _value;

        emit Transfer(_from, _to, _value);

        return true;
    }

    // function approve(address _spender, uint256 _value) public returns (bool success)
    function approve(address _spender, uint256 _value)
        public
        returns (bool success)
    {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
}