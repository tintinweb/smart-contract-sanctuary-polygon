/**
 *Submitted for verification at polygonscan.com on 2023-05-30
*/

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// File: @openzeppelin/contracts/token/ERC777/IERC777.sol


// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC777/IERC777.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC777Token standard as defined in the EIP.
 *
 * This contract uses the
 * https://eips.ethereum.org/EIPS/eip-1820[ERC1820 registry standard] to let
 * token holders and recipients react to token movements by using setting implementers
 * for the associated interfaces in said registry. See {IERC1820Registry} and
 * {ERC1820Implementer}.
 */
interface IERC777 {
    /**
     * @dev Emitted when `amount` tokens are created by `operator` and assigned to `to`.
     *
     * Note that some additional user `data` and `operatorData` can be logged in the event.
     */
    event Minted(address indexed operator, address indexed to, uint256 amount, bytes data, bytes operatorData);

    /**
     * @dev Emitted when `operator` destroys `amount` tokens from `account`.
     *
     * Note that some additional user `data` and `operatorData` can be logged in the event.
     */
    event Burned(address indexed operator, address indexed from, uint256 amount, bytes data, bytes operatorData);

    /**
     * @dev Emitted when `operator` is made operator for `tokenHolder`.
     */
    event AuthorizedOperator(address indexed operator, address indexed tokenHolder);

    /**
     * @dev Emitted when `operator` is revoked its operator status for `tokenHolder`.
     */
    event RevokedOperator(address indexed operator, address indexed tokenHolder);

    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the smallest part of the token that is not divisible. This
     * means all token operations (creation, movement and destruction) must have
     * amounts that are a multiple of this number.
     *
     * For most token contracts, this value will equal 1.
     */
    function granularity() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by an account (`owner`).
     */
    function balanceOf(address owner) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * If send or receive hooks are registered for the caller and `recipient`,
     * the corresponding functions will be called with `data` and empty
     * `operatorData`. See {IERC777Sender} and {IERC777Recipient}.
     *
     * Emits a {Sent} event.
     *
     * Requirements
     *
     * - the caller must have at least `amount` tokens.
     * - `recipient` cannot be the zero address.
     * - if `recipient` is a contract, it must implement the {IERC777Recipient}
     * interface.
     */
    function send(
        address recipient,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev Destroys `amount` tokens from the caller's account, reducing the
     * total supply.
     *
     * If a send hook is registered for the caller, the corresponding function
     * will be called with `data` and empty `operatorData`. See {IERC777Sender}.
     *
     * Emits a {Burned} event.
     *
     * Requirements
     *
     * - the caller must have at least `amount` tokens.
     */
    function burn(uint256 amount, bytes calldata data) external;

    /**
     * @dev Returns true if an account is an operator of `tokenHolder`.
     * Operators can send and burn tokens on behalf of their owners. All
     * accounts are their own operator.
     *
     * See {operatorSend} and {operatorBurn}.
     */
    function isOperatorFor(address operator, address tokenHolder) external view returns (bool);

    /**
     * @dev Make an account an operator of the caller.
     *
     * See {isOperatorFor}.
     *
     * Emits an {AuthorizedOperator} event.
     *
     * Requirements
     *
     * - `operator` cannot be calling address.
     */
    function authorizeOperator(address operator) external;

    /**
     * @dev Revoke an account's operator status for the caller.
     *
     * See {isOperatorFor} and {defaultOperators}.
     *
     * Emits a {RevokedOperator} event.
     *
     * Requirements
     *
     * - `operator` cannot be calling address.
     */
    function revokeOperator(address operator) external;

    /**
     * @dev Returns the list of default operators. These accounts are operators
     * for all token holders, even if {authorizeOperator} was never called on
     * them.
     *
     * This list is immutable, but individual holders may revoke these via
     * {revokeOperator}, in which case {isOperatorFor} will return false.
     */
    function defaultOperators() external view returns (address[] memory);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient`. The caller must
     * be an operator of `sender`.
     *
     * If send or receive hooks are registered for `sender` and `recipient`,
     * the corresponding functions will be called with `data` and
     * `operatorData`. See {IERC777Sender} and {IERC777Recipient}.
     *
     * Emits a {Sent} event.
     *
     * Requirements
     *
     * - `sender` cannot be the zero address.
     * - `sender` must have at least `amount` tokens.
     * - the caller must be an operator for `sender`.
     * - `recipient` cannot be the zero address.
     * - if `recipient` is a contract, it must implement the {IERC777Recipient}
     * interface.
     */
    function operatorSend(
        address sender,
        address recipient,
        uint256 amount,
        bytes calldata data,
        bytes calldata operatorData
    ) external;

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the total supply.
     * The caller must be an operator of `account`.
     *
     * If a send hook is registered for `account`, the corresponding function
     * will be called with `data` and `operatorData`. See {IERC777Sender}.
     *
     * Emits a {Burned} event.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     * - the caller must be an operator for `account`.
     */
    function operatorBurn(
        address account,
        uint256 amount,
        bytes calldata data,
        bytes calldata operatorData
    ) external;

    event Sent(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 amount,
        bytes data,
        bytes operatorData
    );
}

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

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

// File: @openzeppelin/contracts/token/ERC1155/IERC1155.sol


// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;


/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// File: @chainlink/contracts/src/v0.8/VRFRequestIDBase.sol


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
  ) internal pure returns (uint256) {
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
  function makeRequestId(bytes32 _keyHash, uint256 _vRFInputSeed) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked(_keyHash, _vRFInputSeed));
  }
}

// File: @chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol


pragma solidity ^0.8.0;

interface LinkTokenInterface {
  function allowance(address owner, address spender) external view returns (uint256 remaining);

  function approve(address spender, uint256 value) external returns (bool success);

  function balanceOf(address owner) external view returns (uint256 balance);

  function decimals() external view returns (uint8 decimalPlaces);

  function decreaseApproval(address spender, uint256 addedValue) external returns (bool success);

  function increaseApproval(address spender, uint256 subtractedValue) external;

  function name() external view returns (string memory tokenName);

  function symbol() external view returns (string memory tokenSymbol);

  function totalSupply() external view returns (uint256 totalTokensIssued);

  function transfer(address to, uint256 value) external returns (bool success);

  function transferAndCall(
    address to,
    uint256 value,
    bytes calldata data
  ) external returns (bool success);

  function transferFrom(
    address from,
    address to,
    uint256 value
  ) external returns (bool success);
}

// File: @chainlink/contracts/src/v0.8/VRFConsumerBase.sol


pragma solidity ^0.8.0;



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
 * @dev     constructor(<other arguments>, address _vrfCoordinator, address _link)
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
  function fulfillRandomness(bytes32 requestId, uint256 randomness) internal virtual;

  /**
   * @dev In order to keep backwards compatibility we have kept the user
   * seed field around. We remove the use of it because given that the blockhash
   * enters later, it overrides whatever randomness the used seed provides.
   * Given that it adds no security, and can easily lead to misunderstandings,
   * we have removed it from usage and can now provide a simpler API.
   */
  uint256 private constant USER_SEED_PLACEHOLDER = 0;

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
  function requestRandomness(bytes32 _keyHash, uint256 _fee) internal returns (bytes32 requestId) {
    LINK.transferAndCall(vrfCoordinator, _fee, abi.encode(_keyHash, USER_SEED_PLACEHOLDER));
    // This is the seed passed to VRFCoordinator. The oracle will mix this with
    // the hash of the block containing this request to obtain the seed/input
    // which is finally passed to the VRF cryptographic machinery.
    uint256 vRFSeed = makeVRFInputSeed(_keyHash, USER_SEED_PLACEHOLDER, address(this), nonces[_keyHash]);
    // nonces[_keyHash] must stay in sync with
    // VRFCoordinator.nonces[_keyHash][this], which was incremented by the above
    // successful LINK.transferAndCall (in VRFCoordinator.randomnessRequest).
    // This provides protection against the user repeating their input seed,
    // which would result in a predictable/duplicate output, if multiple such
    // requests appeared in the same block.
    nonces[_keyHash] = nonces[_keyHash] + 1;
    return makeRequestId(_keyHash, vRFSeed);
  }

  LinkTokenInterface internal immutable LINK;
  address private immutable vrfCoordinator;

  // Nonces for each VRF key from which randomness has been requested.
  //
  // Must stay in sync with VRFCoordinator[_keyHash][this]
  mapping(bytes32 => uint256) /* keyHash */ /* nonce */
    private nonces;

  /**
   * @param _vrfCoordinator address of VRFCoordinator contract
   * @param _link address of LINK token contract
   *
   * @dev https://docs.chain.link/docs/link-token-contracts
   */
  constructor(address _vrfCoordinator, address _link) {
    vrfCoordinator = _vrfCoordinator;
    LINK = LinkTokenInterface(_link);
  }

  // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
  // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
  // the origin of the call
  function rawFulfillRandomness(bytes32 requestId, uint256 randomness) external {
    require(msg.sender == vrfCoordinator, "Only VRFCoordinator can fulfill");
    fulfillRandomness(requestId, randomness);
  }
}

// File: contracts/NFTLotteryV3.sol

pragma solidity ^0.8.0;





interface IArtisFarm {
    function stakers(address staker)
        external
        view
        returns (
            bool isStaking,
            uint256 startTime,
            uint256 artisBalance,
            address addr
        );
}

contract NFTLottery_v3 is VRFConsumerBase {
    bytes32 internal keyHash;
    uint256 internal LINKfee;
    mapping(address => uint256) public ticketBalances;
    uint256 public ticketFee;
    uint256 public totalTicketsPurchased;
    uint256 public totalLotteryGames;
    uint256 public discountRate;
    IERC1155 public angelClub;
    uint256 public angelClubId;
    IERC777 artis;
    IArtisFarm artisFarm;
    uint256 public discountBalanceThreshold;

    struct LotteryGame {
        bool created;
        mapping(uint256 => address) ticketEntries;
        bool winnerFound;
        bool newEntryAllowed;
        uint256 totalEntries;
        uint256 winningNumber;
        address nftAddress;
        uint256 nftID;
        string chain;
    }
    mapping(uint256 => LotteryGame) public lotteryGames;

    //LINK request management
    mapping(bytes32 => uint256) requestIdToLotteryId;

    //ARTIS token address
    address public artisToken;

    //Address to Admin Priviledges
    address public ADMIN_ROLE;

    event LotteryCreated(
        uint256 gameID,
        address nftAddress,
        uint256 nftID,
        string chain
    );
    event TicketsPurchased(
        address purchaser,
        uint256 amount,
        uint256 totalPrice
    );
    event TicketRedeemed(
        address redeemer,
        uint256 gameID,
        uint256 winningNumber
    );
    event WinningNumberFound(uint256 gameID, uint256 winningNumber);
    event WinnerFound(address winner, uint256 gameID);
    event LotteryReEnabled(uint256 gameID);
    event LotteryDisabled(uint256 gameID);
    event LinkAdded(uint256 amount);

    /**
     * Constructor inherits VRFConsumerBase
     *
     * Network: Polygon Mainnet
     * Chainlink VRF Coordinator address: 0xAE975071Be8F8eE67addBC1A82488F1C24858067
     * LINK token address:                0xb0897686c545045aFc77CF20eC7A532E3120E0F1
     * Key Hash: 0xcc294a196eeeb44da2888d17c0625cc88d70d9760a69d58d853ba6581a9ab0cd
     */
    constructor()
        VRFConsumerBase(
            0xAE975071Be8F8eE67addBC1A82488F1C24858067, // VRF Coordinator
            0xb0897686c545045aFc77CF20eC7A532E3120E0F1 // LINK Token
        )
    {
        // Default values at time of contract creation
        keyHash = 0xcc294a196eeeb44da2888d17c0625cc88d70d9760a69d58d853ba6581a9ab0cd;
        LINKfee = 0.0005 * 10**18; // 0.0005 LINK (Varies by network)
        ADMIN_ROLE = msg.sender;
        ticketFee = 0.1 * 10**18; // 0.1
        artisToken = 0x8EC776d8Eda7275aa566794D6578eF607C32a02C;
        angelClub = IERC1155(0xa79dF500990cBEf47c4b0b7B8c70666bd2fe389b);
        artis = IERC777(artisToken);
        artisFarm = IArtisFarm(0x898d81625bD6818B85ee4b1814C557D70ff570aD);
        discountBalanceThreshold = 100000000000000000000000;
        discountRate = 20;
    }

    function buyTickets(uint256 amount) public payable {
        require(amount > 0, "Must purchase at least one ticket");
        uint256 totalPrice;
        try this.getPrice() returns (uint256 price) {
            totalPrice = price * amount;
        } catch {
            totalPrice = ticketFee * amount;
        }
        require(msg.value == totalPrice, "Invalid ticket price");
        ticketBalances[msg.sender] += amount;
        totalTicketsPurchased += amount;
        emit TicketsPurchased(msg.sender, amount, totalPrice);
    }

    function buyTicketsAndRedeem(uint256 amount, uint256 gameID) external {
        buyTickets(amount);
        redeemTicketBatch(gameID, amount);
    }

    function getPrice() public view returns (uint256) {
        uint256 price = ticketFee;
        uint256 artisBalance = artis.balanceOf(msg.sender);
        uint256 erc1155Balance = angelClub.balanceOf(msg.sender, angelClubId);
        (, , uint256 stakersBalance, ) = artisFarm.stakers(msg.sender);
        if (
            artisBalance + stakersBalance >
            discountBalanceThreshold || erc1155Balance > 0
        ) {
            price = (price * (100 - discountRate)) / 100;
        }
        return price;
    }

    /*
        Game Management
    */
    function createNewLotteryGame(
        address nftAddress,
        uint256 nftId,
        string memory chain
    ) external onlyAdmin {
        totalLotteryGames += 1;
        LotteryGame storage game = lotteryGames[totalLotteryGames];
        require(game.created == false, "LotteryGameID exists already.");
        game.created = true;
        game.newEntryAllowed = true;
        game.totalEntries = 0;
        game.winningNumber = game.totalEntries + 1;
        game.nftID = nftId;
        game.chain = chain;
        game.nftAddress = nftAddress;
        emit LotteryCreated(totalLotteryGames, nftAddress, nftId, chain);
    }

    function disableLotteryGame(uint256 lotteryGameID)
        external
        onlyAdmin
        lotteryExists(lotteryGameID)
    {
        require(
            lotteryGames[lotteryGameID].newEntryAllowed == true,
            "Lottery already disabled."
        );
        lotteryGames[lotteryGameID].winnerFound = false;
        lotteryGames[lotteryGameID].newEntryAllowed = false;
        emit LotteryDisabled(lotteryGameID);
    }

    function enableLotteryGame(uint256 lotteryGameID)
        external
        onlyAdmin
        lotteryExists(lotteryGameID)
    {
        require(
            lotteryGames[lotteryGameID].newEntryAllowed == false,
            "Lottery already enabled."
        );
        lotteryGames[lotteryGameID].winnerFound = false;
        lotteryGames[lotteryGameID].newEntryAllowed = true;
        emit LotteryReEnabled(lotteryGameID);
    }

    /**
     * Requests randomness
     */
    function getWinningLotteryNumbers(uint256 lotteryGameID)
        public
        onlyAdmin
        lotteryExists(lotteryGameID)
    {
        require(
            LINK.balanceOf(address(this)) >= LINKfee,
            "Not enough LINK - fill contract with LINK"
        );
        bytes32 requestID = requestRandomness(keyHash, LINKfee);
        requestIdToLotteryId[requestID] = lotteryGameID;
        lotteryGames[lotteryGameID].newEntryAllowed = false;
    }

    /**
     * Callback function used by VRF Coordinator 0 to total entries
     */
    function fulfillRandomness(bytes32 requestId, uint256 randomness)
        internal
        override
    {
        uint256 lotteryGameID = requestIdToLotteryId[requestId];
        lotteryGames[lotteryGameID].winningNumber = ((randomness %
            lotteryGames[lotteryGameID].totalEntries) - 1);

        emit WinnerFound(
            lotteryGames[lotteryGameID].ticketEntries[
                lotteryGames[lotteryGameID].winningNumber
            ],
            lotteryGameID
        );
        lotteryGames[lotteryGameID].winnerFound = true;
    }

    /*
        Functions to redeem purchased tickets for an active lottery game.
    */
    function redeemTicket(
        uint256 lotteryGameID,
        address user,
        uint256 amount
    ) private lotteryExists(lotteryGameID) {
        LotteryGame storage game = lotteryGames[lotteryGameID];
        require(game.newEntryAllowed == true, "No new entries allowed.");
        require(
            ticketBalances[user] >= amount,
            "You do not have any tickets to use."
        );
        uint256 number = game.totalEntries;
        ticketBalances[user] -= amount;
        uint256 ticket = 0;
        for(ticket = 0; ticket < amount; ticket++){
            game.ticketEntries[number + ticket] = user;
            emit TicketRedeemed(user, lotteryGameID, number);
        }
        game.totalEntries = number + amount;
    }

    function redeemTicketBatch(uint256 gameID, uint256 amount) public {
        redeemTicket(gameID, msg.sender, amount);
    }

    function redeemTicket(uint256 lotteryGameID) public {
        redeemTicket(lotteryGameID, msg.sender, 1);
    }

    /*

        Award tickets functions. 
        OnlyAdmin

    */
    function awardTickets(address user, uint256 amount) public onlyAdmin {
        ticketBalances[user] += amount;
    }

    function awardTicketsBatch(
        address[] calldata users,
        uint256[] calldata amount
    ) external onlyAdmin {
        require(
            users.length == amount.length,
            "Arrays must be of equal length."
        );
        for (uint256 i = 0; i < users.length; i++) {
            awardTickets(users[i], amount[i]);
        }
    }

    function awardAndRedeemTickets(
        address user,
        uint256 amount,
        uint256 lotteryGameID
    ) external onlyAdmin {
        ticketBalances[user] += amount;
        redeemTicket(lotteryGameID, user, amount);
    }

    /*
        onlyAdmin

        Checks to see if caller has admin priviledges
    */
    modifier onlyAdmin() {
        require(msg.sender == ADMIN_ROLE, "NO ADMIN PRIVILEDGES.");
        _;
    }

    modifier lotteryExists(uint256 lotteryGameID) {
        require(
            lotteryGames[lotteryGameID].created == true,
            "Lottery ID does not exist."
        );
        _;
    }

    /*
     *
     *   Setter Functions
     *
     */
    function setFee(uint256 newFee) external onlyAdmin {
        ticketFee = newFee;
    }

    function setStakingContract(address newAddress) external onlyAdmin {
        artisFarm = IArtisFarm(newAddress);
    }

    function setDiscountThreshold(uint256 newThreshold) external onlyAdmin {
        discountBalanceThreshold = newThreshold;
    }

    function setDiscountRate(uint256 newRate) external onlyAdmin {
        discountRate = newRate;
    }

    function setAngelClub(address nftAddress, uint256 nftId)
        external
        onlyAdmin
    {
        angelClub = IERC1155(nftAddress);
        angelClubId = nftId;
    }

    function setLINKFee(uint256 newFee) external onlyAdmin {
        LINKfee = newFee;
    }

    /*
        withdraw
        
        Function to avoid locking your LINK in the contract
    */
    function withdrawLink() external onlyAdmin {
        require(LINK.balanceOf(address(this)) > 0, "No LINK to withdraw");
        LINK.transfer(msg.sender, LINK.balanceOf(address(this)));
    }

    function retrieveEther() external onlyAdmin {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success, "Ether transfer failed");
    }

    /*
     *
     *   Emergency Functions
     *
     */
    function emergencyRetrieveTokens(address _token) external onlyAdmin {
        IERC20 token = IERC20(_token);
        uint256 tokenBalance = token.balanceOf(address(this));
        require(
            token.transfer(msg.sender, tokenBalance),
            "Token transfer failed"
        );
    }
}