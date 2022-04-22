//SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./Interfaces.sol";
import "./Libraries.sol";

interface IWETH is IERC20 {
    function deposit() external payable;
    function withdraw(uint) external;
}

abstract contract FlashLoanReceiverBase is IFlashLoanReceiver {
  using SafeERC20 for IERC20;
  using SafeMath for uint256;

  ILendingPoolAddressesProvider public immutable ADDRESSES_PROVIDER;
  ILendingPool public immutable LENDING_POOL;

  constructor(ILendingPoolAddressesProvider provider) public {
    ADDRESSES_PROVIDER = provider;
    LENDING_POOL = ILendingPool(provider.getLendingPool());
  }
}

contract PolyMultiCallFL is FlashLoanReceiverBase {
    using SafeMath for uint256;
    address private immutable owner;

    address public WETH_address = address(0x9c3C9283D3e44854697Cd22D3Faa240Cfb032889);
    IWETH private constant WETH = IWETH(0x9c3C9283D3e44854697Cd22D3Faa240Cfb032889);
    address private constant ETH_address = address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    constructor(ILendingPoolAddressesProvider _addressProvider) FlashLoanReceiverBase(_addressProvider) public payable {
        owner = msg.sender;
    }

    function executeOperation(
        address[] calldata /* assets */,
        uint256[] calldata amounts,
        uint256[] calldata premiums,
        address /* initiator */,
        bytes calldata params
    )
        external
        override
        returns (bool)
    {
        uint amountOwing = amounts[0].add(premiums[0]);
        uniswapWethFLParams(amounts[0], params, amountOwing);
        WETH.approve(address(LENDING_POOL), amountOwing);
        return true;
    }

    function flashloan(uint256 amountToBorrow, bytes memory _params) external {
        address receiverAddress = address(this);

        address[] memory assets = new address[](1);
        assets[0] = WETH_address;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = amountToBorrow;
        uint256[] memory modes = new uint256[](1);
        modes[0] = 0;
        address onBehalfOf = address(this);
        uint16 referralCode = 161;
        LENDING_POOL.flashLoan(
            receiverAddress,
            assets,
            amounts,
            modes,
            onBehalfOf,
            _params,
            referralCode
        );
    }

    function uniswapWethFLParams(uint256 _amountToFirstMarket, bytes memory _params, uint256 totalAaveDebt) internal {
        (uint256 _ethAmountToCoinbase, address[] memory _targets, bytes[] memory _payloads) = abi.decode(_params, (uint256, address[], bytes[]));
        require(_targets.length == _payloads.length);
        WETH.transfer(_targets[0], _amountToFirstMarket);
        for (uint256 i = 0; i < _targets.length; i++) {
            (bool _success, /* bytes memory _response */) = _targets[i].call(_payloads[i]);
            require(_success); 
        }
        uint256 _wethBalanceAfter = WETH.balanceOf(address(this));

        uint256 _profit = _wethBalanceAfter - totalAaveDebt - _ethAmountToCoinbase;
        require(_profit >= 0);

        WETH.withdraw(_ethAmountToCoinbase + _profit);
        block.coinbase.transfer(_ethAmountToCoinbase);
        msg.sender.transfer(_profit);
    }

    function uniswapWeth(uint256 _wethAmountToFirstMarket, uint256 _ethAmountToCoinbase, address[] memory _targets, bytes[] memory _payloads) external payable {
        require (_targets.length == _payloads.length);
        uint256 _wethBalanceBefore = WETH.balanceOf(address(this));
        WETH.transfer(_targets[0], _wethAmountToFirstMarket);
        for (uint256 i = 0; i < _targets.length; i++) {
            (bool _success, bytes memory _response) = _targets[i].call(_payloads[i]);
            require(_success); _response;
        }

        uint256 _wethBalanceAfter = WETH.balanceOf(address(this));
        require(_wethBalanceAfter > _wethBalanceBefore + _ethAmountToCoinbase);
        if (_ethAmountToCoinbase == 0) return;

        uint256 _ethBalance = address(this).balance;
        if (_ethBalance < _ethAmountToCoinbase) {
            WETH.withdraw(_ethAmountToCoinbase - _ethBalance);
        }
        block.coinbase.transfer(_ethAmountToCoinbase);
    }

    function call(address payable _to, uint256 _value, bytes calldata _data) external onlyOwner payable returns (bytes memory) {
        require(_to != address(0));
        (bool _success, bytes memory _result) = _to.call{value: _value}(_data);
        require(_success);
        return _result;
    }

    receive() external payable {
    }

    function withdraw(address token) external onlyOwner {
        if (token == ETH_address) {
            uint256 bal = address(this).balance;
            payable(msg.sender).transfer(bal);
        } else if (token != ETH_address) {
            uint256 bal = IERC20(token).balanceOf(address(this));
            IERC20(token).transfer(payable(address(msg.sender)), bal);
        }
    }

}