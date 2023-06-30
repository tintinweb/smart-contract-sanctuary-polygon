// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./IERC20.sol";
import "./ERC721Holder.sol";



contract NetlyStake is ERC721, ERC721Holder {

    struct Stake {
        uint256 amount;
        uint256 startTime;
        uint256 tokenID;
    }

    ERC721 public NFT;
    IERC20 public TOKEN;

    uint256 public launchTime;
    bool private isActive = false;
    uint256 public maxStakeTime;
    uint256 private day = 86400;
    uint256 private price = 21;
    mapping (address => uint256) private _excluded;

    mapping (address => uint256[]) private _userBalance;

    mapping (address => Stake[]) public _userStakes;

    mapping (address => uint256) private _lastReward;

    mapping (address => uint256) public _totalStake;

    constructor() ERC721("Netlyfans", "NF") {
        NFT = ERC721(0x3866Eb012aec767b6e8A993Ccc3607fa0470Ef68);
        TOKEN = IERC20(0xAc020D90410103f579Bd67e46771f82E09517e31);
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
        uint256[] memory blc = _checkIDs(_msgSender(), _amount);
        if(_amount > 1) {
        for(uint256 i = 0; i < _amount; i++){
                NFT.safeTransferFrom(_msgSender(), address(this), blc[i], "0x00");
                _userStakes[_msgSender()].push(Stake(1, block.timestamp, blc[i]));
                _totalStake[_msgSender()] += 1; 
        }  
        } else {
                NFT.safeTransferFrom(_msgSender(), address(this), blc[0], "0x00");
                _userStakes[_msgSender()].push(Stake(1, block.timestamp, blc[0]));
                _totalStake[_msgSender()] += 1;
        }
        delete _userBalance[_msgSender()];
    }

    function _checkIDs(address _owner, uint256 _amount) internal returns  (uint256[] memory) {
        uint256 _maxsupply = NFT.totalSupply();
        uint256 j = 0;
        for(uint i = 1; i <= _maxsupply; i++){
            if(NFT.ownerOf(i) == _owner){
                    if(j < _amount){
                        _userBalance[_owner].push(i);
                        j += 1;
                    } else {
                        break;
                    }
                   
                
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
            if(_userStakes[_user][i].startTime != 0){
            if(_lastReward[_user] == 0) {
            startTime = _userStakes[_user][i].startTime; 
        }
            else {
                startTime = _lastReward[_user];
            }
            totHours = (endTime - startTime) / 60 / 60;
            reward += totHours * _userStakes[_user][i].amount * price / 10;
        }
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

    function _payRewards(uint256 reward, address _addr) internal {
        uint256 tAmount = reward * 10 ** 18;
        TOKEN.transfer(_addr, tAmount);
        _lastReward[_addr] = block.timestamp;
    }

    function _unstake(address _addr) internal {
        require(_userStakes[_addr].length > 0, "You must stake an NFT first!");
        for(uint i = _excluded[_addr]; i < _userStakes[_addr].length; i++) {
            if(_userStakes[_addr][i].tokenID != 0){
             NFT.safeTransferFrom(address(this), _addr, _userStakes[_addr][i].tokenID, "0x00");
             _totalStake[_msgSender()] -= 1;
            }
        }
        _erase(_addr);
    }

    function _erase(address _addr) internal {
        uint256 length = _userStakes[_addr].length;
            for(uint256 i = _excluded[_addr]; i < length; i++) {
                delete _userStakes[_addr][i];
                _excluded[_addr] += 1;
            }
    }


}