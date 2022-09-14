//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.7;


import '../interfaces/IGreeter.sol';

/// @title A contract for boilerplating
/// @author Hardhat (and DeFi Wonderland)
/// @notice You can use this contract for only the most basic tests
/// @dev This is just a try out
/// @custom:experimental This is an experimental contract.

contract Greeter is IGreeter {
  string public override greeting;

  constructor(string memory _greeting) {

    greeting = _greeting;
  }

  function greet() external view override returns (string memory) {
    return greeting;
  }

  /// @notice Sets greeting that will be used during greet
  /// @dev Some explanation only defined for devs
  /// @param _greeting The greeting to be used
  /// @return _changedGreet Was greeting changed or nah
  function setGreeting(string memory _greeting) external override returns (bool _changedGreet) {
    if (bytes(_greeting).length == 0) revert EmptyGreeting();

    greeting = _greeting;
    _changedGreet = true;
    emit GreetingSet(_greeting);
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.7;

interface IGreeter {
  event GreetingSet(string _greeting);

  error EmptyGreeting();

  function greeting() external returns (string memory);

  function greet() external view returns (string memory);

  function setGreeting(string memory _greeting) external returns (bool);
}