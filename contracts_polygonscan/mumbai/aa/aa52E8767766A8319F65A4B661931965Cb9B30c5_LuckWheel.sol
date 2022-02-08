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
  
  struct AccountCheckin {
    uint timestamp;
    uint count;
  }

  uint constant public DAYS_PER_WEEK = 7;
  uint constant public DAYS_PER_MONTH = 28;

  mapping (address => AccountCheckin) private _accountCheckin;
  uint private _secondsInDay;
  IPRNG private _prng;

  function initialize(
    uint secondsInDay,
    IPRNG prng
  ) initializer public {
    _secondsInDay = secondsInDay;
    _prng = IPRNG(prng);
  }

  function checkin() external {
    require(block.timestamp - _accountCheckin[msg.sender].timestamp >= _secondsInDay * DAYS_PER_WEEK, 'LuckWheel: already checked in');
    _accountCheckin[msg.sender].count += 1;
    _accountCheckin[msg.sender].timestamp = block.timestamp;
  }

  function _getAvailableSpinsFor(address a) internal view returns (uint spin7, uint spin28) {
    uint count = _accountCheckin[a].count; 
    return (count%DAYS_PER_WEEK , count%DAYS_PER_MONTH); 
  }

  function getAvailableSpinsFor(address a) external view returns (uint spin7, uint spin30) {
    return _getAvailableSpinsFor(a);
  }

  function spin() external {
    (uint spin7, uint spin28) = _getAvailableSpinsFor(msg.sender);
    require(spin7>0, 'No available spins');
    if (spin28 > 0) { 
      // give 200 SNK with chance of 1/1000 or 500 SNK with chance of 1/5000 from treasury.
      _accountCheckin[msg.sender].count -= DAYS_PER_MONTH;
    } else {
      // mint snook, 50% chance
      _accountCheckin[msg.sender].count -= DAYS_PER_WEEK;
    }
  }

  
}