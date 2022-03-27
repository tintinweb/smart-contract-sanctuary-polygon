/**
 *Submitted for verification at polygonscan.com on 2022-03-26
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Testing{
    uint256 public totalSupply_;
    string public name;
    string public symbol;
    uint8 public decimals;
    address public owner;
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;

    event Approval(
        address indexed tokenOwner,
        address indexed spender,
        uint256 tokens
    );

    event Transfer(address indexed from, address indexed to, uint256 tokens);

    constructor(
        uint256 _total,
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        address _owneraddress
    ) {
        totalSupply_ = _total;
        owner = _owneraddress;
        balances[_owneraddress] = totalSupply_;
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
    }

    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

    function balanceOf(address tokenOwner) public view returns (uint256) {
        return balances[tokenOwner];
    }

    function transfer(address receiver, uint256 numTokens)
        public
        returns (bool)
    {
        require(numTokens <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender] - numTokens;
        balances[receiver] = balances[receiver] + numTokens;
        emit Transfer(msg.sender, receiver, numTokens);
        return true;
    }

    function approve(address delegate, uint256 numTokens)
        public
        returns (bool)
    {
        allowed[msg.sender][delegate] = numTokens;
        emit Approval(msg.sender, delegate, numTokens);
        return true;
    }

    function allowance(address _owner, address _delegate)
        public
        view
        returns (uint256)
    {
        return allowed[_owner][_delegate];
    }

    function transferFrom(
        address _owner,
        address _buyer,
        uint256 numTokens
    ) public returns (bool) {
        require(numTokens <= balances[_owner]);
        require(numTokens <= allowed[_owner][msg.sender]);
        balances[_owner] = balances[_owner] - numTokens;
        allowed[_owner][msg.sender] = allowed[_owner][msg.sender] - numTokens;
        balances[_buyer] = balances[_buyer] + numTokens;
        emit Transfer(_owner, _buyer, numTokens);
        return true;
    }

    function buy(uint256 numOfTokens) public payable returns (bool) {
        require(numOfTokens <= balances[owner]);
        require(owner != msg.sender);
        require(msg.value == (numOfTokens / 10**decimals) * 0.000000001 ether);
        balances[msg.sender] = balances[msg.sender] + numOfTokens;
        balances[owner] = balances[owner] - numOfTokens;
        emit Transfer(owner, msg.sender, numOfTokens);
        return true;
    }
}