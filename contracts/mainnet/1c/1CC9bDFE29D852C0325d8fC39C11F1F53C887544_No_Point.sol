/**
 *Submitted for verification at polygonscan.com on 2023-04-22
*/

pragma solidity >0.6.0;


interface ERC20 {
 function transfer(address _to, uint _value) external returns (bool success);
 function transferFrom(address _from, address _to, uint _value) external returns (bool success);
}
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
}
contract Context {
    function _msgSender() internal view returns (address) {
        return msg.sender;
    }

    function _msgData() internal pure returns (bytes memory) {
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;
    address private temp_admin;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() public {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }
   function tempAdmin() public view returns (address) {
        return temp_admin;
    }
    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
     modifier onlyAdmin() {
        require(owner() == _msgSender() || tempAdmin() == _msgSender(), "Ownable: caller is not the owner and caller is not the tempAdmin");
        _;
    }

  

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        _transferOwnership(address(0));
    }
    function setTempAdmin(address _address) public onlyOwner {
        temp_admin = _address;
    }
    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

 
    function _transferOwnership(address newOwner) internal {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}
contract No_Point is Ownable{
     struct PointInfo{
         uint256 level;
         uint256 price;
         uint256 push_radio;
         uint256 indirect_radio;
         uint256 market_radio;
         uint256 sales;
      }  
       mapping(uint256 => PointInfo)public Points;
       address public USDT=0xc2132D05D31c914a87C6611C10748AEb04B58e8F;
       mapping(address => address)public Agents;
       address public ReceiveAddress=0x29467c7a59A7a8b59Bf343E17496C91EE8cDbC24;
       address[] public users;
       uint256 push_number = 12;
       mapping(address => uint256)public isbuy;
       mapping(address => uint256)public MemberLevel;
       mapping(address => uint256)public MySales;
       mapping(address => uint256)public frist;
       mapping(address => uint256)public second;
      constructor () public{
         
    }
    function SetAddress(address  _USDT,address _Receive)onlyAdmin public{
        USDT = _USDT;
        ReceiveAddress =  _Receive;
     }
       function SetPushNumber(uint256  _pushnumber)onlyAdmin public{
        push_number = _pushnumber;
     
     }
     function SetAgent(address _user,address _agent)onlyAdmin public{
          Agents[_user] = _agent;
     }
     function SetSales(address _user,uint256 _sales)onlyAdmin public{
         MySales[_user] = _sales;
     }
     
     function SetMemberLevel(address _user,uint256 _level,address _agent)onlyAdmin public{
          MemberLevel[_user] = _level;
          Agents[_user] = _agent;
     }
   
    
     function AddPoint(uint256 _level,uint256 _real_level,uint256 _price,uint256 _push_radio,uint256 _indirect_radio,uint256 _market_radio,uint256 _sales)onlyAdmin public{
         Points[_level].level = _real_level;
         Points[_level].price = _price;
         Points[_level].push_radio = _push_radio;
         Points[_level].indirect_radio = _indirect_radio;
         Points[_level].market_radio = _market_radio;
         Points[_level].sales = _sales;
     }
     function import_addresss(address[] memory _address,uint256[] memory _level,address[] memory _agent)onlyAdmin public{
              require(_address.length == _level.length && _address.length == _agent.length, "Invalid input");
              for(uint i;i<_address.length;i++){
                   MemberLevel[_address[i]] = _level[i];
                   Agents[_address[i]] = _agent[i];
              }
     }
     function BuyPoint(uint256 _level,address _agent)public{
         require(isbuy[msg.sender] == 0);
         require(Points[_level].price > 0);
         require(_agent != address(0x0));
         require(MemberLevel[_agent] > 0);
        //  require(Points[_level].level > 0);
        
         ERC20(USDT).transferFrom(msg.sender,address(this),Points[_level].price);
         Agents[msg.sender] = _agent;
         share_profit(Points[_level].price,msg.sender);
         if(Agents[msg.sender]  != address(0x0)){
             address parents = Agents[msg.sender];
             if(_level ==1){
                 frist[parents] = frist[parents] +1;
                MySales[parents] = MySales[parents] + 1;
                uint256 new_level = _level + 1;
               if(frist[parents] >= Points[new_level].sales){   
                 MemberLevel[parents]= new_level;
               }
             }
             if(_level == 2){
                  second[parents] = second[parents] +1;
                MySales[parents] = MySales[parents] + 1;
               uint256 new_level = _level + 1;
               if(second[parents] >= Points[new_level].sales){
                  
                 MemberLevel[parents]= new_level;
               }               
            }
         }
          

         users.push(msg.sender);
         MemberLevel[msg.sender]= _level;
         isbuy[msg.sender] = 1;
     }
     function share_profit(uint256 _amount,address _address)private{
    uint256 all_market = 0;
    uint256 already_profit=0;
       for(uint i;i< push_number;i++){
           address addr = Agents[_address];
           
           if(addr != address(0x0)){
             if(i== 0){
                 uint256 push_profit = _amount*Points[MemberLevel[addr]].push_radio/100;
                 if(push_profit > 0){
                     already_profit = already_profit+push_profit;
                     ERC20(USDT).transfer(addr,push_profit);
                 }
             }
             if(i== 1 && Points[MemberLevel[addr]].indirect_radio > 0){
                  uint256 indirect_profit = _amount*Points[MemberLevel[addr]].indirect_radio/100;
                 if(indirect_profit > 0){
                      already_profit = already_profit+indirect_profit;
                     ERC20(USDT).transfer(addr,indirect_profit);
                 }
             }

             if(Points[MemberLevel[addr]].market_radio > 0 && Points[MemberLevel[addr]].market_radio > all_market){
                 uint256 real_market =  Points[MemberLevel[addr]].market_radio - all_market;
                 all_market = real_market + all_market;
                    uint256 market_profit = _amount*real_market/100;
                 if(market_profit > 0){
                     already_profit = already_profit+market_profit;
                     ERC20(USDT).transfer(addr,market_profit);
                 }

             }
           }else{
               break;
           }
           _address = addr;
       }
       ERC20(USDT).transfer(ReceiveAddress,_amount-already_profit);
     }

     


}