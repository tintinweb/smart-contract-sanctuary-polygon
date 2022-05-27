pragma solidity ^0.8.7;
import "./xWALLET.sol";
contract xWALLETSpendable {
    function balanceOf(address who) external view returns (uint256 balance) {
        StakingPool xWALLET = StakingPool(0xEc3b10ce9cabAb5dbF49f946A623E294963fBB4E);
        return xWALLET.balanceOf(who) - xWALLET.lockedShares(who);
    }
}