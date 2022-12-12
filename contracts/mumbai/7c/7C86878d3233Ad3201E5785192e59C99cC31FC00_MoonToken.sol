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
        allowance[_from][msg.sender] = allowance[_from][msg.sender] - _value;

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