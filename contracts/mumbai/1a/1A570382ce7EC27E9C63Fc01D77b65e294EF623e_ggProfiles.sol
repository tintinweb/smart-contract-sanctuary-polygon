// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/**
 * @title ggProfiles
 * @author h0tmilk
 * @notice Non-transferable token (aka Soulbound token) containing informations about ggQuest gaming profile of an address
 * @dev As SBT doesn't have any standard yet, this code may change in the future when it will be available
 **/
contract ggProfiles {

    struct ProfileData {
        // Data of the user
        string pseudo;
        string profilePictureURL;
        string coverPictureURL;
        bool isRegistered;

        // Reputation
        uint gainedReputation;
        uint lostReputation;

        // Associated hird parties (discord, twitch...)
        ThirdParty[] linkedThirdParties;
    }

    struct UpdatableByUserData {
        // Struct to facilitate ProfileData modifications by users
        string pseudo;
        string profilePictureURL;
        string coverPictureURL;
    }

    struct ThirdParty {
        uint thirdPartyId;
        uint userID;
    }

    using SafeMath for uint;

    // Associate an address with profile data
    mapping(address => ProfileData) private profiles;
    // Pseudonymes to avoid two players to have the same one
    mapping(string => bool) private takenPseudonymes;
    address[] public registeredAddresses;

    // Supported thirdParties (Twitch, Discord, Steam...)
    string[] thirdParties;

    string public name;
    string public ticker;
    mapping(address => bool) public operators;
    
    event Mint(address _userAddress, string _pseudo);
    event Burn(address _userAddress);
    event Update(address _userAddress, string _pseudo);

    event IncreaseReputation(address _userAddress, uint _amount);
    event DecreaseReputation(address _userAddress, uint _amount);

    event AddOperator(address _operator);
    event RemoveOperator(address _operator);

    event AddSupportedThirdParty(string _name);
    event LinkThirdPartyToProfile(address _userAddress, uint _thirdPartyId, uint _thirdPartyUserId);
    event UnlinkThirdPartyToProfile(address _userAddress, uint _thirdPartyId);

    constructor(string memory _name, string memory _ticker) {
      name = _name;
      ticker = _ticker;
      operators[msg.sender] = true;
    }

    /**
    * @notice Add operator
    * @param _operator address of the new operator
    **/
    function addOperator(address _operator) external {
        require(operators[msg.sender], "Only operators can manage operators");
        operators[_operator] = true;
        emit AddOperator(_operator);
    }

    /**
    * @notice Remove operator
    * @param _operator address of the operator to remove
    **/
    function removeOperator(address _operator) external {
        require(operators[msg.sender], "Only operators can manage operators");
        delete operators[_operator];
        emit RemoveOperator(_operator);
    }

    /**
    * @notice Checks if the address is an operator
    * @param _operator address to challenge
    * @return true if the address is operator
    **/
    function isOperator(address _operator) external view returns(bool) {
        return operators[_operator];
    }

    /**
    * @notice Registers a new gaming profile
    * @param _userData data of the new profile
    **/
    function mint(UpdatableByUserData memory _userData) external {
        require(!profiles[msg.sender].isRegistered, "Profile already registered");
        _setUserData(msg.sender, _userData);
        profiles[msg.sender].isRegistered = true;

        emit Mint(msg.sender, _userData.pseudo);
    }

    /** 
    * @notice Delete a user profile - operators only
    * @param _userAddress address which owns the profile
    **/
    function burn(address _userAddress) external {
        require(operators[msg.sender], "Only operators have rights to delete users' data");

        delete takenPseudonymes[profiles[_userAddress].pseudo];
        delete profiles[_userAddress];

        emit Burn(_userAddress);
    }

    /** 
    * @notice Update sender's profile data
    * @param _userData updatable data to be affected to the sender
    **/
    function update(UpdatableByUserData memory _userData) external {
        require(profiles[msg.sender].isRegistered, "Profile not registered, please mint first");
        _setUserData(msg.sender, _userData);
        emit Update(msg.sender, _userData.pseudo);
    }

    /**
    * @notice Increase reputation of the user
    * @param _userAddress profile address
    * @param _amount amount to add to the reputation
    **/
    function increaseReputation(address _userAddress, uint _amount) external {
        require(operators[msg.sender], "Only operators can manage reputation");
        require(profiles[_userAddress].isRegistered, "Profile not registered");

        profiles[_userAddress].gainedReputation = profiles[_userAddress].gainedReputation.add(_amount);

        emit IncreaseReputation(_userAddress, _amount);
    }

    /**
    * @notice Decrease reputation of the user
    * @param _userAddress profile address
    * @param _amount amount to add to the reputation
    **/
    function decreaseReputation(address _userAddress, uint _amount) external {
        require(operators[msg.sender], "Only operators can manage reputation");
        require(profiles[_userAddress].isRegistered, "Profile not registered");

        profiles[_userAddress].lostReputation = profiles[_userAddress].lostReputation.add(_amount);

        emit DecreaseReputation(_userAddress, _amount);
    }

    /**
    * @notice Get the reputation score of an address
    * @dev You have to calculate the total score (as SafeMath doesn't support int for negative scores)
    * @param _userAddress profile address
    * @return gained reputation, amount of reputation to add to the total score
    * @return lost reputation, amount of reputation to substract to the total score
    **/
    function getReputation(address _userAddress) external view returns (uint, uint) {
        return (profiles[_userAddress].gainedReputation, profiles[_userAddress].lostReputation);
    }

    /**
    * @notice Get the registered addresses
    * @return array of registered addresses
    **/
    function getRegisteredAddresses() external view returns(address[] memory) {
        return registeredAddresses;
    }

    /** 
    * @notice Check if an address is registered
    * @param _userAddress address of the user
    * @return true if user address is registered
    **/
    function hasProfileData(address _userAddress) external view returns (bool) {
        return profiles[_userAddress].isRegistered;
    }

    /** 
    * @notice Check if a pseudo is available (not taken)
    * @param _pseudo pseudo to challenge
    * @return true if the address is available
    **/
    function isAvailable(string memory _pseudo) external view returns (bool) {
        return !takenPseudonymes[_pseudo];
    }

    /** 
    * @notice Get profile data of a registered address
    * @param _userAddress address of the user
    * @return profile data associated with the given user address
    **/
    function getProfileData(address _userAddress) external view returns (ProfileData memory) {
        return profiles[_userAddress];
    }

    /** 
    * @notice Add a supported third party - operators only
    * @param _thirdPartyName name of the thirdParty (e.g. "TWITCH", "DISCORD", "STEAM"...)
    **/
    function addThirdParty(string memory _thirdPartyName) external {
        require(operators[msg.sender], "Only operators can add a third party");
        thirdParties.push(_thirdPartyName);

        emit AddSupportedThirdParty(_thirdPartyName);
    }

    /** 
    * @notice Get all the supported third parties. Can be used to associate the id with each one of them
    * @return array of thirdParties
    **/
    function getThirdParties() external view returns (string[] memory) {
        return thirdParties;
    }

    /** 
    * @notice Link a third party account to a profile
    * @param _profileAddress address of the profile
    * @param _thirdPartyId id of the supported third party (index of the third party in thirdParties)
    * @param _thirdPartyUserID id of the user in the third party database (with which we can fetch info through third party api)
    **/
    function linkThirdPartyToProfile(address _profileAddress, uint _thirdPartyId, uint _thirdPartyUserID) external {
        require(operators[msg.sender], "Only operators can link third parties to profiles");
        require(bytes(thirdParties[_thirdPartyId]).length != 0, "No third party found with this ID");

        for(uint i = 0; i < profiles[_profileAddress].linkedThirdParties.length; i++) {
            require(profiles[_profileAddress].linkedThirdParties[i].thirdPartyId != _thirdPartyId, "This profile is already linked to this third party");
        }

        ThirdParty memory newThirdPartyLink;
        newThirdPartyLink.thirdPartyId = _thirdPartyId;
        newThirdPartyLink.userID = _thirdPartyUserID;

        profiles[_profileAddress].linkedThirdParties.push(newThirdPartyLink);

        emit LinkThirdPartyToProfile(_profileAddress, _thirdPartyId, _thirdPartyUserID);
    }

    /** 
    * @notice Unlink a third party account from a profile
    * @param _profileAddress address of the profile
    * @param _thirdPartyId id of the supported third party (index of the third party in thirdParties)
    **/
    function unlinkThirdPartyFromProfile(address _profileAddress, uint _thirdPartyId) external {
        require(operators[msg.sender], "Only operators can unlink third parties to profiles");
        require(bytes(thirdParties[_thirdPartyId]).length != 0, "No third party found with this ID");

        bool removed = false;
        uint removedIndex;
        for(uint i = 0; i < profiles[_profileAddress].linkedThirdParties.length; i++) {
            if(profiles[_profileAddress].linkedThirdParties[i].thirdPartyId == _thirdPartyId) {
                delete profiles[_profileAddress].linkedThirdParties[i];
                removed = true;
                removedIndex = i;
            }
        }

        if(removed) {
            // Remove gap from array by putting last item to removed index
            profiles[_profileAddress].linkedThirdParties[removedIndex]
                = profiles[_profileAddress].linkedThirdParties[profiles[_profileAddress].linkedThirdParties.length-1];

            profiles[_profileAddress].linkedThirdParties.pop();
        }

        emit UnlinkThirdPartyToProfile(_profileAddress, _thirdPartyId);
    }

    /** 
    * @notice Update a profile fields
    * @param _user address of the user profile
    * @param _userData data to update
    **/
    function _setUserData(address _user, UpdatableByUserData memory _userData) private {
        string memory currentPseudo = profiles[_user].pseudo;
        string memory newPseudo = _userData.pseudo;

        require(
            !takenPseudonymes[newPseudo] // pseudo not taken
            || (takenPseudonymes[newPseudo] && keccak256(bytes(newPseudo)) == keccak256(bytes(currentPseudo))), // or taken but belonging to the sender and not changing
            "Pseudonyme is not available");
        require(bytes(_userData.pseudo).length != 0, "Pseudo cannot be empty");

        // Mark the pseudo as taken if modified
        if(keccak256(bytes(newPseudo)) != keccak256(bytes(currentPseudo))) {
            takenPseudonymes[currentPseudo] = false;
        }
        takenPseudonymes[newPseudo] = true;

        // Update Profile data
        profiles[msg.sender].pseudo = newPseudo;
        profiles[msg.sender].profilePictureURL = _userData.profilePictureURL;
        profiles[msg.sender].coverPictureURL = _userData.coverPictureURL;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

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
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
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