/**
 *Submitted for verification at polygonscan.com on 2022-02-06
*/

pragma solidity 0.7.0;

contract DevToken {
    // name
    string public name = "Dev Token";
    // Symbol or Ticker
    string public symbol = "DEV";
    // decimal
    uint8 public decimals = 18;
    // totalSupply
    uint256 public totalSupply;

    // transfer event
    event Transfer (address indexed sender, address indexed to, uint256 amount);

    // Approval
    event Approval (address indexed from, address indexed spender, uint256 amount);

    // balance mapping
    mapping (address => uint256) public balanceOf;

    // allowance mapping
    mapping (address => mapping(address => uint256)) public allowance;

    constructor(uint256 _totalSupply) {
        totalSupply = _totalSupply;
        balanceOf[msg.sender] = _totalSupply;
    }


    // transfer function
    // inputs address to and amount
    function transfer(address _to, uint256 _amount) public returns(bool success) {
        // the user that is transferring must have sufficient balance
        require(balanceOf[msg.sender] >= _amount, "You don't have enough balance.");
        // substract the amount from sender
        balanceOf[msg.sender] -= _amount;
        // add the amount to the user transfered
        balanceOf[_to] += _amount;
        emit Transfer(msg.sender, _to, _amount);
        return true;
    }

    // approve function
    // address of approval and amount
    function approve(address _spender, uint256 _amount) public returns(bool success) {
        // increase allowance
        allowance[msg.sender][_spender] += _amount;
        // emit allowance event
        emit Approval(msg.sender, _spender, _amount);
        return true;
    }

    // transferFrom function
    function transferFrom(address _from, address _to, uint256 _amount) public returns(bool success) {
        // check the balance of from user
        require(balanceOf[_from] >= _amount, "Not enough balance in the sender's address.");
        // check the allowance of the msg.sender
        require(allowance[_from][msg.sender] >= _amount, "Amount is greater than the allowance."); 
        // substract the amount from the user
        balanceOf[_from] -= _amount;
        // add the amount to the user
        balanceOf[_to] += _amount;
        // decrease the allowance
        allowance[_from][msg.sender] -= _amount;
        // emit transfer
        emit Transfer(_from, _to, _amount);
        // emit Approval
        emit Approval(_from, msg.sender, _amount);
        return true;
    }
}