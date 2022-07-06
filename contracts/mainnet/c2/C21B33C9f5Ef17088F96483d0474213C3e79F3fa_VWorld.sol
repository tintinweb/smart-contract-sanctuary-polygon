// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

struct LandData {
    /// x-axis
    uint256 horizontal;
    /// y-axis
    uint256 vertical;
    uint256 area;
}

/// @title A contract that allowes user to own, transfer land and see it's history
/// @author Vadim Urlin
/// @dev some of requierments are useless for small projects like this ,
///  but i thought having one is better than not having one)
contract VWorld {
    /// Mapping land ID to data
    mapping(uint256 => LandData) public _landData;

    /// Mapping from land ID to owner address
    mapping(uint256 => address) private _owners;

    /// Mapping land ID to all previous owners
    mapping(uint256 => address[]) private _ownershipHistory;

    /// Array of avaiableLands (tokenId's)
    uint256[] private avaiableLands = [1, 2, 3];

    constructor() {
        _setDefaultLandsInConstructor();
    }

    /// @dev I made this function to make constructor more clear
    function _setDefaultLandsInConstructor() internal {
        uint8[3][3] memory baseLandData = [[1, 1, 1], [2, 2, 1], [3, 3, 2]];
        for (uint256 i = 1; i < baseLandData.length + 1; i++) {
            uint8[3] memory selectedArr = baseLandData[i - 1];
            _landData[i] = LandData(
                selectedArr[0],
                selectedArr[1],
                selectedArr[2]
            );
        }
    }

    /// @param tokenId - id of the token that is being transfered
    /// @param newOwner - new owner of the token
    function transferOwnership(uint256 tokenId, address newOwner)
        external
        onlyLandOwner(tokenId)
    {
        require(
            newOwner != address(0) && newOwner != msg.sender,
            "Can't burn or transferOwnership to yourself"
        );
        require(
            _owners[tokenId] != address(0),
            "Can't transferOwnership of unclaimed token"
        );
        _owners[tokenId] = newOwner;
        _ownershipHistory[tokenId].push(_owners[tokenId]);
    }

    /// @dev after this function is called on tokenId , it can't be called on the same id again
    /// @param tokenId - id of the token that is being claimed
    function claimOwnership(uint256 tokenId) external {
        require(!_exists(tokenId), "Land already has owner");
        require(avaiableLands.length != 0, "All lands have been taken");

        _owners[tokenId] = msg.sender;
        _ownershipHistory[tokenId].push(_owners[tokenId]);
        _removeLandFromAvaiable(tokenId);
    }

    /// Return the owner of tokenId
    function ownerOf(uint256 tokenId) external view returns (address) {
        return _owners[tokenId];
    }

    /// Return all previous + current owner of token
    function ownershipHistoryOf(uint256 tokenId)
        external
        view
        returns (address[] memory)
    {
        return _ownershipHistory[tokenId];
    }

    /// Return all avaiableLands
    function getAvaiableLands() external view returns (uint256[] memory) {
        return avaiableLands;
    }

    function getLandData(uint256 tokenId)
        external
        view
        returns (LandData memory)
    {
        return _landData[tokenId];
    }

    /// Check is the token claimed or not
    function _exists(uint256 tokenId) internal view returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /// Removes land from avaiable array when it is claimed
    function _removeLandFromAvaiable(uint256 tokenId) internal {
        uint256 index = _getIndexOfTokenId(tokenId);
        avaiableLands[index] = avaiableLands[avaiableLands.length - 1];
        avaiableLands.pop();
    }

    /// Get the intex of tokenId in avaiableLands array
    function _getIndexOfTokenId(uint256 tokenId)
        internal
        view
        returns (uint256)
    {
        for (uint256 i = 0; i < avaiableLands.length; i++) {
            if (avaiableLands[i] == tokenId) {
                return i;
            }
        }
        revert("This tokenId is not avaiable");
    }

    /// Modified that makes sure only land owner call the function
    modifier onlyLandOwner(uint256 tokenId) {
        require(_owners[tokenId] == msg.sender, "Caller is not land owner");
        _;
    }
}