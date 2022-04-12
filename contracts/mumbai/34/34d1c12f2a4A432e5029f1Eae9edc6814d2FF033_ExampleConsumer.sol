// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface LinkTokenInterface {
  function allowance(address owner, address spender) external view returns (uint256 remaining);

  function approve(address spender, uint256 value) external returns (bool success);

  function balanceOf(address owner) external view returns (uint256 balance);

  function decimals() external view returns (uint8 decimalPlaces);

  function decreaseApproval(address spender, uint256 addedValue) external returns (bool success);

  function increaseApproval(address spender, uint256 subtractedValue) external;

  function name() external view returns (string memory tokenName);

  function symbol() external view returns (string memory tokenSymbol);

  function totalSupply() external view returns (uint256 totalTokensIssued);

  function transfer(address to, uint256 value) external returns (bool success);

  function transferAndCall(
    address to,
    uint256 value,
    bytes calldata data
  ) external returns (bool success);

  function transferFrom(
    address from,
    address to,
    uint256 value
  ) external returns (bool success);
}

//SPDX-License-Identifier: None
pragma solidity ^0.8.0;

import "../interfaces/IENSRetrieverImplementationResolver.sol";
import "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import "../interfaces/IENSRetriever.sol";

contract ExampleConsumer {
  IENSRetrieverImplementationResolver private s_ensRetriever;
  bytes private s_response;
  LinkTokenInterface private s_linkToken;

  constructor(address _ensRetriever, address _linkTokenAddress) {
    s_ensRetriever = IENSRetrieverImplementationResolver(_ensRetriever);
    s_linkToken = LinkTokenInterface(_linkTokenAddress);
  }

  function requestENSInformation(string calldata _ensName) external {
    uint256 fee = s_ensRetriever.getFee();
    address implementer = s_ensRetriever.getAddress();
    bytes memory eaParams = abi.encode(_ensName);
    bytes memory requestParams = abi.encode(eaParams, this.fulfill.selector);
    s_linkToken.transferAndCall(
      implementer,
      fee,
      abi.encodeWithSelector(IENSRetriever.requestENSAddressInfo.selector, requestParams)
    );
  }

  function fulfill(bytes32 _requestID, bytes calldata _response) external {
    s_response = _response;
  }
}

//SPDX-License-Identifier: None
pragma solidity ^0.8.0;

interface IENSRetriever {
  function requestENSAddressInfo(bytes calldata _params, bytes4 _callbackFn) external returns (bytes32);

  function getFee() external view returns (uint256);
}

//SPDX-License-Identifier: None
pragma solidity ^0.8.0;

interface IENSRetrieverImplementationResolver {
  function setImplementation(address _newImplementation) external;

  function getAddress() external view returns (address);

  function getFee() external returns (uint256);
}