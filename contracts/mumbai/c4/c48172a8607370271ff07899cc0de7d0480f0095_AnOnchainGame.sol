// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "essential-contracts/contracts/fwd/EssentialERC2771Context.sol";
import {INFight} from "./lib/NFight/INFight.sol";

contract AnOnchainGame is EssentialERC2771Context {
    // Constants
    uint8 public constant teamCount = 3;
    uint256 public constant turnLength = 10 minutes;

    // Storage
    uint256 public gameStart;
    uint256 public playerCount;

    mapping(uint8 => uint256[]) public teamStartingSpaces;

    mapping(address => uint8) public playerTeam;
    mapping(address => uint256) public playerLastMove;
    mapping(address => uint256) public playerLocation;

    mapping(uint256 => uint256[]) public adjacentSpaces;
    mapping(uint256 => uint8) public controlledSpaces;
    mapping(uint8 => uint256[]) public roundBattleSpaces;

    // Events
    event Registered(address indexed player, address nftContract, uint256 nftTokenId);
    event Moved(address indexed player, uint256 spaceId);

    // Structs
    struct Space {
        uint256[] adjacentSpaces;
        uint256 spaceId;
    }

    struct Soldier {
        address contractAddress;
        uint256 tokenId;
        uint256 power;   
    }

    // Platform
    INFight public nFight;


    constructor(address _nFight, address trustedForwarder) EssentialERC2771Context(trustedForwarder) {
        nFight = INFight(_nFight);

        // TODO:
        // • start game at ideal time
        // • set controlledSpaces
    }

    // function startGame(uint256[9] calldata startSpaces) external onlyOwner {
    //     gameStart = block.timestamp;

    //     for (uint i = 0; i < playerCount;) {
    //         playerLocation[_msgSender()] = uint256(team);

    //     }

    // }

    function setMap(Space[] calldata spaces) external onlyOwner {
        uint256 count = spaces.length;
        for (uint256 index = 0; index < count; index++) {
            Space memory space = spaces[index];
            adjacentSpaces[space.spaceId] = space.adjacentSpaces;
        }

        // for (uint256 teamIndex = 0; teamIndex < teamCount; teamIndex++) {
        //     teamStartingSpaces[uint8(teamIndex)] = startSpaces[teamIndex];
        // }
    }

    function register() external onlyForwarder {
        require(playerLocation[_msgSender()] == 0, "Already registered");
        IForwardRequest.NFT memory nft = _msgNFT();
        Soldier memory soldier = soldierStats(nft.contractAddress, nft.tokenId);
        
        playerCount += 1;
        uint256 team = playerCount % teamCount;

        playerTeam[_msgSender()] = uint8(team);
        playerLocation[_msgSender()] = teamStartingSpaces[uint8(team)][block.number % teamStartingSpaces[uint8(team)].length];


        emit Registered(_msgSender(), soldier.contractAddress, soldier.tokenId);
    }

    function currentRound() public view returns (uint8) {
        uint256 elapsed = block.timestamp - gameStart;

        return uint8((elapsed / (teamCount * turnLength)) + 1);
    }

    function currentRoundStart() public view returns (uint256) {
        return gameStart + (currentRound() - 1) * teamCount * turnLength;
    }

    function currentTeamMove() public view returns (uint256) {
        uint256 roundStart = gameStart + (turnLength * teamCount * (currentRound() - 1));
        uint256 elapsedRound = block.timestamp - roundStart;

        return (elapsedRound / turnLength) + 1;
    }

    function playersPerTeam(uint8 team) public view returns (uint256 count) {
        uint256 min = playerCount / teamCount;
        uint256 mod = playerCount % teamCount;

        count = min + (mod > (team - 1) ? 1 : 0);
    }

    function performMove(uint256 targetSpace) external onlyForwarder {
        // TODO: would a merkle tree be better here for list of valid adjacent spaces?
        // The max adjacent spaces will prob be < 10, not a crazy loop
        //
        address player = _msgSender();
        require(playerTeam[player] == currentTeamMove(), "Not your team's turn");
        require(playerLastMove[player] < currentRoundStart(), "Move alrready taken this round");

        uint256 currentSpace = playerLocation[player];
        uint256 availableSpaceCount = adjacentSpaces[currentSpace].length;

        bool validMove;
        for (uint256 index = 0; index < availableSpaceCount; ) {
            if (adjacentSpaces[currentSpace][index] == targetSpace) {
                validMove = true;
                break;
            }
            unchecked {
                ++index;
            }
        }

        require(validMove == true, "Ivalid Move");

        playerLastMove[player] = block.timestamp;
        playerLocation[player] = targetSpace;
        
        uint256 controllingTeam = controlledSpaces[targetSpace];

        if (controllingTeam == 0) {
            controlledSpaces[targetSpace] = playerTeam[player];
        } else if (controllingTeam != playerTeam[player] && controllingTeam <= teamCount) {
            // attackers cant move again?
            roundBattleSpaces[currentRound()].push(targetSpace);
            controlledSpaces[targetSpace] = teamCount + 1;
        }

        emit Moved(player, targetSpace);
    }

    function performBattle(uint256 battleSpace) internal {}

    function soldierStats(address contractAddress, uint256 _tokenId) internal view returns (Soldier memory soldier) {
        (
            ,
            ,
            ,
            ,
            ,
            uint256 power
        ) = nFight.getFighter(contractAddress, _tokenId);

        require(power != 0, "WM:mW:404");

        soldier = Soldier({
            power: power,
            contractAddress: contractAddress,
            tokenId: _tokenId
        });
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/Context.sol";
import "./IForwardRequest.sol";

/**
 * @dev Context variant with ERC2771 support.
 */
abstract contract EssentialERC2771Context is Context {
    address private _trustedForwarder;
    address public owner;

    modifier onlyOwner() {
        require(msg.sender == owner, "403");
        _;
    }

    modifier onlyForwarder() {
        require(isTrustedForwarder(msg.sender), "Counter:429");
        _;
    }

    constructor(address trustedForwarder) {
        owner = msg.sender;
        _trustedForwarder = trustedForwarder;
    }

    function setTrustedForwarder(address trustedForwarder) external onlyOwner {
        _trustedForwarder = trustedForwarder;
    }

    function isTrustedForwarder(address forwarder) public view virtual returns (bool) {
        return forwarder == _trustedForwarder;
    }

    function _msgSender() internal view virtual override returns (address sender) {
        if (isTrustedForwarder(msg.sender)) {
            // The assembly code is more direct than the Solidity version using `abi.decode`.
            assembly {
                sender := shr(0x60, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return super._msgSender();
        }
    }

    function _msgData() internal view virtual override returns (bytes calldata) {
        if (isTrustedForwarder(msg.sender)) {
            return msg.data[:msg.data.length - 72];
        } else {
            return super._msgData();
        }
    }

    function _msgNFT() internal view returns (IForwardRequest.NFT memory) {
        uint256 tokenId;
        address contractAddress;
        if (isTrustedForwarder(msg.sender)) {
            assembly {
                contractAddress := shr(0x60, calldataload(sub(calldatasize(), 40)))
                tokenId := calldataload(sub(calldatasize(), 72))
            }
        }

        return IForwardRequest.NFT({contractAddress: contractAddress, tokenId: tokenId});
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface INFight {
    struct Fighter {
        uint256 aggression;
        uint256 awareness;
        uint256 determination;
        uint256 power;
        uint256 resilience;
        uint256 speed;
    }

    function getFighter(address contractAddress, uint256 _tokenId)
        external
        view
        returns (
            uint256 power,
            uint256 speed,
            uint256 aggression,
            uint256 determination,
            uint256 resilience,
            uint256 awareness
        );

    function reportWin(
        address player,
        address targetContract,
        uint256 tokenId
    ) external;

    function reportLoss(address player) external;

    function registerPolygonNFT(
        address contractAddress,
        uint256 tokenId,
        address owner
    ) external;

    function registerToken(address contractAddress, uint256 tokenId) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

interface IForwardRequest {
    struct ERC721ForwardRequest {
        address from; // Externally-owned account (EOA) signing the request.
        address authorizer; // Externally-owned account (EOA) that authorized from account in PlaySession.
        address to; // Destination address, normally a smart contract for an nFight game.
        address nftContract; // The address of the NFT contract for the token being used.
        uint256 nftTokenId; // The tokenId of the NFT being used
        uint256 nftChainId; // The chainId of the NFT neing used
        uint256 targetChainId; // The chainId where the Forwarder and implementation contract are deployed.
        uint256 value; // Amount of ether to transfer to the destination.
        uint256 gas; // Amount of gas limit to set for the execution.
        uint256 nonce; // On-chain tracked nonce of a transaction.
        bytes data; // (Call)data to be sent to the destination.
    }

    struct MetaTransaction {
        uint256 nonce;
        address from;
        bytes functionSignature;
    }

    struct PlaySession {
        address authorized; // Burner EOA that is authorized to play with NFTs by owner EOA.
        uint256 expiresAt; // block timestamp when the session is invalidated.
    }

    struct NFT {
        address contractAddress;
        uint256 tokenId;
    }
}