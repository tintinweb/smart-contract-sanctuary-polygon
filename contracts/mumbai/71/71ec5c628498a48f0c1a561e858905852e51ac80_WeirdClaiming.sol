// SPDX-License-Identifier: MIT

/*
 __    __    ___  ____  ____   ___        ____  __ __  ____   __  _  _____
|  |__|  |  /  _]|    ||    \ |   \      |    \|  |  ||    \ |  |/ ]/ ___/
|  |  |  | /  [_  |  | |  D  )|    \     |  o  )  |  ||  _  ||  ' /(   \_ 
|  |  |  ||    _] |  | |    / |  D  |    |   _/|  |  ||  |  ||    \ \__  |
|  `  '  ||   [_  |  | |    \ |     |    |  |  |  :  ||  |  ||     \/  \ |
 \      / |     | |  | |  .  \|     |    |  |  |     ||  |  ||  .  |\    |
  \_/\_/  |_____||____||__|\_||_____|    |__|   \__,_||__|__||__|\_| \___|
                                                                          
*/

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC20.sol";
import "./AccessControl.sol";
import "./WeirdPunks.sol";
import "./SafeMath.sol";
import "./Math.sol";


contract WeirdClaiming is Ownable, AccessControl {
    using SafeMath for uint256;
    ERC20 public WeirdToken = ERC20(0x70d2a1eee95FC742D64A72E649eE811c6b117Cc0);
    WeirdPunks public WeirdPunksContract = WeirdPunks(0x5eF879bA18f8309cC403Fe4041D7d1Ff86Feb2bd);
    bytes32 public constant ORACLE = keccak256("ORACLE");
    mapping(uint256 => uint256) internal lastClaimed;
    uint256 public tokensPerSecond = 11574074074000;
    event checkEthTokens(address user);
    address oracleAddress;
    
    constructor(address _oracleAddress) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(ORACLE, _oracleAddress);
        oracleAddress = _oracleAddress;
    }

    function claim() public {
        uint256[] memory ownedIDs = WeirdPunksContract.walletOfOwner(msg.sender);
        uint256 owed;

        for(uint256 i; i < ownedIDs.length; i++) {
            uint256 currentID = ownedIDs[i];
            uint256 claimed = lastClaim(currentID);
            require(lastClaim(currentID) > 0, "Error in last claimed amount.");
            owed = owed.add(block.timestamp.sub(claimed).mul(tokensPerSecond));
            lastClaimed[currentID] = block.timestamp;
        }
        require(WeirdToken.balanceOf(address(this)) >= owed, "Not enough tokens in contract.");
        WeirdToken.transfer(msg.sender, owed);
        emit checkEthTokens(msg.sender);
    }

    function oracleClaimEthTokens(address user, uint256[] memory tokenIDs, uint256[] memory ethMigratedTimestamps) public onlyRole(ORACLE) {
        require(tokenIDs.length == ethMigratedTimestamps.length, "tokenIDs and timestamps don't match.");
        uint256 amount = _claimableForIDs(tokenIDs, ethMigratedTimestamps);
        require(WeirdToken.balanceOf(address(this)) >= amount, "Not enough tokens in contract.");
        WeirdToken.transfer(user, amount);
        for(uint256 i; i < tokenIDs.length; i++) {
            uint256 currentID = tokenIDs[i];
            lastClaimed[currentID] = block.timestamp;
        }
    }

    function claimableForWallet(address _user) public view returns (uint256) {
        uint256[] memory ownedIDs = WeirdPunksContract.walletOfOwner(_user);
        uint256 owed;

        for(uint256 i; i < ownedIDs.length; i++) {
            uint256 currentID = ownedIDs[i];
            uint256 claimed = lastClaim(currentID);
            owed = owed.add(block.timestamp.sub(claimed).mul(tokensPerSecond));
        }
        return owed;
    }

    function claimableForIDs(uint256[] memory ownedIDs) public view returns (uint256) {
        uint256 owed;

        for(uint256 i; i < ownedIDs.length; i++) {
            uint256 currentID = ownedIDs[i];
            uint256 claimed = lastClaim(currentID);
            require(lastClaim(currentID) > 0, "Error in last claimed amount.");
            owed = owed.add(block.timestamp.sub(claimed).mul(tokensPerSecond));
        }
        return owed;
    }

    function _claimableForIDs(uint256[] memory ownedIDs, uint256[] memory timestamps) internal view returns (uint256) {
        uint256 owed;

        for(uint256 i; i < ownedIDs.length; i++) {
            uint256 currentID = ownedIDs[i];
            uint256 claimed = Math.max(lastClaim(currentID), timestamps[i]);
            // require(lastClaim(currentID) > 0, "Error in last claimed amount.");
            owed = owed.add(block.timestamp.sub(claimed).mul(tokensPerSecond));
        }
        return owed;
    }

    function lastClaim(uint256 id) public view returns (uint256) {
        uint256 mintedTimestamp = WeirdPunksContract.getMigrateTimestamp(id);
        return Math.max(lastClaimed[id], mintedTimestamp);
    }

    function withdrawTokens() public onlyOwner {
        uint256 totalTokens = WeirdToken.balanceOf(address(this));
        WeirdToken.transfer(msg.sender, totalTokens);
    }

    function setOracleAddress(address newOracleAddress) public onlyOwner {
        _revokeRole(ORACLE, oracleAddress);
        _grantRole(ORACLE, newOracleAddress);
        oracleAddress = newOracleAddress;
    }
}