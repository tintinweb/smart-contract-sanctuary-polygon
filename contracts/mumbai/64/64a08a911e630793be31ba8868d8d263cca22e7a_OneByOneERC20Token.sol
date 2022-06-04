/**
 *Submitted for verification at polygonscan.com on 2022-06-03
*/

pragma solidity ^0.5.0;


interface IERC20 {

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}


pragma solidity ^0.5.0;


library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}


pragma solidity ^0.5.0;


contract ERC20 is IERC20 {

    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 value) public returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue));
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 value) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }

    function _approve(address owner, address spender, uint256 value) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, msg.sender, _allowances[account][msg.sender].sub(amount));
    }
}


pragma solidity ^0.5.0;


contract OneByOneERC20Token is ERC20 {

    string private _name = "One By One";
    string private _symbol = "OBO";
    uint8 private _decimals = 9;
    uint256 public amount;

    // All for airdrop to random lucky person
    address private _owner = 0x87c686760f9a434Aa65D89f2d4DC4764449fd912;

    
    // Expand the influence of the project and invest in various digital cryptocurrency projects. 
    //And use these investment projects as collateral to issue equity tokens: OBOE. 
    //Users who hold OBO can exchange their OBO into OBOE, 
    //and enjoy the benefits brought by the OBOE token investment project and 
    //the value-added benefits of OBOE.
    address private _foundation = 0x2b59d303cCacc359E15cB1F49E63132Bb017Da3b;
    
    // For development team
    address private _team = 0x704406855ad003d7E609f371CadaB86e901506f3;

    //donation account
    //Donate 1 eth = 1000000 OBO Rewards (Actual quantity is based on obo market price)
    //The minimum price of OBO for donation feedback is 0.002$
    //The minimum donation amount needs to be greater than 1 eth
    //Until the donation feedback account is empty
    address  private _donateback = 0xB6425F0676a549aE026742dDEf55c0589aEC0cCF;


    //We hope that those who achieve financial freedom through OBO 
    //(including those who get OBO free airdrops and those who get benefits during the OBO growth stage) 
    //can give back some OBOs to this address, 
    //and all OBOs received on this address will be re-airdropped to others, 
    //we want to be able to keep this cycle of wealth going.
    //Wealth revolving accounts will be published on our official website and github.

    //github project:   https://github.com/obogithub/oboproject
    //twitter:  @OneByOneCoin
    //contact us:   [email protected]


    constructor() public payable{

        _mint(_owner, 1000 * 10**8 * 10**9);

        transfer(_foundation, 250 * 10**8 * 10**9);
        transfer(_team, 50 * 10**8 * 10**9);
        transfer(_donateback, 150 * 10**8 * 10**9);

    }

    //The project team can choose to destroy some OBOs in some special cases
    function burn(uint256 value) public {
      _burn(msg.sender, value);
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
}