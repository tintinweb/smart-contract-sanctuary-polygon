// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.12;

contract Token2 {

    mapping (address => uint) balances;
    mapping (address => mapping (address => uint)) allowed;

    event Transfer(address indexed sender, address indexed receiver, uint value);
    event Approval(address approver, address spender, uint value);
    event TokensBurned(address burner, uint amount);

    uint8 constant public _decimals = 18;
    string constant public _symbol = "DerpCoin";
    string constant public _name = "Derpcoin token Token";
    uint public _totalSupply;
    address public bank;

    // simple initialization, giving complete token supply to one address
    constructor(address _bank) {
        bank = _bank;
        require(bank != address(0), 'Must initialize with nonzero address');
        uint totalInitialBalance = 0;
        balances[bank] = totalInitialBalance;
        _totalSupply = totalInitialBalance;
        emit Transfer(address(0), bank, totalInitialBalance);
    }

    modifier bankOnly() {
        require (msg.sender == bank, 'Only bank address may call this');
        _;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function getOwner() external view returns (address) {
        return bank;
    }

    function setBank(address newBank) public bankOnly {
        address oldBank = bank;
        bank = newBank;
    }

    // burn tokens, taking them out of supply
    function burn(uint amount) public {
        balances[msg.sender] -= amount;
        _totalSupply -= amount;
        emit Transfer(msg.sender, address(0), amount);
        emit TokensBurned(msg.sender, amount);
    }

    // burn tokens for someone else, subject to approval
    function burnFrom(address burned, uint amount) public {

        // deduct
        balances[burned] -= amount;

        // adjust allowance
        allowed[burned][msg.sender] -= amount;

        _totalSupply -= amount;

        emit Transfer(burned, address(0), amount);
        emit TokensBurned(burned, amount);
    }

    // transfer tokens
    function transfer(address to, uint value) public returns (bool success)
    {
        if (to == address(0)) {
            burn(value);
        } else {
            // deduct
            balances[msg.sender] -= value;
            // add
            balances[to] += value;

            emit Transfer(msg.sender, to, value);
        }
        return true;
    }

    // transfer someone else's tokens, subject to approval
    function transferFrom(address from, address to, uint value) public returns (bool success)
    {
        if (to == address(0)) {
            burnFrom(from, value);
        } else {

            // deduct
            balances[from] -= value;

            // add
            balances[to] += value;

            // adjust allowance
            allowed[from][msg.sender] -= value;

            emit Transfer(from, to, value);
        }
        return true;
    }

    // retrieve the balance of address
    function balanceOf(address owner) public view returns (uint balance) {
        return balances[owner];
    }

    // approve another address to transfer a specific amount of tokens
    function approve(address spender, uint value) public returns (bool success) {
        allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    // incrementally increase approval, see https://github.com/ethereum/EIPs/issues/738
    function increaseApproval(address spender, uint value) public returns (bool success) {
        allowed[msg.sender][spender] += value;
        emit Approval(msg.sender, spender, allowed[msg.sender][spender]);
        return true;
    }

    // incrementally decrease approval, see https://github.com/ethereum/EIPs/issues/738
    function decreaseApproval(address spender, uint decreaseValue) public returns (bool success) {
        uint oldValue = allowed[msg.sender][spender];
        // allow decreasing too much, to prevent griefing via front-running
        if (decreaseValue >= oldValue) {
            allowed[msg.sender][spender] = 0;
        } else {
            allowed[msg.sender][spender] = oldValue - decreaseValue;
        }
        emit Approval(msg.sender, spender, allowed[msg.sender][spender]);
        return true;
    }

    // retrieve allowance for a given owner, spender pair of addresses
    function allowance(address owner, address spender) public view returns (uint remaining) {
        return allowed[owner][spender];
    }

    function numCoinsFrozen() public view returns (uint) {
        return balances[address(this)];
    }
}