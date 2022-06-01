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

struct AddressInformation {
  address ensAddress;
  address registrant;
  address controller;
}

contract ExampleConsumer {
  IENSRetrieverImplementationResolver private s_ensRetriever;
  LinkTokenInterface private s_linkToken;

  mapping(string => AddressInformation) public s_addressInfo;
  mapping(bytes32 => string) public s_requestedENSNames;

  event AddressResolved(string indexed _ensName, address _address, address _registrant, address _controller);

  constructor(address _ensRetriever, address _linkTokenAddress) {
    s_ensRetriever = IENSRetrieverImplementationResolver(_ensRetriever);
    s_linkToken = LinkTokenInterface(_linkTokenAddress);
  }

  function requestENSInformation(string calldata _ensName) external {
    uint256 fee = s_ensRetriever.getFee();
    address implementation = s_ensRetriever.getImplementation();
    // Transfer Link tokens to implementation contract that sends request to node
    s_linkToken.transfer(implementation, fee);
    bytes32 reqID = IENSRetriever(implementation).requestENSAddressInfo(_ensName, this.fulfill.selector);
    s_requestedENSNames[reqID] = _ensName;
  }

  function fulfill(
    bytes32 _requestID,
    address _registrant,
    address _controller,
    address _address
  ) external {
    string memory ensName = s_requestedENSNames[_requestID];
    s_addressInfo[ensName] = AddressInformation({
      ensAddress: _address,
      registrant: _registrant,
      controller: _controller
    });
    emit AddressResolved(ensName, _address, _registrant, _controller);
  }
}

//SPDX-License-Identifier: None
pragma solidity ^0.8.0;

interface IENSRetriever {
  function requestENSAddressInfo(string calldata _ensName, bytes4 _callbackFn) external returns (bytes32);

  function fulfill(
    bytes32 _requestId,
    address _registrant,
    address _controller,
    address _address
  ) external;

  function getFee() external view returns (uint256);
}

//SPDX-License-Identifier: None
pragma solidity ^0.8.0;

interface IENSRetrieverImplementationResolver {
  function setImplementation(address _newImplementation) external;

  function getImplementation() external view returns (address);

  function getFee() external returns (uint256);
}