/**
 *Submitted for verification at polygonscan.com on 2022-05-05
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Ownable {
    address private _owner;

    event OwnershipRenounced(address indexed previousOwner);
    event TransferOwnerShip(address indexed previousOwner);

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        _owner = msg.sender;
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(msg.sender == _owner, 'Not owner');
        _;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipRenounced(_owner);
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        emit TransferOwnerShip(newOwner);
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), 'Owner can not be 0');
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IERC20 {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);
}

interface IDEXRouter {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

interface ISphereTreasurySwapper {
    function swapBack() external;
}

contract SphereTreasurySwapper is Ownable, ISphereTreasurySwapper {
    address public routerAddress;

    address public DEAD = 0x000000000000000000000000000000000000dEaD;

    address public sphereAddress;
    address public swapbackTokenAddress;

    address public liquidityReceiver;
    address public treasuryReceiver;
    address public riskFreeValueReceiver;
    address public galaxyBondReceiver;

    uint256 public burnFees;
    uint256 public liquidityFees;
    uint256 public treasuryFees;
    uint256 public rfvFees;
    uint256 public galaxyBondFees;
    uint256 public feeDenominator = 1000;

    uint256 public maxSwapbackAmount = type(uint256).max;

    mapping(address => bool) public swapBacker;

    constructor() public {}

    receive() external payable {}

    function setSphereAddress(address _sphereAddress) external onlyOwner {
        require(_sphereAddress != address(0x0), "sphere address can not be 0x0");
        sphereAddress = _sphereAddress;
    }

    function setSwapbackTokenAddress(address _swapbackTokenAddress) external onlyOwner {
        require(_swapbackTokenAddress != address(0x0), "swapback address can not be 0x0");
        swapbackTokenAddress = _swapbackTokenAddress;
    }

    function setMaxSwapbackAmount(uint256 _maxSwapbackAmount) external onlyOwner {
        if(_maxSwapbackAmount == 0) {
            maxSwapbackAmount = type(uint256).max;
        } else {
            maxSwapbackAmount = _maxSwapbackAmount;
        }
    }

    function setFeeReceivers(
        address _liquidityReceiver,
        address _treasuryReceiver,
        address _riskFreeValueReceiver,
        address _galaxyBondReceiver
    ) external onlyOwner {
        liquidityReceiver = _liquidityReceiver;
        treasuryReceiver = _treasuryReceiver;
        riskFreeValueReceiver = _riskFreeValueReceiver;
        galaxyBondReceiver = _galaxyBondReceiver;
    }

    function setFees(
        uint256 _burnFees,
        uint256 _liquidityFees,
        uint256 _treasuryFees,
        uint256 _rfvFees,
        uint256 _galaxyBondFees
    ) external onlyOwner {
        require(
            (_burnFees + _liquidityFees + _treasuryFees + _rfvFees + _galaxyBondFees) == 1000,
            "Total fees should be 1000"
        );

        burnFees = _burnFees;
        liquidityFees = _liquidityFees;
        treasuryFees = _treasuryFees;
        rfvFees = _rfvFees;
        galaxyBondFees = _galaxyBondFees;
    }

    function setRouter(address _routerAddress) external onlyOwner {
        require(_routerAddress != address(0x0), 'Router can not be null');
        routerAddress = _routerAddress;

        IERC20 fromToken = IERC20(sphereAddress);
        fromToken.approve(routerAddress, type(uint256).max);
    }

    function addSwapBacker(address _swapBacker) external onlyOwner {
        require(_swapBacker != address(0x0), 'swap backer can not be 0x0');
        require(swapBacker[_swapBacker] != true, 'swap backer already set');

        swapBacker[_swapBacker] = true;

        emit AddSwapBacker(_swapBacker);
    }

    function removeSwapBacker(address _swapBacker) external onlyOwner {
        require(_swapBacker != address(0x0), 'swap backer can not be 0x0');
        require(swapBacker[_swapBacker], 'swap backer is not set');

        swapBacker[_swapBacker] = false;

        emit RemoveSwapBacker(_swapBacker);
    }

    modifier onlySwapBacker() {
        require(swapBacker[msg.sender], 'not allowed to swap back');
        _;
    }

    function swapBack()
        external
        override
        onlySwapBacker
    {
        require(liquidityReceiver != address(0x0), "uninitialized liquidity receiver");
        require(treasuryReceiver != address(0x0), "uninitialized liquidity receiver");
        require(riskFreeValueReceiver != address(0x0), "uninitialized liquidity receiver");
        require(galaxyBondReceiver != address(0x0), "uninitialized liquidity receiver");

        uint256 balance = IERC20(sphereAddress).balanceOf(address(this));

        if(balance > maxSwapbackAmount) {
            balance = maxSwapbackAmount;
        }

        uint256 amountToBurn = balance * burnFees / feeDenominator;
        uint256 amountToLiquidify = balance * liquidityFees / 2 / feeDenominator;

        balance -= amountToBurn + amountToLiquidify * 2;

        IERC20(sphereAddress).transfer(address(DEAD), amountToBurn);

        IDEXRouter router = IDEXRouter(routerAddress);

        address[] memory path = new address[](2);
        path[0] = sphereAddress;
        path[1] = swapbackTokenAddress;

        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            balance,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amount = IERC20(swapbackTokenAddress).balanceOf(address(this));
        uint256 amountForTreasury = amount * treasuryFees / feeDenominator;
        uint256 amountForRFV = amount * rfvFees / feeDenominator;
        uint256 amountForGalaxyBonds = amount * galaxyBondFees / feeDenominator;
        uint256 amountToLiquidate = amount - (amountForTreasury + amountForRFV + amountForGalaxyBonds);

        IERC20(swapbackTokenAddress).transfer(treasuryReceiver, amountForTreasury);
        IERC20(swapbackTokenAddress).transfer(riskFreeValueReceiver, amountForRFV);
        IERC20(swapbackTokenAddress).transfer(galaxyBondReceiver, amountForGalaxyBonds);

        router.addLiquidity(
            sphereAddress,
            swapbackTokenAddress,
            amountToLiquidify,
            amountToLiquidate,
            0,
            0,
            liquidityReceiver,
            block.timestamp
        );

        emit SwapBack(balance);
    }

    function withdrawToken(address tokenAddress) external onlyOwner {
        IERC20 token = IERC20(tokenAddress);
        require(token.balanceOf(msg.sender) > 0, 'nothing to withdraw');

        token.transfer(msg.sender, token.balanceOf(msg.sender));
    }

    function withdrawNativeToken() external onlyOwner {
        require(address(this).balance > 0, 'nothing to withdraw');

        uint256 balance = address(this).balance;
        address(msg.sender).call{value: balance}('');
    }

    event AddSwapBacker(address swapBacker);
    event RemoveSwapBacker(address swapBacker);
    event SwapBack(uint256 amount);
}