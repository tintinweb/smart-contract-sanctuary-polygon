// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface IMasterchief {
    function token() external view returns (address);

    function swapToken(
        address recipient,
        uint256 pathId,
        uint256 amountOutMin,
        uint256 amountInMax,
        uint256 deadline,

        address controller_,
        bytes4 selector_,
        bytes calldata args
    ) external payable;
}

interface IRouter {
    function swapETHForExactTokens(
        uint amountOut,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable returns (uint[] memory amounts);

    function getAmountIn(
        uint amountOut,
        uint reserveIn,
        uint reserveOut
    ) external pure returns (uint amountIn);
}

interface IERC20 {
    function balanceOf(
        address account
    ) external view returns (uint256);

    function approve(
        address spender,
        uint256 amount
    ) external returns (bool);
}

contract ETHToUSDCQuickSwapV2Proxy {
    IMasterchief public masterchief;
    IRouter public router;
    address public pair;
    address public token;
    address[] public path;

    constructor(
        IMasterchief masterchief_,
        IRouter router_,
        address pair_,
        address[] memory path_
    )
    {
        masterchief = masterchief_;
        router = router_;
        pair = pair_;
        token = masterchief_.token();
        path = path_;
    }

    receive() external payable {}

    fallback() external payable {}

    function swapToken(
        address, // recipient
        uint256, // pathId
        uint256 amountOutMin,
        uint256, // amountInMax
        uint256 deadline,

        address controller_,
        bytes4 selector_,
        bytes calldata args
    )
        external
        payable
    {
        uint256 amountOut = router.getAmountIn(
            amountOutMin,
            IERC20(path[1]).balanceOf(pair),
            IERC20(token).balanceOf(pair)
        );

        uint256[] memory amounts = router.swapETHForExactTokens{ value: msg.value }(
            amountOut,
            path,
            address(this),
            deadline
        );

        (bool sent, ) = msg.sender.call{ value: (msg.value - amounts[0]) }("");
        require(sent);

        masterchief.swapToken(
            address(0),
            1, // path USDC
            amountOutMin,
            amountOut,
            deadline,

            controller_,
            selector_,
            args
        );
    }

    function approveUSDC()
        external
    {
        IERC20(path[1]).approve(address(masterchief), 0);
        IERC20(path[1]).approve(address(masterchief), type(uint256).max);
    }

}