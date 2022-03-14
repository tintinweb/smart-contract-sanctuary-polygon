// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import '@openzeppelin/contracts/utils/math/SafeMath.sol';

/**
 * @title GoArtCampaign
 * @dev Distribute MATIC tokens in exchange for GoArt MTE Points collected within in the GoArt game.
 */
contract GoArtCampaign {
	// using SafeMath to prevent underflow & overflow bugs
	using SafeMath for uint256;

	// contract's states are defined here.
	enum State {
		Active,
		Closed,
		Finalized
	}

	State public state = State.Closed;

	uint256 public maxRewardTotal = 200000 ether;
	uint256 public totalDistributedReward;

	// funding wallet of the contract
	address payable public treasuryWallet;

	// service cost set by us
	uint256 public fee = 0.1 ether;

	// min amount
	uint256 public minimumAmountToWithdraw = 1 ether;

	// point to reward ratio
	uint256 public ratio = 10;

	// Participant structure for players
	struct Participant {
		string userId;
		address payable walletAddress;
		uint256 claimed;
		uint256 claimable;
	}

	// Store the participants in an array
	Participant[] public participants;

	// Listing all admins
	address[] public admins;

	// mappings to store registered wallet addresses
	mapping(address => bool) public walletsRegistered;

	// mappings to store registered userIds to prevent same user joining the campaign multiple times.
	mapping(string => bool) public userIdsRegistered;

	// Modifier for easier checking if user is admin
	mapping(address => bool) public isAdmin;

	// event for EVM logging
	event ParticipantRegistered(address walletAddress, string userId, uint256 participantIndex);
	event MTEPointSwapped(uint256 totalAmount, uint256 participantIndex);
	event MaticWithdrawn(uint256 amount, uint256 participantIndex);
	event StateChanged(uint8 state);
	event ParticipantCollectiblesUpdated(uint256 index);
	event ParticipantIdUpdated(uint256 index, string uid);

	// Modifier restricting access to only admin
	modifier onlyAdmin() {
		require(isAdmin[msg.sender], 'Only admin can call.');
		_;
	}

	// Constructor to set initial admins during deployment
	constructor() {
		treasuryWallet = payable(msg.sender);
		admins.push(msg.sender);
		isAdmin[msg.sender] = true;
		totalDistributedReward = 0;
	}

	// register a new admin with the given wallet address
	function addAdmin(address _adminAddress) external onlyAdmin {
		// Can't add 0x address as an admin
		require(_adminAddress != address(0x0), '[RBAC] : Admin must be != than 0x0 address');
		// Can't add existing admin
		require(!isAdmin[_adminAddress], '[RBAC] : Admin already exists.');
		// Add admin to array of admins
		admins.push(_adminAddress);
		// Set mapping
		isAdmin[_adminAddress] = true;
	}

	// remove an existing admin address
	function removeAdmin(address _adminAddress) external onlyAdmin {
		// Admin has to exist
		require(isAdmin[_adminAddress]);
		require(admins.length > 1, 'Can not remove all admins since contract becomes unusable.');
		uint256 i = 0;

		while (admins[i] != _adminAddress) {
			if (i == admins.length) {
				revert('Passed admin address does not exist');
			}
			i++;
		}

		// Copy the last admin position to the current index
		admins[i] = admins[admins.length - 1];

		isAdmin[_adminAddress] = false;

		// Remove the last admin, since it's double present
		admins.pop();
	}

	// Fetch all admins
	function getAllAdmins() external view returns (address[] memory) {
		return admins;
	}

	// Change the current state of the contract
	function changeState(uint8 _state) external onlyAdmin {
		require(_state <= uint8(State.Finalized), 'Given state is not a valid state');
		// change the state to given state index.
		state = State(_state);
		// emit the changed state.
		emit StateChanged(_state);
	}

	// See the current state
	function getState() public view returns (State) {
		return state;
	}

	// Change the contract's max reward amount
	function changeMaxReward(uint256 _maxReward) external onlyAdmin {
		maxRewardTotal = _maxReward;
	}

	// change award ration
	function changeRatio(uint256 _ratio) external onlyAdmin {
		ratio = _ratio;
	}

	// register a user's wallet address if the contract is in Active state.
	function registerWallet(address payable walletAddress, string memory userId)
		external
		onlyAdmin
	{
		require(state == State.Active, 'Contract is not in active state at the moment!');
		require(
			!walletsRegistered[walletAddress],
			'This wallet has been used to register earlier.'
		);
		require(!userIdsRegistered[userId], 'This user id is registered earlier.');

		walletsRegistered[walletAddress] = true;
		userIdsRegistered[userId] = true;

		Participant memory participant = Participant(userId, walletAddress, 0, 0);
		participants.push(participant);

		emit ParticipantRegistered(walletAddress, userId, participants.length - 1);
	}

	// A user's MTE points can be swapped to MATIC through this function.
	function swapMTEPointsToMatic(uint256 _MTEPointsItemAmount, uint256 _participantIndex)
		external
		onlyAdmin
	{
		require(state != State.Finalized, 'Contract is finalized. You cannot swap!');
		require(
			_MTEPointsItemAmount > 0,
			'_MTEPointsItemAmount to be swapped has to be greater than 0.'
		);

		Participant storage participant = participants[_participantIndex];
		uint256 maticAmount = _MTEPointsItemAmount.div(ratio);
		participant.claimable = participant.claimable.add(maticAmount);

		emit MTEPointSwapped(participant.claimable, _participantIndex);
	}

	// return all participants
	function getAllParticipants() public view returns (Participant[] memory) {
		return participants;
	}

	function sendMatic(address payable wallet, uint256 amount) internal {
		(bool success, ) = wallet.call{value: amount}('');
		require(success, 'Transfer failed during sending Matic tokens');
	}

	function withdrawMaticTokens(uint256 _participantIndex) external payable onlyAdmin {
		require(state != State.Finalized, 'Contract is finalized. You cannot withdraw!');
		require(
			msg.value >= minimumAmountToWithdraw,
			'You can withdraw minimum 1 MATIC. Anything below is not allowed.'
		);

		uint256 amountToBeWithdrawn = msg.value.sub(fee);

		require(
			totalDistributedReward + msg.value <= maxRewardTotal,
			'Given amount exceeds the total reward to be distributed from this contract'
		);

		Participant storage participant = participants[_participantIndex];
		require(
			participant.claimable.sub(amountToBeWithdrawn) >= 0,
			'Withdraw amount cannot be greater than total claimable amount!'
		);

		// subtract from claimable amount
		participant.claimable = participant.claimable.sub(msg.value);

		// increase the claimed amount with _amount
		participant.claimed = participant.claimed.add(msg.value);

		// transfer the funds
		sendMatic(participant.walletAddress, amountToBeWithdrawn);
		// get the service fee
		sendMatic(treasuryWallet, fee);

		totalDistributedReward = totalDistributedReward.add(msg.value);

		emit MaticWithdrawn(msg.value, _participantIndex);
	}

	// set service fee
	function setServiceFee(uint256 _fee) external onlyAdmin {
		fee = _fee;
	}

	// get service fee
	function getServiceFee() public view returns (uint256) {
		return fee;
	}

	// get maximum reward total
	function getMaxRewardTotal() public view returns (uint256) {
		return maxRewardTotal;
	}

	// set minimumAmount
	function setMinimumAmount(uint256 _minimumAmount) external onlyAdmin {
		minimumAmountToWithdraw = _minimumAmount;
	}

	// get minimum amount
	function getMinimumAmount() public view returns (uint256) {
		return minimumAmountToWithdraw;
	}

	// get total distributed reward
	function getTotalDisributedReward() public view returns (uint256) {
		return totalDistributedReward;
	}

	// check if a wallet is registered
	function walletRegistered(address _walletAddress) public view returns (bool) {
		return walletsRegistered[_walletAddress];
	}

	// check if userId is registered
	function userRegistered(string memory _uuid) public view returns (bool) {
		return userIdsRegistered[_uuid];
	}

	// change the funding wallet
	function changeTreasuryWallet(address _walletAddress) external onlyAdmin {
		treasuryWallet = payable(_walletAddress);
	}

	// Participant functions

	// get a single participant by index
	function getParticipant(uint256 index) public view returns (Participant memory) {
		return participants[index];
	}

	// get number of participants
	function getTotalParticipants() public view returns (uint256) {
		return participants.length;
	}

	// update the participant
	function updateParticipantClaims(
		uint256 index,
		uint256 claimed,
		uint256 claimable
	) external onlyAdmin {
		Participant storage participant = participants[index];
		participant.claimed = claimed;
		participant.claimable = claimable;
		emit ParticipantCollectiblesUpdated(index);
	}

	// update userId in case of an emergency
	function updateParticipantId(uint256 index, string memory uid) external onlyAdmin {
		require(!userIdsRegistered[uid], 'This user id is registered earlier.');
		Participant storage participant = participants[index];
		participant.userId = uid;
		userIdsRegistered[uid] = true;
		emit ParticipantIdUpdated(index, uid);
	}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}