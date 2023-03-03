// SPDX-License-Identifier: MIT
pragma solidity =0.8.10;

import "IERC20.sol";

interface IMultichainV6Router {
    function anySwapOut(
        address token,
        string calldata to,
        uint256 amount,
        uint256 toChainID
    ) external;
}

contract AntfarmTokenBridger {
    address public immutable v6Router;
    address public immutable antfarmToken;
    string public receiverContract;

    uint256 public immutable ethChainId = 4002;

    constructor(
        address _v6Router,
        address _antfarmToken,
        string memory _receiverContract
    ) {
        v6Router = _v6Router;
        antfarmToken = _antfarmToken;
        receiverContract = _receiverContract;
    }

    function bridgeAtfToBurn(uint256 amount) external {
        uint256 contractBalance = IERC20(antfarmToken).balanceOf(address(this));
        require(contractBalance >= amount, "LOW_BALANCE");

        IMultichainV6Router router = IMultichainV6Router(v6Router);
        router.anySwapOut(antfarmToken, receiverContract, amount, ethChainId);
    }
}