/**
 *Submitted for verification at polygonscan.com on 2021-07-29
*/

// File: @chainlink/contracts/src/v0.6/VRFRequestIDBase.sol

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

// File: contracts/cryptobattle.sol

// DEPLOYED AT   0xc7Ebc040D98eD005E7F2C7ab5561a70aFc4Bc426
// OWNER         0xC42127d568FD8ab865D0b05628ADC372b419f244

pragma solidity 0.6.6;


//
//   Play CryptoBattle visit https://cryptobattle.me
//

contract Cryptobattle is VRFConsumerBase {
   
 //UPDATE CHANLINK VRF STUFF  
   
   event placeBetEvent(address indexed _pA, uint256 _pV);
   event payoutEvent(address indexed _pA, uint256 _pV);
   
    //Chainlink vrf
    bytes32 internal keyHash;
   
    //Bets & Chailink fee
   uint256 private betS = 1*10**18;
   uint256 private betM = 2*10**18;
   uint256 private betL = 4*10**18;
   uint256 internal linkFee = 0.0001*10**18;
   uint256 private basePercent = 10;
   uint256 private contractUpkeep = 0;
   uint256 public totalWinningsPaid = 0;
   
   address private owner;
   bool private checksPassed = false;
  
   struct Bet{
    uint256 bet1;
    uint256 tie1;
    uint256 bet2;
    uint256 tie2;
    uint256 tPBV;
  }
  
   struct gameResult{
    bool chainUpdated;
    bool cControl;
    uint8 cFlag;
    uint8 dealer_card;
    uint8 dealer_tie_card1;
    uint8 dealer_tie_card2;
    uint8 bet1_card;
    uint8 tie1_card;
    uint8 bet2_card;
    uint8 tie2_card;
  }
  
  mapping(address => Bet) private bets;
  mapping(address => gameResult) private gameresult;
  mapping(bytes32 => address) private chainmapping;
  
  
     
  constructor() VRFConsumerBase(
            0x3d2341ADb2D31f1c5530cDC622016af293177AE0, // VRF Coordinator
            0xb0897686c545045aFc77CF20eC7A532E3120E0F1  // LINK Token
        ) public
    {
        owner = msg.sender;
        keyHash = 0xf86195cf7690c55907b2b611ebb7343a6f649bff128701cc542f0569e2c549da;
        linkFee;
    }     



  modifier onlyOwner(){
            require(msg.sender == owner);
            _;
        }
        
        
        
  modifier RLock(){
      bool Rlock = false;
            require(!Rlock);
            Rlock = true;
            _;
            Rlock = false;
        }        
    
    
       
     function viewCardsDealt(address _pA) public view returns (uint8[8] memory gameCards) {
          return gameCards = [gameresult[_pA].dealer_card,
                    gameresult[_pA].dealer_tie_card1,
                    gameresult[_pA].dealer_tie_card2,
                    gameresult[_pA].bet1_card,
                    gameresult[_pA].tie1_card,
                    gameresult[_pA].bet2_card,
                    gameresult[_pA].tie2_card,
                    gameresult[_pA].cFlag];
    }     
        
             

   function getRandomNumber() private returns (bytes32 requestId) {
         require(LINK.balanceOf(address(this)) >= linkFee, "Not enough LINK");
         return requestRandomness(keyHash, linkFee);
     }     



   function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
       require(msg.sender == 0x3d2341ADb2D31f1c5530cDC622016af293177AE0);
       address pA = chainmapping[requestId];
       
       gameresult[pA].dealer_card = uint8(uint256(keccak256(abi.encode(randomness, 1))).mod(13).add(2));
       gameresult[pA].dealer_tie_card1 = uint8(uint256(keccak256(abi.encode(randomness, 2))).mod(13).add(2));
       gameresult[pA].dealer_tie_card2 = uint8(uint256(keccak256(abi.encode(randomness, 3))).mod(13).add(2));
       gameresult[pA].bet1_card = uint8(uint256(keccak256(abi.encode(randomness, 4))).mod(13).add(2));
       gameresult[pA].tie1_card = uint8(uint256(keccak256(abi.encode(randomness, 5))).mod(13).add(2));
       gameresult[pA].bet2_card = uint8(uint256(keccak256(abi.encode(randomness, 6))).mod(13).add(2));
       gameresult[pA].tie2_card = uint8(uint256(keccak256(abi.encode(randomness, 7))).mod(13).add(2));
       gameresult[pA].cFlag = 1;
       gameresult[pA].chainUpdated = true;
       
       determineWinner(gameresult[pA].dealer_card, gameresult[pA].dealer_tie_card1, gameresult[pA].dealer_tie_card2, gameresult[pA].bet1_card, gameresult[pA].tie1_card, gameresult[pA].bet2_card, gameresult[pA].tie2_card, pA);
    }   
      
      

  function updateBetBaseValue(uint256 _betS, uint256 _betM, uint256 _betL, uint256 _fee, uint256 _basePercent) public onlyOwner {
      betS = _betS;
      betM = _betM;
      betL = _betL;
      linkFee = _fee;
      basePercent = _basePercent;
  }



  function receiveBet(uint256 _bet1, uint256 _tie1, uint256 _bet2, uint256 _tie2) payable public{
      address pA = msg.sender;
      uint256 pV = msg.value;
      require(checkInput(_bet1, _tie1, _bet2, _tie2, pV));
      gameresult[pA].chainUpdated = false;
      gameresult[pA].cControl = false;
      gameresult[pA].cFlag = 0;
      bets[pA] = Bet(_bet1, _tie1, _bet2, _tie2, bets[pA].tPBV.add(pV));
      bytes32 requestId = getRandomNumber();
      chainmapping[requestId] = pA;
      emit placeBetEvent(pA, pV);
  }
  
  
  
  function determineWinner(uint8 _dealer_card, uint8 _dealer_tie_card1, uint8 _dealer_tie_card2, uint8 _bet1_card, uint8 _tie1_card, uint8 _bet2_card, uint8 _tie2_card, address _pA) private {
      uint256 bet1_value = bets[_pA].bet1;
      uint256 tie1_value = bets[_pA].tie1;
      uint256 bet2_value = bets[_pA].bet2;
      uint256 tie2_value = bets[_pA].tie2;

    if (bet1_value != 0){
            if (_dealer_card != _bet1_card){
                bets[_pA].tPBV = _dealer_card > _bet1_card ? bets[_pA].tPBV.sub(bet1_value) : bets[_pA].tPBV.add(bet1_value);
                }else{
                    if (tie1_value != 0){
                        if (_dealer_tie_card1 != _tie1_card){                                                                                
                            bets[_pA].tPBV = _dealer_tie_card1 > _tie1_card ? bets[_pA].tPBV.sub(bet1_value.mul(2)) : bets[_pA].tPBV.add(bet1_value);
                            }else{
                                bets[_pA].tPBV = bets[_pA].tPBV.add(bet1_value.mul(2));
                                }
                    }else{
                        bets[_pA].tPBV = bets[_pA].tPBV.sub(bet1_value.div(2));
                        }
                    }
                }
        if (bet2_value != 0){
            if (_dealer_card != _bet2_card){
                bets[_pA].tPBV = _dealer_card > _bet2_card ? bets[_pA].tPBV.sub(bet2_value) : bets[_pA].tPBV.add(bet2_value);
                }else{
                    if (tie2_value != 0){
                        if (_dealer_tie_card2 != _tie2_card){
                            bets[_pA].tPBV = _dealer_tie_card2 > _tie2_card ? bets[_pA].tPBV.sub(bet2_value.mul(2)) : bets[_pA].tPBV.add(bet2_value);
                            }else{
                                bets[_pA].tPBV = bets[_pA].tPBV.add(bet2_value.mul(2));
                                }
                    }else{
                        bets[_pA].tPBV = bets[_pA].tPBV.sub(bet2_value.div(2));
                        }
                    }
                }
      bets[_pA].bet1 = 0;
      bets[_pA].bet2 = 0;
      bets[_pA].tie1 = 0;
      bets[_pA].tie2 = 0;
      gameresult[_pA].cControl = true;
    }
    
    
    
    function showPlayerBalance(address _pA) public view returns (uint256 _balance) {
      return bets[_pA].tPBV;
    }
    


    function checkInput(uint256 _bet1, uint256 _tie1, uint256 _bet2, uint256 _tie2, uint256 _pV) private returns (bool _check) {
      uint256 ibetS = betS;
      uint256 ibetM = betM;
      uint256 ibetL = betL;
      require(_bet1 == 0 || _bet1 == ibetS || _bet1 == ibetM || _bet1 == ibetL);
      require(_bet2 == 0 || _bet2 == ibetS || _bet2 == ibetM || _bet2 == ibetL);
      require(_tie1 == 0 || _tie1 == ibetS || _tie1 == ibetM || _tie1 == ibetL);
      require(_tie2 == 0 || _tie2 == ibetS || _tie2 == ibetM || _tie2 == ibetL);
      require(_bet1.add(_bet2) + _tie1.add(_tie2) == _pV);
      require(_pV != 0 && address(this).balance >= _bet1.add(_bet2));
      if (_bet1 == 0) require(_tie1 == 0); else if (_tie1 != 0) require(_bet1 == _tie1);
      if (_bet2 == 0) require(_tie2 == 0); else if (_tie2 != 0) require(_bet2 == _tie2);
      checksPassed = true;
      return checksPassed;
    }
  
  
  
  function calculateFee(uint256 p_Value) private view returns (uint256){
      uint256 calcFee = p_Value.mul(basePercent).div(100);
      return calcFee;
  }



  function showUpkeep() public onlyOwner view returns (uint256){
      return contractUpkeep;
  }



  function payoutWinnings() public RLock(){
        address pA = msg.sender;
        require(gameresult[pA].chainUpdated && gameresult[pA].cControl);
        uint256 winningAmount = bets[pA].tPBV;
        require(winningAmount != 0);
        require(address(this).balance >= winningAmount);
        bets[pA].tPBV = 0;
        require(cleanUp(pA));
        totalWinningsPaid = totalWinningsPaid.add(winningAmount);
        uint256 contractFee = calculateFee(winningAmount);
        contractUpkeep = contractUpkeep.add(contractFee);
        winningAmount = winningAmount.sub(contractFee);
        payable(pA).transfer(winningAmount);
        emit payoutEvent(pA, winningAmount);
    }
    
    
    
    function cleanUp(address _pA) private returns(bool) {
         gameresult[_pA].cControl = false;
         gameresult[_pA].chainUpdated = false;
         gameresult[_pA].cFlag = 0;
         gameresult[_pA].dealer_card = 0;
         gameresult[_pA].dealer_tie_card1 = 0;
         gameresult[_pA].dealer_tie_card2 = 0;
         gameresult[_pA].bet1_card = 0;
         gameresult[_pA].tie1_card = 0;
         gameresult[_pA].bet2_card = 0;
         gameresult[_pA].tie2_card = 0;
         return true;
    }
        
      
        
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
		assert(b <= a);
		return a - b;
	}
	
	
	
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
		c = a + b;
		assert(c >= a);
		return c;
	}
	
	
    
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
		uint256 c = a / b;
		return c;
	}
	
	
	
	function mul(uint256 a, uint256 b) internal pure returns (uint256) {
		uint256 c = a * b;
		assert(a == 0 || c / a == b);
		return c;
	}
	
	
    
    function ownerWithdraw(uint _amount) public onlyOwner{
        require(address(this).balance != 0);
        payable(msg.sender).transfer(_amount);
    }
    
    
    
    
  function showContractBalance() public view returns (uint256 _balance) {
      return address(this).balance;
    }
    
    
    
  function withdrawLink() public onlyOwner {
        require(LINK.transfer(msg.sender, LINK.balanceOf(address(this))));
    }



fallback() external payable {}


}