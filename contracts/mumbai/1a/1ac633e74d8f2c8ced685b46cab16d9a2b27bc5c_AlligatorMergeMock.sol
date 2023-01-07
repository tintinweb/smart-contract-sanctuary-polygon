// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// _______________________________________________________________________
//     _   _                              __                              
//     /  /|                            /    )                            
// ---/| /-|----__---)__----__----__---/---------__--_/_----__---)__---__-
//   / |/  |  /___) /   ) /   ) /___) /  --,   /   ) /    /   ) /   ) (_ `
// _/__/___|_(___ _/_____(___/_(___ _(____/___(___(_(_ __(___/_/_____(__)_
//                          /                                             
//                      (_ /                                              

import {MultiSigWallet} from './treasury.sol';
import './extension/Ownable.sol';
import './chainlink/VRFConsumerBaseV2.sol';
import './chainlink/VRFCoordinatorV2Interface.sol';
import './IAlligators.sol';
import './IMergeGators.sol';

interface ERC721A__IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

contract AlligatorMerge is Ownable, VRFConsumerBaseV2, IMergeGators {

    
    /*//////////////////////////////////////////////////////////////
                               MERGE GATORS
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => RequestStatusMerge) private vrf_requests; 

    uint64 private immutable subscriptionId;
    uint32 private immutable callbackGasLimit = 100000;
    uint32 private constant NUM_WORDS = 1;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    bytes32 private immutable gasLane;
    VRFCoordinatorV2Interface private immutable mvrfCoordinator;

    uint256 internal constant MAX_CHANCE_VALUE = 1000;
    uint256 internal MIN_CHANCE_VALUE = 777;

    uint256 private _taxAmount;
    uint256 private _prizeBps;
    uint256 private _prizePortionBps;

    address payable public taxTreasury;

    address public alligatorsAddress;

    constructor(
        address ownerAddr,
        address ERC721_,
        address payable _taxTreasuryAddress,
        uint256 taxPay_,
        uint64 subscriptionId_,
        address vrfCoordinatorV2_,
        bytes32 gasLane_,
        uint256 prizeBps_,
        uint256 prizePortionBps_
    ) VRFConsumerBaseV2(vrfCoordinatorV2_) {

            _setupOwner(ownerAddr);
            //alligators = Alligators(ERC721_);
            alligatorsAddress = ERC721_;
            taxTreasury = _taxTreasuryAddress;
            _taxAmount = taxPay_;
            _prizeBps = prizeBps_;
            _prizePortionBps = prizePortionBps_;
            subscriptionId = subscriptionId_;
            mvrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinatorV2_);
            gasLane = gasLane_;
        }

    function merge(uint256 _1st, uint256 _2nd, uint256 _3rd) public payable {
        if (msg.value < _taxAmount) revert callErr();
        if (IAlligators(alligatorsAddress).tokenType(_1st) == 3) revert Mergefailed();
        if (IAlligators(alligatorsAddress).tokenType(_2nd) == 3) revert Mergefailed();
        if (IAlligators(alligatorsAddress).tokenType(_3rd) == 3) revert Mergefailed();
        payable(taxTreasury).transfer(_taxAmount - _calculatePortionToRewardPool());
        payable(address(this)).transfer(_calculatePortionToRewardPool());

        uint8[2] memory _1stType = _compareTrait(_1st, _2nd, _3rd, 0);
        uint8[2] memory _2ndType = _compareTrait(_1st, _2nd, _3rd, 1);
        uint8[2] memory _3rdType = _compareTrait(_1st, _2nd, _3rd, 2);
        uint8[2] memory _4thType = _compareTrait(_1st, _2nd, _3rd, 3);
        uint8[2] memory _5thType = _compareTrait(_1st, _2nd, _3rd, 4);
        uint8[2] memory _6thType = _compareTrait(_1st, _2nd, _3rd, 5);
        uint8[2] memory _7thType = _compareTrait(_1st, _2nd, _3rd, 6);

        lvlUp levelUp = lvlUp.FALSE;

        // Generate Merged NFT
        if (IAlligators(alligatorsAddress).anatomy(_1st)[0] == IAlligators(alligatorsAddress).anatomy(_2nd)[0] 
        && IAlligators(alligatorsAddress).anatomy(_1st)[0] == IAlligators(alligatorsAddress).anatomy(_3rd)[0]) {
            if (IAlligators(alligatorsAddress).alligator_level(_1st)[0] == IAlligators(alligatorsAddress).alligator_level(_2nd)[0] 
            && IAlligators(alligatorsAddress).alligator_level(_1st)[0] == IAlligators(alligatorsAddress).alligator_level(_3rd)[0]) {
                if (IAlligators(alligatorsAddress).alligator_level(_1st)[0] < 5) {
                    _1stType[1]++;
                    levelUp = lvlUp.TRUE;
                }
            }
        }
        
        if (IAlligators(alligatorsAddress).anatomy(_1st)[1] == IAlligators(alligatorsAddress).anatomy(_2nd)[1] 
        && IAlligators(alligatorsAddress).anatomy(_1st)[1] == IAlligators(alligatorsAddress).anatomy(_3rd)[1]) {
            if (IAlligators(alligatorsAddress).alligator_level(_1st)[1] == IAlligators(alligatorsAddress).alligator_level(_2nd)[1] 
            && IAlligators(alligatorsAddress).alligator_level(_1st)[1] == IAlligators(alligatorsAddress).alligator_level(_3rd)[1]) {
                if (IAlligators(alligatorsAddress).alligator_level(_1st)[1] < 5) {
                    _2ndType[1]++;
                    levelUp = lvlUp.TRUE;
                }
            }
        }
        
        if (IAlligators(alligatorsAddress).anatomy(_1st)[2] == IAlligators(alligatorsAddress).anatomy(_2nd)[2] 
        && IAlligators(alligatorsAddress).anatomy(_1st)[2] == IAlligators(alligatorsAddress).anatomy(_3rd)[2]) {
            if (IAlligators(alligatorsAddress).alligator_level(_1st)[2] == IAlligators(alligatorsAddress).alligator_level(_2nd)[2] 
            && IAlligators(alligatorsAddress).alligator_level(_1st)[2] == IAlligators(alligatorsAddress).alligator_level(_3rd)[2]) {
                if (IAlligators(alligatorsAddress).alligator_level(_1st)[2] < 5) {
                    _3rdType[1]++;
                    levelUp = lvlUp.TRUE;
                }
            }
        }
        
        if (IAlligators(alligatorsAddress).anatomy(_1st)[3] == IAlligators(alligatorsAddress).anatomy(_2nd)[3] 
        && IAlligators(alligatorsAddress).anatomy(_1st)[3] == IAlligators(alligatorsAddress).anatomy(_3rd)[3]) {
            if (IAlligators(alligatorsAddress).alligator_level(_1st)[3] == IAlligators(alligatorsAddress).alligator_level(_2nd)[3] 
            && IAlligators(alligatorsAddress).alligator_level(_1st)[3] == IAlligators(alligatorsAddress).alligator_level(_3rd)[3]) {
                if (IAlligators(alligatorsAddress).alligator_level(_1st)[3] < 5) {
                    _4thType[1]++;
                    levelUp = lvlUp.TRUE;
                }
            }
        }
        
        if (IAlligators(alligatorsAddress).anatomy(_1st)[4] == IAlligators(alligatorsAddress).anatomy(_2nd)[4] 
        && IAlligators(alligatorsAddress).anatomy(_1st)[4] == IAlligators(alligatorsAddress).anatomy(_3rd)[4]) {
            if (IAlligators(alligatorsAddress).alligator_level(_1st)[4] == IAlligators(alligatorsAddress).alligator_level(_2nd)[4] 
            && IAlligators(alligatorsAddress).alligator_level(_1st)[4] == IAlligators(alligatorsAddress).alligator_level(_3rd)[4]) {
                if (IAlligators(alligatorsAddress).alligator_level(_1st)[4] < 5) {
                    _5thType[1]++;
                    levelUp = lvlUp.TRUE;
                }
            }
        }
        
        if (IAlligators(alligatorsAddress).anatomy(_1st)[5] == IAlligators(alligatorsAddress).anatomy(_2nd)[5] 
        && IAlligators(alligatorsAddress).anatomy(_1st)[5] == IAlligators(alligatorsAddress).anatomy(_3rd)[5]) {
            if (IAlligators(alligatorsAddress).alligator_level(_1st)[5] == IAlligators(alligatorsAddress).alligator_level(_2nd)[5] 
            && IAlligators(alligatorsAddress).alligator_level(_1st)[5] == IAlligators(alligatorsAddress).alligator_level(_3rd)[5]) {
                if (IAlligators(alligatorsAddress).alligator_level(_1st)[5] < 5) {
                    _6thType[1]++;
                    levelUp = lvlUp.TRUE;
                }
            }
        }
        
        if (IAlligators(alligatorsAddress).anatomy(_1st)[6] == IAlligators(alligatorsAddress).anatomy(_2nd)[6] 
        && IAlligators(alligatorsAddress).anatomy(_1st)[6] == IAlligators(alligatorsAddress).anatomy(_3rd)[6]) {
            if(IAlligators(alligatorsAddress).alligator_level(_1st)[6] == IAlligators(alligatorsAddress).alligator_level(_2nd)[6] 
            && IAlligators(alligatorsAddress).alligator_level(_1st)[6] == IAlligators(alligatorsAddress).alligator_level(_3rd)[6]) {
                if (IAlligators(alligatorsAddress).alligator_level(_1st)[6] < 5) {
                    _7thType[1]++;
                    levelUp = lvlUp.TRUE;
                }
            }
        }

        if (levelUp != lvlUp.TRUE) revert Mergefailed();

        IAlligators(alligatorsAddress).createSkeleton(_1stType[0], _2ndType[0], _3rdType[0], _4thType[0], _5thType[0], _6thType[0], _7thType[0]);
        IAlligators(alligatorsAddress).createLevels(_1stType[1], _2ndType[1], _3rdType[1], _4thType[1], _5thType[1], _6thType[1], _7thType[1]);
        IAlligators(alligatorsAddress).merge(_1st, _2nd, _3rd, msg.sender);
        
        _mergePrize(msg.sender);
    }

    function _mergePrize(address _receiver) internal returns (uint256 requestId) {
        requestId = mvrfCoordinator.requestRandomWords(
            gasLane,
            subscriptionId,
            REQUEST_CONFIRMATIONS,
            callbackGasLimit,
            NUM_WORDS
        );
        vrf_requests[requestId] = RequestStatusMerge(
            {
                randomWords: new uint256[](0),
                prize : 0, reciever: _receiver
            });
        emit RequestSent(requestId, NUM_WORDS);
        return requestId;
    }

    function fulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords) internal override {
        vrf_requests[_requestId].randomWords = _randomWords;

        uint moddedRng = _randomWords[0] % MAX_CHANCE_VALUE;

        uint256[2] memory chanceArracy = getChanceArray();

        if (moddedRng > chanceArracy[0]) {
            // withdraw from tax treasury to the reciever. !!!
            address payable to = payable(vrf_requests[_requestId].reciever);
            to.transfer(_calculatePortionToDistribute());
            emit mergePrizeStatus(true);
        }
        emit RequestFulfilled(_requestId, _randomWords);
    }


    function _compareTrait(uint256 _1st, uint256 _2nd, uint256 _3rd, uint8 _index) internal returns (uint8[2] memory) {
        if (IAlligators(alligatorsAddress).alligator_level(_1st)[_index] >= IAlligators(alligatorsAddress).alligator_level(_2nd)[_index]) {
            if (IAlligators(alligatorsAddress).alligator_level(_1st)[_index] >= IAlligators(alligatorsAddress).alligator_level(_3rd)[_index]) {
                // first value is Type index, second one is Level Index
                uint8[2] memory value_ = [IAlligators(alligatorsAddress).anatomy(_1st)[_index], IAlligators(alligatorsAddress).alligator_level(_1st)[_index]];
                return value_;
            } else {
                uint8[2] memory value_ = [IAlligators(alligatorsAddress).anatomy(_3rd)[_index], IAlligators(alligatorsAddress).alligator_level(_3rd)[_index]];
                return value_;
            }
        } else {
            if (IAlligators(alligatorsAddress).alligator_level(_2nd)[_index] >= IAlligators(alligatorsAddress).alligator_level(_3rd)[_index]) {
                uint8[2] memory value_ = [IAlligators(alligatorsAddress).anatomy(_2nd)[_index], IAlligators(alligatorsAddress).alligator_level(_2nd)[_index]];
                return value_;
            } else {
                uint8[2] memory value_ = [IAlligators(alligatorsAddress).anatomy(_3rd)[_index], IAlligators(alligatorsAddress).alligator_level(_3rd)[_index]];
                return value_;
            }
        }
    }

    function _getBalance() internal view returns (uint256) {
        address payable self = payable(address(this));
        uint256 balance = self.balance;
        return balance;
    }

    function _calculatePortionToDistribute() internal view returns (uint256) {
        return _getBalance() * _prizeBps / 10_000;
    }

    function _calculatePortionToRewardPool() internal view returns (uint256) {
        return _taxAmount * _prizePortionBps / 10_000;
    }

    function _canSetOwner() internal virtual view override returns (bool) {
        return msg.sender == owner();
    }

    function getChanceArray() public view returns (uint256[2] memory) {
        return [MIN_CHANCE_VALUE, MAX_CHANCE_VALUE];
    }

    function setChanceArray(uint256 _min) external onlyOwner {
        require(_min < MAX_CHANCE_VALUE, "invalid");
        MIN_CHANCE_VALUE = _min;
    }

    function setTaxAmount(uint256 taxAmount) external onlyOwner {
        _taxAmount = taxAmount;
    }

    function setRewardPoolPortion(uint256 percentage) external onlyOwner {
        _prizePortionBps = percentage;
    }

    function setPrizePortion(uint256 percentage) external onlyOwner {
        _prizeBps = percentage;
    }

    function setTreasuryAddress(address payable _taxTreasuryAddress) external onlyOwner {
        taxTreasury = _taxTreasuryAddress;
    }
    
    function rescueFunds(uint256 _amount, address payable _rescueTo) external onlyOwner {
        _rescueTo.transfer(_amount);
        }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./interfaces/IERC721.sol";
import "./interfaces/IERC721Metadata.sol";

/**
 * @dev Interface of an ERC721A compliant contract.
 */
interface IAlligators is IERC721, IERC721Metadata {

    function tokenType(
        uint256 _tokenId
    ) external view returns (uint8 _type);

    function joker_level(
        uint256 _tokenId
    ) external view returns (uint8 _level);

    function anatomy(
        uint256 _tokenId
    ) external view returns (uint8[7] memory _traits);

    function alligator_level(
        uint256 _tokenId
    ) external view returns (uint8[7] memory _traits);

    function currentMergeId() external view returns (uint256);

    function merge(uint256 _1st, uint256 _2nd, uint256 _3rd, address _owner) external;
    function createSkeleton(uint8 _trait1, uint8 _trait2, uint8 _trait3, uint8 _trait4, uint8 _trait5, uint8 _trait6, uint8 _trait7) external;
    function createLevels(uint8 _trait1, uint8 _trait2, uint8 _trait3, uint8 _trait4, uint8 _trait5, uint8 _trait6, uint8 _trait7) external;

    enum Level {
        L0,
        L1,
        L2,
        L3,
        L4,
        L5
    }

    enum Trait1 {
        X1,
        Y1,
        Z1
    }

    enum Trait2 {
        X2,
        Y2,
        Z2
    }

    enum Trait3 {
        X3,
        Y3,
        Z3
    }

    enum Trait4 {
        X4,
        Y4,
        Z4
    }

    enum Trait5 {
        X5,
        Y5,
        Z5
    }

    enum Trait6 {
        X6,
        Y6,
        Z6
    }

    enum Trait7 {
        X7,
        Y7,
        Z7
    }

    enum SaleStatus {
        PAUSED,
        PRESALE,
        PUBLIC,
        JOKER_SUPPLIED,
        COMMON_SUPPLIED,
        ALL_SUPPLIED
    }

   struct NFT_Anatomy {
        Trait1 trait1;
        Trait2 trait2;
        Trait3 trait3;
        Trait4 trait4;
        Trait5 trait5;
        Trait6 trait6;
        Trait7 trait7;
    }

    struct NFT_LEVEL {
        Level trait1Lvl;
        Level trait2Lvl;
        Level trait3Lvl;
        Level trait4Lvl;
        Level trait5Lvl;
        Level trait6Lvl;
        Level trait7Lvl;
    }

    struct RequestStatus {
        uint256[] randomWords;
        // 0 for off || 1 for on
        uint jokerMint;
        // 0 for off || 1 for on
        uint jokerMintPrize;
        address sender;
        uint256 quantity;
    }

    /**
     * The caller must own the token or be an approved operator.
     */
    error ApprovalCallerNotOwnerNorApproved();

    /**
     * The token does not exist.
     */
    error ApprovalQueryForNonexistentToken();

    /**
     * The caller cannot approve to their own address.
     */
    error ApproveToCaller();

    /**
     * The caller cannot approve to the current owner.
     */
    error ApprovalToCurrentOwner();

    /**
     * Cannot query the balance for the zero address.
     */
    error BalanceQueryForZeroAddress();

    /**
     * Cannot mint to the zero address.
     */
    error MintToZeroAddress();

    /**
     * The quantity of tokens minted must be more than zero.
     */
    error MintZeroQuantity();

    /**
     * The token does not exist.
     */
    error OwnerQueryForNonexistentToken();

    /**
     * The caller must own the token or be an approved operator.
     */
    error TransferCallerNotOwnerNorApproved();

    /**
     * The token must be owned by `from`.
     */
    error TransferFromIncorrectOwner();

    /**
     * Cannot safely transfer to a contract that does not implement the ERC721Receiver interface.
     */
    error TransferToNonERC721ReceiverImplementer();

    /**
     * Cannot transfer to the zero address.
     */
    error TransferToZeroAddress();

    /**
     * The token does not exist.
     */
    error URIQueryForNonexistentToken();

    // Compiler will pack this into a single 256bit word.
    struct TokenOwnership {
        // The address of the owner.
        address addr;
        // Keeps track of the start time of ownership with minimal overhead for tokenomics.
        uint64 startTimestamp;
        // Whether the token has been burned.
        bool burned;
    }

    // Compiler will pack this into a single 256bit word.
    struct AddressData {
        // Realistically, 2**64-1 is more than enough.
        uint64 balance;
        // Keeps track of mint count with minimal overhead for tokenomics.
        uint64 numberMinted;
        // Keeps track of burn count with minimal overhead for tokenomics.
        uint64 numberBurned;
        // For miscellaneous variable(s) pertaining to the address
        // (e.g. number of whitelist mint slots used).
        // If there are multiple variables, please pack them into a uint64.
        uint64 aux;
    }

    /**
     * @dev Returns the total amount of tokens stored by the contract.
     *
     * Burned tokens are calculated here, use `_totalMinted()` if you want to count just minted tokens.
     */
    function totalSupply() external view returns (uint256);

    //function merge(uint256 _1st, uint256 _2nd, uint256 _3rd, address _ownenr) external onlyMerger;
    
    event NftRequested(uint256 indexed requestId, address requester);
    event NftFullfilled(uint256 indexed requestId, address requester, uint256[] randomWords,  bool jokerMint,bool jokerMintPrize, uint256 quantity);
    event RequestSent(uint256 requestId, uint32 numWords);
    event RequestFulfilled(uint256 requestId, uint256[] randomWords);
    event Verified(address indexed user);
    event mergeIsSet(address mergeHub);
    event chanceIsSet(uint256 value);
    event mintLimitIsSet(uint value);
    event WLAddrIsSet(address[] _whitelisted);
    error InvalidSigner();
    error RangeOutOfBounds();
    error callErr();
    error Mergefailed();
    error invalidSigner();
}

pragma solidity ^0.8.4;

interface IMergeGators {

    struct RequestStatusMerge {
        uint256[] randomWords;
        uint prize;
        address reciever;
    }

    enum lvlUp {
        TRUE,
        FALSE
    }

   
    enum Level {
        L1,
        L2,
        L3,
        L4,
        L5
    }

    enum Trait1 {
        X1,
        Y1,
        Z1
    }

    enum Trait2 {
        X2,
        Y2,
        Z2
    }

    enum Trait3 {
        X3,
        Y3,
        Z3
    }

    enum Trait4 {
        X4,
        Y4,
        Z4
    }

    enum Trait5 {
        X5,
        Y5,
        Z5
    }

    enum Trait6 {
        X6,
        Y6,
        Z6
    }

    enum Trait7 {
        X7,
        Y7,
        Z7
    }


   struct NFT_Anatomy {
        Trait1 trait1;
        Trait2 trait2;
        Trait3 trait3;
        Trait4 trait4;
        Trait5 trait5;
        Trait6 trait6;
        Trait7 trait7;
    }

    struct NFT_Level {
        Level trait1Lvl;
        Level trait2Lvl;
        Level trait3Lvl;
        Level trait4Lvl;
        Level trait5Lvl;
        Level trait6Lvl;
        Level trait7Lvl;
    }

    event RequestSent(uint256 requestId, uint32 numWords);
    event RequestFulfilled(uint256 requestId, uint256[] randomWords);
    event chanceIsSet(uint256 value);
    error InvalidSigner();
    error RangeOutOfBounds();
    error callErr();
    error Mergefailed();
    error invalidSigner();
    event mergeRequested(uint256 _1st, uint256 _2nd, uint256 _3rd, address _owner);
    event mergeFulfilled(uint256 mergeId);
    event mergePrizeStatus(bool success);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/** ****************************************************************************
 * @notice Interface for contracts using VRF randomness
 * *****************************************************************************
 * @dev PURPOSE
 *
 * @dev Reggie the Random Oracle (not his real job) wants to provide randomness
 * @dev to Vera the verifier in such a way that Vera can be sure he's not
 * @dev making his output up to suit himself. Reggie provides Vera a public key
 * @dev to which he knows the secret key. Each time Vera provides a seed to
 * @dev Reggie, he gives back a value which is computed completely
 * @dev deterministically from the seed and the secret key.
 *
 * @dev Reggie provides a proof by which Vera can verify that the output was
 * @dev correctly computed once Reggie tells it to her, but without that proof,
 * @dev the output is indistinguishable to her from a uniform random sample
 * @dev from the output space.
 *
 * @dev The purpose of this contract is to make it easy for unrelated contracts
 * @dev to talk to Vera the verifier about the work Reggie is doing, to provide
 * @dev simple access to a verifiable source of randomness. It ensures 2 things:
 * @dev 1. The fulfillment came from the VRFCoordinator
 * @dev 2. The consumer contract implements fulfillRandomWords.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFConsumerBase, and can
 * @dev initialize VRFConsumerBase's attributes in their constructor as
 * @dev shown:
 *
 * @dev   contract VRFConsumer {
 * @dev     constructor(<other arguments>, address _vrfCoordinator, address _link)
 * @dev       VRFConsumerBase(_vrfCoordinator) public {
 * @dev         <initialization with other arguments goes here>
 * @dev       }
 * @dev   }
 *
 * @dev The oracle will have given you an ID for the VRF keypair they have
 * @dev committed to (let's call it keyHash). Create subscription, fund it
 * @dev and your consumer contract as a consumer of it (see VRFCoordinatorInterface
 * @dev subscription management functions).
 * @dev Call requestRandomWords(keyHash, subId, minimumRequestConfirmations,
 * @dev callbackGasLimit, numWords),
 * @dev see (VRFCoordinatorInterface for a description of the arguments).
 *
 * @dev Once the VRFCoordinator has received and validated the oracle's response
 * @dev to your request, it will call your contract's fulfillRandomWords method.
 *
 * @dev The randomness argument to fulfillRandomWords is a set of random words
 * @dev generated from your requestId and the blockHash of the request.
 *
 * @dev If your contract could have concurrent requests open, you can use the
 * @dev requestId returned from requestRandomWords to track which response is associated
 * @dev with which randomness request.
 * @dev See "SECURITY CONSIDERATIONS" for principles to keep in mind,
 * @dev if your contract could have multiple requests in flight simultaneously.
 *
 * @dev Colliding `requestId`s are cryptographically impossible as long as seeds
 * @dev differ.
 *
 * *****************************************************************************
 * @dev SECURITY CONSIDERATIONS
 *
 * @dev A method with the ability to call your fulfillRandomness method directly
 * @dev could spoof a VRF response with any random value, so it's critical that
 * @dev it cannot be directly called by anything other than this base contract
 * @dev (specifically, by the VRFConsumerBase.rawFulfillRandomness method).
 *
 * @dev For your users to trust that your contract's random behavior is free
 * @dev from malicious interference, it's best if you can write it so that all
 * @dev behaviors implied by a VRF response are executed *during* your
 * @dev fulfillRandomness method. If your contract must store the response (or
 * @dev anything derived from it) and use it later, you must ensure that any
 * @dev user-significant behavior which depends on that stored value cannot be
 * @dev manipulated by a subsequent VRF request.
 *
 * @dev Similarly, both miners and the VRF oracle itself have some influence
 * @dev over the order in which VRF responses appear on the blockchain, so if
 * @dev your contract could have multiple VRF requests in flight simultaneously,
 * @dev you must ensure that the order in which the VRF responses arrive cannot
 * @dev be used to manipulate your contract's user-significant behavior.
 *
 * @dev Since the block hash of the block which contains the requestRandomness
 * @dev call is mixed into the input to the VRF *last*, a sufficiently powerful
 * @dev miner could, in principle, fork the blockchain to evict the block
 * @dev containing the request, forcing the request to be included in a
 * @dev different block with a different hash, and therefore a different input
 * @dev to the VRF. However, such an attack would incur a substantial economic
 * @dev cost. This cost scales with the number of blocks the VRF oracle waits
 * @dev until it calls responds to a request. It is for this reason that
 * @dev that you can signal to an oracle you'd like them to wait longer before
 * @dev responding to the request (however this is not enforced in the contract
 * @dev and so remains effective only in the case of unmodified oracle software).
 */
abstract contract VRFConsumerBaseV2 {
  error OnlyCoordinatorCanFulfill(address have, address want);
  address private immutable vrfCoordinator;

  /**
   * @param _vrfCoordinator address of VRFCoordinator contract
   */
  constructor(address _vrfCoordinator) {
    vrfCoordinator = _vrfCoordinator;
  }

  /**
   * @notice fulfillRandomness handles the VRF response. Your contract must
   * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
   * @notice principles to keep in mind when implementing your fulfillRandomness
   * @notice method.
   *
   * @dev VRFConsumerBaseV2 expects its subcontracts to have a method with this
   * @dev signature, and will call it once it has verified the proof
   * @dev associated with the randomness. (It is triggered via a call to
   * @dev rawFulfillRandomness, below.)
   *
   * @param requestId The Id initially returned by requestRandomness
   * @param randomWords the VRF output expanded to the requested number of words
   */
  function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal virtual;

  // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
  // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
  // the origin of the call
  function rawFulfillRandomWords(uint256 requestId, uint256[] memory randomWords) external {
    if (msg.sender != vrfCoordinator) {
      revert OnlyCoordinatorCanFulfill(msg.sender, vrfCoordinator);
    }
    fulfillRandomWords(requestId, randomWords);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface VRFCoordinatorV2Interface {
  /**
   * @notice Get configuration relevant for making requests
   * @return minimumRequestConfirmations global min for request confirmations
   * @return maxGasLimit global max for request gas limit
   * @return s_provingKeyHashes list of registered key hashes
   */
  function getRequestConfig()
    external
    view
    returns (
      uint16,
      uint32,
      bytes32[] memory
    );

  /**
   * @notice Request a set of random words.
   * @param keyHash - Corresponds to a particular oracle job which uses
   * that key for generating the VRF proof. Different keyHash's have different gas price
   * ceilings, so you can select a specific one to bound your maximum per request cost.
   * @param subId  - The ID of the VRF subscription. Must be funded
   * with the minimum subscription balance required for the selected keyHash.
   * @param minimumRequestConfirmations - How many blocks you'd like the
   * oracle to wait before responding to the request. See SECURITY CONSIDERATIONS
   * for why you may want to request more. The acceptable range is
   * [minimumRequestBlockConfirmations, 200].
   * @param callbackGasLimit - How much gas you'd like to receive in your
   * fulfillRandomWords callback. Note that gasleft() inside fulfillRandomWords
   * may be slightly less than this amount because of gas used calling the function
   * (argument decoding etc.), so you may need to request slightly more than you expect
   * to have inside fulfillRandomWords. The acceptable range is
   * [0, maxGasLimit]
   * @param numWords - The number of uint256 random values you'd like to receive
   * in your fulfillRandomWords callback. Note these numbers are expanded in a
   * secure way by the VRFCoordinator from a single random value supplied by the oracle.
   * @return requestId - A unique identifier of the request. Can be used to match
   * a request to a response in fulfillRandomWords.
   */
  function requestRandomWords(
    bytes32 keyHash,
    uint64 subId,
    uint16 minimumRequestConfirmations,
    uint32 callbackGasLimit,
    uint32 numWords
  ) external returns (uint256 requestId);

  /**
   * @notice Create a VRF subscription.
   * @return subId - A unique subscription id.
   * @dev You can manage the consumer set dynamically with addConsumer/removeConsumer.
   * @dev Note to fund the subscription, use transferAndCall. For example
   * @dev  LINKTOKEN.transferAndCall(
   * @dev    address(COORDINATOR),
   * @dev    amount,
   * @dev    abi.encode(subId));
   */
  function createSubscription() external returns (uint64 subId);

  /**
   * @notice Get a VRF subscription.
   * @param subId - ID of the subscription
   * @return balance - LINK balance of the subscription in juels.
   * @return reqCount - number of requests for this subscription, determines fee tier.
   * @return owner - owner of the subscription.
   * @return consumers - list of consumer address which are able to use this subscription.
   */
  function getSubscription(uint64 subId)
    external
    view
    returns (
      uint96 balance,
      uint64 reqCount,
      address owner,
      address[] memory consumers
    );

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @param newOwner - proposed new owner of the subscription
   */
  function requestSubscriptionOwnerTransfer(uint64 subId, address newOwner) external;

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @dev will revert if original owner of subId has
   * not requested that msg.sender become the new owner.
   */
  function acceptSubscriptionOwnerTransfer(uint64 subId) external;

  /**
   * @notice Add a consumer to a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - New consumer which can use the subscription
   */
  function addConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Remove a consumer from a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - Consumer to remove from the subscription
   */
  function removeConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Cancel a subscription
   * @param subId - ID of the subscription
   * @param to - Where to send the remaining LINK to
   */
  function cancelSubscription(uint64 subId, address to) external;

  /*
   * @notice Check to see if there exists a request commitment consumers
   * for all consumers and keyhashes for a given sub.
   * @param subId - ID of the subscription
   * @return true if there exists at least one unfulfilled request for the subscription, false
   * otherwise.
   */
  function pendingRequestExists(uint64 subId) external view returns (bool);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.4;

import "../interfaces/IOwnable.sol";

abstract contract Ownable is IOwnable {
    /// @dev Owner of the contract (purpose: OpenSea compatibility)
    address private _owner;

    /// @dev Reverts if caller is not the owner.
    modifier onlyOwner() {
        if (msg.sender != _owner) {
            revert("Not authorized");
        }
        _;
    }

    /**
     *  @notice Returns the owner of the contract.
     */
    function owner() public view override returns (address) {
        return _owner;
    }

    /**
     *  @notice Lets an authorized wallet set a new owner for the contract.
     *  @param _newOwner The address to set as the new owner of the contract.
     */
    function setOwner(address _newOwner) external override {
        if (!_canSetOwner()) {
            revert("Not authorized");
        }
        _setupOwner(_newOwner);
    }

    /// @dev Lets a contract admin set a new owner for the contract. The new owner must be a contract admin.
    function _setupOwner(address _newOwner) internal {
        address _prevOwner = _owner;
        _owner = _newOwner;

        emit OwnerUpdated(_prevOwner, _newOwner);
    }

    /// @dev Returns whether owner can be set in the given execution context.
    function _canSetOwner() internal view virtual returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.4;

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.4;

/// @title ERC-721 Non-Fungible Token Standard, optional metadata extension
/// @dev See https://eips.ethereum.org/EIPS/eip-721
///  Note: the ERC-165 identifier for this interface is 0x5b5e139f.
/* is ERC721 */
interface IERC721Metadata {
    /// @notice A descriptive name for a collection of NFTs in this contract
    function name() external view returns (string memory);

    /// @notice An abbreviated name for NFTs in this contract
    function symbol() external view returns (string memory);

    /// @notice A distinct Uniform Resource Identifier (URI) for a given asset.
    /// @dev Throws if `_tokenId` is not a valid NFT. URIs are defined in RFC
    ///  3986. The URI may point to a JSON file that conforms to the "ERC721
    ///  Metadata JSON Schema".
    function tokenURI(uint256 _tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.4;

interface IOwnable {
    /// @dev Returns the owner of the contract.
    function owner() external view returns (address);

    /// @dev Lets a module admin set a new owner for the contract. The new owner must be a module admin.
    function setOwner(address _newOwner) external;

    /// @dev Emitted when a new Owner is set.
    event OwnerUpdated(address indexed prevOwner, address indexed newOwner);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

contract MultiSigWallet {
    event Deposit(address indexed sender, uint256 indexed value, uint256 balance);
    event SubmittedTx(address indexed to, uint256 indexed value, bytes indexed data);
    event ApprovedTx(uint256 indexed txId, address indexed approver);
    event RevokeApproval(address indexed owner, uint indexed txId);
    event TxExecuted(address indexed to, uint256 indexed value, bytes indexed data, address executor);

    mapping(address => bool) private isOwner;

    struct Transaction {
        uint256 id;
        address to;
        uint256 value;
        bytes data;
        uint256 confirmations;
        bool executed;
    }

    mapping(uint256 => Transaction) private transactions;
    mapping(uint256 => mapping(address => bool)) private approved;

    uint256 public required;
    uint256 public txId;

    modifier onlyOwner() {
        if (!isOwner[msg.sender]) {
            revert NotOwner();
        }
        _;
    }

    modifier txExists(uint256 _txId) {
        if (_txId > txId - 1) {
            revert TxDoesNotExist();
        }
        _;
    }

    modifier notExecuted(uint256 _txId) {
        if (transactions[_txId].executed) {
            revert TxAlreadyExecuted();
        }
        _;
    }

    modifier notApproved(uint256 _txId) {
        if (approved[_txId][msg.sender]) {
            revert TxAlreadyApproved();
        }
        _;
    }

    error InvalidNumRequired();
    error InvalidOwnerAddress();
    error AlreadyOwner();
    error NotOwner();
    error TxDoesNotExist();
    error TxAlreadyExecuted();
    error TxAlreadyApproved();
    error TxNotApproved();
    error LessConfirmationsThanRequired();
    error TxExecutionFailed();

    constructor(address[] memory _owners, uint256 _required) {
        if (_required > _owners.length) {
            revert InvalidNumRequired();
        }
        for (uint256 i = 0; i < _owners.length; i++) {
            address owner = _owners[i];

            if (owner == address(0)) {
                revert InvalidOwnerAddress();
            }
            if (isOwner[owner]) {
                revert AlreadyOwner();
            }
            isOwner[owner] = true;
        }
        required = _required;
    }

    receive() external payable {
        emit Deposit(msg.sender, msg.value, address(this).balance);
    }

    function submitTx(
        address _to,
        uint256 _value,
        bytes memory _data
    ) external onlyOwner {
        Transaction storage transaction = transactions[txId];
        transaction.id = txId;
        transaction.to = _to;
        transaction.value = _value;
        transaction.data = _data;
        txId++;
        emit SubmittedTx(_to, _value, _data);
    }

    function approveTx(uint256 _txId)
        external
        onlyOwner
        txExists(_txId)
        notApproved(_txId)
        notExecuted(_txId)
    {
        transactions[_txId].confirmations++;
        approved[_txId][msg.sender] = true;
        emit ApprovedTx(_txId, msg.sender);
    }

    function executeTx(uint256 _txId)
        external
        onlyOwner
        txExists(_txId)
        notExecuted(_txId)
    {
        Transaction storage transaction = transactions[_txId];
        if (transaction.confirmations < required) {
            revert LessConfirmationsThanRequired();
        }
        transaction.executed = true;
        (bool success, ) = payable(transaction.to).call{
            value: transaction.value
        }(transaction.data);
        if (!success) {
            revert TxExecutionFailed();
        }
        emit TxExecuted(
            transaction.to,
            transaction.value,
            transaction.data,
            msg.sender
        );
    }

    function revokeApproval(uint256 _txId)
        external
        onlyOwner
        txExists(_txId)
        notExecuted(_txId)
    {
        if (approved[_txId][msg.sender]) {
            transactions[_txId].confirmations--;
            approved[_txId][msg.sender] = false;
        } else {
            revert TxNotApproved();
        }
        emit RevokeApproval(msg.sender, _txId);
    }

    function getTransaction(uint256 _txId) external view txExists(_txId) returns (Transaction memory) {
        return transactions[_txId];
    }

    function checkOwner(address _owner) external view returns (bool) {
        return isOwner[_owner];
    }

    function checkApproved(uint256 _txId, address _approver) external view returns (bool) {
        return approved[_txId][_approver];
    }
}

pragma solidity ^0.8.4;

import "../../src/AlligatorMerge.sol";

contract AlligatorMergeMock is AlligatorMerge {
    address constant owner_ = 0xC5Fcd6be4a3b187Cb9B3Bbd9aAD047767DAEF344;
    uint256 constant taxPay_ = 0.03 ether;
    uint256 constant rewardPoolBPS = 10; 
    uint256 constant rewardPoolDistro = 1; 
    //11
    address constant collection = 0x247F9FE715B8DF2a22f9641a31699FE4A9434BeB;
    address payable constant taxTreasuryAddr = payable(0x010596BD92e86410e5688CCc98492B26798976aF);

    constructor(
        uint64 subscriptionId,
        address vrfCoordinatorV2,
        bytes32 gasLane
        )
        AlligatorMerge(
                owner_,
                collection,
                taxTreasuryAddr,
                taxPay_,
                subscriptionId,
                vrfCoordinatorV2,
                gasLane,
                rewardPoolDistro,
                rewardPoolBPS)
    {}
}