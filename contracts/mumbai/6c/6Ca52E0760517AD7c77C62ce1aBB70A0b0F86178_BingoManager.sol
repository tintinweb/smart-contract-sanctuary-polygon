/**
 *Submitted for verification at polygonscan.com on 2022-05-16
*/

// File: tests/BingGO.sol


pragma solidity ^0.8.13;

//Erc 20 test token


contract BingGO { 
    string  public name = "BingGO";
    string  public symbol = "BingGO";
    uint256 public totalSupply = 1000000000000000000000000; // 1 million tokens
    uint8   public decimals = 18;

    event Transfer(
        address indexed _from,
        address indexed _to,
        uint256 _value
    );

    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    constructor() public {
        balanceOf[msg.sender] = totalSupply;
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= balanceOf[_from]);
        require(_value <= allowance[_from][msg.sender]);
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        allowance[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
    }
}

// File: tests/BingoManager.sol


pragma solidity ^0.8.13;



contract BingoManager {
    string public name = "Bingo Manager";
    BingGO public testToken;
    address public owner;

    mapping(address => uint256) public myBalance;


    constructor(BingGO _testToken) public payable {
        testToken = _testToken;

        //assigning owner on deployment
        owner = msg.sender;
    }

    //stake tokens function

    function Deposit(uint256 _amount) public {
        require(_amount > 0, "amount cannot be 0");
        testToken.transferFrom(msg.sender, address(this), _amount);
        myBalance[msg.sender] +    myBalance[msg.sender] + _amount;
    }

    //claim test 1000 Tst (for testing purpose only !!)
    function Claim( uint256 _amount) public {
        testToken.transfer(msg.sender, _amount);
    }

        //cliam test 1000 Tst (for testing purpose only !!)
    function Withdraw() public {
        uint256 balance = myBalance[msg.sender];
        testToken.transfer(msg.sender, balance);
    }

    
}