/**
 *Submitted for verification at polygonscan.com on 2022-01-23
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
}

// File: @chainlink/contracts/src/v0.8/VRFRequestIDBase.sol



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


contract LotteryContract is VRFConsumerBase {
    
    string private contractName = "Lottery Contract";

    // Start: Configration for game
    uint256 private totalTickets = 2000; // total tickets in one round
    uint256 private oneTicketPrice = 10*10**18; // 1 usdt     
    // End: Configration for game

    // Start:
    uint256 private CurrentGameCount; // which game round is currently going on
    mapping(uint256 => uint256) private totalTicketOfGame; // gamecount => how many tickets  sold (only) (like 1,2,3,4...)

    bool private canPlayerBuyTicket;

    mapping(uint256 => address[]) private playersOfGame; // gamecount => players in the game

    mapping(address => mapping(uint256 =>uint256[]))
        private ticketsOfUserInGame; // owner=>(gamecount=>tickets)

    mapping(uint256 => mapping(uint256 => address)) private inGameOwnerOfTicket; // gamecount=>(ticket=>owner)

    // can't see anyone
    mapping(uint256 => uint256) private private_random_variable_forgame; // gamecount=>random variable for this game and this will private

    struct WinnerPlayers {
        address Player1;
        address Player2;
        address Player3;
        uint256 TotalTickets;
        uint256 Time;
    }
    mapping(uint256 => WinnerPlayers) private winnerJakpotPlayerOfGame;
    mapping(uint256 => address[]) private consulationWinnersOfGame;

    mapping(uint256 => mapping(address=>uint256)) public playerRefferalCountOfGame; // gamecount => (user=>totalReferral) 
    mapping(uint256 => address[]) private playersThatRefferInGame; // gamecount => totalplayers who refer more than 0 players

    struct RefferalWinner {
        uint256 TotalRefferals;
        address  User;
    }
    mapping(uint256 => RefferalWinner[]) private RefferalWinnersShorted; // gamecount => shortedWinners high to low


    // config for admin
    address private admin;

    address private adminWallet1;
    address private adminWallet2;
    address private adminWallet3;
    address private adminWallet4;
    address private adminWallet5;
    address private adminWallet6;

    IERC20 private tokenContract;
    address private tokenAddress = 0x3D20464Caa82E29a2Ff54206Fec6d98178881853;

    bytes32 internal keyHash = 0x6e75b569a01ef56d18cab6a8e71e6600d6ce853834d4a5748b720d06f878b3a4;
    uint256 internal fee = 0.0001 * 10 ** 18;

    constructor()
        VRFConsumerBase(
            0x8C7382F9D8f56b33781fE506E897a4F1e2d17255, // VRF Coordinator
            0x326C977E6efc84E512bB9C30f76E30c160eD06FB  // LINK Token
        )
    {
        admin = msg.sender;
        CurrentGameCount = 1;
        canPlayerBuyTicket = true;

        tokenContract = IERC20(tokenAddress);
    }
    
    
    modifier onlyAdmin() {
        require(msg.sender == admin, "This function only owner can call");
        _;
    }

    modifier onlyWhenGameIsGoingOn() {
        require(
            canPlayerBuyTicket == true,
            "Game will start soon... Please try again."
        );
        _;
    }


    function buyTicket(uint256 quantity) public  onlyWhenGameIsGoingOn  {

        require(tokenContract.allowance(msg.sender,address(this)) >= oneTicketPrice * quantity,"Allow tokens to spend");
        require(tokenContract.transferFrom(msg.sender,address(this), oneTicketPrice*quantity),"Please pay full fee");
        require(totalTicketOfGame[CurrentGameCount] + quantity-1 < totalTickets,"This amount of tickets are not available for this round");

        for(uint256 i = 0; i < quantity;i++){
            _buyTicket_withWithout_refferal();
        }
    }

    function buyTicketUsingReferral(address _referral, uint256 quantity)
        public
        onlyWhenGameIsGoingOn
    {
        require(tokenContract.allowance(msg.sender,address(this)) >= oneTicketPrice * quantity,"Allow tokens to spend");
        require(tokenContract.transferFrom(msg.sender,address(this), oneTicketPrice * quantity),"Please pay full fee");
        require(totalTicketOfGame[CurrentGameCount] + quantity < totalTickets,"This amount of tickets are not available for this round");

        for(uint256 i = 0; i < quantity ;i++){
            // send ticket to who refer this guy
            if(_referral != msg.sender){
                if (isPlayerAddressAdded(_referral)) { // referral must buy alest one ticket
                    playerRefferalCountOfGame[CurrentGameCount][_referral] += 1;
                    if(!isReferPlayerAdded(_referral)){
                        playersThatRefferInGame[CurrentGameCount].push(_referral);
                    }
                }
            }
            _buyTicket_withWithout_refferal();
        }
    }

    function _buyTicket_withWithout_refferal() private {
        if (!isPlayerAddressAdded(msg.sender)) {
            playersOfGame[CurrentGameCount].push(msg.sender);
        }

        if (totalTicketOfGame[CurrentGameCount] == 1) {
            getRandomNumberChainlink();
        }

        totalTicketOfGame[CurrentGameCount] += 1;

        ticketsOfUserInGame[msg.sender][CurrentGameCount].push(totalTicketOfGame[CurrentGameCount]);

        inGameOwnerOfTicket[CurrentGameCount][
            totalTicketOfGame[CurrentGameCount]
        ] = msg.sender;


        if (totalTicketOfGame[CurrentGameCount] >= totalTickets) {
            // stop game, find winner, transfer money and start game again
            canPlayerBuyTicket = false;
            _findRandomVariablesAndWinners();
        }
    }


    function getRandomNumberChainlink() private returns (bytes32 requestId) {
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK - fill contract with faucet");
        return requestRandomness(keyHash, fee);
    } 
    // function getRandomNumberChainlink() private {
    //     private_random_variable_forgame[CurrentGameCount] = block.timestamp;
    // }


    /**
     * Callback function used by VRF Coordinator
     */
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        private_random_variable_forgame[CurrentGameCount] = randomness;

    }


    function _findRandomVariablesAndWinners() private {
        uint256 _firstRandomVariable = private_random_variable_forgame[
            CurrentGameCount
        ];

        uint256 _firstWinnerTicket = (_firstRandomVariable %
            totalTicketOfGame[CurrentGameCount]) + 1;
        address _firstWinner = inGameOwnerOfTicket[CurrentGameCount][
            _firstWinnerTicket
        ];

        //selecting secound winner
        bool runLoop = true;
        uint256 _secoundRandomVariable;
        uint256 _secoundWinnerTicket;
        address _secoundWinner;

        if(playersOfGame[CurrentGameCount].length > 1 ){
            for (uint256 i = 1; runLoop; i++) {
                _secoundRandomVariable = _firstRandomVariable / 2 + i;
                _secoundWinnerTicket =
                    (_secoundRandomVariable % totalTicketOfGame[CurrentGameCount]) +
                    1;
                _secoundWinner = inGameOwnerOfTicket[CurrentGameCount][
                    _secoundWinnerTicket
                ];
                if (_firstWinner != _secoundWinner) {
                    runLoop = false;
                }
            }
        } else{
            _secoundWinner = address(0);
        }

            //selecting third winner
            bool runLoop3 = true;
            uint256 _thirdRandomVariable;
            uint256 _thirdWinnerTicket;
            address _thirdWinner;

        if(playersOfGame[CurrentGameCount].length > 2 ){
            for (uint256 i = 1; runLoop3; i++) {
                _thirdRandomVariable = _secoundRandomVariable / 2 + i;
                _thirdWinnerTicket =
                    (_thirdRandomVariable % totalTicketOfGame[CurrentGameCount]) +
                    1;
                _thirdWinner = inGameOwnerOfTicket[CurrentGameCount][
                    _thirdWinnerTicket
                ];
                if (_firstWinner != _thirdWinner &&  _secoundWinner != _thirdWinner) {
                    runLoop3 = false;
                }
            }

        } else {
            _thirdWinner = address(0);
        }


        winnerJakpotPlayerOfGame[CurrentGameCount] = WinnerPlayers(
            _firstWinner,
            _secoundWinner,
            _thirdWinner,
            totalTicketOfGame[CurrentGameCount],
            block.timestamp
        );


        sendMoneyTo(_firstWinner,6000); //$6000 for 
        sendMoneyTo(_secoundWinner,4000); //$4000 for 
        sendMoneyTo(_thirdWinner,2000); //$2000 for 

        // consulation price
        if(playersOfGame[CurrentGameCount].length > 3 ){
            uint256 _randomVarForConPrice = _firstRandomVariable % playersOfGame[CurrentGameCount].length;

            uint256 _totalPayerForCol = 15;
            if(playersOfGame[CurrentGameCount].length - 3 < _totalPayerForCol){
                _totalPayerForCol = playersOfGame[CurrentGameCount].length - 3;
            }

            for(uint256 i = 0; consulationWinnersOfGame[CurrentGameCount].length <= _totalPayerForCol; i++) {
                if(playersOfGame[CurrentGameCount][_randomVarForConPrice + i] != _firstWinner
                 && playersOfGame[CurrentGameCount][_randomVarForConPrice + i] != _secoundWinner && 
                 playersOfGame[CurrentGameCount][_randomVarForConPrice + i] != _thirdWinner ){
                    consulationWinnersOfGame[CurrentGameCount].push(playersOfGame[CurrentGameCount][_randomVarForConPrice + i]);
                }
                if(_randomVarForConPrice + i + 1 >= consulationWinnersOfGame[CurrentGameCount].length){
                    i = 1;
                    _randomVarForConPrice = 0;
                }
            }

            // send money to col players
            for(uint256 i=0; i < consulationWinnersOfGame[CurrentGameCount].length; i++){
                address _playerAddress = consulationWinnersOfGame[CurrentGameCount][i];
                    if(i < 5){
                        sendMoneyTo(_playerAddress,200); //$200 for 
                            
                    }else if (i < _totalPayerForCol){
                        sendMoneyTo(_playerAddress,100); //$100 for        
                }
            }

        }


        // Send money to refferal users

        RefferalWinner[] memory _referalWinnersTemp = new RefferalWinner[](playersThatRefferInGame[CurrentGameCount].length);

        for(uint256 i = 0; i < playersThatRefferInGame[CurrentGameCount].length;i++){
            address _user = playersThatRefferInGame[CurrentGameCount][i];
            uint256 _totalRef = playerRefferalCountOfGame[CurrentGameCount][_user];
            
            _referalWinnersTemp[i] = RefferalWinner(_totalRef,_user);
        }
        
        
        RefferalWinner[] memory _referalWinnersShorted = getShoetedWinnersArray(_referalWinnersTemp);
        for(uint256 i = 0; i < _referalWinnersShorted.length;i++){
            RefferalWinnersShorted[CurrentGameCount].push(_referalWinnersShorted[i]);
        }


        //sending money to refferals 
        for(uint256 i = 0; i < RefferalWinnersShorted[CurrentGameCount].length;i++){
            address _user = RefferalWinnersShorted[CurrentGameCount][i].User;
            // uint256 _totalRef = RefferalWinnersShorted[CurrentGameCount][i].TotalRefferals;

            if( i < 1){
                sendMoneyTo(_user,300); //$300 for 
            } else if( i < 2){
                sendMoneyTo(_user,250); //$250 for
            } else if( i < 3){
                sendMoneyTo(_user,200); //$200 for
            }
            else if( i < 8){
                sendMoneyTo(_user,150); //$150 for
            } else if( i < 18){
                sendMoneyTo(_user,50);  //$50 for              
            }

        }
        // send money to team
            sendMoneyTo(adminWallet1,2000); 
            sendMoneyTo(adminWallet2,800);
            sendMoneyTo(adminWallet3,400);
            sendMoneyTo(adminWallet4,400);
            sendMoneyTo(adminWallet5,200);
            sendMoneyTo(adminWallet6,200);
            
        // start new game
        canPlayerBuyTicket = true;
        CurrentGameCount += 1;
    }


    function sendMoneyTo(address _to, uint256 _amount) private returns(bool) {
        if(address(0) != _to){
        // (bool os, ) = payable(_to).call{value: }("");
        require(tokenContract.transfer(_to,_amount*10**18),"Send Money to users");
        }

        return true;
    }

    function getShoetedWinnersArray(RefferalWinner[] memory arr_) private pure returns (RefferalWinner[] memory )
    {
        uint256 l = arr_.length;
        RefferalWinner[] memory arr = new RefferalWinner[] (l);

        for(uint256 i=0;i<l;i++)
        {
            arr[i] = arr_[i];
        }

        for(uint256 i=0;i<l;i++)
        {
            for(uint256 j=i+1;j<l;j++)
            {
                if(arr[i].TotalRefferals<arr[j].TotalRefferals)
                {
                    RefferalWinner memory temp= arr[j];
                    arr[j]=arr[i];
                    arr[i] = temp;

                }

            }
        }
        return arr;
    }

    // Start: Helping functions
    function isPlayerAddressAdded(address _player) private view returns (bool) {
        for (uint256 i = 0; i < playersOfGame[CurrentGameCount].length; i++) {
            if (playersOfGame[CurrentGameCount][i] == _player) {
                return true;
            }
        }
        return false;
    }

    function isReferPlayerAdded(address _player) private view returns (bool) {
        for (uint256 i = 0; i < playersThatRefferInGame[CurrentGameCount].length; i++) {
            if (playersThatRefferInGame[CurrentGameCount][i] == _player) {
                return true;
            }
        }
        return false;
    }

    

    function all_players_are_not_same() private view returns (bool) {
        if (1 < playersOfGame[CurrentGameCount].length) {
            address _oneAddress = playersOfGame[CurrentGameCount][0];
            for (
                uint256 i = 1;
                i < playersOfGame[CurrentGameCount].length;
                i++
            ) {
                if (playersOfGame[CurrentGameCount][i] != _oneAddress) {
                    return true;
                }
            }
        }
        return false;
    }

    // End: Helping functions

    // *********Start: Admin Functions

    function isAdmin() public view returns (bool) {
        if (msg.sender == admin) {
            return true;
        } else {
            return false;
        }
    }

    function knowAdminBalance() public view onlyAdmin returns (uint256) {
        return address(this).balance;
    }

    function withdrawAdminBalance(address payable _owner, uint256 _amount)
        public
        onlyAdmin
        returns (bool)
    {
        (bool sent, ) = _owner.call{value: _amount}("");

        return sent;
    }

    function changeAdmin(address _newAdmin) public onlyAdmin {
        admin = _newAdmin;
    }

    function knowAdminBalanceOfToken(IERC20 _tokenAddress)
        public
        view
        onlyAdmin
        returns (uint256)
    {
        return _tokenAddress.balanceOf(address(this));
    }

    function withdrawAdminBalanceOfToken(
        IERC20 _tokenAddress,
        address payable _owner,
        uint256 _amount
    ) public onlyAdmin {
        _tokenAddress.transfer(_owner, _amount);
    }

    function changeTokenAddress(IERC20 _new) public onlyAdmin {
        tokenContract = _new;
    }
    
    function knowAdminBalanceOfToken()
        public
        view
        returns (uint256)
    {
        return tokenContract.allowance(msg.sender,address(this));
    }

    // *********End: Admin Functions

    // Functions for get data

    // --start: Configration for game


    function getTotalTickets() public view returns (uint256) {
        return totalTickets;
    }

    function getOneTicketPrice() public view returns (uint256) {
        return oneTicketPrice;
    }

    // --End: Configration for game

    //

    function getCurrentGameCount() public view returns (uint256) {
        return CurrentGameCount;
    }

    function getCanPlayerBuyTicket() public view returns (bool) {
        return canPlayerBuyTicket;
    }

    function gettotalTicketOfGame(uint256 _gamecount)
        public
        view
        returns (uint256)
    {
        return totalTicketOfGame[_gamecount];
    }


    function getAllTicketsOfUserInGame(address _user, uint256 _gamecount)
        public
        view
        returns (uint256[] memory)
    {
        return ticketsOfUserInGame[_user][_gamecount];
    }

    function getInGameOwnerOfTicket(uint256 _gamecount, uint256 _ticket)
        public
        view
        returns (address)
    {
        return inGameOwnerOfTicket[_gamecount][_ticket];
    }

    function getWinnerJakpotPlayerOfGame(uint256 _gamecount)
        public
        view
        returns (WinnerPlayers memory)
    {
        return winnerJakpotPlayerOfGame[_gamecount];
    }

    function getRefferalWinnersShorted(uint256 _gamecount)
        public
        view
        returns (RefferalWinner[] memory)
    {
        return RefferalWinnersShorted[_gamecount];
    }

    function getConsulationWinnersOfGame(uint256 _gamecount)
        public
        view
        returns (address[] memory)
    {
        return consulationWinnersOfGame[_gamecount];
    }          
}