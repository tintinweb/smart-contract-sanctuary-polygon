/**
 *Submitted for verification at polygonscan.com on 2021-10-16
*/

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
// File: @chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol


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

// File: @openzeppelin/contracts/utils/Context.sol



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

// File: @openzeppelin/contracts/access/Ownable.sol



pragma solidity ^0.8.0;


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: contracts/RandomNumber.sol



/**
 *  ______ _   _  ___  ___  ___   _   _ _____  _   _ _   _
 * |  ___| | | | |  \/  | / _ \ | \ | /  __ \| | | | | | |
 * | |_  | | | | | .  . |/ /_\ \|  \| | /  \/| |_| | | | |
 * |  _| | | | | | |\/| ||  _  || . ` | |    |  _  | | | |
 * | |   | |_| | | |  | || | | || |\  | \__/\| | | | |_| |
 * \_|    \___/  \_|  |_/\_| |_/\_| \_/\____/\_| |_/\___/
 *
 *
 *  _____ _____ ___  _____  _   _  _____   _    _ _____ _   _  _   _  ___________
 * /  ___|_   _/ _ \/  __ \| | | ||  ___| | |  | |_   _| \ | || \ | ||  ___| ___ \
 * \ `--.  | |/ /_\ \ /  \/| |_| || |__   | |  | | | | |  \| ||  \| || |__ | |_/ /
 *  `--. \ | ||  _  | |    |  _  ||  __|  | |/\| | | | | . ` || . ` ||  __||    /
 * /\__/ / | || | | | \__/\| | | || |___  \  /\  /_| |_| |\  || |\  || |___| |\ \
 * \____/  \_/\_| |_/\____/\_| |_/\____/   \/  \/ \___/\_| \_/\_| \_/\____/\_| \_|
 *
 */



pragma solidity ^0.8.9;

// Contract to get random address from holders to send tokens to
contract GenerateRandomNumber is Ownable, VRFConsumerBase {
    address public winner;
    uint256 randNonce = 0;
       bytes32 internal keyHash;
    uint256 internal fee;
    
    uint256 public randomResult;
    
   /**
     * Constructor inherits VRFConsumerBase
     * 
     * Network: Polygon (Matic) Mumbai Testnet
     * Chainlink VRF Coordinator address: 0x8C7382F9D8f56b33781fE506E897a4F1e2d17255
     * LINK token address:                0x326C977E6efc84E512bB9C30f76E30c160eD06FB
     * Key Hash: 0x6e75b569a01ef56d18cab6a8e71e6600d6ce853834d4a5748b720d06f878b3a4
     */
    constructor() 
        VRFConsumerBase(
            0x8C7382F9D8f56b33781fE506E897a4F1e2d17255, // VRF Coordinator
            0x326C977E6efc84E512bB9C30f76E30c160eD06FB  // LINK Token
        ) public
    {
        keyHash = 0x6e75b569a01ef56d18cab6a8e71e6600d6ce853834d4a5748b720d06f878b3a4;
        fee = 0.0001 * 10 ** 18; // 0.0001 LINK
    }
    
    //Declare an Event
    event Winner(address _winner);

    /** 
     * Requests randomness from a user-provided seed
     ************************************************************************************
     *                                    STOP!                                         * 
     *         THIS FUNCTION WILL FAIL IF THIS CONTRACT DOES NOT OWN LINK               *
     *         ----------------------------------------------------------               *
     *         Learn how to obtain testnet LINK and fund this contract:                 *
     *         ------- https://docs.chain.link/docs/acquire-link --------               *
     *         ---- https://docs.chain.link/docs/fund-your-contract -----               *
     *                                                                                  *
     ************************************************************************************/
    function getRandomNumber() public returns (bytes32 requestId) {
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK - fill contract with faucet");
        return requestRandomness(keyHash, fee);
        
    }

    /**
     * Callback function used by VRF Coordinator
     */
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        randomResult =  (randomness % 222) + 1;
    }
    

    address[] data = [
        0xad2806a4daa4aa721349c48F40e8B485b125F870,
        0x9D28605C4db7fb13F5D2E58E7109E0f808d6A7B7,
        0x9D28605C4db7fb13F5D2E58E7109E0f808d6A7B7,
        0xaA92bd09701D53A0f8089A93C354C03C73114450,
        0x9D28605C4db7fb13F5D2E58E7109E0f808d6A7B7,
        0x9D28605C4db7fb13F5D2E58E7109E0f808d6A7B7,
        0x9D28605C4db7fb13F5D2E58E7109E0f808d6A7B7,
        0x49e595e5273B854675B40CCd51A00801EcA16F9F,
        0x098E2a5B2D95eA04Fc63403f4Be650bEb5194f13,
        0x49e595e5273B854675B40CCd51A00801EcA16F9F,
        0x9D28605C4db7fb13F5D2E58E7109E0f808d6A7B7,
        0x3862f3C24F0710278A80Ff42a591877E5A95ce37,
        0xdEb5AfF5E21D0669AB5956475B2Dcb4E9b22ac04,
        0xdEb5AfF5E21D0669AB5956475B2Dcb4E9b22ac04,
        0x9D28605C4db7fb13F5D2E58E7109E0f808d6A7B7,
        0x7828b91A7B8772a4451c705206405DE94a246dD5,
        0x9D28605C4db7fb13F5D2E58E7109E0f808d6A7B7,
        0x79f37a3D42B19BcA7A67C5a312aef3066619AE67,
        0x9D28605C4db7fb13F5D2E58E7109E0f808d6A7B7,
        0xd81cd25e567a6EdF7919200E13Fc03450D04C54f,
        0x5DDf8D955d4C86E2e7081FB06Be7d158bB833086,
        0x9D28605C4db7fb13F5D2E58E7109E0f808d6A7B7,
        0xdEb5AfF5E21D0669AB5956475B2Dcb4E9b22ac04,
        0xdf43e37D18aCFD3aa68BF2D6FCb323543BA8d706,
        0x9D28605C4db7fb13F5D2E58E7109E0f808d6A7B7,
        0x9D28605C4db7fb13F5D2E58E7109E0f808d6A7B7,
        0xa6c8949A8871d309F94996019eB2D7aF500941F0,
        0x6b3841D26891dc6b635DBeC816D453Cf3A084526,
        0xc94aA6042f86049F6Af0512e5F3d47a159E9C359,
        0xdEb5AfF5E21D0669AB5956475B2Dcb4E9b22ac04,
        0x49e595e5273B854675B40CCd51A00801EcA16F9F,
        0xC9c4b79bee62649d91E70F7082FF07E7Dd4ac0C9,
        0x6b3841D26891dc6b635DBeC816D453Cf3A084526,
        0x6c1cc9c0f32980Ead12373e5312EE046D00664bE,
        0x6b3841D26891dc6b635DBeC816D453Cf3A084526,
        0x3862f3C24F0710278A80Ff42a591877E5A95ce37,
        0xdf43e37D18aCFD3aa68BF2D6FCb323543BA8d706,
        0x62309a5fd817D6c6eCDDd61000Ba94a9564B9582,
        0xad2806a4daa4aa721349c48F40e8B485b125F870,
        0x2acC67eD07170E8A683C7Af54F06Bb8fB2fA88F7,
        0x79f37a3D42B19BcA7A67C5a312aef3066619AE67,
        0x9D28605C4db7fb13F5D2E58E7109E0f808d6A7B7,
        0x9D28605C4db7fb13F5D2E58E7109E0f808d6A7B7,
        0x9D28605C4db7fb13F5D2E58E7109E0f808d6A7B7,
        0x9D28605C4db7fb13F5D2E58E7109E0f808d6A7B7,
        0x768D280111e0fDc53E355ceFB1962eB91b6cca2d,
        0x7828b91A7B8772a4451c705206405DE94a246dD5,
        0x8eB3E91CdB937941BFDe3673151B1980bCa062d7,
        0x9D28605C4db7fb13F5D2E58E7109E0f808d6A7B7,
        0x9D28605C4db7fb13F5D2E58E7109E0f808d6A7B7,
        0x9D28605C4db7fb13F5D2E58E7109E0f808d6A7B7,
        0xe6Ef59Af57e89E13b7791980034510107dF7E442,
        0x6b3841D26891dc6b635DBeC816D453Cf3A084526,
        0x2acC67eD07170E8A683C7Af54F06Bb8fB2fA88F7,
        0xe6Ef59Af57e89E13b7791980034510107dF7E442,
        0x6c1cc9c0f32980Ead12373e5312EE046D00664bE,
        0x6c1cc9c0f32980Ead12373e5312EE046D00664bE,
        0x9D28605C4db7fb13F5D2E58E7109E0f808d6A7B7,
        0x7828b91A7B8772a4451c705206405DE94a246dD5,
        0x9D28605C4db7fb13F5D2E58E7109E0f808d6A7B7,
        0x9D28605C4db7fb13F5D2E58E7109E0f808d6A7B7,
        0xad2806a4daa4aa721349c48F40e8B485b125F870,
        0x6b3841D26891dc6b635DBeC816D453Cf3A084526,
        0x7828b91A7B8772a4451c705206405DE94a246dD5,
        0x6c1cc9c0f32980Ead12373e5312EE046D00664bE,
        0x62309a5fd817D6c6eCDDd61000Ba94a9564B9582,
        0xdEb5AfF5E21D0669AB5956475B2Dcb4E9b22ac04,
        0x6b3841D26891dc6b635DBeC816D453Cf3A084526,
        0x098E2a5B2D95eA04Fc63403f4Be650bEb5194f13,
        0x55d0C63B00Ce50527124780224423E5A4671D79b,
        0x6c1cc9c0f32980Ead12373e5312EE046D00664bE,
        0x768D280111e0fDc53E355ceFB1962eB91b6cca2d,
        0x9D28605C4db7fb13F5D2E58E7109E0f808d6A7B7,
        0xa6c8949A8871d309F94996019eB2D7aF500941F0,
        0xd81cd25e567a6EdF7919200E13Fc03450D04C54f,
        0x3862f3C24F0710278A80Ff42a591877E5A95ce37,
        0xdEb5AfF5E21D0669AB5956475B2Dcb4E9b22ac04,
        0x9D28605C4db7fb13F5D2E58E7109E0f808d6A7B7,
        0x9D28605C4db7fb13F5D2E58E7109E0f808d6A7B7,
        0x6c1cc9c0f32980Ead12373e5312EE046D00664bE,
        0x9D28605C4db7fb13F5D2E58E7109E0f808d6A7B7,
        0x9D28605C4db7fb13F5D2E58E7109E0f808d6A7B7,
        0x9D28605C4db7fb13F5D2E58E7109E0f808d6A7B7,
        0x9D28605C4db7fb13F5D2E58E7109E0f808d6A7B7,
        0x7828b91A7B8772a4451c705206405DE94a246dD5,
        0xad2806a4daa4aa721349c48F40e8B485b125F870,
        0x9D28605C4db7fb13F5D2E58E7109E0f808d6A7B7,
        0x2acC67eD07170E8A683C7Af54F06Bb8fB2fA88F7,
        0x9D28605C4db7fb13F5D2E58E7109E0f808d6A7B7,
        0x99D0b6DB84dC574b5163fE66eC9e80067597456f,
        0xfe1a7b1E7f984eef1F435C481Ba5F036e2815924,
        0xc94aA6042f86049F6Af0512e5F3d47a159E9C359,
        0x62309a5fd817D6c6eCDDd61000Ba94a9564B9582,
        0xe510E2B067D2Cad79a8BC3CBA560C118d65285ac,
        0xd170C102DD8Ff7B5fe04B541BEd573cCb29B67F9,
        0x9D28605C4db7fb13F5D2E58E7109E0f808d6A7B7,
        0xaA92bd09701D53A0f8089A93C354C03C73114450,
        0xe510E2B067D2Cad79a8BC3CBA560C118d65285ac,
        0x9D28605C4db7fb13F5D2E58E7109E0f808d6A7B7,
        0xe510E2B067D2Cad79a8BC3CBA560C118d65285ac,
        0x768D280111e0fDc53E355ceFB1962eB91b6cca2d,
        0x9D28605C4db7fb13F5D2E58E7109E0f808d6A7B7,
        0xc94aA6042f86049F6Af0512e5F3d47a159E9C359,
        0x9D28605C4db7fb13F5D2E58E7109E0f808d6A7B7,
        0x098E2a5B2D95eA04Fc63403f4Be650bEb5194f13,
        0x9D28605C4db7fb13F5D2E58E7109E0f808d6A7B7,
        0xdEb5AfF5E21D0669AB5956475B2Dcb4E9b22ac04,
        0x768D280111e0fDc53E355ceFB1962eB91b6cca2d,
        0x098E2a5B2D95eA04Fc63403f4Be650bEb5194f13,
        0x6c1cc9c0f32980Ead12373e5312EE046D00664bE,
        0x62309a5fd817D6c6eCDDd61000Ba94a9564B9582,
        0x62309a5fd817D6c6eCDDd61000Ba94a9564B9582,
        0x2f7a9cc140e50474846b36e036caac4095F015c5,
        0x9D28605C4db7fb13F5D2E58E7109E0f808d6A7B7,
        0x9D28605C4db7fb13F5D2E58E7109E0f808d6A7B7,
        0x9cad128166d151563C3248E4046414AcCB1d1c30,
        0x99D0b6DB84dC574b5163fE66eC9e80067597456f,
        0x99D0b6DB84dC574b5163fE66eC9e80067597456f,
        0x62309a5fd817D6c6eCDDd61000Ba94a9564B9582,
        0x6c1cc9c0f32980Ead12373e5312EE046D00664bE,
        0x4536034E4412E42a0470A6143df01206E30c5995,
        0xb69FE20b8B1Ad52669c8bdB56b823F70AbB59EdD,
        0xe6Ef59Af57e89E13b7791980034510107dF7E442,
        0x3862f3C24F0710278A80Ff42a591877E5A95ce37,
        0x36E92F91B3787C50dBb89e6BbdC7983E2C3C8376,
        0xd81cd25e567a6EdF7919200E13Fc03450D04C54f,
        0xdB9D71e2236E5C678F432A270E85D41DaF0Ed46e,
        0x99D0b6DB84dC574b5163fE66eC9e80067597456f,
        0x6b3841D26891dc6b635DBeC816D453Cf3A084526,
        0x459A16C988f1959Aa040bB2FB8cBA20B0891dB0a,
        0x9D28605C4db7fb13F5D2E58E7109E0f808d6A7B7,
        0x9D28605C4db7fb13F5D2E58E7109E0f808d6A7B7,
        0xad2806a4daa4aa721349c48F40e8B485b125F870,
        0x9D28605C4db7fb13F5D2E58E7109E0f808d6A7B7,
        0x768D280111e0fDc53E355ceFB1962eB91b6cca2d,
        0x49e595e5273B854675B40CCd51A00801EcA16F9F,
        0x098E2a5B2D95eA04Fc63403f4Be650bEb5194f13,
        0x36751160556243f544C0f7a47202B48b264a11fb,
        0x9D28605C4db7fb13F5D2E58E7109E0f808d6A7B7,
        0x45552e83823c69B56E71a3dA8C7249c9Fea0999E,
        0x45552e83823c69B56E71a3dA8C7249c9Fea0999E,
        0xc94aA6042f86049F6Af0512e5F3d47a159E9C359,
        0x768D280111e0fDc53E355ceFB1962eB91b6cca2d,
        0x3862f3C24F0710278A80Ff42a591877E5A95ce37,
        0xe510E2B067D2Cad79a8BC3CBA560C118d65285ac,
        0x098E2a5B2D95eA04Fc63403f4Be650bEb5194f13,
        0xe6Ef59Af57e89E13b7791980034510107dF7E442,
        0xe510E2B067D2Cad79a8BC3CBA560C118d65285ac,
        0x098E2a5B2D95eA04Fc63403f4Be650bEb5194f13,
        0x99D0b6DB84dC574b5163fE66eC9e80067597456f,
        0x098E2a5B2D95eA04Fc63403f4Be650bEb5194f13,
        0x3862f3C24F0710278A80Ff42a591877E5A95ce37,
        0x098E2a5B2D95eA04Fc63403f4Be650bEb5194f13,
        0x9D28605C4db7fb13F5D2E58E7109E0f808d6A7B7,
        0xe510E2B067D2Cad79a8BC3CBA560C118d65285ac,
        0x2acC67eD07170E8A683C7Af54F06Bb8fB2fA88F7,
        0x098E2a5B2D95eA04Fc63403f4Be650bEb5194f13,
        0x098E2a5B2D95eA04Fc63403f4Be650bEb5194f13,
        0x62309a5fd817D6c6eCDDd61000Ba94a9564B9582,
        0x6c1cc9c0f32980Ead12373e5312EE046D00664bE,
        0xad2806a4daa4aa721349c48F40e8B485b125F870,
        0x6b3841D26891dc6b635DBeC816D453Cf3A084526,
        0x9D28605C4db7fb13F5D2E58E7109E0f808d6A7B7,
        0x9D28605C4db7fb13F5D2E58E7109E0f808d6A7B7,
        0x99D0b6DB84dC574b5163fE66eC9e80067597456f,
        0x99D0b6DB84dC574b5163fE66eC9e80067597456f,
        0x098E2a5B2D95eA04Fc63403f4Be650bEb5194f13,
        0x99D0b6DB84dC574b5163fE66eC9e80067597456f,
        0x99D0b6DB84dC574b5163fE66eC9e80067597456f,
        0xad2806a4daa4aa721349c48F40e8B485b125F870,
        0x768D280111e0fDc53E355ceFB1962eB91b6cca2d,
        0x9D28605C4db7fb13F5D2E58E7109E0f808d6A7B7,
        0x9D28605C4db7fb13F5D2E58E7109E0f808d6A7B7,
        0xad2806a4daa4aa721349c48F40e8B485b125F870,
        0x62309a5fd817D6c6eCDDd61000Ba94a9564B9582,
        0x1e0090D9247985083801254d2142ae8deE57367D,
        0x2acC67eD07170E8A683C7Af54F06Bb8fB2fA88F7,
        0x9D28605C4db7fb13F5D2E58E7109E0f808d6A7B7,
        0x55d0C63B00Ce50527124780224423E5A4671D79b,
        0x6c1cc9c0f32980Ead12373e5312EE046D00664bE,
        0x4536034E4412E42a0470A6143df01206E30c5995,
        0xd81cd25e567a6EdF7919200E13Fc03450D04C54f,
        0x9D28605C4db7fb13F5D2E58E7109E0f808d6A7B7,
        0xe510E2B067D2Cad79a8BC3CBA560C118d65285ac,
        0x768D280111e0fDc53E355ceFB1962eB91b6cca2d,
        0x9984b3DcF3f774A32686585a6ea27848dE865aA6,
        0xad2806a4daa4aa721349c48F40e8B485b125F870,
        0x49e595e5273B854675B40CCd51A00801EcA16F9F,
        0x62309a5fd817D6c6eCDDd61000Ba94a9564B9582,
        0x098E2a5B2D95eA04Fc63403f4Be650bEb5194f13,
        0xad2806a4daa4aa721349c48F40e8B485b125F870,
        0x3862f3C24F0710278A80Ff42a591877E5A95ce37,
        0x99D0b6DB84dC574b5163fE66eC9e80067597456f,
        0x6c1cc9c0f32980Ead12373e5312EE046D00664bE,
        0x9D28605C4db7fb13F5D2E58E7109E0f808d6A7B7,
        0x4536034E4412E42a0470A6143df01206E30c5995,
        0x62309a5fd817D6c6eCDDd61000Ba94a9564B9582,
        0x9D28605C4db7fb13F5D2E58E7109E0f808d6A7B7,
        0x9D28605C4db7fb13F5D2E58E7109E0f808d6A7B7,
        0x4536034E4412E42a0470A6143df01206E30c5995,
        0x9D28605C4db7fb13F5D2E58E7109E0f808d6A7B7,
        0x9D28605C4db7fb13F5D2E58E7109E0f808d6A7B7,
        0x3862f3C24F0710278A80Ff42a591877E5A95ce37,
        0xd81cd25e567a6EdF7919200E13Fc03450D04C54f,
        0x62309a5fd817D6c6eCDDd61000Ba94a9564B9582,
        0x768D280111e0fDc53E355ceFB1962eB91b6cca2d,
        0x6b3841D26891dc6b635DBeC816D453Cf3A084526,
        0x7828b91A7B8772a4451c705206405DE94a246dD5,
        0x9D28605C4db7fb13F5D2E58E7109E0f808d6A7B7,
        0x9D28605C4db7fb13F5D2E58E7109E0f808d6A7B7,
        0x9D28605C4db7fb13F5D2E58E7109E0f808d6A7B7,
        0x768D280111e0fDc53E355ceFB1962eB91b6cca2d,
        0x9D28605C4db7fb13F5D2E58E7109E0f808d6A7B7,
        0x9D28605C4db7fb13F5D2E58E7109E0f808d6A7B7,
        0xe510E2B067D2Cad79a8BC3CBA560C118d65285ac,
        0x133C5142c08ADA5e6ef4c96Aa42c0F754Ec06480,
        0x7828b91A7B8772a4451c705206405DE94a246dD5,
        0x6c1cc9c0f32980Ead12373e5312EE046D00664bE,
        0x9D28605C4db7fb13F5D2E58E7109E0f808d6A7B7,
        0xb69FE20b8B1Ad52669c8bdB56b823F70AbB59EdD,
        0xfc8f4d94c3B7351158930523eDa29146E70e32D6,
        0x3862f3C24F0710278A80Ff42a591877E5A95ce37
    ];

    // function _pickRandomAddress() internal returns (address) {
    //     uint256 randomNumber = randMod(3);
    //     address x = data[randomNumber];
    //     return x;
    // }

    // function pickWinner() public onlyOwner {
    //     require(winner == address(0x0), "withdraw Error");
    //     address addressPayable = _pickRandomAddress();
    //     winner = addressPayable;
    // }
}