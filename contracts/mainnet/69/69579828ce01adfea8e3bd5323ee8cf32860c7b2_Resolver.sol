// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.1;

import { IAavegotchiFacet } from "IAavegotchiFacet.sol";
import { ICareCentre } from "ICareCentre.sol";
import { SafeERC20, IERC20 } from "SafeERC20.sol";
import { EnumerableSet } from "EnumerableSet.sol";

contract Resolver {
  using EnumerableSet for EnumerableSet.AddressSet;

  IAavegotchiFacet public immutable gotchiFacet;
  ICareCentre public immutable careCentre;
  IERC20 public immutable ghst;
  address public immutable operator;
  EnumerableSet.AddressSet internal blacklisted;

  constructor(
    address _gotchiFacet,
    address _careCentre,
    address _ghst,
    address _operator
  ) {
    gotchiFacet = IAavegotchiFacet(_gotchiFacet);
    careCentre = ICareCentre(_careCentre);
    ghst = IERC20(_ghst);
    operator = _operator;
    blacklisted.add(address(0xb0C4Cc1AA998DF91D2c27cE06641261707A8c9C3));
  }

  function checker()
    external
    view
    returns (bool canExec, bytes memory execPayload)
  {
    address[] memory _caringOwners = careCentre.getCaringOwners();
    uint256 _length = _caringOwners.length;

    for (uint256 i = 0; i < _length; i++) {
      if (blacklisted.contains(_caringOwners[i])) continue;
      ICareCentre.CareInfo memory _careInfo = careCentre.getCareInfoByOwner(
        _caringOwners[i]
      );

      uint256[] memory _gotchis = _careInfo.gotchis;

      if (!isOwnerGotchis(_caringOwners[i], _gotchis)) continue;
      if (!ownerHasBalance(_caringOwners[i], _careInfo.rate)) continue;
      if (!isApproved(_caringOwners[i])) continue;

      uint256 _lastInteracted = gotchiFacet
        .getAavegotchi(_gotchis[0])
        .lastInteracted;

      uint256 _nextInteract = _lastInteracted + 12 hours;

      if (block.timestamp >= _nextInteract) {
        canExec = true;

        execPayload = abi.encodeWithSelector(
          ICareCentre.exec.selector,
          _careInfo
        );

        return (canExec, execPayload);
      }
    }

    canExec = false;
  }

  function isOwnerGotchis(address owner, uint256[] memory gotchis)
    internal
    view
    returns (bool)
  {
    for (uint256 x = 0; x < gotchis.length; x++) {
      if (gotchiFacet.ownerOf(gotchis[x]) != owner) {
        return false;
      } else {
        continue;
      }
    }
    return true;
  }

  function ownerHasBalance(address owner, uint256 rate)
    internal
    view
    returns (bool)
  {
    if (
      ghst.balanceOf(owner) >= rate &&
      ghst.allowance(owner, address(careCentre)) >= rate
    ) return true;

    return false;
  }

  function isApproved(address owner) internal view returns (bool) {
    return (gotchiFacet.isApprovedForAll(owner, operator));
  }

  function getBlacklisted()
    external
    view
    returns (address[] memory _blacklisted)
  {
    uint256 length = blacklisted.length();
    _blacklisted = new address[](length);
    for (uint256 i = 0; i < length; i++) _blacklisted[i] = blacklisted.at(i);
  }

  function blacklist(address owner) external {
    blacklisted.add(owner);
  }

  function whitelist(address owner) external {
    blacklisted.remove(owner);
  }
}