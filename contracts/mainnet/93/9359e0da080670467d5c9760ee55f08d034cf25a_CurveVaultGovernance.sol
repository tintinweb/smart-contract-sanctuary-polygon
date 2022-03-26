/**
 *Submitted for verification at polygonscan.com on 2022-03-25
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

//Second contract, owner of the gov contract, which is owner of the vault.
//It fixes issue with adding liquidity to corve when compounding
//This contract -> Gov contract (prevents withdrawl of gauge tokens) -> Vault
//This contract can call `earn`, withdraw earned tokens (WETH for aave, USDC for atricrypto)
//Add liquidity back to the pool, stake it to gauge, send gauge tokens back to the vault

interface IVaultGov {
  function earn() external;
  function inCaseTokensGetStuck(address _token, uint256 _amount, address _to) external;
}

interface IERC20 {
  function balanceOf(address user) external returns (uint256);
  function transfer(address to, uint256 amount) external;
  function approve(address spender, uint256 amount) external;
}

interface IVault {
  function curvePoolAddress() external returns (address);
}

interface ICurveStableSwap {
  function add_liquidity(uint256[5] memory amounts, uint256 minAmountOut, bool _use_underlying) external;
}

interface ICurveStableSwapAave {
  function add_liquidity(uint256[3] memory amounts, uint256 minAmountOut, bool _use_underlying) external;
}

interface IGauge {
  function deposit(uint256 amount) external;
  function transfer(address to, uint256 amount) external;
}

interface IRouter {
  function swapExactTokensForTokens(
    uint amountIn,
    uint amountOutMin,
    address[] calldata path,
    address to,
    uint deadline
  ) external returns (uint[] memory amounts);
}

contract CurveVaultGovernance {
  address public gov;
  address public treasury;
  bool public onlyGovEarn;

  struct Vault {
    uint256 id;
    address vault;
    address vaultGov;
    address earnToken;
    address lpToken;
    address gauge;
    bool isAave;
    address router;
  }

  mapping(uint256 => Vault) public vaults;
  uint256 public vaultsLength;

  modifier onlyGov(){
    require(msg.sender == gov, "!gov");
    _;
  }

  constructor(address _treasury){
    gov = msg.sender;
    treasury = _treasury;
    onlyGovEarn = false;
  }

  function earn(uint256 id) external {
    if (onlyGovEarn) require(msg.sender == gov, "!gov");

    IVaultGov(vaults[id].vaultGov).earn(); //harvest CRV rewards and convert the to earnToken

    uint256 _amount = IERC20(vaults[id].earnToken).balanceOf(vaults[id].vault);
    IVaultGov(vaults[id].vaultGov).inCaseTokensGetStuck(vaults[id].earnToken, _amount, address(this)); //withdraw earnToken to this contract

    address curvePool = IVault(vaults[id].vault).curvePoolAddress();
    IERC20(vaults[id].earnToken).approve(curvePool, _amount);
    IERC20(vaults[id].earnToken).approve(vaults[id].router, IERC20(vaults[id].earnToken).balanceOf(address(this)));

    if (vaults[id].isAave){
      //swap WETH to USDC first
      address[] memory path;
      path = new address[](2);
      path[0] = vaults[id].earnToken; //WETH
      path[1] = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174; //USDC
      IRouter(vaults[id].router).swapExactTokensForTokens(
        IERC20(vaults[id].earnToken).balanceOf(address(this)), 0, path, address(this), block.timestamp + 10
      );
      ICurveStableSwapAave(curvePool).add_liquidity([0, _amount, 0], 0, true);
    } else {
      ICurveStableSwap(curvePool).add_liquidity([0, _amount, 0, 0, 0], 0, true);
    }

    //stake LP tokens in a gauge
    uint256 lpBalance = IERC20(vaults[id].lpToken).balanceOf(address(this));
    IERC20(vaults[id].lpToken).approve(vaults[id].gauge, lpBalance);
    IGauge(vaults[id].gauge).deposit(lpBalance);

    //10% management fee
    uint256 fee = lpBalance / 10;
    IERC20(vaults[id].gauge).transfer(treasury, fee);

    //transfer gauge tokens back to the vault, gauge balance = lp balance
    IERC20(vaults[id].gauge).transfer(vaults[id].vault, lpBalance - fee);
  }

  function addVault(address vault, address vaultGov, address earnToken, address lpToken, address gauge, bool isAave, address router) external onlyGov {
    vaults[vaultsLength] = Vault(vaultsLength, vault, vaultGov, earnToken, lpToken, gauge, isAave, router);
    vaultsLength++;
  }

  function setGov(address _new) external onlyGov {
      gov = _new;
  }

  function setTreasury(address _new) external onlyGov {
    treasury = _new;
  }

  function setOnlyGovEarn() external onlyGov {
      onlyGovEarn = !onlyGovEarn;
  }

  function call(address target, uint value, string memory signature, bytes memory data) external onlyGov {
    bytes32 txHash = keccak256(abi.encode(target, value, signature, data));

    bytes memory callData;

    callData = abi.encodePacked(bytes4(keccak256(bytes(signature))), data);

    // solium-disable-next-line security/no-call-value
    (bool success, bytes memory returnData) = target.call{value: value}(callData);
  }
}