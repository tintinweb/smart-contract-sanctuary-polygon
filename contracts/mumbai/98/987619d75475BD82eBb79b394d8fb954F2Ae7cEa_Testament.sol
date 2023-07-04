// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

contract Testament {
  /* ================ CONSTANT ================== */
  uint8 private constant ONE_HUNDRED_PERCENT = 100;
  //30 days => second 2592000
  uint256 private constant TIME_NOT_ACCEPT_ACTIVATION_REQUEST = 10;
  /*================= STRUCT =====================*/
  struct Beneficiary {
    address walletAddress;
    string name;
    uint8 allocationPercentages;
  }

  struct ActivationRequest {
    address createdBy;
    uint256 createdTime;
    uint8 acceptedAmount;
  }

  /*================= STAGE =====================*/
  constructor(address _registryWillAddress) {
    registryWillAddress = _registryWillAddress;
    testator = msg.sender;
    creationTimestamp = block.timestamp;
  }

  address private testator;
  uint256 private creationTimestamp;
  Beneficiary[] private beneficiaries;
  address[] private witness;
  bool private activated;
  uint8 private confirmationMissAmount;
  uint256 private lastConfirmationTimestamp;
  mapping(address => bool) private witnessAccepted;
  bool private registered;
  address private registryWillAddress;
  bool private existRequestActive;
  ActivationRequest private activationRequest;

  /*================= EVENT =====================*/
  event ConfirmationRequestSent(
    address indexed testator,
    uint256 confirmationTime
  );

  event WillActivated(address indexed testator);
  event ProofOfLifeSuccess(address indexed testator);
  event MoneyTransferred(
    address indexed sender,
    address receiver,
    uint256 amount
  );

  event DepositSuccess(address indexed sender, uint256 amount);
  event WithdrawSuccess(address indexed sender, uint256 amount);
  event UpdatedSuccess(address indexed sender);
  event ActivationRequestCreated(address indexed sender, uint256 createdTime);

  /*================ ERROR ========================*/
  error CallSendMoneyToAddressFailed(address _address);
  error NotRegistered();
  error BeneficiaryExisted(address _address);
  error TotalAllocationPercentExeedOneHundredPercent();
  error WitnessAlreadyExisted(address _address);
  error BeneficineryNotFound(address _address);
  error WitnessNotFound(address _address);
  error BeneficineryCanNotIsOwner();
  error WitnessCanNotIsOwner();
  error OnlyRegistryWillCanUpdateRegistered();
  error ActivationRequestNotWithinTimeAllowed();
  error ActivationRequestExisted();
  error ActivationRequestNotExisted();
  error CallUpdateActivatedStatusFail();

  /*================= MODIFIER =====================*/
  modifier onlyNonActivated() {
    require(!activated, "Will activated");
    _;
  }

  modifier onlyOwner() {
    require(testator == msg.sender, "Caller is not the owner");
    _;
  }

  modifier onlyRegistered() {
    require(
      registered,
      "The will must be registered in order to fulfill function"
    );
    _;
  }

  modifier onlyActivationRequestReadyApproved() {
    if (
      activationRequest.createdTime + TIME_NOT_ACCEPT_ACTIVATION_REQUEST >
      block.timestamp
    ) {
      revert ActivationRequestNotWithinTimeAllowed();
    }
    _;
  }

  /*================= FUNCTION =====================*/
  function addBeneficiary(
    address _address,
    uint8 _percentages,
    string memory _name
  ) external onlyOwner {
    validateRegistered();

    if (isOwner(_address)) {
      revert BeneficineryCanNotIsOwner();
    }

    checkBeneficineryNotAdded(_address);
    checkValidPercentages(_percentages);
    beneficiaries.push(Beneficiary(_address, _name, _percentages));

    lastConfirmationTimestamp = block.timestamp;
  }

  function addWitness(address _address) external onlyOwner {
    validateRegistered();

    if (isOwner(_address)) {
      revert WitnessCanNotIsOwner();
    }

    int256 indexInWitness = findIndexOfWitness(_address);
    if (indexInWitness == - 1) {
      witness.push(_address);
    } else {
      revert WitnessAlreadyExisted(_address);
    }

    lastConfirmationTimestamp = block.timestamp;
  }

  function deleteBeneficinery(address _address) external onlyOwner {
    validateRegistered();
    int256 indexOfBeneficinery = findIndexOfBeneficinery(_address);

    if (indexOfBeneficinery == - 1) {
      revert BeneficineryNotFound(_address);
    }

    uint256 indexOfBeneficineryUint = uint256(indexOfBeneficinery);
    if (indexOfBeneficineryUint < beneficiaries.length - 1) {
      beneficiaries[indexOfBeneficineryUint] = beneficiaries[
        beneficiaries.length - 1
        ];
    }
    beneficiaries.pop();

    lastConfirmationTimestamp = block.timestamp;
  }

  function deleteWitness(address _address) external onlyOwner {
    validateRegistered();
    int256 indexOfWitness = findIndexOfWitness(_address);

    if (indexOfWitness == - 1) {
      revert WitnessNotFound(_address);
    }

    uint256 indexOfWitnessUint = uint256(indexOfWitness);
    if (indexOfWitnessUint < witness.length - 1) {
      witness[indexOfWitnessUint] = witness[witness.length - 1];
    }
    witness.pop();

    lastConfirmationTimestamp = block.timestamp;
  }

  // //Called registry: using automation
  function sendProofOfLifeRequest() external onlyNonActivated onlyRegistered {
    if (registryWillAddress != msg.sender) {
      revert OnlyRegistryWillCanUpdateRegistered();
    }

    if (confirmationMissAmount >= 5) {
      activateWill();
    } else {
      //Update the confirmation time
      lastConfirmationTimestamp = block.timestamp;
      confirmationMissAmount++;

      emit ConfirmationRequestSent(testator, block.timestamp);
    }

    lastConfirmationTimestamp = block.timestamp;
  }

  //TODO: miss case request active will
  function activateWill() internal onlyNonActivated {
    //Distribute assets to the beneficiaries
    distributeAssets();
    (bool success,) = registryWillAddress.call(
      abi.encodeWithSignature(
        "updateActivated(address,bool)",
        address(this),
        true
      )
    );
    if (!success) {
      revert CallUpdateActivatedStatusFail();
    }
    emit WillActivated(msg.sender);
  }

  function distributeAssets() private onlyNonActivated {
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
    activated = true;
  }

  function transferTo(address _recipient, uint256 amount)
  private
  onlyNonActivated
  {
    (bool sentStatus,) = payable(_recipient).call{value: amount}("");
    if (!sentStatus) {
      revert CallSendMoneyToAddressFailed(_recipient);
    }
    emit MoneyTransferred(address(this), _recipient, amount);
  }

  function setRegistrationStatus(bool status) public onlyNonActivated {
    if (registryWillAddress != msg.sender) {
      revert OnlyRegistryWillCanUpdateRegistered();
    }
    registered = status;
  }

  function deposit() external payable onlyNonActivated onlyOwner {
    validateRegistered();
    emit DepositSuccess(msg.sender, msg.value);
  }

  function proofOfLife() external onlyNonActivated onlyOwner {
    validateRegistered();

    uint8 amount = confirmationMissAmount - 1;

    if (amount >= 5) {
      activateWill();
    } else {
      confirmationMissAmount = 0;
    }
  }

  //TODO
  function requestActive() external onlyNonActivated {
    validateRegistered();

    if (checkActivationRequestExist()) {
      revert ActivationRequestExisted();
    }

    int256 witnessIndex = findIndexOfWitness(msg.sender);
    if (witnessIndex == - 1) {
      revert WitnessNotFound(msg.sender);
    }

    activationRequest = ActivationRequest({
      createdBy: msg.sender,
      createdTime: block.timestamp,
      acceptedAmount: 0
    });

    emit ActivationRequestCreated(msg.sender, block.timestamp);
  }

  function acceptActiveRequest()
  public
  onlyNonActivated
  onlyActivationRequestReadyApproved
  {
    validateRegistered();

    if (checkActivationRequestExist()) {
      int256 witnessIndex = findIndexOfWitness(msg.sender);
      if (witnessIndex == - 1) {
        revert WitnessNotFound(msg.sender);
      }

      if (activationRequest.acceptedAmount + 1 == witness.length) {
        activateWill();
      } else {
        activationRequest.acceptedAmount++;
      }
    } else {
      revert ActivationRequestNotExisted();
    }
  }

  function checkActivationRequestExist() public view returns (bool) {
    if (activationRequest.createdBy != address(0)) {
      return true;
    }
    return false;
  }

  function withdraw(uint256 _amount) public onlyOwner onlyNonActivated {
    validateRegistered();
    require(address(this).balance >= _amount, "Insufficient balance");
    (bool success,) = msg.sender.call{value: _amount}("");
    require(success, "Failed to send Ether");
    emit WithdrawSuccess(msg.sender, _amount);
  }

  function getAllBeneficiaries() public view returns (Beneficiary[] memory) {
    return beneficiaries;
  }

  function getAssetAmount() public view returns (uint256) {
    return address(this).balance;
  }

  function getConfirmationMissAmount() public view returns (uint8) {
    return confirmationMissAmount;
  }

  function getConfirmationTimestamp() public view returns (uint256) {
    return lastConfirmationTimestamp;
  }

  function getTestator() public view returns (address) {
    return testator;
  }

  function getStatusWill() public view returns (bool) {
    return activated;
  }

  function getCreationTimestamp() public view returns (uint256) {
    return creationTimestamp;
  }

  function getWitness() public view returns (address[] memory) {
    return witness;
  }

  function getRegistrationStatus() public view returns (bool) {
    return registered;
  }

  function validateRegistered() private view {
    if (!registered) {
      revert NotRegistered();
    }
  }

  function findIndexOfBeneficinery(address _address)
  private
  view
  returns (int256)
  {
    int256 response = - 1;
    for (uint256 index = 0; index < beneficiaries.length; index++) {
      if (beneficiaries[index].walletAddress == _address) {
        response = int256(index);
      }
    }
    return response;
  }

  function checkBeneficineryNotAdded(address _address) private view {
    int256 indexOfBeneficinery = findIndexOfBeneficinery(_address);
    if (indexOfBeneficinery != - 1) {
      revert BeneficiaryExisted(_address);
    }
  }

  function getTotalAllocationPercentages() private view returns (uint8) {
    uint8 totalAllocationPercentages = 0;
    for (uint256 index = 0; index < beneficiaries.length; index++) {
      totalAllocationPercentages += beneficiaries[index]
        .allocationPercentages;
    }
    return totalAllocationPercentages;
  }

  function checkValidPercentages(uint8 _percentages) private view {
    if (
      getTotalAllocationPercentages() + _percentages > ONE_HUNDRED_PERCENT
    ) {
      revert TotalAllocationPercentExeedOneHundredPercent();
    }
  }

  function findIndexOfWitness(address _address)
  private
  view
  returns (int256)
  {
    int256 response = - 1;
    for (uint256 index = 0; index < witness.length; index++) {
      if (witness[index] == _address) {
        return response = int256(index);
      }
    }
    return response;
  }

  function isOwner(address _address) private view returns (bool) {
    return testator == _address;
  }
}