pragma solidity ^0.8.0;

import {IPaymentSystem} from './interfaces/IPaymentSystem.sol';

contract PaymentSystem is IPaymentSystem {
  /// @inheritdoc IPaymentSystem
  uint8 public immutable RAFFLE_FEE;

  /// @inheritdoc IPaymentSystem
  address public immutable FEE_COLLECTOR;

  /**
   * @param raffleFee fee subtracted from the raffle tickets total sale, when raffle successful
   * @param feeCollector address where the fees will be transferred to
   */
  constructor(uint8 raffleFee, address feeCollector) {
    RAFFLE_FEE = raffleFee;
    FEE_COLLECTOR = feeCollector;
  }

  /// @inheritdoc IPaymentSystem
  function payRaffleAmount(uint256 raffleAmount, address receiver) external {
    uint256 fee = (raffleAmount * RAFFLE_FEE) / 100;
    // transfer winnings
    _safeTransferETH(receiver, raffleAmount - fee);
    // transfer fee
    _safeTransferETH(FEE_COLLECTOR, fee);
  }

  /// @inheritdoc IPaymentSystem
  function payTicketsAmount(address receiver, uint256 amount) external {
    // Return the ticket price to the owner
    _safeTransferETH(receiver, amount);
  }

  /**
   * @dev transfer ETH to an address, revert if it fails.
   * @param to recipient of the transfer
   * @param value the amount to send
   */
  function _safeTransferETH(address to, uint256 value) internal {
    (bool success, ) = to.call{value: value}(new bytes(0));
    require(success, 'ETH_TRANSFER_FAILED');
  }
}

pragma solidity ^0.8.0;

interface IPaymentSystem {
  /**
   * @notice method to get the fee subtracted from the raffle tickets total sale, when raffle successful
   * @return raffle fee
   */
  function RAFFLE_FEE() external view returns (uint8);

  /**
   * @notice method to get the address where the fees will be transferred to
   * @return address of the receiver of the raffle fee
   */
  function FEE_COLLECTOR() external view returns (address);

  /**
* @notice method to pay the amount (minus fee) collected from all the raffle tickets sold to the receiver. It also
            pays the fee collected from the total amount
  * @param raffleAmount amount collected from the raffle tickets sold
  * @param receiver address that will receive the amount collected from the raffle tickets sold minus the raffle fee
  */
  function payRaffleAmount(uint256 raffleAmount, address receiver) external;

  /**
   * @notice method to claim the cost of the raffle tickets from an expired raffle NFT
   * @param receiver address that will receive the raffle tickets cost
   * @param amount full amount representing the cost of the raffle tickets
   */
  function payTicketsAmount(address receiver, uint256 amount) external;
}