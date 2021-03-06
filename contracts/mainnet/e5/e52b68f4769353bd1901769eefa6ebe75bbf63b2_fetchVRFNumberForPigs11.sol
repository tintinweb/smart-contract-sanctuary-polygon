/**
 *Submitted for verification at polygonscan.com on 2022-04-03
*/

/* Copyright (c) 2018-2021 SmartContract ChainLink, Ltd.
 * 
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

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
  function makeVRFInputSeed(bytes32 _keyHash, uint256 _userSeed,
    address _requester, uint256 _nonce)
    internal pure returns (uint256)
  {
    return  uint256(keccak256(abi.encode(_keyHash, _userSeed, _requester, _nonce)));
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
    bytes32 _keyHash, uint256 _vRFInputSeed) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked(_keyHash, _vRFInputSeed));
  }
}

// File: @chainlink/contracts/src/v0.6/interfaces/LinkTokenInterface.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

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
  function transferAndCall(address to, uint256 value, bytes calldata data) external returns (bool success);
  function transferFrom(address from, address to, uint256 value) external returns (bool success);
}

// File: @chainlink/contracts/src/v0.6/vendor/SafeMathChainlink.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMathChainlink {
  /**
    * @dev Returns the addition of two unsigned integers, reverting on
    * overflow.
    *
    * Counterpart to Solidity's `+` operator.
    *
    * Requirements:
    * - Addition cannot overflow.
    */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, "SafeMath: addition overflow");

    return c;
  }

  /**
    * @dev Returns the subtraction of two unsigned integers, reverting on
    * overflow (when the result is negative).
    *
    * Counterpart to Solidity's `-` operator.
    *
    * Requirements:
    * - Subtraction cannot overflow.
    */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a, "SafeMath: subtraction overflow");
    uint256 c = a - b;

    return c;
  }

  /**
    * @dev Returns the multiplication of two unsigned integers, reverting on
    * overflow.
    *
    * Counterpart to Solidity's `*` operator.
    *
    * Requirements:
    * - Multiplication cannot overflow.
    */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b, "SafeMath: multiplication overflow");

    return c;
  }

  /**
    * @dev Returns the integer division of two unsigned integers. Reverts on
    * division by zero. The result is rounded towards zero.
    *
    * Counterpart to Solidity's `/` operator. Note: this function uses a
    * `revert` opcode (which leaves remaining gas untouched) while Solidity
    * uses an invalid opcode to revert (consuming all remaining gas).
    *
    * Requirements:
    * - The divisor cannot be zero.
    */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // Solidity only automatically asserts when dividing by 0
    require(b > 0, "SafeMath: division by zero");
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }

  /**
    * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
    * Reverts when dividing by zero.
    *
    * Counterpart to Solidity's `%` operator. This function uses a `revert`
    * opcode (which leaves remaining gas untouched) while Solidity uses an
    * invalid opcode to revert (consuming all remaining gas).
    *
    * Requirements:
    * - The divisor cannot be zero.
    */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0, "SafeMath: modulo by zero");
    return a % b;
  }
}

// File: @chainlink/contracts/src/v0.6/VRFConsumerBase.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

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

  using SafeMathChainlink for uint256;

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
  function fulfillRandomness(bytes32 requestId, uint256 randomness)
    internal virtual;

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
  function requestRandomness(bytes32 _keyHash, uint256 _fee)
    internal returns (bytes32 requestId)
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
    nonces[_keyHash] = nonces[_keyHash].add(1);
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
  constructor(address _vrfCoordinator, address _link) public {
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

pragma solidity 0.6.6;

contract fetchVRFNumberForPigs11 is VRFConsumerBase {
    //Polygon Mainnet
    address internal contractOwner;
    address internal vrfCoordinator = 0x3d2341ADb2D31f1c5530cDC622016af293177AE0;
    address internal linkToken = 0xb0897686c545045aFc77CF20eC7A532E3120E0F1;
    bool internal permanentlyStop = false;
    bool internal coordinatorBlocked = false;
    bytes32 internal keyHash = 0xf86195cf7690c55907b2b611ebb7343a6f649bff128701cc542f0569e2c549da;
    uint256 internal fee =  0.0001 * 10 ** 18;
    bytes32 public requestIDGenerated;
    uint256 public randomNumberGenerated;
    address[]public addresses=[0x55d5C69A8573f046E074cC203Ead44c6F49fd61e, 0x2Cc76Af6104A69975e16C4110fE283a09d150BA5, 0xEcEcafB3feA380eD39264a7aC86A3af846375aFF, 0x0D4fF60D09B8Fd790a7663dA86a791C2FeD41a23, 0x14202C79dc15CeBBa5115AdCe8a457F49BC71120, 0x33Ec0e01E2dd454D658E3ae748779F390024A5Cd, 0xf5493d28b94521fe392F640aA78df3C68531964e, 0xbd8a92E249090249c5fB2FF71e47B69fb650d3AF, 0x151771a16117293000120fCCdEb96CFd419F3663, 0xc026Fcdc9607234fEE5DA88B585ed2c9b0733942, 0x5E46D8Ade00a753D2901eb3d9B252e0e611E10d5, 0xa59Fe57dDcb393Dd3Dcaa2bA2766e10D4F38e339, 0xe7a62B99fB32654bDD4E144E0a6CB9507FA843fF, 0x1B2965dC3B1697DD10b7126EC7393d79cdA2cF91, 0x8297A5971a05903D4d33453425D1B800730B10e7, 0xC75291B6e917a1fc72ec396883eA005498dC0e55, 0x1Bc2C46d6A3c1A1DEE9B623FCA10d72987DC639f, 0xB349150d6270152ca24064ec78ce8C7d7Af9f203, 0x5f6DD98a74761939A55383EBf679e0617F7878fA, 0xAB3EBd5025fF4bd0d48B0049383a0496Cd62F90F, 0x7A69a8399740fcB54a182957181a5FCA675e1eF5, 0xF6Aa12C07d271e079859EC7D1Fca34694eD7a7a1, 0x288DeF8225b9E150dc8789e5291CfC5c7E35Eb35, 0x79206B9EE1b48Ad2eE925aC0f119A4DE93509F97, 0x57b0e9c1eafD1d144C186a2Dae435A5e8bEA2eb9, 0xbc074b6707053A349D44656B2a2156244182CAcb, 0xA2dC61ccf1C0B8dd305b82DA1F43FE8289118fa7, 0x6808C8F473363D085D8D8Ece4b53966cAD81Ee4A, 0x66dF013Fd8AcC69c12A3477B5FaaE009ef4E6d73, 0x2E0D63fFCB08eA20fF3AcDbB72dfEc97343885d2, 0xFc541Cd48E0795F042cc58DD730923fCd099e31D, 0x898F43EEC290c12B09a8e06B2D60E2726E86153b, 0xf25E635a9f35c97df49C52637EdDCDcA64259EF8, 0x6280aEB92C12ef44e04a053d3d23E563b4217382, 0x26011974D9919BA43c83B5C89a5D8f99ee7387f2, 0xBDb6fdd2bF2Aa01051540a0630ae568282a4bBef, 0xD7076AcC76d4379610fbA0dDDB1d35aA1280fc89, 0xEf6F400f46ea2B289B226F610d851A8324B67974, 0x3E0f589d68f839c5b9e92598370E4728A193eDfB, 0x750650d39D41cbF2afD591C22A204634EAa60db5, 0xA4D525E5A1dD7F93ab1dD8f71CE6B024e25f7Db8, 0x9ed3dB7a8ec964Ef0813eDb7bf3FF514a25fAE70, 0xc19A3f5d8bB5f10718527e2296aEb2F5C8Dc2974, 0x225189A1EA477a62FE4d27CF30aCa8B9168441D0, 0xF05F0A21310A6Ac0c8379E3c05f904A184E02Eb3, 0x1A6B6a319d119AAdF86Ed5FF3b578D4f7cf746ac, 0xEB0EbBc451218551F4152Db2887faF6c8BBA7BC0, 0xD6EC0742A70A2592aeBA61e3B7bEB9f2E6aa1BC1, 0x9686962604B22EFF0fB99EF0959Ae01897546DcF, 0xbF91459018A2526C745979466b09DBD1D239A41d, 0x85b608cB4AE6b8E7A5d493CD13F1DEe8e8efa701, 0x166aF43E109930652c59C214FCA62090668C28Db, 0xf5dCb2a47f738d8bA39F9Fa2DdC7592f268a262A, 0xcc139276fF0BE2dd9485d24C8E33e1C0b9D2E2DF, 0x00578f555EbF2308318438a1a679F761b788f2a1, 0x20535428e340dCB0138028fD641Fbb161b6986F7, 0xf0B33cEAfab33F5e00A86d74165e21e7b8a75fCA, 0xE43840e77829B2dF75959B7107D172060Ab6bd87, 0x9a11E786b40d16F5DE7c7DDdE39E09321d923F27, 0x8B77F3D65A53eF7F5cef97A1EFe424B1367EBec3, 0xe19A98c174fE6bdD2D4e6Bb602cc1D72932501c8, 0x69C05144e5840cB57d420792Fce17a73Ce206B1E, 0xcd492831d1f8A27C2E7d54E340eE1337b1BdF4a3, 0x9a116b9B8531d83c2e1Ac61BAbd4Fdf622b2dbb9, 0xCa11d10CEb098f597a0CAb28117fC3465991a63c, 0xdF157B7Bc919D559F58756e395079cb4f8bbF826, 0x453a6B83ba2Dd467004f96b3Ae5dd769F3dA0995, 0x64f82728A11e0FA5e27E15FB1937822Ba3169Ab6, 0x80b2B6ACBB2744859C04c7DA78373Dc62f523398, 0x670E1b5DC2dB6af9094dDEfB4D356BA2E60Aba8d, 0x35632b6976b5b6eC3F8D700FAbB7e1e0499C1BfA, 0xFeE16F131dB7B0d4cDb8dA3Be2AFB5e63A58c8a0, 0x6A316f344bDa31e6687173c97c839C7160dD2Cd1, 0xD26AFEa5C8fDf21c43ffE290BcCC6A46D978EF2f, 0xB810D1238dC5E5D664eBC5d19B0Fd2C28d42968D, 0x83e4a3D62d475e38DbE095B8e69f9A11860e5DCB, 0x67DaE9571396b01743C6C93E9f62527134117355, 0x6dd9c7deF4B5355121F479b6dcf1f68cEE608404, 0x14441AC732C0d8cf15f10043D355dA11c831d828, 0x66d12490943f18103E4634A6F8F7275Ce33B6876, 0x681Cbae1C41e5eeC8411dD8e009fA71F81D03F7F, 0x1D1F86dDd0F729154C6C87588f3c8ad740eE3385, 0x6282e24BAAAF04c984e8AE7CD0C763709743Cf9d, 0x5954A0627b5813E6Cb31087fa16728D81977e072, 0xf7200f7a475b53446A10421DEa95299fA9319A85, 0x3125840Ed73f65F4091E3Ad269AaA27f0Bc793C0, 0x962F171449D3dD573fFFf59d34cC80e9F87c0E76, 0xF052482E025a056146d903a8802d04e7328543F5, 0x5d54DBAc524Eed9FE4606F65fC0f069E704323a6, 0x78C89F607113fD12943b0a0D4f3AD15F19350557, 0xFCcb964C514C12794509ed62fa274f0E284ceE82, 0x5F3Cb118b93237b2b0EC7205EC43807e5D4D63e6, 0x4B4DF3B4c0A893C7BeefE72e1b8DAe7654ae6f47, 0xc563cC8B7a34Ca97E1159132549a000481122a1E, 0xED1A4812a6Efc061959045076ac088E5C5E4182a, 0x078ad2Aa3B4527e4996D087906B2a3DA51BbA122, 0x280A156f28488D38897074110588e3B5493Dfe79, 0xEdba5d56d0147aee8a227D284bcAaC03B4a87eD4, 0xED271cb525759A85910CC0518E126B80ccb66b46, 0x89b68CBA02637CfB1266f0DeCe2856B040b563C3, 0xB81E82cF70d5F5770734857529ED0fcD32EBD3fD, 0xc643C9411a6B489e9833b16631140F42bBfCb6d1, 0xb1c0813D37214886B63bB52b3e5e9c53A372F2C6, 0xde45Ac1DdB50D0c7DDb7ce66b3AF6A696AEc6035, 0xe275325f697201Ce25a257C0815e3fe04E72aF58, 0x7Cf67A1A486D5716517A989F180112ba26D1Afcf, 0x6eBD7c0d6D7B6bEa3F2Fd7767DC0e9992dc37Fe6, 0x09759c0Ccc5e9518C33B237B97177d8Bd86DD931, 0xb52E2dbf7f59adA1F56360Ab662041748650Ae06, 0x160e5B66f58924736B0a264f25ffd01e6732C39f, 0xDc9dcE81CB89db0C27C477204f272bBF3bBb2326];
    //Owners of Plezier
    address public winningAddress;
    uint public totalPigsAwarded = 1;

    constructor() 
        VRFConsumerBase(
            vrfCoordinator,
            linkToken
        ) public
    {
        contractOwner = msg.sender;
    }
    
    modifier onlyOwner() {
        require(msg.sender == contractOwner, "Only the owner of the contract may call this function.");
        _;
    }
    
    modifier contractAlive() {
        require(permanentlyStop == false, "The contract is no longer accepting VRF requests.");
        _;
    }
    
    modifier coordinatorAllowed() {
        require(coordinatorBlocked == false, "The VRF Coordinator is no longer allowed to call this function.");
        _;
    }
    
    function getRandomNumber() public onlyOwner contractAlive {
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK to pay the coordinator.");
        requestRandomness(keyHash, fee);
        permanentlyStop = true;
    }

    //When the Chainlink VRF Coordinator calls back with the random number the information is permanently stored in the variables since the contract is single use.
    function fulfillRandomness(bytes32 requestId, uint256 randomNumber) internal override coordinatorAllowed {
        require(msg.sender == vrfCoordinator, "Only the VRF Coordinator may call this function.");
        requestIDGenerated = requestId;
        //Take only the last 12 digits. It's enough to eliminate modulo bias.
        randomNumberGenerated = randomNumber % 10 ** 12 % addresses.length;
        winningAddress = addresses[randomNumberGenerated];
        coordinatorBlocked = true;
    }
}