// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract CommonStruct {
    struct WillTrustedParty {
        address willAddress;
        address owner;
        string executeStatus;
        uint256 timeRequestExecute;
        uint256 secondsWaitToAbleToVoteExecute;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

import "./CommonStruct.sol";
import "./WillRegistry.sol";

contract Will is CommonStruct {
  /*===== STRUCTS =====*/
  struct Beneficiary {
    address walletAddress;
    string name;
    uint8 allocationPercentages;
  }

  struct ActivationRequest {
    address createdBy;
    uint256 createdTime;
    uint8 acceptedAmount;
    uint256 lastUpdatedTime;
    bool isRefused;
  }

  constructor() {
    owner = msg.sender;
    creationTimestamp = block.timestamp;
  }

  /*===== STAGE =====*/
  address private owner;
  uint256 private creationTimestamp;
  uint256 private assetValue;
  Beneficiary[] private beneficiaries;
  bool private isActivated;
  address  private registryWillAddress;
  address[] private trustedParties;
  ActivationRequest private activationRequest;
  address private willRegistryAddress;

  /*===== CONTANTS =====*/
  uint8 private ONE_HUNDRED = 100;
  //30 days => second 2592000
  uint256 private constant TIME_NOT_ACCEPT_ACTIVATION_REQUEST = 10;
  //30 days => second 2592000
  uint256 private constant TIME_READY_RECREATE_ACTIVATION_REQUEST = 10;
  string private constant EXECUTE_STATUS_NONE = "None";
  string private constant EXECUTE_STATUS_REQUEST = "Voting execute will exists, it's not time to vote yet";
  string private constant EXECUTE_STATUS_VOTING = "Voting execute will ready";

  /*===== ERRORS =====*/
  error OnlyOwnerCanCallFunction();
  error TrustedPartiesCanNotBeBeneficiary(address _address);
  error BeneficiaryCanNotBeTrustedParties(address _address);
  error OwnerCanNotBeBeneficiary();
  error ActivationRequestExisted();
  error OwnerCanNotBeTrustedParties();
  error OnlyNonActivatedWillCanCallFunction();
  error ActivationRequestNotWithinTimeAllowed();
  error CallSendMoneyToAddressFailed(address _address);
  error MaxTotalPercentagesOfBeneficiariesIs100();
  error WitnessNotFound(address _address);
  error ActivationRequestNotExisted();
  error OnlyTrustedPartiesCanCallFunction();
  error SomeoneRefusedToVote();
  error NotEnoughTimeToRecreateActivationRequest();
  error WitnessAlreadyExisted(address _address);

  /*===== MODIFIERS =====*/
  modifier onlyOwner() {
    if (!isOwner(msg.sender)) {
      revert OnlyOwnerCanCallFunction();
    }
    _;
  }

  modifier onlyNonActivatedWill() {
    if (isActivated) {
      revert OnlyNonActivatedWillCanCallFunction();
    }
    _;
  }

  modifier onlyTrustedParties() {
    if (!isTrustedParties(msg.sender)) {
      revert OnlyTrustedPartiesCanCallFunction();
    }
    _;
  }

  modifier onlyActivationRequestValid() {
    if (
      activationRequest.createdTime + TIME_NOT_ACCEPT_ACTIVATION_REQUEST >
      block.timestamp
    ) {
      revert ActivationRequestNotWithinTimeAllowed();
    } else if (activationRequest.isRefused) {
      revert SomeoneRefusedToVote();
    }
    _;
  }

  /*===== EVENTS =====*/
  event ActivationRequestCreated(address indexed sender, uint256 createdTime);

  /*===== FUNCTIONS =====*/

  function updateBeneficiaries(Beneficiary[] memory _beneficiaries)
  external
  onlyOwner
  onlyNonActivatedWill
  {
    require(
      _beneficiaries.length > 0,
      "Beneficinaries updated is required."
    );

    uint8 totalAllocationPercentage = 0;
    for (uint256 index = 0; index < _beneficiaries.length; index++) {
      //check if one of beneficinary is trusted parties, tx will be failed.
      if (isTrustedParties(_beneficiaries[index].walletAddress)) {
        revert BeneficiaryCanNotBeTrustedParties(
          _beneficiaries[index].walletAddress
        );
      }
      //check if one of beneficinary is testator, tx will be failed.abi
      if (_beneficiaries[index].walletAddress == owner) {
        revert OwnerCanNotBeBeneficiary();
      }
      // count to check total percentages assigned to beneficinary must less or equal to 100 percent
      totalAllocationPercentage += _beneficiaries[index]
      .allocationPercentages;
    }

    if (totalAllocationPercentage > ONE_HUNDRED) {
      revert MaxTotalPercentagesOfBeneficiariesIs100();
    }

    clearBeneficiaries();

    for (uint256 index = 0; index < _beneficiaries.length; index++) {
      beneficiaries.push(_beneficiaries[index]);
    }
  }

  //create activation request for trusted parties to approve
  function requestActiveWill() external onlyTrustedParties onlyNonActivatedWill {
    if (checkActivationRequestExist()) {
      revert ActivationRequestExisted();
    }

    if (activationRequest.isRefused && activationRequest.lastUpdatedTime > TIME_READY_RECREATE_ACTIVATION_REQUEST) {
      revert NotEnoughTimeToRecreateActivationRequest();
    }

    int256 witnessIndex = findIndexOfWitness(msg.sender);
    if (witnessIndex == - 1) {
      revert WitnessNotFound(msg.sender);
    }

    activationRequest = ActivationRequest({
      createdBy: msg.sender,
      createdTime: block.timestamp,
      acceptedAmount: 0,
      lastUpdatedTime: block.timestamp,
      isRefused: false
    });

    emit ActivationRequestCreated(msg.sender, block.timestamp);
  }

  function voteActiveWill(bool _vote)
  public
  onlyNonActivatedWill
  onlyActivationRequestValid
  {
    isTrustedParties(msg.sender);

    if (_vote) {
      if (checkActivationRequestExist()) {
        int256 witnessIndex = findIndexOfWitness(msg.sender);
        if (witnessIndex == - 1) {
          revert WitnessNotFound(msg.sender);
        }

        if (
          activationRequest.acceptedAmount + 1 ==
          trustedParties.length
        ) {
          distributeAssets();
        } else {
          activationRequest.acceptedAmount++;
        }
      } else {
        revert ActivationRequestNotExisted();
      }
    } else {
      activationRequest.isRefused = true;
      activationRequest.lastUpdatedTime = block.timestamp;
    }
  }

  function checkActivationRequestExist() public view returns (bool) {
    if (activationRequest.createdBy != address(0)) {
      return true;
    }
    return false;
  }

  function addTrustParties(address _address) private {

    if (isOwner(_address)) {
      revert OwnerCanNotBeTrustedParties();
    }

    if (isBeneficiaries(_address)) {
      revert TrustedPartiesCanNotBeBeneficiary(
        _address
      );
    }

    int256 indexInWitness = findIndexOfWitness(_address);
    if (indexInWitness == - 1) {
      trustedParties.push(_address);
    } else {
      revert WitnessAlreadyExisted(_address);
    }
  }


  function removeWitness(address _address) private {

    int256 indexOfWitness = findIndexOfWitness(_address);

    if (indexOfWitness == - 1) {
      revert WitnessNotFound(_address);
    }

    uint256 indexOfWitnessUint = uint256(indexOfWitness);
    if (indexOfWitnessUint < trustedParties.length - 1) {
      trustedParties[indexOfWitnessUint] = trustedParties[trustedParties.length - 1];
    }
    trustedParties.pop();
  }


  function updateTrustParties(
    address[] memory trustedPartiesRemoved,
    address[] memory trustedPartiesAdded
  ) external onlyOwner {
    require(
      trustedPartiesAdded.length > 0 || trustedPartiesRemoved.length > 0,
      "Need have change trustedParties for Will."
    );
    uint256 trustedPartiesRemovedSize = trustedPartiesRemoved.length;
    uint256 trustedPartiesAddedSize = trustedPartiesAdded.length;

    for (uint256 index = 0; index < trustedPartiesRemovedSize; index++) {
      removeWitness(trustedPartiesRemoved[index]);
    }

    for (uint256 index = 0; index < trustedPartiesAddedSize; index++) {
      addTrustParties(trustedPartiesAdded[index]);
    }

    callUpdateTrustedPartiesInWillRegistry(trustedPartiesAdded, trustedPartiesRemoved);

    //    bytes memory encodedData = abi.encodeWithSignature(
    //      "updateWill(Will,address[],address[])",
    //      _will,
    //      trustedPartiesRemoved,
    //      trustedPartiesAdded
    //    );
    //
    //    (bool success, bytes memory result) = registryWillAddress.call(encodedData);
    //    require(success, "Function call failed");
  }


  function findIndexOfWitness(address _address)
  private
  view
  returns (int256)
  {
    int256 response = - 1;
    for (uint256 index = 0; index < trustedParties.length; index++) {
      if (trustedParties[index] == _address) {
        return response = int256(index);
      }
    }
    return response;
  }

  function distributeAssets() private onlyNonActivatedWill {
    uint256 totalAssetAmount = address(this).balance;
    uint256 beneficiariesSize = beneficiaries.length;

    Beneficiary memory beneficiary;
    uint8 allocationPercentage;
    uint256 beneficiaryAmount;

    for (uint256 i = 0; i < beneficiariesSize; i++) {
      beneficiary = beneficiaries[i];
      beneficiaryAmount = (totalAssetAmount * allocationPercentage) / 100;
      transferTo(beneficiary.walletAddress, beneficiaryAmount);
    }
    isActivated = true;
  }

  function transferTo(address _recipient, uint256 amount) private {
    (bool sentStatus,) = payable(_recipient).call{value: amount}("");
    if (!sentStatus) {
      revert CallSendMoneyToAddressFailed(_recipient);
    }
  }

  function clearBeneficiaries() private {
    uint256 arrLength = beneficiaries.length;
    for (uint256 index = 0; index < arrLength; index++) {
      beneficiaries.pop();
    }
  }

  function isOwner(address _address) public view returns (bool) {
    return owner == _address;
  }

  function isTrustedParties(address _address) private view returns (bool) {
    if (trustedParties.length > 0) {
      for (uint256 index = 0; index < trustedParties.length; index++) {
        if (trustedParties[index] == _address) {
          return true;
        }
      }
    }

    return false;
  }

  function isBeneficiaries(address _address) private view returns (bool) {
    if (beneficiaries.length > 0) {
      for (uint256 index = 0; index < beneficiaries.length; index++) {
        if (beneficiaries[index].walletAddress == _address) {
          return true;
        }
      }
    }
    return false;
  }

  function getOwner() external view returns (address) {
    return owner;
  }

  function getCreationTimestamp() public view returns (uint256) {
    return creationTimestamp;
  }

  function getAssetValue() public view returns (uint256) {
    return assetValue;
  }

  function getStatusActive() public view returns (bool) {
    return isActivated;
  }

  function getBeneficiariesLength() public view returns (uint256) {
    return beneficiaries.length;
  }

  function getBeneficiary(uint256 _index)
  public
  view
  returns (Beneficiary memory)
  {
    return beneficiaries[_index];
  }

  function getTrustedParties() public view returns (address[] memory) {
    return trustedParties;
  }

  function registerWillAddress(address _address) external onlyNonActivatedWill onlyOwner {
    willRegistryAddress = _address;

    // first register
    WillTrustedParty memory willTrustedParty =  WillTrustedParty(
          address(this),
          owner,
          EXECUTE_STATUS_NONE,
          activationRequest.createdTime,
          TIME_NOT_ACCEPT_ACTIVATION_REQUEST
        );

    WillRegistry willRegistry = WillRegistry(willRegistryAddress);
    willRegistry.registerWill(willTrustedParty, trustedParties);
  }

  function callUpdateTrustedPartiesInWillRegistry(
    address[] memory trustedPartiesAdded,
    address[] memory trustedPartiesRemoved
  ) private {
    if (willRegistryAddress == address(0)) {
      return;
    }

    // first register
    WillTrustedParty memory willTrustedParty =  WillTrustedParty(
          address(this),
          owner,
          getExecuteStatus(),
          activationRequest.createdTime,
          TIME_NOT_ACCEPT_ACTIVATION_REQUEST
        );

    WillRegistry willRegistry = WillRegistry(willRegistryAddress);
    willRegistry.updateWill(willTrustedParty, trustedPartiesRemoved, trustedPartiesAdded);
  }

  function getExecuteStatus() public view returns (string memory) {
    if (checkActivationRequestExist()) {
      if (activationRequest.isRefused) {
        return EXECUTE_STATUS_NONE;
      } else {
        if (activationRequest.createdTime + TIME_NOT_ACCEPT_ACTIVATION_REQUEST < block.timestamp) {
          return EXECUTE_STATUS_VOTING;
        } else {
          return EXECUTE_STATUS_REQUEST;
        }
      }
    } else {
      return EXECUTE_STATUS_NONE;
    }
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

import "./Will.sol";
import "./CommonStruct.sol";

contract WillRegistry is CommonStruct {
    mapping(address => WillTrustedParty[]) private trustedPartyToWills;

    constructor() {}

    function listWillsAssignedSelf()
        external
        view
        returns (WillTrustedParty[] memory)
    {
        return trustedPartyToWills[msg.sender];
    }

    function registerWill(
        WillTrustedParty memory _will,
        address[] memory trustedParties
    ) public {
        for (uint index = 0; index < trustedParties.length; index++) {
            if (
                trustedPartyToWills[trustedParties[index]][0].willAddress ==
                address(0)
            ) {
                trustedPartyToWills[trustedParties[index]][0] = _will;
            } else {
                trustedPartyToWills[trustedParties[index]].push(_will);
            }
        }
    }

    function updateWill(
        WillTrustedParty memory _will,
        address[] memory trustedPartiesRemoved,
        address[] memory trustedPartiesAdded
    ) public {
        require(_will.willAddress != address(0), "Will address is require.");
        require(
            trustedPartiesAdded.length > 0 || trustedPartiesRemoved.length > 0,
            "Need have change trustedParties for Will."
        );
        require(
            _will.willAddress == msg.sender,
            "Invalid Will contract address."
        );
        checkValidOwnerOfWill(_will.willAddress, _will.owner);

        if (trustedPartiesRemoved.length > 0) {
            unAssignWillForTrustedParties(
                _will.willAddress,
                trustedPartiesRemoved
            );
        }

        if (trustedPartiesAdded.length > 0) {
            assignWillForTrustedParties(_will, trustedPartiesAdded);
        }
    }

    function checkValidOwnerOfWill(
        address _willAddress,
        address _willOwnerAddress
    ) private view {
        uint size;
        assembly {
            size := extcodesize(_willAddress)
        }
        require(size > 0, "The willAddress must be a contract address");

        Will will = Will(_willAddress);
        bool isValidOwner = will.isOwner(_willOwnerAddress);
        require(
            isValidOwner,
            "Only Will contract owner can call this function."
        );
    }

    function unAssignWillForTrustedParties(
        address _willAddress,
        address[] memory trustedPartiesAddress
    ) private {
        WillTrustedParty[] storage wills;
        for (
            uint trustedPartyIndex = 0;
            trustedPartyIndex < trustedPartiesAddress.length;
            trustedPartyIndex++
        ) {
            wills = trustedPartyToWills[
                trustedPartiesAddress[trustedPartyIndex]
            ];

            for (uint willIndex = 0; willIndex < wills.length; willIndex++) {
                if (wills[willIndex].willAddress == _willAddress) {
                    wills[willIndex] = wills[wills.length - 1];
                    wills.pop();
                    break;
                }
            }
        }
    }

    function assignWillForTrustedParties(
        WillTrustedParty memory _will,
        address[] memory trustedPartiesAddress
    ) private {
        WillTrustedParty[] storage wills;
        int assignedWillIndex;
        for (
            uint trustedPartyIndex = 0;
            trustedPartyIndex < trustedPartiesAddress.length;
            trustedPartyIndex++
        ) {
            wills = trustedPartyToWills[
                trustedPartiesAddress[trustedPartyIndex]
            ];
            assignedWillIndex = -1;

            for (uint willIndex = 0; willIndex < wills.length; willIndex++) {
                if (wills[willIndex].willAddress == _will.willAddress) {
                    assignedWillIndex = int(willIndex);
                    break;
                }

                if (assignedWillIndex == -1) {
                    wills.push(_will);
                }
            }
        }
    }
}