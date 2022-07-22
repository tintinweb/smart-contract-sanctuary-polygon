/**
 *Submitted for verification at polygonscan.com on 2022-07-22
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.5.14;

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



// ERC 20 Token Standard #20 Interface

contract ERC20Interface {
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


//Owned
contract Owned {
    address payable public owner;
  
    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }

   

    
}


contract PV19 is ERC20Interface, Owned {
    using SafeMath for uint;

    string public symbol;
    string public  name;
    uint8 public decimals;
    uint _totalSupply;
    uint public PointSpent;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;


    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    constructor() public {
        symbol = "pol";
        name = "Allmost Token";
        decimals = 3;
        _totalSupply = 999000000 * 10**uint(decimals);
        balances[owner] = _totalSupply;
        emit Transfer(address(0), owner, _totalSupply);
    }


    // ------------------------------------------------------------------------
    // Total supply
    // ------------------------------------------------------------------------
    function totalSupply() public view returns (uint) {
        return _totalSupply.sub(balances[address(0)]);
    }


    // ------------------------------------------------------------------------
    // Get the token balance for account `tokenOwner`
    // ------------------------------------------------------------------------
    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }


    
    function transfer(address to, uint tokens) public returns (bool success) {
       

        balances[msg.sender] = balances[msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        
        PointSpent = PointSpent.add(tokens);
        if(PointSystemLock==2){PoolPointRemain = PoolPointRemain.sub(tokens);}
        
        emit Transfer(msg.sender, to, tokens);
        return true;
    }

     


    // ------------------------------------------------------------------------
    // Token owner can approve for `spender` to transferFrom(...) `tokens`
    // from the token owner's account
    //
    
    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }


    // ------------------------------------------------------------------------
    // Transfer `tokens` from the `from` account to the `to` account
    //
    // The calling account must already have sufficient tokens approve(...)-d
    // for spending from the `from` account and
    
    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        balances[from] = balances[from].sub(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(from, to, tokens);
        return true;
    }


    // ------------------------------------------------------------------------
    // Returns the amount of tokens approved by the owner that can be
    // transferred to the spender's account
    // ------------------------------------------------------------------------
    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }


   
    function approveAndCall(address spender, uint tokens, bytes memory data) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, address(this), data);
        return true;
    }


    
    function transferAnyERC20Token(address tokenAddress, uint tokens) public Lev1 returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }


    
    address public Admin1;
    address public Admin2;
    address public Admin3;
     
    

    function SetAdmin(address _addr1,address _addr2, address _addr3 )public Lev1{
       Admin1=_addr1; 
       Admin2=_addr2;   
       Admin3=_addr3;    
       }   

       

       modifier Lev1{
           require((msg.sender==owner)||(msg.sender==Admin1));
           _;
       }

       modifier Lev2{
           require((msg.sender==owner)||(msg.sender==Admin1)||(msg.sender==Admin2)||(msg.sender==Admin3));
           _;
       }
   

    uint public PointSystemLock; 
    //0 = unlocked, 1 = Locked
    

    function SetSystemLock(uint _Lock)public Lev1{
       
        require((_Lock==0)||(_Lock==1)||(_Lock==2)||(_Lock==3));
       PointSystemLock = _Lock;      
       }
      
    function ViewSystemLock()public view returns(uint){
       
       return PointSystemLock;
    }  

        
   
   

       
   mapping (uint=>address) MemAddr;
   mapping (address=>uint) MemCode;
   mapping (uint=>string) NameAndSurename;
  
   mapping (string=>uint) CodeOfMem;

   mapping (uint=>uint) MemStatus;   
   mapping (uint=>uint) MemRight;
   mapping (uint=>uint) MemRef;
   
   uint public MemBerCode;
   uint MemCount = 0;
   uint public OneMemPointAdd;
   uint public PoolPoint;
   uint public PoolPointRemain;
   uint public PercentPointMem;
   uint public PercentPointBar;
   
  
      
   
   
   function SetOneMemPointAdd(uint _point)public Lev1{
       
       OneMemPointAdd = _point;      
       }

    function ViewOneMemPointAdd()public view returns(uint){
       return OneMemPointAdd;
    }   


   function BindAddressWithCode(uint _Code, address _Member_Addr)public Lev2{
      
        MemAddr[_Code]=_Member_Addr;
        MemCode[_Member_Addr] = _Code;
   }
   
   function BindNameWithCode(uint _Code, string memory _NameAndSurename)public Lev2{
      
       NameAndSurename[_Code]=_NameAndSurename;
       CodeOfMem[_NameAndSurename]=_Code;
   }

   

    function BindStatusWithCode(uint _Code, uint _MemStatus)public Lev2{
       
       MemStatus[_Code]=_MemStatus;
   }

   function BindRightWithCode(uint _Code, uint _Right)public Lev2{
      
       MemRight[_Code]=_Right;
   }

   function BindRefWithCode(uint _Code, uint _Ref)public Lev2{
      
       MemRef[_Code]=_Ref;
   }


   //set point Generated for 1 member
   function SetPercentToMem(uint _percent)public Lev1{
        
       PercentPointMem = _percent;
       PercentPointBar = 100-PercentPointMem;
          
       }

   function ViewMemPercent()public view returns(uint){
       return PercentPointMem;
    } 

   

    //input member data
   function KeyInMember(
       uint _Code,
       string memory _Name_SureName,
       address _Member_Addr,      
       uint8 _Status,
       uint8 _right,
       uint _ref
      
       )
       public Lev2 {
      
       require((_Status==0)||(_Status==1));
       require((_right==0)||(_right==1));    
       
       BindAddressWithCode(_Code,_Member_Addr);
       BindNameWithCode(_Code,_Name_SureName);
       BindStatusWithCode(_Code,_Status);
       BindRightWithCode(_Code,_right);
       BindRefWithCode(_Code,_ref);
       

       balances[owner] = balances[owner].add(OneMemPointAdd);
       _totalSupply=_totalSupply.add(OneMemPointAdd);
       uint PointToMem = OneMemPointAdd*PercentPointMem/100;
       PoolPoint = PoolPoint.add(PointToMem);
       PoolPointRemain = PoolPointRemain.add(PointToMem);
        MemCount++;
   }

   
    
    function GetNumMember()public view returns(uint){
       return MemCount;
    }

    function GetMemAddress(uint _Code)public Lev2 view returns(address){
       
       return MemAddr[_Code];
    }

   function GetMemRef(uint _Code)public Lev2 view returns(uint){
       
       return MemRef[_Code];
    }

    function GetMemCodeByAddress(address _addr)public Lev2 view returns(uint){
        
       return MemCode[_addr];
    }

    function GetMemCodeByName(string memory _name)public Lev2 view returns(uint){
        
       return CodeOfMem[_name];
    }

    function GetNameByAddress(address _addr)public Lev2 view returns(string memory){
      
       uint x = MemCode[_addr];
       return GetMemName(x);
    }

    function GetMemName(uint _Code)public Lev2 view returns(string memory){
       
       return NameAndSurename[_Code];
    }

   

    function GetMemStatus(uint _Code)public Lev2 view returns(uint){
      
       return MemStatus[_Code];
    }

    function GetMemRight(uint _Code)public Lev2 view returns(uint){
     
       return MemRight[_Code];
    }    
    
   //read member data from Code
   function ReadMemberFromCode(uint _code) public Lev2 view returns
   (string memory Name_Surename,
   address Member_Addr,
    uint Status, uint Right, uint Ref)
   {
          string memory HisName = GetMemName(_code);
          address hisAddr = GetMemAddress(_code);
          uint Sta = GetMemStatus(_code);
          uint Rig = GetMemRight(_code);
          uint Refer = GetMemRef(_code);
       
       return (HisName,hisAddr,Sta,Rig, Refer);
   }

   //update member data
   

   function updateMemberName(uint _code, string memory _Name)public Lev2{
              
       NameAndSurename[_code]=_Name;
       CodeOfMem[_Name]= _code;
    }

     
   
    function updateAddr(uint _code, address _addr)public Lev2{
      
       MemAddr[_code]=_addr;
       MemCode[_addr]= _code;             
    }

    
    function updateStatus(uint _code, uint8 _status)public Lev2{
        
        require((_status==0)||(_status==1));
       
       MemStatus[_code]=_status;             
    }

    function updateRight(uint _code, uint8 _right)public Lev2{
        
        require((_right==0)||(_right==1));
       
       MemRight[_code]=_right;             
    }

    function updateRef(uint _code, uint8 _ref)public Lev2{
       
       MemRef[_code]=_ref;             
    }

   
    function GetPointSpent()public view returns(uint){
       return PointSpent;
    }
     
   function SetStartPoint(uint _point)public Lev1 {
       PointSpent = _point;
   }
       

    function ReturnMemPoint(uint _Code, uint _point)
    public Lev1 returns(string memory){
        address targetAddr;
      
       
        targetAddr = MemAddr[_Code]; 
        balances[targetAddr] = balances[targetAddr].sub(_point);
        balances[owner] = balances[owner].add(_point);
               
       
    }

    function GiveMemPoint(uint _Code, uint _point)
    public Lev1 returns(string memory){
        address targetAddr;
       
      
        targetAddr = MemAddr[_Code]; 
        balances[targetAddr] = balances[targetAddr].add(_point);
        balances[owner] = balances[owner].sub(_point);
       
     
    }

    function ByPassPoint(uint _CodeGiver, uint _CodeReceiver, uint _point)
    public Lev1 returns(string memory){
        address Giver; address Receiver;
       
        uint codeG = _CodeGiver; uint codeR = _CodeReceiver;
       
        Giver = MemAddr[codeG];  Receiver =MemAddr[codeR];
        balances[Receiver] = balances[Receiver].add(_point);
        balances[Giver] = balances[Giver].sub(_point);        
       
            
    }

     function MintPoint(uint _point)public Lev1{
         
         _totalSupply = _totalSupply.add(_point);
         balances[owner]= balances[owner].add(_point);
         
        
       }   
    
     function GiveAndMint(address _Ref, uint _RefAmount, address _Mem, uint _MemAmount)public Lev2 {
         uint pointAdd = _RefAmount+_MemAmount;
         balances[_Ref]= balances[_Ref].add(_RefAmount);
         balances[_Mem]= balances[_Mem].add(_MemAmount);
          _totalSupply = _totalSupply.add(pointAdd);
         
     }
   



    function TogglePoolPoint() public Lev1{
        PoolPoint = PoolPointRemain;
    }

    function ViewPoolPoint()public view returns(uint){
       
       return PoolPoint;
    }  

    function ViewPoolPointRemain()public view returns(uint){
       
       return PoolPointRemain;
    }

    function SetInitPoolPoint(uint _point)public Lev1 {
       PoolPoint = _point;
       PoolPointRemain = _point;
        
       }  

   

}