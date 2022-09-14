/**
 *Submitted for verification at polygonscan.com on 2022-09-13
*/

// Sources flattened with hardhat v2.0.7 https://hardhat.org

// File contracts/tunnel/FxBaseChildTunnel.sol

// SPDX-License-Identifier: MIT
pragma solidity 0.7.3;

// IFxMessageProcessor represents interface to process message
interface IFxMessageProcessor {
    function processMessageFromRoot(uint256 stateId, address rootMessageSender, bytes calldata data) external;
}

/**
* @notice Mock child tunnel contract to receive and send message from L2
*/
abstract contract FxBaseChildTunnel is IFxMessageProcessor{
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
        require(sender == fxRootTunnel, "FxBaseChildTunnel: INVALID_SENDER_FROM_ROOT");
        _;
    }

    // set fxRootTunnel if not set already
    function setFxRootTunnel(address _fxRootTunnel) public {
        require(fxRootTunnel == address(0x0), "FxBaseChildTunnel: ROOT_TUNNEL_ALREADY_SET");
        fxRootTunnel = _fxRootTunnel;
    }

    function processMessageFromRoot(uint256 stateId, address rootMessageSender, bytes calldata data) public override {
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
    function _sendMessageToRoot(bytes memory message) internal {
        emit MessageSent(message);
    }

    /**
     * @notice Process message received from Root Tunnel
     * @dev function needs to be implemented to handle message as per requirement
     * This is called by onStateReceive function.
     * Since it is called via a system call, any event will not be emitted during its execution.
     * @param stateId uniquestate id
     * @param sender root message sender
     * @param message bytes message that was sent from Root Tunnel
     */
    function _processMessageFromRoot(uint256 stateId, address sender, bytes memory message) virtual internal;
}


// File contracts/examples/state-transfer/FxStateChildTunnel.sol

pragma solidity 0.7.3;

interface ToshimonMinter {
  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _id,
    uint256 _amount,
    bytes calldata _data
  ) external;

  function safeBatchTransferFrom(
    address _from,
    address _to,
    uint256[] calldata _ids,
    uint256[] calldata _amounts,
    bytes calldata _data
  ) external;

  function setApprovalForAll(address _operator, bool _approved) external;

  function isApprovedForAll(address _owner, address _operator)
    external
    view
    returns (bool isOperator);

  function balanceOf(address _owner, uint256 _id)
    external
    view
    returns (uint256);

  function totalSupply(uint256 _id) external view returns (uint256);

  function tokenMaxSupply(uint256 _id) external view returns (uint256);

  function burn(
    address _account,
    uint256 _id,
    uint256 _amount
  ) external;

  function mint(
    address _to,
    uint256 _id,
    uint256 _quantity,
    bytes memory _data
  ) external;
  function mintBatch(address user, uint256[] calldata ids, uint256[] calldata amounts)
        external;
}
pragma experimental ABIEncoderV2;
/** 
 * @title FxStateChildTunnel
 * 
 */
contract ToshimonFxStateChildTunnel is FxBaseChildTunnel {

    ToshimonMinter public toshimonMinter;
    
      uint256 public lastStateId;
      uint256 public packsPurchased;
      uint256 public packsRedeemed;
      bytes private prevHash;
    
      uint256[] public probabilities;
      uint256[][] public cardRanges;
      uint256[] public probabilitiesRare;
      uint256[][] public cardRangesRare; 
      struct PackData{
          uint256[] cards;
          uint256[] quantities;
      }
      mapping(uint256 => PackData) packOpeningResults;
    
    
      event Redeemed(
        uint256 indexed _stateId,
        uint256 indexed _cardId
      );
//fxChild 0x8397259c983751DAf40400790063935a11afa28a
//
    constructor() FxBaseChildTunnel(0x8397259c983751DAf40400790063935a11afa28a) {
        toshimonMinter = ToshimonMinter(0x7658ab44641352046Bde4Aa6df9A62966F439893);
        prevHash = abi.encodePacked(block.timestamp, msg.sender);
        probabilities = [350,600,780,930,980,995,1000];
        cardRanges = [[uint256(1),uint256(102)],[uint256(103),uint256(180)],[uint256(181),uint256(226)],[uint256(227),uint256(248)],[uint256(249),uint256(258)],[uint256(259),uint256(263)],[uint256(264),uint256(264)]];
        probabilitiesRare = [700,930,980,995,1000];
        cardRangesRare = [[265,291],[292,307],[308,310],[311,311],[312,312]];
    }
    
  function getPackOpeningResults(uint256 id) external view returns (uint256[] memory cards, uint256[] memory quantities) {
      PackData memory packData = packOpeningResults[id];
      uint256[] memory _cards = new uint256[](packData.cards.length);
      uint256[] memory _quantities = new uint256[](packData.cards.length);
      
      for(uint256 i = 0; i < packData.cards.length; i++){
          _cards[i] = packData.cards[i];
          _quantities[i] = packData.quantities[i];
      }
      return (_cards,_quantities);
  }
    
  function redeemPackFromBridge(uint256 stateId, uint256 _packsToRedeem, address sender) internal {



    uint256 probability;
    uint256 max;
    uint256 min; 
    uint256[] memory _cardsToMint = new uint256[](312);
    uint256[] memory _cardsToMintCount = new uint256[](312);
    uint256 cardIdWon;
    uint256 rng = _rngSimple(_rng(sender));


    for (uint256 i = 0; i < _packsToRedeem; ++i) {

      for (uint256 j = 0; j < 7; ++j) {
          probability = rng % 1000;
          for (uint256 _probIndex = 0; _probIndex < probabilities.length; ++_probIndex) {
            if(probability < probabilities[_probIndex]){
              max = cardRanges[_probIndex][1];
              min = cardRanges[_probIndex][0];
              break;
            }
          }
          rng = _rngSimple(rng);
          cardIdWon = (rng % (max + 1 - min)) + min;
          _cardsToMint[cardIdWon - 1] = cardIdWon;
          _cardsToMintCount[cardIdWon - 1] = _cardsToMintCount[cardIdWon - 1] + 1;
          emit Redeemed(stateId,cardIdWon);
      }
      
      // run for rare packs start
      probability = rng % 1000;
      for (uint256 _probIndex = 0; _probIndex < probabilitiesRare.length; ++_probIndex) {
        if(probability < probabilitiesRare[_probIndex]){
          max = cardRangesRare[_probIndex][1];
          min = cardRangesRare[_probIndex][0];
          break;
        }
      }
      rng = _rngSimple(rng);
      cardIdWon = (rng % (max + 1 - min)) + min;
      _cardsToMint[cardIdWon - 1] = cardIdWon;
      _cardsToMintCount[cardIdWon - 1] = _cardsToMintCount[cardIdWon - 1] + 1;
      emit Redeemed(stateId,cardIdWon);
    }
    
    toshimonMinter.mintBatch(sender,_cardsToMint,_cardsToMintCount);
  }
  

    function _processMessageFromRoot(uint256 stateId, address sender, bytes memory data)
        internal
        override
        validateSender(sender) {
        (uint256 quantity, address addy) = abi.decode(data, (uint256, address));
        lastStateId = stateId;
        
        redeemPackFromBridge(stateId, quantity, addy);

    }
    

  function _rng(address sender) internal returns (uint256) {
    bytes32 ret = keccak256(prevHash);
    prevHash = abi.encodePacked(ret, block.coinbase, sender);
    return uint256(ret);
  }
  function _rngSimple(uint256 seed) internal pure returns (uint256) {

    return uint256(keccak256(abi.encodePacked(seed)));
  }
  

  function sendMessageToRoot(bytes memory message) public {
    _sendMessageToRoot(message);
  }
}