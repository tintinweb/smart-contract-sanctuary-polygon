/**
 *Submitted for verification at polygonscan.com on 2022-11-16
*/

// File: contracts/FxBaseChildTunnel.sol


pragma solidity ^0.8.0;

// IFxMessageProcessor represents interface to process message
interface IFxMessageProcessor {
    function processMessageFromRoot(
        uint256 stateId,
        address rootMessageSender,
        bytes calldata data
    ) external;
}

/**
 * @notice Mock child tunnel contract to receive and send message from L2
 */
abstract contract FxBaseChildTunnel is IFxMessageProcessor {
    // MessageTunnel on L1 will get data from this event
    event MessageSent(bytes message);

    // fx child
    address public fxChild;

    // fx root tunnel
    address public fxRootTunnel;

    constructor(address _fxChild) {
        fxChild = _fxChild;
    }

    // Sender must be fxRootTunnel in case of ERC20 tunnel
    modifier validateSender(address sender) {
        require(
            sender == fxRootTunnel,
            "FxBaseChildTunnel: INVALID_SENDER_FROM_ROOT"
        );
        _;
    }

    // set fxRootTunnel if not set already
    function setFxRootTunnel(address _fxRootTunnel) external virtual {
       
        fxRootTunnel = _fxRootTunnel;
    }

    function processMessageFromRoot(
        uint256 stateId,
        address rootMessageSender,
        bytes calldata data
    ) external override {
        require(msg.sender == fxChild, "FxBaseChildTunnel: INVALID_SENDER");
        _processMessageFromRoot(stateId, rootMessageSender, data);
    }

    /**
     * @notice Emit message that can be received on Root Tunnel
     * @dev Call the internal function when need to emit message
     * @param message bytes message that will be sent to Root Tunnel
     * some message examples -
     *   abi.encode(tokenId);
     *   abi.encode(tokenId, tokenMetadata);
     *   abi.encode(messageType, messageData);
     */


    /**
     * @notice Process message received from Root Tunnel
     * @dev function needs to be implemented to handle message as per requirement
     * This is called by onStateReceive function.
     * Since it is called via a system call, any event will not be emitted during its execution.
     * @param stateId unique state id
     * @param sender root message sender
     * @param message bytes message that was sent from Root Tunnel
     */
    function _processMessageFromRoot(
        uint256 stateId,
        address sender,
        bytes memory message
    ) internal virtual;
}

// File: contracts/IRaffleMinter.sol

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IRaffleMinter {
    function addNftBurnRaffle(address _user, uint256 _tokens) external;
}
// File: contracts/PolygonBurnManager.sol

pragma solidity ^0.8.0;



contract PolygonBurnManager is FxBaseChildTunnel {
    uint256 internal constant ALICE = 0x0001;
    uint256 internal constant QUEEN = 0x0002;
    uint256 internal constant CLUBS_OF_RUNNER = 0x0013;
    uint256 internal constant DIAMOND_OF_ENERGY = 0x0023;
    uint256 internal constant SPADES_OF_MARKER = 0x0033;
    uint256 internal constant HEART_OF_ALL_ROUNDER = 0x0043;

    uint256 public received1;
    address public received2;


    IRaffleMinter raffleMinter;
    mapping(uint256 => uint256) rafflePerToken;

    constructor(IRaffleMinter _raffle, address fxChild)
        FxBaseChildTunnel(fxChild)
    {
        raffleMinter = _raffle;
    }

    function setRafflePerToken(
        uint256[] memory _tokens,
        uint256[] memory _raffles
    ) external  {
        _setRaffles(_tokens, _raffles);
    }

    function _setRaffles(uint256[] memory _tokens, uint256[] memory _raffles)
        internal
    {
        uint256 loop = _tokens.length;
        for (uint256 i = 0; i < loop; i++) {
            rafflePerToken[_tokens[i] = _raffles[i]];
        }
    }

    function _character(uint256 _tokenId) internal pure returns (uint256) {
        uint256 mask = 0x00000000000000000000000000000000000000000000000FFFF0000;
        return (_tokenId & mask) >> 16;
    }

  

    function addBurnData(address _user, uint256[] memory _tokenIds)
         public  
       
    {
        uint256 loop = _tokenIds.length;
        uint256 total;
        for (uint256 i = 0; i < loop; i++) {
            total += rafflePerToken[_character(_tokenIds[i])];
        }
        raffleMinter.addNftBurnRaffle(_user, total);
    }

      function _processMessageFromRoot(
        uint256, /* stateId */
        address sender,
        bytes memory data
    ) internal override {
        (uint256 tokenId, address tokenOwner) = abi.decode(
            data,
            (uint256, address)
        );
        received1=tokenId;
        received2=tokenOwner;
       uint256[] memory tokenIds=new uint256[](1);
       tokenIds[0]=tokenId;
        addBurnData(tokenOwner, tokenIds );
    }
}