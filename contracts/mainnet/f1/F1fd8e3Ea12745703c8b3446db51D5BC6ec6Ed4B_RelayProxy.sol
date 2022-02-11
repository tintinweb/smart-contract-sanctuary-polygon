// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.0;

interface IDai {
  function permit(
    address,
    address,
    uint256,
    uint256,
    bool,
    uint8,
    bytes32,
    bytes32
  ) external;

  function approve(address spender, uint256 amount) external returns (bool);

  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external returns (bool);
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
    address spender;
    uint256 nonce;
    uint256 expiry;
    bool allowed;
    uint8 v;
    bytes32 r;
    bytes32 s;
  }

  address internal daiAddress;
  address internal erc20OrderRouterAddress;
  IDai internal dai;
  IERC20OrderRouter internal erc20OrderRouter;

  constructor(address _erc20OrderRouter, address _dai) {
    erc20OrderRouterAddress = _erc20OrderRouter;
    erc20OrderRouter = IERC20OrderRouter(_erc20OrderRouter);
    daiAddress = _dai;
    dai = IDai(_dai);
  }

  function depositDaiTokenWithPermit(
    uint256 _amount,
    address _module,
    address payable _owner,
    address _witness,
    bytes calldata _data,
    bytes32 _secret,
    SignedPermit calldata _daiPermit
  ) external {
    require(_daiPermit.holder == _owner, "RelayProxy: Permit holder must be deposit owner");
    require(_daiPermit.spender == address(this), "RelayProxy: Permit spender must be this RelayProxy contract");

    dai.permit(
      _daiPermit.holder,
      _daiPermit.spender,
      _daiPermit.nonce,
      _daiPermit.expiry,
      _daiPermit.allowed,
      _daiPermit.v,
      _daiPermit.r,
      _daiPermit.s
    );
    dai.transferFrom(_daiPermit.holder, _daiPermit.spender, _amount);
    dai.approve(erc20OrderRouterAddress, _amount);
    erc20OrderRouter.depositToken(_amount, _module, daiAddress, _owner, _witness, _data, _secret);
  }
}