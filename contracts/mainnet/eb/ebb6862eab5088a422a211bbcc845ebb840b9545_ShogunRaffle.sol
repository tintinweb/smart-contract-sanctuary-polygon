/**
 *Submitted for verification at polygonscan.com on 2022-12-26
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// All of the SmartCon ticket holders are eligible
// We only know hashes of their ticket confirmation numbers
// We need to run a raffle with seven winners

// Array of all participants
// Array of winners
// Remove winner from participants array, and add it to winners array

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


contract ShogunRaffle is VRFConsumerBaseV2, Ownable {
    // bytes32 - data type for keccak256 hashes

    VRFCoordinatorV2Interface internal immutable i_vrfCoordinator; //i_ for immutable vars, s_ for storage vars
    uint64 internal immutable i_subscriptionId;
    bytes32 internal immutable i_keyHash =  0xd729dc84e21ae57ffb6be0053bf2b0668aa2aaf300a2a7b2ddf7dc0bb6e875a8;
    uint32 internal immutable i_callbackGasLimit = 1000000;
    uint16 internal immutable i_requestConfirmations = 10;

    uint32 internal s_numWords; 
    bool internal s_isRaffleStarted;
    address[] internal s_winners; 


    address[] public s_participants = [
        0x003fD47a87C72a0620e16465ee1cE5E22abd793c,
        0x0046A975dFD8F6017B48Dc36f767e14acC2D67B7,
        0x0057Dde1D8a0CC7AA68dc5Db7F00D21Cd5e12AFC,
        0x00C95c475847e71e89b8356D746408226b4Fdb55,
        0x010667d420c460EA0c8b64c09DF90372e7A1e992,
        0x0158A8190373d8DF8F4a806dF12d7DABD3dCCCF3,
        0x019A867967ABF6A53E5fcD2D8CD7D98B06BAb3A5,
        0x019f797A002C633C3f91154bf468D69549Cd026C,
        0x0205E114608Cd005D3Db5554BBE6B27DFc3C9E8c,
        0x026f5122FDE2aE7348ac8d20Ff1c04088d21B91f,
        0x02adfD90e5659f5A6Cb1CaE68804C1AC81F826D1,
        0x036Be34dab20c78289844c6F479fd584DF8C4972,
        0x04c08A147f9304E7aFf8E466b105BE6693ee2206,
        0x0566848cf2536AaF6b73656C7203A513acAcC191,
        0x05a22c2ac0EbaC65575E201fb34Ae14359B91E06,
        0x05bD3612202051C6B0F7f8308ceAABE9e51af0d0,
        0x062bE3e8715a0E4a4665CF6233F38D3D51739652,
        0x06bE3D823d1B83F6BCe63dEc5B986e86041beB72,
        0x07bd7D8519c6f40C11f7c98230EcB69329a29a54,
        0x095f0e40770351A5fA56BA022A41B49A4AEDa45a,
        0x099F8d035140864b86124Fd839786BcB234a9ae7,
        0x09B98A2330612C1e48944A3b487D556e7B548577,
        0x09bEE453dDDf3ecf48bf439C4260698773F2d234,
        0x09d119E23e25506f02E304E3aD721aE0Ab85e315,
        0x0b441F4C9798DC7DCF4a5F5Ab4EA53F71AB39A7e,
        0x0BaBf2cB67039E589B6c4740A930a78A4D1f57e7,
        0x0be2714aB6515dA8ceB2E9E1CF62F297B86fBBD0,
        0x0c56a0E975cBb70331fd2Dd9ea737189aaD46693,
        0x0c72b346Ac4546b11E94B9A6cBa1F06c0B741e96,
        0x0d04C7088671C03372FAE01E1feEE9049a7E6606,
        0x0d782f0bBE3AAC33e631e0EB3244F97d9364bdfe,
        0x0dB85C4975Dc0eD1f0F83eEb1ec412eF11443884,
        0x0e56db3Cc28Df9AAcd3c9E8A5c25404B04406C9B,
        0x0efF89Db604290333b065449Dae37145DEB02e0a,
        0x0f33F415bf753C88F159a7E182e8B784e9047511,
        0x0Ff8A9C2b89A70a6676Bc1a5168b1e46d31E46E3,
        0x104e4A76960b4bF24492a47239Efc891A23B2374,
        0x1083C64B21a5e9b3c2B3A254f93C18F9980297da,
        0x1122E5395f4fbd0d542cbEb54298447D66c0CD22,
        0x113D31672f2963379B72f389b864dd498a16a26b,
        0x11De7082a216fE0F166C8AbFfDB1f745d38e0b72,
        0x130BbEF83939c3E6939DA50CDcd23dE97dd41F5a,
        0x1400338848566d56584D7D4ced26762e7E09649a,
        0x1446Ae9DFF7Cb798a7B8B0b91eA89E604cAC191a,
        0x1478344FC7463B7ee9861b8A8428bfb8242baa52,
        0x149b0074c57382A38c22F317b0Cd1E66c28117D2,
        0x14C0b1F2a5069066385c70c2E35df00a5a96eD81,
        0x154adf994AD640E1409986A3911664647b8C91C6,
        0x15ACeb93E5C523f55643E3E65b8619E0A2A43a4a,
        0x15dC6D6D14Aa11370EcCacc32502d1ef753b2663,
        0x16f1B3e0267BF91d2BB98aEBb821F59C0000d818,
        0x172b343116086C8CEd8c7C61e365b8766d9628A5,
        0x1739f0485ea3F719eA433505122250816Fc7A2C1,
        0x175c5d5e92fdF820D57A5B1F9F2EE13f792BA4f7,
        0x178C804D46b1dF6364E80C11c36712294e657DB6,
        0x19556FF1D37bc346fcAe6282973c5D75422FFfc0,
        0x19c2374e37BD4d9de6526a3aa0c29403337D3977,
        0x19eD8E524d3761A980F9756662A626BDA2059F32,
        0x1a2CC31c6E7e27162113B994D4ab7f09c08Eda52,
        0x1ABda66510c51cE9c758C00680c44A7b56c3D910,
        0x1b30c1D67333b5C3dACC649876BF09B6702AB8e8,
        0x1B87404Fa7476F9d3377c8442796B6DD2E2559Cb,
        0x1C4dF2d54ca514f5C62596CdFde7B95c4C866885,
        0x1c80A78E1aAfD648979b8f7B4Ec8e180F2188FC8,
        0x1cc83473979E2b4c412ff28499B4562F059D8Df3,
        0x1d082b97D30F061e391a733B406B76ac42DC8cEa,
        0x1D15B8345BF5283897B460231ea4CC040d663615,
        0x1f2F65cfB19866CbE3582FF8f8B8adA5a9f09395,
        0x1f32A8163512Cbf1BEc99810aeDaF7a81617c2f3,
        0x2048e8574eb289c80d3a7Fcb45B0eCc0C98Cda21,
        0x21120481045Cabe89e94c0B7a97112523FDd2693,
        0x22354b2417bCE0CC23dd20d4C2F3f2F262D01f11,
        0x2285d362bfB51A2f05Cec348C5060e7201661690,
        0x2379Ee1fb52b3AEfc345877D9C4EDD9226f2966F,
        0x23e9C810bE1D75dbf9a68902A24bEBd619e050D6,
        0x252E78e977aD6338AE6C3CFBd0a347B5Fd8d9677,
        0x2568Dc0aB94FCf6303B2744dFc11808eC70B8C3b,
        0x264D7cC901923Ff50DdDa5B58DfB759a66Df0899,
        0x2663a3b25e176959c7185F6d36e84BCf0D79308e,
        0x272F251f7a3ce9D8c6920300d91151095Ac3bE48,
        0x288e9f3579B2558268b64b7e6169B03B1bBc1948,
        0x28C6F7FF1fCD1e7505c9C6d3Bcbc88B099aFE350,
        0x28Cb957A36Ad5De4EB6D908c9F85B529E3410D41,
        0x298cA5A3e044e614DcC1666138be3244eD9b345F,
        0x2996fe5cACF429286372a63318B1E29e999D0dbF,
        0x2a36f8897DfeF3Bf79FCaB97301a7ae6Ba3D8A52,
        0x2AF9D463654d07fC1754ce12c46eF32Fd043ADeF,
        0x2Ba243EF5Cff72eA821e9109D68286AddDFe0279,
        0x2bB2Cb4E64394fBe8371a542119e41F4fd1Af5A0,
        0x2c3E79D3DCE90FB0886C89Ec602E61757E589a94,
        0x2cce430174b85a9dBD3632A50988E78Ca97eE5F4,
        0x2CEb7fc8aa5B41c7a6e19e4C07EDBA1B7046CDa0,
        0x2D56c603DFB41507fd9CB1BAA167a3DD90281ec5,
        0x2E29Ba788896696ec261A6c35055c5AEC339ee45,
        0x2e2DAeC7aAa64910a6D68Bd02A0087e154EF8b07,
        0x2e3aB9c77a1F2c774FaD3a760b36d6fA8ac806f7,
        0x2f277cC8bfb356a9901e069107def87033BfBae4,
        0x2f38c852CD596d0Ece510F9a497b6562e5C80B09,
        0x30bEa732635084D3013Cef764379B1FcB7B09A1c,
        0x3127d515a2e8C3610e2feE8Ed54A957AcDB0C0b4,
        0x316ec05eC892Ce05d3A5F2B1d105022497da7104,
        0x31DbBE5E575D8DD8D882cd31ac6181C8b8139Ffb,
        0x330153C61f909A19ef7c93Bc9438Eb2111eA2bb8,
        0x33EB04d6EA897944dCAB0692D662AA656B88CCf2,
        0x367081B5Bf599dEaae6379566b7B4DF1847f0fA0,
        0x3718c28179A0ddA388d61F52632a737Bf0fAd0DD,
        0x379dED82BfF4fDdD278814e8C209327bE9EAA708,
        0x37bC782b7856C8B35Bf93c31a4246A5DC2245122,
        0x37fe3e82871D6068c23619ca9b27b0Cf9af21B03,
        0x38436113C86dEeF2b6624d5c7CAB99Baa558274b,
        0x38e4C7f518b7969BbB0326140Ca857a32Fe69B9A,
        0x3988D80c8350aEF29cc9A4a1611733111715b672,
        0x3991eCA764BE38eA97Da16ad4267902590bD893F,
        0x39Fd1880B3D3Af3705a765771e78becbd229517D,
        0x3B807021a7E6a280CfcA369e4c16c7c9E188D336,
        0x3B8ff84b3EDe8B75861529D25175674FE6b6Ff2F,
        0x3Bf12feAf4ebb3755c432EB1F47525F02EB2906C,
        0x3F00BdFdafadDe6d07594067b73114aD3631999a,
        0x3f36d0dD23139a619E368F0AA89279be9cc61cD8,
        0x3ff5C552D55ec4107c6D3062368F53863ACc24E2,
        0x4001a0605cB35C804590f28cFD4Ab4D3cB87e5AE,
        0x4037eE88B2B5C31B06DC7B55BBC78D8E8b0e3d7b,
        0x407B19368fA8C8d97Aa75aF0FB6842fB7b5EC818,
        0x40c1e43BD64EE4ed8C3076ccbd760C515D9C00a1,
        0x411bD221E82C22c862C247d01A6089Ab4387267A,
        0x439Edffd4cc312427f5F5cC10F377ABa9839c7f0,
        0x442eF2d3f3E5Ce2740a07FCCF1d0CCd4a5dBdE57,
        0x4512cEbb6a19d0008C2d4486610d6fFb103328de,
        0x4536aB15E0ec96B1844FC1c1bE0a8dcF98f53592,
        0x457897A64f659766D5C68B499f15c02e27aEeEf4,
        0x4614dc64F15b908d5fdcb02c67FFD1814D8d2A0E,
        0x4638c1A11A1475aFd253A2FA570b8d77D0744441,
        0x473785F22D26b775d2F488dfa7D4d66711DD9192,
        0x47797008e865102EcCce40b798FED7DeDe49b44b,
        0x47f2eAf7Bf24f1981F66779a6A16DfEC3A0eD6b5,
        0x487D58049183b7D1F76710c757620756005BAe64,
        0x48BC50745494E2c12234b707A459b375118885bd,
        0x48e4e6C9b5DEb09CD9dBE938D53751E2421b89b5,
        0x49aA8a846230a5655DaCB777E852603d210A0a8e,
        0x4a27BfD91B30EfAf08706d2105e5D8A1ad09fF0C,
        0x4ABfD51f34c82bCd130e3b26859c5498775b2915,
        0x4ac046cD59997cC3f2D0F2dd644c81e961d57dCf,
        0x4ACd61B27509ac5Afa151AedB9D073BCe095dD7A,
        0x4B78BA5edD0530148CBE104327d04B3daae2DE0C,
        0x4B7B1B9A50ED66Db1396CB8cf085358c2681Ab86,
        0x4CD99f98B574579A9F48E7E4c5294e1f2aCa1550,
        0x4d8D43a4986B34D8B89379C7Be14127eB392FC0c,
        0x4E3b43222dAD5C9095fe3E16B5F84C0699804a3c,
        0x4E87b30dA0b566D1f533E9e19790eB1eeA23F910,
        0x4F42Fea1fEEB0F46Ca21Eeeb8454301b0a5b88ee,
        0x4F7a0d7c1A9869Ee6Cc7075A40A224B8589d0aAf,
        0x5043Cb357681b26B56960f54d573855900E47911,
        0x504a6949983A107ccD12e2C011E881c55C3A4B8D,
        0x5089940bC7Ceb062e9db67a1C61d314cbA64A17A,
        0x510212441B0D2Aa9D9a9d140BF71f6117A34988a,
        0x515fEE38396b3EfabD5d24F0ce05fC2c6A351ae3,
        0x51c1c3bbe53bA188577e3F4B33Ea59258d709360,
        0x51e6921C7e62fE0d6b0CcF8d2fe0249b173Ae83d,
        0x529AC1a0b4491d2d851705Fb9B0314294e284d0A,
        0x5388875De4f4De4B780f56155E2E828951e70452,
        0x544A020722754f2f4810351c6E9E0B5E154C0D1f,
        0x55C3C7B012f875c68CF65677a2D566f17a532B29,
        0x55ca3E987132d3dAFCA9154D0B3a334AE1501653,
        0x562763A8802c7549caC7ac107cc28Fe5f2165F68,
        0x56485da819b2c7366c0FC44B69e42c3173B9bc75,
        0x56cc483797E7d158016f9b817AC2ed31B0aF6332,
        0x56D06D8CD92EEE3d8828C6CAD990ea2FAd6b11c8,
        0x56f4B4ebF796E14b72ADb50cD0592fCbEa2eB837,
        0x5823473fbC51eC1ACf14Ef411fefE6b5b5b16dC2,
        0x588BFCC4e0d4A75297df5C65C99AcB25f288666a,
        0x58BC6389Df3178f37998B46fEE876F795F14509F,
        0x5906E15C9d92d88a6A2e710c431E4D977529A780,
        0x5a9FEcF87D9b46aD9820D28bc1020b2C30E99200,
        0x5Ab572AEED89526C81d2A016236093f5A68f3819,
        0x5aD90385678751E1728f208C7F3de466c9AF5Dc8,
        0x5B2dB04a39e45EfF396d707694CfeE1940D2C56D,
        0x5C067000AC8b790e6A38e81aA77ff2Cb478B5B27,
        0x5c0A576D959FD751495d465aa98950e4B1CA42d7,
        0x5c244F1197CB71a280333C18Bd6d51C60d294159,
        0x5c55425AA4270528A4024680743f5c27Ff36b0CB,
        0x5c85fC188f9F9094FCA7206f5907a28bB7c192e8,
        0x5Cc09262952341683Ee32b92A2cB44df3fc69b5a,
        0x5dA7ebFA13031Bd7a41cF0942C32662F4a81f492,
        0x5E479Dd286B0998cc21785570B01d935098a3831,
        0x5e5Be80F4e4f312F29888ad1EFE1Ee35CD18beD4,
        0x5F18f35b26dF7CC635fF95167fD6DE746EbAAD83,
        0x5f299A5813B39Ce4F3443182D835A809A7680aCa,
        0x5F778c94ADFd1857DE1A270Efa5900403DFeFeC7,
        0x5Ff3e835Cf60D3dDE1190999CBD19d2f17c1eeAd,
        0x610c27C2Cae7d94c8727Dff9EBB552b30b119ECC,
        0x613E28a29704BA05bEB9DdBDc54a8B8Deb7B1025,
        0x61a64D0181F4d02c900F2192145e0432f422c0d6,
        0x6201EE6a8FAD5a9b560bC40e58a91Ae9B32df641,
        0x6263a12c3d8AD2f7BaC221b460408496B9c9f0Ab,
        0x6271a78a9a864bbF05C45E3D252A17e87904F9A2,
        0x62c40e75D2C5A1872db323BEC6fA3E9b6dF7B99A,
        0x633627D796fc6962a17Eb9E5108d08A84fAb1498,
        0x635139D0914Af98d41FEFb6e2d69c18A3655a038,
        0x6355ee78fE001Ed04537D02A28f216087B7643F6,
        0x63C6389c1bE54A0aD43210aF799B9F848611c2B2,
        0x650993dc97634CCf05D362beAD78B4adD5D506C5,
        0x656c498E72be5Dc8B8c4CC85eBd9eB2280C67869,
        0x66DC4f3cFFB666e57734a9F15A0cE6b625eDf50C,
        0x66DE381B1C3b0aF3c6F3107F9b9771A485D91101,
        0x6751d18783F7680ba342aAb2c421Eae5886D9Bf8,
        0x67De67f51df9Ee240917E46958Dc89A5aB4215E3,
        0x67f6d0F49F43a48D5f5A75205AF95c72b5186d9f,
        0x6851085601fBebE5B365fd0EcC31F4F5BF2a146D,
        0x688bE36a3E23b8E5Fe0d88479b34D192c6130352,
        0x68aFA767cA68584da59fA7140f42317e6806B6AB,
        0x68cb598b9daAc1170B563f4e25A6897Fa853E437,
        0x6A03Ea11625F2F5623D1Be7F4B2EC71b68030178,
        0x6A37fD8ED1181581B3EbFdCdb5275AaD5c7C545B,
        0x6AdB4A4A3a348D2E0C139Cf2B1759c2ae631D629,
        0x6aEB233b75E95F984d462235A67F7D87bfBE9365,
        0x6B25FA04B5056159e7ddcc3274Ab7BD547C697C2,
        0x6b94bB6ee526A7fFf650F36c2AD834d34B5757EC,
        0x6C9dd3C986BAEDEB34F7F8b6A199F4488560017E,
        0x6D681a891FCB6c38F04f3129E624a9D8b970cAfd,
        0x6dF563b5063eD2554D780C1e2a614B9bA3857E33,
        0x6e9E947980D6745b83FfB70Fb273b863C9427599,
        0x6eB65C9193287E0feb8B21282e5F230019bA8601,
        0x6f97071F1C600f6f80BeCeCb8C3893188360f59A,
        0x6FAD77FC6f1b3aA02742961cdC79bf3Da6F81ade,
        0x723A1c1Bf28D14Aa309ab6d8D2B805f9D3cd379b,
        0x72C77230D2c6748F3e0A0479eb7AA33Eb0687F61,
        0x734B5394D44C77D542f8831561Ea1311fc588d5d,
        0x73C1CA4Ce2C19BFB52d45Db7D06B59071cfc736C,
        0x7490cc8D350b92f30cD38Bb0d91402b5fA161c41,
        0x74d8d443b9300B2A71025e4425212d78AD4Db1A2,
        0x75B2fF3767A7FdBa1B675fbf7255447EE4dFD945,
        0x7674b1A9eD6C2355bA37E4e0c181657fa2e96B65,
        0x77c9614c73c1e32538C4Ed825031F6195a1cE455,
        0x78049d5E3A8fD3f482Aaf8A4EE22C4fc18BE1EdD,
        0x783AaaFCDd4C03A6a7b55bE74eF27A091658256e,
        0x794BdbA47D63b56be27eDa546be4172DFE6FF2E6,
        0x7984e56E37D7A4E534A7ca0936fc9b0a04b1dd1D,
        0x7985C2Acb0E70CFdc006c77636121a69a736604c,
        0x7a5ACaE0EF884ac31FeFd6DbC5075BD3E80F27CB,
        0x7ad5BE48A9c1d5168eF1bC37672D6D45f7A894aA,
        0x7aFB0153d4ccfA8720C81e7CDe84709faA4B0400,
        0x7b8912DEae59BDD8F40C9D90bF4798e09Cd06654,
        0x7d1cA478E8d3E83349e9dF63357e87d3dDef5989,
        0x7d33A7A8588371707F099420B06Cce47eb060ab2,
        0x7D57bf90237fcB602A3Ab1e6A4370863Bdd12Ee2,
        0x7D8572AfD311B553bA364545008c167391EA822b,
        0x7dD72353Fce48276567C3763EBdeF856E5940D5d,
        0x7eaad8Faf76269532a5E8d1Ea2DE3601249c068e,
        0x7EC089FA35BF500C69769Fe438817a87c6c7a525,
        0x7f08d440AE8Df085e4A3D622505cC0e43B9Ea0E4,
        0x7f4A03E462D45DA25eec3541c125c5133Da926DD,
        0x7f5a3C83F7906ff2dB41784c48c4A742867b4A29,
        0x7f5EE6822208b8113d69b0827E9d397236C8Ed11,
        0x7FB73bBDDE56Ec995f075193eB0a04B1D94b1837,
        0x8077BaB739A889c7415B292029c1b249E15ae992,
        0x80AA76faB13FDf472602F0597A31c131aF865390,
        0x81366f7c380a9D64240E5dd1F2b07510DdEd46dC,
        0x81Fe00a5Ea34b9c8Aca11067e48a0A731B608aA4,
        0x8307d04eA1BcCC6E3f7b576ACc13234dCd9d51d5,
        0x8403F342CBB7B838Ef0b11684B6310647906580C,
        0x843EC4A6f66694c26ac23AE4106727bCF252D3b2,
        0x86Aff1448E56c44B081bC5A8092120d32E1E48E8,
        0x89107367EC98502241BA3716AAB730aa0A28Db15,
        0x8a2cB19a7594ca57d837f919Bf0C10f8bB94821E,
        0x8a46ef73D7bA41E99844b24b4d28f5b1563419D7,
        0x8a5855f78962C5c6620fca7a40691b39AB291fd7,
        0x8b1386B0C45093bE27586F7e1f0Bf5D6CFd520EF,
        0x8c6138C8Ac3d9C391c58C3b6197b093226540E3e,
        0x8C9aA0cfbeDAFf8647ac61c389A9e6E97f463768,
        0x8cCdc53E56Eb4880aEdc7706B7D27DBCB6680D5C,
        0x8d786bf5Ef018a06E6b63269ef957F9cB11074F3,
        0x8d95Ee33F6064A7f577c1AF7272709465F2acB40,
        0x8DB08ae2Cf033cE3FbAB6B638a44efe4C2a6B29A,
        0x8E47a5BC6F75a18900813A73C00E464F47557Cc1,
        0x8faDe62c6Cd202975259bbA9Be1053021825E0d3,
        0x8Fb25FCDb7884231EdCc2165dF151b27fC529089,
        0x906F8d0f5368F140398128168287F6F960B2e591,
        0x91689a5d400b1ccB1A0e65a815E7dD83761105C2,
        0x93c9ae1Ee6E26f82F873c88a1c29a927489cbA0a,
        0x9451CadD6ed927817e63eC757Ab9B327f1A28555,
        0x94b7F5500d0cAb8aFb94BE3deB686DD10c0F77e9,
        0x94Df0c855bB66832eE8dE11E3bD7024dA4E8e701,
        0x9670183d0d5812B3B1af173EBca20018dBE8211C,
        0x9858d646B5C705932b33C86f6cE029b316504C2A,
        0x9946234689024A0a0a290AB6668B6b470fd9b9e8,
        0x995e76ce8D11c0334F1232e2fB442ff152Ab4C0C,
        0x99C6fCdfb40c836d1F3450aD7f0eaEfB428AaC17,
        0x99f0079753AFcBE20DE9A84be0eA34E836Cff514,
        0x99fd66366dd8C944336A53c44C73114Ca7d45bEB,
        0x9Bef027B205dF7DCD648eD476f5fDe53304aBF31,
        0x9bF8C690917b1a1D87a415a53636D3b0B9DFEBeA,
        0x9C2c66eA331162498cda41D67892E9500E5eA341,
        0x9cFF7d491d1987aE8d4993516EB4F5c0E27753f0,
        0x9d14928f9C58cD37ea859edcFb55e0775CaAe4eA,
        0x9d26631A32a039bc968D5bFe1d41AE95d066383d,
        0x9D78635298809eCCf43d713529382aD1109347c5,
        0x9E49a51a88A6Bb3fE1F53883B263e9A54383ca3F,
        0x9e71221a93FC8863E843a11A4721CFF087F855eA,
        0x9e89286FBAC33292726eA455AbE39fC3302D71F4,
        0x9f58301517e2F88Ee830d7819255770335419Fd8,
        0x9F6fa28B90147ad2352B990eCEf84d0bd8Fc7E46,
        0x9fA6e91ffC0287B75B6786D782c4fc948D74D533,
        0xA1170d11Df896E95ee97492572cbAF53c1963B9c,
        0xa14E796CD5F4C92cA19F0b9CBeC0bbec3D5a34FB,
        0xA1b5B0f2EE691d763552980B209D9FBFdb36f9dD,
        0xA1C9df9d1b8d6ED6F4FdD2d04ACD178d69900c05,
        0xA1d246CEB3122F6C186f19594D27500B3a78Deb3,
        0xA25303f9dB39Ab503834EA0384654022C3C53645,
        0xa390cEB4A7Fa719c704518C18E6A660f0d2474a1,
        0xA399Fc9160D3F8931695fcBaa53aBB1C64947A6E,
        0xa4c9007e5bea16485345C1593Ce0cb9F4FABd28f,
        0xa5067B15c7eCDCa4dCdf31A95925E72118285F02,
        0xa538b5Bbc950Ae391e4145c978719287a48bE58B,
        0xa543Ed5fEC376054FF7451Fb4406A9D8345F3c23,
        0xa56c18BE4E7b6be5F5671582b86502B32e150371,
        0xA5aC1995c352769F2E7f81953a421fBe23D3172E,
        0xa68CF152BA507c24b0B38a83d078931105776b90,
        0xA68fAF02E51a3467E8C6bc0D8e22a67784eB9DC4,
        0xA7C7dc522323ee8E4D27241E435D6B3a39B113a1,
        0xa9152B3bdD276679530eb8F13674CC1B163d9E38,
        0xA9f68cc54Af6452049501bF0251a8FA7901f2c2B,
        0xaA39dB9d80A3E55802b6bfecA93639C95d11fCE5,
        0xAa52269254E31B3Eb01fA2916c825489EB2Ff6Fa,
        0xabAD60Bea5CABc6296220A152Ae2142Fa7185Dba,
        0xAbFe469E7e8a77Bba2c09a1f6e16a6AcB252aB9C,
        0xAC3f705001a542230120849E88F8C8732ef38b64,
        0xAd19E8D224eeCa3Ee89Cb50bbc7B96f83db12b22,
        0xad39825354384f035B2871543eBf2DB596eF8f0a,
        0xae63A4A9966f32ef8Cf6e607df7cC87d7FE00116,
        0xae9dc735A9673aFdCC2F9e649D9E9F838c317Ce7,
        0xaF9fa7D9ea409329F5259883d05B140668E3B131,
        0xAfdb80b4deCc04227cB8ED97fe69f19b40Ba2D20,
        0xAfE296c4aBb89Db7757f08889BCFF170f0F81931,
        0xB0D3e62AF4087Cb93a7FA366723E49D92283079c,
        0xb2ec41b1DeFEB89a6C5A18F78d561602daf88B5a,
        0xB3356df1f6D7e23Fb0b3033c0E796ef4326249bd,
        0xb380725709CcAC6fC27a6e4db83E2c899A514fF9,
        0xb567676DC73944504F764952A7cCF67227184D7a,
        0xB5E5ae4FB8d211F7850f463a71Af982277593852,
        0xb8CA95Fdd8996858B8be5D50A30c8387018d8Ec5,
        0xB915cDE0287C312E6Be8087783708596c28B3755,
        0xB91E4d9280b142f2DE26C19E615743cEcAB72545,
        0xbA217Cc2A4402eD319057D692B1a549Af76C0E02,
        0xBa46CAd34620107D5F598ef87b4FDB1cF3057432,
        0xbb4A7484f8A360241Be7B8d31f6Ae64F8e55a251,
        0xBb86bDea3ecDc4b6166d9f083A95f920035bd5D3,
        0xbc293e86eefa31af132C2035F2c60a42753b3b55,
        0xBc9a6eA3E32B05e87f3e3e0DdbB23FC0C62c61f3,
        0xbd1dB7614754bcD42E4CA3c697B4B66cA249cE40,
        0xbd4a14aA8c27927f19950335B49ddFE82aB7bc54,
        0xBD6501C845877A9daceAdD4C7F5A5555f93cA0C0,
        0xBe747d5c9259AC14Ef5C0c351A48e42D67DbE7f4,
        0xbfAd81ff3209E545fEF9B940990f9224D73d2DFc,
        0xBfb6DCb37955B10c5f4E78e8c795A4227Ed7Ad90,
        0xBFc42dd991BA3b09933931f64d1bD3fECA7a52CE,
        0xC035f22499c26a0B2C71A3dD155CD4b131540AAb,
        0xC0eC996A7Bd41b317754B8E3D49757E1e281a128,
        0xC1173EdDa7b7Dd95E731f65A3932BD9df0494295,
        0xc1da2E6Dec41E2Bc8b34422E1E59723059657066,
        0xc21Af38Cf65066eD850f38afCCDD13038909f322,
        0xc26f3F7b8F904d652CeB4519dfb87330Df028aCc,
        0xc31372CbD5b6e858572923522968c6F880AaA4E1,
        0xc3330dC58e7a2e71D93B78E1668Ee2666fF38DB4,
        0xC3422Ec0f7F4f38c32062aBf8F605744a527eB49,
        0xC345730907Af13622089881dD83a533F9530A3aA,
        0xc351819e178A756bcfB5A15C048F9345E8DEe155,
        0xc3C6Fd2f0fF728d1acB999eeA2aD56302E333021,
        0xc59B04E3DA7F303B34f27BEA63BBC52D0Bc927A6,
        0xc5B08f590264C2db4e2FB22fa82d402f1FB418a8,
        0xc5eb4276C4C33b3C061e98F78196e47BB3B25680,
        0xC67cBa6A92F673d321d07C4bb688D7bfDFAf5DA2,
        0xC6B30ac8C0bCED25F3A396a14a02d7e6f1e7c3d7,
        0xC6D31ffFD5C43eB385d66379b043eA32AD15c739,
        0xCAfb8f232AE1dF50DEaF43627083A9E6d9271257,
        0xcb123A238AED4007F2D7EDFc485158f1d042A24f,
        0xcB504a16daA231E00c6c9862CfC61cF5fD76df76,
        0xCB69b912477D7BC9683DcBF69e3E21C3fc520d9a,
        0xcBA288BFff9bbE0d0bAcee9B83C3c1DE7d2b89Aa,
        0xcc8d9E4E8Ed55e9efAE68C353fD8DF140b9B14c1,
        0xcc8E2111a6Fc5D15109C2131C5691237353aE727,
        0xCC8F583d26cc03CC136E393BA5879Cf03372D650,
        0xCccdD71C5b2e67e109E24Aa3a5b8F89C65e4172B,
        0xCd2e70B2c7D12fE370456EC2415105C714802541,
        0xcd67A5F4a13bd1d0670fa8DC2Ea4047F3245684D,
        0xCD9bb0fB347BB76dF79b401d93241b41966D774f,
        0xcE685DE786037F0Ee0D2688aA80c130142c89249,
        0xCEB7bde7F6F7f52fB569d0F72E5a8009cF2d616d,
        0xcf2BEF424922384d66cABd3Ce46A119b1b18caf4,
        0xcf6a470F00b096b384A51cf5a758AE0806057b53,
        0xCfb935c7F44D15fF55652DC70D9cBdb96C30daDa,
        0xcFCdAf5B29b04E0605c33ffc8aE003EEf7Aa2d74,
        0xCfEdc3F208B9777619B50Fb37e2e3584402E5a16,
        0xd0A7D45ee397303A8fb197B822C2Ade9259Ab378,
        0xD0B489731dE5bEbC537e6A9d864270d12dAE586f,
        0xD1190DF947D118B77d5654A30C81d44A581b062C,
        0xD20B31Be8F6743B501D11a39c846b8cBc33e704D,
        0xD22CD685e04cE13422A46Ce55993Abe1A64Dd03E,
        0xD2a29A98DE084F59ac3532D661b767cd34d0Fb41,
        0xD2fcDBcA8277DdA1b9e768A5Ef0de0406F6663e3,
        0xD31b7EC23567267Ce32dd955a17331db4cE157c9,
        0xD3548fB3fD52ee8b8d2A048562A836BF330B10ad,
        0xD4D933A01f2a5136dE45470be393D538965E7E09,
        0xD54082aF7Fbf2d82EB7c3783eab86Ce900109c9a,
        0xD69bD92A59AFa514F14b8487686dC344b2F8e528,
        0xd6cfF4551953edD2FF11c4D1758bA741d5A030Ec,
        0xd70D41f353e73C71FE34B50525d3C3F41ab118Ef,
        0xD7e41c8aA3d1D1055C79D1cEFA6e4D0786D9A58e,
        0xD81BbEcd60eBfF0DEA9EA046A9FC25bfe8710F96,
        0xd8f92292A5daaD39b7C2E9375488457108217197,
        0xD912ECE0c5e4F2625e89618e645ec718CE187E6B,
        0xd918f20F56660060Ab028633276020029ff0dBf9,
        0xd971F6e130C940F688cCE8BC100b09D811BFCca2,
        0xd9a78789Df17505C3681A25943C208263080D089,
        0xdB57afC36D20fAA4b06d70DABE011c7994Ad7923,
        0xdb98DbB2141D1fcafe148b4590F1BDb088a1DD41,
        0xdcebe36a2b03E882B43712fAec128E237E0ED522,
        0xdcFF890b54C14879Be6567E204B05201b1828718,
        0xDd2cD9c7eddd2edFE76e721C9652Da7eF7B27e6d,
        0xddD67AdF98dA1E4da21Ce9c5ab5E33efb9ec473e,
        0xde9a72f1736a3e10cD6B297E306c9f9a49808507,
        0xdEd8B945218e82Fe19F082404f792ad4C5642c80,
        0xDfBAf7d00aE8178A8E59C0725C0C89CaeA266638,
        0xe07C55DfD3937d88fa74d3551Ce3207D68114BaB,
        0xE0d2f7c9FAD901F00321734E6Ecc97824CAe0556,
        0xE19F2603C33F2D08045B5ddbd5fc7E54D8ECfD45,
        0xe1cd8941418e5324e2B4EF08c4b956208ed7E91D,
        0xe29aBe7f8662018D501EBA2D74f21361D6811B45,
        0xE3D1629624e0F1A63412932a5D034A76b90d467C,
        0xE59703FB51509975F124A0B2E1f023d90bdaB81F,
        0xE63121DD7C1c7220dfc660a0D25f3421CE38798B,
        0xE6A3aB493C404E1A5ffb1123B129EDBfa0141cf6,
        0xe6cb7B30f8b3f8E5d983e20F437F2F060BB4BAAD,
        0xE6e40E20D1eC6513aa6430621c36B2478C0a40E7,
        0xe8C732a149932a6AEF6D0AB0E80BA17F5Ae01701,
        0xE8d1F574681b38208FffB351B9fcedF7A90a2a0a,
        0xE8f479A33F0Ce458c5d7ed22e438A76604eFe609,
        0xE936702567AAc37c0F4F9d1c2a6b5e0329D50841,
        0xE9cdCe13919c5Ca2Fe4A750F01Fe7831b331b1C7,
        0xeAAC7c7f61f6540A3ca47EAB6c0ecc51a59225FE,
        0xeb2Db627c3c80d7b200D406EEe1EA4C10c30911C,
        0xEc97fA5c6fa70AD581a4334766AC3b42E4e60fA7,
        0xECfAC686Ebb3DB10029C20567DE8d926Ebe03Fd7,
        0xeDCd83F179aaC83568C651Bce26F00eC8CbA07a9,
        0xEe78697017c5Cf0A648afB30Da8f271481bf5C9b,
        0xEf6Ef2a058b995817D7FD1c396716CbA215B8C0C,
        0xefdca0163F611e44D80B4CBead43c8A32e7dfC4d,
        0xf00317A5cfcF5EFa42FaFd7997cB6A8Faf92769E,
        0xf0055d648363B794cE8Fc61F9e3f4D37447202BF,
        0xf094C2406f91E946d8C4757A2F8c00D9Ec4D703E,
        0xF0e9c2cD91Eb01e89A45D10cb56d733ECFBeEd59,
        0xf18B25D2AA78EDC60b6ADA5e5dce09fd39148D8c,
        0xF383203F2d96F033D163edd8dbc9a98eD2292A3a,
        0xf41ed49494491761FDd04665771C6844412F21b8,
        0xf45319cA86E73C0Dd5290Be2f2A666bBBD545bC3,
        0xF4891F12FB71Cff79d098813AC7F0a551ab857cf,
        0xF4ce75FB8b910375CC9ABAE1207495376C1b84f2,
        0xF4e5E180a3398AdeA335Bd84C715918a223EC1b9,
        0xF5A7dBc60BF22D04983dE7e33E50FFdCa3327EbC,
        0xF5B29D49D7C599537BaD339a0618aF471203dfE0,
        0xF690cdbFb7546dEEdd96FA937526ddfC87A3003F,
        0xf6C2D71F8Fa8bE13BFeC6D8eb8028279Ed7C081b,
        0xF78f82627d4C9fD5E57bedF19904117218FB26D7,
        0xF7eeDd2bC737406d46d4cBFd51c2E90A6979987d,
        0xF7ef3935aCb22079C7c2107f7a2f508C76b431EB,
        0xF8971D48aC34C4434DEc5Cd2Da76E0fb37e6C8b2,
        0xf979Ef95a300d4b42C51e1c24EDb002d98A18B7e,
        0xF9D64D9D68CFD7b832352e8df062b2AF10121EA5,
        0xfb39b44BE29508C0F31438904c6872bC512B1e72,
        0xfCa19721fFf69D8F4452b774A03c130e10139716,
        0xfd7adf79fE1b3C6CcA09aE9F90B8fabEacc0F1Cf,
        0xFdeDdB79801746844c6FCf19A6Eff0D51A2c0471,
        0xfED9fC68eA0Ec3CE1A9507b85468D72575d98A1f,
        0xFEFCDD25c4b2cF8E37A0739b1f540c00D67E2aE2,
        0xff66a8910B66CD4aE51002B1508E824665c5D28c
    ];

    event RaffleStarted(uint256 indexed requestId);
    event RaffleWinner(address indexed raffleWinner);
    event RaffleEnded(uint256 indexed requestId);

    error RaffleCanBeRunOnlyOnce();

    modifier onlyOnce() {
        if (s_isRaffleStarted) revert RaffleCanBeRunOnlyOnce();
        _;
    }

    constructor(
        uint64 subscriptionId
    ) VRFConsumerBaseV2(0xAE975071Be8F8eE67addBC1A82488F1C24858067) {
        i_subscriptionId = subscriptionId;
        i_vrfCoordinator = VRFCoordinatorV2Interface(0xAE975071Be8F8eE67addBC1A82488F1C24858067);
    }


    function runRaffle(uint32 numberOfWinner) external onlyOwner {
        // We don't want anyone to be able to run a raffle
        // We want this raffle to be run only once
        s_isRaffleStarted = true;
        s_numWords = numberOfWinner;
        requestRandomWords();
    }

    function getWinners() external view returns (address[] memory) {
        return s_winners;
    }

    function requestRandomWords() internal {
        // Requesting s_numWords of random values from Chainlink VRF
        uint256 requestId = i_vrfCoordinator.requestRandomWords(
            i_keyHash,
            i_subscriptionId,
            i_requestConfirmations,
            i_callbackGasLimit,
            s_numWords
        );

        emit RaffleStarted(requestId);
    }

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords)
        internal
        virtual
        override
    {
        // Catching random values provided by Chainlink VRF as a callback
        // Decide winners
        uint256 length = s_numWords;
        for (uint i = 0; i < length; ) {
            address raffleWinner = s_participants[
                randomWords[i] % s_participants.length
            ];

            // add to winners array
            s_winners.push(raffleWinner);
            // remove from participants array
            // s_participants.remove(raffleWinner);

            emit RaffleWinner(raffleWinner);

            unchecked {
                ++i;
            }
        }

        emit RaffleEnded(requestId);
    }
}