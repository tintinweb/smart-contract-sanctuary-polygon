// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface IMasterchief {
    function buy(
        address recipient,
        address delegatee,
        uint256 pathId,
        uint256 amount,
        uint256 amountOutMin,
        uint256 deadline
    ) external payable;

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

    function swapGovernanceToken(
        address recipient,
        uint256 pathId,
        uint256 amountOutMin,
        uint256 amountIn,
        uint256 deadline,

        address controller_,
        bytes4 selector_,
        bytes calldata args
    ) external payable;
}

interface IToken {
    function approve(
        address spender,
        uint256 amount
    ) external returns (bool);

    function balanceOf(
        address account
    ) external view returns (uint256);

    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);
}

interface IRouter {
    function swapExactTokensForETH(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
}

interface IBridge {
    function transfers(
        bytes32 transferId
    ) external view returns (bool);
}

contract BridgeReceiver {
    IBridge public immutable bridge;

    IMasterchief public immutable masterchief;
    IRouter public immutable router;
    IToken public immutable weth;

    address public immutable weth9;
    address public executer;

    address[] public path = new address[](2);

    mapping(bytes32 => uint8) public transfers;

    modifier onlyExecuter {
        require(executer == msg.sender); _;
    }

    constructor(
        IBridge _bridge,
        IMasterchief _masterchief,
        IRouter _router,
        IToken _weth,
        address _weth9,
        address _executer
    )
    {
        bridge = _bridge;
        masterchief = _masterchief;
        router = _router;
        weth = _weth;
        weth9 = _weth9;
        executer = _executer;

        path[0] = address(_weth); path[1] = _weth9;
    }

    receive() external payable {}

    fallback() external payable {}

    function buy(
        bytes32 transferId,
        address recipient,
        address delegatee,
        uint256 fee0Permille,
        uint256 fee1Permille,
        uint256 fee2Permille,
        uint256 amount,

        uint256 amountOutMin,
        uint256 deadline
    )
        external
        onlyExecuter
    {
        require(transfers[transferId] == 0, "transfer exists");
        transfers[transferId] = 1;

        uint256 amountIn = amount * (1000 - fee0Permille - fee1Permille) / 1000;

        masterchief.buy(
            recipient,
            delegatee,
            3, // pathId
            amountIn,
            amountOutMin,
            deadline
        );

        uint256[] memory amounts = router.swapExactTokensForETH(
            amount * fee1Permille / 1000,
            0,
            path,
            address(this),
            deadline
        );

        (bool sent, ) = recipient.call{ value: amounts[1] * (1000 - fee2Permille) / 1000 }("");
        (bool sent2, ) = executer.call{ value: address(this).balance }("");
        require(sent && sent2, "failed to send Matic");
    }

    function swapToken(
        bytes32 transferId,
        address recipient,

        uint256 fee1Permille,
        uint256 fee2Permille,
        uint256 amount,

        uint256 amountOutMin,
        uint256 deadline,
        address controller,
        bytes4 selector,
        bytes calldata args
    )
        external
        onlyExecuter
    {
        require(transfers[transferId] == 0, "transfer exists");
        transfers[transferId] = 1;

        uint256 balance = weth.balanceOf(address(this));
        uint256 amountInMax = amount * (1000 - fee1Permille) / 1000;

        masterchief.swapToken(
            address(0),
            3, // pathId
            amountOutMin,
            amountInMax,
            deadline,
            controller,
            selector,
            args
        );

        uint256[] memory amounts = router.swapExactTokensForETH(
            weth.balanceOf(address(this)) + amountInMax - balance,
            0,
            path,
            address(this),
            deadline
        );

        (bool sent, ) = recipient.call{ value: amounts[1] * (1000 - fee2Permille) / 1000 }("");
        (bool sent2, ) = executer.call{ value: address(this).balance }("");
        require(sent && sent2, "failed to send Matic");
    }

    function swapGovernanceToken(
        bytes32 transferId,
        address recipient,

        uint256 fee1Permille,
        uint256 fee2Permille,
        uint256 amount,

        uint256 amountOutMin,
        uint256 deadline,
        address controller,
        bytes4 selector,
        bytes calldata args
    )
        external
        onlyExecuter
    {
        require(transfers[transferId] == 0, "transfer exists");
        transfers[transferId] = 1;

        uint256 balance = weth.balanceOf(address(this));
        uint256 amountInMax = amount * (1000 - fee1Permille) / 1000;

        masterchief.swapGovernanceToken(
            address(0),
            3, // pathId
            amountOutMin,
            amountInMax,
            deadline,
            controller,
            selector,
            args
        );

        uint256[] memory amounts = router.swapExactTokensForETH(
            weth.balanceOf(address(this)) + amountInMax - balance,
            0,
            path,
            address(this),
            deadline
        );

        (bool sent, ) = recipient.call{ value: amounts[1] * (1000 - fee2Permille) / 1000 }("");
        (bool sent2, ) = executer.call{ value: address(this).balance }("");
        require(sent && sent2, "failed to send Matic");
    }

    function withdraw(
        bytes32 transferId,
        address recipient,
        uint256 fee1Permille,
        uint256 fee2Permille,
        uint256 amount,
        uint256 deadline
    )
        external
        onlyExecuter
    {
        require(transfers[transferId] == 0, "transfer exists");
        transfers[transferId] = 2;

        uint256[] memory amounts = router.swapExactTokensForETH(
            amount * (1000 - fee1Permille) / 1000,
            0,
            path,
            address(this),
            deadline
        );

        (bool sent, ) = recipient.call{ value: amounts[1] * (1000 - fee2Permille) / 1000 }("");
        (bool sent2, ) = executer.call{ value: address(this).balance }("");
        require(sent && sent2, "failed to send Matic");
    }

    function bridgeTransfers(
        bytes32 transferId
    )
        external
        view
        returns (bool)
    {
        return bridge.transfers(transferId);
    }

    function approve()
        external
    {
        weth.approve(address(masterchief), 0);
        weth.approve(address(masterchief), type(uint256).max);

        weth.approve(address(router), 0);
        weth.approve(address(router), type(uint256).max);
    }

    function setExecuter(
        address _executer
    )
        external
        onlyExecuter
    {
        require(_executer != address(0));
        executer = _executer;
    }
}