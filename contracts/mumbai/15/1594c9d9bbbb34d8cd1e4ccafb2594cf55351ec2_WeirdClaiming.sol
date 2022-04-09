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
    ERC20 public WeirdToken = ERC20(0x326C977E6efc84E512bB9C30f76E30c160eD06FB);
    WeirdPunks public WeirdPunksContract = WeirdPunks(0x0eD13579C74eff623F228Ec5D1572c5527EBD328);
    bytes32 public constant ORACLE = keccak256("ORACLE");
    mapping(uint256 => uint256) public lastClaimed;
    uint256 public tokensPerSecond;
    event checkEthTokens(address user);
    // uint256 public genesisTimestamp;
    
    constructor(address _oracleAddress, uint256 _tokensPerSecond) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(ORACLE, _oracleAddress);
        setTokensPerSecond(_tokensPerSecond);
        // genesisTimestamp = _genesisTimestamp;
    }

    function claim() public {
        uint256[] memory ownedIDs = WeirdPunksContract.walletOfOwner(msg.sender);
        uint256 owed;

        for(uint256 i; i < ownedIDs.length; i++) {
            uint256 currentID = ownedIDs[i];
            uint256 claimed = lastClaim(currentID);
            owed = owed.add(block.timestamp.sub(claimed).mul(tokensPerSecond));
            lastClaimed[currentID] = block.timestamp;
        }
        require(WeirdToken.balanceOf(address(this)) >= owed, "Not enough tokens in contract.");
        WeirdToken.transfer(msg.sender, owed);
        emit checkEthTokens(msg.sender);
    }

    function oracleClaimEthTokens(address user, uint256[] memory tokenIDs) public onlyRole(ORACLE) {
        for(uint256 i; i < tokenIDs.length; i++) {
            uint256 currentID = tokenIDs[i];
            lastClaimed[currentID] = block.timestamp;
        }
        uint256 amount = claimableForIDs(tokenIDs);
        require(WeirdToken.balanceOf(address(this)) >= amount, "Not enough tokens in contract.");
        WeirdToken.transfer(user, amount);
    }

    function claimableForIDs(uint256[] memory ownedIDs) public view returns (uint256) {
        uint256 owed;

        for(uint256 i; i < ownedIDs.length; i++) {
            uint256 currentID = ownedIDs[i];
            uint256 claimed = lastClaim(currentID);
            owed = owed.add(block.timestamp.sub(claimed).mul(tokensPerSecond));
        }
        return owed;
    }

    function lastClaim(uint256 id) public view returns (uint256) {
        uint256 mintedTimestamp = WeirdPunksContract.getMigrateTimestamp(id);
        return Math.max(lastClaimed[id], mintedTimestamp);
    }

    function setTokensPerSecond(uint256 _tokensPerSecond) public {
        tokensPerSecond = _tokensPerSecond;
    }

    function withdrawTokens() public {
        uint256 totalTokens = WeirdToken.balanceOf(address(this));
        WeirdToken.transfer(msg.sender, totalTokens);
    }
}