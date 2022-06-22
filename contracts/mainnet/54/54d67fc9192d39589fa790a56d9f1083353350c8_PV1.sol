/**
 *Submitted for verification at polygonscan.com on 2022-06-22
*/

pragma solidity ^0.5.14;
//pragma experimental ABIEncoderV2;


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
    address payable public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address payable _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}


// ----------------------------------------------------------------------------
// ERC20 Token, with the addition of symbol, name and decimals and a
// fixed supply
// ----------------------------------------------------------------------------
contract PV1 is ERC20Interface, Owned {
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
        symbol = "pola";
        name = "POLA Token V1";
        decimals = 3;
        _totalSupply = 230000000 * 10**uint(decimals);
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


    // ------------------------------------------------------------------------
    // Transfer the balance from token owner's account to `to` account
    // - Owner's account must have sufficient balance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function transfer(address to, uint tokens) public returns (bool success) {
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        PointSpent = PointSpent.add(tokens);
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


    // ------------------------------------------------------------------------
    // Don't accept ETH
    // ------------------------------------------------------------------------
    //function () external payable {
      //  revert();
    //}


    // ------------------------------------------------------------------------
    // Owner can transfer out any accidentally sent ERC20 tokens
    // ------------------------------------------------------------------------
    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }
    
    address public Admin1;
    address public Admin2;
     
    function SetAdmin1(address _addr)public onlyOwner{
       Admin1=_addr;       
       }

    function SetAdmin2(address _addr)public onlyOwner{
       Admin2=_addr;       
       }   
   

    

 
   struct Member{
        uint Code;
        string Name_SureName;
        uint16 CitizenID;
        string Tel;
        address Member_Addr;
        uint ReferCode;
        uint8 Status; //0 = free applied, 1= paid applied

   }

   Member[] public members;
   
   mapping (uint=>address) MemAddr;
   mapping (uint=>string) NameAndSurename;
   mapping (uint=>uint) Referer;
   mapping (uint=>uint) MemStatus;
   uint public MemBerCode;
   uint MemCount = 0;
   uint public OneMemPointAdd;
   uint public PoolPoint;
   uint public PercentPointMem;
   uint public PercentPointBar;
   uint public MinBigPoint;

   
   function SetMinBigPoint(uint _bigpoint)public onlyOwner returns(uint){
       MinBigPoint = _bigpoint;      
       }

   function ViewMinBigPoint()public view returns(uint){
       return MinBigPoint;
    }     

   function SetPoolPoint(uint _point)public onlyOwner returns(uint){
       PoolPoint = _point;      
       }

   function ViewPoolPoint()public view returns(uint){
       return PoolPoint;
    }     

   function SetPercentToMem(uint _percent)public onlyOwner returns(uint){
       PercentPointMem = _percent;
       PercentPointBar = 100-PercentPointMem;
       return PercentPointMem;         
       }

   function ViewMemPercent()public view returns(uint){
       return PercentPointMem;
    } 

    function ViewBarPercent()public view returns(uint){
       return PercentPointBar;
    } 

   function SetOneMemPointAdd(uint _point)public onlyOwner returns(uint){
       OneMemPointAdd = _point;      
       }

    function ViewOneMemPointAdd()public view returns(uint){
       return OneMemPointAdd;
    }   


   function BindAddressWithCode(uint _Code, address _Member_Addr)public{
       require((msg.sender==owner)||(msg.sender==Admin1)||(msg.sender==Admin2));
        MemAddr[_Code]=_Member_Addr;
   }
   
   function BindNameWithCode(uint _Code, string memory _NameAndSurename)public{
       require((msg.sender==owner)||(msg.sender==Admin1)||(msg.sender==Admin2));
       NameAndSurename[_Code]=_NameAndSurename;
   }

   function BindRefererWithCode(uint _Code, uint _Referer)public{
       require((msg.sender==owner)||(msg.sender==Admin1)||(msg.sender==Admin2));
       Referer[_Code]=_Referer;
   }

   function BindStatusWithCode(uint _Code, uint _MemStatus)public{
       require((msg.sender==owner)||(msg.sender==Admin1)||(msg.sender==Admin2));
       MemStatus[_Code]=_MemStatus;
   }

    //input member data
   function KeyInMember(
       uint _Code,
       string memory _Name_SureName,
       uint16 _CitizenID,
       string memory _Tel,
       address _Member_Addr,
       uint _ReferCode,
       uint8 _Status)
       public {
       require((msg.sender==owner)||(msg.sender==Admin1)||(msg.sender==Admin2));    
       members.push(Member(_Code,_Name_SureName,_CitizenID,_Tel, _Member_Addr,_ReferCode,_Status));
       BindAddressWithCode(_Code,_Member_Addr);
       BindNameWithCode(_Code,_Name_SureName);
       BindRefererWithCode(_Code,_ReferCode);
       BindStatusWithCode(_Code,_Status);
       balances[owner] = balances[owner].add(OneMemPointAdd);
       _totalSupply=_totalSupply.add(OneMemPointAdd);
       uint PointToMem = OneMemPointAdd*PercentPointMem/100;
       PoolPoint = PoolPoint.add(PointToMem);
        MemCount++;
   }

   function GetMemberCodebyOrder(uint _index)public view returns(uint){
       require((msg.sender==owner)||(msg.sender==Admin1)||(msg.sender==Admin2));
       Member storage member=members[_index];
       uint x = member.Code;
       return x;
    }
    
    function GetNumMember()public view returns(uint){
       return MemCount;
    }

    function GetMemAddress(uint _Code)public view returns(address){
        require((msg.sender==owner)||(msg.sender==Admin1)||(msg.sender==Admin2));
       return MemAddr[_Code];
    }

    function GetMemName(uint _Code)public view returns(string memory){
        require((msg.sender==owner)||(msg.sender==Admin1)||(msg.sender==Admin2));
       return NameAndSurename[_Code];
    }
    
    function GetMemReferer(uint _Code)public view returns(uint){
        require((msg.sender==owner)||(msg.sender==Admin1)||(msg.sender==Admin2));
       return Referer[_Code];
    }
    
    
   //read member data from Order
   function ReadMemberFromOrder(uint _index) public view returns
   (uint Code,string memory Name_Surename,
   uint16 CitizenID,string memory Tel, address Member_Addr,
   uint ReferCode, uint8 Status)
   {
       require((msg.sender==owner)||(msg.sender==Admin1)||(msg.sender==Admin2));
       Member storage member=members[_index];
       return (member.Code,member.Name_SureName,member.CitizenID,
       member.Tel,member.Member_Addr,member.ReferCode,member.Status);
   }

   //update member data
   function updateMemberCode(uint _index, uint _Code)public {
       require((msg.sender==owner)||(msg.sender==Admin1)||(msg.sender==Admin2));
       Member storage member=members[_index];
       member.Code = _Code;
   }

   function updateMemberName(uint _index, string memory _Name)public{
       require((msg.sender==owner)||(msg.sender==Admin1)||(msg.sender==Admin2));
       Member storage member=members[_index];
       member.Name_SureName = _Name;
       uint _x = member.Code;
       NameAndSurename[_x]=_Name;
    }

   function updateCitizenID(uint _index, uint16 _ID)public{
       require((msg.sender==owner)||(msg.sender==Admin1)||(msg.sender==Admin2));
       Member storage member=members[_index];
       member.CitizenID = _ID;
             
    }

    function updateTel(uint _index, string memory _tel)public{
        require((msg.sender==owner)||(msg.sender==Admin1)||(msg.sender==Admin2));
       Member storage member=members[_index];
       member.Tel = _tel;             
    }

    function updateAddr(uint _index, address _addr)public{
        require((msg.sender==owner)||(msg.sender==Admin1)||(msg.sender==Admin2));
       Member storage member=members[_index];
       member.Member_Addr = _addr;
       uint _x = member.Code;
       MemAddr[_x]=_addr;             
    }

    function updateReferer(uint _index, uint _referer)public{
        require((msg.sender==owner)||(msg.sender==Admin1)||(msg.sender==Admin2));
       Member storage member=members[_index];
       member.ReferCode = _referer;
       uint _x = member.Code;
       Referer[_x]=_referer;             
    }

    function updateStatus(uint _index, uint8 _status)public{
        require((msg.sender==owner)||(msg.sender==Admin1)||(msg.sender==Admin2));
       Member storage member=members[_index];
       member.Status = _status;
       uint _x = member.Code;
       MemStatus[_x]=_status;             
    }
   
    function GetPointSpent()public view returns(uint){
       return PointSpent;
    }
     
   function SetStartPoint(uint _point, string memory _note)public onlyOwner returns
   (uint,string memory){
       PointSpent = _point;
       string memory Reason = _note; 
       return(PointSpent, Reason) ;     
       }

    function ReturnMemPoint(uint _Code, uint _point, string memory _note)
    public onlyOwner returns(uint, address, uint, string memory){
        address targetAddr;
        string memory Reasons = _note;
        uint code = _Code;
        uint p    = _point;
        targetAddr = MemAddr[_Code]; 
        balances[targetAddr] = balances[targetAddr].sub(_point);
        balances[owner] = balances[owner].add(_point);
               
        return (code, targetAddr, p, Reasons);        
    }

    function GiveMemPoint(uint _Code, uint _point, string memory _note)
    public onlyOwner returns(uint, address, uint, string memory){
        address targetAddr;
        string memory Reasons = _note;
        uint code = _Code;
        uint p    = _point;
        targetAddr = MemAddr[_Code]; 
        balances[targetAddr] = balances[targetAddr].add(_point);
        balances[owner] = balances[owner].sub(_point);
       
        return (code, targetAddr, p, Reasons);        
    }

    function ByPassPoint(uint _CodeGiver, uint _CodeReceiver, uint _point, string memory _note)
    public onlyOwner returns(uint, address, uint,address, uint, string memory){
        address Giver; address Receiver;
        string memory Reasons = _note;
        uint codeG = _CodeGiver; uint codeR = _CodeReceiver;
        uint p    = _point;
        Giver = MemAddr[codeG];  Receiver =MemAddr[codeR];
        balances[Receiver] = balances[Receiver].add(_point);
        balances[Giver] = balances[Giver].sub(_point);        
       
        return (codeG,Giver,codeR, Receiver,p, Reasons);        
    }

     function MintPoint(uint _point, string memory _reasons)public onlyOwner returns(uint, string memory){
         uint pointMint = _point;
         _totalSupply = _totalSupply.add(_point);
         balances[owner]= balances[owner].add(_point);
         string memory reasons = _reasons;
         return(pointMint, reasons);
       }   
    
    

}