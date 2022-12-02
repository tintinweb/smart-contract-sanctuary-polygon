/**
 *Submitted for verification at polygonscan.com on 2022-12-02
*/

// SPDX-License-Identifier: MIT
pragma solidity = 0.8.12;

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
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

contract pairHelper is Ownable {
    address public USDT;
    address public ETH;

    constructor (address _USDT,address _ETH) {
        setConfig(_USDT,_ETH);
    }

    function setConfig(address _USDT,address _ETH) public onlyOwner {
        USDT = _USDT;
        ETH = _ETH;
    }

    function getPairInfo(IAocoFactory _factoryAddress, address _token,address _defaultToken) private view returns(uint256 reserve) {
        address pair = _factoryAddress.getPair(_token, _defaultToken);
        try IAocoPair(pair).token0() returns(address token_) {
            (uint256 reserve0, uint256 reserve1,) = IAocoPair(pair).getReserves();
            if (token_ == _token) {
                reserve = reserve0;
            } else {
                reserve = reserve1;
            }
        } catch{
            reserve = 0;
        }
    }

    struct returnItem {
        IAocoFactory _factoryAddress;
        uint256 reserve_USDT;
        uint256 reserve_ETH;
    }

    function getPairInfo2(IAocoFactory _factoryAddress, address _token) private view returns(returnItem memory pairInfo_) {
        pairInfo_ = new returnItem[](1)[0];
        pairInfo_._factoryAddress = _factoryAddress;
        pairInfo_.reserve_USDT = getPairInfo(_factoryAddress,_token, USDT);
        pairInfo_.reserve_ETH = getPairInfo(_factoryAddress,_token, ETH);
    }

    function massGetPairInfo(IAocoFactory[] memory _factoryAddressList,address _token) public view returns(returnItem[] memory pairInfoList_) {
        pairInfoList_ = new returnItem[](_factoryAddressList.length);
        for (uint256 i=0;i<_factoryAddressList.length;i++) {
            pairInfoList_[i] = getPairInfo2(_factoryAddressList[i],_token);
        }
    }
}