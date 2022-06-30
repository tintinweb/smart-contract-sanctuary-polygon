/**
 *Submitted for verification at polygonscan.com on 2022-06-30
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

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

interface AnyswapV1ERC20 {
    function mint(address to, uint256 amount) external returns (bool);
    function burn(address from, uint256 amount) external returns (bool);
    function setMinter(address _auth) external;
    function applyMinter() external;
    function revokeMinter(address _auth) external;
    function changeVault(address newVault) external returns (bool);
    function depositVault(uint amount, address to) external returns (uint);
    function withdrawVault(address from, uint amount, address to) external returns (uint);
    function underlying() external view returns (address);
    function deposit(uint amount, address to) external returns (uint);
    function withdraw(uint amount, address to) external returns (uint);
}

interface AnyswapV4Router {
    function anySwapOutUnderlying(address token, address to, uint amount, uint toChainID) external;
}

contract XcapitMultichainRouter {

    constructor() {}

    address public anyswapRouterAddress;
    bool feeOn = false;
    uint256 feePercentage = 2;

    mapping (address => uint[]) public allowedTokens;

    function getFee() external view returns(bool _feeOn, uint256 _feePercentage)  {
        _feeOn = feeOn;
        _feePercentage = feePercentage;
    }

    function setFee(bool _fee, uint256 _percentage) external {
        if (feeOn) {
            require(feePercentage > 0 && feePercentage < 100, "Fee in a bad range");
        }
        feeOn = _fee;
        feePercentage = _percentage;
    }

    function setAnyswapRouterAddress(address _address) external {
        anyswapRouterAddress = _address;
    }

    function getAllowedMoves(address  _token) external view returns(uint[] memory _allowed) {
        _allowed = allowedTokens[_token];
    }

    function setAllowedMoves(address  _allowed, uint[] memory _destiny) external {
        allowedTokens[_allowed] = _destiny;
    }

    function move(
        address  _anyTokenAddress,
        address  _walletToAddress,
        uint  _hexAmount,
        uint  _chainToID
    ) external {
        bool validChain = false;
        address tokenAddress = AnyswapV1ERC20(_anyTokenAddress).underlying();
        require(allowedTokens[tokenAddress].length > 0, "Token not allowed");
        for(uint i = 0; i < allowedTokens[tokenAddress].length; i++) {
            if(allowedTokens[tokenAddress][i] == _chainToID) {
                validChain = true;
                break;
            }
        }
        require(validChain, "Chain to not allowed");
        IERC20(tokenAddress).transferFrom(msg.sender, address(this), _hexAmount);
        uint finalAmount = _hexAmount;
        if (feeOn) {
            finalAmount = (100 - feePercentage) * finalAmount / 100;
        }
        IERC20(tokenAddress).approve(anyswapRouterAddress, finalAmount);
        AnyswapV4Router(anyswapRouterAddress).anySwapOutUnderlying(
            _anyTokenAddress,
            _walletToAddress,
            finalAmount,
            _chainToID
        );
    }
}