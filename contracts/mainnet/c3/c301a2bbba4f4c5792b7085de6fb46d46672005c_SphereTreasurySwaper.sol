/**
 *Submitted for verification at polygonscan.com on 2022-04-20
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
        require(newOwner != address(0),
            'Owner can not be 0');
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

interface ISphereTreasurySwaper {
  function swapBack(address receiver, address toTokenAddress) external;
}

contract SphereTreasurySwaper is Ownable, ISphereTreasurySwaper {
  address public routerAddress;

  mapping(address => bool) public swapBacker;

  constructor() {}

  receive() external payable {}

  function setRouter(address _routerAddress) external onlyOwner {
    require(_routerAddress != address(0x0), "Router can not be null");
    routerAddress = _routerAddress;

    address weth = IDEXRouter(routerAddress).WETH();
    IERC20 fromToken = IERC20(weth);
    fromToken.approve(routerAddress, ~uint128(0));
  }

  function addSwapBacker(address _swapBacker) external onlyOwner {
    require(_swapBacker != address(0x0), "swap backer can not be 0x0");
    require(swapBacker[_swapBacker] != true, "swap backer already set");

    swapBacker[_swapBacker] = true;

    emit AddSwapBacker(_swapBacker);
  }

  function removeSwapBacker(address _swapBacker) external onlyOwner {
    require(_swapBacker != address(0x0), "swap backer can not be 0x0");
    require(swapBacker[_swapBacker], "swap backer is not set");

    swapBacker[_swapBacker] = false;

    emit RemoveSwapBacker(_swapBacker);
  }

  modifier onlySwapBacker() {
    require(swapBacker[msg.sender], "not allowed to swap back");
    _;
  }

  function swapBack(address receiver, address toTokenAddress) override external onlySwapBacker {
    require(receiver != address(0x0), "receiver can not be 0x0 address");
    require(toTokenAddress != address(0x0), "to token can not be null");

    uint256 balance = address(this).balance;

    IDEXRouter router = IDEXRouter(routerAddress);

    address[] memory path = new address[](2);
    path[0] = router.WETH();
    path[1] = toTokenAddress;

    router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: balance}(
      0,
      path,
      receiver,
      block.timestamp
    );

    emit SwapBack(receiver, toTokenAddress, balance);
  }

  function withdrawToken(address tokenAddress) external onlyOwner {
    IERC20 token = IERC20(tokenAddress);
    require(token.balanceOf(msg.sender) > 0, "nothing to withdraw");

    token.transfer(msg.sender, token.balanceOf(msg.sender));
  }

  function withdrawNativeToken() external onlyOwner {
    require(address(this).balance > 0, "nothing to withdraw");

    uint256 balance = address(this).balance;
    address(msg.sender).call{value: balance}("");
  }

  event AddSwapBacker(address swapBacker);
  event RemoveSwapBacker(address swapBacker);
  event SwapBack(address receiver, address toTokenAddress, uint256 amount);
}