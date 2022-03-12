/**
 *Submitted for verification at polygonscan.com on 2022-03-12
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

interface ICurveVault {
  function earn() external;
  function inCaseTokensGetStuck(address _token, uint256 _amount, address _to) external;
}

contract CurveVaultGovernance {
  address public gov;
  address public vault;
  address public forbidden; //address of token that cannot be rescued

  modifier onlyGov(){
    require(msg.sender == gov, "!gov");
    _;
  }

  constructor(address _gaugeToken, address _vault){
    gov = msg.sender;
    forbidden = _gaugeToken;
    vault = _vault;
  }

  function earn() external onlyGov {
    ICurveVault(vault).earn();
  }

  function inCaseTokensGetStuck(address _token, uint256 _amount, address _to) external onlyGov {
    require(_token != forbidden, "forbidden token");

    ICurveVault(vault).inCaseTokensGetStuck(_token, _amount, _to);
  }

  function call(uint value, string memory signature, bytes memory data) external onlyGov {
    require(keccak256(abi.encodePacked(signature)) != keccak256("inCaseTokensGetStuck(address,uint256,address)"), "Cannot use call for inCaseTokensGetStuck");
    require(keccak256(abi.encodePacked(signature)) != keccak256("setGov(address)"), "Cannot use call for setGov");
    require(bytes(signature).length > 0, "0 length signature");

    bytes32 txHash = keccak256(abi.encode(vault, value, signature, data));

    bytes memory callData;

    callData = abi.encodePacked(bytes4(keccak256(bytes(signature))), data);

    // solium-disable-next-line security/no-call-value
    (bool success, bytes memory returnData) = vault.call{value: value}(callData);
  }
}