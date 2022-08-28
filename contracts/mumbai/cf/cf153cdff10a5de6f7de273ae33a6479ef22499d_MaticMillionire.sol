/**
 *Submitted for verification at polygonscan.com on 2022-08-27
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



 //MultiSign---------------------------
 
    address[] public owners;
    mapping(address=>bool) public isOwner;

    uint public WalletRequired;
    Transaction[] public transactions;
    mapping(uint=> mapping(address=>bool)) public approved;


    struct Transaction{
      
        bool  isExecuted;
    }


        //-----------------------EVENTS-------------------

    event assignTrnx(uint trnx);
    event Approve(address owner, uint trnxId);
    event Revoke(address owner, uint trnxId);
    event Execute(uint trnxId);


// Replace below address with main token token
    address public tokenAddress;
    address  defaultAddress;
    struct sysInfo{
        uint joinPrice;   // join price / entry price
        uint poolPrice;  // pool entry price
        uint withdrawFee; // withdraw fee that is dedcut when you will proccess for withdraw.
        uint pool2Deadline; // this pool deadline time frame
        uint8 pool2Entrylimit; // number of entry you can take in pool within deadline.
    }
    sysInfo public sysInfos ;
    
    bool isContractPaused= false; // contract lock/unlock controll
    bool USDT_INTERFACE_ENABLE; // for switching Token standard
	
   

    struct userInfo {
        bool        joined;  // for checking user active/deactive status
        address     referral; // user sponser / ref 
        uint256     withdrawLimit; // user eligible limit that he can withdraw.
        uint256     totalWithdrawn;// user total fund he withdraw from system.
        uint256     poolTime;      //running pool time 
        uint8       poolLimit;     // eligible entry limit within pooltime.
        bool        isBlocked;      // user block status for admin
    }
    mapping (address => userInfo) public userInfos;


    constructor(address _defaultAddress ) public {
       

    // default user 

        userInfos[_defaultAddress].joined=true;
        userInfos[_defaultAddress].referral=_defaultAddress;

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
		
        userInfos[msg.sender].withdrawLimit += (sysInfos.joinPrice*3);

        if (userInfos[msg.sender].poolTime==0){

             userInfos[msg.sender].poolTime = sysInfos.pool2Deadline+now;
        }
         
        _transfer(msg.sender,address(this),sysInfos.joinPrice);

        emit investEv(msg.sender,sysInfos.joinPrice);
        return true;

    }
      //  invest user by internal fund
    event reInvestEv(address user, uint amount);
    function reinvest(address _user, uint investTime) external onlySigner returns(bool) {

        require(userInfos[_user].joined==true && userInfos[_user].isBlocked==false,"invalid user or block");
        
        uint investamount =  investTime*sysInfos.joinPrice;

		userInfos[_user].withdrawLimit += investamount*2;

        emit reInvestEv(_user,investamount);
        return true;

    }

     // Global pool 2X user

    event pool_2X_EV(address user, uint amount);

    function buyPool_2X() public returns(bool) {
       
        require((userInfos[msg.sender].poolLimit <= sysInfos.pool2Entrylimit && userInfos[msg.sender].poolTime < now) || (userInfos[msg.sender].poolLimit < sysInfos.pool2Entrylimit && userInfos[msg.sender].poolTime > now) ,"Your pool limit is expire");
       
        require(userInfos[msg.sender].joined==true && userInfos[msg.sender].isBlocked==false,"invalid user or block");
        
         _buyPool(msg.sender);

        return true;
    }

    // Global pool 2X user internal fund
    event repool_2X_Ev(address user, uint amount);
    //position means number of entry you want to take in pool.
    function rePool2X(address _user,uint8 _position) external onlySigner returns(bool) {
        require(userInfos[_user].joined==true && userInfos[_user].isBlocked==false,"invalid user or block");
        require(_position != 0 && _position <= sysInfos.pool2Entrylimit && _position>=userInfos[_user].poolLimit && userInfos[_user].poolLimit!=sysInfos.pool2Entrylimit ,"invalid _xtime data");
        require(userInfos[_user].withdrawLimit >= _position*sysInfos.poolPrice ,"user limit is exuast");
        require((userInfos[_user].poolLimit <= sysInfos.pool2Entrylimit && userInfos[_user].poolTime < now) || (userInfos[_user].poolLimit < sysInfos.pool2Entrylimit && userInfos[_user].poolTime > now) ,"Your pool limit is expire");
        
                
             _buyPool(_user,_position);
        

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
        require(sysInfos.withdrawFee<_amount,"withdrwal amount is to low");
        
        uint fullAmount;
        if (userInfos[_user].withdrawLimit >=_amount){
            fullAmount = _amount; 
        }
        else {
            fullAmount = userInfos[_user].withdrawLimit;  
        }
        userInfos[_user].totalWithdrawn+=fullAmount;


        _transfer(msg.sender,fullAmount-sysInfos.withdrawFee);
        
        userInfos[_user].withdrawLimit-=fullAmount;
        emit withdrawEv(_user,_amount);

        return true;

    }
	



//-------------------------------ADMIN CALLER FUNCTION -----------------------------------

  function imitMultsign(address[] calldata _owners,uint _requiredWallet)external onlyOwner returns (bool){

        //-------------------MUltiSign-------------------
        require(_owners.length>0,"owner required");
        require(owners.length==0,"owner required");
        require(_requiredWallet>0 && _requiredWallet<=_owners.length,"invalid required number of owner wallets");

        for(uint i=0;i<_owners.length;i++){

            address owner = _owners[i];
            require(owner!=address(0),"invalid owner");
            require(!isOwner[owner],"owner is already there!");
            isOwner[owner]=true;
            owners.push(owner);
        }

        WalletRequired =_requiredWallet; // you need at least this number wallet to execute transaction
        return true;
  }


   function changeUserAddress(address oldUserAddress, address newUserAddress) external onlyOwner returns(bool){

   userInfos[newUserAddress] = userInfos[oldUserAddress];
        
        
        userInfo memory UserInfo;
            UserInfo = userInfo({
            joined:false,
            referral:address(0),
            withdrawLimit:0,
            totalWithdrawn:0,
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
        sysInfos.withdrawFee= withdrwalFee;
		sysInfos.pool2Deadline= setPoolTime;
        sysInfos.pool2Entrylimit= setPoolLimit;
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


    //---------------------Internal/Optimized Function-----------------------------

    function _transfer(address _from, address _to,uint _amount) internal {

        require(_from!=address(0) && _to!=address(0) && _amount>0 ,"Invalid User or Amount");

        if(USDT_INTERFACE_ENABLE==true){

            tokenInterface(tokenAddress).transferFrom(_from, _to, _amount);
        }else{

            ERC20In(tokenAddress).transferFrom(_from, _to, _amount);
        }

    }


    function _transfer(address _to,uint _amount) internal {

        require(_to!=address(0) && _amount>0 ,"Invalid User or Amount");

        if(USDT_INTERFACE_ENABLE==true){

            tokenInterface(tokenAddress).transfer(_to, _amount);
        }else{

            ERC20In(tokenAddress).transfer(_to, _amount);
        }

    }


    function _buyPool(address _user)internal {

        if (userInfos[_user].poolTime < now){
            userInfos[_user].poolTime = sysInfos.pool2Deadline+now;
            userInfos[_user].poolLimit = 1;
        } 
        else{
            userInfos[_user].poolLimit++;
        }
            _transfer(_user,address(this),sysInfos.poolPrice);

            emit pool_2X_EV(msg.sender,sysInfos.poolPrice);
    }


    function _buyPool(address _user, uint8 _position)internal {

        if (userInfos[_user].poolTime < now){
            userInfos[_user].poolTime = sysInfos.pool2Deadline+now;
            userInfos[_user].poolLimit = _position;
            
        } 
        else{
             userInfos[_user].poolLimit+=_position;
        }

        userInfos[_user].totalWithdrawn+= _position*sysInfos.poolPrice;
            //_transfer(_user,address(this),sysInfos.poolPrice);

        emit pool_2X_EV(_user,_position*sysInfos.poolPrice);


    }





    //----------------------Modifier-------------------

    // YOU CAN REMOVE THIS OWNER MODIFIER IF YOU ALREADY USING OWNED LIB

    modifier trnxExists(uint _trnxId){
        require(_trnxId<transactions.length,"trnx does not exist");
        _;
    }

    modifier notApproved(uint _trnxId){

        require(!approved[_trnxId][msg.sender],"trnx has already done");
        _;
    }

    modifier notExecuted(uint _trnxId){
        Transaction storage _transactions = transactions[_trnxId];
        require(!_transactions.isExecuted,"trnx has already executed");
        _;
    }



 // ADD NEW TRANSACTION 

    function newTransaction() external onlyOwner returns(uint){


        transactions.push(Transaction({
            isExecuted:false
        }));

        emit assignTrnx(transactions.length-1);
        return transactions.length-1;
    }

    // APPROVE TRANSACTION BY ALL OWNER WALLET FOR EXECUTE CALL
    function approveTransaction(uint _trnxId)
     external onlyOwner
     trnxExists(_trnxId)
     notApproved(_trnxId)
     notExecuted(_trnxId)

    {

        approved[_trnxId][msg.sender]=true;
        emit Approve(msg.sender,_trnxId);

    }

    // GET APPROVAL COUNT OF TRANSACTION
    function _getAprrovalCount(uint _trnxId) public view returns(uint ){

        uint count;
        for(uint i=0; i<owners.length;i++){

            if (approved[_trnxId][owners[i]]){

                count+=1;
            }
        }

        return count;
     
    }

    // EXECUTE TRANSACTION 
    function executeTransaction(uint _trnxId) internal trnxExists(_trnxId) notExecuted(_trnxId){
        require(_getAprrovalCount(_trnxId)>=WalletRequired,"you don't have sufficient approval");
        Transaction storage _transactions = transactions[_trnxId];
        _transactions.isExecuted = true;
        emit Execute(_trnxId);

    }

    //----------------------THIS IS JUST TEST FUNCTION WE CAN REPLACE THIS FUNCTION TO ANY -- MULTIsIGN CALL FUNCTION--------
    function Transferfund(uint _trnxId) external onlyOwner {

        address(uint160(msg.sender)).transfer(address(this).balance);

        executeTransaction(_trnxId);

    }


    // USE THIS FUNCTION WITHDRAW/REJECT TRANSACTION
    function revoke(uint _trnxId) external
    onlyOwner
    trnxExists(_trnxId)
    notExecuted(_trnxId)
    {
        require(approved[_trnxId][msg.sender],"trnx has not been approve");
        approved[_trnxId][msg.sender]=false;

       emit Revoke(msg.sender,_trnxId);
    }


}