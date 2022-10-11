pragma solidity >=0.8.0 <0.9.0;

interface IERC20 {
    function transfer(address _to, uint256 _value) external returns (bool);
    
    // don't need to define other functions, only using `transfer()` in this case

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

contract TestTransfer {

    address private owner;
    IERC20 dai;
    mapping (address => uint) private balance;
    mapping (address => mapping(address => uint)) private deposites;



    constructor() {
     //   console.log("Owner contract deployed by:", msg.sender);
        owner = msg.sender; // 'msg.sender' is sender of current call, contract deployer for a constructor
        dai = IERC20(0xe11A86849d99F524cAC3E7A0Ec1241828e332C62);
    }

    function deposit(uint amount) public payable returns (uint) {
        balance[msg.sender] += msg.value;
        dai.transferFrom(msg.sender, address(this), amount);
        return balance[msg.sender];
    }

    function withdraw(uint amount) public returns (uint remainingBal) {
        // Check enough balance available, otherwise just return balance
        if (amount <= balance[msg.sender]) {
            balance[msg.sender] -= amount;
            dai.transfer(msg.sender, amount);
        }
        return balance[msg.sender];
    }

    function userBalance(address addr) public  view returns (uint) {
        return balance[addr];
    }
}