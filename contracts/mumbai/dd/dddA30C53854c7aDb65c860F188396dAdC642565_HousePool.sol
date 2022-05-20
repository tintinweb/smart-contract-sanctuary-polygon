/**
 *Submitted for verification at polygonscan.com on 2022-05-16
*/

pragma solidity 0.8.12;
contract HousePool
{
    //structs
    struct UserBoxStruct{
        uint Balance;
        uint ActualBalance;
        uint DepositTime;
        uint rewardDept;
        uint LossDept;
    }
    //mapping()
    mapping (address => UserBoxStruct[]) public Users;
    mapping(address => uint)public userItemlength;
    mapping(address => bool)public accessGrant;
    bool public depositPaused;
    //State variables
    bool internal locked;
    uint256 public  maxProfitDivisor = 1000000; //supports upto four decimals
    uint256 public maxProfit; //max profit user can make
    uint256 public maxProfitAsPercentOfHouse; //mac profit as percent
    uint public releaseTime=24 hours;
    uint public totalDepositedAmount;
    uint public totalValueLocked;//without rewards 
    uint public accRewardPershare;
    //Extra
    uint public accLossPerShare;

    address public Owner;
    uint public totalRewardAmountgained;//Balance will be coming in and update this variable
 
    //modifiers
    modifier onlyOwner(){
        require(msg.sender == Owner,"Caller is NOt an Owner" );
        _;
    }
    modifier checkZero(){
        require(msg.value > 0,"Value needs to be greater than zero");
        _;
    }
    modifier validIndex(address _user,uint _index){
        require(_index <= (Users[_user].length -1));
        _;
    }
    modifier validBalance(address _user){
        require(Users[_user].length > 0);
        _;
    }
    modifier isGranted()
    {
        require(accessGrant[msg.sender] == true,"No Access to Call function");
        _;
    }
     modifier noReentrancy() {
        require(!locked , "No reentrancy");
        locked = true;
        _;
        locked = false;
    }
    modifier checkDeposit(){
        require(!depositPaused,"Deposits are not active");
        _;
    }
    //events
    event Deposit(address indexed _sender,uint _amount,uint _depositedTime,uint _IndexNum,uint _releaseTime);
    event Withdraw(address indexed _sender,uint _amount,uint _IndexNum);
    event transfer(address indexed _to,uint _amount);
    //constructor
    constructor(){
        Owner = msg.sender;
        ownerSetMaxProfitAsPercentOfHouse(1000); 
    }
    receive() external payable{
    }
    
    function deposit() external payable checkZero checkDeposit returns(bool success) {

        UserBoxStruct memory user=UserBoxStruct({
            Balance : msg.value,
            DepositTime:block.timestamp,
            ActualBalance:0,
            rewardDept:(msg.value*(accRewardPershare))/(1e18),//determines whatever the rewards we gained before this deposit we already distributed it
            LossDept:(msg.value *(accLossPerShare)/(1e18))//determines that whatever the loss that happened before it he already paid it
        });
        Users[msg.sender].push(user);
        totalDepositedAmount +=msg.value;
        totalValueLocked +=msg.value;
        userItemlength[msg.sender] += 1;
        setMaxProfit();
        emit Deposit(msg.sender,msg.value,user.DepositTime,Users[msg.sender].length-1,(user.DepositTime+releaseTime));
        return true;

    }

    function withdraw(uint amount,uint _index) external validBalance(msg.sender) validIndex(msg.sender,_index) noReentrancy returns(bool success) 
    {

        setMyPresentBalance(msg.sender,_index);
        UserBoxStruct storage user = Users[msg.sender][_index];
        require(amount <= user.ActualBalance,"Look into the Actual Balance");//if amount is greater than 0 ,check if the amount exceeds the actual balance
        require(block.timestamp > (user.DepositTime + releaseTime),"The Locking is not completed");
        
        uint pending=((user.Balance*accRewardPershare)/(1e18))-(user.rewardDept);
        if(pending > 0)
        {
            payable(msg.sender).transfer(pending);//
        }
        if(amount > 0)
        {
            
            if(user.ActualBalance - amount== 0)//if amount is equal to actual amount 
            {
                totalDepositedAmount -=user.Balance;
                user.Balance =0;
                user.ActualBalance -=amount;  
                
                user.LossDept =0;//(user.Balance*(accLossPerShare))/(1e18)-->anyway this will give us zero ,so we are keeping zero
                user.rewardDept = 0;//(user.Balance*(accRewardPershare))/(1e18)--->anyway this will give us zero,so we are keeping zero
                if(Users[msg.sender].length > 1)//if the user length is greater than 1
                {   
                    Users[msg.sender][_index]=Users[msg.sender][Users[msg.sender].length-1];//Replace the index with final index of the user 
                    Users[msg.sender].pop();//pop out the last index 
                    userItemlength[msg.sender] -=1;//decrease the length 
                       
                }
                else if(Users[msg.sender].length == 1)
                {
                    Users[msg.sender].pop();//take out the index of the user 
                    userItemlength[msg.sender] -=1;//decrease the length 
                }    
            }
            else
            {
                uint UserLostAmount =user.Balance-user.ActualBalance;
                totalDepositedAmount -=(amount+UserLostAmount);
                user.Balance -=(amount + UserLostAmount);
                user.ActualBalance -=amount; 
                user.LossDept =(user.Balance*(accLossPerShare))/(1e18);
                user.rewardDept = (user.Balance*(accRewardPershare))/(1e18);
           
            }
            
            TransferFunds(msg.sender,amount); 
        }
        else
        {
            user.rewardDept = (user.Balance*(accRewardPershare))/(1e18);
        }
       
        emit Withdraw(msg.sender,amount,_index);
        return true;

    } 
     function PendingRewards(address _user,uint _index) public validBalance(_user) validIndex(_user,_index) view returns(uint)
    {
        
        uint pending;
        UserBoxStruct storage user = Users[_user][_index];
       
        if(((user.Balance *  accRewardPershare)/1e18) > user.rewardDept)
        {
            pending =((user.Balance*accRewardPershare)/(1e18))-(user.rewardDept);
        }
        return pending;
    }

    //Getters
    function GetMypresentBalance(address _user,uint _index)public validBalance(_user) validIndex(_user,_index) view returns(uint actualamount)
    {
       UserBoxStruct storage user = Users[_user][_index];
      actualamount = ((user.Balance +(user.LossDept))-((user.Balance*accLossPerShare)/(1e18)));
    }
    function setMyPresentBalance(address _user,uint _index)internal returns(uint){//Keep it internal
       UserBoxStruct storage user = Users[_user][_index];
        user.ActualBalance = GetMypresentBalance(_user,_index);
        return user.ActualBalance;

    }
    
    function Getmybalance(address _user,uint _index)public validBalance(_user) validIndex(_user,_index) view returns(uint )
    {
        UserBoxStruct storage user = Users[_user][_index];
        return user.Balance;
    }
    
   

    //Owner functions
    function Transfer(uint _amount)public noReentrancy isGranted  
    {
        require(_amount > 0,"The input amount is very less");
        require(_amount < totalValueLocked,"The amount is too high");
        require(msg.sender != address(0),"Address should not be zero");
        CalculateLossPerShare(_amount);
        TransferFunds(msg.sender,_amount);
        emit transfer(msg.sender,_amount);
        
    }
   
    function SendRewardFunds()payable public isGranted {
        
       totalRewardAmountgained += msg.value;
       uint RewardAmount=msg.value;
        if(RewardAmount > 0 && totalDepositedAmount>0)
        {
            accRewardPershare =accRewardPershare+((RewardAmount*1e18)/totalDepositedAmount);
            
        }
    } 


    function TransferOwnerShip(address _newOwner)external onlyOwner {
        require(_newOwner != address(0),"The address cannot be zero");
        require(_newOwner != Owner,"Same owner is reassigned");
        Owner = _newOwner;
    } 
    
    //Extra
    function CalculateLossPerShare(uint _amount)internal
    {
        uint LossAmount = _amount;
        if(LossAmount > 0 && totalDepositedAmount>0)
        {
            accLossPerShare = accLossPerShare+((LossAmount*1e18)/totalDepositedAmount);
        }
    }
    
    function ownerSetMaxProfitAsPercentOfHouse(uint256 newMaxProfitAsPercent)
        public
        onlyOwner
    {
       require(newMaxProfitAsPercent > 0,"The percent of the percent should not be 0");
       require(newMaxProfitAsPercent != maxProfitAsPercentOfHouse,"Assigning the same value is not allowed");
        maxProfitAsPercentOfHouse = newMaxProfitAsPercent;
        setMaxProfit();
    }
    function TransferFunds(address _user,uint _amount)internal {
        if(_amount <= totalValueLocked)
        {
            totalValueLocked =totalValueLocked - _amount;  
            setMaxProfit();
            payable(_user).transfer(_amount);
             
        }
        else
        {
            uint valuelock=totalValueLocked;
            totalValueLocked =0;
            setMaxProfit();
            payable(_user).transfer(valuelock);    
        }
        

    }

    function setMaxProfit() internal {
        require(maxProfitAsPercentOfHouse > 0,"the percentage for profit should be higher");
        maxProfit =
            (totalValueLocked * maxProfitAsPercentOfHouse) / maxProfitDivisor;
    }

    function SetTransferAccess(address _account,bool _value)external onlyOwner
    {
        require(_account != address(0),"The account address should not equal to the zero address");
        require(accessGrant[_account] != _value,"Don't assign the same value again ");
        accessGrant[_account]=_value;
    }


    function getUserDepositLength()public view returns(uint)
    {
        return Users[msg.sender].length;
    }

     function ownerPauseDeposit(bool newStatus) external onlyOwner {
        require(newStatus != depositPaused,"The status of deposit should not be same as previous one");
        depositPaused = newStatus;
    }

    function emergencyWithdraw(address  _recipient) external onlyOwner{
        require(_recipient != address(0),"The recipient address should not equal to zero address");
        payable(_recipient).transfer(address(this).balance);
    }

    
}