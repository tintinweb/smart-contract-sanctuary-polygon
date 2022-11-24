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
        require(owner() == _msgSender(), "pool001");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "pool002");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract USDTPool2 is Ownable {
    IERC20 public USDT;
    mapping(address => bool) public userBlackList;
    mapping(address => bool) public callerList;
    uint256 public defaultMaxAmount;
    uint256 public swapRate = 10;
    uint256 public swapAllRate = 1000;
    mapping(address => uint256) public userMaxAmountList;

    constructor(IERC20 _USDT, uint256 _swapRate, uint256 _swapAllRate, uint256 _defaultMaxAmount) {
        setUSDT(_USDT);
        setSwapRates(_swapRate, _swapAllRate);
        setDefaultMaxAmount(_defaultMaxAmount);
    }

    function setUSDT(IERC20 _USDT) public onlyOwner {
        USDT = _USDT;
    }

    function setSwapRates(uint256 _swapRate, uint256 _swapAllRate) public onlyOwner {
        swapRate = _swapRate;
        swapAllRate = _swapAllRate;
    }

    function setDefaultMaxAmount(uint256 _defaultMaxAmount) public onlyOwner {
        defaultMaxAmount = _defaultMaxAmount;
    }

    function setUserMaxAmountList(address _user, uint256 _amount) external onlyOwner {
        userMaxAmountList[_user] = _amount;
    }

    function setCallerList(address _user, bool _status) external onlyOwner {
        callerList[_user] = _status;
    }

    function setUserBlackList(address _user, bool _status) external onlyOwner {
        userBlackList[_user] = _status;
    }

    function claimUSDT(address _user, uint256 _amount) external {
        require(callerList[msg.sender], "pool003");
        require(!userBlackList[_user], "pool004");
        if (userMaxAmountList[_user] == 0) {
            require(_amount <= defaultMaxAmount, "pool005");
        } else {
            require(_amount <= userMaxAmountList[_user], "pool006");
        }
        USDT.transfer(msg.sender, _amount);
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