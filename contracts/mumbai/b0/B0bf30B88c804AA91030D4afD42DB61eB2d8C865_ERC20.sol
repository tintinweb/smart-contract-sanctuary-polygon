// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import {IERC20} from "../../interfaces/IERC20.sol";

contract ERC20 is IERC20 {
    bytes10 public constant name = "Mock Token";
    bytes3 public constant symbol = "MTK";

    uint public immutable decimals;
    uint public immutable totalSupply;

    address public immutable owner;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowances;

    constructor(uint _decimals) {
        owner = msg.sender;
        decimals = _decimals;
        totalSupply = 1_000_000_000 * (10 ** decimals);
        balances[owner] = totalSupply;
    }

    function balanceOf(address _owner) external view returns (uint256 balance) {
        return balances[_owner];
    }

    function transfer(
        address _to,
        uint256 _value
    ) external returns (bool success) {
        require(balances[msg.sender] >= _value, "!bal");

        balances[msg.sender] -= _value;
        balances[_to] += _value;

        emit Transfer(msg.sender, _to, _value);

        return true;
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external returns (bool success) {
        require(balances[_from] >= _value, "!bal");
        require(allowances[_from][msg.sender] >= _value, "!alwnc");

        balances[_from] -= _value;
        allowances[_from][msg.sender] -= _value;

        balances[_to] += _value;

        emit Transfer(_from, _to, _value);

        return true;
    }

    function approve(
        address _spender,
        uint256 _value
    ) external returns (bool success) {
        require(_value > 0, "!value");
        require(balances[msg.sender] >= _value, "!balance");

        allowances[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);

        return true;
    }

    function allowance(
        address _owner,
        address _spender
    ) external view returns (uint256 remaining) {
        return allowances[_owner][_spender];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    /// @param _owner The address from which the balance will be retrieved
    /// @return balance the balance
    function balanceOf(address _owner) external view returns (uint256 balance);

    /// @notice send `_value` token to `_to` from `msg.sender`
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return success Whether the transfer was successful or not
    function transfer(
        address _to,
        uint256 _value
    ) external returns (bool success);

    /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
    /// @param _from The address of the sender
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return success Whether the transfer was successful or not
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external returns (bool success);

    /// @notice `msg.sender` approves `_addr` to spend `_value` tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _value The amount of wei to be approved for transfer
    /// @return success Whether the approval was successful or not
    function approve(
        address _spender,
        uint256 _value
    ) external returns (bool success);

    /// @param _owner The address of the account owning tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @return remaining Amount of remaining tokens allowed to spent
    function allowance(
        address _owner,
        address _spender
    ) external view returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );
}