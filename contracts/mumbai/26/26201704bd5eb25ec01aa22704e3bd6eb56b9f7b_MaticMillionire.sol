/**
 *Submitted for verification at polygonscan.com on 2022-08-26
*/

pragma solidity 0.5.10; 



contract owned
{
    address internal owner;
    address internal newOwner;
    address public signer;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
        signer = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }


    modifier onlySigner {
        require(msg.sender == signer, 'caller must be signer');
        _;
    }


    function changeSigner(address _signer) public onlyOwner {
        signer = _signer;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }

    //the reason for this flow is to protect owners from sending ownership to unintended address due to human error
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

//*******************************************************************//
//------------------         token interface        -------------------//
//*******************************************************************//

 interface tokenInterface
 {
    function transfer(address _to, uint256 _amount) external;
    function transferFrom(address _from, address _to, uint256 _amount) external;
 }


 interface ERC20In{

    function transfer(address _to, uint256 _amount) external returns (bool);
    function transferFrom(address _from, address _to, uint256 _amount) external returns(bool);

 }
 



contract MaticMillionire is owned {


// Replace below address with main token token
    address public tokenAddress;
    address  defaultAddress;
    struct sysInfo{
        uint joinPrice;
        uint poolPrice;
        uint withfee;
        uint p2Xtime;
        uint8 p2Xlimit;
    }
    sysInfo public sysInfos ;
    
    bool isContractPaused= false;
    bool USDT_INTERFACE_ENABLE;
	
   

    struct userInfo {
        bool joined;
        address referral;
        uint256  limitWith;
        uint256  withdrawn;
        uint256  poolTime;
        uint8 poolLimit;
        bool isBlocked;
    }
    mapping (address => userInfo) public userInfos;


    constructor(address _defaultAddress ) public {
       

    // default user 

        userInfos[_defaultAddress].joined=true;
        userInfos[_defaultAddress].referral=defaultAddress;

         emit regUserEv(_defaultAddress, _defaultAddress);

        
    }


     // user registration 

     function payRegUser( address _referral ) external returns(bool) 
    {
       regUser(_referral);
       investUser();
      
        return true;
    }
    
    
    event regUserEv(address user, address referral);
    function regUser( address _referral ) public returns(bool) 
    {
        require(isContractPaused==false,"contract is locked");
        require(userInfos[msg.sender].joined==false,"you are blocked");
        if (_referral==address(0) || userInfos[_referral].joined==false){
            _referral= defaultAddress;
        }
        userInfos[msg.sender].joined=true;
        userInfos[msg.sender].referral=_referral;
        emit regUserEv(msg.sender, _referral);
        return true;
    }

    

    // invest user
    event investEv(address user, uint amount);

    function investUser() public returns(bool) {
       
        require(userInfos[msg.sender].joined==true && userInfos[msg.sender].isBlocked==false,"invalid user or block");
		userInfos[msg.sender].limitWith += (sysInfos.joinPrice*3);
        if (userInfos[msg.sender].poolTime==0){
             userInfos[msg.sender].poolTime = sysInfos.p2Xtime+now;
        }
         
        if(USDT_INTERFACE_ENABLE==true){
            tokenInterface(tokenAddress).transferFrom(msg.sender, address(this), sysInfos.joinPrice);
        }else{
            ERC20In(tokenAddress).transferFrom(msg.sender, address(this), sysInfos.joinPrice);
        }

        emit investEv(msg.sender,sysInfos.joinPrice);
        return true;

    }
      //  invest user by internal fund
    event reInvestEv(address user, uint amount);
    function reinvest(address _user, uint investTime) external onlySigner returns(bool) {
        require(userInfos[msg.sender].joined==true && userInfos[msg.sender].isBlocked==false,"invalid user or block");
        
        uint investamount =  investTime*sysInfos.joinPrice;
		userInfos[_user].limitWith += investamount*2;

        emit reInvestEv(_user,investamount);
        return true;

    }

     // Global pool 2X user

    event pool_2X_EV(address user, uint amount);

    function buyPool_2X() public returns(bool) {
       
        require(userInfos[msg.sender].joined==true && userInfos[msg.sender].isBlocked==false,"invalid user or block");
        
        if (userInfos[msg.sender].poolTime < now){

            userInfos[msg.sender].poolTime = sysInfos.p2Xtime+now;
            userInfos[msg.sender].poolLimit = 1;
             if(USDT_INTERFACE_ENABLE==true){
            tokenInterface(tokenAddress).transferFrom(msg.sender, address(this), sysInfos.poolPrice);
               }else{
            ERC20In(tokenAddress).transferFrom(msg.sender, address(this), sysInfos.poolPrice);
        }

        emit pool_2X_EV(msg.sender,sysInfos.poolPrice);

        } 
        else{
        require(userInfos[msg.sender].poolLimit < sysInfos.p2Xlimit,"Your pool limit is expire");
        userInfos[msg.sender].poolLimit++;

        if(USDT_INTERFACE_ENABLE==true){
            tokenInterface(tokenAddress).transferFrom(msg.sender, address(this), sysInfos.poolPrice);
        }else{
            ERC20In(tokenAddress).transferFrom(msg.sender, address(this), sysInfos.poolPrice);
        }

        emit pool_2X_EV(msg.sender,sysInfos.poolPrice);
        }
        return true;

    }

    // Global pool 2X user internal fund
    event repool_2X_Ev(address user, uint amount);
    function rePool2X(address _user,uint8 xTime) external onlySigner returns(bool) {
        require(userInfos[_user].joined==true && userInfos[msg.sender].isBlocked==false,"invalid user or block");
        require(userInfos[_user].limitWith >= xTime*sysInfos.poolPrice ,"user limit is exuast");
        require(xTime != 0 && xTime <= sysInfos.p2Xlimit ,"invalid _xtime data");

        
        if (userInfos[_user].poolTime<now){

            userInfos[_user].poolTime = (sysInfos.p2Xtime+now);
            userInfos[_user].poolLimit = xTime;
            userInfos[_user].withdrawn+= xTime*sysInfos.poolPrice;
             if(USDT_INTERFACE_ENABLE==true){
            tokenInterface(tokenAddress).transferFrom(_user, address(this), xTime*sysInfos.poolPrice);
                }
               else{
            ERC20In(tokenAddress).transferFrom(_user, address(this), xTime*sysInfos.poolPrice);
                }

        emit pool_2X_EV(_user,xTime*sysInfos.poolPrice);

        }
        else{
       
        require(userInfos[_user].poolLimit != sysInfos.p2Xlimit ,"Your pool limit is expire");
        uint8 xLimit;
        if (userInfos[_user].poolLimit < xTime){
            xLimit = xTime-userInfos[_user].poolLimit;
        }
        else{
             xLimit = xTime;
        }
        userInfos[_user].poolLimit+=xLimit;
        userInfos[_user].withdrawn+= xLimit*sysInfos.poolPrice;
        if(USDT_INTERFACE_ENABLE==true){
            tokenInterface(tokenAddress).transferFrom(msg.sender, address(this), xLimit*sysInfos.poolPrice);
        }else{
            ERC20In(tokenAddress).transferFrom(msg.sender, address(this), xLimit*sysInfos.poolPrice);
        }

        emit pool_2X_EV(msg.sender,sysInfos.poolPrice);
        }
        return true;


    }

    // fallback function

    function () payable external {
       
    }
    

    //  withdraw
    event withdrawEv(address user, uint _amount);
    function withdrawMyGain(address _user, uint _amount) external onlySigner returns(bool) {


        require(isContractPaused==false,"contract is locked by owner");
        require(userInfos[_user].joined==true && userInfos[msg.sender].isBlocked==false,"invalid user or block");
        require(sysInfos.withfee<_amount,"wwithdrwal amount is to low");
        
        uint fullAmount;
        if (userInfos[_user].limitWith >=_amount){
            fullAmount = _amount; 
        }
        else {
            fullAmount = userInfos[_user].limitWith;  
        }
        userInfos[_user].withdrawn+=fullAmount;

        if(USDT_INTERFACE_ENABLE==true){

                tokenInterface(tokenAddress).transfer(msg.sender, fullAmount-sysInfos.withfee);

            }else{

                ERC20In(tokenAddress).transfer(msg.sender, fullAmount-sysInfos.withfee);
            } 
        
        userInfos[_user].limitWith-=fullAmount;
        emit withdrawEv(_user,_amount);

        return true;

    }
	



//-------------------------------ADMIN CALLER FUNCTION -----------------------------------



   function changeUserAddress(address oldUserAddress, address newUserAddress) external onlyOwner returns(bool){

   userInfos[newUserAddress] = userInfos[oldUserAddress];
        
        
        userInfo memory UserInfo;
            UserInfo = userInfo({
            joined:false,
            referral:address(0),
            limitWith:0,
            withdrawn:0,
            poolTime:0,
            poolLimit:0,
            isBlocked:false

         });
        
        userInfos[oldUserAddress] = UserInfo;
        
        return true;    
    }


    function setPrams(uint joinAmount, uint poolAmount, uint withdrwalFee, uint setPoolTime, uint8 setPoolLimit) external onlyOwner returns(bool){

		sysInfos.joinPrice= joinAmount;
        sysInfos.poolPrice= poolAmount;
        sysInfos.withfee= withdrwalFee;
		sysInfos.p2Xtime= setPoolTime;
        sysInfos.p2Xlimit= setPoolLimit;
        return true;
    }

 

    function blockUser(address _user) external onlyOwner returns(bool){

        require(userInfos[_user].isBlocked==false,"user is already block ");
        userInfos[_user].isBlocked=true;

        return true;
    }

    function unblockUser(address _user) external onlyOwner returns(bool){
        require(userInfos[_user].isBlocked==true,"user is already unblock");
        userInfos[_user].isBlocked=false;

        return true;
    }



    function lockContract() external onlyOwner returns(bool){

        isContractPaused=!isContractPaused;

        return true;

    }


}