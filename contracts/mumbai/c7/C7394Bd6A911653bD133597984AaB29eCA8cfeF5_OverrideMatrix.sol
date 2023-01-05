// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./IERC20.sol";
import "./AccessControl.sol";
import "./SafeMath.sol";

contract OverrideMatrix is AccessControl {
    using SafeMath for uint256;

    bytes32 public constant SETENV_ROLE = keccak256("SETENV_ROLE");
    bytes32 public constant REMOVE_ROLE = keccak256("REMOVE_ROLE");
    bytes32 public constant INIT_ROLE = keccak256("INIT_ROLE");

    struct matrix6 {
        address vertex;
        address upper;
        address[2] upperLayer;
        address[4] lowerLayer;
        uint256 amount;
        bool isReVote;
    }

    struct matrix3 {
        address vertex;
        address[3] upperLayer;
        uint256 amount;
        bool isReVote;
    }

    struct accountInfo {
        bool isRegister;
        address referRecommender;
        uint256 currentMaxGrade;
        mapping(uint256 => bool) gradeExist;
        mapping(uint256 => matrix6) matrix6Grade;
        mapping(uint256 => matrix3) matrix3Grade;
        mapping(uint256 => bool) isPauseAutoNewGrant;
        mapping(uint256 => bool) isPauseAutoReVote;
    }

    mapping(address => accountInfo) private accountInfoList;

    address public noReferPlatform;
    address public feePlatform;
    uint256 public maxAuto = 20;
    uint256 public baseRewardRate = 1e18;
    uint256 public baseLocationPrice = 5e6;
    uint256 public basePlatformRate = 25e4;

    IERC20 public USDToken;
    IERC20 public Token;

    uint256 public constant maxGrade = 12;
    uint256 private rate = 1e6;
    uint256 private perAutoTimes = 0;

    event NewLocationEvent(
        address indexed account,
        address indexed location,
        uint256 grade,
        uint256 index
    );

    // 0xfD48259b3d097C66BE6BF53d93172e284016f7842 合约所有人后
    constructor(address _usdt, address _token, address _noReferPlatform, address _feePlatform, address _initAcc) {
        // 0x8EdE604d2cA3Ba41CEE27B303EC9912295E8d296
        _grantRole(DEFAULT_ADMIN_ROLE, 0x50A30c6dE1dE43B7eB5be8774Db8bac45f3007A3);
        // 0x8EdE604d2cA3Ba41CEE27B303EC9912295E8d296
        _grantRole(SETENV_ROLE, 0x50A30c6dE1dE43B7eB5be8774Db8bac45f3007A3);
        // 0x8EdE604d2cA3Ba41CEE27B303EC9912295E8d296
        _grantRole(REMOVE_ROLE, 0x50A30c6dE1dE43B7eB5be8774Db8bac45f3007A3);
        // 0x8EdE604d2cA3Ba41CEE27B303EC9912295E8d296
        _grantRole(INIT_ROLE, 0x50A30c6dE1dE43B7eB5be8774Db8bac45f3007A3);

        USDToken = IERC20(_usdt); // 0xc2132d05d31c914a87c6611c10748aeb04b58e8f
        Token = IERC20(_token); // 0xB5864A43c12Df55Ff7320595f800DeB7867e3050
        noReferPlatform = _noReferPlatform; // 0x166483d95aC7b65D62F07CE11BFA6abcA37de62A
        feePlatform = _feePlatform;  // 0xb2018e56be5B77A6797FE2fa543663D487b5d8D7

        accountInfoList[_initAcc].isRegister = true; // 0x5eED93D68526056B75542005e836dfb49d62a3c1
    }

    function refer(address _refer) public {
        require(
            accountInfoList[_refer].referRecommender != _msgSender() &&
            accountInfoList[_msgSender()].referRecommender == address(0) &&
            _refer != address(0),
            "param account error"
        );
        require(accountInfoList[_refer].isRegister, "refer not registered");
        accountInfoList[_msgSender()].isRegister = true;
        accountInfoList[_msgSender()].referRecommender = _refer;
    }

    function newLocation(uint256 newGrade) public {
        require(newGrade > 0 && newGrade <= maxGrade, "param newGrade error");
        _newLocation(_msgSender(), newGrade);
        perAutoTimes = 0;
    }

    function openAutoGrade(uint256 grade) public {
        require(accountInfoList[_msgSender()].isPauseAutoNewGrant[grade], "already open AutoGrade");
        require(grade > 0 && grade < maxGrade, "param grade error");
        require(accountInfoList[_msgSender()].gradeExist[grade], "grade not exist");
        uint256 member = matrixMember(grade);
        if (member == 3) {
            require(accountInfoList[_msgSender()].matrix3Grade[grade].upperLayer[0] == address(0), "not close");
        } else {
            require(accountInfoList[_msgSender()].matrix6Grade[grade].lowerLayer[1] == address(0), "not close");
            require(accountInfoList[_msgSender()].matrix6Grade[grade].lowerLayer[2] == address(0), "not close");
        }
        accountInfoList[_msgSender()].isPauseAutoNewGrant[grade] = false;
    }

    function closeAutoGrade(uint256 grade) public {
        require(!accountInfoList[_msgSender()].isPauseAutoNewGrant[grade], "already close AutoGrade");
        require(grade > 0 && grade < maxGrade, "param grade error");
        require(accountInfoList[_msgSender()].gradeExist[grade], "grade not exist");
        uint256 member = matrixMember(grade);
        if (member == 3) {
            require(accountInfoList[_msgSender()].matrix3Grade[grade].upperLayer[0] == address(0), "not close");
        } else {
            require(accountInfoList[_msgSender()].matrix6Grade[grade].lowerLayer[1] == address(0), "not close");
            require(accountInfoList[_msgSender()].matrix6Grade[grade].lowerLayer[2] == address(0), "not close");
        }
        accountInfoList[_msgSender()].isPauseAutoNewGrant[grade] = true;
    }

    function openAutoVote(uint256 grade) public {
        require(accountInfoList[_msgSender()].isPauseAutoReVote[grade], "already open AutoVote");
        require(grade > 0 && grade < maxGrade && accountInfoList[_msgSender()].gradeExist[grade], "param grade error");
        accountInfoList[_msgSender()].isPauseAutoReVote[grade] = false;
    }

    function closeAutoVote(uint256 grade) public {
        require(!accountInfoList[_msgSender()].isPauseAutoReVote[grade], "already close AutoVote");
        accountInfoList[_msgSender()].isPauseAutoReVote[grade] = true;
    }

    function setBasePrice(uint256 amount) public onlyRole(SETENV_ROLE) {
        baseLocationPrice = amount;
    }

    function setMaxAuto(uint256 max) public onlyRole(SETENV_ROLE) {
        maxAuto = max;
    }

    function setBasePlatformRate(uint256 newRate) public onlyRole(SETENV_ROLE) {
        basePlatformRate = newRate;
    }

    function setNoReferPlatform(address platform) public onlyRole(SETENV_ROLE) {
        noReferPlatform = platform;
    }

    function setFeePlatform(address platform) public onlyRole(SETENV_ROLE) {
        feePlatform = platform;
    }

    function removeLiquidity(address token, address account, uint256 amount) public onlyRole(REMOVE_ROLE) {
        IERC20(token).transfer(account, amount);
    }

    function initRefer(address upper, address lower) public onlyRole(INIT_ROLE) {
        if (!accountInfoList[upper].isRegister) {
            accountInfoList[upper].isRegister = true;
        }
        if (!accountInfoList[lower].isRegister) {
            accountInfoList[lower].isRegister = true;
        }
        require(accountInfoList[lower].referRecommender == address(0) && accountInfoList[upper].referRecommender != lower);
        accountInfoList[lower].referRecommender = upper;
    }

    function _newLocation(address _account, uint256 _newGrade) internal {
        require(!accountInfoList[_account].gradeExist[_newGrade], "this grade already exists");
        require(accountInfoList[_account].currentMaxGrade.add(1) >= _newGrade, "new grade is more than the current");
        require(accountInfoList[_account].isRegister, "account must has recommender");
        uint256 price = currentPrice(_newGrade);
        USDToken.transferFrom(_account, address(this), price);
        Token.mint(_account, price.mul(baseRewardRate).div(rate));
        _addLocations(_account, accountInfoList[_account].referRecommender, _newGrade);
    }

    function _addLocations(address _account, address _vertex, uint256 _newGrade) internal {
        uint256 types = matrixMember(_newGrade);
        if (_vertex != address(0)) {
            if (!accountInfoList[_vertex].gradeExist[_newGrade]) {
                _vertex = address(0);
                USDToken.transfer(noReferPlatform, currentPrice(_newGrade));
                accountInfoList[_account].gradeExist[_newGrade] = true;
                if (accountInfoList[_account].currentMaxGrade < _newGrade) {
                    accountInfoList[_account].currentMaxGrade = _newGrade;
                }
                return;
            }
        } else {
            USDToken.transfer(noReferPlatform, currentPrice(_newGrade));
            accountInfoList[_account].gradeExist[_newGrade] = true;
            if (accountInfoList[_account].currentMaxGrade < _newGrade) {
                accountInfoList[_account].currentMaxGrade = _newGrade;
            }
            return;
        }
        if (types == 6) {
            if (_vertex != address(0)) {
                _addLocationsTo6(_account, _vertex, _newGrade);
            }
        }
        if (types == 3) {
            accountInfoList[_account].matrix3Grade[_newGrade].vertex = _vertex;
            if (_vertex != address(0)) {
                _addLocationsTo3(_account, _vertex, _newGrade);
            }
        }
        accountInfoList[_account].gradeExist[_newGrade] = true;
        if (accountInfoList[_account].currentMaxGrade < _newGrade) {
            accountInfoList[_account].currentMaxGrade = _newGrade;
        }
    }

    function _addLocationsTo6(address _account, address _vertex, uint256 _grade) internal {
        if (accountInfoList[_vertex].matrix6Grade[_grade].upperLayer[0] == address(0) ||
            accountInfoList[_vertex].matrix6Grade[_grade].upperLayer[1] == address(0)) {
            if (accountInfoList[_vertex].matrix6Grade[_grade].upperLayer[0] == address(0)) {
                _set6Location(_vertex, _account, _grade, 0);
            } else {
                _set6Location(_vertex, _account, _grade, 1);
            }
        } else {
            for (uint256 i = 0; i < 4; i++) {
                if (accountInfoList[_vertex].matrix6Grade[_grade].lowerLayer[i] == address(0)) {
                    if (i == 0 || i == 1) {
                        address upper = accountInfoList[_vertex].matrix6Grade[_grade].upperLayer[0];
                        if (i == 0) {
                            if (accountInfoList[upper].matrix6Grade[_grade].upperLayer[0] == address(0)) {
                                _set6Location(upper, _account, _grade, 0);
                            }
                        }
                        if (i == 1) {
                            if (accountInfoList[upper].matrix6Grade[_grade].upperLayer[1] == address(0)) {
                                _set6Location(upper, _account, _grade, 1);
                            }
                        }
                    } else {
                        address upper = accountInfoList[_vertex].matrix6Grade[_grade].upperLayer[1];
                        if (i == 2) {
                            if (accountInfoList[upper].matrix6Grade[_grade].upperLayer[0] == address(0)) {
                                _set6Location(upper, _account, _grade, 0);
                            }
                        }
                        if (i == 3) {
                            if (accountInfoList[upper].matrix6Grade[_grade].upperLayer[1] == address(0)) {
                                _set6Location(upper, _account, _grade, 1);
                            }
                        }
                    }
                    return;
                }
            }
        }
    }

    function _addLocationsTo3(address _account, address _vertex, uint256 _grade) internal {
        if (!accountInfoList[_vertex].gradeExist[_grade]) {
            USDToken.transfer(noReferPlatform, currentPrice(_grade));
        } else {
            for (uint256 i = 0; i < 3; i++) {
                if (accountInfoList[_vertex].matrix3Grade[_grade].upperLayer[i] == address(0)) {
                    _set3Location(_vertex, _account, _grade, i);
                    return;
                }
            }
        }
    }

    function _set6Location(address _setKey, address _setValue, uint256 _setGrade, uint256 _setLocation) internal {
        if (_setLocation == 0) {
            accountInfoList[_setKey].matrix6Grade[_setGrade].upperLayer[0] = _setValue;
            if (accountInfoList[_setKey].matrix6Grade[_setGrade].upper != address(0)) {
                accountInfoList[_setValue].matrix6Grade[_setGrade].vertex = accountInfoList[_setKey].matrix6Grade[_setGrade].upper;
                accountInfoList[_setValue].matrix6Grade[_setGrade].upper = _setKey;
            } else {
                accountInfoList[_setValue].matrix6Grade[_setGrade].vertex = _setKey;
                accountInfoList[_setValue].matrix6Grade[_setGrade].upper = _setKey;
            }
            if (accountInfoList[_setValue].matrix6Grade[_setGrade].upper != address(0)) {
                if (
                    accountInfoList[accountInfoList[_setValue].matrix6Grade[_setGrade].vertex].matrix6Grade[_setGrade].upperLayer[1] == _setKey
                ) {
                    if (accountInfoList[accountInfoList[_setValue].matrix6Grade[_setGrade].vertex].matrix6Grade[_setGrade].lowerLayer[2] == address(0)) {
                        _set6Location(accountInfoList[_setValue].matrix6Grade[_setGrade].vertex, _setValue, _setGrade, 4);
                    }
                } else if (
                    accountInfoList[accountInfoList[_setValue].matrix6Grade[_setGrade].vertex].matrix6Grade[_setGrade].upperLayer[0] == _setKey
                ) {
                    if (accountInfoList[accountInfoList[_setValue].matrix6Grade[_setGrade].vertex].matrix6Grade[_setGrade].lowerLayer[0] == address(0)) {
                        _set6Location(accountInfoList[_setValue].matrix6Grade[_setGrade].vertex, _setValue, _setGrade, 2);
                    }
                }
            }
            if (
                accountInfoList[accountInfoList[_setValue].matrix6Grade[_setGrade].upper].matrix6Grade[_setGrade].vertex == address(0)
            ) {
                USDToken.transfer(noReferPlatform, currentPrice(_setGrade));
            }
            emit NewLocationEvent(_setValue, _setKey, _setGrade, 1);
            return;
        }
        if (_setLocation == 1) {
            accountInfoList[_setKey].matrix6Grade[_setGrade].upperLayer[1] = _setValue;
            if (accountInfoList[_setKey].matrix6Grade[_setGrade].upper != address(0)) {
                accountInfoList[_setValue].matrix6Grade[_setGrade].vertex = accountInfoList[_setKey].matrix6Grade[_setGrade].upper;
                accountInfoList[_setValue].matrix6Grade[_setGrade].upper = _setKey;
            } else {
                accountInfoList[_setValue].matrix6Grade[_setGrade].vertex = _setKey;
                accountInfoList[_setValue].matrix6Grade[_setGrade].upper = _setKey;
            }
            if (accountInfoList[_setValue].matrix6Grade[_setGrade].upper != address(0)) {
                if (
                    accountInfoList[accountInfoList[_setValue].matrix6Grade[_setGrade].vertex].matrix6Grade[_setGrade].upperLayer[1] == _setKey
                ) {
                    if (accountInfoList[accountInfoList[_setValue].matrix6Grade[_setGrade].vertex].matrix6Grade[_setGrade].lowerLayer[3] == address(0)) {
                        _set6Location(accountInfoList[_setValue].matrix6Grade[_setGrade].vertex, _setValue, _setGrade, 5);
                    }
                } else if (
                    accountInfoList[accountInfoList[_setValue].matrix6Grade[_setGrade].vertex].matrix6Grade[_setGrade].upperLayer[0] == _setKey
                ) {
                    if (accountInfoList[accountInfoList[_setValue].matrix6Grade[_setGrade].vertex].matrix6Grade[_setGrade].lowerLayer[1] == address(0)) {
                        _set6Location(accountInfoList[_setValue].matrix6Grade[_setGrade].vertex, _setValue, _setGrade, 3);
                    }
                }
            }
            if (
                accountInfoList[accountInfoList[_setValue].matrix6Grade[_setGrade].upper].matrix6Grade[_setGrade].vertex == address(0)
            ) {
                USDToken.transfer(noReferPlatform, currentPrice(_setGrade));
            }
            emit NewLocationEvent(_setValue, _setKey, _setGrade, 2);
            return;
        }
        if (_setLocation == 2) {
            accountInfoList[_setKey].matrix6Grade[_setGrade].lowerLayer[0] = _setValue;
            if (accountInfoList[_setValue].matrix6Grade[_setGrade].upper == address(0)) {
                accountInfoList[_setValue].matrix6Grade[_setGrade].upper = accountInfoList[_setKey].matrix6Grade[_setGrade].upperLayer[0];
            }
            if (accountInfoList[accountInfoList[_setValue].matrix6Grade[_setGrade].upper].matrix6Grade[_setGrade].upperLayer[0] == address(0)) {
                _set6Location(accountInfoList[_setValue].matrix6Grade[_setGrade].upper, _setValue, _setGrade, 0);
            }
            accountInfoList[_setValue].matrix6Grade[_setGrade].vertex = _setKey;
            emit NewLocationEvent(_setValue, _setKey, _setGrade, 3);
            USDToken.transfer(_setKey, currentPrice(_setGrade));
            return;
        }
        if (_setLocation == 3) {
            accountInfoList[_setKey].matrix6Grade[_setGrade].lowerLayer[1] = _setValue;
            if (accountInfoList[_setValue].matrix6Grade[_setGrade].upper == address(0)) {
                accountInfoList[_setValue].matrix6Grade[_setGrade].upper = accountInfoList[_setKey].matrix6Grade[_setGrade].upperLayer[0];
            }
            if (accountInfoList[accountInfoList[_setValue].matrix6Grade[_setGrade].upper].matrix6Grade[_setGrade].upperLayer[1] == address(0)) {
                _set6Location(accountInfoList[_setValue].matrix6Grade[_setGrade].upper, _setValue, _setGrade, 1);
            }
            accountInfoList[_setValue].matrix6Grade[_setGrade].vertex = _setKey;
            emit NewLocationEvent(_setValue, _setKey, _setGrade, 4);
            _should6AutoNewGrant(_setKey, _setGrade);
            _should6AutoReVote(_setKey, _setGrade);
            return;
        }
        if (_setLocation == 4) {
            accountInfoList[_setKey].matrix6Grade[_setGrade].lowerLayer[2] = _setValue;
            if (accountInfoList[_setValue].matrix6Grade[_setGrade].upper == address(0)) {
                accountInfoList[_setValue].matrix6Grade[_setGrade].upper = accountInfoList[_setKey].matrix6Grade[_setGrade].upperLayer[1];
            }
            if (accountInfoList[accountInfoList[_setValue].matrix6Grade[_setGrade].upper].matrix6Grade[_setGrade].upperLayer[0] == address(0)) {
                _set6Location(accountInfoList[_setValue].matrix6Grade[_setGrade].upper, _setValue, _setGrade, 0);
            }
            accountInfoList[_setValue].matrix6Grade[_setGrade].vertex = _setKey;
            emit NewLocationEvent(_setValue, _setKey, _setGrade, 5);
            _should6AutoNewGrant(_setKey, _setGrade);
            return;
        }
        if (_setLocation == 5) {
            accountInfoList[_setKey].matrix6Grade[_setGrade].lowerLayer[3] = _setValue;
            if (accountInfoList[_setValue].matrix6Grade[_setGrade].upper == address(0)) {
                accountInfoList[_setValue].matrix6Grade[_setGrade].upper = accountInfoList[_setKey].matrix6Grade[_setGrade].upperLayer[1];
            }
            if (accountInfoList[accountInfoList[_setValue].matrix6Grade[_setGrade].upper].matrix6Grade[_setGrade].upperLayer[1] == address(0)) {
                _set6Location(accountInfoList[_setValue].matrix6Grade[_setGrade].upper, _setValue, _setGrade, 1);
            }
            accountInfoList[_setValue].matrix6Grade[_setGrade].vertex = _setKey;
            emit NewLocationEvent(_setValue, _setKey, _setGrade, 6);
            _should6AutoReVote(_setKey, _setGrade);
            return;
        }
    }

    function _set3Location(address _setKey, address _setValue, uint256 _setGrade, uint256 _setLocation) internal {
        accountInfoList[_setKey].matrix3Grade[_setGrade].upperLayer[_setLocation] = _setValue;
        emit NewLocationEvent(_setValue, _setKey, _setGrade, _setLocation.add(1));
        if (_setLocation == 0) {
            _should3AutoNewGrant(_setKey, _setGrade);
        }
        if (_setLocation == 1) {
            _should3AutoNewGrant(_setKey, _setGrade);
        }
        if (_setLocation == 2) {
            _should3AutoReVote(_setKey, _setGrade);
        }
    }

    function _should6AutoNewGrant(address _account, uint256 _grade) internal {
        if (perAutoTimes >= maxAuto) {
            require(false, "server timeout, please wait for some time, and try again");
        }

        if (
            accountInfoList[_account].currentMaxGrade >= _grade.add(1) &&
            accountInfoList[_account].isPauseAutoNewGrant[_grade]
            ) {
                uint256 price = currentPrice(_grade);
                if (accountInfoList[_account].matrix6Grade[_grade].amount != 1) {
                    price = price.add(accountInfoList[_account].matrix6Grade[_grade].amount);
                    accountInfoList[_account].matrix6Grade[_grade].amount = 1;
                }
                USDToken.transfer(_account, price);
                return;
        }
        if (accountInfoList[_account].currentMaxGrade >= _grade.add(1)) {
            uint256 price = currentPrice(_grade);
            if (!accountInfoList[_account].isPauseAutoNewGrant[_grade]) {  
                if (accountInfoList[_account].matrix6Grade[_grade].amount == 0) {
                    uint256 platformRate = price.mul(basePlatformRate).div(rate);
                    USDToken.transfer(feePlatform, platformRate);
                    USDToken.transfer(_account, price.sub(platformRate));
                } else {
                    USDToken.transfer(_account, price);
                }
            } else {
                if (accountInfoList[_account].matrix6Grade[_grade].isReVote) {
                    USDToken.transfer(_account, price);
                } else {
                    uint256 platformRate = price.mul(basePlatformRate).div(rate);
                    USDToken.transfer(feePlatform, platformRate);
                    USDToken.transfer(_account, price.sub(platformRate));   
                }
            }
            return;
        } else {
            if (
                accountInfoList[_account].matrix6Grade[_grade].lowerLayer[1] != address(0) &&
                accountInfoList[_account].matrix6Grade[_grade].lowerLayer[2] != address(0)
            ) {
                if (!accountInfoList[_account].isPauseAutoNewGrant[_grade]) {
                    Token.mint(_account, currentPrice(_grade.add(1)).mul(baseRewardRate).div(rate));
                    perAutoTimes++;
                    address vertex = accountInfoList[_account].referRecommender;
                    if (!accountInfoList[vertex].gradeExist[_grade.add(1)]) {
                        vertex = address(0);
                    }
                    _addLocations(_account, vertex, _grade.add(1));
                } else {
                    uint256 price = currentPrice(_grade);
                    uint256 platformRate = price.mul(basePlatformRate).div(rate);
                    USDToken.transfer(feePlatform, platformRate);
                    USDToken.transfer(_account, price.sub(platformRate));
                }
            } else {
                if (accountInfoList[_account].isPauseAutoNewGrant[_grade]) {
                    uint256 price = currentPrice(_grade);
                    uint256 platformRate = price.mul(basePlatformRate).div(rate);
                    USDToken.transfer(feePlatform, platformRate);
                    USDToken.transfer(_account, price.sub(platformRate));
                } else {
                    accountInfoList[_account].matrix6Grade[_grade].amount = currentPrice(_grade);
                }
            }
        }
    }

    function _should6AutoReVote(address _account, uint256 _grade) internal {
        if (perAutoTimes >= maxAuto) {
            require(false, "server timeout, please wait for some time, and try again");
        }
        if (
            accountInfoList[_account].matrix6Grade[_grade].lowerLayer[0] != address(0) &&
            accountInfoList[_account].matrix6Grade[_grade].lowerLayer[1] != address(0) &&
            accountInfoList[_account].matrix6Grade[_grade].lowerLayer[2] != address(0) &&
            accountInfoList[_account].matrix6Grade[_grade].lowerLayer[3] != address(0)
        ) {
            if (!accountInfoList[_account].isPauseAutoReVote[_grade]) {
                Token.mint(_account, currentPrice(_grade).mul(baseRewardRate).div(rate));
                perAutoTimes++;
                address recommender = accountInfoList[_account].referRecommender;
                if (accountInfoList[recommender].gradeExist[_grade]) {
                    _addLocations(_account, recommender, _grade);
                } else {
                    _addLocations(_account, address(0), _grade);
                }
                resetAccount6Matrix(_account, _grade);
                accountInfoList[_account].matrix6Grade[_grade].isReVote = true;
            } else {
                uint256 price = currentPrice(_grade);
                uint256 platformRate = price.mul(basePlatformRate).div(rate);
                USDToken.transfer(feePlatform, platformRate);
                USDToken.transfer(_account, price.sub(platformRate));
                accountInfoList[_account].gradeExist[_grade] = false;
                resetAccount6Matrix(_account, _grade);
            }
        }
    }

    function _should3AutoNewGrant(address _account, uint256 _grade) internal {
        if (perAutoTimes >= maxAuto) {
            require(false, "server timeout, please wait for some time, and try again");
        }
        if (_grade == maxGrade) {
            uint256 price = currentPrice(maxGrade);
            if (!accountInfoList[_account].isPauseAutoNewGrant[_grade]) {
                USDToken.transfer(_account, price);
            } else {
                uint256 platformRate = price.mul(basePlatformRate).div(rate);
                USDToken.transfer(feePlatform, platformRate);
                USDToken.transfer(_account, price.sub(platformRate));
            }
            return;
        }

        if (
            accountInfoList[_account].currentMaxGrade >= _grade.add(1) &&
            accountInfoList[_account].isPauseAutoNewGrant[_grade]
            ) {
                uint256 price = currentPrice(_grade);
                if (accountInfoList[_account].matrix3Grade[_grade].amount != 1) {
                    price = price.add(accountInfoList[_account].matrix3Grade[_grade].amount);
                    accountInfoList[_account].matrix3Grade[_grade].amount = 1;
                }
                USDToken.transfer(_account, price);
                return;
        }
        if (accountInfoList[_account].currentMaxGrade >= _grade.add(1)) {
            uint256 price = currentPrice(_grade);
            if (!accountInfoList[_account].isPauseAutoNewGrant[_grade]) {
                if (accountInfoList[_account].matrix3Grade[_grade].amount == 0) {
                    uint256 platformRate = price.mul(basePlatformRate).div(rate);
                    USDToken.transfer(feePlatform, platformRate);
                    USDToken.transfer(_account, price.sub(platformRate));
                } else {
                    USDToken.transfer(_account, price);
                }
            } else {        
                if (accountInfoList[_account].matrix3Grade[_grade].isReVote) {
                    USDToken.transfer(_account, price);
                } else {
                    uint256 platformRate = price.mul(basePlatformRate).div(rate);
                    USDToken.transfer(feePlatform, platformRate);
                    USDToken.transfer(_account, price.sub(platformRate));  
                }
            }
            return;
        } else {
            if (
                accountInfoList[_account].matrix3Grade[_grade].upperLayer[0] != address(0) &&
                accountInfoList[_account].matrix3Grade[_grade].upperLayer[1] != address(0)
            ) {
                if (!accountInfoList[_account].isPauseAutoNewGrant[_grade]) {
                    Token.mint(_account, currentPrice(_grade.add(1)).mul(baseRewardRate).div(rate));
                    perAutoTimes++;
                    address vertex = address(0);
                    if (accountInfoList[accountInfoList[_account].referRecommender].gradeExist[_grade.add(1)]) {
                        vertex = accountInfoList[_account].referRecommender;
                    }
                    _addLocations(_account, vertex, _grade.add(1));
                } else {
                    uint256 price = currentPrice(_grade.add(1));
                    uint256 platformRate = price.mul(basePlatformRate).div(rate);
                    USDToken.transfer(feePlatform, platformRate);
                    USDToken.transfer(_account, price.sub(platformRate));
                }
            } else {
                if (accountInfoList[_account].isPauseAutoNewGrant[_grade]) {
                    uint256 price = currentPrice(_grade);
                    uint256 platformRate = price.mul(basePlatformRate).div(rate);
                    USDToken.transfer(feePlatform, platformRate);
                    USDToken.transfer(_account, price.sub(platformRate));
                } else {
                    accountInfoList[_account].matrix3Grade[_grade].amount = currentPrice(_grade);
                }
            }
        }
    }

    function _should3AutoReVote(address _account, uint256 _grade) internal {
        if (perAutoTimes >= maxAuto) {
            require(false, "server timeout, please wait for some time, and try again");
        }
        if (
            accountInfoList[_account].matrix3Grade[_grade].upperLayer[0] != address(0) &&
            accountInfoList[_account].matrix3Grade[_grade].upperLayer[1] != address(0) &&
            accountInfoList[_account].matrix3Grade[_grade].upperLayer[2] != address(0)
        ) {
            if (!accountInfoList[_account].isPauseAutoReVote[_grade]) {
                Token.mint(_account, currentPrice(_grade).mul(baseRewardRate).div(rate));
                perAutoTimes++;
                address recommender = accountInfoList[_account].referRecommender;
                if (accountInfoList[recommender].gradeExist[_grade]) {
                    _addLocations(_account, recommender, _grade);
                } else {
                    _addLocations(_account, address(0), _grade);
                }
                resetAccount3Matrix(_account, _grade);
                accountInfoList[_account].matrix3Grade[_grade].isReVote = true;
            } else {
                uint256 price = currentPrice(_grade);
                uint256 platformRate = price.mul(basePlatformRate).div(rate);
                USDToken.transfer(feePlatform, platformRate);
                USDToken.transfer(_account, price.sub(platformRate));
                accountInfoList[_account].gradeExist[_grade] = false;
                resetAccount3Matrix(_account, _grade);
            }
        }
    }

    function resetAccount6Matrix(address _account, uint256 _grade) internal {
        accountInfoList[_account].matrix6Grade[_grade].upperLayer[0] = address(0);
        accountInfoList[_account].matrix6Grade[_grade].upperLayer[1] = address(0);
        accountInfoList[_account].matrix6Grade[_grade].lowerLayer[0] = address(0);
        accountInfoList[_account].matrix6Grade[_grade].lowerLayer[1] = address(0);
        accountInfoList[_account].matrix6Grade[_grade].lowerLayer[2] = address(0);
        accountInfoList[_account].matrix6Grade[_grade].lowerLayer[3] = address(0);
    }

    function resetAccount3Matrix(address _account, uint256 _grade) internal {
        accountInfoList[_account].matrix3Grade[_grade].upperLayer[0] = address(0);
        accountInfoList[_account].matrix3Grade[_grade].upperLayer[1] = address(0);
        accountInfoList[_account].matrix3Grade[_grade].upperLayer[2] = address(0);
    }

    function matrixMember(uint256 _grade) internal pure returns (uint256) {
        require(_grade > 0 && _grade <= maxGrade, "error grade");
        if (_grade == 3 || _grade == 6 || _grade == 9 || _grade == maxGrade) {return 3;}
        return 6;
    }

    function currentPrice(uint256 _grade) public view returns (uint256) {
        return baseLocationPrice.mul(2 ** _grade.sub(1));
    }

    function accountGrade(address account, uint256 grade) public view returns (address[6] memory array) {
        require(account != address(0) && grade > 0 && grade <= maxGrade, "param error");
        uint256 member = matrixMember(grade);
        if (member == 3) {
            array[0] = accountInfoList[account].matrix3Grade[grade].upperLayer[0];
            array[1] = accountInfoList[account].matrix3Grade[grade].upperLayer[1];
            array[2] = accountInfoList[account].matrix3Grade[grade].upperLayer[2];
        }
        if (member == 6) {
            array[0] = accountInfoList[account].matrix6Grade[grade].upperLayer[0];
            array[1] = accountInfoList[account].matrix6Grade[grade].upperLayer[1];
            array[2] = accountInfoList[account].matrix6Grade[grade].lowerLayer[0];
            array[3] = accountInfoList[account].matrix6Grade[grade].lowerLayer[1];
            array[4] = accountInfoList[account].matrix6Grade[grade].lowerLayer[2];
            array[5] = accountInfoList[account].matrix6Grade[grade].lowerLayer[3];
        }
        return array;
    }

    function accInfo(address account, uint256 grade) public view returns (bool isPauseAutoNewGrant, bool isPauseAutoReVote) {
        return (accountInfoList[account].isPauseAutoNewGrant[grade], accountInfoList[account].isPauseAutoReVote[grade]);
    }

    function referRecommender(address account) public view returns (address) {
        return accountInfoList[account].referRecommender;
    }

    function latestGrade(address account) public view returns (uint256) {
        return accountInfoList[account].currentMaxGrade;
    }

    function accmatrixAmount(address account, uint256 grade) public view returns (uint256) {
        if (grade == 3 || grade == 6 || grade == 9 || grade == 12) {
            return accountInfoList[account].matrix3Grade[grade].amount;
        } else {
            return accountInfoList[account].matrix6Grade[grade].amount;
        }   
    }

}