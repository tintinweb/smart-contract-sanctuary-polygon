pragma solidity ^0.7.5;

contract ReserveLike {}

contract KlaytnDai {
    string public constant name = "Klaytn Dai";
    string public constant symbol = "KDAI";

    string public constant version = "0413";

    address public owner;

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    event SetOwner(address owner);

    function setOwner(address _owner) public onlyOwner {
        owner = _owner;
        emit SetOwner(_owner);
    }

    function add(uint256 a, uint256 b) private pure returns (uint256) {
        require(a <= uint256(-1) - b);
        return a + b;
    }

    function sub(uint256 a, uint256 b) private pure returns (uint256) {
        require(a >= b);
        return a - b;
    }

    ReserveLike public Reserve;

    function setReserve(address reserve) public onlyOwner {
        Reserve = ReserveLike(reserve);
    }

    constructor() public {
        owner = msg.sender;
    }

    uint8 public constant decimals = 18;
    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance; // (holder, spender)

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(
        address indexed holder,
        address indexed spender,
        uint256 amount
    );

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public returns (bool) {
        if (from != msg.sender && allowance[from][msg.sender] != uint256(-1)) {
            allowance[from][msg.sender] = sub(
                allowance[from][msg.sender],
                amount
            );
        }

        if (to == address(Reserve)) {
            burn(from, amount);
            return true;
        }

        balanceOf[from] = sub(balanceOf[from], amount);
        balanceOf[to] = add(balanceOf[to], amount);

        emit Transfer(from, to, amount);

        return true;
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function mint(address user, uint256 amount) private {
        balanceOf[user] = add(balanceOf[user], amount);
        totalSupply = add(totalSupply, amount);

        emit Transfer(address(0), user, amount);
    }

    function burn(address user, uint256 amount) private {
        balanceOf[user] = sub(balanceOf[user], amount);
        totalSupply = sub(totalSupply, amount);

        emit Transfer(user, address(0), amount);
    }

    function transfer(address to, uint256 amount) public returns (bool) {
        if (msg.sender == address(Reserve)) {
            mint(to, amount);
            return true;
        }

        return transferFrom(msg.sender, to, amount);
    }
}