/**
 *Submitted for verification at polygonscan.com on 2022-05-04
*/

pragma solidity ^0.8.13;

contract PureToken {

    mapping( address => uint256 ) balances;
    mapping( address => mapping( address => uint256 ) ) allowed;

    uint256 _totalSupply = 2000000;

    address public owner;

    event Transfer( address indexed _from, address indexed _to, uint256 _value );
    event Approval( address indexed _owner, address indexed _spender, uint256 _value );

    constructor() {

        owner = msg.sender;
        balances[owner] = _totalSupply;

    }

    function name() public view returns ( string memory ) {

        return "PureMTLToken";

    }

    function symbol() public view returns ( string memory ) { 

        return "PMTLT";

    }

    function decimals() public view returns ( uint8 ) {

        return 0;

    }

    function totalSupply() public view returns ( uint256 ) {

        return _totalSupply;

    }

    function balanceOf(address _owner) external view returns ( uint256 balance ) {

        return balances[_owner ];

    }

    function transfer(address _to, uint256 _value) external returns (bool success) {

        if ( balances[msg.sender] >= _value ) {

            balances[msg.sender] -= _value;
            balances[_to] += _value;

            emit Transfer( msg.sender, _to, _value );

            return true;

        } else {

            return false;

        }

    }

    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success) {

        if ( 
            balances[_from] >= _value              &&
            allowed[_from][msg.sender] >= _value   &&
            _value > 0                             &&
            balances[_to] + _value > balances[_to]
        ) {

            balances[_from] -= _value;
            balances[_to]   += _value;

            emit Transfer( _from, _to, _value );

            return true;

        } else {

            return false;

        }

    }

    function approve(address _spender, uint256 _value) external returns (bool success) {

        allowed[msg.sender][_spender] = _value;

        emit Approval( msg.sender, _spender, _value );

        return true;

    }

    function allowance(address _owner, address _spender) external view returns (uint256 remaining) {

        return allowed[_owner][_spender];

    }

    function toDestroy() public { 

        require( msg.sender == owner );

        selfdestruct( payable( owner ) );

    }

}