// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.0;

interface IRaffleTicket {
  /**
   * @notice object containing a raffle information
   * @param raffleId id of the raffle that the tickets will be associated to
   * @param pricePerTicket price cost of one ticket
   * @param maxTickets maximum number of thickets that can be associated with the raffle
   * @param ticketSVGComposer contract address in charge of creating the raffle ticket svg string
   * @param paymentTokenDecimals decimals of the token used to purchase a ticket
   * @param paymentTokenSymbol symbol string of the token used to purchase a ticket
   */
  struct RaffleTicketConfiguration {
    uint256 raffleId;
    uint256 pricePerTicket;
    uint256 maxTickets;
    address ticketSVGComposer;
    uint8 paymentTokenDecimals;
    string paymentTokenSymbol;
  }

  /**
   * @notice method to get tha raffle address the tickets are associated to
   * @return address of the raffle
   */
  function RAFFLE() external view returns (address);

  /**
   * @notice method to get the address of the contract in charge of creating the tickets svg string
   * @return address of the svg composer contract
   */
  function TICKET_SVG_COMPOSER() external view returns (address);

  /**
   * @notice method to get the id of the raffle nft the tickets are associated to
   * @return id of the raffle
   */
  function RAFFLE_ID() external view returns (uint256);

  /**
   * @notice method to get the price cost per one ticket of the raffle
   * @return price cost of a ticket
   */
  function PRICE_PER_TICKET() external view returns (uint256);

  /**
   * @notice method to get the maximum number of thickets that can be created for the associated raffle
   * @return maximum number of tickets
   */
  function MAX_TICKETS() external view returns (uint256);

  /**
   * @notice method to get the decimals of the token used for purchasing a ticket
   * @return token decimals
   */
  function PAYMENT_TOKEN_DECIMALS() external view returns (uint8);

  /**
   * @notice method to create a number of tickets associated to a raffle for a specified address
   * @param receiver address that will receive the raffle tickets
   * @param quantity number of tickets of a raffle that need to be sent to the receiver address
   */
  function createTickets(address receiver, uint256 quantity) external;

  /**
   * @notice method to get how many tickets of the associated raffle have been sold
   * @return number of sold tickets
   */
  function ticketsSold() external view returns (uint256);

  /**
   * @notice method to eliminate (burn) a ticket
   * @param ticketId id that needs to be eliminated
   * @dev unsafely burns a ticket nft (without owners approval). only callable by Raffle contract. This is
          so owners dont need to spend gas by allowing the burn.
   */
  function destroyTicket(uint256 ticketId) external;

  /**
   * @notice method to get the symbol of the token used for ticket payment
   * @return string of the payment token symbol
   */
  function getPaymentTokenSymbol() external view returns (string memory);
}

pragma solidity ^0.8.0;

import {IRaffleTicket} from '../interfaces/IRaffleTicket.sol';

library RaffleConfig {
  /**
  * @notice method to get the time in seconds of the start buffer.
  * @return start buffer time in seconds
  * @dev This time is to have a waiting period between raffle creation and raffle start (raffle tickets can be purchased)
         so raffle creator can cancel if something went wrong on creation.
  */
  uint16 public constant RAFFLE_START_BUFFER = 3600; // 1 hour

  /// @notice defines the possible raffle states
  enum RaffleStates {
    CREATED,
    ACTIVE, // users can buy raffle tickets
    RAFFLE_SUCCESSFUL, // ready to execute random number to choose winner
    CANCELED,
    EXPIRED, // not reached soft cap and has expired
    FINISHED // winner has been chosen,
  }

  // TODO: provably add more stuff like timestamps block numbers etc
  /**
   * @notice object with a Raffle information
   * @param raffleId sequential number identifying the raffle. Its the NFT id
   * @param minTickets minimum number of tickets to be sold before raffle duration for a raffle to be successful
   * @param canceled flag indicating if the raffle has been canceled
   * @param ticketSalesCollected flag indicating if the ticket sales balance has been withdrawn to raffle creator
   * @param maxTickets maximum number of tickets that the raffle can sell.
   * @param prizeNftCollected flag indicating if the raffle winner has collected the prize NFT
   * @param randomWordFulfilled flag indicating if a random word has already been received by Chainlink VRF
   * @param creationTimestamp time in seconds of the raffle creation
   * @param expirationDate raffle expiration timestamp in seconds
   * @param raffleDuration raffle duration in seconds
   * @param pricePerTicket price that a raffle ticket is sold for. Denominated in gas token where the
            Raffle has been deployed
   * @param prizeNftId id of the raffle prize NFT. NFT that is being raffled
   * @param prizeNftAddress address of the raffle prize NFT
   * @param vrfRequestId identification number of the VRF request to get a random work
   * @param randomWord word resulting of querying VRF
   * @param vrfRequestIdCost gas cost of requesting a random word to VRF
   * @param ticketWinner raffle ticket that has been selected as raffle winner. Owner of the raffle ticket NFT will be
            able to withdraw the prize NFT.
   * @param ticketWinnerSelected flag indicating if if a raffle ticket has been selected as winner
   */
  struct RaffleConfiguration {
    uint256 raffleId;
    uint40 minTickets;
    address raffleTicket;
    bool canceled;
    bool ticketSalesCollected;
    uint40 maxTickets;
    bool prizeNftCollected;
    bool randomWordFulfilled;
    uint40 creationTimestamp;
    uint40 expirationDate;
    uint40 raffleDuration;
    uint256 pricePerTicket;
    uint256 prizeNftId;
    address prizeNftAddress;
    uint256 ticketWinner;
    bool ticketWinnerSelected; // TODO: provably not needed if we use ticketWinner??
  }

  /**
   * @notice method to get the current state of a raffle NFT
   * @param raffleConfig raffle Nft configuration object
   * @return raffle NFT current state
   */
  function getRaffleState(RaffleConfiguration memory raffleConfig)
    external
    view
    returns (RaffleStates)
  {
    if (raffleConfig.ticketWinnerSelected) {
      return RaffleStates.FINISHED;
    } else if (
      IRaffleTicket(raffleConfig.raffleTicket).ticketsSold() ==
      raffleConfig.maxTickets ||
      (IRaffleTicket(raffleConfig.raffleTicket).ticketsSold() >
        raffleConfig.minTickets &&
        raffleConfig.expirationDate < uint40(block.timestamp))
    ) {
      return RaffleStates.RAFFLE_SUCCESSFUL;
    } else if (raffleConfig.canceled) {
      return RaffleStates.CANCELED;
    } else if (raffleConfig.expirationDate < uint40(block.timestamp)) {
      return RaffleStates.EXPIRED;
    } else if (
      raffleConfig.creationTimestamp + RAFFLE_START_BUFFER <
      uint40(block.timestamp)
    ) {
      return RaffleStates.ACTIVE;
    } else {
      return RaffleStates.CREATED;
    }
  }
}