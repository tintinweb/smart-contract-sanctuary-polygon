/**
 *Submitted for verification at polygonscan.com on 2022-11-21
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.12;

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
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
        _setOwner(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(owner() == _msgSender(), "k002");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "k003");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract USDTPool is Ownable {
    IERC20 public USDT;

    struct userInfo {
        bool _canClaim;
        uint256 _maxAmount;
    }

    mapping(address => userInfo) public userInfoList;

    constructor(IERC20 _USDT) {
        USDT = _USDT;
    }

    event setClaimerListEvent(address _user, bool _status, uint256 _maxAmount, uint256 _time);
    event claimUSDTEvent(address _user, uint256 _amount, uint256 _time);

    function setClaimerList(address _user, bool _status, uint256 _maxAmount) external onlyOwner {
        if (_status == false || _maxAmount == 0) {
            _maxAmount = 0;
            _status = false;
        }
        userInfoList[_user]._canClaim = _status;
        userInfoList[_user]._maxAmount = _maxAmount;
        emit setClaimerListEvent(_user, _status, _maxAmount, block.timestamp);
    }

    function claimUSDT(uint256 _amount) external {
        require(userInfoList[msg.sender]._canClaim, "e001");
        require(_amount <= userInfoList[msg.sender]._maxAmount, "e002");
        USDT.transfer(msg.sender, _amount);
        emit claimUSDTEvent(msg.sender, _amount, block.timestamp);
    }

    function claimToken(IERC20 _token, uint256 _amount) external onlyOwner {
        _token.transfer(msg.sender, _amount);
    }

    function claimEth(uint256 _amount) external onlyOwner {
        payable(msg.sender).transfer(_amount);
    }

    receive() external payable {
    }
}