/**
 *Submitted for verification at polygonscan.com on 2022-02-21
*/

// File: contracts/ArianeeLost/ArianeeLost.sol

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

abstract contract iSmartAsset{
    function ownerOf(uint256 _tokenId) virtual external returns (address _owner);
}

contract ArianeeLost{

    event Lost(uint256 indexed _tokenId);

    event Retrieved(uint256 indexed _tokenId);

    mapping(uint256 => bool) lostTokensUnderlying;

    iSmartAsset public smartAsset;

     /**
      * @param _smartAssetAddress address of SmartAssetContract
      */
    constructor(address _smartAssetAddress) {
        smartAsset =iSmartAsset(_smartAssetAddress);
    }

    /**
     * @dev Only owner can modifier
     * @param _tokenId tokenId of certificate.
     */
    modifier onlyOwner(uint256 _tokenId){
      require(
        smartAsset.ownerOf(_tokenId) == msg.sender,
        "Not authorized because not the owner"
        );
        _;
    }

     /**
      * @dev tokenId's underlying has to be lost
      * @param _tokenId tokenId of certificate.
      */
    modifier onlyHasBeenLost(uint256 _tokenId){
      require(
        lostTokensUnderlying[_tokenId] == true,
        "tokenId's underlying is not lost"
        );
        _;
    }

    /**
     * @dev tokenId's underlying has not to be lost
     * @param _tokenId tokenId of certificate.
     */
    modifier onlyHasNotBeenLost(uint256 _tokenId){
      require(
        lostTokensUnderlying[_tokenId] == false,
        "tokenId's underlying is not lost"
        );
        _;
    }

    /**
     * @dev Public function to set tokenId's underlying status as lost
     * @param _tokenId tokenId of certificate.
     */
    function setLost(uint256 _tokenId) external onlyOwner(_tokenId) onlyHasNotBeenLost(_tokenId){
        lostTokensUnderlying[_tokenId]=true;
        emit Lost(_tokenId);
    }

    /**
     * @dev Public function to unset tokenId's underlying status as lost. underlying has been retrieved.
     * @param _tokenId tokenId of certificate.
     */
    function unsetLost(uint256 _tokenId) external onlyOwner(_tokenId) onlyHasBeenLost(_tokenId){
        lostTokensUnderlying[_tokenId]=false;
        emit Retrieved(_tokenId);
    }

    /**
     * @dev Public function to get status of token.
     * @param _tokenId tokenId of certificate.
     */
    function isLost(uint256 _tokenId) public view returns (bool _isLost) {
    _isLost = lostTokensUnderlying[_tokenId];
  }

}