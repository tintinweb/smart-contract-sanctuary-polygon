/**
 *Submitted for verification at polygonscan.com on 2022-09-14
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IERC721 {
    function balanceOf(address) external view returns (uint256);
    function safeTransferMany(address, uint[] memory) external;
    function claim(address) external;
    function pending(address, address) external view returns (uint256);
}

interface IERC20 {
    function balanceOf(address) external view returns (uint256);
    function transfer(address, uint) external;
    function transferFrom(address, address, uint) external;
}

contract Staking {

    IERC721 public immutable nft;
    IERC20 public immutable tigusd;

    uint256 public totalStaked;
    uint256 public accRewardsPerToken;
    mapping(address => uint256) public userStaked;
    mapping(address => uint256) public userPaid;
    address public immutable treasury;
    address public immutable deployer;

    constructor (IERC721 _nft, IERC20 _tigusd, address _treasury) {
        nft = _nft;
        tigusd = _tigusd;
        treasury = _treasury;
        deployer = msg.sender;
    }

    function deposit(uint _amount) external {
        require(_amount + totalStaked <= 200000e18, "Capped");
        tigusd.transferFrom(msg.sender, address(this), _amount);
        _claim(msg.sender);
        userStaked[msg.sender] += _amount;
        totalStaked += _amount;
        userPaid[msg.sender] = accRewardsPerToken*userStaked[msg.sender]/1e18;
    }

    function withdrawAll() external {
        withdraw(userStaked[msg.sender]);
    }

    function withdraw(uint256 _amount) public {
        require(userStaked[msg.sender] >= _amount, "BadWithdraw");
        _claim(msg.sender);
        userStaked[msg.sender] -= _amount;
        totalStaked -= _amount;
        tigusd.transfer(msg.sender, _amount);
        userPaid[msg.sender] = accRewardsPerToken*userStaked[msg.sender]/1e18;
    }

    function claim() external {
        _claim(msg.sender);
    }

    function _claim(address _user) private {
        if (totalStaked == 0) return;
        uint256 _pending = nft.pending(address(this), address(tigusd));
        accRewardsPerToken += _pending*1e18/totalStaked;
        nft.claim(address(tigusd));
        tigusd.transfer(_user, userStaked[_user]*accRewardsPerToken/1e18-userPaid[_user]);
        userPaid[_user] = accRewardsPerToken*userStaked[_user]/1e18;
    }

    function pending(address _user) external view returns (uint256) {
        if (totalStaked == 0) return 0;
        return userStaked[_user]*(accRewardsPerToken+nft.pending(address(this), address(tigusd))*1e18/totalStaked)/1e18-userPaid[_user];
    }

    function recoverNft(uint256[] memory _ids) external {
        require(msg.sender == treasury || msg.sender == deployer, "!Permission");
        nft.safeTransferMany(treasury, _ids);
    }
}