// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./IERC20.sol";
import "./ERC721Holder.sol";



contract NetlyStake is ERC721, ERC721Holder {

    struct Stake {
        uint256 amount;
        uint256 startTime;
    }

    ERC721 public NFT;
    IERC20 public TOKEN;

    uint256 public launchTime;
    bool private isActive = false;
    uint256 public maxStakeTime;
    uint256 private day = 86400;
    uint256 private price = 1;

    mapping (address => uint256[]) private _userBalance;

    mapping (address => Stake[]) public _userStakes;

    mapping (address => mapping (uint256 => bool)) private _userIDsToStake;

    mapping (address => uint256) private _lastReward;

    mapping (address => uint256) private _lastTID;

    mapping (address => uint256) public _totalStake;

    constructor() ERC721("Netlyfans", "NF") {
        NFT = ERC721(0x3F7b4c01db4a78E22E656cca9b5E4C5Aa8114d34);
        TOKEN = IERC20(0xc663c8b94FD43283e34281b48271F08eE32E0c13);
    }

    function flipStake() public onlyOwner {
        isActive = true;
        launchTime = block.timestamp;
        maxStakeTime = block.timestamp + day * 60;
    }

    function stake(uint256 _amount) public {
        require(isActive, "Not allowed yet!");
        require(block.timestamp < maxStakeTime, "Stake period has come to an end.");
        require(NFT.balanceOf(_msgSender()) >= _amount,"Insufficient Balance");
        uint256[] memory blc = _checkIDs(_msgSender());
        uint256 _last;
        if(_amount > 1) {
        for(uint256 i =_lastTID[_msgSender()]; i < _lastTID[_msgSender()] + _amount; i++){
            if(!_userIDsToStake[_msgSender()][blc[i]]){
                NFT.safeTransferFrom(_msgSender(), address(this), blc[i], "0x00");
                _userIDsToStake[_msgSender()][blc[i]] = true;
                _userStakes[_msgSender()].push(Stake(1, block.timestamp));
                _last = blc[i];
                _totalStake[_msgSender()] += 1;
            } 
        }
        _lastTID[_msgSender()] = _last;  
        } else {
                NFT.safeTransferFrom(_msgSender(), address(this), blc[0], "0x00");
                _userIDsToStake[_msgSender()][blc[0]] = true;
                _userStakes[_msgSender()].push(Stake(1, block.timestamp));
                _last = blc[0];
                _totalStake[_msgSender()] += 1;
        }
    }

    function _checkIDs(address _owner) internal returns  (uint256[] memory) {
        uint256 _maxsupply = NFT.totalSupply();
        for(uint i = 1; i <= _maxsupply; i++){
            if(NFT.ownerOf(i) == _owner){
                if(!_userIDsToStake[_owner][i])
                _userBalance[_owner].push(i);
            }
        }
        return _userBalance[_owner];
    }

    function calculateRewards(address _user) public view returns (uint256) {
        require(_userStakes[_user].length > 0, "You haven't staked any NFT yet!");
        uint256 reward;
        uint256 totHours;
        uint256 endTime;
         uint256 startTime;
        if(maxStakeTime < block.timestamp){
            endTime = maxStakeTime;
        }
        else {
            endTime = block.timestamp;
        }

        for(uint i = 0; i < _userStakes[_user].length; i++) {
            if(_lastReward[_user] == 0) {
            startTime = _userStakes[_user][i].startTime; 
        }
            else {
                startTime = _lastReward[_user];
            }
            totHours = (endTime - startTime) / 60 / 60 / 24;
            reward += totHours * _userStakes[_user][i].amount * price;
        }
        return reward;
    }

    function claim() public {
        require(_userStakes[_msgSender()].length > 0, "You must stake an NFT first!");
        uint256 amount = calculateRewards(_msgSender());
        require(amount > 0, "Be Patient!");
        if(block.timestamp > maxStakeTime) {
            _unstake(_msgSender());
            _payRewards(amount, _msgSender());
        }
            _unstake(_msgSender());
    }

    function userDepositsNumber(address _addr) public view returns (uint256) {
        uint256 number = _userStakes[_addr].length;
        return number;
    }



    function _payRewards(uint256 reward, address _addr) internal {
        uint256 tAmount = reward * 10 ** 18;
        TOKEN.transfer(_addr, tAmount);
        _lastReward[_addr] = block.timestamp;
    }

    function _unstake(address _addr) internal {
        require(_userStakes[_addr].length > 0, "You must stake an NFT first!");
        for(uint i = 0; i < _userStakes[_addr].length; i++) {
             NFT.safeTransferFrom(address(this), _addr, _userBalance[_addr][i], "0x00");
             _userIDsToStake[_addr][i] = false;
        }
    }


}