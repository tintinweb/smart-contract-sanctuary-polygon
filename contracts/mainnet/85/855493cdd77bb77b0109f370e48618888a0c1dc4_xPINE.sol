/**
 *Submitted for verification at polygonscan.com on 2022-08-14
*/

pragma solidity ^0.8.13;

interface IERC20 {
    function totalSupply() external view returns (uint);

    function balanceOf(address account) external view returns (uint);

    function transfer(address recipient, uint amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

contract xPINE is IERC20 {
    string public name     = "xPINE Token";
    string public symbol   = "xPINE";
    uint8  public decimals = 6;
    uint balance = 0;

    IERC20 constant internal depositCurrency = IERC20(0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174);

    event  Deposit(address indexed dst, uint wad);
    event  Withdrawal(address indexed src, uint wad);

    mapping (address => uint)                       public  balanceOf;
    mapping (address => mapping (address => uint))  public  allowance;

    function deposit(uint amount) public payable {
        require(depositCurrency.transferFrom(msg.sender, address(this), amount));
        balanceOf[msg.sender] += amount;
        balance += amount;
        emit Deposit(msg.sender, amount);
    }

    function withdraw(uint amount) public {
        require(balanceOf[msg.sender] >= amount);
        balanceOf[msg.sender] -= amount;
        balance -= amount;
        depositCurrency.transfer(msg.sender, amount);
        emit Withdrawal(msg.sender, amount);
    }

    function totalSupply() public view returns (uint) {
        return balance;
    }

    function approve(address guy, uint wad) public returns (bool) {
        allowance[msg.sender][guy] = wad;
        emit Approval(msg.sender, guy, wad);
        return true;
    }

    function transfer(address dst, uint wad) public returns (bool) {
        return transferFrom(msg.sender, dst, wad);
    }

    function transferFrom(address src, address dst, uint wad)
        public
        returns (bool)
    {
        require(balanceOf[src] >= wad);

        if (src != msg.sender && allowance[src][msg.sender] != 0) {
            require(allowance[src][msg.sender] >= wad);
            allowance[src][msg.sender] -= wad;
        }

        balanceOf[src] -= wad;
        balanceOf[dst] += wad;

        emit Transfer(src, dst, wad);
        return true;
    }
}