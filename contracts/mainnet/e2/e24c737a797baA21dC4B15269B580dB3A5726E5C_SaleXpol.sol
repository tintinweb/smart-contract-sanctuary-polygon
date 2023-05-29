// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.1;

import "./CryptopoliumToken.sol";


contract SaleXpol {
    string public constant name = "SaleXpol";
    address payable public owner;
    uint256 private price = 75;


    mapping(address => bool) public buyers;

    CryptopoliumToken public tPol;
    address public usdt = 0xc2132D05D31c914a87C6611C10748AEb04B58e8F;

    constructor(CryptopoliumToken _tPol) payable {
        tPol = _tPol;
        owner = payable(msg.sender);
    }

    receive() external payable {
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not the owner");
    _;
    }

    modifier onlyBuyers() {
        require(buyers[msg.sender], "Your wallet is not listed for this private sale!");
        _;
    }

    function transferOwnership(address newOwner) external onlyOwner {
        if (newOwner != address(0)) {
            owner = payable(newOwner);
        }
    } 

    function sale(uint256 _amount) public onlyBuyers {
        
        uint256 payment = (_amount * price)/10**5;
        payment = payment/10**12;

        require(payment <= IERC20(usdt).balanceOf(msg.sender), "You do not have enough USDT in your wallet!");
        require(_amount <= tPol.balanceOf(address(this)), "Not enough XPOL for sell");

        IERC20(usdt).transferFrom(msg.sender, address(this), payment);
        tPol.transfer(msg.sender, _amount);

    }

    function withdraw(uint256 _amount) public onlyOwner {
        
        require(_amount <= IERC20(usdt).balanceOf(address(this)), "Not enough USDT");
        IERC20(usdt).transfer(owner, _amount);

    }

     function withdrawP(uint256 _amount) public onlyOwner {
        require(msg.sender == owner, "Only owner");
        require(_amount <= tPol.balanceOf(address(this)), "Not enough XPOL");
        tPol.transfer(owner, _amount);

    }

    function add(address[] memory a) public onlyOwner {
        

        for(uint i = 0; i < a.length; i++) {
            buyers[a[i]] = true;
        }
    }
    
    function check(address a) public view returns(bool c) {
        
        if(buyers[a]) c = true;
        return c;
    }

    function setPrice(uint256 _amount) public onlyOwner {
        price = _amount;
    }

    function getPrice() public view returns (uint256) {
        return price;
    }



}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.17;

interface IERC20 {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);


    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract CryptopoliumToken is IERC20 {
    
    string public constant name = "Cryptopolium";
    string public constant symbol = "XPOL";
    uint8 public constant decimals = 18;

    mapping(address => uint256) balances;
    mapping(address => mapping (address => uint256)) allowed;

    uint256 totalSupply_ = 12000000000000000000000000000;

    constructor() {
        balances[msg.sender] = totalSupply_;
    }

    function totalSupply() public override view returns (uint256) {
        return totalSupply_;
    }

    function balanceOf(address tokenOwner) public override view returns (uint256) {
        return balances[tokenOwner];
    }

    function transfer(address receiver, uint256 numTokens) public override returns (bool) {
        require(numTokens <= balances[msg.sender]);
        balances[msg.sender] -= numTokens;
        balances[receiver] += numTokens;
        emit Transfer(msg.sender, receiver, numTokens);
        return true;
    }

    function approve(address delegate, uint256 numTokens) public override returns (bool) {
        allowed[msg.sender][delegate] = numTokens;
        emit Approval(msg.sender, delegate, numTokens);
        return true;
    }

    function allowance(address owner, address delegate) public override view returns (uint) {
        return allowed[owner][delegate];
    }

    function transferFrom(address owner, address buyer, uint256 numTokens) public override returns (bool) {
        require(numTokens <= balances[owner]);
        require(numTokens <= allowed[owner][msg.sender]);

        balances[owner] -= numTokens;
        allowed[owner][msg.sender] -= numTokens;
        balances[buyer] += numTokens;
        emit Transfer(owner, buyer, numTokens);
        return true;
    }
}