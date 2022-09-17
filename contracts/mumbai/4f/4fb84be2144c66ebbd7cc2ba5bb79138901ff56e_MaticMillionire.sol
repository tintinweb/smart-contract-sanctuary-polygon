/**
 *Submitted for verification at polygonscan.com on 2022-09-16
*/

/**
 *Submitted for verification at polygonscan.com on 2022-09-14
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
        uint256     creditFund;    //transfer fund from other user.
        uint256     poolTime;      //running pool time 
        uint8       poolLimit;     // eligible entry limit within pooltime.
        bool        isBlocked;      // user block status for admin
    }
    mapping (address => userInfo) public userInfos;


    constructor(address _defaultAddress , address _defaultRef) public {
       

    // default user 
    sysInfos.pool2Deadline =86400; // 1 day

    defaultUser(_defaultAddress,_defaultRef);

        
    }

    function defaultUser(address _user ,address _ref) internal {

        userInfos[_user].joined=true;
        userInfos[_ref].joined=true;
        userInfos[_ref].referral=_ref;
        userInfos[_user].referral=_ref;

        // extend it 

         userInfos[_user].poolLimit=1;
         userInfos[_user].poolTime = sysInfos.pool2Deadline+now;
         userInfos[_user].withdrawLimit=10000000*1e18;
         userInfos[_ref].withdrawLimit=10000000*1e18;


         emit regUserEv(_user, _ref);

         emit investEv(_user,1);

         emit pool_2X_EV (_user,1);

         emit pool_3X_EV (_user,1);

    }


    function initMultiSignWallet( address[] calldata _owners,uint _requiredWallet) external {

                 //-------------------MUltiSign-------------------
        require(_owners.length>0,"owner required");
        require(owners.length==0,"owner is already available");
        require(_requiredWallet>0 && _requiredWallet<=_owners.length,"invalid required number of owner wallets");

        for(uint i=0;i<_owners.length;i++){

            address owner = _owners[i];
            require(owner!=address(0),"invalid owner");
            require(!isOwner[owner],"owner is already there!");
            isOwner[owner]=true;
            owners.push(owner);
        }

        WalletRequired =_requiredWallet; // you need at least this number wallet to execute transaction



    }


     //**User Call ___  user registration 

     function payRegUser( address _referral) external returns(bool) 
    {
       regUser(_referral);
       investUser(1);
       
        return true;
    }
    
    //**User Call ___ free registration
    event regUserEv(address user, address referral);
    function regUser( address _referral ) public returns(bool) 
    {
        require(isContractPaused==false,"contract is locked");
        require(userInfos[msg.sender].joined==false,"you are blocked");
        require(userInfos[_referral].joined==true,"Your referral is not activated");
        if (_referral==address(0) || userInfos[_referral].joined==false){
            _referral= defaultAddress;
        }
        
        userInfos[msg.sender].referral=_referral;
        emit regUserEv(msg.sender, _referral);
        return true;
    }

    

    //**User Call ___ Daap invest from user
    event investEv(address user, uint position);
   

    function investUser(uint8 position) public returns(bool) {

        require(userInfos[msg.sender].referral!= address(0) && userInfos[msg.sender].isBlocked==false,"invalid user or block");

        uint totalAmount = position*sysInfos.joinPrice;

        // Invest from credit fund.

        if( userInfos[msg.sender].creditFund >=totalAmount){

            userInfos[msg.sender].creditFund-=totalAmount;

        }
         // Invest from DApp Wallet fund.
        else{

             _transfer(msg.sender,address(this),totalAmount);

        }
        // Comman function.

         if (userInfos[msg.sender].poolTime==0){

             userInfos[msg.sender].poolTime = sysInfos.pool2Deadline+now;
             userInfos[msg.sender].poolLimit = position>1?2:position;
        }
        userInfos[msg.sender].joined= true;
        userInfos[msg.sender].withdrawLimit += totalAmount*3 ;
        
        emit investEv(msg.sender,position);

        emit pool_2X_EV (msg.sender,position);

        emit pool_3X_EV (msg.sender,position);

        return true;

    }


    //  invest user by internal fund
    event reInvestEv(address user, uint postion);
    function reinvest(address _user, uint postion, uint totaAmount) external onlySigner returns(bool) {

        require(userInfos[_user].joined==true && userInfos[_user].isBlocked==false,"invalid user or block");
        uint investamount =  postion*sysInfos.joinPrice;
        require((totaAmount-userInfos[_user].totalWithdrawn)>=investamount,"avilable fund is low");
        
		userInfos[_user].withdrawLimit += investamount*2;
        userInfos[_user].totalWithdrawn += investamount;

        emit reInvestEv(_user,postion);

        emit pool_2X_EV (_user,postion);

        emit pool_3X_EV (_user,postion);

        return true;

    }

    event pool_3X_EV(address user, uint position);
    event pool_2X_EV(address user, uint position);
    function _buyPool(address _user, uint8 position)internal {

        require(userInfos[_user].joined==true && userInfos[_user].isBlocked==false,"invalid user or block");
        require(position>0 && position<= sysInfos.pool2Entrylimit," invalid position entry");
        // user pool time expire so max pool limit pass || user pool time is not expire so under value paas pool limit. 
        require((userInfos[_user].poolLimit <= sysInfos.pool2Entrylimit && userInfos[_user].poolTime < now) || (userInfos[_user].poolLimit < sysInfos.pool2Entrylimit && userInfos[_user].poolTime > now) ,"Your pool limit is expire");
        
        // Comman function.

        if (userInfos[_user].poolTime < now){
            //Pool time reset
            userInfos[_user].poolTime = sysInfos.pool2Deadline+now;
            userInfos[_user].poolLimit = position;
            
        } 
        else{
             userInfos[_user].poolLimit+= position;
        }

         emit pool_2X_EV (_user,position);


    }


    //**User Call ___ DAap Global pool 2X user

    function buyPool_2X( uint8 position) public returns(bool) {

        _buyPool(msg.sender, position);

        uint totalAmount = position*sysInfos.poolPrice;
       
        if( userInfos[msg.sender].creditFund >=totalAmount){

            userInfos[msg.sender].creditFund-=totalAmount;

        }
         // Invest from DApp Wallet fund.
        else{

             _transfer(msg.sender,address(this),totalAmount);

        }
        return true;

        
    }

    // Global pool 2X user internal fund
    //position means number of entry you want to take in pool.
    function rePool2X(address _user,uint8 position, uint totaAmount) external onlySigner returns(bool) {

        require(userInfos[_user].withdrawLimit >= position*sysInfos.poolPrice ,"user limit is exuast");
        
        uint amount = position*sysInfos.poolPrice;
        require((totaAmount-userInfos[_user].totalWithdrawn)>=amount,"avilable fund is low");

           _buyPool(_user, position);
		   userInfos[_user].withdrawLimit -= amount;
           userInfos[_user].totalWithdrawn += amount;
      
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
        require(sysInfos.withdrawFee<_amount,"withdrwal amount is to low");// fee check
       
        uint aviAmount = _amount-userInfos[_user].totalWithdrawn;
        require(aviAmount !=0,"invalid amount");

        if (userInfos[_user].withdrawLimit >= aviAmount){
         
        }
        else {
             aviAmount = userInfos[_user].withdrawLimit;
           
        }
        userInfos[_user].withdrawLimit-=aviAmount;
        userInfos[_user].totalWithdrawn+=aviAmount;

        _transfer(msg.sender,aviAmount-sysInfos.withdrawFee);
        
      
        emit withdrawEv(_user,_amount);

        return true;

    }

        // internal fund transfer.
        event transferFromLimit_Ev(address from, address to , uint amount);

        function transferfromLimit(address _from,address _to, uint _amount, uint totalAmount) external onlySigner returns(bool) {


        require(isContractPaused==false,"contract is locked by owner");
        require(userInfos[_from].joined==true && userInfos[_from].isBlocked==false," from user invalid or block");
        require(userInfos[_to].joined==true && userInfos[_to].isBlocked==false," To user invalid or block");
        require(totalAmount-userInfos[_from].totalWithdrawn>=_amount,"insuffcient fund");
       
        uint fullAmount; //limit check call.
        if (userInfos[_from].withdrawLimit >=_amount){
            fullAmount = _amount; 
        }
        else {
            fullAmount = userInfos[_from].withdrawLimit;  
        }
       
        userInfos[_from].withdrawLimit-=fullAmount;
        userInfos[_to].creditFund+=fullAmount;

        emit transferFromLimit_Ev (_from,_to,fullAmount);       

        return true;

    }

    // **User Call ___ DApp credit fund tranfer.
     event transferFromrCredit_Ev(address from, address to , uint amount);

        function transferfromCredit(address _to, uint _amount) external  returns(bool) {

        require(isContractPaused==false,"contract is locked by owner");
        require(userInfos[msg.sender].joined==true && userInfos[msg.sender].isBlocked==false," from user invalid or block");
        require(userInfos[_to].joined==true && userInfos[_to].isBlocked==false," To user invalid or block");
        require(userInfos[msg.sender].creditFund >=_amount,"Your credit fund balance is low");

        userInfos[msg.sender].creditFund-=_amount;
        userInfos[_to].creditFund+=_amount;

        emit transferFromrCredit_Ev (msg.sender,_to,_amount);       

        return true;

    }
	



//-------------------------------ADMIN CALLER FUNCTION -----------------------------------



   function changeUserAddress(address oldUserAddress, address newUserAddress) external onlyOwner returns(bool){

   userInfos[newUserAddress] = userInfos[oldUserAddress];
        
        
        userInfo memory UserInfo;
            UserInfo = userInfo({
            joined:false,
            referral:address(0),
            withdrawLimit:0,
            totalWithdrawn:0,
            creditFund:0,
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

    function changetokenaddress(address newtokenaddress) onlyOwner public returns(string memory){
        //if owner makes this 0x0 address, then it will halt all the operation of the contract. This also serves as security feature.
        //so owner can halt it in any problematic situation. Owner can then input correct address to make it all come back to normal.
        tokenAddress = newtokenaddress;

        return("token address updated successfully");
    }


    function Switch_Interface () external onlyOwner  returns (string memory) {

        USDT_INTERFACE_ENABLE=!USDT_INTERFACE_ENABLE;
        
        if (USDT_INTERFACE_ENABLE==true){

            return "USDT INTERFACE ENABLED";

        }else{

            return "ERC20 INTERFACE ENABLED";
        }
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