/**
 *Submitted for verification at polygonscan.com on 2023-07-02
*/

pragma solidity 0.8.18;

contract MillionMoney {
    address public ownerWallet;

    struct UserStruct {
        bool isExist;
        uint id;
        uint referrerID;
        address[] referral;
        uint256[] noOfPayments;
        uint256 cycle;
        uint256 initialId;
        uint256 earning;
    }

    struct UserEarning
    {
        address referrer;
        uint256 earning;
    }

    uint REFERRER_1_LEVEL_LIMIT = 2;
    uint PERIOD_LENGTH = 100 days;

    mapping(uint => uint) public LEVEL_PRICE;

    mapping (address => mapping(uint256 => UserStruct)) public users;
    mapping (address => UserEarning) public userEarnings;
    mapping (uint => address) public userList;
    uint public currUserID = 0;
    uint256[] payments = [5,15,20,30,30];

    event regLevelEvent(address indexed _user, address indexed _referrer, uint _time);
    event prolongateLevelEvent(address indexed _user, uint _level, uint _time);
    event getMoneyForLevelEvent(address indexed _user, address indexed _referral, uint _level, uint _time);
    event lostMoneyForLevelEvent(address indexed _user, address indexed _referral, uint _level, uint _time);

    event Registration(address indexed user, address indexed referrer, uint indexed userId, uint referrerId);
    event Reinvest(address indexed user, address indexed currentReferrer, address indexed caller, uint256 matrix, uint256 level,uint256 reinvestCount);
    event Upgrade(address indexed user, address indexed referrer, uint8 matrix, uint8 level);
    event NewUserPlace(address indexed user, address indexed referrer,address indexed currentReferrer, uint256  matrix, uint256 level, uint256 depth,uint256 reinvestcount);
    event MissedEthReceive(address indexed receiver, address indexed from, uint8 matrix, uint8 level);
    event SentExtraEthDividends(address indexed from, address indexed receiver, uint8 matrix, uint8 level);
    event Referral(address indexed from, address indexed receiver, uint8 matrix, uint8 level);
    
    event EarningsMatrix(address indexed user,uint256 amount,uint8 matrix,uint8 level);

    constructor() {
        ownerWallet = msg.sender;

        LEVEL_PRICE[1] = 0.005 ether;
        LEVEL_PRICE[2] = 0.010 ether;
        LEVEL_PRICE[3] = 0.020 ether;
        LEVEL_PRICE[4] = 0.040 ether;
        LEVEL_PRICE[5] = 0.080 ether;
        LEVEL_PRICE[6] = 0.160 ether;
        LEVEL_PRICE[7] = 0.320 ether;
        LEVEL_PRICE[8] = 0.640 ether;
        LEVEL_PRICE[9] = 1.280 ether;
        LEVEL_PRICE[10] = 2.560 ether;

        currUserID++;
        for(uint256 i=1;i<=10;i++){
        users[ownerWallet][i].isExist = true;
        users[ownerWallet][i].id = currUserID;
        userEarnings[ownerWallet].referrer = ownerWallet;
        users[ownerWallet][i].initialId = currUserID;
        userList[currUserID] = ownerWallet;
        }
    }

    function regUser(address _referer) public payable {
        uint _referrerID = users[_referer][1].id;
        require(!users[msg.sender][1].isExist, 'User exist');
        require(_referrerID > 0 && _referrerID <= currUserID, 'Incorrect referrer Id');
        // require(msg.value == LEVEL_PRICE[1], 'Incorrect Value');

        if(users[userList[_referrerID]][1].referral.length >= REFERRER_1_LEVEL_LIMIT) _referrerID = users[findFreeReferrer(userList[_referrerID],1)][1].id;

        
        currUserID++;
        users[msg.sender][1].isExist = true;
        users[msg.sender][1].id = currUserID;
        users[msg.sender][1].referrerID = _referrerID;
        userEarnings[msg.sender].referrer = _referer;
        userList[currUserID] = msg.sender;
        users[msg.sender][1].initialId = currUserID;

        users[userList[_referrerID]][1].referral.push(msg.sender);

        payForLevel(1, msg.sender,1);
        // payable (_referer).transfer(LEVEL_PRICE[1]*40/100);

        emit Registration(msg.sender, userList[_referrerID],currUserID, block.timestamp);
    }

    function buyLevel(uint256 _slot) public payable {
        
        require(users[msg.sender][1].isExist, 'User not exist');
        uint _referrerID = users[userEarnings[msg.sender].referrer][_slot].id;
        if(_referrerID ==0){
            _referrerID = 1;
        }
        require(msg.value == LEVEL_PRICE[_slot], 'Incorrect Value');

        if(users[userList[_referrerID]][_slot].referral.length >= REFERRER_1_LEVEL_LIMIT) _referrerID = users[findFreeReferrer(userList[_referrerID],_slot)][_slot].id;

        currUserID++;
        users[msg.sender][_slot].isExist = true;
        users[msg.sender][_slot].id = currUserID;
        users[msg.sender][_slot].referrerID = _referrerID;
        userList[currUserID] = msg.sender;
        users[msg.sender][_slot].initialId = currUserID;

        users[userList[_referrerID]][_slot].referral.push(msg.sender);

       // payForLevel(1, msg.sender,_slot);
         payable (userList[_referrerID]).transfer(LEVEL_PRICE[1]*40/100);
        emit regLevelEvent(msg.sender, userList[_referrerID], block.timestamp);
    }



    function reinvest(address _user,uint256 _slot) internal {
        uint256 _referrerID = users[userEarnings[_user].referrer][_slot].id;
        if(users[userList[_referrerID]][_slot].referral.length >= REFERRER_1_LEVEL_LIMIT) _referrerID = users[findFreeReferrer(userList[_referrerID],1)][_slot].id;
        currUserID++;
        users[_user][_slot].id = currUserID;
        users[_user][_slot].referrerID = _referrerID;
        userList[currUserID] = _user;

        users[userList[_referrerID]][_slot].referral.push(_user);
        users[_user][_slot].noOfPayments[1] = 0;
        users[_user][_slot].noOfPayments[2] = 0;
        users[_user][_slot].noOfPayments[3] = 0;
        users[_user][_slot].noOfPayments[4] = 0;
        users[_user][_slot].noOfPayments[5] = 0;
        users[_user][_slot].cycle++;
        users[_user][_slot].referral = new address[](0);
        emit Reinvest(_user,userList[_referrerID],_user,users[_user][_slot].cycle,_slot,users[_user][_slot].cycle);
        payForLevel(1, _user,_slot);
    }

    function payForLevel(uint _level, address _user,uint256 _slot) internal {
        address referer=userList[users[_user][_slot].referrerID];
        
            if(!users[referer][_slot].isExist){
             referer = userList[1];
            }
        users[referer][_slot].noOfPayments[_level]++;

        // if(_level==5 && users[referer][_slot].noOfPayments[_level]==32){
        //     reinvest(referer,_slot);
        // }
        // else{
        //     uint256 comm = ((LEVEL_PRICE[_slot]/2)*(payments[_level-1]))/100;
        //     payable(referer).transfer(comm);
        //     users[referer][_slot].earning += comm;
        //     userEarnings[referer].earning += comm;
        //     emit getMoneyForLevelEvent(referer, msg.sender, _level, block.timestamp);
        // }
        // emit NewUserPlace(msg.sender, referer,referer, 3, _slot, _level,users[referer][_slot].cycle);
        // if(_level<5){
        //     payForLevel(_level+1, referer,_slot);
        // }
        
    }

    function findFreeReferrer(address _user,uint256 _slot) public view returns(address) {
        if(users[_user][_slot].referral.length < REFERRER_1_LEVEL_LIMIT) return _user;

        address[] memory referrals = new address[](62);
        referrals[0] = users[_user][_slot].referral[0];
        referrals[1] = users[_user][_slot].referral[1];

        address freeReferrer;
        bool noFreeReferrer = true;

        for(uint i = 0; i < 62; i++) {
            if(users[referrals[i]][_slot].referral.length == REFERRER_1_LEVEL_LIMIT) {
                if(i < 31) {
                    referrals[(i+1)*2] = users[referrals[i]][_slot].referral[0];
                    referrals[(i+1)*2+1] = users[referrals[i]][_slot].referral[1];
                }
            }
            else {
                noFreeReferrer = false;
                freeReferrer = referrals[i];
                break;
            }
        }

        require(!noFreeReferrer, 'No Free Referrer');

        return freeReferrer;
    }

    function viewUserReferral(address _user) public view returns(address[] memory) {
        return users[_user][1].referral;
    }

    function bytesToAddress(bytes memory bys) private pure returns (address addr) {
        assembly {
            addr := mload(add(bys, 20))
        }
    }

    function getUserInfoPayment(address _user,uint256 _slot) external view returns(uint256[6] memory noOfPayments)
    {
        for(uint256 i=1;i<=5;i++){
            noOfPayments[i] = users[_user][_slot].noOfPayments[i];
        }

        return noOfPayments;
    }
}