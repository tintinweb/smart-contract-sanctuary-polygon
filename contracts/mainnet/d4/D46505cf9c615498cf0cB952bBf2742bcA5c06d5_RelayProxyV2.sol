/**
 *Submitted for verification at polygonscan.com on 2022-07-18
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

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


interface IDai {
    function balanceOf(address account) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function pull(address usr, uint wad) external;

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
}


contract RelayProxyV2 {
    address public daiAddress;
    address public limitOrdersAddress;
    IERC20OrderRouter erc20OrderRouter;
    IDai daiInstance;

    constructor(address _erc20OrderRouter, address _daiAddress, address _limitOrdersAddress) {
        require(_erc20OrderRouter != address(0), "Error: INVALID_erc20OrderRouter");
        require(_daiAddress != address(0), "Error: INVALID_daiAddress");
        require(_limitOrdersAddress != address(0), "Error: INVALID_limitOrdersAddress");

        daiAddress = _daiAddress;
        limitOrdersAddress = _limitOrdersAddress;
        erc20OrderRouter = IERC20OrderRouter(_erc20OrderRouter);
        daiInstance = IDai(daiAddress);

        // give DAI allowance to erc20OrderRouter
        daiInstance.approve(_erc20OrderRouter, 115792089237316195423570985008687907853269984665640564039457584007913129639935);
    }

    event CollectAndSubmitSignature(
        address indexed _address,
        uint256 _amount
    );

    function collectAndDepositDaiTokens(
        address _holder,
        uint256 _amount,
        address _witness,
        bytes calldata _data,
        bytes32 _secret,
        uint256 nonce,
        uint256 expiry,
        uint8[] memory v,
        bytes32[] memory r,
        bytes32[] memory s
    ) external {
        require(_holder != address(0), "Error: INVALID_HOLDER");
        require(_witness != address(0), "Error: INVALID_WITNESS");

        // if user DAI allowance has not yet been given
        if (daiInstance.allowance(_holder, address(this)) == 0) {
            daiInstance.permit(_holder, address(this), nonce, expiry, true, v[0], r[0], s[0]);
        }
        require(daiInstance.allowance(_holder, address(this)) > _amount, "Error: INVALID_ALLOWANCE");

        // pulling the Dai tokens from the holder
        daiInstance.pull(_holder, _amount);

        // deposit the pulled Dai tokens into erc20OrderRouter contract on behalf of the holder
        erc20OrderRouter.depositToken(_amount, limitOrdersAddress, daiAddress, payable(_holder), _witness, _data, _secret);

        // clear user DAI allowance
        daiInstance.permit(_holder, address(this), nonce + 1, expiry, false, v[1], r[1], s[1]);
	    require(daiInstance.allowance(_holder, address(this)) == 0, "Error: INVALID_0_ALLOWANCE");

        emit CollectAndSubmitSignature(_holder, _amount);
    }
}