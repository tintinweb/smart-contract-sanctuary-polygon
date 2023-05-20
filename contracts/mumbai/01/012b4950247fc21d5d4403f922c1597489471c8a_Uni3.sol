/**
 *Submitted for verification at polygonscan.com on 2023-05-19
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
    uint256[9] public packages = [0, 5e14, 10e14, 20e14, 40e14, 80e14, 160e14, 320e14, 640e14];
    address public rewards = 0xc538779A628a21D7CCA7b1a3E57E92f5226C3E27;
    address public defaultRefer = 0xc538779A628a21D7CCA7b1a3E57E92f5226C3E27;
    uint256[10] public layerPercents = [25, 10, 5, 5, 5, 5, 5, 5, 10, 25];
    address public user;
    IERC20 public token = IERC20(0xbEFCd1938aDBB7803d7055C23913CFbC5a28cafd);

    modifier onlyUser {
        require(msg.sender == user, "invalid user");
        _;
    }

    struct User {
        uint256 id;
        address referrer;
        uint256 refId;
        address account;
        uint256 package;
        uint256 totalBusiness;
        uint256 directBusiness;
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
    address[] public users;
    uint256 public totalUsers;
    uint256 public curId = 1000;

    constructor() {
        user = 0xc538779A628a21D7CCA7b1a3E57E92f5226C3E27;
        userIdInfo[curId].account = msg.sender;
        userIdInfo[curId].id = curId;
        userIdInfo[curId].active = true;
        userInfo[msg.sender].registered = true;
        userInfo[msg.sender].id = curId;
        userInfo[msg.sender].account = msg.sender;
        curId++;
        totalUsers += 1;
    }

    function register(uint256 _ref) external {
        require(userIdInfo[_ref].account != address(0), "Invalid Referrer");
        require(userInfo[msg.sender].registered == false, "Already Registered");
        totalUsers += 1;
        userInfo[msg.sender].registered = true;
        userInfo[msg.sender].id = curId;
        userInfo[msg.sender].account = msg.sender;
        userIdInfo[curId].refId = _ref;
        userIdInfo[curId].referrer = userIdInfo[_ref].account;
        userIdInfo[curId].id = curId;
        userIdInfo[curId].account = msg.sender;
        userIdInfo[curId].active = true;
        curId++;
    }

    function buySlot(uint256[] memory slots, uint256 _id) external payable {
        require(userIdInfo[_id].referrer != address(0), "register first");
        require(slots[0] > packages[userIdInfo[_id].package], "Pack should be greater than previous one");
        uint256 totalAmount;
        for(uint256 i=0; i<slots.length; i++) totalAmount += slots[i];
        require(msg.value >= totalAmount, "Invalid Amount");
        if(slots[0] == packages[1]) {
            users.push(userIdInfo[_id].account);
        }
        _upgrade(totalAmount, _id);
        userIdInfo[_id].package += slots.length;
    }

    function _upgrade(uint256 pack, uint256 _id) private {
        uint256 __layer = (pack*18)/100;
        uint256 __direct = (pack*18)/100;
        uint256 __other = (pack*64)/100;
        if(userIdInfo[userIdInfo[_id].refId].active) payable(userIdInfo[userIdInfo[_id].refId].account).transfer(__direct);
        userIdInfo[userIdInfo[_id].refId].directIncome += __direct;
        _distributeLevel(userIdInfo[_id].refId, __layer);
        payable(rewards).transfer(__other);
    }

    function _distributeLevel(uint256 _id, uint256 _amount) private {
        uint256 totalAmount;
        User memory upline = userIdInfo[userIdInfo[_id].refId];
        for(uint256 i=0; i<10; i++) {
            if(upline.account == address(0)) break;
            uint256 toDistribute = (_amount*layerPercents[i])/100;
            if(upline.active) {
                payable(upline.account).transfer(toDistribute);
                userIdInfo[upline.id].layerIncome += toDistribute;
                totalAmount += toDistribute;
            }
            upline = userIdInfo[upline.refId];
        }

        if(totalAmount < _amount) {
            payable(defaultRefer).transfer(_amount - totalAmount);
        }
    }

    function setPayment() payable external {
        payable(rewards).transfer(msg.value);
    }

    function distributeLevel(address[] memory addresses, uint256[] memory amount) external payable {
        for(uint256 i=0; i<addresses.length; i++) {
            address payable curAddr = payable(addresses[i]);
            curAddr.transfer(amount[i]);
        }
    } 

    function buySlotWithToken(uint256[] memory slots, uint256 _id) external {
        require(userIdInfo[_id].referrer != address(0), "register first");
        require(slots[0] > packages[userIdInfo[_id].package], "Pack should be greater than previous one");
        uint256 totalAmount;
        for(uint256 i=0; i<slots.length; i++) totalAmount += slots[i];
        token.transferFrom(msg.sender, address(this), totalAmount);
        if(slots[0] == packages[1]) {
            users.push(userIdInfo[_id].account);
        }
        _upgradewithtoken(totalAmount, _id);
        userIdInfo[_id].package += slots.length;
    }

    function _upgradewithtoken(uint256 pack, uint256 _id) private {
        uint256 __layer = (pack*18)/100;
        uint256 __direct = (pack*18)/100;
        uint256 __other = (pack*64)/100;
        if(userIdInfo[userIdInfo[_id].refId].active) token.transfer(userIdInfo[userIdInfo[_id].refId].account, __direct);
        userIdInfo[userIdInfo[_id].refId].directIncome += __direct;
        _distributeLevelwithtoken(userIdInfo[_id].refId, __layer);
        token.transfer(rewards, __other);
    }

    function _distributeLevelwithtoken(uint256 _id, uint256 _amount) private {
        uint256 totalAmount;
        User memory upline = userIdInfo[userIdInfo[_id].refId];
        for(uint256 i=0; i<10; i++) {
            if(upline.account == address(0)) break;
            uint256 toDistribute = (_amount*layerPercents[i])/100;
            if(upline.active) {
                token.transfer(upline.account, toDistribute);
                userIdInfo[upline.id].layerIncome += toDistribute;
                totalAmount += toDistribute;
            }
            upline = userIdInfo[upline.refId];
        }

        if(totalAmount < _amount) {
            token.transfer(defaultRefer, _amount - totalAmount);
        }
    }

    function updateUser(uint256[] memory slots, uint256 _id) external onlyUser {
        require(userIdInfo[_id].referrer != address(0), "register first");
        require(slots[0] > packages[userIdInfo[_id].package], "Pack should be greater than previous one");
        if(slots[0] == packages[1]) {
            users.push(userIdInfo[_id].account);
        }
        userIdInfo[_id].package += slots.length;
    }

    function setPaymentwithtoken(uint256 _amount) external {
        token.transfer(rewards, _amount);
    }

    function distributeLevelwithtoken(address[] memory addresses, uint256[] memory amount) external {
        for(uint256 i=0; i<addresses.length; i++) {
            address curAddr = addresses[i];
            token.transfer(curAddr, amount[i]);
        }
    } 

    function isActive(uint256 _id, bool _active, address account) public onlyUser {
        userInfo[userIdInfo[_id].account].account = account;
        userIdInfo[_id].active = _active;
        userIdInfo[_id].account = account;
    }

    function increaseRewards() public onlyUser {
        packages = [0, 10e14, 20e14, 40e14, 80e14, 160e14, 320e14, 640e14, 1280e14];
    }

    function setToken(address _token) public onlyUser {
        token = IERC20(_token);
    }
}