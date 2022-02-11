/**
 *Submitted for verification at polygonscan.com on 2022-02-07
*/

// Sources flattened with hardhat v2.4.1 https://hardhat.org

// File @openzeppelin/contracts-upgradeable/proxy/utils/[email protected]

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}


// File contracts/IPRNG.sol


pragma solidity ^0.8.0;

interface IPRNG {
  function generate() external;
  function read(uint64 max) external returns (uint64);
}


// File contracts/LuckWheel.sol


pragma solidity ^0.8.0;


contract LuckWheel is Initializable {  
  
  mapping (address => uint[]) private _accountTimestamps;
  function login() external {
    _accountTimestamps[msg.sender].push(block.timestamp);
  }

  // function _getAvailableSpinsFor(address a) internal view returns (uint) {
  //    return _dailyLogin[a].counter == 0 ? 0 : _dailyLogin[a].counter % 7;
  // }

  // function getAvailableSpinsFor(address a) external view returns (uint) {
  //   return _getAvailableSpins(a);
  // }
  
  // function spin() external {
  //   require(_getAvailableSpins(msg.sender) > 0, 'No available spins');
  //   if (_dailyLogin[msg.sender]<4) {
  //     // mint snook with 50%
  //   } else {
  //     // take 500 SNK from treasury with 1/5000 chance and 200 SNK with 1/1000
  //     _dailyLogin[msg.sender] = 0;
  //   }
  // }
}