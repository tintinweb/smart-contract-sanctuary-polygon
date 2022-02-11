//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";


contract Nugao  is VRFConsumerBase{


    uint constant N_UNITS = 6;      // Number of locations where units can be dispersed
    uint constant N_TURNS = 10;     // Number of turns the match has
    uint constant BOOST = 2;        // Additional boost when players units enter the opponnents domain
    uint constant LIMIT = 24;

    // Keeping track of the matches
    uint public matchCounter;
    mapping (uint => address[2]) public players;        // Players involved in the match
    mapping (uint => bytes32[2]) public commitments;    // Players' commitments
    mapping (uint => bool[2]) public revealed;          // Players have revealed their commitments
    mapping (uint => uint8[6][2]) public values;        // Players formation
    mapping (uint => address) public winner;            // Winner of the match
    mapping (uint => address) public cheater;           // Stores if someone has cheated

    // ChainLink related
    bytes32 internal keyHash;
    uint256 internal fee;
    mapping (uint => bytes32) public requestId;
    mapping (bytes32 => uint) randomResult;
    mapping (bytes32 => uint) public matchFromRequestId;

    constructor() VRFConsumerBase(
            0x8C7382F9D8f56b33781fE506E897a4F1e2d17255, // VRF Coordinator
            0x326C977E6efc84E512bB9C30f76E30c160eD06FB  // LINK Token
    ){
        keyHash = 0x6e75b569a01ef56d18cab6a8e71e6600d6ce853834d4a5748b720d06f878b3a4;
        fee = 0.0003 * 10 ** 18; 
    }

    /** 
     * Requests randomness 
     */
    function getRandomNumber() public returns (bytes32 requestId) {
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK - fill contract with faucet");
        return requestRandomness(keyHash, fee);
    }

    /**
     * Callback function used by VRF Coordinator
     */
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        randomResult[requestId] = randomness;
    }

    /** 
     * Starts a new match by providing the commitment message
     */
    function startMatch(bytes32 _commitment) public returns(uint){
        players[matchCounter][0] = msg.sender;
        commitments[matchCounter][0] = _commitment;
        matchCounter += 1;

        return matchCounter-1;
    }

    /** 
     * Joins a specific match 
     */
    function joinMatch(uint matchId, bytes32 _commitment) public {
        require(players[matchId][0] != address(0), "ERR: Match with that ID has not yet been started.");
        require(players[matchId][1] == address(0), "ERR: 2 players have already joined.");
        require(players[matchId][0] != msg.sender, "ERR: You cannot play with yourself.");

        players[matchId][1] = msg.sender;
        commitments[matchId][1] = _commitment;
    }


    function reveal(uint matchId, uint nonce, uint8[N_UNITS] memory _values) public {

        require(cheater[matchId] == address(0), "ERR: Your opponent has cheated!");

        uint playerId = _getSenderId(matchId, msg.sender);
        require(playerId < 2, "ERR: msg.sender is not in the match !");

        bytes32 d = digest(nonce, _values);
        require(commitments[matchId][playerId] == d, "ERR: Reveal doesn't correspond with the commit message.");

        uint sum = 0;
        for(uint8 i = 0; i < N_UNITS; ++i) {
            values[matchId][playerId][i] = _values[i];
            sum +=  _values[i];
        }

        cheater[matchId] = (sum <= LIMIT) ? address(0) : msg.sender;

        revealed[matchId][playerId] = true;

        if(cheater[matchId] == address(0)){

            uint otherPlayerId = (playerId == 0) ? 1 : 0;

            if(revealed[matchId][otherPlayerId] == true) { // game can be solved
                requestId[matchId] = getRandomNumber();
            }

        }

    }

    function resolveWinner(uint matchId) public {
        (address  _winner, , , , ) = playOut(matchId);
        winner[matchId] = _winner;
    }


    function playOut(uint matchId) public view returns(
        address _winner, 
        uint8[N_UNITS][N_TURNS] memory val1, 
        uint8[N_UNITS][N_TURNS] memory val2, 
        uint8[N_UNITS][N_TURNS] memory loy1, 
        uint8[N_UNITS][N_TURNS] memory loy2
    ) {

        require(revealed[matchId][0] == true && revealed[matchId][1] == true, "ERR: Both player have not yet revealed their formations.");

        require(randomResult[requestId[matchId]] != 0, "ERR: Randomness not yet fullfiled");

        for(uint j = 0; j < N_UNITS; ++j){
            val1[0][j] = values[matchId][0][j]; 
            val2[0][j] = values[matchId][1][j];
            loy1[0][j] = 0;
            loy2[0][j] = 1;
        }

        uint order; uint RNG = randomResult[requestId[matchId]];

        for(uint turn = 1; turn < N_TURNS; ++turn){

            order = (RNG >> turn) & 1;
            
            rotate(turn, order, val1, val2, loy1, loy2);

            hexRule(turn, order, val1, val2, loy1, loy2);

            triangleRule(turn, val1, val2, loy1, loy2);

        }
   
        uint sum1 = 0; 
        uint sum2 = 0;
        uint8 unit1; 
        uint8 unit2;
        for(uint i = 0; i < N_UNITS; ++i){
            unit1 = val1[N_TURNS-1][i]; unit2 = val2[N_TURNS-1][i]; 
            if(loy1[N_TURNS-1][i] == 0){ // player1 unit remained loyal
                sum1 += unit1;
            }else { // player2 has infiltred
                sum2 += BOOST*unit1;
            }
            if(loy2[N_TURNS-1][i] == 1){ // player2 unit remained loyal
                sum2 += unit2;
            }else { // player1 has infiltred
                sum1 += BOOST*unit1;
            }
        }
        _winner = (sum1 < sum2) ? players[matchId][1] : players[matchId][0];
    }

   function rotate(uint turn, uint whoRotates, 
        uint8[N_UNITS][N_TURNS] memory val1, 
        uint8[N_UNITS][N_TURNS] memory val2, 
        uint8[N_UNITS][N_TURNS] memory loy1, 
        uint8[N_UNITS][N_TURNS] memory loy2
    ) internal view {

        if(whoRotates == 0){ // player1 moves

            uint8 firstVal1 = val1[turn-1][N_UNITS-1];
            uint8 firstLoy1 = loy1[turn-1][N_UNITS-1];
            for(uint j = 0; j < N_UNITS-1; ++j){
                val1[turn][j+1] = val1[turn-1][j];
                loy1[turn][j+1] = loy1[turn-1][j];
            }val1[turn][0] = firstVal1;
            loy1[turn][0] = firstLoy1;

            for(uint j = 0; j < N_UNITS; ++j){
                val2[turn][j] = val2[turn-1][j];
                loy2[turn][j] = loy2[turn-1][j];
            }

        } else {  // player2 moves

            uint8 firstVal2 = val2[turn-1][0];
            uint8 firstLoy2 = loy2[turn-1][0];
            for(uint j = 0; j < N_UNITS-1; ++j){
                val2[turn][j] = val2[turn-1][j+1];
                loy2[turn][j] = loy2[turn-1][j+1];
            }val2[turn][N_UNITS-1] = firstVal2;
            loy2[turn][N_UNITS-1] = firstLoy2;

            for(uint j = 0; j < N_UNITS; ++j){
                val1[turn][j] = val1[turn-1][j];
                loy1[turn][j] = loy1[turn-1][j];
            }
        }
       
    }

   function hexRule(uint turn, uint whoAttacks, 
        uint8[N_UNITS][N_TURNS] memory val1, 
        uint8[N_UNITS][N_TURNS] memory val2, 
        uint8[N_UNITS][N_TURNS] memory loy1, 
        uint8[N_UNITS][N_TURNS] memory loy2
    ) internal view {

            // determine the value of the units
            uint8 unit1 = val1[turn][0]; 
            uint8 unit2 = val2[turn][0]; 

            if (loy1[turn][0] == loy2[turn][0]){ // units are on the same side
                // TODO: some increment ?
            } else { // attack

                if(whoAttacks == 0){ // player1 attacks
                    if(unit1 >= unit2){// moving to the enemy's Nugao
                        val2[turn][0] = unit1 / 2;
                        val1[turn][0] -= unit1 / 2;
                        loy2[turn][0] = 0; // loyalties have changed 
                    }else{ // does damage
                        val2[turn][0] -= unit1;
                    }
                } else { // player2 attacks
                    if(unit2 >= unit1){// moving to the enemy's Nugao
                        val1[turn][0] = unit2 / 2;
                        val2[turn][0] -= unit2 / 2;
                        loy1[turn][0] = 1; // loyalties have changed 
                    }else{ // does damage
                        val1[turn][0] -= unit2;
                    }
                }
            }
    }

    function triangleRule(uint turn,
        uint8[N_UNITS][N_TURNS] memory val1, 
        uint8[N_UNITS][N_TURNS] memory val2, 
        uint8[N_UNITS][N_TURNS] memory loy1, 
        uint8[N_UNITS][N_TURNS] memory loy2
    ) internal view {

        uint8[4] memory order = [0, 2, 4, 0];

        for(uint i = 0; i < order.length-1; i++){
            if(loy1[turn][order[i]] != loy1[turn][order[i+1]]) {
                if(val1[turn][order[i]] < val1[turn][order[i+1]]){
                    val1[turn][order[i]] = val1[turn][order[i+1]];
                    val1[turn][order[i+1]] = 0;
                    loy1[turn][order[i]] = loy1[turn][order[i+1]];
                }
            }
        }

        for(uint i = 0; i < order.length-1; i++){
            if(loy2[turn][order[i]] != loy2[turn][order[i+1]]) {
                if(val2[turn][order[i]] < val2[turn][order[i+1]]){
                    val2[turn][order[i]] = val2[turn][order[i+1]];
                    val2[turn][order[i+1]] = 0;
                    loy2[turn][order[i]] = loy2[turn][order[i+1]];
                }
            }
        }

    }


    function _getSenderId (uint matchId, address sender) internal returns (uint) {
        uint id = 3;
        if(sender == players[matchId][0]) id = 0;
        else if (sender == players[matchId][1]) id = 1;
        return id;
    }

    function getPlayers(uint matchId) public view returns (address [2] memory){
        return players[matchId];
    }

    function getCommitments(uint matchId) public view returns (bytes32 [2] memory){
        return commitments[matchId];
    }

    function getValues(uint matchId) public view returns (uint8 [N_UNITS][2] memory){
        return values[matchId];
    }

    function getWinner(uint matchId) public view returns (address) {
        return winner[matchId];
    }

    function getCheater(uint matchId) public view returns (address) {
        return cheater[matchId];
    }

    function getScore(address player) public view returns (uint winCount, uint notYetResolved, uint total){

        for(uint matchId = 0; matchId < matchCounter; ++matchId){
            total += (players[matchId][0] == player || players[matchId][1] == player) ? 1 : 0; 
            if(revealed[matchId][0] == true && revealed[matchId][1] == true && randomResult[requestId[matchId]] != 0){
                (address _winner, , , , ) = playOut(matchId);
                winCount += ( _winner == player) ? 1 : 0;
            }
            notYetResolved += (randomResult[requestId[matchId]] == 0) ? 1 : 0;
        }

    }

    function getRandomResult(uint matchId) public view returns (uint){
        return randomResult[requestId[matchId]];
    }

    function digest(uint nonce, uint8[6] memory values) public pure returns (bytes32) {
         return keccak256(abi.encodePacked(nonce, values[0], values[1], values[2], values[3], values[4], values[5]));
    }


}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/LinkTokenInterface.sol";

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

// SPDX-License-Identifier: MIT
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