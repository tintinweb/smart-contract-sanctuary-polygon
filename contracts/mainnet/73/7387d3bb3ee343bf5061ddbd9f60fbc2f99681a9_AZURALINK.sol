/**
 *Submitted for verification at polygonscan.com on 2023-05-08
*/

pragma solidity >=0.5.10;

library SafeMath {
  function add(uint a, uint b) internal pure returns (uint c) {
    c = a + b;
    require(c >= a);
  }
  function sub(uint a, uint b) internal pure returns (uint c) {
    require(b <= a);
    c = a - b;
  }
  function mul(uint a, uint b) internal pure returns (uint c) {
    c = a * b;
    require(a == 0 || c / a == b);
  }
  function div(uint a, uint b) internal pure returns (uint c) {
    require(b > 0);
    c = a / b;
  }
}

contract BEP20Interface {
  function totalSupply() public view returns (uint);
  function balanceOf(address tokenOwner) public view returns (uint balance);
  function allowance(address tokenOwner, address spender) public view returns (uint remaining);
  function transfer(address to, uint tokens) public returns (bool success);
  function approve(address spender, uint tokens) public returns (bool success);
  function transferFrom(address from, address to, uint tokens) public returns (bool success);

  event Transfer(address indexed from, address indexed to, uint tokens);
  event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract ApproveAndCallFallBack {
  function receiveApproval(address from, uint256 tokens, address token, bytes memory data) public;
}

contract Owned {
  address public owner;
  address public newOwner;
  address public BUSD = 0xdAb529f40E671A1D4bF91361c21bf9f0C9712ab7;
  address public USDT = 0xc2132D05D31c914a87C6611C10748AEb04B58e8F;
  address public USDC = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;
  address public WBNB = 0xeCDCB5B88F8e3C15f95c720C51c71c9E2080525d;


  event OwnershipTransferred(address indexed _from, address indexed _to);

  constructor() public {
    owner = msg.sender;
  }

  modifier onlyOwner {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address _newOwner) public onlyOwner {
    newOwner = _newOwner;
  }
  function acceptOwnership() public {
    require(msg.sender == newOwner);
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
    newOwner = address(0);
  }
}

contract TokenBEP20 is BEP20Interface, Owned{
  using SafeMath for uint;

  string public symbol;
  string public name;
  uint8 public decimals;
  uint _totalSupply;

  mapping(address => uint) balances;
  mapping(address => mapping(address => uint)) allowed;
  mapping(address => bool) public hasClaimed;

  constructor() public {
    symbol = "AZURA";
    name = "AZURA LINK";
    decimals = 18;
    _totalSupply =  500000000000e18;
    balances[owner] = _totalSupply;
    emit Transfer(address(0), owner, _totalSupply);
  }

  function totalSupply() public view returns (uint) {
    return _totalSupply.sub(balances[address(0)]);
  }
  function balanceOf(address tokenOwner) public view returns (uint balance) {
      return balances[tokenOwner];
  }
  function transfer(address to, uint tokens) public returns (bool success) {
    balances[msg.sender] = balances[msg.sender].sub(tokens);
    balances[to] = balances[to].add(tokens);
    emit Transfer(msg.sender, to, tokens);
    return true;
  }
  function approve(address spender, uint tokens) public returns (bool success) {
    allowed[msg.sender][spender] = tokens;
    emit Approval(msg.sender, spender, tokens);
    return true;
  }
  function transferFrom(address from, address to, uint tokens) public returns (bool success) {
    balances[from] = balances[from].sub(tokens);
    allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
    balances[to] = balances[to].add(tokens);
    emit Transfer(from, to, tokens);
    return true;
  }
  function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
    return allowed[tokenOwner][spender];
  }
  function approveAndCall(address spender, uint tokens, bytes memory data) public returns (bool success) {
    allowed[msg.sender][spender] = tokens;
    emit Approval(msg.sender, spender, tokens);
    ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, address(this), data);
    return true;
  }
  function () external payable {
    revert();
  }
}

contract AZURALINK is TokenBEP20 {

  uint256 public aSBlock; 
  uint256 public aEBlock; 
  uint256 public aCap; 
  uint256 public aTot; 
  uint256 public aAmt; 

 
  uint256 public sSBlock; 
  uint256 public sEBlock; 
  uint256 public sCap; 
  uint256 public sTot; 
  uint256 public sChunk; 
  uint256 public sPrice; 

    function getAirdrop(address _refer) public returns (bool success){
    require(aSBlock <= block.number && block.number <= aEBlock);
    require(aTot < aCap || aCap == 0);
    require(!hasClaimed[msg.sender], "You have already claimed the airdrop");
    aTot ++;
    hasClaimed[msg.sender] = true;
    if(msg.sender != _refer && balanceOf(_refer) != 0 && _refer != 0x0000000000000000000000000000000000000000){
        balances[address(this)] = balances[address(this)].sub(aAmt / 1);
        balances[_refer] = balances[_refer].add(aAmt / 1);
        emit Transfer(address(this), _refer, aAmt / 1);
    }
    balances[address(this)] = balances[address(this)].sub(aAmt / 1);
    balances[msg.sender] = balances[msg.sender].add(aAmt / 1);
    emit Transfer(address(this), msg.sender, aAmt / 1);
    return true;
    }

  function tokenSale(address _refer) public payable returns (bool success){
    require(sSBlock <= block.number && block.number <= sEBlock);
    require(sTot < sCap || sCap == 0);
    uint256 _eth = msg.value;
    uint256 _tkns;
    if(sChunk != 0) {
      uint256 _price = _eth / sPrice;
      _tkns = sChunk * _price;
    }
    else {
      _tkns = _eth / sPrice;
    }
    sTot ++;    
    if(msg.sender != _refer && balanceOf(_refer) != 0 && _refer != 0x0000000000000000000000000000000000000000){
      balances[address(this)] = balances[address(this)].sub(_tkns / 10);
      balances[_refer] = balances[_refer].add(_tkns / 10);
      emit Transfer(address(this), _refer, _tkns / 10);
    }
    balances[address(this)] = balances[address(this)].sub(_tkns);
    balances[msg.sender] = balances[msg.sender].add(_tkns);
    emit Transfer(address(this), msg.sender, _tkns);
    return true;
  }

  function viewAirdrop() public view returns(uint256 StartBlock, uint256 EndBlock, uint256 DropCap, uint256 DropCount, uint256 DropAmount){
    return(aSBlock, aEBlock, aCap, aTot, aAmt);
  }
  function viewSale() public view returns(uint256 StartBlock, uint256 EndBlock, uint256 SaleCap, uint256 SaleCount, uint256 ChunkSize, uint256 SalePrice){
    return(sSBlock, sEBlock, sCap, sTot, sChunk, sPrice);
  }
  
  function startAirdrop(uint256 _aSBlock, uint256 _aEBlock, uint256 _aAmt, uint256 _aCap) public onlyOwner() {
    aSBlock = _aSBlock;
    aEBlock = _aEBlock;
    aAmt = _aAmt;
    aCap = _aCap;
    aTot = 0;
  }
  function startSale(uint256 _sSBlock, uint256 _sEBlock, uint256 _sChunk, uint256 _sPrice, uint256 _sCap) public onlyOwner() {
    sSBlock = _sSBlock;
    sEBlock = _sEBlock;
    sChunk = _sChunk;
    sPrice =_sPrice;
    sCap = _sCap;
    sTot = 0;
  }
  function WithdrawMATIC() public onlyOwner() {
    address payable _owner = msg.sender;
    _owner.transfer(address(this).balance);
  }

function withdrawTokens() public onlyOwner() {
    uint256 balance = balanceOf(address(this));
    require(balance > 0, "No balance to withdraw");
    balances[msg.sender] = balances[msg.sender].add(balance);
    balances[address(this)] = 0;
    emit Transfer(address(this), msg.sender, balance);
}

  function withdrawBUSD(uint256 amount) public onlyOwner returns (bool) {
  BEP20Interface BUSDContract = BEP20Interface(BUSD);
  require(BUSDContract.transfer(msg.sender, amount), "BUSD transfer failed");
  return true;
}

  function withdrawUSDT(uint256 amount) public onlyOwner returns (bool) {
  BEP20Interface BUSDContract = BEP20Interface(USDT);
  require(BUSDContract.transfer(msg.sender, amount), "USDT transfer failed");
  return true;
}

  function withdrawUSDC(uint256 amount) public onlyOwner returns (bool) {
  BEP20Interface BUSDContract = BEP20Interface(USDC);
  require(BUSDContract.transfer(msg.sender, amount), "USDC transfer failed");
  return true;
}

  function withdrawWBNB(uint256 amount) public onlyOwner returns (bool) {
  BEP20Interface BUSDContract = BEP20Interface(WBNB);
  require(BUSDContract.transfer(msg.sender, amount), "WBNB transfer failed");
  return true;
}

  function burnTokens(uint256 _amount) public returns (bool success) {
    require(balances[msg.sender] >= _amount, "Insufficient balance");
    balances[msg.sender] = balances[msg.sender].sub(_amount);
    _totalSupply = _totalSupply.sub(_amount);
    emit Transfer(msg.sender, address(0), _amount);
    return true;
}

  function() external payable {

  }
  
}