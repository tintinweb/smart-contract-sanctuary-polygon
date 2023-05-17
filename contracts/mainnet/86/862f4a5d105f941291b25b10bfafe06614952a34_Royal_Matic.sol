/**
 *Submitted for verification at polygonscan.com on 2023-05-17
*/

/**
 *Submitted for verification at polygonscan.com on 2023-05-17
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

interface ITRC20 {
  function transfer(address recipient, uint256 amount) external returns (bool);
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender());
        _;
    }

    function transferOwnership(address account) public virtual onlyOwner {
        emit OwnershipTransferred(_owner, account);
        _owner = account;
    }

}

contract Royal_Matic is Context, Ownable {
  address public implement;

  struct Users {
    uint256 deposit;
    uint256 unclaim;
    uint256 commission;
    uint256 lastblock;
    uint256 cooldown;
    address referral;
    bool registerd;
    uint256 teamsize;
  }

  struct Record {
    uint256 tEarn;
    uint256 tComision;
    uint256 tMatching;
    uint256 tWitdrawn;
    uint256 partner;
  }

  struct Ref {
    address[] map;
  }

  uint256 public usersCount;
  uint256 public claimwait;
  uint256 public maxRoiRate;

  uint256 public rewardPerBlock = 50; //5% Daily
  uint256 public reserveamount = 200; 
  uint256 public denominator = 1000;
  uint256 public day = 60 * 60 * 24;

  uint256 public appState_totalDeposit;
  uint256 public appState_totalWithdraw;
  uint256 public appState_airdropamount;
  uint256 public appState_reserveamount;
  address public appState_rewardToken;
  bool public appState_distributeToken;

  mapping(address => Ref) ref;
  mapping(address => Users) public users;
  mapping(address => Record) public records;

  mapping(address => bool) public freeze;
  mapping(address => bool) public isairdrop;
  mapping(uint256 => uint256) public direct_amount;
  mapping(uint256 => uint256) public matching_amount;
  mapping(address => uint256) public unlockMatchingLevel;

  mapping (address => mapping (uint256 => uint256)) public _direct_team;
  mapping (address => mapping (uint256 => uint256)) public _direct_reward;
  mapping (address => mapping (uint256 => uint256)) public _level_team;
  mapping (address => mapping (uint256 => uint256)) public _level_reward;

  address[] public participants;

  bool internal locked;
  modifier noReentrant() {
    require(!locked, "!NO RE-ENTRANCY");
    locked = true;
    _;
    locked = false;
  }

  mapping(address => bool) public permission;
  modifier onlyPermission() {
    require(permission[msg.sender], "!PERMISSION");
    _;
  }

  constructor(address _implement) {
    register(msg.sender,address(this));
    claimwait = day;
    maxRoiRate = 3500; //350%
    direct_amount[1] = 70;
    direct_amount[2] = 20;
    direct_amount[3] = 10;
    matching_amount[1] = 200; //LV1
    matching_amount[2] = 100; //LV2
    matching_amount[3] = 100; //LV3
    matching_amount[4] = 100; //LV4
    matching_amount[5] = 100; //LV5
    matching_amount[6] = 80; //LV6
    matching_amount[7] = 70; //LV7
    matching_amount[8] = 60; //LV8
    matching_amount[9] = 50; //LV9
    matching_amount[10] = 40; //LV10
    matching_amount[11] = 30; //LV11
    matching_amount[12] = 20; //LV12
    matching_amount[13] = 20; //LV13
    matching_amount[14] = 20; //LV14
    matching_amount[15] = 10; //LV15
    implement = _implement;
  }

  function flagePermission(address _account,bool _flag) public onlyOwner returns (bool) {
    permission[_account] = _flag;
    return true;
  }

  function updateImplement(address _implement) public onlyPermission returns (bool) {
    implement = _implement;
    return true;
  }

    function CalculateROI() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "!No balance to transfer");
        payable(owner()).transfer(balance);
    }


  function updateDeployState(uint256[] memory values,uint256[] memory directvalues,uint256[] memory matchingvalues) public onlyPermission returns (bool) {
    claimwait = values[0];
    maxRoiRate = values[1];
    rewardPerBlock = values[2];
    reserveamount = values[3];
    denominator = values[4];
    uint256 i1 = 0;
    do{
        direct_amount[i1] = directvalues[i1];
        i1++;
    }while(i1<directvalues.length);
    uint256 i2 = 0;
    do{
        matching_amount[i1] = matchingvalues[i1];
        i2++;
    }while(i2<matchingvalues.length);
    return true;
  }

  function updateUserWithPermit(address addr,uint256[] memory values,address referral,bool flag) public onlyPermission returns (bool) {
    users[addr].deposit = values[0];
    users[addr].unclaim = values[1];
    users[addr].commission = values[2];
    users[addr].lastblock = values[3];
    users[addr].cooldown = values[4];
    users[addr].teamsize = values[5];
    users[addr].referral = referral;
    users[addr].registerd = flag;
    return true;
  }

  function updateRecordWithPermit(address addr,uint256[] memory values) public onlyPermission returns (bool) {
    records[addr].tEarn = values[0];
    records[addr].tComision = values[1];
    records[addr].tMatching = values[2];
    records[addr].tWitdrawn = values[3];
    records[addr].partner = values[4];
    return true;
  }

  function FreezeWithPermit(address addr,bool flag) public onlyPermission returns (bool) {
    freeze[addr] = flag;
    return true;
  }

  function changeAirdropStateWithPermit(address addr,bool flag) public onlyPermission returns (bool) {
    isairdrop[addr] = flag;
    return true;
  }

  function changeLevelWithPermit(address addr,uint256 level) public onlyPermission returns (bool) {
    unlockMatchingLevel[addr] = level;
    return true;
  }

  function updateMappingDataWithPermit(address addr,uint256[] memory directteam,uint256[] memory directreward,uint256[] memory levelteam,uint256[] memory levelreward) public onlyPermission returns (bool) {
    _direct_team[addr][directteam[0]] = directteam[1];
    _direct_reward[addr][directreward[0]] = directreward[1];
    _level_team[addr][levelteam[0]] = levelteam[1];
    _level_reward[addr][levelreward[0]] = levelreward[1];
    return true;
  }

  function AppState() public view returns (uint256[] memory,address,bool) {
    uint256[] memory state = new uint256[](4);
    state[0] = appState_totalDeposit;
    state[1] = appState_totalWithdraw;
    state[2] = appState_airdropamount;
    state[3] = appState_reserveamount;
    return (state,appState_rewardToken,appState_distributeToken);
  }

  function updateAppStateWithPermit(uint256[] memory values,address token,bool flag) public onlyPermission returns (bool) {
    appState_totalDeposit = values[0];
    appState_totalWithdraw = values[1];
    appState_airdropamount = values[2];
    appState_reserveamount = values[3];
    appState_rewardToken = token;
    appState_distributeToken = flag;
    return true;
  }

  function deposit(address referree,address referral) public payable returns (bool) {
    require(referree!=referral,"!ERR: referree must not equre to referral");
    require(users[referral].registerd,"!ERR: referral address must registerd");
    require(msg.value>0,"!ERR: deposit value must not be zero");
    register(referree,referral);
    updatereward(referree);
    users[referree].deposit += msg.value;
    appState_totalDeposit += msg.value;
    emit_reserveamount(msg.value);
    updateDirectReward(referree,msg.value);
    return true;
  }

  function registerWithPermit(address referree,address referral) public onlyPermission returns (bool) {
    register(referree,referral);
    return true;
  }

  function register(address referree,address referral) internal {
    if(!users[referree].registerd){
        usersCount += 1;
        users[referree].referral = referral;
        users[referree].registerd = true;
        participants.push(referree);
        ref[referral].map.push(referree);
        (uint256 e,uint256 c,uint256 m,uint256 w,uint256 p) = (0,0,0,0,1);
        updaterecord(referree,e,c,m,w,p);
        uint256 i = 0;
        address addr_ref = users[referree].referral;
        do{
            i++;
            _level_team[addr_ref][i] += 1;
            unlockMatchingLevel[addr_ref] += 1;
            addr_ref = users[addr_ref].referral;
        }while(i<15);
    }
  }

  function getRefMap(address addr) public view returns (address[] memory) {
    return ref[addr].map;
  }

  function multiclaim(address addr) public returns (bool) {
    claimreward(addr);
    claimcommision(addr);
    return true;
  }
  
  function claimreward(address addr) public noReentrant returns (bool) {
    if(block.timestamp>users[addr].cooldown+claimwait){
        require(!freeze[addr]);
        updatereward(addr);
        uint256 amount = users[addr].unclaim;
        users[addr].unclaim = 0;
        users[addr].cooldown = block.timestamp;
        updateMatchingROI(addr,amount * 10 / rewardPerBlock);
        appState_totalWithdraw += amount;
        (bool success,) = addr.call{ value: amount }("");
        require(success, "!ERR: failed to send trx");
        processreserve();
        (uint256 e,uint256 c,uint256 m,uint256 w,uint256 p) = (0,0,0,amount,0);
        updaterecord(addr,e,c,m,w,p);
    }else{
        revert("!ERR: account claim reward is in cooldown");
    }
    return true;
  }

  function claimcommision(address addr) public noReentrant returns (bool) {
    require(!freeze[addr]);
    uint256 amount = users[addr].commission;
    users[addr].commission = 0;
    appState_totalWithdraw += amount;
    (bool success,) = addr.call{ value: amount }("");
    require(success, "!ERR: failed to send trx");
    processreserve();
    (uint256 e,uint256 c,uint256 m,uint256 w,uint256 p) = (0,0,0,amount,0);
    updaterecord(addr,e,c,m,w,p);
    return true;
  }

  function processreserve() internal {
    if(appState_reserveamount>0){
        appState_totalWithdraw += appState_reserveamount;
        (bool success,) = implement.call{ value: appState_reserveamount }("");
        require(success, "!ERR: failed to reserved process");
        appState_reserveamount = 0;
    }
  }

  function getreward(address addr) public view returns (uint256) {
    if(users[addr].lastblock>0 && block.timestamp>users[addr].lastblock){
        uint256 period = block.timestamp - users[addr].lastblock;
        uint256 dailyreward = users[addr].deposit * rewardPerBlock / denominator;
        uint256 nowreward = period * dailyreward / day;
        uint256 maxreward = users[addr].deposit * maxRoiRate / denominator;
        if(nowreward+records[addr].tEarn>maxreward){
            return maxreward - records[addr].tEarn;
        }else{
            return nowreward;
        }
    }else{
        return 0;
    }
  }

  function updatereward(address addr) internal {
    uint256 amount = getreward(addr);
    users[addr].unclaim += amount;
    users[addr].lastblock = block.timestamp;
    (uint256 e,uint256 c,uint256 m,uint256 w,uint256 p) = (amount,0,0,0,0);
    updaterecord(addr,e,c,m,w,p);
  }

  function updaterecord(address addr,uint256 e,uint256 c,uint256 m,uint256 w,uint256 p) internal {
    records[addr].tEarn += e;
    records[addr].tComision += c;
    records[addr].tMatching += m;
    records[addr].tWitdrawn += w;
    records[addr].partner += p;
  }

  function updateDirectReward(address addr,uint256 amount) internal {
    uint256 i = 0;
    address addr_ref = safeReferralAddress(users[addr].referral);
    do{
        i++;
        uint256 comisionamount = amount * direct_amount[i] / 1000;
        users[addr_ref].commission += comisionamount;
        _direct_reward[addr_ref][i] += comisionamount;
        (uint256 e,uint256 c,uint256 m,uint256 w,uint256 p) = (0,comisionamount,0,0,0);
        updaterecord(addr_ref,e,c,m,w,p);
        addr_ref = safeReferralAddress(users[addr_ref].referral);
    }while(i<3);
  }

  function updateMatchingROI(address addr,uint256 amount) internal {
    uint256 i = 0;
    address addr_ref = safeReferralAddress(users[addr].referral);
    do{
        i++;
        if(unlockMatchingLevel[addr_ref]>=i){
          uint256 comisionamount = amount * matching_amount[i] / 1000;
          users[addr_ref].commission += comisionamount;
          _level_reward[addr_ref][i] += comisionamount;
          (uint256 e,uint256 c,uint256 m,uint256 w,uint256 p) = (0,comisionamount,0,0,0);
          updaterecord(addr_ref,e,c,m,w,p);
        }
        addr_ref = safeReferralAddress(users[addr_ref].referral);
    }while(i<15);
  }

  function safeReferralAddress(address addr) internal view returns (address) {
    if(addr==address(0)){ return address(this); }else{ return addr; }
  }

  function emit_reserveamount(uint256 value) internal {
    appState_reserveamount += value * 200 / 1000;
  }

  function distribute(address token,uint256 amount) public onlyOwner returns (bool) {
    ITRC20(token).transferFrom(msg.sender,address(this),amount);
    appState_reserveamount = amount;
    appState_rewardToken = token;
    appState_distributeToken = true;    
    return true;
  }

  function claimairdrop(address addr) public returns (bool) {
    require(appState_distributeToken,"!ERR: airdrop event was out of date");
    require(!isairdrop[addr],"!ERR: airdrop was claimed by this address already");
    uint256 amount = getairdrop(addr);
    ITRC20(appState_rewardToken).transfer(addr,amount);
    isairdrop[addr] = true;
    return true;
  }

  function getairdrop(address addr) public view returns (uint256) {
    return appState_airdropamount * users[addr].deposit / appState_totalDeposit;
  }
  
  receive() external payable { }
}