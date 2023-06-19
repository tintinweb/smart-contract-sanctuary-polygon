// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/LinkTokenInterface.sol";

import "./VRFRequestIDBase.sol";

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
 * @dev simple access to a verifiable source of randomness.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFConsumerBase, and can
 * @dev initialize VRFConsumerBase's attributes in their constructor as
 * @dev shown:
 *
 * @dev   contract VRFConsumer {
 * @dev     constuctor(<other arguments>, address _vrfCoordinator, address _link)
 * @dev       VRFConsumerBase(_vrfCoordinator, _link) public {
 * @dev         <initialization with other arguments goes here>
 * @dev       }
 * @dev   }
 *
 * @dev The oracle will have given you an ID for the VRF keypair they have
 * @dev committed to (let's call it keyHash), and have told you the minimum LINK
 * @dev price for VRF service. Make sure your contract has sufficient LINK, and
 * @dev call requestRandomness(keyHash, fee, seed), where seed is the input you
 * @dev want to generate randomness from.
 *
 * @dev Once the VRFCoordinator has received and validated the oracle's response
 * @dev to your request, it will call your contract's fulfillRandomness method.
 *
 * @dev The randomness argument to fulfillRandomness is the actual random value
 * @dev generated from your seed.
 *
 * @dev The requestId argument is generated from the keyHash and the seed by
 * @dev makeRequestId(keyHash, seed). If your contract could have concurrent
 * @dev requests open, you can use the requestId to track which seed is
 * @dev associated with which randomness. See VRFRequestIDBase.sol for more
 * @dev details. (See "SECURITY CONSIDERATIONS" for principles to keep in mind,
 * @dev if your contract could have multiple requests in flight simultaneously.)
 *
 * @dev Colliding `requestId`s are cryptographically impossible as long as seeds
 * @dev differ. (Which is critical to making unpredictable randomness! See the
 * @dev next section.)
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
 * @dev Since the ultimate input to the VRF is mixed with the block hash of the
 * @dev block in which the request is made, user-provided seeds have no impact
 * @dev on its economic security properties. They are only included for API
 * @dev compatability with previous versions of this contract.
 *
 * @dev Since the block hash of the block which contains the requestRandomness
 * @dev call is mixed into the input to the VRF *last*, a sufficiently powerful
 * @dev miner could, in principle, fork the blockchain to evict the block
 * @dev containing the request, forcing the request to be included in a
 * @dev different block with a different hash, and therefore a different input
 * @dev to the VRF. However, such an attack would incur a substantial economic
 * @dev cost. This cost scales with the number of blocks the VRF oracle waits
 * @dev until it calls responds to a request.
 */
abstract contract VRFConsumerBase is VRFRequestIDBase {

  /**
   * @notice fulfillRandomness handles the VRF response. Your contract must
   * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
   * @notice principles to keep in mind when implementing your fulfillRandomness
   * @notice method.
   *
   * @dev VRFConsumerBase expects its subcontracts to have a method with this
   * @dev signature, and will call it once it has verified the proof
   * @dev associated with the randomness. (It is triggered via a call to
   * @dev rawFulfillRandomness, below.)
   *
   * @param requestId The Id initially returned by requestRandomness
   * @param randomness the VRF output
   */
  function fulfillRandomness(
    bytes32 requestId,
    uint256 randomness
  )
    internal
    virtual;

  /**
   * @dev In order to keep backwards compatibility we have kept the user
   * seed field around. We remove the use of it because given that the blockhash
   * enters later, it overrides whatever randomness the used seed provides.
   * Given that it adds no security, and can easily lead to misunderstandings,
   * we have removed it from usage and can now provide a simpler API.
   */
  uint256 constant private USER_SEED_PLACEHOLDER = 0;

  /**
   * @notice requestRandomness initiates a request for VRF output given _seed
   *
   * @dev The fulfillRandomness method receives the output, once it's provided
   * @dev by the Oracle, and verified by the vrfCoordinator.
   *
   * @dev The _keyHash must already be registered with the VRFCoordinator, and
   * @dev the _fee must exceed the fee specified during registration of the
   * @dev _keyHash.
   *
   * @dev The _seed parameter is vestigial, and is kept only for API
   * @dev compatibility with older versions. It can't *hurt* to mix in some of
   * @dev your own randomness, here, but it's not necessary because the VRF
   * @dev oracle will mix the hash of the block containing your request into the
   * @dev VRF seed it ultimately uses.
   *
   * @param _keyHash ID of public key against which randomness is generated
   * @param _fee The amount of LINK to send with the request
   *
   * @return requestId unique ID for this request
   *
   * @dev The returned requestId can be used to distinguish responses to
   * @dev concurrent requests. It is passed as the first argument to
   * @dev fulfillRandomness.
   */
  function requestRandomness(
    bytes32 _keyHash,
    uint256 _fee
  )
    internal
    returns (
      bytes32 requestId
    )
  {
    LINK.transferAndCall(vrfCoordinator, _fee, abi.encode(_keyHash, USER_SEED_PLACEHOLDER));
    // This is the seed passed to VRFCoordinator. The oracle will mix this with
    // the hash of the block containing this request to obtain the seed/input
    // which is finally passed to the VRF cryptographic machinery.
    uint256 vRFSeed  = makeVRFInputSeed(_keyHash, USER_SEED_PLACEHOLDER, address(this), nonces[_keyHash]);
    // nonces[_keyHash] must stay in sync with
    // VRFCoordinator.nonces[_keyHash][this], which was incremented by the above
    // successful LINK.transferAndCall (in VRFCoordinator.randomnessRequest).
    // This provides protection against the user repeating their input seed,
    // which would result in a predictable/duplicate output, if multiple such
    // requests appeared in the same block.
    nonces[_keyHash] = nonces[_keyHash] + 1;
    return makeRequestId(_keyHash, vRFSeed);
  }

  LinkTokenInterface immutable internal LINK;
  address immutable private vrfCoordinator;

  // Nonces for each VRF key from which randomness has been requested.
  //
  // Must stay in sync with VRFCoordinator[_keyHash][this]
  mapping(bytes32 /* keyHash */ => uint256 /* nonce */) private nonces;

  /**
   * @param _vrfCoordinator address of VRFCoordinator contract
   * @param _link address of LINK token contract
   *
   * @dev https://docs.chain.link/docs/link-token-contracts
   */
  constructor(
    address _vrfCoordinator,
    address _link
  ) {
    vrfCoordinator = _vrfCoordinator;
    LINK = LinkTokenInterface(_link);
  }

  // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
  // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
  // the origin of the call
  function rawFulfillRandomness(
    bytes32 requestId,
    uint256 randomness
  )
    external
  {
    require(msg.sender == vrfCoordinator, "Only VRFCoordinator can fulfill");
    fulfillRandomness(requestId, randomness);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract VRFRequestIDBase {

  /**
   * @notice returns the seed which is actually input to the VRF coordinator
   *
   * @dev To prevent repetition of VRF output due to repetition of the
   * @dev user-supplied seed, that seed is combined in a hash with the
   * @dev user-specific nonce, and the address of the consuming contract. The
   * @dev risk of repetition is mostly mitigated by inclusion of a blockhash in
   * @dev the final seed, but the nonce does protect against repetition in
   * @dev requests which are included in a single block.
   *
   * @param _userSeed VRF seed input provided by user
   * @param _requester Address of the requesting contract
   * @param _nonce User-specific nonce at the time of the request
   */
  function makeVRFInputSeed(
    bytes32 _keyHash,
    uint256 _userSeed,
    address _requester,
    uint256 _nonce
  )
    internal
    pure
    returns (
      uint256
    )
  {
    return uint256(keccak256(abi.encode(_keyHash, _userSeed, _requester, _nonce)));
  }

  /**
   * @notice Returns the id for this request
   * @param _keyHash The serviceAgreement ID to be used for this request
   * @param _vRFInputSeed The seed to be passed directly to the VRF
   * @return The id for this request
   *
   * @dev Note that _vRFInputSeed is not the seed passed by the consuming
   * @dev contract, but the one generated by makeVRFInputSeed
   */
  function makeRequestId(
    bytes32 _keyHash,
    uint256 _vRFInputSeed
  )
    internal
    pure
    returns (
      bytes32
    )
  {
    return keccak256(abi.encodePacked(_keyHash, _vRFInputSeed));
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface LinkTokenInterface {

  function allowance(
    address owner,
    address spender
  )
    external
    view
    returns (
      uint256 remaining
    );

  function approve(
    address spender,
    uint256 value
  )
    external
    returns (
      bool success
    );

  function balanceOf(
    address owner
  )
    external
    view
    returns (
      uint256 balance
    );

  function decimals()
    external
    view
    returns (
      uint8 decimalPlaces
    );

  function decreaseApproval(
    address spender,
    uint256 addedValue
  )
    external
    returns (
      bool success
    );

  function increaseApproval(
    address spender,
    uint256 subtractedValue
  ) external;

  function name()
    external
    view
    returns (
      string memory tokenName
    );

  function symbol()
    external
    view
    returns (
      string memory tokenSymbol
    );

  function totalSupply()
    external
    view
    returns (
      uint256 totalTokensIssued
    );

  function transfer(
    address to,
    uint256 value
  )
    external
    returns (
      bool success
    );

  function transferAndCall(
    address to,
    uint256 value,
    bytes calldata data
  )
    external
    returns (
      bool success
    );

  function transferFrom(
    address from,
    address to,
    uint256 value
  )
    external
    returns (
      bool success
    );

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
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
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

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
    function getApproved(uint256 tokenId) external view returns (address operator);

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

//SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

// ============ Imports ============

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@chainlink/contracts/src/v0.8/dev/VRFConsumerBase.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

contract Waffle is VRFConsumerBase, IERC721Receiver {
  // ============ Immutable storage ============

  // Chainlink keyHash
  bytes32 internal immutable keyHash;
  // Chainlink fee
  uint256 internal immutable fee;
  // NFT owner
  address public immutable owner;
  // Price (in Ether) per raffle slot
  uint256 public immutable slotPrice;
  // Number of total available raffle slots
  uint256 public immutable numSlotsAvailable;
  // Address of NFT contract
  address public immutable nftContract;
  // NFT ID
  uint256 public immutable nftID;

  // ============ Mutable storage ============

  // Result from Chainlink VRF
  uint256 public randomResult = 0;
  // Toggled when contract requests result from Chainlink VRF
  bool public randomResultRequested = false;
  // Number of filled raffle slots
  uint256 public numSlotsFilled = 0;
  // Array of slot owners
  address[] public slotOwners;
  // Mapping of slot owners to number of slots owned
  mapping(address => uint256) public addressToSlotsOwned;
  // Toggled when contract holds NFT to raffle
  bool public nftOwned = false;

  // ============ Events ============

  // Address of slot claimee and number of slots claimed
  event SlotsClaimed(address indexed claimee, uint256 numClaimed);
  // Address of slot refunder and number of slots refunded
  event SlotsRefunded(address indexed refunder, uint256 numRefunded);
  // Address of raffle winner
  event RaffleWon(address indexed winner);

  // ============ Constructor ============

  constructor(
    address _owner,
    address _nftContract,
    address _ChainlinkVRFCoordinator,
    address _ChainlinkLINKToken,
    bytes32 _ChainlinkKeyHash,
    uint256 _ChainlinkFee,
    uint256 _nftID,
    uint256 _slotPrice, 
    uint256 _numSlotsAvailable
  ) VRFConsumerBase(
    _ChainlinkVRFCoordinator,
    _ChainlinkLINKToken
  ) {
    owner = _owner;
    keyHash = _ChainlinkKeyHash;
    fee = _ChainlinkFee;
    nftContract = _nftContract;
    nftID = _nftID;
    slotPrice = _slotPrice;
    numSlotsAvailable = _numSlotsAvailable;
  }

  // ============ Functions ============

  /**
   * Enables purchasing _numSlots slots in the raffle
   */
  function purchaseSlot(uint256 _numSlots) payable external {
    // Require purchasing at least 1 slot
    require(_numSlots > 0, "Waffle: Cannot purchase 0 slots.");
    // Require the raffle contract to own the NFT to raffle
    require(nftOwned == true, "Waffle: Contract does not own raffleable NFT.");
    // Require there to be available raffle slots
    require(numSlotsFilled < numSlotsAvailable, "Waffle: All raffle slots are filled.");
    // Prevent claiming after winner selection
    require(randomResultRequested == false, "Waffle: Cannot purchase slot after winner has been chosen.");
    // Require appropriate payment for number of slots to purchase
    require(msg.value == _numSlots * slotPrice, "Waffle: Insufficient ETH provided to purchase slots.");
    // Require number of slots to purchase to be <= number of available slots
    require(_numSlots <= numSlotsAvailable - numSlotsFilled, "Waffle: Requesting to purchase too many slots.");

    // For each _numSlots
    for (uint256 i = 0; i < _numSlots; i++) {
      // Add address to slot owners array
      slotOwners.push(msg.sender);
    }

    // Increment filled slots
    numSlotsFilled = numSlotsFilled + _numSlots;
    // Increment slots owned by address
    addressToSlotsOwned[msg.sender] = addressToSlotsOwned[msg.sender] + _numSlots;

    // Emit claim event
    emit SlotsClaimed(msg.sender, _numSlots);
  }

  /**
   * Deletes raffle slots and decrements filled slots
   * @dev gas optimization: could force one-tx-per-slot-deletion to prevent iteration
   */
  function refundSlot(uint256 _numSlots) external {
    // Require the raffle contract to own the NFT to raffle
    require(nftOwned == true, "Waffle: Contract does not own raffleable NFT.");
    // Prevent refunding after winner selection
    require(randomResultRequested == false, "Waffle: Cannot refund slot after winner has been chosen.");
    // Require number of slots owned by address to be >= _numSlots requested for refund
    require(addressToSlotsOwned[msg.sender] >= _numSlots, "Waffle: Address does not own number of requested slots.");

    // Delete slots
    uint256 idx = 0;
    uint256 numToDelete = _numSlots;
    // Loop through all entries while numToDelete still exist
    while (idx < slotOwners.length && numToDelete > 0) {
      // If address is not a match
      if (slotOwners[idx] != msg.sender) {
        // Only increment for non-matches. In case of match keep same to check against last idx item
        idx++;
      } else {
        // Swap and pop
        slotOwners[idx] = slotOwners[slotOwners.length - 1];
        slotOwners.pop();
        // Decrement num to delete
        numToDelete--;
      }
    }

    // Repay raffle participant
    payable(msg.sender).transfer(_numSlots * slotPrice);
    // Decrement filled slots
    numSlotsFilled = numSlotsFilled - _numSlots;
    // Decrement slots owned by address
    addressToSlotsOwned[msg.sender] = addressToSlotsOwned[msg.sender] - _numSlots;

    // Emit refund event
    emit SlotsRefunded(msg.sender, _numSlots);
  }

  /**
   * Collects randomness from Chainlink VRF to propose a winner.
   */
  function collectRandomWinner() external returns (bytes32 requestId) {
    // Require at least 1 raffle slot to be filled
    require(numSlotsFilled > 0, "Waffle: No slots are filled");
    // Require NFT to be owned by raffle contract
    require(nftOwned == true, "Waffle: Contract does not own raffleable NFT.");
    // Require caller to be raffle deployer
    require(msg.sender == owner, "Waffle: Only owner can call winner collection.");
    // Require this to be the first time that randomness is requested
    require(randomResultRequested == false, "Waffle: Cannot collect winner twice.");

    // Toggle randomness requested
    randomResultRequested = true;

    // Call for random number
    return requestRandomness(keyHash, fee);
  }

  /**
   * Collects random number from Chainlink VRF
   */
  function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
    // Store random number as randomResult
    randomResult = randomness;
  }

  /**
   * Disburses NFT to winner and raised raffle pool to owner
   */
  function disburseWinner() external {
    // Require that the contract holds the NFT
    require(nftOwned == true, "Waffle: Cannot disurbse NFT to winner without holding NFT.");
    // Require that a winner has been collected already
    require(randomResultRequested == true, "Waffle: Cannot disburse to winner without having collected one.");
    // Require that the random result is not 0
    require(randomResult != 0, "Waffle: Please wait for Chainlink VRF to update the winner first.");

    // Transfer raised raffle pool to owner
    payable(owner).transfer(address(this).balance);

    // Find winner of NFT
    address winner = slotOwners[randomResult % numSlotsFilled];

    // Transfer NFT to winner
    IERC721(nftContract).safeTransferFrom(address(this), winner, nftID);

    // Toggle nftOwned
    nftOwned = false;

    // Emit raffle winner
    emit RaffleWon(winner);
  }

  /**
   * Deletes raffle, assuming that contract owns NFT and a winner has not been selected
   */
  function deleteRaffle() external {
    // Require being owner to delete raffle
    require(msg.sender == owner, "Waffle: Only owner can delete raffle.");
    // Require that the contract holds the NFT
    require(nftOwned == true, "Waffle: Cannot cancel raffle without raffleable NFT.");
    // Require that a winner has not been collected already
    require(randomResultRequested == false, "Waffle: Cannot delete raffle after collecting winner.");

    // Transfer NFT to original owner
    IERC721(nftContract).safeTransferFrom(address(this), msg.sender, nftID);

    // Toggle nftOwned
    nftOwned = false;

    // For each slot owner
    for (uint256 i = numSlotsFilled - 1; i >= 0; i--) {
      // Refund slot owner
      payable(slotOwners[i]).transfer(slotPrice);
      // Pop address from slot owners array
      slotOwners.pop();
    }
  }

  /**
   * Receive NFT to raffle
   */
  function onERC721Received(
    address operator,
    address from, 
    uint256 tokenId,
    bytes calldata data
  ) external override returns (bytes4) {
    // Require NFT from correct contract
    require(from == nftContract, "Waffle: Raffle not initiated with this NFT contract.");
    // Require correct NFT ID
    require(tokenId == nftID, "Waffle: Raffle not initiated with this NFT ID.");

    // Toggle contract NFT ownership
    nftOwned = true;

    // Return required successful interface bytes
    return 0x150b7a02;
  }

  /**
   * Deposits the NFT to the contract for raffling
   */
  function depositNFT() external {
    // Transfer the NFT to the contract
    IERC721(nftContract).safeTransferFrom(msg.sender, address(this), nftID);

    // Toggle contract NFT ownership
    nftOwned = true;
  }
}