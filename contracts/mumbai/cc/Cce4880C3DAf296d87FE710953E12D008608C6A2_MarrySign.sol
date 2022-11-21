// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import '@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol';
import './CurrencyConverter.sol';

// import "hardhat/console.sol";

/**
 * @title MarrySign allows a couple to give their marital vows to each other digitally.
 */
contract MarrySign {
  /// @notice Import CurrencyConverter library.
  using CurrencyConverter for uint256;

  enum AgreementState {
    Created,
    Accepted,
    Refused,
    Terminated
  }

  /**
   * @notice The Agreement structure is used to store agreement data.
   */
  struct Agreement {
    /// @dev Unique hash of the agreement which is used as its ID.
    bytes32 id;
    /// @dev The first party of the agreement (agreement starter).
    address alice;
    /// @dev The second party fo the agreement (agreement acceptor).
    address bob;
    /// @dev Vow text.
    bytes content;
    /// @dev A penalty which the one pays for agreement termination. USD * 10**2
    uint256 terminationCost;
    /// @dev Agreement status.
    AgreementState state;
    /// @dev Create/update date in seconds from Unix epoch.
    uint256 updatedAt;
  }

  /**
   * @notice The Pointer structure is used to detect deleted agreements. If Pointer.isSet == false, then it's a deleted agreement.
   */
  struct Pointer {
    uint256 index;
    bool isSet;
  }

  /// @dev Some features are only available to the contract owner, e.g. withdrawal.
  error CallerIsNotOwner();
  /// @dev Agreement.content cannot be empty.
  error EmptyContent();
  /// @dev We don't allow zero termination cost.
  error ZeroTerminationCost();
  /// @dev When Bob is not set.
  error BobNotSpecified();
  /// @dev We use it to check Agreement's createdAt, updatedAt, etc. timestamps.
  error InvalidTimestamp();
  /// @dev When the caller is not authorized to call a function.
  error AccessDenied();
  /// @dev We check if the termination cost is close to what user pays on agreement termination. If not, we fire the error.
  error WrongAmount();
  /// @dev if there is no an active agreement by given criteria.
  error AgreementNotFound();

  /**
   * @notice Is emitted when a new agreement is created.
   * @param id {bytes32} The newly-created agreement ID.
   */
  event AgreementCreated(bytes32 id);
  /**
   * @notice Is emitted when the agreement is accepted by the second party (Bob).
   * @param id {bytes32} The accepted agreement ID.
   */
  event AgreementAccepted(bytes32 id);
  /**
   * @notice Is emitted when the agreement is refused by any party.
   * @param id {bytes32} The refused agreement ID.
   */
  event AgreementRefused(bytes32 id);
  /**
   * @notice Is emitted when the agreement is terminated by any party.
   * @param id {bytes32} The terminated agreement ID.
   */
  event AgreementTerminated(bytes32 id);

  /// @dev Allowed termination cost set and paid difference in Wei. Because of the volatility.
  uint256 public constant ALLOWED_TERMINATION_COST_DIFFERENCE = 1000;

  /// @dev We charge this percent of the termination cost for our service.
  uint8 private constant SERVICE_FEE_PERCENT = 10;

  /// @dev The contract owner.
  address payable private owner;
  /// @dev List of all agreements created.
  Agreement[] private agreements;
  /// @dev Maps Agreement.id to Agreement index for easier navigation.
  mapping(bytes32 => Pointer) private pointers;

  /// @dev Used for making Agreement.IDs trully unique.
  uint256 private randomFactor;

  /// @dev Chainlink DataFeed client.
  AggregatorV3Interface private priceFeed;

  /**
   * @notice Contract constructor.
   * @param priceFeedAddress {address} Chainlink Price Feed address.
   */
  constructor(address priceFeedAddress) payable {
    priceFeed = AggregatorV3Interface(priceFeedAddress);
    owner = payable(msg.sender);
  }

  /**
   * @notice Get the number of all created agreements.
   * @return {uint256}
   */
  function getAgreementCount() public view returns (uint256) {
    return agreements.length;
  }

  /**
   * @notice Get an agreement.
   * @param id {bytes32} Agreement ID.
   * @return {Agreement}
   */
  function getAgreement(bytes32 id) public view returns (Agreement memory) {
    // If Pointer.isSet=false, it means that this pointer "doesn't exist".
    if (!pointers[id].isSet) {
      revert AgreementNotFound();
    }

    if (bytes32(agreements[pointers[id].index].id).length == 0) {
      revert AgreementNotFound();
    }

    return agreements[pointers[id].index];
  }

  /**
   * @notice Get an agreement by an address of one of the partners.
   * @param partnerAddress {address} Partner's address.
   * @return {Agreement}
   */
  function getAgreementByAddress(address partnerAddress)
    public
    view
    returns (Agreement memory)
  {
    for (uint256 i = 0; i < getAgreementCount(); i++) {
      if (
        agreements[i].state != AgreementState.Created &&
        agreements[i].state != AgreementState.Accepted
      ) {
        continue;
      }

      if (
        agreements[i].alice == partnerAddress ||
        agreements[i].bob == partnerAddress
      ) {
        return agreements[i];
      }
    }

    revert AgreementNotFound();
  }

  /**
   * @notice Get accepted (public) agreements.
   * @dev @todo: Optimize : there are two similar loops.
   * @dev @todo: Add pagination to not go over time/size limits.
   * @return {Agreement[]}
   */
  function getAcceptedAgreements() public view returns (Agreement[] memory) {
    uint256 acceptedCount = 0;

    for (uint256 i = 0; i < getAgreementCount(); i++) {
      if (agreements[i].state != AgreementState.Accepted) {
        continue;
      }

      acceptedCount++;
    }

    Agreement[] memory acceptedAgreements = new Agreement[](acceptedCount);

    uint256 j = 0;
    for (uint256 i = 0; i < getAgreementCount(); i++) {
      if (agreements[i].state != AgreementState.Accepted) {
        continue;
      }

      acceptedAgreements[j] = agreements[i];
      j++;
    }

    return acceptedAgreements;
  }

  /**
   * @notice Create a new agreement.
   * @param bob {address} The second party's adddress.
   * @param content {bytes} The vow content.
   * @param terminationCost {uint256} The agreement termination cost.
   * @param createdAt {uint256} The creation date in seconds since the Unix epoch.
   */
  function createAgreement(
    address bob,
    bytes memory content,
    uint256 terminationCost,
    uint256 createdAt
  ) public validTimestamp(createdAt) {
    if (content.length == 0) {
      revert EmptyContent();
    }
    if (bob == address(0)) {
      revert BobNotSpecified();
    }
    if (terminationCost == 0) {
      revert ZeroTerminationCost();
    }

    // Every agreement gets its own randomFactor to make sure all agreements have unique IDs.
    randomFactor++;

    bytes32 id = generateAgreementId(
      msg.sender,
      bob,
      content,
      terminationCost,
      randomFactor
    );

    Agreement memory agreement = Agreement(
      id,
      msg.sender,
      bob,
      content,
      terminationCost,
      AgreementState.Created,
      createdAt
    );

    agreements.push(agreement);

    pointers[id] = Pointer(getAgreementCount() - 1, true);

    emit AgreementCreated(id);
  }

  /*
   * @notice Accept the agreement by the second party (Bob).
   * @param id {bytes32} The agreement ID.
   * @param acceptedAt {uint256} The acceptance date in seconds since the Unix epoch.
   */
  function acceptAgreement(bytes32 id, uint256 acceptedAt)
    public
    validTimestamp(acceptedAt)
  {
    Agreement memory agreement = getAgreement(id);

    if (msg.sender != agreement.bob) {
      revert AccessDenied();
    }

    agreements[pointers[id].index].state = AgreementState.Accepted;
    agreements[pointers[id].index].updatedAt = acceptedAt;

    emit AgreementAccepted(id);
  }

  /*
   * @notice Refuse an agreement by either Alice or Bob.
   * @param id {bytes3} The agreement ID.
   * @param refusedAt {uint256} The refusal date in seconds since the Unix epoch.
   */
  function refuseAgreement(bytes32 id, uint256 refusedAt)
    public
    validTimestamp(refusedAt)
  {
    Agreement memory agreement = getAgreement(id);

    if (agreement.bob != msg.sender && agreement.alice != msg.sender) {
      revert AccessDenied();
    }

    agreements[pointers[id].index].state = AgreementState.Refused;
    agreements[pointers[id].index].updatedAt = refusedAt;

    emit AgreementRefused(id);
  }

  /*
   * @notice Terminate an agreement by either either Alice or Bob (involves paying compensation and service fee).
   * @param id {bytes32} The agreement ID.
   */
  function terminateAgreement(bytes32 id) public payable {
    Agreement memory agreement = getAgreement(id);

    if (agreement.bob != msg.sender && agreement.alice != msg.sender) {
      revert AccessDenied();
    }

    uint256 terminationCostInWei = CurrencyConverter.convertUSDToWei(
      agreement.terminationCost,
      priceFeed
    );

    // Make sure user pays the correct termination cost (taking into account the allowed difference).
    if (
      msg.value < terminationCostInWei - ALLOWED_TERMINATION_COST_DIFFERENCE ||
      msg.value > terminationCostInWei + ALLOWED_TERMINATION_COST_DIFFERENCE
    ) {
      revert WrongAmount();
    }

    // Calculate and transfer our service fees.
    uint256 fee = (terminationCostInWei * SERVICE_FEE_PERCENT) / 100;
    if (fee != 0) {
      owner.transfer(fee);
    }

    // Pay the rest to the oposite partner.
    uint256 compensation = terminationCostInWei - fee;
    if (agreement.alice == msg.sender) {
      // Alice pays Bob the compensation.
      payable(agreement.bob).transfer(compensation);
    } else {
      // Bob pays Alice the compensation.
      payable(agreement.alice).transfer(compensation);
    }

    delete agreements[pointers[id].index];
    // We have to somehow distinguish the terminated agreement from active ones.
    // That's because the array item deletion doesn't factually remove the element from the array.
    agreements[pointers[id].index].state = AgreementState.Terminated;

    emit AgreementTerminated(id);
  }

  /*
   * @notice Transfer contract funds to the contract-owner (withdraw).
   */
  function withdraw() public onlyOwner {
    owner.transfer(address(this).balance);
  }

  /**
   * @notice Get Chainlink PriceFeed version.
   */
  function getPriceFeedVersion() public view returns (uint256) {
    return getPriceFeed().version();
  }

  /**
   * @notice Get Chainlink PriceFeed instance.
   */
  function getPriceFeed() public view returns (AggregatorV3Interface) {
    return priceFeed;
  }

  /**
   * @notice Generate agreement hash which is used as its ID.
   */
  function generateAgreementId(
    address alice,
    address bob,
    bytes memory content,
    uint256 terminationCost,
    uint256 randomFactorParam
  ) private pure returns (bytes32) {
    bytes memory hashBytes = abi.encode(
      alice,
      bob,
      // @todo: Think about excluding content from here because if it's long, it can affect performance.
      content,
      terminationCost,
      randomFactorParam
    );
    return keccak256(hashBytes);
  }

  /**
   * @notice Check the validity of the timespamp.
   * @param timestamp {uint256} The timestamp being validated.
   */
  modifier validTimestamp(uint256 timestamp) {
    // @todo Improve the validation.
    // The condition timestamp == 0 || timestamp > block.timestamp + 15 seconds || timestamp < block.timestamp - 1 days
    // doesn't work in tests for some reason.
    if (timestamp == 0) {
      revert InvalidTimestamp();
    }
    _;
  }

  /**
   * @notice Check whether the caller is the contract-owner.
   */
  modifier onlyOwner() {
    if (msg.sender != owner) {
      revert CallerIsNotOwner();
    }
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import '@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol';

// import "hardhat/console.sol";

/**
 * @notice CurrencyConverter library allows to convert USD to ETH.
 *
 * Inspired by https://github.com/PatrickAlphaC/hardhat-fund-me-fcc/blob/main/contracts/PriceConverter.sol
 * (by https://github.com/PatrickAlphaC).
 */
library CurrencyConverter {
  /// @dev A multiplier which is used to support decimals.
  uint256 private constant MULTIPLIER = 10**18;

  /**
   * @notice Convert integer USD amount to Wei.
   * @return {uint256} An amount in Wei.
   */
  function convertUSDToWei(uint256 usdAmount, AggregatorV3Interface priceFeed)
    internal
    view
    returns (uint256)
  {
    (uint256 ethPrice, uint256 ethPriceDecimals) = getETHPriceInUSD(priceFeed);

    return
      uint256(((usdAmount * MULTIPLIER) / (ethPrice / 10**ethPriceDecimals)));
  }

  /**
   * @notice Return current ETH price in USD (multiplied to 10**18).
   * @return {uint256} Latest ETH price in USD.
   * @return {uint256} A number of decimals used to store the ETH price.
   */
  function getETHPriceInUSD(AggregatorV3Interface priceFeed)
    private
    view
    returns (uint256, uint256)
  {
    (, int256 answer, , , ) = priceFeed.latestRoundData();

    uint256 decimals = priceFeed.decimals();

    return (uint256(answer), decimals);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}