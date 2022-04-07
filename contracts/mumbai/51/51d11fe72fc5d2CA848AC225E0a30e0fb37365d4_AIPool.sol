/**
 *Submitted for verification at polygonscan.com on 2022-04-06
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface DateTime {
        function getYear(uint timestamp) external pure returns (uint16);
        function getMonth(uint timestamp) external pure returns (uint8);
        function getDay(uint timestamp) external pure returns (uint8);
        function toTimestamp(uint16 year, uint8 month, uint8 day, uint8 hour) external pure returns (uint);
}
interface ITradeBNB
{
   function totalAIPool(address user) external view returns(uint256);
   function userjointime(address user) external view returns(uint40);

}
interface IEACAggregatorProxy
{
    function latestAnswer() external view returns (uint256);
}
contract AIPool {
    string public name     = "AI Pool";
    address public TradeBNB ;
    bool public safeguard;  //putting safeguard on will halt all non-owner functions
    mapping (address => bool) public frozenAccount;
    event FrozenAccounts(address target, bool frozen);
    event  Withdrawal(address indexed src, uint256 wad, uint256 bnbval);
    event UserClaim(address indexed _user, uint256 amount, uint claimstarttime);
   event setPoolpercEv(uint16[] percs);
    mapping(address => bool) internal administrators;
    uint public adminfeeperc = 3;
    uint public minWithdraw = 5 * (10**18);
    struct user
    {
      uint256 withdrawble;
      uint256 totalwithdrawn;
      uint256 totalwithdrawnBNB;
      uint lastwithdraw;
    }
    uint16[] public poolperc=[180,250,770,960,510,620,390,630,540,630,250,230,850,630,870,280,640,460,750,640,690,510,210,150,660,890,360,830,620,230,360];

    mapping(address => user) public userInfo;
    address public terminal;
    address public EACAggregatorProxyAddress;
    DateTime public dateTime ;
    receive() external payable {
   }
    modifier onlyAdministrator(){
        address _customerAddress = msg.sender;
        require(administrators[_customerAddress],"Caller must be admin");
        _;
    }
    constructor(address _EACAggregatorProxyAddress,address dateTimeAddr)
    {
      administrators[msg.sender] = true;
      terminal = msg.sender;
      administrators[terminal] = true;
      //main -- 0x0567F2323251f0Aab15c8dFb1967E4e8A7D42aeE
      EACAggregatorProxyAddress = _EACAggregatorProxyAddress;
      //0x4eDdEeE8E95aD2b29b8032B79359e9bF25E98150 -- main
      dateTime = DateTime(dateTimeAddr);
    }
    function isContract(address _address) internal view returns (bool){
        uint32 size;
        assembly {
            size := extcodesize(_address)
        }
        return (size > 0);
    }
    function sendToOnlyExchangeContract(uint256 _amount) public onlyAdministrator returns(bool)
    {
        require(!isContract(msg.sender),  'No contract address allowed');
        require(address(this).balance >= _amount,'Insufficient Balance');
        payable(terminal).transfer(_amount);
        return true;
    }
    function changPoolPerc(uint16[] memory _setpoolperc) public onlyAdministrator returns(bool)
    {
        require(_setpoolperc.length == 31,'Values must be for 31 days');
        poolperc = _setpoolperc;
        emit setPoolpercEv(_setpoolperc);
        return true;
    }
    function changTradeBNB(address _TradeBNB) public onlyAdministrator returns(bool)
    {
        TradeBNB = _TradeBNB;
        return true;
    }
    function setAdminFeeForWithdraw(uint _adminfeeperc) public onlyAdministrator returns(bool)
    {
        adminfeeperc = _adminfeeperc;
        return true;
    }

    function getYear(uint bdate) view public returns (uint16){
      return dateTime.getYear(bdate);
    }
    function getMonth(uint bdate) view public returns (uint8){
        return dateTime.getMonth(bdate);
    }
    function getDay(uint bdate) view public returns (uint8){
        return dateTime.getDay(bdate);
    }

    function carry_fwd() public returns (bool) {
      require(!safeguard);
      require(!frozenAccount[msg.sender], "caller has been frozen");
      require(TradeBNB!=address(0),"Stake contract has not been set");
      uint256 userAITotal = ITradeBNB(TradeBNB).totalAIPool(msg.sender);
      require(userAITotal>0, "Invalid AI Pool trading");
      uint vcurdat = block.timestamp;
      uint userjoined =ITradeBNB(TradeBNB).userjointime(msg.sender);
      if(userInfo[msg.sender].lastwithdraw > 0)
      {
        userjoined = userInfo[msg.sender].lastwithdraw + 86400;
      }
      require(userjoined <= vcurdat ,"Invalid date for claim");
      uint8 vmonth=getMonth(vcurdat);
      uint8 vday=getDay(vcurdat);
      uint vstartday = 1 ;
      if(vmonth == getMonth(userjoined))
      {
        vstartday =getDay(userjoined);
      }
      for(uint i=vstartday; i <= vday;i++)
      {
        userInfo[msg.sender].withdrawble += userAITotal * poolperc[i - 1] / 100000;
      }

      userInfo[msg.sender].lastwithdraw = block.timestamp;
      emit UserClaim(msg.sender, userInfo[msg.sender].withdrawble, userjoined);
      return true;
    }
    function withdraw() public returns (bool) {
        require(!safeguard);
        require(!frozenAccount[msg.sender], "caller has been frozen");
        require(TradeBNB!=address(0),"Stake contract has not been set");
        uint256 userAITotal = ITradeBNB(TradeBNB).totalAIPool(msg.sender);
        require(userAITotal>0, "Invalid AI Pool trading");
        uint vcurdat = block.timestamp;
        uint userjoined =ITradeBNB(TradeBNB).userjointime(msg.sender);
        if(userInfo[msg.sender].lastwithdraw > 0)
        {
          userjoined = userInfo[msg.sender].lastwithdraw + 86400;
        }
        require(userjoined <= vcurdat  ,"Invalid date for claim");
        uint8 vmonth=getMonth(vcurdat);
        uint16 vyear=getYear(vcurdat);
        uint8 vday=getDay(vcurdat);
        uint256 amount;

        if(vyear == getYear(userjoined) && vmonth >= getMonth(userjoined))
        {
          uint vstartday = 1 ;
          if(vmonth == getMonth(userjoined))
          {
            vstartday =getDay(userjoined);
          }
          for(uint i=vstartday; i <= vday;i++)
          {
            amount += userAITotal * poolperc[i - 1] / 100000;
          }
        }
        if(vyear > getYear(userjoined))
        {
          for(uint i=1;i <= vday;i++)
          {
            amount += userAITotal * poolperc[i - 1] / 100000;
          }
        }

        require(userInfo[msg.sender].withdrawble + amount >= minWithdraw, "not reached withdraw limit");

        userInfo[msg.sender].lastwithdraw = block.timestamp;

        amount += userInfo[msg.sender].withdrawble;
        uint256 adminfee = amount * adminfeeperc / 100;
        uint256 userbalance = USDToBNB(amount - adminfee);
        adminfee =USDToBNB(adminfee);
        userInfo[msg.sender].withdrawble = 0;
        userInfo[msg.sender].totalwithdrawn += amount;
        userInfo[msg.sender].totalwithdrawnBNB += userbalance + adminfee;
        payable(msg.sender).transfer(userbalance);
        payable(terminal).transfer(adminfee);
        emit Withdrawal(msg.sender, amount , userbalance + adminfee) ;


        return true;
    }

    struct user1
    {
      uint joiningtime;
      uint256 totalaibus;
      uint lastwithdraw;
    }
    mapping(address => user1) public usertests;
    function setuser(address _user, uint joiningtime, uint256 totalaibus, uint lastWithdraw) public
    {
      usertests[_user].joiningtime =joiningtime;
      usertests[_user].totalaibus =totalaibus;
      userInfo[_user].lastwithdraw = lastWithdraw;
    }
    /*function withdrawtest(uint vcurdat) public returns (bool) {
        require(!safeguard);
        require(!frozenAccount[msg.sender], "caller has been frozen");
        //require(TradeBNB!=address(0),"Stake contract has not been set");
        uint256 userAITotal = usertests[msg.sender].totalaibus;// ITradeBNB(TradeBNB).totalAIPool(msg.sender);
        require(userAITotal>0, "Invalid AI Pool trading");
       // uint vcurdat = block.timestamp;
        uint lastWithdrawtime= userInfo[msg.sender].lastwithdraw + 86400;
        uint userjoined =usertests[msg.sender].joiningtime ;//ITradeBNB(TradeBNB).userjointime(msg.sender);
        require(userjoined <= vcurdat && lastWithdrawtime <= vcurdat ,'Invalid date for claim');
        uint8 vmonth=getMonth(vcurdat);
        uint16 vyear=getYear(vcurdat);
        uint8 vday=getDay(vcurdat);
        uint256 amount;
        if(userInfo[msg.sender].lastwithdraw==0){
          if(vyear == getYear(userjoined) && vmonth==getMonth(userjoined))
          {
            for(uint i=getDay(userjoined);i <= vday;i++)
            {
              userInfo[msg.sender].withdrawble += userAITotal * poolperc[i - 1] / 100000;
            }
          }
        }
        if(vyear == getYear(lastWithdrawtime) && vmonth >= getMonth(lastWithdrawtime))
        {
          uint vstartday = 1 ;
          if(vmonth == getMonth(lastWithdrawtime))
          {
            vstartday =getDay(lastWithdrawtime);
          }
          for(uint i=vstartday;i <= vday;i++)
          {
            amount += userAITotal * poolperc[i - 1] / 100000;
          }
        }
        if(vyear > getYear(lastWithdrawtime))
        {
          for(uint i=1;i <= vday;i++)
          {
            amount += userAITotal * poolperc[i - 1] / 100000;
          }
        }
        bool iswithdraw ;

        if(vyear >= getYear(userjoined) && vmonth>getMonth(userjoined))
        {
          require(userInfo[msg.sender].withdrawble + amount >= minWithdraw, "not reached withdraw limit");
          iswithdraw =true;
        }
        else
        {
          if(userInfo[msg.sender].withdrawble >= minWithdraw)
          {
            iswithdraw =true;
          }
        }
        userInfo[msg.sender].lastwithdraw = vcurdat;
        if(iswithdraw ==true){
          amount += userInfo[msg.sender].withdrawble;
          uint256 adminfee = amount * adminfeeperc / 100;
          uint256 userbalance = USDToBNB(amount - adminfee);
          adminfee =USDToBNB(adminfee);
          userInfo[msg.sender].withdrawble = 0;
          userInfo[msg.sender].totalwithdrawn += amount;
          userInfo[msg.sender].totalwithdrawnBNB += userbalance + adminfee;
          payable(msg.sender).transfer(userbalance);
          payable(terminal).transfer(adminfee);
          emit Withdrawal(msg.sender, amount , userbalance + adminfee) ;
        }

        return true;
    }*/
    function carry_fwd_test(uint vcurdat) public returns (bool) {
      require(!safeguard);
      require(!frozenAccount[msg.sender], "caller has been frozen");
      //require(TradeBNB!=address(0),"Stake contract has not been set");
      uint256 userAITotal = usertests[msg.sender].totalaibus;// ITradeBNB(TradeBNB).totalAIPool(msg.sender);
      require(userAITotal>0, "Invalid AI Pool trading");
      //uint vcurdat = block.timestamp;
      uint userjoined = usertests[msg.sender].joiningtime ;//ITradeBNB(TradeBNB).userjointime(msg.sender);
      if(userInfo[msg.sender].lastwithdraw > 0)
      {
        userjoined = userInfo[msg.sender].lastwithdraw + 86400;
      }
      require(userjoined <= vcurdat ,"Invalid date for claim");
      uint8 vmonth=getMonth(vcurdat);
      uint8 vday=getDay(vcurdat);
      //require(vyear == getYear(userjoined) && vmonth==getMonth(userjoined),"Carry forwarding is for current month only");
      uint vstartday = 1 ;
      if(vmonth == getMonth(userjoined))
      {
        vstartday =getDay(userjoined);
      }
      for(uint i=vstartday; i <= vday;i++)
      {
        userInfo[msg.sender].withdrawble += userAITotal * poolperc[i - 1] / 100000;
      }
      userInfo[msg.sender].lastwithdraw = vcurdat;
      emit UserClaim(msg.sender, userInfo[msg.sender].withdrawble, userjoined);
      return true;
    }
    function withdrawtest(uint vcurdat) public returns (bool) {
        require(!safeguard);
        require(!frozenAccount[msg.sender], "caller has been frozen");
        //require(TradeBNB!=address(0),"Stake contract has not been set");
        uint256 userAITotal = usertests[msg.sender].totalaibus;// ITradeBNB(TradeBNB).totalAIPool(msg.sender);
        require(userAITotal>0, "Invalid AI Pool trading");
       // uint vcurdat = block.timestamp;
        uint userjoined = usertests[msg.sender].joiningtime ;// ITradeBNB(TradeBNB).userjointime(msg.sender);
        if(userInfo[msg.sender].lastwithdraw > 0)
        {
          userjoined = userInfo[msg.sender].lastwithdraw + 86400;
        }
        require(userjoined <= vcurdat  ,"Invalid date for claim");
        uint8 vmonth=getMonth(vcurdat);
        uint16 vyear=getYear(vcurdat);
        uint8 vday=getDay(vcurdat);
        uint256 amount;

        if(vyear == getYear(userjoined) && vmonth >= getMonth(userjoined))
        {
          uint vstartday = 1 ;
          if(vmonth == getMonth(userjoined))
          {
            vstartday =getDay(userjoined);
          }
          for(uint i=vstartday; i <= vday;i++)
          {
            amount += userAITotal * poolperc[i - 1] / 100000;
          }
        }
        if(vyear > getYear(userjoined))
        {
          for(uint i=1;i <= vday;i++)
          {
            amount += userAITotal * poolperc[i - 1] / 100000;
          }
        }

        require(userInfo[msg.sender].withdrawble + amount >= minWithdraw, "not reached withdraw limit");

        userInfo[msg.sender].lastwithdraw = vcurdat;

        amount += userInfo[msg.sender].withdrawble;
        uint256 adminfee = amount * adminfeeperc / 100;
        uint256 userbalance = USDToBNB(amount - adminfee);
        adminfee =USDToBNB(adminfee);
        userInfo[msg.sender].withdrawble = 0;
        userInfo[msg.sender].totalwithdrawn += amount;
        userInfo[msg.sender].totalwithdrawnBNB += userbalance + adminfee;
        payable(msg.sender).transfer(userbalance);
        payable(terminal).transfer(adminfee);
        emit Withdrawal(msg.sender, amount , userbalance + adminfee) ;


        return true;
    }
    function destruct() onlyAdministrator() public{
        selfdestruct(payable(terminal));
    }
    function BNBToUSD(uint bnbAmount) public view returns(uint)
    {
        uint256  bnbpreice = IEACAggregatorProxy(EACAggregatorProxyAddress).latestAnswer();
        return bnbAmount * bnbpreice * (10 ** 10) / (10 ** 18);
        //return bnbAmount * 423;
    }
    function USDToBNB(uint busdAmount) public view returns(uint)
    {
        uint256  bnbpreice = IEACAggregatorProxy(EACAggregatorProxyAddress).latestAnswer();
        return busdAmount  / bnbpreice * (10 ** 8);
        //return busdAmount/423;
    }
    /**
        * Change safeguard status on or off
        *
        * When safeguard is true, then all the non-owner functions will stop working.
        * When safeguard is false, then all the functions will resume working back again!
        */
    function changeSafeguardStatus() onlyAdministrator public{
        if (safeguard == false){
            safeguard = true;
        }
        else{
            safeguard = false;
        }
    }
    function freezeAccount(address target, bool freeze) onlyAdministrator public {
        frozenAccount[target] = freeze;
        emit  FrozenAccounts(target, freeze);
    }
    function setterminal(address _terminal) public  onlyAdministrator returns(bool)
    {
        administrators[terminal] = false;
        terminal = _terminal;
        administrators[terminal] = true;
        return true;
    }
    function setMinWithdraw(uint _minWithdraw) public onlyAdministrator returns(bool)
    {
        minWithdraw = _minWithdraw * (10 ** 18);
        return true;
    }
}