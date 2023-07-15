/**
 *Submitted for verification at polygonscan.com on 2023-07-14
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

library SafeMath {
 
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, "SafeMath: addition overflow");
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    return sub(a, b, "SafeMath: subtraction overflow");
  }

  function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b <= a, errorMessage);
    uint256 c = a - b;
    return c;
  }

  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    require(c / a == b, "SafeMath: multiplication overflow");
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    return div(a, b, "SafeMath: division by zero");
  }

  function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b > 0, errorMessage);
    uint256 c = a / b;
    return c;
  }

  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    return mod(a, b, "SafeMath: modulo by zero");
  }

  function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b != 0, errorMessage);
    return a % b;
  }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IERC20 {

    function allowance(address owner, address spender) external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

struct UserPackage {
    address referral;
    uint256 invest;
    uint256 levelIncome;
    uint256 nonWorkingIncome;
    uint256 royaltyIncome;
    uint256 nonLimit;
    uint256 limit;
}

struct User {
    bool isExists;
    uint256 userId;
    address referral;
    uint256 totalInvest;
    uint256 totalIncome;
}

contract WingsNetV1 is Ownable {

    bool internal initialized;
    address internal PayableToken;
    address[] internal receivers;
    
    uint256 public totalUsers;
    uint256 public totalInvestment;
    uint256[] public plans;
    mapping(uint256 => address) public user;
    mapping(address => User) public users;
    mapping(address => UserPackage[10]) public userPackages;
    mapping(uint8 => address[]) public nonWorking;
    mapping(uint8 => address[]) public royaltyAcheivers;

    uint16[] internal levelDistribution;
    uint16[] internal nonWorkingDistribution;
    uint16[] internal royaltyDistribution;
    mapping(address => mapping (uint8 => address[])) internal referTeam;
    
    event Register(address indexed _user);
    event Activate(address indexed _user, uint256 indexed _amount, address indexed _referral);
    event DistributedLevel(address indexed _to, address indexed _from, uint256 _amount, uint256 _level);
    event DistributedNonWorking(address indexed _to, address indexed _form, uint256 _amount, uint256 _count);
    event DistributedRoyalty(address indexed _to, address indexed _form, uint256 _amount, uint256 _count);
    
    using SafeMath for uint256;

    modifier isUser() {
        require(users[_msgSender()].isExists, "caller is not user!");
        _;
    }

    constructor(address payableToken_, address[] memory receivers_, address[] memory leaders_) {
        require(!initialized, "Contract is already initialized");
        initialized = true;
        PayableToken = payableToken_;
        _setReceivers(receivers_);

        levelDistribution = [2500,1500,500,400,300,200,100,100,100,100,100,100,100,100,100,100,100,100,100,100];
        royaltyDistribution = [0, 0, 100, 150, 250];
        nonWorkingDistribution = [2000,2000,2000,2000,2000];
        plans = [25e18, 50e18, 100e18, 200e18, 400e18];

        _register(owner(), owner());
        
        uint256 _lenLeader = leaders_.length;
        for (uint8 j = 0; j < _lenLeader; ++j) {
            _register(leaders_[j], leaders_[0]);
        }

        uint256 _len = 3;
        for (uint8 i = 0; i < _len; ++i){
            _activate(i, owner());
            for (uint8 j = 0; j < _lenLeader; ++j) {
                _activate(i, leaders_[j]);
            }
        }
    }

    function register(address referral_) external returns (bool registed) {
        require (!users[_msgSender()].isExists, "already registered!");
        IERC20(PayableToken).transferFrom(_msgSender(), address(this), plans[0]);
        _register(_msgSender(), referral_);
        _activate(0, _msgSender());
        _distributeLevel(0, _msgSender());
        _distributeNonWorking(0 , _msgSender());
        _distributeRoyalty(0, _msgSender());
        _distribute();
        return true;
    }

    function _register(address _user, address _referral) internal {
        if (!users[_referral].isExists) {
            _referral = owner();
        }
        ++totalUsers;
        users[_user].isExists = true;
        users[_user].referral = _referral;
        users[_user].userId = totalUsers;
        user[totalUsers] = _user;
        emit Register(_user);
    }

    function activate(uint8 plan_) external isUser returns (bool) {
        require  ((plans.length > plan_) , "Invalid plan Id!");
        if (plan_ < 4 && userPackages[_msgSender()][plan_].invest > 0) {
            revert ("only buy this package once!");
        }
        else if (plan_ >= 1 && userPackages[_msgSender()][plan_ - 1].invest == 0) {
            revert ("active plan in serial order wise!");
        }
        IERC20(PayableToken).transferFrom(_msgSender(), address(this), plans[plan_]);
        _activate(plan_, _msgSender());
        _distributeLevel(plan_, _msgSender());
        _distributeNonWorking(plan_, _msgSender());
        _distributeRoyalty(plan_, _msgSender());
        _distribute();
        return true;
    }

    function _activate(uint8 plan_, address user_) internal {
        address _referral = getReferral(plan_, user_);
        UserPackage memory _package = userPackages[user_][plan_];
        if (userPackages[user_][plan_].invest == 0) {
            _package.referral = _referral;
            referTeam[_referral][plan_].push(user_);
        }
        else {
            _referral = _package.referral;
        }
        _package.invest = _package.invest.add(plans[plan_]);
        _package.nonLimit = _package.nonLimit.add(plans[plan_].mul(160).div(100));
        uint8[5] memory _limit = [10, 8, 6, 5, 4];
        _package.limit = _package.limit.add(plans[plan_].mul(_limit[plan_]));
        userPackages[user_][plan_] = _package;
        users[user_].totalInvest = users[user_].totalInvest.add(plans[plan_]);
        totalInvestment = totalInvestment.add(plans[plan_]);
        addNonWorking(plan_, user_);
        if (plan_ > 1 && (_referCount(plan_, _referral) >= 20) && (userPackages[_referral][plan_].limit > 0)){
            addAcheiver(plan_, _referral);
        }
        emit Activate(user_, plans[plan_], _referral);
    }
    
    function _distributeLevel(uint8 plan_, address user_) internal {
        address _referral = userPackages[user_][plan_].referral;
        for (uint64 i = 0; i < 20; ++i) {
            uint256 _amount = (plans[plan_].mul(levelDistribution[i])).div(1e4);
            UserPackage memory _package = userPackages[_referral][plan_];
            if (_referCount(plan_, _referral) >= i) {
                if (_package.invest > 0 && _package.limit > 0) {
                    if (_package.limit < _amount) {
                        _amount = _package.limit;
                    }
                    
                    if (i < 5) {
                        _package.limit = _package.limit.sub(_amount);
                        _package.levelIncome = _package.levelIncome.add(_amount);
                        users[_referral].totalIncome = users[_referral].totalIncome.add(_amount);
                        if (_amount > 0) {
                            IERC20(PayableToken).transfer(_referral, _amount);
                            emit DistributedLevel(_referral, user_, _amount, (i + 1));
                        }
                    }
                    else if ((plan_ > 0 && userPackages[_referral][plan_ + 1].invest > 0) || (plan_ == 4)) {
                        _package.limit = _package.limit.sub(_amount);
                        _package.levelIncome = _package.levelIncome.add(_amount);
                        users[_referral].totalIncome = users[_referral].totalIncome.add(_amount);
                        if (_amount > 0) {
                            IERC20(PayableToken).transfer(_referral, _amount);
                            emit DistributedLevel(_referral, user_, _amount, (i + 1));
                        }
                    }
                    userPackages[_referral][plan_] = _package;
                }
            }
            _referral = userPackages[_referral][plan_].referral;
        }
    }

    function _distributeNonWorking(uint8 plan_, address user_) internal {
        address[] memory _users = nonWorking[plan_];
        uint256 _len = _users.length;
        if (_len > 0) {
            uint256 _amount = plans[plan_].mul(nonWorkingDistribution[plan_]).div(1e4).div(_len - 1);    
            for (uint64 i = 0; i < _len; ++i) {
                if (_users[i] != user_) {
                    UserPackage memory _package = userPackages[_users[i]][plan_];
                    if (_package.nonLimit < _amount) {
                        _amount = _package.nonLimit;
                        removeNonWorking(plan_, _users[i]);
                    }
                    if (_package.limit < _amount) {
                        _amount = _package.limit;
                        removeNonWorking(plan_, _users[i]);
                    }
                    _package.nonLimit = _package.nonLimit.sub(_amount);
                    _package.limit = _package.limit.sub(_amount);
                    _package.nonWorkingIncome = _package.nonWorkingIncome.add(_amount);
                    userPackages[_users[i]][plan_] = _package;
                    users[_users[i]].totalIncome = users[_users[i]].totalIncome.add(_amount);
                    if (_amount > 0) {
                        IERC20(PayableToken).transfer(_users[i], _amount);
                        emit DistributedNonWorking(_users[i], user_, _amount, (_len - 1));
                    }
                }
            }
        }
    }

    // function _distributeRoyalty(uint8 plan_, address user_) internal {
    //     uint256 _lenRol = royaltyDistribution.length;
    //     for (uint8 _plan = 2; _plan < _lenRol; ++_plan) {
    //         address[] memory _users = royaltyAcheivers[_plan];
    //         uint256 _len = _users.length;
    //         if (_len > 0) {
    //             uint256 _amount = plans[plan_].mul(royaltyDistribution[_plan]).div(1e4).div(_len);
    //             for (uint64 i = 0; i < _len; ++i) {
    //                 if (_users[i] != user_) {
    //                     UserPackage memory _package = userPackages[_users[i]][_plan];
    //                     if (_package.limit > 0 && _package.nonLimit > 0) {
    //                         if (_package.nonLimit < _amount) {
    //                             _amount = _package.nonLimit;
    //                             removeAcheiver(_plan, _users[i]);
    //                         }
    //                         if (_package.limit < _amount) {
    //                             _amount = _package.limit;
    //                             removeAcheiver(_plan, _users[i]);
    //                         }
    //                         _package.nonLimit = _package.nonLimit.sub(_amount);
    //                         _package.limit = _package.limit.sub(_amount);
    //                         _package.royaltyIncome = _package.royaltyIncome.add(_amount);
    //                         userPackages[_users[i]][plan_] = _package;
    //                         users[_users[i]].totalIncome = users[_users[i]].totalIncome.add(_amount);
    //                         if (_amount > 0) {
    //                             IERC20(PayableToken).transfer(_users[i], _amount);
    //                             emit DistributedRoyalty(_users[i], user_, _amount, _len);
    //                         }
    //                     }
    //                 }
    //             }
    //         }
    //     }
    // }

    function _distributeRoyalty(uint8 plan_, address user_) internal {
        uint256 _lenRol = royaltyDistribution.length;
        for (uint8 _plan = 2; _plan < _lenRol; ++_plan) {
            address[] memory _users = royaltyAcheivers[_plan];
            uint256 _len = _users.length;
            if (_len > 0) {
                uint256 _amount = plans[plan_].mul(royaltyDistribution[_plan]).div(1e4).div(_len);
                for (uint64 i = 0; i < _len; ++i) {
                    if (_users[i] != user_) {
                        UserPackage memory _package = userPackages[_users[i]][_plan];
                        if (_package.limit > 0 && _package.nonLimit > 0) {
                            if (_package.nonLimit < _amount) {
                                _amount = _package.nonLimit;
                            }
                            if (_package.limit < _amount) {
                                _amount = _package.limit;
                            }
                            _package.nonLimit = _package.nonLimit.sub(_amount);
                            _package.limit = _package.limit.sub(_amount);
                            _package.royaltyIncome = _package.royaltyIncome.add(_amount);
                            userPackages[_users[i]][plan_] = _package;
                            users[_users[i]].totalIncome = users[_users[i]].totalIncome.add(_amount);
                            if (_amount > 0) {
                                IERC20(PayableToken).transfer(_users[i], _amount);
                                emit DistributedRoyalty(_users[i], user_, _amount, _len);
                            }
                        }
                        else if (_plan != 4){
                            UserPackage memory _package2 = userPackages[_users[i]][_plan + 1];
                            if (_package2.limit > 0 && _package2.nonLimit > 0) {
                                if (_package2.nonLimit < _amount) {
                                    _amount = _package2.nonLimit;
                                    removeAcheiver(_plan, _users[i]);
                                }
                                if (_package2.limit < _amount) {
                                    _amount = _package2.limit;
                                    removeAcheiver(_plan, _users[i]);
                                }

                                if (acheiverExists(_plan + 1, _users[i]))
                                { 
                                    removeAcheiver(_plan, _users[i]);
                                }

                                _package2.nonLimit = _package2.nonLimit.sub(_amount);
                                _package2.limit = _package2.limit.sub(_amount);
                                _package2.royaltyIncome = _package2.royaltyIncome.add(_amount);
                                userPackages[_users[i]][plan_ + 1] = _package2;
                                users[_users[i]].totalIncome = users[_users[i]].totalIncome.add(_amount);
                                if (_amount > 0) {
                                    IERC20(PayableToken).transfer(_users[i], _amount);
                                    emit DistributedRoyalty(_users[i], user_, _amount, _len);
                                }
                            }
                        }
                    }
                }
            }
        }
    }


    function _distribute() internal {
        uint256 _len = receivers.length;
        uint256 bal = IERC20(PayableToken).balanceOf(address(this)).div(_len);
        if (bal > 0) {
            for (uint i = 0; i < _len; ++i) {
                IERC20(PayableToken).transfer(receivers[i], bal);
            }
        }
    }



    function getReferral(uint8 plan_, address user_) public view returns (address) {
        address referral_ = users[user_].referral;
        uint i = 0;
        do {
            if (userPackages[referral_][plan_].invest > 0 || referral_ == owner()) {
                ++i;
            }
            else {
               referral_ = users[referral_].referral; 
            }
        }
        while (i < 1);
        if (referral_ == address(0)) {
            referral_ = owner();
        }
        return referral_;
    }

    function referralExists(uint8 plan_, address user_) public view returns (bool) {
        address[] storage _users = royaltyAcheivers[plan_];
        uint256 _len = _users.length;
        for (uint256 i = 0; i < _len; ++i) {
            if (_users[i] == user_) {
                return true;
            }
        }
        return false;
    }


    function acheiverExists(uint8 plan_, address user_) public view returns (bool) {
        address[] storage _users = royaltyAcheivers[plan_];
        uint256 _len = _users.length;
        for (uint256 i = 0; i < _len; i++) {
            if (_users[i] == user_) {
                return true;
            }
        }
        return false;
    }

    function getAcheiversCount(uint8 plan_) external view returns (uint256) {
        return royaltyAcheivers[plan_].length;
    }

    function addAcheiver(uint8 plan_, address user_) internal {
        require(user_ != address(0), "Invalid address");
        if (!acheiverExists(plan_, user_)) {
            royaltyAcheivers[plan_].push(user_);
        }
    }

    function removeAcheiver(uint8 plan_, address userToRemove_) internal {
        if (acheiverExists(plan_, userToRemove_)) {
            address[] storage _users = royaltyAcheivers[plan_];
            uint256 _len = _users.length;
            for (uint256 i = 0; i < _len; ++i) {
                if (_users[i] == userToRemove_) {
                    _users[i] = _users[_len - 1];
                    _users.pop();
                    break;
                }
            }
        }
    }


    function nonWorkingExists(uint8 plan_, address user_) public view returns (bool) {
        address[] storage _users = nonWorking[plan_];
        uint256 _len = _users.length;
        for (uint256 i = 0; i < _len; ++i) {
            if (_users[i] == user_) {
                return true;
            }
        }
        return false;
    }

    function getNonWorkingCount(uint8 plan_) external view returns (uint256) {
        return nonWorking[plan_].length;
    }

    function addNonWorking(uint8 plan_, address user_) internal {
        require(user_ != address(0), "Invalid address");
        if (!nonWorkingExists(plan_, user_)) {
            nonWorking[plan_].push(user_);
        }
    }

    function removeNonWorking(uint8 plan_, address userToRemove_) internal {
        if (nonWorkingExists(plan_, userToRemove_)) {
            address[] storage _users = nonWorking[plan_];
            uint256 _len = _users.length;
            for (uint256 i = 0; i < _len; ++i) {
                if (_users[i] == userToRemove_) {
                    _users[i] = _users[_len - 1];
                    _users.pop();
                    break;
                }
            }
        }
    }
    

    function setReceivers(address[] memory receivers_) external onlyOwner {
        _setReceivers(receivers_);
    }

    function _setReceivers(address[] memory receivers_) internal {
        require(receivers_.length > 0, "must declare receiver");
        receivers = receivers_;
    }

    function referList(uint8 plan_, address user_) external view returns (address[] memory) {
        return referTeam[user_][plan_];
    }

    function referCount(uint8 plan_, address user_) external view returns (uint256) {
        return _referCount(plan_, user_);
    }

    function _referCount(uint8 plan_, address user_) internal view returns (uint256) {
        return referTeam[user_][plan_].length;
    }
}