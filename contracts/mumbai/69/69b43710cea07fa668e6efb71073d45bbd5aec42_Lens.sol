// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import "../interfaces/ILensHub.sol";


contract Lens {

    ILensHub lensHub;
    address collectModule;
    uint256 handleTokenId;
    
    constructor (address _lensHub, address _collectModule) {
        lensHub = ILensHub(_lensHub);
        collectModule = _collectModule;
    }

    function setHandleTokenId() external {
        handleTokenId = ILensHub(lensHub).tokenOfOwnerByIndex(address(this), 0);
    }

    function post(string memory postContent) external {
        
        ILensHub.PostData memory data = ILensHub.PostData({
            profileId: handleTokenId,
            contentURI: postContent, // TODO: add IPFS hash
            collectModule: collectModule,
            collectModuleInitData: abi.encode(false),
            referenceModule: address(0),
            referenceModuleInitData: ""
        });

        lensHub.post(data);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

/**
 * @title ILensHub
 * @author Lens Protocol
 *
 * @notice This is the interface for the LensHub contract, the main entry point for the Lens Protocol.
 * You'll find all the events and external functions, as well as the reasoning behind them here.
 */
interface ILensHub {
  /**
   * @notice A struct containing the parameters required for the `post()` function.
   *
   * @param profileId The token ID of the profile to publish to.
   * @param contentURI The URI to set for this new publication.
   * @param collectModule The collect module to set for this new publication.
   * @param collectModuleInitData The data to pass to the collect module's initialization.
   * @param referenceModule The reference module to set for the given publication, must be whitelisted.
   * @param referenceModuleInitData The data to be passed to the reference module for initialization.
   */
  struct PostData {
    uint256 profileId;
    string contentURI;
    address collectModule;
    bytes collectModuleInitData;
    address referenceModule;
    bytes referenceModuleInitData;
  }

  /**
   * @notice Publishes a post to a given profile, must be called by the profile owner.
   *
   * @param vars A PostData struct containing the needed parameters.
   *
   * @return uint256 An integer representing the post's publication ID.
   */
  function post(PostData calldata vars) external returns (uint256);

  function tokenOfOwnerByIndex(address owner, uint256 index) external returns (uint256);
}