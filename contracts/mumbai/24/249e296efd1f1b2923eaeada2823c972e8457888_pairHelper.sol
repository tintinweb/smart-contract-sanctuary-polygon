/**
 *Submitted for verification at polygonscan.com on 2023-03-02
*/

// SPDX-License-Identifier: MIT
pragma solidity = 0.8.6;

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

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
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


interface IAocoFactory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

interface IAocoPair {
    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves() external view returns (uint256 reserve0, uint256 reserve1, uint256 blockTimestampLast);
}

interface IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);
}

contract pairHelper is Ownable {
    address public USDT;
    address public ETH;

    struct tokenInfo {
        string name;
        string symbol;
        uint256 decimals;
        uint256 balance;
    }

    struct pairInfo {
        address token0;
        address token1;
        uint256 reserve0;
        uint256 reserve1;
    }

    struct configItem {
        address _USDT;
        address _ETH;
    }

    struct returnItem {
        IAocoFactory _factoryAddress;
        tokenInfo _tokenInfo;
        pairInfo _pairInfoForUSDT;
        pairInfo _pairInfoForETH;
    }

    constructor (configItem memory _configItem) {
        setConfig(_configItem);
    }

    function getTokenInfo(IERC20 _token, address _user) public view returns (tokenInfo memory _tokenInfo) {
        _tokenInfo.name = _token.name();
        _tokenInfo.symbol = _token.symbol();
        _tokenInfo.decimals = _token.decimals();
        _tokenInfo.balance = _token.balanceOf(_user);
    }

    function setConfig(configItem memory _configItem) public onlyOwner {
        USDT = _configItem._USDT;
        ETH = _configItem._ETH;
    }

    function getPairInfo(IAocoFactory _factoryAddress, address _token, address _defaultToken) private view returns (pairInfo memory _pairInfo) {
        address pair = _factoryAddress.getPair(_token, _defaultToken);
        if (pair != address(0)) {
            address token0 = IAocoPair(pair).token0();
            address token1 = IAocoPair(pair).token1();
            (uint256 reserve0, uint256 reserve1,) = IAocoPair(pair).getReserves();
            _pairInfo = pairInfo(token0, token1, reserve0, reserve1);
        }
    }

    function getPairInfo2(IAocoFactory _factoryAddress, address _token, address _user) private view returns (returnItem memory pairInfo_) {
        pairInfo_ = new returnItem[](1)[0];
        pairInfo_._factoryAddress = _factoryAddress;
        pairInfo_._tokenInfo = getTokenInfo(IERC20(_token), _user);
        pairInfo_._pairInfoForUSDT = getPairInfo(_factoryAddress, _token, USDT);
        pairInfo_._pairInfoForETH = getPairInfo(_factoryAddress, _token, ETH);
    }

    function massGetPairInfo(IAocoFactory[] memory _factoryAddressList, address _token, address _user) public view returns (returnItem[] memory pairInfoList_) {
        pairInfoList_ = new returnItem[](_factoryAddressList.length);
        for (uint256 i = 0; i < _factoryAddressList.length; i++) {
            pairInfoList_[i] = getPairInfo2(_factoryAddressList[i], _token, _user);
        }
    }
}