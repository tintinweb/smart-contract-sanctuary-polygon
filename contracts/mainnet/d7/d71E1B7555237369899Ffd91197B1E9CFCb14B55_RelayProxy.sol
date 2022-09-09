// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.13;

interface IDai {
    function permit(
        address holder,
        address spender,
        uint256 nonce,
        uint256 expiry,
        bool allowed,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function transferFrom(
        address src,
        address dst,
        uint256 wad
    ) external;

    function approve(address usr, uint256 wad) external returns (bool);
}

interface IERC20OrderRouter {
    function depositToken(
        uint256 _amount,
        address _module,
        address _inputToken,
        address payable _owner,
        address _witness,
        bytes calldata _data,
        bytes32 _secret
    ) external;
}

contract RelayProxy {
    struct SignedPermit {
        address holder;
        uint256 nonce;
        uint256 expiry;
        bool allowed;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    struct OrderData {
        uint256 amount;
        address module;
        address inputToken;
        address payable owner;
        address witness;
        bytes data;
        bytes32 secret;
    }

    IDai public immutable dai;
    IERC20OrderRouter public immutable erc20OrderRouter;

    constructor(IDai _dai, IERC20OrderRouter _erc20OrderRouter) {
        require(address(_dai) != address(0), "DAI can not be zero address");
        require(
            address(_erc20OrderRouter) != address(0),
            "ERC20OrderRouter can not be zero address"
        );
        dai = _dai;
        erc20OrderRouter = _erc20OrderRouter;
    }

    function relayGelatoLimitOrder(
        OrderData calldata orderData,
        SignedPermit calldata daiPermit
    ) external {
        // Permit token spending using signed permit
        dai.permit(
            orderData.owner,
            address(this),
            daiPermit.nonce,
            daiPermit.expiry,
            daiPermit.allowed,
            daiPermit.v,
            daiPermit.r,
            daiPermit.s
        );

        // Transfer tokens from owner and approve spending
        dai.transferFrom(orderData.owner, address(this), orderData.amount);
        dai.approve(address(erc20OrderRouter), orderData.amount);

        // Deposit tokens to ERC20OrderRouter
        erc20OrderRouter.depositToken(
            orderData.amount,
            orderData.module,
            orderData.inputToken,
            orderData.owner,
            orderData.witness,
            orderData.data,
            orderData.secret
        );
    }
}