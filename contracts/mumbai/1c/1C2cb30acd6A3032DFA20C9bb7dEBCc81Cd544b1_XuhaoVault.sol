// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface BeefyUniV2Zap {
    function beefIn(address beefyVault, uint256 tokenAmountOutMin , address tokenIn , uint256 tokenInAmount ) external;
    function beefOutAndSwap(address beefyVault, uint256 withdrawAmount  , address addressTokenOut , uint256 desiredTokenOutMin  ) external;
}

import "./interfaces/BeefyUniZapV2.sol";
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IXuhaoVault {
    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);

    function depositToken(uint256 _amount, address _addressToken)
        external
        returns (bool);

    function xuhaoIn(
        uint256 _amount,
        address beefyVault,
        uint256 tokenAmountOutMin,
        address addressTokenIn
    ) external;

    function xuhaoOut(
        address beefyVault,
        uint256 _amount,
        address addressTokenOut,
        uint256 desiredTokenOutMin
    ) external;

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event TransferFrom(address indexed from, address indexed to, uint256 value);
    event Transfer(address indexed recipient, uint256 value);
    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );
}

contract XuhaoVault {
    address public owner;
    address public constant usdc =
        address(0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174);
    address public constant mai =
        address(0xa3Fa99A148fA48D14Ed51d610c367C61876997F1);
    address public constant beefyVaultV6 =
        address(0xebe0c8d842AA5A57D7BEf8e524dEabA676F91cD1);
    address public constant beefyUniV2Zap =
        address(0x540A9f99bB730631BF243a34B19fd00BA8CF315C);
    address public constant uniSwapV2Pair =
        address(0x160532D2536175d65C03B97b0630A9802c274daD);

    uint256 private constant MAX_UINT256 = 2**256 - 1;
    uint256 public balancesUSDC;
    uint256 public balancesMAI;
    uint8 public decimalsUSDC;
    uint8 public decimalsMAI;

    constructor(
        uint256 _balancesMAI,
        uint8 _decimalsMAI,
        uint256 _balancesUSDC,
        uint8 _decimalsUSDC
    ) {
        decimalsMAI = _decimalsMAI;
        decimalsUSDC = _decimalsUSDC;
        balancesUSDC = _balancesUSDC;
        balancesMAI = _balancesMAI;
        owner = msg.sender;
    }

    function approveToken(address _addressToken, address spender) private {
        if (IXuhaoVault(_addressToken).allowance(address(this), spender) == 0) {
            IXuhaoVault(_addressToken).approve(spender, type(uint256).max);
        }
    }

    function depositToken(uint256 _amount, address _addressToken)
        public
        returns (bool)
    {
        require(_amount > 0, "Invalid deposit amount");
        IXuhaoVault(_addressToken).transferFrom(
            owner,
            address(this),
            (_amount)
        );
        if (IXuhaoVault(_addressToken) == IXuhaoVault(usdc)) {
            balancesUSDC += _amount;
        } else if (IXuhaoVault(_addressToken) == IXuhaoVault(mai)) {
            balancesMAI += _amount;
        }
        return true;
    }

    function xuhaoIn(
        uint256 _amount,
        address beefyVault,
        uint256 tokenAmountOutMin,
        address addressTokenIn
    ) external {
        // approveToken(addressTokenIn, address(beefyUniV2Zap));
        require(_amount > 0, "Invalid deposit amount");
        uint256 toVault = (_amount * 90) / 100;
        uint256 value = _amount;
        IXuhaoVault(addressTokenIn).transferFrom(owner, address(this), (value));
        BeefyUniV2Zap(beefyUniV2Zap).beefIn(
            beefyVault,
            tokenAmountOutMin,
            addressTokenIn,
            toVault
        );
        if (IXuhaoVault(addressTokenIn) == IXuhaoVault(usdc)) {
            balancesUSDC += value - toVault;
        } else if (IXuhaoVault(addressTokenIn) == IXuhaoVault(mai)) {
            balancesMAI += value - toVault;
        }
    }

    function xuhaoOutAndSwap(
        address beefyVault,
        uint256 withdrawAmount,
        address desiredToken,
        uint256 desiredTokenOutMin
    ) external {
        require(withdrawAmount > 0, "Invalid deposit amount");
        approveToken(desiredToken, address(uniSwapV2Pair));
        BeefyUniV2Zap(beefyUniV2Zap).beefOutAndSwap(
            beefyVault,
            withdrawAmount,
            desiredToken,
            desiredTokenOutMin
        );
    }

    function withdrawToken(uint256 _amount, address addressToken) external {
        // oke
        require((_amount) > 0, "Invalid withdraw amount");
        IXuhaoVault(addressToken).transfer(owner, (_amount));
    }
}