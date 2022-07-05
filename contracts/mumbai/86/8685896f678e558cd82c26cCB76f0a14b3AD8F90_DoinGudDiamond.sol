// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./LibDiamond.sol";
import "./IDiamondLoupe.sol";
import "./IDiamondCut.sol";
import "./IERC173.sol";
import "./IERC165.sol";

/**
@title Main DoinGud contract
@dev see EIP-2535
*/
contract DoinGudDiamond {
  event TransferSingle(
    address indexed _operator,
    address indexed _from,
    address indexed _to,
    uint256 _id,
    uint256 _amount
  );

  error NoSuchFunction();

  struct DiamondArgs {
    address owner;
  }

  constructor(
    IDiamondCut.FacetCut[] memory _diamondCut,
    DiamondArgs memory _args
  ) payable {
    LibDiamond.diamondCut(_diamondCut, address(0), new bytes(0));
    LibDiamond.setContractOwner(_args.owner);

    LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();

    // adding ERC165 data
    ds.supportedInterfaces[type(IERC165).interfaceId] = true;
    ds.supportedInterfaces[type(IDiamondCut).interfaceId] = true;
    ds.supportedInterfaces[type(IDiamondLoupe).interfaceId] = true;
    ds.supportedInterfaces[type(IERC173).interfaceId] = true;
    //ds.supportedInterfaces[type(IERC1155).interfaceId] = true;
  }

  /**
    @notice Find facet for function that is called and execute the function if a facet is found and return any value.
  */
  fallback() external payable {
    LibDiamond.DiamondStorage storage ds;
    bytes32 position = LibDiamond.DIAMOND_STORAGE_POSITION;
    assembly {
      ds.slot := position
    }
    address facet =
      address(
        bytes20(ds.facetAddressAndSelectorPosition[msg.sig].facetAddress)
      );
    if (facet == address (0)) {
      revert NoSuchFunction();
    }
    assembly {
      calldatacopy(0, 0, calldatasize())
      let result := delegatecall(gas(), facet, 0, calldatasize(), 0, 0)
      returndatacopy(0, 0, returndatasize())
      switch result
        case 0 {
          revert(0, returndatasize())
        }
        default {
          return(0, returndatasize())
        }
    }
  }
}