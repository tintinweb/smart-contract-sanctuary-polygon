/**
 *Submitted for verification at polygonscan.com on 2023-06-24
*/

//SPDX-License-Identifier: Unlicense
//CAUTION: NOT AUDITED, NO GUARANTEES OF PERFORMANCE

/*******************************************
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~ ROULETTE ~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
--------------------------------------------
      3 6 9 12 15 18 21 24 27 30 33 36
    0 2 5 8 11 14 17 20 23 26 29 32 35
      1 4 7 10 13 16 19 22 25 28 31 34
--------------------------------------------
 <Even|Odd> ~~ <Black|Red> ~~ <1st|2nd> ~~ <1st|2nd|3rd>
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
*******************************************/

/*** @notice on-chain roulette using API3/ANU quantum random numbers.
 *** Immutable after deployment except for setRequestParameters().
 *** CAUTION: NOT AUDITED, NO GUARANTEES OR WARRANTIES PROVIDED WHATSOEVER.
 *** Only supports one bet (single number, black/red, even/odd, 1st/2nd or 1st/2nd/3rd of board) per spin.
 *** User places bet by calling applicable payable function, then calls spinRouletteWheel(),
 *** then calls checkIf[BetType]Won() after QRNG airnode responds with spinResult for user
 *** following the applicable chain's minimum confirmations (25 for Optimism)
 *** hardcoded minimum bet of .001 ETH to prevent spam of sponsorWallet, winnings paid from this contract **/
/// @dev https://github.com/api3dao/qrng-example/blob/main/contracts/QrngExample.sol
/// @title Roulette
/// Roulette odds should prevent the casino (this contract) and sponsorWallet from bankruptcy, but anyone can refill by sending ETH directly to address

pragma solidity >=0.8.4;

interface IAuthorizationUtilsV0 {
  function checkAuthorizationStatus(
    address[] calldata authorizers,
    address airnode,
    bytes32 requestId,
    bytes32 endpointId,
    address sponsor,
    address requester
  ) external view returns (bool status);

  function checkAuthorizationStatuses(
    address[] calldata authorizers,
    address airnode,
    bytes32[] calldata requestIds,
    bytes32[] calldata endpointIds,
    address[] calldata sponsors,
    address[] calldata requesters
  ) external view returns (bool[] memory statuses);
}

interface ITemplateUtilsV0 {
  event CreatedTemplate(bytes32 indexed templateId, address airnode, bytes32 endpointId, bytes parameters);

  function createTemplate(
    address airnode,
    bytes32 endpointId,
    bytes calldata parameters
  ) external returns (bytes32 templateId);

  function getTemplates(
    bytes32[] calldata templateIds
  ) external view returns (address[] memory airnodes, bytes32[] memory endpointIds, bytes[] memory parameters);

  function templates(
    bytes32 templateId
  ) external view returns (address airnode, bytes32 endpointId, bytes memory parameters);
}

interface IWithdrawalUtilsV0 {
  event RequestedWithdrawal(
    address indexed airnode,
    address indexed sponsor,
    bytes32 indexed withdrawalRequestId,
    address sponsorWallet
  );

  event FulfilledWithdrawal(
    address indexed airnode,
    address indexed sponsor,
    bytes32 indexed withdrawalRequestId,
    address sponsorWallet,
    uint256 amount
  );

  function requestWithdrawal(address airnode, address sponsorWallet) external;

  function fulfillWithdrawal(bytes32 withdrawalRequestId, address airnode, address sponsor) external payable;

  function sponsorToWithdrawalRequestCount(address sponsor) external view returns (uint256 withdrawalRequestCount);
}

interface IAirnodeRrpV0 is IAuthorizationUtilsV0, ITemplateUtilsV0, IWithdrawalUtilsV0 {
  event SetSponsorshipStatus(address indexed sponsor, address indexed requester, bool sponsorshipStatus);

  event MadeTemplateRequest(
    address indexed airnode,
    bytes32 indexed requestId,
    uint256 requesterRequestCount,
    uint256 chainId,
    address requester,
    bytes32 templateId,
    address sponsor,
    address sponsorWallet,
    address fulfillAddress,
    bytes4 fulfillFunctionId,
    bytes parameters
  );

  event MadeFullRequest(
    address indexed airnode,
    bytes32 indexed requestId,
    uint256 requesterRequestCount,
    uint256 chainId,
    address requester,
    bytes32 endpointId,
    address sponsor,
    address sponsorWallet,
    address fulfillAddress,
    bytes4 fulfillFunctionId,
    bytes parameters
  );

  event FulfilledRequest(address indexed airnode, bytes32 indexed requestId, bytes data);

  event FailedRequest(address indexed airnode, bytes32 indexed requestId, string errorMessage);

  function setSponsorshipStatus(address requester, bool sponsorshipStatus) external;

  function makeTemplateRequest(
    bytes32 templateId,
    address sponsor,
    address sponsorWallet,
    address fulfillAddress,
    bytes4 fulfillFunctionId,
    bytes calldata parameters
  ) external returns (bytes32 requestId);

  function makeFullRequest(
    address airnode,
    bytes32 endpointId,
    address sponsor,
    address sponsorWallet,
    address fulfillAddress,
    bytes4 fulfillFunctionId,
    bytes calldata parameters
  ) external returns (bytes32 requestId);

  function fulfill(
    bytes32 requestId,
    address airnode,
    address fulfillAddress,
    bytes4 fulfillFunctionId,
    bytes calldata data,
    bytes calldata signature
  ) external returns (bool callSuccess, bytes memory callData);

  function fail(
    bytes32 requestId,
    address airnode,
    address fulfillAddress,
    bytes4 fulfillFunctionId,
    string calldata errorMessage
  ) external;

  function sponsorToRequesterToSponsorshipStatus(
    address sponsor,
    address requester
  ) external view returns (bool sponsorshipStatus);

  function requesterToRequestCountPlusOne(address requester) external view returns (uint256 requestCountPlusOne);

  function requestIsAwaitingFulfillment(bytes32 requestId) external view returns (bool isAwaitingFulfillment);
}

/// @title The contract to be inherited to make Airnode RRP requests
abstract contract RrpRequesterV0 {
  IAirnodeRrpV0 public immutable airnodeRrp;

  /// @dev Reverts if the caller is not the Airnode RRP contract.
  /// Use it as a modifier for fulfill and error callback methods, but also
  /// check `requestId`.
  modifier onlyAirnodeRrp() {
    require(msg.sender == address(airnodeRrp), "Caller not Airnode RRP");
    _;
  }

  /// @dev Airnode RRP address is set at deployment and is immutable.
  /// RrpRequester is made its own sponsor by default. RrpRequester can also
  /// be sponsored by others and use these sponsorships while making
  /// requests, i.e., using this default sponsorship is optional.
  /// @param _airnodeRrp Airnode RRP contract address
  constructor(address _airnodeRrp) {
    airnodeRrp = IAirnodeRrpV0(_airnodeRrp);
    IAirnodeRrpV0(_airnodeRrp).setSponsorshipStatus(address(this), true);
  }
}

contract Roulette is RrpRequesterV0 {
  uint256 public constant MIN_BET = 10000000000000; // .001 ETH
  uint256 spinCount;
  address airnode;
  address immutable deployer;
  address payable sponsorWallet;
  bytes32 endpointId;

  // ~~~~~~~ ENUMS ~~~~~~~

  enum BetType {
    Color,
    Number,
    EvenOdd,
    Third,
	 Half
  }

  // ~~~~~~~ MAPPINGS ~~~~~~~

  mapping(address => bool) public userBetAColor;
  mapping(address => bool) public userBetANumber;
  mapping(address => bool) public userBetEvenOdd;
  mapping(address => bool) public userBetThird;
  mapping(address => bool) public userBetHalf;
  mapping(address => bool) public userToColor;
  mapping(address => bool) public userToEven;

  mapping(address => uint256) public userToCurrentBet;
  mapping(address => uint256) public userToSpinCount;
  mapping(address => uint256) public userToNumber;
  mapping(address => uint256) public userToThird;
  mapping(address => uint256) public userToHalf;

  mapping(bytes32 => bool) expectingRequestWithIdToBeFulfilled;

  mapping(bytes32 => uint256) public requestIdToSpinCount;
  mapping(bytes32 => uint256) public requestIdToResult;

  mapping(uint256 => bool) blackNumber;
  mapping(uint256 => bool) public blackSpin;
  mapping(uint256 => bool) public spinIsComplete;

  mapping(uint256 => BetType) public spinToBetType;
  mapping(uint256 => address) public spinToUser;
  mapping(uint256 => uint256) public spinResult;

  // ~~~~~~~ ERRORS ~~~~~~~

  error HouseBalanceTooLow();
  error NoBet();
  error ReturnFailed();
  error SpinNotComplete();
  error TransferToDeployerWalletFailed();
  error TransferToSponsorWalletFailed();

  // ~~~~~~~ EVENTS ~~~~~~~

  event RequestedUint256(bytes32 requestId);
  event ReceivedUint256(bytes32 indexed requestId, uint256 response);
  event SpinComplete(bytes32 indexed requestId, uint256 indexed spinNumber, uint256 qrngResult);
  event WinningNumber(uint256 indexed spinNumber, uint256 winningNumber);

  /// sponsorWallet must be derived from address(this) after deployment
  /// https://docs.api3.org/airnode/v0.6/grp-developers/requesters-sponsors.html#how-to-derive-a-sponsor-wallet
  /// @param _airnodeRrp Airnode RRP contract address, https://docs.api3.org/airnode/v0.6/reference/airnode-addresses.html
  /// @dev includes init of blackNumber mapping to match roulette board for betColor()
  /// https://docs.api3.org/qrng/chains.html
  /// https://docs.api3.org/airnode/v0.6/reference/airnode-addresses.html
  constructor(address _airnodeRrp) RrpRequesterV0(_airnodeRrp) {
    deployer = msg.sender;
    blackNumber[2] = true;
    blackNumber[4] = true;
    blackNumber[6] = true;
    blackNumber[8] = true;
    blackNumber[10] = true;
    blackNumber[11] = true;
    blackNumber[13] = true;
    blackNumber[15] = true;
    blackNumber[17] = true;
    blackNumber[20] = true;
    blackNumber[22] = true;
    blackNumber[24] = true;
    blackNumber[26] = true;
    blackNumber[28] = true;
    blackNumber[29] = true;
    blackNumber[31] = true;
    blackNumber[33] = true;
    blackNumber[35] = true;
  }

  /// @notice for user to spin after bet is placed
  /// @dev calls the AirnodeRrp contract with a request
  /// @param _spinCount the msg.sender's spin number assigned when bet placed
  function _spinRouletteWheel(uint256 _spinCount) internal {
    require(!spinIsComplete[_spinCount], "spin already complete");
    require(_spinCount == userToSpinCount[msg.sender], "!= msg.sender spinCount");
    bytes32 requestId = airnodeRrp.makeFullRequest(
      airnode,
      endpointId,
      address(this),
      sponsorWallet,
      address(this),
      this.fulfillUint256.selector,
      ""
    );
    expectingRequestWithIdToBeFulfilled[requestId] = true;
    requestIdToSpinCount[requestId] = _spinCount;
    emit RequestedUint256(requestId);
  }

  /** @dev AirnodeRrp will call back with a response
   *** if no response returned (0) user will have bet returned (see check functions) */
  function fulfillUint256(bytes32 requestId, bytes calldata data) external onlyAirnodeRrp {
    require(expectingRequestWithIdToBeFulfilled[requestId], "Unexpected Request ID");
    expectingRequestWithIdToBeFulfilled[requestId] = false;
    uint256 _qrngUint256 = abi.decode(data, (uint256));
    requestIdToResult[requestId] = _qrngUint256;
    _spinComplete(requestId, _qrngUint256);
    emit ReceivedUint256(requestId, _qrngUint256);
  }

  /** @dev a failed fulfill (return 0) assigned 37 to avoid modulo problem
   *** in spinResult calculations in above functions,
   *** otherwise assigns the QRNG result to the applicable spin number **/
  function _spinComplete(bytes32 _requestId, uint256 _qrngUint256) internal {
    uint256 _spin = requestIdToSpinCount[_requestId];
    if (_qrngUint256 == 0) {
      spinResult[_spin] = 37;
    } else {
      spinResult[_spin] = _qrngUint256;
    }
    spinIsComplete[_spin] = true;
    if (spinToBetType[_spin] == BetType.Number) {
      checkIfNumberWon(_spin);
    } else if (spinToBetType[_spin] == BetType.Color) {
      checkIfColorWon(_spin);
    } else if (spinToBetType[_spin] == BetType.EvenOdd) {
      checkIfEvenOddWon(_spin);
	 } else if (spinToBetType[_spin] == BetType.Half) {
		checkIfHalfWon(_spin);
    } else if (spinToBetType[_spin] == BetType.Third) {
      checkIfThirdWon(_spin);
    }
    emit SpinComplete(_requestId, _spin, spinResult[_spin]);
  }

  /// @dev set parameters for airnodeRrp.makeFullRequest
  /// @param _airnode ANU airnode contract address
  /// @param _sponsorWallet derived sponsor wallet address
  /// @param _endpointId endpointID for the QRNG, see https://docs.api3.org/qrng/providers.html
  /// @notice derive sponsorWallet via https://docs.api3.org/airnode/v0.6/concepts/sponsor.html#derive-a-sponsor-wallet
  /// only non-immutable function, to allow updating request parameters if needed
  function setRequestParameters(address _airnode, bytes32 _endpointId, address payable _sponsorWallet) external {
    require(msg.sender == deployer, "msg.sender not deployer");
    airnode = _airnode;
    endpointId = _endpointId;
    sponsorWallet = _sponsorWallet;
  }

  /// @notice sends msg.value to sponsorWallet to ensure Airnode continues responses
  function topUpSponsorWallet() external payable {
    require(msg.value != 0, "msg.value == 0");
    (bool sent, ) = sponsorWallet.call{ value: msg.value }("");
    if (!sent) revert TransferToSponsorWalletFailed();
  }

  // to refill the "house" (address(this)) if bankrupt
  receive() external payable {}

  /// @dev Reverts if msg.value < MIN_BET or House balance is too low
  /// @param _value uint moltiplicator for check the win
  // After checks, increments spinCount and save msg.value, spinCount and msg.sender
  modifier checkBetConditions(uint _value) {
    require(msg.value >= MIN_BET, "msg.value < MIN_BET");
    if (address(this).balance < msg.value * _value) revert HouseBalanceTooLow();
    unchecked {
      ++spinCount;
    }
    userToCurrentBet[msg.sender] = msg.value;
    userToSpinCount[msg.sender] = spinCount;
    spinToUser[spinCount] = msg.sender;
    _;
  }

  /// @notice for internal usage, to send unsuccessful bet to sponsor wallet and deployer
  /// @param _user user address
  function sendUnsuccessfullBet(address _user) internal {
      (bool sent, ) = sponsorWallet.call{ value: userToCurrentBet[_user] / 10 }("");
      if (!sent) revert TransferToSponsorWalletFailed();
      (bool sent2, ) = deployer.call{ value: userToCurrentBet[_user] / 50 }("");
      if (!sent2) revert TransferToDeployerWalletFailed();
  }

  /// @notice for internal usage, to send successful bet to the player
  /// @param _user user address
  /// @param _value moltiplicator for the win
  function sendSuccessfullBet(address _user, uint _value) internal {
    (bool sent, ) = _user.call{ value: userToCurrentBet[_user] * _value }("");
    if (!sent) revert HouseBalanceTooLow();
  }

  /// @notice for internal usage, to send back bet to the player
  /// @param _user user address
  function returnBet(address _user) internal {
    (bool sent, ) = _user.call{ value: userToCurrentBet[_user] }("");
    if (!sent) revert ReturnFailed();
  }

  /// @notice for user to submit a single-number bet, which pays out 35:1 if correct after spin
  /// @param _numberBet number between 0 and 36
  /// @return userToSpinCount[msg.sender] spin count for this msg.sender, to enter in spinRouletteWheel()
  function betNumber(uint256 _numberBet) checkBetConditions(35) external payable returns (uint256) {
    require(_numberBet < 37, "_numberBet is > 36");
    userToNumber[msg.sender] = _numberBet;
    userBetANumber[msg.sender] = true;
    spinToBetType[spinCount] = BetType.Number;
    _spinRouletteWheel(spinCount);
    return (userToSpinCount[msg.sender]);
  }

  /// @notice for user to check number bet result when spin complete
  /// @dev unsuccessful bet sends 10% to sponsor wallet to ensure future fulfills, 2% to deployer, rest kept by house
  function checkIfNumberWon(uint256 _spin) internal returns (uint256) {
    address _user = spinToUser[_spin];
    if (userToCurrentBet[_user] == 0) revert NoBet();
    if (!userBetANumber[_user]) revert NoBet();
    if (!spinIsComplete[_spin]) revert SpinNotComplete();
    if (spinResult[_spin] == 37) {
      returnBet(_user);
    } else {}
    if (userToNumber[_user] == spinResult[_spin] % 37) {
      sendSuccessfullBet(_user, 35);
    } else {
      sendUnsuccessfullBet(_user);
    }
    userBetANumber[_user] = false;
    userToCurrentBet[_user] = 0;
    emit WinningNumber(_spin, spinResult[_spin] % 37);
    return (spinResult[_spin] % 37);
  }

  /// @notice submit bet and "1", "2", or "3" for a bet on 1st/2nd/3rd of table, which pays out 3:1 if correct after spin
  /// @param _oneThirdBet uint 1, 2, or 3 to represent first, second or third of table
  /// @return userToSpinCount[msg.sender] spin count for this msg.sender, to enter in spinRouletteWheel()
  function betOneThird(uint256 _oneThirdBet) checkBetConditions(3) external payable returns (uint256) {
    require(_oneThirdBet == 1 || _oneThirdBet == 2 || _oneThirdBet == 3, "_oneThirdBet not 1 or 2 or 3");
    userToThird[msg.sender] = _oneThirdBet;
    userBetThird[msg.sender] = true;
    spinToBetType[spinCount] = BetType.Third;
    _spinRouletteWheel(spinCount);
    return (userToSpinCount[msg.sender]);
  }

  /// @notice for user to check third bet result when spin complete
  /// @dev unsuccessful bet sends 10% to sponsor wallet to ensure future fulfills, 2% to deployer, rest kept by house
  function checkIfThirdWon(uint256 _spin) internal returns (uint256) {
    address _user = spinToUser[_spin];
    if (userToCurrentBet[_user] == 0) revert NoBet();
    if (!userBetThird[_user]) revert NoBet();
    if (!spinIsComplete[_spin]) revert SpinNotComplete();
    uint256 _result = spinResult[_spin] % 37;
    uint256 _thirdResult;
    if (_result > 0 && _result < 13) {
      _thirdResult = 1;
    } else if (_result > 12 && _result < 25) {
      _thirdResult = 2;
    } else if (_result > 24) {
      _thirdResult = 3;
    }
    if (spinResult[_spin] == 37) {
      returnBet(_user);
    } else {}
    if (
      (userToThird[_user] == 1 && _thirdResult == 1) ||
      (userToThird[_user] == 2 && _thirdResult == 2) ||
      (userToThird[_user] == 3 && _thirdResult == 3)
    ) {
      sendSuccessfullBet(_user, 3);
    } else {
      sendUnsuccessfullBet(_user);
    }
    userBetThird[_user] = false;
    userToCurrentBet[_user] = 0;
    emit WinningNumber(_spin, spinResult[_spin] % 37);
    return (spinResult[_spin] % 37);
  }

  // make similar function as above for halves
    /// @notice submit bet and "1" or "2" for a bet on 1st/2nd/3rd of table, which pays out 2:1 if correct after spin
  /// @param _halfBet uint 1 or 2 to represent first or second half of table
  /// @return userToSpinCount[msg.sender] spin count for this msg.sender, to enter in spinRouletteWheel()
  function betHalf(uint256 _halfBet) checkBetConditions(2) external payable returns (uint256) {
	 require(_halfBet == 1 || _halfBet == 2, "_halfBet not 1 or 2");
	 userToHalf[msg.sender] = _halfBet;
	 userBetHalf[msg.sender] = true;
	 spinToBetType[spinCount] = BetType.Half;
	 _spinRouletteWheel(spinCount);
	 return (userToSpinCount[msg.sender]);
  }

  /// @notice for user to check half bet result when spin complete
  /// @dev unsuccessful bet sends 10% to sponsor wallet to ensure future fulfills, 2% to deployer, rest kept by house
  function checkIfHalfWon(uint256 _spin) internal returns (uint256) {
	 address _user = spinToUser[_spin];
	 if (userToCurrentBet[_user] == 0) revert NoBet();
	 if (!userBetHalf[_user]) revert NoBet();
	 if (!spinIsComplete[_spin]) revert SpinNotComplete();
	 uint256 _result = spinResult[_spin] % 37;
	 uint256 _halfResult;
	 if (_result > 0 && _result < 19) {
		_halfResult = 1;
	 } else if (_result > 18) {
		_halfResult = 2;
	 }
	 if (spinResult[_spin] == 37) {
		returnBet(_user);
	 } else {}
	 if (
    (userToHalf[_user] == 1 && _halfResult == 1) ||
    (userToHalf[_user] == 2 && _halfResult == 2)
   ) {
		sendSuccessfullBet(_user, 2);
	 } else {
    sendUnsuccessfullBet(_user);
	 }
	 userBetHalf[_user] = false;
   userToCurrentBet[_user] = 0;
   emit WinningNumber(_spin, spinResult[_spin] % 37);
   return (spinResult[_spin] % 37);
  }




  /** @notice for user to submit a boolean even or odd bet, which pays out 2:1 if correct
   *** reminder that a return of 0 is neither even nor odd in roulette **/
  /// @param _isEven boolean bet, true for even
  /// @return userToSpinCount[msg.sender] spin count for this msg.sender, to enter in spinRouletteWheel()
  function betEvenOdd(bool _isEven) checkBetConditions(2) external payable returns (uint256) {
    userBetEvenOdd[msg.sender] = true;
    if (_isEven) {
      userToEven[msg.sender] = true;
    } else {}
    spinToBetType[spinCount] = BetType.EvenOdd;
    _spinRouletteWheel(spinCount);
    return (userToSpinCount[msg.sender]);
  }

  /// @notice for user to check even/odd bet result when spin complete
  /// @dev unsuccessful bet sends 10% to sponsor wallet to ensure future fulfills, 2% to deployer, rest kept by house
  function checkIfEvenOddWon(uint256 _spin) internal returns (uint256) {
    address _user = spinToUser[_spin];
    if (userToCurrentBet[_user] == 0) revert NoBet();
    if (!userBetEvenOdd[_user]) revert NoBet();
    if (!spinIsComplete[_spin]) revert SpinNotComplete();
    uint256 _result = spinResult[_spin] % 37;
    if (spinResult[_spin] == 37) {
      returnBet(_user);
    } else {}
    if (_result == 0) {
      (bool sent, ) = sponsorWallet.call{ value: userToCurrentBet[_user] / 10 }("");
      if (!sent) revert TransferToSponsorWalletFailed();
    } else if (
      (userToEven[_user] && (_result % 2 == 0)) ||
      (!userToEven[_user] && _result % 2 != 0)
    ) {
      sendSuccessfullBet(_user, 2);
    } else {
      sendUnsuccessfullBet(_user);
    }
    userBetEvenOdd[_user] = false;
    userToCurrentBet[_user] = 0;
    emit WinningNumber(_spin, spinResult[_spin] % 37);
    return (spinResult[_spin] % 37);
  }

  /** @notice for user to submit a boolean black or red bet, which pays out 2:1 if correct
   *** reminder that 0 is neither red nor black in roulette **/
  /// @param _isBlack boolean bet, true for black, false for red
  /// @return userToSpinCount[msg.sender] spin count for this msg.sender, to enter in spinRouletteWheel()
  function betColor(bool _isBlack) checkBetConditions(2) external payable returns (uint256) {
    userBetAColor[msg.sender] = true;
    if (_isBlack) {
      userToColor[msg.sender] = true;
    } else {}
    spinToBetType[spinCount] = BetType.Color;
    _spinRouletteWheel(spinCount);
    return (userToSpinCount[msg.sender]);
  }

  /// @notice for user to check color bet result when spin complete
  /// @dev unsuccessful bet sends 10% to sponsor wallet to ensure future fulfills, 2% to deployer, rest kept by house
  function checkIfColorWon(uint256 _spin) internal returns (uint256) {
    address _user = spinToUser[_spin];
    if (userToCurrentBet[_user] == 0) revert NoBet();
    if (!userBetAColor[_user]) revert NoBet();
    if (!spinIsComplete[_spin]) revert SpinNotComplete();
    uint256 _result = spinResult[_spin] % 37;
    if (spinResult[_spin] == 37) {
      returnBet(_user);
    } else if (_result == 0) {
      sendUnsuccessfullBet(_user);
    } else {
      if (blackNumber[_result]) {
        blackSpin[_spin] = true;
      } else {}
      if (
        (userToColor[_user] && blackSpin[_spin]) ||
        (!userToColor[_user] && !blackSpin[_spin] && _result != 0)
      ) {
        sendSuccessfullBet(_user, 2);
      } else {
        sendUnsuccessfullBet(_user);
      }
    }
    userBetAColor[_user] = false;
    userToCurrentBet[_user] = 0;
    emit WinningNumber(_spin, spinResult[_spin] % 37);
    return (spinResult[_spin] % 37);
  }
}